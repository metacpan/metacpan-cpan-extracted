package Search::Sitemap::URL;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw( Bool );
use MooseX::Types::URI qw( Uri );
use Search::Sitemap::Types qw(
    SitemapChangeFreq SitemapLastMod SitemapPriority
);
use XML::Twig qw();
use POSIX qw( strftime );
use HTML::Entities qw( encode_entities );
use Scalar::Util qw( blessed );
use namespace::clean -except => 'meta';

class_has 'encode_entities'   => (
    is      => 'rw',
    isa     => Bool,
);

class_has 'lenient'           => (
    is      => 'rw',
    isa     => Bool,
);

has 'loc'           => (
    is          => 'rw',
    isa         => Uri,
    coerce      => 1,
    predicate   => 'has_loc',
    clearer     => 'clear_loc',
);
has 'changefreq'    => (
    is          => 'rw',
    isa         => SitemapChangeFreq,
    coerce      => 1,
    predicate   => 'has_changefreq',
    clearer     => 'clear_changefreq',
);
has 'lastmod'       => (
    is          => 'rw',
    isa         => SitemapLastMod,
    coerce      => 1,
    predicate   => 'has_lastmod',
    clearer     => 'clear_lastmod',
);
has 'priority'      => (
    is          => 'rw',
    isa         => SitemapPriority,
    coerce      => 1,
    predicate   => 'has_priority',
    clearer     => 'clear_priority',
);
has 'mobile'        => (
    is          => 'rw',
    isa         => Bool,
    predicate   => 'has_mobile',
    clearer     => 'clear_mobile',
);

sub _loc_as_elt {
    my $self = shift;
    return unless $self->has_loc;
    my $loc = XML::Twig::Elt->new(
        '#PCDATA' => encode_entities( $self->loc->as_string )
    );
    $loc->set_asis( 1 );
    return $loc;
}

sub _mobile_as_elt {
    my $self = shift;
    return unless $self->mobile;
    return XML::Twig::Elt->new( 'mobile', namespace => 'mobile' );
}

sub as_elt {
    my ( $self, $type, @fields ) = @_;

    $type ||= 'url';
    unless ( @fields ) { @fields = qw( loc changefreq lastmod priority ) }

    my @elements = ();
    for my $f ( @fields ) {
        my $exists = $self->can( "has_$f" );
        next if $exists and not $self->$exists;

        my $method = '_'.$f.'_as_elt';
        my $val;
        if ( $self->can( $method ) ) {
            $val = $self->$method();
        } else {
            $val = XML::Twig::Elt->new( '#PCDATA' => $self->$f() );
        }
        next unless $val;
        next unless blessed $val;
        next unless $val->isa( 'XML::Twig::Elt' );
        push( @elements, $val->wrap_in( $f ) );
    }
    return XML::Twig::Elt->new( $type, {}, @elements );
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::URL - URL Helper class for Search::Sitemap

=head1 SYNOPSIS

  use Search::Sitemap;

=head1 DESCRIPTION

This is a helper class that supports L<Search::Sitemap> and
L<Search::Sitemap::Index>.

=head1 METHODS

=head2 new()

=head2 loc()

Change the URL associated with this object.  For a L<Search::Sitemap> this
specifies the URL to add to the sitemap, for a L<Search::Sitemap::Index>, this
is the URL to the sitemap.

=head2 changefreq()

Set the change frequency of the object.  This field is not used in sitemap
indexes, only in sitemaps.

=head2 lastmod()

Set or retrieve the last modified time.  This will return a L<DateTime>
object.  When setting it, you can provide any of these types of values:

=over 4

=item a complete ISO8601 time string

A complete time string will be accepted in exactly this format:

  YYYY-MM-DDTHH:MM:SS+TZ:TZ

  YYYY   - 4-digit year
  MM     - 2-digit month (zero padded)
  DD     - 2-digit year (zero padded)
  T      - literal character 'T'
  HH     - 2-digit hour (24-hour, zero padded)
  SS     - 2-digit second (zero padded)
  +TZ:TZ - Timezone offset (hours and minutes from GMT, 2-digit, zero padded)

=item epoch time

Seconds since the epoch, such as would be returned from time().  If you provide
an epoch time, then an appropriate ISO8601 time will be constructed with
gmtime() (which means the timezone offset will be +00:00).

=item an ISO8601 date (YYYY-MM-DD)

A simple date in YYYY-MM-DD format.

=item a L<DateTime> object.

If a L<DateTime> object is provided, then an appropriate timestamp will be
constructed from it.

=item a L<HTTP::Response> object.

If given an L<HTTP::Response> object, the last modified time will be
calculated from whatever time information is available in the response
headers.  Currently this means either the Last-Modified header, or the
current time - the current_age() calculated by the response object.
This is useful for building web crawlers.

=item a L<File::stat> object.

If given a L<File::stat> object, the last modified time will be set from
L<File::stat/mtime>.

=item a L<Path::Class::File> object.

If given a L<Path::Class::File> object, the last modified time will be set
to the mtime of the referenced file.

=back

Note that in order to conserve memory, any of these items that you provide
will be converted to a complete ISO8601 time string when they are stored.
This means that if you pass an object to lastmod(), you can't get it back
out.  If anyone actually has a need to get the objects back out, then I
might make a configuration option to store the objects internally.

If you have suggestions for other types of date/time objects or formats
that would be useful, let me know and I'll consider them.

=head2 priority()

Get or set the priority.  This field is not used in sitemap indexes, only in
sitemaps.

=head2 mobile()

Set to a true value if this URL refers to a page that is intended for mobile
devices.  This will affect how some search engines index the URL.

For more information on mobile sitemaps, see
L<http://www.google.com/support/webmasters/bin/answer.py?answer=34627>

=head2 as_elt

Returns this URL and it's associated data as an L<XML::Twig::Elt> object.
This is primarily an internal use method, you probably don't need to mess
with it.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/search-sitemap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Search::Sitemap>

L<Search::Sitemap::Index>

L<Search::Sitemap::Ping>

L<http://www.jasonkohles.com/software/search-sitemap/>

L<http://www.sitemaps.org/>

L<http://www.google.com/support/webmasters/bin/answer.py?answer=34648>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

