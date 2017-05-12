package Search::Sitemap::Index;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
extends 'Search::Sitemap';
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw( ArrayRef );
use Search::Sitemap::Types qw( SitemapURL XMLPrettyPrintValue );
use namespace::clean -except => 'meta';

class_has '+base_element' => ( default => 'sitemapindex' );
class_has '+url_type'   => ( default => 'sitemap' );
class_has '+url_fields' => ( default => sub { [qw( loc lastmod )] } );

around '_build_xml_headers' => sub {
    my $next = shift;
    my $headers = $next->( @_ );
    $headers->{ 'xsi:schemaLocation' } =~ s/sitemap\.xsd$/siteindex.xsd/;
    return $headers;
};

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::Index - Perl extension for managing Sitemap Indexes

=head1 SYNOPSIS

  use Search::Sitemap::Index;
  
  my $index = Search::Sitemap::Index->new();
  $index->read( 'sitemap-index.gz' );
  
  $index->add( Search::Sitemap::URL->new(
    loc     => 'http://www.jasonkohles.com/sitemap1.gz',
    lastmod => '2005-11-01',
  ) );

  $index->write( 'sitemap-index.gz' );
  
=head1 DESCRIPTION

A sitemap index is used to point search engines at your sitemaps if you have
more than one of them.

=head1 METHODS

L<Search::Sitemap::Index> inherits all the methods found in L<Search::Sitemap>.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/Search-Sitemap>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Search::Sitemap>

L<Search::Sitemap::Ping>

L<http://www.jasonkohles.com/software/Search-Sitemap>

L<http://www.sitemaps.org/>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

