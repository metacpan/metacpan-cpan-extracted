package Net::XIPCloud;

use strict;
use Fcntl;
use Data::Dumper;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use File::stat;
use LWP::UserAgent;
use HTTP::Request;
use IO::Socket::SSL;
require Exporter;

our $VERSION = '0.7';

@ISA = qw(Exporter);
@EXPORT = qw();

=head1 NAME

Net::XIPCloud - Perl extension for interacting with Internap's XIPCloud storage platform

=head1 SYNOPSIS

use Net::XIPCloud;

my $xip = Net::XIPCloud->new( username => 'myusername', password => 'mypassword );

$xip->connect();

$xip->cp("fromcontainer","fromobject","tocontainer","toobject");

$xip->mv("fromcontainer","fromobject","tocontainer","toobject");

$xip->file("somecontainer","someobject");

$xip->file("somecontainer/some/pseudo/path/to/object");

$xip->ls();

$xip->ls("mycontainer");

$xip->ls("mycontainer/some/pseudo/path/");

$xip->mkdir("newcontainer");

$xip->mkdir("newcontainer/some/pseudo/path/");

$xip->rmdir("somecontainer");

$xip->du();

$xip->du("somecontainer");

my $data = $xip->get_value("somecontainer","someobject");

$xip->get_file("somecontainer","someobject","/tmp/someobject");

$xip->put_value("somecontainer","someobject",$data,"text/html");

$xip->put_file("somecontainer","someobject","/tmp/someobject","text/html");

$xip->get_fhstream("somecontainer","someobject",*STDOUT);

$xip->rm("somecontainer","someobject");

$xip->create_manifest("somecontainer","someobject");

$xip->chmod("somecontainer","public");

$xip->cdn("somecontainer","enable","logs",300);

$xip->cdn("somecontainer","disable");

$xip->cdn("somecontainer");

$xip->cdn();

=head1 DESCRIPTION

This perl module creates an XIPCloud object, which allows direct manipulation of objects and containers
within Internap's XIPCloud storage.

A valid XIPCloud account is required to use this module

=cut

=head2 new( username => 'username', password => 'password');

Returns a reference to a new XIPCloud object. This method requires passing of a valid username and password.

=cut

sub new() {
  my $class = shift;
  my %args = @_;
  my $self = {};

  bless $self, $class;

  # default values for API and version
  $self->{api_url} = 'https://auth.storage.santa-clara.internapcloud.net:443/';
  $self->{api_version} = 'v1.0';

  # stash remaining arguments in object
  foreach my $el (keys %args) {
    $self->{$el} = $args{$el};
  }
  return $self;
}

=head2 connect()

Connects to XIPCloud using the username and password provids in the new() call.

Method returns 1 for success and undef for failure.

=cut

sub connect() {
  my $self = shift;
  my $status = undef;

  # prepare authentication headers
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(GET => $self->{api_url}.$self->{api_version});
  $req->header( 'X-AUTH-USER' => $self->{username} );
  $req->header( 'X-AUTH-KEY' => $self->{password} );

  # dispatch request
  my $res = $ua->request($req);

  # persist state on connect
  if ($res->is_success) {
    $status = 1;
    $self->{connected} = 1;
    $self->{storage_token} = $res->header( 'x-storage-token' );
    $self->{storage_url} = $res->header( 'x-storage-url' );
    $self->{cdn_url} = $res->header( 'x-cdn-management-url' );
    $self->{debug} && print "connected: token [".$self->{storage_token}."] url [".$self->{storage_url}."] cdn [".$self->{cdn_url}."]\n";
  }

  # fail
  else {
    $self->{debug} && print "connection failed\n";
  }

  return $status;
}

=head2 ls([CONTAINER])

Depending on the calling arguments, this method returns the list of containers or list
of objects within a single container as an array reference.

Limit and marker values may be provided (see API documentation) for pagination.

=cut

sub ls() {
  my $self = shift;
  my $container = shift;
  my $limit = shift;
  my $marker = shift;
  my $list = [];
  my $path = undef;

  # make sure we have an active connection
  return undef unless ($self->{connected});

  # prepare LWP object for connection
  my $ua = LWP::UserAgent->new;
  my $requrl = $self->{storage_url};

  # let caller specify a pseudo path
  if ($container =~ /\//) {
    split('/',$container); 
    $container = shift;
    $path = join('/',@_);
  }

  # we don't necessarily need a container
  # ls() without one lists all the containers
  if ($container) {
    $requrl.='/'.$container;
  }

  # handle special flags
  if ($limit || $marker || $path) {
    $requrl.="?limit=$limit&marker=$marker&path=$path";
  }

  # prepare the request object
  my $req = HTTP::Request->new(GET => $requrl);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # dispatch request
  my $res = $ua->request($req);

  # stuff return values into our result set
  if ($res->is_success) {
    my @raw = split("\n",$res->content);
    foreach (@raw) {
      next if /^$/;
      push @$list, $_;
    }

    $self->{debug} && print "ls: success - got [".scalar(@$list)."] elements\n";
  }

  # failed
  else {
    undef $list;
    $self->{debug} && print "ls: failed\n";
  }

  return $list;
}

=head2 file("somecontainer","someobject")

This call returns metadata about a specific object.

=cut

sub file() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $status = undef;
  my $path = undef;

  # let file() be called with one or two arguments
  if ($object) {
    $container.='/'.$object;
  }

  # handle pseudo paths
  if ($container =~ /\//) {
    split('/',$container);
    $container = shift;
    $path = join('/',@_);
  }

  # ensure we have enough information to proceed
  return undef unless ($self->{connected} && $container && $path);

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(HEAD => $self->{storage_url}.'/'.$container.'/'.$path);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # dispatch request
  my $res = $ua->request($req);

  # grab subset of returned fields
  # TODO: should be extended to handle all x- fields
  if ($res->is_success) {
    $status->{size} = $res->header("content-length");
    $status->{mtime} = $res->header("last-modified");
    $status->{md5sum} = $res->header("etag");
    $status->{type} = $res->header("content-type");

    $self->{debug} && print "file: success [$container/$path]\n";
  }

  # fail
  else {
    $self->{debug} && print "file: failed [$container/$path]\n";
  }

  return $status;
}

=head2 cp("fromcontainer","fromobject",'tocontainer","toobject");

Copy the contents of one object to another

=cut

sub cp() {
  my $self = shift;
  my $scontainer = shift;
  my $sobject = shift;
  my $dcontainer = shift;
  my $dobject = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $scontainer && $sobject && $dcontainer && $dobject);

  # hold onto the content-type of the source object for later
  # we'll need it to create the destination object
  my $src = $self->file($scontainer,$sobject);
  return undef unless (ref $src eq 'HASH');
  my $type = $src->{type};

  # prepare the copy request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(COPY => $self->{storage_url}.'/'.$scontainer.'/'.$sobject);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Destination' => $dcontainer.'/'.$dobject);
  $req->header( 'Content-type' => $type);

  # dispatch the request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
    $status = 1;
    $self->{debug} && print "cp: success [$scontainer/$sobject]=>[$dcontainer/$dobject]\n";
  }

  # failed
  else {
    $self->{debug} && print "cp: failed [$scontainer/$sobject]=>[$dcontainer/$dobject]\n";
  }
  return $status;
}

=head2 mv("fromcontainer","fromobject",'tocontainer","toobject");

Rename an object, clobbering any existing object

=cut

sub mv() {
  my $self = shift;
  my $scontainer = shift;
  my $sobject = shift;
  my $dcontainer = shift;
  my $dobject = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $scontainer && $sobject && $dcontainer && $dobject);

  # exit on moving an objec to itself - bad idea with copy/delete method
  return if ( ($scontainer eq $dcontainer) && ($sobject eq $dobject));

  # get the source object's content-type and save it for later
  my $src = $self->file($scontainer,$sobject);
  return undef unless (ref $src eq 'HASH');
  my $type = $src->{type};

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(COPY => $self->{storage_url}.'/'.$scontainer.'/'.$sobject);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Destination' => $dcontainer.'/'.$dobject);
  $req->header( 'Content-type' => $type);

  # dispatch request
  my $res = $ua->request($req);

  # copy was successful
  if ($res->is_success) {

    # delete the old object
    if ( $self->rm($scontainer,$sobject) ) {
      $status = 1;
      $self->{debug} && print "mv: success [$scontainer/$sobject]=>[$dcontainer/$dobject]\n";
    }

    # WAT? delete of old object failed!
    else {
      $self->{debug} && print "mv: failed [$scontainer/$sobject]=>[$dcontainer/$dobject]\n";
    }
  }

  # copy failed
  else {
    $self->{debug} && print "mv: failed [$scontainer/$sobject]=>[$dcontainer/$dobject]\n";
  }
  return $status;
}

=head2 mkdir("somecontainer")

This method creates a new container. It returns 1 for success and undef for failure.

=cut

sub mkdir() {
  my $self = shift;
  my $container = shift;
  my $status = undef;
  my $path = undef;

  # ensure we have enough information to proceed
  return undef unless ($self->{connected} && $container);

  # handle pseudo paths
  if ($container =~ /\//) {
    split('/',$container); 
    $container = shift;
    $path = join('/',@_);
  }

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-Length' => '0' );

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {

    # create the pseudo path marker if needed
    if ($path) {
      $status = $self->put_value($container,$path,' ','application/directory');

      # success
      if ($status) {
        $self->{debug} && print "mkdir: success [$container]\n";
      }

      # pseudo path failed
      else {
        $self->{debug} && print "mkdir: failed [$container]\n";
      }
    }
  }
 
  # failed
  else {
    $self->{debug} && print "mkdir: failed [$container]\n";
  }

  return $status;
}

=head2 rmdir("somecontainer")

This method removes a container and its contents. It returns 1 for success and undef for failure.

=cut

sub rmdir() {
  my $self = shift;
  my $container = shift;
  my $status = undef;
  my $path = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container);

  # handle pseudo paths
  if ($container =~ /\//) {
    split('/',$container); 
    $container = shift;
    $path = join('/',@_);
  }

  # TODO - handle recursive deletion of pseudo-folder objects
  # wish there was a way to do this with the api

  # prepare LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(DELETE => $self->{storage_url}.'/'.$container);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-Length' => '0' );

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
    $status = 1;
    $self->{debug} && print "rmdir: success [$container]\n";   
  }

  # failed
  else {
    $self->{debug} && print "rmdir: failed [$container]\n";
  }
  return $status;
}

=head2 du([CONTAINER])

Depending on calling arguments, this method returns account or container-level statistics as 
a hash reference.

=cut

sub du() {
  my $self = shift;
  my $container = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected});

  # prepare LWP reques
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(HEAD => $self->{storage_url}.($container?'/'.$container:''));
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {

    # return fields appropriate for container
    if ($container) {
      $status->{bytes} = $res->header('x-container-bytes-used');
      $status->{objects} = $res->header('x-container-object-count');
    }

    # return global statistics
    else {
      $status->{bytes} = $res->header('x-account-bytes-used');
      $status->{objects} = $res->header('x-account-object-count');
      $status->{containers} = $res->header('x-account-container-count');
    }

    $self->{debug} && print "du: success\n";
  }

  # failed
  else{
    $self->{debug} && print "du: failed\n";
  }
  return $status;
}

=head2 get_value("somecontainer","someobject")

This method returns a scalar value, containing the body of the requested object.

=cut

sub get_value() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $data = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object);

  # prepare the LWP object
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(GET => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {

    # stash return data
    $data = $res->content;

    $self->{debug} && print "get_value: success for [$container/$object]\n";
  }
 
  # failed
  else {
    $self->{debug} && print "get_value: failed for [$container/$object]\n";
  }
  return $data;
}

=head2 put_value("somecontainer","someobject","..data..","text/html")

This method places the contents of a passed scalar into the specified container and object.

Content-type may be specified, but is optional. It defaults to "text/plain"

=cut

sub put_value() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $data = shift;
  my $content_type = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object && $data);

  # use a sane default content-type if one isn't specified
  unless ($content_type) {
    $content_type = 'application/octet-stream';
  }

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-type' => $content_type);
  $req->content( $data );  

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
 
    # stash return data
    $data = $res->content;

    $self->{debug} && print "put_value: success for [$container/$object]\n";
  }

  # failed
  else {
    $self->{debug} && print "put_value: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 get_file("somecontainer","someobject","/tmp/destfile")

This method places the contents of the requested object in a target location of the filesystem.

=cut

sub get_file() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $tmpfile = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object && $tmpfile);

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(GET => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # dispatch request, specifying a location to store the data returned
  my $res = $ua->request($req,$tmpfile);

  # success
  if ($res->is_success) {
    $status = 1;

    $self->{debug} && print "get_file: success for [$container/$object]\n";
  }

  # failure
  else {
    $self->{debug} && print "get_file: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 put_file("somecontainer","someobject","/tmp/sourcefile","text/html")

This method places the contents of a specified source file into an object.

=cut

sub put_file() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $srcfile = shift;
  my $content_type = shift;
  my $status = undef;

  # ensure we have enough information to continue
  # source file must exist
  return undef unless ($self->{connected} && $container && $object && (-e $srcfile) );

  # use a sane default content-type when one isn't specified
  unless ($content_type) {
    $content_type = 'application/octet-stream';
  }

  # get the size of the source file
  my $size = stat($srcfile)->size;

  # open the file in binary mode for reading
  open(IN, $srcfile);
  binmode IN;

  # create reader callback
  my $reader = sub { 
    read IN, my $buf, 65536;
    return $buf;
  };

  # prepare LWP for fancy stuff
  $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

  # create LWP object
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-type' => $content_type);
  $req->header( 'Content-length' => $size );

  # tell LWP to use our reader callback
  $req->content($reader);

  # dispatch request
  my $res = $ua->request($req);

  # close input file
  close(IN);

  # success
  if ($res->is_success) {
    $status = 1;

    $self->{debug} && print "put_file: success for [$container/$object]\n";
  }

  # faled
  else {
    $self->{debug} && print "put_file: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 get_fhstream("somecontainer","someobject",*FILE)

This method takes a container, object and open file handle as arguments.
It retrieves the object in chunks, which it writes to *FILE as they are received.

=cut

sub get_fhstream() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  local (*OUT) = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object && *OUT);

  # make sure the file handle we were passed is open
  return undef unless ( (O_WRONLY | O_RDWR) & fcntl (OUT, F_GETFL, my $slush));

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(GET => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );

  # create our custom handler for reading
  my $res = $ua->request($req,
    sub {
      my ($chunk,$res) = @_;
      print OUT $chunk;
    }
  );

  # success
  if ($res->is_success) {
    $status = 1;

    $self->{debug} && print "get_fhstream: success for [$container/$object]\n";
  }

  # failed
  else {
    $self->{debug} && print "get_fhstream: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 rm("somecontainer","someobject")

This method removes an object.

=cut

sub rm() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object);

  # prepare the LWP object
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(DELETE => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-Length' => '0' );

  # dispatch the request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
    $status = 1;
    $self->{debug} && print "rm: success for [$container/$object]\n";
  }

  # failed
  else {
    $self->{debug} && print "rm: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 create_manifest("somecontainer","someobject")

This method creates a manifest for large-object support

=cut

sub create_manifest() {
  my $self = shift;
  my $container = shift;
  my $object = shift;
  my $status = undef;
  my $content_type = 'application/octet-stream';
  my $data;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $object);

  # prepare the LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(PUT => $self->{storage_url}.'/'.$container.'/'.$object);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'Content-type' => $content_type);

  # point the manifest header to ourselves
  # segments will be further along our path:
  # somecontainer/manifest            <- manifest
  # somecontainer/manifest/segment1   <- segment
  # somecontainer/manifest/segment2   <- segment
  $req->header( 'X-Object-Manifest' => $container.'/'.$object);
  $req->header( 'Content-Length' => '0' );
  $req->content('');  

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
    $self->{debug} && print "create_manifest: success for [$container/$object]\n";
  }

  # failed
  else {
    $self->{debug} && print "create_manifest: failed for [$container/$object]\n";
  }
  return $status;
}

=head2 chmod("somecontainer","public")

This method makes a container "public" or "private".

=cut

sub chmod() {
  my $self = shift;
  my $container = shift;
  my $mode = shift;
  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected} && $container && $mode);

  # fix-up mode
  if ($mode eq 'public') {
    $mode = '.r:*';
  }
  else {
    $mode = '.r:-*';
  }

  # prepare LWP request
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => $self->{storage_url}.'/'.$container);
  $req->header( 'X-STORAGE-TOKEN' => $self->{storage_token} );
  $req->header( 'X-CONTAINER-READ' => $mode );

  # dispatch request
  my $res = $ua->request($req);

  # success
  if ($res->is_success) {
    $status = 1;
    $self->{debug} && print "chmod: success [$container]\n";   
  }

  # failed
  else {
    $self->{debug} && print "chmod: failed [$container]\n";
  }
  return $status;
}

=head2 cdn("somecontainer","enable","true",300)

This method manages a container's cdn configuration. 

Called with no arguments, it returns array reference, containing 
all cdn-enabled containers.

Called with just a container name, it returns a hash reference,
containing the cdn metadata for a container.

Called with a container name and "disable", it disables the cdn
extensions for that container.

Called with a container name, "enable", logging preference and TTL,
it configures cdn extensions for a container.

=cut

sub cdn() {
  my $self = shift;
  my $container = shift;
  my $mode = shift;
  my $logs = shift;
  my $ttl = shift;

  my $status = undef;

  # ensure we have enough information to continue
  return undef unless ($self->{connected});

  # prepare LWP request
  my $ua = LWP::UserAgent->new;

  # handle bare call - list cdn-enabled containers
  if ( ! $container ) {
    my $req = HTTP::Request->new(GET => $self->{cdn_url});
    $req->header( 'X-AUTH-TOKEN' => $self->{storage_token} );

    # dispatch request
    my $res = $ua->request($req);

    # stuff return values into our result set
    if ($res->is_success) {
      my $list = [];
      my @raw = split("\n",$res->content);
      foreach (@raw) {
        next if /^$/;
        push @$list, $_;
      }  

      $self->{debug} && print "cdn: success\n";
      return $list;
    }
    else {
      $self->{debug} && print "cdn: failed\n";
      return [];
    }
  }

  # get cdn attributes for a container
  if ( $container && !$mode) {
    my $req = HTTP::Request->new(HEAD => $self->{cdn_url}.'/'.$container);
    $req->header( 'X-AUTH-TOKEN' => $self->{storage_token} );

    # dispatch request
    my $res = $ua->request($req);

    # stuff return values into our result set
    if ($res->is_success) {
      my $metadata;
      $metadata->{ttl} = $res->header("x-ttl");
      $metadata->{logs} = $res->header("x-log-retention");
      $metadata->{enabled} = $res->header("x-cdn-enabled");
      $metadata->{uri} = $res->header("x-cdn-uri");
      $metadata->{ssluri} = $res->header("x-cdn-uri");
      $metadata->{ssluri} =~ s/http/https/g;

      $self->{debug} && print "cdn: success [$container]\n";
      return $metadata;
    }
    else {
      $self->{debug} && print "cdn: failed [$container]\n";
      return undef;
    }

  }

  # disable cdn support for a container
  if ( $container && ( $mode eq 'disable')) {
    my $req = HTTP::Request->new(POST => $self->{cdn_url}.'/'.$container);
    $req->header( 'X-AUTH-TOKEN' => $self->{storage_token} );
    $req->header( 'X-CDN-ENABLED' => 'False' );

    # dispatch request
    my $res = $ua->request($req);

    # stuff return values into our result set
    if ($res->is_success) {
      $self->{debug} && print "cdn: success [$container] disable\n";
      return 1;
    }
    else {
      $self->{debug} && print "cdn: failed [$container] disable\n";
      return undef;
    }
  }

  # enable cdn on a container / update attributes
  if ( $container && ( $mode eq 'enable')) {

    my $req = HTTP::Request->new(POST => $self->{cdn_url}.'/'.$container);
    $req->header( 'X-AUTH-TOKEN' => $self->{storage_token} );
    $req->header( 'X-CDN-ENABLED' => 'True' );
    $logs && $req->header( 'X-LOG-RETENTION' => $logs );
    $ttl && $req->header( 'X-TTL' => $ttl );

    # dispatch request
    my $res = $ua->request($req);

    # stuff return values into our result set
    if ($res->is_success) {
      my $metadata;
      $metadata->{uri} = $res->header("x-cdn-uri");
      $metadata->{ssluri} = $res->header("x-cdn-uri");
      $metadata->{ssluri} =~ s/http/https/g;

      $self->{debug} && print "cdn: success [$container] enable\n";
      return $metadata;
    }
    else {
      # container might not exist - try again with a PUT
      $req = HTTP::Request->new(PUT =>  $self->{cdn_url}.'/'.$container);
      $req->header( 'X-AUTH-TOKEN' => $self->{storage_token} );
      $req->header( 'CONTENT-LENGTH' => 0 );
      $req->header( 'X-CDN-ENABLED' => 'True' );
      $logs && $req->header( 'X-LOG-RETENTION' => $logs );
      $ttl && $req->header( 'X-TTL' => $ttl );

      # dispatch request
      my $res = $ua->request($req);

      if ($res->is_success) {
        my $metadata;
        $metadata->{uri} = $res->header("x-cdn-uri");
        $metadata->{ssluri} = $res->header("x-cdn-uri");
        $metadata->{ssluri} =~ s/http/https/g;

        $self->{debug} && print "cdn: success container [$container] logs [$logs] ttl [$ttl] enable\n";
        return $metadata;
      }
      else {
        $self->{debug} && print "cdn: failed [$container] logs [$logs] ttl [$ttl] enable\n";
        return undef;
      }
    }
  }
}

1;
__END__

=head1 AUTHOR

Dennis Opacki, dopacki@internap.com

=head1 SEE ALSO

perl(1).

=cut
