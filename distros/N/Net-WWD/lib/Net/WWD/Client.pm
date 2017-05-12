package Net::WWD::Client;

#######################################
# WorldWide Database Client Package   #
# Copyright 2000-2004 John Baleshiski #
# All rights reserved.                #
#######################################
# Version 0.50 - Initial release
# Version 0.51 - Fixed install package to run on any Perl version > 5.0
# Version 0.52 - Implemented local cache for objects (Not released)
# Version 0.53 - Removed client/server clock sync dependency from local object caching
# Version 0.54 - Changed /usr/share/wwdcache to /usr/share/wwd/cache

=head1 NAME

Net::WWD::Client - WorldWide Database Client

=head1 SYNOPSIS

use Net::WWD::Client;


$wwd = new Net::WWD::Client;

$wwd->auth($username,$password);

print $wwd->get($domainname, $link, $readpassword);

$wwd->set($domainname, $link, $value, $modifypassword, $newmodifypassword, $temporarypassword, $timetoliveinseconds, $readpassword, $allowediplist);

$wwd->delete($domainname, $link, $readpassword);


=head1 WWD OBJECT SPACE

To obtain a username and password to be able to use WWD objects on the server IDServer.org, please visit http://idserver.org/signup

=head1 EXPORT

None by default.

=cut

use 5.0;
use CGI qw(:standard escapeHTML);
use Fcntl qw(:flock);
use HTTP::Request;
use LWP::UserAgent;
use HTTP::Headers;
use CGI::Carp "fatalsToBrowser";
use CGI::Carp;
use Data::Dumper;
#use Carp;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.54';

my $header = HTTP::Headers->new('content-type' => 'text/html');
my $ua = LWP::UserAgent->new;
my $web=$user=$pass=$localdir="";

=head1 METHODS

=cut

sub new {
        my $proto = shift;
        my $self = {};
        bless $self, $proto;
	$localdir = $ENV{'HOME'};
	if(!-e "/usr") { mkdir("/usr"); }
	if(!-e "/usr/share") { mkdir("/usr/share"); }
	if(!-e "/usr/share/wwd") {
		mkdir("/usr/share/wwd");
		chmod 0600, "/usr/share/wwd";
	}
	if(!-e "/usr/share/wwd/cache") {
		mkdir("/usr/share/wwd/cache");
		chmod 0600, "/usr/share/wwd/cache";
	}
	if(!-e "/usr/share/wwd/data-store") {
		mkdir("/usr/share/wwd/data-store");
		chmod 0600, "/usr/share/wwd/data-store";
	}
	if($localdir eq "") { $localdir = "/usr/share/wwd/cache/"; }
	my $fname = $localdir . "/.wwd";
	if(!-e $fname) { mkdir($fname); }

        return $self;
}

=head2 SET AUTHORIZATION

  $wwd->auth($username,$password);
  
  Sets internal variables to passing the username and password for every call is not needed. Set this if you need to access non-public objects.

=cut

sub auth {
	my($self,$usr,$pw) = @_;
	$user = $usr;
	$pass = $pw;
	return 1;
}

=head2 GET WWD OBJECT

  $wwd->get($site,$link,$readpassword,$flags);
  
  This function will first look in the current users wwd object cache. When a request is made to the WWD Interface, three items are returned in a : seperated list. The first item is the timestamp when the object was last modified. The second item is the object's TIME TO LIVE in seconds. A value of 0 or a negative value means the object will never be stored to the local wwd object cache.
  
  If the item is found in the local cache and has not yet expired, it's value will be used. Otherwise, the object will be requested from the server and then stored into the local wwd object cache unless it's TTL is 0 or negative.

  Currently, the only flag to pass is "n" meaning don't use any cached result (always pull from the server.

=cut

sub get {
        my ($self,$site,$link,$rp,$flags) = @_;
        if(!defined $rp) { $rp = ""; }
        if($site !~ /^http/) { $site = "http://${site}"; }
	my $domain = $site;
	if($domain =~ /\/\//) { $domain = $'; }
	if(-e "${localdir}/.wwd/${domain}/${link}" && $flags !~ /n/i) {
		$strFilename = "${localdir}/.wwd/${domain}/${link}";
		open(FH,$strFilename);
		flock(FH,LOCK_EX);
		my $ttl = <FH>;
		my $arrFinfo = stat $strFilename;
		my $objTime = $arrFinfo[9];
		if($ttl >= $objTime) {
			my $data = <FH>;
			close(FH);
			$data =~ s/\r/\n/g;
			return $data;
		}
		close(FH);
	}

        my($modtime,$ttl,$data) = parseget("${site}/wwd/wwd.cgi?t=${link}&user=${user}&pw=${pass}&rp=${rp}&${VERSION}");
	if($ttl eq "") { $ttl = 60*60*24; }
	if($ttl > 0) {
                my $fname = $localdir."/.wwd/${domain}";
                if($user ne "") { $fname .= "/${user}"; }
                cacheData("${fname}/${link}", ($ttl + time)."\n${data}");
        }
        return $data;
}

sub cacheData {
        my($fname, $data) = @_;

        @dirs = split(/\//, $fname);
        $fname = "";
        for(my $i=0; $i<@dirs; $i++) {
                $fname .= $dirs[$i];
                if($i+1 < @dirs) {
                        $fname .= "/";
                        if(!-e $fname) { mkdir($fname); }
                }
        }

        open(cFH,">${fname}");
        flock(cFH,LOCK_EX);
        print cFH $data;
        close(cFH);
}

=head2 SET THE VALUE OF A WWD OBJECT

  $wwd->set($site,$link,$value,$currentModifyPassword,$newModifyPassword,$temppass,$ttl,$readpass,$allowedlist);
  
  If the object currently has a modification password set (this is highly recommended) it must be passed in $currentModifyPassword.
  
  To specify a new modification password, set $newModifyPassword
  
  To set a temporary read password, set $temppass to $ttl:$data. For example, to set the temporary password to "hello" for the next 100 seconds, set $temppass to "100:hello";
  
  To set the object's cache TIME TO LIVE (in seconds), set $ttl. TTL can be set to 0 or a negative number to turn off all wwd client's caching of this object.
  
  To set the read password, set $readpass
  
  To restrict access to the object, set $allowedlist. To add a domainname or IP address to the allowed list, set $allowedlist to "+(domain/ip". For example, "+axissite.com". To remove a domainname or IP address from the allowed list, set $allowedlist to "-(domain/ip". To set the allowed list to a certain list, to not include the + or - as the first character. For example, to allow 192.168.1.10 and 192.168.1.11 only, set $allowedlist to "192.168.1.10,192.168.1.11". To set the domain or ip to only be able to read the value of the object 10 times, append ";10R" to the ip or domainname. For example, "+axissite.com;10R". For every read, the count will decrement. When it has been exhausted, it will automatically be removed from the list. This list is in addition to any possible read password. You can restrict access to certain ip addresses and have a read password. Both must evalute true for the object to be returned.

=cut

sub set {
        my ($self,$site,$link,$value,$modpass,$newmodpass,$temppass,$ttl,$readpass,$allowed) = @_;
        if($site !~ /^http/) { $site = "http://${site}"; }
        if(!defined $value) { $value = ""; }
        if(!defined $modpass) { $modpass = ""; }
        if(!defined $newmodpass) { $newmodpass = ""; }
        if(!defined $temppass) { $temppass = ""; }
        if(!defined $ttl) { $ttl = ""; }
        if(!defined $readpass) { $readpass = ""; }
        if(!defined $allowed) { $allowed = ""; }

        my $data = webget("${site}/wwd/wwd.cgi?ac=save&v=${value}&t=${link}&user=${user}&pw=${pass}&p=${modpass}&mp=${newmodpass}&tp=${temppass}&ttl=${ttl}&rp=${readpass}&a=${allowed}&${VERSION}");
	if($data =~ /\n\n/) { $data = $'; }
	$data =~ s/\n$//g;
        return $data;
}

=head2 DELETE WWD OBJECT

  $wwd->delete($site,$link,$pw);

  Example: $wwd->delete("idserver.org","testobject",$password);
  
  Example will delete the "testobject" from "idserver.org"
  If the read password exists, it must be supplied via $password)

=cut

sub delete {
        my ($self,$site,$link,$rp) = @_;
        if($site !~ /^http/) { $site = "http://${site}"; }
        if(!defined $rp) { $rp = ""; }

        my $data = webget("${site}/wwd/wwd.cgi?t=${link}&user=${user}&pw=${pass}&p=${rp}&ac=del&${VERSION}");
        if($data =~ /\n\n/) { $data = $'; }
        $data =~ s/\n$//g;
        return $data;
}



#####################
# Internal routines #
#####################

sub parseget {
	my $url = shift;
	my $data = webget($url);
	my $modtime=$ttl="";
	if($data =~ /\n\n/) { $data         = $'; }
	if($data =~ /:/)    { $modtime      = $`; $data = $'; }
	if($data =~ /:/)    { $ttl          = $`; $data = $'; }
	$data =~ s/\n$//g;
	return ($modtime,$ttl,$data);
}

sub webget {
        my($url, $data) = @_;
        if(!defined $url) { $url = ""; }
        if(!defined $data) { $data = ""; }
        return $ua->request(HTTP::Request->new(GET,"${url}?${data}",$header))->as_string();
}


1;
__END__

=head1 AUTHOR

John Baleshiski, E<lt>john@idserver.orgE<gt>

For more information and the technical specification, visit http://idserver.org/wwd

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by John Baleshiski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
