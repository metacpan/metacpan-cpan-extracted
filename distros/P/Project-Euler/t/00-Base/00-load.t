#!perl -T

use strict;
use warnings;
use autodie;
use Test::Most;

bail_on_fail;

use constant PROBLEM_PATH => 'lib/Project/Euler/Problem/';


my @files;
opendir (my $dir, PROBLEM_PATH);
while (( my $filename = readdir($dir) )) {
    push @files, $1  if  $filename =~ / \A (p \d+) \.pm \z /xmsi;
}

plan tests => (scalar @files * 1) + 2;
diag( "Testing Project::Euler, Perl $], $^X" );


use_ok( 'Project::Euler' );
use_ok( 'Project::Euler::Problem::Base' );

#  Make sure all of the defined problems load okay
for  my $problem  (@files) {
    my $mod = sprintf('Project::Euler::Problem::%s', $problem);
    use_ok( $mod );
}
