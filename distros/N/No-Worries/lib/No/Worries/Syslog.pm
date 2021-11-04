#+##############################################################################
#                                                                              #
# File: No/Worries/Syslog.pm                                                   #
#                                                                              #
# Description: syslog handling without worries                                 #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Syslog;
use strict;
use warnings;
use 5.005; # need the four-argument form of substr()
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.24 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Encode qw();
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::Log qw();
use No::Worries::String qw(string_trim);
use Params::Validate qw(validate :types);
use Sys::Syslog qw(openlog closelog syslog);
use URI::Escape qw(uri_escape);

#
# global variables
#

our($MaximumLength, $SplitLines);

#
# open a "connection" to syslog via openlog()
#

my %syslog_open_options = (
    ident    => { optional => 1, type => SCALAR, regex => qr/^[\w\-\.\/]+$/ },
    option   => { optional => 1, type => SCALAR, regex => qr/^\w+(,\w+)*$/ },
    facility => { optional => 1, type => SCALAR, regex => qr/^\w+$/ },
);

sub syslog_open (@) {
    my(%option);

    %option = validate(@_, \%syslog_open_options) if @_;
    # defaults which may differ from Sys::Syslog
    $option{option} = "ndelay,pid" unless $option{option};
    # we do not allow "nofatal" as this clashes with our error handling
    $option{option} =~ s/\bnofatal\b//g if $option{option};
    # simply call openlog() now...
    eval { openlog($option{ident}, $option{option}, $option{facility}) };
    dief("cannot openlog(): %s", $@) if $@;
}

#
# close a "connection" to syslog via closelog()
#

sub syslog_close () {
    # simply call closelog()
    eval { closelog() };
    dief("cannot closelog(): %s", $@) if $@;
}

#
# sanitize a string so that it can safely be given to syslog
#

sub syslog_sanitize ($) {
    my($string) = @_;
    my($flags, $tmp);

    $flags = "";
    # 1: try to UTF-8 encode it if it has the UTF-8 flag set
    if (Encode::is_utf8($string)) {
        # we use Encode::FB_DEFAULT to replace invalid characters
        local $@ = ""; # preserve $@!
        $tmp = Encode::encode("UTF-8", $string, Encode::FB_DEFAULT);
        unless ($tmp eq $string) {
            # encoded is indeed different, use it
            $string = $tmp;
            $flags .= "U";
        }
    }
    # 2: silently trim trailing spaces and replace tabs
    $string =~ s/\s+$//;
    $string =~ s/\t/    /g;
    # 3: try to URI escape non-printable characters plus # % \ `
    $tmp = uri_escape($string, q{\x00-\x1f\x7f-\xff\x23\x25\x5c\x60});
    unless ($tmp eq $string) {
        # escaped is indeed different, use it
        $string = $tmp;
        $flags .= "E";
    }
    # 4: truncate if it is too long, taking into acount the possible flags
    $tmp = length($string) - $MaximumLength + 4;
    if ($tmp > 0) {
        substr($string, $MaximumLength - 4, $tmp, "");
        $flags .= "T";
    }
    # 5: append the flags to keep track of what happened to the string
    $string .= "#$flags" if $flags;
    # that should be enough...
    return($string);
}

#
# handy wrappers around syslog()
#

sub _syslog_any ($$@) {
    my($priority, $prefix, $message, @arguments) = @_;
    my($separator, $string);

    $message = sprintf($message, @arguments) if @arguments;
    $message = string_trim($message);
    $separator = " ";
    if ($SplitLines and $message =~ /\n/) {
        # multiple syslog entries
        foreach my $line (split(/\n/, $message)) {
            $string = syslog_sanitize("[$prefix]$separator$line");
            eval { syslog($priority, $string) };
            dief("cannot syslog(): %s", $@) if $@;
            $separator = "+";
        }
    } else {
        # one syslog entry
        $string = syslog_sanitize("[$prefix]$separator$message");
        eval { syslog($priority, $string) };
        dief("cannot syslog(): %s", $@) if $@;
    }
}

sub syslog_error   ($@) { _syslog_any("err",     "ERROR",   @_) }
sub syslog_warning ($@) { _syslog_any("warning", "WARNING", @_) }
sub syslog_info    ($@) { _syslog_any("info",    "INFO",    @_) }
sub syslog_debug   ($@) { _syslog_any("debug",   "DEBUG",   @_) }

#
# No::Worries::Log-compatible handler
#

sub log2syslog ($) {
    my($info) = @_;

    if ($info->{level} eq "error") {
        syslog_error($info->{message});
    } elsif ($info->{level} eq "warning") {
        syslog_warning($info->{message});
    } elsif ($info->{level} eq "info") {
        syslog_info($info->{message});
    } else {
        syslog_debug($info->{message}); # for debug _and_ trace
    }
    return(1);
}

#
# module initialization
#

$MaximumLength = 1000;
$SplitLines = 1;

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++,
         map("syslog_$_", qw(open close sanitize error warning info debug)));
    $exported{"log2syslog"} = sub { $No::Worries::Log::Handler = \&log2syslog };
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__ 

=head1 NAME

No::Worries::Syslog - syslog handling without worries

=head1 SYNOPSIS

  use No::Worries::Syslog qw(syslog_open syslog_close syslog_info);

  # setup/open syslog
  syslog_open(ident => "progname", facility => "daemon");

  # report an informational message
  syslog_info("foo is %s", $foo);

  # close syslog
  syslog_close();

=head1 DESCRIPTION

This module eases syslog handling by providing convenient wrappers
around standard syslog functions.

The functions provide a thin layer on top of L<Sys::Syslog> to make it
easier and safer to use. All the functions die() on error and the
strings passed to syslog will always be sanitized.

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item syslog_open([OPTIONS])

open a "connection" to syslog using L<Sys::Syslog>'s openlog();
supported options

=over

=item * C<facility>: corresponding to openlog()'s eponymous argument

=item * C<ident>: corresponding to openlog()'s eponymous argument

=item * C<option>: corresponding to openlog()'s eponymous argument

=back

=item syslog_close()

close a "connection" to syslog using L<Sys::Syslog>'s closelog()

=item syslog_sanitize(STRING)

sanitize the given string so that it can safely be given to syslog():
UTF-8 encode wide characters, trim trailing spaces, replace tabs by
spaces, URI escape non-printable characters and truncate if too long

=item syslog_debug(MESSAGE)

report a sanitized debugging message to syslog
(with LOG_DEBUG priority and C<[DEBUG]> prefix)

=item syslog_debug(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item syslog_info(MESSAGE)

report a sanitized informational message to syslog
(with LOG_INFO priority and C<[INFO]> prefix)

=item syslog_info(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item syslog_warning(MESSAGE)

report a sanitized warning message to syslog
(with LOG_WARNING priority and C<[WARNING]> prefix)

=item syslog_warning(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item syslog_error(MESSAGE)

report a sanitized error message to syslog
(with LOG_ERR priority and C<[ERROR]> prefix)

=item syslog_error(FORMAT, ARGUMENTS...)

idem but with sprintf()-like API

=item log2syslog(INFO)

L<No::Worries::Log> handler to send information to syslog; this is not
exported and must be called explicitly

=back

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being
exported):

=over

=item $MaximumLength

maximum length of a message given to syslog (default: 1000)

=item $SplitLines

true if multi-line messages should be logged as separate syslog
messages (default: true)

=back

=head1 SEE ALSO

L<No::Worries>,
L<No::Worries::Die>,
L<No::Worries::Log>,
L<No::Worries::Warn>,
L<Sys::Syslog>,
L<URI::Escape>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
