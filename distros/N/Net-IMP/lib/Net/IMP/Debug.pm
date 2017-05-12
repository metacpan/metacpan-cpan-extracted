use strict;
use warnings;
package Net::IMP::Debug;

use base 'Exporter';
our @EXPORT = qw($DEBUG debug);
our @EXPORT_OK = qw($DEBUG_RX set_debug);

our $DEBUG = 0;          # is debugging enabled at all
our $DEBUG_RX = undef;   # debug only packages matching given regex
my  $DEBUG_SUB = undef;  # external debug function to call instead of internal

# import exported stuff, special case var => \$debug, func => \$code
sub import {
    # on default import go immediately to Exporter
    goto &Exporter::import if @_ == 1;

    # extract var => \$var from import and alias it to DEBUG
    # extract sub => \$code and set $DEBUG_SUB
    for(my $i=1;$i<@_-1;$i++) {
	if ( $_[$i] eq 'var' ) {
	    *DEBUG = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	} elsif ( $_[$i] eq 'rxvar' ) {
	    *DEBUG_RX = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	} elsif ( $_[$i] eq 'sub' ) {
	    $DEBUG_SUB = $_[$i+1];
	    splice(@_,$i,2);
	    $i-=2;
	}
    }

    # call Exporter only if we have remaining args, because we don't
    # want to trigger the default export if user gave args (e.g. var,sub)
    goto &Exporter::import if @_>1;
}

# set debugging properties
sub set_debug {
    $DEBUG    = $_[1] if @_>1 && defined $_[1];
    $DEBUG_RX = $_[2] if @_>2;
}

# print out debug message or forward to external debug func
sub debug {
    $DEBUG or return;
    my $msg = shift;
    $msg = sprintf($msg,@_) if @_;
    if ( $DEBUG_SUB ) {
	@_ = ($msg);
	# goto foreign debug sub
	# if DEBUG_RX is set this ill be done later
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
    $msg = "${sub}[$line]: ".$msg;

    $msg =~s{^}{DEBUG: }mg;
    print STDERR $msg,"\n";
}


1;
__END__

=head1 NAME

Net::IMP::Debug - provide debugging functions

=head1 SYNOPSIS

    # within Net::IMP packages
    use Net::IMP::Debug;
    ...
    debug('some msg');
    debug('got msg="%s" count=%d',$msg,$count);
    $DEBUG && debug('some msg');

    # outside of Net::IMP
    use Net::IMP;
    Net::IMP->set_debug(1,qr{::Pattern});

    # or integrate it into existing debugging framework
    # $myDebug needs to be global, not lexical!
    use myDebug qw(my_debug $myDEBUG);
    use Net::IMP::Debug var => \$myDEBUG, sub => \&my_debug;

=head1 DESCRIPTION

L<Net::IMP::Debug> provides debugging functions for use inside the L<Net::IMP>
packages.
It provides a way to debug only some packages and to make the internal
debugging use an external debug function for output.

The following API is defined for internal use:

=over 4

=item debug($message) | debug($format,@args)

Create a debug message.
It can be used with a single C<$message> or C<sprintf>-like with C<$format> and
C<@args>.

If message gets dynamically generated in an expensive way, it is better to
call C<debug> only if C<$DEBUG> is true, so that the message only gets
generated on active debugging.

If no external debug function is set (see below), the function will write the
message to STDERR, prefixed with subroutine name and line number.
If an external debug function is set, it will call this function with the
debug message, maintaining the calling stack (e.g. using C<goto>).

This function gets exported by default.

=item $DEBUG

This variable is true if debugging is on, else false.
It gets exported by default.

=item $DEBUG_RX

This variable can contain a regex.
If set, only debugging within packages matching the regex will be enabled, but
only if c<$DEBUG> is also true.

This variable can be exported.

=back

For external use the C<set_debug> function is provided.

=over 4

=item $class->set_debug(onoff,regex)

With this function one can enable/disable debugging.

If C<onoff> is defined it will enable (if true) or disable (if false)
debugging.

If C<regex> is given it will be used as a filter to decide, which packages can
write debug messages.
If explicitly given as C<undef> the value will be reset.

=back

To integrate the debugging of L<Net::IMP> with other debugging frameworks one
has to call

  Net::IMP::Debug var => \$myDEBUG, sub => \&my_debug;

as early as possible (before any modules using L<Net::IMP>s debug functionality
get loaded).

=over 4

=item var => \$myDEBUG

This make the local C<$DEBUG> variable an alias for C<$myDEBUG>.
C<$myDEBUG> needs to be a global variable, lexical variables will not work.

=item rxvar => \$myDEBUG_RX

This makes the local C<$DEBUG_RX> variable an alias for C<$myDEBUG_RX>.
C<$myDEBUG_RX> needs to be a global variable, lexical variables will not work.

=item sub => \&my_debug

This will call C<my_debug> with the debug message instead of using the builtin
implementation.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
