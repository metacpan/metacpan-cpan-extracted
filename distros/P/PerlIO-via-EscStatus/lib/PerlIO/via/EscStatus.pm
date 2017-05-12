# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.

package PerlIO::via::EscStatus;
use 5.008005; # for unicode properties
use strict;
use warnings;
use Carp;
use Term::Size;
use List::Util qw(min max);
use IO::Handle;  # $fh->flush method

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(ESCSTATUS_STR print_status make_status);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use PerlIO::via::EscStatus::Parser;
use Regexp::Common 'ANSIescape', 'no_defaults';

our $VERSION = 11;

# set this to 1 or 2 for some diagnostics to STDERR
use constant DEBUG => 0;


# Flush crib notes:
#
# IO::Handle::flush(), an xsub, calls PerlIO_flush() (per perlapio) and
# returns a status which can be returned by WRITE or CLOSE.
#
# A "local $|=1" to make print() do a flush (in the style of
# IO::Handle::printflush()) gets the flush status incorporated into the
# print() success return, but it does "flush/print/flush", and that first
# flush is wasteful.
#
# Believe autoflush $| is always off on the $fh subhandle, irrespective of
# whether or not it's set on the top-level.  Is that right?
#
# There's only two places to flush the lower handle: WRITE is the main one,
# and POPPED the other (apart from an explicit FLUSH).

use constant { TABSTOP => 8,
               ESCSTATUS_STR => "\e_EscStatus\e\\"
             };

#------------------------------------------------------------------------------
# public funcs

sub print_status {
  return print make_status(@_);
}

sub make_status {
  my $str = join('',@_);
  $str =~ s/^\n+//;
  $str =~ s/\n+$//;
  $str =~ s/\n/ /g;
  return ESCSTATUS_STR . $str . "\n";
}

#------------------------------------------------------------------------------
#
# Fields in each instance:
#
# "display" -- boolean whether to display the status.  True when the last
# ordinary output char was a newline.  Status display is held off until any
# line of ordinary output is complete.  When first pushed assume we it's the
# start of a line.
#
# "status" -- current status string, or empty string '' for none.  This has
# been truncated to the tty width (the tty width as of when the status
# arrived).
#
# "status_width" -- the print-width of the "status" string.  This can differ
# from its length() due to tabs and zero-width and double-width unicode
# chars.
#
# "parser" -- PerlIO::via::EscStatus::Parser object.
#
# "utf8" -- boolean, initialized by UTF8() below.  True when we turned on
# the utf8 flag on our layer.  This is instance data because there doesn't
# seem to be a way for a PerlIO::via module to inspect its own layer flags
# later.
#
sub PUSHED {
  my ($class, $mode, $fh) = @_;
  if (DEBUG) {
    require Data::Dumper;
    print STDERR "PUSHED ", Data::Dumper::Dumper ([$class,$mode,$fh]);
  }
  return bless { display      => 1,
                 status       => '',
                 status_width => 0,
                 parser       => PerlIO::via::EscStatus::Parser->new,
               }, $class;
}

sub UTF8 {
  my ($self, $belowFlag, $fh) = @_;
  if (DEBUG) { print STDERR "UTF8: ",$belowFlag?"yes":"no","\n"; }
  return ($self->{'utf8'} = $belowFlag);
}

# Cribs:
#   - close() calls CLOSE followed by POPPED
#   - binmode() removing the layer calls POPPED alone
#   - if PUSHED returns -1 then POPPED is called with class name and undef,
#     but that doesn't apply as our push always succeeds
#
# As of Perl 5.10.0 CLOSE is called after PerlIO::via has closed the
# sublayers (with PerlIOBase_close()) in $fh, so unfortunately it's too late
# to print an _erase_status().  There's a FLUSH call from PerlIOBase_close()
# just before the close, but there's no obvious way to tell it's the
# last-ever flush.
#
# For POPPED must call flush on the sublayers to get the _erase_status() to
# show immediately; nothing other happens on the sublayers just because
# we're being popped.
#
sub CLOSE {
  my ($self, $fh) = @_;
  if (DEBUG) { print STDERR "CLOSE() $self $fh\n"; }

  # no good, $fh already closed
  # return _erase_status ($self, $fh, 0);

  # treat as now no status showing
  $self->{'status'} = '';
  $self->{'status_width'} = 0;
  return 0; # success
}
sub POPPED {
  my ($self, $fh) = @_;
  if (DEBUG) { print STDERR "POPPED() $self ", (defined $fh ? $fh : 'undef'), "\n"; }
  _erase_status ($self, $fh, 1);
  return 0; # always claim success, per perliol(1) docs
}
# return 0 success, -1 failure
sub _erase_status {
  my ($self, $fh, $want_flush) = @_;
  if ($self->{'display'} && $self->{'status_width'} != 0) {
    my $output = "\r" . (' ' x $self->{'status_width'}) . "\r";
    $self->{'status'} = '';
    $self->{'status_width'} = 0;
    print $fh $output
      or do {
        if (DEBUG) { print STDERR "_erase_status print error: $!\n"; }
        return -1;
      };
    if ($want_flush) {
      $fh->flush()
        or do {
          if (DEBUG) { print STDERR "_erase_status flush error\n"; }
          return -1;
        };
    }
  }
  return 0;
}

# As of perl 5.10.0 the default in PerlIO::via is to do nothing if you don't
# supply a FLUSH, so chain down explicitly.
sub FLUSH {
  my ($self, $fh) = @_;
  if (DEBUG) { print STDERR "EscStatus FLUSH $self $fh\n"; }
  if ($fh) {
    return $fh->flush;
  } else {
    return 0; # success
  }
}

sub WRITE {
  my ($self, $buf, $fh) = @_;
  my $ret_ok = length ($buf);
  if (DEBUG >= 2) {
    require Data::Dumper;
    print STDERR "WRITE len=",length($buf),
      " utf8=",utf8::is_utf8($buf)?"yes":"no",
      " ", Data::Dumper->new([$buf])->Useqq(1)->Dump;
  }
  my $want_flush = 0;

  my $status = $self->{'status'};
  my $status_width = $self->{'status_width'};

  if ($self->{'utf8'}) {
    require Encode;
    Encode::_utf8_on($buf);
  }
  my ($new_status, $ordinary) = $self->{'parser'}->parse($buf);
  my $output = $ordinary;

  my $new_status_width;
  if (defined $new_status) {
    ($new_status, $new_status_width)
      = _truncate ($new_status, _term_width($fh) - 1);

    if ($new_status eq $status) {
      $new_status = undef; # ignore if unchanged
    }
  }

  if ($ordinary eq '' && defined $new_status && $self->{'display'}) {
    # optimized update of existing status, letting the new overwrite the
    # old, instead of using all spaces
    my $end_len = max (0, $status_width - $new_status_width);
    $output = "\r" . $new_status . (' ' x $end_len) . ("\b" x $end_len);
    $want_flush = 1;
    $self->{'status'} = $new_status;
    $self->{'status_width'} = $new_status_width;
    goto OUTPUT;
  }

  my $want_status_reprint = ($ordinary ne '' || defined $new_status);

  if ($want_status_reprint
      && $self->{'display'}
      && $self->{'status'} ne '') {
    if (_str_first_line_covers_n ($ordinary, $status_width)) {
      $output = "\r" . $output;
    } else {
      $output = "\r" . (' ' x $status_width) . "\r" . $output;
    }
  }

  if (defined $new_status) {
    $self->{'status'} = $status = $new_status;
    $self->{'status_width'} = $new_status_width;
  }

  # if there's some ordinary text being printed then update "display"
  # if the new text ends with newline then should display status
  if ($ordinary ne '') {
    $self->{'display'} = ($ordinary =~ /\n$/);
  }

  if ($self->{'display'} && $want_status_reprint && $status ne '') {
    $output .= $status;
    $want_flush = 1;
  }

 OUTPUT:
  # Believe for 5.10.0 the utf8 flag should be on the $output string when we
  # (and the sublayer) are in utf8 mode.  Suspect anything seen in the past
  # contradicting that was due to PerlIO_findFILE() in Term::Size mangling
  # the whole stack to a :stdio and turning off the utf8 layer flag(s).
  #
  # if ($self->{'utf8'}) { Encode::_utf8_off ($output); }

  if (DEBUG >= 2) {
    require Data::Dumper;
    my $dumper = Data::Dumper->new ([$output]);
    $dumper->Useqq(1);
    print STDERR "  to lower layer len=",length($output),
      " utf8=",utf8::is_utf8($output)?"yes":"no",
      " ", $dumper->Dump;
  }

  print $fh $output or return -1;
  if ($want_flush) { $fh->flush() or return -1; }
  return $ret_ok;
}

#------------------------------------------------------------------------------

# Zero-width char class.
# CR treated as zero width in case it occurs as CRLF.
#
use constant IsZero =>
    "+utf8::Me\n"  # mark, enclosing
  . "+utf8::Mn\n"  # mark, non-spacing
  . "+utf8::Cf\n"  # control, format
  . "-00AD\n"      #    but exclude soft hyphen which is in Cf
  . "+0007\n"      # BEL
  . "+000D\n";     # CR, for our purposes

# Double-width char class, being East Asian "wide" and "full" chars.
# Rumour has it this might be locale-dependent.  When turned into a
# non-unicode charset there can be slightly different width rules, or
# something like that.
#
use constant IsDouble =>
    "+utf8::EastAsianWidth:W\n"
  . "+utf8::EastAsianWidth:F\n";

# "Other" char class, being anything which doesn't introduce one of the
# other regexp subexprs, and meaning in practice a single-width char.
#
use constant IsOther =>
    "!PerlIO::via::EscStatus::IsZero\n"
  . "-PerlIO::via::EscStatus::IsDouble\n"
  . "-0009\n"         # not a Tab
  . "-001B\n"         # not an Esc
  . "-0080\t009F\n";  # not an ANSI 8-bit escape, including not CSI

# Return true if $str has a complete first line ending in \n and that line
# is long enough to overwrite $n chars.
sub _str_first_line_covers_n {
  my ($str, $n) = @_;
  if ($str !~ /^(.*?)\n/) { return 0; } # not a whole first line
  my (undef, $gotlen) = _truncate ($1, $n + 2 * TABSTOP);
  return ($gotlen >= $n);
}

# _truncate() truncates $str to fit in $limit columns.
#
# The return is two values ($part, $cols).  $part is a leading portion of
# $str, and possibly later ANSI escapes.  $cols is how many columns $part
# takes when printed.
#
# For the common case of a run of single-width ascii chars, there's one
# regexp match for the whole lot, then a second notices end of string.
#
# Text::CharWidth has some similar stuff for IsZero, IsDouble, etc, but
# operates on locale byte strings rather than perl wide chars.  Not sure if
# the width is supposed to be locale-dependent, or just character dependent.
# Strictly speaking it depends on the tty anyway.
#
sub _truncate {
  my ($str, $limit) = @_;
  my $ret = '';
  my $col = 0;
  my $overflow = 0;

  while ($str =~ /\G((\p{IsZero}+)   # $2
                  |(\p{IsDouble}+)   # $3
                  |(\t)               # $4
                  |($RE{ANSIescape})  # $5
                  |\p{IsOther}+
                  |.                  # plain Esc, either non-ANSI or malformed
                  )/gxo) {  # o -- compile $RE once
    my $part = $1;
    if (DEBUG >= 2) { require Data::Dumper;
                      my $dumper = Data::Dumper->new ([$part]);
                      $dumper->Useqq(1);
                      print STDERR "  +$col ",$dumper->Dump; }

    if (defined $5) {
      # an ANSI escape sequence, keep all escape sequences
      $ret .= $part;
      next;
    }
    if ($overflow) {
      # exclude ordinary chars once overflowed
      next;
    }

    if (defined $2) {
      # a run of zero width chars, no change to col
      if (DEBUG >= 2) { print STDERR "  zero width\n"; }

    } elsif (defined $3) {
      # a run of double-width chars
      my $room = int (($limit - $col) / 2); # round down
      if (DEBUG >= 2) {
        print STDERR "  doubles ".length($part)." in $room\n";
      }
      if (length($part) > $room) {
        # truncate
        $part = substr ($part, 0, $room);
        $overflow = 1;
      }
      $col += 2 * length($part);

    } elsif (defined $4) {
      # a tab (treated one at a time for ease of coding!)
      if (DEBUG >= 2) { print STDERR "  tab\n"; }
      my $newcol = $col + TABSTOP - ($col % TABSTOP);
      if ($newcol > $limit) {
        $overflow = 1;
        next;
      }
      $col = $newcol;

    } else {
      # a run of single-printing chars, or a single non-ansi Esc or other
      my $room = $limit - $col;
      if (DEBUG >= 2) {
        print STDERR "  singles ".length($part)." in $room\n";
      }
      if (length($part) > $room) {
        # truncate
        $part = substr ($part, 0, $room);
        $overflow = 1;
      }
      $col += length($part);
    }

    $ret .= $part;
  }

  if (DEBUG >= 2) { require Data::Dumper;
                    my $dumper = Data::Dumper->new ([$ret]);
                    $dumper->Useqq(1);
                    print STDERR "  ret $col ",$dumper->Dump; }
  return ($ret, $col);
}

# This _term_width() is a nasty hack for perl 5.10.0 where PerlIO_findFILE()
# as used by Term::Size 0.2, through the "FILE*" typemap, clears the :utf8
# flag on a perlio layer.  Not sure if that clearing is a bug or a feature.
# It might be a feature in that you lose translations when going to raw
# stdio.  In any case until Term::Size uses PerlIO_fileno() have a
# workaround here with a temporary stream on a dup-ed fileno() of $fh to
# keep the original safe from harm.
#
# There's probably plenty of other strategies for an idea of "print width"
# on a stream.  Some sort of property of the whole stream, or per-layer,
# which could be overridden when you want wider or narrower output no matter
# what the underlying fd claims (eg. from a "COLUMNS" envvar) ...
#
# Note: If $fh is only for read then '>&' mode makes $tmp give a FILE* as
# NULL, which seg-faults with Term::Size 0.2.  Should be output-only in the
# uses from WRITE, but wouldn't mind guarding against that, or depending on
# a better Term::Size.
#
sub _term_width {
  my ($fh) = @_;
  my $width;
  my $fd = fileno($fh);
  if (DEBUG >= 2) { print STDERR "_term_width on fd=",
                      (defined $fd ? $fd : 'undef'), "\n"; }
  if (defined $fd) {
    if (open my $tmp, '>&', $fd) {
      $width = Term::Size::chars($tmp);
      close $tmp or die;
    }
  }
  return ($width || 80);
}

1;
__END__

=head1 NAME

PerlIO::via::EscStatus - dumb terminal status display layer

=head1 SYNOPSIS

 use PerlIO::via::EscStatus qw(print_status);
 binmode (STDOUT, ':via(EscStatus)') or die;

 print_status ("Done 10% ...");
 print_status ("Done 20% ...");
 print "This is ordinary text output.\n";
 print_status ("Done 90% ...");
 print_status ("");   # erase status

=head1 DESCRIPTION

An EscStatus layer prints and reprints a status line using carriage returns
and backspaces for a dumb terminal.  This is meant as a progress or status
display in a command line program.

    Working ... record 20 of 80 (25%)
                                     ^--cursor left here

Status lines are communicated to EscStatus "in band" in the output stream
using an escape sequence.  Currently this is an ANSI "APC" application
control followed by the status line.  C<make_status()> and C<print_status()>
below produce this.

    "\e_EscStatus\e\\Status string\n"

The layer clears and redraws the status when ordinary output text is printed
so it appears as normal.  The status is also erased when the layer is
popped, though unfortunately not when the stream is closed (see L</BUGS>
below).

See F<examples/demo.pl> in the PerlIO-via-EscStatus sources for a simple
complete program.

=head2 Motivation

The idea of an output layer is that it lets you send ordinary output with
plain C<print>, C<printf>, etc, and the layer takes care of what status is
showing and should be cleared and redrawn.

The alternative is a special message printing function to do the clearing.
If you're in full control of your ordinary output then that's fine (for
instance C<Term::ProgressBar> does it that way), but if you might have parts
of a library or program only setup with plain C<print> then a layer is a
good way to keep them from making a mess of the display.

The "in-band" method of passing status strings to the layer has the
advantage that higher layers can buffer or do extra transformations and
everything stays in the intended sequence.  It's even possible for a status
stream to come from a child process through a pipe or socket and stay in the
escapes form until being re-sent to a final EscStatus layer on C<STDOUT>.

The escape format chosen is meant to be easy to produce and tolerably
readable if for some reason crunching by EscStatus is missed.  The
C<EscStatus::ShowAll> layer lets you explicitly print all status lines for
development.  Or the C<EscStatus::ShowNone> layer strips them for a quiet
mode or batch mode operation.  (See L<PerlIO::via::EscStatus::ShowAll> and
L<PerlIO::via::EscStatus::ShowNone>.)

=head1 CHARACTERS

Each status line is truncated to the width of the terminal as determined by
C<Term::Size::chars()> (see L<Term::Size>).  No attempt is made (as yet) to
monitor C<SIGWINCH> for changes to the width, though the size is checked for
each new line so the next new status uses the new size.

EscStatus follows the "utf8" flag of the layer below it when first pushed,
allowing extended characters to be printed.  Often the layer below will be
an C<":encoding"> for the user's terminal (eg. F<examples/fracs.pl> in the
PerlIO-via-EscStatus sources).  The difference for EscStatus is in the
string width calculations for utf8 multibyte sequences.  Note that changing
the utf8 flag after pushing doesn't work properly (see L</BUGS> below).

For string width calculations tabs (C<\t>) are 8 spaces.  Various East Asian
"double-width" characters take two columns.  BEL (C<\a>), ANSI escapes, and
various unicode modifier characters take no space.  See F<examples/wide.pl>
in the PerlIO-via-EscStatus sources for a complete program printing
double-width East Asian characters.

If a status line is truncated then all ANSI escapes are kept, so if say bold
is turned on and off then the off escape is preserved.  See
F<examples/colour.pl> in the PerlIO-via-EscStatus sources for an example of
SGR colour escapes.

If a lower layer expands a character because it's unencodable on the final
output then that's likely to make a mess of the width calculation.  For
example the C<:encoding> layer C<PERLQQ> mode turns unencodables into an 8
character sequence C<"\x{1234}">, which is more than EscStatus will have
allowed for.  The suggestion is to expand or transform before EscStatus so
it sees what's really going to go out.  An encode and re-decode is one way
to do that, though a bit wasteful.

=head1 FUNCTIONS

=over 4

=item C<< print_status ($str,...) >>

=item C<< $str = make_status ($str,...) >>

Form a status line output string by concatenating the given C<$str> strings
and adding the necessary escape marker sequences.  C<print_status> prints it
to C<STDOUT>, C<make_status> returns it as a string.

Any newlines in the middle of the strings are changed to spaces, since only
a single line of status is possible.

=back

=head1 OTHER NOTES

The suggestion is to push C<PerlIO::via::EscStatus> onto C<STDOUT> and leave
C<STDERR> alone.  Leaving C<STDERR> alone has the advantage of not putting
anything in the way of an unexpected error print.  You can trap "normal"
errors and turn them into a print on C<STDOUT>, leaving C<STDERR> only for
the unexpected.  The alternative is to C<< >&= >> alias stderr onto stdout.
That makes sense since there's only one actual destination (the terminal),
once you trust EscStatus not to lose anything!

When updating a displayed status it's important not to hammer the terminal
with too much output.  It can easily become the speed of the terminal and
not the speed of the program which is the limiting factor.  Generally the
trick is to print a new status only say once per second.  This means the
display isn't perfectly up-to-date, but the only time that's a problem is if
the program goes away number crunching for a long time with an old status
showing, in which case the wrong processing stage gets the blame for the
delay.

=head1 BUGS

When the stream is closed the status shown by EscStatus is not erased.  This
is because C<PerlIO::via> closes the sublayers first.  Perhaps that can
change in the future.  The suggestion when closing is to either print an
empty status to clear, or to pop the EscStatus (erasing works when popped).

    print_status ('');
    close STDOUT;  # or "exit 0" or whatever

If the utf8 flag on the stream is changed (by C<binmode>) EscStatus doesn't
notice and will keep using the state when it was first pushed.  Perhaps this
will change in the future, assuming there's sensible uses for turning it on
and off dynamically.

C<Term::Size> version 0.2 uses C<PerlIO_findFILE> and as of Perl 5.10.0 that
turns off the C<utf8> flag on the stream, preventing wide-char output.
EscStatus has a workaround for its use of C<Term::Size> but an application
might need to do the same.  The symptom is the usual "Wide character in
print" warning, on a stream you thought you'd already set for wide output.

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::EscStatus::ShowAll>,
L<PerlIO::via::EscStatus::ShowNone>,
L<ProgressMonitor::Stringify::ToEscStatus>

L<Term::Sk> formatting progress status messages, and F<examples/term-sk.pl>
in the PerlIO-via-EscStatus sources for combining that with EscStatus.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perlio-via-escstatus/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

PerlIO-via-EscStatus is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

PerlIO-via-EscStatus is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
PerlIO-via-EscStatus.  If not, see L<http://www.gnu.org/licenses/>.

=cut
