use Test;
use vars qw($tests);

BEGIN {$tests = 5; plan tests => $tests}

$cmd = "perl -Mblib t/check_inter_perf.pl -h";
$str = `$cmd`;
print "Test was: $cmd\n" if ($?);
$t += ok $str, '/^check_inter_perf/';

@nosuchsites = qw(www.cia.gov.au www.cia.gov.nz) ;
@slowsites = qw(pericles.ipaustralia.gov.au/ols/ecentre/content/olsHome.jsp) ;
@graphicsites = qw(www.chinatelecom.com.cn) ;

require 't/Nagios_WebTransact_Timed_cache.pl' ;

if ( $proxy && $account && $proxy_pass ) {
  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy -A $account -p $proxy_pass" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance Ok:/' ;

  print "Test was: $cmd\n" if ($?);
  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy -A $account -p $proxy_pass @nosuchsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -T 1 -P $proxy -A $account -p $proxy_pass @slowsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy -A $account -p $proxy_pass -D -v @graphicsites" ;
  $str = `$cmd 2>&1` ;
  $t += ok $str, '/\S+\s+\d+\.\d+\s+image download time:\s+\d+\.\d+/'

} elsif ( $proxy ) {
  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance Ok:/' ;

  print "Test was: $cmd\n" if ($?);
  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy @nosuchsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -T 1 -P $proxy @slowsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -P $proxy -D -v @graphicsites" ;
  $str = `$cmd 2>&1` ;
  $t += ok $str, '/\S+\s+\d+\.\d+\s+image download time:\s+\d+\.\d+/'

} else {
  $cmd = "perl -Mblib t/check_inter_perf.pl" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance Ok:/' ;

  print "Test was: $cmd\n" if ($?);
  $cmd = "perl -Mblib t/check_inter_perf.pl @nosuchsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -T 1 @slowsites" ;
  $str = `$cmd` ;
  $t += ok $str, '/^Internet performance b0rked:/' ;

  $cmd = "perl -Mblib t/check_inter_perf.pl -D -v @graphicsites" ;
  $str = `$cmd 2>&1` ;
  $t += ok $str, '/\S+\s+\d+\.\d+\s+image download time:\s+\d+\.\d+/'

}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
