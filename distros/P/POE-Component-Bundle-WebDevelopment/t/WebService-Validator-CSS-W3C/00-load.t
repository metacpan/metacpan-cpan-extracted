#!perl -T

use Test::More tests => 9;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('WebService::Validator::CSS::W3C');
    use_ok('POE');
    use_ok('POE::Wheel::Run');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Filter::Line');
	use_ok( 'POE::Component::WebService::Validator::CSS::W3C' );
}

diag( "Testing POE::Component::WebService::Validator::CSS::W3C $POE::Component::WebService::Validator::CSS::W3C::VERSION, Perl $], $^X" );
