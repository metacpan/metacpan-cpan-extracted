use strict;
# $Id: ModestMaps.pm,v 1.63 2008/08/03 17:08:39 asc Exp $

package Net::Flickr::Geo::ModestMaps;
use base qw(Net::Flickr::Geo);

$Net::Flickr::Geo::ModestMaps::VERSION = '0.72';

=head1 NAME

Net::Flickr::Geo::ModestMaps - tools for working with geotagged Flickr photos and Modest Maps

=head1 SYNOPSIS

 my %opts = ();
 getopts('c:s:', \%opts);

 #
 # Defaults
 #

 my $cfg = Config::Simple->new($opts{'c'});

 #
 # Atkinson dithering is hawt but takes a really long
 # time...
 #

 $cfg->param("modestmaps.filter", "atkinson");
 $cfg->param("modestmaps.timeout", (45 * 60));

 #
 # Let's say all but one of your photos are in the center of
 # Paris and the last one is at the airport. If you try to render
 # a 'poster style' (that is all the tiles for the bounding box
 # containing those points at street level) map you will make 
 # your computer cry...
 #

 $cfg->param("pinwin.skip_photos", [506934069]);

 #
 # I CAN HAS MAPZ?
 #

 my $fl = Net::Flickr::Geo::ModestMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'info'));

 my $map_data = $fl->mk_poster_map_for_photoset($opts{'s'});

 #
 # returns stuff like :
 #
 # {
 #  'url' => 'http://127.0.0.1:9999/?provider=YAHOO_AERIAL&marker=yadda yadda yadda',
 #  'image-height' => '8528',
 #  'marker-484080715' => '5076,5606,4919,5072,500,375',
 #  'marker-506435771' => '5256,4768,5099,542,500,375',
 #  'path' => '/tmp/dkl0o7uxjY.jpg',
 #  'image-width' => '6656',
 # }
 #

 my $results = $fl->upload_poster_map($map_data->{'path'});

 #
 # returns stuff like :
 #
 # [
 #   ['/tmp/GGsf4552h.jpg', '99999992'],
 #   ['/tmp/kosfGgsfdh.jpg', '99999254'],
 #   ['/tmp/h354jF590.jpg', '999984643'],
 #   [ and so on... ] 
 # ];
 #

=head1 DESCRIPTION

Tools for working with geotagged Flickr photos and the Modest Maps ws-pinwin HTTP service.


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

=item * B<photo_size>

String.

The string label for the photo size to display, as defined by the flickr.photos.getSizes
API method : 

 http://www.flickr.com/services/api/flickr.photos.getSizes.html

Default is I<Medium>

=item * B<zoom>

Int.

By default, the object will try to map the (Flickr) accuracy to the corresponding
zoom level of the Modest Maps provider you have chosen. If this option is defined
then it will be used as the zoom level regardless of what Flickr says.

=item * B<crop_width>

Int.

Used by the I<crop_poster_map> (and by extension I<upload_poster_map>) object methods to
define the width of each slice taken from a poster map.

Default is 1771

=item * B<crop_height>

Int.

Used by the I<crop_poster_map> (and by extension I<upload_poster_map>) object methods to
define the height of each slice taken from a poster map.

Default is 1239

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

=head2 modestmaps

=over 4

=item * B<server>

The URL to a server running the ws-pinwin.py HTTP interface to the 
ModestMaps tile-creation service.

This requires Modest Maps 1.0 release or higher.

=item * B<provider>

A map provider and tile format for generating map images.

As of this writing, current providers are :

=over 4

=item * B<MICROSOFT_ROAD>

=item * B<MICROSOFT_AERIAL>

=item * B<MICROSOFT_HYBRID>

=item * B<GOOGLE_ROAD>

=item * B<GOOGLE_AERIAL>

=item * B<GOOGLE_HYBRID>

=item * B<YAHOO_ROAD>

=item * B<YAHOO_AERIAL>

=item * B<YAHOO_HYBRID>

=back 

=item * B<method>

Used only when creating poster maps, the method parameter defines how the underlying
map is generated. Valid options are :

=over 4

=item * B<extent>

Render map tiles at a suitable zoom level in order to fit the bounding
box (for all the images in a photoset) in an image with specific dimensions
(I<pinwin.map_height> and I<pinwin.map_width>).

=item * B<bbox>

Render all the map tiles necessary to display the bounding box (for all the
images in a photoset) at a specific zoom level.

=back

Default is bbox.

=item * B<bleed>

If true then extra white space will be added the underlying image in order to
fit any markers that may extend beyond the original dimensions of the map.

Boolean.

Default is true.

=item * B<adjust>

Used only when creating poster maps, the adjust parameter tells the modest maps server
to extend bbox passed by I<n> kilometers. This is mostly for esthetics so that there is
a little extra map love near pinwin located at the borders of a map.

Boolean.

Default is .25

=item * B<filter>

Tell the Modest Maps server to filter the rendered map image before applying an markers.
Valid options are :

=over 4

=item * B<atkinson>

Apply the Atkinson dithering filter to the map image.

This is brutally slow. Especially for poster maps. That's life.

=back

=item * B<timeout>

Int.

The number of seconds the object's HTTP handler will wait when requesting data from the 
Modest Maps server.

Default is 300 seconds.

=back

=cut

use Net::ModestMaps;
use Data::Dumper;
use FileHandle;
use GD;
use Imager;
use URI;

# for clustermaps 

use List::Util qw(min max);
use Date::Calc qw (Today Add_Delta_Days Delta_Days);
use Geo::Geotude;
use Geo::Distance;
use LWP::Simple;
use POSIX qw (ceil floor);
use Image::Size qw(imgsize);

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Returns a I<Net::Flickr::Geo> object.

=cut

# Defined in Net::Flickr::API

=head1 PINWIN MAPS

=cut

=head2 $obj->mk_pinwin_map_for_photo($photo_id)

Fetch a map using the Modest Maps ws-pinwin API for a geotagged Flickr photo
and place a "pinwin" style thumbnail of the photo over the map's marker.

Returns an array of arrays  (kind of pointless really, but at least consistent).

The first element of the (second-level) array will be the path to the newly created map
image. If uploads are enabled the newly created Flickr photo ID will be
passed as the second element.

=cut

# Defined in Net::Flickr::Geo

=head2 $obj->mk_pinwin_maps_for_photoset($photoset_id)

For each geotagged photo in a set, fetch a map using the Modest Maps
ws-pinwin API for a geotagged Flickr photo and place a "pinwin" style
thumbnail of the photo over the map's marker.

If uploads are enabled then each map for a given photo will be
added such that it appears before the photo it references.

Returns an array of arrays.

The first element of each (second-level) array reference will be the path to the newly
created map image. If uploads are enabled the newly created Flickr photo
ID will be passed as the second element.

=cut

# Defined in Net::Flickr::Geo

=head1 POSTER MAPS

=head2 $obj->mk_poster_map_for_photoset($set_id)

For each geotagged photo in a set, plot the latitude and longitude and
create a bounding box for the collection. Then fetch a map for that box
using the Modest Maps ws-pinwin API for a geotagged Flickr photo and place
a "pinwin" style thumbnail for each photo in the set.

Automatic uploads are not available for this method since the resultant
images will almost always be too big.

Returns a hash reference containing the URL that was used to request the
map image, the path to the data that was sent back as well as all of the
Modest Maps specific headers sent back.

=cut

sub mk_poster_map_for_photoset {
        my $self   = shift;
        my $set_id = shift;

        my $ph_size = $self->divine_option("pinwin.photo_size", "Medium");
        my $provider = $self->divine_option("modestmaps.provider");
        my $method = $self->divine_option("modestmaps.method", "bbox");
        my $bleed = $self->divine_option("modestmaps.bleed", 1);
        my $adjust = $self->divine_option("modestmaps.adjust", .25);
        my $filter = $self->divine_option("modestmaps.filter", );

        my $upload = $self->divine_option("pinwin.upload", 0);

        # 

        my $photos = $self->collect_photos_for_set($set_id);

        if (! $photos){
                return undef;
        }

        my $ne_lat = undef;
        my $ne_lon = undef;

        my $sw_lat = undef;
        my $sw_lon = undef;

        my %urls = ();
        my @markers = ();
        my @poly = ();

        foreach my $ph (@$photos){

                my $id = $ph->getAttribute("id");

                my $ph_url = $self->flickr_photo_url($ph);
                $urls{$id} = $ph_url;

                my $sz = $self->api_call({'method' => 'flickr.photos.getSizes',
                                          'args' => {'photo_id' => $id,}});
                
                my $sm = ($sz->findnodes("/rsp/sizes/size[\@label='$ph_size']"))[0];
                my $w = $sm->getAttribute("width");
                my $h = $sm->getAttribute("height");

                my $lat = $ph->getAttribute("latitude");
                my $lon = $ph->getAttribute("longitude");

                push @poly, "$lat,$lon";

                $sw_lat = min($sw_lat, $lat);
                $sw_lon = min($sw_lon, $lon);
                $ne_lat = max($ne_lat, $lat);
                $ne_lon = max($ne_lon, $lon);

                my %args = (
                            'uid' => $id,
                            'lat' => $lat,
                            'lon' => $lon,
                            'width' => $w,
                            'height' => $h,
                           );
                
                my $marker = Net::Flickr::Geo::ModestMaps::Marker->new(%args);
                push @markers, $marker;
        }

        my $bbox = "$sw_lat,$sw_lon,$ne_lat,$ne_lon";

        #
        # fetch the actual map
        #

        my $markers_prepped = Net::Flickr::Geo::ModestMaps::MarkerSet->prepare(\@markers);

        my %mm_args = (
                       'provider' => $provider,
                       'method' => $method,
                       'bleed' => $bleed,
                       'adjust' => $adjust,
                       'bbox' => $bbox,
                       'marker' => $markers_prepped,
                   );

        if ($method eq "extent"){
                $mm_args{'width'} = $self->divine_option("pinwin.map_width", 1024);
                $mm_args{'height'} = $self->divine_option("pinwin.map_height", 1024);
        }

        else {
                $mm_args{'zoom'} = $self->divine_option("modestmaps.zoom", 17);                
        }

        if ($filter){
                $mm_args{'filter'} = $filter;
        }

        if (my $convex = $self->divine_option("modestmaps.convex")){
                $mm_args{'convex'} = $convex;
        }

        $self->log()->info(Dumper(\%mm_args));

        my $map_data  = $self->fetch_modestmap_image(\%mm_args);
        
        if (! $map_data){
                return undef;
        }

        #
        # place the markers (please to refactor me...)
        # 

        my @images = ();

        foreach my $prop (%$map_data){

                if ($prop =~ /^marker-(.*)$/){

                        my $id = $1;
                        
                        my $ph_url = $urls{$id};
                        my $ph_img = $self->mk_tempfile(".jpg");
                        
                        if (! $self->simple_get($ph_url, $ph_img)){
                                next;
                        }

                        my @pw_details = split(",", $map_data->{$prop});
                        my $pw_x = $pw_details[2];
                        my $pw_y = $pw_details[3];
                        my $pw_w = $pw_details[4];
                        my $pw_h = $pw_details[5];

                        push @images, [$ph_img, $pw_x, $pw_y, $pw_w, $pw_h];
                }
        }

        my $out = $self->place_marker_images($map_data->{'path'}, \@images);
        $map_data->{'path'} = $out;

	return $map_data;
}

=head2 $obj->upload_poster_map($poster_map)

Take a file created by the I<mk_poster_map_for_photoset> and chop it up
in "postcard-sized" pieces and upload each to Flickr.

Returns an array of arrays.

The first element of the (second-level) array will be the path to the newly created map
image. If uploads are enabled the newly created Flickr photo ID will be
passed as the second element.

=cut

sub upload_poster_map {
        my $self = shift;
        my $map = shift;

        my $slices = $self->crop_poster_map($map);
        my @res = shift;

        foreach my $img (@$slices){

                my %args = ('photo' => $img);
                my $id = $self->upload_image(\%args);
                
                push @res, [$img, $id];
                unlink($img);
        }

        return \@res;
}

=head2 $obj->crop_poster_map($poster_map)

Take a file created by the I<mk_poster_map_for_photoset> and chop it up
in "postcard-sized" pieces.

The height and width of each piece are defined by the I<pinwin.crop_width> and
I<pinwin.crop_height> config options.

Any image whose cropping creates a file smaller than either dimension will
be padded with extra (white) space.

Returns a list of files.

=cut

sub crop_poster_map {
        my $self = shift;
        my $map = shift;

        my $crop_width = $self->divine_option("pinwin.crop_width", 1771);
        my $crop_height = $self->divine_option("pinwin.crop_width", 1239);

        my $offset_x = 0;
        my $offset_y = 0;

        my @slices = ();

        my $im = Imager->new();
        $im->read('file' => $map);

        my $map_h = $im->getheight();
        my $map_w = $im->getwidth();

        while ($offset_x < $map_w) {

                while ($offset_y < $map_h) {

                        my $x = $offset_x;
                        my $y = $offset_y;

                        my $slice = $im->crop('left' => $x, 'top' => $y, 'width' => $crop_width, 'height' => $crop_height);

			my $h = $slice->getheight();
                        my $w = $slice->getwidth();
                        
                        if (($h < $crop_height) || ($w < $crop_width)){

                                my $canvas = Imager->new('xsize' => $crop_width, 'ysize' => $crop_height);
                                $canvas->box('color' => 'white', 'xmin' => 0, 'ymin' => 0, 'xmax' => $crop_width, 'ymax' => $crop_height, 'filled' => 1);
                                $canvas->paste('img' => $slice, 'left' => 0, 'top' => 0);
                                push @slices, $canvas;
                        }

                        else {
                        	push @slices, $slice;
	                }

                        $offset_y += $crop_height;
                }

                $offset_x += $crop_width;
                $offset_y = 0;
        }

        my @files = map {
                $self->write_jpeg($im);
        } @slices;

        return \@files;
}

=head1 CLUSTER MAPS

=head2 $obj->mk_cluster_maps_for_photo($photo_id)

Like poster maps, cluster maps plot many photos in multiple pinwins on a single
background map image. Unlike poster maps, where you explicitly list all the photos
to display (by specifying a photo set) cluster maps renders a single photo as its
principal focus with all the photos with in an (n) kilometer radius of the subject
photo.

Multiple photos sharing the same latitude and longitude are also clustered together
and rendered in a single pinwin, whose size and shape is relative to the square
root of the number of total photos. This helps, in densely photographed areas, to 
prevent cascading pinwins from rocketing off the map canvas trying to find a suitably
empty space to avoid overlapping other nearby pinwins.

As of this writing, all the surrounding photos are rendered using their 75x75 pixel
square thumbnail though this will be a user-configurable option in future releases. 
The principal photo size can still be set by assigning the I<pinwin.photo_size> config
variable (the default is I<Medium>).

Cluster maps are not a general purpose interface to the Flickr I<photos.search> 
method (yet) although there are some flags to limit search results to the principal
photo's owner or by one or more copyright licenses.

All (except B<method>, discussed below) the usual config options may be set for
cluster maps. In addition, you may also define the following options :

=over 4

=item * B<clustermap.radius>

Float.

The number of kilometers from I<$photo_id>'s lat/lon in which to perform a
radial query for other geotagged photos. 

Default is I<1>

=item * B<clustermap.offset>

Int.

The number of days on either side of I<$photo_id>'s "date taken" value with which
to limit the scope of the query.

Default is I<0>

=item * B<clustermap.only_photo_owner>

Boolean.

Limit all queries to include only photos uploaded by I<$photo_id>'s owner.

Default is I<true>

=item * B<clustermap.force_photo_owner>

Boolean.

Typically used when setting the I<photo_license> to ensure that nearby photos
uploaded by I<$photo_id>s owner are included. If true, this will cause the code
to execute the same search twice. The second query will remove any licensing 
restrictions and enforce that only photos owned by I<$photo_id>'s owner be
returned. The two result sets will then be merged and sorted by distance from
the center point.

(Ignored if the I<clustermap.only_photo_owner> is true.)

Default is I<false>

=item * B<photo_license>

String.

A comma-separated list of Flickr license IDs to limit the list of photos returned
by the I<photos.search> API method.

Default is none.

=item * B<clustermap.geo_perms>

String.

Post search, ensure that all the photos have a minimum set of geo permissions.

Valid options are : "public", "contact", "friend", "family", "friend or family" 
and "all".

Default is I<all>

=item * B<clustermap.max_photos>

Int.

Although the clustering of photos sharing the same latitude and longitude helps
cut down on number of pinwins the Modest Maps needs to figure out how to layout
on the background map, there is still an upper limit after which it (Modest Maps)
will simply give up.

The exact number is a little hard to say as it is usually a function of how closely
grouped any number of pinwins (clustered or not) are to each other. Anecdotally,
anything less than 100 is fine; less than 200 is a toss up; anything after that 
usually wakes the baby.

Default is I<100>

=item * B<clustermap.max_photos_per_group>

Int.

All of the clusters are grouped by their lat/lon position rounded off to three
decimal points. You can change this option to set the maximum number of photos
that can be contained in a single group.

Default is half the value of the I<clustermap.max_photos> parameter.

=back

If either the B<max_photos> or B<max_photos_per_group> is exceeded then another
search query is initiated, where the radial days offset from I<$photo_id>'s taken
date is reduced by 10%. If no offset value was set by the user then an initial
value of 365 is set (meaning that if there are still too many photos after the
second query it will be reset to 328 days and so on.)

Finally, all cluster maps assume the Modest Maps B<bbox> method. The bounding box
itself is calcluated using the photos further from the center and is adjusted (in
size) relative to distance between the south-west and north-east corners.

If the distance is less that 1km, the bounding box will be expanded by .25km; If
the distance is less than 1.5km, the bounding box will be expanded by .1km; If the
bounding is less than 2km, the bounding box will be expanded by .1km.

Returns a hash reference containing the URL that was used to request the
map image, the path to the data that was sent back as well as all of the
Modest Maps specific headers sent back.

Attribution for the photos is returned in a hash refernce whose key is labeled
I<attribution> and whose contents are a series of nested hashes mapping marker
IDs to owners and a list of photos for that marker. For example :

 $response = {
 	# lots of other stuff
        'marker-2561168539' => '1455,4189,1427,2065,75,75',
        'attribution' => {
        	'2366199422' => {
                	'foobar' => ['http://www.flickr.com/photos/foobar/999999'],
                 }
	 }
 }

=cut

sub mk_cluster_map_for_photo {
        my $self = shift;
        my $photo_id = shift;

        my ($ph, $ph_marker, $queries) = $self->mk_cluster_map_for_photo_base($photo_id);
        my ($markers, $bbox);

        # really ?

        if (scalar(@$queries) == 1){
                ($markers, $bbox) = $self->search_for_cluster_map($queries->[0]);
        }

        else {
                ($markers, $bbox) = $self->blended_search_for_cluster_map($queries);
        }

        # 

        unshift @{$markers}, $ph_marker;
	return $self->create_cluster_map($markers, $bbox);
}

=head2 $obj->mk_historical_cluster_map_for_photo($photo_id)

Historical cluster maps are similar to plain old cluster in nature, but not in
execution. Rather than doing a single query and showing whatever happens to be
closest to I<$photo_id> historical cluster maps rely on the code making two
calls to the photos.search each explicitly constrained by a date range.

The first query will ask for photos within (n) days of when the photo was taken;
the second query will ask for photos within (n) days of today.

The two result sets are then smushed together, sorted by distance to I<$photo_id>
and clustered in to groups. If the number of photos, or grouped photos, is too
high then each date range is reduced (the value of offset days is multiplied by 90%
and rounded down) and the process is repeated until everything fits.

Or something breaks.

Then we make a map!

All the same rules and options that apply for plain old cluster maps are valid
for historical cluster maps.

=cut

sub mk_historical_cluster_map_for_photo {
        my $self = shift;
        my $photo_id = shift;

        my $offset = $self->divine_option("clustermap.offset", 0);
        my $today = $self->today();
        my ($before_now, $after_now) = $self->calculate_delta_days($today, $offset);

        my ($ph, $ph_marker, $queries) = $self->mk_cluster_map_for_photo_base($photo_id);

        # tmp array so we don't get stuck in an infinite
	# loop always creating new queries to modify...

        my @new_queries = ();

        foreach my $query_then (@$queries){

                my %query_now = map {
                        $_ => $query_then->{$_};
                } keys %{$query_then};               
                
                $query_now{'min_taken_date'} = $before_now;
                $query_now{'max_taken_date'} = $after_now;
                
                push @new_queries, \%query_now;
        }

        map { push @$queries, $_ } @new_queries;

        my ($markers, $bbox) = $self->blended_search_for_cluster_map($queries);
        unshift @{$markers}, $ph_marker;

	return $self->create_cluster_map($markers, $bbox);
}

# shhh...

sub mk_cluster_maps_for_photoset {
        my $self = shift;
        my $set_id = shift;

        my $upload = $self->divine_option('pinwin.upload', 0);

        # 

        my $photos = $self->collect_photos_for_set($set_id);

        if (! $photos){
                return undef;
        }

        my @maps = ();
        my @set  = ();

        foreach my $ph (@$photos){

                my $uid = $ph->getAttribute("id");
                my $map = $self->mk_cluster_map_for_photo($uid);

                if (! $map){
                        $self->log()->error("failed to generate cluster map for photo #$uid");
                        next;
                }

                my @local_res = ($map->{'path'});

                if ($upload){
                        my $id = $self->upload_map($ph, $map->{'path'});

                        push @local_res, $id;
                        push @set, $id;
                        push @set, $ph->getAttribute("id");
                }

                push @maps, \@local_res;
        }

        if (($upload) && (scalar(@set))) {
                $self->api_call({'method' => 'flickr.photosets.editPhotos',
                                 'args' => {'photoset_id'      => $set_id,
                                            'primary_photo_id' => $set[0],
                                            'photo_ids'        => join(",", @set)}});
        }

        return \@maps;
}

#
# not so public
#

sub create_cluster_map {
        my $self = shift;
        my $markers = shift;
        my $bbox = shift;

        my $mm_args = $self->prepare_modestmaps_args_for_cluster_map($markers, $bbox);
        my $urls = $self->gather_urls_for_cluster_map($markers);

	my $map_data = $self->create_pinwin_map($mm_args, $urls);

        if (! $map_data){
                return undef;
        }

        # 

        $map_data->{'attribution'} = $self->collect_attributions($markers);
        
        $self->log()->debug(Dumper($map_data));
        return $map_data;
}

sub create_pinwin_map {
        my $self = shift;
        my $mm_args = shift;
        my $img_urls = shift;

        $self->log()->debug(Dumper($mm_args));
        $self->log()->debug(Dumper($img_urls));

	my $map_data = $self->fetch_modestmap_image($mm_args);
        
        if (! $map_data){
                return undef;
        }
        
        my $out = $self->place_map_images($map_data, $img_urls);
        $map_data->{'path'} = $out;

	return $map_data;
}

sub collect_attributions {
        my $self = shift;
        my $markers = shift;

        my %attribution = ();

        foreach my $mrk (@$markers){
                
                if (! exists($mrk->{'attribution'})){
                        next;
                }

                my $uid = $mrk->{'uid'};

                if (ref($mrk->{'attribution'}) ne "ARRAY"){
                        $attribution{$uid}->{$mrk->{'attribution'}->{'owner'}} = $mrk->{'attribution'}->{'url'};   
                }

                else {
                        map { 
                                
                                my $owner = $_->{'owner'};
                                my $url = $_->{'url'};
                                
                                $attribution{$uid}->{$owner} ||= [];
                                push @{$attribution{$uid}->{$owner}}, $url;
                                
                        } @{$mrk->{'attribution'}};
                }
        }

        return \%attribution;
}

sub fetch_map_image {
        my $self = shift;
        my $ph = shift;
        my $thumb_data = shift;

        # please refactor me...

        my $lat = $self->get_geo_property($ph, "latitude");
        my $lon = $self->get_geo_property($ph, "longitude");
        my $acc = $self->get_geo_property($ph, "accuracy");

        if ((! $lat) || (! $lon)){
                return undef;
        }

        # 

        my $zoom = $self->flickr_accuracy_to_zoom($acc);
        $self->log()->info("zoom to $zoom ($acc)");

        #

        my $out = $self->mk_tempfile(".png");

        my $provider = $self->divine_option("modestmaps.provider");
        my $bleed = $self->divine_option("modestmaps.bleed");
        my $filter = $self->divine_option("modestmaps.filter");
        $zoom = $self->divine_option("modestmaps.zoom", $zoom);

        # 

        my %args = (
                    'uid' => 'thumbnail',
                    'lat' => $lat, 
                    'lon' => $lon,
                    'width' => $thumb_data->{'width'},
                    'height' => $thumb_data->{'height'},
                     );

        my $marker = Net::Flickr::Geo::ModestMaps::Marker->new(%args);

        my $height = $self->divine_option("pinwin.map_height", 1024);
        my $width = $self->divine_option("pinwin.map_width", 1024);

        my %mm_args = (
                       'provider' => $provider,
                       'latitude' => $lat,
                       'longitude' => $lon,
                       'zoom' => $zoom,
                       'method' => 'center',
                       'height' => $height,
                       'width' => $width,
                       'bleed' => $bleed,
                       'marker' => $marker,
                   );

        if ($filter){
                $mm_args{'filter'} = $filter;
        }

        # $self->log()->info(Dumper(\%mm_args));
        return $self->fetch_modestmap_image(\%mm_args, $out);
}

sub flickr_accuracy_to_zoom {
        my $self = shift;
        my $acc = shift;

        my $provider = $self->divine_option("modestmaps.provider");
        $provider =~ /^([^_]+)_/;
        my $short = lc($1);

        if ($short eq 'yahoo'){
                return $acc;
        }

        else {
                return $acc + 1;
        }

}

sub fetch_modestmap_image {
        my $self = shift;
        my $args = shift;
        my $out = shift;

        $out ||= $self->mk_tempfile(".jpg");

        my $timeout = $self->divine_option("modestmaps.timeout", (5 * 60));
        my $remote = $self->divine_option("modestmaps.server");

        my $mm = Net::ModestMaps->new();
        $mm->host($remote);
        $mm->timeout($timeout);
        $mm->ensure_max_header_lines($args->{'marker'});
        
        my $data = $mm->draw($args, $out);

        if (my $err = $data->{'error'}){
                $self->log()->info("modestmaps error : $err->{'code'}, $err->{'message'}");
                return undef;
        }

        $self->log()->info("received modest map image and stored in $out");
        return $data;
}

sub modify_map {
        my $self = shift;
        my $ph = shift;
        my $map_data = shift;
        my $thumb_data = shift;

        my @pw_details = split(",", $map_data->{'marker-thumbnail'});
        my $pw_x = $pw_details[2];
        my $pw_y = $pw_details[3];
        my $pw_w = $pw_details[4];
        my $pw_h = $pw_details[5];
        
        my @images = ([$thumb_data->{path}, $pw_x, $pw_y, $pw_w, $pw_h]);

        return $self->place_marker_images($map_data->{'path'}, \@images);
}

sub place_marker_images {
        my $self = shift;
        my $map_img = shift;
        my $markers = shift;

        # use GD instead of Imager because the latter has
        # a habit of rendeing the actual thumbnails all wrong...

        # ensure the truecolor luv to prevent nasty dithering

        my $truecolor = 1;
        
        my $im = GD::Image->newFromPng($map_img, $truecolor);

        foreach my $data (@$markers){
                my ($mrk_img, $x, $y, $w, $h) = @$data;
                my $ph = GD::Image->newFromJpeg($mrk_img, $truecolor);
                
                eval {
                        $im->copy($ph, $x, $y, 0, 0, $w, $h);
                };

                if ($@){
                        $self->log()->error("picture made GD cry, skipping. $@");
                }

                unlink($mrk_img);
        }

        unlink($map_img);

        return $self->write_jpeg($im);
}

sub place_map_images {
        my $self = shift;
        my $map_data = shift;
        my $urls = shift;

        my @images = ();

        foreach my $prop (%$map_data){

                if ($prop =~ /^marker-(.*)$/){

                        my $id = $1;
                        
                        my $ph_url = $urls->{$id};
                        my $ph_img = $self->mk_tempfile(".jpg");
                        
                        $self->log()->info("fetch $ph_url");

                        if (! $self->simple_get($ph_url, $ph_img)){
                                $self->log()->error("failed to retrieve $ph_url, $!");
                                next;
                        }

                        my @pw_details = split(",", $map_data->{$prop});
                        my $pw_x = $pw_details[2];
                        my $pw_y = $pw_details[3];
                        my $pw_w = $pw_details[4];
                        my $pw_h = $pw_details[5];

                        push @images, [$ph_img, $pw_x, $pw_y, $pw_w, $pw_h];
                }
        }

        return $self->place_marker_images($map_data->{'path'}, \@images);
}

#
# search
#

sub collect_blended_search {
        my $self = shift;
        my $queries = shift;

        my $perms = $self->divine_option("clustermap.geo_perms", "all");

        my %unsorted = ();
        my @possible = ();

	my %seen = ();

        foreach my $q (@$queries){

		my %local_q = ();

		foreach my $k (keys %{$q}){
			if ($k =~ /^__/){
				next;
			}

        		$local_q{$k} = $q->{$k};
		}

                my $search = $self->api_call({'method' => 'flickr.photos.search', 'args' => \%local_q});

                foreach my $ph ($search->findnodes("/rsp/photos/photo")){

			my $uid = $ph->getAttribute("id");

                        if (exists($seen{$uid})){
                                next;
                        }

                        $seen{$uid} ++;

			if (exists($q->{'__exclude'})){
				if (grep /$uid/, @{$q->{'__exclude'}}){
					$self->log()->info("exclude photo #$uid from blended search");
					next;
				}
			}

                        if (! $self->ensure_geo_perms($uid, $perms)){
                                next;
                        }

                        my $geo = Geo::Distance->new();
                        my $dist = $geo->distance("kilometer", $q->{'lon'}, $q->{'lat'}, $ph->getAttribute("longitude"), $ph->getAttribute("latitude"));

                        $unsorted{$dist} ||= [];
                        push @{$unsorted{$dist}}, $ph;
                }
        }

        foreach my $dist (sort {$a <=> $b} keys %unsorted){
                map { push @possible, $_ } @{$unsorted{$dist}};
        }

        return \@possible;
}

#
# marker methods
#

sub gather_urls_for_cluster_map {
        my $self = shift;
        my $markers = shift;

        my %urls = map {
                $_->{'uid'} => $_->{'url'};
        } @$markers;

	return \%urls;
}

#
# cluster methods (photo)
#

sub mk_cluster_map_for_photo_base {
        my $self = shift;
        my $photo_id = shift;

        my $ph_size = $self->divine_option("pinwin.photo_size", "Medium");
        my $r = $self->divine_option("clustermap.radius", 1);
        my $offset = $self->divine_option("clustermap.offset", 0);
        my $own = $self->divine_option("clustermap.only_photo_owner", 1);
        my $force_own = $self->divine_option("clustermap.force_photo_owner", 0);
        my $license = $self->divine_option("clustermap.photo_license", "*");

        # 

        my $ph = $self->api_call({'method' => 'flickr.photos.getInfo', 'args' => {'photo_id' => $photo_id}});
        $ph = ($ph->findnodes("/rsp/photo"))[0];

        my $owner = $ph->findvalue("owner/\@nsid");

        my $lat = $self->get_geo_property($ph, "latitude");
        my $lon = $self->get_geo_property($ph, "longitude");

        my $sizes = $self->api_call({'method' => 'flickr.photos.getSizes', 'args' => {'photo_id' => $photo_id}});
        
        my $h = $sizes->findvalue("/rsp/sizes/size[\@label='Medium']/\@height");
        my $w = $sizes->findvalue("/rsp/sizes/size[\@label='Medium']/\@width");
        
        my $url = sprintf("http://farm%d.static.flickr.com/%d/%s_%s.jpg",
                          $ph->getAttribute("farm"),
                          $ph->getAttribute("server"),
                          $ph->getAttribute("id"),
                          $ph->getAttribute("secret"));

        my %args = (
                    'uid' => $photo_id,
                    'lat' => $lat,
                    'lon' => $lon,
                    'width' => $w,
                    'height' => $h,
                    'url' => $url,
                   );
                
        if ($license){
                my $username = $ph->findvalue("owner/\@username");
                my $ph_url = $ph->findvalue("urls/url[\@type='photopage']");
                $args{'attribution'} = {'owner' => $username, 'url' => $ph_url};
        }

        my $ph_marker = Net::Flickr::Geo::ModestMaps::Marker->new(%args);

        #
        # Basic search criteria
        #

        my %query = (
                     'lat' => $lat,
                     'lon' => $lon,
                     'radius' => $r,
                     'extras' => 'geo,date_taken',
                     '__exclude' => [$ph->getAttribute('id')],
                    );

        if ($license ne "*"){
                $query{'license'} = $license;
                $query{'extras'} .= ",owner_name";
        }

        if ($own){
                $query{'user_id'} = $owner;
        }

        if ($offset){
                my $dt = $ph->findvalue("dates/\@taken");
                my ($before, $after) = $self->calculate_delta_days($dt, $offset);

                $query{'min_taken_date'} = $before;
                $query{'max_taken_date'} = $after;
        }

        # 

        my @queries = (\%query);

        #

        if ((! $own) && ($force_own) && (exists($query{'license'}))){

                $self->log()->info("forcing photo owner photos, requires a blended search");

                my %query_me = map {
                        $_ => $query{$_};
                } keys %query;

                delete($query_me{'license'});
                $query_me{'user_id'} = $ph->findvalue("owner/\@nsid");

                push @queries, \%query_me;
        }

        #

        return ($ph, $ph_marker, \@queries);
}

#
# cluster methods (markers)
#

sub markers_for_clusters {
        my $self = shift;
        my $clusters = shift;

        my @markers = ();

        foreach my $key (keys %{$clusters}){

                if (scalar(@{$clusters->{$key}}) == 1){
                        push @markers, $clusters->{$key}->[0];
                        next;
                }

                my @images = ();
                my @attribution = ();

                my ($uid, $lat, $lon);

                foreach my $mrk (@{$clusters->{$key}}){

                        if (! exists($mrk->{'url'})){
                                next;
                        }

                        $uid = $mrk->{'uid'};
                        $lat = $mrk->{'lat'};
                        $lon = $mrk->{'lon'};

                        push @images, $mrk->{'url'};

                        if (exists($mrk->{'attribution'})){
                                push @attribution, $mrk->{'attribution'};
                        }
                }

                # reassign $w,$h

                my $stacked = $self->stack_images(\@images);
                my ($w, $h) = imgsize($stacked);

                my $url = "file://" . $stacked;

                my %args = ('uid' => $uid,
                            'lat' => $lat,
                            'lon' => $lon,
                            'width' => $w,
                            'height' => $h,
                            'url' => $url,
                            'attribution' => \@attribution,
                           );

                my $marker = Net::Flickr::Geo::ModestMaps::Marker->new(%args);
                push @markers, $marker;
        }

        return \@markers;
}

#
# cluster methods (search)
#

sub search_for_cluster_map {
        my $self = shift;
        my $query = shift;
        return $self->blended_search_for_cluster_map([$query]);
}

sub blended_search_for_cluster_map {
        my $self = shift;
        my $queries = shift;

        my $max_photos = $self->divine_option("clustermap.max_photos", 100);
        my $max_grouped = $self->divine_option("clustermap.max_photos_per_group", int($max_photos / 2));
        my $offset = $self->divine_option("clustermap.offset", 0);

        my $photos = undef;
        my $clusters = undef;
        my $groups = undef;
        my $bbox = undef;

        my $ok = 0;

        my @pts = ();

        foreach my $q (@$queries){
                push @pts, [$q->{'lat'}, $q->{'lon'}];
        }

        while (! $ok){

                $self->log()->debug("new blended search");
		$photos = $self->collect_blended_search($queries);

		my $cnt_photos = scalar(@$photos);
                my $cnt_groups = 0;
                my $cnt_clusters = 0;
                my $cnt_grouped = 0;

                my $local_ok = ($cnt_photos <= $max_photos) ? 1 : 0;

                $self->log()->info("search returns $cnt_photos photos (max : $max_photos)");

                if ($local_ok){
                        ($clusters, $groups, $bbox) = $self->cluster_blended_search($photos, \@pts);

                        $cnt_groups = scalar(keys %$groups);
                        $cnt_clusters = scalar(keys %$clusters);
                       
                        $cnt_grouped = map { max($cnt_grouped, $_) } values %$groups;

                        $self->log()->info("search returned $cnt_clusters clustered photos, across $cnt_groups groups (max photos/group : $cnt_grouped)");
                        $local_ok = ($cnt_grouped <= $max_grouped) ? 1 : 0;
                }

                if ($local_ok){
                        $ok = 1;
                        last;
                }

                # reset

                $self->log()->info("too many photos adjusting offset and radius so as not to make modestmaps cry");

                $offset = ($offset) ? floor($offset * .9) : 365;

                if ($offset <= 0){
                        $self->log()->error("offset equals zero, eyes turning black");
                        return undef;
                }

                foreach my $q (@{$queries}){

                        if ((! $q->{'min_taken_date'}) || (! $q->{'max_taken_date'})){

                                my $today = $self->today();
                                my ($min, $max) = $self->calculate_delta_days($today, $offset);

                                $q->{'min_taken_date'} = $min;
                                $q->{'max_taken_date'} = $max;
                        }

                        else {

                                $q->{'min_taken_date'} =~ /(\d{4})-(\d{2})-(\d{2})/;
                                my ($y1, $m1, $d1) = ($1, $2, $3);

                                $q->{'max_taken_date'} =~ /(\d{4})-(\d{2})-(\d{2})/;
                                my ($y2, $m2, $d2) = ($1, $2, $3);
                                
                                my $delta = Delta_Days($y1, $m1, $d1, $y2, $m2, $d2);
                                my @new = Add_Delta_Days($y1, $m1, $d1, int($delta / 2));
                                
                                my $start = sprintf("%04d-%02d-%02d", @new);
                                $self->log()->info("reset start date to $start with an offset of $offset days");
                                
                                my ($min, $max) = $self->calculate_delta_days($start, $offset);
                                
                                $self->log()->info("reset min taken date from $q->{'min_taken_date'} to $min");
                                $self->log()->info("reset min taken date from $q->{'max_taken_date'} to $max");
                                
                                $q->{'min_taken_date'} = $min;
                                $q->{'max_taken_date'} = $max;
			}

                        # 

                        $q->{'per_page'} ||= $self->divine_option("clustermap.max_photos", 100);
                        $q->{'per_page'} = ceil($q->{'per_page'} * .9);
                }
        }

        #

        my $markers = $self->markers_for_clusters($clusters);

        return ($markers, $bbox);
}

sub cluster_blended_search {
        my $self = shift;
        my $photos = shift;
        my $pts = shift;

        my %clusters = ();
        my %groups = ();
        my %bbox = ();

        if (defined($pts)){
                foreach my $c (@$pts){
                        $bbox{'sw_lat'} = (exists($bbox{'sw_lat'})) ? min($bbox{'sw_lat'}, $c->[0]) : $c->[0];
                        $bbox{'sw_lon'} = (exists($bbox{'sw_lon'})) ? min($bbox{'sw_lon'}, $c->[1]) : $c->[1];
                        $bbox{'ne_lat'} = (exists($bbox{'ne_lat'})) ? max($bbox{'ne_lat'}, $c->[0]) : $c->[0];
                        $bbox{'ne_lon'} = (exists($bbox{'ne_lon'})) ? max($bbox{'ne_lon'}, $c->[1]) : $c->[1];
                }
        }
        
        foreach my $ph (@$photos){
                
                my $uid = $ph->getAttribute("id");

                my $lat = $self->get_geo_property($ph, "latitude");
                my $lon = $self->get_geo_property($ph, "longitude");
                my $cluster_key = $self->geotude($lat, $lon);
                
                # to do : allow for other sizes and center crop...

                my $url = sprintf("http://farm%d.static.flickr.com/%d/%s_%s_s.jpg",
                                  $ph->getAttribute("farm"),
                                  $ph->getAttribute("server"),
                                  $ph->getAttribute("id"),
                                  $ph->getAttribute("secret"));

                my %args = (
                            'uid' => $uid,
                            'lat' => $lat,
                            'lon' => $lon,
                            'width' => 75,
                            'height' => 75,
                            'url' => $url,
                           );

                # attribution

                if (my $owner = $ph->getAttribute("ownername")){

                        my $page = sprintf("http://www.flickr.com/photos/%s/%s",
                                           $ph->getAttribute("owner"),
                                           $uid);

                        $args{'attribution'} = {'owner' => $owner, 'url' => $page};
                }

                my $marker = Net::Flickr::Geo::ModestMaps::Marker->new(%args);
                
                $clusters{$cluster_key} ||= [];
                push @{$clusters{$cluster_key}}, $marker;

                $bbox{'sw_lat'} = (exists($bbox{'sw_lat'})) ? min($bbox{'sw_lat'}, $lat) : $lat;
                $bbox{'sw_lon'} = (exists($bbox{'sw_lon'})) ? min($bbox{'sw_lon'}, $lon) : $lon;
                $bbox{'ne_lat'} = (exists($bbox{'ne_lat'})) ? max($bbox{'ne_lat'}, $lat) : $lat;
                $bbox{'ne_lon'} = (exists($bbox{'ne_lon'})) ? max($bbox{'ne_lon'}, $lon) : $lon;
                
                # to do : check to see how closely together
                # stuff is clustered; weight counts below accordingly
                
                my $rnd_lat = sprintf("%.2f", $lat);
                my $rnd_lon = sprintf("%.2f", $lon);
                my $group_key = $self->geotude($rnd_lat, $rnd_lon);
                
                $groups{$group_key} ++;
        }

        return \%clusters, \%groups, \%bbox;
}

#
# cluster methods (other)
#

sub prepare_modestmaps_args_for_cluster_map {
        my $self = shift;
        my $markers = shift;
        my $bbox = shift;

        my $provider = $self->divine_option("modestmaps.provider");
        my $bleed = $self->divine_option("modestmaps.bleed", 1);
        my $adjust = $self->divine_option("modestmaps.adjust", .25);
        my $filter = $self->divine_option("modestmaps.filter", );
        my $zoom = $self->divine_option("modestmaps.zoom", 17);

        my $markers_prepped = Net::Flickr::Geo::ModestMaps::MarkerSet->prepare($markers);

        my %mm_args = (
                       'provider' => $provider,
                       'method' => 'bbox',
                       'bleed' => $bleed,
                       'adjust' => $adjust,
                       'marker' => $markers_prepped,
                       'zoom' => $zoom,
                       'bbox' => "$bbox->{'sw_lat'},$bbox->{'sw_lon'},$bbox->{'ne_lat'},$bbox->{'ne_lon'}",
                   );

        my $dist_avg = $self->calculate_average_distance($bbox);
        
        my $readjust = 0;
        
        if ($dist_avg < 1){
                $readjust = .25;
        }
                
        elsif ($dist_avg < 1.5){
                $readjust = .15     
        }
        
        elsif ($dist_avg < 2){
                $readjust = .1;
        }
        
        else { }
        
        if (($readjust) && ($readjust > $mm_args{'adjust'})){
                $self->log()->info("autosetting modestmaps adjust parameter to $readjust");
                $mm_args{'adjust'} = $readjust;
        }

	if ($filter){
                $mm_args{'filter'} = $filter;
        }

        return \%mm_args;
}

#
# geo
#

sub geotude {
        my $self = shift;
        my $lat = shift;
        my $lon = shift;

        my $geo = Geo::Geotude->new('latitude' => $lat, 'longitude' => $lon);
        return $geo->geotude();
}

sub calculate_average_distance {
        my $self = shift;
        my $bbox = shift;

        my $geo = Geo::Distance->new();
        
        my $dist_x = $geo->distance("kilometer", $bbox->{'sw_lon'}, $bbox->{'sw_lat'}, $bbox->{'sw_lon'}, $bbox->{'ne_lat'});
        my $dist_y = $geo->distance("kilometer", $bbox->{'sw_lon'}, $bbox->{'sw_lat'}, $bbox->{'sw_lon'}, $bbox->{'ne_lat'});
                
        my $dist_avg = ($dist_x + $dist_y) / 2;
                
        $self->log()->info("distance between sw and ne corners is $dist_x km and $dist_y km");
        $self->log()->info("average distance is $dist_avg km");

	return $dist_avg;
}

#
# images
#

sub stack_images {
        my $self = shift;
        my $images = shift;

        my $count = scalar(@$images);
        my $per_row = ceil(sqrt($count));
        my $rows = ceil($count/$per_row);

	my $other_rows = $rows - 1;
	my $last_row = $count - ($other_rows * $per_row);

	if ($last_row == $other_rows){
		$per_row += 1;
		$rows -= 1;
	}

        $self->log()->info("stacking $count images $per_row per row for a total of $rows rows");

        my $spacer_px = 10;
        my $spacers_w = $per_row - 1;
        my $spacers_h = $rows - 1;

        my $cnv_w = ($per_row * 75) + ($spacers_w * $spacer_px);
        my $cnv_h = ($rows * 75) + ($spacers_h * $spacer_px);

        $self->log()->debug("stacking canvas is $cnv_w x $cnv_h pixels");

        my $truecolor = 1;
        GD::Image->trueColor($truecolor);

        my $im = new GD::Image($cnv_w, $cnv_h);
        my $wh = $im->colorAllocate(255, 255, 255);

        $im->filledRectangle(0, 0, $cnv_w, $cnv_h, $wh);

        my $across = 1;
        my $down = 1;

        foreach my $url (@$images){

                my $tmp = $self->mk_tempfile(".jpg");

                if (! getstore($url, $tmp)){
                        $self->log()->error("failed to retrieve $url for stacking, $!");
                        next;
                }

                my $ph = GD::Image->newFromJpeg($tmp, $truecolor);

                if (! $ph){
                        $self->log()->error("failed to create image from $tmp, $!");
                        next;
                }

                my $copy_x = ($spacer_px * ($across - 1)) + (75 * ($across - 1));
                my $copy_y = ($spacer_px * ($down - 1)) + (75 * ($down - 1));

                $self->log()->debug("copy image at $copy_x ($across accross) and $copy_y ($down down)");

                eval {
                	$im->copy($ph, $copy_x, $copy_y, 0, 0, 75, 75);
		};

                if ($@){
                        $self->log()->error("picture made GD cry, skipping. $@");
                }

                unlink($tmp);

                if ($across == $per_row){
                        $across = 1;
                        $down += 1;
                }

                else {
                        $across += 1
                }
        }

        return $self->write_jpeg($im);
}

sub write_jpeg {
        my $self = shift;
        my $im = shift;
        my $out = shift;

        if (! defined($out)){
                $out = $self->mk_tempfile(".jpg");
        }

        my $fh = FileHandle->new(">$out");

        binmode($fh);
        $fh->print($im->jpeg(100));
        $fh->close();

        return $out;
}

#
# datetime
#

sub calculate_delta_days {
        my $self = shift;
        my $dt = shift;
        my $offset = shift;
       
        $dt =~ /^(\d{4})-(\d{2})-(\d{2})/;
        
        my $yyyy = $1;
        my $mm = $2;
        my $dd = $3;
        
        my $before = sprintf("%04d-%02d-%02d 00:00:00", Add_Delta_Days($yyyy, $mm, $dd, -$offset));
        my $after = sprintf("%04d-%02d-%02d 23:59:59", Add_Delta_Days($yyyy, $mm, $dd, $offset));

        return ($before, $after);
}

sub today {
        my $self = shift;
        return sprintf("%04d-%02d-%02d", Today());
}

#
# hey ! look over there !!
#

package Net::Flickr::Geo::ModestMaps::MarkerSet;

sub prepare {
        my $pkg = shift;
        my $markers = shift;

        if (ref($markers) ne "ARRAY"){
                return "$markers";
        }

        my @prep = map { "$_" } @$markers;
        return \@prep;
}

package Net::Flickr::Geo::ModestMaps::Marker;

use overload q("") => sub {
        my $self = shift;

        my @parts = map {
                $self->{$_}
        } qw(uid lat lon width height);

        return join(",", @parts);
};

sub new {
        my $pkg = shift;
        my %self = @_;
        return bless \%self, $pkg;
}

=head1 VERSION

0.72

=head1 DATE

$Date: 2008/08/03 17:08:39 $

=head1 AUTHOR

Aaron Straup Cope  E<lt>ascope@cpan.orgE<gt>

=head1 EXAMPLES

L<http://flickr.com/photos/straup/tags/modestmaps/>

=head1 REQUIREMENTS

Modest Maps 1.0 or higher. 

L<http://modestmaps.com/>

=head1 NOTES

All uploads to Flickr are marked with a content-type of "other".

=head1 SEE ALSO

L<Net::Flickr::Geo>

L<Net::ModestMaps>

L<http://modestmaps.com/>

L<http://mike.teczno.com/notes/oakland-crime-maps/IX.html>

L<http://www.aaronland.info/weblog/2008/02/05/fox/#ws-modestmaps>

=head1 BUGS

Sure, why not.

Please report all bugs via L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2007-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
