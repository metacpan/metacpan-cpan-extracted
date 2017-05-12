#!/usr/bin/perl -w

use strict ;

use Getopt::Long;

use Nagios::WebTransact ;

my $PROGNAME = 'check_atmoss_new_conn.pl' ;
my ($debug, $download_images, $proxy, $account, $pass) ;

Getopt::Long::Configure('bundling', 'no_ignore_case') ;
GetOptions (
        "h|help"        => \&print_usage,
        "d|debug"       => \$debug,
	"D|download_images"       => \$download_images,
        "P|proxy:s"     => \$proxy,
        "A|account:s"   => \$account,
        "p|pass:s"      => \$pass,
) ;

my $Proxy = {} ;
$Proxy = { server => "http://$proxy/" } if $proxy ;
$Proxy->{account} = $account  if $account ;
$Proxy->{pass}    = $pass     if $pass ;

my $Intro              	= 'http://Pericles.IPAustralia.Gov.AU/atmoss/falcon.application_start' ;
my $MultiSessConn	= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Users_Cookies.Run_Create' ;
my $Search		= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon.Result' ;
my $ResultDetails	= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Details.Show_TM_Details' ;
my $SrchList		= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Searches.List_Search' ;
my $DelSrchLists	= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Searches.SubmitChoice' ;
my $EndSession		= 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Users_Cookies.clear_User' ;

my $Int			= 'Welcome to ATMOSS' ;
my $ConnSrch		= 'Connect to Trade Mark Search' ;
my $MltiSess		= 'Fill in one or more of the fields below' ;
my $Srch		= 'Your search request retrieved\s+\d+\s+match(es)?' ;
my $ResSum		= 'Trade Mark\s+:\s+\d+' ;
my $ResDet		= 'Indexing Details' ;
my $SrchLs		= 'Search List' ;

my $MSC_f               = [p_Anon => 'ANONYMOUS', p_user_type => 'Enter as Guest', p_JS => 'N'] ;

my $Srch_v		= [p_tm_number_list => 'tmno'] ;

my $RD_v		= [p_tm_number => 'tmno'] ;
my $RD_f		= [p_Detail => 'DETAILED', p_search_no => 0];
my $DAS_f		= [p_CmbDelete => 1, p_Button => 'Delete All Searches', p_extID => 'ANONYMOUS', p_password => '', p_CmbDisplay => 1, 
			   p_CmbRefine => 1, p_CmbCombine1 => 1, p_CmbCombineOperator => 'INTERSECT', p_CmbCombine2 => 1, p_search_used => 0 ] ;

my $OraFault		= 'We were unable to process your request at this time' ;

my @URLS		= (
  {Method => 'GET',  Url => $Intro,	      Qs_var => [],	Qs_fixed => [],    Exp => $Int,	    Exp_Fault => $OraFault},
  {Method => 'POST', Url => $MultiSessConn,   Qs_var => [],	Qs_fixed => $MSC_f,Exp => $MltiSess,Exp_Fault => $OraFault},
  {Method => 'POST', Url => $Search,	      Qs_var => $Srch_v,Qs_fixed => [],    Exp => $ResSum,  Exp_Fault => $OraFault},
  {Method => 'GET',  Url => $ResultDetails,   Qs_var => $RD_v,	Qs_fixed => $RD_f, Exp => $ResDet,  Exp_Fault => $OraFault},
  {Method => 'GET',  Url => $SrchList,        Qs_var => [],	Qs_fixed => [],    Exp => $SrchLs,  Exp_Fault => $OraFault},
  {Method => 'POST', Url => $DelSrchLists,    Qs_var => [],	Qs_fixed => $DAS_f,Exp => $MltiSess,Exp_Fault => $OraFault},
  {Method => 'GET',  Url => $EndSession,      Qs_var => [],	Qs_fixed => [],    Exp => $Int,     Exp_Fault => $OraFault},
	) ;

my (@tmarks, $tmno, $i) ;

@tmarks = @ARGV ? @ARGV : (3, 100092, 200099, 300006, 400075, 500067, 600076, 700066, 800061) ;
$i = @ARGV == 1 ? 0 : int( rand($#tmarks) + 0.5 ) ;
$tmno = $tmarks[$i] ;

my $x = Nagios::WebTransact->new( \@URLS ) ;
my ($rc, $message) =  $x->check( {tmno => $tmno}, debug => $debug, proxy => $Proxy, download_images => $download_images ) ;

print $rc ? 'ATMOSS Ok. ' : 'ATMOSS b0rked: ', $message, "\n" ; 
     
sub print_usage () {
	print "$PROGNAME Check of IP Australia ATMOSS service.\n" ;
        print "$PROGNAME Trade Mark Number eg '3'\n" ;
        print "$PROGNAME [-d | --debug]\n";
        print "$PROGNAME [-h | --help]\n";
	print "$PROGNAME [-D|download_images]\n";
	print "$PROGNAME [-P | --proxy] name of proxy server. Include :port as a suffix if required eg localhost:3128\n";
        print "$PROGNAME [-A | --account] account to use proxy server\n";
        print "$PROGNAME [-p | --pass] password to use proxy server\n";

	exit 0 ;

}
