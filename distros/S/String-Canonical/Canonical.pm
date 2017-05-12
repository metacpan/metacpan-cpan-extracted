#!/usr/bin/perl

=head1 NAME

String::Canonical - Creates canonical strings.

=head1 SYNOPSIS

 use String::Canonical qw/cstr/;
 print cstr("one thousand maniacs");

 print String::Canonical::get("Second tier");

=head1 DESCRIPTION

This module generates a canonical string by converting roman numerals to digits, English descriptions of numbers to digits, stripping off all accents on characters (as well as handling oe = ö, ae = æ, etc.), replacing words with symbols (e.g. and = &, plus = +, etc.) and removing common variant endings.

In short, this module generates the same signature for the following
strings:

    bjørk = björk = bjoerk = bjork
    1,000 maniacs = one thousand maniacs = 1k maniacs
    Boyz II Men = Boyz To Men = Boyz 2 Men
    ACDC = AC/DC = AC-DC
    Rubin and company = Rubin & Company = Rubin & Co.
    Third Eye Blind = 3rd eye blind
    Train runnin' = Train Running

=cut

# --- prologue ----------------------------------------------------------------

package String::Canonical;

require 5.000;

use warnings;
use strict;
use Exporter;

use Lingua::EN::Numericalize;	# interpret English
use Text::Roman qw/roman2int/;	# interpret Roman numbers

use vars qw/$VERSION @ISA @EXPORT_OK/;
$VERSION    = substr q$Revision: 1.2 $, 10;
@ISA        = qw/Exporter/;
@EXPORT_OK  = qw/&cstr &cstr_cmp/;

my @dx;     # deletions
my %yx;     # transliterations
my %sx;     # replacements

# --- module interface --------------------------------------------------------

=head1 INTERFACE

The following functions may be imported into the caller package by name:

=head2 cstr/get [string = $_]

Returns the canonical form of the string passed.  If no string is passed, $_ is used.  When called in void context the function will set $_.  The functon may also be accessed as B<get> but only B<cstr> may be exported.

=cut

sub get { &cstr; }

sub cstr {
	my $s = lc(shift || $_) || return;
    local $_ if defined wantarray();

	$s =~ s/\Q$_\E/$sx{$_}/gi for keys %sx;
	eval "\$s =~ y/$_/$yx{$_}/" for keys %yx;
	$s =~ s/\Q$_\E//g for @dx;

    ($_, $s) = (str2nbr($s), "");
	$s .= roman2int() || $_ for split;

	$s =~ s/[_\W]//g;
    $_ = $s;
	}

=head2 cstr_cmp/cmp <string> [string = $_]

Compares two strings.  Note that if the second string is not provided, $_ is used.

=cut

sub cmp { &cstr_cmp; }

sub cstr_cmp {
    my $s1 = shift;
    my $s2 = shift || $_;

    cstr($s1) eq cstr($s2);
    }

# --- internal structures -----------------------------------------------------

@dx = qw/the da/;

%sx = (
	"company" => "co",
	"brother" => "bro",
	"to"	  => 2,
	"for"	  => 4,
	"mister"  => "mr",
	"senior"  => "sr",
	"o'"	  => "of",
	"ol'"	  => "old",
    "in'"     => "ing",
	"oe"	  => "o",
	"ae"	  => "a",
	"@"		  => "at",
	"&"	  	  => "and",
    "'n"      => "and",
    " n'"     => "and",
    "'n'"     => "and",
	"#"		  => "no",
	"nbr"	  => "no",
	"number"  => "no",
	"%"		  => "pct",
	"percent" => "pct",
    "volume"  => "vol",
	"ß"		  => "ss",
    "+"       => "plus",
	);

%yx = (
	"äÄàÀáÁåÅâÂãÃ"	=> "a",
	"ëËèÈéÉêÊ"	  	=> "e",
	"ïÏìÌíÍîÎ"		=> "i",
	"öÖòÒóÓôÔõÕ"	=> "o",
	"üÜùÙúÚûÛ"		=> "u",
	"æÆøØçÇñÑðÐþÞýÝÿÿ"
		=> "aaooccnnddddyyyy",
	);

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 SUPPORT

For help and thank you notes, e-mail the author directly.  To report a bug, submit a patch or add to our wishlist please visit the CPAN bug manager at: F<http://rt.cpan.org>

=head1 AVAILABILITY

The latest version of the tarball, RPM and SRPM may always be found at: F<http://perl.arix.com/>  Additionally the module is available from CPAN.

=head1 LICENCE AND COPYRIGHT

This utility is free and distributed under GPL, the Gnu Public License.  A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.gnu.org/licenses/> to obtain a copy of this license.

$Id: Canonical.pm,v 1.2 2003/02/15 01:44:39 ekkis Exp $

=cut
