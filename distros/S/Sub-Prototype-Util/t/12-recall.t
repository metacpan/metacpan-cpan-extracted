#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 20 + (("$]" >= 5.010) ? 4 : 0);

use Scalar::Util;
use Sub::Prototype::Util qw<recall>;

sub exception {
 my ($msg) = @_;
 $msg =~ s/\s+/\\s+/g;
 return qr/^$msg.*?at\s+\Q$0\E\s+line\s+\d+/;
}

eval { recall undef };
like $@, exception('No subroutine'), 'recall undef croaks';
eval { recall '' };
like $@, exception('No subroutine'), 'recall "" croaks';
eval { recall \1 };
like $@, exception('Unhandled SCALAR'), 'recall scalarref croaks';
eval { recall [ ] };
like $@, exception('Unhandled ARRAY'), 'recall arrayref croaks';
eval { recall sub { } };
like $@, exception('Unhandled CODE'), 'recall coderef croaks';
eval { recall { 'foo' => undef, 'bar' => undef } };
like $@, qr!exactly\s+one\s+key/value\s+pair!,
                                           'recall hashref with 2 pairs croaks';
eval { recall 'hlagh' };
like $@, qr/^Undefined\s+subroutine/, 'recall <unknown> croaks';
eval { recall 'for' };
like $@, exception('syntax error'), 'invalid eval code croaks';

sub noproto { $_[1], $_[0] }
sub mytrunc ($;$) { $_[1], $_[0] }
sub mygrep1 (&@) { grep { $_[0]->() } @_[1 .. $#_] }
sub mygrep2 (\&@) { grep { $_[0]->() } @_[1 .. $#_] }
sub modify ($) { my $old = $_[0]; $_[0] = 5; $old }

my $t = [ 1, 2, 3, 4 ];
my $m = [ sub { $_ + 10 }, 1 .. 5 ];
my $g = [ sub { $_ > 2 }, 1 .. 5 ];

my @tests = (
 [ 'main::noproto', 'no prototype', $t, $t, [ 2, 1 ] ],
 [ { 'main::noproto' => undef }, 'no prototype forced', $t, $t, [ 2, 1 ] ],
 [ 'CORE::push', 'push', [ [ 1, 2 ], 3, 5 ], [ [ 1, 2, 3, 5 ], 3, 5 ], [ 4 ] ],
 [ { 'CORE::push' => '\@$' }, 'push just one', [ [ 1, 2 ], 3, 5 ], [ [ 1, 2, 3 ], 3, 5 ], [ 3 ] ],
 [ { 'CORE::map' => '\&@' }, 'map', $m, $m, [ 11 .. 15 ] ],
 [ 'main::mytrunc', 'truncate 1', [ 1 ], [ 1 ], [ undef, 1 ] ],
 [ 'main::mytrunc', 'truncate 2', $t, $t, [ 2, 1 ] ],
 [ 'main::mygrep1', 'grep1', $g, $g, [ 3 .. 5 ] ],
 [ 'main::mygrep2', 'grep2', $g, $g, [ 3 .. 5 ] ],
 [ 'main::modify', 'modify arguments', [ 1 ], [ 5 ], [ 1 ] ],
);

sub myit { push @{$_[0]->[2]}, 3; return 4 };
if ("$]" >= 5.010) {
 Scalar::Util::set_prototype(\&myit, '_');
 push @tests, [ 'main::myit', '_ with argument',
                [ [ 1, 2, [ ] ], 5 ],
                [ [ 1, 2, [ 3 ] ], 5 ],
                [ 4 ]
              ];
 push @tests, [ 'main::myit', '_ with no argument', [ ], [ 3 ], [ 4 ] ];
}

for (@tests) {
 my $r = [ recall $_->[0], @{$_->[2]} ];
 is_deeply($r, $_->[4], $_->[1] . ' return value');
 is_deeply($_->[2], $_->[3], $_->[1] . ' arguments modification');
}
