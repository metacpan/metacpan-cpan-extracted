#!/usr/bin/env perl

=head1 NAME

create_test_config.pl - create a test configuration

=head1 SYNOPSIS

./create_test_config.pl [ -h ] [ -v ] [ -b <monitoring binary> ] [ -p <prefix> ] [ -l layout ] [ <directory> ]

=head1 DESCRIPTION

this script generates a valid test configuration

=head1 ARGUMENTS

script has the following arguments

=over 4

=item help

    -h

print help and exit

=item verbose

    -v

verbose output

=item prefix

    -p

add this prefix to all exported hosts and services

=item binary

    nagios/icinga binary to use

will search for nagios, nagios3 and icinga in path if not set

=item layout

    use nagios or icinga

=item directory

    output directory for export

=back

=head1 EXAMPLE

./create_test_config.pl -p test1 /tmp/test-config/

=head1 AUTHOR

2009, Sven Nierlein, <nierlein@cpan.org>

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use lib '../lib';
use lib 'lib';
use Monitoring::Generator::TestConfig;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v, $opt_p, $opt_b, $opt_d, $opt_l);
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"              => \$opt_h,
   "v"              => \$opt_v,
   "p=s"            => \$opt_p,
   "b=s"            => \$opt_b,
   "l=s"            => \$opt_l,
   "<>"             => \&add_dir,
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

if(!defined $opt_d and !defined $ENV{'OMD_ROOT'}) {
    pod2usage( { -verbose => 1, -message => 'no export directory given!' } );
    exit 3;
}

$opt_p = ""       unless defined $opt_p;
$opt_l = "nagios" unless defined $opt_l or defined $ENV{'OMD_ROOT'};


#########################################################################
my $ngt = Monitoring::Generator::TestConfig->new(
                    'output_dir'                => $opt_d,
                    'layout'                    => $opt_l,
                    'verbose'                   => 1,
                    'overwrite_dir'             => 1,
                    'prefix'                    => $opt_p,
                    'binary'                    => $opt_b,
                    'routercount'               => 10,
                    'hostcount'                 => 100,
                    'services_per_host'         => 10,
                    'main_cfg'                  => {
                            #'broker_module' => '/opt/projects/git/check_mk/livestatus/src/livestatus.o /tmp/live.sock',
                        },
                    'hostfailrate'              => 2, # percentage
                    'servicefailrate'           => 5, # percentage
                    'host_settings'             => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
                    'service_settings'          => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
                    'router_types'              => {
                                    'down'         => 10, # percentage
                                    'up'           => 10,
                                    'flap'         => 10,
                                    'pending'      => 10,
                                    'random'       => 60,
                        },
                    'host_types'                => {
                                    'down'         => 5, # percentage
                                    'up'           => 50,
                                    'flap'         => 5,
                                    'pending'      => 5,
                                    'random'       => 35,
                        },
                    'service_types'             => {
                                    'ok'           => 50, # percentage
                                    'warning'      => 5,
                                    'unknown'      => 5,
                                    'critical'     => 5,
                                    'pending'      => 5,
                                    'flap'         => 5,
                                    'random'       => 25,
                        },
);
$ngt->create();
#########################################################################

sub add_dir {
    my $dir = shift;
    $opt_d  = $dir;
    return;
}
