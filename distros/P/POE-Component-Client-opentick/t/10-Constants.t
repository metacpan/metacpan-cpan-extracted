#!/usr/bin/perl
#
#   Unit tests for ::Constants.pm
#
#   infi/2008
#

#use strict;
#use warnings;
use Data::Dumper;

use Test::More tests => 101;

# Test #1: Can use module
BEGIN { use_ok( 'POE::Component::Client::opentick::Constants' ); }

# Test section: OTConstants
is( OTConstant( 'OT_LOGIN' ),                   1,
                                    'OTConstant: OT_LOGIN' );
is( OTConstant( 'OT_ERR_NO_DATA' ),          1003,
                                    'OTConstant: OT_ERR_NO_DATA' );
is( OTConstant( 'OT_ERR_RECEIVE' ),          3001,
                                    'OTConstant: OT_ERR_RECEIVE' );
is( OTConstant( 'OT_OS_LINUX' ),               20,
                                    'OTConstant: OT_OS_LINUX' );
is( OTConstant( 'OT_PLATFORM_OT' ),             1,
                                    'OTConstant: OT_PLATFORM_LINUX' );
is( OTConstant( 'OT_HIST_CODE_EOD' ),           0,
                                    'OTConstant: OT_HIST_CODE_EOD');
is( OTConstant( 'OT_FLAG_CANCEL' ),            64,
                                    'OTConstant: OT_FLAG_CANCEL' );
is( OTConstant( 'OT_BOOK_TYPE_LEVEL' ),        10,
                                    'OTConstant: OT_BOOK_TYPE_LEVEL' );
is( OTConstant( 'OT_INSTRUMENT_INDEX' ),        2,
                                    'OTConstant: OT_INSTRUMENT_INDEX' );
is( OTConstant( 'OT_ERR_NO_DATA' ),          1003,
                                    'OTConstant: OT_ERR_NO_DATA' );
is( OTConstant( 'OT_DELETE_TYPE_AFTER' ),     'A',
                                    'OTConstant: OT_ERR_NO_DATA' );
is( OTConstant( 'OT_REQUEST_OPTION_CHAIN_U' ), 22,
                                    'OTConstant: OT_REQUEST_OPTION_CHAIN_U' );
is( OTConstant( 'moogoogaipan' ),           undef,
                                    'OTConstant: invalid string' );
is( OTConstant( 42 ),                       undef,
                                    'OTConstant: invalid numeric' );

# Test section: Can access templates
is( OTTemplate( 'ERROR' ),         'v v a*',
                                    'OTTemplate: ERROR' );
is( OTTemplate( "cmds/OT_LOGIN" ), 'v C C a16 a6 a64 a64',
                                    'OTTemplate: cmds/OT_LOGIN' );
is( OTTemplate( "resp/OT_REQUEST_LIST_SYMBOLS" ), 'Z4 Z15 C v/Z',
                                    'OTTemplate: resp/OT_REQUEST_LIST_SYMBOLS');
is( OTTemplate( 'borkbork' ),        undef, 'OTTemplate: invalid string' );
is( OTTemplate( 'brown/SMURF' ),     undef, 'OTTemplate: invalid path' );
is( OTTemplate( 2222 ),              undef, 'OTTemplate: invalid numeric' );

# Test section: Can access default settings
is( ref( OTDefault( 'servers_delayed' ) ), 'ARRAY',
                                           'OTDefault: servers_delayed' );
is( OTDefault( 'port_delayed' ),             10015, 'OTDefault: port_delayed' );
is( OTDefault( 'schlumberger' ),     undef, 'OTDefault: invalid string' );
is( OTDefault( 319058 ),             undef, 'OTDefault: invalid numeric' );

# Test section: Can access commands
is( OTCommand( 5 ),         'OT_REQUEST_HIST_DATA',
                                    'OTCommand: OT_REQUEST_HIST_DATA' );
is( OTCommand( 19 ),        'OT_REQUEST_DIVIDENDS',
                                    'OTCommand: OT_REQUEST_DIVIDENDS' );
is( OTCommand( 'froo' ),    'OT_INT_UNKNOWN',
                                    'OTCommand: invalid string' );
is( OTCommand( 239147 ),    'OT_INT_UNKNOWN',
                                    'OTCommand: invalid numeric' );

# Test section: Can access response lengths
is( OTResponses( OTConstant( 'OT_HEARTBEAT' ) ), 0,
                                    'OTResponses: OT_HEARTBEAT' );
is( OTResponses( OTConstant( 'OT_LOGIN' ) ), 1,
                                    'OTResponses: OT_LOGIN' );
is( OTResponses( OTConstant( 'OT_REQUEST_SPLITS' ) ), 2,
                                    'OTResponses: OT_REQUEST_SPLITS' );
is( OTResponses( OTConstant( 'OT_REQUEST_EQUITY_INIT' ) ), 1,
                                    'OTResponses: OT_REQUEST_EQUITY_INIT' );
is( OTResponses( 'meow' ),  undef,  'OTResponses: invalid string' );
is( OTResponses( 128947 ),  undef,  'OTResponses: invalid numeric' );

# Test #7: has_otlib exported
ok(
    has_otlib() == 1 || has_otlib() == 0,
    'has_otlib exported',
);

# Test #8: Can access OTCancel
is( scalar keys %{ OTCancel( OTConstant( 'OT_CANCEL_TICK_STREAM' ) )},  2,
                                           'OTCancel: OT_CANCEL_TICK_STREAM' );
is( scalar keys %{ OTCancel( OTConstant( 'OT_CANCEL_HIST_DATA' ) )},    2,
                                           'OTCancel: OT_CANCEL_HIST_DATA' );
is( scalar keys %{ OTCancel( OTConstant( 'OT_CANCEL_OPTION_CHAIN' ) )}, 2,
                                           'OTCancel: OT_CANCEL_OPTION_CHAIN' );
is( scalar keys %{ OTCancel( OTConstant( 'OT_CANCEL_BOOK_STREAM' ) )},  2,
                                           'OTCancel: OT_CANCEL_BOOK_STREAM' );
is( OTCancel( qw/Gefingerpoken/ ),  undef, 'OTCancel: invalid string' );
is( OTCancel( 21423 ),              undef, 'OTCancel: invalid numeric' );

# Test #9: OTCmdStatus access
ok(
    OTCmdStatus( OTConstant( 'OT_STATUS_OK' ) )                 &&
    OTCmdStatus( OTConstant( 'OT_STATUS_ERROR' ) )              &&
    ! OTCmdStatus( qw/My hovercraft is full of eels/ )          &&
    ! OTCmdStatus( 42 ),
    'OTCmdStatus correctness',
);

# Test #10: OTMsgType access
ok(
    OTMsgType( OTConstant( 'OT_MES_REQUEST' ) )                 &&
    OTMsgType( OTConstant( 'OT_MES_RESPONSE' ) )                &&
    ! OTMsgType( qw/Mein Luftkissenboot ist voller Aale/ )      &&
    ! OTMsgType( 83194 ),
    'OTMsgType correctness',
);

# Test #11: OTEvent access
is( OTEvent( 'OT_ON_LOGIN' ),          'ot_on_login',
                                            'OTEvent: OT_ON_LOGIN' );
is( OTEvent( 'OT_ON_ERROR' ),          'ot_on_error',
                                            'OTEvent: OT_ON_ERROR' );
is( OTEvent( 'OT_ON_DATA' ),           'ot_on_data',
                                            'OTEvent: OT_ON_DATA' );
is( OTEvent( 'OT_ON_LOGOUT' ),         'ot_on_logout',
                                            'OTEvent: OT_ON_LOGOUT' );
is( OTEvent( 'OT_REQUEST_COMPLETE' ),  'ot_request_complete',
                                            'OTEvent: OT_REQUEST_COMPLETE' );
is( OTEvent( 'OT_REQUEST_CANCELLED' ), 'ot_request_cancelled',
                                            'OTEvent: OT_REQUEST_CANCELLED' );
is( OTEvent( 'OT_CONNECT_FAILED' ),    'ot_connect_failed',
                                            'OTEvent: OT_CONNECT_FAILED' );
is( OTEvent( 'OT_STATUS_CHANGED' ),    'ot_status_changed',
                                            'OTEvent: OT_STATUS_CHANGED' );
is( OTEvent( 'meow' ),  undef,         'OTEvent: invalid string' );
is( OTEvent( 498124 ),  undef,         'OTEvent: invalid numeric' );

# Test #12: OTEventList access
is( scalar OTEventList(), 8, 'OTEventList size' );

# Test #13: OTEventByEvent access
is( OTEventByEvent( 'ot_on_login' ),         'OT_ON_LOGIN',
                                'OTEventByEvent: OT_ON_LOGIN' );
is( OTEventByEvent( 'ot_request_complete' ), 'OT_REQUEST_COMPLETE',
                                'OTEventByEvent: OT_REQUEST_COMPLETE' );
is( OTEventByEvent( qw/B1FF/ ), undef, 'OTEventByEvent: invalid string' );
is( OTEventByEvent( 9482 ),     undef, 'OTEventByEvent: invalid numeric' );

# Test #14: OTEventByCommand access
is( OTEventByCommand( OTConstant( 'OT_LOGIN' ) ),
        OTEvent( 'OT_ON_LOGIN' ), 'OTEventByCommand: OT_LOGIN' );
is( OTEventByCommand( OTConstant( 'OT_REQUEST_HIST_TICKS' ) ),
        OTEvent( 'OT_ON_DATA' ),  'OTEventByCommand: OT_REQUEST_HIST_TICKS' );
is( OTEventByCommand( OTConstant( 'OT_INT_UNKNOWN' ) ),
        OTEvent( 'OT_ON_ERROR' ), 'OTEventByCommand: OT_ON_ERROR' );
is( OTEventByCommand( OTConstant( 'OT_LOGOUT' ) ),
        OTEvent( 'OT_ON_LOGOUT' ), 'OTEventByCommand: OT_ON_LOGOUT' );
is( OTEventByCommand( qw/FEEN/ ), undef, 'OTEventByCommand: invalid string' );
is( OTEventByCommand( 55 ),       undef, 'OTEventByCommand: invalid numeric' );

# Test #15: OTAPItoCommand access
is( OTAPItoCommand( 'requestSplits' ),    OTConstant( 'OT_REQUEST_SPLITS' ),
            'OTAPItoCommand: requestSplits' );
is( OTAPItoCommand( 'requestDividends' ), OTConstant( 'OT_REQUEST_DIVIDENDS' ),
            'OTAPItoCommand: requestDividends' );
is( OTAPItoCommand( 'requestOptionInit' ), OTConstant('OT_REQUEST_OPTION_INIT'),
            'OTAPItoCommand: requestOptionInit' );
is( OTAPItoCommand( 'requestTickStream' ), OTConstant('OT_REQUEST_TICK_STREAM'),
            'OTAPItoCommand: requestTickStream' );

# Test series: proper deprecation
my @junk = OTAPItoCommand( 'requestTickStream' );
ok(
    # now check if the above returns a proper list in list context
    @junk == 2                                                  &&
    $junk[1] eq OTAPItoCommand( 'requestTickStreamEx' ),
    'proper deprecation',
);

# Test #16: OTeod access
ok(
    OTeod( 0 )          &&
    ! OTeod( 42 )       &&
    ! OTeod( qw/BLOOP/ ),
    'OTeod correctness'
);

# Test #17: OTCommandList access
ok(
    scalar OTCommandList()      == 27,
    'OTCommandList size',
);

# Test #18: OTDatatype access
is( OTDatatype( 1 ),    'OT_DATATYPE_QUOTE',     'OTDatatype: QUOTE' );
is( OTDatatype( 4 ),    'OT_DATATYPE_BBO',       'OTDatatype: BBO' );
is( OTDatatype( 51 ),   'OT_DATATYPE_OHL_TODAY', 'OTDatatype: OHL_TODAY' );

# Test: OTTradeIndicator correctness
is( OTTradeIndicator( '@' ), 'Regular Trade',       'OTTradeIndicator: @' );
is( OTTradeIndicator( 'S' ), 'Split Trade',         'OTTradeIndicator: S' );
is( OTTradeIndicator( 'E' ), 'Automatic Execution', 'OTTradeIndicator: E' );
is( OTTradeIndicator( 423 ), undef,       'OTTradeIndicator: invalid num' );
is( OTTradeIndicator( '/' ), undef,       'OTTradeIndicator: invalid string' );

# Test: OTQuoteIndicator correctness
is( OTQuoteIndicator( 'A' ), 'Depth on Ask side',   'OTQuoteIndicator: A' );
is( OTQuoteIndicator( 'O' ), 'Opening Quote',       'OTQuoteIndicator: O' );
is( OTQuoteIndicator( ' ' ), 'No Special Condition Exists', 'OTQuoteIndicator: null' );
is( OTQuoteIndicator( 555 ), undef,       'OTQuoteIndicator: invalid num' );
is( OTQuoteIndicator( '_' ), undef,       'OTQuoteIndicator: invalid string' );

# Test: 64-bit correctness
is( OT64bit( 1 ), (), 'OT64bit: nothing' );
is( OT64bit( 'VROOM' ), (), 'OT64bit: invalid string' );

eval {
    no warnings;
    my $foo = unpack("D","");
};
my $PERL_64BIT_INT = $@ ? 0 : 1;

if( $PERL_64BIT_INT )
{
    is( OT64bit( OTConstant( 'OT_DATATYPE_EQ_INIT' ) ),         undef,
                             'OT64bit: OT_DATATYPE_EQ_INIT' );
    is( OT64bit( OTConstant( 'OT_DATATYPE_TRADE' ) ),           undef,
                             'OT64bit: OT_DATATYPE_TRADE' );
    is( OT64bit( OTConstant( 'OT_DATATYPE_OHLC' ) ),            undef,
                             'OT64bit: OT_DATATYPE_OHLC' );
    is( OTTemplate( 'resp/OT_REQUEST_EQUITY_INIT' ),
        'C a3 C Z80 d a8 d a8 d a8 d a8 D D a9 a12 C C C',
        'OTTemplate: 64-bit resp/OT_REQUEST_EQUITY_INIT' );
    is( OTTemplate( 'datatype/OT_DATATYPE_TRADE' ),
        'C V d V D V a a C',
        'OTTemplate: 64-bit datatype/OT_DATATYPE_TRADE' );
    is( OTTemplate( 'datatype/OT_DATATYPE_OHLC' ),
        'C V d d d d D',
        'OTTemplate: 64-bit datatype/OT_DATATYPE_OHLC' );
} else {
    is( OT64bit( OTConstant( 'OT_DATATYPE_EQ_INIT' ) ),         2,
                             'OT64bit: OT_DATATYPE_EQ_INIT' );
    is( OT64bit( OTConstant( 'OT_DATATYPE_TRADE' ) ),           1,
                             'OT64bit: OT_DATATYPE_TRADE' );
    is( OT64bit( OTConstant( 'OT_DATATYPE_OHLC' ) ),            1,
                             'OT64bit: OT_DATATYPE_OHLC' );
    is( OTTemplate( 'resp/OT_REQUEST_EQUITY_INIT' ),
        'C a3 C Z80 d a8 d a8 d a8 d a8 a8 a8 a9 a12 C C C',
        'OTTemplate: 32-bit resp/OT_REQUEST_EQUITY_INIT' );
    is( OTTemplate( 'datatype/OT_DATATYPE_TRADE' ),
        'C V d V a8 V a a C',
        'OTTemplate: 32-bit datatype/OT_DATATYPE_TRADE' );
    is( OTTemplate( 'datatype/OT_DATATYPE_OHLC' ),
        'C V d d d d a8',
        'OTTemplate: 32-bit datatype/OT_DATATYPE_OHLC' );
}

# Test: OTCanceller correctness
is( OTCanceller( 3 ), 4, 'Canceller: OT_REQUEST_TICK_STREAM' );
is( OTCanceller( 15 ), 4, 'Canceller: OT_REQUEST_TICK_STREAM_EX' );
is( OTCanceller( 13 ), 14, 'Canceller: OT_REQUEST_HIST_DATA' );
is( OTCanceller( 21 ), 14, 'Canceller: OT_REQUEST_HIST_BOOKS' );
is( OTCanceller( 11 ), 12, 'Canceller: OT_REQUEST_OPTION_CHAIN' );
is( OTCanceller( 16 ), 12, 'Canceller: OT_REQUEST_OPTION_CHAIN_EX' );
is( OTCanceller( 5 ), 6, 'Canceller: OT_REQUEST_BOOK_STREAM' );
is( OTCanceller( 17 ), 6, 'Canceller: OT_REQUEST_BOOK_STREAM_EX' );

__END__
