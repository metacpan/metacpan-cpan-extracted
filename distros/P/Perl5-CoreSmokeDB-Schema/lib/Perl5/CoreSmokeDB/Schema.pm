use utf8;
package Perl5::CoreSmokeDB::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vCye+8pfvU4CmiRtdudyxw

our $VERSION = 1.07;
our $SCHEMAVERSION = 3;
our $PGAPPNAME = 'Perl5CoreSmokeDB';

=head1 NAME

Perl5::CoreSmokeDB::Schema - DBIC::Schema for the smoke reports database

=head1 SYNOPSIS

    use Perl5::CoreSmokeDB::Schema;
    my $schema = Perl5::CoreSmokeDB::Schema->connect($dsn, $user, $pswd, $options);

    my $report = $schema->resultset('Report')->find({ id => 1 });

=head1 DESCRIPTION

This class is used in the backend for accessing the database.

Another use is: C<< $schema->deploy() >>

=cut

use Exception::Class (
    'Perl5::CoreSmokeDB::Schema::Exception' =>
        'Perl5::CoreSmokeDB::Schema::VersionMismatchException' => {
        isa   => 'Perl5::CoreSmokeDB::Schema::Exception',
        alias => 'throw_version_mismatch'
    },
    'Perl5::CoreSmokeDB::Schema::DBDriverMismatchExeption' => {
        isa   => 'Perl5::CoreSmokeDB::Schema::Exception',
        alias => 'throw_dbdriver_mismatch',
    },
);

=head2 $schema->connection

    after connection => sub { };

Check the version in the database with our C<$SCHEMAVERSION> unless the option
C<ignore_version> was passed.

=cut

sub connection {
    my $self = shift;
    $self->next::method(@_);

    $self->_check_version($_[3]);

    $self->pg_post_connect     if $_[0] =~ m{^ dbi:Pg: }x;
    $self->sqlite_post_connect if $_[0] =~ m{^ dbi:SQLite: }x;

    return $self;
}

sub _check_version {
    my $self = shift;
    my ($args) = @_;
    $args ||= { };

    return 1 if $args->{ignore_version};

    my $dbversion = $self->resultset('TsgatewayConfig')->find(
        {name => 'dbversion'}
    )->value;

    if ($SCHEMAVERSION > $dbversion) {
        throw_version_mismatch(
            sprintf(
                "SCHEMAVersion %d does not match DBVersion %d",
                $SCHEMAVERSION,
                $dbversion
            )
        );
    }
    return $self;
}

=head2 deploy()

    around deploy => sub { };

Populate the tsgateway_config-table with data.

=cut

sub deploy {
    my $self = shift;

    if ($self->storage->connect_info->[0] =~ m{^dbi:SQLite}) {
        $self->sqlite_post_connect();
    }
    elsif ($self->storage->connect_info->[0] =~ m{^dbi:Pg}) {
        $self->pg_pre_deploy();
    }
    else {
        my ($driver) = $self->storage->connect_info->[0] =~ m{^ (dbi: [^:]+) }x;
        throw_dbdriver_mismatch(
            sprintf("%s not supported for %s (dbi:Pg/dbi:SQLite)", $driver, __PACKAGE__)
        );
    }

    $self->next::method(@_);

    my $dbh = $self->storage->dbh;
    # FIX the plevel column; DBIx::Class doesn't know how to do 'GENERATED'
    # columns
    $dbh->do(<<EOQ);
ALTER TABLE report
DROP COLUMN plevel
EOQ
    $dbh->do(<<EOQ);
ALTER TABLE report
 ADD COLUMN plevel varchar GENERATED ALWAYS AS (git_describe_as_plevel(git_describe)) STORED
EOQ

    $self->resultset('TsgatewayConfig')->populate(
        [
            {name => 'dbversion', value => $SCHEMAVERSION},
        ]
    );
}

use constant SQLITE_DETERMINISTIC => 0x800; # from sqlite3.c source in DBD::SQLite

=head2 $schema->sqlite_post_connect

Install the function needed for the C<plevel> column (for this connection). It
is called just before C<< $schema->deploy >> and also just after C<<
$schema->connect >>.

=cut

sub sqlite_post_connect {
    my $self = shift;
    my $dbh = $self->storage->dbh;

    $dbh->sqlite_create_function(
        'git_describe_as_plevel',
        1, \&plevel,
        SQLITE_DETERMINISTIC
    );
}

=head2 $schema->pg_post_connect

Set the C<application_name> for this connection to B<Perl5CoreSmokeDB>.

=cut

sub pg_post_connect {
    my $self = shift;

    $self->storage->dbh->do("SET application_name TO $PGAPPNAME");
}

=head2 $schema->pg_pre_deploy

Install the function needed for the C<plevel> column, this function is now part
of that database and doesn't need reinstalling for each connection.

=cut

sub pg_pre_deploy {
    my $self = shift;
    my $dbh = $self->storage->dbh;

    $dbh->do(<<'EOQ');
CREATE OR REPLACE FUNCTION public.git_describe_as_plevel(varchar)
    RETURNS varchar
    LANGUAGE plpgsql
    IMMUTABLE
AS $function$
    DECLARE
        vparts varchar array [5];
        plevel varchar;
        clean  varchar;
    BEGIN
        SELECT regexp_replace($1, E'^v', '') INTO clean;
        SELECT regexp_replace(clean, E'-g\.\+$', '') INTO clean;

        SELECT regexp_split_to_array(clean, E'[\.\-]') INTO vparts;

        SELECT vparts[1] || '.' INTO plevel;
        SELECT plevel || lpad(vparts[2], 3, '0') INTO plevel;
        SELECT plevel || lpad(vparts[3], 3, '0') INTO plevel;
        if array_length(vparts, 1) = 3 then
            SELECT array_append(vparts, '0') INTO vparts;
        end if;
        if regexp_matches(vparts[4], 'RC') = array['RC'] then
            SELECT plevel || vparts[4] INTO plevel;
        else
            SELECT plevel || 'zzz' INTO plevel;
        end if;
        SELECT plevel || lpad(vparts[array_upper(vparts, 1)], 3, '0') INTO plevel;

        return plevel;
    END;
$function$ ;
EOQ
}

=head2 plevel($git-describe)

This is the function used for SQLite to set the value of the C<plevel> column.

=cut

sub plevel {
    my $data = shift;

    (my $git_describe  = $data) =~ s{^v}{};
    $git_describe =~ s{-g[0-9a-f]+$}{}i;

    my @vparts = split(/[.-]/, $git_describe, 5);
    my $plevel = sprintf("%u.%03u%03u", @vparts[0..2]);
    if (@vparts < 4) {
        push(@vparts, '0');
    }
    my $rc = $vparts[3] =~ m{RC}i ? $vparts[3] : 'zzz';
    $plevel .= $rc;
    $plevel .= sprintf("%03u", $vparts[-1] // '0');

    return $plevel;
}

=head1 AUTHOR

E<copy> MMXIII- MMXII - Abe Timmerman <abeltje@cpan.org>, H.Merijn Brand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
1;
