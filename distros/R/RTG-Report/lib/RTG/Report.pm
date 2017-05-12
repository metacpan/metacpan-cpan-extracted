package RTG::Report;

use strict;
use warnings;

our $VERSION = '1.17';

# built-in modules
use English qw( -no_match_vars );

sub new {
    my ( $class, $name ) = @_;
    my $self = { name => $name };
    bless( $self, $class );
    return $self;
};

sub formatted_header {

    my $self = shift;
    my ($report_units, $no_rates, $utilization, $no_95th) = @_;

    my $unit = $report_units == 1000       ? 'Kbytes'
             : $report_units == 1000000    ? 'Mbytes'
             : $report_units == 1000000000 ? 'Gbytes'
             : '?bytes';

    my @headers = ( 
        'Pod', 'RID', 'Router',
        'IID', 'Connection/Interface', 'Speed', 'Description',
        "In $unit",
        "Out $unit",
    );

    # redefine $unit b/c every use of unit below here is rate
    $unit = $report_units == 1000       ? 'Kbit/s'
          : $report_units == 1000000    ? 'Mbit/s'
          : $report_units == 1000000000 ? 'Gbit/s'
          : '?bit/s';

    if ( !$no_rates ) {
        push @headers, 
            "Avg In $unit",
            "Avg Out $unit",
            "Max In $unit",
            "Max Out $unit";
    };

    if ( $utilization ) {
        push @headers, 
            'Util Avg In %',
            'Util Avg Out %',
            'Util Max In %',
            'Util Max Out %';
    }

    if ( !$no_95th ) { push @headers, "95th In $unit", "95th Out $unit"; };

    push @headers, 'Start Date', 'End Date';

    return @headers;
};

sub get_interface_stats {

    my $self     = shift;
    my $args_ref = shift;
    
    my $db       = $args_ref->{'db'};
    my $table    = $args_ref->{'table'};
    my $range    = $args_ref->{'range'};
    my $iid      = $args_ref->{'iid'};
    my $debug    = $args_ref->{'debug'};

    my $query="SELECT counter, UNIX_TIMESTAMP(dtime) AS unix_time 
               FROM $table
                 WHERE $range
                 AND id=$iid";
#                   ORDER BY dtime";   # sort in perl, it is faster

    my $db_err = 0;
    my @rows = $db->query($query)->hashes or $db_err++;
    if ( $db_err ) {
        print "no results found $table for id=$iid from $range\n" if $debug;
        #warn $db->error;
        warn "query: $query\n" if $debug;
        return { rate_peak=>0,rate_avg=>0,rate_95th=>0,bytes=>0};
    };

    my ($bytes_total, $last_timestamp, $num_rate_samples, 
        $rate_avg_total, $rate_95th, $rate_avg, $rate_peak, @rate );
    $bytes_total = $rate_peak = $rate_avg = $rate_95th = $last_timestamp = 0;

    foreach my $row ( sort { $a->{'unix_time'} <=> $b->{'unix_time'} } @rows ) {

        my $counter     = $row->{'counter'};
        my $timestamp   = $row->{'unix_time'};

        $self->timestamp_sanity($last_timestamp, $timestamp, $table, $iid, $counter);

        if ( $timestamp == $last_timestamp ) {
            #warn "** duplicate timestamps: ".
            #   "table: $table id: $iid count: $counter ts: $timestamp lts: $last_timestamp\n";
            $bytes_total += $counter;
            next;
        };

        $bytes_total += $counter;

        # to calculate rates, we must have an interval. Skip the first row of
        # data since we have no start time to calculate against.
        if ( $last_timestamp == 0 ) { $last_timestamp = $timestamp; next; };

        $num_rate_samples++;
        my $counter_bits = $counter * 8;              # convert octets/bytes to bits

        my $interval = $timestamp - $last_timestamp;  # the interval is not fixed
        my $rate_cur = $counter_bits/$interval;       # calc the rate of this sample
        push @rate, $rate_cur;
        $rate_avg_total += $rate_cur;
        if ($rate_cur > $rate_peak) { $rate_peak = $rate_cur; }  # calc max rate

        $last_timestamp = $timestamp;
    }
    warn "There were $num_rate_samples rate samples in the period.\n" if $debug;

    # calculate 95th percentile
    if ( $num_rate_samples ) {
        @rate = sort { $a <=> $b } @rate;
        $rate_95th = @rate[ int( $num_rate_samples * 0.95 + 0.5) ];
    };

    # calculate average rate
    if ( $num_rate_samples && $num_rate_samples !=0 ) {
        $rate_avg = sprintf("%.0f", $rate_avg_total/$num_rate_samples);
    };

    return {
        bytes     => $bytes_total,
        rate_peak => sprintf("%.0f", $rate_peak),
        rate_avg  => $rate_avg,
        rate_95th => $rate_95th,
    };
}

sub get_the_date {

    my ($self, $bump) = @_;

    my $time = time;
#    warn "time: " . time . "\n" if $debug;

    $bump = $bump ? $bump * 86400 : 0;
    my $offset_time = time - $bump;
#    warn "selected time: $offset_time\n" if $debug;

    # load Date::Format to get the time2str function
    eval { require Date::Format };
    if ( ! $EVAL_ERROR) {

        my $ss = Date::Format::time2str( "%S", ( $offset_time ) );
        my $mn = Date::Format::time2str( "%M", ( $offset_time ) );
        my $hh = Date::Format::time2str( "%H", ( $offset_time ) );
        my $dd = Date::Format::time2str( "%d", ( $offset_time ) );
        my $mm = Date::Format::time2str( "%m", ( $offset_time ) );
        my $yy = Date::Format::time2str( "%Y", ( $offset_time ) );
        my $lm = Date::Format::time2str( "%m", ( $offset_time - 2592000 ) );

#        warn "get_the_date: $yy/$mm/$dd $hh:$mn\n" if $debug;
        return $dd, $mm, $yy, $lm, $hh, $mn, $ss;
    }

    die "Date::Format is not installed!\n";
}

sub is_arrayref {

    my ( $self, $should_be_arrayref, $debug ) = @_;

    my $error;

    return if ! defined $should_be_arrayref;

    eval {
        # simply accessing it will generate an exception.
        if ( $should_be_arrayref->[0] ) {
            print "is_arrayref is a arrayref!\n" if $debug;
        }
    };
    $@ ? return : return 1;
}

sub should_i_skip_it {

    my ($self, $if_desc, $if_name, $skip_desc, $skip_name) = @_;

#####  Due to use of Config::Std #####
# if one description is present in the config file, we get a string.
# If more than one is present, we get an arrayref

    if ( $skip_desc ) {
        if ( $self->is_arrayref($skip_desc) ) {
            foreach my $desc ( @$skip_desc ) {
                return 1 if ( $desc eq 'blank' && $if_desc eq '' );
                return 1 if ( $desc eq $if_desc );
            }
        }
        else {
            return 1 if ( $skip_desc eq 'blank' && $if_desc eq '' );
            return 1 if ( $skip_desc eq $if_desc );
        }
    };

    if ( $skip_name ) {
        if ( $self->is_arrayref($skip_name) ) {
            foreach my $name ( @$skip_name ) {
                return 1 if ( $name eq 'blank' && $if_name eq '' );
                return 1 if $if_name =~ /$name/i;
            }
        }
        else {
            return 1 if ( $skip_name eq 'blank' && $if_name eq '' );
            return 1 if ( $skip_name eq $if_name );
        }
    };
    return;
};

sub status {
    my ($self, $mess, $nocr, $debug) = @_;

    if ($debug) {
        print $mess;
        print "\n" unless $nocr;
    }
    return $nocr ? $mess : "$mess\n";
};

sub timestamp_sanity {

    my ($self, $last_timestamp, $timestamp, $table, $iid, $counter) = @_;

    # timestamps should never go backwards, we sorted them
    if ( $last_timestamp > $timestamp ) {
        print "* Bad Sample " .
            "table: $table id: $iid count: $counter ts: $timestamp lts: $last_timestamp\n";
        die "The last timestamp ($last_timestamp) is newer than the current one($timestamp)!\n";
    };

    if ( $timestamp - $last_timestamp < 0 ) {
        die "timestamp value ($timestamp) wandered into the forest alone! Report this error!\n";
    };

    if ( $counter < 0 ) {
        die "** Invalid Counter Value $counter\n" .
            "table: $table id: $iid count: $counter ts: $timestamp lts: $last_timestamp\n";
#       print "*** stmt: $query\n";
    } 

    return 1;
};


1;
__END__;

=head1 NAME

RTG::Report - RTG reporting and data processing utilities

=head1 VERSION

1.16

=head1 SYNOPSIS

Functions shared by the RTG::Report utilities.

=head1 FUNCTIONS

=head2 new

instantiate a new RTG::Report object

=head2 formatted_header

generates a CSV file header. The fields are dynamically generated based on the contents of rtgreport.conf.

=head2 get_interface_stats

This is the heart of RTGs data reporting. This function:

 * queries the SQL data store, fetching the interface counters for the selected
  interface during the specified reporting period. 
 * sorts the records cronologically
 * iterates over each record, performing calculations on the raw numbers
 * finally, calculating the 95th average rates for the period
 * returns a hashref with bytes transferred, peak rate, average rate, and 95th

=head2 get_the_date

returns an array with year, month, day, hours, min, and seconds as scalars

=head2 is_arrayref

tests is the argument passed in is an arrayref. Returns true or undef.

=head2 should_i_skip_it

Interfaces can be ignored based on their name or description. Great examples of interfaces  you might wan to ignore for reporting purposes would be VLAN or port-channel interfaces. This sub chooses which interfaces to ignore based on your settings in rtgreport.conf. 

=head2 status

prints status functions

=head2 timestamp_sanity

runs a few tests to make sure the data we are processing is consistent.

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Layered Technologies, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

