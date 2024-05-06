#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;
use File::Spec;

my $internal = Test::Compile::Internal->new();
my @locations;

# Given, When
@locations = $internal->_default_locations();

# Then
is(@locations, 0, "no locations found");

# Given, When
@locations = $internal->_default_locations("flubber");

# Then
is(@locations, 0, "didn't find flubber");

# Given, When
@locations = $internal->_default_locations("lib");

# Then
is(@locations, 1, "lib directory seems good");

# Given
if ( -e 'blib' ) {
    # When
    @locations = $internal->_default_locations("lib");

    # Then
    my $expected = File::Spec->catfile("blib", "lib");
    is($locations[0], $expected, "prefer to look in blib if it's available");
}



$internal->done_testing

