#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::IRC::Plugin');
	use_ok( 'POE::Component::IRC::Plugin::CPAN::Info' );
}

diag( "Testing POE::Component::IRC::Plugin::CPAN::Info $POE::Component::IRC::Plugin::CPAN::Info::VERSION, Perl $], $^X" );
