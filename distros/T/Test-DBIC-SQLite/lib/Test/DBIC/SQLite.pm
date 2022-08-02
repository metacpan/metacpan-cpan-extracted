package Test::DBIC::SQLite;
use Moo;
with 'Test::DBIC::DBDConnector';

our $VERSION = "1.01";

use parent 'Test::Builder::Module';
our @EXPORT = qw( connect_dbic_sqlite_ok drop_dbic_sqlite_ok );

$Test::DBIC::SQLite::LeaveCreatedDatabases //= 0;

use Types::Standard qw( Bool Str );
has '+dbi_connect_info' => (
    is      => 'ro',
    isa     => Str,
    default => sub {':memory:'},
);
has _did_create => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

# Keep a "singleton" around for the functional interface.
my $_tdbc_cache;

sub DEMOLISH {
    my $self = shift;
    if ($self->_did_create && !$Test::DBIC::SQLite::LeaveCreatedDatabases) {
        unlink($self->dbi_connect_info) if -e $self->dbi_connect_info;
    }
    $self->_set__did_create(0);
}

sub connect_dbic_sqlite_ok {
    my $class = __PACKAGE__;
    my %args = $class->validate_positional_parameters(
        [
            $class->parameter(schema_class      => $class->Required),
            $class->parameter(dbi_connect_info  => $class->Optional),
            $class->parameter(post_connect_hook => $class->Optional),
        ],
        \@_
    );

    # if one provides a post_connect_hook but undef for dbi_connect_info of
    # type Maybe[Str], the default cannot kick in.
    $args{dbi_connect_info} //= ':memory:';
    delete($args{post_connect_hook}) if @_ < 3;

    $_tdbc_cache = $class->new(%args);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $schema = $_tdbc_cache->connect_dbic_ok();

    return $schema;
}

sub drop_dbic_sqlite_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = $_tdbc_cache->drop_dbic_ok();

    undef($_tdbc_cache);

    return $result;
}

sub drop_dbic_ok {
    my $self = shift;
    my $dbname = $self->dbi_connect_info;
    my $msg = "$dbname DROPPED";

    if ($dbname ne ':memory:') {
        my $count = unlink($dbname);
        if (not $count) {
            $self->builder->diag("Could not unlink($dbname): $!");
            return $self->builder->ok(0, $msg);
        }
        $self->_set__did_create(0);
    }
    return $self->builder->ok(1, $msg);
}

sub MyDBD_connection_parameters {
    my $self = shift;
    $self->validate_positional_parameters(
        [
            $self->parameter(
                dbi_connect_info => $self->Required,
                { store => \my $db_name }
            ),
        ],
        \@_
    );

    return [ "dbi:SQLite:dbname=$db_name" ];
}

sub MyDBD_check_wants_deploy {
    my $self = shift;
    $self->validate_positional_parameters(
        [
            $self->parameter(
                connection_info => $self->Required,
                { store => \my $connection_params }
            )
        ],
        \@_
    );

    my ($db_name) = $connection_params->[0] =~ m{dbname=(.+)(?:;|$)};
    my $wants_deploy = $db_name eq ':memory:'
        ? 1
        : ((not -e $db_name) ? 1 : 0);

    $self->_set__did_create(1) if ($db_name ne ':memory:') && (not -e $db_name);

    return $wants_deploy;
}

around ValidationTemplates => sub {
    my $vt = shift;
    my $class = shift;

    use Types::Standard qw( ArrayRef Maybe Str );

    my $validation_templates = $class->$vt();
    return {
        %$validation_templates,
        dbi_connect_info => { type => Maybe[Str], default => ':memory:' },
        connection_info  => { type => ArrayRef },
    };
};

use namespace::autoclean 0.16;
1;

=pod

=head1 NAME

Test::DBIC::SQLite - Connect to and deploy a L<DBIx::Class::Schema> on SQLite

=head1 SYNOPSIS

The preferred way:

    #! perl -w
    use Test::More;
    use Test::DBIC::SQLite;

    my $t = Test::DBIC::SQLite->new(
        schema_class    => 'My::Schema',
        pre_deploy_hook => \&define_functions,
    );
    my $schema = $t->connect_dbic_ok();

    my $thing = $schema->resultset('MyTable')->search(
        { name    => 'Anything' },
        { columns => [ { ul_name   => \'uc_last(name)' } ] }
    )->first;
    is(
       $thing->get_column('ul_name'),
       'anythinG',
       "SELECT uc_last(name) AS ul_name FROM ...; works!"
    );

    $schema->storage->disconnect;
    $t->drop_dbic_ok();
    done_testing();

    # select uc_last('Stupid'); -- stupiD
    # these functions will only exist within this database connection
    sub define_functions {
        my ($schema) = @_;
        my $dbh = $schema->storage->dbh;
        $dbh->sqlite_create_function(
            'uc_last',
            1,
            sub { my ($str) = @_; $str =~ s{(.*)(.)$}{\L$1\U$2}; return $str },
        );
    }


The compatible with C<v0.01> way:

    #! perl -w
    use Test::More;
    use Test::DBIC::SQLite;
    my $schema = connect_dbic_sqlite_ok('My::Schema');
    ...
    drop_dbic_sqlite_ok();
    done_testing();

=head1 DESCRIPTION

This is a re-implementation of C<Test::DBIC::SQLite v0.01> that uses the
L<Moo::Role>: L<Test::DBIC::DBDConnector>.

It will C<import()> L<warnings> and L<strict> for you.

=head2 C<< Test::DBIC::SQLite->new >>

    my $t = Test::DBIC::SQLite->new(%parameters);
    my $schema = $t->connect_dbic_ok();
    ...
    $schema->storage->disconnect;
    $t->drop_dbic_ok();

=head3 Parameters

Named, list:

=over

=item B<< I<C<schema_class>> => C<$schema_class> >>(I<Required>)

The class name of the L<DBIx::Class::Schema> to use for the database connection.


=item B<< I<C<dbi_connect_info>> => C<$sqlite_dbname> >> (I<Optional>, C<:memory:>)

The default is B<C<:memory:>> which will create a temporary in-memory database.
One can also pass a file name for a database on disk. See
L<MyDBD_connection_parameters|/implementation-of-mydbd_connection_parameters>.


=item B<< I<C<pre_deploy_hook>> => C<$pre_deploy_hook> >> (I<Optional>)

This is an optional C<CodeRef> that will be executed right after the connection
is established but before C<< $schema->deploy >> is called. The CodeRef will
only be called if deploy is also needed. See
L<MyDBD_check_wants_deploy|/implementation-of-mydbd_check_wants_deploy>.


=item B<< I<C<post_connect_hook>> => C<$post_connect_hook> >> (I<Optional>)

This is an optional C<CodeRef> that will be executed right after deploy (if any)
and just before returning the schema instance. Useful for populating the
database.

=back

=head3 Returns

An initialised instance of C<Test::DBIC::SQLite>.

=head2 C<< $td->connect_dbic_ok >>

This method is inherited from L<Test::DBIC::DBDConnector>.

=head3 Returns

An initialised instance of C<$schema_class>.

=head2 C<< $td->drop_dbic_ok >>

This method implements C<< rm $dbname >>, in order not to litter your test
directory with left over test databases.

B<NOTE>: Make sure you called C<< $schema->storage->disconnect() >> first.

B<NOTE>: If the test-object goes out of scope without calling C<<
$td->drop_dbic_ok() >>, the destructor will try to remove the file. Use
C<$Test::DBIC::SQLite::LeaveCreatedDatabases = 1> to keep the file for
debugging.

=head2 C<connect_dbic_sqlite_ok(@parameters)>

Create a SQLite3 database and deploy a dbic_schema. This function is provided
for compatibility with C<v0.01> of this module.

See L<< Test::DBIC::SQLite->new|/Test::DBIC::SQLite->new >> for further information,
although only these 3 arguments are supported.

=head3 Parameters

Positional:

=over

=item 1. B<< C<$schema_class> >> (I<Required>)  

The class name of the L<DBIx::Class::Schema> to use for the database connection.

=item 2. B<< C<$sqlite_dbname> >> (I<Optional>, C<:memory:>)  

The default is B<C<:memory:>> which will create a temporary in-memory database.
One can also pass a file name for a database on disk. See L<MyDBD_connection_parameters|/implementation-of-mydbd_connection_parameters>.

=item 3. B<< C<$post_connect_hook> >> (I<Optional>)

This is an optional C<CodeRef> that will be executed right after deploy (if any)
and just before returning the schema instance. Useful for populating the
database.

=back

=head3 Returns

An initialised instance of C<$schema_class>.

=head2 C<drop_dbic_sqlite_ok()>

This function uses the cached information of the call to C<connect_dbic_sqlite_ok()>
and clears it after the database is dropped, using another temporary connection
to the template database.

See L<the C<drop_dbic_ok()> method|/"-td-drop_dbic_ok">.

=head2 Implementation of C<MyDBD_connection_parameters>

The value of the C<dbi_connect_info> parameter to the `new()`
constructor, is passed to this method. For this I<SQLite3> implementation this is a
single string that should contain the name of the database on disk, that can be
accessed with C<sqlite3 (1)>. By default we use the "special" value of
B<C<:memory:>> to create a temporary in-memory database.

This method returns a list of parameters to be passed to
C<< DBIx::Class::Schema->connect() >>. Keep in mind that the last argument
(options-hash) will always be augmented with key-value pair: C<< ignore_version => 1 >>.

=head3 Note

At this moment we do not support the C<uri=file:$db_file_name?mode=rwc> style of
I<dsn>, only the C<dbname=$db_file_name> style, as we only support
C<$sqlite_dbname> as a single parameter.


=head2 Implementation of C<MyDBD_check_wants_deploy>

For in-memory databases this will always return B<true>. For databases on disk
this will return B<true> if the file does not exist and B<false> if it does.

=begin devel_cover_pod

=head2 DEMOLISH

Remove created database files when the object goes out of scope.

=end devel_cover_pod

=head1 AUTHOR

E<copy> MMXV-MMXXI - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
