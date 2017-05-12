#!/usr/bin/perl -w

use strict ;

use Getopt::Long;

use Nagios::WebTransact ;

my $PROGNAME = 'check_onlineservices' ;

my ($debug, $download_images, $account, $proxy, $pass) ;

Getopt::Long::Configure('bundling', 'no_ignore_case') ;
GetOptions
        ("V|version"	=> \&version,
        "h|help"	=> \&help,
        "A|account:s"	=> \$account,
        "p|pass:s"	=> \$pass,
        "P|proxy:s"	=> \$proxy,
        "h|help"	=> \&print_usage,
        "d|debug" 	=> \$debug,
        "D|download_images" 	=> \$download_images,
) ;

my $Host_Prod		= 'pericles.IPAustralia.Gov.AU' ;
my $Intro_Prod		= '/ols/ecentre/content/olsHome.jsp' ;

my $Null		= '' ;
my $Int			= q(Welcome to IP Australia's Online Services) ;

my $OraFault		= 'We were unable to process your request at this time' ;
my $AUB_message		= 'Your search returned no records (Error e100)' ;
my $AUBFault		= $OraFault . '|'. $AUB_message ;

my $url         	= 'http://' . $Host_Prod . $Intro_Prod ;

my @urls = (
  {Method => 'GET',  Url => $url,	  Qs_var => [],    Qs_fixed => [],	Exp => $Int,	Exp_Fault => $AUBFault},
	) ;


my $Proxy = {} ;
$Proxy = { server => "http://$proxy/" } if $proxy ;
$Proxy->{account} = $account  if $account ;
$Proxy->{pass}    = $pass     if $pass ;

my $web_trx = Nagios::WebTransact->new( \@urls ) ;
my ($rc, $message) =  $web_trx->check( {}, timeout => 50, debug => $debug, cookies => 1, proxy => $Proxy, download_images => $download_images) ;
print "Online Services. $message\n" ;

sub print_usage () {
        print "$PROGNAME\n" ;
        print "$PROGNAME [-d | --debug]\n";
        print "$PROGNAME [-D | --download_images]\n";
        print "$PROGNAME [-h | --help]\n";
        print "$PROGNAME [-P | --proxy] name of proxy server. Include :port as a suffix if required eg localhost:3128\n";
        print "$PROGNAME [-A | --account] account to use proxy server\n";
        print "$PROGNAME [-p | --pass] password to use proxy server\n";
        print "$PROGNAME [-V | --version]\n";
}
