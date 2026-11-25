requires 'Carp';
requires 'List::MoreUtils',   '0.406';
requires 'Module::Pluggable', '4.8';
requires 'Module::Runtime';
requires 'Moo',            '0.009013';
requires 'Package::Stash', '0.33';
requires 'Params::Util',   '0.37';
requires 'Regexp::Common', '2011121001';
requires 'Scalar::Util';
requires 'Text::ParseWords';
recommends 'Hash::Merge',          '0.299';
recommends 'MooX::ConfigFromFile', '0.008';
recommends 'Text::Abbrev';

on test => sub {
    requires 'Capture::Tiny';
    requires 'MooX::ConfigFromFile', '0.008';
    recommends 'MooX::Options',      '4.100';
    requires 'Test::More',           '0.98';
    requires 'Text::Abbrev';
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
