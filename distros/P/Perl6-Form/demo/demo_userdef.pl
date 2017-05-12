use Perl6::Form;

$ID = 10565263827;
$retail = 173.87;
$disc = $retail * .95;
$tax = $retail * .12;

$desc = "3.5 in. closed length. Translucent ruby handle. Features, large & small blades, corkscrew, can opener with small screwdriver, bottle opener with large screwdriver, Perl interpreter, wire stripper, reamer, key ring, tweezers, toothpick, plus 12 other features.";

sub stars {
    my ($match,$opts) = @_;
    $opts->{fill}='*';
    return '{*>>{'.length($match).'}>.<}';
}

print form
	{field=>[qr/(\*+)/=>\&stars], interleave=>1},
    <<'.',
=================[ Quote for item: {>>>>>>>>>>>>>>>>} ]=================

      Retail: **********        Desc: {:<<<<<<<<<<<<<<<<<<<<<<<<}
  Discounted: **********              {:<<<<<<<<<<<<<<<<<<<<<<<<}
         Tax: **********              {:<<<<<<<<<<<<<<<<<<<<<<<<}
                                      {:[[[[[[[[[[[[[[[[[[[[[[[[}
.
      $ID, $retail, $desc, $disc, $desc, $tax, $desc, $desc;
