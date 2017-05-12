use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "  a b\tc" =~ m/%?chars:=( \s+ \S+ )/, 'Named unrepeated hash capture' );
ok( exists $0->{'%?chars'}{'  a'}, "One key captured" );
ok( !defined $0->{'%?chars'}{'  a'}, "One value undefined" );
ok( keys %{$0->{'%?chars'}} == 1, "No extra unrepeated captures" );

ok( "  a b\tc" =~ m/%?chars:=( \s+ \S+ )+/, 'Named simple hash capture' );
ok( exists $0->{'%?chars'}{'  a'}, "First simple key captured" );
ok( !defined $0->{'%?chars'}{'  a'}, "First simple value undefined" );
ok( exists $0->{'%?chars'}{' b'}, "Second simple key captured" );
ok( !defined $0->{'%?chars'}{' b'}, "Second simple value undefined" );
ok( exists $0->{'%?chars'}{"\tc"}, "Third simple key captured" );
ok( !defined $0->{'%?chars'}{"\tc"}, "Third simple value undefined" );
ok( keys %{$0->{'%?chars'}} == 3, "No extra simple captures" );

ok( "  a b\tc" =~ m/%?first:=( \s+ \S+ )+ %?last:=( \s+ \S+)+/, 'Sequential simple hash capture' );
ok( exists $0->{'%?first'}{'  a'}, "First sequential key captured" );
ok( !defined $0->{'%?first'}{'  a'}, "First sequential value undefined" );
ok( exists $0->{'%?first'}{' b'}, "Second sequential key captured" );
ok( !defined $0->{'%?first'}{' b'}, "Second sequential value undefined" );
ok( exists $0->{'%?last'}{"\tc"}, "Third sequential key captured" );
ok( !defined $0->{'%?last'}{"\tc"}, "Third sequential value undefined" );
ok( keys %{$0->{'%?first'}} == 2, "No extra first sequential captures" );
ok( keys %{$0->{'%?last'}} == 1, "No extra last sequential captures" );

ok( "abcxyd" =~ m/a  %?foo:=[.(.)]+ d/, 'Repeated nested hash capture' );
ok( exists $0->{'%?foo'}{c}, 'Nested key 1 captured' );
ok( !defined $0->{'%?foo'}{c}, 'No nested value 1 captured' );
ok( exists $0->{'%?foo'}{y}, 'Nested key 2 captured' );
ok( !defined $0->{'%?foo'}{y}, 'No nested value 2 captured' );
ok( keys %{$0->{'%?foo'}} == 2, "No extra nested captures" );

ok( "abcd" =~ m/a  %?foo:=[.(.)]  d/, 'Unrepeated nested hash capture' );
ok( exists $0->{'%?foo'}{c}, 'Unrepeated key captured' );
ok( !defined $0->{'%?foo'}{c}, 'Unrepeated value not captured' );
ok( keys %{$0->{'%?foo'}} == 1, "No extra unrepeated nested captures" );

ok( "abcd" =~ m/a  %?foo:=[(.)(.)]  d/, 'Unrepeated nested hash multicapture' );
ok( exists $0->{'%?foo'}{b}, 'Unrepeated key multicaptured' );
ok( $0->{'%?foo'}{b} eq c, 'Unrepeated value not multicaptured' );
ok( keys %{$0->{'%?foo'}} == 1, "No extra unrepeated nested multicaptures" );

ok( "abcxyd" =~ m/a  %?foo:=[(.)(.)]+ d/, 'Repeated nested hash multicapture' );
ok( exists $0->{'%?foo'}{b}, 'Nested key 1 multicaptured' );
ok( $0->{'%?foo'}{b} eq 'c', 'Nested value 1 multicaptured' );
ok( exists $0->{'%?foo'}{x}, 'Nested key 2 multicaptured' );
ok( $0->{'%?foo'}{x} eq 'y', 'Nested value 2 multicaptured' );
ok( keys %{$0->{'%?foo'}} == 2, "No extra nested multicaptures" );

ok( "abcxyd" =~ m/a  %::foo:=[.(.)]+  d/, 'Package hash capture' );
ok( exists $foo{c}, 'Package hash key 1 captured' );
ok( !defined $foo{c}, 'Package hash value 1 not captured' );
ok( exists $foo{y}, 'Package hash key 2 captured' );
ok( !defined $foo{y}, 'Package hash value 2 not captured' );
ok( keys %foo == 2, "No extra package hash captures" );

rule two {..}

ok( "abcd" =~ m/a  %?foo:=[<?two>]  d/, 'Compound hash capture' );
ok( $0->{two} eq "bc", 'Implicit subrule variable captured' );
ok( keys %{$0->{'%?foo'}} == 0, 'Explicit hash variable not captured' );

ok( "  a b\tc" =~ m/%?chars:=[ %?spaces:=[(\s+)] (\S+)]+/, 'Nested multihash capture' );
ok( exists $0->{'%?chars'}{a}, "Outer hash capture key 1" );
ok( !defined $0->{'%?chars'}{a}, "Outer hash no capture value 1" );
ok( exists $0->{'%?chars'}{b}, "Outer hash capture key 2" );
ok( !defined $0->{'%?chars'}{b}, "Outer hash no capture value 2" );
ok( exists $0->{'%?chars'}{c}, "Outer hash capture key 3" );
ok( !defined $0->{'%?chars'}{c}, "Outer hash no capture value 3" );
ok( keys %{$0->{'%?chars'}} == 3, 'Outer hash no extra captures' );

ok( exists $0->{'%?spaces'}{'  '}, "Inner hash capture key 1" );
ok( !defined $0->{'%?spaces'}{'  '}, "Inner hash no capture value 1" );
ok( exists $0->{'%?spaces'}{' '}, "Inner hash capture key 2" );
ok( !defined $0->{'%?spaces'}{' '}, "Inner hash no capture value 2" );
ok( exists $0->{'%?spaces'}{"\t"}, "Inner hash capture key 3" );
ok( !defined $0->{'%?spaces'}{"\t"}, "Inner hash no capture value 3" );
ok( keys %{$0->{'%?spaces'}} == 3, 'Inner hash no extra captures' );

rule spaces { @?spaces:=[(\s+)] }

ok( "  a b\tc" =~ m/%?chars:=[ <?spaces> (\S+)]+/, 'Subrule hash capture' );

ok( exists $0->{'%?chars'}{a}, "Outer subrule hash capture key 1" );
ok( !defined $0->{'%?chars'}{a}, "Outer subrule hash no capture value 1" );
ok( exists $0->{'%?chars'}{b}, "Outer subrule hash capture key 2" );
ok( !defined $0->{'%?chars'}{b}, "Outer subrule hash no capture value 2" );
ok( exists $0->{'%?chars'}{c}, "Outer subrule hash capture key 3" );
ok( !defined $0->{'%?chars'}{c}, "Outer subrule hash no capture value 3" );
ok( keys %{$0->{'%?chars'}} == 3, 'Outer subrule hash no extra captures' );
ok( $0->{spaces} eq "\t", "Final subrule hash capture" );


ok( "  a b\tc" =~ m/%?chars:=[ %?spaces:=[(<spaces>)] (\S+)]+/, 'Nested subrule hash multicapture' );
ok( exists $0->{'%?chars'}{a}, "Outer rule nested hash key multicapture" );
ok( !defined $0->{'%?chars'}{a}, "Outer rule nested hash value multicapture" );
ok( exists $0->{'%?chars'}{b}, "Outer rule nested hash key multicapture" );
ok( !defined $0->{'%?chars'}{b}, "Outer rule nested hash value multicapture" );
ok( exists $0->{'%?chars'}{c}, "Outer rule nested hash key multicapture" );
ok( !defined $0->{'%?chars'}{c}, "Outer rule nested hash value multicapture" );
ok( keys %{$0->{'%?chars'}} == 3, 'Outer subrule hash no extra multicaptures' );

ok( exists $0->{'%?spaces'}{'  '}, "Inner rule nested hash key multicapture" );
ok( !defined $0->{'%?spaces'}{'  '}, "Inner rule nested hash value multicapture" );
ok( exists $0->{'%?spaces'}{' '}, "Inner rule nested hash key multicapture" );
ok( !defined $0->{'%?spaces'}{' '}, "Inner rule nested hash value multicapture" );
ok( exists $0->{'%?spaces'}{"\t"}, "Inner rule nested hash key multicapture" );
ok( !defined $0->{'%?spaces'}{"\t"}, "Inner rule nested hash value multicapture" );
ok( keys %{$0->{'%?spaces'}} == 3, 'Inner subrule hash no extra multicaptures' );

ok( "  a b\tc" =~ m/%?chars:=[ (<spaces>) (\S+)]+/, 'Nested multiple hash capture' );
ok( $0->{'%?chars'}{'  '} eq 'a', "Outer rule nested hash value multicapture" );
ok( $0->{'%?chars'}{' '} eq 'b', "Outer rule nested hash value multicapture" );
ok( $0->{'%?chars'}{"\t"} eq 'c', "Outer rule nested hash value multicapture" );
ok( keys %{$0->{'%?chars'}} == 3, 'Outer subrule hash no extra multicaptures' );

ok( "Gattaca" =~ m:i/ %::bases:=(A|C|G|T)+ /, "All your bases..." );
ok( exists $bases{a}, "a key" );
ok( !defined $bases{a}, "No a value" );
ok( exists $bases{c}, "c key" );
ok( !defined $bases{c}, "No c value" );
ok( !exists $bases{g}, "No g key" );
ok( exists $bases{G}, "G key" );
ok( !defined $bases{G}, "No G value" );
ok( exists $bases{t}, "t key" );
ok( !defined $bases{t}, "No t value" );
ok( keys %bases == 4, "No other bases" );

%::bases = ();
%::aca = ('aca' => 1);;
ok( "Gattaca" =~ m:i/ %::bases:=(A|C|G|T)<4> (%::aca) /, "Hash interpolation" );
ok( exists $bases{a}, "a key" );
ok( !defined $bases{a}, "No a value" );
ok( !exists $bases{c}, "No c key" );
ok( !exists $bases{g}, "No g key" );
ok( exists $bases{G}, "G key" );
ok( !defined $bases{G}, "No G value" );
ok( exists $bases{t}, "t key" );
ok( !defined $bases{t}, "No t value" );
ok( keys %bases == 3, "No other bases" );
ok( "$1" eq "aca", "Trailing aca" );

