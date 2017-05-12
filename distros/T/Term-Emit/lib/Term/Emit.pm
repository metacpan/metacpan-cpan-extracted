# Term::Emit - Print with indentation, status, and closure
#
#  $Id: Emit.pm 395 2012-09-06 18:21:50Z steve $

package Term::Emit;
use warnings;
use strict;
use 5.008;

use Exporter;
use base qw/Exporter/;
use Scope::Upper 0.06 qw/:words reap/;

our $VERSION   = '0.0.4';
our @EXPORT_OK = qw/emit emit_over emit_prog emit_text emit_done emit_none
    emit_emerg
    emit_alert
    emit_crit emit_fail emit_fatal
    emit_error
    emit_warn
    emit_note
    emit_info emit_ok
    emit_debug
    emit_notry
    emit_unk
    emit_yes
    emit_no/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

use constant MIN_SEV => 0;
use constant MAX_SEV => 15;
our %SEVLEV = (
    EMERG => 15,
    ALERT => 13,
    CRIT  => 11,
    FAIL  => 11,
    FATAL => 11,
    ERROR => 9,
    WARN  => 7,
    NOTE  => 6,
    INFO  => 5,
    OK    => 5,
    DEBUG => 4,
    NOTRY => 3,
    UNK   => 2,
    OTHER => 1,
    YES   => 1,
    NO    => 0,
);
our %BASE_OBJECT = ();

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # Get the class name
    my $this  = {
        pos     => 0,                     # Current output column number
        progwid => 0,                     # Width of last progress message emitted
        msgs    => []
    };    # Closing message stack
    bless $this, $class;
    $this->setopts(@_);
    return $this;
}

sub base {
    my ($this) = _process_args(@_);
    return $this;
}

sub clone {
    my $this = shift;    # Object to clone
    return Term::Emit->new(%{$this}, _clean_opts(@_));
}

sub import {
    my $class = shift;

    # Yank option sets, if any, out from the arguments
    my %opts = ();
    my @args = ();
    while (@_) {
        my $arg = shift;
        if (ref($arg) eq 'HASH') {
            %opts = (%opts, %{$arg});    #merge
            next;
        }
        push @args, $arg;
    }
    %opts = _clean_opts(%opts);

    # Create the default base object
    $BASE_OBJECT{0} ||= new Term::Emit(%opts);

    # Continue exporter's work
    return $class->export_to_level(1, $class, @args);
}

#
# Set options
#
sub setopts {
    my ($this, $opts, %args) = _process_args(@_);

    # Merge & clean 'em
    %args = (%{$opts}, %args);
    %args = _clean_opts(%args);    ###why does this not work here?? -fh vs fh

    # Process args
    my $deffh = select();
    no strict 'refs';
    $this->{fh} 
        = $args{fh}
        || $this->{fh}
        || \*{$deffh};
    use strict 'refs';
    $this->{envbase} 
        = $args{envbase}
        || $this->{envbase}
        || 'term_emit_fd';    ### TODO: apply to all envvars we use, not just _fd
    $this->{bullets}
        = exists $ENV{term_emit_bullets} ? $ENV{term_emit_bullets}
        : exists $args{bullets}          ? $args{bullets}
        : exists $this->{bullets}        ? $this->{bullets}
        :                                  0;
    $this->{closestat} 
        = $args{closestat}
        || $this->{closestat}
        || 'DONE';
    $this->{color}
        = exists $ENV{term_emit_color}
        ? $ENV{term_emit_color}
        : $args{color}
        || $this->{color}
        || 0;
    $this->{ellipsis}
        = exists $ENV{term_emit_ellipsis}
        ? $ENV{term_emit_ellipsis}
        : $args{ellipsis}
        || $this->{ellipsis}
        || '...';
    $this->{maxdepth}
        = exists $ENV{term_emit_maxdepth} ? $ENV{term_emit_maxdepth}
        : exists $args{maxdepth}          ? $args{maxdepth}
        :   $this->{maxdepth};    #undef=all, 0=none, 3=just first 3 levels, etc
    $this->{showseverity}
        = exists $ENV{term_emit_showseverity} ? $ENV{term_emit_showseverity}
        : exists $args{showseverity}          ? $args{showseverity}
        :                                  $this->{showseverity};
    $this->{step}
        = exists $ENV{term_emit_step} ? $ENV{term_emit_step}
        : exists $args{step}          ? $args{step}
        : defined $this->{step}       ? $this->{step}
        :                               2;
    $this->{timestamp} = $args{timestamp}
        || $this->{timestamp}
        || 0;
    $this->{trailer}
        = exists $ENV{term_emit_trailer}
        ? $ENV{term_emit_trailer}
        : $args{trailer}
        || $this->{trailer}
        || q{.};
    $this->{width}
        = exists $ENV{term_emit_width}
        ? $ENV{term_emit_width}
        : $args{width}
        || $this->{width}
        || 80;

    #    $this->{timefmt}   = $args{timefmt}   || $this->{timefmt}   || undef;   # Timestamp format
    #    $this->{pos} = $args{pos}
    #        if defined $args{pos};

    # Recompute a few things
    # TODO: Allow bullets to be given as CSV:  "* ,+ ,- ,  " for example.
    # TODO: Put this in a sub of its own.
    $this->{bullet_width} = 0;
    if (ref $this->{bullets} eq 'ARRAY') {
        foreach my $b (@{$this->{bullets}}) {
            $this->{bullet_width} = length($b)
                if length($b) > $this->{bullet_width};
        }
    }
    elsif ($this->{bullets}) {
        $this->{bullet_width} = length($this->{bullets});

        return 0;
    }
}

#
# Emit a message, starting a new level
#
sub emit {
    my ($this, $opts, @args) = _process_args(@_);
    my $jn = defined $, ? $, : q{};
    if (@args && ref($args[0]) eq 'ARRAY') {

        # Using [opentext, closetext] notation
        my $pair  = shift @args;
        my $otext = $pair->[0] || '';
        my $ctext = $pair->[1] || $otext;
        unshift @args, $otext;
        $opts->{closetext} = $ctext;
    }
    my $msg = join $jn, @args;
    if (!@args) {

        # Use our caller's subroutine name as the message
        (undef, undef, undef, $msg) = caller(1);
        $msg =~ s{^main::}{}sxm;
    }

    #  Tied closure:
    #   If we're returning into a list context,
    #   then we're tying closure to the scope of the caller's list element.
    return Term::Emit::TiedClosure->new($this, $opts, $msg)
        if wantarray;

    # Store context
    my $cmsg
        = defined $opts->{closetext}
        ? $opts->{closetext}
        : $msg;
    push @{$this->{msgs}}, [$msg, $cmsg];
    my $level = $ENV{$this->_envvar()}++ || 0;

    # Setup the scope reaper for autoclosure
    reap sub {
        $this->emit_done({%{$opts}, want_level => $level}, $this->{closestat});
    } => SCOPE(1);

    # Filtering by level?
    return 1
        if defined($this->{maxdepth}) && $level >= $this->{maxdepth};

    # Start back at the left
    my $s = 1;
    $s = $this->_spew("\n")
        if $this->{pos};
    return $s unless $s;
    $this->{pos}     = 0;
    $this->{progwid} = 0;

    # Level adjust?
    $level += $opts->{adjust_level}
        if $opts->{adjust_level} && $opts->{adjust_level} =~ m{^-?\d+$}sxm;

    # Timestamp
    my $tsr = defined $opts->{timestamp}? $opts->{timestamp} : $this->{timestamp};
    $tsr = \&_timestamp if $tsr && !ref($tsr);
    my $ts = $tsr? &$tsr($level) : q{};

    # The message
    my $bullet = $this->_bullet($level);
    my $indent = q{ } x ($this->{step} * $level);
    my $tlen   = 0;
    my $span   = $this->{width} - length($ts) - length($bullet) - ($this->{step} * $level) - 10;
    my @mlines = _wrap($msg, int($span * 2 / 3), $span);
    while (defined(my $txt = shift @mlines)) {
        $s = $this->_spew($ts . $bullet . $indent . $txt);
        return $s unless $s;
        $s = $this->_spew(@mlines ? "\n" : $this->{ellipsis});
        return $s unless $s;
        $tlen   = length($txt);
        $bullet = q{ } x $this->{bullet_width};    # Only bullet the first line
        $ts     = q{ } x length($ts);              # Only timestamp the first line
    }
    $this->{pos} += length($ts) + ($this->{step} * $level) + length($bullet) + $tlen + length($this->{ellipsis});
    return 1;
}

#
# Complete the current level, with status
#
sub emit_done {
    my ($this, $opts, @args) = _process_args(@_);
    my $want_level = $opts->{want_level};
    my $sev        = shift @args || 'DONE';
    my $sevlev     = defined $SEVLEV{uc $sev}? $SEVLEV{uc $sev} : $SEVLEV{'OTHER'};

    # Test that we're at the right level - do this BEFORE changing the envvar
    my $ret_level = ($ENV{$this->_envvar()} || 0) - 1;
    return
        if defined $want_level && $ret_level != $want_level;

    # Decrement level
    return $sevlev
        if !$ENV{$this->_envvar()};
    my $level = --$ENV{$this->_envvar()};
    delete $ENV{$this->_envvar()}
        if $level <= 0;

    # Filtering - level & severity
    my $showseverity
        = defined $opts->{showseverity}  ? $opts->{showseverity}
        : defined($this->{showseverity}) ? $this->{showseverity}
        :                             MAX_SEV;
    if (   $sevlev < $showseverity
        && defined($this->{maxdepth})
        && $level >= $this->{maxdepth})
    {
        pop @{$this->{msgs}};    # discard it
        return $sevlev;
    }

    # Are we silently closing this level?
    if ($opts->{silent}) {
        my $s = 1;
        $s = $this->_spew("\n")
            if $this->{pos};
        return $s unless $s;
        $this->{pos}     = 0;
        $this->{progwid} = 0;
        pop @{$this->{msgs}};    # discard it
        return $sevlev;
    }

    # Make the severity text
    my $sevstr = " [$sev]\n";
    my $slen   = 8;              # make left justified within max width 3+5
    $sevstr = " [" . _colorize($sev, $sev) . "]\n"
        if $this->{color};

    # Re-issue message if needed
    my $msgs = pop @{$this->{msgs}};
    my ($omsg, $cmsg) = @{$msgs};    # Opening and closing messages
                                     # -(if not the same, force a re-issue)-
    if ($this->{pos} && ($omsg ne $cmsg)) {
        # Closing differs from opening, so we need to re-issue with the closing
        my $s = $this->_spew("\n");
        return $s unless $s;
        $this->{pos} = 0;
    }
    if ($this->{pos} 
        && defined($this->{maxdepth})
        && $level >= $this->{maxdepth}) {
        # This would be level-filtered, but severity overrode it, so we need to re-issue
        my $s = $this->_spew("\n");
        return $s unless $s;
        $this->{pos} = 0;
    }
    if ($this->{pos} == 0) {
        # Timestamp
        my $tsr = defined $opts->{timestamp}? $opts->{timestamp} : $this->{timestamp};
        $tsr = \&_timestamp if $tsr && !ref($tsr);
        my $ts = $tsr? &$tsr($level) : q{};

        my $bullet = $this->_bullet($level);
        my $indent = q{ } x ($this->{step} * $level);
        my $tlen   = 0;
        my $span   = $this->{width} - length($ts) - ($this->{step} * $level) - 10;
        my @mlines = _wrap($cmsg, int($span * 2 / 3), $span);
        while (defined(my $txt = shift @mlines)) {
            my $s;
            $s = $this->_spew($ts . $bullet . $indent . $txt);
            return $s unless $s;
            $s = $this->_spew("\n")
                if @mlines;
            return $s unless $s;
            $tlen   = length($txt);
            $bullet = q{ } x $this->{bullet_width};    # Only bullet the first line
            $ts     = q{ } x length($ts);              # Only timestamp the first line
        }
        $this->{pos} += length($ts) + length($bullet) + ($this->{step} * $level) + $tlen;
    }

    # Trailer
    my $ndots = $this->{width} - $this->{pos} - $slen;
    my $s     = 1;
    $s = $this->_spew($this->{trailer} x $ndots)
        if $ndots > 0;
    return $s unless $s;

    # Severity
    $s = $this->_spew($sevstr);
    return $s unless $s;
    $this->{pos} = 0;

    # Reason option?
    my $reason = $opts->{reason};
    $opts->{force} = 1; # Always give reason if we got thru above level filtering
    $s = emit_text($opts, $reason)
        if $reason;
    return $s unless $s;

    # Return with a severity value
    return $sevlev;
}

#
# Progress output
#
sub emit_over {
    my ($this, $opts, @args) = _process_args(@_);

    # Filtering by level?
    my $level = $ENV{$this->_envvar()} || 0;
    return 1
        if defined($this->{maxdepth}) && $level > $this->{maxdepth};

    # Erase prior progress output
    my $s = 1;
    $s = $this->_spew(qq{\b} x $this->{progwid});
    return $s unless $s;
    $s = $this->_spew(q{ } x $this->{progwid});
    return $s unless $s;
    $s = $this->_spew(qq{\b} x $this->{progwid});
    return $s unless $s;
    $this->{pos} -= $this->{progwid};
    $this->{progwid} = 0;

    return $this->emit_prog(@args);
}

sub emit_prog {
    my ($this, $opts, @args) = _process_args(@_);
    my $jn = defined $, ? $, : q{};
    my $msg = join $jn, @args;
    my $s;

    # Filtering by level?
    my $level = $ENV{$this->_envvar()} || 0;
    return 1
        if defined($this->{maxdepth}) && $level > $this->{maxdepth};

    # Start a new line?
    my $avail = $this->{width} - $this->{pos} - 10;
    if (length($msg) > $avail) {
        my $level  = $ENV{$this->_envvar()};
        my $bspace = q{ } x $this->{bullet_width};
        my $indent = q{ } x ($this->{step} * $level);
        $s = $this->_spew("\n");
        return $s unless $s;
        $s = $this->_spew($bspace . $indent);
        return $s unless $s;
        $this->{pos}     = length($bspace) + length($indent);
        $this->{progwid} = 0;
    }

    # The text
    $s = $this->_spew($msg);
    return $s unless $s;
    $this->{pos}     += length($msg);
    $this->{progwid} += length($msg);

    return 1;
}

#
# Issue additional info at the current level
#
sub emit_text {
    my ($this, $opts, @args) = _process_args(@_);
    my $jn = defined $, ? $, : q{};
    my $msg = join $jn, @args;

    # Filtering by level?
    my $level = $ENV{$this->_envvar()} || 0;
    return 1
        if !$opts->{force} && defined($this->{maxdepth}) && $level > $this->{maxdepth};

    # Start a new line
    my $s = 1;
    $s = $this->_spew("\n")
        if $this->{pos};
    return $s unless $s;

    # Level adjust?
    $level++;    # We're over by one by default
    $level += $opts->{adjust_level}
        if $opts->{adjust_level} && $opts->{adjust_level} =~ m{^-?\d+$}sxm;

    # Emit the text
    my $indent = q{ } x ($this->{step} * $level);
    my $span = $this->{width} - ($this->{step} * $level) - 10;
    my @mlines = _wrap($msg, int($span * 2 / 3), $span);
    while (defined(my $txt = shift @mlines)) {
        my $bspace = q{ } x $this->{bullet_width};
        $s = $this->_spew($bspace . $indent . $txt . "\n");
        return $s unless $s;
        $this->{pos} = 0;
    }
    return 1;
}

sub emit_emerg {emit_done @_, "EMERG"};    # syslog: Off the scale!
sub emit_alert {emit_done @_, "ALERT"};    # syslog: A major subsystem is unusable.
sub emit_crit  {emit_done @_, "CRIT"};     # syslog: a critical subsystem is not working entirely.
sub emit_fail  {emit_done @_, "FAIL"};     # Failure
sub emit_fatal {emit_done @_, "FATAL"};    # Fatal error
sub emit_error {emit_done @_, "ERROR"};    # syslog 'err': Bugs, bad data, files not found, ...
sub emit_warn  {emit_done @_, "WARN"};     # syslog 'warning'
sub emit_note  {emit_done @_, "NOTE"};     # syslog 'notice'
sub emit_info  {emit_done @_, "INFO"};     # syslog 'info'
sub emit_ok    {emit_done @_, "OK"};       # copacetic
sub emit_debug {emit_done @_, "DEBUG"};    # syslog: Really boring diagnostic output.
sub emit_notry {emit_done @_, "NOTRY"};    # Untried
sub emit_unk   {emit_done @_, "UNK"};      # Unknown
sub emit_yes   {emit_done @_, "YES"};      # Yes
sub emit_no    {emit_done @_, "NO"};       # No
sub emit_none  {emit_done {-silent => 1}, @_, "NONE"}
# *Special* closes level quietly (prints no wrapup severity)

#
# Return the bullet string for the given level
#
sub _bullet {
    my ($this, $level) = @_;
    my $bullet = q{};
    if (ref($this->{bullets}) eq 'ARRAY') {
        my $pmax = $#{$this->{bullets}};
        $bullet = $this->{bullets}->[$level > $pmax ? $pmax : $level];
    }

    # TODO: Allow bullets to be given as CSV:  "* ,+ ,- ,  " for example.
    elsif ($this->{bullets}) {
        $bullet = $this->{bullets};
    }
    else {
        return q{};
    }
    my $pad = q{ } x ($this->{bullet_width} - length($bullet));
    return $bullet . $pad;
}

#
# Clean option keys
#
sub _clean_opts {
    my %in  = @_;
    my %out = ();
    foreach my $k (keys %in) {
        my $v = $in{$k};
        delete $in{$k};
        $k =~ s{^\s*-?(\w+)\s*}{$1}sxm;
        $out{lc $k} = $v;
    }
    return %out;
}

#
# Add ANSI color to a string, if ANSI is enabled
### TODO:  use Term::ANSIColor, a standard module (verify what perl version introduced it, tho)
#
sub _colorize {
    my ($str, $sev) = @_;
    my $zon  = q{};
    my $zoff = q{};
    $zon = chr(27) . '[1;31;40m' if $sev =~ m{\bEMERG(ENCY)?}i;        #bold red on black
    $zon = chr(27) . '[1;35m'    if $sev =~ m{\bALERT\b}i;             #bold magenta
    $zon = chr(27) . '[1;31m'    if $sev =~ m{\bCRIT(ICAL)?\b}i;       #bold red
    $zon = chr(27) . '[1;31m'    if $sev =~ m{\bFAIL(URE)?\b}i;        #bold red
    $zon = chr(27) . '[1;31m'    if $sev =~ m{\bFATAL\b}i;             #bold red
    $zon = chr(27) . '[31m'      if $sev =~ m{\bERR(OR)?\b}i;          #red
    $zon = chr(27) . '[33m'      if $sev =~ m{\bWARN(ING)?\b}i;        #yellow
    $zon = chr(27) . '[36m'      if $sev =~ m{\bNOTE\b}i;              #cyan
    $zon = chr(27) . '[32m'      if $sev =~ m{\bINFO(RMATION)?\b}i;    #green
    $zon = chr(27) . '[1;32m'    if $sev =~ m{\bOK\b}i;                #bold green
    $zon = chr(27) . '[37;43m'   if $sev =~ m{\bDEBUG\b}i;             #grey on yellow
    $zon = chr(27) . '[30;47m'   if $sev =~ m{\bNOTRY\b}i;             #black on grey
    $zon = chr(27) . '[1;37;47m' if $sev =~ m{\bUNK(OWN)?\b}i;         #bold white on gray
    $zon = chr(27) . '[32m'      if $sev =~ m{\bYES\b}i;               #green
    $zon = chr(27) . '[31m'      if $sev =~ m{\bNO\b}i;                #red
    $zoff = chr(27) . '[0m' if $zon;
    return $zon . $str . $zoff;
}

#
# The level's envvar for this filehandle
#
sub _envvar {
    my $this = shift;
    return $this->{envbase} . _oid($this->{fh});
}

# Return an output identifier for the filehandle
#
sub _oid {
    my $fh = shift;
    return 'str' if ref($fh) eq 'SCALAR';
    return 0 if ref($fh);
    return fileno($fh || q{}) || 0;
}

#
# Figure out what was passed to us
#
#   Each $BASE_OBJECT in the hash is associated with one output ID (the oid).
#    The oid is just the fileno() of the file handle for normal output,
#    or the special text "str" when output is to a scalar string reference.
#    That's why we use a base object _hash_ instead of an array.
#   The $BASE_OBJECT{0} is the default one.  It's equivalent to whatever
#    oid was specified in the "use Term::Emit ... {-fh=>$blah}" which typically
#    is STDOUT (oid=1) but may be anything.
#
#   So what're we doing here?  We have to figure out which base object to use.
#   Our subs can be called four ways:
#       A) emit "blah";
#       B) emit *LOG, "blah";
#       C) $tobj->emit "blah";
#       D) $tobj->emit *LOG, "blah";
#   Also note that "emit {-fh=>*LOG},..." is considered equivalent to case B,
#   while "$tobj->emit {-fh=>*LOG},..." is considered equivalent to case D.
#
#   In case A, we simply use the default base object $BASE_OBJECT{0}.
#   In case B, we get the oid of *LOG and use that base object.
#       If the base object does not exist, then we make one,
#       cloning it from base object 0 but overriding with the file handle.
#   In case C, we use the base object $tobj - this is classic OO perl.
#   In case D, it's like case B except that if we have to make a new
#       base object, we clone from $tobj instead of base object 0.
#
sub _process_args {
    my $this = ref($_[0]) eq __PACKAGE__ ? shift : $BASE_OBJECT{0};
    my $oid = _oid($_[0]);
    if ($oid) {

        # We're given a filehandle or scalar ref for output.
        #   Find the associated base object or make a new one for it
        my $fh = shift;
        if ($fh eq $BASE_OBJECT{0}->{fh}) {

            # Use base object 0, 'cuz it matches
            $oid = 0;
        }
        elsif (!exists $BASE_OBJECT{$oid}) {
            $BASE_OBJECT{$oid} = $this->clone(-fh => $fh);
        }
        $this = $BASE_OBJECT{$oid};
    }
    my $opts = {};
    if (ref($_[0]) eq 'HASH') {
        $opts = {_clean_opts(%{shift()})};
    }
    return ($this, $opts, @_);
}

#
# Emit output to filehandle, string, whatever...
#
sub _spew {
    my $this = shift;
    my $out  = shift;
    my $fh   = $this->{fh};
    return ref($fh) eq 'SCALAR' ? ${$fh} .= $out : print {$fh} $out;
}

#
# Default timestamp 
#
sub _timestamp {
    my $level = shift; #fwiw
    my ($s, $m, $h) = localtime(time());
    return sprintf "%2.2d:%2.2d:%2.2d ", $h, $m, $s;
}

#
# Wrap text to fit within line lengths
#   (Do we want to delete this and add a dependency to Text::Wrap ??)
#
sub _wrap {
    my ($msg, $min, $max) = @_;
    return ($msg)
        if !defined $msg
            || $max < 3
            || $min > $max;

    # First split on newlines
    my @lines = ();
    foreach my $line (split(/\n/, $msg)) {
        my $split = $line;

        # Then if each segment is more than the width, wrap it
        while (length($split) > $max) {

            # Look backwards for whitespace to split on
            my $pos = $max;
            while ($pos >= $min) {
                if (substr($split, $pos, 1) =~ m{\s}sxm) {
                    $pos++;
                    last;
                }
                $pos--;
            }
            $pos = $max if $pos < $min;    #no good place to break, use the max

            # Break it
            my $chunk = substr($split, 0, $pos);
            $chunk =~ s{\s+$}{}sxm;
            push @lines, $chunk;
            $split = substr($split, $pos, length($split) - $pos);
        }
        $split =~ s{\s+$}{}sxm;            #trim
        push @lines, $split;
    }
    return @lines;
}

### O ###

package Term::Emit::TiedClosure;

sub new {
    my ($proto, $base, @args) = @_;
    my $class = ref($proto) || $proto;     # Get the class name
    my $this = {-base => $base};
    bless($this, $class);
    $base->emit(@args);
    return $this;
}

sub DESTROY {
    my $this = shift;
    return $this->{-base}->emit_done();
}

1;                                         # EOM
__END__

=head1 NAME

Term::Emit - Print with indentation, status, and closure

=head1 VERSION

This document describes Term::Emit version 0.0.4

=head1 SYNOPSIS

For a script like this:

    use Term::Emit qw/:all/;
    emit "System parameter updates";
      emit "CLOCK_UTC";
      #...do_something();
      emit_ok;

      emit "NTP Servers";
      #...do_something();
      emit_error;

      emit "DNS Servers";
      #...do_something();
      emit_warn;

You get this output:

   System parameter updates...
     CLOCK_UTC................................................. [OK]
     NTP Servers............................................... [ERROR]
     DNS Servers............................................... [WARN]
   System parameter updates.................................... [DONE]

=head1 DESCRIPTION

The C<Term::Emit> package is used to print balanced and nested messages
with a completion status.  These messages indent easily within each other,
autocomplete on scope exit, are easily parsed, may be bulleted, can be filtered,
and even can show status in color.

For example, you write code like this:

    use Term::Emit qw/:all/;
    emit "Reconfiguring the grappolator";
    do_whatchamacallit();
    do_something_else();

It begins by printing:

    Reconfiguring the grappolator...

Then it does "whatchamacallit" and "something else".  When these are complete
it adds the rest of the line: a bunch of dots and the [DONE].

    Reconfiguring the grappolator............................... [DONE]

Your do_whatchamacallit() and do_something_else() subroutines may also C<emit>
what they're doing, and indicate success or failure or whatever, so you
can get nice output like this:

    Reconfiguring the grappolator...
      Processing whatchamacallit................................ [WARN]
      Fibulating something else...
        Fibulation phase one.................................... [OK]
        Fibulation phase two.................................... [ERROR]
        Wrapup of fibulation.................................... [OK]
    Reconfiguring the grappolator............................... [DONE]


A series of examples will make I<Term::Emit> easier to understand.

=head2 Basics

    use Term::Emit ':all';
    emit "Frobnicating the biffolator";
    sleep 1; # simulate the frobnication process
    emit_done;

First this prints:

    Frobnicating the biffolator...

Then after the "frobnication" process is complete, the line is
continued so it looks like this:

    Frobnicating the biffolator................................ [DONE]

=head2 Autocompletion

In the above example, we end with a I<emit_done> call to indicate that
the thing we told about (I<Frobnicating the biffolator>) is now done.
We don't need to do the C<emit_done>.  It will be called automatically
for us when the current scope is exited (for this example: when the program ends).
So the code example could be just this:

    use Term::Emit ':all';
    emit "Frobnicating the biffolator";
    sleep 1; # simulate the frobnication process

and we'd get the same results.  

Yeah, autocompletion may not seem so useful YET,
but hang in there and you'll soon see how wonderful it is.

=head2 Completion Severity

There's many ways a task can complete.  It can be simply DONE, or it can
complete with an ERROR, or it can be OK, etc.  These completion codes are
called the I<severity code>s.  C<Term::Emit> defines many different severity codes.
The severity codes are borrowed from the UNIX syslog subsystem,
plus a few from VMS and other sources.  They should be familiar to you.

Severity codes also have an associated numerical value.
This value is called the I<severity level>.
It's useful for comparing severities to eachother or filtering out
severities you don't want to be bothered with.

Here are the severity codes and their severity values.
Those on the same line are considered equal in severity:

    EMERG => 15,
    ALERT => 13,
    CRIT  => 11, FAIL => 11, FATAL => 11,
    ERROR => 9,
    WARN  => 7,
    NOTE  => 6,
    INFO  => 5, OK => 5,
    DEBUG => 4,
    NOTRY => 3,
    UNK   => 2,
    YES   => 1,
    NO    => 0,

You may make up your own severities if what you want is not listed.
Please keep the length to 5 characters or less, otherwise the text may wrap.
Any severity not listed is given the value 1.

To complete with a different severity, call C<emit_done> with the
severity code like this:

    emit_done "WARN";

C<emit_done> returns with the severity value from the above table,
otherwise it returns 1, unless there's an error in which case it
returns false.

As a convienence, it's easier to use these functions which do the same thing,
only simpler:

     Function          Equivalent                       Usual Meaning
    ----------      -----------------      -----------------------------------------------------
    emit_emerg      emit_done "EMERG";     syslog: Off the scale!
    emit_alert      emit_done "ALERT";     syslog: A major subsystem is unusable.
    emit_crit       emit_done "CRIT";      syslog: a critical subsystem is not working entirely.
    emit_fail       emit_done "FAIL";      Failure
    emit_fatal      emit_done "FATAL";     Fatal error
    emit_error      emit_done "ERROR";     syslog 'err': Bugs, bad data, files not found, ...
    emit_warn       emit_done "WARN";      syslog 'warning'
    emit_note       emit_done "NOTE";      syslog 'notice'
    emit_info       emit_done "INFO";      syslog 'info'
    emit_ok         emit_done "OK";        copacetic
    emit_debug      emit_done "DEBUG";     syslog: Really boring diagnostic output.
    emit_notry      emit_done "NOTRY";     Untried
    emit_unk        emit_done "UNK";       Unknown
    emit_yes        emit_done "YES";       Yes
    emit_no         emit_done "NO";        No

We'll change our simple example to give a FATAL completion:

    use Term::Emit ':all';
    emit "Frobnicating the biffolator";
    sleep 1; # simulate the frobnication process
    emit_fatal;

Here's how it looks:

    Frobnicating the biffolator................................ [FATAL]

=head3 Severity Colors

A spiffy little feature of C<Term::Emit> is that you can enable colorization of the
severity codes.  That means that the severity code inside the square brackets
is printed in color, so it's easy to see.  The standard ANSI color escape sequences
are used to do the colorization.

Here's the colors:

    EMERG    bold red on black
    ALERT    bold magenta
    CRIT     bold red
    FAIL     bold red
    FATAL    bold red
    ERROR    red
    WARN     yellow (usually looks orange)
    NOTE     cyan
    INFO     green
    OK       bold green
    DEBUG    grey on yellow/orange
    NOTRY    black on grey
    UNK      bold white on grey
    DONE     default font color (unchanged)
    YES      green
    NO       red

To use colors, do this when you I<use> Term::Emit:

    use Term::Emit ":all", {-color => 1};
        -or-
    Term::Emit::setopts(-color => 1);

Run sample003.pl, included with this module, to see how it looks on
your terminal.

=head2 Nested Messages

Nested calls to C<emit> will automatically indent with eachother.
You do this:

    use Term::Emit ":all";
    emit "Aaa";
    emit "Bbb";
    emit "Ccc";

and you'll get output like this:

    Aaa...
      Bbb...
        Ccc.......................... [DONE]
      Bbb............................ [DONE]
    Aaa.............................. [DONE]

Notice how "Bbb" is indented within the "Aaa" item, and that "Ccc" is
within the "Bbb" item.  Note too how the Bbb and Aaa items were repeated
because their initial lines were interrupted by more-inner tasks.

You can control the indentation with the I<-step> attribute,
and you may turn off or alter the repeated text (Bbb and Aaa) as you wish.

=head3 Nesting Across Processes

If you write a Perl script that uses Term::Emit, and this script invokes other
scripts that also use Term::Emit, some nice magic happens.  The inner scripts become
aware of the outer, and they "nest" their indentation levels appropriately.
Pretty cool, eh?

=head3 Filtering-out Deeper Levels (Verbosity)

Often a script will have a verbosity option (-v usually), that allows
a user to control how much output to see.  Term::Emit makes this easy
with the -maxdepth option.

Suppose your script has the verbose option in $opts{verbose}, where 0 means
no output, 1 means some output, 2 means more output, etc.  In your script,
do this:

    Term::Emit::setopts(-maxdepth => $opts{verbose});

Then output will be filtered from nothing to full-on based on the verbosity setting.

=head4 ...But Show Severe Messages

If you're using -maxdepth to filter messages, sometimes you still want 
to see a message regardless of the depth filtering - for example, a severe error.
To set this, use the -showseverity option.  All messages that have
at least that severity value or higher will be shown, regardless of the depth 
filtering.  Thus, a better filter would look like:

    Term::Emit::setopts(-maxdepth     => $opts{verbose},
                        -showseverity => 7);

See L</Completion Severity> above for the severity numbers.
Note that the severity is rolled up to the deepest message filtered by
the -maxdepth setting; any -reason text is hooked to that level.

=head2 Closing with Different Text

Suppose you want the opening and closing messages to be different.
Such as I<"Starting gompchomper"> and I<"End of the gomp">.

To do this, use the C<-closetext> option, like this:

    emit {-closetext => "End of the gomp"}, "Starting gompchomper";

Now, instead of the start message being repeated at the end, you get
custom end text.

A convienent shorthand notation for I<-closetext> is to instead call
C<emit> with a pair of strings as an array reference, like this:

    emit ["Start text", "End text"];

Using the array reference notation is easier, and it will override
the -closetext option if you use both.  So don't use both.

=head3 Changing the 'close text' afterwards

*** TODO:  Provide an easy way to do this! ***

OK, you got me!  I didn't think of this case when I built this module.

It's not easy to do now, even with access to the base object.
For now, I recommend you use -reason and give extra reason text.
When I fix it, it'll probably take the form of setopts(-closetext => "blah")
and emit_done {-closetext=>"blah"};

=head2 Closing with Different Severities, or... Why Autocompletion is Nice

So far our examples have been rather boring.  They're not vey real-world.
In a real script, you'll be doing various steps, checking status as you go,
and bailing out with an error status on each failed check.  It's only when
you get to the bottom of all the steps that you know it's succeeded.
Here's where emit becomes more useful:

    use Term::Emit qw/:all/, {-closestat => "ERROR"};
    emit "Juxquolating the garfibnotor";
    return
        if !do_kibvoration();
    return
        if !do_rumbalation();
    $fail_reason = do_major_cleanup();
    return emit_warn {-reason => $fail_reason}
         if $fail_reason;
    emit_ok;

In this example, we set C<-closestat> to "ERROR".  This means that if we
exit scope without doing a emit_done() (or its equivalents), a emit_error()
will automatically be called.

Next we do_kibvoration and do_runbalation (whatever these are!).
If either fails, we simply return.  Automatically then, the emit_error()
will be called to close out the context.

In the third step, we do_major_cleanup().  If that fails, we explicitly
close out with a warning (the emit_warn), and we pass some reason text.

If we get thru all three steps, we close out with an OK.


=head2 Output to Other File Handles

By default, C<Term::Emit> writes its output to STDOUT (or whatever select()
is set to).  You can tell C<Term::Emit> to use another file handle like this:

    use Term::Emit qw/:all/, {-fh => *LOG};
        -or-
    Term::Emit::setopts(-fh => *LOG);

Individual "emit" lines may also take a file handle as the first
argument, in a manner similar to a print statement:

    emit *LOG, "this", " and ", "that";

Note the required comma after the C<*LOG> -- if it was a C<print> you
would omit the comma.

=head3 Output to Strings

If you give Term::Emit a scalar (string) reference instead of a file handle,
then Term::Emit's output will be appended to this string.

For example:

    my $out = "";
    use Term::Emit qw/:all/, {-fh => \$out};
        -or-
    Term::Emit::setopts(-fh => \$out);

Individual "emit" lines may also take a scalar reference as the first
argument:

    emit \$out, "this ", " and ", "that";

=head2 Output Independence

C<Term::Emit> separates output contexts by file handle.  That means the
indentation, autoclosure, bullet style, width, etc. for any output told
to STDERR is independent of output told to STDOUT, and independent
of output told to a string.  All output to a string is lumped together
into one context.

=head3 Return Status

Like C<print>, the C<emit> function returns a true value on success
and false on failure.  Failure can occur, for example, when attempting
to emit to a closed filehandle.

To get the return status, you must assign into a scalar context,
not a list context:

      my $stat;
      $stat = emit "Whatever";      # OK. This puts status into $stat
      ($stat) = emit "Whatever";    # NOT what it looks like!

In list context, the closure for C<emit> is bound to the list variable's
scope and autoclosure is disabled.  Probably not what you wanted.

=head2 Message Bullets

You may preceed each message with a bullet.
A bullet is usually a single character
such as a dash or an asterix, but may be multiple characters.
You probably want to include a space after each bullet, too.

You may have a different bullet for each nesting level.
Levels deeper than the number of defined bulelts will use the last bullet.

Define bullets by passing an array reference of the bullet strings
with C<-bullet>.  If you want the bullet to be the same for all levels,
just pass the string.  Here's some popular bullet definitions:

    -bullets => "* "
    -bullets => [" * ", " + ", " - ", "   "]

Here's an example with bullets turned on:

 * Loading system information...
 +   Defined IP interface information......................... [OK]
 +   Running IP interface information......................... [OK]
 +   Web proxy definitions.................................... [OK]
 +   NTP Servers.............................................. [OK]
 +   Timezone settings........................................ [OK]
 +   Internal clock UTC setting............................... [OK]
 +   sshd Revocation settings................................. [OK]
 * Loading system information................................. [OK]
 * Loading current CAS parameters............................. [OK]
 * RDA CAS Setup 8.10-2...
 +   Updating configuration...
 -     System parameter updates............................... [OK]
 -     Updating CAS parameter values...
         Updating default web page index...................... [OK]
 -     Updating CAS parameter values.......................... [OK]
 +   Updating configuration................................... [OK]
 +   Forced stopping web server............................... [OK]
 +   Restarting web server.................................... [OK]
 +   Loading crontab jobs...remcon............................ [OK]
 * RDA CAS Setup 8.10-2....................................... [DONE]

=head2 Mixing Term::Emit with print'ed Output

Internally, Term::Emit keeps track of the output cursor position.  It only
knows about what it has spewed to the screen (or logfile or string...).
If you intermix C<print> statements with your C<emit> output, then things
will likely get screwy.  So, you'll need to tell Term::Emit where you've
left the cursor.  Do this by setting the I<-pos> option:

    emit "Skrawning all xyzons";
    print "\nHey, look at me, I'm printed output!\n";
    Term::Emit::setopts (-pos => 0);  # Tell where we left the cursor


=head1 EXPORTS

Nothing is exported by default.  You'll want to do one of these:

    use Term::Emit qw/emit emit_done/;    # To get just these two functions
    use Term::Emit qw/:all/;              # To get all functions

Most of the time, you'll want the :all form.


=head1 SUBROUTINES/METHODS

Although an object-oriented interface exists for I<Term::Emit>, it is uncommon
to use it that way.  The recommended interface is to use the class methods
in a procedural fashion.
Use C<emit()> similar to how you would use C<print()>.

=head2 Methods

The following subsections list the methods available:

=head3 C<base>

Internal base object accessor.  Called with no arguments, it returns
the Term::Emit object associated with the default output filehandle.
When called with a filehandle, it returns the Term::Emit object associated
with that filehandle.

=head3 C<clone>

Clones the current I<Term::Emit> object and returns a new copy.
Any given attributes override the cloned object.
In most cases you will NOT need to clone I<Term::Emit> objects yourself.

=head3 C<new>

Constructor for a Term::Emit object.
In most cases you will B<NOT> need to create I<Term::Emit> objects yourself.

=head3 C<setopts>

Sets options on a Term::Emit object. For example to enable colored severities,
or to set the indentation step size.  Call it like this:

        Term::Emit::setopts(-fh    => *MYLOG,
                            -step  => 3,
                            -color => 1);

See L</Options>.

=head3 C<emit>

Use C<emit> to emit a message similar to how you would use C<print>.

Procedural call syntax:

    emit LIST
    emit *FH, LIST
    emit \$out, LIST
    emit {ATTRS}, LIST

Object-oriented call syntax:

    $tobj->emit (LIST)
    $tobj->emit (*FH, LIST)
    $tobj->emit (\$out, LIST)
    $tobj->emit ({ATTRS}, LIST)

=head3 C<emit_done>

Closes the current message level, re-printing the message
if necessary, printing dot-dot trailers to get proper alignment,
and the given completion severity.

=head3 C<emit_alert>

=head3 C<emit_crit>

=head3 C<emit_debug>

=head3 C<emit_emerg>

=head3 C<emit_error>

=head3 C<emit_fail>

=head3 C<emit_fatal>

=head3 C<emit_info>

=head3 C<emit_no>

=head3 C<emit_note>

=head3 C<emit_notry>

=head3 C<emit_ok>

=head3 C<emit_unk>

=head3 C<emit_warn>

=head3 C<emit_yes>

All these are convienence methods that call C<emit_done()>
with the indicated severity.  For example, C<emit_fail()> is
equivalent to C<emit_done "FAIL">.  See L</Completion Severity>.

=head3 C<emit_none>

This is equivalent to emit_done, except that it does NOT print
a wrapup line or a completion severity.  It simply closes out
the current level with no message.

=head3 C<emit_over>

=head3 C<emit_prog>

Emits a progress indication, such as a percent or M/N or whatever
you devise.  In fact, this simply puts *any* string on the same line
as the original message (for the current level).

Using C<emit_over> will first backspace over a prior progress string
(if any) to clear it, then it will write the progress string.
The prior progress string could have been emitted by emit_over
or emit_prog; it doesn't matter.

C<emit_prog> does not backspace, it simply puts the string out there.

For example,

  use Term::Emit qw/:all/;
  emit "Varigating the shaft";
  emit_prog '10%...';
  emit_prog '20%...';

gives this output:

  Varigating the shaft...10%...20%...

Keep your progress string small!  The string is treated as an indivisible
entity and won't be split.  If the progress string is too big to fit on the
line, a new line will be started with the appropriate indentation.

With creativity, there's lots of progress indicator styles you could
use.  Percents, countdowns, spinners, etc.
Look at sample005.pl included with this package.
Here's some styles to get you thinking:

        Style       Example output
        -----       --------------
        N           3       (overwrites prior number)
        M/N         3/7     (overwrites prior numbers)
        percent     20%     (overwrites prior percent)
        dots        ....    (these just go on and on, one dot for every step)
        tics        .........:.........:...
                            (like dots above but put a colon every tenth)
        countdown   9... 8... 7...
                            (liftoff!)


=head3 C<emit_text>

This prints the given text without changing the current level.
Use it to give additional information, such as a blob of description.
Lengthy lines will be wrapped to fit nicely in the given width.

=head2 Options

The I<emit*> functions, the I<setopts()> function, and I<use Term::Emit> take the following
optional attributes.  Supply options and their values as a hash reference,
like this:

    use Term::Emit ':all', {-fh => \$out,
                            -step => 1,
                            -color => 1};
    emit {-fh => *LOG}, "This and that";
    emit {-color => 1}, "Severities in living color";

The leading dash on the option name is optional, but encouraged;
and the option name may be any letter case, but all lowercase is preferred.

=head3 -adjust_level

Only valid for C<emit> and C<emit_text>.  Supply an integer value.

This adjusts the indentation level of the message inwards (positive) or
outwards (negative) for just this message.  It does not affect filtering
via the I<maxdepth> attribute.  But it does affect the bullet character(s)
if bullets are enabled.

=head3 -bullets

Enables or disables the use of bullet characters in front of messages.
Set to a false value to disable the use of bullets - this is the default.
Set to a scalar character string to enable that character(s) as the bullet.
Set to an array reference of strings to use different characters for each
nesting level.  See L</Message Bullets>.

=head3 -closestat

Sets the severity code to use when autocompleting a message.
This is set to "DONE" by default.  See
L</Closing with Different Severities, or... Why Autocompletion is Nice> above.

=head3 -closetext

Valid only for C<emit>.

Supply a string to be used as the closing text that's paired
with this level.  Normally, the text you use when you emit() a message
is the text used to close it out.  This option lets you specify
different closing text.  See L</Closing with Different Text>.

=head3 -color

Set to a true value to render the completion severities in color.
ANSI escape sequences are used for the colors.  The default is
to not use colors.  See L</Severity Colors> above.

=head3 -ellipsis

Sets the string to use for the ellipsis at the end of a message.
The default is "..." (three periods).  Set it to a short string.
This option is often used in combination with I<-trailer>.

    Frobnicating the bellfrey...
                             ^^^_____ These dots are the ellipsis

=head3 -envbase

May only be set before making the first I<emit()> call.

Sets the base part of the environment variable used to maintain
level-context across process calls.  The default is "term_emit_".
See L</CONFIGURATION AND ENVIRONMENT>.

=head3 -fh

Designates the filehandle or scalar to receive output.  You may alter
the default output, or specify it on individual emit* calls.

    use Term::Emit ':all', {-fh => *STDERR};  # Change default output to STDERR
    emit "Now this goes to STDERR instead of STDOUT";
    emit {-fh => *STDOUT}, "This goes to STDOUT";
    emit {-fh => \$outstr}, "This goes to a string";

The emit* methods have a shorthand notation for the filehandle.
If the first argument is a filehandle or a scalar reference, it is
presumed to be the -fh attribute.  So the last two lines of the above
example could be written like this:

    emit *STDOUT, "This goes to STDOUT";
    emit \$outstr, "This goes to a string";

The default filehandle is whatever was C<select()>'ed, which
is typically STDOUT.

=head3 -maxdepth

Only valid with C<setopts()> and I<use Term::Emit>.

Filters messages by setting the maximum depth of messages tha will be printed.
Set to undef (the default) to see all messages.
Set to 0 to disable B<all> messages from Term::Emit.
Set to a positive integer to see only messages at that depth and less.

=head3 -pos

Used to reset what Term::Emit thinks the cursor position is.
You may have to do this is you mix ordinary print statements
with emit's.

Set this to 0 to indicate we're at the start of a new line
(as in, just after a print "\n").  See L</Mixing Term::Emit with print'ed Output>.

=head3 -reason

Only valid for emit_done (and its equivalents like emit_warn,
emit_error, etc.).

Causes emit_done() to emit the given reason string on the following line(s),
indented underneath the completed message.  This is useful to supply additional
failure text to explain to a user why a certain task failed.

This programming metaphor is commonly used:

    .
    .
    .
    my $fail_reason = do_something_that_may_fail();
    return emit_fail {-reason => $fail_reason}
        if $fail_reason;
    .
    .
    .

=head3 -silent

Only valid for emit(), emit_done(), and it's equivalents, like emit_ok, emit_warn, etc.

Set this option to a true value to make an emit_done() close out silently.
This means that the severity code, the trailer (dot dots), and
the possible repeat of the message are turned off.

The return status from the call is will still be the appropriate
value for the severity code.

=head3 -step

Sets the indentation step size (number of spaces) for nesting messages.
The default is 2.
Set to 0 to disable indentation - all messages will be left justified.
Set to a small positive integer to use that step size.

=head3 -timestamp

If false (the default), emitted lines are not prefixed with a timestamp.
If true, the default local timestamp HH::MM::SS is prefixed to each emit line.
If it's a coderef, then that function is called to get the timestamp string.
The function is passed the current indent level, for what it's worth.
Note that no delimiter is provided between the timestamp string and the 
emitted line, so you should provide your own (a space or colon or whatever).
Also, emit_text() output is NOT timestamped, just that from emit() and 
its closure.

=head3 -trailer

The B<single> character used to trail after a message up to the
completion severity.
The default is the dot (the period, ".").  Here's what messages
look like if you change it to an underscore:

  The code:
    use Term::Emit ':all', {-trailer => '_'};
    emit "Xerikineting";

  The output:
    Xerikineting...______________________________ [DONE]

Note that the ellipsis after the message is still "...";
use -ellipsis to change that string as well.

=head3 -want_level

Indicates the needed matching scope level for an autoclosure call
to emit_done().  This is really an internal option and you should
not use it.  If you do, I'll bet your output would get all screwy.
So don't use it.

=head3 -width

Sets the terminal width of your output device.  I<Term::Emit> has no
idea how wide your terminal screen is, so use this option to
indicate the width.  The default is 80.

You may want to use L<Term::Size::Any|Term::Size::Any>
to determine your device's width:

    use Term::Emit ':all';
    use Term::Size::Any 'chars';
    my ($cols, $rows) = chars();
    Term::Emit::setopts(-width => $cols);
      .
      .
      .

=head1 CONFIGURATION AND ENVIRONMENT

I<Term::Emit> requires no configuration files or environment variables.
However, it does set environment variables with this form of name:

    term_emit_fd#_th#

This envvar holds the current level of messages (represented
visually by indentation), so that indentation can be smoothly
maintained across process contexts.

In this envvar's name, fd# is the fileno() of the output file handle to which
the messages are written.  By default output is to STDERR,
which has a fileno of 2, so the envvar would be C<term_emit_fd2>.
If output is being written to a string (C<<-fh => \$some_string>>),
then fd# is the string "str", for example C<term_emit_fdstr>

When Term::Emit is used with threads, the thread ID is placed
in th# in the envvar.
Thus for thread #7, writing Term::Emit messages to STDERR, the envvar
would be C<term_emit_fd2_th7>.
For the main thread, th# and the leading underscore are omitted.

Under normal operation, this environment variable is deleted
before the program exits, so generally you won't see it.

Note: If your program's output seems excessively indented, it may be
that this envvar has been left over from some other aborted run.
Check for it and delete it if found.

=head1 DEPENDENCIES

This pure-Perl module depends upon Scope::Upper.

=head1 DIAGNOSTICS

None.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

Limitation:  Output in a threaded environment isn't always pretty.
It works OK and won't blow up, but indentation may get a bit screwy.
I'm workin' on it.

Bugs: No bugs have been reported.

Please report any bugs or feature requests to
C<bug-term-emit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

To format C<Term::Emit> output to HTML, use
L<Term::Emit::Format::HTML|Term::Emit::Format::HTML> .

Other modules like C<Term::Emit> but not quite the same:

=over 4

=item *

L<Debug::Message|Debug::Message>

=item *

L<Log::Dispatch|Log::Dispatch>

=item *

L<PTools::Debug|PTools::Debug>

=item *

L<Term::Activity|Term::Activity>

=item *

L<Term::ProgressBar|Term::ProgressBar>

=back

=head1 AUTHOR

Steve Roscio  C<< <roscio@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Thanx to Paul Vencel for his review of this package, and to Jimmy Maguire
for his namespace advice.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2012, Steve Roscio C<< <roscio@cpan.org> >>.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law.  Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose.  The
entire risk as to the quality and performance of the software is with
you.  Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=for me to do:
    * Get this to work back at 5.006
    * Validate any given options
    * Fixup anonymous literals
    * Hmmm... how to setopts() the default -fh  vs. setopts() for a particular -fh?
    * Make a 'print' wrapper to keep track of position,
       and POD about interaction with print
       then a function to reset the internal position (or use a setopts() attr)
    * Make emit() use indirect object notation so it's a drop-in for print
        ** But do we want the overhead of IO::Handle?
    * Timestamps - maybe do in another module?
        Allow timestamps in something akin to sprintf format within the strings.
        IE, solve this problem:
            emit ["Starting Frobnication process at %T",
                  "Frobnication process complete at %T"];
    * emit_more : another emit at the same level as the prior?
       for example:
           emit "yomama";
           emit_more "yopapa";  # does not start a new context, like emit_text
             but at upper level (or call it "yell"?)
    * Thread support
    * Add a "Closing Silently" section up around the closing w/diff text section.
    * Read envvars for secondary defaults, so qx() wrapping looks consistent.
    * Envvars for color, width, maxdepth, etc...
       ** export the envvars (in setopts()) so wrapped scripts pick 'em up
       ** clean up the envvars, iff we set 'em
       ** make 'em work by fd# as well, not just default.  IE, have
            term_emit_color apply to the default fd, but
            term_emit_fd2_color applies to stdout.  And so on.
