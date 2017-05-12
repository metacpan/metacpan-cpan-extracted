package Report::Generator::Render;

use warnings;
use strict;

use Carp qw(croak);

=head1 NAME

Report::Generator::Render - base class for rendering reports

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

This module is not intended to be used directly.

=head1 DESCRIPTION

C<Report::Generator::Render> provides an abstract base class for rendering
reports in L<Report::Generator>.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new
{
    my ( $proto, $attr ) = @_;

    # XXX some checks might be required here ...

    my $self = bless( $attr, $proto );

    return $self;
}

=head2 render

Routine called to render the output. Must return a true value on success
or set C<< $self->{error} >> otherwise.

=cut

sub render { croak "Abstract " . __PACKAGE__ . "::render called"; }

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-report-generator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Report-Generator>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Report::Generator::Render

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Report-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Report-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Report-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Report-Generator/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Report::Controller
