################################################################################
#
# $Id: TaskForest.pm 290 2010-03-23 00:00:10Z aijaz $
#
# This is the primary class of this application.  Version infromation
# is taken from this file.
#
################################################################################

package TaskForest;
use strict;
use warnings;
use POSIX (":sys_wait_h", "strftime");
use Data::Dumper;
use TaskForest::Family;
use TaskForest::Options;
use TaskForest::Logs qw /$log/;
use File::Basename;
use Carp;
use TaskForest::LocalTime;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.37';
}


################################################################################
#
# Name      : The constructor
# Usage     : my $tf = TaskForest->new();
# Purpose   : Gets required and optional parameters from command line, or the
#             environment, if required parameters are missing from the command
#             line.   
# Returns   : Self
# Argument  : If you pass a hash of parameters and values, they are inserted
#             into the environment (as if they were always in %ENV)
# Throws    : 
#
################################################################################
#
sub new {
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    if (%parameters) {
        foreach my $p (keys %parameters) {
            next unless $p =~ /^TF_([A-Z_]+)$/;
            # untaint
            $parameters{$p} =~ s/[^a-z0-9_\/:\.]//ig;
            $ENV{$p} = $parameters{$p};
        }
    }

    # Get Options
    $self->{options} = &TaskForest::Options::getOptions();

    return $self;
}




################################################################################
#
# Name      : runMainLoop
# Usage     : $tf->runMainLoop();
# Purpose   : This function loops until end_time (23:55) by default.  In each 
#             loop it examines all the Family files and sees if there are any
#             jobs that need to be run.  Because of this, any changes
#             made to any of the family files  will take effect on the
#             iteration of the loop.  By default the system sleeps 60
#             seconds at the end of each loop.  
# Returns   : Nothing
# Argument  : 
# Throws    : 
#
################################################################################
#
sub runMainLoop {
    my $self = shift;
    # We don't want to have to process zombie child processes
    #
    $SIG{CHLD} = 'IGNORE';


    my $end_time            = $self->{options}->{end_time};
    $end_time               =~ /(\d\d)(\d\d)/;
    my $end_time_in_seconds = $1 * 3600 + $2 * 60;
    my $wait_time           = $self->{options}->{wait_time};

    my $rerun = 0;
    my $RELOAD = 1;

    $self->{options} = &TaskForest::Options::getOptions($rerun);  $rerun = 1;
    &TaskForest::Logs::init("New Loop");
   
    while (1) {
        
        # get a fresh list of all family files
        #
        my @families = $self->globFamilyFiles($self->{options}->{family_dir});
        
        
        foreach my $family_name (@families) {
            # create a new family object. It is possible that this
            # family will never need to be run today.  That is yet to
            # be determined.
            #
            my ($name) = $family_name =~ /$self->{options}->{family_dir}\/(.*)/;
            my $family = TaskForest::Family->new(name => $name);

            if (!defined $family) {
                # there was a syntax error
                
            }

            # If there aren't any jobs in the family, we really don't
            # need to try.
            #
            next unless $family->{jobs}; # no jobs to run today

            print Dumper($family) if $self->{options}->{verbose};

            # The cycle method gets the current status and runs any
            # jobs that are ready to be run.
            #
            $log->info("Calling cycle from runMainLoop");
            $family->cycle();
        }

        # The once_only option is good when testing.
        #
        if ($self->{options}->{once_only}) {
            last;
        }
        
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::lt();
        my $now = sprintf("%02d%02d", $hour, $min);
        print "It is $now, the time to end is $end_time\n" if $self->{options}->{verbose};
        my $now_plus_wait = $hour * 3600 + $min * 60 + $wait_time;
        if ( $now_plus_wait >= $end_time_in_seconds) {
            $log->info("In $wait_time seconds it will be past $end_time.  Exiting loop.");
            last;
        }
        $log->info("After $wait_time seconds, $now_plus_wait < $end_time_in_seconds.  Sleeping $wait_time");
        sleep $wait_time;                         # by default: 60s

        &TaskForest::Logs::resetLogs();
        $self->{options} = &TaskForest::Options::getOptions($rerun); 
        # &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $RELOAD);
        &TaskForest::Logs::init("New Loop");
        
    }
    
}


################################################################################
#
# Name      : globFamilyFiles
# usage     : $tf->globFamilyFiles();
# Purpose   : Find all family files given the rules of what's a valid file name
#             and what file names are to be ignored
# Returns   : An array of file names
# Argument  : The family directory to be searched
# Throws    : 
#
################################################################################
#
sub globFamilyFiles {
    my ($self, $dir) = @_;

    my $glob_string = "$dir/*";
    my @all_files = glob($glob_string);
    my @families = ();

    my @ignore_regexes = ();
    if (ref($self->{options}->{ignore_regex}) eq 'ARRAY') {
        @ignore_regexes = @{$self->{options}->{ignore_regex}};
    }
    elsif ($self->{options}->{ignore_regex}) {
        @ignore_regexes = ($self->{options}->{ignore_regex});
    }
    

    my @regexes = map { qr/$_/ } @ignore_regexes;
    
    foreach my $file (@all_files) {
        my $basename = basename($file);
        if ($basename =~ /[^a-zA-Z0-9_]/) {
            next;
        }
        my $ok = 1;
        foreach my $regex (@regexes) {
            if ($basename =~ /$regex/) {
                $ok = 0;
                last;
            }
        }
        if ($ok) {
            push (@families, $file);
        }
    }

    return @families;
}

################################################################################
#
# Name      : status
# usage     : $tf->status();
# Purpose   : This function determines the status of all jobs that have run
#             today, as well as the the status of jobs that have not
#             yet run (are in the "Waiting" or "Ready" state.  
#             If the --collapse option is given, pending repeat
#             jobs are not displayed.  
# Returns   : A data structure representing all the jobs
# Argument  : data-only - If this is true, then nothing is printed.
# Throws    : 
#
################################################################################
#
sub status {
    my ($self, $data_only) = @_;


    #my $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, 'reload');
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::lt();
    my $log_date = sprintf("%4d%02d%02d", $year, $mon, $mday);
    
    # get a fresh list of all family files
    #
    my @families = $self->globFamilyFiles($self->{options}->{family_dir});

    my $display_hash = { all_jobs => [], Success  => [], Failure  => [], Ready  => [], Waiting  => [],  Running => []};

    my $tz_for_family = {};

    foreach my $family_name (sort @families) {
        # create a new Family object
        #
        my ($name) = $family_name =~ /$self->{options}->{family_dir}\/(.*)/;
        my $family = TaskForest::Family->new(name => $name);

        $tz_for_family->{$name} = $family->{tz}; 
        
        next unless $family->{jobs}; # no jobs to run today

        # get the status of any jobs that may have already run (or
        # failed) today.
        #
        $family->getCurrent();

        # display the family
        #
        $family->display($display_hash);
    }

    foreach my $job (@{$display_hash->{Ready}}, @{$display_hash->{Waiting}}, @{$display_hash->{TokenWait}}, @{$display_hash->{Hold}}) {
        $job->{actual_start} = $job->{stop} = "--:--";
        $job->{rc} = '-';
        $job->{has_actual_start} = $job->{has_stop} = $job->{has_rc} = 0;
        $job->{log_date} = sprintf("%4d%02d%02d", $year, $mon, $mday);
    }

    foreach my $job (@{$display_hash->{Success}}, @{$display_hash->{Failure}}, @{$display_hash->{Running}}) {
        my $dt = DateTime->from_epoch( epoch => $job->{actual_start} );
        $dt->set_time_zone($job->{tz});
        $job->{actual_start_epoch} = $job->{actual_start};
        $job->{actual_start} = sprintf("%02d:%02d", $dt->hour, $dt->minute);
        $job->{has_actual_start} = 1;
        $job->{has_rc} = 1;

        if (($job->{stop}) && ($job->{status} ne "Running")) {
            $dt = DateTime->from_epoch( epoch => $job->{stop} );
            $dt->set_time_zone($job->{tz});
            $job->{stop} = sprintf("%02d:%02d", $dt->hour, $dt->minute);
            $job->{has_stop} = 1;
            if ($job->{status} eq 'Success') {
                $job->{is_success} = 1;
            }
            else { 
                $job->{is_success} = 0;
            }
        }
        else {
            $job->{stop} = '--:--';
            $job->{rc} = '-';
            $job->{has_stop} = $job->{has_rc} = 0;
        }
    }

    $self->getUnaccountedForJobs($display_hash);

    map { ($_->{base_name}) = $_->{name} =~ /([^\-]+)/; } @{$display_hash->{all_jobs}};

    my @sorted = sort  {
        
                               $a->{family_name} cmp $b->{family_name}                 # family first
                                                  ||
                                 $a->{base_name} cmp $b->{base_name}                    # base name
                                                  ||
                          $b->{has_actual_start} <=> $a->{has_actual_start}            # REady and Waiting after Success or Failed 
                                                  ||

                        # after this point they're either both run or both not run
                                                      
  (($a->{has_actual_start}) ? ($a->{actual_start} cmp $b->{actual_start}) :             # Actual start if possible (if both have started ELSE BOTH HAVE FAILED, THEN:
                                    $a->{start} cmp $b->{start})                      # Waiting after Ready
                                                  ||
                                      $a->{name} cmp $b->{name}                        # Job Name
               

                              
        
    } @{$display_hash->{all_jobs}};

    my $oe = 'odd';
    my $log_dir;
    foreach my $job (@sorted) {
        $job->{oe} = $oe = (($oe eq 'odd') ? 'even' : 'odd');
        $job->{has_output_file} = 0;
        if ($job->{has_actual_start}) {
            $job->{output_file} = "$job->{family_name}.$job->{name}.$job->{pid}.$job->{actual_start_epoch}.stdout";
            if ($job->{log_dir}) {
                $log_dir = $job->{log_dir};  # from getUnaccountedForJobs
            }
            else { 
                $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $tz_for_family->{$job->{family_name}});
            }
            if (-e "$log_dir/$job->{output_file}") {
                $job->{has_output_file} = 1;
            }
            $job->{log_date} = substr($log_dir, -8);  
        }
        else {
            if ($job->{log_dir}) {
                $log_dir = $job->{log_dir};  # from getUnaccountedForJobs
            }
            else { 
                $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $tz_for_family->{$job->{family_name}});
            }
            $job->{log_date} = substr($log_dir, -8);  
        }
        $job->{is_waiting} = ($job->{status} eq 'Waiting') ? 1 : 0;
    }

    
    $display_hash->{all_jobs} = \@sorted;

    return $display_hash if $data_only;

    ## ########################################
    
    my $max_len_name = 0;
    my $max_len_tz = 0;
    foreach my $job (@{$display_hash->{all_jobs}}) {
        my $l = length($job->{full_name} = "$job->{family_name}::$job->{name}");
        if ($l > $max_len_name) { $max_len_name = $l; }
        
        $l = length($job->{tz});
        if ($l > $max_len_tz)   { $max_len_tz   = $l; }

    }

    my $format = "%-${max_len_name}s   %-7s   %6s   %-${max_len_tz}s   %-5s   %-6s  %-5s\n";
    printf($format, '', '', 'Return', 'Time', 'Sched', 'Actual', 'Stop');
    printf($format, 'Job', 'Status', 'Code', 'Zone', 'Start', 'Start', 'Time');
    print "\n";
    
    my $collapse = $self->{options}->{collapse};
   
    foreach my $job (@{$display_hash->{all_jobs}}) {
        if ($collapse and
          $job->{name} =~ /--Repeat/ and
          $job->{status} eq 'Waiting') {
            next;  # don't print every waiting repeat job
        }
        printf($format,
               $job->{full_name},
               $job->{status},
               $job->{rc},
               $job->{tz},
               $job->{start},
               $job->{actual_start},
               $job->{stop});
    }
    
}



################################################################################
#
# Name      : hist_status
# usage     : $tf->status();
# Purpose   : This function determines the status of all jobs that have run
#             for a particular day.  If the --collapse option is given, 
#             pending repeat jobs are not displayed.  
# Returns   : A data structure representing all the jobs
# Argument  : data-only - If this is true, then nothing is printed.
# Throws    : 
#
################################################################################
#
sub hist_status {
    my ($self, $date, $data_only) = @_;
    my $log_dir = $self->{options}->{log_dir}."/$date";

    my $display_hash = { all_jobs => [], Success  => [], Failure  => [], Ready  => [], Waiting  => [],  };
    $self->getUnaccountedForJobs($display_hash, $date);

    map { ($_->{base_name}) = $_->{name} =~ /([^\-]+)/; } @{$display_hash->{all_jobs}};

    my @sorted = sort  {
                               $a->{family_name} cmp $b->{family_name}                 # family first
                                                  ||
                                 $a->{base_name} cmp $b->{base_name}                   # base name
                                                  ||
                              $a->{actual_start} cmp $b->{actual_start}                # start_time 
                                                  ||
                                      $a->{name} cmp $b->{name}                        # Job Name
    } @{$display_hash->{all_jobs}};
    
    my $oe = 'odd';
    foreach my $job (@sorted) {
        $job->{oe} = $oe = (($oe eq 'odd') ? 'even' : 'odd');
        $job->{has_output_file} = 0;
        $job->{output_file} = "$job->{family_name}.$job->{name}.$job->{pid}.$job->{actual_start_epoch}.stdout";
        if (-e "$log_dir/$job->{output_file}") {
            $job->{has_output_file} = 1;
            $job->{log_dir} = $log_dir;
        }
        $job->{log_date} = $date;
        $job->{is_waiting} = ($job->{status} eq 'Waiting') ? 1 : 0;
    }

    $display_hash->{all_jobs} = \@sorted;

    return $display_hash if $data_only;

    my $max_len_name = 0;
    my $max_len_tz = 0;
    foreach my $job (@{$display_hash->{all_jobs}}) {
        my $l = length($job->{full_name} = "$job->{family_name}::$job->{name}");
        if ($l > $max_len_name) { $max_len_name = $l; }
        
        $l = length($job->{tz});
        if ($l > $max_len_tz)   { $max_len_tz   = $l; }

    }

    my $format = "%-${max_len_name}s   %-7s   %6s   %-${max_len_tz}s   %-5s   %-6s  %-5s\n";
    printf($format, '', '', 'Return', 'Time', 'Sched', 'Actual', 'Stop');
    printf($format, 'Job', 'Status', 'Code', 'Zone', 'Start', 'Start', 'Time');
    print "\n";
    
    my $collapse = $self->{options}->{collapse};
   
    foreach my $job (@{$display_hash->{all_jobs}}) {
        if ($collapse and
          $job->{name} =~ /--Repeat/ and
          $job->{status} eq 'Waiting') {
            next;  # don't print every waiting repeat job
        }
        printf($format,
               $job->{full_name},
               $job->{status},
               $job->{rc},
               $job->{tz},
               $job->{start},
               $job->{actual_start},
               $job->{stop});
        
    }
}
    

################################################################################
#
# Name      : getUnaccountedForJobs
# usage     : $tf->getUnaccountedForJobs($display_hash, "YYYYMMDD");
# Purpose   : This function browses a log directory for a particular date
#             and populates the input variable $display_hash with data
#             about each job that ran that day.
# Returns   : None
# Argument  : $display_hash - the hash that will contain the data for
#             all the jobs.
#             $date - the date for which you want job data
# Throws    : "Cannot open file"
#
################################################################################
#
sub getUnaccountedForJobs {
    my ($self, $display_hash, $date) = @_;
    my $log_dir;

    unless ($date) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::lt();
        $date = sprintf("%4d%02d%02d", $year, $mon, $mday);
    }
    $log_dir = $self->{options}->{log_dir}."/$date";
    return unless -d $log_dir;
    
    my $seen  = {};
    foreach my $job (@{$display_hash->{Success}}, @{$display_hash->{Failure}}) {
        $seen->{"$job->{family_name}.$job->{name}"} = 1;
    }
    
    # readdir
    my $glob_string = "$log_dir/*.[01]";
    my @files = glob($glob_string);

    my $new = [];
    my $file_name;
    my %valid_fields = ( actual_start => 1, pid => 1, stop => 1, rc => 1, );
    foreach my $file (@files) {
        my ($family_name, $job_name, $status) = $file =~ /$log_dir\/([^\.]+)\.([^\.]+)\.([01])/;
        my $full_name = "$family_name.$job_name";
        next if $seen->{$full_name};  # don't update $seen, because we want to show every job that ran.

        my $job = { family_name => $family_name,
                    name => $job_name,
                    full_name => $full_name,
                    start => '--:--',
                    status => ($status) ? 'Failure' : 'Success' };  # just a hash, not an object, since this is only used for display

        # read the pid file
        substr($file, -1, 1) = 'pid';
        open(F, $file) || croak "cannot open $file to read job data";
        while (<F>) { 
            chomp;
            my ($k, $v) = /([^:]+): (.*)/;
            $v =~ s/[^a-z0-9_ ,.\-]/_/ig;
            if ($valid_fields{$k}) {
                $job->{$k} = $v;
            }
        }
        close F;

        my $tz                   = $self->{options}->{default_time_zone};
        $job->{actual_start_epoch} = $job->{actual_start};
        my $dt                   = DateTime->from_epoch( epoch => $job->{actual_start} );
        $dt->set_time_zone($tz);
        $job->{actual_start}     = sprintf("%02d:%02d", $dt->hour, $dt->minute);
        $job->{actual_start_dt}  = sprintf("%d/%02d/%02d %02d:%02d", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute); #sprintf("%02d:%02d", $dt->hour, $dt->minute);
        $dt                      = DateTime->from_epoch( epoch => $job->{stop} );
        $dt->set_time_zone($tz);
        $job->{stop}             = sprintf("%02d:%02d", $dt->hour, $dt->minute);
        $job->{stop_dt}          = sprintf("%d/%02d/%02d %02d:%02d", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute);  #sprintf("%02d:%02d", $dt->hour, $dt->minute);
        $job->{has_actual_start} = $job->{has_stop} = $job->{has_rc} = 1;
        $job->{tz}               = $tz;
        $job->{log_dir}          = $log_dir;

        $job->{is_success} = ($job->{status} eq 'Success') ? 1 : 0;
        

        push (@{$display_hash->{all_jobs}}, $job);
    }
}



#################### main pod documentation begin ###################

=head1 NAME

TaskForest - A simple but expressive job scheduler that allows you to chain jobs/tasks and create time dependencies. Uses text config files to specify task dependencies.

=head1 VERSION

This is version 1.37.

=head1 EXECUTIVE SUMMARY

With the TaskForest Job Scheduler you can:

=over 4

=item * 

schedule jobs run at predetermined times

=item *

have jobs be dependent on each other

=item *

rerun failed jobs

=item *

mark jobs as succeeded or failed

=item *

put jobs on hold and release the holds

=item *

release all dependencies on a job

=item *

check the status of all jobs scheduled to run today

=item *

interact with the included web service using your own client code

=item *

interact with the included web server using your default browser

=item *

express the relationships between jobs using a simple text-based format (a big advantage if you like using 'grep')

=back

=head1 SYNOPSIS

Over the years TaskForest has migrated from a collection of simple
perl modules to a full-fledged system.  I have found that putting the
documentation in a single POD is getting much more difficult.  You can
now find the latest documetation on the TaskForest website located at

 http://www.taskforest.com

If you run the included web server, you will also find a complete copy
of the documentation on the included web site.

=head1 BUGS

For an up-to-date bug listing and to submit a bug report, please
send an email to the TaskForest Discussion Mailing List at
"taskforest-discuss at lists dot sourceforge dot net"

=head1 SUPPORT

For support, please visit our website at http://www.taskforest.com/ or
send an email to the TaskForest Discussion Mailing List at
"taskforest-discuss at lists dot sourceforge dot net"

=head1 AUTHORS

Aijaz A. Ansari
http://www.taskforest.com/

The following developers have graciously contributed patches to enhance TaskForest:

=over 4

=item *

Steve Hulet

=back

Please see the 'Changes' file for details.  If you have contributed
code, and your name is not on the above list, please accept my
apologies and let me know, so that I may give you credit.

If you're using this program, I would love to hear from you.  Please
send an email to the TaskForest Discussion Mailing List at
"taskforest-discuss at lists dot sourceforge dot net" and let me know
what you think of it.

=head1 ACKNOWLEDGEMENTS

Many thanks to the following for their help and support:

=over 4

=item *

SourceForge

=item *

Rosco Rouse

=item *

Svetlana Lemeshov

=item *

Teresia Arthur

=item *

Steve Hulet

=back

I would also like to thank Randal L. Schwartz for teaching the readers of
the Feb 1999 issue of Web Techniques how to write a pre-forking web
server, the code upon which the TaskForest Web server is built.

I would also like to thank the fine developers at Yahoo! for providing
yui to the open source community.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself - specifically, the Artistic
License. 

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

