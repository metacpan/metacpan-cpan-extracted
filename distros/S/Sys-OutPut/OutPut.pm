# Sys::OutPut.pm
#
# Little Output Utility
#
# $Id: OutPut.pm,v 1.2 1998/01/19 03:56:49 aks Exp $
# $Source: /usr/cvsroot/perl/Sys-OutPut/OutPut.pm,v $
#
# I don't like to do "print STDERR" or "print STDOUT", so these
# little routines do it for me.  And, they take care of ensuring
# that newlines are output when appropriate.

package Sys::OutPut;

use Exporter;
@ISA    = qw( Exporter );
@EXPORT = qw( talk out put err debug );

$quiet = defined($::quiet) ? $::quiet : '' unless defined($quiet);
$debug = defined($::debug) ? $::debug : '' unless defined($debug); 

sub talk {
    &err(@_) unless $quiet;
    undef;
}

# out $FORMAT, $ARGS, ...

sub out {
    my $fmt = shift;
    $fmt = '' unless defined $fmt;	# avoid undef refs
    my @args = @_;
    $fmt .= "\n" if $fmt eq '' || substr($fmt,-1) ne "\n";
    printf STDOUT $fmt,@args;
    undef;
}

sub put {
    printf STDOUT @_;
    undef;
}

sub err {
    my $fmt = shift;
    $fmt = '' unless defined $fmt;	# avoid undef refs
    my @args = @_;
    $fmt .= "\n" if $fmt eq '' || substr($fmt,-1) ne "\n";
    printf STDERR $fmt,@args;
    undef;
}

sub debug {
    return '' unless $debug;
    &err(@_);
    1;
}

1;

__END__

=head1 NAME

Sys::OutPut -- Perl module to help make output easier.

=head1 SYNOPSIS

  usage Sys::OutPut;

  talk $fmtstr [, @args];

  out  $fmtstr [, @args];

  put  $fmtstr [, @args];

  err  $fmtstr [, @args];

  debug $fmtstr [, @args];

  $Sys::OutPut::quiet = $::quiet;

  $Sys::OutPut::debug = $::debug;

=head1 DESCRIPTION

These subroutines will make generating output to C<STDOUT> and C<STDERR>
easier.

All of the routines treat the I<$fmtstr> argument as a I<printf> format
string, with I<@args> as the format string arguments.

The B<talk> routine generates output to C<STDERR> only if the variable
C<$Sys::OutPut::quiet> is non-null and non-zero.

The B<out> routine generates output to C<STDOUT>, with a I<newline> 
appended to <$fmtstr>, if it is not already terminated with one.

The B<put> routine generates output to C<STDOUT>, without any 
additional trailing newline.

The B<err> routine generates output to C<STDERR>, with a I<newline>
appended if needed.

The B<debug> routine generates output to C<STDERR> only if the variable 
C<$Sys::OutPut::debug> is non-null and non-zero, which is also returned 
as the result.  This allows for convenient usages such as in the following 
example:

    sub foo {
	...
	return if debug "Stopping now.";
	...
	next if debug "Skipping further processing";
	...
    }

If not defined by the user, the C<$Sys::OutPut::quiet> and 
C<$Sys::OutPut::debug> variables are initialized from their 
corresponding main variables C<$::quiet> and C<$::debug>, 
respectively, unless they are already defined.

=head1 AUTHOR

Alan K. Stebbens <aks@sgi.com>

=head1 BUGS

