# Mobile::Ads::Zestadz.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::Zestadz;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::Zestadz::VERSION='0.1.0';
$Mobile::Ads::Zestadz::ver=$Mobile::Ads::Zestadz::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();

=head1 NAME

Mobile::Ads::Zestadz - module to serve Zestadz ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::Zestadz([$parent]);
 $ad = new Mobile::Ads::Zestadz
 ($text,$link,$image) = $ad->get_zestadz_ad({
				site	=> 'AdMob site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				test	=> 'set this if this is a test ad',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::Zestadz> provides an object oriented interface to serve advertisements
from AdMob in mobile sites.
This was ported from VB code in their site

=head1 new Mobile::Ads::Zestadz

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head2 Parameters/Properties

=over 4

=item site

C<>=> Zestadz site code, delivered by them. Something in the form off ``01234abcdef12345''

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

*get_ad = \&get_zestadz_ad;

sub get_zestadz_ad {
	my $self = shift;
	
	my ($site,$metadata,$request,$remote,$address,$text,$link) = ('','','','','','');
	if (ref $_[0] eq 'HASH') {
		$site = $_[0]->{'site'} || $self->{'site'};
		$metadata = $_[0]->{'metadata'};
		$request = $_[0]->{'request'};
		$remote  = $_[0]->{'remote'};
		$address = $_[0]->{'address'};
		$text = $_[0]->{'text'};
		$link = $_[0]->{'link'};
	}
	else {
		($site,$metadata,$request,$remote,$address,$text,$link) = @_;
	}
	
	$site	 ||= $self->{'site'};
	$remote	 ||= $ENV{'HTTP_USER_AGENT'};
	$address ||= $ENV{'REMOTE_ADDR'};
	$metadata ||= 'http://'.$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'};
	$request  ||="impression"; 
	$text ||= $self->{'text'};
	$link ||= $self->{'link'};
	
	Carp::croak("cant serve ads without site\n") unless ($site);
	Carp::croak("cant serve ads without remote user agent\n") unless ($remote);
	Carp::croak("cant serve ads without remote address\n") unless ($address);
	
	# fetch data
	my $res;
	#"?cid="&cid&"&ua="&ua&"&ip="&ip&"&mt="&mt&"&request="&req&"" 
	my $params = {
					cid		=> $site,
					ua		=> $remote,
					ip		=> $address,
					mt		=> $metadata,
					request => $request
				};
		
	eval q[$res = $self->{'parent'}->get_ad({ 
											url		=> 'http://www.zestadz.com/waphandler',
											method	=> 'GET',
											params	=> $params
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
	my $type = 0;
	if ($toparse =~ m|^(.+?)\~(\d+)\~(.+?)~(.+?)~(.+?)$|s) {
		#an ad with both text and image (and link of course)
		(
			$ret->{'link'}  = 'http://www.zestadz.com/waplanding?lm='.$1.'~ck',
			$type = $2,
			$ret->{'image'} = $3,
			$ret->{'text'}  = $5 
		);
	}
	elsif ($toparse =~ m|^(.+?)\~(\d+)\~(.+?)~(.+?)$|s) {
		#an ad with either only text or only image (and link of course) ($2 will tell us which is which)
		(
			$ret->{'link'}  = 'http://www.zestadz.com/waplanding?lm='.$1.'~ck',
			$type = $2,
			$ret->{'image'} = $3,
			$ret->{'text'}  = $3,
			 
		);
	}
	
	if ($type == 4) {
		$ret->{'link'} = $link;
		$ret->{'text'} = $text;
		$ret->{'image'} = '';
	}
	elsif ($type == 2) {
		$ret->{'image'} = '';
	}
	elsif ($type == 1) {
		$ret->{'text'} = '';
	}
	
	defined($ret->{'link'})  and $ret->{'link'}  = $self->{'parent'}->XMLEncode($ret->{'link'});
	defined($ret->{'text'})  and $ret->{'text'}  = $self->{'parent'}->XMLEncode($ret->{'text'});
	defined($ret->{'image'}) and $ret->{'image'} = $self->{'parent'}->XMLEncode($ret->{'image'});
	
	return $ret;
}

=pod

=head2 Methods

=over 4

=item get_zestadz_ad

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
 	All ua stuff put in Mobile::Ads
 0.0.6
 	Aliased get_ad to get_zestadz_ad
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
