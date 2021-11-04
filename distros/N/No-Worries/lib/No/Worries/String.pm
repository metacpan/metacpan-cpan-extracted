#+##############################################################################
#                                                                              #
# File: No/Worries/String.pm                                                   #
#                                                                              #
# Description: string handling without worries                                 #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::String;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Export qw(export_control);
use Params::Validate qw(validate validate_pos :types);

#
# global variables
#

our(
    @_ByteSuffix,  # byte suffixes used by bytefmt
    @_Map,         # mapping of characters to escaped strings
    %_Plural,      # pluralization cache
);

#
# format a number of bytes
#

sub string_bytefmt ($;$) {
    my($number, $precision) = @_;
    my($index);

    $precision = 2 unless defined($precision);
    $index = 0;
    while ($_ByteSuffix[$index] and $number > 1024) {
        $index++;
        $number /= 1024.0;
    }
    return("$number $_ByteSuffix[$index]") if $number =~ /^\d+$/;
    return(sprintf("%.${precision}f %s", $number, $_ByteSuffix[$index]));
}

#
# escape a string (quite compact, human friendly but not Perl eval()'able)
#

sub string_escape ($) {
    my($string) = @_;
    my(@list);

    validate_pos(@_, { type => SCALAR });
    foreach my $ord (map(ord($_), split(//, $string))) {
        push(@list, $ord < 256 ? $_Map[$ord] : sprintf("\\x{%04x}", $ord));
    }
    return(join("", @list));
}

#
# return the plural form of the given noun
#

sub string_plural ($) {
    my($noun) = @_;

    unless ($_Plural{$noun}) {
        if ($noun =~ /(ch|s|sh|x|z)$/) {
            $_Plural{$noun} = $noun . "es";
        } elsif ($noun =~ /[bcdfghjklmnpqrstvwxz]y$/) {
            $_Plural{$noun} = substr($noun, 0, -1) . "ies";
        } elsif ($noun =~ /f$/) {
            $_Plural{$noun} = substr($noun, 0, -1) . "ves";
        } elsif ($noun =~ /fe$/) {
            $_Plural{$noun} = substr($noun, 0, -2) . "ves";
        } elsif ($noun =~ /[bcdfghjklmnpqrstvwxz]o$/) {
            $_Plural{$noun} = $noun . "es";
        } else {
            $_Plural{$noun} = $noun . "s";
        }
    }
    return($_Plural{$noun});
}

#
# quantify the given (count, noun) pair
#

sub string_quantify ($$) {
    my($count, $noun) = @_;

    return($count . " " . ($count == 1 ? $noun : string_plural($noun)));
}

#
# return the real length of a string (removing ANSI Escape sequences)
#

sub _strlen ($) {
    my($string) = @_;

    return(0) unless defined($string);
    $string =~ s/\x1b\[[0-9;]*[mGKH]//g;
    return(length($string));
}

#
# return an aligned and padded string
#

sub _strpad ($$$) {
    my($string, $length, $align) = @_;
    my($strlen, $before, $after);

    $string = "" unless defined($string);
    $strlen = _strlen($string);
    $align ||= "left";
    if ($align eq "left") {
        $before = 0;
        $after = $length - $strlen;
    } elsif ($align eq "right") {
        $before = $length - $strlen;
        $after = 0;
    } elsif ($align eq "center") {
        $before = ($length - $strlen) >> 1;
        $after = $length - $strlen - $before;
    } else {
        die("unexpected alignment: $align\n");
    }
    return((" " x $before) . $string . (" " x $after));
}

#
# return a string generated from a repeated pattern
#

sub _strgen ($$) {
    my($pattern, $length) = @_;

    return(substr($pattern x $length, 0, $length));
}

#
# return a formatted table line
#

sub _tblfmt ($$) {
    my($column, $option) = @_;
    my($line, $index);

    $line = $option->{indent};
    $line .= $option->{lsep};
    $index = 0;
    while ($index < @{ $option->{collen} }) {
        $line .= $option->{colsep} if $index;
        $line .= _strpad($column->[$index],
                         $option->{collen}[$index],
                         $option->{align}[$index]);
        $index++;
    }
    $line .= $option->{rsep};
    $line .= "\n";
    return($line);
}

#
# transform a table into a string
#

my %string_table_options = (
    align    => { optional => 1, type => ARRAYREF },
    colsep   => { optional => 1, type => SCALAR },
    header   => { optional => 1, type => ARRAYREF },
    headsep  => { optional => 1, type => SCALAR },
    indent   => { optional => 1, type => SCALAR },
    markdown => { optional => 1, type => BOOLEAN },
);

sub string_table ($@) {
    my($lines, %option, @collen, @headsep, $index, $length, $result);

    # handle options
    $lines = shift(@_);
    %option = validate(@_, \%string_table_options) if @_;
    $option{align} ||= [];
    $option{colsep} = " | "
        unless defined($option{colsep});
    $option{headsep} = $option{markdown} ? "-" : "="
        unless defined($option{headsep});
    $option{indent} = ""
        unless defined($option{indent});
    if ($option{markdown}) {
        $option{lsep} = $option{rsep} = $option{colsep};
        $option{lsep} =~ s/^\s+//;
        $option{rsep} =~ s/\s+$//;
    } else {
        $option{lsep} = "";
        $option{rsep} = "";
    }
    # compute column lengths
    foreach my $line ($option{header} ? ($option{header}) : (), @{ $lines }) {
        $index = 0;
        foreach my $entry (@{ $line }) {
            $length = _strlen($entry);
            $collen[$index] = $length
                unless defined($collen[$index]) and $collen[$index] >= $length;
            $index++;
        }
    }
    # compute total length
    $length = length($option{lsep}) + length($option{rsep});
    $length += length($option{colsep}) * (@collen - 1);
    foreach my $collen (@collen) {
        $length += $collen;
    }
    $option{collen} = \@collen;
    $result = "";
    # format header
    if ($option{header}) {
        $result .= _tblfmt($option{header}, \%option);
        if (length($option{headsep})) {
            if ($option{markdown}) {
                @headsep = map(_strgen($option{headsep}, $_), @collen);
                $result .= _tblfmt(\@headsep, \%option);
            } else {
                $result .= $option{indent};
                $result .= _strgen($option{headsep}, $length) . "\n";
            }
        }
    }
    # format lines
    foreach my $line (@{ $lines }) {
        $result .= _tblfmt($line, \%option);
    }
    return($result);
}

#
# remove leading and trailing spaces
#

sub string_trim ($) {
    my($string) = @_;

    validate_pos(@_, { type => SCALAR });
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return($string);
}

#
# module initialization
#

@_ByteSuffix = qw(B kB MB GB TB PB EB ZB YB);
foreach my $ord (0 .. 255) {
    $_Map[$ord] = 32 <= $ord && $ord < 127 ?
        chr($ord) : sprintf("\\x%02x", $ord);
}
$_Map[ord("\t")] = "\\t";
$_Map[ord("\n")] = "\\n";
$_Map[ord("\r")] = "\\r";
$_Map[ord("\e")] = "\\e";
$_Map[ord("\\")] = "\\\\";
%_Plural = (
    "child" => "children",
    "data"  => "data",
    "foot"  => "feet",
    "index" => "indices",
    "man"   => "men",
    "tooth" => "teeth",
    "woman" => "women",
);

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, map("string_$_",
        qw(bytefmt escape plural quantify table trim)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::String - string handling without worries

=head1 SYNOPSIS

  use No::Worries::String qw(*);

  # format a number of bytes
  printf("%s has %s\n", $path, string_bytefmt(-s $path));

  # escape a string
  printf("found %s\n", string_escape($data));

  # produce a nice output (e.g "1 file" or "3 files")
  printf("found %s\n", string_quantify($count, "file"));

  # format a table
  print(string_table([
      [1, 1,  1],
      [2, 4,  8],
      [3, 9, 27],
  ], header => [qw(x x^2 x^3)]));

  # trim a string
  $string = string_trim($input);

=head1 DESCRIPTION

This module eases string handling by providing convenient string manipulation
functions.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item string_bytefmt(NUMBER[, PRECISION])

return the given NUMBER formatted as a number of bytes with a suffix such as
C<kB> or C<GB>; the default precision (i.e. number of digits after the decimal
dot) is 2

=item string_escape(STRING)

return a new string with all potentially non-printable characters escaped;
this includes ASCII control characters, non-7bit ASCII and Unicode characters

=item string_plural(STRING)

assuming that STRING is an English noun, returns its plural form

=item string_quantify(NUMBER, STRING)

assuming that STRING is an English noun, returns a string saying how much of
it there is; e.g. C<string_quantify(2, "foot")> is C<"2 feet">

=item string_table(TABLE[, OPTIONS])

transform the given table (a reference to an array of arrays of strings) into
a formatted multi-line string; supported options:

=over

=item * C<align>: array reference of alignment directions (default: "left");
possible values are "left", "center" and "right"

=item * C<colsep>: column separator string (default: " | ")

=item * C<header>: array reference of column headers (default: none)

=item * C<headsep>: header separator (default: "=" or "-" for MarkDown)

=item * C<indent>: string to prepend to each line (default: "")

=item * C<markdown>: return a MarkDown compatible table

=back

=item string_trim(STRING)

return a new string with leading and trailing spaces removed

=back

=head1 SEE ALSO

L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
