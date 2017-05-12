use Perl6::Rules;
use Test::Simple 'no_plan';

# BUG: Captures in subrules that are captured cause
#      memory faults under 5.8.3
#      This problem has been reported.
#
# rule dotdot { (.)(.) };

rule dotdot { .. };

ok("zzzabcdefzzz" =~ m/(a.)<dotdot>(..)/, "Match");
ok($0, "Matched");
ok($0 eq "abcdef", "Captured");
ok($0->[0] eq 'abcdef', '$0->[0]');
ok($0->[1] eq 'ab', '$0->[1]');
ok($1 eq 'ab', '$1');
ok($0->[2] eq 'ef', '$0->[2]');
ok($2 eq 'ef', '$2');
ok(!defined($0->[3]), 'no $0->[3]');
ok(!defined($3), 'no $3');
ok(!defined($0->{dotdot}), 'no $0->{dotdot}');

ok("zzzabcdefzzz" =~ m/(a.)<?dotdot>(..)/, "Match");
ok($0, "Matched");
ok($0 eq "abcdef", "Captured");
ok($0->[0] eq 'abcdef', '$0->[0]');
ok($0->[1] eq 'ab', '$0->[1]');
ok($1 eq 'ab', '$1');
ok($0->[2] eq 'ef', '$0->[2]');
ok($2 eq 'ef', '$2');
ok(!defined($0->[3]), '$0->[3]');
ok(!defined($3), '$3');
ok($0->{dotdot} eq 'cd', '$0->{dotdot}');
ok($0->{dotdot}[0] eq 'cd', '$0->{dotdot}[0]');

# BUG: See above.
# ok($0->{dotdot}[1] eq 'c', '$0->{dotdot}[1]');
# ok($0->{dotdot}[2] eq 'd', '$0->{dotdot}[2]');

ok(!defined($0->{dotdot}[3]), '$0->{dotdot}[3]');

ok( "abcd" =~ m/(a(b(c))(d))/, "Nested captured" );
ok( $1 eq "abcd", 'Nested $1' );
ok( $2 eq "bc", 'Nested $2' );
ok( $3 eq "c", 'Nested $3' );
ok( $4 eq "d", 'Nested $4' );

ok( "bookkeeper" =~ m/(((\w)$3)+)/, "Backreference" );
ok( $1 eq 'ookkee', Captured );
ok( $2 eq 'ee', Captured );

rule single { o | k | e };

ok( "bookkeeper" =~ m/<?single> ($?single)/, "Named backref" );
ok( $0->{single} eq 'o', "Named capture" );
ok( $1 eq 'o', 'Backref capture');

ok( "bookkeeper" =~ m/(<single>) ($1)/, "Positional backref" );
ok( $1 eq 'o', "Named capture" );
ok( $2 eq 'o', 'Backref capture');

ok( "bokeper" !~ m/(<single>) ($1)/, "Failed positional backref" );
ok( "bokeper" !~ m/<?single> ($?single)/, "Failed named backref" );

ok( "\$1" eq '$'.'1', 'Non-translation of non-interpolated "\\$1"' );
ok( '$1'  eq '$'.'1', 'Non-translation of non-interpolated \'$1\'' );
ok( q($1) eq '$'.'1', 'Non-translation of non-interpolated q($1)' );
ok( q{$1} eq '$'.'1', 'Non-translation of non-interpolated q{$1}' );
ok( q[$1] eq '$'.'1', 'Non-translation of non-interpolated q[$1]' );
ok( q<$1> eq '$'.'1', 'Non-translation of non-interpolated q<$1>' );
ok( q<$1 <<<>>>> eq '$'.'1 <<<>>>', 'Non-translation of nested q<$1>' );
ok( q/$1/ eq '$'.'1', 'Non-translation of non-interpolated q/$1/' );
ok( q!$1! eq '$'.'1', 'Non-translation of non-interpolated q!$1!' );
ok( q|$1| eq '$'.'1', 'Non-translation of non-interpolated q|$1|' );
ok( q#$1# eq '$'.'1', 'Non-translation of non-interpolated q#$1#' );


grammar English { rule name { john } }
grammar French  { rule name { jean } }
grammar Russian { rule name { ivan } }

ok( "john" =~ m/<?English.name> | <?French.name> | <?Russian.name>/, "English name" );
ok( $0 eq "john", "Match is john");
ok( $0 ne "jean", "Match isn't jean");
ok( $0->{name} eq "john", "Name is john");

ok( "jean" =~ m/<?English.name> | <?French.name> | <?Russian.name>/, "French name" );
ok( $0 eq "jean", "Match is jean");
ok( $0->{name} eq "jean", "Name is jean");

ok( "ivan" =~ m/<?English.name> | <?French.name> | <?Russian.name>/, "Russian name" );
ok( $0 eq "ivan", "Match is ivan");
ok( $0->{name} eq "ivan", "Name is ivan");

# BUG: See above.
#
# rule name { <?English.name> | <?French.name> | <?Russian.name> }
#  
# ok( "john" =~ m/<?name>/, "English metaname" );
# ok( $0 eq "john", "Metaname match is john");
# ok( $0 ne "jean", "Metaname match isn't jean");
# ok( $0->{name} eq "john", "Metaname is john");
# ok( $0->{name}{name} eq "john", "Metaname name is john");

