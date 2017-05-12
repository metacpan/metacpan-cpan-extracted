requires 'Furl';
requires 'JSON';
requires 'JSON::XS';
requires 'Test::More';
requires 'Try::Tiny';
requires 'URI::Escape';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::More';
};
