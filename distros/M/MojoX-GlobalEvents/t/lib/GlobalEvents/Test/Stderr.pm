package  # private package
    GlobalEvents::Test::Stderr;

use MojoX::GlobalEvents;

on 'ge_test_stderr' => sub {
    print STDERR __PACKAGE__;
};

1;
