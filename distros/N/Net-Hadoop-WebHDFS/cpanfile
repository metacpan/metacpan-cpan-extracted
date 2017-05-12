requires 'Furl';
requires 'JSON';
requires 'JSON::XS';
requires 'Test::Deep';
requires 'Test::More';
requires 'Try::Tiny';
requires 'URI';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Deep';
    requires 'Test::More';
};
