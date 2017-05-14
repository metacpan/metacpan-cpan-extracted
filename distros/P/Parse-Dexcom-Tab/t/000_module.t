use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok( 'Parse::Dexcom::Tab' );

# We do the negative first, as we don't want to muck
# up the class defintion beforehand.
my $d2 = new_ok( 'Parse::Dexcom::Tab', [ 
        file => 't/data/data.csv', 
        skip_patient_fields => 1
    ]
);
subtest 'Making sure we cannot do stuff' => sub { 
    is( $d2->can('Id'), undef, 'Cannot Id' );
    is( $d2->can('SerialNumber'), undef, 'Cannot SerialNumber' );
    is( $d2->can('IsDataBlinded'), undef, 'Cannot IsDataBlinded' );
    is( $d2->can('IsKeepPrivate'), undef, 'Cannot IsKeepPrivate' );
};

# The "normal" way...
my $d = new_ok( 'Parse::Dexcom::Tab', [ file => 't/data/data.csv' ] );
subtest 'Patient Info Field attributes' => sub { 
    _check_field( 'Id', '{TestId}' );
    _check_field( 'SerialNumber', 'TestSerial' );
    _check_field( 'IsDataBlinded', "0" );
    _check_field( 'IsKeepPrivate', "1" );

};

# Check the data..
subtest 'Spot-checking sensor readings' => sub { 
    my @list = (
        [ 0, DateTime->from_epoch( epoch => 1425522098 ), 68, 'Dexcom CGM Sensor' ],
        [ 8, DateTime->from_epoch( epoch => 1425524497 ), 0, 'Dexcom CGM Sensor' ],
        [ 9, DateTime->from_epoch( epoch => 1425524797 ), 104, 'Dexcom CGM Sensor' ]
    );

    for my $r ( @list ) { 
        my $index = shift @$r;
        my $reading = $d->sensor_readings->[$index];
        _check_reading( $reading, @$r );       
    }
};

subtest 'Spot-checking meter readings' => sub { 
    my @list = (
        [ 8, DateTime->from_epoch( epoch => 1425670915 ), 158, 'Dexcom CGM Manual' ],
        [ 11, DateTime->from_epoch( epoch => 1425751293 ), 121, 'Dexcom CGM Manual' ]
    );
 for my $r ( @list ) { 
        my $index = shift @$r;
        my $reading = $d->meter_readings->[$index];
        _check_reading( $reading, @$r );       
    }


};



done_testing;

sub _check_field { 
    my( $field, $value ) = @_;

    ok( $d->can( $field ), "$field attribute is present" );
    is( $d->$field(), $value, "$field is '$value'" );
}

sub _check_reading { 
    my( $reading, $stamp, $value, $source ) = @_;
    is( $reading->mgdl, $value, "mgdl is $value" );
    is( DateTime->compare( $stamp, $reading->stamp ), 0, "stamp is a match" );
    is( $reading->source, $source, "source is $source" );
}
