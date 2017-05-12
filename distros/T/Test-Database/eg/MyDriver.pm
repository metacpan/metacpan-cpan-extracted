package Test::Database::Driver::MyDriver;
use strict;
use warnings;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

# uncomment only if your database engine is file-based
#sub is_filebased {1}

sub _version {
    # return a version string
}

sub dsn {
    my ($self, $dbname) = @_;
    # return a dsn for $dbname
}

# this routine has a default implementation for file-based database engines
sub create_database {
    my ( $self, $dbname, $keep ) = @_;
    $dbname = $self->available_dbname() if !$dbname;

    # create the database if it doesn't exist
    # ...

    # return the handle
    return Test::Database::Handle->new(
        dsn      => $self->dsn($dbname),
        name     => $dbname,
        driver   => $self,
        # ... other fields, like username, password
    );
}

sub drop_database {
    my ( $self, $dbname ) = @_;

    # drop the database
}

# this routine has a default implementation for file-based database engines
sub databases {
    my ($self) = @_;
    # return the names of all databases existing in this driver
}

'MyDriver';

__END__

=head1 NAME

Test::Database::Driver::MyDriver - A Test::Database driver for MyDriver

=head1 SYNOPSIS

    use Test::Database;
    my @handles = Test::Database->handles( 'MyDriver' );

=head1 DESCRIPTION

This module is the C<Test::Database> driver for C<DBD::MyDriver>.

=head1 SEE ALSO

L<Test::Database::Driver>

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2009 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

