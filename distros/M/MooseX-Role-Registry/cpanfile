requires 'Moose::Role';
requires 'Syntax::Keyword::Try';
requires 'YAML::XS';
requires 'namespace::autoclean';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::CheckDeps';
};
