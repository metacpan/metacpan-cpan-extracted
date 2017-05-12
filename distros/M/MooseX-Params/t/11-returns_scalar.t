use strict;
use warnings;

use Test::Most;
use MooseX::Params;

sub foo_default  :Returns(Array)                         { qw(foo bar baz) }
sub foo_first    :Returns(Array) ReturnsScalar(First)    { qw(foo bar baz) }
sub foo_last     :Returns(Array) ReturnsScalar(Last)     { qw(foo bar baz) }
sub foo_arrayref :Returns(Array) ReturnsScalar(ArrayRef) { qw(foo bar baz) }
sub foo_count    :Returns(Array) ReturnsScalar(Count)    { qw(foo bar baz) }

my @res_default  = foo_default();
my @res_first    = foo_first();
my @res_last     = foo_last();
my @res_arrayref = foo_arrayref();
my @res_count    = foo_count();

my $res_default  = foo_default();
my $res_first    = foo_first();
my $res_last     = foo_last();
my $res_arrayref = foo_arrayref();
my $res_count    = foo_count();


my $foo_bar_baz = [qw(foo bar baz)];

is_deeply \@res_default,  $foo_bar_baz, 'default in list context';
is_deeply \@res_first,    $foo_bar_baz, 'first in list context';
is_deeply \@res_last,     $foo_bar_baz, 'last in list context';
is_deeply \@res_arrayref, $foo_bar_baz, 'arrayref in list context';
is_deeply \@res_count,    $foo_bar_baz, 'count in list context';

is        $res_default,   3,            'default in scalar context';
is        $res_first,     'foo',        'first in scalar context';
is        $res_last,      'baz',        'last in scalar context';
is_deeply $res_arrayref,  $foo_bar_baz, 'arrayref in scalar context';
is        $res_count,     3,            'count in scalar context';

done_testing;
