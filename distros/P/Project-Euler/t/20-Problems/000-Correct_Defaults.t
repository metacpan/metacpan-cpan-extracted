#!perl -T

use strict;
use warnings;
use autodie;
use Test::More;

use constant PROBLEM_PATH => 'lib/Project/Euler/Problem/';


my @files;
opendir (my $dir, PROBLEM_PATH);
while (( my $filename = readdir($dir) )) {
    push @files, $1  if  $filename =~ / \A (p \d+) \.pm \z /xmsi;
}

plan tests => (scalar @files * (2 + 7 + 3));


#  Make sure all of the defined problems load okay
for  my $problem  (@files) {
    my $mod = sprintf('Project::Euler::Problem::%s', $problem);
    diag( "Testing $mod" );

    # TESTS -> 2
    use_ok( $mod );
    my $problem = new_ok( $mod );

    # TESTS -> 7
    ok ( $problem->problem_name  , 'Problem_name is set correctly'   );
    ok ( $problem->problem_date  , 'Problem_date is set correctly'   );
    ok ( $problem->problem_desc  , 'Problem_desc is set correctly'   );
    ok ( $problem->problem_link  , 'Problem_link is set correctly'   );
    ok ( $problem->default_input , 'Default_input is set correctly'  );
    ok ( $problem->default_answer, 'Default_answer is set correctly' );
    ok ( $problem->help_message  , 'Help_message is set correctly'   );

    # TESTS -> 3
    ok ( $problem->solve         , "$mod ran without errors"         );
    ok ( $problem->solved_status , "$mod solved correctly"           );
	is ( $problem->solved_wanted, $problem->solved_answer, "$mod gave the incorrect answer");
}
