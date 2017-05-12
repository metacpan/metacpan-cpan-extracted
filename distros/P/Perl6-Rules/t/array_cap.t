use Perl6::Rules;;
use Test::Simple 'no_plan';

ok( "  a b\tc" =~ m/@?chars:=( \s+ \S+ )+/, 'Named simple array capture' );
ok( join("|",@{$0->{'@?chars'}}) eq "  a| b|\tc", "Captured strings" );

ok( "  a b\tc" =~ m/@?first:=( \s+ \S+ )+ @?last:=( \s+ \S+)+/, 'Sequential simple array capture' );
ok( join("|",@{$0->{'@?first'}}) eq "  a| b", "First captured strings" );
ok( join("|",@{$0->{'@?last'}}) eq "\tc", "Last captured strings" );

ok( "abcxyd" =~ m/a  @?foo:=[.(.)]+ d/, 'Repeated hypothetical array capture' );
ok( "@{$0->{'@?foo'}}" eq "c y", 'Hypothetical variable captured' );
ok( keys %$0 == 1, "No extra captures" );

ok( "abcd" =~ m/a  @?foo:=[.(.)]  d/, 'Hypothetical array capture' );
ok( "@{$0->{'@?foo'}}" eq "c", 'Hypothetical variable captured' );

ok( "abcxyd" =~ m/a  @::ARGV:=[.(.)]+  d/, 'Global array capture' );
ok( "@::ARGV" eq "c y", 'Global array captured' );
ok( keys %$0 == 0, "No vestigal captures" );

ok( "abcxyd" =~ m/a  @::foo:=[.(.)]+  d/, 'Package array capture' );
ok( "@::foo" eq "c y", 'Package array captured' );

rule two {..}

ok( "abcd" =~ m/a  @?foo:=[<?two>]  d/, 'Compound hypothetical capture' );
ok( $0->{two} eq "bc", 'Implicit hypothetical variable captured' );
ok( ! @{$0->{'@?foo'}}, 'Explicit hypothetical variable not captured' );

ok( "  a b\tc" =~ m/@?chars:=[ @?spaces:=[(\s+)] (\S+)]+/, 'Nested array capture' );
ok( "@{$0->{'@?chars'}}" eq "a b c", "Outer array capture" );
ok( join("|",@{$0->{'@?spaces'}}) eq "  | |\t", "Inner array capture" );

rule spaces { @?spaces:=[(\s+)] }

ok( "  a b\tc" =~ m/@?chars:=[ <?spaces> (\S+)]+/, 'Subrule array capture' );

ok( "@{$0->{'@?chars'}}" eq "a b c", "Outer rule array capture" );
ok( $0->{spaces} eq "\t", "Final subrule array capture" );

ok( "  a b\tc" =~ m/@?chars:=[ @?spaces:=[(<spaces>)] (\S+)]+/, 'Nested subrule array capture' );
ok( "@{$0->{'@?chars'}}" eq "a b c", "Outer rule nested array capture" );
ok( join("|",@{$0->{'@?spaces'}}) eq "  | |\t", "Subrule array capture" );


ok( "  a b\tc" =~ m/@?chars:=[ (<spaces>) (\S+)]+/, 'Nested multiple array capture' );
ok( ref $0->{'@?chars'} eq "ARRAY", "Multiple capture to nested array" );
ok( @{$0->{'@?chars'}} == 3, "Multiple capture count" );
ok( ref $0->{'@?chars'}[0] eq "ARRAY", "Multiple capture to nested AoA[0]" );
ok( ref $0->{'@?chars'}[1] eq "ARRAY", "Multiple capture to nested AoA[2]" );
ok( ref $0->{'@?chars'}[2] eq "ARRAY", "Multiple capture to nested AoA[3]" );
ok( $0->{'@?chars'}[0][0] eq "  ", "Multiple capture value of nested AoA[0][0]" );
ok( $0->{'@?chars'}[0][1] eq "a", "Multiple capture value of nested AoA[0][1]" );
ok( $0->{'@?chars'}[1][0] eq " ", "Multiple capture value of nested AoA[1][0]" );
ok( $0->{'@?chars'}[1][1] eq "b", "Multiple capture value of nested AoA[1][1]" );
ok( $0->{'@?chars'}[2][0] eq "\t", "Multiple capture value of nested AoA[2][0]" );
ok( $0->{'@?chars'}[2][1] eq "c", "Multiple capture value of nested AoA[2][1]" );


ok( "GATTACA" =~ m/ @::bases:=(A|C|G|T)+ /, "All your bases..." );
ok( "@::bases" eq "G A T T A C A", "...are belong to us" );

@::bases = ();
ok( "GATTACA" =~ m/ @::bases:=(A|C|G|T)<4> (@::bases+) /, "Array reinterpolation" );
ok( "@::bases" eq "G A T T", "...are belong to..." );
ok( "$1" eq "A", "...A" );

