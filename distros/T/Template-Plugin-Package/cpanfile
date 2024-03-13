# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'Template' => 0;
requires 'Template::Plugin' => 0;


on 'configure' => sub {
    requires 'ExtUtils::MakeMaker', '6.46';
};

on 'build' => sub {
    requires 'ExtUtils::MakeMaker', '6.46';
};

on 'test' => sub {
    requires 'Test::More', '0.95';  # So we can run subtests on v5.10
};

# vi:et:sw=4 ts=4 ft=perl
