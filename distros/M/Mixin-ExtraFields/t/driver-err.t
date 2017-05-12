use strict;
use warnings;

# Let's just test a couple of the failures that should be possible if you screw
# up your driver declaration.

use Test::More tests => 2;
use lib 't/lib';

eval {
  package MEF::Tarkin::Grand;
  require Mixin::ExtraFields;
  Mixin::ExtraFields->import('-fields');
};

like($@, qr/no driver supplied/, "there is no default default driver");

eval {
  package MEF::Tarkin::Grand;
  require Mixin::ExtraFields;
  Mixin::ExtraFields->import(-fields => { driver => '+MEFD::NoCompile' });
};

like($@, qr/compilation failed/i, "we can't use a driver that won't compile!");
