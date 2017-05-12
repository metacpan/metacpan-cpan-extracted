package Test::Database::Driver::Pg;
$Test::Database::Driver::Pg::VERSION = '1.113';
use strict;
use warnings;
use Carp;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

sub _version {
    DBI->connect_cached( $_[0]->connection_info() )
        ->selectcol_arrayref('SELECT VERSION()')->[0] =~ /^PostgreSQL (\S+)/;
    return $1;
}

sub create_database {
    my ($self) = @_;
    my $dbname = $self->available_dbname();

    DBI->connect_cached( $self->connection_info() )
        ->do( "CREATE DATABASE $dbname"
            . ( $self->{template} ? " TEMPLATE $self->{template}" : '' ) );

    # return the handle
    return Test::Database::Handle->new(
        dsn      => $self->dsn($dbname),
        name     => $dbname,
        username => $self->username(),
        password => $self->password(),
        driver   => $self,
    );
}

sub drop_database {
    my ( $self, $dbname ) = @_;

    DBI->connect_cached( $self->connection_info() )
        ->do("DROP DATABASE $dbname")
        if grep { $_ eq $dbname } $self->databases();
}

sub databases {
    my ($self)    = @_;
    my $basename  = qr/^@{[$self->_basename()]}/;
    my $databases = eval {
        DBI->connect_cached( $self->connection_info(), { PrintError => 0 } )
            ->selectall_arrayref(
            'SELECT datname FROM pg_catalog.pg_database');
    };
    return grep {/$basename/} map {@$_} @$databases;
}

'Pg';

__END__

=head1 NAME

Test::Database::Driver::Pg - A Test::Database driver for Pg

=head1 SYNOPSIS

    use Test::Database;
    my @handles = Test::Database->handles( 'Pg' );

=head1 DESCRIPTION

This module is the L<Test::Database> driver for L<DBD::Pg>.

=head1 EXTRA PARAMETERS

This driver understands the following extra parameters in the configuration
file:

=over 4

=item template

The template to use when creating a new database.

=back

=head1 SEE ALSO

L<Test::Database::Driver>

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

