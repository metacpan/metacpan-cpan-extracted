#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Filter::Line');
    use_ok('POE::Wheel::Run');
    use_ok('WWW::DoingItWrongCom::RandImage');
	use_ok( 'POE::Component::WWW::DoingItWrongCom::RandImage' );
}

diag( "Testing POE::Component::WWW::DoingItWrongCom::RandImage $POE::Component::WWW::DoingItWrongCom::RandImage::VERSION, Perl $], $^X" );
