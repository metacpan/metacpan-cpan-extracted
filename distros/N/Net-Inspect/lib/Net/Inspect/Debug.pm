use strict;
use warnings;
package Net::Inspect::Debug;

use base 'Exporter';
our @EXPORT = qw(debug trace);
our @EXPORT_OK = qw($DEBUG $DEBUG_RX %TRACE xdebug xtrace);

our $DEBUG = 0;          # is debugging enabled at all
our $DEBUG_RX = undef;   # debug only packages matching given regex
my  $DEBUG_SUB = undef;  # external debug function to call instead of internal
my  $OUTPUT_SUB = undef; # external output function to call instead of internal

# import exported stuff, special case var => \$debug, func => \$code
sub import {
    # on default import go immediately to Exporter
    goto &Exporter::import if @_ == 1;

    # extract var => \$var from import and alias it to DEBUG
    # extract sub => \$code and set $DEBUG_SUB
    for(my $i=1;$i<@_;$i++) {
	if ( $_[$i] eq 'var' ) {
	    *DEBUG = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	} elsif ( $_[$i] eq 'sub' ) {
	    $DEBUG_SUB = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	} elsif ( $_[$i] eq 'output' ) {
	    $OUTPUT_SUB = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	} elsif ( $_[$i] =~m{^(?:debug)?(\d+)$} ) {
	    $DEBUG = $1;
	    splice(@_,$i,1);
	    $i--;
	}
    }

    # call Exporter only if we have remaining args, because we don't
    # want to trigger the default export if user gave args (e.g. var,sub)
    goto &Exporter::import if @_>1;
}

# print out debug message or forward to external debug func
sub debug {
    $DEBUG or return;
    my $msg = shift;
    $msg = do { no warnings; sprintf($msg,@_) } if @_;
    if ( $DEBUG_SUB ) {
	@_ = ($msg);
	# goto foreign debug sub
	# if DEBUG_RX is set this will be done later
	goto &$DEBUG_SUB if ! $DEBUG_RX;
    }

    my ($pkg,$line) = (caller(0))[0,2];
    if ( $DEBUG_RX ) {
	$pkg ||= 'main';
	# does not match wanted package
	return if $pkg !~ $DEBUG_RX;
	# goto foreign debug sub
	goto &$DEBUG_SUB if $DEBUG_SUB;
    }

    my $sub = (caller(1))[3];
    $sub =~s{^main::}{} if $sub;
    $sub ||= 'Main';
    $msg =~ s{
	(\\)
	| (\r)
	| (\n)
	| (\t)
	| ([\x00-\x1f\x7f-\xff])
    }{
	$1 ? "\\\\" :
	$2 ? "\\r" :
	$3 ? "\\n" :
	$4 ? "\\t" :
	sprintf("\\x%02x",ord($5))
    }xesg;
    $msg = "${sub}[$line]: ".$msg;

    if ( $OUTPUT_SUB ) {
	$OUTPUT_SUB->( DEBUG => $msg );
    } else {
	$msg =~s{^}{DEBUG: }mg;
	print STDERR $msg,"\n";
    }
}

sub xdebug {
    $DEBUG or return;
    my $obj = shift;
    my $msg = shift;
    unshift @_,"[$obj] $msg";
    goto &debug;
}

our %TRACE;
sub trace {
    %TRACE or return;
    my $pkg = lc((caller(0))[0]);
    $pkg =~s/.*:://;
    $TRACE{$pkg} or $TRACE{'*'} or return;

    my $msg = shift;
    $msg = sprintf($msg,@_) if @_;

    if ( $OUTPUT_SUB ) {
	$OUTPUT_SUB->( "TRACE[$pkg]" => $msg );
    } else {
	$msg =~s{\n}{\n  *  }g;
	$msg =~s{\A}{[$pkg]: };
	print STDERR $msg,"\n";
    }
}

sub xtrace {
    %TRACE or return;
    my $obj = shift;
    my $msg = shift;
    unshift @_, "[$obj] $msg";
    goto &trace;
}


1;
__END__

=head1 NAME

Net::Inspect::Debug - provides debugging facilities for Net::Inspect library

=head1 DESCRIPTION

the following functionality is provided:

=over 4

=item debug(msg,[@args])

if C<$DEBUG> is set prints out debugging message, prefixed with "DEBUG" and info
about calling function and code line. If C<@args> are given C<msg> is considered
and format string which will be combined with C<@args> to the final message.

This function is exported by default.

=item xdebug(object,...)

Same es debug, but prefixed with object.
Usually overwritten in classes to show info about object.

This function can be exported on demand.

=item trace(msg,[@args])

if C<$TRACE{'*'}> or C<$TRACE{$$pkg}>' is set prints out trace message, prefixed
with "[$pkg]". C<$pkg> is the last part of the package name, where trace got
called.
If C<@args> are given C<msg> is considered and format string which will be
combined with C<@args> to the final message.

This function is exported by default.

=item xtrace(object,...)

Same es trace, but prefixed with object.
Usually overwritten in classes to show info about object.

This function can be exported on demand.

=item $DEBUG

If true debugging messages will be print.
Can be explicitly imported, but is not exported by default.

=item $DEBUG_RX

This variable can contain a regex.
If set, only debugging within packages matching the regex will be enabled, but
only if c<$DEBUG> is also true.

Can be explicitly imported, but is not exported by default.

=item %TRACE

If true for '*' or C<$pkg> (see C<trace>) trace messages will be print.
Can be explicitly imported, but is not exported by default.

=back

To integrate the debugging of L<Net::Inspect> with other debugging frameworks
one has to call one of

  Net::Inspect::Debug var => \$myDEBUG, sub => \&my_debug;
  Net::Inspect::Debug var => \$myDEBUG, output => \&my_output;

as early as possible (before any modules using L<Net::IMP>s debug functionality
get loaded).

=over 4

=item var => \$myDEBUG

This make the local C<$DEBUG> variable an alias for C<$myDEBUG>.
C<$myDEBUG> needs to be a global variable, lexical variables will not work.

=item sub => \&my_debug

This will call C<my_debug> with the debug message instead of using the builtin
implementation.

=item output => \&my_output

This will call C<my_output> instead of the printing to STDERR done within
the internal (x)debug and (x)trace functions.

=back

To ease debugging one could give a number C<D> of C<debugD> as debug level
directly when importing the module, e.g.

   perl -MNet::Inspect::Debug=10 ...
   use Net::Inspect::Debug 'debug10';
