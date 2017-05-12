use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "abcd" =~ m/a  $?foo:=(..)  d/, 'Hypothetical variable capture' );
ok( $0->{foo} eq "bc", 'Hypothetical variable captured' );

ok( "abcd" =~ m/a  $::foo:=(..)  d/, 'Package variable capture' );
ok( $foo eq "bc", 'Package variable captured' );

ok( "abcd" =~ m/a  $2:=(.) $1:=(.) d/, "Reverse capture" ); 
ok( $1 eq "c", '$1 captured' );
ok( $2 eq "b", '$2 captured' );

rule two {..}

ok( "abcd" =~ m/a  $?foo:=(<?two>)  d/, 'Compound hypothetical capture' );
ok( $0->{two} eq "bc", 'Implicit hypothetical variable captured' );
ok( $0->{foo} eq "bc", 'Explicit hypothetical variable captured' );

ok( "abcd" =~ m/a  $::foo:=(<?two>)  d/, 'Mixed capture' );
ok( $0->{two} eq "bc", 'Implicit hypothetical variable captured' );
ok( $foo eq "bc", 'Explicit package variable captured' );

ok( "a cat_O_9_tails" =~ m:w/<?alpha> <?ident>/, 'Standard captures' );
ok( $0->{alpha} eq "a", 'Captured <alpha>' );
ok( $0->{ident} eq "cat_O_9_tails", 'Captured <ident>' );

ok( "Jon Lee" =~ m:w/$?first:=(<?ident>) $?family:=(<?ident>)/,
    'Repeated standard captures' );
ok( $0->{first}  eq "Jon", 'Captured $first' );
ok( $0->{family} eq "Lee", 'Captured $family' );
ok( $0->{ident}  eq "Lee", 'Captured <ident>' );

ok( "foo => 22" =~ m:w/$1:=(foo) =\> (\d+) | $2:=(\d+) \<= $1:=(foo) /,
    "Pair match"
  );
ok( $1 eq 'foo', "Key match" );
ok( $2 eq '22', "Value match" );

ok( "22 <= foo" =~ m:w/$1:=(foo) =\> (\d+) | $2:=(\d+) \<= $1:=(foo) /,
    "Pair match"
  );
ok( $1 eq 'foo', "Reverse key match" );
ok( $2 eq '22', "Reverse value match" );
