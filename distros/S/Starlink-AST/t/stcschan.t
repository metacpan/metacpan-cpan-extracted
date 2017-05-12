#!perl

# Stcs Channel

use strict;
use Test::More;

BEGIN {
 use Starlink::AST;
 if ( Starlink::AST::Version() < 5002000 ) {
   plan skip_all => "Not supported. Please upgrade to AST Version > 5.2";
   exit;
 } else {
   plan tests => 13;
 }
};


# Implement astShow
my $obj = new Starlink::AST::UnitMap( 1, "" );

my $ch = new Starlink::AST::StcsChan ( sink => sub {print "# $_[0]\n" } );
isa_ok($ch, 'Starlink::AST::StcsChan');
isa_ok($ch, 'Starlink::AST::Channel');


$ch->Write( $obj );
ok(1, "Write complete");

# Try again, but storing to an array
my @cards;
{
$ch = new Starlink::AST::StcsChan ( sink => sub {push(@cards, $_[0]) } );
$ch->Write( $obj );
}

for (@cards) {
  print "# $_\n";
}
ok(1, "Write to internal array complete");


# This test taken from pyast

my @buffin = (
  "StartTime 1900-01-01 Circle ICRS 148.9 69.1 2.0",
  "SpeCtralInterval 4000 7000 unit Angstrom" );
my @buffout;

my $buffch = new Starlink::AST::StcsChan(
  sink => sub {push @buffout, shift},
  source => sub {return shift @buffin} );

my $readobj = $buffch->Read();

isa_ok($readobj, 'Starlink::AST::Prism');
cmp_ok($readobj->Get('Naxes'), '==', 4);

my ($lbnd, $ubnd) = $readobj->GetRegionBounds();
cmp_ok($ubnd->[0], '>',  1000000000 ); # shoudl be == max float
ok(nearly_equal($lbnd->[1], 2.50080939227851), 'lbnd[1]');
ok(nearly_equal($ubnd->[1], 2.6967811201606), 'ubnd[1]');
ok(nearly_equal($lbnd->[2], 1.171115928088195), 'lbnd[2]');
ok(nearly_equal($ubnd->[2], 1.24091013301998), 'ubnd[2]');
is($lbnd->[3], 4000.0);
is($ubnd->[3], 7000.0);

sub nearly_equal {
  my ($a, $b) = @_;
  return ($a - $b) < 0.0000000001;
}
