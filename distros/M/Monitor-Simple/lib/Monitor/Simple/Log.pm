#-----------------------------------------------------------------
# Monitor::Simple::Log
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::Log
#-----------------------------------------------------------------

package Monitor::Simple::Log;

use warnings;
use strict;
use Log::Log4perl qw(:easy);

our $VERSION = '0.2.8'; # VERSION

my $default_loglevel  = 'INFO';
my $default_logfile   = 'smonitor.log';
#my $default_logformat = '%d (%r) %p> %F{1}:%L - %m%n';
my $default_logformat = '%d (%r) %p> %m%n';

# will be filled by calling log_init() - they are just a copy of $args
# given in log_init()
my $logging_options = {};

# -----------------------------------------------------------------
# Return current logging options.
# -----------------------------------------------------------------
sub get_logging_options {
    return $logging_options;
}

# -----------------------------------------------------------------
# Initiate logging. Arguments is a hashref (some values may be
# undefined). For example:
#
# Monitor::Simple::Log->log_init ({ level  => $opt_loglevel,
#                                 file   => $opt_logfile,
#                                 layout => $opt_logformat });
# -----------------------------------------------------------------
sub log_init {
    my ($self, $args) = @_;
    $logging_options = $args;

    my $logger_conf = {};

    # log level
    my $opt_loglevel = $args->{level};
    if ($opt_loglevel) {
        my $level = Log::Log4perl::Level::to_priority (uc ($opt_loglevel));
        $logger_conf->{level} = $level;
    } else {
        $logger_conf->{level} = Log::Log4perl::Level::to_priority ($default_loglevel);
    }

    # log file
    my $opt_logfile = $args->{file};
    $opt_logfile ||= $default_logfile;
    $opt_logfile =~ s{^[><]+}{};   # I had problems when '>' was there; it created binary log file (TBD?)
    if ($opt_logfile ne 'STDOUT' and $opt_logfile ne 'STDERR' and $opt_logfile !~ m{^>}) {
        $opt_logfile = ">>$opt_logfile";
    }
    $logger_conf->{file} = $opt_logfile;

    # log layout pattern
    my $opt_logformat = $args->{layout};
    $opt_logformat ||= $default_logformat;
    $logger_conf->{layout} = $opt_logformat;

    Log::Log4perl->easy_init ($logger_conf);

}

# -----------------------------------------------------------------
# Convert (and return) my $logging_options to the command-line
# arguments used for plugins and notifiers.
# -----------------------------------------------------------------
sub logging_args {
    my ($self) = @_;
    my @logging_args = ();
    push (@logging_args, '-logfile',   $logging_options->{file})   if $logging_options->{file};
    push (@logging_args, '-loglevel',  $logging_options->{level})  if $logging_options->{level};
    push (@logging_args, '-logformat', $logging_options->{layout}) if $logging_options->{layout};
    return (@logging_args);
}

1;

__END__
=pod

=head1 NAME

Monitor::Simple::Log - See documentation in Monitor::Simple

=head1 VERSION

version 0.2.8

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

