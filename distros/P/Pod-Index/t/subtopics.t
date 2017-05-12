use strict;
use warnings;
use Test::More;

# preamble to make it work portably regardless of where the test is run
use File::Spec::Functions;
my ($volume, $dirstring, $file) = File::Spec->splitpath($0);
my @DIRS = File::Spec->splitdir($dirstring);
pop @DIRS while (@DIRS and $DIRS[-1] =~ /^(t|)$/);
unshift @INC, catdir(@DIRS);

#plan 'no_plan';
plan tests => 4;

use_ok('Pod::Index::Search');

my $q = Pod::Index::Search->new(
    filename => catfile(@DIRS, 't', 'test.txt'),
);

isa_ok($q, 'Pod::Index::Search');

my @subtopics = $q->subtopics('balloon');
is_deeply(
    \@subtopics, 
    ['balloon, floating', 'balloon, gas-filled', 'balloon, light'], 
    'topics'
);

@subtopics = $q->subtopics('balloon', deep => 1);
is_deeply(
    \@subtopics, 
    ['balloon, floating', 'balloon, gas-filled, helium', 'balloon, light'], 
    'topics'
);
