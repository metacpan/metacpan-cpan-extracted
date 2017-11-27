use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

local $t::Util::EVAL = 1;

test('use pragma', <<'END', {strict => 0, warnings => 0});
use strict;
use warnings;
END

test('use Module', <<'END', {'FindBin' => 0, 'Time::Local' => 0});
use FindBin;
use Time::Local;
END

test('use Module Version', <<'END', {'FindBin' => 0.01, 'Time::Local' => '0.02'});
use FindBin 0.01;
use Time::Local 0.02;
END

test('use v-string', <<'END', {perl => 'v5.8.1'});
use v5.8.1;
END

test('use version_number', <<'END', {perl => '5.008001'});
use 5.008001;
END

test('use Module ()', <<'END', {'Time::Local' => 0});
use Time::Local ();
END

test('use Module version ()', <<'END', {'Time::Local' => 0.01});
use Time::Local 0.01 ();
END

test('use Module qw(args)', <<'END', {'Time::Local' => 0});
use Time::Local qw(timelocal);
END

test('use lib', <<'END', {lib => 0, constant => 0, FindBin => 0});
use FindBin;
use lib "$FindBin::Bin/../lib";
use constant FOO => 'BAR';
END

test('use in a block', <<'END', {'Test::More' => 0});
{use Test::More}
END

local $t::Util::EVAL = 0;
test('use method', <<'END', {});
__PACKAGE__->use("Test::More");
END

# NKH/Text-Editor-Vip-0.08.1/lib/Text/Editor/Vip/Color/Color.pm
test('pod', <<'END', {});
=TODO

tests

do not use print for output but some Vip error or login func

=cut
END

test('overload', <<'END', {overload => 0}); # TRIZEN/Math-BigNum-0.20/lib/Math/BigNum/Nan.pm
use overload
  q{""} => \&stringify,
  q{0+} => \&numify,
  bool  => \&boolify,

  '=' => \&copy,

  # Some shortcuts for speed
  '+='  => \&_self,
  '-='  => \&_self,
  '*='  => \&_self,
  '/='  => \&_self,
  '%='  => \&_self,
  '^='  => \&_self,
  '&='  => \&_self,
  '|='  => \&_self,
  '**=' => \&_self,
  '<<=' => \&_self,
  '>>=' => \&_self,

  '+'  => \&nan,
  '*'  => \&nan,
  '&'  => \&nan,
  '|'  => \&nan,
  '^'  => \&nan,
  '~'  => \&nan,
  '>>' => \&nan,
  '<<' => \&nan,

  '++' => \&_self,
  '--' => \&_self,

  eq  => sub { "$_[0]" eq "$_[1]" },
  ne  => sub { "$_[0]" ne "$_[1]" },
  cmp => sub {
    $_[2]
      ? "$_[1]" cmp $_[0]->stringify
      : $_[0]->stringify cmp "$_[1]";
  },

  '!='  => sub { 1 },
  '=='  => sub { 0 },
  '>'   => sub { 0 },
  '>='  => sub { 0 },
  '<'   => sub { 0 },
  '<='  => sub { 0 },
  '<=>' => sub { 0 },

  '**'  => \&nan,
  '-'   => \&nan,
  '/'   => \&nan,
  '%'   => \&nan,
  atan2 => \&nan,

  sin  => \&nan,
  cos  => \&nan,
  exp  => \&nan,
  log  => \&nan,
  int  => \&nan,
  abs  => \&nan,
  sqrt => \&nan;
END

done_testing;
