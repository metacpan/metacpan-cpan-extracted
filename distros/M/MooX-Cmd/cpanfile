requires 'Carp';
requires 'List::MoreUtils',   '0.406';
requires 'Moo',               '0.009013';
requires 'Module::Pluggable', '4.8';
requires 'Module::Runtime';
requires 'Package::Stash', '0.33';
requires 'Params::Util',   '0.37';
requires 'Regexp::Common', '2011121001';
requires 'Scalar::Util';
requires 'Text::ParseWords';

recommends 'Hash::Merge',          '0.299';
recommends 'MooX::ConfigFromFile', '0.008';
recommends 'Text::Abbrev';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Capture::Tiny';
};

on develop => sub {
    requires 'Test::CPAN::Changes';
    requires 'Test::Kwalitee';
    requires 'Test::Perl::Critic';
    requires 'Test::PerlTidy';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes';
    requires 'Test::Spelling';
};
