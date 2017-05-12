# -*- mode: cperl -*-

requires 'perl', '5.008005';

on build => sub {
    requires 'Module::Build::Tiny', '0.022';
};

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Base';
    requires 'Test::Requires';
    requires 'FindBin';
    requires 'Path::Class';
    requires 'Devel::Cover';
};
