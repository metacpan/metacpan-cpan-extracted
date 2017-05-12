use strict;
use Test;
use POE::Component::Daemon::Win32;
use Win32::TieRegistry ( Delimiter => '/' );

BEGIN { plan tests => 2 };

print "Running Windows NT..................";
ok (IsWinNT(), 1);
printf "Running Windows NT 4.0 or greater...";
ok(IsSupportedOSVersion(), 1);

sub IsWinNT {

  $Registry->Open (
    'LMachine/SOFTWARE/Microsoft/Windows NT/', {
    Access => Win32::TieRegistry::KEY_READ()
  }) ? 1 : 0;

}

sub IsSupportedOSVersion {

  my $version = 0;

  if (my $key = $Registry->Open (
    'LMachine/SOFTWARE/Microsoft/Windows NT/CurrentVersion/', {
    Access => Win32::TieRegistry::KEY_READ()
  })) {

  	unless (defined ($version = $key->{'CurrentVersion'})) {

  		$version = 0;

  	}

  }

  $version >= 4.0 ? 1 : 0;

}