use Perl6::Form;

$ID = 10565263827;
$retail = 173.87;
$disc = $retail * .95;
$tax = 12.6125;

$desc = "3.5 in. closed length. Translucent ruby handle. Features, large & small blades, corkscrew, can opener with small screwdriver, bottle opener with large screwdriver, Perl interpreter, wire stripper, reamer, key ring, tweezers, toothpick, plus 12 other features.";

print form {fill=>'*', interleave=>1}, <<'.',
=================[ Quote for item: {<<<<<<<<<<} ]=================

      Retail: {$>>>>>.<}        Desc: {<<<<<<<<<<<<<<<<<<<<<<<<<}
  Discounted: {$>>>>>.<}              {VVVVVVVVVVVVVVVVVVVVVVVVV}
         Tax: {>>>>.<<%}              {VVVVVVVVVVVVVVVVVVVVVVVVV}
                                      {VVVVVVVVVVVVVVVVVVVVVVVVV}
.
      {fill=>' '}, $ID,
	  $retail,
	  {fill=>' '}, $desc,
	  $disc,
	  $tax;
