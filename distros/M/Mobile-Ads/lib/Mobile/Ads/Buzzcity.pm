# Mobile::Ads::Buzzcity.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::Buzzcity;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::Buzzcity::VERSION='0.1.0';
$Mobile::Ads::Buzzcity::ver=$Mobile::Ads::Buzzcity::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();

=head1 NAME

Mobile::Ads::Buzzcity - module to serve buzzcity ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::Buzzcity;
 $ad = new Mobile::Ads::Buzzcity
 ($text,$link,$image) = $ad->get_buzzcity_ad({
				site	=> 'Ads.gr site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::Buzzcity> provides an object oriented interface to serve advertisements
from buzzcity.com in mobile sites.

=head1 new Mobile::Ads::Buzzcity

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head2 Parameters/Properties

=over 4

=item site

C<>=> Buzzcity site code, delivered by them. Something in the form off ``123456'' (they call it ``partnerid'')

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

*get_ad = \&get_buzzcity_ad;

sub get_buzzcity_ad {
	my $self = shift;
	
	my ($site,$remote,$address,$text,$link) = ('','','','','','');
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
					partnerid	=> $site,
					a			=> $remote,
					i			=> $address,
					get			=> 1
				};
		
	eval q[$res = $self->{'parent'}->get_ad({ 
											url		=> 'http://ads.buzzcity.com/show.php',
											method	=> 'GET',
											params	=> $params
										});];
	if ($@) {
		return ($text,$link);
	}
	else {
		my $ret = $self->parse($res,$site,$text,$link);
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
	
	my ($toparse,$pid,$text,$link) = @_;
	my $ret = { };
	
	if ($toparse =~ m|^(.+?)\r?\n(.+?)\r?\n(.+?)$|s) {
		#an ad with both text and image (and link of course)
		(
			$ret->{'link'}  = $3,
			$ret->{'text'}  = $1,
			$ret->{'image'} = $2 
		);
	}
	elsif ($toparse =~ m|^(.+?)\r?\n(.+?)$|s) {
		#an ad with only text and link
		(
			$ret->{'link'}  = 'http://click.buzzcity.com/click.php?partnerid='.$pid.'&cid='.$2,
			$ret->{'text'}  = $1
		);
	}
	
	defined($ret->{'link'})  and $ret->{'link'}  = $self->{'parent'}->XMLEncode($ret->{'link'});
	defined($ret->{'text'})  and $ret->{'text'}  = $self->{'parent'}->XMLEncode($ret->{'text'});
	defined($ret->{'image'}) and $ret->{'image'} = $self->{'parent'}->XMLEncode($ret->{'image'});
	
	return $ret;
}

=pod

=head2 Methods

=over 4

=item get_buzzcity_ad

C<>=> Does the actual fetching of the ad for the site given. Refer to new for details
Returns a list ($text_for_ad,$link_for_ad,$ad_image) value.

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
 	Initial Release for Buzzcity, can only deal with text ads for now
 0.0.7
 	Aliased get_ad to get_buzzcity_ad
 0.0.8
 	Option to reuse parent Mobile::Ads instead of creating anew
 0.0.9
 	Skipped this to have same verion number in all modules
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
