use inc::Module::Install;

name 'NgxQueue';
all_from 'lib/NgxQueue.pm';

cpanfile;

if (want_xs) {
    use_ppport 3.20;
    cc_warnings;
    cc_src_paths 'src';

    test_target test_pp => (
        env => { PERL_ONLY => 1 },
    );
}

author_tests 'xt';

WriteAll;
