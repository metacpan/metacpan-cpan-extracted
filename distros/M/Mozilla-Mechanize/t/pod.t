#!/usr/bin/perl -Tw
use Test::More;
eval "use Test::Pod 1.14";

if ($ENV{USER} ne 'slanning') {
    plan skip_all => 'POD tests are intended for developers';
}
elsif (@_) {
    plan skip_all => "Test::Pod 1.14 required for testing POD: $@";
}
else {
    all_pod_files_ok();
}
