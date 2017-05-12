# Copyright: 	2014 by Sebastian Enger 
# Email: 		sebastian.enger at gmail - com
# Web: 			Buzz News on http://www.buzzerstar.com/
# Licence: 		Perl
# All rights released.
package MobileDetect;
#
# MobileDetect.pm - Perl detection for mobile phone and tablet devices
#
# Thanks to:
#   https://github.com/serbanghita/Mobile-Detect/blob/master/Mobile_Detect.php
#	https://github.com/serbanghita/Mobile-Detect/blob/master/Mobile_Detect.json
#
use 5.006;
use strict;
no strict "subs";
use warnings FATAL => 'all';
no warnings qw/misc/;
use JSON;
use LWP::Protocol::https;
use LWP::UserAgent;
use Storable;

our $VERSION 					= '1.21';
use constant JSON_REMOTE_FILE 	=> 'https://raw.githubusercontent.com/serbanghita/Mobile-Detect/master/Mobile_Detect.json';
use constant JSON_LOCAL_FILE 	=> '/var/tmp/Mobile_Detect.json';
use constant HASH_LOCAL_FILE 	=> '/var/tmp/Mobile_Detect.db';

our @EXPORT = qw(is_phone is_tablet is_mobile_os is_mobile_ua detect_phone detect_tablet detect_mobile_os detect_mobile_ua);

sub new {
	my($class, %args) = @_;
	my $self 		= bless({}, $class);
	my $json 		= JSON->new();
	my $filestamp	= 0;
	my $filesize	= 0; 
	my %hashfile;
	my $hash;
	
	if (-e HASH_LOCAL_FILE && -f HASH_LOCAL_FILE){
		$filestamp	= -M HASH_LOCAL_FILE;
		$filestamp	= int($filestamp);
		$filesize	= -s HASH_LOCAL_FILE; 
	}
		 	
	# if we have a filestamp a file that has been created 31 days before
	# AND we have a filesize of the file of lower than 1000 bytes we have to download and parse the json file
	if ( $filestamp > 31 && $filesize < 1000 ){ 
	#	print "just downloading json content and fix it to hash content\n";
		
		unlink JSON_LOCAL_FILE; 
		unlink HASH_LOCAL_FILE;
	
		my $ua 				= LWP::UserAgent->new();
		my $res 			= $ua->get(JSON_REMOTE_FILE);
		my $json_content 	= "";
		if ($res->is_success) {
			 $json_content 	= $res->content;
		 } else {
			 die "Cannot download JSON RAW File From Github - exiting." . $res->status_line;
		 }
		my $json_text 		= $json->allow_nonref->utf8->relaxed->decode($json_content);
		
		while (my($k, $v) = each (%{$json_text->{uaMatch}->{tablets}})){
			$hash->{tablets}->{$k} = $v;
		}
		while (my($k, $v) = each (%{$json_text->{uaMatch}->{phones}})){
			$hash->{phones}->{$k} = $v;
		} 
		while (my($k, $v) = each (%{$json_text->{uaMatch}->{browsers}})){
			$hash->{browsers}->{$k} = $v;
		}
		while (my($k, $v) = each (%{$json_text->{uaMatch}->{os}})){
			$hash->{os}->{$k} = $v;
		}
		$self->{json}=$hash;	
		my %hashfile = %{$hash};
		Storable::store(\%hashfile, HASH_LOCAL_FILE) or die "Can't store %hash in ".HASH_LOCAL_FILE." !\n";
	} else {
	#	print "just reading hash content\n";
		$hash = Storable::retrieve(HASH_LOCAL_FILE);
		$self->{json}=$hash;
	}
	return $self;
}

sub detect_phone(){
	my $self 	= shift;
	my $str 	= shift;
	my $retVal  = 0;
	while (my($k1, $v1) = each (%{$self->{json}->{phones}})){
		if ($str =~ m/$v1/igs){
			$retVal = $k1;
		}
	}
	return $retVal;
}
sub detect_tablet(){
	my $self 	= shift;
	my $str 	= shift;
	
	my $retVal  = 0;
	while (my($k2, $v2) = each (%{$self->{json}->{tablets}})){
		if ($str =~ m/$v2/igs){
			$retVal = $k2;
		} 
	}
	return $retVal;
}
sub detect_mobile_os(){
	my $self 	= shift;
	my $str 	= shift;
	
	my $retVal  = 0;
	while (my($k3, $v3) = each (%{$self->{json}->{os}})){
		if ($str =~ m/$v3/igs){
			$retVal = $k3;
		} 
	}
	return $retVal;
}
sub detect_mobile_ua(){
	my $self 	= shift;
	my $str 	= shift;

	my $retVal  = 0;
	while (my($k4, $v4) = each (%{$self->{json}->{browsers}})){
		if ($str =~ m/$v4/igs){
			$retVal = $k4;
		}
	}
	return $retVal;
}

sub is_phone(){
	my $self 	= shift;
	my $str 	= shift;
	
	my $val1 	= $self->detect_phone($str);
	my $val2 	= $self->detect_mobile_os($str);
	my $val3 	= $self->detect_mobile_ua($str);
	if ( $val1 =~ /[a-zA-Z]/igs || $val2 =~ /[a-zA-Z]/igs || $val3 =~ /[a-zA-Z]/igs ){
		return 1;
	}
	return 0;
}
sub is_tablet(){
	my $self 	= shift;
	my $str 	= shift;
	my $val 	= $self->detect_tablet($str);
	if ($val =~ /[a-zA-Z]/igs){
		return 1;
	}
	return 0;
}
sub is_mobile_os(){
	my $self 	= shift;
	my $str 	= shift;
	my $val 	= $self->detect_mobile_os($str);
	if ($val =~ /[a-zA-Z]/igs){
		return 1;
	}
	return 0;
}
sub is_mobile_ua(){
	my $self 	= shift;
	my $str 	= shift;
	my $val 	= $self->detect_mobile_ua($str);
	if ($val =~ /[a-zA-Z]/igs){
		return 1;
	}
}

=pod
=head1 NAME

	MobileDetect - The great new MobileDetect Library for Perl is finally available!
	Perl Module for the PHP Toolchain Mobile Detect from https://github.com/serbanghita/Mobile-Detect .
	More Information and development Tools can be found here https://www.buzzerstar.com/development/ and https://devop.tools/

	Feel free to download, modify or change to code to fullfill your needs.

=head1 VERSION
	
	1.16
	
=head1 DEPENDENCIE

	use strict;
	use JSON;
	use LWP::Protocol::https;
	use LWP::UserAgent;
	use Storable;

=head1 SYNOPSIS

	#!/usr/bin/perl

	use MobileDetect;

	my $obj 	= MobileDetect->new(); 
	my $check 	= "Mozilla/5.0 (Linux; U; Android 4.1.2; nl-nl; SAMSUNG GT-I8190/I8190XXAME1 Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"; # Samsung Galaxy S3 Mini

	print "is_phone: 			".$obj->is_phone($check); print "\n";
	print "detect_phone: 		".$obj->detect_phone($check); print "\n";
	print "is_tablet: 			".$obj->is_tablet($check);print "\n";
	print "detect_tablet: 		".$obj->detect_tablet($check);print "\n";

	print "is_mobile_os: 		".$obj->is_mobile_os($check);print "\n";
	print "detect_mobile_os:	".$obj->detect_mobile_os($check);print "\n";
	print "is_mobile_ua: 		".$obj->is_mobile_ua($check);print "\n";
	print "detect_mobile_ua:	".$obj->detect_mobile_ua($check)."\n";

=head1 DESCRIPTION

Check a given string against the Mobile Detect Library that can be found here: https://github.com/serbanghita/Mobile-Detect
I have prepared a Perl Version, because there is no such thing in perl and i also want to show my support for Mr. Șerban Ghiță
and his fine piece of PHP Software.

The newest Version 1.15 has build in flat file database support, where the content of the downloaded json file is being preparsed
and can be read into memory with the needed hash structure for perl to process. 

This is the Perl Version. You need to setup LWP with HTTPS Support before (needed to regulary update the Mobile_Detect.json file
	from github).

	Install needed modules example:
	From the bash call :"cpan"
	cpan [1] Promt: call "install JSON"
	cpan [2] Promt: call "install JSON::XS"
	cpan [3] Promt: call "install LWP::Protocol"
	cpan [4] Promt: call "install LWP::Protocol::https"
	cpan [5] Promt: call "install Storable"
	
=head1 AUTHOR

	Sebastian Enger, C<< <sebastian _._ enger (at) gmail _._ com> >>
	L<Buzzerstar Development|https://www.buzzerstar.com/development/>
	L<Buzz Trending News auf BuzzerStar|https://www.buzzerstar.com/trending/>
	L<Tech Startup News|https://blog.onetopp.com/>
	L<Innovation Consulting|https://www.onetopp.com/>
	L<Devops|https://devop.tools/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mobiledetect-pp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MobileDetect>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MobileDetect

You can also look for information at:

L<https://code.google.com/p/mobiledetect/>

Or write the author an bug request email: 
Sebastian Enger, C<< <sebastian.enger at gmail.com> >>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sebastian Enger.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

1; # End of MobileDetect