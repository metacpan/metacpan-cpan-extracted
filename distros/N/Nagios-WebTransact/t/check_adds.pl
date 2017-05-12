#!/usr/bin/perl -w

use strict ;

use Nagios::WebTransact;

my $PROGNAME = 'check_adds.pl' ;

use Getopt::Long ;

Getopt::Long::Configure('bundling', 'no_ignore_case') ;

my ($debug, $download_images, $proxy, $account, $pass) ;
GetOptions
        (
        "h|help"        => \&print_usage,
        "d|debug"       => \$debug,
        "D|download_images"       => \$download_images,
        "P|proxy:s"	=> \$proxy,
	"A|account:s"   => \$account,
	"p|pass:s"	=> \$pass,
) ;

my $Proxy = {} ;
$Proxy = { server => "http://$proxy/" } if $proxy ;
$Proxy->{account} = $account  if $account ;
$Proxy->{pass}    = $pass     if $pass ;

my $ar = [ { Method    => "GET",
              Url       => "http://Pericles.IPAustralia.Gov.AU/adds2/ADDS.ADDS_START.intro",
              Qs_var    => [],
              Qs_fixed  => [], 
              Exp       => [ qw<(the) (recommend) (therefore)> ],
              Exp_Fault => "we are not able to processe",
	   } ] ;

my $web_trx = Nagios::WebTransact->new($ar) ;
my ($rc, $message) = $web_trx->check( {}, debug => $debug, proxy => $Proxy, download_images => $download_images ) ;

print $rc ? 'ADDS Ok. ' : 'Adds b0rked: ', $message, "\n" ; 

sub print_usage () {
        print "$PROGNAME Check of the IP Australia ADDS service.\n" ;
        print "$PROGNAME [-d | --debug]\n";
        print "$PROGNAME [-D | --download_images]\n";
        print "$PROGNAME [-h | --help]\n";
        print "$PROGNAME [-P | --proxy] name of proxy server. Include :port as a suffix if required eg localhost:3128\n";
        print "$PROGNAME [-A | --account] account to use proxy server\n";
        print "$PROGNAME [-p | --pass] password to use proxy server\n";

	exit 0;
}
