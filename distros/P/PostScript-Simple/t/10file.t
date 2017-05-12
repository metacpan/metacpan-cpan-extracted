#!/usr/bin/perl -w

use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 6;
#use Data::Dumper;
use PostScript::Simple;

my $f = 'xtest-a.ps';
my $s = new PostScript::Simple(xsize => 50, ysize => 200);

$s->box(10, 10, 40, 190);
$s->output( $f );

#print STDERR Dumper $s;

# check object
ok( $s->{psresources}{REENCODEFONT} =~ m|/START| );
ok( index( $s->_buildpage($s->{pspages}[0]),
           q[10 ubp 10 ubp 40 ubp 190 ubp box stroke]) > -1 );

# check output
ok( -e $f );
open( CHK, $f ) or die("Can't open the file $f: $!");
$/ = undef;
my $file = <CHK>;
close CHK;

ok( index( $file, '%!PS-Adobe-3.0 EPSF-1.2' ) == 0 );
ok( index( $file, '%%EOF' ) == (length( $file ) - 6) );
ok( index( $file, '10 ubp 10 ubp 40 ubp 190 ubp box stroke' ) > 0 );
