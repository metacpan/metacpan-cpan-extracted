#!perl
use Test::More;

if ( not $ENV{AUTHOR_TESTS} ) {
    plan skip_all => 'Skipping author tests';
}
else {
    eval "use Test::Pod 1.14";
    die $@ if $@;
    all_pod_files_ok();
}
