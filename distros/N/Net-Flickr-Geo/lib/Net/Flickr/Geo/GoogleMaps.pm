use strict;
# $Id: GoogleMaps.pm,v 1.16 2008/01/28 06:38:28 asc Exp $

package Net::Flickr::Geo::GoogleMaps;
use base qw (Net::Flickr::Geo);

$Net::Flickr::Geo::GoogleMaps::VERSION = '0.72';

=head1 NAME

Net::Flickr::Geo::GoogleMaps - tools for working with geotagged Flickr photos and Google! Maps

=head1 SYNOPSIS

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::GoogleMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'info'));

 my @map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 print Dumper(\@map);

 # returns :
 # ['/tmp/GGsf4552h.jpg', '99999992'];

=head1 DESCRIPTION

Tools for working with geotagged Flickr photos and Google! Maps

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

Default is 512.

=item * B<map_width>

The width of the background map on which the pinwin/thumbnail will be
placed.

Default is 512.

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

=head2 google

=over 4

=item * B<api_key>

A valid Google! developers API key.

=item * B<map_type>

Specify the map format, returned by the Google Maps API.

=over 4

=item * B<roadmap>

Standard maps.google.com map tiles.

=item * B<mobile>

Map tiles optimized for viewing on mobile devices.

=back

Default is I<roadmap>

=back

=cut

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

Fetch a map using the Google! Map Image API for a geotagged Flickr photo
and place a "pinwin" style thumbnail of the photo over the map's marker.

Returns an array of arrays  (kind of pointless really, but at least consistent).

The first element of the (second-level) array will be the path to the newly created map
image. If uploads are enabled the newly created Flickr photo ID will be
passed as the second element.

=cut

# Defined in Net::Flickr::Geo

=head2 $obj->mk_pinwin_maps_for_photoset($photoset_id)

For each geotagged photo in a set, fetch a map using the Google! Map
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

        my $api_key = $self->divine_option("google.api_key");
        my $map_type = $self->divine_option("google.map_type", "roadmap");

        my $h = $self->divine_option("pinwin.map_height", 512);
        my $w = $self->divine_option("pinwin.map_width", 512);

        if (($h > 512) || ($w > 512)){
                $self->log()->error("Static Google maps may only be 512 pixels (or less) tall or wide");
        }

        my %args = (
                    'center' => join(",", $lat, $lon),
                    'size' => join("x", $w, $h),
                    'key' => $api_key,
                    'zoom' => $acc,
                    'map_type' => $map_type,
                   );

        my $uri = URI->new("http://maps.google.com");
        $uri->path("staticmap");
        $uri->query_form(%args);

        my $url = $uri->as_string();        
        $self->log()->info("fetch google maps : $url");

        my $ua  = LWP::UserAgent->new();
        my $req = HTTP::Request->new(GET => $url);
        my $res = $ua->request($req);

        my $path = $self->simple_get($url, $self->mk_tempfile(".png"));

	if (! -f $path){
		return undef;
	}

        return {
                'url' => $url,
                'path' => $path,
               };
}

=head1 VERSION

0.72

=head1 DATE

$Date: 2008/01/28 06:38:28 $

=head1 AUTHOR

Aaron Straup Cope  E<lt>ascope@cpan.orgE<gt>

=head1 REQUIREMENTS

B<Sadly, this still requires that you have a command-line version of ImageMagick installed
to have the pinwin marker successfully composited on to the map.>

The transparency is otherwise not honoured by either I<GD> or I<Imager>. Please for your
patches or cluebats...

=head1 NOTES

All uploads to Flickr are marked with a content-type of "other".

=head1 SEE ALSO

L<Net::Flickr::Geo>

L<http://code.google.com/apis/maps/documentation/staticmaps/index.html>

=head1 BUGS

Sure, why not.

Please report all bugs via L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2007-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
