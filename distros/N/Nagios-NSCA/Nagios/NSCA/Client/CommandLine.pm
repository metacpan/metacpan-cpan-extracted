package Nagios::NSCA::Client::CommandLine;
use strict;
use warnings;
use base 'Nagios::NSCA::Client::Base';
use Nagios::NSCA::Encrypt;
use UNIVERSAL;

our $VERSION = sprintf("%d", q$Id: CommandLine.pm,v 1.3 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

# Constants
use constant DEFAULT_NSCA_HOST => '127.0.0.1';
use constant DEFAULT_NSCA_PORT => 5667;
use constant DEFAULT_NSCA_TIMEOUT => 10;
use constant DEFAULT_NSCA_DELIMITER => "\t";
use constant DEFAULT_NSCA_CONFIG => "send_nsca.cfg";

sub new {
    my ($class, %args) = @_;
    my $fields = {
        host => DEFAULT_NSCA_HOST,
        port => DEFAULT_NSCA_PORT,
        timeout => DEFAULT_NSCA_TIMEOUT,
        delimiter => DEFAULT_NSCA_DELIMITER,
        config => DEFAULT_NSCA_CONFIG,
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    $self->_initFromArgv($args{argv});

    return $self;
}

sub usage {
    my $encrypt = "AVAILABLE";
    $encrypt = "NOT AVAILABLE" if not Nagios::NSCA::Encrypt->hasMcrypt();
    return<<USAGE;

NSCA Perl Client 0.1
Copyright (c) 2006 Matthew O'Connor (matthew\@canonical.org)
Last Modified: 04-10-2006
License: GPL
Encryption Routines: $encrypt

Usage: ./send_nsca -H <host_address> [-p port] [-to to_sec] [-d delim] [-c config_file]

Options:
 <host_address> = The IP address of the host running the NSCA daemon
 [port]         = The port on which the daemon is running - default is 5667
 [to_sec]       = Number of seconds before connection attempt times out.
                  (default timeout is 10 seconds)
 [delim]        = Delimiter to use when parsing input (defaults to a tab)
 [config_file]  = Name of config file to use

Note:
This utility is used to send passive check results to the NSCA daemon.  Host and
Service check data that is to be sent to the NSCA daemon is read from standard
input. Input should be provided in the following format (tab-delimited unless
overriden with -d command line argument, one entry per line):

Service Checks:
<host_name>[tab]<svc_description>[tab]<return_code>[tab]<plugin_output>[newline]

Host Checks:
<host_name>[tab]<return_code>[tab]<plugin_output>[newline]
USAGE
}

sub _initFromArgv {
    my ($self, $argv) = @_;
    $argv = \@main::ARGV if not $argv;

    # Make sure we have an array reference
    if (not $argv or not UNIVERSAL::isa($argv, 'ARRAY')) {
        die "Unable to process command line.  Internal error.\n";
    }

    # Bail if no command line args are given.
    if (not @$argv) {
        die $self->usage() . "\n";
    }

    # Support old style command line where the hostname is the first argument
    # and it's not adorned w/ a -H.  So if the first item in argv is not
    # something starting with a dash, it must be a  server name.
    $self->host(shift @$argv) if $$argv[0] !~ /^-/;

    while (@$argv) {
        my ($option, $value) = (shift @$argv, shift @$argv);

        # Bail out if we don't have a value
        if (not $value) {
            die "No value given for option: \"$option\"\n";
        }

        if ($option eq '-H') {
            $self->host($value);
        } elsif ($option eq '-p') {
            $self->port($value);
        } elsif ($option eq '-to') {
            $self->timeout($value);
        } elsif ($option eq '-c') {
            $self->config($value);
        } elsif ($option eq '-d') {
            $self->delimiter($value);
        } elsif ($option eq '-h' or $option eq '--help') {
            die $self->usage() . "\n";
        } elsif ($option eq '-l' or $option eq '--license') {
            die $self->usage() . "\n";
        } elsif ($option eq '-V' or $option eq '--version') {
            die $self->usage() . "\n";
        } else {
            die "Invalid items on command line: \"$option\" \"$value\"\n\n" .
                 $self->usage() . "\n";
        }
    }
}

1;
