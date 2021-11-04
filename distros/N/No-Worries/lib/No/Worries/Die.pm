#+##############################################################################
#                                                                              #
# File: No/Worries/Die.pm                                                      #
#                                                                              #
# Description: error handling without worries                                  #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Die;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Carp qw(shortmess longmess);
use No::Worries qw($ProgramName);
use No::Worries::Export qw(export_control);
use No::Worries::String qw(string_trim);

#
# global variables
#

our($Prefix, $Syslog);

#
# kind of die() with sprintf()-like API
#

sub dief ($@) {
    my($message, @arguments) = @_;

    $message = sprintf($message, @arguments) if @arguments;
    die(string_trim($message) . "\n");
}

#
# reasonable die() handler
#

sub handler ($) {
    my($message) = @_;

    # do nothing if called parsing a module/eval or executing an eval
    return if not defined($^S) or $^S;
    # handle a "normal" error
    $message = string_trim($message);
    if ($ENV{NO_WORRIES}) {
        if ($ENV{NO_WORRIES} =~ /\b(confess)\b/) {
            $message = longmess($message);
            goto done;
        }
        if ($ENV{NO_WORRIES} =~ /\b(croak)\b/) {
            $message = shortmess($message);
            goto done;
        }
    }
    $message .= "\n";
  done:
    if ($Syslog) {
        unless (defined(&No::Worries::Syslog::syslog_error)) {
            eval { require No::Worries::Syslog };
            if ($@) {
                warn($@);
                $Syslog = 0;
            }
        }
        if ($Syslog) {
            eval { No::Worries::Syslog::syslog_error($message) };
            warn($@) if $@;
        }
    }
    die($Prefix . " " . $message);
}

#
# module initialization
#

# we tell Carp to treat our package as being internal
$Carp::Internal{ (__PACKAGE__) }++;

# we set a default prefix
$Prefix = length($ProgramName) ? "$ProgramName\:" : "***";

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(dief));
    $exported{"handler"} = sub { $SIG{__DIE__} = \&handler };
    $exported{"syslog"} = sub { $Syslog = 1 };
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__ 

=head1 NAME

No::Worries::Die - error handling without worries

=head1 SYNOPSIS

  use No::Worries::Die qw(dief handler);

  open($fh, "<", $path) or dief("cannot open(%s): %s", $path, $!);
  ... not reached in case of failure ...

  $ ./myprog
  myprog: cannot open(foo): No such file or directory

  $ NO_WORRIES=confess ./myprog
  myprog: cannot open(foo): No such file or directory at myprog line 16
      main::test() called at ./myprog line 19

=head1 DESCRIPTION

This module eases error handling by providing a convenient wrapper
around die() with sprintf()-like API. dief() is to die() what printf()
is to print() with, in addition, the trimming of leading and trailing
spaces.

It also provides a handler for die() that prepends a prefix
($No::Worries::Die::Prefix) to all errors. It also uses the C<NO_WORRIES>
environment variable to find out if L<Carp>'s croak() or confess()
should be used instead of die(). Finally, the wrapper can be told to
also log errors to syslog (see $No::Worries::Die::Syslog).

This handler can be installed simply by importing it:

  use No::Worries::Die qw(dief handler);

Alternatively, it can be installed "manually":

  use No::Worries::Die qw(dief);
  $SIG{__DIE__} = \&No::Worries::Die::handler;

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item dief(MESSAGE)

report an error described by the given MESSAGE

=item dief(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item handler(MESSAGE)

$SIG{__DIE__} compatible error handler (this function cannot be imported)

=back

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being
exported):

=over

=item $Prefix

prefix to prepend to all errors (default: the program name)

=item $Syslog

true if errors should also be sent to syslog using
L<No::Worries::Syslog>'s syslog_error() (default: false)

=back

=head1 ENVIRONMENT VARIABLES

This module uses the C<NO_WORRIES> environment variable to control how errors
should be reported. Supported values are:

=over

=item C<croak>

L<Carp>'s croak() will be used instead of die()

=item C<confess>

L<Carp>'s confess() will be used instead of die()

=back

=head1 SEE ALSO

L<Carp>,
L<No::Worries>,
L<No::Worries::Syslog>,
L<No::Worries::Warn>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
