package Stewbeef::TestModule;

use 5.006;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(
  hello_world
);

=head1 NAME

Stewbeef::TestModule - Stewbeef's test module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  my $greeting = hello_world();

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 hello_world

  my $greeting = hello_world();

Returns the string 'hello world'.

=cut

sub hello_world { 'hello world' }

=head1 AUTHOR

Michael Stewart, C<< <mstewart at stewdev.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-stewbeef-testmodule at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Stewbeef-TestModule>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Stewbeef::TestModule


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Stewbeef-TestModule>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Stewbeef-TestModule>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Stewbeef-TestModule>

=item * Search CPAN

L<https://metacpan.org/release/Stewbeef-TestModule>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Michael Stewart.

This is free software, licensed under:

  The MIT (X11) License


=cut

1;
