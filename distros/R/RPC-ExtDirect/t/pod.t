use Test::More;

if ( $ENV{POD_TESTS} ) {
    eval "use Test::Pod 1.00";
    plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

    all_pod_files_ok();
}
else {
    plan skip_all => 'POD tests are not enabled.';
}

