#!perl -T

use strict;
use warnings;

use Test::More tests => 9 + 4 * 7 + 3 + ((5 * 4 * 4) * 3 + 1) + 5 + 3 + 2 + 6;

use Scope::Upper qw<uplevel HERE UP>;

# Basic

sub {
 uplevel { pass 'no @_: callback' };
 is "@_", 'dummy', 'no @_: @_ outside';
}->('dummy');

sub {
 uplevel { is "@_", '', "no arguments, no context" }
}->('dummy');

sub {
 uplevel { is "@_", '', "no arguments, with context" } HERE
}->('dummy');

sub {
 uplevel { is "@_", '1', "one const argument" } 1, HERE
}->('dummy');

my $x = 2;
sub {
 uplevel { is "@_", '2', "one lexical argument" } $x, HERE
}->('dummy');

our $y = 3;
sub {
 uplevel { is "@_", '3', "one global argument" } $y, HERE
}->('dummy');

sub {
 uplevel { is "@_", '4 5', "two const arguments" } 4, 5, HERE
}->('dummy');

sub {
 uplevel { is "@_", '1 2 3 4 5 6 7 8 9 10', "ten const arguments" }
         1 .. 10 => HERE;
}->('dummy');

# Reification of @_

sub {
 my @args = (1 .. 10);
 uplevel {
  my $r = shift;
  is        $r,  1,           'shift: result';
  is_deeply \@_, [ 2 .. 10 ], 'shift: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'shift: args';
 is_deeply \@_,    [ 'dummy' ], 'shift: @_ outside';
}->('dummy');

sub {
 my @args = (1 .. 10);
 uplevel {
  my $r = pop;
  is        $r,  10,         'pop: result';
  is_deeply \@_, [ 1 .. 9 ], 'pop: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'pop: args';
 is_deeply \@_,    [ 'dummy' ], 'pop: @_ outside';
}->('dummy');

sub {
 my @args = (1 .. 10);
 uplevel {
  my $r = unshift @_, 0;
  is        $r,  11,          'unshift: result';
  is_deeply \@_, [ 0 .. 10 ], 'unshift: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'unshift: args';
 is_deeply \@_,    [ 'dummy' ], 'unshift: @_ outside';
}->('dummy');

sub {
 my @args = (1 .. 10);
 uplevel {
  my $r = push @_, 11;
  is        $r,  11,          'push: result';
  is_deeply \@_, [ 1 .. 11 ], 'push: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'push: args';
 is_deeply \@_,    [ 'dummy' ], 'push: @_ outside';
}->('dummy');

sub {
 my @args = (1 .. 10);
 uplevel {
  my ($r) = splice @_, 4, 1;
  is        $r,  5,                   'splice: result';
  is_deeply \@_, [ 1 .. 4, 6 .. 10 ], 'splice: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'splice: args';
 is_deeply \@_,    [ 'dummy' ], 'splice: @_ outside';
}->('dummy');

sub {
 my @args = (1 .. 10);
 uplevel {
  my ($r, $s, $t, @rest) = @_;
  is_deeply [ $r, $s, $t, \@rest ], [ 1 .. 3, [ 4 .. 10 ] ], 'unpack 1: result';
  is_deeply \@_, [ 1 .. 10 ],                             'unpack 1: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1 .. 10 ], 'unpack 1: args';
 is_deeply \@_,    [ 'dummy' ], 'unpack 1: @_ outside';
}->('dummy');

sub {
 my @args = (1, 2);
 uplevel {
  my ($r, $s, $t, @rest) = @_;
  is_deeply [ $r, $s, $t, \@rest ], [ 1, 2, undef, [ ] ], 'unpack 2: result';
  is_deeply \@_, [ 1, 2 ],                                'unpack 2: @_ inside';
 } @args, HERE;
 is_deeply \@args, [ 1, 2 ],    'unpack 2: args';
 is_deeply \@_,    [ 'dummy' ], 'unpack 2: @_ outside';
}->('dummy');

# Aliasing

sub {
 my $s = 'abc';
 uplevel {
  $_[0] = 'xyz';
 } $s, HERE;
 is $s, 'xyz', 'aliasing, one layer';
}->('dummy');

sub {
 my $s = 'abc';
 sub {
  uplevel {
   $_[0] = 'xyz';
  } $_[0], HERE;
  is $_[0], 'xyz', 'aliasing, two layers 1';
 }->($s);
 is $s, 'xyz', 'aliasing, two layers 2';
}->('dummy');

# goto

SKIP: {
 if ("$]" < 5.008) {
  my $cb = sub { fail 'should not be executed' };
  local $@;
  eval { sub { uplevel { goto $cb } HERE }->() };
  like $@, qr/^uplevel\(\) can't execute code that calls goto before perl 5\.8/,
           'goto croaks';
  skip "goto to an uplevel'd stack frame does not work on perl 5\.6"
                                                   => ((5 * 4 * 4) * 3 + 1) - 1;
 }

 my @args = (
  [ [ ],          [ 'm' ]      ],
  [ [ 'a' ],      [ ]          ],
  [ [ 'b' ],      [ 'n' ]      ],
  [ [ 'c' ],      [ 'o', 'p' ] ],
  [ [ 'd', 'e' ], [ 'q' ]      ],
 );

 for my $args (@args) {
  my ($out, $in) = @$args;

  my @out  = @$out;
  my @in   = @$in;

  for my $reify_out (0, 1) {
   for my $reify_in (0, 1) {
    my $desc;

    my $base_test = sub {
     if ($reify_in) {
      is_deeply \@_, $in, "$desc: \@_ inside";
     } else {
      is "@_", "@in", "$desc: \@_ inside";
     }
    };

    my $goto_test         = sub { goto $base_test };
    my $uplevel_test      = sub { &uplevel($base_test, @_, HERE) };
    my $goto_uplevel_test = sub { &uplevel($goto_test, @_, HERE) };

    my @tests = (
     [ 'goto'                    => sub { goto $base_test }         ],
     [ 'goto in goto'            => sub { goto $goto_test }         ],
     [ 'uplevel in goto'         => sub { goto $uplevel_test }      ],
     [ 'goto in uplevel in goto' => sub { goto $goto_uplevel_test } ],
    );

    for my $test (@tests) {
     ($desc, my $cb) = @$test;
     $desc .= ' (' . @out . ' out, ' . @in . ' in';
     $desc .= ', reify out' if $reify_out;
     $desc .= ', reify in'  if $reify_in;
     $desc .= ')';

     local $@;
     eval {
      sub {
       &uplevel($cb, @in, HERE);
       if ($reify_out) {
        is_deeply \@_, $out, "$desc: \@_ outside";
       } else {
        is "@_", "@out", "$desc: \@_ outside";
       }
      }->(@out);
     };
     is $@, '', "$desc: no error";
    }
   }
  }
 }

 sub {
  my $s  = 'caesar';
  my $cb = sub {
   $_[0] = 'brutus';
  };
  sub {
   uplevel {
    goto $cb;
   } $_[0], HERE;
  }->($s);
  is $s, 'brutus', 'aliasing and goto';
 }->('dummy');
}

# goto XS

SKIP: {
 skip "goto to an uplevel'd stack frame does not work on perl 5\.6" => 5
                                                                if "$]" < 5.008;

 my $desc = 'uplevel() calling goto &uplevel';
 local $@;
 eval {
  sub {
   my $outer_cxt = HERE;
   sub {
    my $inner_cxt = HERE;
    sub {
     uplevel {
      is HERE, $inner_cxt, "$desc: context inside first uplevel";
      is "@_", '1 2 3',    "$desc: arguments inisde first uplevel";
      unshift @_, 0;
      push    @_, 4;
      unshift @_, sub {
       is HERE, $outer_cxt,  "$desc: context inside second uplevel";
       is "@_", '0 1 2 3 4', "$desc: arguments inisde second uplevel";
      };
      push @_, UP;
      goto \&uplevel;
     } 1 .. 3 => UP;
    }->();
   }->();
  }->();
 };
 is $@, '', "$desc: no error";
}

# uplevel() to uplevel()

{
 my $desc = '\&uplevel as the uplevel() callback';
 local $@;
 eval {
  sub {
   my $cxt = HERE;
   sub {
    sub {
     # Note that an XS call does not need a context, so after the first uplevel
     # call UP will point to the scope above the first target.
     uplevel(\&uplevel => (sub {
      is "@_", '1 2 3', "$desc: arguments inisde";
      is HERE, $cxt,    "$desc: context inside";
     } => 1 .. 3 => UP) => UP);
    }->(10 .. 19);
   }->(sub { die 'wut' } => HERE);
  }->('dummy');
 };
 is $@, '', "$desc: no error";
}

# Magic

{
 package Scope::Upper::TestMagic;

 sub TIESCALAR {
  my ($class, $cb) = @_;
  bless { cb => $cb }, $class;
 }

 sub FETCH { $_[0]->{cb}->(@_) }

 sub STORE { die "Read only magic scalar" }
}

tie my $mg, 'Scope::Upper::TestMagic', sub { $$ };
sub {
 uplevel { is_deeply \@_, [ $$ ], "one magical argument" } $mg, HERE
}->('dummy');

tie my $mg2, 'Scope::Upper::TestMagic', sub { $mg };
sub {
 uplevel { is_deeply \@_, [ $$ ], "one double magical argument" } $mg2, HERE
}->('dummy');

# Destruction

{
 package Scope::Upper::TestTimelyDestruction;

 sub new {
  my ($class, $flag) = @_;
  $$flag = 0;
  bless { flag => $flag }, $class;
 }

 sub DESTROY {
  ${$_[0]->{flag}}++;
 }
}

SKIP: {
 skip 'This fails even with a plain subroutine call on 5.8.0' => 6
                                                               if "$]" <= 5.008;

 my $destroyed;
 {
  my $z = Scope::Upper::TestTimelyDestruction->new(\$destroyed);
  is $destroyed, 0, 'destruction: not yet 1';
  sub {
   is $destroyed, 0, 'destruction: not yet 2';
   uplevel {
    is $destroyed, 0, 'destruction: not yet 3';
   } $z, HERE;
   is $destroyed, 0, 'destruction: not yet 4';
  }->('dummy');
  is $destroyed, 0, 'destruction: not yet 5';
 }
 is $destroyed, 1, 'destruction: destroyed';
}
