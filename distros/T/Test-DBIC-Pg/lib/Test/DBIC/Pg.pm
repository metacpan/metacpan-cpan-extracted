package Test::DBIC::Pg;
use Moo;
with 'Test::DBIC::DBDConnector';

our $VERSION = "1.00";

use DBI;

use parent 'Test::Builder::Module';
our @EXPORT = qw( connect_dbic_pg_ok drop_dbic_pg_ok );

$Test::DBIC::Pg::LeaveCreatedDatabases //= 0;

# allow for DBI options syntax: dbi:Pg(FetchHashKeyName=>NAME_uc):dbname=blah
my $dsn_regex = qr{^ dbi:Pg(?:\(.+?\))?: }x;

use Types::Standard qw( Bool Dict HashRef Maybe Str StrMatch );
has '+dbi_connect_info' => (
    is   => 'ro',
    type => Dict [
        dsn      => StrMatch [$dsn_regex],
        username => Types::Standard::Optional [Str],
        password => Types::Standard::Optional [Str],
        options  => Types::Standard::Optional [HashRef],
    ],
    default => sub { { dsn => "dbi:Pg:dbname=_test_dbic_pg_$$" } },
);
has _pg_tmp_connect_dsn => (
    is  => 'rwp',
    isa => Maybe [
        Dict [
            tmp_dsn  => StrMatch [$dsn_regex],
            dbname   => Str,
            pghost   => Maybe [Str],
            dsn      => StrMatch [$dsn_regex],
            username => Types::Standard::Optional [Str],
            password => Types::Standard::Optional [Str],
            options  => Types::Standard::Optional [HashRef],
        ]
    ],
);
has _tmp_connection => (
    is      => 'lazy',
    clearer => 1,
);
has TMPL_DB => (
    is      => 'ro',
    default => sub {'template1'},
);
has _did_create => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

# Keep a "singleton" around for the functional interface.
my $_tdbc_cache;

sub _build__tmp_connection {
    my $self = shift;
    return DBI->connect(
        $self->_pg_tmp_connect_dsn->{tmp_dsn},
        $self->_pg_tmp_connect_dsn->{username},
        $self->_pg_tmp_connect_dsn->{password},
    );
}

sub DEMOLISH {
    my $self = shift;
    if ($self->_did_create && !$Test::DBIC::Pg::LeaveCreatedDatabases) {
        my $dbh = $self->_tmp_connection;
        local (
            $dbh->{PrintError}, $dbh->{RaiseError},
            $dbh->{PrintWarn}, $dbh->{RaiseWarn}
        );
        $dbh->do(
            sprintf("DROP DATABASE %s", $self->_pg_tmp_connect_dsn->{dbname})
        );
        $self->_set__did_create(0);
        $dbh->disconnect;
    }
}

sub connect_dbic_pg_ok {
    my $class = __PACKAGE__;
    my %args = $class->validate_positional_parameters(
        [
            $class->parameter(schema_class      => $class->Required),
            $class->parameter(dbi_connect_info  => $class->Optional),
            $class->parameter(pre_deploy_hook   => $class->Optional),
            $class->parameter(post_connect_hook => $class->Optional),
        ],
        \@_
    );
    $args{dbi_connect_info} //= { dsn => "dbi:Pg:dbname=_test_dbic_pg_$$" };

    $_tdbc_cache //= $class->new(%args);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $schema =  $_tdbc_cache->connect_dbic_ok();
    if (!$schema) {
        undef($_tdbc_cache);
    }

    return $schema;
}

sub drop_dbic_pg_ok {
    if (!defined($_tdbc_cache)) {
        my $msg = "no database DROPPED";
        return $_tdbc_cache->builder->ok(1, $msg);
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = $_tdbc_cache->drop_dbic_ok();

    undef($_tdbc_cache);

    return $result;
}

sub drop_dbic_ok {
    my $self = shift;
    my $dbname = $self->_pg_tmp_connect_dsn->{dbname};
    my $msg = "$dbname DROPPED";

    my $dbh = $self->_tmp_connection();
    local ($dbh->{PrintError}, $dbh->{RaiseError});
    my $rows = $dbh->do("DROP DATABASE $dbname");
    if (! $rows) {
        $self->builder->diag("DROP $dbname: '@{[$DBI::errstr // q/ok/]}'");
    }
    $dbh->disconnect();
    $self->_clear_tmp_connection;
    $self->_set__did_create(0);

    return $self->builder->ok(1, $msg);
}

sub MyDBD_connection_parameters {
    my $self = shift;
    $self->validate_positional_parameters(
        [
            $self->parameter(
                dbi_connect_info => $self->Required,
                { store => \my $pg_connect_info }
            )
        ],
        \@_
    );

    my $tmp_dsn_info = $self->_parse_pg_dsn($pg_connect_info->{dsn});
    $self->_set__pg_tmp_connect_dsn(
        {
            %$pg_connect_info,
            %$tmp_dsn_info,
        }
    );
    my $tmp_dbh = $self->_tmp_connection;

    return [ @{$pg_connect_info}{qw/ dsn username password options /} ];
}

sub MyDBD_check_wants_deploy {
    my $self = shift;

    local $ENV{PGHOST} = $self->_pg_tmp_connect_dsn->{pghost} if not $ENV{PGHOST};
    my $dbh = $self->_tmp_connection;

    my @known_dbs = $dbh->data_sources();
    my $wants_deploy = not grep {
        m{dbname=(.+?)(?=;|$)} && $1 eq $self->_pg_tmp_connect_dsn->{dbname}
    } @known_dbs;

    if ($wants_deploy) {
        my $rows = $dbh->do("CREATE DATABASE ". $self->_pg_tmp_connect_dsn->{dbname});
        $self->_set__did_create(1);
    }
    $dbh->disconnect();
    $self->_clear_tmp_connection;

    return $wants_deploy;
}

sub _parse_pg_dsn {
    my $self = shift;;
    $self->validate_positional_parameters(
        [ $self->parameter(dsn => $self->Required, {store => \my $dsn}) ],
        \@_
    );
    my ($pghost) = $dsn =~ m{(?<=host=)(?<host>[-.\w]+?)(?=;|$)}
        ? $+{host}
        : undef;

    my $template_db = $self->TMPL_DB;

    my ($db_attr) = $dsn =~ m{(?<db_attr>dbname|database|db)(?==)}
        ? $+{db_attr}
        : 'dbname';
    (my $tmp_dsn = $dsn) =~ s{(?<=(?:$db_attr)=)(?<dbname>\w+?)(?=;|$)}{$template_db};
    my $dbname = $+{dbname} // "<unknown>";

    return {
        tmp_dsn => $tmp_dsn,
        dbname  => $dbname,
        pghost  => $pghost,
    };
}

around ValidationTemplates => sub {
    my $vt = shift;
    my $class = shift;

    use Types::Standard qw( ArrayRef Dict HashRef Maybe Str StrMatch );

    my $validation_templates = $class->$vt();
    return {
        %$validation_templates,
        connection_info  => { type => ArrayRef },
        dsn              => { type => StrMatch [$dsn_regex] },
        dbi_connect_info => {
            type => Maybe [Dict [
                dsn      => StrMatch [$dsn_regex],
                username => Types::Standard::Optional [Str],
                password => Types::Standard::Optional [Str],
                options  => Types::Standard::Optional [HashRef],
            ]],
            default => sub { { dsn => "dbi:Pg:dbname=_test_dbic_pg_$$" } }
        },
    };
};

use namespace::autoclean 0.16;
1;

=pod

=head1 NAME

Test::DBIC::Pg - Connect to and deploy a DBIx::Class::Schema on Postgres

=head1 SYNOPSIS

The preferred way:

    #! perl -w
    use Test::More;
    use Test::DBIC::Pg;

    my $td = Test::DBIC::Pg->new(schema_class => 'My::Schema');
    my $schema = $td->connect_dbi_ok();
    ...
    $schema->storage->disconnect();
    $td->drop_dbic_ok();
    done_testing();

The compatible with L<Test::DBIC::SQLite> way:

    #! perl -w
    use Test::More;
    use Test::DBIC::Pg;
    my $schema = connect_dbic_pg_ok('My::Schema');
    ...
    $schema->storage->disconnect();
    drop_dbic_pg_ok();
    done_testing();

=head1 DESCRIPTION

This is an implementation of C<Test::DBIC::Pg> that uses the L<Moo::Role>:
L<Test::DBIC::DBDConnector> from the L<Test::DBIC::SQLite> package.

It will C<import()> L<warnings> and L<strict> for you.

=head2 C<< Test::DBIC::Pg->new >>

    my $td = Test::DBIC::Pg->new(%parameters);
    my $schema = $td->connect_dbic_ok();
    ...
    $schema->storage->disconnect();
    $td->drop_dbic_ok();

=head3 Parameters

Named, list:

=over

=item B<< C<schema_class> >> => C<$schema_class> (I<Required>)

The class name of the L<DBIx::Class::Schema> to use.

=item B<< C<dbi_connect_info> >> => C<$pg_connect_info> (I<Optional>,
C<< { dsn => "dbi:Pg:dbname=_test_dbic_pg_$$" } >>)

This is a HashRef that will be used to connect to the PostgreSQL server:

=over 8

=item B<< C<dsn> >> => C<dbi:Pg:host=mypg;dbname=_my_test_x>

This Data Source Name (dsn) must also contain the C<dbi:Pg:> bit that is needed
for L<DBI> to connect to your database/server.
We do allow for DBI options syntax: C<< dbi:Pg(FetchHashKeyName=>NAME_uc):dbname=blah >>

If your database doesn't exist it will be created. This will need an extra
temporary database connection.

=item B<< C<username> >> => C<$username>

This is the username that will be used to connect to the PostgreSQL server, if
omitted L<DBD::Pg> will try to use C<$ENV{PGUSER}>.

=item B<< C<password> >> => C<$password>

This is the password that will be used to connect to the PostgreSQL server, if
omitted L<DBD::Pg> will look at C<~/.pgpass> to see if it can find a suitable
password in there. (See also postgres docs for C<$ENV{PGPASSWORD}> en
C<$ENV{PGPASSFILE}>).

=item B<< C<options> >> => C<$options_hash>

This options hashref is also passed to the C<< DBIx::Class::Schema->connect() >>
method for extra options. This hash will contain the extra key/value pair C<<
skip_version => 1 >> whenever the B<wants_deploy> attribute is true.

=back

=item B<< C<pre_deploy_hook> >> => C<$pre_deploy_hook> (I<Optional>)

A CodeRef to execute I<before> C<< $schema->deploy >> is called.

This CodeRef is called with an instantiated C<< $your_schema_class >> object as argument.

=item B<< C<post_connect_hook> >> => C<$post_connect_hook> (I<Optional>)

A coderef to execute I<after> C<< $schema->deploy >> is called, if at all.

This coderef is called with an instantiated C<< $your_schema_class >> object as argument.

=item B<< C<TMPL_DB> >> => C<$template_database> (I<Optional>, C<template1>)

In order to create and drop your test database a temporary connection needs to
be made to the PostgreSQL instance from your dsn, but with a template database
(tools like C<createdb> and C<dropdb> also do this in the background).
The default database for these type of connections is C<template1> - and this
module uses that as well - but your DBA could have configured a different
database for this function, therefore we support the setting of C<TMPL_DB>.

=back

=head2 C<< $td->connect_dbic_ok() >>

This method is inherited from L<Test::DBIC::DBDConnoctor>.

If the database needs deploying, there will be another temporary database
connection to the template database in order to issue the C<CREATE DATABASE
$dbname> statement.

=head3 Returns

An initialised instance of C<$schema_class>.

=head2 C<< $td->drop_dbic_ok >>

This method implements a C<< dropdb $dbname >>, in order not to litter your
server with test databases.

During this method there will be another temporary database connection to the
template database, in order to issue the C<DROP DATABASE $dbname> statement
(that cannot be run from the connection with the test database it self).

=head2 C<connect_dbic_pg_ok(@parameters)>

Create a PostgreSQL database and deploy a dbic_schema. This function is provided
for compatibility with L<Test::DBIC::SQLite>.

See L<< Test::DBIC::Pg->new|/Test::DBIC::Pg->new >> for further information,
although only these 4 arguments are supported.

=head3 Parameters

Positional:

=over

=item 1. C<$schema_class> (Required)

=item 2. C<$pg_connect_info> (Optional)

=item 3. C<$pre_deploy_hook> (Optional)

=item 4. C<$post_connect_hook> (Optional)

=back

=head2 C<drop_dbic_pg_ok()>

This function uses the cached information of the call to C<connect_dbic_pg_ok()>
and clears it after the database is dropped, using another temporary connection
to the template database.

See L<the C<drop_dbic_ok()> method|/"-td-drop_dbic_ok">.

=head2 Implementation of C<MyDBD_connection_parameters>

As there is no fiddling with the already provided connection paramaters, this
method sets up the connection parameter for the temporary connection to the
template database in order to create or drop the (temporary) test database.

=head2 Implementation of C<MyDBD_check_wants_deploy>

In this method the temporary connection to the template database is set up and a
list of available database is requested - via C<< $dbh->data_sources() >> - to
check if the test database already exists. If it doesn't, the database will be
created and a true value is returned, otherwise a false value is returned and no
new database is created.

=begin devel_cover_pod

=head2 DEMOLISH

Remove created database files when the object goes out of scope.

=end devel_cover_pod

=head1 AUTHOR

E<copy> MMXXI - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
