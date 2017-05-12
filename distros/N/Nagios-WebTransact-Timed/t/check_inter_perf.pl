#!/usr/bin/perl -w

use strict ;

use Getopt::Long;

use Nagios::WebTransact::Timed ;

my $PROGNAME = 'check_inter_perf.pl' ;
my ($debug, $verbose, $proxy, $account, $pass, $timeout, $download_images, $fail_ratio_pct) ;

Getopt::Long::Configure('bundling', 'no_ignore_case') ;
# Without 'no_ignore_case', -P is clobbered by -p ..
GetOptions(
        "h|help"        => \&print_usage,
        "d|debug"       => \$debug,
        "v|verbose"     => \$verbose,
        "D|download_images"     => \$download_images,
        "P|proxy:s"     => \$proxy,
        "A|account:s"   => \$account,
        "T|timeout:f"   => \$timeout,
        "F|fail_ratio_pct:i"   => \$fail_ratio_pct,
        "p|pass:s"      => \$pass,
) ;

my $Proxy = {} ;
   $Proxy->{server}  = "http://$proxy/"	if $proxy ;
   $Proxy->{account} = $account		if $account ;
   $Proxy->{pass}    = $pass		if $pass ;

my $Delphion		= 'http://www.delphion.com' ;
my $Altavista		= 'http://www.altavista.com' ;
my $WPages		= 'http://www.whitepages.com.au' ;
my $EPO			= 'http://ep.espacenet.com' ;
my $Lycos		= 'http://www.lycos.com' ;
my $Netscape		= 'http://www.netscape.com' ;
my $Hotbot		= 'http://www.hotbot.com' ;
my $Google		= 'http://www.google.com' ;
my $ANZwers		= 'http://www.anzwers.com.au' ;
my $USPTO		= 'http://www.uspto.gov' ;
my $AskJeeves		= 'http://www.askjeeves.com' ;
my $Dogpile		= 'http://www.dogpile.com' ;
my $GTPatent		= 'http://www.getthepatent.com' ;

my $CatchAll		= '.*' ;	# FIXME

my $SquidFault		= 'X-Squid-Error: ERR' ;

my $Timeout		= 10 ;
my $Fail_ratio_pct 	= 50 ;

my @URLS		=  (scalar @ARGV == 0 ?
  (
    {Method => 'GET',	Url => $Delphion,Qs_var => [],	Qs_fixed => [], Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Altavista,Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $WPages,	Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $EPO,	Qs_var => [],	Qs_fixed => [], Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Lycos,	Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Netscape,Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Hotbot,	Qs_var => [],	Qs_fixed => [], Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Google,	Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $ANZwers,Qs_var => [],	Qs_fixed => [], Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $USPTO,	Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $AskJeeves,Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $Dogpile,Qs_var => [],	Qs_fixed => [],	Exp => $CatchAll,	Exp_Fault => $SquidFault},
    {Method => 'GET',	Url => $GTPatent,Qs_var => [],	Qs_fixed => [], Exp => $CatchAll,	Exp_Fault => $SquidFault},
 ) : 
  map {Method => 'GET', Url => "http://$_/", Qs_fixed => [], Qs_var => [], Exp => $CatchAll, Exp_Fault => $SquidFault},  @ARGV) ;

$timeout ||= $Timeout ;
$fail_ratio_pct ||= $Fail_ratio_pct ;

my $x = Nagios::WebTransact::Timed->new( \@URLS ) ;

my $cache = $Proxy->{server} ;		# want to set $cache for display

my ($rc, $message, $get_times_ar) =  $x->check( {}, verbose => $verbose, debug => $debug, proxy => $Proxy, timeout => $timeout,
						    fail_ratio_percent => $fail_ratio_pct, download_images => $download_images  ) ;

my $get_times_report = &present_get_times( @$get_times_ar) ; ;
my $trx_report = 'via ' . ( $cache ? "'$cache' " : ' ') . "$message $get_times_report\n" ;

print $rc ? 'Internet performance Ok:  ' : 'Internet performance b0rked: ', $trx_report, "\n" ;

sub present_get_times() {

  my (@get_times) = @_ ; 
  
  my (@worst_times, @worst_for_print, $avg, $n, $sigma_x, $sigma_x2, $stddev) ;
  
  @worst_times = sort { -$a <=> -$b } @get_times ;
  @worst_for_print = splice(@worst_times, 0, 5) ;
  
  $n = 0 ;
  foreach my $t (@get_times) {
    $sigma_x  += $t ;
    $sigma_x2 += $t * $t ;
    $n++ ;
  } 

  $avg = sprintf("%2.2f", $sigma_x / $n ) ;
  $stddev = ( $n > 1 ? sprintf("%2.2f", sqrt( ($sigma_x2 - $n * $avg * $avg)/($n - 1) ) ) :
                       'undef' ) ;
  
  return "avg: $avg stddev: $stddev  5 worst: " . join(" ", @worst_for_print) ;
}

sub print_usage () {
        print "$PROGNAME Check of Internet performance by getting and timing a bunch of URLs eg http://google.com/ http://abc.com/ http://x.com/.\n" ;
        print "$PROGNAME [-d | --debug]\n";
        print "$PROGNAME [-v | --verbose]\n";
        print "$PROGNAME [-h | --help]\n";
        print "$PROGNAME [-D | --download_images] download images in the pages (provided they have not been already fetched)\n";
        print "$PROGNAME [-P | --proxy] name of proxy server. Include :port as a suffix if required eg localhost:3128\n";
        print "$PROGNAME [-A | --account] account to use proxy server\n";
        print "$PROGNAME [-F | --fail_ratio_pct] return a failure if greater than this proportion of URLs fail. Specifed as percentage (%).\n" ;
        print "$PROGNAME [-p | --pass] password to use proxy server\n";
        print "$PROGNAME [-T | --timeout] maximum time (seconds) to wait for one URL\n" ;

        exit 0;

}
