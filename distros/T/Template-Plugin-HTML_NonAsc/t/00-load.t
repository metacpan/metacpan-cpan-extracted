#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Template' );
    use_ok( 'HTML::Entities' );
    use_ok( 'Template::Plugin::HTML_NonAsc' );
}

diag( "Testing Template::Plugin::HTML_NonAsc $Template::Plugin::HTML_NonAsc::VERSION, Perl $], $^X" );
