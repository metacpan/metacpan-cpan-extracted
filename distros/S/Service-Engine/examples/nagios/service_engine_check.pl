#!/usr/bin/perl -w
  
# a nagios check plugin for monitoring Service::Engine
 
##############################################################################
# prologue
use strict;
use warnings;
use Monitoring::Plugin;
use JSON;
use LWP::UserAgent;
use JSON;
use HTTP::Request;

our $UA = LWP::UserAgent->new();
our $JSON = JSON->new->allow_nonref;
 
use vars qw($VERSION $PROGNAME  $port $host $aspect $password $code $msg);
$VERSION = '1.0';
 
# get the base name of this script for use in the examples
use File::Basename;
$PROGNAME = basename($0);
 
 
##############################################################################
# define and get the command line options.
#   see the command line option guidelines at
#   https://www.monitoring-plugins.org/doc/guidelines.html#PLUGOPTIONS

# Instantiate Monitoring::Plugin object (the 'usage' parameter is mandatory)
my $p = Monitoring::Plugin->new(
    usage => "Usage: %s [-H <host>] [-P <port>] [-A <aspect> backlog|threads|thorughput] [-p <password>]",
    version => $VERSION,
    blurb => 'This plugin checks Service::Engine status and will output OK, WARNING or CRITICAL',
    extra => ""
);
 
 
# Define and document the valid command line options
# usage, help, version, timeout and verbose are defined by default.
 
$p->add_arg(
    spec => 'host|H=s',
    help =>
qq{-H, --host=STRING
   The host name or IP},
    required => 1,
);
 
$p->add_arg(
    spec => 'port|P=s',
    help =>
qq{-P, --port=STRING
   The host port. },
   default => 8080,
);

$p->add_arg(
    spec => 'aspect|A=s',
    help =>
qq{-A, --aspect=STRING
   What aspect to monitor? backlog|threads|throughput },
   required => 1,
);

$p->add_arg(
    spec => 'password|p=s',
    help =>
qq{-p, --password=STRING
   password },
);
 
# Parse arguments and process standard ones (e.g. usage, help, version)
$p->getopts;
 
# perform sanity checking on command line options
unless ( defined $p->opts->host && defined $p->opts->aspect ) {
    $p->plugin_die( " you didn't supply host and aspect arguments " );
}

my %codes = (
    'info' => OK,
    'warning' => WARNING,
    'critical' => CRITICAL,
    'unknown' => UNKNOWN,
);
 
 
##############################################################################
# check stuff.
 
# THIS is where you'd do your actual checking to get a real value for $result
#  don't forget to timeout after $p->opts->timeout seconds, if applicable.
my $result;

# make a call to the health api
my $api_endpoint = 'http://' . $p->opts->host . ':' . $p->opts->port . '/Health/api_overview/?password=' . $p->opts->password;
my $api_request = HTTP::Request->new('GET', $api_endpoint);
my $api_res = $UA->request($api_request);

#{
#"Throughput":{"msg":"INFO: shortlinkEngine:1 Throughput","time":1548704047,
#    "throughput":{
#                    "350":{"ratio":"1.00","out":3,"in":3,"throughput":"0.01"},
#                    "60":{"ratio":"1.00","out":3,"in":3,"throughput":"0.05"},
#                    "10":{"ratio":"1.00","out":3,"in":3,"throughput":"0.30"},
#                    "5":{"ratio":"1.00","out":3,"in":3,"throughput":"0.60"}
#                  },
#                    "state":"ok","condition":"info"},
#"Backlog":{"msg":"INFO: shortlinkEngine:1 average thread backlog is 0, queue backlog is 0","average_backlog":"0","time":1548704047,"total_backlog":"0","state":"ok","condition":"info"},
#"Threads":{"msg":"INFO: shortlinkEngine:1 thread count is 3","time":1548704047,"thread_count":"3","state":"ok","condition":"info"}
#
#}

if ($api_res->is_success) {
    my $resContent = $api_res->content;
    my $json = eval{$JSON->decode($resContent)};
    if (ref($json) ne 'HASH') {
        
        $code = $codes{'UNKNOWN'};
        $msg = 'could not parse response';
        
    } else {
        my $condition = lc $json->{ucfirst $p->opts->aspect}->{'condition'};
        # info|warning|critical
        $code = $codes{$condition};
        $msg = $json->{ucfirst $p->opts->aspect}->{'msg'};
    }
    
} else {

    $code = $codes{'UNKNOWN'};
    $msg = 'could not connect to service engine';
    
    return '';    
} 
 
##############################################################################
# output the result and exit
$p->plugin_exit(
    return_code => $code,
    message => $msg
);
