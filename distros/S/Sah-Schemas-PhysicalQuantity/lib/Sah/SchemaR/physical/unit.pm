package Sah::SchemaR::physical::unit;

our $DATE = '2020-04-04'; # DATE
our $VERSION = '0.002'; # VERSION

our $rschema = ["str",[{description=>"\nAll units recognized by <pm:Physics::Unit> are valid.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,value=>"kg"},{valid=>0,value=>"foo"}],in=>["\$","%","a","abamp","abampere","abamperes","abamps","abcoul","abcoulomb","abcoulombs","abfarad","abfarads","abhenry","abhenrys","abohm","abohms","abvolt","abvolts","acre","acres","amp","ampere","amperes","amps","amu","angstrom","angstroms","arcmin","arcminute","arcminutes","arcsec","arcsecond","arcseconds","are","ares","astronomical-unit","atm","atmosphere","atomic-mass-unit","atomic-mass-units","atto","au","bar","barn","barns","bars","becquerel","billion","billions","billionth","bit","bits","bq","british-thermal-unit","british-thermal-units","britishthermalunit","britishthermalunits","btu","btus","bushel","bushels","byte","bytes","c","cal","calorie","calories","candela","candelas","candle","candles","carat","carats","cc","cd","centi","centuries","century","cg","cl","cm","coul","coulomb","coulombs","cup","cups","cycle","cycles","dag","day","days","deca","deci","deg","degree","degree-kelvin","degree-kelvins","degree-rankine","degrees","degrees-kelvin","degrees-rankine","deka","demi","dg","dl","dollar","dollars","doz","dozen","dram","drams","dyne","dynes","e","earth-gravity","eight","eighteen","eighteens","eighties","eights","eighty","electron-volt","electron-volts","electronvolt","electronvolts","elementary-charge","eleven","elevens","eq","erg","ergs","ev","exa","exbi","f","farad","farads","fathom","fathoms","feet","femto","fifteen","fifteens","fifth","fifths","fifties","fifty","five","fives","floz","fluid-ounce","fluid-ounces","fluidounce","fluidounces","fluidram","fluidrams","foot","foot-pound","foot-pounds","footpound","footpounds","forties","fortnight","fortnights","forty","four","fours","fourteen","fourteens","fourth","fourths","fps","ft","ft-lb","ftlb","furlong","furlongs","g","g0","gal","gallon","gallons","gauss","gev","gibi","giga","gill","gills","gm","grain","grains","gram","gram-force","gram-weight","grams","gravitational-constant","gray","gross","gy","h","half","halves","hectare","hectares","hecto","henry","henrys","hertz","hg","horsepower","hour","hours","hp","hr","hrs","hundred","hundreds","hundredth","hundredweight","hundredweights","hz","in","inch","inches","j","j-point","joule","joules","k","karat","karats","kcal","kelvin","kelvins","kg","kgf","kibi","kilo","kilohm","kilohms","km","knot","knots","kph","kps","kwh","l","lb","lbf","lbm","lbms","lbs","light-year","light-years","lightyear","lightyears","liter","liters","long-ton","long-tons","ly","m","ma","maxwell","maxwells","mebi","mega","megohm","megohms","meter","meters","metre","metres","metric-ton","metric-tons","mev","mg","mh","mho","mhos","mi","micro","micron","microns","mil","mile","miles","millenia","millenium","milli","million","millions","millionth","mils","min","minim","minims","mins","minute","minutes","ml","mm","mol","mole","moles","mon","mons","month","months","mph","mps","ms","msec","msecs","mv","na","nano","nautical-mile","nautical-miles","nauticalmile","nauticalmiles","newton","newtons","nine","nines","nineteen","nineteens","nineties","ninety","nm","nmi","ns","nsec","nsecs","nt","ohm","ohms","one","ones","ounce","ounce-force","ounce-troy","ounces","ounces-troy","oz","ozf","pa","parsec","parsecs","pascal","pebi","peck","pecks","pennyweight","pennyweights","percent","perch","perches","peta","pf","pi","pica","pico","pint","pints","point","pole","poles","pound","pound-force","pound-mass","pound-weight","pounds","pounds-force","pounds-mass","ps","psec","psecs","psi","pt","qt","quadrillion","quadrillions","quadrillionth","quart","quarts","quintillion","quintillions","quintillionth","rad","radian","radians","re","rem","revolution","revolutions","rod","rods","rp","rpm","s","score","scores","scruple","scruples","sec","second","seconds","secs","semi","seven","sevens","seventeen","seventeens","seventies","seventy","short-ton","short-tons","siemens","sievert","six","sixes","sixteen","sixteens","sixties","sixty","slug","slugs","speed-of-light","sr","statamp","statampere","statamperes","statamps","statcoul","statcoulomb","statcoulombs","statfarad","statfarads","stathenry","stathenrys","statohm","statohms","statvolt","statvolts","steradian","steradians","stone","stones","sv","tablespoon","tablespoons","tbsp","teaspoon","teaspoons","tebi","ten","tens","tenth","tera","tesla","teslas","tev","third","thirds","thirteen","thirteens","thirties","thirty","thousand","thousands","thousandth","three","threes","ton","tonne","tonnes","tons","torr","trillion","trillions","trillionth","troy-ounce","troy-ounces","troy-pound","troy-pounds","tsp","twelve","twelves","twenties","twenty","two","twos","u","ua","uf","ug","uh","um","unity","us","us-dollar","us-dollars","usec","usecs","uv","v","volt","volts","w","watt","watts","wb","weber","webers","week","weeks","wk","yard","yards","year","years","yocto","yotta","yr","yrs","zepto","zetta"],summary=>"A physical unit"}],["str"]];

1;
# ABSTRACT: A physical unit

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::physical::unit - A physical unit

=head1 VERSION

This document describes version 0.002 of Sah::SchemaR::physical::unit (from Perl distribution Sah-Schemas-PhysicalQuantity), released on 2020-04-04.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-PhysicalQuantity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-PhysicalQuantity>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-PhysicalQuantity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
