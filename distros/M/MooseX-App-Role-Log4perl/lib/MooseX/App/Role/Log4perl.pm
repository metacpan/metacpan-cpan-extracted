package MooseX::App::Role::Log4perl;

use strict;
use warnings;
use 5.010_000;
use Moose::Role;
use MooseX::App::Role;
use Log::Log4perl qw(:easy);

our $VERSION = "0.03";

option 'logfile' =>
(
    is => 'rw',
    isa => 'Str',
    documentation => q[Path to file used for logging ],
    cmd_flag => 'log',
    default => '',
);

option 'debug' =>
(
    is => 'rw',
    isa => 'Bool',
    documentation => q[Turn on debug mode],
);

option 'quiet' =>
(
    is => 'ro',
    isa => 'Bool',
    documentation => q[Turn off log messages written to STDOUT],
);

has 'log' => (
    is => 'rw',
    lazy => 1,
    builder => '_init_logging',
);

sub _init_logging
{
    my $self = shift;

    # Setup logging.
    my $log_level = $self->debug ? "DEBUG" : "INFO";
    my $log_cat = "$log_level, Screen";
    $log_cat .= ", Logfile" if $self->logfile;
    my $screen_threshold = $self->quiet ? "OFF" : $log_level;
    my $file_path = $self->logfile;
    my $log_conf = qq(
        log4perl.category = $log_cat
        log4perl.appender.Screen = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = %p - %m%n
        log4perl.appender.Screen.Threshold = $screen_threshold
        log4perl.appender.Logfile = Log::Log4perl::Appender::File
        log4perl.appender.Logfile.filename = $file_path
        log4perl.appender.Logfile.mode = append
        log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Logfile.layout.ConversionPattern = %d %p - %m%n
    );
    Log::Log4perl::init( \$log_conf );
    return Log::Log4perl::get_logger();

}

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::App::Role::Log4perl - Add basic Log::Log4perl logging to a MooseX::App application as a role.

=head1 SYNOPSIS

    use MooseX::App::Simple;

    with MooseX::App::Role::Log4perl
    
    sub run
    {
        my $self = shift;

        $self->log->debug("This is a DEBUG message");
        $self->log->info("This is an INFO message");
        $self->log->warn("This is a WARN message");
        $self->log->error("This is an ERROR message");
        $self->log->fatal("This is a FATAL message");

    }

=head1 DESCRIPTION

The is a role built for CLI apps using the MooseX::App framework. It adds the following command line options:

    --logfile #write log4perl output to a file
    --debug   #include your debug log messages
    --quiet   #suppress output to the terminal (STDOUT)

By default this role will only log messages to STDOUT with INFO or higher priority.

=head1 LICENSE

Copyright (C) John Dexter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

John Dexter 

=cut
