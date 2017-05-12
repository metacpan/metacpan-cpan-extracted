#-----------------------------------------------------------------
# Monitor::Simple::Utils
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::Utils
#-----------------------------------------------------------------

use warnings;
use strict;
package Monitor::Simple::Utils;

use Getopt::Long 2.38 qw(GetOptionsFromArray);
use Monitor::Simple;
use IO::CaptureOutput qw(capture_exec);
use Log::Log4perl qw(:easy);

our $VERSION = '0.2.8'; # VERSION

#-----------------------------------------------------------------
# Read plugin's command-line arguments @args.
#
# It returns configuration file name (may be undef) and service ID (if
# not found in @args, use $default_service_id). It uses logging
# options (if any found) to set the logging system.
# -----------------------------------------------------------------
sub parse_plugin_args {
    my ($self, $default_service_id, @args) = @_;

    my ($opt_service, $opt_config);
    my ($opt_logfile, $opt_loglevel, $opt_logformat);
    Getopt::Long::Configure ('no_ignore_case');
    GetOptionsFromArray (\@args,
                         'id|service=s'   => \$opt_service,
                         'cfg|config=s'   => \$opt_config,

                         # logging
                         'logfile=s'      => \$opt_logfile,
                         'loglevel=s'     => \$opt_loglevel,
                         'logformat=s'    => \$opt_logformat,
        );
    $opt_service = $default_service_id unless $opt_service;
    Monitor::Simple::Log->log_init ({ level  => $opt_loglevel,
                                    file   => $opt_logfile,
                                    layout => $opt_logformat });

    return ($opt_config, $opt_service);
}

#-----------------------------------------------------------------
# Report it and exit accordingly. $config is not used (at least now)
# and can be undef.
# -----------------------------------------------------------------
sub report_and_exit {
    my ($self, $service_id, $config, $return_code, $return_msg) = @_;

    # $return_msg should not be ever empty
    $return_msg = 'Message empty or lost...' unless $return_msg;

    $return_msg .= "\n" unless $return_msg =~ m{\n$};
    INFO ("Done: $service_id $return_code $return_msg");
    print STDOUT $return_msg;

    exit ($return_code);
}

#--------------------------------------------------------------------
# For the given plugin $command, it processes the real $exit_code and
# returns it as a processsed return code and accompanying message -
# which may be just a copy of the given $stdout.
# -------------------------------------------------------------------
sub process_exit {
    my ($self, $command, $exit_code, $stdout) = @_;

    if ($exit_code == -1) {
        # external command was not executed, at all
        return (-1, "Failed to execute plugin '$command'");

    } elsif ($exit_code & 127) {
        # external command was killed by a signal
        return (2, sprintf ("Plugin '$command' died with signal %d, %s coredump",
                            ($exit_code & 127),  ($exit_code & 128) ? 'with' : 'without'));

    } else {
        # external command finished (good or bad, it depends on its exit code)
        chomp $stdout;
        return ( ($exit_code >> 8), $stdout);
    }
}

#-----------------------------------------------------------------
# Read notifier's command-line arguments $args (an arrayref - so the
# recognized arguments can be removed from the provided array).
#
# It returns a service ID, a file name with the notification message
# and a reference to an array with all email addresses (may be empty
# for some notifiers).
#
# It uses logging options (if any found) to set the logging system.
# -----------------------------------------------------------------
sub parse_notifier_args {
    my ($self, $args) = @_;

    my ($opt_service, $opt_msgfile, @opt_emails);
    my ($opt_logfile, $opt_loglevel, $opt_logformat);
    Getopt::Long::Configure ('no_ignore_case', 'pass_through');
    GetOptionsFromArray ($args,
                         'service=s'    => \$opt_service,
                         'msg=s'        => \$opt_msgfile,
                         'emails=s'     => \@opt_emails,

                         # logging
                         'logfile=s'      => \$opt_logfile,
                         'loglevel=s'     => \$opt_loglevel,
                         'logformat=s'    => \$opt_logformat,
        );
    Monitor::Simple::Log->log_init ({ level  => $opt_loglevel,
                                    file   => $opt_logfile,
                                    layout => $opt_logformat });

    @opt_emails = split (m{\s*,\s*}, join (',', @opt_emails));

    return ($opt_service, $opt_msgfile, \@opt_emails);
}

# -------------------------------------------------------------------
# It executes an external program with the given arguments and
# (optionally) checks its STDOUT and/or STDERR for the given
# content. If everything okay it just returns. Otherwise, it exits
# with the nagios-compliant reporting (see more about it in
# report_and_exit()).
#
# It reads (and understands) the configuration (an example):
#
# <plugin command="check-prg.pl">
#   <prg-test>
#     <program>mrsclient</program>
#     <args>
#       <arg>-H</arg> <arg>mrs.cbrc.kaust.edu.sa</arg>
#       <arg>-l</arg>
#     </args>
#     <stdout>
#       <contains>enzyme</contains>
#       <contains>gene</contains>
#       <contains>sprot</contains>
#     </stdout>
#   </prg-test>
#   <prg-test>
#     <program>mrsclient</program>
#     <args>
#       <arg>-H</arg> <arg>mrs.cbrc.kaust.edu.sa</arg>
#       <arg>-d</arg> <arg>sprot</arg>
#       <arg>-q</arg> <arg>canine</arg>
#       <arg>-c</arg>
#       <arg>-n</arg>
#       <arg></arg>
#     </args>
#     <stdout>
#       <not-empty/>
#       <is-integer/>
#     </stdout>
#   </prg-test>
# </plugin>
# -------------------------------------------------------------------
sub exec_or_exit {
    my ($self, $service_id, $full_config) = @_;
    my $config = $self->service_config_or_exit ($service_id, $full_config);

    # warn (and exit) if the test cannot be executed
    unless (exists $config->{plugin}->{'prg-test'}) {
        # a warning: test ignored
        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                               Monitor::Simple::RETURN_WARNING,
                                               'PRG test(s) ignored');
    }
    foreach my $prgtest (@{ $config->{plugin}->{'prg-test'} }) {
        unless ($prgtest->{program}) {
            # a warning: test cannot be executed
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_WARNING,
                                                   "PRG test cannot be executed (missing 'program' parameter)");
        }
        # building a command-line
        my @command = ($prgtest->{program});
        if (defined $prgtest->{args}) {
            foreach my $arg (@{ $prgtest->{args} }) {
                push (@command, $arg) if defined $arg;  # ignoring empty arguments
            }
        }

        # prepare for timeout (zero means no timeout)
        my $timeout = $prgtest->{timeout} || 0;
        if (!$self->is_integer ($timeout)) {
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                     Monitor::Simple::RETURN_WARNING,
                                                     'PRG test cannot be executed (a non-integer value in timeout)');
        }
        $timeout = 0 unless $timeout > 0;

        # call the external program
        DEBUG ("Executing: " . join (' ', @command));
        my ($stdout, $stderr, $success, $exit_code);

        if ($timeout) {
            eval {
                local $SIG{ALRM} = sub { die "alarm\n" };
                alarm $timeout;
                ($stdout, $stderr, $success, $exit_code) = capture_exec (@command);
                alarm 0;
            };
            if ($@) {
                if ($@ eq "alarm\n") {
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                             Monitor::Simple::RETURN_WARNING,
                                                             "Timeout after waiting for $timeout seconds");
                } else {
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                             Monitor::Simple::RETURN_UNKNOWN,
                                                             $@);
                }
            }

        } else {
            ($stdout, $stderr, $success, $exit_code) = capture_exec (@command);
        }

        if ($stderr) {
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_UNKNOWN,
                                                   $stderr);
        }
        my ($code, $msg) = Monitor::Simple::Utils->process_exit ($command[0], $exit_code, $stdout);
        unless ($code == 0) {
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_CRITICAL,
                                                   $msg);
        }

        # check the response
        if (exists $prgtest->{stdout}) {

            # check for emptyness (have we got anything?)
            if (exists $prgtest->{stdout}->{'not-empty'}) {
                unless ($msg) {
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                           Monitor::Simple::RETURN_WARNING,
                                                           "Returned content is empty");
                }
            }

            # have we got an expected content?
            my $expected = $prgtest->{stdout}->{contains};
            if (defined $expected) {
                foreach my $content (@$expected) {
                    my $quoted = quotemeta ($content);
                    if ($msg !~ m{$quoted}) {
                        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                               Monitor::Simple::RETURN_WARNING,
                                                               "Returned content does not contain: $content");
                    }
                }
            }

            # check for numeric response
            if (exists $prgtest->{stdout}->{'is-integer'}) {
                if ($msg !~ m{\s*\d+\s*}) {
                    $msg =~ s{^\s*|\s*$}{}g;
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                           Monitor::Simple::RETURN_WARNING,
                                                           "Returned content '$msg' is not an integer");
                }
            }

        }
    }

    # everything is okay
    return;
}

use constant PAT_INT   => "[-+]?_*[0-9][0-9_]*";  # taken from Getopt::Long
sub is_integer {
    my ($self, $value) = @_;
    my $valid = PAT_INT;
    return $value =~ /^$valid$/si;
}

#-----------------------------------------------------------------
# Extract and return the configuration for the given service
# $service_id from $full_config. Exit with a warning exit code if such
# configuration cannot be found.
# -----------------------------------------------------------------
sub service_config_or_exit {
    my ($self, $service_id, $full_config) = @_;
    my $config = Monitor::Simple::Config->extract_service_config ($service_id, $full_config);

    # warn (and exit) if the service is unknown to the configuration
    unless ($config) {
        # a warning: test ignored
        $self->report_and_exit ($service_id, $full_config,
                                Monitor::Simple::RETURN_WARNING,
                                "Service '$service_id' unknown. Test(s) ignored.");
    }
    return $config;
}


1;


=pod

=head1 NAME

Monitor::Simple::Utils - See documentation in Monitor::Simple

=head1 VERSION

version 0.2.8

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
