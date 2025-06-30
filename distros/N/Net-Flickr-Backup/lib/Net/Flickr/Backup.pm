use strict;
use warnings;

package Net::Flickr::Backup 3.200;
use parent qw(Net::Flickr::RDF);

use utf8;

# ABSTRACT: OOP for backing up your Flickr photos locally

#pod =head1 SYNOPSIS
#pod
#pod   use Net::Flickr::Backup;
#pod   use Log::Dispatch::Screen;
#pod
#pod   my $flickr = Net::Flickr::Backup->new($cfg);
#pod
#pod   my $feedback = Log::Dispatch::Screen->new(
#pod     'name'      => 'info',
#pod     'min_level' => 'info',
#pod   );
#pod
#pod   $flickr->log->add($feedback);
#pod   $flickr->backup;
#pod
#pod =head1 OPTIONS
#pod
#pod Options are passed to Net::Flickr::Backup using a Config::Simple object or
#pod a valid Config::Simple config file. Options are grouped by "block".
#pod
#pod =head2 flickr
#pod
#pod =over 4
#pod
#pod =item C<api_key>
#pod
#pod String. I<required>
#pod
#pod A valid Flickr API key.
#pod
#pod =item C<api_secret>
#pod
#pod String. I<required>
#pod
#pod A valid Flickr Auth API secret key.
#pod
#pod =item C<auth_token>
#pod
#pod String. I<required>
#pod
#pod A valid Flickr Auth API token.
#pod
#pod The C<api_handler> defines which XML/XPath handler to use to process API responses.
#pod
#pod =over 4
#pod
#pod =item C<LibXML>
#pod
#pod Use XML::LibXML.
#pod
#pod =item C<XPath>
#pod
#pod Use XML::XPath.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =head2 backup
#pod
#pod =over 4
#pod
#pod =item C<photos_root>
#pod
#pod String. I<required>
#pod
#pod The root folder where you want photographs to be stored. Individual
#pod files are named using the following pattern:
#pod
#pod   <photos_root>/<YYYY>/<MM>/<DD>/<YYYYMMDD>-<photo_id>-<clean_title>_<size>.jpg
#pod
#pod Where the various components are:
#pod
#pod =over 4
#pod
#pod =item C<YYYYMMDD>
#pod
#pod   photo[@id=123]/dates/@taken
#pod
#pod =item C<photo_id>
#pod
#pod   photo/@id
#pod
#pod =item C<clean_title>
#pod
#pod   photo[@id=123]/title
#pod
#pod Unicode characters translated in to ASCII (using Text::Unidecode) and the
#pod entire string is stripped anything that is not an alphanumeric, underbar,
#pod dash or a square bracket.
#pod
#pod =item C<size>
#pod
#pod Net::Flickr::Backup will attempt to fetch not only the original file uploaded
#pod to Flickr but also, depending on your config options, the medium and square
#pod versions. Filenames will be modified as follows:
#pod
#pod =over 4
#pod
#pod =item C<original>
#pod
#pod The original photo you uploaded to the Flickr servers. No extension is
#pod added.
#pod
#pod =item C<medium>
#pod
#pod These photos are scaled to 500 pixels at the longest dimension. A B<_m>
#pod extension is added.
#pod
#pod =item C<medium_640>
#pod
#pod These photos are scaled to 640 pixels at the longest dimension. A B<_z>
#pod extension is added.
#pod
#pod =item C<square>
#pod
#pod These photos are to cropped to 75 x 75 pixels at the center. A B<_s>
#pod extension is added.
#pod
#pod =item C<site_mp4>
#pod
#pod The MP4 version of a video uploaded to Flickr. A B<_site> extension is added.
#pod
#pod =item C<video_original>
#pod
#pod An original video uploaded to Flickr. No extentsion is added.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =item C<fetch_original>
#pod
#pod Boolean.
#pod
#pod Retrieve the "original" version of a photo from the Flickr servers.
#pod
#pod Default is true.
#pod
#pod =item C<fetch_video_original>
#pod
#pod Boolean.
#pod
#pod Retrieve the "original" version of a video from the Flickr servers.
#pod
#pod Default is true.
#pod
#pod =item C<fetch_medium>
#pod
#pod Boolean.
#pod
#pod Retrieve the "medium" version of a photo from the Flickr servers; these photos
#pod have been scaled to 500 pixels at the longest dimension.
#pod
#pod Default is false.
#pod
#pod =item C<fetch_medium_640>
#pod
#pod Boolean.
#pod
#pod Retrieve the "medium" version of a photo from the Flickr servers; these photos
#pod have been scaled to 640 pixels at the longest dimension.
#pod
#pod Default is false.
#pod
#pod =item C<fetch_square>
#pod
#pod Boolean.
#pod
#pod Retrieve the "square" version of a photo from the Flickr servers; these photos
#pod have been cropped to 75 x 75 pixels at the center.
#pod
#pod Default is false.
#pod
#pod =item C<fetch_site_mp4>
#pod
#pod Boolean.
#pod
#pod Retrieve the "site MP4" version of a video from the Flickr servers;
#pod
#pod Default is false.
#pod
#pod =item C<scrub_backups>
#pod
#pod Boolean.
#pod
#pod If true then, for each Flickr photo ID backed up, the library will check
#pod B<backup.photos_root> for images (and metadata files) with a matching ID but
#pod a different name. Matches will be deleted.
#pod
#pod =item C<force>
#pod
#pod Boolean.
#pod
#pod Force a photograph to be backed up even if it has not changed.
#pod
#pod Default is false.
#pod
#pod =back
#pod
#pod =head2 rdf
#pod
#pod =over 4
#pod
#pod =item C<do_dump>
#pod
#pod Boolean.
#pod
#pod Generate an RDF description for each photograph. Descriptions
#pod are written to disk in separate files.
#pod
#pod Default is false.
#pod
#pod =item C<rdfdump_root>
#pod
#pod String.
#pod
#pod The path where RDF data dumps for a photo should be written. The default
#pod is the same path as B<backup.photos_root>.
#pod
#pod File names are generated with the same pattern used to name
#pod photographs.
#pod
#pod =item C<rdfdump_inline>
#pod
#pod Boolean.
#pod
#pod Set to true if you want the RDF dump for a photo to be stored in the file's
#pod JPEG COM block. RDF data will only be stored (for the time being) in the original
#pod image file and not any of the scaled versions.
#pod
#pod This option will only work for JPEG files and is still B<experimental>. It may change
#pod or, you know, not always work. Using Adobe's XMP spec is on the list of things to poke
#pod at so if you've got any suggestions on the subject, they'd be welcome.
#pod
#pod Default is false.
#pod
#pod =item C<photos_alias>
#pod
#pod String.
#pod
#pod If defined this string is applied as regular expression substitution to
#pod B<backup.photos_root>.
#pod
#pod Default is to append the B<file:/> URI protocol to a path.
#pod
#pod =item C<query_geonames>
#pod
#pod Boolean.
#pod
#pod If true and a photo has geodata (latitude, longitude) associated with it, then
#pod the geonames.org database will be queried for a corresponding match. Data will
#pod be added as properties of the photo's geo:Point description. For example:
#pod
#pod   <geo:Point rdf:about="http://www.flickr.com/photos/35034348999@N01/272880469#location">
#pod     <geo:long>-122.025151</geo:long>
#pod     <flickr:accuracy>16</flickr:accuracy>
#pod     <acl:access>visbility</acl:access>
#pod     <geo:lat>37.417839</geo:lat>
#pod     <acl:accessor>public</acl:accessor>
#pod     <geoname:Feature rdf:resource="http://ws.geonames.org/rdf?geonameId=5409655"/>
#pod   </geo:Point>
#pod
#pod   <geoname:Feature rdf:about="http://ws.geonames.org/rdf?geonameId=5409655">
#pod     <geoname:featureCode>PPLX</geoname:featureCode>
#pod     <geoname:countryCode>US</geoname:countryCode>
#pod     <geoname:regionCode>CA</geoname:regionCode>
#pod     <geoname:region>California</geoname:region>
#pod     <geoname:city>Santa Clara</geoname:city>
#pod     <geoname:gtopo30>2</geoname:gtopo30>
#pod   </geoname:Feature>
#pod
#pod =back
#pod
#pod =head2 iptc
#pod
#pod =over 4
#pod
#pod =item C<do_dump>
#pod
#pod Boolean.
#pod
#pod If true, then a limited set of metadata associated with a photo will be stored
#pod as IPTC information.
#pod
#pod A photo's title is stored as the IPTC B<Headline>, description as B<Caption/Abstract>
#pod and tags are stored in one or more B<Keyword> headers. Per the IPTC 7901 spec,
#pod all text is converted to the ISO-8859-1 character encoding.
#pod
#pod For example:
#pod
#pod   exiv2 -pi /home/asc/photos/2006/06/20/20060620-171674319-mie.jpg
#pod   Iptc.Application2.RecordVersion       Short       1  2
#pod   Iptc.Application2.Keywords            String     11  cameraphone
#pod   Iptc.Application2.Keywords            String     15  "san francisco"
#pod   Iptc.Application2.Keywords            String      5  filtr
#pod   Iptc.Application2.Keywords            String      3  mie
#pod   Iptc.Application2.Keywords            String     20  upcoming:event=77752
#pod   Iptc.Application2.Headline            String      3  Mie
#pod
#pod Default is false.
#pod
#pod =back
#pod
#pod =head2 search
#pod
#pod Any valid parameter that can be passed to the I<flickr.photos.search>
#pod method B<except> 'user_id' which is pre-filled with the user_id that
#pod corresponds to the B<flickr.auth_token> token.
#pod
#pod =head2 modified_since
#pod
#pod String.
#pod
#pod This specifies a time-based limiting criteria for fetching photos.
#pod
#pod The syntax is B<(n)(modifier)> where B<(n)> is a positive integer and B<(modifier)>
#pod may be one of the following:
#pod
#pod =over 4
#pod
#pod =item C<h>
#pod
#pod Fetch photos that have been modified in the last B<(n)> hours.
#pod
#pod =item C<d>
#pod
#pod Fetch photos that have been modified in the last B<(n)> days.
#pod
#pod =item C<w>
#pod
#pod Fetch photos that have been modified in the last B<(n)> weeks.
#pod
#pod =item C<M>
#pod
#pod Fetch photos that have been modified in the last B<(n)> months.
#pod
#pod =back
#pod
#pod =cut

use Carp ();
use Encode;
use JSON::PP;

use Text::Unidecode;

use File::Basename;
use File::Path;
use File::Spec;
use File::Find::Rule;

use DirHandle;

use IO::AtomicFile;
use IO::Scalar;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;

use Memoize;
use Sys::Hostname;

my %FETCH_SIZES = (
  'Medium 640'     => '_z',
  'Medium'         => '_m',
  'Original'       => '',
  'Site MP4'       => '_site',
  'Square'         => '_s',
  'Video Original' => '',
);

my $FLICKR_URL        = "https://www.flickr.com/";
my $FLICKR_URL_PHOTOS = $FLICKR_URL . "photos/";

my $UA = LWP::UserAgent->new;

#pod =head1 CLASS METHODS
#pod
#pod =cut

#pod =head2 Net::Flickr::Backup->new($cfg)
#pod
#pod Returns a I<Net::Flickr::Backup> object.
#pod
#pod =cut

# Defined in Net::Flickr::API

sub init {
  my $self = shift;
  my $cfg  = shift;

  if (! $self->SUPER::init($cfg)) {
    return undef;
  }

  # Ensure that we have 'flickr' and 'backup' config blocks

  foreach my $block ('flickr', 'backup') {

    my $test = $self->{cfg}->param(-block=>$block);

    if (! keys %$test) {
      $self->log->error("unable to find any properties for $block block in config file");
      return undef;
    }
  }

  $self->{__lastmod_since} = 0;
  $self->{__callbacks}     = {};
  $self->{__cancel}  = 0;

  $self->{__hostname} = undef;

  memoize("_clean");
  return 1;
}

#pod =head1 OBJECTS METHODS YOU SHOULD CARE ABOUT
#pod
#pod =cut

#pod =head2 $obj->backup
#pod
#pod Returns true or false.
#pod
#pod =cut

sub backup {
  my $self = shift;
  my $args = shift;

  my $auth = $self->get_auth;

  if (! $auth) {
    return 0;
  }

  my $photos_root = $self->{cfg}->param("backup.photos_root");

  if (! $photos_root) {
    $self->log->error("no photo root defined, exiting");
    return 0;
  }

  my $poll_meth;
  my $poll_args = $self->{cfg}->param(-block => "search");

  if (my $min_date = delete $poll_args->{"modified_since"}) {
    if (keys %$poll_args) {
      $self->log->error("search.modified_since provided, but also other search options, which won't work");
      return 0;
    }

    if ($min_date !~ /^\d+$/) {
      $min_date = _mk_mindate($min_date);

      if (! $min_date) {
        $self->log->error("unable to parse min date criteria, exiting");
        return 0;
      }
    }

    $poll_meth = "flickr.photos.recentlyUpdated";
    $poll_args = { min_date => $min_date };

    $self->{__lastmod_since} = $min_date;
  } else {
    $poll_meth = "flickr.photos.search";
    $poll_args->{user_id} = $auth->find("/rsp/auth/user/\@nsid")->string_value;
  }

  $self->log->info("search args ($poll_meth): " .  JSON::PP->new->canonical->encode($poll_args));

  my $num_pages    = 0;
  my $current_page = 1;

  my $poll = 1;

  while ($poll) {

    if ($self->{__cancel}) {
      last;
    }

    $poll_args->{page} = $current_page;

    my $photos = $self->api_call({
      method  => $poll_meth,
      args    => $poll_args,
    });

    if (! $photos) {
      return 0;
    }

    if (($current_page == 1) && ($self->_has_callback("start_backup_queue"))) {
      $self->_execute_callback("start_backup_queue", $photos);
    }

    $num_pages = $photos->find("/rsp/photos/\@pages")->string_value;

    foreach my $node ($photos->findnodes("/rsp/photos/photo")) {

      if ($self->{__cancel}) {
        last;
      }

      $self->{__files} = {};

      my $id      = $node->getAttribute("id");
      my $secret  = $node->getAttribute("secret");

      $self->log->info(
        sprintf "photo %s: now backing up (%s)",
        $id,
        _clean($node->getAttribute("title"))
      );

      if ($self->_has_callback("start_backup_photo")) {
        $self->_execute_callback("start_backup_photo", $node);
      }

      my $ok = $self->backup_photo($id, $secret);

      if ($self->_has_callback("finish_backup_photo")) {
        $self->_execute_callback("finish_backup_photo", $node, $ok);
      }

    }

    if ($current_page >= $num_pages) {
      $poll = 0;
    }

    $current_page ++;
  }

  if ($self->_has_callback("finish_backup_queue")) {
    $self->_execute_callback("finish_backup_queue");
  }

  if ((! $self->{__cancel}) && ($self->{cfg}->param("backup.scrub_backups"))) {
    $self->log->info("scrubbing backups");
    $self->scrub;
  }

  return 1;
}

#pod =head1 OBJECT METHODS YOU MAY CARE ABOUT
#pod
#pod =cut

#pod =head2 $obj->backup_photo($id,$secret)
#pod
#pod Backup an individual photo. This method is called internally by
#pod I<backup>.
#pod
#pod =cut

sub backup_photo {
  my $self   = shift;
  my $id     = shift;
  my $secret = shift;

  # FIX ME: add 'skip' hash containing id+secret
  # If there is a problem storing photo data, ensure
  # that it is not accidentally scrubbed.

  if (! $self->get_auth) {
    return 0;
  }

  my $force       = $self->{cfg}->param("backup.force");
  my $photos_root = $self->{cfg}->param("backup.photos_root");

  if (! $photos_root) {
    # This shouldn't be possible.  We checked for it in ->backup.
    Carp::croak("no photo root defined, exiting");
  }

  my $info = $self->api_call({
    method  =>"flickr.photos.getInfo",
    args    => {
      photo_id  => $id,
      secret    => $secret,
    },
  });

  if (! $info) {
    return 0;
  }

  $self->{_scrub}->{$id} = [];

  my $img = ($info->findnodes("/rsp/photo"))[0];

  if (! $img) {
    return 0;
  }

  my $dates = ($img->findnodes("dates"))[0];
  my $media = $img->getAttribute("media");

  my $last_update = $dates->getAttribute("lastupdate");
  my $has_changed = 1;

  my %data = (
    photo_id => $id,
    user_id  => $img->find("owner/\@nsid")->string_value,
    title    => $img->find("title")->string_value,
    taken    => $dates->getAttribute("taken"),
    posted   => $dates->getAttribute("posted"),
    lastmod  => $last_update
  );

  my $title = _clean($data{title}) || "untitled";

  my $dt = $data{taken};

  $dt =~ /^(\d{4})-(\d{2})-(\d{2})/;
  my ($yyyy,$mm,$dd) = ($1,$2,$3);

  my $sizes = $self->api_call({
    method => "flickr.photos.getSizes",
    args   => { photo_id => $id },
  });

  if (! $sizes) {
    return 0;
  }

  my $fetch_cfg = $self->{cfg}->param(-block=>"backup");

  my $files_modified = 0;

  FETCH: foreach my $label (keys %FETCH_SIZES) {
    if (
      ($media ne 'video')
      &&
      ($label eq 'Video Original' || $label eq 'Site MP4')
    ) {
      next FETCH;
    }

    my $fetch_label = lc($label);
    $fetch_label =~ s/ /_/g;

    my $fetch_param = "fetch_" . $fetch_label;
    my $do_fetch    = 1;

    if (($label !~ /Original/) || (exists($fetch_cfg->{$fetch_param}))) {
      $do_fetch = $fetch_cfg->{$fetch_param};
    }

    if (! $do_fetch) {
      $self->log->debug("photo $id: size $label: $fetch_param option is false, skipping");
      next;
    }

    my $sz = ($sizes->findnodes("/rsp/sizes/size[\@label='$label']"))[0];

    if (! $sz) {
      $self->log->warning("photo $id: size $label: no copy at this size");
      next;
    }

    my $source = $sz->getAttribute("source");

    my $ext;

    if (($label eq 'Site MP4') || ($label eq 'Video Original')) {

      my $req = HTTP::Request->new('HEAD' => $source);
      my $res = $UA->request($req);
      my $headers = $res->headers;

      my $type = $headers->content_type;
      $type =~ m{^video/([-a-z0-9]+)};

      $ext = $1 eq 'mp4' ? 'mp4'
           : $1          ? "video-$1"
           :               "video-unknown";

      $self->log->info("photo $id: size $label: using extension $ext from Content-Type $type of video");
    } else {
      # Absurd. -- rjbs, 2025-06-28
      ($ext) = $source =~ /\.([^.]{3,4})\z/;
      $self->log->info("photo $id: size $label: using extension $ext from source URL");
    }

    unless ($ext) {
      $self->log->info(qq{photo $id: size $label: using extension "unknown" as last resort});
      $ext = 'unknown';
    }

    my $img_root  = File::Spec->catdir($photos_root, $yyyy, $mm, $dd);
    my $img_fname = sprintf("%04d%02d%02d-%s-%s%s.%s", $yyyy, $mm, $dd, $id, $title, $FETCH_SIZES{$label}, $ext);

    $self->log->info("photo $id: size $label: target name is $img_fname");
    push @{$self->{_scrub}->{$id}}, $img_fname;

    my $img_bak = File::Spec->catfile($img_root, $img_fname);
    $self->{__files}->{$label} = $img_bak;

    if ((-s $img_bak) && (! $force)){

      if (! $has_changed){
        $self->log->info("photo $id: size $label: skipping, another size was up to date");
        next;
      }

      my $mtime = (stat($img_bak))[9];

      if ((-f $img_bak) && ($last_update) && ($mtime >= $last_update)){
        $self->log->info("photo $id: size $label: skippping, file has not changed ($mtime/$last_update)");
        $has_changed = 0;
        next;
      }
    }

    if (! -d $img_root) {

      $self->log->info("photo $id: size $label: create $img_root");

      if (! mkpath([$img_root], 0, 0755)) {
        $self->log->error("photo $id: size $label: failed to create $img_root: $!");
        next;
      }
    }

    my $mirror_res = $UA->mirror($source, $img_bak);
    if ($mirror_res->code == 304) {
      $self->log->info("photo $id: size $label: no changes");
    } elsif (! $mirror_res->is_success) {
      $self->log->error("photo $id: size $label: failed to store '$source' as '$img_bak'; " .  $mirror_res->status_line);
      next; # <-- give up if we could not mirror
    } else {
      $self->log->info("photo $id: size $label: stored $img_bak");
      $files_modified ++;
    }
  }

  # Ensure that we don't accidentally purge any metafiles

  my $meta_bak = $self->path_rdf_dumpfile($info);
  push @{$self->{_scrub}->{$id}}, basename($meta_bak);

  # Do we need to keep going...

  $has_changed = ($files_modified) ? 1 : 0;

  {
    my $not = $has_changed ? '' : 'not ';
    $self->log->info("photo $id: has ${not}changed: photos on disk ${not}updated");
  }

  if ((! $has_changed) && (! $force)) {
    my $lastmod = $self->{__lastmod_since};

    if (($lastmod) && ($last_update >= $lastmod)) {
      $has_changed = 1;
      $self->log->info("photo $id: has changed (photo object): $last_update > $lastmod");
    }

    # Ensure the RDF file is there and up to date

    if (! $self->{cfg}->param("rdf.rdfdump_inline")) {
      my $dump = $self->path_rdf_dumpfile($info);
      $self->log->debug("photo $id: rdf dump target: $dump");

      if (($has_changed) && (-f $dump)) {

        my $dumpmod = (stat($dump))[9];
        $self->log->debug("photo $id: rdf dump exists with mtime $dumpmod");

        if ($dumpmod >= $lastmod) {
          $has_changed = 0;
          $self->log->info("photo $id: rdf has not changed: $last_update < $dumpmod");
        }
      }

      else {
        if (! -f $dump) {
          $self->log->info("photo $id: rdf dump does not exist at $dump");
          $has_changed = 1;
        }
      }
    }

  }

  my $has = $has_changed ? 'changed' : 'not changed';
  $self->log->info("photo $id: has $has");

  # We want RDF
  if ($self->{cfg}->param("rdf.do_dump")) {
    $self->store_rdf($info, $has_changed, $force);
  }

  # We want IPTC
  if ($self->{cfg}->param("iptc.do_dump")) {
    $self->store_iptc($info, $has_changed, $force);
  }

  return 1;
}

sub store_rdf {
  my $self  = shift;
  my $photo       = shift;
  my $has_changed = shift;
  my $force       = shift;

  if (! $force){
    $force = $self->{cfg}->param("rdf.force");
  }

  my $rdf_root   = $self->{cfg}->param("rdf.rdfdump_root");
  my $rdf_inline = $self->{cfg}->param("rdf.rdfdump_inline");
  my $rdf_str    = "";

  if ((! $rdf_inline) && (! $rdf_root)) {
    $rdf_root = $self->{cfg}->param("backup.photos_root");
  }

  my $secret = $photo->find("/rsp/photo/\@originalsecret")->string_value;
  my $id     = $photo->find("/rsp/photo/\@id")->string_value;

  my $meta_bak   = $self->path_rdf_dumpfile($photo);
  my $meta_str   = "";

  if ((! $force) && (! $has_changed) && (! $rdf_inline) && (-f $meta_bak)) {
    return 1;
  }

  my $meta_root = dirname($meta_bak);

  if ((! -d $meta_root) && (! $rdf_inline)) {

    $self->log->info("photo $id: create $meta_root");

    if (! mkpath([$meta_root], 0, 0755)) {
      $self->log->error("photo $id: failed to create $meta_root, $!");
      next;
    }
  }

  $self->log->info("photo $id: fetching RDF data for photo");

  my $fh = undef;

  if ($rdf_inline) {
    $fh = IO::Scalar->new(\$rdf_str);
  }

  else {
    $fh = IO::AtomicFile->open($meta_bak, "w");
  }

  if (! $fh) {
    $self->log->error("photo $id: failed to open '$meta_bak', $!");
    return 0;
  }

  my $desc_ok = $self->describe_photo({
    photo_id => $id,
    secret   => $secret,
    fh       => \*$fh,
  });

  if (! $desc_ok) {
    $self->log->error("photo $id: failed to describe photo $id:$secret");

    if (! $rdf_inline){
      $fh->delete;
    }

    return 0;
  }

  # JPEG/RDF COM
  if ($rdf_inline) {
    if (! $self->store_rdf_inline(\$rdf_str, $self->{__files}->{Original})) {
      return 0;
    }
  }

  else {
    if (! $fh->close) {
      $self->log->error("photo $id: failed to write '$meta_bak', $!");
      return 0;
    }
  }

  return 1;
}

sub store_iptc {
  my $self = shift;
  my $photo       = shift;
  my $has_changed = shift;
  my $force       = shift;

  if ((! $has_changed) && (! $force)) {
    return 1;
  }

  return $self->store_iptc_inline($photo, $self->{__files}->{Original});
}

sub store_iptc_inline {
  my $self     = shift;
  my $photo    = shift;
  my $original = shift;

  my $im = $self->_jpeg_handler($original);

  if (! $im) {
    return 0;
  }

  my %iptc = (
    'Headline' => $self->_iptcify($photo->find("/rsp/photo/title")->string_value),
    'Caption/Abstract' => $self->_iptcify($photo->find("/rsp/photo/description")->string_value),
    'Keywords' => [],
  );

  my @tags;

  foreach my $tag ($photo->findnodes("/rsp/photo/tags/tag")) {
    my $raw = $self->_iptcify($tag->getAttribute("raw"));

    if ($raw =~ /\s/) {
      $raw = "\"$raw\"";
    }

    push @{$iptc{Keywords}}, $raw;
  }

  if (! $im->set_app13_data(\%iptc, 'UPDATE', 'IPTC')) {
    $self->log->error("Failed to updated IPTC");
    return 0;
  }

  if (! $im->save($original)) {
    $self->log->error("Failed store IPTC, $!");
    return 0;
  }

  return 1;
}

sub store_rdf_inline {
  my $self     = shift;
  my $str_rdf  = shift;
  my $path_jpg = shift;

  my $im = $self->_jpeg_handler($path_jpg, "COM");

  if (! $im) {
    return 0;
  }

  $im->add_comment($$str_rdf);

  if (! $im->save("$path_jpg")) {
    $self->log->error("Failed store COM block, $!");
    return 0;
  }

  return 1;
}

#pod =head2 $obj->scrub
#pod
#pod Returns true or false.
#pod
#pod =cut

sub scrub {
  my $self = shift;

  if (! keys %{$self->{_scrub}}) {
    return 1;
  }

  my $rule = File::Find::Rule->new;
  $rule->file;

  $rule->exec(sub {
    my ($shortname, $path, $fullname) = @_;

    $shortname =~ /^\d{8}-(\d+)-/;
    my $id = $1;

    if (! $id) {
      return 0;
    }

    if (! exists($self->{_scrub}->{$id})) {
      return 0;
    }

    if (grep /$shortname/, @{$self->{_scrub}->{$id}}) {
      return 0;
    }

    $self->log->info("mark $fullname for scrubbing");
    return 1;
  });

  foreach my $root ($rule->in($self->{cfg}->param("backup.photos_root"))) {

    $self->log->info("unlink $root");

    if (! unlink($root)) {
      $self->log->error("failed to unlink $root, $!");
      next;
    }

    # next unlink empty parent directories

    my $dd_dir   = dirname($root);
    my $mm_dir   = dirname($dd_dir);
    my $yyyy_dir = dirname($mm_dir);

    foreach my $path ($dd_dir, $mm_dir, $yyyy_dir) {
      if (&_has_children($path)) {
        last;
      }

      else {

        $self->log->info("unlink $path");

        if (! rmtree([$path], 0, 1)) {
          $self->log->error("failed to unlink, $path");
          last;
        }
      }
    }
  }

  $self->{_scrub} = {};
  return 1;
}

#pod =head2 $obj->cancel_backup
#pod
#pod Cancel the backup process as soon as the current photo backup
#pod is complete.
#pod
#pod =cut

sub cancel_backup {
  my $self = shift;
  $self->{__cancel} = 1;
}

#pod =head2 $obj->register_callback($name, \&func)
#pod
#pod B<This method is still considered experimental and may be removed.>
#pod
#pod Valid callback triggers are:
#pod
#pod =over 4
#pod
#pod =item C<start_backup_queue>
#pod
#pod The list of photos to be backed up is pulled from the Flickr servers
#pod is done in batches. This trigger is invoked for the first successful
#pod result set.
#pod
#pod The callback function will be passed a I<XML::XPath> representation
#pod of the result document returned by the Flickr API.
#pod
#pod =item C<finish_backup_queue>
#pod
#pod This trigger is invoked after the last photo has been backed up.
#pod
#pod =item C<start_backup_photo>
#pod
#pod This trigger is invoked before the object's B<backup_photo> method is
#pod called.
#pod
#pod The callback function will be passed a I<XML::XPath> representation
#pod of the current photo, as returned by the Flickr API.
#pod
#pod =item C<finish_backup_photo>
#pod
#pod This trigger is invoked after the object's B<backup_photo> method is
#pod called.
#pod
#pod The callback function will be passed a I<XML::XPath> representation
#pod of the current photo, as returned by the Flickr API, followed by a
#pod boolean indicating whether or not the backup was successful.
#pod
#pod =back
#pod
#pod Returns true or false, if I<$func> is not a valid code
#pod reference.
#pod
#pod =cut

sub register_callback {
  my $self = shift;
  my $name = shift;
  my $func = shift;

  if (ref($func) ne "CODE") {
    return 0;
  }

  $self->{__callbacks}->{$name} = $func;
  return 1;
}


#pod =head2 $obj->namespaces
#pod
#pod Returns a hash ref of the prefixes and namespaces used by I<Net::Flickr::RDF>
#pod
#pod The default key/value pairs are:
#pod
#pod =over 4
#pod
#pod =item C<a>
#pod
#pod http://www.w3.org/2000/10/annotation-ns
#pod
#pod =item C<acl>
#pod
#pod http://www.w3.org/2001/02/acls#
#pod
#pod =item C<dc>
#pod
#pod http://purl.org/dc/elements/1.1/
#pod
#pod =item C<dcterms>
#pod
#pod http://purl.org/dc/terms/
#pod
#pod =item C<exif>
#pod
#pod http://nwalsh.com/rdf/exif#
#pod
#pod =item C<exifi>
#pod
#pod http://nwalsh.com/rdf/exif-intrinsic#
#pod
#pod =item C<flickr>
#pod
#pod x-urn:flickr:
#pod
#pod =item C<foaf>
#pod
#pod http://xmlns.com/foaf/0.1/#
#pod
#pod =item C<geo>
#pod
#pod http://www.w3.org/2003/01/geo/wgs84_pos#
#pod
#pod =item C<i>
#pod
#pod http://www.w3.org/2004/02/image-regions#
#pod
#pod =item C<rdf>
#pod
#pod http://www.w3.org/1999/02/22-rdf-syntax-ns#
#pod
#pod =item C<rdfs>
#pod
#pod http://www.w3.org/2000/01/rdf-schema#
#pod
#pod =item C<skos>
#pod
#pod http://www.w3.org/2004/02/skos/core#
#pod
#pod =back
#pod
#pod I<Net::Flickr::Backup> adds the following namespaces:
#pod
#pod =over 4
#pod
#pod =item C<computer>
#pod
#pod x-urn:B<$OSNAME>: (where $OSNAME is the value of C<$^O>)
#pod
#pod =back
#pod
#pod =cut

sub namespaces {
  my $self = shift;
  my %ns = %{$self->SUPER::namespaces};
  $ns{computer} = sprintf "x-urn:%s:", $^O;
  return (wantarray) ? %ns : \%ns;
}

#pod =head2 $obj->namespace_prefix($uri)
#pod
#pod Return the namespace prefix for I<$uri>
#pod
#pod =cut

# Defined in Net::Flickr::RDF

#pod =head2 $obj->uri_shortform($prefix,$name)
#pod
#pod Returns a string in the form of I<prefix>:I<property>. The property is
#pod the value of $name. The prefix passed may or may be the same as the prefix
#pod returned depending on whether or not the user has defined or redefined their
#pod own list of namespaces.
#pod
#pod The prefix passed to the method is assumed to be one of prefixes in the
#pod B<default> list of namespaces.
#pod
#pod =cut

# Defined in Net::Flickr::RDF

#pod =head2 $obj->make_photo_triples(\%data)
#pod
#pod Returns an array ref of array refs of the meta data associated with a
#pod photo (I<%data>).
#pod
#pod If any errors are unencounter an error is recorded via the B<log>
#pod method and the method returns undef.
#pod
#pod =cut

sub make_photo_triples {
  my $self = shift;
  my $data = shift;

  my $triples = $self->SUPER::make_photo_triples($data);

  if (! $triples) {
    return undef;
  }

  my $user_id     = (getpwuid($>))[0];
  my $os_uri      = sprintf("x-urn:%s:",$^O);
  my $user_uri    = $os_uri."user";

  my $creator_uri = sprintf("x-urn:%s#%s", $self->hostname_short, $user_id);

  push @$triples, [$user_uri, $self->uri_shortform("rdfs", "subClassOf"), "http://xmlns.com/foaf/0.1/Person"];

  foreach my $label (keys %{$self->{__files}}) {

    my $uri   = "file://".$self->{__files}->{$label};
    my $photo = sprintf("%s%s/%s", $FLICKR_URL_PHOTOS, $data->{user_id}, $data->{photo_id});

    push @$triples, [$uri, $self->uri_shortform("rdfs", "seeAlso"), $photo];
    push @$triples, [$uri, $self->uri_shortform("dc", "creator"), $creator_uri];
    push @$triples, [$uri, $self->uri_shortform("dcterms", "created"), _w3cdtf() ];
  }

  push @$triples, [$creator_uri, $self->uri_shortform("foaf", "name"), (getpwuid($>))[6]];
  push @$triples, [$creator_uri, $self->uri_shortform("foaf", "nick"), $user_id];
  push @$triples, [$creator_uri, $self->uri_shortform("rdf", "type"), "computer:user"];

  return $triples;
}

sub hostname_short {
  my $self = shift;

  if ($self->{__hostname}){
    return $self->{__hostname};
  }

  my @parts = split(/\./, hostname);
  my $short = $parts[0];

  $self->{__hostname} = $short;
  return $short;
}

#pod =head2 $obj->namespace_prefix($uri)
#pod
#pod Return the namespace prefix for I<$uri>
#pod
#pod =cut

#pod =head2 $obj->uri_shortform($prefix,$name)
#pod
#pod Returns a string in the form of I<prefix>:I<property>. The property is
#pod the value of $name. The prefix passed may or may be the same as the prefix
#pod returned depending on whether or not the user has defined or redefined their
#pod own list of namespaces.
#pod
#pod The prefix passed to the method is assumed to be one of prefixes in the
#pod B<default> list of namespaces.
#pod
#pod =cut

# Defined in Net::Flickr::RDF

#pod =head2 $obj->api_call(\%args)
#pod
#pod Valid args are:
#pod
#pod =over 4
#pod
#pod =item C<method>
#pod
#pod A string containing the name of the Flickr API method you are
#pod calling.
#pod
#pod =item C<args>
#pod
#pod A hash ref containing the key value pairs you are passing to
#pod I<method>
#pod
#pod =back
#pod
#pod If the method encounters any errors calling the API, receives an API error
#pod or can not parse the response it will log an error event, via the B<log> method,
#pod and return undef.
#pod
#pod Otherwise it will return a I<XML::LibXML::Document> object (if XML::LibXML is
#pod installed) or a I<XML::XPath> object.
#pod
#pod =cut

# Defined in Net::Flickr::API

#pod =head2 $obj->log
#pod
#pod Returns a I<Log::Dispatch> object.
#pod
#pod =cut

# Defined in Net::Flickr::API

sub path_rdf_dumpfile {
  my $self  = shift;
  my $photo = shift;

  my $rdf_root   = $self->{cfg}->param("rdf.rdfdump_root");
  my $rdf_inline = $self->{cfg}->param("rdf.rdfdump_inline");
  my $rdf_str    = "";

  if ((! $rdf_inline) && (! $rdf_root)) {
    $rdf_root = $self->{cfg}->param("backup.photos_root");
  }

  my $id     = $photo->find("/rsp/photo/\@id")->string_value;
  my $secret = $photo->find("/rsp/photo/\@secret")->string_value;
  my $title  = $photo->find("/rsp/photo/title")->string_value || "untitled";
  $title     = _clean($title);

  my $dt = $photo->find("/rsp/photo/dates/\@taken")->string_value;

  $dt =~ /^(\d{4})-(\d{2})-(\d{2})/;
  my ($yyyy,$mm,$dd) = ($1,$2,$3);

  my $meta_root  = File::Spec->catdir($rdf_root, $yyyy, $mm, $dd);
  my $meta_fname = sprintf("%04d%02d%02d-%s-%s.xml", $yyyy, $mm, $dd, $id, $title);
  my $meta_path  = File::Spec->catfile($meta_root, $meta_fname);

  return $meta_path;
}

sub _clean {
  my $str = shift;

  $str = lc($str);

  $str =~ s/\.jpg$//;

  # unidecode to convert everything to
  # happy happy ASCII

  # see also: http://perladvent.org/2004/12th/

  $str = unidecode(&_unescape(&_decode($str)));

  $str =~ s/@/ at /g;
  $str =~ s/&/ and /g;
  $str =~ s/\*/ star /g;

  $str =~ s/'//g;
  $str =~ s/\^//g;

  $str =~ s/[^a-z0-9-_]/ /ig;

  # make all whitespace single spaces
  $str =~ s/\s+/ /g;

  # remove starting or trailing whitespace
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;

  # make all spaces underscores
  $str =~ s/ /_/g;

  return $str;
}

sub _decode {
  my $str = shift;

  if (! utf8::is_utf8($str)) {
    $str = decode_utf8($str);
  }

  $str =~ s/(?:%([a-fA-F0-9]{2})%([a-fA-F0-9]{2}))/pack("U0U*", hex($1), hex($2))/eg;
  return $str;
}

# Borrowed from URI::Escape

sub _unescape {
  my $str = shift;

  if (defined($str)) {
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
  }

  return $str;
}

sub _has_children {
  my $path = shift;
  my $dh = DirHandle->new($path);
  my $has = grep { $_ !~ /^\.+$/ } $dh->read;
  return $has;
}

# Borrowed from LWP::Authen::Wsse

sub _w3cdtf {
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime;
  $mon++; $year += 1900;

  return sprintf("%04s-%02s-%02sT%02s:%02s:%02sZ",
           $year, $mon, $mday, $hour, $min, $sec);
}

sub _has_callback {
  my $self = shift;
  my $name = shift;

  my $cb = $self->{__callbacks};

  if (! exists($cb->{$name})) {
    return 0;
  }

  elsif (ref($cb->{$name} ne "CODE")) {
    return 0;
  }

  else {
    return 1;
  }
}

sub _execute_callback {
  my $self = shift;
  my $name = shift;
  $self->{__callbacks}->{$name}->(@_);
}

sub _mk_mindate {
  my $str = shift;

  $str =~ /^(\d+)([hdwM])$/;

  my $count  = $1;
  my $period = $2;

  # print "count $count: period $period\n";

  if ((! $count) || (! $period)) {
    return 0;
  }

  if ($period eq "h") {
    return time - ($count * (60 * 60));
  }

  elsif ($period eq "d") {
    return time - ($count * (24 * (60 * 60)));
  }

  elsif ($period eq "w") {
    return time - ($count * (7 * (24 * (60 * 60))));
  }

  elsif ($period eq "M") {
    return time - ($count * (4 * (7 * (24 * (60 * 60)))));
  }

  else {
    return 0;
  }
}

sub _jpeg_handler {
  my $self = shift;
  my $img  = shift;

  eval "require Image::MetaData::JPEG";

  if ($@) {
    $self->log->error("Failed to load Image::MetaData::JPEG, $@");
    return undef;
  }

  my $im = Image::MetaData::JPEG->new($img, @_);

  if (! $im) {
    $self->log->error("Failed to read $img, " . Image::MetaData::JPEG::Error());
    return undef;
  }

  return $im;
}

sub _iptcify {
  my $self = shift;
  return encode("iso-8859-1", _decode($_[0]));
}

#pod =head1 EXAMPLES
#pod
#pod =cut

#pod =head2 CONFIG FILES
#pod
#pod This is an example of a Config::Simple file used to back up photos tagged
#pod with 'cameraphone' from Flickr
#pod
#pod   [flickr]
#pod   api_key=asd6234kjhdmbzcxi6e323
#pod   api_secret=s00p3rs3k3t
#pod   auth_token=123-omgwtf4u
#pod   api_handler=LibXML
#pod
#pod   [search]
#pod   tags=cameraphone
#pod   per_page=500
#pod
#pod   [backup]
#pod   photos_root=/home/asc/photos
#pod   scrub_backups=1
#pod   fetch_medium=1
#pod   fetch_square=1
#pod   force=0
#pod
#pod   [rdf]
#pod   do_dump=1
#pod   rdfdump_root=/home/asc/photos
#pod
#pod =head2 RDF
#pod
#pod This is an example of an RDF dump for a photograph backed up from
#pod Flickr (using Net::Flickr::RDF):
#pod
#pod   <?xml version='1.0'?>
#pod   <rdf:RDF
#pod    xmlns:geoname="http://www.geonames.org/onto#"
#pod    xmlns:a="http://www.w3.org/2000/10/annotation-ns"
#pod    xmlns:ph="http://www.machinetags.org/wiki/ph#camera"
#pod    xmlns:filtr="http://www.machinetags.org/wiki/filtr#process"
#pod    xmlns:nfr_geo="http://www.machinetags.org/wiki/geo#debug"
#pod    xmlns:place="x-urn:flickr:place:"
#pod    xmlns:exif="http://nwalsh.com/rdf/exif#"
#pod    xmlns:mt="x-urn:flickr:machinetag:"
#pod    xmlns:exifi="http://nwalsh.com/rdf/exif-intrinsic#"
#pod    xmlns:geonames="http://www.machinetags.org/wiki/geonames#feature"
#pod    xmlns:dcterms="http://purl.org/dc/terms/"
#pod    xmlns:dc="http://purl.org/dc/elements/1.1/"
#pod    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
#pod    xmlns:acl="http://www.w3.org/2001/02/acls#"
#pod    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
#pod    xmlns:foaf="http://xmlns.com/foaf/0.1/"
#pod    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
#pod    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#pod    xmlns:flickr="x-urn:flickr:"
#pod   >
#pod
#pod    <flickr:user rdf:about="http://www.flickr.com/people/72238590@N00">
#pod      <foaf:mbox_sha1sum>2fc2c76d7634d1a6446b1898bf5471205ed3d0cb</foaf:mbox_sha1sum>
#pod      <foaf:name></foaf:name>
#pod      <foaf:nick>thincvox</foaf:nick>
#pod    </flickr:user>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/filtr:process=filtr">
#pod      <skos:altLabel>filtr</skos:altLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/filtr:process=filtr"/>
#pod      <skos:prefLabel rdf:resource="filtr:process=filtr"/>
#pod    </flickr:tag>
#pod
#pod    <geoname:Feature rdf:about="http://ws.geonames.org/rdf?geonameId=5400754">
#pod      <geoname:featureCode>PPLX</geoname:featureCode>
#pod      <geoname:countryCode>US</geoname:countryCode>
#pod      <geoname:regionCode>CA</geoname:regionCode>
#pod      <geoname:gtopo30>58</geoname:gtopo30>
#pod      <geoname:region>State of California</geoname:region>
#pod      <geoname:city>San Francisco County</geoname:city>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </geoname:Feature>
#pod
#pod    <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/geonames#feature">
#pod      <mt:predicate>feature</mt:predicate>
#pod      <mt:namespace>geonames</mt:namespace>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:machinetag>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg">
#pod      <dcterms:relation>Original</dcterms:relation>
#pod      <exifi:height>1944</exifi:height>
#pod      <exifi:width>2592</exifi:width>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/cameraphone">
#pod      <skos:prefLabel>cameraphone</skos:prefLabel>
#pod    </flickr:tag>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/filtr">
#pod      <skos:prefLabel>filtr</skos:prefLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/filtr"/>
#pod    </flickr:tag>
#pod
#pod    <rdf:Description rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395#exif">
#pod      <exif:flash>Flash did not fire, auto mode</exif:flash>
#pod      <exif:digitalZoomRatio>100/100</exif:digitalZoomRatio>
#pod      <exif:isoSpeedRatings>100</exif:isoSpeedRatings>
#pod      <exif:pixelXDimension>2592</exif:pixelXDimension>
#pod      <exif:apertureValue>297/100</exif:apertureValue>
#pod      <exif:pixelYDimension>1944</exif:pixelYDimension>
#pod      <exif:focalLength>5.6 mm</exif:focalLength>
#pod      <exif:dateTimeDigitized>2007-05-30T15:10:01PDT</exif:dateTimeDigitized>
#pod      <exif:colorSpace>sRGB</exif:colorSpace>
#pod      <exif:fNumber>f/2.8</exif:fNumber>
#pod      <exif:dateTimeOriginal>2007-05-30T15:10:01PDT</exif:dateTimeOriginal>
#pod      <exif:shutterSpeedValue>4351/1000</exif:shutterSpeedValue>
#pod      <exif:exposureTime>0.049 sec (49/1000)</exif:exposureTime>
#pod    </rdf:Description>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/sanfrancisco">
#pod      <skos:prefLabel>san francisco</skos:prefLabel>
#pod      <skos:altLabel>sanfrancisco</skos:altLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/sanfrancisco"/>
#pod    </flickr:tag>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/sanfrancisco">
#pod      <skos:prefLabel>sanfrancisco</skos:prefLabel>
#pod    </flickr:tag>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2.jpg">
#pod      <dcterms:relation>Medium</dcterms:relation>
#pod      <exifi:height>375</exifi:height>
#pod      <exifi:width>500</exifi:width>
#pod      <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/geonames:feature=5405296">
#pod      <skos:altLabel>5405296</skos:altLabel>
#pod      <skos:broader rdf:resource="http://www.machinetags.org/wiki/geonames#feature"/>
#pod      <skos:prefLabel rdf:resource="geonames:feature=5405296"/>
#pod    </flickr:tag>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/cameraphone">
#pod      <skos:prefLabel>cameraphone</skos:prefLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/cameraphone"/>
#pod    </flickr:tag>
#pod
#pod    <flickr:photoset rdf:about="http://www.flickr.com/photos/35034348999@N01/sets/72157594459261101">
#pod      <dc:description></dc:description>
#pod      <dc:title>LOG (2007)</dc:title>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod    </flickr:photoset>
#pod
#pod    <flickr:comment rdf:about="http://www.flickr.com/photos/straup/522214395/#comment72157600293655654">
#pod      <dc:identifier>6065-522214395-72157600293655654</dc:identifier>
#pod      <dc:created>2007-05-31T14:54:25</dc:created>
#pod      <a:body>Kittens!</a:body>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:comment>
#pod
#pod    <flickr:user rdf:about="http://www.flickr.com/people/35034348999@N01">
#pod      <foaf:mbox_sha1sum>587a68f90c4030a9b0c7d8ca6ff8549a8b40e5cd</foaf:mbox_sha1sum>
#pod      <foaf:name>Aaron Straup Cope</foaf:name>
#pod      <foaf:nick>straup</foaf:nick>
#pod    </flickr:user>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/ph:camera=n95">
#pod      <skos:altLabel>n95</skos:altLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/ph:camera=n95"/>
#pod      <skos:prefLabel rdf:resource="ph:camera=n95"/>
#pod    </flickr:tag>
#pod
#pod    <rdf:Description rdf:about="x-urn:flickr:comment">
#pod      <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/10/annotation-nsAnnotation"/>
#pod    </rdf:Description>
#pod
#pod    <flickr:comment rdf:about="http://www.flickr.com/photos/straup/522214395/#comment72157600295486776">
#pod      <dc:identifier>6065-522214395-72157600295486776</dc:identifier>
#pod      <dc:created>2007-06-01T00:19:05</dc:created>
#pod      <a:body>here kitty, kitty, &lt;a href=&quot;http://thincvox.com/audio_recordings/meow.mp3&quot;&gt;meow&lt;/a&gt;</a:body>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/72238590@N00"/>
#pod      <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:comment>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/geonames:feature=5405296">
#pod      <skos:altLabel>5405296</skos:altLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/geonames:feature=5405296"/>
#pod      <skos:prefLabel rdf:resource="geonames:feature=5405296"/>
#pod    </flickr:tag>
#pod
#pod    <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/filtr#process">
#pod      <mt:predicate>process</mt:predicate>
#pod      <mt:namespace>filtr</mt:namespace>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:machinetag>
#pod
#pod    <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/geo#debug">
#pod      <mt:predicate>debug</mt:predicate>
#pod      <mt:namespace>geo</mt:namespace>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:machinetag>
#pod
#pod    <flickr:photo rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395">
#pod      <filtr:process>filtr</filtr:process>
#pod      <nfr_geo:debug>namespace test</nfr_geo:debug>
#pod      <acl:access>visbility</acl:access>
#pod      <dc:title>Untitled #1180563722</dc:title>
#pod      <ph:camera>n95</ph:camera>
#pod      <dc:rights>All rights reserved.</dc:rights>
#pod      <acl:accessor>public</acl:accessor>
#pod      <dc:description></dc:description>
#pod      <dc:created>2007-05-30T15:10:01-0700</dc:created>
#pod      <dc:dateSubmitted>2007-05-30T15:18:39-0700</dc:dateSubmitted>
#pod      <geonames:feature>5405296</geonames:feature>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/sanfrancisco"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/ph:camera=n95"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/geonames:feature=5405296"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/geo:debug=namespacetest"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/filtr:process=filtr"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/filtr"/>
#pod      <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/cameraphone"/>
#pod      <dcterms:isPartOf rdf:resource="http://www.flickr.com/photos/35034348999@N01/sets/72157594459261101"/>
#pod      <a:hasAnnotation rdf:resource="http://www.flickr.com/photos/straup/522214395/#comment72157600295486776"/>
#pod      <a:hasAnnotation rdf:resource="http://www.flickr.com/photos/straup/522214395/#comment72157600293655654"/>
#pod      <geo:Point rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#location"/>
#pod    </flickr:photo>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_t.jpg">
#pod      <dcterms:relation>Thumbnail</dcterms:relation>
#pod      <exifi:height>75</exifi:height>
#pod      <exifi:width>100</exifi:width>
#pod      <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <rdf:Description rdf:about="x-urn:flickr:machinetag">
#pod      <rdfs:subClassOf rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
#pod    </rdf:Description>
#pod
#pod    <geo:Point rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395#location">
#pod      <geo:long>-122.401937</geo:long>
#pod      <acl:access>visbility</acl:access>
#pod      <geo:lat>37.794694</geo:lat>
#pod      <flickr:accuracy>16</flickr:accuracy>
#pod      <acl:accessor>public</acl:accessor>
#pod      <skos:broader rdf:resource="http://ws.geonames.org/rdf?geonameId=5400754"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/geo/United%20States/California/San%20Francisco/San%20Francisco"/>
#pod    </geo:Point>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/filtr:process=filtr">
#pod      <skos:altLabel>filtr</skos:altLabel>
#pod      <skos:broader rdf:resource="http://www.machinetags.org/wiki/filtr#process"/>
#pod      <skos:prefLabel rdf:resource="filtr:process=filtr"/>
#pod    </flickr:tag>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/ph:camera=n95">
#pod      <skos:altLabel>n95</skos:altLabel>
#pod      <skos:broader rdf:resource="http://www.machinetags.org/wiki/ph#camera"/>
#pod      <skos:prefLabel rdf:resource="ph:camera=n95"/>
#pod    </flickr:tag>
#pod
#pod    <rdf:Description rdf:about="#">
#pod      <dcterms:hasVersion>2.0:1180823550</dcterms:hasVersion>
#pod      <dc:created>2007-06-02T15:32:30-0700</dc:created>
#pod      <dc:creator rdf:resource="http://search.cpan.org/dist/Net-Flickr-RDF-2.0"/>
#pod      <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </rdf:Description>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/filtr">
#pod      <skos:prefLabel>filtr</skos:prefLabel>
#pod    </flickr:tag>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/geo:debug=namespacetest">
#pod      <skos:altLabel>namespace test</skos:altLabel>
#pod      <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
#pod      <skos:broader rdf:resource="http://www.flickr.com/photos/tags/geo:debug=namespacetest"/>
#pod      <skos:prefLabel rdf:resource="geo:debug=namespace test"/>
#pod      <skos:altLabel rdf:resource="geo:debug=namespacetest"/>
#pod    </flickr:tag>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_m.jpg">
#pod      <dcterms:relation>Small</dcterms:relation>
#pod      <exifi:height>180</exifi:height>
#pod      <exifi:width>240</exifi:width>
#pod      <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <rdf:Description rdf:about="x-urn:flickr:user">
#pod      <rdfs:subClassOf rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
#pod    </rdf:Description>
#pod
#pod    <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/ph#camera">
#pod      <mt:predicate>camera</mt:predicate>
#pod      <mt:namespace>ph</mt:namespace>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:machinetag>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_s.jpg">
#pod      <dcterms:relation>Square</dcterms:relation>
#pod      <exifi:height>75</exifi:height>
#pod      <exifi:width>75</exifi:width>
#pod      <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_b.jpg">
#pod      <dcterms:relation>Large</dcterms:relation>
#pod      <exifi:height>768</exifi:height>
#pod      <exifi:width>1024</exifi:width>
#pod      <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod      <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
#pod    </dcterms:StillImage>
#pod
#pod    <flickr:place rdf:about="http://www.flickr.com/geo/United%20States/California/San%20Francisco/San%20Francisco">
#pod      <place:county>San Francisco</place:county>
#pod      <place:country>United States</place:country>
#pod      <place:region>California</place:region>
#pod      <place:locality>San Francisco</place:locality>
#pod      <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
#pod    </flickr:place>
#pod
#pod    <flickr:tag rdf:about="http://www.flickr.com/photos/tags/geo:debug=namespacetest">
#pod      <skos:altLabel>namespace test</skos:altLabel>
#pod      <skos:broader rdf:resource="http://www.machinetags.org/wiki/geo#debug"/>
#pod      <skos:prefLabel rdf:resource="geo:debug=namespacetest"/>
#pod    </flickr:tag>
#pod
#pod  </rdf:RDF>
#pod
#pod =head1 CONTRIBUTORS
#pod
#pod Thomas Sibley E<lt>tsibley@cpan.orgE<gt>
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Net::Flickr::API>
#pod
#pod L<Net::Flickr::RDF>
#pod
#pod L<Config::Simple>
#pod
#pod L<Flickr's user authentication page|https://www.flickr.com/services/api/auth.oauth.html>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Flickr::Backup - OOP for backing up your Flickr photos locally

=head1 VERSION

version 3.200

=head1 SYNOPSIS

  use Net::Flickr::Backup;
  use Log::Dispatch::Screen;

  my $flickr = Net::Flickr::Backup->new($cfg);

  my $feedback = Log::Dispatch::Screen->new(
    'name'      => 'info',
    'min_level' => 'info',
  );

  $flickr->log->add($feedback);
  $flickr->backup;

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 OPTIONS

Options are passed to Net::Flickr::Backup using a Config::Simple object or
a valid Config::Simple config file. Options are grouped by "block".

=head2 flickr

=over 4

=item C<api_key>

String. I<required>

A valid Flickr API key.

=item C<api_secret>

String. I<required>

A valid Flickr Auth API secret key.

=item C<auth_token>

String. I<required>

A valid Flickr Auth API token.

The C<api_handler> defines which XML/XPath handler to use to process API responses.

=over 4

=item C<LibXML>

Use XML::LibXML.

=item C<XPath>

Use XML::XPath.

=back

=back

=head2 backup

=over 4

=item C<photos_root>

String. I<required>

The root folder where you want photographs to be stored. Individual
files are named using the following pattern:

  <photos_root>/<YYYY>/<MM>/<DD>/<YYYYMMDD>-<photo_id>-<clean_title>_<size>.jpg

Where the various components are:

=over 4

=item C<YYYYMMDD>

  photo[@id=123]/dates/@taken

=item C<photo_id>

  photo/@id

=item C<clean_title>

  photo[@id=123]/title

Unicode characters translated in to ASCII (using Text::Unidecode) and the
entire string is stripped anything that is not an alphanumeric, underbar,
dash or a square bracket.

=item C<size>

Net::Flickr::Backup will attempt to fetch not only the original file uploaded
to Flickr but also, depending on your config options, the medium and square
versions. Filenames will be modified as follows:

=over 4

=item C<original>

The original photo you uploaded to the Flickr servers. No extension is
added.

=item C<medium>

These photos are scaled to 500 pixels at the longest dimension. A B<_m>
extension is added.

=item C<medium_640>

These photos are scaled to 640 pixels at the longest dimension. A B<_z>
extension is added.

=item C<square>

These photos are to cropped to 75 x 75 pixels at the center. A B<_s>
extension is added.

=item C<site_mp4>

The MP4 version of a video uploaded to Flickr. A B<_site> extension is added.

=item C<video_original>

An original video uploaded to Flickr. No extentsion is added.

=back

=back

=item C<fetch_original>

Boolean.

Retrieve the "original" version of a photo from the Flickr servers.

Default is true.

=item C<fetch_video_original>

Boolean.

Retrieve the "original" version of a video from the Flickr servers.

Default is true.

=item C<fetch_medium>

Boolean.

Retrieve the "medium" version of a photo from the Flickr servers; these photos
have been scaled to 500 pixels at the longest dimension.

Default is false.

=item C<fetch_medium_640>

Boolean.

Retrieve the "medium" version of a photo from the Flickr servers; these photos
have been scaled to 640 pixels at the longest dimension.

Default is false.

=item C<fetch_square>

Boolean.

Retrieve the "square" version of a photo from the Flickr servers; these photos
have been cropped to 75 x 75 pixels at the center.

Default is false.

=item C<fetch_site_mp4>

Boolean.

Retrieve the "site MP4" version of a video from the Flickr servers;

Default is false.

=item C<scrub_backups>

Boolean.

If true then, for each Flickr photo ID backed up, the library will check
B<backup.photos_root> for images (and metadata files) with a matching ID but
a different name. Matches will be deleted.

=item C<force>

Boolean.

Force a photograph to be backed up even if it has not changed.

Default is false.

=back

=head2 rdf

=over 4

=item C<do_dump>

Boolean.

Generate an RDF description for each photograph. Descriptions
are written to disk in separate files.

Default is false.

=item C<rdfdump_root>

String.

The path where RDF data dumps for a photo should be written. The default
is the same path as B<backup.photos_root>.

File names are generated with the same pattern used to name
photographs.

=item C<rdfdump_inline>

Boolean.

Set to true if you want the RDF dump for a photo to be stored in the file's
JPEG COM block. RDF data will only be stored (for the time being) in the original
image file and not any of the scaled versions.

This option will only work for JPEG files and is still B<experimental>. It may change
or, you know, not always work. Using Adobe's XMP spec is on the list of things to poke
at so if you've got any suggestions on the subject, they'd be welcome.

Default is false.

=item C<photos_alias>

String.

If defined this string is applied as regular expression substitution to
B<backup.photos_root>.

Default is to append the B<file:/> URI protocol to a path.

=item C<query_geonames>

Boolean.

If true and a photo has geodata (latitude, longitude) associated with it, then
the geonames.org database will be queried for a corresponding match. Data will
be added as properties of the photo's geo:Point description. For example:

  <geo:Point rdf:about="http://www.flickr.com/photos/35034348999@N01/272880469#location">
    <geo:long>-122.025151</geo:long>
    <flickr:accuracy>16</flickr:accuracy>
    <acl:access>visbility</acl:access>
    <geo:lat>37.417839</geo:lat>
    <acl:accessor>public</acl:accessor>
    <geoname:Feature rdf:resource="http://ws.geonames.org/rdf?geonameId=5409655"/>
  </geo:Point>

  <geoname:Feature rdf:about="http://ws.geonames.org/rdf?geonameId=5409655">
    <geoname:featureCode>PPLX</geoname:featureCode>
    <geoname:countryCode>US</geoname:countryCode>
    <geoname:regionCode>CA</geoname:regionCode>
    <geoname:region>California</geoname:region>
    <geoname:city>Santa Clara</geoname:city>
    <geoname:gtopo30>2</geoname:gtopo30>
  </geoname:Feature>

=back

=head2 iptc

=over 4

=item C<do_dump>

Boolean.

If true, then a limited set of metadata associated with a photo will be stored
as IPTC information.

A photo's title is stored as the IPTC B<Headline>, description as B<Caption/Abstract>
and tags are stored in one or more B<Keyword> headers. Per the IPTC 7901 spec,
all text is converted to the ISO-8859-1 character encoding.

For example:

  exiv2 -pi /home/asc/photos/2006/06/20/20060620-171674319-mie.jpg
  Iptc.Application2.RecordVersion       Short       1  2
  Iptc.Application2.Keywords            String     11  cameraphone
  Iptc.Application2.Keywords            String     15  "san francisco"
  Iptc.Application2.Keywords            String      5  filtr
  Iptc.Application2.Keywords            String      3  mie
  Iptc.Application2.Keywords            String     20  upcoming:event=77752
  Iptc.Application2.Headline            String      3  Mie

Default is false.

=back

=head2 search

Any valid parameter that can be passed to the I<flickr.photos.search>
method B<except> 'user_id' which is pre-filled with the user_id that
corresponds to the B<flickr.auth_token> token.

=head2 modified_since

String.

This specifies a time-based limiting criteria for fetching photos.

The syntax is B<(n)(modifier)> where B<(n)> is a positive integer and B<(modifier)>
may be one of the following:

=over 4

=item C<h>

Fetch photos that have been modified in the last B<(n)> hours.

=item C<d>

Fetch photos that have been modified in the last B<(n)> days.

=item C<w>

Fetch photos that have been modified in the last B<(n)> weeks.

=item C<M>

Fetch photos that have been modified in the last B<(n)> months.

=back

=head1 CLASS METHODS

=head2 Net::Flickr::Backup->new($cfg)

Returns a I<Net::Flickr::Backup> object.

=head1 OBJECTS METHODS YOU SHOULD CARE ABOUT

=head2 $obj->backup

Returns true or false.

=head1 OBJECT METHODS YOU MAY CARE ABOUT

=head2 $obj->backup_photo($id,$secret)

Backup an individual photo. This method is called internally by
I<backup>.

=head2 $obj->scrub

Returns true or false.

=head2 $obj->cancel_backup

Cancel the backup process as soon as the current photo backup
is complete.

=head2 $obj->register_callback($name, \&func)

B<This method is still considered experimental and may be removed.>

Valid callback triggers are:

=over 4

=item C<start_backup_queue>

The list of photos to be backed up is pulled from the Flickr servers
is done in batches. This trigger is invoked for the first successful
result set.

The callback function will be passed a I<XML::XPath> representation
of the result document returned by the Flickr API.

=item C<finish_backup_queue>

This trigger is invoked after the last photo has been backed up.

=item C<start_backup_photo>

This trigger is invoked before the object's B<backup_photo> method is
called.

The callback function will be passed a I<XML::XPath> representation
of the current photo, as returned by the Flickr API.

=item C<finish_backup_photo>

This trigger is invoked after the object's B<backup_photo> method is
called.

The callback function will be passed a I<XML::XPath> representation
of the current photo, as returned by the Flickr API, followed by a
boolean indicating whether or not the backup was successful.

=back

Returns true or false, if I<$func> is not a valid code
reference.

=head2 $obj->namespaces

Returns a hash ref of the prefixes and namespaces used by I<Net::Flickr::RDF>

The default key/value pairs are:

=over 4

=item C<a>

http://www.w3.org/2000/10/annotation-ns

=item C<acl>

http://www.w3.org/2001/02/acls#

=item C<dc>

http://purl.org/dc/elements/1.1/

=item C<dcterms>

http://purl.org/dc/terms/

=item C<exif>

http://nwalsh.com/rdf/exif#

=item C<exifi>

http://nwalsh.com/rdf/exif-intrinsic#

=item C<flickr>

x-urn:flickr:

=item C<foaf>

http://xmlns.com/foaf/0.1/#

=item C<geo>

http://www.w3.org/2003/01/geo/wgs84_pos#

=item C<i>

http://www.w3.org/2004/02/image-regions#

=item C<rdf>

http://www.w3.org/1999/02/22-rdf-syntax-ns#

=item C<rdfs>

http://www.w3.org/2000/01/rdf-schema#

=item C<skos>

http://www.w3.org/2004/02/skos/core#

=back

I<Net::Flickr::Backup> adds the following namespaces:

=over 4

=item C<computer>

x-urn:B<$OSNAME>: (where $OSNAME is the value of C<$^O>)

=back

=head2 $obj->namespace_prefix($uri)

Return the namespace prefix for I<$uri>

=head2 $obj->uri_shortform($prefix,$name)

Returns a string in the form of I<prefix>:I<property>. The property is
the value of $name. The prefix passed may or may be the same as the prefix
returned depending on whether or not the user has defined or redefined their
own list of namespaces.

The prefix passed to the method is assumed to be one of prefixes in the
B<default> list of namespaces.

=head2 $obj->make_photo_triples(\%data)

Returns an array ref of array refs of the meta data associated with a
photo (I<%data>).

If any errors are unencounter an error is recorded via the B<log>
method and the method returns undef.

=head2 $obj->namespace_prefix($uri)

Return the namespace prefix for I<$uri>

=head2 $obj->uri_shortform($prefix,$name)

Returns a string in the form of I<prefix>:I<property>. The property is
the value of $name. The prefix passed may or may be the same as the prefix
returned depending on whether or not the user has defined or redefined their
own list of namespaces.

The prefix passed to the method is assumed to be one of prefixes in the
B<default> list of namespaces.

=head2 $obj->api_call(\%args)

Valid args are:

=over 4

=item C<method>

A string containing the name of the Flickr API method you are
calling.

=item C<args>

A hash ref containing the key value pairs you are passing to
I<method>

=back

If the method encounters any errors calling the API, receives an API error
or can not parse the response it will log an error event, via the B<log> method,
and return undef.

Otherwise it will return a I<XML::LibXML::Document> object (if XML::LibXML is
installed) or a I<XML::XPath> object.

=head2 $obj->log

Returns a I<Log::Dispatch> object.

=head1 EXAMPLES

=head2 CONFIG FILES

This is an example of a Config::Simple file used to back up photos tagged
with 'cameraphone' from Flickr

  [flickr]
  api_key=asd6234kjhdmbzcxi6e323
  api_secret=s00p3rs3k3t
  auth_token=123-omgwtf4u
  api_handler=LibXML

  [search]
  tags=cameraphone
  per_page=500

  [backup]
  photos_root=/home/asc/photos
  scrub_backups=1
  fetch_medium=1
  fetch_square=1
  force=0

  [rdf]
  do_dump=1
  rdfdump_root=/home/asc/photos

=head2 RDF

This is an example of an RDF dump for a photograph backed up from
Flickr (using Net::Flickr::RDF):

  <?xml version='1.0'?>
  <rdf:RDF
   xmlns:geoname="http://www.geonames.org/onto#"
   xmlns:a="http://www.w3.org/2000/10/annotation-ns"
   xmlns:ph="http://www.machinetags.org/wiki/ph#camera"
   xmlns:filtr="http://www.machinetags.org/wiki/filtr#process"
   xmlns:nfr_geo="http://www.machinetags.org/wiki/geo#debug"
   xmlns:place="x-urn:flickr:place:"
   xmlns:exif="http://nwalsh.com/rdf/exif#"
   xmlns:mt="x-urn:flickr:machinetag:"
   xmlns:exifi="http://nwalsh.com/rdf/exif-intrinsic#"
   xmlns:geonames="http://www.machinetags.org/wiki/geonames#feature"
   xmlns:dcterms="http://purl.org/dc/terms/"
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
   xmlns:acl="http://www.w3.org/2001/02/acls#"
   xmlns:skos="http://www.w3.org/2004/02/skos/core#"
   xmlns:foaf="http://xmlns.com/foaf/0.1/"
   xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:flickr="x-urn:flickr:"
  >

   <flickr:user rdf:about="http://www.flickr.com/people/72238590@N00">
     <foaf:mbox_sha1sum>2fc2c76d7634d1a6446b1898bf5471205ed3d0cb</foaf:mbox_sha1sum>
     <foaf:name></foaf:name>
     <foaf:nick>thincvox</foaf:nick>
   </flickr:user>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/filtr:process=filtr">
     <skos:altLabel>filtr</skos:altLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/filtr:process=filtr"/>
     <skos:prefLabel rdf:resource="filtr:process=filtr"/>
   </flickr:tag>

   <geoname:Feature rdf:about="http://ws.geonames.org/rdf?geonameId=5400754">
     <geoname:featureCode>PPLX</geoname:featureCode>
     <geoname:countryCode>US</geoname:countryCode>
     <geoname:regionCode>CA</geoname:regionCode>
     <geoname:gtopo30>58</geoname:gtopo30>
     <geoname:region>State of California</geoname:region>
     <geoname:city>San Francisco County</geoname:city>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </geoname:Feature>

   <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/geonames#feature">
     <mt:predicate>feature</mt:predicate>
     <mt:namespace>geonames</mt:namespace>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:machinetag>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg">
     <dcterms:relation>Original</dcterms:relation>
     <exifi:height>1944</exifi:height>
     <exifi:width>2592</exifi:width>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/cameraphone">
     <skos:prefLabel>cameraphone</skos:prefLabel>
   </flickr:tag>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/filtr">
     <skos:prefLabel>filtr</skos:prefLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/filtr"/>
   </flickr:tag>

   <rdf:Description rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395#exif">
     <exif:flash>Flash did not fire, auto mode</exif:flash>
     <exif:digitalZoomRatio>100/100</exif:digitalZoomRatio>
     <exif:isoSpeedRatings>100</exif:isoSpeedRatings>
     <exif:pixelXDimension>2592</exif:pixelXDimension>
     <exif:apertureValue>297/100</exif:apertureValue>
     <exif:pixelYDimension>1944</exif:pixelYDimension>
     <exif:focalLength>5.6 mm</exif:focalLength>
     <exif:dateTimeDigitized>2007-05-30T15:10:01PDT</exif:dateTimeDigitized>
     <exif:colorSpace>sRGB</exif:colorSpace>
     <exif:fNumber>f/2.8</exif:fNumber>
     <exif:dateTimeOriginal>2007-05-30T15:10:01PDT</exif:dateTimeOriginal>
     <exif:shutterSpeedValue>4351/1000</exif:shutterSpeedValue>
     <exif:exposureTime>0.049 sec (49/1000)</exif:exposureTime>
   </rdf:Description>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/sanfrancisco">
     <skos:prefLabel>san francisco</skos:prefLabel>
     <skos:altLabel>sanfrancisco</skos:altLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/sanfrancisco"/>
   </flickr:tag>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/sanfrancisco">
     <skos:prefLabel>sanfrancisco</skos:prefLabel>
   </flickr:tag>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2.jpg">
     <dcterms:relation>Medium</dcterms:relation>
     <exifi:height>375</exifi:height>
     <exifi:width>500</exifi:width>
     <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/geonames:feature=5405296">
     <skos:altLabel>5405296</skos:altLabel>
     <skos:broader rdf:resource="http://www.machinetags.org/wiki/geonames#feature"/>
     <skos:prefLabel rdf:resource="geonames:feature=5405296"/>
   </flickr:tag>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/cameraphone">
     <skos:prefLabel>cameraphone</skos:prefLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/cameraphone"/>
   </flickr:tag>

   <flickr:photoset rdf:about="http://www.flickr.com/photos/35034348999@N01/sets/72157594459261101">
     <dc:description></dc:description>
     <dc:title>LOG (2007)</dc:title>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
   </flickr:photoset>

   <flickr:comment rdf:about="http://www.flickr.com/photos/straup/522214395/#comment72157600293655654">
     <dc:identifier>6065-522214395-72157600293655654</dc:identifier>
     <dc:created>2007-05-31T14:54:25</dc:created>
     <a:body>Kittens!</a:body>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:comment>

   <flickr:user rdf:about="http://www.flickr.com/people/35034348999@N01">
     <foaf:mbox_sha1sum>587a68f90c4030a9b0c7d8ca6ff8549a8b40e5cd</foaf:mbox_sha1sum>
     <foaf:name>Aaron Straup Cope</foaf:name>
     <foaf:nick>straup</foaf:nick>
   </flickr:user>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/ph:camera=n95">
     <skos:altLabel>n95</skos:altLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/ph:camera=n95"/>
     <skos:prefLabel rdf:resource="ph:camera=n95"/>
   </flickr:tag>

   <rdf:Description rdf:about="x-urn:flickr:comment">
     <rdfs:subClassOf rdf:resource="http://www.w3.org/2000/10/annotation-nsAnnotation"/>
   </rdf:Description>

   <flickr:comment rdf:about="http://www.flickr.com/photos/straup/522214395/#comment72157600295486776">
     <dc:identifier>6065-522214395-72157600295486776</dc:identifier>
     <dc:created>2007-06-01T00:19:05</dc:created>
     <a:body>here kitty, kitty, &lt;a href=&quot;http://thincvox.com/audio_recordings/meow.mp3&quot;&gt;meow&lt;/a&gt;</a:body>
     <dc:creator rdf:resource="http://www.flickr.com/people/72238590@N00"/>
     <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:comment>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/geonames:feature=5405296">
     <skos:altLabel>5405296</skos:altLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/geonames:feature=5405296"/>
     <skos:prefLabel rdf:resource="geonames:feature=5405296"/>
   </flickr:tag>

   <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/filtr#process">
     <mt:predicate>process</mt:predicate>
     <mt:namespace>filtr</mt:namespace>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:machinetag>

   <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/geo#debug">
     <mt:predicate>debug</mt:predicate>
     <mt:namespace>geo</mt:namespace>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:machinetag>

   <flickr:photo rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395">
     <filtr:process>filtr</filtr:process>
     <nfr_geo:debug>namespace test</nfr_geo:debug>
     <acl:access>visbility</acl:access>
     <dc:title>Untitled #1180563722</dc:title>
     <ph:camera>n95</ph:camera>
     <dc:rights>All rights reserved.</dc:rights>
     <acl:accessor>public</acl:accessor>
     <dc:description></dc:description>
     <dc:created>2007-05-30T15:10:01-0700</dc:created>
     <dc:dateSubmitted>2007-05-30T15:18:39-0700</dc:dateSubmitted>
     <geonames:feature>5405296</geonames:feature>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/sanfrancisco"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/ph:camera=n95"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/geonames:feature=5405296"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/geo:debug=namespacetest"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/filtr:process=filtr"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/filtr"/>
     <dc:subject rdf:resource="http://www.flickr.com/photos/35034348999@N01/tags/cameraphone"/>
     <dcterms:isPartOf rdf:resource="http://www.flickr.com/photos/35034348999@N01/sets/72157594459261101"/>
     <a:hasAnnotation rdf:resource="http://www.flickr.com/photos/straup/522214395/#comment72157600295486776"/>
     <a:hasAnnotation rdf:resource="http://www.flickr.com/photos/straup/522214395/#comment72157600293655654"/>
     <geo:Point rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#location"/>
   </flickr:photo>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_t.jpg">
     <dcterms:relation>Thumbnail</dcterms:relation>
     <exifi:height>75</exifi:height>
     <exifi:width>100</exifi:width>
     <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <rdf:Description rdf:about="x-urn:flickr:machinetag">
     <rdfs:subClassOf rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
   </rdf:Description>

   <geo:Point rdf:about="http://www.flickr.com/photos/35034348999@N01/522214395#location">
     <geo:long>-122.401937</geo:long>
     <acl:access>visbility</acl:access>
     <geo:lat>37.794694</geo:lat>
     <flickr:accuracy>16</flickr:accuracy>
     <acl:accessor>public</acl:accessor>
     <skos:broader rdf:resource="http://ws.geonames.org/rdf?geonameId=5400754"/>
     <skos:broader rdf:resource="http://www.flickr.com/geo/United%20States/California/San%20Francisco/San%20Francisco"/>
   </geo:Point>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/filtr:process=filtr">
     <skos:altLabel>filtr</skos:altLabel>
     <skos:broader rdf:resource="http://www.machinetags.org/wiki/filtr#process"/>
     <skos:prefLabel rdf:resource="filtr:process=filtr"/>
   </flickr:tag>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/ph:camera=n95">
     <skos:altLabel>n95</skos:altLabel>
     <skos:broader rdf:resource="http://www.machinetags.org/wiki/ph#camera"/>
     <skos:prefLabel rdf:resource="ph:camera=n95"/>
   </flickr:tag>

   <rdf:Description rdf:about="#">
     <dcterms:hasVersion>2.0:1180823550</dcterms:hasVersion>
     <dc:created>2007-06-02T15:32:30-0700</dc:created>
     <dc:creator rdf:resource="http://search.cpan.org/dist/Net-Flickr-RDF-2.0"/>
     <a:annotates rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </rdf:Description>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/filtr">
     <skos:prefLabel>filtr</skos:prefLabel>
   </flickr:tag>

   <flickr:tag rdf:about="http://www.flickr.com/photos/35034348999@N01/tags/geo:debug=namespacetest">
     <skos:altLabel>namespace test</skos:altLabel>
     <dc:creator rdf:resource="http://www.flickr.com/people/35034348999@N01"/>
     <skos:broader rdf:resource="http://www.flickr.com/photos/tags/geo:debug=namespacetest"/>
     <skos:prefLabel rdf:resource="geo:debug=namespace test"/>
     <skos:altLabel rdf:resource="geo:debug=namespacetest"/>
   </flickr:tag>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_m.jpg">
     <dcterms:relation>Small</dcterms:relation>
     <exifi:height>180</exifi:height>
     <exifi:width>240</exifi:width>
     <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <rdf:Description rdf:about="x-urn:flickr:user">
     <rdfs:subClassOf rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
   </rdf:Description>

   <flickr:machinetag rdf:about="http://www.machinetags.org/wiki/ph#camera">
     <mt:predicate>camera</mt:predicate>
     <mt:namespace>ph</mt:namespace>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:machinetag>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_s.jpg">
     <dcterms:relation>Square</dcterms:relation>
     <exifi:height>75</exifi:height>
     <exifi:width>75</exifi:width>
     <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <dcterms:StillImage rdf:about="http://farm1.static.flickr.com/232/522214395_ed16f959a2_b.jpg">
     <dcterms:relation>Large</dcterms:relation>
     <exifi:height>768</exifi:height>
     <exifi:width>1024</exifi:width>
     <dcterms:isVersionOf rdf:resource="http://farm1.static.flickr.com/232/522214395_d2841bdbb0_o.jpg"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
     <rdfs:seeAlso rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395#exif"/>
   </dcterms:StillImage>

   <flickr:place rdf:about="http://www.flickr.com/geo/United%20States/California/San%20Francisco/San%20Francisco">
     <place:county>San Francisco</place:county>
     <place:country>United States</place:country>
     <place:region>California</place:region>
     <place:locality>San Francisco</place:locality>
     <dc:isReferencedBy rdf:resource="http://www.flickr.com/photos/35034348999@N01/522214395"/>
   </flickr:place>

   <flickr:tag rdf:about="http://www.flickr.com/photos/tags/geo:debug=namespacetest">
     <skos:altLabel>namespace test</skos:altLabel>
     <skos:broader rdf:resource="http://www.machinetags.org/wiki/geo#debug"/>
     <skos:prefLabel rdf:resource="geo:debug=namespacetest"/>
   </flickr:tag>

 </rdf:RDF>

=head1 CONTRIBUTORS

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 SEE ALSO

L<Net::Flickr::API>

L<Net::Flickr::RDF>

L<Config::Simple>

L<Flickr's user authentication page|https://www.flickr.com/services/api/auth.oauth.html>

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Ricardo Signes Thomas Sibley

=over 4

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Thomas Sibley <tsibley@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Aaron Straup Cope.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
