package POE::Component::Client::opentick::Constants;
#
#   opentick.com POE client
#
#   Protocol constants
#
#   infi/2008
#
#   $Id: Constants.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#
#   NOTE: This is deep hackery, and thus ugly.  But, I'm trying to do
#         the Right Thing(tm).
#

use strict;
use warnings;
use Carp qw( carp );
$Carp::CarpLevel = 1;
use Data::Dumper;

use vars qw( $VERSION $TRUE $FALSE );

BEGIN {
    require Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( OTConstant  OTCommand   OTDefault OTCancel OTTemplate
                      OTResponses OTCmdStatus OTMsgType OTEvent  OTEventList
                      OTEventByEvent OTEventByCommand   OTAPItoCommand OTeod
                      OTCommandList  OTDatatype  OTCommandtoAPI  OT64bit
                      OTCanceller    OTTradeIndicator   OTQuoteIndicator
                      has_otlib );
    ($VERSION)  = q$Revision: 56 $ =~ /(\d+)/;
}

###
### Variables
###

*TRUE  = \1;
*FALSE = \0;

my $OTLIB_FOUND;            # Boolean, TRUE if official library is found
my $PERL_64BIT_INT;         # Boolean, TRUE if we have 64 bit integers
my $OTConstants;            # Most of the constants from the library
my $OTTemplates;            # pack/unpack templates
my $OTResponses;            # Counts of responses to various requests
my $OTDefaults;             # Default settings for the main client
our $OTCommands;            # Command number => name mapping
our $OTDatatypes;           # Datatype number => name mapping
my $OTCancels;              # Cancellation command mapping
my $OTEvents;               # Event alias => name mapping
my $OTCommandEvents;        # Command => event mapping
my $OTAPItoCommands;        # API => command mapping
my $OTTradeIndicators;      # Trade Indicator mapping
my $OTQuoteIndicators;      # Quote Indicator mapping
my $OTDeprecated;           # Deprecated method -> replacement mapping
my $OT64bit;                # COMPLETE HACK; simulate 64bit on 32bit

# Check for 64-bit support in our perl.
BEGIN {
    eval{
        my $foo = unpack("D","");
    };
    $PERL_64BIT_INT = $@ ? 0 : 1;
}

# Try to find the official library to use its constants.
BEGIN {
    # Check if the OPENTICK_LIB envvar is set, and prepend it to @INC.
    if( defined( $ENV{OPENTICK_LIB} ) && length( $ENV{OPENTICK_LIB} )
                                      && ( -d $ENV{OPENTICK_LIB} ) )
    {
        unshift( @INC, $ENV{OPENTICK_LIB} );
    }
    # Check @INC
    eval
    {
        no warnings;
        require opentick::OTConstants;
    };
    unless( $@ )
    {
        # Official lib is present in @INC, snarf its constants.
        for( keys( %opentick::OTConstants:: ) )
        {
            next unless /^OT_/;
            $OTConstants->{ $_ } = ${ $opentick::OTConstants::{ $_ } };
        }
        $OTLIB_FOUND = 1;
    }
    else
    {
        # Official lib not found in @INC.  Seed with our own values.
        $OTLIB_FOUND = 0;
#        carp( "OT:WARN: Official opentick lib not found; using built-in constants.\n" );
        $OTConstants = {
            OT_CANCEL_MESSAGE       => 'Request cancelled',

#           Force protocol version 4 later.
#            OT_PROTOCOL_VER         => 4,

            OT_MES_REQUEST          => 1,
            OT_MES_RESPONSE         => 2,

            OT_MSG_END_OF_DATA      => 10,
            OT_MSG_END_OF_REQUEST   => 20,
            OT_MSG_END_OF_SNAPSHOT  => 30,

            OT_STATUS_OK            => 1,
            OT_STATUS_ERROR         => 2,

            OT_STATUS_INACTIVE      => 1,
            OT_STATUS_CONNECTING    => 2,
            OT_STATUS_CONNECTED     => 3,
            OT_STATUS_LOGGED_IN     => 4,

            OT_INSTRUMENT_STOCK     => 1,
            OT_INSTRUMENT_INDEX     => 2,
            OT_INSTRUMENT_FUTURE    => 4,
            OT_INSTRUMENT_OPTION    => 3,

            OT_TICK_TYPE_QUOTE      => 1,
            OT_TICK_TYPE_MMQUOTE    => 2,
            OT_TICK_TYPE_TRADE      => 3,
            OT_TICK_TYPE_BBO        => 4,

            OT_MASK_TYPE_QUOTE      => 1,
            OT_MASK_TYPE_MMQUOTE    => 2,
            OT_MASK_TYPE_TRADE      => 4,
            OT_MASK_TYPE_BBO        => 8,
            OT_MASK_TYPE_LEVEL1     => 13,
            OT_MASK_TYPE_LEVEL2     => 2,
            OT_MASK_TYPE_BOTH       => 15,
            OT_MASK_TYPE_ALL        => 15,

            OT_BOOK_TYPE_CANCEL     => 5,
            OT_BOOK_TYPE_CHANGE     => 6,
            OT_BOOK_TYPE_DELETE     => 7,
            OT_BOOK_TYPE_EXECUTE    => 8,
            OT_BOOK_TYPE_ORDER      => 9,
            OT_BOOK_TYPE_LEVEL      => 10,
            OT_BOOK_TYPE_PURGE      => 11,
            OT_BOOK_TYPE_REPLACE    => 12,
            
            OT_DELETE_TYPE_ORDER    => '1',
            OT_DELETE_TYPE_PREVIOUS => '2',
            OT_DELETE_TYPE_ALL      => '3',
            OT_DELETE_TYPE_AFTER    => 'A',

            OT_FLAG_OPEN            => 1,
            OT_FLAG_HIGH            => 2,
            OT_FLAG_LOW             => 4,
            OT_FLAG_CLOSE           => 8,
            OT_FLAG_UPDATE_LAST     => 16,
            OT_FLAG_UPDATE_VOLUME   => 32,
            OT_FLAG_CANCEL          => 64,
            OT_FLAG_FROM_BOOK       => 128,

            OT_HIST_RAW_TICKS       => 1,
            OT_HIST_OHLC_TICK_BASED => 2,
            OT_HIST_OHLC_MINUTELY   => 3,
            OT_HIST_OHLC_HOURLY     => 4,
            OT_HIST_OHLC_DAILY      => 5,
            OT_HIST_OHLC_WEEKLY     => 6,
            OT_HIST_OHLC_MONTHLY    => 7,
            OT_HIST_OHLC_YEARLY     => 8,
            OT_HIST_OHL_TODAY       => 9,

            OT_HIST_CODE_EOD            => 0,
            OT_HIST_CODE_TICK_QUOTE     => 1,
            OT_HIST_CODE_TICK_MMQUOTE   => 2,
            OT_HIST_CODE_TICK_TRADE     => 3,
            OT_HIST_CODE_TICK_BBO       => 4,
            OT_HIST_CODE_OHLC           => 50,
            OT_HIST_CODE_OHL_TODAY      => 51,

            OT_INT_UNKNOWN              => 0,
            OT_LOGIN                    => 1,
            OT_LOGOUT                   => 2,
            OT_REQUEST_TICK_STREAM      => 3,       # Deprecated, use _EX
            OT_REQUEST_TICK_STREAM_EX   => 15,
            OT_CANCEL_TICK_STREAM       => 4,
            OT_REQUEST_HIST_DATA        => 5,
            OT_REQUEST_HIST_TICKS       => 17,
            OT_CANCEL_HIST_DATA         => 6,
            OT_REQUEST_LIST_EXCHANGES   => 7,
            OT_REQUEST_LIST_SYMBOLS     => 8,
            OT_HEARTBEAT                => 9,
            OT_REQUEST_EQUITY_INIT      => 10,
            OT_REQUEST_OPTION_CHAIN     => 11,      # Deprecated, use _EX
            OT_REQUEST_OPTION_CHAIN_EX  => 16,
            OT_CANCEL_OPTION_CHAIN      => 12,
            OT_REQUEST_BOOK_STREAM      => 13,
            OT_CANCEL_BOOK_STREAM       => 14,

            OT_ERR_OPENTICK             => 1000,
            OT_ERR_SYSTEM               => 2000,
            OT_ERR_SOCK                 => 3000,

            OT_ERR_BAD_LOGIN            => 1001,
            OT_ERR_NOT_LOGGED_IN        => 1002,
            OT_ERR_NO_DATA              => 1003,
            OT_ERR_INVALID_CANCEL_ID    => 1004,
            OT_ERR_INVALID_INTERVAL     => 1005,
            OT_ERR_NO_LICENSE           => 1006,
            OT_ERR_LIMIT_EXCEEDED       => 1007,
            OT_ERR_DUPLICATE_REQUEST    => 1008,
            OT_ERR_INACTIVE_ACCOUNT     => 1009,
            OT_ERR_LOGGED_IN            => 1010,
            OT_ERR_BAD_REQUEST          => 1011,
            OT_ERR_NO_HIST_PACKAGE      => 1012,
            OT_ERR_SERVER_ERROR         => 2002,
            OT_ERR_CANNOT_CONNECT       => 2003,
            OT_ERR_BROKEN_CONNECTION    => 2004,
            OT_ERR_NO_THREAD            => 2005,
            OT_ERR_NO_SOCKET            => 2006,

            OT_OS_UNKNOWN               => 1,
            OT_OS_WIN95                 => 2,
            OT_OS_WIN98                 => 3,
            OT_OS_WIN98SE               => 4,
            OT_OS_WINME                 => 5,
            OT_OS_WINNT                 => 6,
            OT_OS_WIN2000               => 7,
            OT_OS_WINXP                 => 8,
            OT_OS_LINUX                 => 20,

            OT_PLATFORM_OT              => 1,
            OT_PLATFORM_WEALTHLAB       => 3,
            OT_PLATFORM_QUANTSTUDIO     => 2,
            OT_PLATFORM_JAVA            => 7,
        };
    }   # END otlib parsing

    # Newer constants -- not included in perl otFeed OTConstants.pm distro
    # So we'll set them regardless of constant source.
    $OTConstants->{OT_ERR_RECEIVE}                   = 3001;
    $OTConstants->{OT_REQUEST_SPLITS}                = 18;
    $OTConstants->{OT_REQUEST_DIVIDENDS}             = 19;
    $OTConstants->{OT_REQUEST_HIST_BOOKS}            = 20;
    $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}        = 21;
    $OTConstants->{OT_REQUEST_OPTION_CHAIN_U}        = 22;
    $OTConstants->{OT_REQUEST_OPTION_INIT}           = 23;
    $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX}       = 24;
    $OTConstants->{OT_REQUEST_TICK_SNAPSHOT}         = 25;
    $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT} = 26;

    # Force this to 4, overriding the built-in constant values.
    $OTConstants->{OT_PROTOCOL_VER}             = 4;

    ####### My own extensions #######
    ### Response counts
    $OTConstants->{OT_RESPONSES_NONE}           = 0;
    $OTConstants->{OT_RESPONSES_ONE}            = 1;
    $OTConstants->{OT_RESPONSES_FINITE}         = 2;
    $OTConstants->{OT_RESPONSES_CONTINUOUS}     = 3;
    ### Data types
    $OTConstants->{OT_DATATYPE_EOD}             = 0;
    # Misc
    $OTConstants->{OT_DATATYPE_QUOTE}           = 1;
    $OTConstants->{OT_DATATYPE_MMQUOTE}         = 2;
    $OTConstants->{OT_DATATYPE_TRADE}           = 3;
    $OTConstants->{OT_DATATYPE_BBO}             = 4;
    # RequestBook*, RequestOption*, RequestTick*
    $OTConstants->{OT_DATATYPE_CANCEL}          = 5;
    $OTConstants->{OT_DATATYPE_CHANGE}          = 6;
    $OTConstants->{OT_DATATYPE_DELETE}          = 7;
    $OTConstants->{OT_DATATYPE_EXECUTE}         = 8;
    $OTConstants->{OT_DATATYPE_ORDER}           = 9;
    $OTConstants->{OT_DATATYPE_PRICELEVEL}      = 10;
    $OTConstants->{OT_DATATYPE_PURGE}           = 11;
    $OTConstants->{OT_DATATYPE_REPLACE}         = 12;
    $OTConstants->{OT_DATATYPE_HALT}            = 13;
    $OTConstants->{OT_DATATYPE_SPLIT}           = 14;
    $OTConstants->{OT_DATATYPE_DIVIDEND}        = 15;
    $OTConstants->{OT_DATATYPE_EQ_INIT}         = 17;
    $OTConstants->{OT_DATATYPE_EQUITY_INIT}     = 17;       # Alias
    $OTConstants->{OT_DATATYPE_OPTION_INIT}     = 18;
    $OTConstants->{OT_DATATYPE_OHLC}            = 50;
    $OTConstants->{OT_DATATYPE_OHL_TODAY}       = 51;

    # Fill the reverse command map early for other modules.
    my @cmds = qw(  OT_INT_UNKNOWN   OT_LOGIN   OT_LOGOUT    OT_HEARTBEAT
                    OT_REQUEST_TICK_STREAM      OT_REQUEST_TICK_STREAM_EX
                    OT_CANCEL_TICK_STREAM       OT_REQUEST_HIST_DATA
                    OT_REQUEST_HIST_TICKS       OT_CANCEL_HIST_DATA
                    OT_REQUEST_LIST_EXCHANGES   OT_REQUEST_LIST_SYMBOLS
                    OT_REQUEST_EQUITY_INIT      OT_REQUEST_OPTION_CHAIN
                    OT_REQUEST_OPTION_CHAIN_EX  OT_CANCEL_OPTION_CHAIN
                    OT_REQUEST_BOOK_STREAM      OT_CANCEL_BOOK_STREAM
                    OT_REQUEST_SPLITS           OT_REQUEST_DIVIDENDS
                    OT_REQUEST_HIST_BOOKS       OT_REQUEST_BOOK_STREAM_EX
                    OT_REQUEST_OPTION_CHAIN_U   OT_REQUEST_OPTION_INIT
                    OT_REQUEST_LIST_SYMBOLS_EX  OT_REQUEST_TICK_SNAPSHOT
                    OT_REQUEST_OPTION_CHAIN_SNAPSHOT );
    $OTCommands->{ $OTConstants->{$_} } = $_ for( @cmds );

    # Fill in the reverse datatype map
    my @dts = qw(   OT_DATATYPE_EOD         OT_DATATYPE_QUOTE
                    OT_DATATYPE_MMQUOTE     OT_DATATYPE_TRADE
                    OT_DATATYPE_BBO         OT_DATATYPE_SPLIT
                    OT_DATATYPE_DIVIDEND    OT_DATATYPE_OPTION_INIT
                    OT_DATATYPE_OHLC        OT_DATATYPE_OHL_TODAY
                    OT_DATATYPE_CANCEL      OT_DATATYPE_CHANGE
                    OT_DATATYPE_DELETE      OT_DATATYPE_EXECUTE
                    OT_DATATYPE_ORDER       OT_DATATYPE_PRICELEVEL
                    OT_DATATYPE_PURGE       OT_DATATYPE_REPLACE     );
    $OTDatatypes->{ $OTConstants->{$_} } = $_ for( @dts );

    # Commands that cancel other requests.
    $OTCancels = {
        $OTConstants->{OT_CANCEL_TICK_STREAM}  => {
                    $OTConstants->{OT_REQUEST_TICK_STREAM}       => 1,
                    $OTConstants->{OT_REQUEST_TICK_STREAM_EX}    => 1,
        },
        $OTConstants->{OT_CANCEL_HIST_DATA}    => {
                    $OTConstants->{OT_REQUEST_HIST_DATA}         => 1,
                    $OTConstants->{OT_REQUEST_HIST_TICKS}        => 1,
        },
        $OTConstants->{OT_CANCEL_OPTION_CHAIN} => {
                    $OTConstants->{OT_REQUEST_OPTION_CHAIN}      => 1,
                    $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX}   => 1,
        },
        $OTConstants->{OT_CANCEL_BOOK_STREAM}  => {
                    $OTConstants->{OT_REQUEST_BOOK_STREAM}       => 1,
                    $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}    => 1,
        },
    };

} # /BEGIN


# Templates for pack() and unpack()
$OTTemplates = {
    # basic templates
    MSG_LENGTH                                  => 'V',
    HEADER                                      => 'C C x x V V',
    ERROR                                       => 'v v a*',
    # templates for command message bodies
    cmds        => {
        $OTConstants->{OT_LOGIN}                   => 'v C C a16 a6 a64 a64',
        $OTConstants->{OT_LOGOUT}                  => 'a64',
        $OTConstants->{OT_REQUEST_TICK_STREAM}     => 'a64 a15 a15',
        $OTConstants->{OT_REQUEST_TICK_STREAM_EX}  => 'a64 a15 a15 x x V',
        $OTConstants->{OT_REQUEST_HIST_DATA}       => 'a64 a15 a15 x x V V C x v',
        $OTConstants->{OT_REQUEST_HIST_TICKS}      => 'a64 a15 a15 V V V',
        $OTConstants->{OT_REQUEST_LIST_EXCHANGES}  => 'a64',
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS}    => 'a64 a15',
        $OTConstants->{OT_REQUEST_EQUITY_INIT}     => 'a64 a15 a15',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN}    => 'a64 a15 a15 v V',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX} => 'a64 a15 a15 v V V',
        $OTConstants->{OT_REQUEST_BOOK_STREAM}     => 'a64 a15 a15',
        $OTConstants->{OT_HEARTBEAT}               => '',       # none
        $OTConstants->{OT_CANCEL_TICK_STREAM}      => 'a64 V',
        $OTConstants->{OT_CANCEL_HIST_DATA}        => 'a64 V',
        $OTConstants->{OT_CANCEL_OPTION_CHAIN}     => 'a64 V',
        $OTConstants->{OT_CANCEL_BOOK_STREAM}      => 'a64 V',
    # NEW!
        $OTConstants->{OT_REQUEST_SPLITS}          => 'a64 a15 a15 V V',
        $OTConstants->{OT_REQUEST_DIVIDENDS}       => 'a64 a15 a15 V V',
        $OTConstants->{OT_REQUEST_HIST_BOOKS}      => 'a64 a15 a15 V V V',
        $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}  => 'a64 a15 a15 x x V',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_U}  => 'a64 a15 a15 v V V d d V',
        $OTConstants->{OT_REQUEST_OPTION_INIT}     => 'a64 a15 a15 v V d d V',
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX} => 'a64 a15 a15 V',
        $OTConstants->{OT_REQUEST_TICK_SNAPSHOT}   => 'a64 a15 a15 x x V',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT} => 'a64 a15 a15 v V V d d V',
    },
    # templates for command response bodies
    resp        => {
        $OTConstants->{OT_LOGIN}                   => 'a64 C Z64 v',
        $OTConstants->{OT_LOGOUT}                  => '',       # none
        $OTConstants->{OT_REQUEST_TICK_STREAM}     => '',       # unneeded
        $OTConstants->{OT_REQUEST_TICK_STREAM_EX}  => '',       # unneeded
        $OTConstants->{OT_REQUEST_HIST_DATA}       => 'V',      # + datatype
        $OTConstants->{OT_REQUEST_HIST_TICKS}      => 'V',      # + datatype
        $OTConstants->{OT_REQUEST_LIST_EXCHANGES}  => 'v/Z',
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS}    => 'Z4 Z15 C v/Z',
        # Requires 64-bit int support built into Perl, but we'll simulate it.
        $OTConstants->{OT_REQUEST_EQUITY_INIT}     =>
            $PERL_64BIT_INT
                ? 'C a3 C Z80 d a8 d a8 d a8 d a8 D D a9 a12 C C C'
                : 'C a3 C Z80 d a8 d a8 d a8 d a8 a8 a8 a9 a12 C C C',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN}    => '',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX} => '',
        $OTConstants->{OT_REQUEST_BOOK_STREAM}     => '',
        $OTConstants->{OT_HEARTBEAT}               => '',       # none
        $OTConstants->{OT_CANCEL_TICK_STREAM}      => '',
        $OTConstants->{OT_CANCEL_HIST_DATA}        => '',
        $OTConstants->{OT_CANCEL_OPTION_CHAIN}     => '',
        $OTConstants->{OT_CANCEL_BOOK_STREAM}      => '',
    # NEW!
        $OTConstants->{OT_REQUEST_SPLITS}          => 'C V V V V V V',
        $OTConstants->{OT_REQUEST_DIVIDENDS}       => 'C d V V V V a a',
        $OTConstants->{OT_REQUEST_HIST_BOOKS}      => '',
        $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}  => '',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_U}  => '',
        $OTConstants->{OT_REQUEST_OPTION_INIT}     => 'C Z12 Z12 d V a4 a2 a2 a a9 a3 a',
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX} => '',
        $OTConstants->{OT_REQUEST_TICK_SNAPSHOT}   => '',
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT} => '',
    },
    datatype    => {
        $OTConstants->{OT_DATATYPE_EOD}             => 'C',
        $OTConstants->{OT_DATATYPE_QUOTE}           => 'C V V V d d a2 a a',
        $OTConstants->{OT_DATATYPE_MMQUOTE}         => 'C V V V d d a4 a',
        # XXX: The 'a8' in the next line should actually be a D.
        # Requires 64-bit int support built into Perl, but we'll simulate it.
        $OTConstants->{OT_DATATYPE_TRADE}           =>
            $PERL_64BIT_INT
                ? 'C V d V D V a a C'
                : 'C V d V a8 V a a C',
        $OTConstants->{OT_DATATYPE_BBO}             => 'C V d V a',
        $OTConstants->{OT_DATATYPE_OHLC}            =>
            $PERL_64BIT_INT
                ? 'C V d d d d D'
                : 'C V d d d d a8',
        $OTConstants->{OT_DATATYPE_OHL_TODAY}       => 'C d d d',
        # requestBookStream*, requestOptionChain*, requestHistBooks
        $OTConstants->{OT_DATATYPE_CANCEL}          => 'C V Z21 V',
        $OTConstants->{OT_DATATYPE_CHANGE}          => 'C V Z21 d V',
        $OTConstants->{OT_DATATYPE_DELETE}          => 'C V Z21 C C',
        $OTConstants->{OT_DATATYPE_EXECUTE}         => 'C V Z21 V V',
        $OTConstants->{OT_DATATYPE_ORDER}           => 'C V Z21 d V C C',
        $OTConstants->{OT_DATATYPE_PRICELEVEL}      => 'C V d V C a4',
        $OTConstants->{OT_DATATYPE_PURGE}           => 'C V a3',
        $OTConstants->{OT_DATATYPE_REPLACE}         => 'C V Z21 d V C',
    },
};

# A complete hack.  Needed to simulate 64-bit integers in 32-bits.
$OT64bit = {
    $OTConstants->{OT_DATATYPE_TRADE}        => [ 4 ],
    $OTConstants->{OT_DATATYPE_OHLC}         => [ 6 ],
    # This next key seems odd, but is actually correctly numbered.
    $OTConstants->{OT_DATATYPE_EQUITY_INIT}  => [ 12, 13 ],
};

# Number of response packets to this request
$OTResponses = {
        $OTConstants->{OT_LOGIN}                   => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_LOGOUT}                  => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_TICK_STREAM}     => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_CANCEL_TICK_STREAM}      => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_HIST_DATA}       => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_CANCEL_HIST_DATA}        => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_LIST_EXCHANGES}  => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS}    => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_HEARTBEAT}               => $OTConstants->{OT_RESPONSES_NONE},
        $OTConstants->{OT_REQUEST_EQUITY_INIT}     => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_OPTION_CHAIN}    => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_CANCEL_OPTION_CHAIN}     => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_BOOK_STREAM}     => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_CANCEL_BOOK_STREAM}      => $OTConstants->{OT_RESPONSES_ONE},
        $OTConstants->{OT_REQUEST_TICK_STREAM_EX}  => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX} => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_HIST_TICKS}      => $OTConstants->{OT_RESPONSES_FINITE},
    # NEW!
        $OTConstants->{OT_REQUEST_SPLITS}          => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_REQUEST_DIVIDENDS}       => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_REQUEST_HIST_BOOKS}      => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}  => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_U}  => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_OPTION_INIT}     => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX} => $OTConstants->{OT_RESPONSES_FINITE},
        $OTConstants->{OT_REQUEST_TICK_SNAPSHOT}   => $OTConstants->{OT_RESPONSES_CONTINUOUS},
        $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT} => $OTConstants->{OT_RESPONSES_CONTINUOUS},
};

# opentick client defaults, most can be overridden.
$OTDefaults = {
    # POE defaults
    alias            => 'opentick',              # default POE alias
    # network/socket defaults
    servers_realtime => [ qw( feed1.opentick.com    feed2.opentick.com    ) ],
    servers_delayed  => [ qw( delayed1.opentick.com delayed2.opentick.com ) ],
    port_realtime    => 10010,                   # port for realtime data
    port_delayed     => 10015,                   # port for delayed data
    realtime         => $FALSE,                  # request realtime data
    # Connection defaults
    autologin        => $TRUE,                   # Automatically log in?
    conntimeout      => 30,                      # Timeout for connect()
    autoreconnect    => $TRUE,                   # Automatically reconnect?
    reconninterval   => 60,                      # Reconn interval in seconds
    reconnretries    => 5,                       # Retries before giving up
    # Protocol defaults
    heartbeat        => 15,                      # delay in seconds for beats
    protocolver      => $OTConstants->{ 'OT_PROTOCOL_VER' },
    platform         => $OTConstants->{ 'OT_PLATFORM_OT' },
    platformpass     => '',
    os               => $OTConstants->{ 'OT_OS_LINUX' },
    macaddr          => '08:00:02:01:02:03',     # 3Com, heh
    apitimeout       => 30,                      # Time out for API commands
    # LAME
    request_timeout  => 30,                      # Time before expunging
                                                 # ListSymbols or ListExch*
};

# symbolic event name to actual POE event name map.
$OTEvents = {
    OT_ON_LOGIN          => 'ot_on_login',
    OT_ON_ERROR          => 'ot_on_error',
    OT_ON_DATA           => 'ot_on_data',
    OT_ON_LOGOUT         => 'ot_on_logout',
    OT_REQUEST_COMPLETE  => 'ot_request_complete',
    OT_REQUEST_CANCELLED => 'ot_request_cancelled',
    OT_CONNECT_FAILED    => 'ot_connect_failed',
    OT_STATUS_CHANGED    => 'ot_status_changed',
};

# integral command number to POE event name map.
$OTCommandEvents = {
    $OTConstants->{OT_INT_UNKNOWN}              => $OTEvents->{OT_ON_ERROR},
    $OTConstants->{OT_LOGIN}                    => $OTEvents->{OT_ON_LOGIN},
    $OTConstants->{OT_LOGOUT}                   => $OTEvents->{OT_ON_LOGOUT},
    $OTConstants->{OT_REQUEST_TICK_STREAM}      => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_CANCEL_TICK_STREAM}  => $OTEvents->{OT_REQUEST_CANCELLED},
    $OTConstants->{OT_REQUEST_HIST_DATA}        => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_CANCEL_HIST_DATA}    => $OTEvents->{OT_REQUEST_CANCELLED},
    $OTConstants->{OT_REQUEST_LIST_SYMBOLS}     => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_LIST_EXCHANGES}   => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_HEARTBEAT}                => undef,
    $OTConstants->{OT_REQUEST_EQUITY_INIT}      => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_OPTION_CHAIN}     => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_CANCEL_OPTION_CHAIN} => $OTEvents->{OT_REQUEST_CANCELLED},
    $OTConstants->{OT_REQUEST_BOOK_STREAM}      => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_CANCEL_BOOK_STREAM}  => $OTEvents->{OT_REQUEST_CANCELLED},
    $OTConstants->{OT_REQUEST_TICK_STREAM_EX}   => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX}  => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_HIST_TICKS}       => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_SPLITS}           => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_DIVIDENDS}        => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_HIST_BOOKS}       => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_BOOK_STREAM_EX}   => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_OPTION_CHAIN_U}   => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_OPTION_INIT}      => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX}  => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_TICK_SNAPSHOT}    => $OTEvents->{OT_ON_DATA},
    $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT} => $OTEvents->{OT_ON_DATA},
};

# API method name to command number map
$OTAPItoCommands = {
    'requestSplits'         => $OTConstants->{OT_REQUEST_SPLITS},
    'requestDividends'      => $OTConstants->{OT_REQUEST_DIVIDENDS},
    'requestOptionInit'     => $OTConstants->{OT_REQUEST_OPTION_INIT},
    'requestHistData'       => $OTConstants->{OT_REQUEST_HIST_DATA},
    'requestHistTicks'      => $OTConstants->{OT_REQUEST_HIST_TICKS},
    'requestTickStream'     => $OTConstants->{OT_REQUEST_TICK_STREAM},
    'requestTickStreamEx'   => $OTConstants->{OT_REQUEST_TICK_STREAM_EX},
    'requestTickSnapshot'   => $OTConstants->{OT_REQUEST_TICK_SNAPSHOT},
    'requestOptionChain'    => $OTConstants->{OT_REQUEST_OPTION_CHAIN},
    'requestOptionChainEx'  => $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX},
    'requestOptionChainU'   => $OTConstants->{OT_REQUEST_OPTION_CHAIN_U},
    'requestOptionChainSnapshot' => $OTConstants->{OT_REQUEST_OPTION_CHAIN_SNAPSHOT},
    'requestEqInit'         => $OTConstants->{OT_REQUEST_EQUITY_INIT},
    'requestEquityInit'     => $OTConstants->{OT_REQUEST_EQUITY_INIT},
    'requestBookStream'     => $OTConstants->{OT_REQUEST_BOOK_STREAM},
    'requestBookStreamEx'   => $OTConstants->{OT_REQUEST_BOOK_STREAM_EX},
    'requestHistBooks'      => $OTConstants->{OT_REQUEST_HIST_BOOKS},
    'requestListSymbols'    => $OTConstants->{OT_REQUEST_LIST_SYMBOLS},
    'requestListSymbolsEx'  => $OTConstants->{OT_REQUEST_LIST_SYMBOLS_EX},
    'requestListExchanges'  => $OTConstants->{OT_REQUEST_LIST_EXCHANGES},
    'cancelTickStream'      => $OTConstants->{OT_CANCEL_TICK_STREAM},
    'cancelHistData'        => $OTConstants->{OT_CANCEL_HIST_DATA},
    'cancelOptionChain'     => $OTConstants->{OT_CANCEL_OPTION_CHAIN},
    'cancelBookStream'      => $OTConstants->{OT_CANCEL_BOOK_STREAM},
};

# Deprecated methods and their suggested replacements
$OTDeprecated = {
    $OTConstants->{OT_REQUEST_TICK_STREAM}
                            => $OTConstants->{OT_REQUEST_TICK_STREAM_EX},
    $OTConstants->{OT_REQUEST_OPTION_CHAIN}
                            => $OTConstants->{OT_REQUEST_OPTION_CHAIN_EX},
};

$OTTradeIndicators = {
    '@' =>  'Regular Trade',
    A   =>  'Acquisition - Cash',
    B   =>  'Bunched Trade - Average Price',
    C   =>  'Cash Trade',
    D   =>  'Distribution - Next Day Market',
    E   =>  'Automatic Execution',
    F   =>  'Intermarket Sweep Order',
    G   =>  'Bunched Sold Trade - Opening/Reopening Trade Detail',
    H   =>  'Intraday Trade Detail',
    I   =>  'Basket Index on Close Transaction',
    J   =>  'Rule 127 Trade (NYSE only)',
    K   =>  'Rule 155 Trade (AMEX only)',
    L   =>  'Sold Last',
    N   =>  'Next Day',
    O   =>  'Opened',
    P   =>  'Prior Reference Price',
    R   =>  'Seller',
    S   =>  'Split Trade',
    T   =>  'Form-T Trade - Pre/Post Market Trade',
    W   =>  'Average Price Trade',
    Z   =>  'Sold (Out of Sequence)',
};

$OTQuoteIndicators = {
    A   =>  'Depth on Ask side',
    B   =>  'Depth on Bid side',
    C   =>  'Closing',
    D   =>  'News Dissemination',
    E   =>  'Order Influx',
    F   =>  'Fast Trading',
    G   =>  'Trading Range Indication',
    H   =>  'Depth on Bid and Ask',
    I   =>  'Order Imbalance',
    J   =>  'Due to Related Security-news Dissemination',
    K   =>  'Due to Related Security-news Pending',
    L   =>  'Closed Market Maker (NASDAQ)',
    M   =>  'No Eligible Market Participant Quotes in Issue at Market Close',
    N   =>  'Non-Firm Quote',
    O   =>  'Opening Quote',
    P   =>  'News Pending',
    Q   =>  'Additional Information-Due To Related Security',
    R   =>  'Regular (NASDAQ Open)',
    S   =>  'Due To Related Security',
    T   =>  'Resume',
    V   =>  'In View of Common',
    X   =>  'Equipment Changeover',
    Y   =>  'Regular One Sided',
    Z   =>  'No Open/No Resume',
    ' ' =>  'No Special Condition Exists',      # space
};

########################################################################
###   Functions                                                      ###
########################################################################

sub has_otlib
{
    return( $OTLIB_FOUND ? $TRUE : $FALSE );
}

sub OTConstant
{
    return( $OTConstants->{ $_[0] } );
}

sub OTCommand
{
    return( $OTCommands->{ $_[0] } || $OTCommands->{ 0 } );
}

# NUMBER => DT_SYMBOL
sub OTDatatype
{
    return( $OTDatatypes->{ $_[0] } );
}

sub OTCommandList
{
    return( values( %{ $OTCommands } ) );
}

sub OTDefault
{
    return( $OTDefaults->{ $_[0] } );
}

# Return which request command_ids can be cancelled by a cancel command_id
sub OTCancel
{
    return( $OTCancels->{ $_[0] } );
}

# Return the cancel command_id for a request command_id
sub OTCanceller
{
    my( $command_id ) = @_;

    for my $cancel_id ( keys( %$OTCancels ) )
    {
        return( $cancel_id ) if( $OTCancels->{$cancel_id}->{$command_id} );
    }

    return;
}

sub OTEvent
{
    return( $OTEvents->{ $_[0] } );
}

sub OTEventByEvent
{
    my %OTEventNames = reverse( %$OTEvents );
    return( $OTEventNames{ $_[0] } );
}

sub OTEventList
{
    return( values( %$OTEvents ) );
}

sub OTEventByCommand
{
    return( $OTCommandEvents->{ $_[0] } );
}
  
# API method name to command number map
sub OTAPItoCommand
{
    my $repl;

    return( wantarray
            ? ( $OTAPItoCommands->{ $_[0] }, 
                OTDeprecated( $OTAPItoCommands->{ $_[0] } ) )
            : $OTAPItoCommands->{ $_[0] } );
}

# command number to API map
sub OTCommandtoAPI
{
    return unless defined( $_[0] );
    my %map = reverse %{ $OTAPItoCommands };

    return( $map{ $_[0] } );
}

# Equity TRADE indicator code to description map
sub OTTradeIndicator
{
    return( $OTTradeIndicators->{ $_[0] } );
}

# Equity QUOTE indicator code to description map
sub OTQuoteIndicator
{
    return( $OTQuoteIndicators->{ $_[0] } );
}

# Return the number of responses (a constant) for a command type
sub OTResponses
{
    return( $OTResponses->{ $_[0] } );
}

# Return the suggested command id, if the supplied command id is deprecated
sub OTDeprecated
{
    return( $OTDeprecated->{ $_[0] } );
}

# Is a valid command status
sub OTCmdStatus
{
    my( $cmd_status ) = @_;

    return( ( $cmd_status =~ /^\d+$/ and
              ( $cmd_status == $OTConstants->{OT_STATUS_ERROR} or
                $cmd_status == $OTConstants->{OT_STATUS_OK} ) )
            ? $TRUE
            : $FALSE );
}

# Is a valid opentick message type
sub OTMsgType
{
    my( $msg_type ) = @_;

    return( ( $msg_type =~ /^\d+$/ &&
              ( $msg_type == $OTConstants->{OT_MES_REQUEST} or
                $msg_type == $OTConstants->{OT_MES_RESPONSE} ) )
            ? $TRUE
            : $FALSE );
}

# Is DataType End-of-Data ?
sub OTeod
{
    my( $data_type ) = @_;

    return( ( defined( $data_type )     &&
              $data_type =~ /^\d+$/     &&
              $data_type == $OTConstants->{OT_DATATYPE_EOD} )
            ? $TRUE
            : $FALSE );
}

# Are some fields actually supposed to be 64-bit integral values?
sub OT64bit
{
    my( $input ) = @_;

    return () if( $PERL_64BIT_INT );

    return( defined( $OT64bit->{$input} ) ? @{$OT64bit->{$input}} : () );
}

# Return the pack template for the specified item.
# Allows for some XPath-style magic.
sub OTTemplate
{
    my( $template ) = @_;

    my( $tree, $tmpl_name ) = split( /\//, $template );

    my $result;
    if( defined( $tmpl_name ) )
    {
        # be nice and convert the command for them.
        $tmpl_name = $OTConstants->{ $tmpl_name }
            unless( $tmpl_name =~ /^\d+$/ );
        return unless( defined( $tmpl_name ) );
        $result = $OTTemplates->{ $tree }->{ $tmpl_name };
    }
    else
    {
        $result = $OTTemplates->{ $template };
    }

    return( $result );
}

###
### Main
###

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Constants - Constants for the opentick POE Component.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Constants;

=head1 DESCRIPTION

This module contains all of the constants used by the rest of
POE::Component::Client::opentick, and thus is of no use to anything else.

It also rudely exports a bunch of junk into your namespace.  This is
desirable for the POE component, but why would you want that in your own
module?

Don't fiddle with it.  Ist easy schnappen der Springenwerk, blowen-fusen
und poppen corken mit spitzensparken.

=head1 EXPORTS

Exports the following methods into the using package's namespace:

=over 

=item B<$value       = OTConstant( $const_name )>

Return the value of the named constant.

=item B<$cmd_name    = OTCommand( $cmd_number )>

Return the command name from the constant command number.

=item B<$cmd_name    = OTCommandList( )>

Return a list of all symbolic E<lt>CommandTypeE<gt> names.

=item B<$value       = OTDefault( $value_name )>

Return one of the default values by name.

=item B<$pack_tmpl   = OTTemplate( $tmpl_name )>

Return the named pack() template.

=item B<$hashref     = OTCancel( $cmd_number )>

Return a hashref of the command IDs that the supplied $cmd_number can cancel.

Mapped like such:

{ $cmd_number =E<gt> $TRUE, $cmd_number2 =E<gt> $TRUE, ... }

It's a hashref for O(1) lookups instead of O(n) list grepping.

=item B<$cmd_id      = OTCanceller( $cmd_id )>

Returns the canceller command ID of the appropriate cancel request for the
supplied command ID.

=item B<$datatype    = OTDatatype( $const_num )>

Return a I<$string> representing the datatype for the supplied constant.

=item B<$count       = OTResponses( $cmd_number )>

Return the I<$count> of expected response packets to the specified command.

Possible values and their meanings are:

 undef   Unknown or unlisted number of responses.
 0       No response is generated (OT_HEARTBEAT).
 1       Only one reply packet is generated.
 2       A finite number of response packets are generated.
 3       The stream is continuous until told to shut up.

=item B<$boolean     = OTCmdStatus( $value )>

Return I<TRUE> if the value is a valid CommandStatus.

=item B<$boolean     = OTMsgType( $value )>

Return I<TRUE> if the value is a valid MessageType.

=item B<$eventname   = OTEvent( $name )>

Return actual POE $eventname for symbolic event name constant.

=item B<$constname   = OTEventByEvent( $eventname )>

The reverse of the above.

=item B<$constname   = OTEventByCommand( $cmd_number )>

Returns the POE event to issue for a particular $cmd_number response.

e.g. OTEventByCommand( OTConstants('OT_LOGIN') ) returns 'ot_on_login'

=item B<@eventnames  = OTEventList( )>

Return a list of all actual OTEvent names ( values( %$OTEvents ) ).

=item B<$cmd_id      = OTDeprecated( $cmd_id )>

Return the replacement $cmd_id, if the supplied $cmd_id refers to an
Opentick-deprecated command.

Only requestTickStream and requestOptionChain are deprecated right now.

=item B<$boolean     = OTeod( $value )>

Return TRUE if the value specifies End-Of-Data for E<lt>DataTypeE<gt>.

=item B<$cmd_num     = OTAPItoCommand( $api_name )>

Return the $command_number for the specified PUBLIC $api_name.

=item B<$description = OTQuoteIndicator( $code )>

Return the description of the supplied Indicator code from an EQUITY quote,
or undef if not found.

=item B<$description = OTTradeIndicator( $code )>

Return the description of the supplied Indicator code from a TRADE quote,
or undef if not found.

=item B<$api_name    = OTCommandtoAPI( $cmd_id )>

Does the reverse of the above.

=item B<@fieldnums   = OT64bit( $cmd_id )>

Return a list of field numbers that are actually supposed to be 64-bit
integers for this I<$cmd_id>.  This is to simulate 64-bit ints on a 32-bit
perl.  Returns the empty list if we're compiled with 64-bit ints, or the
I<$cmd_id> doesn't require any 64-bit simulation.

Basically, it's used internally and useless for anything else.

=item B<$boolean     = has_otlib( )>

Return I<TRUE> if official opentick libraries were found in @INC.

=back

=head1 WARNINGS

This module attempts to include the official 'opentick' perl library paths
from @INC, to retrieve constant values, and carps the following warning if
it is not present:

B<Official opentick lib not found; using built-in constants.>

It is better to use the official opentick library constant values, if you
can.  I am sure they will strive to be backward-compatible, but I cannot
guarantee the values contained herein will always work in the future.

They can be downloaded from:

L<http://www.opentick.com/index.php?app=content&event=api&menu=products>

Install at least B<opentick::OTConstants> to a path in your @INC, and this
module will find them.  (Read B<perldoc -q "include path"> if you are unsure
how to modify your @INC path.)

=head1 SEE ALSO

L<POE>

L<POE::Component::Client::opentick>

L<http://poe.perl.org>

L<http://www.opentick.com/>

perldoc lib

perldoc -q "include path"

=head1 AUTHOR

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

The data from opentick.com are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the opentick.com and exchange license agreements with the data.

Further details are available on L<http://www.opentick.com/>.

=cut

