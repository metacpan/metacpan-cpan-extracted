package SWISH::Prog::KSx::Results;
use strict;
use warnings;

our $VERSION = '0.21';

use base qw( SWISH::Prog::Results );
use SWISH::Prog::KSx::Result;

__PACKAGE__->mk_ro_accessors(qw( ks_hits ));

=head1 NAME

SWISH::Prog::KSx::Results - search results for Swish3 KinoSearch backend

=head1 SYNOPSIS

 # see SWISH::Prog::Results

=head1 DESCRIPTION

SWISH::Prog::KSx::Results is a KinoSearch-based Results
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Results> documentation.

=head2 next

Returns the next SWISH::Prog::KSx::Result object from the result set.

=cut

sub next {
    my $hit = $_[0]->ks_hits->next or return;
    return SWISH::Prog::KSx::Result->new(
        doc   => $hit,
        score => int( $hit->get_score * 1000 ),  # scale like xapian, swish-e
    );
}

=head2 ks_hits

Get the internal KinoSearch::Search::Hits object.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::KSx


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-KSx/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

