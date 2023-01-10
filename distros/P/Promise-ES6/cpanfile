on test => sub {
    requires $_ for (
        'autodie',
        'FindBin',
        'Test::Fatal',
        'Test::Class',
        'Test::Deep',
        'Test::FailWarnings',
    );

    requires 'Test::More' => 1.302103;  # skip() without test count
};

on develop => sub {
    requires 'AnyEvent';
    recommends 'IO::Async';
    recommends 'Mojolicious';
};

configure_requires 'ExtUtils::MakeMaker::CPANfile';

recommends 'Future::AsyncAwait' => 0.47;
