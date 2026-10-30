use strict;
use warnings;

use Config;
use Test::More;

BEGIN { $Net::IDN::Punycode::_NO_XS = 1 }

use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'XS version loaded despite $_NO_XS' if !eval {
    \&Net::IDN::Punycode::encode_punycode ==
    \&Net::IDN::Punycode::PP::encode_punycode; };
  plan skip_all => 'fork is emulated' if $Config{d_pseudofork};
}

use Test::NoWarnings;
use Net::IDN::UTS46 ();

plan tests => 1 + 1;

## every code point assigned since Unicode 4.0.1 and valid under UTS #46,
## so no supported perl rejects one before the length check
our $label = join("", map chr, 0x3400 .. 0x4DB5, 0x4E00 .. 0x9FA5,
  0x20000 .. 0x2A6D6);

## old perls load Unicode tables the first time they see each code point,
## so run every code point through short labels before the alarm starts
for (my $i = 0; $i < length $label; $i += 50) {
  eval { Net::IDN::UTS46::uts46_to_ascii(substr $label, $i, 50) };
}

SKIP: {
  my $pid = fork;
  skip 'cannot fork', 1 if !defined $pid;

  if (!$pid) {
    close STDERR;
    $SIG{__WARN__} = sub {};	# Test::NoWarnings keeps a backtrace per warning
    alarm 10;
    eval { Net::IDN::UTS46::uts46_to_ascii($label) };
    exit($@ =~ /label too long/ ? 0 : 1);
  }

  waitpid($pid, 0);
  is($?, 0, 'an overlong label of distinct code points'
    .' (to_ascii rejects it before encoding)');
}
