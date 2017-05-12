#!/usr/bin/perl

use strict;
use warnings;
use Perl::Version;
use Test::More tests => 44;

package dummy;
sub new { return bless {}, shift }

package main;

my $v1 = Perl::Version->new();
isa_ok $v1, 'Perl::Version';

my $warned;
local $SIG{__WARN__} = sub { $warned = shift };

my %expect = (
  stringify  => 'v0.0.0',
  numify     => '0.000',
  components => '1',
  alpha      => 0,
  normal     => 'v0.0.0',
  revision   => 0,
  version    => undef,
  subversion => undef,
  is_alpha   => '',
);

while ( my ( $meth, $expect ) = each %expect ) {
  $warned = undef;
  my $result = eval { $v1->$meth };
  unless ( ok !$@, "$meth: no error" ) {
    diag( "Error was $@" );
  }
  unless ( ok !$warned, "$meth: no warning" ) {
    diag( "Warning was $@" );
  }
  is $result, $expect, "$meth: result OK";
}

my $v2 = Perl::Version->new( '5.8.8' );
is "$v2", '5.8.8', 'stringify overload OK';
my $v3 = $v2->new();
is "$v3", 'v0.0.0', 'new as method yields empty object';
my $v4 = $v3->new( $v2 );
is "$v4", '5.8.8', 'copy OK';

ok $v2 < 'v5.8.9', 'compare with string';
ok $v2 == 'v5.8.8', 'compare with string';
ok $v2 > 'v5.8.7', 'compare with string';
ok 'v5.8.9' > $v2, 'compare with string';
ok 'v5.8.8' == $v2, 'compare with string';
ok 'v5.8.7' < $v2, 'compare with string';

my $ar = [ 1, 2, 3 ];
$v3->components( $ar );
is "$v3", 'v1.2.3', 'set components from array';
$ar->[1]++;
is "$v3", 'v1.2.3', 'array copied rather than referenced';

eval { Perl::Version::new() };
like $@, qr/called.+method/, 'calling new as a function fails';

my $dummy = dummy->new;
eval { my $x = $v1 <=> $dummy };
like $@, qr/compare with/, 'compare to random object fails';

eval { my $x = $v1 <=> [] };
like $@, qr/compare with/, 'compare to hash ref fails';

eval { $v4->component };
like $@, qr/component number/, 'need component number';

eval { $v2->increment( 3 ) };
like $@, qr/out of range/, 'out of range';
