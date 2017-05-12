# Mobile::Ads.pm version 0.0.2
#
# Copyright (c) 2008 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Ads;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw();

$Mobile::Ads::VERSION='0.0.2';
$Mobile::Ads::ver=$Mobile::Ads::VERSION;

use strict 'vars';
use warnings;
use diagnostics;
use Carp();
use LWP::UserAgent();
use HTTP::Request::Common();

=head1 NAME

Mobile::Ads - base class for Mobile Ads

Version 0.0.2

=head1 SYNOPSIS

 use Mobile::Ads::Admob;
 
=head1 DESCRIPTION

C<Mobile::Ads> provides an object oriented interface to serve advertisements
It does nothing by itself and you should probably use one of
C<Mobile::Ads::AdMob_v1> (old AdMob implementation, lacks graphical ads)
C<Mobile::Ads::AdMob_v2> (newer AdMob, support image ads)
C<Mobile::Ads::Admoda>
C<Mobile::Ads::AdSense>  (Google AdSense for Mobile)
C<Mobile::Ads::Adsgr>    (ads.gr mobile ads)
C<Mobile::Ads::Adultmoda>
C<Mobile::Ads::Buzzcity>
C<Mobile::Ads::Decktrade>
C<Mobile::Ads::GetMobile>
C<Mobile::Ads::MoJiva>
C<Mobile::Ads::ZastAdz>

Refer to their man pages for help (?)

=head1 new Mobile::Ads

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;

	#defaults
	$self->{'timeout'} = 2;
	
	$self->{'ua'} = new LWP::UserAgent;
	$self->{'ua'}->timeout($self->{'timeout'});
	$self->{'ua'}->agent("Mobile::Ads/$Mobile::Ads::VERSION/".$self->{'ua'}->_agent);
	#development aids 
	$self->{'DEBUG'} = 0;
	
	return $self;
}

sub get_ad {
	my $self = shift;
	
	my ($url,$method,$params) = ('','','');
	if (ref $_[0] eq 'HASH') {
		$url	= $_[0]->{'url'};
		$method = $_[0]->{'method'};
		$params = $_[0]->{'params'};
	}
	else {
		($url,$method,$params) = @_;
	}
	
	#test $uri is valid...
	$url =~ m|^https?://| or Carp::croak("Ads.pm get_ad(): invalid URL $url\n");
	
	my $res;
	# fetch data
	if ($method eq 'POST') {
		if ($params && ref($params) eq 'HASH') {
			$self->{'DEBUG'} and Carp::cluck("POST to $url with $params\n");
			$res = $self->{'ua'}->request(HTTP::Request::Common::POST $url, $params);
		}
		else {
			$self->{'DEBUG'} and Carp::cluck("POST to $url without params\n");
			#perhaps no need for $params, but one should still POST to this URL
			$res = $self->{'ua'}->request(HTTP::Request::Common::POST $url);
		}
	}
	else {
		if ($params && ref($params) eq 'HASH') {
			#add $params to the Query_String (remember to URLEncode them, btw)
			if ($url =~ m|\?|) {
				Carp::croak("Ads.pm get_ad() : either construct the QUERY_STRING for $url yourself, or give arguments in \$params, but not both\n");
			}
			else {
				#first add the ``?'' to the URL (making it a URI :)
				my $uri = $url . "?";
				
				my $last = 0; #useful to figure out when to stop adding ``&''s
				
				foreach (keys(%$params)) {
					if ($last) {
						$last = 0;
						$uri .= "&";
					}
					
					$uri .= $self->URLEncode($_);
					if ($params->{$_}) {
						$uri .= "=".$self->URLEncode($params->{$_});
					}
					
					$last = 1;
				}
				$self->{'DEBUG'} and Carp::cluck("GET to $url with $params -> $uri\n");
				$res = $self->{'ua'}->request(HTTP::Request::Common::GET $uri);
			}
		}
		else {
			$self->{'DEBUG'} and Carp::cluck("GET to $url without params\n");
			$res = $self->{'ua'}->request(HTTP::Request::Common::GET $url);
		}
	}
	
	if ($res->is_success()) {
		$self->{'DEBUG'} and Carp::cluck($res->as_string." is_success\n");
		return($res->content()); 
	}
	else {
		Carp::croak("HTTP Request failed with ".$res->as_string."\n");
	}
}

sub URLEncode {
	my $self = shift;
	
	my $toencode = shift;
	
	$toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
	return $toencode;
}

sub XMLEncode {
	my $self = shift;
	
	my $toencode = shift;
	$toencode =~ s/\&(?!amp\;)/\&amp;/sg;
	$toencode =~ s|\>|\&gt;|sg;
	$toencode =~ s|\<|\&lt;|sg;
	#only for the sake of completeness...
	$toencode =~ s|\"|\&quot;|sg;
	return $toencode;
}

=pod

=head2 Methods

=over 4

=item get_ad

C<>=> Does the actual HTTP. 
url is obviously the ad serving site URL,
method is either ``POST'' or anything else (in which case a GET is performed)
and params is a hash reference with key/value pairs. The module will take care to URLEncode
as neccessary or set Content-length and Content-type if POST.
Note that you can either construct a GET URI yourself (taking care of encoding and stuff or
pass the arguments in params, but not both). 

Example:
	$response = $ad->get_ad ( 
							{ 
								url => 'http://ad.serving.site/ad.php',
								method => 'GET',
								params => {
											'some'	=> 'params'
											'can'	=> 'go here'
										}
							});

will result in ``http://ad.serving.site/ad.php?some=params&can=go%20here'' being actually sent
to the server.

Will happily croak() if server is unreachable or not return 200, so eval() as neccessary.
Will NOT apply any kind of translation to the returned content. For this, each module should
make provisions for itself.
 
=item URLEncode

C<>=> Shamelessly plugged from Apache::ASP::Server::URLEncode

=item XMLEncode

C<>=> Just escapes ``&'' where neccessary in its input to make it XML safe. 
Proably of use to everyone, so put here.

=back

=cut


=head1 Revision History

 0.0.1 
	Initial Release
 0.0.2 
	First CPAN released version and the addition of $self->timeout to easily set
	LWP::UserAgent timeout
 
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
