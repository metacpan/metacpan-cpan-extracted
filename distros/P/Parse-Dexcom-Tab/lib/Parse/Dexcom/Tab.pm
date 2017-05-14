package Parse::Dexcom::Tab;
use Moose;
use Moose::Util::TypeConstraints;
use Text::CSV;
use Try::Tiny;
use Diabetes::Glucose;
use DateTime::Format::DateParse;

sub BUILD { 
    my $self = shift;
 
    $self->_parse;
}

subtype 'Parse::Dexcom::Tab::CSVFile'
    => as 'FileHandle';

coerce 'Parse::Dexcom::Tab::CSVFile'
    => from 'Str'
    => via { 
        open my $fh, "<", $_ or die "Could not open file $_: $!";
        return $fh;
    };

has 'csv' => ( 
    is => 'rw',
    lazy_build => 1,
    documentation => 'An object that can parse CSV data, should be Text::CSV or similar.',
);

has 'file' => ( 
    is => 'rw',
    isa => 'Parse::Dexcom::Tab::CSVFile',
    coerce => 1,
    documentation => 'Contains a filehandle with tab-delimited data.',
    required => 1,
);

sub _build_csv { 
    my $self = shift;

    Text::CSV->new( {
        sep_char => "\t",
    });
}

has 'sensor_readings' => ( 
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has 'meter_readings' => ( 
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has 'units' => ( 
    is => 'rw',
    default => 'mgdl',
    required => 1,
);

has 'skip_patient_fields' => ( 
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub _parse { 
    my $self = shift;
    
    my $c = $self->csv;
    my $headers = $c->getline( $self->file );
    
    unless( $self->skip_patient_fields ) { 
        __PACKAGE__->meta->make_mutable;
    }

    while( my $row = $c->getline( $self->file ) ) { 
        # CSV Fields in order, by row:
        # 0: PatientInfoField
        # 1: PatientInfoValue
        # 2: GlucoseInternalTime
        # 3: GlucoseDisplayTime
        # 4: GlucoseValue
        # 5: MeterInternalTime
        # 6: MeterDisplayTime
        # 7: MeterValue
        # 8: EventLoggedInternalTime
        # 9: EventLoggedDisplayTime
        # 10: EventTime
        # 11: EventType
        # 12: EventDescription
        #
        $self->_get_patient_info( $row );
        $self->_get_glucose_value( $row );
        $self->_get_meter_value( $row );
        
        # Events are ignored for now, I don't have any and
        # this is for me, fuckers.
    }

    __PACKAGE__->meta->make_immutable;
}

# This is the scariest of them all, as there could be ANYTHING
# in there, oh my god!
sub _get_patient_info {
    my( $self, $row ) = @_;
    return if $self->skip_patient_fields;

    my( $field, $value ) = @$row[0,1];
    return unless $field && defined $value;       # Make sure we got a field name and a defined value
    my $meta = $self->meta;
    
    $meta->add_attribute( 
        $field => ( 
            accessor => $field,
            default => $value
        )
    );
    $self->$field( $value );
}

# Grab sensor values and save 'em.
sub _get_glucose_value {
    my( $self, $row ) = @_;

    my( $time, $reading ) = ( $row->[2], $row->[4] );
  
    if( $reading eq 'Low' ) { $reading = 0; }
    if( $reading eq 'High' ) { $reading = -1; }
    my $g = Diabetes::Glucose->new( 
        $self->units    => $reading,
        source          => 'Dexcom CGM Sensor',
        stamp           => DateTime::Format::DateParse->parse_datetime( $time, 'UTC' ),
    );
        
    my $list = $self->sensor_readings;
    push @$list, $g;
    $self->sensor_readings( $list );
    
}

# Grab meter (calibration, "Enter BG") values.
sub _get_meter_value {
    my( $self, $row ) = @_;
    my( $time, $reading ) = ( $row->[5], $row->[7] );

    my $g = Diabetes::Glucose->new( 
        $self->units        => $reading,
        source              => 'Dexcom CGM Manual',
        stamp               => DateTime::Format::DateParse->parse_datetime( $time, 'UTC' ),
    );

    my $list = $self->meter_readings;
    push @$list, $g;
    $self->meter_readings( $list );
}


__PACKAGE__->meta->make_immutable;

=head1 NAME

Parse::Dexcom::Tab - Parse the Dexcom tab-delimited export file.

=head1 VERSION

This dpcument describes version 1.0.

=head1 SYNOPSIS

    use Parse::Dexcom::Tab;

    my $pdt = Parse::Dexcom::Tab->new(
        file    => '/path/to/data.csv',
    );

    say $pdt->SerialNumber;     # SNRA313JAS (or whatever)
    say $pdt->Id;               # {some-GUID-here}
    
    for my $sensor ( $pdt->sensor_readings ) { 
        say $sensor->mgdl, " at ", $sensor->stamp;
    }

=head1 DESCRIPTION

This package will parse a Tab-delimited export from the Dexcom Studio 
application and use L<Diabetes::Glucose> to store the glucose readings
in a nice, east-to-access format.  

Readings from the sensor are placed in the C<sensor_readings> array refernece.

Readings from a meter, such as entered during the "Enter BG" or calibration
are placed in the C<meter_readings> array reference.

Both of these array references contain L<Diabetes::Glucose> objects.  See
the documentation there for more information (it's a simple object that 
stores data and does the mgdl/mmol conversation for you).

Any patient info fields are created accessors by the same name as the field
and available for use.  

=head1 METHODS

=over 3

=item new

Constructor, requires a filename in the C<file> attribute.  This file
should be a tab-delimited file exported by the Dexcom Studio, or at the very
least, a file in the same format.  

Alternatively, you may provide a open file handle suitable for reaidng that
provides the same data.  

All parsing and MOP operations are done at construction.  When your program
is reading to take the performance hit, create one of these.

=item sensor_readings

An array ref containing L<Diabetes::Glucose> objects.  You might want to 
sort it by the C<stamp> attribute, a DateTime object.

These are readings that the sensor provided.  

=item meter_readings

Same as C<sensor_readings>, except these readings are provided by the "Enter 
BG" option on the receiver.  

=item Patient Info Fields

All patient info fields have their own accessors created.  At the time of
this writing, the sample file I pulled from my reciever has te following:

=over 3

=item Id

=item SerialNumber

=item IsDataBlinded

=item IsKeepPrivate

=back

The're not terribly useful.  If you wish to avoid the computational time
needed to create these attributes, provide  C<<no_patient_fields => 1>> in the 
constructor.


=back

=head1 BUGS

=head1 AUTHOR

=head1 LICENSE
