#!perl
use 5.10.0;
use strict;
use warnings;
use Test::Most;

# Mandate the POD tests, contrary to the dagolden no-pod-tests fad. I rank
# documentation on par with the code, not something one can maybe remember to
# maybe run the release testing for.
use Test::Pod;

all_pod_files_ok();
