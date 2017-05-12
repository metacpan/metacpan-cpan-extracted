package CatalystX::Controller::OpenSearch;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Search::OpenSearch::Server::Catalyst';
with 'Search::OpenSearch::Server';

1;

__END__

=head1 NAME

CatalystX::Controller::OpenSearch - controller for Search::OpenSearch::Server::Catalyst

=head1 SYNOPSIS

 package MyApp::Controller::Search;
 use Moose;
 BEGIN { extends 'CatalystX::Controller::OpenSearch'; }
 1;

=head1 DESCRIPTION

This class is a controller consuming the Roles L<Search::OpenSearch::Server::Catalyst>
and L<Search::OpenSearch::Server>.

B<NOTE> The BEGIN block noted in the SYNOPSIS is important for compatability with Moose Roles
and Catalyst controller method attributes.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server::Catalyst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Server/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
