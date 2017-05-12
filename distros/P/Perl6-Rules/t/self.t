use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "A(B(CCCC))D" =~ m/ [ \w+ | \( <self> \) ]+ /, "<self> match" );
ok( $0 eq "A(B(CCCC))D", "Matched fully" );

ok( "A(B(CCCC)D"  =~ m/ [ \w+ | \( <self> \) ]+ /, "<self> non-match" );
ok( $0 eq "A", "Matched short" );

ok( "A(B(CCCC)(D))E" =~ m/ [ \w+ | \( <self>+ \) ]+ /, "<self> repeated match" );
ok( $0 eq "A(B(CCCC)(D))E", "Matched repeatedly" );

ok( "A(B(CCCC))D" =~ m/ [ \w+ | \( <?self> \) ]+ /, "<self> capture" );
ok( $0 eq "A(B(CCCC))D", "Matched capturefully" );
ok( $0->{self} eq "B(CCCC)", "Level 1 capture" );
ok( $0->{self}{self} eq "CCCC", "Level 2 capture" );

ok( "A(B(CCCC)(DD))(EE)F" =~ m/ [ \w+ | \( <?self>+ \) ]+ /, "<self> repeated capture" );

ok( $0 eq "A(B(CCCC)(DD))(EE)F", "Matched repeatly capturefully" );
ok( $0->{self}[0] eq "EE", "Repeated capture" );
