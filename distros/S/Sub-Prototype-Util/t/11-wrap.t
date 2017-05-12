#!perl -T

use strict;
use warnings;

use Test::More tests => 7 + 6 + 3 + 1 + 6 + 1 + (("$]" >= 5.010) ? 2 : 0) + 1;

use Scalar::Util;
use Sub::Prototype::Util qw<wrap>;

sub exception {
 my ($msg) = @_;
 $msg =~ s/\s+/\\s+/g;
 return qr/^$msg.*?at\s+\Q$0\E\s+line\s+\d+/;
}

eval { wrap undef };
like $@, exception('No subroutine'), 'recall undef croaks';
eval { wrap '' };
like $@, exception('No subroutine'), 'recall "" croaks';
eval { wrap \1 };
like $@, exception('Unhandled SCALAR'), 'recall scalarref croaks';
eval { wrap [ ] };
like $@, exception('Unhandled ARRAY'), 'recall arrayref croaks';
eval { wrap sub { } };
like $@, exception('Unhandled CODE'), 'recall coderef croaks';
eval { wrap { 'foo' => undef, 'bar' => undef } };
like $@, qr!exactly\s+one\s+key/value\s+pair!,
                                           'recall hashref with 2 pairs croaks';
eval { wrap 'hlagh', qw<a b c> };
like $@, exception('Optional arguments'),
                                  'recall takes options in a key => value list';

my $push_exp = "$]" >= 5.013_007 ? '{ CORE::push($_[0], @_[1..$#_]) }'
                                 : '{ CORE::push(@{$_[0]}, @_[1..$#_]) }';
my $push = wrap 'CORE::push', compile => 0;
is($push, 'sub ' . $push_exp, 'wrap push as a sub (default)');
$push = wrap 'CORE::push', sub => 1, compile => 0;
is($push, 'sub ' . $push_exp, 'wrap push as a sub');
$push = wrap 'CORE::push', sub => 0;
is($push, $push_exp, 'wrap push as a raw string');
$push = wrap 'CORE::push';
is(ref $push, 'CODE', 'wrap compiled push is a CODE reference');
my @a = qw<a b>;
my $ret = $push->(\@a, 7 .. 12);
is_deeply(\@a, [ qw<a b>, 7 .. 12 ], 'wrap compiled push works');
is($ret, 8, 'wrap compiled push returns the correct number of elements');

my $push2 = wrap { 'CORE::push' => '\@;$' };
is(ref $push2, 'CODE', 'wrap compiled truncated push is a CODE reference');
@a = qw<x y z>;
$ret = $push2->(\@a, 3 .. 5);
is_deeply(\@a, [ qw<x y z>, 3 ], 'wrap compiled truncated push works');
is($ret, 4, 'wrap compiled truncated push returns the correct number of elements');

sub cb (\[$@]\[%&]&&);
my $cb = wrap 'main::cb', sub => 0, wrong_ref => 'die';
my $x = ', sub{&{$c[0]}}, sub{&{$c[1]}}) ';
is($cb,
   join('', q!{ my @c = @_[2, 3]; !,
            q!my $r = ref($_[0]); !,
            q!if ($r eq 'SCALAR') { !,
             q!my $r = ref($_[1]); !,
             q!if ($r eq 'HASH') { !,
              q!main::cb(${$_[0]}, %{$_[1]}! . $x,
             q!} elsif ($r eq 'CODE') { !,
              q!main::cb(${$_[0]}, &{$_[1]}! . $x,
             q!} else { !,
              q!die !,
             q!} !,
            q!} elsif ($r eq 'ARRAY') { !,
             q!my $r = ref($_[1]); !,
             q!if ($r eq 'HASH') { !,
              q!main::cb(@{$_[0]}, %{$_[1]}! . $x,
             q!} elsif ($r eq 'CODE') { !,
              q!main::cb(@{$_[0]}, &{$_[1]}! . $x,
             q!} else { !,
              q!die !,
             q!} !,
            q!} else { !,
             q!die !,
            q!} }!),
    'callbacks');

sub myref { ref $_[0] };

sub cat (\[$@]\[$@]) {
 if (ref $_[0] eq 'SCALAR') {
  if (ref $_[1] eq 'SCALAR') {
   return ${$_[0]} . ${$_[1]};
  } elsif (ref $_[1] eq 'ARRAY') {
   return ${$_[0]}, @{$_[1]};
  }
 } elsif (ref $_[0] eq 'ARRAY') {
  if (ref $_[1] eq 'SCALAR') {
   return @{$_[0]}, ${$_[1]};
  } elsif (ref $_[1] eq 'ARRAY') {
   return @{$_[0]}, @{$_[1]};
  }
 }
}

SKIP: {
 skip 'perl 5.8.x is needed to test execution of \[$@] prototypes' => 6
   if "$]" < 5.008;

 my $cat = wrap 'main::cat', ref => 'main::myref',
                             sub => 1,
                             wrong_ref => 'die "hlagh"',
 my @tests = (
  [ \'a',        \'b',        [ 'ab' ],        'scalar-scalar' ],
  [ \'c',        [ qw<d e> ], [ qw<c d e> ],   'scalar-array' ],
  [ [ qw<f g> ], \'h',        [ qw<f g h> ],   'array-scalar' ],
  [ [ qw<i j> ], [ qw<k l> ], [ qw<i j k l> ], 'array-array' ]
 );
 for (@tests) {
  my $res = [ $cat->($_->[0], $_->[1]) ];
  is_deeply($res, $_->[2], 'cat ' . $_->[3]);
 }
 eval { $cat->({ foo => 1 }, [ 2 ] ) };
 like($@, qr/^hlagh\s+at/, 'wrong reference type 1');
 eval { $cat->(\1, sub { 2 } ) };
 like($@, qr/^hlagh\s+at/, 'wrong reference type 2');
}

sub noproto;
my $noproto_exp = '{ main::noproto(@_) }';
my $noproto = wrap 'main::noproto', sub => 0;
is($noproto, $noproto_exp, 'no prototype');

sub myit { my $ar = shift; push @$ar, @_; };
if ("$]" >= 5.010) {
 Scalar::Util::set_prototype(\&myit, '\@$_');
 my $it = wrap 'main::myit';
 my @a = qw<u v w>;
 local $_ = 7;
 $it->(\@a, 3, 4, 5);
 is_deeply(\@a, [ qw<u v w>, 3, 4 ], '_ with arguments');
 $it->(\@a, 6);
 is_deeply(\@a, [ qw<u v w>, 3, 4, 6, 7 ], '_ without arguments');
}

sub myshift (;\@) { shift @{$_[0]} }

eval { wrap { 'main::dummy' => '\[@%]' }, ref => 'main::myshift' };
like $@, qr/to main::myshift must be array \([\w ]+\) at \Q$0\E line \d+/,
                                                     'invalid eval code croaks';
