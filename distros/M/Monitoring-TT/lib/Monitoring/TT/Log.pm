package Monitoring::TT::Log;

use strict;
use warnings;
use utf8;
use Data::Dumper;

$Monitoring::TT::Log::Verbose = 1;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(error warn info debug trace log);

BEGIN {
    # check if we have ansi color support
    $Monitoring::TT::Log::has_ansi = 0;
    eval {
        require Term::ANSIColor;
        Term::ANSIColor->import();
    };
    $Monitoring::TT::Log::has_ansi = 1 unless $@;
    $Monitoring::TT::Log::has_ansi = 0 unless(-t STDIN && -t STDOUT);
}

#####################################################################

=head1 NAME

Monitoring::TT::Log - Loging Facility

=head1 DESCRIPTION

Generates output to STDOUT and STDERR

=head1 METHODS

=head2 error

write a error message to stderr

=cut
sub error {
    print STDERR color('red')   if $Monitoring::TT::Log::Verbose >= 0;
    _out($_[0],'error')         if $Monitoring::TT::Log::Verbose >= 0;
    print STDERR color('reset') if $Monitoring::TT::Log::Verbose >= 0;
    return "";
}

#####################################################################

=head2 warn

write a warning message to stderr

=cut
sub warn {
    print STDERR color('yellow') if $Monitoring::TT::Log::Verbose >= 1;
    _out($_[0],'warning')        if $Monitoring::TT::Log::Verbose >= 1;
    print STDERR color('reset')  if $Monitoring::TT::Log::Verbose >= 1;
    return "";
}

#####################################################################

=head2 info

write a info message to stdout

=cut
sub info {
    _out($_[0],'info') if $Monitoring::TT::Log::Verbose >= 2;
    return "";
}

#####################################################################

=head2 debug

write a debug message to stdout

=cut
sub debug {
    _out($_[0],'debug') if $Monitoring::TT::Log::Verbose >= 3;
    return "";
}

#####################################################################

=head2 trace

write a trace message to stdout

=cut
sub trace {
    _out($_[0],'trace') if $Monitoring::TT::Log::Verbose >= 4;
    return "";
}

#####################################################################

=head2 log

log something, if line starts with ERROR: its an error, info otherwise

=cut
sub log {
    my($msg) = @_;
    if(ref $msg) {
        info($msg);
        return "";
    }
    if($msg =~ m/^ERROR:/mx) {
        $msg =~ s/^ERROR:\s*//gmx;
        error($msg);
    }
    elsif($msg =~ m/^WARNING:/mx) {
        $msg =~ s/^WARNING:\s*//gmx;
        &warn($msg);
    } else {
        _out($msg, 'plain');
    }
    return "";
}

#####################################################################
sub _out {
    my($data, $lvl, $time) = @_;
    return "" unless defined $data;
    $time = $time || (scalar localtime());
    if(ref $data) {
        return _out(Dumper($data), $lvl, $time);
    }
    for my $line (split/\n/mx, $data) {
        if($lvl eq 'plain') {
            print $line, "\n";
            next;
        }
        my $txt = "[".$time."][".uc($lvl)."] ".$line."\n";
        if($lvl eq 'error' or $lvl eq 'warning') {
            print STDERR $txt;
        } else {
            print STDOUT $txt;
        }
    }
    return "";
}

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
