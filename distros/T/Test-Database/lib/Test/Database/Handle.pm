package Test::Database::Handle;
$Test::Database::Handle::VERSION = '1.113';
use strict;
use warnings;
use Carp;
use DBI;

# basic accessors
for my $attr (qw( dbd dsn username password name driver )) {
    no strict 'refs';
    *{$attr} = sub { return $_[0]{$attr} };
}

sub new {
    my ( $class, %args ) = @_;

    exists $args{$_} or croak "$_ argument required"
       for qw( dsn );

    my ( $scheme, $driver, $attr_string, $attr_hash, $driver_dsn )
        = DBI->parse_dsn( $args{dsn} );

    # fix args
    %args = (
        %args,
        dbd => $driver,
    );

    # try to provide a Test::Database::Driver object
    if ( !exists $args{driver} ) {
        eval {
            $args{driver} = "Test::Database::Driver::$driver"->new(
                driver_dsn => $args{dsn},
                username   => $args{username},
                password   => $args{password},
            );
        };
    }

    return bless { %args }, $class;
}

sub connection_info { return @{ $_[0] }{qw( dsn username password )} }

sub dbh {
    my ( $self, $attr ) = @_;
    return $self->{dbh} ||= DBI->connect( $self->connection_info(), $attr );
}

'IDENTITY';

__END__

=head1 NAME

Test::Database::Handle - A class for Test::Database handles

=head1 SYNOPSIS

    use Test::Database;

    my $handle = Test::Database->handle(@requests);
    my $dbh    = $handle->dbh();

=head1 DESCRIPTION

Test::Database::Handle is a very simple class for encapsulating the
information about a test database handle.

Test::Database::Handle objects are used within a test script to
obtain the necessary information about a test database handle.
Handles are obtained through the C<< Test::Database->handles() >>
or C<< Test::Database->handle() >> methods.

=head1 METHODS

Test::Database::Handle provides the following methods:

=head2 new

Return a new Test::Database::Handle with the given parameters
(C<dsn>, C<username>, C<password>).

The only mandatory argument is C<dsn>.

=head1 ACCESSORS

The following accessors are available.

=head2 dsn

Return the Data Source Name.

=head2 username

Return the connection username. Defaults to C<undef>.

=head2 password

Return the connection password. Defaults to C<undef>.

=head2 connection_info

Return the connection information triplet (C<dsn>, C<username>, C<password>).

    my ( $dsn, $username, $password ) = $handle->connection_info;

=head2 dbh

    my $dbh = $handle->dbh;
    my $dbh = $handle->dbh( $attr );

Return the DBI database handle obtained when connecting with the
connection triplet returned by C<connection_info()>.

The optional parameter C<$attr> is a reference to a hash of connection
attributes, passed directly to DBI's C<connect()> method.

=head2 name

Return the database name attached to the handle.

=head2 dbd

Return the DBI driver name, as computed from the C<dsn>.

=head2 driver

Return the L<Test::Database::Driver> object attached to the handle.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

