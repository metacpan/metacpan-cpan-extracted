package Test::Chado::Role::HasDBManager;
{
  $Test::Chado::Role::HasDBManager::VERSION = 'v4.1.1';
}

use namespace::autoclean;
use Moo::Role;
use MooX::late;
use File::ShareDir qw/module_dir/;
use File::Spec::Functions;
use IO::File;
use autodie qw/:file/;
use DBI;
use Test::Chado::Types qw/DBH/;
use Test::Chado;

requires '_build_dbh',  '_build_database', '_build_driver';
requires 'drop_schema', 'create_database', 'drop_database';
requires 'get_client_to_deploy', 'deploy_by_client';
requires 'is_dynamic_schema';

has 'dbh' => (
    is      => 'rw',
    isa     => DBH,
    lazy    => 1,
    builder => '_build_dbh'
);

has 'dbi_attributes' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return { AutoCommit => 1, RaiseError => 1 };
    }
);

has 'database' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_database'
);

has 'driver' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_driver'
);

has 'ddl' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return catfile( module_dir('Test::Chado'),
            'chado.' . lc $self->driver );
    }
);

has [qw/user password/] => ( is => 'rw', isa => 'Str' );
has 'driver_dsn' => ( is => 'rw', isa => 'Str' );
has 'dsn' => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {
        my ( $self, $value ) = @_;
        my ( $scheme, $driver, $attr_str, $attr_hash, $driver_dsn )
            = DBI->parse_dsn($value);
        $self->driver($driver);
        $self->driver_dsn($driver_dsn);
    }
);

sub deploy_schema {
    my ($self) = @_;
    if ( my $client = $self->get_client_to_deploy ) {
        $self->deploy_by_client($client);
    }

    else {
        $self->deploy_by_dbi;
    }
}

sub deploy_by_dbi {
    my ($self) = @_;
    my $dbh = $self->dbh;

    my $fh = IO::File->new( $self->ddl, 'r' );
    my $data = do { local ($/); <$fh> };
    $fh->close();

LINE:
    foreach my $line ( split( /\n{2,}/, $data ) ) {
        next LINE if $line =~ /^\-\-/;
        $line =~ s{;$}{};
        $line =~ s{/}{};
        $dbh->do($line);
    }
}

sub reset_schema {
    my ($self) = @_;
    $self->drop_schema;
    $self->deploy_schema;
}

1;

__END__

=pod

=head1 NAME

Test::Chado::Role::HasDBManager

=head1 VERSION

version v4.1.1

=head1 SYNOPSIS

package MyMooClass;
with 'Test::Chado::Role::HasDBManager';

B<Now implement all the required attributes given below>

=head1 DESCRIPTION

Moo role based interface to be consumed by backend specific classes for managing database

=head1 ATTRIBUTES

=head2 dsn

Datasource dsn

=item dbi_attributes

Extra parameters for database connection, by default RaiseError and AutoCommit are set.

=item driver_dsn

=item deploy_by_dbi

Deploy schema using DBI

=item reset_schema

First drops the schema, the reloads it. 

=back

=head1 API

=head2 Needs implementation

=over

=item database

Database name. The method B<_build_database> should be B<implemented> by consuming class.

=item dbh

Database handler, a L<DBI> object. The method <_build_dbh> should be B<implemented> by consuming class.

=item driver

Name of the database backend. It is being set from dsn value.The method <_build_driver> should be B<implemented> by consuming class.

=item ddl

Location of the database specific ddl file. Should be B<implemented> by consuming class.

=item is_dynamic_schema

Indicates whether B<DBIx::Class::Schema> should be dynamic or comes from L<Bio::Chado::Schema>. Should be B<implemented> by consuming class.

=item deploy_schema

Load the database schema from the ddl file. Should be B<implemented> by consuming class.

=item get_client_to_deploy

Full path for the command line client. Return undef in case not available. Should be B<implemented> by consuming class.

=item deploy_by_client

Use backend specific command line tool to deploy the schema. Should be B<implemented> by consuming class.

=item drop_schema

Drop the loaded schema. Should be B<implemented> by consuming class.

=item create_database

Create database. Should be B<implemented> by consuming class.

=item drop_database

Drop database. Should be B<implemented> by consuming class.

=back

=head2 Optional

=item user

Database user

=item password

Database password

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
