# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

package Regexp::Common::ANSIescape;
use 5.005;
use strict;
use Carp;
# no import(), don't want %RE or builtins, and can call pattern() by full name
use Regexp::Common ();

use vars '$VERSION';
$VERSION = 14;

## no critic (ProhibitEscapedCharacters)


use constant CSI_7BIT => "\e\\\x5B";  # ie. Esc and a literal [ char
use constant CSI_8BIT => "\x9B";

# C1 Esc @ through Esc _
# excluding CSI which is Esc 0x5B, and 0x9B
# Note \x5C is "\" so doubled to escape.
#
use constant C1_ALL_7BIT => "\e[\x40-\x5A\\\x5C-\x5F]";
use constant C1_ALL_8BIT =>   "[\x80-\x9A\x9C-\x9F]";

# C1 forms taking a string parameter
#
#   DCS   Esc P  (0x50 / 0x90)
#   SOS   Esc X  (0x58 / 0x98)
#   OSC   Esc ]  (0x5D / 0x9D)
#   PM    Esc ^  (0x5E / 0x9E)
#   APC   Esc _  (0x5F / 0x9F)
#
# Note \x5D "]" first in the char class, and \x5E "^" not first.
#
use constant C1_STR_7BIT => "\e[\x5D\x50\x58\x5E\x5F]";
use constant C1_STR_8BIT =>   "[\x9D\x90\x98\x9E\x9F]";

# "character string" is anything except SOS or ST
use constant CHAR_STR => "(.|\n)*?";

# C1 forms not taking a string parameter
# this is C1_ALL except the five in C1_STR (and not CSI 0x5B,0x9B)
# Note \x5C "\" doubled to escape.
#
use constant C1_NST_7BIT => "\e[\x40-\x4F\x51-\x57\x59\x5A\\\x5C]";
use constant C1_NST_8BIT =>   "[\x80-\x8F\x91-\x97\x99\x9A\x9C]";

# ST string terminator
use constant ST_7BIT => "\e\\\\";  # ie. Esc and a backslash
use constant ST_8BIT => "\x9C";

use constant CSI_7OR8    => '(?:'. CSI_7BIT    .'|'. CSI_8BIT    .')';
use constant C1_STR_7OR8 => '(?:'. C1_STR_7BIT .'|'. C1_STR_8BIT .')';
use constant ST_7OR8     => '(?:'. ST_7BIT     .'|'. ST_8BIT     .')';


Regexp::Common::pattern
  (name   => ['ANSIescape'],
   create => sub {
     my ($self, $flags) = @_;

     if (exists $flags->{-only7bit} && exists $flags->{-only8bit}) {
       croak 'ANSIescape: cannot have only7bit and only8bit at the same time';
     }

     my @ret;
     push @ret, (exists $flags->{-only7bit}   ? CSI_7BIT  # 7-bit only
                 : exists $flags->{-only8bit} ? CSI_8BIT  # 8-bit only
                 :                              CSI_7OR8) # 7bit or 8bit
       . "(?k:[\x30-\x3F]*)(?k:[\x20-\x2F]*[\x40-\x7E])";

     if (exists $flags->{-sepstring}) {
       if (! exists $flags->{-only8bit}) { push @ret, C1_ALL_7BIT; }
       if (! exists $flags->{-only7bit}) { push @ret, C1_ALL_8BIT; }

     } else {
       if (! exists $flags->{-only8bit}) { push @ret, C1_NST_7BIT; }
       if (! exists $flags->{-only7bit}) { push @ret, C1_NST_8BIT; }

       if (exists $flags->{-only7bit}) {
         push @ret, C1_STR_7BIT . CHAR_STR . ST_7BIT;  # 7-bit only
       } elsif (exists $flags->{-only8bit}) {
         push @ret, C1_STR_8BIT . CHAR_STR . ST_8BIT;  # 8-bit only
       } else {
         push @ret, C1_STR_7OR8 . CHAR_STR . ST_7OR8;  # 7-bit or 8-bit
       }
     }
     return '(?k:' . join('|',@ret) . ')';
   });


# Some stuff which might have distinguished SOS taking "character string"s
# from others taking only "command string" chars
#
# C1_SOS_7BIT => "\e[\x58]";
# C1_SOS_8BIT =>   "[\x98]";
# C1_SOS_7OR8    => '(?:'. C1_SOS_7BIT .'|'. C1_SOS_8BIT .')';
# # "command string" is Backspace, Tab, LF, VT, FF, CR and printables
# CMD_STR => "[\x08-\x0D\x20-\x7E]*?",
# push @ret, C1_SOS_7BIT   . CHAR_STR . ST_7BIT;
# push @ret, C1_SOS_8BIT   . CHAR_STR . ST_8BIT;
# push @ret, C1_SOS_7OR8   . CHAR_STR . ST_7OR8;
#

1;

__END__

=head1 NAME

Regexp::Common::ANSIescape -- regexps for ANSI terminal escapes

=for test_synopsis my ($str)

=head1 SYNOPSIS

 use Regexp::Common 'ANSIescape', 'no_defaults';

 if ($str =~ /$RE{ANSIescape}/) {
    # ...
 }

 my $re1 = $RE{ANSIescape}{-only7bit};
 my $re2 = $RE{ANSIescape}{-sepstring};

=head1 DESCRIPTION

See L<Regexp::Common> for the basics of C<Regexp::Common> patterns.  An
ANSIescape pattern matches an ANSI terminal escape sequence like

    Esc[30;48m             # CSI sequence
    Esc[?1h                # CSI with private params
    EscU                   # C1 control
    Esc_ APPSTRING Esc\    # C1 with string param

    \x9B 30m               # ditto in 8-bit intro
    \x9B ?1h
    \x85
    \x9F APPSTRING \x9C

Here "Esc" means C<\x1B> ASCII escape character.  The 7-bit forms are Esc
followed by various combinations of printable ASCII C<"\x20"> through
C<"\x7E">.

The 8-bit forms use bytes C<"\x80"> through C<"\x9F">.  The C<-only7bit>
option below can omit the 8-bit patterns if they might have another
meaning.

=over 4

=item *

ISO-8859 character sets such as Latin-1 don't use C<\x80> through C<\x9F>,
so they're free to be the ANSI escapes.

=item *

Unicode code points C<\x80> through C<\x9F> have the ANSI meaning, so Perl
wide-char strings on ASCII systems are fine (but not EBCDIC systems).

=item *

UTF-8 encoding uses bytes C<\x80> through C<\x9F> as intermediate parts of
normal characters, so must either decode to code points first, or use
C<-only7bit>.

=item *

Other encodings may use C<\x80> through C<\x9F> as characters, eg. DOS code
page 1252 extension of Latin-1.  Generally C<-only7bit> should be used in
that case.

=back

=for ProhibitUnbalancedParens allow next

The parameter part like "0" in "Esc[0m" can be any bytes 0x30 through 0x3F.
This means "private parameter" values like the VT100 "DECSET" extensions are
matched.

=head1 OPTIONS

=over 4

=item C<{-only7bit}>

=item C<{-only8bit}>

Match only the 7-bit forms like C<"\eE">.  Or match only the 8-bit forms
like C<"\x{85}">.  The default is to match both.  The 7-bit forms are the
most common.

=item C<{-sepstring}>

By default the string parameter to APC, DCS, OSC, PM and SOS is included in
the match, for example an APC like the following is matched in its entirety.

    \x{9F}Stringarg\x{9C}

With C<-sepstring> the pattern instead matches the start "\x{9F}" and the
terminator "\x{9C}" individually, with the C<Stringarg> part unmatched.

In both cases the strings can be any characters through to the first ST
form.  The ANSI standard restricts the characters allowed in the "command
string" of APC, DCS, OSC and PM, whereas anything can be a "character
string" to SOS.  The "command string" restrictions are not enforced by
ANSIescape.

=item C<{-keep}>

With the standard C<-keep> option, grouping parens are included in the
regexps to set the following capture variables

=over 4

=item C<$1>

The entire escape sequence.

=item C<$2>

The parameters to a CSI sequence.  For example

    \e[30;49m    ->   30;49      (SGR)
    \e[?5h       ->   ?5         (DECSCNM extension)

=item C<$3>

Intermediate characters (if any) and final character of a CSI escape.  For
example

    \e[30m       ->   m
    \e[30+P      ->   +P

=back

=back

=head1 IMPORTS

ANSIescape should be loaded through the C<Regexp::Common> mechanism, see
L<Regexp::Common/Loading specific sets of patterns.>.  Remember that loading
a non-builtin pattern like ANSIescape also loads all the builtin patterns.

    # ANSIescape plus all builtins
    use Regexp::Common 'ANSIescape';

If you want only C<$RE{ANSIescape}> then add C<no_defaults> (or a specific
set of desired builtins).

    # ANSIescape alone
    use Regexp::Common 'ANSIescape', 'no_defaults';

=head1 SEE ALSO

L<Regexp::Common>

The ANSI standard can be obtained as ECMA-48 at

    http://www.ecma-international.org/publications/standards/Ecma-048.htm

=head1 HOME PAGE

http://user42.tuxfamily.org/regexp-common-other/index.html

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015 Kevin Ryde

Regexp-Common-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Regexp-Common-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
