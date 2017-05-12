package RRD::Tweak;

use strict;
use warnings;
use Carp;


use base 'DynaLoader';

our $VERSION = '1.00';
bootstrap RRD::Tweak;

# Internal object structure:
# $self->{ds} is array of DS definitions
# $self->{rra} is array of RRA definitions
# $self->{cdp_prep}[$rra][$ds] is a hash of intermediate data
# $self->{cdp_data}[$rra][$row][$ds] is a data element
#  (last row corresponds to the newest data)

=head1 NAME

RRD::Tweak - RRD file manipulation

=cut



=head1 SYNOPSIS

    use RRD::Tweak;

    my $rrd = RRD::Tweak->new();
    $rrd->load_file($filename1);
    my $rrd_info = $rrd->info();

    $rrd->del_ds(5);
    $rrd->add_ds({name => 'InErrors',
                  type=> 'COUNTER',
                  heartbeat => 755});
    $rrd->modify_ds(2, {max => 1000});

    $rrd->add_rra({cf => 'MAX',
                   xff => 0.77,
                   steps => 12,
                   rows => 10000}) ;
    $rrd->modify_rra(6, {rows => 3000});

    $rrd->save_file($filename2);


This is a module for manipulating the structure of RRDtool files. It can
read a file, alter its DS and RRA structure, and save a new file. It
also allows creating new empty RRD files in memory or on the disk.

The file read/write operations are implemented in native C. The module
links with librrd, so the librrd library and its header files are
required for building the RRD::Tweak module. The module is tested with
RRDtool versions 1.3 and 1.4. As the RRD file format is architecture
dependent, RRD::Tweak can only read files which are created by RRDtool
in the same processor architecture.

=head1 METHODS

=head2 new

 my $rrd = RRD::Tweak->new();

Creates a new RRD::Tweak object

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->{'errmsg'} = '';
    $self->_set_empty(1);

    return $self;
}


=head2 is_empty

  $status = $rrd->is_empty();

Returns true value if this RRD::Tweak object contains no data. The
object can be empty due to new() or clean() objects.

=cut

sub is_empty {
    my $self = shift;
    return $self->{'is_empty'};
}

sub _set_empty {
    my $self = shift;
    my $val = shift;
    $self->{'is_empty'} = $val;
    return;
}


=head2 validate

  $status = $rrd->validate();

Validates the contents of an RRD::Tweak object and returns false if the
data is inconsistent. In case of failed validation, $rrd->errmsg()
returns a human-readable explanation of the failure.

=cut

# DS types supported
my %valid_ds_types =
    ('GAUGE' => 1,
     'COUNTER' => 1,
     'DERIVE' => 1,
     'ABSOLUTE' => 1,
     'COMPUTE' => 1);

# CF names and corresponding required attributes
my %cf_names_and_rra_attributes =
    ('AVERAGE'      => ['xff'],
     'MIN'          => ['xff'],
     'MAX'          => ['xff'],
     'LAST'         => ['xff'],
     'HWPREDICT'    => ['hw_alpha', 'hw_beta', 'dependent_rra_idx'],
     'MHWPREDICT'   => ['hw_alpha', 'hw_beta', 'dependent_rra_idx'],
     'DEVPREDICT'   => ['dependent_rra_idx'],
     'SEASONAL'     => ['seasonal_gamma', 'seasonal_smooth_idx',
                        'dependent_rra_idx'],
     'DEVSEASONAL'  => ['seasonal_gamma', 'seasonal_smooth_idx',
                        'dependent_rra_idx'],
     'FAILURES'     => ['delta_pos', 'delta_neg', 'window_len',
                        'failure_threshold', 'dependent_rra_idx'],
    );

# required cdp_prep attributes for each CF
my %cdp_prep_attributes =
    ('AVERAGE'      => ['value', 'unknown_datapoints'],
     'MIN'          => ['value', 'unknown_datapoints'],
     'MAX'          => ['value', 'unknown_datapoints'],
     'LAST'         => ['value', 'unknown_datapoints'],
     'HWPREDICT'    => ['intercept', 'last_intercept', 'slope', 'last_slope',
                        'null_count', 'last_null_count'],
     'MHWPREDICT'   => ['intercept', 'last_intercept', 'slope', 'last_slope',
                        'null_count', 'last_null_count'],
     'DEVPREDICT'   => [],
     'SEASONAL'     => ['seasonal', 'last_seasonal', 'init_flag'],
     'DEVSEASONAL'  => ['seasonal', 'last_seasonal', 'init_flag'],
     'FAILURES'     => ['history'],
    );

# CF names with special treatment
my %hw_rra_name =
    ('HWPREDICT'    => 1,
     'MHWPREDICT'   => 1,
     'DEVPREDICT'   => 1,
     'SEASONAL'     => 1,
     'DEVSEASONAL'  => 1,
     'FAILURES'     => 1,
     );


sub validate {
    my $self = shift;

    if( $self->is_empty() ) {
        $self->_set_errmsg('This is an empty RRD::Tweak object');
        return 0;
    }

    # validate positive numbers
    foreach my $key ('pdp_step', 'last_up') {
        if( not defined($self->{$key}) ) {
            $self->_set_errmsg('$self->{' . $key . '} is undefined');
            return 0;
        }
        if( not eval {$self->{$key} > 0}) {
            $self->_set_errmsg('$self->{' . $key .
                               '} is not a positive number');
            return 0;
        }
    }

    # validate the presence of arrays
    foreach my $key ('ds', 'rra', 'cdp_prep', 'cdp_data') {
        if( not defined($self->{$key}) ) {
            $self->_set_errmsg('$self->{' . $key . '} is undefined');
            return 0;
        }
        if( ref($self->{$key}) ne 'ARRAY' ) {
            $self->_set_errmsg('$self->{' . $key .
                               '} is not an ARRAY');
            return 0;
        }
    }

    # Check that we have a positive number of DS'es
    my $n_ds = scalar(@{$self->{'ds'}});
    if( $n_ds == 0 ) {
        $self->_set_errmsg('no datasources are defined in RRD');
        return 0;
    }

    # validate each DS definition
    for( my $ds=0; $ds < $n_ds; $ds++ ) {
        my $r = $self->{'ds'}[$ds];

        # validate strings
        foreach my $key ('name', 'type', 'last_ds') {
            if( not defined($r->{$key}) ) {
                $self->_set_errmsg('$self->{ds}[' . $ds .
                                   ']{' . $key . '} is undefined');
                return 0;
            }
            if( $r->{$key} eq '' ) {
                $self->_set_errmsg('$self->{ds}[' . $ds .
                                   ']{' . $key . '} is empty');
                return 0;
            }
        }

        # check if the type is valid
        if( not $valid_ds_types{$r->{'type'}} ) {
            $self->_set_errmsg('$self->{ds}[' . $ds .
                               ']{type} has invalid value: "' . $r->{'type'} .
                               '"');
            return 0;
        }

        # validate numbers
        my @number_keys = ('scratch_value', 'unknown_sec');
        if( $r->{'type'} ne 'COMPUTE' ) {
            push(@number_keys, 'hb', 'min', 'max');
        } else {
            # COMPUTE is not currently supported by Tweak.xs because RPN
            # processing methods are not exported by librrd
            push(@number_keys, 'rpn');
        }

        foreach my $key (@number_keys) {
            if( not defined($r->{$key}) ) {
                $self->_set_errmsg('$self->{ds}[' . $ds .
                                   ']{' . $key . '} is undefined');
                return 0;
            }

            if( $r->{$key} !~ /^-?nan$/io and
                $r->{$key} !~ /^[0-9e+\-.]+$/io ) {
                $self->_set_errmsg('$self->{ds}[' . $ds .
                                   ']{' . $key . '} is not a number');
                return 0;
            }
        }
    }

    # Check that we have a positive number of RRA's
    my $n_rra = scalar(@{$self->{'rra'}});
    if( $n_rra == 0 ) {
        $self->_set_errmsg('no round-robin arrays are defined in RRD');
        return 0;
    }

    # validate RRA definitions

    for( my $rra=0; $rra < $n_rra; $rra++) {
        my $r = $self->{'rra'}[$rra];

        if( ref($r) ne 'HASH' ) {
            $self->_set_errmsg('$self->{rra}[' . $rra . '] is not a HASH');
            return 0;
        }

        my $cf = $r->{cf};
        if( not defined($cf) ) {
            $self->_set_errmsg('$self->{rra}[' . $rra . ']{cf} is undefined');
            return 0;
        }

        if( not defined($cf_names_and_rra_attributes{$cf}) ) {
            $self->_set_errmsg('Unknown CF name in $self->{rra}[' . $rra .
                               ']{cf}: ' . $cf);
            return 0;
        }

        my $pdp_per_row = $r->{'pdp_per_row'};
        if( not defined($pdp_per_row) ) {
            $self->_set_errmsg('$self->{rra}[' . $rra .
                               ']{pdp_per_row} is undefined');
            return 0;
        }
        if( 0 + $pdp_per_row <= 0 ) {
            $self->_set_errmsg('$self->{rra}[' . $rra .
                               ']{pdp_per_row} is not a positive integer');
            return 0;
        }

        if( ref($r->{'cdp_prep_defaults'}) ne 'HASH' ) {
            $self->_set_errmsg('$self->{rra}[' . $rra .
                               ']{cdp_prep_defaults} is undefined');
            return 0;
        }

        foreach my $key (@{$cf_names_and_rra_attributes{$cf}}) {
            if( not defined($r->{$key}) ) {
                $self->_set_errmsg('$self->{rra}[' . $rra . ']{' . $key .
                                   '} is undefined');
                return 0;
            }
        }
    }

    # Check the sizes of cdp_prep and cdp_data arrays
    if( scalar(@{$self->{'cdp_prep'}}) != $n_rra ) {
        $self->_set_errmsg('Wrong size of $self->{cdp_prep} array. ' .
                           'Expected: ' . $n_rra . ', is: ' .
                           scalar(@{$self->{'cdp_prep'}}));
        return 0;
    }
    if( scalar(@{$self->{'cdp_data'}}) != $n_rra ) {
        $self->_set_errmsg('Wrong size of $self->{cdp_data} array. ' .
                           'Expected: ' . $n_rra . ', is: ' .
                           scalar(@{$self->{'cdp_data'}}));
        return 0;
    }

    # validate cdp_prep
    for( my $rra=0; $rra < $n_rra; $rra++) {

        if( ref($self->{'cdp_prep'}[$rra]) ne 'ARRAY' ) {
            $self->_set_errmsg('$self->{cdp_prep}[' . $rra .
                               '] is not an ARRAY');
            return 0;
        }

        my $cf = $self->{'rra'}[$rra]{cf};

        for( my $ds=0; $ds < $n_ds; $ds++ ) {
            my $r = $self->{'cdp_prep'}[$rra][$ds];

            if( ref($r) ne 'HASH' ) {
                $self->_set_errmsg('$self->{cdp_prep}[' . $rra .
                                   '][' . $ds . '] is not an HASH');
                return 0;
            }

            foreach my $key (@{$cdp_prep_attributes{$cf}}) {
                if( not defined($r->{$key}) ) {
                    $self->_set_errmsg
                        ('$self->{cdp_prep}[' . $rra .
                         '][' . $ds . ']{' . $key . '} is undefined');
                    return 0;
                }
            }

            if( $cf eq 'FAILURES' ) {
                if( ref($r->{'history'}) ne 'ARRAY' ) {
                    $self->_set_errmsg
                        ('$self->{cdp_prep}[' . $rra .
                         '][' . $ds . ']{history} is not an ARRAY');
                    return 0;
                }

                # in rrd_format.h: MAX_FAILURES_WINDOW_LEN=28
                if( scalar(@{$r->{'history'}}) > 28 ) {
                    $self->_set_errmsg
                        ('$self->{cdp_prep}[' . $rra .
                         '][' . $ds . ']{history} is a too large array');
                    return 0;
                }
            }
        }
    }

    # validate cdp_data
    for( my $rra=0; $rra < $n_rra; $rra++) {

        my $rra_data = $self->{'cdp_data'}[$rra];
        if( ref($rra_data) ne 'ARRAY' ) {
            $self->_set_errmsg('$self->{cdp_data}[' . $rra .
                               '] is not an ARRAY');
            return 0;
        }

        my $rra_len = scalar(@{$rra_data});
        if( $rra_len == 0 ) {
            $self->_set_errmsg('$self->{cdp_data}[' . $rra .
                               '] is an empty array');
            return 0;
        }

        for( my $row=0; $row < $rra_len; $row++ ) {
            my $row_data = $rra_data->[$row];
            if( ref($row_data) ne 'ARRAY' ) {
                $self->_set_errmsg('$self->{cdp_data}[' . $rra .
                                   '][' . $row . '] is not an ARRAY');
                return 0;
            }

            my $row_len = scalar(@{$row_data});
            if( $row_len != $n_ds ) {
                $self->_set_errmsg('$self->{cdp_data}[' . $rra .
                                   '][' . $row . '] array has wrong size. ' .
                                   'Expected: ' . $n_ds . ', found: ' .
                                   $row_len);
                return 0;
            }

            for( my $ds=0; $ds < $n_ds; $ds++ ) {
                if( not defined($row_data->[$ds]) ) {
                    $self->_set_errmsg('$self->{cdp_prep}[' . $rra .
                                       '][' . $ds . '][' . $ds .
                                       '] is undefined');
                    return 0;
                }
            }
        }
    }

    return 1;
}




=head2 errmsg

  $msg = $rrd->errmsg();

Returns a text string explaining the details if $rrd->validate() failed.

=cut

sub errmsg {
    my $self = shift;
    return $self->{'errmsg'};
}

sub _set_errmsg {
    my $self = shift;
    my $msg = shift;
    $self->{'errmsg'} = $msg;
    return;
}




=head2 load_file

 $rrd->load_file($filename);

Reads the RRD file and stores its whole content in the RRD::Tweak object

=cut

sub load_file {
    my $self = shift;
    my $filename = shift;

    croak('load_file() requires a filename') unless defined($filename);

    # the native method is defined in Tweak.xs and uses librrd methods
    $self->_load_file($filename);

    $self->_set_empty(0);

    # populate $self->{'rra'}[$rra]->{'cdp_prep_defaults'}
    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {
        $self->_default_cdp_prep_attributes($rra);
    }

    if( not $self->validate() ) {
        croak('load_file prodiced an invalid RRD::Tweak object: ' .
              $self->errmsg());
    }

    return;
}




=head2 save_file

 $rrd->save_file($filename);

Creates a new RRD file from the contents of the RRD::Tweak object. If
the file already exists, it's truncated and overwritten.

=cut

sub save_file {
    my $self = shift;
    my $filename = shift;

    croak('save_file() requires a filename') unless defined($filename);

    if( not $self->validate() ) {
        croak('Cannot run save_file because RRD::Tweak object is invalid: '  .
              $self->errmsg());
    }

    # the native method is defined in Tweak.xs and uses librrd methods
    $self->_save_file($filename);

    return;
}


=head2 clean

 $rrd->clean();

The method empties the RRD::Tweak object to what it was right after new().

=cut

sub clean {
    my $self = shift;

    delete $self->{'pdp_step'};
    delete $self->{'last_up'};
    delete $self->{'ds'};
    delete $self->{'rra'};
    delete $self->{'cdp_prep'};
    delete $self->{'cdp_data'};
    $self->{'errmsg'} = '';
    $self->_set_empty(1);
    return;
}




=head2 create

 $rrd->create({step => 300,
               start => time(),
               ds => [{name => 'InOctets',
                       type=> 'COUNTER',
                       heartbeat => 600},
                      {name => 'OutOctets',
                       type => 'COUNTER',
                       heartbeat => 600},
                      {name => 'Load',
                       type => 'GAUGE',
                       heartbeat => 800,
                       min => 0,
                       max => 255}],
               rra => [{cf => 'AVERAGE',
                        xff => 0.5,
                        steps => 1,
                        rows => 2016},
                       {cf => 'AVERAGE',
                        xff => 0.25,
                        steps => 12,
                        rows => 768},
                       {cf => 'MAX',
                        xff => 0.25,
                        steps => 12,
                        rows => 768}]});

The method initializes the RRD::Tweak object with new RRD data as
specified by the arguments.  The arguments are presented in a hash
reference with the following keys and values: C<step>, defining the
minumum RRA resolution (default is 300 seconds); C<start> in seconds
from epoch (default is "time() - 10"); C<ds> pointing to an array that
defines the datasources; C<rra> pointing to an array with RRA
definitions.

C<start> and C<lastupdate> are synonyms.

Each datasource definition is a hash with the following arguments:
C<name>, C<type>, C<heartbeat>, C<min> (default: "nan"), C<max>
(default: "nan"). The COMPUTE datasource type is currently not supported.

Each RRA definition is a hash with arguments: C<cf> defines the
consolidation function; C<steps> defines how many minimal steps are
aggregated by this RRA; C<rows> defines the size of the RRA.

For AVERAGE, MIN, MAX, and LAST consolidation functions, C<xff> is required.

The a subset of the following attributes is required for each RRA that
is related to the Holt-Winters Forecasting: C<hw_alpha>, C<hw_beta>,
C<dependent_rra_idx>, C<dependent_rra_idx>, C<seasonal_gamma>,
C<seasonal_smooth_idx>, C<delta_pos>, C<delta_neg>, C<window_len>,
C<failure_threshold>, C<dependent_rra_idx>. Also C<smoothing_window> is
supported for RRD files of version 4.

See also I<rrdcreate> manual page of RRDTool for more details.

=cut


sub create {
    my $self = shift;
    my $arg = shift;

    if( not $self->is_empty() ) {
        croak('create() requies an empty RRD::Tweak object');
    }

    if( ref($arg) ne 'HASH' ) {
        croak('create() requies a hashref as argument');
    }

    if( ref($arg->{'ds'}) ne 'ARRAY' ) {
        croak('create() requires "ds" array in the argument');
    }

    my $n_ds = scalar(@{$arg->{'ds'}});
    if( $n_ds == 0 ) {
        croak('create(): "ds" is an empty array');
    }

    if( ref($arg->{rra}) ne 'ARRAY' ) {
        croak('create() requires "rra" array in the argument');
    }

    my $n_rra = scalar(@{$arg->{'rra'}});
    if( $n_rra == 0 ) {
        croak('create(): "rra" is an empty array');
    }

    my $pdp_step = $arg->{'step'};
    $pdp_step = 300 unless defined($pdp_step);
    $self->{'pdp_step'} = $pdp_step;

    my $last_up = $arg->{'start'};
    if( not defined($last_up) ) {
        $last_up = $arg->{'lastupdate'};
    }
    elsif( defined($arg->{'lastupdate'}) ) {
        croak('create(): both "start" and "lastupdate" are defined');
    }

    $last_up = (time() - 10) unless defined($last_up);
    $self->{'last_up'} = $last_up;

    $self->{'ds'} = [];
    $self->{'rra'} = [];
    $self->{'cdp_prep'} = [];
    $self->{'cdp_data'} = [];

    # process DS definitions
    for( my $ds=0; $ds < $n_ds; $ds++ ) {
        my $r = $arg->{'ds'}[$ds];
        if( ref($r) ne 'HASH' ) {
            croak('create(): $arg->{ds}[' . $ds .
                  '] is not a HASH');
        }

        $self->add_ds($r);
    }

    # process RRA definitions
    for( my $rra=0; $rra < $n_rra; $rra++) {
        my $r = $arg->{'rra'}[$rra];
        if( ref($r) ne 'HASH' ) {
            croak('create(): $arg->{rra}[' . $rra .
                  '] is not a HASH');
        }

        $self->add_rra($r);
    }

    $self->_set_empty(0);
    return;
}



# For a newly created RRA, this method
# populates $self->{'rra'}[$rra]->{'cdp_prep_defaults'}
# see details in rrd_create.c

sub _default_cdp_prep_attributes {
    my $self = shift;
    my $rra = shift;

    my $cf = $self->{'rra'}[$rra]->{'cf'};

    my $cdp_prep_attr = {};

    if( grep {$cf eq $_} qw/AVERAGE MIN MAX LAST/ ) {
        my $pdp_step = $self->{'pdp_step'};
        my $last_up = $self->{'last_up'};
        my $pdp_per_row = $self->{'rra'}[$rra]->{'pdp_per_row'};
        my $unknown_sec = $last_up % $pdp_step;

        $cdp_prep_attr->{'value'} = 'nan';
        $cdp_prep_attr->{'unknown_datapoints'} =
            (($last_up - $unknown_sec) % ($pdp_step * $pdp_per_row)) /
                $pdp_step;
    }
    elsif( grep {$cf eq $_} qw/HWPREDICT MHWPREDICT/ ) {
        $cdp_prep_attr->{'intercept'} = 'nan';
        $cdp_prep_attr->{'last_intercept'} = 'nan';
        $cdp_prep_attr->{'slope'} = 'nan';
        $cdp_prep_attr->{'last_slope'} = 'nan';
        $cdp_prep_attr->{'null_count'} = 1;
        $cdp_prep_attr->{'last_null_count'} = 1;
    }
    elsif( grep {$cf eq $_} qw/SEASONAL DEVSEASONAL/ ) {
        $cdp_prep_attr->{'seasonal'} = 'nan';
        $cdp_prep_attr->{'last_seasonal'} = 'nan';
        $cdp_prep_attr->{'init_flag'} = 1;
    }
    elsif( $cf eq 'FAILURES' ) {
        my $history = [];
        my $window_len = $self->{'rra'}[$rra]->{'window_len'};
        for( my $i=0; $i < $window_len; $i++ ) {
            push(@{$history}, 0);
        }
        $cdp_prep_attr->{'history'} = $history;
    }

    $self->{'rra'}[$rra]->{'cdp_prep_defaults'} = $cdp_prep_attr;
    return;
}


sub _validate_ds_name {
    my $self = shift;
    my $ds_name = shift;

    if( length($ds_name) > 19 ) {
        croak('DS name is too long: "' . $ds_name . '"');
    }

    if( $ds_name !~ /^[0-9a-zA-Z_-]+$/o ) {
        croak('DS has invalid characters: "' . $ds_name . '"');
    }
    return;
}


# check name uniqueness
sub _check_unique_ds_name {
    my $self = shift;
    my $ds_name = shift;

    foreach my $ds_def (@{$self->{'ds'}}) {
        if( $ds_name eq $ds_def->{'name'} ) {
            croak('A DS named "' . $ds_name .
                  '" already exists in this RRD::Tweak object');
        }
    }
    return;
}



=head2 add_ds

 $rrd->add_ds({name => 'InOctets',
               type=> 'COUNTER',
               heartbeat => 600});

The method takes a hash reference as an argument and extends the
RRD::Tweak object by adding a new datasource. The new datasource is
appended to the array of other datasources. The name should be unique,
otherwise the method croaks. The hash keys and values are the same as
the DS attributes in create() method.

add_ds() should only be called on an RRD::Tweak object with some data in
it. The data can be initialized by create() or load_file().

=cut

sub add_ds {
    my $self = shift;
    my $arg = shift;

    if( ref($arg) ne 'HASH' ) {
        croak('add_ds() requies a hashref as argument');
    }

    if( ref($self->{'ds'}) ne 'ARRAY' or
        ref($self->{'rra'}) ne 'ARRAY' or
        ref($self->{'cdp_prep'}) ne 'ARRAY' or
        ref($self->{'cdp_data'}) ne 'ARRAY' ) {
        croak('add_ds() is called on an unitialized RRD::Tweak object');
    }

    my $ds_attr = {};

    foreach my $key ('name', 'type') {
        if( not defined($arg->{$key}) ) {
            croak('add_ds(): $arg->{' . $key . '} is undefined');
        }

        if( $arg->{$key} eq '' ) {
            croak('add_ds(): $arg->{' . $key . '} is empty');
        }

        $ds_attr->{$key} = $arg->{$key};
    }

    $self->_validate_ds_name($arg->{'name'});
    $self->_check_unique_ds_name($arg->{'name'});

    if( not $valid_ds_types{$arg->{'type'}} ) {
        croak('add_ds(): $arg->{type} has invalid value: "' .
              $arg->{'type'} . '"');
    }

    if( $arg->{'type'} eq 'COMPUTE' ) {
        croak('add_ds(): DS type COMPUTE is currently unsupported');
    }
    else {
        my $hb = $arg->{'heartbeat'};
        if( not defined($hb) ) {
            croak('add_ds(): $arg->{heartbeat} is undefined');
        }
        $ds_attr->{'hb'} = int($hb);

        foreach my $key ('min', 'max') {
            my $val = $arg->{$key};
            if( defined($val) ) {
                if( $val eq 'U' ) {
                    $val = 'nan';
                }
            }
            else {
                $val = 'nan';
            }

            $ds_attr->{$key} = $val;
        }
    }

    # Values as defined in rrd_create.c
    $ds_attr->{'last_ds'} = 'U';
    $ds_attr->{'scratch_value'} = '0.0';
    $ds_attr->{'unknown_sec'} = $self->{'last_up'} % $self->{'pdp_step'};

    # add to the list of DS definitions
    push(@{$self->{'ds'}}, $ds_attr);

    # update cdp_prep

    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {
        my $cdp_prep_attr = $self->{'rra'}[$rra]->{'cdp_prep_defaults'};
        if( not defined($cdp_prep_attr) ) {
            croak('add_ds(): $self->{rra}[' . $rra .
                  ']->{cdp_prep_defaults} is undefined');
        }

        # duplicate cdp_prep attributes for the new DS
        my $attr = {};
        while(my($key, $value) = each %{$cdp_prep_attr}) {
            $attr->{$key} = $value;
        }

        # if this is the first DS, $self->{'cdp_prep'}[$rra] is
        # not initialized yet
        if( not defined($self->{'cdp_prep'}[$rra]) ) {
            $self->{'cdp_prep'}[$rra] = [];
        }

        push(@{$self->{'cdp_prep'}[$rra]}, $attr);
    }

    # update cdp_data
    for( my $rra=0; $rra < $n_rra; $rra++) {
        my $rra_data = $self->{'cdp_data'}[$rra];
        my $rra_len = scalar(@{$rra_data});

        for( my $row=0; $row < $rra_len; $row++ ) {
            push(@{$rra_data->[$row]}, 'nan');
        }
    }

    return;
}




=head2 del_ds

 $rrd->del_ds($ds_index);

The method removes a datasource from a given index. The indexing starts
from 0.

=cut

sub del_ds {
    my $self = shift;
    my $del_ds_index = shift;

    my $n_ds = scalar(@{$self->{'ds'}});

    if( $del_ds_index < 0 or $del_ds_index >= $n_ds ) {
        croak('del_ds(): DS index is outside of allowed range: ' .
              $del_ds_index);
    }

    splice(@{$self->{'ds'}}, $del_ds_index, 1);

    # update cdp_prep and cdp_data
    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {

        splice(@{$self->{'cdp_prep'}[$rra]}, $del_ds_index, 1);

        my $rra_data = $self->{'cdp_data'}[$rra];
        my $rra_len = scalar(@{$rra_data});

        for( my $row=0; $row < $rra_len; $row++ ) {
            splice(@{$rra_data->[$row]}, $del_ds_index, 1);
        }
    }

    return;
}



=head2 modify_ds

 $rrd->modify_ds($ds_index, {heartbeat => 700});

The method takes the DS index and a hash reference with DS parameters
that need to be modified. All DS parameters described for the create()
method are supported.

=cut

sub modify_ds {
    my $self = shift;
    my $mod_ds_index = shift;
    my $arg = shift;

    my $n_ds = scalar(@{$self->{'ds'}});

    if( $mod_ds_index < 0 or $mod_ds_index >= $n_ds ) {
        croak('modify_ds(): DS index is outside of allowed range: ' .
              $mod_ds_index);
    }

    my $ds_attr = $self->{'ds'}[$mod_ds_index];

    if( exists $arg->{'name'} and
        $arg->{'name'} ne $ds_attr->{'name'} )
    {
        $self->_validate_ds_name($arg->{'name'});
        $self->_check_unique_ds_name($arg->{'name'});
        $ds_attr->{'name'} = $arg->{'name'};
    }

    if( exists($arg->{'type'}) and
        $arg->{'type'} ne $ds_attr->{'type'} )
    {
        if( not $valid_ds_types{$arg->{'type'}} ) {
            croak('modify_ds(): $arg->{type} has invalid value: "' .
                  $arg->{'type'} . '"');
        }

        if( $arg->{'type'} eq 'COMPUTE' ) {
            croak('modify_ds(): DS type COMPUTE is currently unsupported');
        }

        $ds_attr->{'type'} = $arg->{'type'};
    }

    # when we start supporting COMPUTE datasources, need also to process
    # the type changing more correctly: a new type may require new
    # attributes.

    if( $ds_attr->{'type'} ne 'COMPUTE' ) {

        if( exists($arg->{'heartbeat'}) and
            int($arg->{'heartbeat'}) != $ds_attr->{'hb'} ) {
            $ds_attr->{'hb'} = int($arg->{'heartbeat'});
        }

        foreach my $key ('min', 'max') {
            my $val = $arg->{$key};
            if( defined($val) ) {
                if( $val eq 'U' ) {
                    $val = 'nan';
                }

                if( $val =~ /^-?nan$/i ) {
                    if( $ds_attr->{$key} !~ /^-?nan$/io ) {
                        $ds_attr->{$key} = 'nan';
                    }
                }
                elsif( $val != $ds_attr->{$key} ) {
                    $ds_attr->{$key} = $val;
                }
            }
        }
    }
    return;
}







=head2 add_rra

 $rrd->add_rra({cf => 'AVERAGE',
                xff => 0.25,
                steps => 12,
                rows => 768});

The method takes a hash reference as an argument and extends the
RRD::Tweak object by adding a new round-robin array. The new RRA is
appended to the list of other RRA's. The hash keys and values are the
same as the RRA attributes in create() method. If an RRA with the same
C<cf> and C<steps> already exists in the RRD::Tweak object, the method
croaks with an error.

add_rra() should only be called on an RRD::Tweak object with some data in
it. The data can be initialized by create() or load_file().

=cut

sub add_rra {
    my $self = shift;
    my $arg = shift;

    if( ref($arg) ne 'HASH' ) {
        croak('add_rra() requies a hashref as argument');
    }

    if( ref($self->{'ds'}) ne 'ARRAY' or
        ref($self->{'rra'}) ne 'ARRAY' or
        ref($self->{'cdp_prep'}) ne 'ARRAY' or
        ref($self->{'cdp_data'}) ne 'ARRAY' ) {
        croak('add_rra() is called on an unitialized RRD::Tweak object');
    }

    my $rradef_attr = {};

    my $cf = $arg->{cf};
    if( not defined($cf) ) {
        croak('add_rra(): $arg->{cf} is undefined');
    }

    if( not defined($cf_names_and_rra_attributes{$cf}) ) {
        $self->_set_errmsg('add_rra(): Unknown CF name in ' . '$arg->{cf}');
    }
    $rradef_attr->{'cf'} = $cf;

    my $pdp_per_row = $arg->{'steps'};
    if( not defined($pdp_per_row) or int($pdp_per_row) <= 0 ) {
        croak('add_rra(): $arg->{steps} is not a positive integer');
    }
    $rradef_attr->{'pdp_per_row'} = $pdp_per_row;

    # check uniqueness of this RRA
    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {
        if( $self->{'rra'}[$rra]->{'cf'} eq $cf and
            $self->{'rra'}[$rra]->{'pdp_per_row'} == $pdp_per_row ) {
            croak('add_rra(): an RRA with CF=' . $cf .
                  ' and steps=' . $pdp_per_row . ' already exists');
        }
    }

    my $rra_len = $arg->{'rows'};
    if( not defined($rra_len) or int($rra_len) <= 0 ) {
        croak('add_rra(): $arg->{rows} is not a positive integer');
    }

    foreach my $key (@{$cf_names_and_rra_attributes{$cf}}) {
        if( not defined($arg->{$key}) ) {
            croak('add_rra(): $arg->{' . $key . '} is undefined');
        }
        $rradef_attr->{$key} = $arg->{$key};
    }

    my $new_rra = $n_rra;
    push(@{$self->{'rra'}}, $rradef_attr);

    # update cdp_data

    my $n_ds = scalar(@{$self->{'ds'}});
    my $rra_data = [];
    for( my $row=0; $row < $rra_len; $row++ ) {
        my $row_data = [];
        for( my $ds=0; $ds < $n_ds; $ds++ ) {
            push(@{$row_data}, 'nan');
        }
        push(@{$rra_data}, $row_data);
    }

    push(@{$self->{'cdp_data'}}, $rra_data);

    # populate cdp_prep_defaults for the newly created RRA

    $self->_default_cdp_prep_attributes($new_rra);

    # create cdp_prep entries

    my $cdp_prep_attr = $self->{'rra'}[$new_rra]->{'cdp_prep_defaults'};
    my $rra_cdp_prep = [];

    for( my $ds=0; $ds < $n_ds; $ds++ ) {
        my $attr = {};
        while(my($key, $value) = each %{$cdp_prep_attr}) {
            $attr->{$key} = $value;
        }
        push(@{$rra_cdp_prep}, $attr);
    }

    push(@{$self->{'cdp_prep'}}, $rra_cdp_prep);

    # try to derive the data rows where possible
    $self->_populate_rra($n_rra);

    return;
}



=head2 del_rra

 $rrd->del_rra($rra_index);

The method removes a round-robin array from a given index. The indexing
starts from 0.

=cut

sub del_rra {
    my $self = shift;
    my $del_rra_index = shift;

    my $n_rra = scalar(@{$self->{'rra'}});

    if( $del_rra_index < 0 or $del_rra_index >= $n_rra ) {
        croak('del_rra(): RRA index is outside of allowed range: ' .
              $del_rra_index);
    }

    # Holt-Winters RRA refer to other array indices, so we adjust the
    # references which are affected by this deletion
    for( my $rra = $del_rra_index+1; $rra < $n_rra; $rra++) {
        if( $hw_rra_name{$self->{'rra'}[$rra]{cf}} ) {
            if( $self->{'rra'}[$rra]{'dependent_rra_idx'} >= $del_rra_index ) {
                $self->{'rra'}[$rra]{'dependent_rra_idx'}--;
            }
        }
    }

    splice(@{$self->{'rra'}}, $del_rra_index, 1);
    splice(@{$self->{'cdp_prep'}}, $del_rra_index, 1);
    splice(@{$self->{'cdp_data'}}, $del_rra_index, 1);
    return;
}



=head2 modify_rra

 $rrd->modify_rra($rra_index, {xff => 0.40});

The method takes the RRA index and a hash reference with RRA parameters
that need to be modified. The following parameters are supported:

=over 4

=item * xff

Modifying of XFF does not change any data in the array, and only affects
future updates.

=item * rows

If the number of rows is increasing, the existing data stays intact, and
the new data elements which fall into the extended time range are set to
NaN.

If the number of rows is decreasing, the oldest data elements are
discarded.

=back

=cut

sub modify_rra {
    my $self = shift;
    my $mod_rra_index = shift;
    my $arg = shift;

    my $n_rra = scalar(@{$self->{'rra'}});

    if( $mod_rra_index < 0 or $mod_rra_index >= $n_rra ) {
        croak('modify_rra(): RRA index is outside of allowed range: ' .
              $mod_rra_index);
    }

    my $r = $self->{'rra'}[$mod_rra_index];
    my $cf = $r->{cf};

    if( exists $arg->{'xff'} ) {
        if( not exists $r->{'xff'} )
        {
            croak('modify_rra(): the RRA ' . $mod_rra_index . ' has CF: ' .
                  $cf . ' and it does not support xff attribute');
        }

        if( $arg->{'xff'} != $r->{'xff'} )
        {
            $r->{'xff'} = $arg->{'xff'};
        }
    }

    if( exists $arg->{'rows'} ) {
        if( int($arg->{'rows'}) <= 0 ) {
            croak('modify_rra(): $arg->{rows} is not a positive integer');
        }

        my $rra_data = $self->{'cdp_data'}[$mod_rra_index];
        my $rra_len = scalar(@{$rra_data});

        if( $arg->{'rows'} < $rra_len ) {

            # shrink the RRA: remove the array head
            splice(@{$rra_data}, 0, ($rra_len - $arg->{'rows'}));
        }
        elsif( $arg->{'rows'} > $rra_len ) {

            # grow the RRA: add NAN values at the head

            my $rows_to_add = $arg->{'rows'} - $rra_len;
            my $n_ds = scalar(@{$self->{'ds'}});
            my $prepend_rra_data = [];

            for( my $i=0; $i < $rows_to_add; $i++ ) {
                my $row_data = [];
                for( my $ds=0; $ds < $n_ds; $ds++ ) {
                    push(@{$row_data}, 'nan');
                }
                push(@{$prepend_rra_data}, $row_data);
            }

            unshift(@{$rra_data}, @{$prepend_rra_data});

            # try to derive the data rows where possible
            $self->_populate_rra($mod_rra_index);
        }
    }
    return;
}









=head2 info

 my $result = $rrd->info();

The method returns a hash reference with all available information as
described for the create() method. It always returns a "lastupdate"
value in the returned attributes.

=cut

sub info {
    my $self = shift;

    my $ret ={ 'step' => $self->{'pdp_step'},
               'lastupdate' => $self->{'last_up'} };

    my $ds_info = [];
    my $n_ds = scalar(@{$self->{'ds'}});

    for( my $ds=0; $ds < $n_ds; $ds++ ) {

        my $ds_attr = $self->{'ds'}[$ds];
        my $r = {};

        foreach my $key ('name', 'type') {
            $r->{$key} = $ds_attr->{$key};
        }

        if( $r->{'type'} ne 'COMPUTE' ) {
            $r->{'heartbeat'} = $ds_attr->{'hb'};
            foreach my $key ('min', 'max') {
                $r->{$key} = $ds_attr->{$key};
            }
        }
        else {
            $r->{'rpn'} = $ds_attr->{'rpn'};
        }

        push(@{$ds_info}, $r);
    }

    $ret->{'ds'} = $ds_info;

    my $rra_info = [];
    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {

        my $rra_attr = $self->{'rra'}[$rra];
        my $r = {};

        $r->{'cf'} = $rra_attr->{'cf'};
        $r->{'steps'} = $rra_attr->{'pdp_per_row'};
        $r->{'rows'} = scalar(@{$self->{'cdp_data'}[$rra]});

        foreach my $key (@{$cf_names_and_rra_attributes{$r->{'cf'}}}) {
            $r->{$key} = $rra_attr->{$key};
        }

        push(@{$rra_info}, $r);
    }

    $ret->{'rra'} = $rra_info;

    return $ret;
}



=head2 has_hwpredict

 my $hw_status = $rrd->has_hwpredict();

The method returns true if any of Holt-Winters RRA exist in the RRD file.

=cut

sub has_hwpredict {
    my $self = shift;
    my $ds_index = shift;

    my $n_rra = scalar(@{$self->{'rra'}});
    for( my $rra=0; $rra < $n_rra; $rra++) {
        if( $hw_rra_name{$self->{'rra'}[$rra]{'cf'}} ) {
            return 1;
        }
    }
    return 0;
}




=head2 ds_descr

 $rrd->ds_descr($ds_index);

The method returns the DS description string as described in
I<rrdcreate> manual page (e.g. "DS:InOctets:COUNTER:700:0:U").

=cut

sub ds_descr {
    my $self = shift;
    my $ds_index = shift;

    my $n_ds = scalar(@{$self->{'ds'}});

    if( $ds_index < 0 or $ds_index >= $n_ds ) {
        croak('ds_descr(): DS index is outside of allowed range: ' .
              $ds_index);
    }

    my $ds_attr = $self->{'ds'}[$ds_index];

    my $ret = 'DS:' . $ds_attr->{'name'} . ':' . $ds_attr->{'type'};

    if( $ds_attr->{'type'} ne 'COMPUTE' ) {
        $ret .= ':' . $ds_attr->{'hb'};

        foreach my $key ('min', 'max') {
            if( $ds_attr->{$key} !~ /^-?nan$/io ) {
                $ret .= ':' . $ds_attr->{$key};
            }
            else {
                $ret .= ':U';
            }
        }
    }
    else {
        croak('ds_descr(): DS type COMPUTE is currently unsupported');
    }

    return $ret;
}





=head2 rra_descr

 $rrd->rra_descr($rra_index);

The method returns a string description of a round-robin array, as specified in
I<rrdcreate> manual page (e.g. "RRA:AVERAGE:0.25:12:365").

The returned string for Holt-Winters prediction RRA delivers only
partial information.

=cut

sub rra_descr {
    my $self = shift;
    my $rra_index = shift;

    my $n_rra = scalar(@{$self->{'rra'}});

    if( $rra_index < 0 or $rra_index >= $n_rra ) {
        croak('rra_descr(): RRA index is outside of allowed range: ' .
              $rra_index);
    }

    my $r = $self->{'rra'}[$rra_index];
    my $cf = $r->{cf};
    my $rra_len = scalar(@{$self->{'cdp_data'}[$rra_index]});
    my $steps = $r->{'pdp_per_row'};

    my $ret = 'RRA:' . $cf;

    if( not $hw_rra_name{$cf} ) {
        $ret .= ':' . $r->{'xff'} . ':' . $steps . ':' . $rra_len;
    }

    return $ret;
}


##
##  Private methods
###################

# after an RRA is created or extended, this method tries to derive the
# values from other RRA's

sub _populate_rra
{
    my $self = shift;
    my $pop_rra_index = shift;

    my $rra_data = $self->{'cdp_data'}[$pop_rra_index];
    my $rra_len = scalar(@{$rra_data});
    my $cf = $self->{'rra'}[$pop_rra_index]{'cf'};
    my $pdp_per_row = $self->{'rra'}[$pop_rra_index]{'pdp_per_row'};
    my $xff = $self->{'rra'}[$pop_rra_index]{'xff'};

    my $n_rra = scalar(@{$self->{'rra'}});
    my $n_ds = scalar(@{$self->{'ds'}});

    if( $n_rra == 1 ) {
        # this is the only RRA, so there's no data to derive from
        return;
    }

    if( $hw_rra_name{$cf} ) {
        # this is a Holt-Winters array, and we don't know how to populate it
        return;
    }

    my %rraidx_per_steps;
    for( my $rra=0; $rra < $n_rra; $rra++) {
        if( $rra != $pop_rra_index ) {
            my $r = $self->{'rra'}[$rra];
            my $steps = $r->{'pdp_per_row'};

            if( ($r->{'cf'} eq $cf) or
                ($r->{'cf'} eq 'AVERAGE' and $steps == 1) ) {
                $rraidx_per_steps{$steps} = $rra;
            }
        }
    }

    if( scalar(keys %rraidx_per_steps) == 0 ) {
        # we could not find any RRA to derive the data from
        return;
    }

    # arrange the RRA indexes from most granular to less granular
    my @rraidx_ascending_steps;
    foreach my $steps (sort {$a <=> $b} keys %rraidx_per_steps) {
        push( @rraidx_ascending_steps, $rraidx_per_steps{$steps} );
    }

    for ( my $row=0; $row < $rra_len; $row++ ) {

        # check if we have any NANs in this row
        my @nan_ds;
        for ( my $ds=0; $ds < $n_ds; $ds++ ) {
            if( $rra_data->[$row][$ds] =~ /nan/io ) {
                push(@nan_ds, $ds);
            }
        }

        if( not scalar(@nan_ds) ) {
            # this row has all values already defined, skip it from population
            next;
        }

        # negative integers in (pdp_step)*seconds
        my $row_start_time = ($row - $rra_len) * $pdp_per_row;
        my $row_end_time = $row_start_time + $pdp_per_row;

        foreach my $rra ( @rraidx_ascending_steps ) {
            my $r = $self->{'rra'}[$rra];
            my $src_steps = $r->{'pdp_per_row'};
            my $src_data = $self->{'cdp_data'}[$rra];
            my $src_len = scalar(@{$src_data});

            if ( $row_start_time + $src_len * $src_steps < 0 ) {
                # our new row is outside of the array boundaries
                next;
            }

            my $n_src_rows = int($pdp_per_row/$src_steps);
            if ( $n_src_rows == 0 ) {
                # the source row is less granular than ours --
                # then we take just one value
                $n_src_rows = 1;
            }

            # grab the values from source rows
            my @known_values = ();
            my @unknown_values = ();
            my $start_src_row = int($src_len +
                                    $row_start_time/$src_steps);
            foreach my $ds (@nan_ds) {
                my $known_val_per_ds = [];
                my $unknown_val_per_ds = 0;

                for ( my $src_row_pos = 0; $src_row_pos < $n_src_rows;
                      $src_row_pos++ ) {
                    my $src_row = $start_src_row + $src_row_pos;
                    my $data_element = $src_data->[$src_row][$ds];
                    if ( $data_element =~ /nan/io ) {
                        $unknown_val_per_ds++;
                    } else {
                        push(@{$known_val_per_ds}, $data_element);
                    }
                }

                $known_values[$ds] = $known_val_per_ds;
                $unknown_values[$ds] = $unknown_val_per_ds;
            }

            # if the number of knowns is good enough, take the value
            foreach my $ds (@nan_ds) {
                if ( $unknown_values[$ds] * 1.0 / $n_src_rows <= $xff ) {

                    # now calculate the new value from knowns
                    if ( $cf eq 'AVERAGE' ) {
                        my $val = 0;
                        map {$val += $_} @{$known_values[$ds]};
                        $rra_data->[$row][$ds] =
                            $val / scalar(@{$known_values[$ds]});
                    } elsif ( $cf eq 'MIN' ) {
                        my $val = '+inf';
                        map {if($_ < $val){$val = $_} }
                            @{$known_values[$ds]};
                        $rra_data->[$row][$ds] = $val;
                    } elsif ( $cf eq 'MAX' ) {
                        my $val = '-inf';
                        map {if($_ > $val){$val = $_} }
                            @{$known_values[$ds]};
                        $rra_data->[$row][$ds] = $val;
                    } elsif ( $cf eq 'LAST' ) {
                        my $val = pop @{$known_values[$ds]};
                        $rra_data->[$row][$ds] = $val;
                    }
                }
            }

            # we've done all we could, so finish trying other RRA's
            last;
        }
    }

    return;
}



=head1 AUTHOR

Stanislav Sinyagin, C<< <ssinyagin at k-open.com> >>


=head1 ACKNOWLEDGEMENTS

This development has been sponsored by Nexellent AG and UPC Cablecom AG,
Switzerland.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislav Sinyagin.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
