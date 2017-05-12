use Perl6::Form;

$ID = 10565263827;
$retail = 173.87;
$disc = $retail * .95;
$tax = $retail * .12;

$desc = "3.5 in. closed length. Translucent ruby handle. Features, large & small blades, corkscrew, can opener with small screwdriver, bottle opener with large screwdriver, Perl interpreter, wire stripper, reamer, key ring, tweezers, toothpick, plus 12 other features.";

sub starbright {
    my ($match,$opts) = @_;
    $opts->{fill}='*';
	(my $whole = $match->[1]) =~ tr/*/>>/;
	 my $point = $match->[2];
	(my $fract = $match->[3]) =~ tr/*/<</;
    return "{$whole$point$fract}";
}

my $starlight = qr/ [{] ([*]+) ([.,]) ([*]+) [}] /x;

sub starfield() {
	return { field => [$starlight => \&starbright] };
}

print form starfield, {interleave=>1}, <<'.',
=================[ Quote for item: {>>>>>>>>>>>>>>>>} ]=================

      Retail: {******.*}        Desc: {<<<<<<<<<<<<>>>>>>>>>>>>>}
  Discounted: {******.*}              {VVVVVVVVVVVVVVVVVVVVVVVVV}
         Tax: {******.*}              {VVVVVVVVVVVVVVVVVVVVVVVVV}
                                      {VVVVVVVVVVVVVVVVVVVVVVVVV}
  {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
.
      $ID, $retail, $desc, $disc, $tax;
