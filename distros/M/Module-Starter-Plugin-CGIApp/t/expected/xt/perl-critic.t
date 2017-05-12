#!/usr/bin/perl

# Test that the module passes perlcritic
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Find;

my @MODULES = (
	'Perl::Critic 1.098',
	"Test::Perl::Critic 1.01 (-profile => 'xt/perlcriticrc')",
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
    eval "use $MODULE";
    if ( $@ ) {
        plan( skip_all => "$MODULE not available for testing" );
    }
}

my @files = qw{
    lib/Foo/Bar.pm
    lib/Foo/Baz.pm
};

foreach my $file (@files) {
    critic_ok($file);
}

done_testing(scalar @files);

1;
