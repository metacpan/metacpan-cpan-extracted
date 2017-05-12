use strict;
# $Id: MultiMaps.pm,v 1.8 2008/08/03 17:08:40 asc Exp $

package Net::Flickr::Geo::MultiMaps;
use base qw (Net::Flickr::Geo);

$Net::Flickr::Geo::MultiMaps::VERSION = '0.72';

=head1 NAME

Net::Flickr::Geo::MultiMaps - tools for working with geotagged Flickr photos and Yahoo! Maps

=head1 SYNOPSIS

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::MultiMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'info'));

 my @map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 print Dumper(\@map);

 # returns :
 # ['/tmp/GGsf4552h.jpg', '99999992'];

=head1 DESCRIPTION

Tools for working with geotagged Flickr photos and MultiMapss

=cut

=head1 OPTIONS

Options are passed to Net::Flickr::Backup using a Config::Simple object or
a valid Config::Simple config file. Options are grouped by "block".

=head2 flickr

=over 4

=item * B<api_key>

String. I<required>

A valid Flickr API key.

=item * B<api_secret>

String. I<required>

A valid Flickr Auth API secret key.

=item * B<auth_token>

String. I<required>

A valid Flickr Auth API token.

The B<api_handler> defines which XML/XPath handler to use to process API responses.

=over 4 

=item * B<LibXML>

Use XML::LibXML.

=item * B<XPath>

Use XML::XPath.

=back

=back

=head2 pinwin

=item * B<map_height>

The height of the background map on which the pinwin/thumbnail will be
placed.

Default is 1024.

=item * B<map_width>

The width of the background map on which the pinwin/thumbnail will be
placed.

Default is 1024.

=item * B<upload>

Boolean.

Automatically upload newly create map images to Flickr. Photos will be tagged with the following machine tags :

=over 4

=item * B<flickr:photo=photo_id>

Where I<photo_id> is the photo that has been added to the map image.

=item * B<flickr:map=pinwin>

=back

Default is false.

=item * B<upload_public>

Boolean.

Mark pinwin uploads to Flickr as viewable by anyone.

Default is false.

=item * B<upload_friend>

Boolean.

Mark pinwin uploads to Flickr as viewable only by friends.

Default is false.

=item * B<upload_family>

Boolean.

Mark pinwin uploads to Flickr as viewable only by family.

Default is false.

=item * B<zoom>

Int.

By default, the object will try to map the (Flickr) accuracy to the corresponding
zoom level of the Modest Maps provider you have chosen. If this option is defined
then it will be used as the zoom level regardless of what Flickr says.

=item * B<skip_photos>

Int (or array reference of ints)

Used by I<photoset> related object methods, a list of photos to exclude from the list
returned by the Flickr API.

=item * B<skip_tags>

String (or array reference of strings)

Used by I<photoset> related object methods, a list of tags that all photos must B<not> have if
they are to be included in the final output.

=item * B<ensure_tags>

String (or array reference of strings)

Used by I<photoset> related object methods, a list of tags that all photos must have if
they are to be included in the final output.

=head2 multimap

=over 4

=item * B<appid>

A valid MultiMaps developers API key.

=back

=cut

use GD;
use FileHandle;
use File::Temp qw (tempfile);

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Returns a I<Net::Flickr::Geo> object.

=cut

# Defined in Net::Flickr::API

=head1 OBJECT METHODS

=cut

=head2 $obj->mk_pinwin_map_for_photo($photo_id)

Fetch a map using the MultiMaps Image API for a geotagged Flickr photo
and place a "pinwin" style thumbnail of the photo over the map's marker.

Returns an array of arrays  (kind of pointless really, but at least consistent).

The first element of the (second-level) array will be the path to the newly created map
image. If uploads are enabled the newly created Flickr photo ID will be
passed as the second element.

=cut

# Defined in Net::Flickr::Geo

=head2 $obj->mk_pinwin_maps_for_photoset($photoset_id)

For each geotagged photo in a set, fetch a map using the Yahoo! Map
Image API for a geotagged Flickr photo and place a "pinwin" style
thumbnail of the photo over the map's marker.

If uploads are enabled then each map for a given photo will be
added such that it appears before the photo it references.

Returns an array of arrays.

The first element of each (second-level) array reference will be the path to the newly
created map image. If uploads are enabled the newly created Flickr photo
ID will be passed as the second element.

=cut

# Defined in Net::Flickr::Geo

sub fetch_map_image {
        my $self = shift;
        my $ph = shift;
        my $thumb_data = shift;

        my $lat = $self->get_geo_property($ph, "latitude");
        my $lon = $self->get_geo_property($ph, "longitude");
        my $acc = $self->get_geo_property($ph, "accuracy");

        if ((! $lat) || (! $lon)){
                return undef;
        }

        # 

        my $api_key = $self->divine_option("multimap.api_key");

        my $h = $self->divine_option("pinwin.map_height", 1024);
        my $w = $self->divine_option("pinwin.map_width", 1024);

        # 

        my %args = (
                    'lat' => $lat,
                    'lon' => $lon,
                    'zoomFactor' => $acc,
                    'width' => $w,
                    'height' => $h,
                   );

        my $uri = URI->new("http://developer.multimap.com");
        $uri->path("API/map/1.2/" . $api_key);
        $uri->query_form(%args);

        my $url = $uri->as_string();        
        $self->log()->info("fetch multimap : $url");

        #

        my $path = $self->simple_get($url, $self->mk_tempfile(".png"));

        return {
                'url' => $url,
                'path' => $path,
               };
}

=head1 VERSION

0.72

=head1 DATE

$Date: 2008/08/03 17:08:40 $

=head1 AUTHOR

Aaron Straup Cope  E<lt>ascope@cpan.orgE<gt>

=head1 REQUIREMENTS

B<Sadly, this still requires that you have a command-line version of ImageMagick installed
to have the pinwin marker successfully composited on to the map.>

The transparency is otherwise not honoured by either I<GD> or I<Imager>. Please for your
patches or cluebats...

=head1 NOTES

This still needs some loving to hide the MultiMap markers that are included with the map
image. It's on the list...

All uploads to Flickr are marked with a content-type of "other".

=head1 SEE ALSO

L<Net::Flickr::Geo>

L<http://www.multimap.com/share/documentation/openapi/1.2/web_service/staticmaps.htm>

=head1 BUGS

Sure, why not.

Please report all bugs via L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2007-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
