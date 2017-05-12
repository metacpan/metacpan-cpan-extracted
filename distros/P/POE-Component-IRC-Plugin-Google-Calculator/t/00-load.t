#!/user/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::WWW::Google::Calculator');
    use_ok('POE::Component::IRC::Plugin');
	use_ok( 'POE::Component::IRC::Plugin::Google::Calculator' );
}

diag( "Testing POE::Component::IRC::Plugin::Google::Calculator $POE::Component::IRC::Plugin::Google::Calculator::VERSION, Perl $], $^X" );
