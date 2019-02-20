package  # private package
    GlobalEvents::Test::Stderr::Tee;

use MojoX::GlobalEvents;

on 'ge_test_stderr_tee' => sub {
    print STDERR __PACKAGE__;
};

1;
