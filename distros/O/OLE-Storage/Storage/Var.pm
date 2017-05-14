#
# $Id: Var.pm,v 1.1.1.1 1998/02/25 21:13:00 schwartz Exp $
#
# OLE::Storage::Var
#
# Property variable handling.
#
# Copyright (C) 1996, 1997, 1998 Martin Schwartz 
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#
# Contact: schwartz@cs.tu-berlin.de
#

package OLE::Storage::Var;
use strict;
my $VERSION=do{my@R=('$Revision: 1.1.1.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

use OLE::Storage::Std;
use OLE::Storage::Handler();
use OLE::Storage::Property();
use Unicode::Map();

my $uncool_debug = 0;

##
## --- Public --------------------------------------------------------------
##

sub new {
#
# $Var = new Var;
#
   bless ({}, ref($_[0]) || $_[0])
      -> _init_handling()
   ;
}

sub cs_from  { my $S=shift; $S->{CS_FROM}=shift if @_; $S->{CS_FROM} }
sub map      { my $S=shift; $S->{MAP}=shift if @_; $S->{MAP} }
sub handler  { my $S=shift; $S->{H}=shift if @_; $S->{H} }
sub property { OLE::Storage::Property->new(@_) }


##
## --- Private -------------------------------------------------------------
##

sub error { 
   my ($Var, $str) = @_;
   OLE::Storage::Property->new($Var, \$str, 0, "myerror") 
}


#
# --- Interface to OLE::Storage::Property ------------------------------------
#

sub _IS_SCALAR { !(($_[1] || 0) &  0x1000) }
sub _IS_ARRAY  {   ($_[1] || 0) &  0x1000  }
sub _IS_VARRAY {   ($_[1] || 0) == 0x100c  }
sub _TO_SCALAR {   ($_[1] || 0) &  0xfff   }
sub _TO_ARRAY  {   ($_[1] || 0) |  0x1000  }
sub _TO_VARRAY {                   0x100c  }

sub _STORE {
   my ($S, $bufR, $oR, $from) = @_;
   $S->handler()->convert($from, "store", $bufR, $oR)
   || $uncool_debug && 
      (printf "Error: o=%x, type=%x, buf=".("%08x "x5)."...\n", 
         $$oR, $from, get_nlong(5, $bufR, $$oR)
      )
   || "";
}

sub _RETRIEVE {
   my ($S, $from_ext, $to, $bufR) = @_;
   if (ref($bufR)) {
      $S->handler()->convert([$from_ext, $bufR->[0]], $to, $bufR->[1]);
   }
}

sub _TYPESTR {
   shift->handler()->typestr(shift());
}

#
# --- Init -----------------------------------------------------------------
#

sub _init_handling {
#
# This installs all the methods used to convert properties of type1 to
# variables or properties of type2 (type1 is allowed to equal type2).
# This module stores all variables together with an extra type information, 
# that is strictly private and must not be interesting to other modules.
# The idea is to store variables internally in some few standard 
# representations, like strings, integers or floats.
#
# You see immediately, that this concept is quite slow: as any e.g. integer
# $number will be stored as a data structure: ["int", $number] or any string
# $text would be stored as: ["string", \$text]. (s.b.)
#
   my $S = shift;
   my $H = $S->handler(OLE::Storage::Handler->new);

   $S->map(
      new Unicode::Map ({ 
         ID => ( $ENV{LC_CTYPE} || "CP1252" ) 
      })
   );
   return 0 if !$S->map;

   $H->add (0x00, "empty",	"store",  \&_0x00_store);
   $H->add (0x01, "null",	"store",  \&_0x01_store);
   $H->add (0x02, "i2",		"store",  \&_0x02_store);
   $H->add (0x03, "i4",		"store",  \&_0x03_store);
   $H->add (0x04, "r4",		"store",  \&_0x04_store);
   $H->add (0x05, "r8",		"store",  \&_0x05_store);
   $H->add (0x06, "cy",		"store",  \&_0x06_store);
   $H->add (0x07, "date",	"store",  \&_0x05_store); 
   $H->add (0x08, "bstr");
   $H->add (0x0a, "error",	"store",  \&_0x0a_store);
   $H->add (0x0b, "bool",	"store",  \&_0x0b_store);
   $H->add (0x0c, "variant");   # does exist only as array!
   $H->add (0x11, "ui1",	"store",  \&_0x11_store);
   $H->add (0x12, "ui2",	"store",  \&_0x12_store);
   $H->add (0x13, "ui4",	"store",  \&_0x13_store);
   $H->add (0x14, "i8");
   $H->add (0x15, "ui8");
   $H->add (0x1e, "lpstr",	"store",  \&_0x1e_store);
   $H->add (0x1f, "lpwstr",	"store",  \&_0x1f_store);
   $H->add (0x40, "filetime",	"store",  \&_0x40_store);
   $H->add (0x41, "blob",       "store",  \&_0x41_store);
   $H->add (0x42, "stream");
   $H->add (0x43, "storage");
   $H->add (0x44, "streamed_object");
   $H->add (0x45, "stored_object");
   $H->add (0x46, "blobobject");
   $H->add (0x47, "cf");
   $H->add (0x48, "clsid",	"store",  \&_0x48_store);

   #
   # Normal procedure to store will be to create some variable like a string
   # or a buffer and to pass a reference of this to the following handling 
   # functions. These would take the reference, pass it further and store it 
   # finally. But sometimes it should be clever to pass not references, as e.g. 
   # for integers. The internal types listed below are followed by a dot for 
   # pure data and by an "R" for reference data. (provisorically...)
   #
   $S->_init_bool();	# .
   $S->_init_buf();	# R
   $S->_init_date();	# R
   $S->_init_int();	# .
   $S->_init_string();	# R
   $S->_init_float();	# .
   $S->_init_guid();	# R
   $S->_init_wstring();	# R
   $S->_init_myerror();	# R

   $H->add ("zstr", "zstr",     "store",  \&_zstr_store);
   $H->add ("zwstr", "zwstr",   "store",  \&_zwstr_store);
   
   $S;
}

#
# --- Store ----------------------------------------------------------------
#

sub _0x00_store {	# 0x00 == empty
   ["string", \""]
}
sub _0x01_store {	# 0x01 == null
   ["int", 0]
}
sub _0x02_store {	# 0x02 == i2
   my $int = &get_word;
   $int = - (($int^0xffff) +1) if ($int & 0x8000);
   ["int", $int];
}
sub _0x03_store {	# 0x03 == i4
   my $int = &get_long;
   $int = - (($int^0xffffffff) +1) if ($int & 0x80000000);
   ["int", $int];
}
sub _0x04_store {	# 0x04 == r4
   ["float", &get_real]
}
sub _0x05_store {	# 0x05 == r8
   ["float", &get_double]
}
sub _0x06_store {	# 0x06 == cy
   [0x06, ""];
}
sub _0x0a_store {	# 0x0a == error
   ["int", &get_long];
}
sub _0x0b_store {	# 0x0b == bool
   ["bool", &get_long];
}
sub _0x11_store {	# 0x11 == ui1
   ["int", &get_byte];
}
sub _0x12_store {	# 0x12 == ui2
   ["int", &get_word];
}
sub _0x13_store {	# 0x13 == ui4
   ["int", &get_long];
}
sub _0x1e_store {	# 0x1e == lpstr
   my ($bufR, $oR) = @_;
   ["string", \get_zstr($bufR, $oR, &get_long)];
}
sub _0x1f_store {	# 0x1f == lpwstr
   my ($bufR, $oR) = @_;
   ["wstring", \get_rzwstr($bufR, $oR, &get_long)];
}
sub _0x40_store {
   ["date", &_filetime_to_date];
}
sub _0x41_store {
   my ($bufR, $oR) = @_;
   ["buf", \get_str($bufR, $oR, &get_long)];
}
sub _0x48_store {
   ["guid", [get_struct("LWWBBBBBBBB", @_)] ];
}

sub _zstr_store {
   my ($bufR, $oR) = @_;
   ["string", \get_zstr($bufR, $oR, length($$bufR))];
}
sub _zwstr_store {
   my ($bufR, $oR) = @_;
   ["wstring", \get_rzwstr($bufR, $oR, length($$bufR))];
}

#
# --- bool -----------------------------------------------------------------
#

sub _init_bool {
   my $H = shift()->handler();
   $H->add (["bool", "bool", 
      "store",   \&_bool_store,   "",			# Y
      "bool",    \&_bool_bool,    "",			# Y
      "buf",     \&_bool_buf,     "",			# .
      "date",    \&_bool_date,    "",			# .
      "int",     \&_bool_int,     "",			# Y
      "float",   \&_bool_float,   "",			# Y
      "guid",    \&_bool_guid,    "",			# .
      "string",  \&_bool_string,  ["Yes", "No"],	# Y
      "wstring", \&_bool_wstring, [nwstr("Yes", "No")],	# Y
   ]);
}
sub _bool_store   { ["bool", shift()] }
sub _bool_bool    { shift() }
sub _bool_buf     { undef }
sub _bool_date    { undef }
sub _bool_int     { shift() ? -1 : 0 }
sub _bool_float   { shift() ? -1.0 : 0.0 }
sub _bool_guid    { undef }
sub _bool_string  { my ($val, $x, $par) = @_; $val ? $par->[0] : $par->[1] }
sub _bool_wstring { my ($val, $x, $par) = @_; $val ? $par->[0] : $par->[1] }

#
# --- buf ------------------------------------------------------------------
#

sub _init_buf {
   my $H = shift->handler();
   $H->add (["buf", "buf", 
      "store",   \&buf_store,    "",	# Y
      "bool",    \&_buf_bool,    "",	# .
      "buf",     \&_buf_buf,     "",	# Y
      "date",    \&_buf_date,    "",	# .
      "int",     \&_buf_int,     "",	# .
      "float",   \&_buf_float,   "",	# .
      "guid",    \&_buf_guid,    "",	# .
      "string",  \&_buf_string,  "",	# .
      "wstring", \&_buf_wstring, "",	# .
   ]);
}
sub _buf_store   { ["buf", shift()] }
sub _buf_bool    { undef }
sub _buf_buf     { my $valR = shift; $$valR }
sub _buf_date    { undef }
sub _buf_int     { undef }
sub _buf_float   { undef }
sub _buf_guid    { undef }
sub _buf_string  { undef }
sub _buf_wstring { undef }

#
# --- date -----------------------------------------------------------------
#

sub _init_date {
   my $H = shift->handler();
   $H->add (["date", "date", 
      "store",  \&_date_store, "",	# Y
      "bool",   \&_date_bool,  "",	# .
      "buf",    \&_date_buf,   "",	# .
      "date",   \&_date_date,  "",	# Y
      "int",    \&_date_int,   "",	# Y
      "float",  \&_date_float, "",	# Y
      "guid",   \&_date_guid,  "",	# .
      "string", \&_date_string, 	# Y
         ["%02d.%02d.%04d, %02d:%02d:%02d", "%02d:%02d:%02d", "<undef>"],
      "wstring",   \&_date_wstring, 	# Y
         ["%02d.%02d.%04d, %02d:%02d:%02d", "%02d:%02d:%02d", "<undef>"],
   ]);
}
sub _date_store  { ["date", shift()] }
sub _date_bool   { undef }
sub _date_buf    { undef }
sub _date_date   { my $valR = shift; @$valR }
sub _date_int    { int(_date_float(@_)) }
sub _date_float  { 
   my $valR = shift;
   my ($d, $h) = _date_to_filetime(@$valR);
   $d*2**6+$h/2**26;
}
sub _date_guid   { undef }
sub _date_string {
#
# $datestr = _date_string(
#    \$buf, \$o, 
#    [] || [$da, $mo, $ye, $ho, $mi, $se],
#    [$date_and_time_mask, $time_mask, $undefined_mask]
# );
#
   my ($valR, $oR, $par) = @_;
   return $par->[2] if !@$valR;
   my ($da, $mo, $ye, $ho, $mi, $se) = @$valR;
   if ($ye) {
      sprintf ($par->[0], $da, $mo, $ye, $ho, $mi, $se);
   } else {
      sprintf ($par->[1], $ho, $mi, $se);
   }
}
sub _date_wstring { _string_wstring (\_date_string(@_), 0, "%s") }

#
# --- int ------------------------------------------------------------------
#

sub _init_int {
   my $H = shift->handler();
   $H->add (["int", "int", 
      "store",   \&_int_store,   "",
      "bool",    \&_int_bool,    "",	# Y
      "buf",     \&_int_buf,     "",	# .
      "date",    \&_int_date,    "",	# Y
      "int",     \&_int_int,     "",	# Y
      "float",   \&_int_float,   "",	# Y
      "guid",    \&_int_guid,    "",	# .
      "string",  \&_int_string,  "%d",	# Y
      "wstring", \&_int_wstring, "%d", 	# Y
   ]);
}
sub _int_store   { ["int", shift()] }
sub _int_bool    { shift() ? 1 : 0 }
sub _int_buf     { undef }
sub _int_date    { _float_date(@_) }
sub _int_int     { shift() }
sub _int_float   { shift() + 0.0 }
sub _int_guid    { undef }
sub _int_string  { my ($val, $x, $par) = @_; sprintf $par, $val }
sub _int_wstring { _string_wstring (\_int_string(@_), 0, "%s") }

#
# --- float ----------------------------------------------------------------
#

sub _init_float {
   my $H = shift->handler();
   $H->add (["float", "float", 
      "store",   \&_float_store,   "",
      "bool",    \&_float_bool,    "",		# Y
      "buf",     \&_float_buf,     "",		# .
      "date",    \&_float_date,    "",		# Y
      "int",     \&_float_int,     "",		# Y
      "float",   \&_float_float,   "",		# Y
      "guid",    \&_float_guid,    "",		# .
      "string",  \&_float_string,  "%.2f",	# Y
      "wstring", \&_float_wstring, "%.2f", 	# Y
   ]);
}
sub _float_store  { ["float", shift()] }
sub _float_bool   { shift() ? 1 : 0 }
sub _float_buf    { undef }
sub _float_date   { 
   my $val = shift;
   _filetime_to_date(\nlong([$val*2**26, $val/2**6]));
}
sub _float_int     { int(shift()) }
sub _float_float   { shift() }
sub _float_guid    { undef }
sub _float_string  { my ($val, $oR, $par) = @_; sprintf $par, $val }
sub _float_wstring { _string_wstring (\_float_string(@_), 0, "%s") }

#
# --- guid -----------------------------------------------------------------
#

sub _init_guid {
   my $H = shift->handler();
   $H->add (["guid", "guid",
      "store",   \&_guid_store,   "",				# Y
      "bool",    \&_guid_bool,    "",				# .
      "buf",     \&_guid_buf,     "",				# .
      "date",    \&_guid_date,    "",				# .
      "int",     \&_guid_int,     "",				# .
      "float",   \&_guid_float,   "",				# .
      "guid",    \&_guid_guid,    "",				# Y
      "string",  \&_guid_string,  "%08X-%04X-%04X-%02X%02X-".("%02X"x6), # Y
      "wstring", \&_guid_wstring, "%08X-%04X-%04X-%02X%02X-".("%02X"x6), # Y
   ]);
}
sub _guid_store   { ["guid", shift()] }
sub _guid_bool    { undef }
sub _guid_buf     { undef }
sub _guid_date    { undef }
sub _guid_int     { undef }
sub _guid_float   { undef }
sub _guid_guid    { my $valR = shift; $$valR }
sub _guid_string  { my ($valR, $x, $par) = @_; sprintf $par, @$valR }
sub _guid_wstring { _string_wstring (\_guid_string(@_), 0, "%s") }

#
# CLSIDs:
#
#    00020810-0000-0000-C000-000000000046 	Excel.Sheet.5
#    00020900-0000-0000-C000-000000000046	Word.Document.6
#    00020901-0000-0000-C000-000000000046	Word.Picture.6
#    00020906-0000-0000-C000-000000000046	Word.Document.8
#    00021A11-0000-0000-C000-000000000046       Visio
#


#
# --- string ---------------------------------------------------------------
#

sub _init_string {
   my $S = shift;
   my $H = $S->handler();
   $H->add (["string", "string", 
      "store",   \&_string_store,   "",
      "bool",    \&_string_bool,    "",		# .
      "buf",     \&_string_buf,     "",		# .
      "date",    \&_string_date,    "",		# .
      "int",     \&_string_int,     "",		# .
      "float",   \&_string_float,   "",		# .
      "guid",    \&_string_guid,    "",		# .
      "string",  \&_string_string,  "",		# Y
      "wstring", \&_string_wstring, $S->map	# Y
   ]);
}
sub _string_store   { ["string", shift()] }
sub _string_bool    { undef }
sub _string_buf     { undef }
sub _string_date    { undef }
sub _string_int     { undef }
sub _string_float   { undef }
sub _string_guid    { undef }
sub _string_string  { ${$_[0]} }
sub _string_wstring { $_[2]->to_unicode($_[0]) }

#
# --- wstring -----------------------------------------------------------------
#

sub _init_wstring {
   my $S = shift;
   my $H = $S->handler();
   $H->add (["wstring", "wstring",
      "store",   \&_wstring_store,   "",	# Y
      "bool",    \&_wstring_bool,    "",	# .
      "buf",     \&_wstring_buf,     "",	# .
      "date",    \&_wstring_date,    "",	# .
      "int",     \&_wstring_int,     "",	# .
      "float",   \&_wstring_float,   "",	# .
      "guid",    \&_wstring_guid,    "",	# .
      "wstring", \&_wstring_wstring, "",	# Y
      "string",  \&_wstring_string,  $S->map	# Y
   ]);
}
sub _wstring_store  { ["wstring", shift()] }
sub _wstring_bool   { undef }
sub _wstring_buf    { undef }
sub _wstring_date   { undef }
sub _wstring_int    { undef }
sub _wstring_float  { undef }
sub _wstring_guid   { undef }
sub _wstring_string { $_[2]->from_unicode($_[0]) }
sub _wstring_wstring { ${$_[0]} }

#
# --- myerror --------------------------------------------------------------
#
# I'm thinking about not installing an error handling for properties.
# Anyway, meanwhile...
#

sub _init_myerror {
   my $H = shift->handler();
   $H->add (["myerror", "myerror", 
      "store",   \&_myerror_store,   "",
      "bool",    \&_myerror_bool,    "",
      "buf",     \&_myerror_buf,     "",
      "date",    \&_myerror_date,    "",
      "int",     \&_myerror_int,     "",
      "float",   \&_myerror_float,   "",
      "guid",    \&_myerror_guid,    "",
      "string",  \&_myerror_string,  "",
      "wstring", \&_myerror_wstring, "",
      "myerror", \&_myerror_myerror, "%s", 
   ]);
}
sub _myerror_store   { ["myerror", shift()] }
sub _myerror_bool    { undef }
sub _myerror_buf     { undef }
sub _myerror_date    { undef }
sub _myerror_int     { undef }
sub _myerror_float   { undef }
sub _myerror_guid    { undef }
sub _myerror_string  { "" }
sub _myerror_wstring { "" }
sub _myerror_myerror { &_string_string }

#
# -- FILETIME --------------------------------------------------------------
#

# filetime is a 64 bit ulong. It counts every second 10 * 10 ^ 6, 
# starting at 01/01/1601. When the 64 bit int gets evaluated as
# two 32 bit integers, the faster running ("least significant long")
# can hold just 0x100000000 / 10000000.0 (about 429.5) seconds. So the 
# slower running ("most significant long") increments every 429.5 seconds.

my @monsum = ( 
   [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
   [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
);
my $a_minute = 60 * 10000000.0 / (0x10000000 * 16);

sub _filetime_to_date {
   my ($ds, $dd) = get_nlong(2, @_);
   return [] if (!$ds) && (!$dd);

   my ($day, $month, $year, $hour, $min, $sec);
   my ($i, $m, $d, $dsum, $tmpsec);

   $dsum = $dd + ($ds / (0x10000000 * 16.0));

   $d= int( $dsum/($a_minute*60*24) )+1;
   $m= $dsum - ($d-1)*$a_minute*60*24;

   $year  = int( $d/365.2425 ) + 1601;
   my $switch = _is_schaltjahr($year);

   $d -= _years_to_days ($year, 1601);
   for( $i=11; $i && ($d <= _days($switch, $i+1)); $i--) {}
   $month = $i+1; 
   $day   = $d - _days($switch, $i+1);

   $hour  = int ( $m / ($a_minute*60) ); 
   $min   = int ( $m/$a_minute - $hour*60 );
   $sec   =     ( ($m/$a_minute - $hour*60 - $min) * 60);

   $year -= 1601 if $year == 1601;
   [$day, $month, $year, $hour, $min, $sec];
}

sub _date_to_filetime {
   my ($day, $month, $year, $hour, $min, $sec) = @_;
   my ($d, $tss, $tsd);
   my $switch = _is_schaltjahr($year);

   $d = _years_to_days($year, 1601) + _days($switch, $month) + $day-1; 
   $tsd = (24*60*$d + 60*$hour +$min +$sec/60.0) * $a_minute;
   $tss = ($tsd-int($tsd)) * 0x10000000 * 16;

   ( int($tsd), int($tss) );
}

sub _is_schaltjahr {
   my $year = shift;
   !($year%4) && ($year%100 || !($year%400) ) && 1 || 0;
}

sub _years_to_days {
   my ($year, $baseyear) = @_;
   int($year-$baseyear) * 365 
     + int( ($year-$baseyear) / 4 )
     - int( ($year-$baseyear) / 100 )
     + int( ($year-$baseyear) / 400 )
   ;
}

sub _days {
   $monsum[shift]->[-1+shift]
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Var - Variable handling for properties

$Revision: 1.1.1.1 $ $Date: 1998/02/25 21:13:00 $

=head1 SYNOPSIS

use OLE::Storage::Var;

I<$Var> = new Var;

I<$Property> = I<$Var> -> property (I<\$buf>, I<$o>||I<\$o> [,I<$type>])

I<$Handler> = I<$Var> -> handler ()

=head1 DESCRIPTION

This package is governing the two packages OLE::Storage::Property and
OLE::Storage::Handler. It manages the binary data of properties.
OLE::Storage::Property uses methods of $Var to store and convert properties.
OLE::Storage::Var will probably be changed very much in close future. So
what a luck, that:

Normally the only thing you will have to do with this package is
to create an instance either via package OLE::Storage with
"$Var = OLE::Storage->NewVar", or with same method of package
OLE::PropertySet. This $Var you need to pass to OLE::Storage->open 
calls.

I<Note>: If you should to have to create new properties by your own,
do it always via this $Var interface. 

=head1 SEE ALSO

L<OLE::Storage::Property>, L<OLE::Storage::Handler>, demonstration program "lls"

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut

