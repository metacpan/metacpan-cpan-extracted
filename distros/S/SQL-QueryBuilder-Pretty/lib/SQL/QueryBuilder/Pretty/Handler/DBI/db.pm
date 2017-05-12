#!/usr/bin/perl 
package SQL::QueryBuilder::Pretty::Handler::DBI::db;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $class = shift;
    my %self  = @_;

    my $database = $self{'handler'}->{'Driver'}->{'Name'};

    $class = CORE::join( q{::}, $class, $database );
    eval "use $class; 1" or croak $@;
    return $class->new( %self );
} 

=head1 NAME

SQL::QueryBuilder::Pretty::Handler::DBI::db - DBI handler extension for 
SQL::QueryBuilder::Pretty.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Directly: 

    use SQL::QueryBuilder::Pretty::Handler::DBI::db;

    my $pretty = SQL::QueryBuilder::Pretty::Handler::DBI::db->new();

    print $pretty->print('SELECT * FROM table WHERE col1 = NOW()');

or indirecly using SQL::QueryBuilder::Pretty:

    use SQL::QueryBuilder::Pretty;

    my $pretty = SQL::QueryBuilder::Pretty->new(
        '-handler' => $dbh,
    );

    print $pretty->print('SELECT * FROM table WHERE col1 = NOW()');

=head1 DESCRIPTION

L<DBI> handler extension for SQL::QueryBuilder::Pretty.

=over 4

=item I<PACKAGE>->new(I<%options>)

Initializes the object.

=back

=head1 SEE ALSO

L<SQL::QueryBuilder::Pretty>, L<DBI>.

=head1 AUTHOR

André Rivotti Casimiro, C<< <rivotti at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by André Rivotti Casimiro. Published under the terms of 
the Artistic License 2.0.

=cut

1;
