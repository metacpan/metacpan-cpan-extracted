package Net::Amazon::Thumbnail;
use strict;
use warnings;

use File::Spec;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use XML::XPath;
use XML::XPath::XMLParser;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use POSIX qw( strftime );
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(aws_access_key_id secret_access_key empty_image thumb_size ua thumb_store urls method_type));
our $VERSION = "0.06";

sub new {
  my($class, $parms) = @_;
  my $self = {};
  bless $self, $class;
  if($parms->{debug}) {
      my $fh = $parms->{debug};
      $self->{debug} = do {local $/; <$fh> };
  }
  if($parms->{path}) {
      die "Invalid directory:" . $parms->{path} unless -d $parms->{path};
  }
  my $ua = LWP::UserAgent->new;
  $ua->timeout(30);
  $self->ua($ua);
  $self->aws_access_key_id($parms->{key_id});
  $self->secret_access_key($parms->{access_key});
  $self->thumb_size(ucfirst($parms->{size}) || 'Large');
  $self->empty_image($parms->{no_image} || 0);
  $self->thumb_store($parms->{path});
  $self->method_type('GET');
  return $self;
}

sub get_thumbnail {
  my $self = shift;
  my $url = shift;
  die "No Url given\n" unless($url);
  $self->method_type('GET') unless($self->method_type eq 'GET');
  my $thumbs = $self->_XML2thumb($self->_request($self->_format_url($url)));
  return $thumbs;
}

sub post_thumbnail {
  my $self = shift;
  my $url = shift;
  die "No Url given\n" unless($url);
  $self->method_type('POST') unless($self->method_type eq 'POST');
  my $thumbs = $self->_XML2thumb($self->_request($self->_format_url($url)));
  return $thumbs;
}


sub _store {
  my $self = shift;
  my $image = shift;
  my $url = shift;
  my $uri = URI->new($url);
  my $name = $uri->authority;
  if($self->{nameList} && $self->{nameList}->{$name}) {
    $name = $self->{nameList}->{$name};
  }
  my $path = File::Spec->catfile($self->thumb_store, $name . '.jpg');
  unlink($path) if -e $path;
  my $response = $self->ua->get($image, ':content_file' => $path);
  return $path;
}

sub _XML2thumb {
  my $self = shift;
  my $xp = shift;
  my $thumbs;
  my $image;
  foreach my $response ($xp->find('/aws:ThumbnailResponse/aws:Response/aws:ThumbnailResult')->get_nodelist){
    my $thumbnode = $response->find('aws:Thumbnail');
    my $node = $thumbnode->get_node(0);
    if($node->findvalue('@Exists') eq 'true') {
      my $thumbnail_url = $node->string_value;
      my $request_url = $response->find('aws:RequestUrl')->string_value;
      $image = ($self->thumb_store) ? $self->_store($thumbnail_url, $request_url) : $thumbnail_url;
    }
    else {
      $image = $self->empty_image;
    }
    push(@{ $thumbs }, $image);
 }
  return $thumbs;
}

sub _format_url {
  my $self = shift;
  my $url = shift;
  my %urls_param;
  my $scheme_reg = qr/^http/i;
  if ( ! ref($url) ) {
    $urls_param{'Url'} = ($url !~ $scheme_reg) ? "http://$url" : $url; 
    $urls_param{'Size'} = $self->thumb_size;
  }
  elsif ( UNIVERSAL::isa($url,'HASH') ) {
    my $next = 0;
    for my $key ( keys %$url ) {
        $next++;
        my $url_value = ($key !~ $scheme_reg) ? "http://$key" : $key;
        my $name = (length(_trim($url->{$key})) > 0) ? $url->{$key} : 0;
        my $uri = URI->new($url_value);
        my $key_name = $uri->authority;
        $self->{nameList}->{$key_name} = $name;
        $urls_param{"Thumbnail.$next.Url"} = $url_value;
    }
    $urls_param{'Shared.Size'} = $self->thumb_size;
  }
  elsif ( UNIVERSAL::isa($url,'ARRAY') ) {
    my @url_array = @{$url};
    my $size = scalar @url_array;
    my $next = 0;
  	for (my $i = 0; $i < $size; $i++){
	  $next = $i + 1;
      my $url_value = ($url_array[$i] !~ $scheme_reg) ? "http://" . $url_array[$i] : $url_array[$i];
      $urls_param{"Thumbnail.$next.Url"} = $url_value;
	}
    $urls_param{'Shared.Size'} = $self->thumb_size;
  }
  return \%urls_param;
}

sub _request {
  my($self, $parms) = @_;
  my $output;
  my $xp; 
  my $response;

  $parms->{Action} = "Thumbnail";
  $parms->{AWSAccessKeyId} = $self->aws_access_key_id;
  $parms->{Timestamp} = strftime("%Y-%m-%dT%H:%M:%S.000Z",gmtime);

  my $hmac = Digest::HMAC_SHA1->new($self->secret_access_key);
  $hmac->add( $parms->{Action} . $parms->{Timestamp} );
  $parms->{Signature} = $hmac->b64digest . '=';
  my $url = 'http://ast.amazonaws.com/xino/?';

  my $uri = URI->new($url);
  $uri->query_param($_, $parms->{$_}) foreach keys %$parms;

  if($self->{debug}) {
    $xp = XML::XPath->new(xml => $self->{debug});
    return $xp;
  }
  else {
	$response = ($self->method_type eq 'GET') ? $self->ua->get("$uri") : $self->ua->post("$uri");
    $output = $response->content;
  }
  $xp = XML::XPath->new(xml => $output);

  unless($response->is_success) { 
    my $error_code = $xp->findvalue('//*[name() = "Code"]') || 'N/A';
    my $error_msg = $xp->findvalue('//*[name() = "Message"]') || 'N/A';
    my $request_id = $xp->findvalue('//*[name() = "RequestID"]') || 'N/A';
    my $error_format = "Error fetching response for request id: %s\nResponse Status: %s\nResponse Code: %s\nResponse Message: %s\n";
    die sprintf($error_format, $request_id, $response->status_line, $error_code, $error_msg);
  }
  return $xp;
}

sub _trim {
    @_ = @_ ? @_ : $_ if defined wantarray;
    for (@_ ? @_ : $_) { s/\A\s+//; s/\s+\z// }
    return wantarray ? @_ : "@_";
}

1;

__END__

=head1 NAME

Net::Amazon::Thumbnail - Use the Amazon Alexa Site Thumbnail web service

=head1 SYNOPSIS

use Net::Amazon::Thumbnail;

	my %conf = (
    	key_id  => "YoursecretkeyID",
	    access_key  => "Yoursecretaccesskey",
    	size    => "Large",
	    path    => "C:/dev/thumbs/",
    	no_image    => "noimage.jpg"
	);

	my $thumb = Net::Amazon::Thumbnail->new(\%conf);

	# Request single thumbnail
	my $images = $thumb->get_thumbnail('amazon.com');

	# Request multiple thumbnails
	my @domains = ('http://perlmonks.org', 'http://perl.com');
	$images = $thumb->get_thumbnail(\@domains);

	# Request with custom name (when path is provided)
	my %domain = ('perl.com' => 'TheSourceForPerl');
	$images = $thumb->get_thumbnail(\%domain);

=head1 DESCRIPTION

The Net::Amazon::Thumbnail module allows you to use the Amazon
Alexa Site Thumbnail web service with relative ease.

The Alexa Site Thumbnail web service provides developers with
programmatic access to thumbnail images for the home pages of 
web sites. It offers access to Alexa's large and growing collection 
of images, gathered from its comprehensive web crawl. This web 
service enables developers to enhance web sites, search results, 
web directories, blog entries, and other web real estate with 
Alexa thumbnails images.

In order to access the Alexa Web Information Service, you will need an
Amazon Web Services Subscription ID. See
http://www.amazon.com/gp/aws/landing.html

There are some limitations, so be sure to read the The Amazon Alexa
Web Information Service FAQ.

=head1 INTERFACE

The interface follows. Most of this documentation was copied from the
API reference. Upon errors, an exception is thrown.

=head2 new

The constructor method creates a new Net::Amazon::Thumbnail
object. You must pass in a hash reference containing the Amazon Web 
Services Access Key ID, Secret Access Key, thumbnail size (small or large),
and the name of your default empty image. Optionally you can also provide
a path to store the images.

	my $thumb = Net::Amazon::Thumbnail->new(\%conf);

=head2 Config

The configuration options have just a few requirements.
The following keys are required:

=over

=item key_id

    key_id  => "YoursecretkeyID",

=item access_key

    access_key  => "Yoursecretaccesskey",

=back

The following keys are optional

=over

=item size

    size    => "large",

Size of the returned thumbnail (Small = 111x82 pixels, Large = 201x147 pixels).
If this parameter is not specified it defaults to "Large".
The first letter of this paramater is automatically uppercased.

=item path

    path    => "C:/dev/thumbs/",

The location of where you want the thumbnails stored locally.
Dies upon unsuccessful directory test.

=item no_image

The default image you want returned for queued thumbnails.
If the thumbnail is not available, this is the image returned.
If the path option was given, non existant images are not stored.

    no_image    => "noimage.jpg"

=back

=head2 get_thumbnail

The get_thumbnail method retrieves the thumbnails for the sites given,
and returns an array reference containing the thumbnail(s) requested.

This method only accepts one argument, which must be a reference.

=over 

=item B<Flexible argument types>:

=item String (single domain)	

	my $images = $thumb->get_thumbnail('http://perlmonks.org');

=item Array reference (multiple domains)

	my @domains = qw(http://cpan.org, sourceforge.net);
	my $images = $thumb->get_thumbnail(\@domains);

=item Hash reference (multiple domains with custom names)

	my %domains = (
		perlmonks.org => 'monastery',
		cpan.org	=> 'cpan'
	);
	my $images = $thumb->get_thumbnail(\%domains);	

=back

If the path option was given, it will return the stored image instead of the image hosted
on Amazon.

=head2 post_thumbnail

The post_thumbnail is exactly the same as get method, except that it dispatches a C<POST> request
instead of a C<GET> request.

Although this method does work, the API says to use C<GET> requests.

=head1 BUGS AND LIMITATIONS                                                     
                                                                                
No bugs have been reported.
                                                                                
Please report any bugs or feature requests to                                   
C<bug-Net-Amazon-Thumbnail@rt.cpan.org>.                   
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Amazon-Thumbnail> is the RT queue
for Net::Amazon::Thumbnail.  Please check to see if your bug has already been reported. 

=head1 AUTHOR

Ian Tyndall C<ityndall@cpan.org>

=head1 COPYRIGHT                                                    

Copyright (c) 2007, Ian Tyndall C<ityndall@cpan.org>. All rights reserved.           
                                                                                
This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.

=cut
