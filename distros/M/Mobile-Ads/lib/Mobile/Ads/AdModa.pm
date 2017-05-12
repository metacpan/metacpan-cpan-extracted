# Mobile::Ads::AdModa.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::AdModa;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::AdModa::VERSION='0.1.0';
$Mobile::Ads::AdModa::ver=$Mobile::Ads::AdModa::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();

=head1 NAME

Mobile::Ads::AdModa - module to serve AdModa ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::AdModa;
 $ad = new Mobile::Ads::AdModa
 ($text,$link) = $ad->get_text_ad({
				site	=> 'AdModa site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::AdModa> provides an object oriented interface to serve advertisements
from AdModa in mobile sites.
This is just a slightly altered version of the perl code found on AdModa's site.

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head1 new Mobile::Ads::AdModa

=head2 Parameters/Properties

=over 4

=item site

C<>=> AdModa site code, delivered by them. Something in the form off ``999''

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

*get_ad = \&get_image_ad;

sub get_admoda_ad {
	my $self = shift;
	
	my $url = shift;
	
	my ($site,$remote,$address,$text,$link,$image) = ('','','','','','','');
	if (ref $_[0] eq 'HASH') {
		$site = $_[0]->{'site'} || $self->{'site'};
		$remote  = $_[0]->{'remote'};
		$address = $_[0]->{'address'};
		$text = $_[0]->{'text'};
		$link = $_[0]->{'link'};
	}
	else {
		($site,$remote,$address,$text,$link) = @_;
	}
	
	$site	 ||= $self->{'site'};
	$remote	 ||= $ENV{'HTTP_USER_AGENT'};
	$address ||= $ENV{'REMOTE_ADDR'};
	$text ||= $self->{'text'};
	$link ||= $self->{'link'};
	
	Carp::croak("cant serve ads without site\n") unless ($site);
	Carp::croak("cant serve ads without remote user agent\n") unless ($remote);
	Carp::croak("cant serve ads without remote address\n") unless ($address);
	
	# fetch data
	my $res;
	my $params = {
					z  => $site,
					ua => $remote,
					a  => $address,
				};
	
	eval q[$res = $self->{'parent'}->get_ad({ 
											url		=> $url,
											method	=> 'GET',
											params	=> $params
										});];
	if ($@) {
		$link and $link = $self->{'parent'}->XMLEncode($link);
		$text and $text = $self->{'parent'}->XMLEncode($text);
		return ($text,$link);
	}
	else {
		chomp($res);
		my ( $bannerid, $image_url, $click_url, $texte ) = split( /\|/, $res );
		
		if ( $bannerid ) {
			$image_url ||= '';
			$text ||= 'Click here...';
			($link,$text,$image) = ($click_url,$texte,$image_url);
		}
		$link  and $link = $self->{'parent'}->XMLEncode($link);
		$text  and $text = $self->{'parent'}->XMLEncode($text);
		$image and $text = $self->{'parent'}->XMLEncode($image);
		return ($text,$link,$image);
	}
}

sub get_image_ad {
	my $self = shift;
	
	my $url = 'http://www.admoda.com/ads/fetch.php';
	
	my ($text,$link,$image) = $self->get_admoda_ad($url,@_);
	
	($text and $link and $image and return ($text,$link,$image)) or
	($text and $link and return ($text,$link)) or
	Carp::croak("Cant get ad: no text and link\n");
}

sub get_text_ad {
	my $self = shift;
	
	my $url = 'http://www.admoda.com/ads/textfetch.php';
	
	my ($text,$link,$image) = $self->get_admoda_ad($url,@_);
	
	($text and $link and $image and return ($text,$link,$image)) or
	($text and $link and return ($text,$link)) or
	Carp::croak("Cant get ad: no text and link\n");
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
 	Aliased get_ad to get_(admoda)image_ad
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
