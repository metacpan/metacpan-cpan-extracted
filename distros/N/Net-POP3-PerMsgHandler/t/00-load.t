#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Net::POP3::PerMsgHandler' );
	use_ok( 'Net::POP3::PerMsgHandler::Control' );
	use_ok( 'Net::POP3::PerMsgHandler::Message' );
}

diag( "Testing Net::POP3::PerMessage $Net::POP3::PerMessage::VERSION, Perl $], $^X" );
