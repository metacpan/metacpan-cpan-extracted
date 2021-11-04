#+##############################################################################
#                                                                              #
# File: No/Worries/Log.pm                                                      #
#                                                                              #
# Description: logging without worries                                         #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Log;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use IO::Handle qw();
use No::Worries qw($HostName $ProgramName);
use No::Worries::Date qw(date_stamp);
use No::Worries::Export qw(export_control);
use No::Worries::File qw(file_read);
use No::Worries::Die qw(dief);

#
# constants
#

use constant _LEVEL_ERROR   => "error";
use constant _LEVEL_WARNING => "warning";
use constant _LEVEL_INFO    => "info";
use constant _LEVEL_DEBUG   => "debug";
use constant _LEVEL_TRACE   => "trace";

#
# global variables
#

our($Handler);

our(
    %_KnownLevel,           # hash with known levels
    %_InterestingLevel,     # hash with interesting levels
    %_Level2Char,           # hash mapping levels to chars for the output
    $_MaybeInterestingInfo, # filtering sub (partial)
    $_InterestingInfo,      # filtering sub (complete)
    $_ConfigTag,            # dev:ino:mtime of the last configuration file used
);

#+++############################################################################
#                                                                              #
# configuring                                                                  #
#                                                                              #
#---############################################################################

#
# configure the module from the given file (if needed)
#

sub log_configure ($) {
    my($path) = @_;
    my(@stat, $tag);

    @stat = stat($path) or dief("cannot stat(%s): %s", $path, $!);
    $tag = join(":", $stat[0], $stat[1], $stat[9]);
    return(0) if $_ConfigTag and $_ConfigTag eq $tag;
    log_filter(file_read($path));
    $_ConfigTag = $tag;
    return(1);
}

#+++############################################################################
#                                                                              #
# filtering                                                                    #
#                                                                              #
#---############################################################################

#
# return the Perl code to use for a given filtering expression
#

sub _expr_code ($@) {
    my($partial, $attr, $op, $value) = @_;

    # for partial filtering, we do not care about the message
    return("1") if $attr eq "message" and $partial;
    # for the attributes we know about, it is easy
    return("\$info->{$attr} $op $value")
        if $attr =~ /^(level|time|program|host|file|line|sub|message)$/;
    # for the other attributes, the test always fails if not defined
    return("(defined(\$info->{$attr}) and \$info->{$attr} $op $value)");
}

#
# compile the given filter
#

sub _compile_filter ($@) {
    my($partial, @filter) = @_;
    my(@code, $code, $sub);

    @code = (
        "package No::Worries::Log::Filter;",
        "use strict;",
        "use warnings;",
        "\$sub = sub {",
        "  my(\$info) = \@_;",
        "  return(1) if",
    );
    foreach my $expr (@filter) {
        if (ref($expr) eq "ARRAY") {
            push(@code, "    " . _expr_code($partial, @{ $expr }));
        } else {
            push(@code, "    $expr");
        }
    }
    $code[-1] .= ";";
    push(@code,
         "  return(0);",
         "}",
    );
    $code = join("\n", @code);
    eval($code); ## no critic 'BuiltinFunctions::ProhibitStringyEval'
    dief("invalid code built: %s", $@) if $@;
    return($sub);
}

#
# parse a single filtering expression
#

sub _parse_expr ($$$) {
    my($line, $level, $expr) = @_;
    my($attr, $op, $value);

    # we first parse the (attr, op, value) triplet
    if ($_KnownLevel{$expr}) {
        # there can be only one level per filter line and we keep track of it
        dief("invalid filter line: %s", $line) if ${ $level };
        ${ $level } = $expr;
        ($attr, $op, $value) = ("level", "==", $expr);
    } elsif ($expr =~ /^(\w+)(==|!=)$/ and $1 ne "level") {
        # special case for comparison with empty string
        ($attr, $op, $value) = ($1, $2, "");
    } elsif ($expr =~ /^(\w+)(==|!=|=~|!~|>=?|<=?)(\S+)$/ and $1 ne "level") {
        # normal case
        ($attr, $op, $value) = ($1, $2, $3);
    } else {
        dief("invalid filter expression: %s", $expr);
    }
    # we then check the value
    if ($op eq "=~" or $op eq "!~") {
        # match: check that the value is a valid regular expression
        eval { $expr =~ /$value/ };
        dief("invalid regexp: %s", $value) if $@;
        $value = "m\0$value\0";
    } elsif ($op eq "==" or $op eq "!=") {
        # equality: adjust according to type
        unless ($value =~ /^-?\d+$/) {
            $op = $op eq "==" ? "eq" : "ne";
            $value = "qq\0$value\0";
        }
    } else {
        # numerical: check that the value is a valid integer
        dief("invalid integer: %s", $value) unless $value =~ /^-?\d+$/;
    }
    # so far, so good
    return([ $attr, $op, $value ]);
}

#
# parse and compile the filter to use
#

sub log_filter ($) {
    my($filter) = @_;
    my($and_re, $or_re, $level, @list, @filter, %il, $ii, $mii);

    # strip comments and empty lines and extra spaces
    @list = ();
    foreach my $line (split(/\n/, $filter)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ s/\s+/ /g;
        next if $line eq "" or $line =~ /^\#/;
        push(@list, $line);
    }
    $filter = join("\n", @list);
    # find out how to split lines and expressions
    if ($filter =~ /\s(and|or)\s/) {
        # with syntactical sugar
        $and_re = qr/\s+and\s+/;
        $or_re = qr/\s+or\s+/;
    } else {
        # without syntactical sugar
        $and_re = qr/ /;
        $or_re = qr/\n/;
    }
    # parse line by line
    foreach my $line (split($or_re, $filter)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq "" or $line =~ /^\#/;
        $level = "";
        @list = ();
        foreach my $expr (split($and_re, $line)) {
            $expr = _parse_expr($line, \$level, $expr);
            # each expression within a line is AND'ed
            push(@list, $expr, "and");
        }
        if ($level) {
            # one level specified
            $il{$level}++;
        } else {
            # no level specified => all are potentially interesting
            foreach my $kl (keys(%_KnownLevel)) {
                $il{$kl}++;
            }
        }
        # remove the last "and"
        pop(@list);
        # each line within a filter is OR'ed
        push(@filter, @list, "or");
    }
    if (@filter) {
        # non-empty filter => remove the last "or"
        pop(@filter);
    } else {
        # empty filter => default behavior
        %il = (_LEVEL_INFO() => 1);
        @filter = ("1");
    }
    $ii  = _compile_filter(0, @filter);
    $mii = _compile_filter(1, @filter);
    # so far, so good...
    %_InterestingLevel = %il;
    $_InterestingInfo = $ii;
    $_MaybeInterestingInfo = $mii;
}

#+++############################################################################
#                                                                              #
# outputting                                                                   #
#                                                                              #
#---############################################################################

#
# default handler: print compact yet user friendly output to STDOUT or STDERR
#

sub log2std ($) {
    my($info) = @_;
    my($id, $string, $fh);

    $id = $INC{"threads.pm"} ? "$info->{pid}.$info->{tid}": $info->{pid};
    $string = sprintf("%s %s %s[%s]: %s\n",
                      $_Level2Char{$info->{level}}, date_stamp($info->{time}),
                      $info->{program}, $id, $info->{message});
    $fh = $info->{level} eq _LEVEL_INFO ? *STDOUT : *STDERR;
    $fh->print($string);
    $fh->flush();
    return(1);
}

#
# dump handler: print all attributes to STDERR
#

sub log2dump ($) {
    my($info) = @_;
    my(@list);

    foreach my $attr (sort(keys(%{ $info }))) {
        if ($info->{$attr} =~ /^[\w\.\-\/]*$/) {
            push(@list, "$attr=$info->{$attr}");
        } else {
            push(@list, "$attr=\'$info->{$attr}\'");
        }
    }
    STDERR->print("% @list\n");
    STDERR->flush();
    return(1);
}

#+++############################################################################
#                                                                              #
# formatting                                                                   #
#                                                                              #
#---############################################################################

#
# format the message
#

sub _message ($$) {
    my($message, $info) = @_;
    my(@list, $format, $pos);

    @list = @{ $message };
    unless (@list) {
        # no message given => empty string
        return("");
    }
    $format = shift(@list);
    if (ref($format) eq "CODE") {
        # code message => result of the call
        return($format->(@list));
    }
    if (ref($format)) {
        # unexpected first argument
        dief("unexpected argument: %s", $format);
    }
    unless (@list) {
        # plain message
        return($format);
    }
    # sprintf message => format it
    $pos = 0;
    foreach my $arg (@list) {
        if (ref($arg) eq "SCALAR") {
            # attribute argument
            dief("unknown attribute: %s", ${ $arg })
                unless defined($info->{${ $arg }});
            $arg = $info->{${ $arg }};
        } elsif (not ref($arg)) {
            # plain argument
            dief("undefined argument at position %d", $pos)
                unless defined($arg);
        } else {
            dief("unexpected argument: %s", $arg);
        }
        $pos++;
    }
    return(sprintf($format, @list));
}

#+++############################################################################
#                                                                              #
# handling                                                                     #
#                                                                              #
#---############################################################################

#
# handle information
#

sub _handle ($$) {
    my($message, $info) = @_;
    my(@list);

    # build the info to log with minimal (= cheap to get) information
    $info->{time} = time();
    $info->{program} = $ProgramName;
    $info->{host} = $HostName;
    $info->{pid} = $$;
    $info->{tid} = threads->tid() if $INC{"threads.pm"};
    @list = caller(1);
    $info->{file} = $list[1];
    $info->{line} = $list[2];
    @list = caller(2);
    $info->{caller} = defined($list[3]) ? $list[3] : "main";
    # check if we may care about this info
    return(0) unless $_MaybeInterestingInfo->($info);
    # format the message
    $info->{message} = _message($message, $info);
    # we always strip trailing spaces
    $info->{message} =~ s/\s+$//;
    # check if we really care about this info
    return(0) unless $_InterestingInfo->($info);
    # now send it to the right final handler
    return($Handler->($info));
}

#+++############################################################################
#                                                                              #
# public API                                                                   #
#                                                                              #
#---############################################################################

#
# check whether a level is "active"
#

sub log_wants_error   () { return($_InterestingLevel{_LEVEL_ERROR()})   }
sub log_wants_warning () { return($_InterestingLevel{_LEVEL_WARNING()}) }
sub log_wants_info    () { return($_InterestingLevel{_LEVEL_INFO()})    }
sub log_wants_debug   () { return($_InterestingLevel{_LEVEL_DEBUG()})   }
sub log_wants_trace   () { return($_InterestingLevel{_LEVEL_TRACE()})   }

#
# log error information
#

sub log_error (@) {
    my(@args) = @_;
    my($attrs);

    return(0) unless $_InterestingLevel{_LEVEL_ERROR()};
    if (@args and ref($args[-1]) eq "HASH") {
        $attrs = pop(@args);
    } else {
        $attrs = {};
    }
    return(_handle(\@args, { %{ $attrs }, level => _LEVEL_ERROR }));
}

#
# log warning information
#

sub log_warning (@) {
    my(@args) = @_;
    my($attrs);

    return(0) unless $_InterestingLevel{_LEVEL_WARNING()};
    if (@args and ref($args[-1]) eq "HASH") {
        $attrs = pop(@args);
    } else {
        $attrs = {};
    }
    return(_handle(\@args, { %{ $attrs }, level => _LEVEL_WARNING }));
}

#
# log informational information ;-)
#

sub log_info (@) {
    my(@args) = @_;
    my($attrs);

    return(0) unless $_InterestingLevel{_LEVEL_INFO()};
    if (@args and ref($args[-1]) eq "HASH") {
        $attrs = pop(@args);
    } else {
        $attrs = {};
    }
    return(_handle(\@args, { %{ $attrs }, level => _LEVEL_INFO }));
}

#
# log debugging information
#

sub log_debug (@) {
    my(@args) = @_;
    my($attrs);

    return(0) unless $_InterestingLevel{_LEVEL_DEBUG()};
    if (@args and ref($args[-1]) eq "HASH") {
        $attrs = pop(@args);
    } else {
        $attrs = {};
    }
    return(_handle(\@args, { %{ $attrs }, level => _LEVEL_DEBUG }));
}

#
# log tracing information (fixed message)
#

sub log_trace () {
    return(0) unless $_InterestingLevel{_LEVEL_TRACE()};
    return(_handle(
        [ "in %s at %s line %s", \ "caller", \ "file", \ "line" ],
        { level => _LEVEL_TRACE },
    ));
}

#+++############################################################################
#                                                                              #
# module initialization                                                        #
#                                                                              #
#---############################################################################

# we select the relevant handler to use
if ($ENV{NO_WORRIES} and $ENV{NO_WORRIES} =~ /\b(log2dump)\b/) {
    $Handler = \&log2dump;
} else {
    $Handler = \&log2std;
};

# here are all the known levels
%_Level2Char = (
    error   => "!",
    warning => "?",
    info    => ":",
    debug   => "#",
    trace   => "=",
);
foreach my $level (keys(%_Level2Char)) {
    $_KnownLevel{$level}++;
}

# by default we only care about informational level or higher
%_InterestingLevel = %_KnownLevel;
delete($_InterestingLevel{_LEVEL_DEBUG()});
delete($_InterestingLevel{_LEVEL_TRACE()});

# by default we do not filter anything out
$_MaybeInterestingInfo = $_InterestingInfo = sub { return(1) };

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++,
         map("log_$_", qw(configure filter)),
         map("log_$_",       qw(error warning info debug trace)),
         map("log_wants_$_", qw(error warning info debug trace)),
    );
    $exported{"log2std"}  = sub { $Handler = \&log2std };
    $exported{"log2dump"} = sub { $Handler = \&log2dump };
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__ 

=head1 NAME

No::Worries::Log - logging without worries

=head1 SYNOPSIS

  use No::Worries::Log qw(*);

  # log an information level message with sprintf()-like syntax
  log_info("accepted connection from %s:%d", inet_ntoa($addr), $port);

  # log expensive debugging information only if needed
  if (log_wants_debug()) {
      $string = ... whatever ...
      log_debug($string, { component => "webui" });
  }

  # log a low-level trace: this is cheap and can be added in many places
  sub foo () {
      log_trace();
      ... code...
  }

  # specify the filter to use: debug messages from web* components
  log_filter(<<EOT);
      debug component=~^web
  EOT

=head1 DESCRIPTION

This module eases information logging by providing convenient
functions to log and filter information. All the functions die() on
error.

It provides five main functions to submit information to be logged:

=over

=item * log_error(ARGUMENTS): for error information

=item * log_warning(ARGUMENTS): for warning information

=item * log_info(ARGUMENTS): for (normal) information

=item * log_debug(ARGUMENTS): for debugging information

=item * log_trace(): for a low level trace

=back

The supplied information is structured and can contain extra
attributes (key/value pairs) like in the SYNOPSIS example.

If the information passes through the filter, it is given to the
handler for logging.

=head1 ATTRIBUTES

An information "object" always contains the following attributes:

=over

=item * C<level>: the information level as C<error>, C<warning>, C<info>,
C<debug> or C<trace>

=item * C<time>: Unix time indicating when the information got submitted

=item * C<caller>: the name of the caller's subroutine or C<main>

=item * C<file>: the file path

=item * C<line>: the line number

=item * C<program>: the program name, as known by the No::Worries module

=item * C<host>: the host name, see $No::Worries::HostName

=item * C<pid>: the process identifier

=item * C<tid>: the thread identifier (in case threads are used)

=item * C<message>: the formatted message string

=back

In addition, extra attributes can be given when calling log_error(),
log_warning(), log_info() or log_debug().

These attributes are mainly used for filtering (see next section) but
can also be used for formatting.

=head1 FILTER

The filter defines which information should be logged (i.e. given to
the handler) or not. It can be controlled via the log_filter() and
log_configure() functions.

The filter is described via a multi-line string. Each line is made of
one or more space separated expressions that must be all true. A
filter matches if any of its lines matches. Empty lines and comments
are allowed for readability.

A filter expression can be either C<error>, C<warning>, C<info>,
C<debug> or C<trace> (meaning that the level must match it) or of the
form I<{attr}{op}{value}> where I<{attr}> is the attribute name,
I<{op}> is the operation (either C<=~>, C<!~>, C<==>, C<!=>, C<E<lt>>,
C<E<lt>=>, C<E<gt>> or C<E<gt>=>) and I<value> is the value to use for
the test (either an integer, a string or a regular expression).

If the value is not an integer, it will be treated like the contents
of a double quoted string or a regular expression, so escape sequences
will be honored. For parsing reasons (expressions are space
separated), the value cannot contain space characters. If you need
some, they have to be escaped like in the examples below.

Here are commented examples:

  # comments start with a 'hash' sign
  # all info level
  info

  # debug level with messages matching "permission denied"
  # (expressions are space separated so the space must be escaped)
  debug message=~permission\x20denied

  # debug level from any subroutine in Foo::Bar on host "venus"
  debug caller=~^Foo::Bar:: host==venus

  # trace level at the end of the file foo.pm
  trace file=/full/path/foo.pm line>999

Note: user-supplied attributes can also be used in filters. If they
are not defined, the match will fail. For instance:

  # we want to see only debug messages with a low karma
  log_filter("debug karma<=42");
  # the following will be logged
  log_debug("yes", { karma => 7 });
  # the following will not be logged
  log_debug("no", { karma => 1999 });
  log_debug("no");

You can also use an alternative syntax with explicit C<or> and
C<and>. This is very convenient to fit the filter in a single line
(for instance when given on the command line). For instance:

  # multi-line style filter
  info
  debug caller==main

is equivalent to:

  info or debug and caller==main

=head1 HANDLER

If the information successfully passes through the filter it is given
to the handler, i.e. the code reference stored in
$No::Worries::Log::Handler.

The default handler prints compact yet user friendly output to STDOUT
(C<info> level) or STDERR (otherwise).

The L<No::Worries::Syslog> module contains a similar handler to log
information to syslog.

Here is how to change the variable to a handler that dumps all the
information attributes to STDERR:

  $No::Worries::Log::Handler = \&No::Worries::Log::log2dump;

The same can be achived at module loading time by using for instance:

  use No::Worries::Log qw(* log2dump);

You can put your own code in $No::Worries::Log::Handler. It will be
called with a single argument: the structured information as a hash
reference. This can be useful for ad-hoc filtering or to do something
else that logging to STDOUT/STDERR or syslog.

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item log_filter(FILTER)

use the given filter (string) to configure what should gets logged or not

=item log_configure(PATH)

use the given path (file) to configure what should gets logged or not;
this reads the file if needed (i.e. if it changed since last time) and
calls log_filter()

=item log_wants_error()

return true if the current filter may pass error level information

=item log_wants_warning()

return true if the current filter may pass warning level information

=item log_wants_info()

return true if the current filter may pass info level information

=item log_wants_debug()

return true if the current filter may pass debug level information

=item log_wants_trace()

return true if the current filter may pass trace level information

=item log_error(ARGUMENTS)

give an error level information to the module to get logged if the
current filter lets it pass; see below for its ARGUMENTS

=item log_warning(ARGUMENTS)

give a warning level information to the module to get logged if the
current filter lets it pass; see below for its ARGUMENTS

=item log_info(ARGUMENTS)

give an info level information to the module to get logged if the
current filter lets it pass; see below for its ARGUMENTS

=item log_debug(ARGUMENTS)

give a debug level information to the module to get logged if the
current filter lets it pass; see below for its ARGUMENTS

=item log_trace()

give a trace level information to the module to get logged if the
current filter lets it pass; the trace information contains the name
of the caller subroutine, the file path and the line number

=item log2std(INFO)

handler for $No::Worries::Log::Handler to send information to
STDOUT/STDERR in a compact yet user friendly way; this is not exported
and must be called explicitly

=item log2dump(INFO)

handler for $No::Worries::Log::Handler that dumps all the information
attributes to STDERR; this is not exported and must be called
explicitly

=back

=head1 USAGE

log_error(), log_warning(), log_info() and log_debug() can be called
in different ways:

=over

=item * log_xxx(): no arguments, same as giving an empty string

=item * log_xxx("string"): the message will be the given string

=item * log_xxx("format", @args): the message will be the result of sprintf()

=item * log_xxx(\&code): the message will be the return value of the code

=item * log_xxx(\&code, @args): idem but also supplying arguments to give

=back

In addition, in all cases, an optional last argument containing
user-supplied attributes can be given as a hash reference. For
instance:

  log_info("foo is %s", $foo, { component => "webui" });

Note that the following:

  log_debug(\&dump_hash, \%big_hash);

will treat the last argument as being the attributes hash. If this is
not what you want, you should supply an empty attributes hash so that
\%big_hash gets interpreted as an argument to give to dump_hash():

  log_debug(\&dump_hash, \%big_hash, {});

With the sprintf() style usage, you can supply string references as
arguments. They will be replaced by the corresponding attributes. For
instance:

  log_debug("unexpected data: %s [line %d]", $data, \"line");

The usages with a code reference are useful for expensive operations
that you want to perform only when you are pretty sure that the
information will be logged. The code reference will be called only
after an initial filtering. For instance:

  # expensive code to return a message to maybe log
  sub dump_state ($) {
      my($data) = @_;
      ... heavy work ...
      return(... something ...);
  }
  # subroutine that may want to dump its state
  sub foo () {
      ... some code ...
      log_debug(\&dump_state, $some_data);
      ... some code ...
  }
  # filter that only cares about debug information from main::bar
  log_filter("debug caller==main::bar");
  # the following will not call dump_state()
  foo();

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being
exported):

=over

=item $Handler

the subroutine (code reference) to call for every information that
successfully passes through the filter, the default is normally
\&No::Worries::Log::log2std() (see below)

=back

=head1 ENVIRONMENT VARIABLES

This module uses the C<NO_WORRIES> environment variable to find out
which handler to use by default. Supported values are:

=over

=item C<log2std>

use No::Worries::Log::log2std() (this is the default anyway)

=item C<log2dump>

use No::Worries::Log::log2dump()

=back

=head1 SEE ALSO

L<No::Worries>,
L<No::Worries::Syslog>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
