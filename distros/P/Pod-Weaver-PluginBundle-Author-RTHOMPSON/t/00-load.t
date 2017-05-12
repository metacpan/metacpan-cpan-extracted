#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Pod::Weaver::PluginBundle::Author::RTHOMPSON');
}

diag(
"Testing Pod::Weaver::PluginBundle::Author::RTHOMPSON $Pod::Weaver::PluginBundle::Author::RTHOMPSON::VERSION, Perl $], $^X"
);
