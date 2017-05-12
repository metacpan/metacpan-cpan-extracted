#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Trap;
use Test::Differences;

delete @ENV{qw{PATH ENV IFS CDPATH BASH_ENV}};

my $d = 't/basic-dummy';
our $trap;

use_ok( 'Run::Parts' );

my @rc = trap { die "foo" };
$trap->did_die('Expecting foo to die' );
is ( $trap->stdout, '', 'Expecting no STDOUT' );
$trap->die_like(qr/foo/, "Argues about foo");

my $rp = Run::Parts->new($d);
my @r = trap { $rp->lines("foo\n", "bar\n"); };
$trap->did_die('Expecting lines to die' );
is ( $trap->stdout, '', 'Expecting no STDOUT' );
$trap->die_like(qr/lines is no method/,
       "Warn's about lines not being a method");

@r = trap { $rp->chomped_lines("foo\n", "bar\n"); };
$trap->did_die('Expecting chomped_lines to die' );
is ( $trap->stdout, '', 'Expecting no STDOUT' );
$trap->die_like(qr/chomped_lines is no method/,
       "Warn's about chomped_lines not being a method");

done_testing();
