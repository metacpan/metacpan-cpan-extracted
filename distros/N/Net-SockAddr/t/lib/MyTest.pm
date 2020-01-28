package MyTest;
use 5.012;
use Test::Catch;
use Test::More;
use Net::SockAddr;
use Test::Exception;

XS::Loader::load();

sub import {
    my $caller = caller();
    foreach my $sym_name (qw/
        is cmp_deeply ok done_testing skip isnt time_mark check_mark pass fail cmp_ok like isa_ok unlike diag plan
        var create_file create_dir move change_file_mtime change_file unlink_file remove_dir subtest new_ok dies_ok catch_run
    /) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
    }
}

1;