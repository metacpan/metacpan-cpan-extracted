#!perl -T

use strict;
use warnings;

use Test::More;

plan tests => 23 * ($^P ? 4 : 5) + 40 +  ($^P ? 1 : 3) + 7 + (32 + 7) + 1;

use Scope::Upper qw<:words>;

# Tests with hardcoded values are for internal use only and doesn't imply any
# kind of future compatibility on what the words should actually return.

my $stray_warnings = 0;
local $SIG{__WARN__} = sub {
 ++$stray_warnings;
 warn(@_);
};

our @warns;
my $warn_catcher = sub {
 my $what;
 if ($_[0] =~ /^Cannot target a scope outside of the current stack at /) {
  $what = 'smash';
 } elsif ($_[0] =~ /^No targetable (subroutine|eval) scope in the current stack at /) {
  $what = $1;
 }
 if (defined $what) {
  push @warns, $what;
 } else {
  warn(@_);
 }
 return;
};
my $old_sig_warn;

my $top = HERE;

is $top,     0,            'main : here' unless $^P;
is TOP,      $top,         'main : top';
$old_sig_warn = $SIG{__WARN__};
local ($SIG{__WARN__}, @warns) = $warn_catcher;
is UP,       $top,         'main : up';
is "@warns", 'smash',      'main : up warns';
local @warns;
is SUB,      undef,        'main : sub';
is "@warns", 'subroutine', 'main : sub warns';
local @warns;
is EVAL,     undef,        'main : eval';
is "@warns", 'eval',       'main : eval warns';
local $SIG{__WARN__} = $old_sig_warn;

{
 my $desc = '{ 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

do {
 my $desc = 'do { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
};

eval {
 my $desc = 'eval { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local $SIG{__WARN__} = $old_sig_warn;
 is EVAL,     HERE,         "$desc : eval";
};
diag $@ if $@;

eval q[
 my $desc = 'eval "1"';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local $SIG{__WARN__} = $old_sig_warn;
 is EVAL,     HERE,         "$desc : eval";
];
diag $@ if $@;

sub {
 my $desc = 'sub { 1 }';
 is HERE,     1,      "$desc : here" unless $^P;
 is TOP,      $top,   "$desc : top";
 is UP,       $top,   "$desc : up";
 is SUB,      HERE,   "$desc : sub";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is EVAL,     undef,  "$desc : eval";
 is "@warns", 'eval', "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}->();

my $true  = 1;
my $false = !$true;

if ($true) {
 my $desc = 'if () { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

unless ($false) {
 my $desc = 'unless () { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

if ($false) {
 fail "false was true : $_" for 1 .. 5;
} else {
 my $desc = 'if () { } else { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

for (1) {
 my $desc = 'for (list) { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

for (1 .. 1) {
 my $desc = 'for (num range) { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

for (1 .. 1) {
 my $desc = 'for (pv range) { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

for (my $i = 0; $i < 1; ++$i) {
 my $desc = 'for (;;) { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

my $flag = 1;
while ($flag) {
 $flag = 0;
 my $desc = 'while () { 1 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

my @list = (1);
while (my $thing = shift @list) {
 my $desc = 'while (my $thing = ...) { 2 }';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
}

do {
 my $desc = 'do { 1 } while (0)';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
} while (0);

map {
 my $desc = 'map { 1 } 1';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
} 1;

grep {
 my $desc = 'grep { 1 } 1';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
} 1;

my $var = 'a';
$var =~ s[.][
 my $desc = 'subst';
 is HERE,     1,            "$desc : here" unless $^P;
 is TOP,      $top,         "$desc : top";
 is UP,       $top,         "$desc : up";
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SUB,      undef,        "$desc : sub";
 is "@warns", 'subroutine', "$desc : sub warns";
 local @warns;
 is EVAL,     undef,        "$desc : eval";
 is "@warns", 'eval',       "$desc : eval warns";
 local $SIG{__WARN__} = $old_sig_warn;
]e;

$var = 'a';
$var =~ s{.}{UP}e;
is $var, $top, 'subst : fake block';

$var = 'a';
$var =~ s{.}{do { UP }}e;
is $var, 1, 'subst : do block optimized away' unless $^P;

$var = 'a';
$var =~ s{.}{do { my $x; UP }}e;
is $var, 1, 'subst : do block preserved' unless $^P;

SKIP: {
 skip 'Perl 5.10 required to test given/when' => 4 * ($^P ? 4 : 5) + 4
                                                                if "$]" < 5.010;

 eval <<'TEST_GIVEN';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  my $desc = 'given';
  my $base = HERE;
  given (1) {
   is HERE,     $base + 1,    "$desc : here" unless $^P;
   is TOP,      $top,         "$desc : top";
   is UP,       $base,        "$desc : up";
   $old_sig_warn = $SIG{__WARN__};
   local ($SIG{__WARN__}, @warns) = $warn_catcher;
   is SUB,      undef,        "$desc : sub";
   is "@warns", 'subroutine', "$desc : sub warns";
   local $SIG{__WARN__} = $old_sig_warn;
   is EVAL,     $base,        "$desc : eval";
  }
TEST_GIVEN
 diag $@ if $@;

 eval <<'TEST_GIVEN_WHEN';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  my $desc = 'when in given';
  my $base = HERE;
  given (1) {
   my $given = HERE;
   when (1) {
    is HERE,     $base + 3,    "$desc : here" unless $^P;
    is TOP,      $top,         "$desc : top";
    is UP,       $given,       "$desc : up";
    $old_sig_warn = $SIG{__WARN__};
    local ($SIG{__WARN__}, @warns) = $warn_catcher;
    is SUB,      undef,        "$desc : sub";
    is "@warns", 'subroutine', "$desc : sub warns";
    local $SIG{__WARN__} = $old_sig_warn;
    is EVAL,     $base,        "$desc : eval";
   }
  }
TEST_GIVEN_WHEN
 diag $@ if $@;

 eval <<'TEST_GIVEN_DEFAULT';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  my $desc = 'default in given';
  my $base = HERE;
  given (1) {
   my $given = HERE;
   default {
    is HERE,     $base + 3,    "$desc : here" unless $^P;
    is TOP,      $top,         "$desc : top";
    is UP,       $given,       "$desc : up";
    $old_sig_warn = $SIG{__WARN__};
    local ($SIG{__WARN__}, @warns) = $warn_catcher;
    is SUB,      undef,        "$desc : sub";
    is "@warns", 'subroutine', "$desc : sub warns";
    local $SIG{__WARN__} = $old_sig_warn;
    is EVAL,     $base,        "$desc : eval";
   }
  }
TEST_GIVEN_DEFAULT
 diag $@ if $@;

 eval <<'TEST_FOR_WHEN';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  my $desc = 'when in for';
  my $base = HERE;
  for (1) {
   my $loop = HERE;
   when (1) {
    is HERE,     $base + 2,    "$desc : here" unless $^P;
    is TOP,      $top,         "$desc : top";
    is UP,       $loop,        "$desc : up";
    $old_sig_warn = $SIG{__WARN__};
    local ($SIG{__WARN__}, @warns) = $warn_catcher;
    is SUB,      undef,        "$desc : sub";
    is "@warns", 'subroutine', "$desc : sub warns";
    local $SIG{__WARN__} = $old_sig_warn;
    is EVAL,     $base,        "$desc : eval";
   }
  }
TEST_FOR_WHEN
 diag $@ if $@;
}

SKIP: {
 skip 'Hardcoded values are wrong under the debugger' => 7 if $^P;

 my $base = HERE;

 do {
  eval {
   do {
    sub {
     eval q[
      {
       is HERE,           $base + 6, 'mixed : here';
       is TOP,            $top,      'mixed : top';
       is SUB,            $base + 4, 'mixed : first sub';
       is SUB(SUB),       $base + 4, 'mixed : still first sub';
       is EVAL,           $base + 5, 'mixed : first eval';
       is EVAL(EVAL),     $base + 5, 'mixed : still first eval';
       is EVAL(UP(EVAL)), $base + 2, 'mixed : second eval';
      }
     ];
    }->();
   }
  };
 } while (0);
}

{
 my $block = HERE;
 is SCOPE,     $block,  'block : scope';
 is SCOPE(0),  $block,  'block : scope 0';
 is SCOPE(1),  $top,    'block : scope 1';
 $old_sig_warn = $SIG{__WARN__};
 local ($SIG{__WARN__}, @warns) = $warn_catcher;
 is SCOPE(2),  $top,    'block : scope 2';
 is "@warns",  'smash', 'block : scope 2 warns';
 local @warns;
 is CALLER,    $top,    'block : caller';
 is "@warns",  'smash', 'block : caller warns';
 local @warns;
 is CALLER(0), $top,    'block : caller 0';
 is "@warns",  'smash', 'block : caller 0 warns';
 local @warns;
 is CALLER(1), $top,    'block : caller 1';
 is "@warns",  'smash', 'block : caller 1 warns';
 local $SIG{__WARN__} = $old_sig_warn;
 sub {
  my $sub = HERE;
  is SCOPE,     $sub,    'block sub : scope';
  is SCOPE(0),  $sub,    'block sub : scope 0';
  is SCOPE(1),  $block,  'block sub : scope 1';
  is SCOPE(2),  $top,    'block sub : scope 2';
  is CALLER,    $sub,    'block sub : caller';
  is CALLER(0), $sub,    'block sub : caller 0';
  $old_sig_warn = $SIG{__WARN__};
  local ($SIG{__WARN__}, @warns) = $warn_catcher;
  is CALLER(1), $top,    'block sub : caller 1';
  is "@warns",  'smash', 'block sub : caller 1 warns';
  local $SIG{__WARN__} = $old_sig_warn;
  for (1) {
   my $loop = HERE;
   is SCOPE,     $loop,   'block sub for : scope';
   is SCOPE(0),  $loop,   'block sub for : scope 0';
   is SCOPE(1),  $sub,    'block sub for : scope 1';
   is SCOPE(2),  $block,  'block sub for : scope 2';
   is SCOPE(3),  $top,    'block sub for : scope 3';
   is CALLER,    $sub,    'block sub for : caller';
   is CALLER(0), $sub,    'block sub for : caller 0';
   $old_sig_warn = $SIG{__WARN__};
   local ($SIG{__WARN__}, @warns) = $warn_catcher;
   is CALLER(1), $top,    'block sub for : caller 1';
   is "@warns",  'smash', 'block sub for : caller 1 warns';
   local $SIG{__WARN__} = $old_sig_warn;
   eval {
    my $eval = HERE;
    is SCOPE,     $eval,   'block sub for eval : scope';
    is SCOPE(0),  $eval,   'block sub for eval : scope 0';
    is SCOPE(1),  $loop,   'block sub for eval : scope 1';
    is SCOPE(2),  $sub,    'block sub for eval : scope 2';
    is SCOPE(3),  $block,  'block sub for eval : scope 3';
    is SCOPE(4),  $top,    'block sub for eval : scope 4';
    is CALLER,    $eval,   'block sub for eval : caller';
    is CALLER(0), $eval,   'block sub for eval : caller 0';
    is CALLER(1), $sub,    'block sub for eval : caller 1';
    $old_sig_warn = $SIG{__WARN__};
    local ($SIG{__WARN__}, @warns) = $warn_catcher;
    is CALLER(2), $top,    'block sub for eval : caller 2';
    is "@warns",  'smash', 'block sub for eval : caller 2 warns';
    local $SIG{__WARN__} = $old_sig_warn;
   }
  }
 }->();
}

is $stray_warnings, 0, 'no stray warnings';
