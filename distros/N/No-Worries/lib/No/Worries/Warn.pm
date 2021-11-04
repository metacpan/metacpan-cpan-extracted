#+##############################################################################
#                                                                              #
# File: No/Worries/Warn.pm                                                     #
#                                                                              #
# Description: warning handling without worries                                #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Warn;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

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
# kind of warn() with sprintf()-like API
#

sub warnf ($@) {
    my($message, @arguments) = @_;

    $message = sprintf($message, @arguments) if @arguments;
    warn(string_trim($message) . "\n");
}

#
# reasonable warn() handler
#

sub handler ($) {
    my($message) = @_;

    $message = string_trim($message);
    if ($ENV{NO_WORRIES}) {
        if ($ENV{NO_WORRIES} =~ /\b(cluck)\b/) {
            $message = longmess($message);
            goto done;
        }
        if ($ENV{NO_WORRIES} =~ /\b(carp)\b/) {
            $message = shortmess($message);
            goto done;
        }
    }
    $message .= "\n";
  done:
    if ($Syslog) {
        unless (defined(&No::Worries::Syslog::syslog_warning)) {
            eval { require No::Worries::Syslog };
            if ($@) {
                warn($@);
                $Syslog = 0;
            }
        }
        if ($Syslog) {
            eval { No::Worries::Syslog::syslog_warning($message) };
            warn($@) if $@;
        }
    }
    warn($Prefix . " " . $message);
}

#
# module initialization
#

# we tell Carp to treat our package as being internal
$Carp::Internal{ (__PACKAGE__) }++;

# we set a default prefix
$Prefix = length($ProgramName) ? "$ProgramName\!" : "*";

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(warnf));
    $exported{"handler"} = sub { $SIG{__WARN__} = \&handler };
    $exported{"syslog"} = sub { $Syslog = 1 };
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__ 

=head1 NAME

No::Worries::Warn - warning handling without worries

=head1 SYNOPSIS

  use No::Worries::Warn qw(warnf handler);

  if (open($fh, "<", $path)) {
      ... so something in case of success ...
  } else {
      warnf("cannot open(%s): %s", $path, $!);
      ... do something else in case of failure ...
  }

  $ ./myprog
  myprog: cannot open(foo): No such file or directory

  $ NO_WORRIES=cluck ./myprog
  myprog: cannot open(foo): No such file or directory at myprog line 16
      main::test() called at ./myprog line 19

=head1 DESCRIPTION

This module eases warning handling by providing a convenient wrapper
around warn() with sprintf()-like API. warnf() is to warn() what printf()
is to print() with, in addition, the trimming of leading and trailing
spaces.

It also provides a handler for warn() that prepends a prefix
($No::Worries::Warn::Prefix) to all warnings. It also uses the
C<NO_WORRIES> environment variable to find out if L<Carp>'s carp() or
cluck() should be used instead of warn(). Finally, the wrapper can be
told to also log warnings to syslog (see $No::Worries::Warn::Syslog).

This handler can be installed simply by importing it:

  use No::Worries::Warn qw(warnf handler);

Alternatively, it can be installed "manually":

  use No::Worries::Warn qw(warnf);
  $SIG{__WARN__} = \&No::Worries::Warn::handler;

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item warnf(MESSAGE)

report a warning described by the given MESSAGE

=item warnf(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item handler(MESSAGE)

$SIG{__WARN__} compatible warning handler (this function cannot be imported)

=back

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being
exported):

=over

=item $Prefix

prefix to prepend to all warnings (default: the program name)

=item $Syslog

true if warnings should also be sent to syslog using
L<No::Worries::Syslog>'s syslog_warning() (default: false)

=back

=head1 ENVIRONMENT VARIABLES

This module uses the C<NO_WORRIES> environment variable to control how
warnings should be reported. Supported values are:

=over

=item C<carp>

L<Carp>'s carp() will be used instead of warn()

=item C<cluck>

L<Carp>'s cluck() will be used instead of warn()

=back

=head1 SEE ALSO

L<Carp>,
L<No::Worries>,
L<No::Worries::Die>,
L<No::Worries::Syslog>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
