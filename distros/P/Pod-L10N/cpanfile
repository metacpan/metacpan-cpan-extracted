requires 'perl', '5.010000';
requires 'Pod::L10N::Model';
requires 'Pod::Simple', '>=3.18, !=3.26, !=3.30';

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    # make_path()
    requires 'File::Path', '2.06_05';
    requires 'Test::Exception';
    # done_testing()
    requires 'Test::Simple', '0.88';
};
