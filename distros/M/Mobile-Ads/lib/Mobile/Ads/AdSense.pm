# Mobile::Ads::AdSense.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::AdSense;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::AdSense::VERSION='0.1.0';
$Mobile::Ads::AdSense::ver=$Mobile::Ads::AdSense::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();
use Time::HiRes();
use XML::LibXML();

=head1 NAME

Mobile::Ads::AdSense - module to serve Google Adsense for Mobile ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::AdSense;
 $ad = new Mobile::Ads::AdSense
 ($text,$link) = $ad->get_text_ad({
				site	=> 'Google AdSense site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::AdSense> provides an object oriented interface to serve advertisements
from Google AdSense for Mobile in mobile sites.
This is just a slightly altered version of the perl code found on Google's site.

=head1 new Mobile::Ads::AdSense

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head2 Parameters/Properties

=over 4

=item site

C<>=> Goggle Adsense site code, delivered by them. Something in the form off ``999''

=item remote

C<>=> Remote User Agent ($ENV{'HTTP_USER_AGENT'}). In fact $ENV{'HTTP_USER_AGENT'} will be used
if not supplied.

=item address

C<>=> $ENV{'REMOTE_ADDR'}. All things about HTTP_USER_AGENT also apply here.

=item text

C<>=> Should we fail to retrieve a real ad, this is the text of the ad displayed instead

=item link

C<>=> Same with text, but for the ad's link. 

=back

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;

	my $parent = shift;
	
	if ($parent && ref($parent) && ref($$parent) && ref($$parent) eq "Mobile::Ads") {
		$self->{'parent'} = $$parent;
	}
	elsif ($parent && ref($parent) && ref($parent) eq "Mobile::Ads") {
		$self->{'parent'} = $parent;
	}
	else {
		$self->{'parent'} = new Mobile::Ads;
	}
	
	$self->{'parser'} = XML::LibXML->new;
	return $self;
}

*get_ad = \&get_adsense_textimage_ad;

sub get_adsense_ad {
	my $self = shift;
	
	my $ad_type = shift;
	
	my ($site,$client,$remote,$address,$text,$link,$image,$color_border,$color_bg,$color_link,$color_text,$color_url,$format,$markup) = 
		('','','','','','','','','','','','','','');
	if (ref $_[0] eq 'HASH') {
		$site   = $_[0]->{'site'}   || $self->{'site'};
		$client = $_[0]->{'client'} || $self->{'client'};
		$remote  = $_[0]->{'remote'};
		$address = $_[0]->{'address'};
		$text = $_[0]->{'text'};
		$link = $_[0]->{'link'};
		$image = $_[0]->{'image'};
		$color_border = $_[0]->{'color_border'};
		$color_bg	  = $_[0]->{'color_bg'};
		$color_link	  = $_[0]->{'color_link'};
		$color_text	  = $_[0]->{'color_text'};
		$color_url	  = $_[0]->{'color_url'};
		$format = $_[0]->{'format'};
		$markup = $_[0]->{'markup'};
	}
	else {
		($site,$client,$remote,$address,$text,$link,$image,$color_border,$color_bg,$color_link,$color_text,$color_url,$format,$markup) = @_;
	}
	
	$site	 ||= $self->{'site'};
	$remote	 ||= $ENV{'HTTP_USER_AGENT'};
	$address ||= $ENV{'REMOTE_ADDR'};
	$text ||= $self->{'text'};
	$link ||= $self->{'link'};
	
	Carp::croak("cant serve ads without site (google calls it ``channel'')\n") unless ($site);
	Carp::croak("cant serve ads without client\n") unless ($client);
	Carp::croak("cant serve ads without remote user agent\n") unless ($remote);
	Carp::croak("cant serve ads without remote address\n") unless ($address);
	
	my $google_dt = sprintf("%.0f", 1000 * Time::HiRes::gettimeofday());
	my $encoding = 'utf8';
	my $google_host = (defined($ENV{'HTTP_HOST'}) ? 'http://'.$ENV{'HTTP_HOST'} : 'http://just.a.test');
	my $url = ( defined($ENV{'REQUEST_URI'}) ? $google_host.$ENV{'REQUEST_URI'} : 'http://just.a.test/please_ignore_me');
	my $referer = $ENV{'HTTP_REFERER'} || '';
	#my $google_host = 'http://wapamama.net';
	#my $url = $google_host.'/lalakis.xml';
	#my $referer = 'http://wapamama.net/llala.xml?user=2' || '';
	
	$color_border ||= '555555';
	$color_bg	  ||= 'EEEEEE';
	$color_link	  ||= '0000CC';
	$color_text	  ||= '000000';
	$color_url	  ||= '008000';
	
	$format ||= 'mobile_single';
	$markup ||= 'xhtml';
	$ad_type ||= 'text_image';
	
	# fetch data
	my $res;
	my $params = {
					ad_type			=> $ad_type,
					channel			=> $site,
					client			=> $client,
					color_border	=> $color_border, 
					color_bg		=> $color_bg,
					color_link		=> $color_link,
					color_text		=> $color_text,
					color_url		=> $color_url,
					dt				=> $google_dt,
					format			=> $format,
					host			=> $google_host,
					ip				=> $address,
					markup			=> $markup,
					oe				=> $encoding,
					output			=> $markup,
					ref				=> $referer,
					url				=> $url,
					useragent		=> $remote,
				};
	
	$self->append_screen_res(\$params);
	
	eval q[$res = $self->{'parent'}->get_ad({ 
											url		=> 'http://pagead2.googlesyndication.com/pagead/ads',
											method	=> 'GET',
											params	=> $params
										});];
	if ($@) {
		return '';
	}
	else {
		my $ret = $self->parse($res);
		return $ret;
	}
}

sub get_adsense_image_ad {
	my $self = shift;
	
	my $ad = $self->get_adsense_ad('image',@_);
	
	return $ad;
}

sub get_adsense_text_ad {
	my $self = shift;
	
	my $ad = $self->get_adsense_ad('text',@_);
	
	return $ad;
}

sub get_adsense_textimage_ad {
	my $self = shift;
	
	my $ad = $self->get_adsense_ad('text_image',@_);
	
	return $ad;
}

sub append_screen_res {
	my $self = shift;
	
	my $params = shift;
	
	return if (!ref($params));
	
	my $screen_res = $ENV{"HTTP_UA_PIXELS"};
	my $delimiter = "x";
	if (!$screen_res) {
		$screen_res = $ENV{"HTTP_X_UP_DEVCAP_SCREENPIXELS"};
		$delimiter = ",";
	}
	
	if ($screen_res) {
		$screen_res =~ m|(\d+)$delimiter(\d+)| and ($$params->{'u_w'},$$params->{'u_h'}) = ($1,$2);
	}
}

sub parse {
	my $self = shift;
	
	my $toparse = shift;

	my $ret = '';
	
	#if answer isn't a big comment...
	if ($toparse !~ m|^\<\!\-\-.+?\-\-\>$|) {
		$ret = $toparse;
	}
	
	if ($ret) {
		$ret =~ s/\&(?!amp\;)/\&amp;/sg;
		my $dom = $self->{'parser'}->parse_html_string($ret,  { encoding => 'UTF-8' }) or Carp::croak("Cannot parse |$ret|");
		$dom->setEncoding('UTF-8');
		my $output_html = $dom->toString;
		$output_html =~ s/.*\n//;
		$output_html =~ s/.*\n//;
		$output_html =~ s/\<\/?body\>//gs;
		$output_html =~ s/\<\/?html\>//gs;
		$ret = $output_html;
	}
	
	return $ret;
}

=pod

=head2 Methods

=over 4

=item get_text_ad

C<>=> Does the actual fetching of a text ad for the site given. Refer to new for details
Returns a list ($text_for_ad,$link_for_ad) value.

=item get_image_ad

C<>=> Does the actual fetching of an image ad for the site given. Refer to new for details
Returns a list ($text_for_ad,$link_for_ad,$image_url) value.

=back

=cut


=head1 Revision History

 0.0.1 
	Initial Release
 0.0.2 
	Fixed stupid typo
 0.0.3 
	Didn't preserve default values on failure
 0.0.4
 	All ua stuff put in Mobile::Ads
 0.0.5 
	$ua timeout set to 2 sec in $self->{'parent'}
 0.0.6 
	raw google output has some pitfalls. implemented XML::LibXML parsing
	of the returned ad code.
 0.0.7 
	slight problems with encoding in LibXML parsing
 0.0.8
 	Aliased get_ad to get_adsense_ad
 0.0.9
 	Option to reuse parent Mobile::Ads instead of creating anew
 0.1.0
 	One could also use a reference to the parent... :)

=head1 BUGS

Thoughtlessly crafted to avoid having the same piece of code in several places.
Could use lots of enhancements.

=head1 DISCLAIMER

This module borrowed its OO interface from Mail::Sender.pm Version : 0.8.00 
which is available on CPAN.

=head1 AUTHOR

Thanos Chatziathanassiou <tchatzi@arx.net>
http://www.arx.net

=head1 COPYRIGHT

Copyright (c) 2008 arx.net - Thanos Chatziathanassiou . All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. 

=cut

1;
