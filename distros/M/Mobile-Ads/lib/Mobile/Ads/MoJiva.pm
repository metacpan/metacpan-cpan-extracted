# Mobile::Ads::MoJiva.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::MoJiva;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::MoJiva::VERSION='0.1.0';
$Mobile::Ads::MoJiva::ver=$Mobile::Ads::MoJiva::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();
use Digest::MD5 qw();

=head1 NAME

Mobile::Ads::MoJiva - module to serve MoJiva ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::MoJiva;
 $ad = new Mobile::Ads::MoJiva
 ($text,$link,$image) = $ad->get_mojiva_ad({
				site	=> 'MoJiva site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				test	=> 'set this if this is a test ad',
 				zone	=> 'ad zone',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::MoJiva> provides an object oriented interface to serve advertisements
from AdMob in mobile sites.
This is just a slightly altered version of the perl code found on AdMob's site.

=head1 new Mobile::Ads::MoJiva

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head2 Parameters/Properties

=over 4

=item site

C<>=> MoJiva site code, delivered by them. Something in the form off ``123''

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
	
	return $self;
}

*get_ad = \&get_mojiva_ad;

sub get_mojiva_ad {
	my $self = shift;
	
	my $mojiva_endpoint = "http://ads.mojiva.com/ad";
	
	my ($site,$test,$remote,$address,$uri,$markup,$text,$link,$key,$count,$border,$header,$bgcolor,$textcol,$linkcol,$adtype,$zone) = 
			('','','','','','','','','','','','','','','','','');
	
	if (ref $_[0] eq 'HASH') {
		$site	 = $_[0]->{'site'} || $self->{'site'};
		$test	 = $_[0]->{'test'} || '';
		$remote	 = $_[0]->{'remote'} || $ENV{'HTTP_USER_AGENT'};
		$address = $_[0]->{'address'} || $ENV{'REMOTE_ADDR'};
		$uri	 = $_[0]->{'uri'} || 'http://'.$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'};
		$text	 = $_[0]->{'text'} || $self->{'text'} || '';
		$link	 = $_[0]->{'link'} || $self->{'link'} || '';
		#alterations from admob start here..
		$adtype	 = $_[0]->{'adtype'} || $self->{'adtype'} || 3;
		$key	 = $_[0]->{'key'}  || $self->{'key'} || 1;
		$zone	 = $_[0]->{'zone'}  || $self->{'zone'} || 143;
		$count	 = $_[0]->{'count'} || $self->{'count'} || 1;
		$border	 = $_[0]->{'border'} || $self->{'border'} || '#000000';
		$header	 = $_[0]->{'header'} || $self->{'header'} || '#cccccc';
		$bgcolor = $_[0]->{'bgcolor'} || $self->{'bgcolor'} || '#eeeeee';
		$textcol = $_[0]->{'textcol'} || $self->{'textcol'} || '#000000';
		$linkcol = $_[0]->{'linkcol'} || $self->{'linkcol'} || '#ff0000';
	}
	else {
		($site,$test,$remote,$address,$uri,$markup,$text,$link,$key,$count,$border,$header,$bgcolor,$textcol,$linkcol,$adtype,$zone) = @_;
	}
	
	$site	 ||= $self->{'site'};
	$remote	 ||= $ENV{'HTTP_USER_AGENT'};
	$address ||= $ENV{'REMOTE_ADDR'};
	$text ||= $self->{'text'};
	$link ||= $self->{'link'};
		
	Carp::croak("cant serve ads without site\n") unless ($site);
	Carp::croak("cant serve ads without remote user agent\n") unless ($remote);
	Carp::croak("cant serve ads without remote address\n") unless ($address);
	
	my $mojiva_post = {
						'site'			=> $site,
						'ua'			=> $remote,
						'ip'			=> $address,
						'url'			=> $uri,
						'zone'			=> $zone, #is 143 constant ? i'd venture to guess not
						'adstype'		=> $adtype, #could also use 1 for text or 2 for image only (3==text+image)
						'key'			=> $key, 
        				'count'			=> $count,
        				'paramBORDER'	=> $border, # ads border color
				        'paramHEADER'	=> $header, # header color
				        'paramBG'		=> $bgcolor, # background color
				        'paramTEXT'		=> $textcol, # text color
				        'paramLINK'		=> $linkcol # url color
					};
	
	#test ads need just find POSTs ``m'' field.
	if ($test eq 'test') {
		$mojiva_post->{'test'} = '1';
	}
	
	#do the POST
	my $res;
	#through $self->{parent} prefrably...
	eval q[$res = $self->{'parent'}->get_ad({
												url		=> $mojiva_endpoint,
												method	=> 'POST',
												params	=> $mojiva_post
											});];
	if ($@) {
		return ($text,$link);
	}
	else {
		my $ret = $self->parse($res,$text,$link);
		if (wantarray) {
			return ($ret->{'text'},$ret->{'link'},$ret->{'image'});
		}
		else {
			return $ret;
		}
	}
}

sub parse {
	my $self = shift;
	
	my ($toparse,$text,$link) = @_;

	my $ret = { };
	
	$toparse =~ m|\<a.+?href=[\"\']([^\'\"]+)[\'\"]|s and $ret->{'link'} = $1;
	$toparse =~ m|\<img.+?src=[\"\']([^\'\"]+)[\'\"]|s and $ret->{'image'} = $1;
	$toparse =~ m|\>([^\<\>]+?)\</a\>|s and $ret->{'text'} = $1;
	
	#we need at least link and text to exist...
	if ($ret->{'link'} && ($ret->{'text'} || $ret->{'image'}) ) {
		$ret->{'image'} ||= '';
		$ret->{'text'}  ||= '';
	}
	else {
		$ret->{'link'} = $link;
		$ret->{'text'} = $text;
		$ret->{'image'} = '';
	}
	
	defined($ret->{'link'})  and $ret->{'link'}  = $self->{'parent'}->XMLEncode($ret->{'link'});
	defined($ret->{'text'})  and $ret->{'text'}  = $self->{'parent'}->XMLEncode($ret->{'text'});
	defined($ret->{'image'}) and $ret->{'image'} = $self->{'parent'}->XMLEncode($ret->{'image'});
	
	return $ret;
}

=pod

=head2 Methods

=over 4

=item get_mojiva_ad

C<>=> Does the actual fetching of the ad for the site given. Refer to new for details
Returns a list ($text_for_ad,$link_for_ad) value in list context or an 
``<a href="$link">$text</a>'' if called in scalar context.

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
	$ua timeout set to 20 sec
 0.0.5 
	$ua timeout set to 2 sec
	Implemented the new version AdMob code 
	(still some funky parts in there, but seems to work)
 0.0.6
 	Aliased get_ad to get_v2_ad
 0.0.7
 	Option to reuse parent Mobile::Ads instead of creating anew
 0.0.8/0.0.9
 	Skipped those to have same verion number in all modules
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
