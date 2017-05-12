# Mobile::Ads::AdMob_v2.pm version 0.1.0
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads::AdMob_v2;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::AdMob_v2::VERSION='0.1.0';
$Mobile::Ads::AdMob_v2::ver=$Mobile::Ads::AdMob_v2::VERSION;

use strict 'vars';
use Carp();
use Mobile::Ads();
use Digest::MD5 qw();

=head1 NAME

Mobile::Ads::AdMob_v2 - module to serve AdMob ads

Version 0.1.0

=head1 SYNOPSIS

 use Mobile::Ads::AdMob_v2;
 $ad = new Mobile::Ads::AdMob_v2
 ($text,$link,$image) = $ad->get_v2_ad({
				site	=> 'AdMob site code',
 				remote	=> $ENV{'HTTP_USER_AGENT'},
 				address	=> $ENV{'REMOTE_ADDR'},
 				text	=> 'default ad text',
 				link	=> 'default ad link',
 				test	=> 'set this if this is a test ad',
 				});
 
=head1 DESCRIPTION

C<Mobile::Ads::AdMob_v2> provides an object oriented interface to serve advertisements
from AdMob in mobile sites.
This is just a slightly altered version of the perl code found on AdMob's site.

=head1 new Mobile::Ads::AdMob_v2

=over 4

=item [$parent]

To reuse Mobile::Ads in multiple (subsequent) ad requests, you can pass a C<Mobile::Ads>
reference here. Instead of creating a new Mobile::Ads object, we will use the one you
pass instead. This might save a little C<LWP::UserAgent> creation/destruction time.

=head2 Parameters/Properties

=over 4

=item site

C<>=> AdMob site code, delivered by them. Something in the form off ``0123456789abcde''

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
	
	$self->{'admob_ignore'} = {
								'HTTP_PRAGMA'			=> 1, 
								'HTTP_CACHE_CONTROL'	=> 1,
								'HTTP_CONNECTION'		=> 1, 
								'HTTP_USER_AGENT'		=> 1,
								'HTTP_COOKIE'			=> 1
							};
	return $self;
}

*get_ad = \&get_v2_ad;

sub get_v2_ad {
	my $self = shift;
	
	my $admob_version  = '20080401-PERL-137fac4271564026';
	my $admob_endpoint = 'http://r.admob.com/ad_source.php';
	my $encoding = 'UTF-8';
	
	my ($site,$test,$remote,$address,$uri,$markup,$text,$link,$postal_code,$area_code,$coordinates,$dob,$gender,$keywords,$search) = 
			('','','','','','','','','','','','','','','','');
	
	if (ref $_[0] eq 'HASH') {
		$site	 = $_[0]->{'site'} || $self->{'site'};
		$test	 = $_[0]->{'test'} || '';
		$remote	 = $_[0]->{'remote'} || $ENV{'HTTP_USER_AGENT'};
		$address = $_[0]->{'address'} || $ENV{'REMOTE_ADDR'};
		$uri	 = $_[0]->{'uri'} || 'http://'.$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'};
		$markup	 = $_[0]->{'markup'} || '';
		$text	 = $_[0]->{'text'} || $self->{'text'} || '';
		$link	 = $_[0]->{'link'} || $self->{'link'} || '';
		$postal_code = $_[0]->{'postal_code'} || '';
		$area_code 	 = $_[0]->{'area_code'} || '';
		$coordinates = $_[0]->{'coordinates'} || '';
		$keywords	 = $_[0]->{'keywords'} || '';
		$search	 = $_[0]->{'search'} || '';
		$dob	 = $_[0]->{'dob'} || '';
		$gender	 = $_[0]->{'gender'} || '';
		#I cannot yet figure out what $admob_t is supposed to be
		#but in their code, the way it is written, it is always '' (empty string or NULL)
	}
	else {
		($site,$test,$remote,$address,$uri,$markup,$text,$link,$postal_code,$area_code,$coordinates,$dob,$gender,$keywords,$search) = @_;
	}
	
	$site	 ||= $self->{'site'};
	$remote	 ||= $ENV{'HTTP_USER_AGENT'};
	$address ||= $ENV{'REMOTE_ADDR'};
	$text ||= $self->{'text'};
	$link ||= $self->{'link'};
		
	Carp::croak("cant serve ads without site\n") unless ($site);
	Carp::croak("cant serve ads without remote user agent\n") unless ($remote);
	Carp::croak("cant serve ads without remote address\n") unless ($address);
	
	my $admob_post = {
						's'		=> $site,
						'u'		=> $remote,
						'i'		=> $address,
						'p'		=> $uri,
						't'		=> '', #still haven't figured out what this is
						'e'		=> $encoding, 
						'ma'	=> $markup,
						'v'		=> $admob_version,
						'd[pc]'	=> $postal_code,
						'd[ac]'	=> $area_code,
						'd[coord]'	=> $coordinates,
						'd[dob]'	=> $dob,
						'd[gender]' => $gender,
						'k'			=> $keywords,
						'search'	=> $search,
					};
	
	#stuff the rest of the $ENV in $admob_post
	foreach (keys(%ENV)) {
		if ( !$self->{'admob_ignore'}->{$_} ) {
			length($_) > 5 and $admob_post->{"h[" . substr( $_, 5 ) . "]"} = $ENV{$_};
		}
	}
	
	#test ads need just find POSTs ``m'' field.
	if ($test eq 'test') {
		$admob_post->{'m'} = '';
	}
	
	#do the POST
	my $res;
	#through $self->{parent} prefrably...
	eval q[$res = $self->{'parent'}->get_ad({
												url		=> $admob_endpoint,
												method	=> 'POST',
												params	=> $admob_post
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
	if ($ret->{'link'} && $ret->{'text'}) {
		$ret->{'image'} ||= '';
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

=item get_v2_ad

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
