#!/usr/bin/perl
#
#   Unit tests for ::Record.pm
#
#   infi/2008
#

use strict;
use warnings;

use Test::More tests => 42;
use Data::Dumper;

BEGIN {
    # Test
    use_ok( 'POE::Component::Client::opentick::Constants' );
    # Test
    use_ok( 'POE::Component::Client::opentick::Record' );
}

my ($stdout,$stderr,$obj);

# Test: Object creation
isa_ok( $obj = POE::Component::Client::opentick::Record->new(
                    RequestID   => 42,
                    CommandID   => 18,
                    Data        => [ qw/ Nicflot blorny quando floon / ],
               ),
        'POE::Component::Client::opentick::Record' );

# Test: extract raw data
is( scalar( @{ $obj->get_raw_data() } ), 4, 'get_raw_data()' );

# Test: as_string, default separator
is( $obj->as_string(), 'Nicflot blorny quando floon',
                                    'as_string(), default separator' );

# Test: as_string, supplied separator
is( $obj->as_string('---'), 'Nicflot---blorny---quando---floon',
                                    'as_string(), separator = "---"' );

# Test: get_command_id()
is( $obj->get_command_id(), OTConstant( 'OT_REQUEST_SPLITS' ),
                                                'get_command_id()' );

# Test: get_command_name()
is( $obj->get_command_name(), OTCommand( 18 ), 'get_command_name()' );

# Test: get_request_id()
is( $obj->get_request_id(), 42, 'get_request_id()' );

# Test: get_data_type()
is( $obj->get_datatype(), undef, 'get_datatype()' );

# Test: get_field_names()
is( scalar( $obj->get_field_names() ), 4, 'get_field_names()' );

# Test: set_data() followed by retrieving same data
ok(
    $obj->set_data( [ qw/gorflutz schmeen/ ] )      &&
    scalar( @{ $obj->get_raw_data() } ) == 2,
    'set_data(), get_raw_data()',
);

# Test set_command_id() followed by retrieving same id
ok(
    $obj->set_command_id( OTConstant( 'OT_REQUEST_DIVIDENDS' ) )    &&
    $obj->get_command_name() eq 'OT_REQUEST_DIVIDENDS',
    'set_command_id()',
);

# Test get_data()
is( scalar( $obj->get_data() ), 2, 'get_data()' );

# Test get_data( $aryref )
{
    my @junk;
    is( $obj->get_data( \@junk ), 2, 'get_data( \@aryref )' );
    is( $junk[0], 'gorflutz', '(get_data( \@aryref ))[0] correctness' );
    is( $junk[1], 'schmeen',  '(get_data( \@aryref ))[1] correctness' );
}

# Test get_data( $hashref )
{
    my %junk;
    is( $obj->get_data( \%junk ), 2, 'get_data( \%hashref )' );
    is( $junk{DataType}, 'gorflutz', 'get_data( \%hashref ) correctness' );
    is( $junk{Price},    'schmeen',  'get_data( \%hashref ) correctness' );
}

ok(
    defined( $obj->set_datatype( 0 ) )                               &&
    $obj->is_eod() == 1,
    'set_datatype( 0 ) && is_eod()',
);

# Test: get_field_names()
for( 1, 8, 18, 19, 23 )
{
    $obj = POE::Component::Client::opentick::Record->new(
            CommandID => $_,
            RequestID => $_ * 2,
            Data      => [ (1..30) ],
    );
#    diag( $obj->get_field_names() );
    ok(
        $obj->get_field_names() > 0,
        "get_field_names( cid=$_ )",
    );
}

for my $dt ( 1..12,17,18,50,51 )
{
    $obj = POE::Component::Client::opentick::Record->new(
            CommandID => 2,
            RequestID => $dt * 2,
            DataType  => $dt,
            Data      => [ (1..30) ],
    );
#    diag( $obj->get_field_names() );
    ok(
        $obj->get_field_names() > 0,
        "get_field_names( dt=$dt )",
    );
}

__END__

