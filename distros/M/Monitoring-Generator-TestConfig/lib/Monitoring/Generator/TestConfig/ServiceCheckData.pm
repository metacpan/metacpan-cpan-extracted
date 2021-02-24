package Monitoring::Generator::TestConfig::ServiceCheckData;

use strict;
use warnings;


########################################

=over 4

=item get_test_servicecheck

    returns the test servicecheck plugin source

=back

=cut

sub get_test_servicecheck {
    my $self = shift;
    our $testservicecheck;
    return($testservicecheck) if defined $testservicecheck;
    $testservicecheck = do { local $/; <DATA> };
    return($testservicecheck);
}

1;

__DATA__
#!/usr/bin/perl
# nagios: +epn

=head1 NAME

test_servicecheck.pl - service check replacement for testing purposes

=head1 SYNOPSIS

./test_servicecheck.pl [ -v ] [ -h ]
                       [ --type=<type>                 ]
                       [ --minimum-outage=<seconds>    ]
                       [ --failchance=<percentage>     ]
                       [ --previous-state=<state>      ]
                       [ --state-duration=<meconds>    ]
                       [ --total-critical-on-host=<nr> ]
                       [ --total-warning-on-host=<nr>  ]

=head1 DESCRIPTION

this service check calculates a random based result. It can be used as a testing replacement
service check

example configuration:

    defined command {
        command_name  check_service
        command_line  $USER1$/test_servicecheck.pl --failchance=2% --previous-state=$SERVICESTATE$ --state-duration=$SERVICEDURATIONSEC$ --total-critical-on-host=$TOTALHOSTSERVICESCRITICAL$ --total-warning-on-host=$TOTALHOSTSERVICESWARNING$
    }

=head1 ARGUMENTS

script has the following arguments

=over 4

=item help

    -h

print help and exit

=item verbose

    -v

verbose output

=item type

    --type

can be one of ok,warning,critical,unknown,random,flap

=back

=head1 EXAMPLE

./test_servicecheck.pl --minimum-outage=60
                       --failchance=3%
                       --previous-state=OK
                       --state-duration=2500
                       --total-critical-on-host=0
                       --total-warning-on-host=0

=head1 AUTHOR

2009, Sven Nierlein, <nierlein@cpan.org>

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Sys::Hostname;
use Time::HiRes qw(gettimeofday tv_interval);

#########################################################################
do_check();

#########################################################################
sub do_check {
    my ($t0, $perfdata);
    #####################################################################
    # parse and check cmd line arguments
    my ($opt_h, $opt_v, $opt_failchance, $opt_previous_state, $opt_minimum_outage, $opt_state_duration, $opt_total_crit, $opt_total_warn, $opt_type, $opt_hostname, $opt_servicedesc);
    $t0 = [gettimeofday];
    Getopt::Long::Configure('no_ignore_case');
    if(!GetOptions (
       "h"                        => \$opt_h,
       "v"                        => \$opt_v,
       "type=s"                   => \$opt_type,
       "minimum-outage=i"         => \$opt_minimum_outage,
       "failchance=s"             => \$opt_failchance,
       "previous-state=s"         => \$opt_previous_state,
       "state-duration=i"         => \$opt_state_duration,
       "total-critical-on-host=i" => \$opt_total_crit,
       "total-warning-on-host=i"  => \$opt_total_warn,
       "hostname=s"               => \$opt_hostname,
       "servicedesc=s"            => \$opt_servicedesc,
    )) {
        pod2usage( { -verbose => 1, -message => 'error in options' } );
        exit 3;
    }

    if(defined $opt_h) {
        pod2usage( { -verbose => 1 } );
        exit 3;
    }
    my $verbose = 0;
    if(defined $opt_v) {
        $verbose = 1;
    }

    #########################################################################
    # Set Defaults
    $opt_minimum_outage = 0    unless defined $opt_minimum_outage;
    $opt_failchance     = '5%' unless defined $opt_failchance;
    $opt_previous_state = 'OK' unless defined $opt_previous_state;
    $opt_state_duration = 0    unless defined $opt_state_duration;
    $opt_total_crit     = 0    unless defined $opt_total_crit;
    $opt_total_warn     = 0    unless defined $opt_total_warn;

    #########################################################################
    if($opt_failchance =~ m/^(\d+)%/) {
        $opt_failchance = $1;
    } else {
        pod2usage( { -verbose => 1, -message => 'failchance must be a percentage' } );
        exit 3;
    }

    #########################################################################
    my $states = {
        'OK'       => 0,
        'WARNING'  => 1,
        'CRITICAL' => 2,
        'UNKNOWN'  => 3,
        'PENDING'  => 4,
    };

    #########################################################################
    my $servicedesc = $opt_servicedesc || 'servicecheck';

    my $hostname = hostname;
    my $host_desc = "$hostname";
    if(defined $opt_hostname) {
        $host_desc = "$opt_hostname (checked by $hostname)";
    }

    #########################################################################
    # not a random check?
    if(defined $opt_type and lc $opt_type ne 'random') {
        if(lc $opt_type eq 'ok') {
            $perfdata = _perfdata($t0);
            print "$host_desc OK: ok $servicedesc $perfdata\n";
            exit 0;
        }
        if(lc $opt_type eq 'warning') {
            $perfdata = _perfdata($t0);
            print "$host_desc WARNING: warning $servicedesc $perfdata\n";
            exit 1;
        }
        if(lc $opt_type eq 'critical') {
            $perfdata = _perfdata($t0);
            print "$host_desc CRITICAL: critical $servicedesc $perfdata\n";
            exit 2;
        }
        if(lc $opt_type eq 'unknown') {
            $perfdata = _perfdata($t0);
            print "$host_desc UNKNOWN: unknown $servicedesc $perfdata\n";
            exit 3;
        }
        if(lc $opt_type eq 'flap') {
            $perfdata = _perfdata($t0);
            if($opt_previous_state eq 'OK' or $opt_previous_state eq 'UP') {
                print "$host_desc FLAP: down $servicedesc down $perfdata\n";
                exit 2;
            }
            print "$host_desc FLAP: up $servicedesc up $perfdata\n";
            exit 0;
        }
        if(lc $opt_type eq 'block') {
            sleep(3600);
            $perfdata = _perfdata($t0);
            print "$host_desc BLOCK: blocking.... $servicedesc $perfdata\n";
            exit 0;
        }

    }

    my $rand     = int(rand(100));
    print "random number is $rand\n" if $verbose;

    # if the service is currently up, then there is a chance to fail
    if($opt_previous_state eq 'OK') {
        if($rand < $opt_failchance) {
            # failed

            # warning critical or unknown?
            my $rand2 = int(rand(100));

            # 60% chance for a critical
            if($rand2 > 60) {
                # a failed check takes a while
                my $sleep = 5 + int(rand(20));
                sleep($sleep);
                $perfdata = _perfdata($t0);
                print "$host_desc CRITICAL: random $servicedesc critical $perfdata\n";
                print "sometimes with multiline and <b>html tags</b>\n";
                exit 2;
            }
            # 30% chance for a warning
            if($rand2 > 10) {
                # a failed check takes a while
                my $sleep = 5 + int(rand(20));
                sleep($sleep);
                $perfdata = _perfdata($t0);
                print "$host_desc WARNING: random $servicedesc warning $perfdata\n";
                print "sometimes with multiline and <b>html tags</b>\n";
                exit 1;
            }

            # 10% chance for a unknown
            $perfdata = _perfdata($t0);
            print "$host_desc UNKNOWN: random $servicedesc unknown $perfdata\n";
            print "sometimes with multiline and <b>html tags</b>\n";
            exit 3;
        }
    }
    else {
        # already hit the minimum outage?
        if($opt_minimum_outage > $opt_state_duration) {
            $perfdata = _perfdata($t0);
            print "$host_desc $opt_previous_state: random $servicedesc minimum outage not reached yet $perfdata\n";
            print "sometimes with multiline and <b>html tags</b>\n";
            exit $states->{$opt_previous_state};
        }
        # if the service is currently down, then there is a 30% chance to recover
        elsif($rand < 30) {
            $perfdata = _perfdata($t0);
            print "$host_desc REVOVERED: random $servicedesc recovered $perfdata\n";
            print "sometimes with multiline and <b>html tags</b>\n";
            exit 0;
        }
        else {
            # a failed check takes a while
            my $sleep = 5 + int(rand(20));
            $perfdata = _perfdata($t0);
            sleep($sleep);
            print "$host_desc $opt_previous_state: random $servicedesc unchanged $perfdata\n";
            print "sometimes with multiline and <b>html tags</b>\n";
            exit $states->{$opt_previous_state};
        }
    }

    $perfdata = _perfdata($t0);
    print "$host_desc OK: random $servicedesc ok $perfdata\n";
    print "sometimes with multiline and <b>html tags</b>\n";
    exit 0;
}

sub _perfdata {
    my($t0) = @_;
    my $t1  = [gettimeofday];
    my $rt  = tv_interval $t0, $t1;
    return "| runtime=$rt"
}
