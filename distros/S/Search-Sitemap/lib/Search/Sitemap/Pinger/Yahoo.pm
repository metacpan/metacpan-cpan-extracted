package Search::Sitemap::Pinger::Yahoo;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
extends 'Search::Sitemap::Pinger';
use namespace::clean -except => 'meta';

sub submit_url_for {
    my ( $self, $url ) = @_;
    my $submit = URI->new( 'http://search.yahooapis.com/SiteExplorerService/V1/ping' );
    $submit->query_form( sitemap => $url );
    return $submit;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::Pinger::Yahoo - Search::Sitemap::Pinger for Yahoo

=head1 SYNOPSIS

See L<Search::Sitemap::Ping>.

=head1 METHODS

=head2 submit_url_for( $url )

Given a url for a sitemap file, returns the URL that you need to use in a GET
request in order to submit the provided url to the Search Engine.

=head1 SEE ALSO

L<Search::Sitemap::Ping>

L<http://help.yahoo.com/l/us/yahoo/search/siteexplorer/manage/siteexplorer-45.html>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

L<http://www.jasonkohles.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

