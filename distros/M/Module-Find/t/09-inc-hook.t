use strict;
use warnings;
use Test::More tests => 3;
use Module::Find;

BEGIN {
  package MFTestIncHook;
  sub files { keys %{$_[0]} };

  sub MFTestIncHook::INC {
    if (my $fat = $_[0]{$_[1]}) {
      open my $fh, '<', \$fat
        or die "error: $!";
      return $fh;
    }
    return;
  };

  unshift @INC, bless {
    'MFTest/Packed/Module.pm' => <<'END_MOD',
package MFTest::Packed::Module;
$VERSION = 5;
END_MOD
  }, __PACKAGE__;
}

my @l = useall 'MFTest::Packed';

is scalar @l, 1;
is $l[0], 'MFTest::Packed::Module';
is $MFTest::Packed::Module::VERSION, 5;
