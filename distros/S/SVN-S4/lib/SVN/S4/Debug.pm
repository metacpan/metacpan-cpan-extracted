# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Debug;
use Carp;
use Time::HiRes qw(gettimeofday tv_interval);

use vars qw($VERSION $_GlobalDebug);
use strict;

use Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(DEBUG INFO CONSOLE debug_option);
#                   #also:   $Debug is_debug package_debug

$VERSION = "2.000";

our %_PackImported;
our $_ShowAny;
our $_ShowDeltas;

BEGIN {
    $_GlobalDebug = 0 if !$_GlobalDebug;   # Default 0, so can "is_debug>=2" without unused warning
}
debug_option('-debugi',$ENV{S4_DEBUG}) if $ENV{S4_DEBUG};

our $_Last_Timevec;

######################################################################
# Import magic

sub import {
    my ($pack,@imports) = @_;
    my $callpack = caller;
    return if $_PackImported{$callpack}++;  # Import only once to avoid multiple redeclarations
    #use Data::Dumper; print "Import ",Dumper($callpack,$pack,\@imports),"\n";
    # Form special debug variable and functions
    eval qq{
	package $callpack;
	use vars qw (\$Debug);
	package $callpack;
	sub is_debug { \$Debug || \$SVN::S4::Debug::_GlobalDebug; }
    };
    my @to_export;
    foreach my $imp (@imports) {
	# These functions and variables must be in the importer's package,
	# because $Debug needs to be per-package, and FAST.
	if ($imp eq '$Debug') {  # Special, always required
	} elsif ($imp eq 'is_debug') {  # Special, always required
	} elsif ($imp eq 'package_debug') {
	    eval qq{
		package $callpack;
		sub package_debug { \$Debug=\$_[0] if defined \$_[0]; return \$Debug; }
	    };
	} else {
	    push @to_export, $imp;
	}
    }
    SVN::S4::Debug->export_to_level(1, $pack, @to_export);
}

######################################################################
# Debug and features on/off

sub debug_option {
    my $flag = shift;
    my $value = shift;
    if ($value =~ /^[0-9]+$/) {  # Set global level
	global_debug($value);
    } elsif ($value =~ /^([a-zA-Z0-9_:]+):(\d+)/) {  # Set one module's level
	eval "\$$1::Debug = $2;";
    } else {
	croak "%Error: Illegal debug option format: $flag $value,";
    }
}
sub global_debug {
    $_GlobalDebug = $_[0] if defined $_[0];
    return $_GlobalDebug;
}
sub show_deltas {
    $_ShowDeltas = $_[0] if defined $_[0];
    _recalc();
    return $_ShowDeltas;
}
sub _recalc {
    $_ShowAny = $_ShowDeltas;
}

######################################################################

sub DEBUG {
    logmsg (*STDERR,1, @_);
}
sub INFO {
    logmsg (*STDOUT,0, @_);
}
sub CONSOLE {
    logmsg (*STDERR,0, @_);
}

sub logmsg {
    my $fh = shift;
    my $trace = shift;  # If non-zero, number of levels up to find filename
    my $msg = join('',@_);
    if ($_ShowAny || $trace) {
	my $prepend = sprintf("%s%05d ", "s4-", $$);
	my $time = [gettimeofday()];
	my ($sec,$min,$hour,$mday,$mon) = localtime($time->[0]);
	$prepend .= sprintf("%02d:%02d:%02d.%06d",
			    $hour, $min, $sec, $time->[1]);
	if ($_ShowDeltas) {
	    $_Last_Timevec ||= $time;
	    my $dtime = tv_interval($_Last_Timevec,$time);
	    $prepend .= sprintf("+%04d.%06d", int($dtime), int($dtime*1e6)%1e6);
	    $_Last_Timevec = $time;
	}
	my $ket = "} ";
	if ($trace) {
	    $prepend .= " " if $prepend;
	    my ($class,$fn,$ln) = caller($trace);
	    $fn =~ m!(.*[/\\])(.*)$!;
	    my $path = $1; my $base = $2;
	    $base =~ s!\.(pl|pm)$!!;
	    $base = substr($base,0,12);
	    my $left = 12-length($base);
	    $base = substr($path,length($path)-$left).$base;
	    $prepend .= sprintf("%-19s",$base.":".sprintf("%04d",$ln)."}");
	    $ket = " ";
	}
	$msg = "{".$prepend.$ket.$msg if $prepend;
    }
    $fh->print($msg);  # Print in one call, tis faster
}

######################################################################
######################################################################
######################################################################
######################################################################
1;
__END__

=pod

=head1 NAME

SVN::S4::Debug - Allow debug messages to be easily switched on and off.

=head1 SYNOPSIS

  use SVN::S4::Debug qw(INFO DEBUG is_debug);
  INFO ("informational message");
  DEBUG ("debug message") if is_debug>=2;

=head1 DESCRIPTION

SVN::S4::Debug functions are used instead of print, to allow control
over all log messages work in a unified way.

Debug levels can be controlled globally, or via a per-package $Debug
variable that is created automatically.  (However, it's more general to
test the is_debug method in scripts, unless it is a very hot function.)

Conventions for inside BugVise (but not required by this module) are that
debug level 1 is for high-level messages for program debug.  Levels 2 and
above are for package debug, 2 being common, and above 2 being very
verbose.

=head1 METHODS

=over 4

=item INFO

Print an informational message.

=item DEBUG

Print a debug message.

=item debug_option I<switch>

Enable debug on all modules, based on the command line argument passed.
This is typically called from a Getopt::Long parser.  Options supported
are: "--debug" will set debug level 1 globally, and "--debugi {level}" will
set the global debug level to the specified value. "--debugi
{package}:{level}" to set debug on one package, and will also work on any
package that uses a $Debug variable.

=item global_debug I<level>

Enable debug on all modules.

=item is_debug

Return current debug level, or zero if not enabled.

=item package_debug I<level>

Enable debug on the current package.

=item show_deltas I<flag>

If true, print timestamps as relative to the last printout.

=back

=head1 ENVIRONMENT

=over 4

=item BUGVISE_DEBUG

If set, parse the contents of BUGVISE_DEBUG as a debug_option() at package
start time.

=back

=head1 DISTRIBUTION

Copyright 2007-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Log::Log4perl>

=cut
