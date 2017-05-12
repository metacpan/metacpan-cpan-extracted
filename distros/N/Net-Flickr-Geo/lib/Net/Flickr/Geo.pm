# $Id.pm,v 1.11 2007/06/07 06:55:36 asc Exp $

use strict;

package Net::Flickr::Geo;
use base qw (Net::Flickr::API);

$Net::Flickr::Geo::VERSION = '0.72';

=head1 NAME 

Net::Flickr::Geo - tools for working with geotagged Flickr photos

=head1 SYNOPSIS

There is no synopsis. There is only documentation for provider specific
packages. Okay, I lied. There's a little bit below. But really, please
consult provider specific packaged for details.

=head1 DESCRIPTION

Tools for working with geotagged Flickr photos.

=head1 PROVIDERS 

=head2 ModestMaps

Fetch maps using the Modest Maps ws-pinwin HTTP interface : 

 #
 # Simple
 #

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 $cfg->param("pinwin.photo_size", "Medium");
 $cfg->param("modestmaps.filter", "atkinson");
 $cfg->param("pinwin.upload", 1);
        
 my $fl = Net::Flickr::Geo::ModestMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'debug'));

 my $map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 $fl->log()->info("wrote map to $map->[0]->[0]");

 #
 # Fancy
 #

 my %opts = ();
 getopts('c:s:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::ModestMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'info'));

 my $data = $fl->mk_poster_map_for_photoset($opts{'s'});
 $fl->log()->info(Dumper($data));

 my $tiles = $fl->upload_poster_map($data->{'path'});
 $fl->log()->info(Dumper($tiles));

=head2 YahooMaps

Fetch maps using the Yahoo! Maps Image API : 

 #
 # Simple
 #

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::YahooMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'debug'));

 my $map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 $fl->log()->info("wrote map to $map->[0]->[0]");

 #
 # Handy
 #

 my %opts = ();
 getopts('c:s:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::YahooMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'debug'));

 my $map = $fl->mk_pinwin_maps_for_photoset($opts{'s'});

 foreach my $data (@$map){
        $fl->log()->info("wrote image/map to $data->[0]");
 }

=head2 Google Maps

Fetch maps using the Google Maps Static Maps API : 

 #
 # Simple
 #

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::GoogleMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'debug'));

 $cfg->param("google.map_type", "mobile");

 my $map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 $fl->log()->info("wrote map to $map->[0]->[0]");

=head2 MultiMaps

Fetch maps using the MultiMap Static Maps API : 

 #
 # Simple
 #

 my %opts = ();
 getopts('c:i:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my $fl = Net::Flickr::Geo::MultiMaps->new($cfg);
 $fl->log()->add(Log::Dispatch::Screen->new('name' => 'scr', min_level => 'debug'));

 my $map = $fl->mk_pinwin_map_for_photo($opts{'i'});
 $fl->log()->info("wrote map to $map->[0]->[0]");

=head1 IMPORTANT

B<Versions 0.5 and higher are, essentially, not even a little bit backwards
compatible.>

Please adjust your code and expectations accordingly. It shouldn't
happen again...

=cut

use File::Temp qw (tempfile);

use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request;
use Geo::Coordinates::DecimalDegrees;
use Flickr::Upload;
use Image::Size;
use FileHandle;

#
# shared, and public
#

sub init {
        my $self = shift;
        my $args = shift;

        if (! $self->SUPER::init($args)){
                return undef;
        }

        $self->{'__cache'} = {'geo_perms' => {}};

        return 1;
}

sub mk_pinwin_map_for_photo {
        my $self     = shift;
        my $photo_id = shift;

        my $upload = $self->divine_option('pinwin.upload', 0);

        # 

        my $res = $self->api_call({'method' => 'flickr.photos.getInfo',
                                   'args'   => {'photo_id' => $photo_id}});

        if (! $res){
                return undef;
        }

        my $ph  = ($res->findnodes("/rsp/photo"))[0];
        my $map = $self->mk_pinwin_map($ph);

        if (! $map){
                return undef;
        }

        my @res = ($map);

        if ($upload){
                my $id = $self->upload_map($ph, $map);
                push @res, $id;
        }

        return [ \@res ];
}

sub mk_pinwin_maps_for_photoset {
        my $self   = shift;
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

                my $map = $self->mk_pinwin_map($ph);

                if (! $map){
                        next;
                }

                my @local_res = ($map);

                if ($upload){
                        my $id = $self->upload_map($ph, $map);

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
# shared, and not really public
#

sub mk_pinwin_map {
        my $self = shift;
        my $ph = shift;

        my $id = $ph->getAttribute("id");

        #

        my $thumb_data = $self->fetch_flickr_photo($ph);

        if (! $thumb_data){
                $self->log()->error("unable to retrieve photo $id");
                return undef;
        }

        # 

        my $map_data  = $self->fetch_map_image($ph, $thumb_data);

        if (! $map_data) {
                $self->log()->error("unable to add photo $id to map");
                return undef;
        }

        my $new = $self->modify_map($ph, $map_data, $thumb_data);

        unlink($map_data->{'path'});
        unlink($thumb_data->{'path'});

        return $new;
}

sub collect_photos_for_set {
        my $self = shift;
        my $set_id = shift;

        my $res = $self->api_call({'method' => 'flickr.photosets.getPhotos',
                                   'args' => {'photoset_id' => $set_id,
                                              'extras' => 'geo, machine_tags, tags'}});

        if (! $res){
                return undef;
        }

        my %ihasamapz = ();
        my @photos = ();

        my $skip_ids = $self->divine_option("pinwin.skip_photos");
        my $ensure_tags = $self->divine_option("pinwin.ensure_tags");
        my $skip_tags = $self->divine_option("pinwin.skip_tags");

        if (($skip_ids) && (ref($skip_ids) ne 'ARRAY')){
                $skip_ids = [$skip_ids];
        }

        if (($ensure_tags) && (ref($ensure_tags) ne 'ARRAY')){
                $ensure_tags = [$ensure_tags];
        }

        if (($skip_tags) && (ref($skip_tags) ne 'ARRAY')){
                $skip_tags = [$skip_tags];
        }

        foreach my $ph ($res->findnodes("/rsp/photoset/photo")){

                my $id = $ph->getAttribute("id");

                if (($skip_ids) && (grep /$id/, @$skip_ids)){
                        $self->log()->info("photo id $id excluded, skipping");
                        next;
                }

                # 

                my $mt = $ph->getAttribute("machine_tags");

                if ($mt =~ /\bflickr\:map\=pinwin\b/){

                        if ($mt =~ /\bflickr\:photo\=(\d+)\b/){
                                $ihasamapz{$1} = $id;
                        }
                       
                        $self->log()->info("photo id $id tagged pinwin, skipping");
                        next;
                }

                if (my $mapid = $ihasamapz{$id}){
                        $self->log()->info("photo id $id already has a map $mapid, skipping");
                        next;
                }

                if (! $ph->getAttribute("latitude")){
                        $self->log()->info("photo id $id has no geo information, skipping");
                        next;
                }

                if ($ensure_tags){
                        my $has_tag = 0;
                        my $tags = $ph->getAttribute("tags");

                        foreach my $t (@$ensure_tags){
                                if ($tags =~ /\b$t\b/){
                                        $has_tag = 1;
                                        last;
                                }
                        }

                        if (! $has_tag){
                                $self->log()->info("photo id $id does not contain required tags : " . join(";", @$ensure_tags));
                                next;
                        }
                        
                }

                if ($skip_tags){

                        my $has_tag = 0;
                        my $tags = $ph->getAttribute("tags");

                        foreach my $t (@$skip_tags){
                                if ($tags =~ /\b$t\b/){
                                        $has_tag = 1;
                                        last;
                                }
                        }

                        if ($has_tag){
                                $self->log()->info("photo id $id has skippable tags : " . join(";", @$skip_tags));
                                next;
                        }
                }

                push @photos, $ph;
        }

        return \@photos;
}

sub flickr_photo_url {
        my $self = shift;
        my $ph = shift;

        my $sz = $self->divine_option("pinwin.photo_size", "Small");
        my $ext = $self->flickr_photo_extension($sz);

        my $id = $ph->getAttribute("id");
        my $fid = $ph->getAttribute("farm");
        my $sid = $ph->getAttribute("server");;
        my $secret = $ph->getAttribute("secret");

        return "http://farm" . $fid . ".static.flickr.com/" . $sid . "/" . $id . "_" . $secret . $ext . ".jpg";
}

sub flickr_photo_extension {
        my $self = shift;
        my $size = shift;

        my %map = (
                   'square' => '_s',
                   'thumbnail' => '_t',
                   'small' => '_m',
                   'medium' => '',
                  );

        return $map{ lc($size) };
}

sub fetch_flickr_photo {
        my $self = shift;
        my $ph = shift;
                
        my $url = $self->flickr_photo_url($ph);
        my $path =  $self->simple_get($url, $self->mk_tempfile(".jpg"));

        if (! $path){
                return undef;
        }

        my ($img_w, $img_h) = imgsize($path);

        my %data = (
                    'url' => $url,
                    'path' => $path,
                    'height' => $img_h,
                    'width' => $img_w,
                   );

        return \%data;
}

sub mk_tempfile {
        my $self = shift;
        my $ext  = shift;

        my ($fh, $filename) = tempfile(UNLINK => 0, SUFFIX => $ext);
        return $filename;
}

sub simple_get {
        my $self   = shift;
        my $remote = shift;       
        my $local  = shift;

        $local ||= $self->mk_tempfile();

        $self->log()->info("fetch remote file : $remote");
        $self->log()->info("store local file : $local");

        if (! getstore($remote, $local)){
                $self->log()->error("failed to retrieve remote URL ($remote)");
                return 0;
        }

        return $local;
}

sub get_geo_property {
        my $self = shift;
        my $ph = shift;
        my $prop = shift;

        my $value = $ph->getAttribute($prop);

        if (! $value){
                $value = $ph->findvalue("location/\@" . $prop);
        }

        return $value;
}

sub pretty_print_latlong {
        my $self = shift;
        my $lat = shift;
        my $lon = shift;

        my @lat_dms = decimal2dms($lat);
        my $ns = ($lat_dms[3]) ? "N" : "S";

        my $str_lat = sprintf(qq(%d° %d' %d" $ns), @lat_dms);

        my @lon_dms = decimal2dms($lon);
        my $ew = ($lon_dms[3]) ? "E" : "W";

        my $str_lon = sprintf(qq(%d° %d' %d" $ew), @lon_dms);
        return "$str_lat, $str_lon";
}

sub upload_map {
        my $self = shift;
        my $ph   = shift;
        my $map  = shift;

        #

        my $lat = $self->get_geo_property($ph, "latitude");
        my $lon = $self->get_geo_property($ph, "longitude");
        my $title = $self->pretty_print_latlong($lat, $lon);

        my $tag = "flickr:photo=" . $ph->getAttribute("id");

        my %args = (
                    'photo'      => $map,
                    'title'      => $title,
                    'tags'       => "$tag flickr:map=pinwin",
                   );

        return $self->upload_image(\%args);
}

sub upload_image {
        my $self = shift;
        my $args = shift;

        $args->{'is_public'} = ($self->divine_option("pinwin.upload_public"), 0);
        $args->{'is_friend'} = ($self->divine_option("pinwin.upload_friend"), 0);
        $args->{'is_family'} = ($self->divine_option("pinwin.upload_family"), 0);
        $args->{'auth_token'} = $self->divine_option("flickr.auth_token");

        $self->log()->info("upload to flickr : $args->{photo}");

        my $id = undef;

        eval {

                my $ua  = Flickr::Upload->new({'key'=> $self->divine_option("flickr.api_key"),
                                               'secret' => $self->divine_option("flickr.api_secret")});

                $id = $ua->upload(%$args);
        };

        if (! $id) {
                $self->log()->error("failed to upload photo, $@");
                return;
        }

        # This is not a love song...

        $self->api_call({'method' => 'flickr.photos.setContentType',
                         'args' => {'photo_id' => $id, 'content_type' => 3}});


        $self->log()->info("photo uploaded with ID $id");
        return $id;
}

sub divine_option {
        my $self = shift;
        my $opt = shift;
        my $default = shift;

        my $v = $self->{'cfg'}->param($opt);

        if (defined($v)){
                $self->log()->info("divine by config : $opt => $v");
                return $v;
        }

        $self->log()->info("divine by default : $opt => $default");
        return $default;
}

sub load_pinwin {
        my $self = shift;

        if (! $self->{'__pinwin'}){

                use Net::Flickr::Geo::Pinwin;
                my $pinwin = Net::Flickr::Geo::Pinwin->mk_flickr_pinwin();

                $self->log()->info("created temporary pinwin : $pinwin");
                $self->{'__pinwin'} = $pinwin;
        }

        return $self->{'__pinwin'};
}

sub modify_map {
        my $self = shift;
        my $ph = shift;

        my $map_data = shift;
        my $thumb_data = shift;
        my $out = shift;

        $out ||= $self->mk_tempfile(".png");

        my $pinwin = $self->load_pinwin();

        #

        my $truecolour = 1;

        use GD;
        my $pw = GD::Image->newFromPng($pinwin, $truecolour);
        $pw->alphaBlending(0);
        $pw->saveAlpha(1);
        
        my $th = GD::Image->newFromJpeg($thumb_data->{'path'});
        $th->alphaBlending(0);
        $th->saveAlpha(1);

        # place the thumb on the pinwin

        $pw->copy($th, 11, 10, 0, 0, 75, 75);

        #
        # so so wrong but for the life of me I can't figure
        # out why the transparency for the pinwin is not
        # preserved below...
        #

        my $pin = $self->mk_tempfile(".png");
        my $fh = FileHandle->new(">$pin");

        binmode($fh);
        $fh->print($pw->png(0));
        $fh->close();

        my $h = $self->divine_option("pinwin.map_height", 1024);
        my $w = $self->divine_option("pinwin.map_width", 1024);

        my $x = int($w / 2) - 28;
        my $y = int($h / 2) - 134;
        
        my $cmd = "composite -quality 100 -geometry +" . $x . "+" . $y . " $pin $map_data->{'path'} $out";

        if (system($cmd)){
                $self->log()->error("failed to modify map ($cmd) , $!");
                return;
        }

        return $out;

        #
        # we now return you to your regular programming which doesn't work...
        #

        # place the pinwin on the map

        my $map = GD::Image->newFromPng($map_data->{'path'}, $truecolour);
        $map->alphaBlending(0);
        $map->saveAlpha(1);

        # fix me!
        # why doesn't the alpha in $pw get preserved

        $map->copy($pw, $x, $y, 0, 0, 159, 146);
        
        #

        $self->log()->info("save as $out");
        my $f = FileHandle->new(">$out");

        binmode($fh);
        $f->print($map->png(0));
        $f->close();

        return $out;
}

sub ensure_geo_perms {
        my $self = shift;
        my $photo_id = shift;
        my $require = shift;

        if ($require eq "all"){
                return 1;
        }

        # 

        my $key = "$photo_id-$require";

        if (exists($self->{'__cache'}->{'geo_perms'}->{$key})){
                return $self->{'__cache'}->{'geo_perms'}->{$key};
        }

        #

        $self->log()->info("ensure geo permissions : $require");

        my $perms = $self->api_call({'method' => 'flickr.photos.geo.getPerms', 'args' => {'photo_id' => $photo_id}});
        my $ok = 0;

        if ($require eq "public"){
                $ok = $perms->findvalue("/rsp/perms/\@ispublic");
        }

        elsif ($require eq "contact"){
                $ok = $perms->findvalue("/rsp/perms/\@iscontact");
        }

        elsif ($require eq "friend"){
                $ok = $perms->findvalue("/rsp/perms/\@isfriend");
        }

        elsif ($require eq "family"){
                $ok = $perms->findvalue("/rsp/perms/\@isfamily");
        }

        elsif ($require eq "friend or family"){

                if ($perms->findvalue("/rsp/perms/\@isfriend")){
                        $ok = 1;
                }

                else {
                        $ok = $perms->findvalue("/rsp/perms/\@isfamily");
                }
        }

        else { }

        $self->{'__cache'}->{'geo_perms'}->{$key} = $ok;
        return $ok;
}

sub DESTROY {
        my $self = shift;

        if (-f $self->{'__pinwin'}){
                $self->log()->info("removing temporary pinwin : " . $self->{'__pinwin'});
                # unlink($self->{'__pinwin'});
        }
        
        $self->SUPER::DESTROY();
}

=head1 VERSION

0.72

=head1 DATE

$Date: 2008/08/03 17:08:39 $

=head1 AUTHOR

Aaron Straup Cope  E<lt>ascope@cpan.orgE<gt>

=head1 NOTES

All uploads to Flickr are marked with a content-type of "other".

=head1 SEE ALSO

L<Net::Flickr::API>

L<http://developer.yahoo.com/maps/rest/V1/mapImage.html>

L<http://www.multimap.com/share/documentation/openapi/1.2/web_service/staticmaps.htm>

L<http://code.google.com/apis/maps/documentation/staticmaps/index.html>

L<http://modestmaps.com/>

L<http://mike.teczno.com/notes/oakland-crime-maps/IX.html>

L<http://www.aaronland.info/weblog/2007/07/28/trees/#delmaps_pm>

L<http://www.aaronland.info/weblog/2007/06/08/pynchonite/#net-flickr-geo>

L<http://www.aaronland.info/weblog/2007/06/08/pynchonite/#nfg_mm>

L<http://flickr.com/photos/straup/sets/72157600321286227/>

L<http://www.flickr.com/help/filters/>

=head1 BUGS

Sure, why not.

Please report all bugs via L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2007-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
