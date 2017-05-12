##==============================================================================
## Module::Check_Args - a quick way to check argument counts
##==============================================================================
## $Id: Check_Args.pm,v 1.1 2000/11/04 18:46:06 kevin Exp $
##==============================================================================
require 5.000;

package Module::Check_Args;
use strict;
use Exporter ();
use vars qw{@EXPORT @ISA $VERSION %_PROCS};
@ISA = qw{Exporter};
@EXPORT = qw{exact_argcount range_argcount atleast_argcount atmost_argcount};
($VERSION) = q$Revision: 1.1 $ =~ /Revision:\s+([^\s]+)/;

use constant no_dieproc => "no behavior set for Module::Check_Args - 'import' never called?";

=head1 NAME

Module::Check_Args - a quick way to check argument counts for methods

=head1 SYNOPSIS

use Module::Check_Args;

exact_argcount I<$argcnt>;

range_argcount I<$minargs>, I<$maxargs>;

atleast_argcount I<$minargs>;

atmost_argcount I<$maxargs>;

=head1 DESCRIPTION

When writing a complex program, some of the hardest problems to track down
are subroutines that aren't called with the right arguments.  Perl provides
a means to check this at compile time, but there is no way to do this for
subroutines that take a variable number of arguments or for object methods.
C<Module::Check_Args> provides routines that check the number of arguments
passed to their callers and raise an exception if the number passed doesn't
match the number expected.  It's possible to specify that the number of
arguments must be exactly I<n>, at most I<n>, at least I<n>, or between
I<n> and I<m>.

When using these routines from within a method, be sure to account for the
implicit first argument containing the object reference or class name!

By default, the four _argcount routines are exported.

By importing the following pseudo-symbols, you can request various
behaviors from C<Module::Check_Args>:

=over 4

=item use Module::Check_Args qw(-die);

Specifies that an argument count mismatch is a fatal error.  The message will
give the file and line number of the call containing the bad number of
arguments.  This is the default.

=item use Module::Check_Args qw(-warn);

An argument mismatch is a warning only.

=item use Module::Check_Args qw(-off);

No argument-count checking is performed.  The four checking routines are still
exported, so that you don't need to change code that contains them, but they
are dummy procedures.

=back

If you have multiple packages that use Module::Check_Args, each one can have
different behavior.

=cut
##------------------------------------------------------------------------------
## import
##------------------------------------------------------------------------------
sub _dummy_proc { };

sub import {
    my $module = shift;
    my @options = grep { /^-/ } @_;
    die "only one -option allowed to ${module}::import\n" if @options > 1;
    my $option = shift(@options) || '-die';
    @_ = grep { ! /^-/ } @_;
    my ($calling_package, $filename, $line) = caller;
    ##
    ## Set up the procedures to handle various methods of reporting the error.
    ##
    my %subs = (
        -die => sub {
            my ($package, $filename, $line, $subroutine) = caller(2);
            die "$filename($line): ", @_, "\n";
        },
        -warn  => sub {
            my ($package, $filename, $line, $subroutine) = caller(2);
            warn "$filename($line): ", @_, "\n";
        },
        -off => 1
    );
    die "'$option' invalid in ${module}::import from $calling_package ($filename, line $line)\n"
        unless exists $subs{$option};
    ##
    ## If the option is -off, export dummy subroutines that don't actually do anything.
    ##
    if ($option eq '-off') {
        no strict 'refs';
        *{"$calling_package\::exact_argcount"} = *_dummy_proc;
        *{"$calling_package\::atleast_argcount"} = *_dummy_proc;
        *{"$calling_package\::atmost_argcount"} = *_dummy_proc;
        *{"$calling_package\::range_argcount"} = *_dummy_proc;
    } else {
        $_PROCS{$calling_package} = $subs{$option};
        unshift(@_, $module);
        goto &Exporter::import;
    }
}

=head2 Routines

=over 4

=item exact_argcount I<$argcnt>;

Specifies that the caller must have exactly I<$argcnt> arguments.

=cut
##------------------------------------------------------------------------------
## exact_argcount
##------------------------------------------------------------------------------
sub exact_argcount ($) {
    my $dieproc = $_PROCS{scalar(caller)} or die no_dieproc;
    package DB;
    use Carp;
    use vars qw(@args);
    croak "wrong argument count to Module::Check_Args::exact_argcount" unless @_ == 1;
    my $argcount = shift;
    my (@callerdata) = caller(1);
    unless (@args == $argcount) {
        $dieproc->(
            "wrong number of arguments to \&$callerdata[3] - was ",
            scalar(@args),
            ", should be $argcount"
        );
    }
}

=item range_argcount I<$minargs>, I<$maxargs>;

Specifies that the caller must have at least I<$minargs> arguments but no more
than I<$maxargs>.

=cut
##------------------------------------------------------------------------------
## range_argcount
##------------------------------------------------------------------------------
sub range_argcount ($$) {
    my $dieproc = $_PROCS{scalar(caller)} or die no_dieproc;
    package DB;
    croak "wrong argument count to Module::Check_Args::range_argcount" unless @_ == 2;
    my ($minargs, $maxargs) = @_;
    my (@callerdata) = caller(1);
    unless (@args >= $minargs && @args <= $maxargs) {
        $dieproc->(
            "wrong number of arguments to \&$callerdata[3] - was ",
            scalar(@args),
            ", should be between $minargs and $maxargs"
        );
    }
}

=item atleast_argcount I<$minargs>;

Specifies that the caller must have at least I<$minargs> arguments, but can have
any number more than that.

=cut
##------------------------------------------------------------------------------
## atleast_argcount
##------------------------------------------------------------------------------
sub atleast_argcount ($) {
    my $dieproc = $_PROCS{scalar(caller)} or die no_dieproc;
    package DB;
    croak "wrong argument count to Module::Check_Args::atleast_argcount" unless @_ == 1;
    my $minargs = shift;
    my (@callerdata) = caller(1);
    unless (@args >= $minargs) {
        $dieproc->(
            "not enough arguments to \&$callerdata[3] - was ",
            scalar(@args),
            ", should be at least $minargs"
        );
    }
}

=pod

=item atmost_argcount I<$maxargs>;

Specifies that the caller must have at most I<$maxargs> arguments, but can have
any number up to that, including zero.

=cut
##------------------------------------------------------------------------------
## atmost_argcount
##------------------------------------------------------------------------------
sub atmost_argcount ($) {
    my $dieproc = $_PROCS{scalar(caller)} or die no_dieproc;
    package DB;
    croak "wrong argument count to Module::Check_Args::atmost_argcount" unless @_ == 1;
    my $maxargs = shift;
    my (@callerdata) = caller(1);
    unless (@args <= $maxargs) {
        $dieproc->(
            "too many arguments to \&$callerdata[3] - was ",
            scalar(@args),
            ", should be no greater than $maxargs"
        );
    }
}

=back

=head1 DIAGNOSTICS

=over 4

=item wrong argument count to Module::Check_Args::I<routine>

One of the argument count checking routines was itself called with an invalid
argument count.  This is always a fatal error regardless of the behavior
specified in the B<use> declaration.

=item I<file>(I<line>): too many arguments to I<routine> - was %d, should be no greater than %d

=item I<file>(I<line>): not enough arguments to I<routine> - was %d, should be at least %d

=item I<file>(I<line>): wrong number of arguments to I<routine> - was %d, should be between %d and %d

=item I<file>(I<line>): wrong number of arguments to I<routine> - was %d, should be %d

I<routine> was called with an invalid number of arguments at the indicated location.
These messages are either fatal errors or warnings depending on the behavior specified
in the B<use> declaration.

=item no behavior set for Module::Check_Args - 'import' never called?

One of the argument count check routines was called, but no behavior
(-die, -warn) had ever been set.  This can only happen if you use
something like the following combination of commands:

    use Module::Check_Args ();
    ...
    &Module::Check_Args::exact_argcount(3);

Don't do that.

=back

=head1 SEE ALSO

perlfunc -f caller

=head1 AUTHOR

Kevin Michael Vail <kevin@vailstar.com>

=cut

1;

##==============================================================================
## $Log: Check_Args.pm,v $
## Revision 1.1  2000/11/04 18:46:06  kevin
## $module::import != ${module}::import
##
## Revision 1.0  2000/11/04 18:42:27  kevin
## Initial revision
##==============================================================================
