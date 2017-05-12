#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pod::Weaver::Role::SectionReplacer' ) || print "Bail out!
";
}

diag( "Testing Pod::Weaver::Role::SectionReplacer $Pod::Weaver::Role::SectionReplacer::VERSION, Perl $], $^X" );
