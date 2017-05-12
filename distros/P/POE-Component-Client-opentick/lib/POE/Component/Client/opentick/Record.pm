package POE::Component::Client::opentick::Record;
#
#   opentick.com POE client
#
#   Protocol message response encapsulation, corresponding with a single
#       RECORD of data.
#
#   infi/2008
#
#   $Id: Record.pm 56 2009-01-08 16:51:14Z infidel $
#
#   See comments at beginning of Protocol.pm for implementation
#
#   Full user POD documentation after __END__
#

use strict;
use warnings;
use Data::Dumper;

# Ours
use POE::Component::Client::opentick::Constants;
use POE::Component::Client::opentick::Util;

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE );

###
### Variables
###

($VERSION) = q$Revision: 56 $ =~ /(\d+)/;
*TRUE      = \1;
*FALSE     = \0;
*KEEP      = \0;
*DELETE    = \1;

# FIXME: comment out the unneeded entries when testing is complete.
my $field_names = {
        OTConstant('OT_LOGIN')                   => [
            qw( SessionID RedirectFlag RedirectHostName RedirectPortNum ),
        ],
        OTConstant('OT_LOGOUT')                  => [],         # none
        OTConstant('OT_REQUEST_TICK_STREAM')     => [],
        OTConstant('OT_REQUEST_TICK_STREAM_EX')  => [],
        OTConstant('OT_REQUEST_HIST_DATA')       => [],
        OTConstant('OT_REQUEST_HIST_TICKS')      => [],
        OTConstant('OT_REQUEST_LIST_EXCHANGES')  => [
            qw( ExchangeCode ExchangeAvail ExchangeTitle ExchanceDesc ),
        ],
        OTConstant('OT_REQUEST_LIST_SYMBOLS')    => [
            qw( Currency     Symbol        Type          Company ),
        ],
        OTConstant('OT_REQUEST_EQUITY_INIT')     => [],
#            qw( DataType        Currency       InstrumentType   Company
#                PrevClosePrice  PrevCloseDate  AnnualHighPrice  AnnualHighDate
#                AnnualLowPrice  AnnualLowDate  EarningsPrice    EarningsDate
#                TotalShares     AverageVolume  CUSIP            ISIN
#                IsUPC11830      IsSmallCap     IsTestIssue ),
#        ],
        OTConstant('OT_REQUEST_OPTION_CHAIN')    => [],
        OTConstant('OT_REQUEST_OPTION_CHAIN_EX') => [],
        OTConstant('OT_REQUEST_BOOK_STREAM')     => [],
        OTConstant('OT_HEARTBEAT')               => [],         # none
        OTConstant('OT_CANCEL_TICK_STREAM')      => [],         # none
        OTConstant('OT_CANCEL_HIST_DATA')        => [],         # none
        OTConstant('OT_CANCEL_OPTION_CHAIN')     => [],         # none
        OTConstant('OT_CANCEL_BOOK_STREAM')      => [],         # none
        OTConstant('OT_REQUEST_SPLITS')          => [
            qw( DataType         ToFactor       ForFactor
                DeclarationDate  ExecutionDate  RecordDate PaymentDate ),
        ],
        OTConstant('OT_REQUEST_DIVIDENDS')       => [
            qw( DataType    Price        DeclarationDate  ExecutionDate
                RecordDate  PaymentDate  Flags            Special ),
        ],
        OTConstant('OT_REQUEST_HIST_BOOKS')      => [],
        OTConstant('OT_REQUEST_BOOK_STREAM_EX')  => [],
        OTConstant('OT_REQUEST_OPTION_CHAIN_U')  => [],
        OTConstant('OT_REQUEST_OPTION_INIT')     => [
            qw( DataType       UnderlyerSymbol  Symbol    StrikePrice
                ContractSize   ExpYear          ExpMonth  ExpDay
                ExerciseStyle  UnderlyerCUSIP   Currency  OptionMarker ),
        ],
        OTConstant('OT_REQUEST_LIST_SYMBOLS_EX') => [],
        OTConstant('OT_REQUEST_TICK_SNAPSHOT')   => [],
        OTConstant('OT_REQUEST_OPTION_CHAIN_SNAPSHOT') => [],
};

my $field_datatypes = {
        OTConstant( 'OT_DATATYPE_QUOTE' )       => [
            qw( Datatype    Timestamp
                BidSize     AskSize     BidPrice    AskPrice
                AskExchange Indicator   TickIndicator ),
        ],
        OTConstant( 'OT_DATATYPE_MMQUOTE' )     => [
            qw( Datatype    Timestamp
                BidSize     AskSize     BidPrice    AskPrice
                MMID        Indicator   TickExchange ),
        ],
        OTConstant( 'OT_DATATYPE_TRADE' )       => [
            qw( Datatype    Timestamp
                Price       Size        Volume      SeqNumber
                Indicator   TickIndicator   Flags   TickExchange ),
        ],
        OTConstant( 'OT_DATATYPE_BBO' )         => [
            qw( Datatype    Timestamp
                Price       Size        Side ),
        ],
        OTConstant( 'OT_DATATYPE_OHLC' )        => [
            qw( Datatype    Timestamp
                Open        High        Low     Close   Volume ),
        ],
        OTConstant( 'OT_DATATYPE_OHL_TODAY' )   => [
            qw( Open        High        Low ),
        ],
        OTConstant( 'OT_DATATYPE_CANCEL' )      => [
            qw( OrderRef    Size ),
        ],
        OTConstant( 'OT_DATATYPE_CHANGE' )      => [
            qw( OrderRef    Price       Size ),
        ],
        OTConstant( 'OT_DATATYPE_DELETE' )      => [
            qw( OrderRef    DeleteType  Side ),
        ],
        OTConstant( 'OT_DATATYPE_EXECUTE' )     => [
            qw( OrderRef    Size        MatchNumber ),
        ],
        OTConstant( 'OT_DATATYPE_ORDER' )       => [
            qw( OrderRef    Price       Size    Side    Display ),
        ],
        OTConstant( 'OT_DATATYPE_PRICELEVEL' )  => [
            qw( Price       Size        Side    LevelId ),
        ],
        OTConstant( 'OT_DATATYPE_PURGE' )       => [
            qw( ECNNameRoot ),
        ],
        OTConstant( 'OT_DATATYPE_REPLACE' )     => [
            qw( OrderRef    Price       Size    Side ),
        ],
        OTConstant( 'OT_DATATYPE_EQ_INIT' )     => [
            qw( DataType        Currency       InstrumentType   Company
                PrevClosePrice  PrevCloseDate  AnnualHighPrice  AnnualHighDate
                AnnualLowPrice  AnnualLowDate  EarningsPrice    EarningsDate
                TotalShares     AverageVolume  CUSIP            ISIN
                IsUPC11830      IsSmallCap     IsTestIssue ),
        ],
        OTConstant('OT_DATATYPE_OPTION_INIT')     => [
            qw( DataType       UnderlyerSymbol  Symbol    StrikePrice
                ContractSize   ExpYear          ExpMonth  ExpDay
                ExerciseStyle  UnderlyerCUSIP   Currency  OptionMarker ),
        ],
};

# Valid arguments that can be passed to the constructor.
my $valid_args = {
    requestid   => $KEEP,
    commandid   => $KEEP,
    datatype    => $KEEP,
    data        => $KEEP,
};

#######################################################################
###   Public methods                                                ###
#######################################################################

sub new
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of parameters" ) if( @args & 1 );

    my $self = {
        requestid   => undef,
        commandid   => undef,
        datatype    => undef,
        data        => [],
    };

    bless( $self, $class );

    $self->initialize( @args );

    return( $self );
}

sub initialize
{
    my( $self, %args ) = @_;

    for( keys( %args ) )
    {
        $self->{lc $_} = $args{$_} if( exists( $valid_args->{lc $_} ) );
    }

    # SPECIAL CASES FOR 64-BIT SIMULATION.  Really stupid.
    # See POD documentation for details.
    my @fields;
    if( defined( $self->{datatype} )
        && ( $self->{datatype} == OTConstant( 'OT_DATATYPE_TRADE' )
          || $self->{datatype} == OTConstant( 'OT_DATATYPE_EQ_INIT' )
          || $self->{datatype} == OTConstant( 'OT_DATATYPE_OHLC' ) ) )
    {
        @fields = OT64bit( $self->{datatype} );
    }
    $self->_expand_64bit_fields( @fields ) if( @fields );
    # END special case

    return;
}

#######################################################################
###   Accessor methods                                              ###
#######################################################################

# Requires an arrayref (row) of data to store.
sub set_data
{
    my $self = shift;
    my $data = ref( $_[0] ) eq 'ARRAY' ? $_[0] : [ @_ ];

    $self->{data} = $data;

    return( scalar( @{ $self->{data} = $data } ) );
}

sub set_datatype
{
    my( $self, $datatype ) = @_;
    return unless( $datatype =~ /^\d+$/ );

    return( $self->{datatype} = $datatype );
}

sub set_command_id
{
    my( $self, $cmd_id ) = @_;

    return( $self->{commandid} = $cmd_id );
}

sub get_data
{
    my $self = shift;

    if( ref( $_[0] ) eq 'ARRAY' )
    {
        @{$_[0]} = @{ $self->get_data_as_arrayref() };
        return( @{ $_[0] } );
    }
    elsif( ref( $_[0] ) eq 'HASH' )
    {
        %{$_[0]} = %{ $self->get_data_as_hashref() };
        return( keys( %{ $_[0] } ) );
    }
    else
    {
        return( @{ $self->{data} } );
    }
}

sub get_data_as_hashref
{
    my( $self ) = @_;

    my %hash;
    @hash{ $self->get_field_names() } = @{ $self->{data} };

    return( \%hash );
}

sub get_data_as_arrayref
{
    return( $_[0]->get_raw_data() );
}

sub get_raw_data
{
    my( $self ) = @_;

    return( $self->{data} );
}

sub as_string
{
    my( $self, $separator ) = @_;

    $separator = ' ' unless( defined( $separator ) );

    return( join( $separator, @{ $self->{data} } ) );
}

sub get_field_names
{
    my( $self ) = @_;

    my @fields = $self->{datatype}
                 ? exists( $field_datatypes->{ $self->{datatype} } )
                   ? @{ $field_datatypes->{ $self->{datatype} } }
                   : ()
                 : exists( $field_names->{ $self->{commandid} } )
                   ? @{ $field_names->{ $self->{commandid} } }
                   : ();
    # give them only enough field names to correspond with data!
    @fields = @fields[0..$#{ $self->{data} }]
        if( $#{$self->{data}} < scalar( @fields ) );

    return( @fields );
}

sub get_command_id
{
    my( $self ) = @_;

    return( $self->{commandid} );
}

sub get_command_name
{
    my( $self ) = @_;

    return( OTCommand( $self->{commandid} ) );
}

sub get_request_id
{
    my( $self ) = @_;

    return( $self->{requestid} );
}

sub get_datatype
{
    my( $self ) = @_;

    return( $self->{datatype} );
}

# is this an EOD record?
sub is_eod
{
    my( $self ) = @_;

    return( OTeod( $self->{datatype} ) );
}

###
### Private methods
###

sub _expand_64bit_fields
{
    my( $self, @fields ) = @_;

    $self->{data}->[$_] = asc2longlong( $self->{data}->[$_] ) for( @fields );

    return;
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Record - Encapsulation for data records for the POE opentick.com component.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Record;

=head1 DESCRIPTION

This module contains methods for manipulating resulting records returned by
opentick.com's API calls.

Don't fiddle with it.  Ist easy schnappen der Springenwerk, blowen-fusen
und poppen corken mit spitzensparken.

=head1 METHODS

Provides the following public methods for accessing resulting data:

=over 4

=item B<$object    = new( $const_name )>

Create a new ::Record object.

=item B<initialize( @args )>

Initialize the object instance.

=item B<set_data( $data )>

Set the data field of the ::Record object.

=item B<set_datatype( $datatype )>

Set the datatype field of the ::Record object.

=item B<set_command_id( $command_id )>

Set the command_id field of the ::Record object.

=item I<[ @values = ]> B<get_data(> I<[ $data ]> B<)>

Get the actual data from the ::Record object.

This function has 3 forms:

=over 4

=item *

When called with NO ARGUMENTS, it returns an @array (well, a list) of
all of the data.

=item *

When called with an ARRAYREF argument pointing to an actual variable,
it stores the data INTO the passed \@arrayref.

=item *

When called with a HASHREF argument pointing to an actual variable,
it stores the data INTO the passed \%hashref, with keys being set to the
field names, and values set to the corresponding data.

=back

Example:

 my( %data, @data );
 my @results = $record->get_data();     # Results in @record.
 my $count   = $record->get_data( \%data );  # Results in %data
 my $count   = $record->get_data( \@data );  # Results in @data

=item B<$data   = get_raw_data( )>

Get the raw data as an $arrayref from the ::Record object.

=item B<$data   = get_data_as_hashref( )>

Get the raw data as a mapped $hashref from the ::Record object.  Keys are
column names, values are the corresponding data.

Just an explicit form of get_data().

=item B<$data   = get_data_as_arrayref( )>

Get the raw data as an $arrayref from the ::Record object.

Just an explicit form of get_data().

=item B<$string = as_string(> I<[ $delimiter]> B<)>

Get the data from the object as a $string, with fields optionally separated
by the value of $delimiter.  $delimiter defaults to ' ' (a space).

=item B<@fields = get_field_names( )>

Get the corresponding field names for the data stored in the ::Record object.

=item B<$cmd_id = get_command_id( )>

Get the numeric CommandID from the ::Record object.  Corresponds with the
opentick.com's protocol value for CommandID.

=item B<$cmd_name = get_command_name( )>

Get the symbolic command name from the ::Record object.  Returns a
meaningful constant value, suitable for use with some methods in
::Constants.

=item B<$req_id  = get_request_id( )>

Get the numeric $request_id for the request that the data in the ::Record
object arrived in response to.

=item B<$datatype = get_datatype( )>

Get the numeric $datatype corresponding with the resulting records.
Probably useless for end users.

=item B<$boolean  = is_eod( )>

Does this ::Record object represent an EndOfData condition?  If so, the DATA
field is useless.  Just wraps $command_id and $request_id.

=back

=head1 64-BIT SIMULATION

A couple of responses in the opentick protocol specify 64-bit "long long"
return types.  This module knows which responses and fields these are, and
will "expand" them using Perl hackery to return their proper values, even
when Perl isn't compiled with 'use64bitint'.

Currently, this isn't bypassed to use native long longs with a 64-bit perl
build, but it will be in a later version.

=head1 SEE ALSO

L<POE> -- Information on the Perl Object Environment

L<POE::Component::Client::opentick> -- General documentation on this module

L<POE::Component::Client::opentick::Constants> -- Contains several helper
methods to expand some data fields you may receive.

L<http://poe.perl.org> -- Official POE site

L<http://www.opentick.com/> -- opentick website

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

