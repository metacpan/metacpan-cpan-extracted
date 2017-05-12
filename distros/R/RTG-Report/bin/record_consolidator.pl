#!perl
use strict;
use warnings;
 
# perl build-in modules
use English;
use Data::Dumper;

# perl modules from CPAN
use Config::Std { def_sep => '=' };
use Date::Calc qw/ Add_Delta_DHMS /;
use Date::Format;
use DBIx::Simple;

# Local modules
use lib "lib";
use RTG::Report;
my $reporter = RTG::Report->new();

###########  PROCESS MANAGEMENT  ###########
my $wanna_die = 0;            # dont die in the middle of db updates
$SIG{INT} = \&catch_signal;   # instead, catch signals and die cleanly
$SIG{QUIT} = \&catch_signal;

my $debug = 1;
###########   SITE CONFIGURATION  ###########
# Load named config file into specified hash...
read_config '/usr/local/etc/rtgreport.conf' => my %config;

my $db_user        = $config{DatabaseRW}{user};
my $db_pass        = $config{DatabaseRW}{pass};
my $dsn            = $config{DatabaseRW}{dsn};
my $prune_days     = $config{Pruning}{days};
my $prune_interval = $config{Pruning}{interval};
my $networks_ref   = $config{Networks}{network};

my %networks;
foreach ( @$networks_ref ) {
    my ($net, $db, $dc, $num) = $_ =~ /^\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*$/;
    $networks{$net} = { db=>$db, dc=>$dc, num=>$num };
};

###########     DATE VARIABLES    ###########
my ($dd, $mm, $yy, $lm, $hh, $mn, $ss) = get_the_date($prune_days);

my $prune_before_date = $yy . $mm . $dd . '000000';   # only prune records b4 this
#$prune_before_date = '20070401000000';               # manual override
print "earliest: $prune_before_date\n" if $debug;


my $db = DBIx::Simple->connect( $dsn, $db_user, $db_pass)   # connect to db
                or die "couldn't connect to mysql: $!\n";

my $printed_count;

### foreach database defined in %networks
foreach my $net (
    sort { $networks{$a}->{'num'} <=> $networks{$b}->{'num'} } keys %networks ) {

    my $db_name = $networks{$net}->{'db'};
    print "$net db is $db_name\n" if $debug;

    # get all of the interfaces
    my @interfaces = $db->query( 
        "SELECT id,rid FROM $db_name.interface" )->hashes;

    print "db $db_name has " . scalar @interfaces ." interfaces\n" if $debug;

    my %unique_table_list;

    print_header();
    foreach my $interface (@interfaces) {
        die "\n" if $wanna_die;

        foreach my $pruned_table ( prune_interface($db_name, $interface) ) { 
            $unique_table_list{$pruned_table} = 1;
            if ($printed_count % 15 == 0) {
                $printed_count++;
                print_header() 
            };
        };
    };

    foreach my $table ( keys %unique_table_list ) {
        print "\nOPTIMIZE TABLE $table";
        $db->query("OPTIMIZE TABLE $table") or warn "Couldn't optimize $table\n";
    };
    print "\n";
}

sub prune_interface {

    my ($db_name, $interface) = @_;

    my $iid = $interface->{'id'};
    my $rid = $interface->{'rid'};

# DEBUGGING / TESTING
#    return unless ($rid>44);
#    return unless ($iid==610);

    my %needs_optimize;
    foreach my $table ( get_table_names($db_name, $rid) ) {

        my $deletes = my $inserts = 0;

        foreach my $period ( get_periods_to_prune($table, $iid) ) {

            my $p_start = $period->{'start'};
            my $p_end   = $period->{'end'};
 
            # select all records for the period 
            my $query = "SELECT * FROM $table
                          WHERE dtime >= $p_start AND dtime < $p_end AND id=$iid";
            my @aggregate_recs = $db->query($query)->hashes;
            my $count = scalar @aggregate_recs;

            next if $count < 2;  # don't aggregate single records
            $needs_optimize{$table} = 1;

            my $counters_total = aggregate_counters(\@aggregate_recs);

            # insert aggregate record into the database.
            my $agg_time = plus_minutes($p_end, -1);
            my $insert_q = "INSERT INTO $table (id,counter,dtime) VALUES ($iid,$counters_total,$agg_time)";
#            print "$insert_q;\n" if $debug;
            my $db_err = 0;
            $db->query($insert_q) or $db_err++;

            # remove the individual records
            if ( !$db_err ) {                             # verify insertion
                $inserts++;
                foreach my $record ( @aggregate_recs ) {  
                    my $delete_q = "DELETE FROM $table WHERE dtime='" . $record->{'dtime'} . "' AND id=$iid AND counter=".$record->{'counter'};
                    #print "$delete_q;\n";
                    $db->query($delete_q) or $db_err++;
                    if ( !$db_err ) { $deletes++; };
                };
            };
        };

        my $compression = $inserts && $deletes ? int( 100-($inserts/$deletes*100) ) : 0;
        if ($compression) {
            printf "   %6i -> %4i = %2i", $deletes, $inserts, $compression;
            print '%';
            $printed_count++;
        };
        die "\n" if $wanna_die;
    };
    my @optimize_list;
    foreach my $table ( keys %needs_optimize ) {
        push @optimize_list, $table;
    };
    return @optimize_list;
};

sub plus_minutes {
    my $time = shift;
    my $minutes = shift;

    # Add_Delta_DHMS($year,$month,$day, $hour,$min,$sec,$Dd,$Dh,$Dm,$Ds);

    # incoming time format:  20070206105430
    return sprintf(
        "%04d%02d%02d%02d%02d%02d", 
            Add_Delta_DHMS(
                substr($time, 0,4),  # year
                substr($time, 4,2),  # month
                substr($time, 6,2),  # day
                substr($time, 8,2),  # hour
                substr($time, 10,2), # min
                substr($time, 12,2), # sec
                0,        # Dday
                0,        # Dhour
                $minutes, # Dmin
                0         # Dsec
            )
    );
};

sub aggregate_counters {
    my $records = shift;
    my $counter = 0;
    foreach my $record ( @$records ) { $counter += $record->{'counter'}; };
    return $counter;
}

sub catch_signal {
    my $signame = shift;
    $wanna_die++;
    print "\n\n\t\tcaught $signame signal, exiting gracefully...\n";
}

sub get_oldest_timestamp {

    my ($iid,$table) = @_;

    # find the record with the oldest date
    my $db_err;
    my $query = "SELECT dtime,UNIX_TIMESTAMP(dtime) AS unix_time
                 FROM $table
                    WHERE dtime<$prune_before_date
                    AND id=$iid
                    ORDER BY dtime
                    LIMIT 1";

    my @rows = $db->query($query)->hashes or $db_err++;
    if ($db_err) {
        #print "no results for $table id $iid\n";
        return;
    };

    # sort the rows in order of date/time
    #@rows = sort { $a->{'unix_time'} <=> $b->{'unix_time'} } @rows;

    # the first row will be the oldest
    return $rows[0]->{'dtime'};
};

sub get_periods_to_prune {

    my ($table, $iid) = @_;

    # format:  2007-02-06 10:54:30
    my $oldest_timestamp = get_oldest_timestamp($iid,$table);

    return if !$oldest_timestamp;  # print "oldest: $oldest_timestamp\n";

    # calculate the 1 hour period with the oldest data
    printf "\n  %-30s %-5i  %-22s", $table, $iid, $oldest_timestamp if $debug;
    my $start_time = get_start_from_dtime($oldest_timestamp);
    my $end_time   = plus_minutes($start_time, $prune_interval);

    return if ( $end_time > $prune_before_date );

    my @periods = ( {start=>$start_time, end=>$end_time} );
    my $periods;
    my %prune_todo;
    while ( $end_time < $prune_before_date ) {
        $periods++;
        $start_time = $end_time;
        $end_time   = plus_minutes($start_time, $prune_interval);

        my $prune_day = substr($start_time, 0, 8);
        if ( !defined $prune_todo{$prune_day} ) {
            my $prune_start = $prune_day . "000000";
            my $prune_end   = $prune_day . "235959";
            my $query = "SELECT COUNT(*) FROM $table 
                            WHERE dtime >= $prune_start AND dtime < $prune_end 
                            AND id=$iid";

            $db->query($query)->into(my $prune_matches);

            if    ( $prune_interval > 50 && $prune_matches > 30 )  { $prune_todo{$prune_day} = 1; }
            elsif ( $prune_interval > 10 && $prune_matches > 200 ) { $prune_todo{$prune_day} = 1; }
            else                                                   { $prune_todo{$prune_day} = 0; };
        };
        if ( $prune_todo{$prune_day} ) {
            push @periods, {start=>$start_time, end=>$end_time};
        };
    };
    printf "%5i ", $periods if $debug;
    return @periods;
};

sub get_start_from_dtime {
    my $dtime = shift;

    # dtime format:  2007-02-06 10:54:30
    my @date_vals;
    push @date_vals, substr($dtime, 0,4);  # year
    push @date_vals, substr($dtime, 5,2);  # month
    push @date_vals, substr($dtime, 8,2);  # day
    push @date_vals, substr($dtime, 11,2); # hour

    return join('',@date_vals).'0000';
};

sub get_table_names {

    my ($db_name, $rid) = @_;

    my $bits_in     = $db_name . ".ifInOctets_"     . $rid;
    my $bits_out    = $db_name . ".ifOutOctets_"    . $rid;
    my $packets_in  = $db_name . ".ifInUcastPkts_"  . $rid;
    my $packets_out = $db_name . ".ifOutUcastPkts_" . $rid;

    return $bits_in, $bits_out, $packets_in, $packets_out;
};

sub get_the_date {

    my $bump = shift;
    my $time = time;

    $bump = $bump ? $bump * 86400 : 0;
    my $offset_time = time - $bump;
    warn "selected time: $offset_time\n" if $debug;

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

#       warn "get_the_date: $yy/$mm/$dd $hh:$mn\n" if $debug;
        return $dd, $mm, $yy, $lm, $hh, $mn, $ss;
    }

    die "Date::Format is not installed!\n";
}

sub print_header {
    print "\n\n          table name              iid     oldest timestamp     periods       compression";
};

 

=head1 NAME

record_consolidator.pl - consolidate old RTG data to reduce database size.


=head1 VERSION

1.0.0


=head1 SYNOPSIS

  record_consolidator

Options for controlling consolidation are found in rtgreport.conf.


=head1 DESCRIPTION

record_consolidator.pl - Consolidates RTG data into summary records. We monitor tens of thousands of network ports and have hundreds of gigabytes of RTG data. When disk space or performance becomes an issue, the RTG supplied tool is a pruning script that simply deletes old data. Rather than deleting that data, I wanted to condense it, preserving the essence of the data. I borrowed a concept from Tobias Otiker and his RRD databases--rather than discard old data, reduce its granularity. 

In testing, I discovered that 15 minute averages still work perfectly with unaltered versions of the RTG CGI application. Any more than 15 minute averages and graphs stop rendering. Dropping from 5 to 15 minute averages reduces the disk space required by old data by 66%. 

How you use the consolidator script will be dictated by your business needs. I suggest using the consolidator script with two sets of settings. Old data that is no longer needed for graph publication should be pruned to 60 minute averages. A setting of 190/60 will do this. Then have another tier of pruning where you consolidate data older than 2-3 months to 15 minute averages. A setting of 90/15 would do that.

=head1 CONFIGURATION

The consolidator script is controlled by two settings in the rtgreport.conf config file:

 [Pruning]
  days     = 190
  interval = 60

Days controls what data you want to alter. A setting of 190 as shown will only condense data older than 190 days. Interval controls what interval the consolidated records will be. A setting of 15 will condense the data to 15 minute averages (66% reduction). A setting of 60 as shown will reduce the data to 60 minute averages for a 91% reduction in disk space.

=head1 DEPENDENCIES

 Config::Std
 Date::Calc
 Date::Format
 DBIx::Simple


=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 CHANGES


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Layered Technologies, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


