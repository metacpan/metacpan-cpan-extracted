use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ( -s 't/Nagios_WebTransact_Timed_cache.pl' ) {
  print "If you access the Internet with a proxy server, please enter the Proxy details when prompted. Skip otherwise.\n" ;
  print "Please enter the name of any required Proxy server [if necessary for Internet access]. Include a suffix of ':<port>' if port is not 80: " ;
  chomp( $proxy = <STDIN> ) ;
  print "\n" ;
  print "Please enter the name of the account (if using a proxy that requires authentication) to use on the Proxy server: " ;
  chomp( $account = <STDIN> ) ;
  print "\n" ;
  print "Please enter the name of the password (if using a proxy that requires authentication) to use for the Proxy server: " ;
  chomp( $proxy_pass = <STDIN> ) ;
  print "\n" ;
  $stuff = '$proxy      = ' . "'$proxy'"      . ' ;' . "\n" .
           '$account    = ' . "'$account'"    . ' ;' . "\n" .
           '$proxy_pass = ' . "'$proxy_pass'" . ' ;' . "\n" ;
  open(CACHE, '> t/Nagios_WebTransact_Timed_cache.pl') or die "Can't open t/Nagios_WebTransact_Timed_cache.pl for output: $!" ;
  print CACHE $stuff ;
  print CACHE '1;', "\n" ;
  close CACHE ;
} ;

WriteMakefile(
    'NAME'	=> 'Nagios::WebTransact::Timed',
    'PREREQ_PM' => { Time::HiRes => 0, Nagios::WebTransact => 0.14, LWP => 0 },
    # 'PREREQ_PRINT' => 1,
    'VERSION_FROM' => 'Timed.pm', # finds $VERSION
);
