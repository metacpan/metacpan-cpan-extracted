#!/usr/bin/perl
use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 26;
use PostScript::Simple;

# test for units

my $s = new PostScript::Simple();
my $t = new PostScript::Simple(units => "in", direction => "LeftUp");
my $u = new PostScript::Simple(units => "in", direction => "RightDown");

ok( $s );
ok( $t );

ok( ! keys(%{$s->{usedunits}}) );

ok( $s->_u("4") eq "4 ubp " );
ok( $t->_u("4") eq "4 uin " );

ok( keys(%{$s->{usedunits}}) );

ok( $s->_u("4 bp") eq "4 ubp " );
ok( $s->_u("4.5 in") eq "4.5 uin " );

ok( $s->{usedunits}{bp} eq "/ubp {} def" );
ok( $s->{usedunits}{in} eq "/uin {72 mul} def" );
ok( ! defined($t->{usedunits}{bp}) );
ok( $t->{usedunits}{in} eq "/uin {72 mul} def" );

ok( $s->_u([9.9, "pt"]) eq "9.9 upt ");


# check invalid args

eval { $s->_u([2]) };
ok( $@ );

eval { $s->_u([2, 5]) };
ok( $@ );

eval { $s->_u([2.78, "mm", 6]) };
ok( $@ );

eval { $s->_u("mm") };
ok( $@ );

eval { $s->_u("6 6") };
ok( $@ );

ok( $s->_ux("5 pc") eq "5 upc " );
ok( $t->_ux("5 pc") eq "-5 upc " );
ok( $t->_uy("5 pc") eq "5 upc " );

ok( $u->_uxy("5.394857 pc", "0.0010") eq "5.394857 upc -0.001 uin " );
ok( $u->_uxy([1010105.394857, "dd"], "0.0010") eq "1010105.394857 udd -0.001 uin " );

ok( keys(%{$s->{usedunits}}) == 4 );
ok( keys(%{$t->{usedunits}}) == 2 );
ok( keys(%{$u->{usedunits}}) == 3 );


