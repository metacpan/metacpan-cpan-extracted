package Search::Sitemap;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use Search::Sitemap::Types qw(
    SitemapUrlStore XMLPrettyPrintValue SitemapURL
);
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw( Str HashRef Bool ArrayRef CodeRef );
use Search::Sitemap::URL;
use XML::Twig;
use IO::File;
use Carp qw( carp croak );
use HTML::Entities qw( decode_entities );
use namespace::clean -except => 'meta';

has 'urls'  => (
    is      => 'ro',
    isa     => SitemapUrlStore,
    coerce  => 1,
    default => sub {
        Class::MOP::load_class( 'Search::Sitemap::URLStore::Memory' );
        return Search::Sitemap::URLStore::Memory->new;
    },
    handles => {
        get_url     => 'get',
        put_url     => 'put',
        put_urls    => 'put',
        find_url    => 'find',
    },
);

has 'pretty'    => (
    is      => 'rw',
    isa     => XMLPrettyPrintValue,
    coerce  => 1,
    default => 'none',
);

class_has 'base_element'    => (
    is          => 'rw',
    isa         => Str,
    default     => 'urlset'
);

has 'xmlparser' => (
    is      => 'rw',
    isa     => 'XML::Twig',
    lazy    => 1,
    default => sub {
        my $self = shift;

        XML::Twig->new(
            twig_roots  => {
                $self->base_element => sub {
                    my ( $twig, $elt ) = @_;
                    foreach my $c ( $elt->children ) {
                        my %url = ();
                        my $var = $c->gi;
                        croak "Unrecognised element $var"
                            unless $var =~ /^(?:url|sitemap)$/;
                        foreach my $e ( $c->children ) {
                            $url{ $e->gi } = decode_entities( $e->text );
                        }
                        $self->update( \%url );
                    }
                    $twig->purge;
                },
            },
        );
    },
    handles => [qw( safe_parse )],
);

has 'have_zlib' => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        local $@;
        eval { Class::MOP::load_class( 'IO::Zlib' ) };
        return $@ ? 0 : 1;
    },
);

has 'extensions'    => ( is => 'ro', isa => HashRef, default => sub { {} } );

has 'xml_headers'   => ( is => 'rw', isa => HashRef, lazy_build => 1 );
sub _build_xml_headers {
    my $self = shift;
    my $ext = $self->extensions;
    return {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => join( ' ',
            'http://www.sitemaps.org/schemas/sitemap/0.9',
            'http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd',
        ),
        'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
        ( map { ( "xmlns:$_" => $ext->{ $_ } ) } keys %{ $ext } ),
    }
}

sub xml {
    my $self = shift;

    my $xml = XML::Twig::Elt->new(
        $self->base_element => $self->xml_headers,
        ( map {
            $_->as_elt( $self->url_type => $self->url_fields );
        } $self->urls->all ),
    );
    $xml->set_pretty_print( $self->pretty );
    my $header = '<?xml version="1.0" encoding="UTF-8"?>';
    if ( $self->pretty ) { $header .= "\n" }
    return $header.$xml->sprint();
}

class_has 'url_type'    => ( is => 'rw', isa => Str, default => 'url' );
class_has 'url_fields'  => (
    is          => 'rw',
    isa         => ArrayRef[Str],
    auto_deref  => 1,
    default     => sub { [qw( loc lastmod changefreq priority )] }
);

sub BUILD {
    my ( $self, $args ) = @_;

    $self->urls->add_trigger( put => sub {
        my $self = shift;
        return if $self->extensions->{ 'mobile' };
        for my $url ( @_ ) {
            if ( $url->has_mobile && $url->mobile ) {
                $self->extensions->{ 'mobile' } = 'http://www.google.com/schemas/sitemap-mobile/1.0';
                return;
            }
        }
    } );
}

sub read {
    my ( $self, $file ) = @_;

    croak "No filename specified for ".ref( $self )."->read" unless $file;

    # don't try to parse missing or empty files
    # no errors for this, because we might be creating it
    return unless -f $file && -s _;

    # don't try to parse very small compressed files
    # (empty .gz files are 20 bytes)
    return if $file =~ /\.gz/ && -s $file < 50;

    if ( $file =~ /\.gz$/ ) {
        croak "IO::Zlib not available, cannot read compressed sitemaps"
            unless $self->have_zlib;
        $self->safe_parse( IO::Zlib->new( $file => "rb" ) );
    } else {
        $self->safe_parse( IO::File->new( $file => "r" ) );
    }
}

sub write {
    my ( $self, $file ) = @_;

    croak "No filename specified for ".ref( $self )."->write" unless $file;

    my $fh;
    if ( $file =~ /\.gz$/i ) {
        croak "IO::Zlib not available, cannot write compressed sitemaps"
            unless $self->have_zlib;
        $fh = IO::Zlib->new( $file => 'wb9' );
    } else {
        $fh = IO::File->new( $file => 'w' );
    }
    croak "Could not create '$file'" unless $fh;
    $fh->print( $self->xml );
}

sub update {
    my $self = shift;
    my $data = ( @_ == 1 ) ? shift : { @_ };
    my $loc = $data->{ 'loc' } or croak "Can't call ->update without 'loc'";
    if ( my $obj = $self->get_url( $loc ) ) {
        for my $key ( keys %{ $data } ) {
            next if $key eq 'loc';
            $obj->$key( $data->{ $key } );
        }
        return $obj;
    } else {
        my $obj = Search::Sitemap::URL->new( $data );
        $self->put_url( $obj );
        return $obj;
    }
}

sub add {
    my $self = shift;

    my @urls = ();
    if ( ref $_[0] ) {
        push( @urls, map { to_SitemapURL( $_ ) } @_ );
    } elsif ( $_[0] =~ m{://} ) {
        push( @urls, map { Search::Sitemap::URL->new( loc => $_ ) } @_ );
    } else {
        push( @urls, Search::Sitemap::URL->new( @_ ) );
    }
    $self->put_urls( @urls );
    return ( @urls == 1 ) ? $urls[0] : wantarray ? @urls : \@urls;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf-8

=head1 NAME

Search::Sitemap - Perl extension for managing Search Engine Sitemaps

=head1 SYNOPSIS

  use Search::Sitemap;
  
  my $map = Search::Sitemap->new();
  $map->read( 'sitemap.gz' );
  
  # Main page, changes a lot because of the blog
  $map->add( Search::Sitemap::URL->new(
    loc        => 'http://www.jasonkohles.com/',
    lastmod    => '2005-06-03',
    changefreq => 'daily',
    priority   => 1.0,
  ) );
  
  # Top level directories, don't change as much, and have a lower priority
  $map->add( {
    loc        => "http://www.jasonkohles.com/$_/",
    changefreq => 'weekly',
    priority   => 0.9, # lower priority than the home page
  } ) for qw(
    software gpg hamradio photos scuba snippets tools
  );
  
  $map->write( 'sitemap.gz' );

=head1 DESCRIPTION

The Sitemap Protocol allows you to inform search engine crawlers about URLs
on your Web sites that are available for crawling. A Sitemap consists of a
list of URLs and may also contain additional information about those URLs,
such as when they were last modified, how frequently they change, etc.

This module allows you to create and modify sitemaps.

=head1 METHODS

=head2 new()

Creates a new Search::Sitemap object.

  my $map = Search::Sitemap->new();

=head2 read( $file )

Read a sitemap in to this object.  Reading of compressed files is done
automatically if the filename ends with .gz.

=head2 write( $file )

Write the sitemap out to a file.  Writing of compressed files is done
automatically if the filename ends with .gz.

=head2 urls()

Return the L<Search::Sitemap::URLStore> object that make up the sitemap.

To get all urls (L<Search::Sitemap::URL> objects) please use:

    my @urls = $map->urls->all;

=head2 add( $item, [$item...] )

Add the L<Search::Sitemap::URL> items listed to the sitemap.

If you pass hashrefs instead of objects, it will turn them into objects for
you.  If the first item you pass is a simple scalar that matches \w, it will
assume that the values passed are a hash for a single object.  If the first
item passed matches m{^\w+://} (i.e. it looks like a URL) then all the
arguments will be treated as URLs, and L<Search::Sitemap::URL> objects will be
constructed for them, but only the loc field will be populated.

This means you can do any of these:

  # create the Search::Sitemap::URL object yourself
  my $url = Search::Sitemap::URL->new(
    loc => 'http://www.jasonkohles.com/',
    priority => 1.0,
  );
  $map->add($url);
  
  # or
  $map->add(
    { loc => 'http://www.jasonkohles.com/' },
    { loc => 'http://www.jasonkohles.com/software/search-sitemap/' },
    { loc => 'http://www.jasonkohles.com/software/geo-shapefile/' },
  );
  
  # or
  $map->add(
    loc       => 'http://www.jasonkohles.com/',
    priority  => 1.0,
  );
  
  # or even something funkier
  $map->add( qw(
    http://www.jasonkohles.com/
    http://www.jasonkohles.com/software/search-sitemap/
    http://www.jasonkohles.com/software/geo-shapefile/
    http://www.jasonkohles.com/software/text-fakedata/
  ) );
  foreach my $url ( $map->urls ) { $url->changefreq( 'daily' ) }

=head2 update

Similar to L</add>, but while L</add> will replace an existing object that
has the same URL, update will update the provided values.

As as example, if you do this:

    $map->add(
        loc         => 'http://www.example.com/',
        priority    => 1.0,
    );
    $map->add(
        loc         => 'http://www.example.com/',
        changefreq  => 'daily',
    );

The sitemap will end up containing this:

    <url>
        <loc>http://www.example.com</loc>
        <changefreq>daily</changefreq>
    </url>

But if instead you use update:

    $map->update(
        loc         => 'http://www.example.com/',
        priority    => 1.0,
    );
    $map->update(
        loc         => 'http://www.example.com/',
        changefreq  => 'daily',
    );

This sitemap will end up with this:

    <url>
        <loc>http://www.example.com</loc>
        <changefreq>daily</changefreq>
        <priority>1.0</priority>
    </url>

=head2 xml();

Return the xml representation of the sitemap.

=head2 pretty()

Set this to a true value to enable 'pretty-printing' on the XML output.  If
false (the default) the XML will be more compact but not as easily readable
for humans (Google and other computers won't care what you set this to).

If you set this to a 'word' (something that matches /[a-z]/i), then that
value will be passed to XML::Twig directly (see the L<XML::Twig> pretty_print
documentation).  Otherwise if a true value is passed, it means 'nice', and a
false value means 'none'.

Returns the value it was set to, or the current value if called with no
arguments.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/search-sitemap>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.
 
=head1 ACKNOWLEDGEMENTS

Thanks to Alex J. G. Burzyński for help with maintaining this module.

=head1 SEE ALSO

L<Search::Sitemap::Index>

L<Search::Sitemap::Ping>

L<Search::Sitemap::Robot>

L<http://www.jasonkohles.com/software/search-sitemap>

L<http://www.sitemaps.org/>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

