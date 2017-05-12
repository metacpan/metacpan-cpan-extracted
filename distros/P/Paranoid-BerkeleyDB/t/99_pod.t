#!/usr/bin/perl -T
use Paranoid;
use Test::More;
psecureEnv('/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin');
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
