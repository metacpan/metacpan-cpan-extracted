#!perl -Tw

use Test::More tests => 23;

BEGIN {
	use_ok( 'Net::PJLink', ':RESPONSES' ) || print "Bail out!\n";
}

is( OK,			Net::PJLink::OK,		"Export OK" );
is( ERR_COMMAND,	Net::PJLink::ERR_COMMAND,	"Export ERR_COMMAND" );
is( ERR_PARAMETER,	Net::PJLink::ERR_PARAMETER,	"Export ERR_PARAMETER" );
is( ERR_UNAVL_TIME,	Net::PJLink::ERR_UNAVL_TIME,	"Export ERR_UNAVL_TIME" );
is( ERR_PRJT_FAIL,	Net::PJLink::ERR_PRJT_FAIL,	"Export ERR_PRJT_FAIL" );
is( ERR_NETWORK,	Net::PJLink::ERR_NETWORK,	"Export ERR_NETWORK" );
is( ERR_AUTH,		Net::PJLink::ERR_AUTH,		"Export ERR_AUTH" );
is( WARNING,		Net::PJLink::WARNING,		"Export WARNING" );
is( ERROR,		Net::PJLink::ERROR,		"Export ERROR" );
is( ERR_TIMEOUT,	Net::PJLink::ERR_TIMEOUT,	"Export ERR_TIMEOUT" );
is( ERR_PARSE,		Net::PJLink::ERR_PARSE,		"Export ERR_PARSE" );
is( POWER_OFF,		Net::PJLink::POWER_OFF,		"Export POWER_OFF" );
is( POWER_ON,		Net::PJLink::POWER_ON,		"Export POWER_ON" );
is( POWER_COOLING,	Net::PJLink::POWER_COOLING,	"Export POWER_COOLING" );
is( POWER_WARMUP,	Net::PJLink::POWER_WARMUP,	"Export POWER_WARMUP" );
is( INPUT_RGB,		Net::PJLink::INPUT_RGB,		"Export INPUT_RGB" );
is( INPUT_VIDEO,	Net::PJLink::INPUT_VIDEO,	"Export INPUT_VIDEO" );
is( INPUT_DIGITAL,	Net::PJLink::INPUT_DIGITAL,	"Export INPUT_DIGITAL" );
is( INPUT_STORAGE,	Net::PJLink::INPUT_STORAGE,	"Export INPUT_STORAGE" );
is( INPUT_NETWORK,	Net::PJLink::INPUT_NETWORK,	"Export INPUT_NETWORK" );
is( MUTE_VIDEO,		Net::PJLink::MUTE_VIDEO,	"Export MUTE_VIDEO" );
is( MUTE_AUDIO,		Net::PJLink::MUTE_AUDIO,	"Export MUTE_AUDIO" );

