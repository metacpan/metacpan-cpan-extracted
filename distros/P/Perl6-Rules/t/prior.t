use Perl6::Rules;
use Test::Simple 'no_plan';

ok( !eval { "A" =~ m/<prior>/ }, "No prior successful match" );
ok( $@ eq "No successful <prior> rule\n", "Correct error message" );

ok( "A" =~ m/<[A-Z]>/, "Successful match" );

ok( "B" =~ m/<prior>/, "Prior successful match" );
ok( "!" !~ m/<prior>/, "Prior successful non-match" );

ok( "A" !~ m/B/, "Unsuccessful match" );

ok( "B" =~ m/<prior>/, "Still prior successful match" );
ok( "B" =~ m/<prior>/, "And still prior successful match" );

ok( "AB" =~ m/A <prior>/, "Nested prior successful match" );
ok( "A" !~ m/A <prior>/, "Nested prior successful non-match" );
ok( "B" =~ m/<prior>/, "And even now prior successful match" );

ok( "!" =~ m/<-[A-Z]>/, "New successful match" );

ok( "B" !~ m/<prior>/, "New prior successful non-match" );
ok( "!" =~ m/<prior>/, "New prior successful match" );

ok( "A" !~ m/B/, "New unsuccessful match" );

ok( "%" =~ m/<prior>/, "New still prior successful match" );
ok( "@" =~ m/<prior>/, "New and still prior successful match" );

ok( "A!" =~ m/A <prior>/, "New nested prior successful match" );
ok( "A" !~ m/A <prior>/, "New nested prior successful non-match" );
ok( "^" =~ m/<prior>/, "New and even now prior successful match" );


ok( "A" =~ m/<[A-Z]>/, "Another successful match" );
ok( "AA" =~ m/^ <prior>+ $/, "Repeated prior" );
ok( $0 eq "AA", "Matched fully" );

ok( "A" =~ m/^ <?prior> $/, "Captured prior" );
ok( $0->{prior} eq "A", "Captured correctly" );

ok( "AAAA" =~ m/^ <?prior>+ $/, "Repeatedly captured prior" );
ok( $0->{prior}[0] eq 'A', "Capture 0" );
ok( $0->{prior}[1] eq 'A', "Capture 1" );
ok( $0->{prior}[2] eq 'A', "Capture 2" );
ok( $0->{prior}[3] eq 'A', "Capture 3" );
ok( ! defined $0->{prior}[4], "Capture 4" );
