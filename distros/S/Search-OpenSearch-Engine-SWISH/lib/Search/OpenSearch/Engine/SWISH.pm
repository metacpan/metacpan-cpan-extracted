package Search::OpenSearch::Engine::SWISH;

use warnings;
use strict;
use Carp;
use base qw( Search::OpenSearch::Engine );
use SWISH::Prog::Native::Searcher;

our $VERSION = '0.04';

sub init_searcher {
    my $self     = shift;
    my $index    = $self->index or croak "index not defined";
    my $searcher = SWISH::Prog::Native::Searcher->new( invindex => $index );
    return $searcher;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Engine::SWISH - Swish-e 2.x server with OpenSearch results

=head1 SYNOPSIS


=head1 METHODS

=head2 init_searcher

Returns a SWISH::Prog::Native::Searcher object.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-engine-swish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Engine-SWISH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Engine::SWISH


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Engine-SWISH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Engine-SWISH>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Engine-SWISH>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Engine-SWISH/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
