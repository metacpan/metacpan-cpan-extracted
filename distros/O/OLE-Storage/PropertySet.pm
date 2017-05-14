#
# $Id: PropertySet.pm,v 1.1.1.1 1998/02/25 21:13:00 schwartz Exp $
#
# OLE::PropertySet
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

package OLE::PropertySet;
use strict;
my $VERSION=do{my@R=('$Revision: 1.1.1.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

use OLE::Storage::Std;
use OLE::Storage::Var();

sub Startup  { my $S=shift; $S->{STARTUP} = shift if @_; $S->{STARTUP} }
sub Var      { my $S=shift; $S->{VAR}   = shift if @_; $S->{VAR} }
sub NewVar   { OLE::Storage::Var::new   qw(OLE::Storage::Var) }

# package globals
my %PPSET;

sub dictionary { ##
#
# 1||0 = dictionary(\%dictionary [,$nodefault]);
#
   my ($S, $dictR, $forbid) = @_;
   $S->_load_dictionary($forbid);
   %$dictR = %{$S->{DICT}};
1}

sub exists {
   my ($S, $id) = @_;
   defined $S->_prop($id);
}

sub idset { ##
#
# 1||0 = idset(\%ppset_idset [,$nodefault]);
#
   my ($S, $idsetR, $forbid) = @_;
   $S->_load_dictionary($forbid);
   %{$idsetR}=();
   for (keys %{$S->_prop}) {
      $idsetR->{$_} = $S->{DICT}{$_};
   }
1}

sub idstr {
#
# $str||undef = idstr($id [,$nodefault])
#
   my ($S, $id, $forbid) = @_;
   $S->_load_dictionary($forbid);
   $S->{DICT}{$id};
}

sub load {
#
# $self||0 = 1. load ($Startup, $Var, $pps, $Doc [,$filter])
# 	   = 2. load ($Startup, $Var, $name, \$buf [,$filter])
#
   my ($proto, $Startup, $Var, $pps, $Doc, $filter) = @_;
   my $class = ref($proto) || $proto;

   my $name;
   my $Scalar = (ref($Doc) =~ /SCALAR/);
   if ($Scalar) {
      $name = $pps; 
   } else {
      $name = $Doc->name($pps)->string;
   }

   my $S = _init($Startup, $Var, $name, _type($name), $filter);
   bless ($S, $class);

   return $S->_error("This is not a PropertySet handle.") if !$S->{TYPE};

   if ($Scalar) {
      my $bufR = $Doc;
      $S->{BUF} = $$bufR;
   } else {
      $S->{PPS}  = $pps;
      $S->{DOC}	 = $Doc;
      return 0 if !$Doc->read($pps, \$S->{BUF});
   }

   $S->_load() && $S;
}

sub property {
#
# 1. $Property = property($id)
# 2. @Properties = property($id1 [,$id2...])
#
# If an error occurs, an internal error $Property is returned.
#
   my $S = shift;
   if (!@_) {
      return $S->_var()->error("No property id given.");
   } elsif (!wantarray) {
      return $S->_property(shift());
   } else {
      map ($S->_property($_), @_);
   }
}

sub type { 
#
# type || 0 = 			type e {1, 0x10}
#    1. type ($Doc, $pps)
#    2. type ($name)
#
   my ($Quatsch, $Doc, $pps) = @_;
   if (defined $pps) {
      # case 1
      return 0 if ! $Doc->is_file($pps);
      return _type($Doc->name($pps)->string());
   } else {
      # case 2
      my $name = $Doc;
      return _type($name);
   }
}

#
# --------------------------- private ------------------------------
#

sub _error { my $S = shift; $S->{STARTUP}->error(@_) if defined $S->{STARTUP} }

sub _filter {
   shift->{FILTER};
}

sub _init {
#
# $self||0 = _init ($Startup, $Var, $name, $type [,$filter])
#
   my ($Startup, $Var, $name, $type, $filter) = @_;
   {
      STARTUP	=> $Startup,		# Startup object
      VAR       => $Var,		# Var object
      FILTER	=> $filter,		# property filter method
    # aggregated data
      PROP	=> {},			# Property {id}
      DICT_LOAD => undef,
      DICT_PROP	=> {},			# Dictionary of property {id}
      DICT_DEF	=> {},			# Default dictionary property {id}
      DICT	=> {},			# DICT_PROP || DICT_PROP+DICT_DEF
      HEADER	=> {},			# Header data.
    # IO
      NAME      => $name,		# name of propertyset
      TYPE      => $type,		# type of PropertySet
      BUF	=> undef,		# Buffer for PropertySet stream.
      DOC	=> undef,		# Laola document object
      PPS	=> undef,		# Property storage handle
   };
}

sub _load {
#
# 1||0 = _load();
#
   my $S = shift;
   if ($S->{TYPE} == 1) {
      $S->_load_ppset_05();
   } elsif ($S->{TYPE} == 0x10) {
      $S->_load_ppset_CompObj();
   } else {
      $S->_error("Unknown property set type!");
   }
}

sub _load_dictionary {
   my ($S, $forbid) = @_;

   $forbid = 0 if ! defined $forbid;
   return if defined $S->{DICT_LOAD} && ($S->{DICT_LOAD} == $forbid);

   if (!$forbid && $PPSET{$S->{NAME}}) {
      $S->{DICT} = $PPSET{$S->{NAME}}->{DICT};
   }
   my ($k, $v);
   while (($k, $v) = each %{$S->{DICT_PROP}} ) {
      $S->{DICT}{$k} = $v;
   }
   $S->{DICT_LOAD} = $forbid;
}

sub _property {
#
#  $Property || $ErrorProperty = _property($id)
# 
   my ($S, $id) = @_;
   return $S->_var()->error("Property not available!") if !$S->exists($id);
   $S->_prop($id);
}

sub _type {
#!
   my $name = shift;
   return $PPSET{$name}->{TYPE} if $PPSET{$name};
   return 1 if $name =~ /^\05/;
0}

sub _var {
   shift->{VAR};
}
sub _prop {
   my ($S, $key, $val) = @_;
   $S->{PROP}{$key} = $val if defined $val;
   return $S->{PROP}{$key} if defined $key;
   $S->{PROP};
}

#
# ---------------- Flat stream data into system -------------------
#

sub _load_ppset_CompObj {
#
# true||0 = _load_ppset_CompObj ()
#
# Structure:
# 00: word    uk1        0x0001
# 02: word    byteorder  0xfffe
# 04: word    osver      lbyte=version  hbyte=revision
# 06: word    os         0=win16 1=mac 2=win32
# 08:                    ff ff ff ff  00 09 02 00  00 00 00 00 
#                        c0 00 00 00  00 00 00 46 
# 1c: word()  offsets
#
   my $S = shift;
   my $bufR = \$S->{BUF};
   my ($l, $n, $o, $var, $vl);

   my $H = {
      BYTEORDER   => get_word($bufR, 2),   
      OSVER       => get_word($bufR, 4),  
      OS          => get_word($bufR, 6), 
   };
   return $S->_error ("I don't understand the property set.")
      if ($H->{BYTEORDER} != 0xfffe) 
   ;
   $S->{HEADER} = $H;

   get_it: {
      $o = 0x1c;
      for (0,1,2) {
         $S->_prop($_, $S->_var->property($bufR, \$o, 0x1e));
      }
   }
1}

sub _load_ppset_05 {
#
# true||0 = _load_ppset_05 ()
#
# Structure:
# 00: word    byteorder  0xfffe
# 02: word    format     0
# 04: word    osver      lbyte=version  hbyte=revision
# 06: word    os         0=win16  1=mac  2=win32
# 08: clsid              class identifier {e.g. @0}
# 18: long    reserved   >=1
# 1c: fmtid              format identifier
# 2c: word    offset0    offset of first property chunk
#
   my $S = shift;
   my $bufR = \$S->{BUF};
   my ($did, $dname, $fido, $id, $l, $n, $num, $o, $type, @var, $vid, $vo);

   my $H = {
      BYTEORDER => get_word($bufR, 0x00), 
      FORMAT    => get_word($bufR, 0x02),
      OSVER     => get_word($bufR, 0x04),
      OS        => get_word($bufR, 0x06),
      CLSID     => $S->_var->property($bufR, 0x08, 0x48),
      RESERVED  => get_long($bufR, 0x18),
      FMTID     => $S->_var->property($bufR, 0x1c, 0x48),
      OFFSET    => [ get_word($bufR, 0x2c) ],
      CODEPAGE  => {},
      LOCALE	=> {},
   };

   return $S->_error("I don't understand the property set.") if
      ($H->{BYTEORDER} != 0xfffe) 
      || ($H->{FORMAT} != 0)
      || ($H->{RESERVED} < 1)
      || (${$H->{OFFSET}}[0] < 0x30)
   ;
 
   get_it: {
      $o = $H->{OFFSET}->[0];

      for ($n=0; $n < $H->{RESERVED}; $n++) {
         # default dictionary and codepage
         $H->{CODEPAGE}->{$n*0x1000+1} = 0x4e4;

         $num=get_word($bufR, $o+4);
         for (0 .. $num-1) {
            $id = get_long($bufR, $o+8+$_*8);
            if ($n) {
               $id = $_ if $id>1;
            }

            $fido = get_long($bufR, $o+8+$_*8+4);
            $vid = $n*0x1000 + $id;
            $vo = $H->{OFFSET}->[$n]+$fido;

            if ($id==0x80000000) {
               # locale
               $H->{LOCALE}->{$vid} = $S->_var->property($bufR, \$vo) 
                  -> int()
               ;
            } elsif ($id>1) {
               # read variable
               $S->_prop($vid, $S->_var->property($bufR, $vo));
            } elsif ($id==1) {
               $H->{CODEPAGE}->{$vid} = $S->_var->property($bufR, \$vo) 
                  -> int()
               ;
               #printf "Codepage %d\n", $H->{CODEPAGE}->{$vid};
            } elsif ($id==0) {
               # read dictionary
               for (1..get_long($bufR, \$vo)) {
                  $did = get_long($bufR, \$vo);
                  $S->{DICT_PROP}{$did+$n*0x1000} = 
                     $S->_var->property($bufR, \$vo, 0x1e) -> string()
                  ;
               }
            }
         }
         $o+=get_word($bufR, $o);
         $H->{OFFSET}->[$n+1]=$o;
      }
   }
   $S->{HEADER} = $H;
1}

##
## ---------------------------- Tie Support -------------------------------
##

sub TIEHASH {
#
# $PropertySet||0 = TIEHASH $classname, $Startup, $Var, $Doc, $pps [,$filter]
#
   goto &load;
}

sub CLEAR{0} 
sub DELETE{0} 
sub DESTROY{0}
sub STORE{0}

sub FETCH {
#
# FETCH this, key
#
   my $S = shift;
   if (my $filter = $S->_filter()) {
      $S -> property (@_) -> $filter();
   } else {
      $S -> property (@_);
   }
}

sub EXISTS {
   goto &exists;
}

sub FIRSTKEY {
   my $S = shift;
   keys %{$S->_prop};
   $S->NEXTKEY();
}

sub NEXTKEY {
#
# NEXTKEY this, lastkey
#
   scalar each %{$_[0]->_prop};
}

#
# -------------------------------- Defines --------------------------------
#

# global_definitions
$[=0;

# \05
%PPSET = (
   "\05SummaryInformation" => {
      TYPE => 1,
      NAME => "Summary Info",
      DICT => {
          2 => "Title",
          3 => "Subject",
          4 => "Authress",
          5 => "Keywords",
          6 => "Comments",
          7 => "Template",
          8 => "LastAuthress",
          9 => "Revision",
         10 => "EditTime",
         11 => "LastPrinted",
         12 => "Created",
         13 => "LastSaved",
         14 => "Pages",
         15 => "Words",
         16 => "Chars",
         17 => "Thumbnail",
         18 => "Application",
         19 => "Security"
      },
      GUID => [
          0xf29f85e0, 0x4ff9, 0x1068,
          "\0xab\0x91\0x08\0x00\0x2b\0x27\0xb3\0xd9"
      ]
   },
   "\05DocumentSummaryInformation" => {
      TYPE => 1,
      NAME => "Document Summary Info",
      DICT => {
          2 => "Category",
          3 => "PresentationTarget",
          4 => "Bytes",
          5 => "Lines",
          6 => "Paragraphs",
          7 => "Slides",
          8 => "Notes",
          9 => "HiddenSlides",
         10 => "MMClips",
         11 => "ScaleCrop",
         12 => "HeadingPairs",
         13 => "TitlesOfParts",
         14 => "Manager",
         15 => "Company",
         16 => "LinksUpToDate",
      },
      GUID => [
          0xd5cdd502, 0x2e9c, 0x101b, 
          "\0x93\0x97\0x08\0x00\0x2b\0x2c\0xf9\0xae"
      ],
      USERGUID => [
          0xd5cdd505, 0x2e9c, 0x101b,
          "\0x93\0x97\0x08\0x00\0x2b\0x2c\0xf9\0xae"
      ]
   },
   "\01CompObj" => {
      TYPE => 0x10,
      NAME => "Compound Object Info",
      DICT => {
          0 => "doc_long",
          1 => "doc_class",
          2 => "doc_spec"
      }
   }
);

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::PropertySet - Handles Property Sets

$Revision: 1.1.1.1 $ $Date: 1998/02/25 21:13:00 $

=head1 SYNOPSIS

 use OLE::Storage();
 use OLE::PropertySet();

 $Var = OLE::Storage -> NewVar;
 $Doc = OLE::Storage -> open ($Startup, $Var, "testfile.doc");

=over 4

=item direct mode

I<$PS> = OLE::PropertySet->load (I<$Startup>, I<$Var>, I<$pps>, I<$Doc>)

I<@list> = string { I<$PS> -> property (2, 5, 6) }

=item tie mode

I<$PS> = tie I<%PS>, OLE::PropertySet, I<$Startup>, I<$Var>, I<$pps>, I<$Doc>

I<@list> = string { I<$PS>{2}, I<$PS>{5}, I<$PS>{6} }

=back

=head1 DESCRIPTION

OLE::PropertySet gives read access to property sets. These are streams,
that e.g. are residing inside of Structured Storage documents. Because
property set technology is not limited to these documents borders, this
package was designed to connect easily to Structured Storage documents 
and to arbitrary property set streams.

To understand the use of this package, I recommend highly to study the tool 
"ldat".

=over 4

=item dictionary

C<1>||C<O> == I<$PS> -> dictionary (I<\%dict> [,C<1>])

Stores the dictionary of PropertySet I<$PS> in hash I<%dict>. The 
dictionary is a hash array having the property identifier numbers as
keys and the identifier names as values. By default the default dictionaries 
defined in OLE::PropertySet are also printed out. To leave them out, 
specify the optional parameter 1.

Normally you will not need this method, but use idset() instead.

=item idset

C<1>||C<O> == I<$PS> -> idset (I<\%idset> [,C<1>]);

Stores the idset of PropertySet I<$PS> in hash I<%idset>. The idset
is a hash array based on the really available property identifiers.
%idset has property identifier numbers as keys and the identifier
names according to the PropertySets dictionary as values. The optional
parameter spares out the default dictionary (see dictionary).

B<Note>: Some or all id names can be empty, if they cannot be figured 
out. Nevertheless the ids are valid.

=item idstr

I<$idstr>||C<undef> = I<$PS> -> idstr ($id [,C<1>])

Returns the property identifier string for property $id according to
the PropertySets dictionary. The optional parameter spares out the default
dictionary (see dictionary).

=item load

=over 4

=item I<$PS>||C<0> ==

1. load (I<$Startup>, I<$Var>, I<$pps>, I<$Doc> [,C<filter>])

2. load (I<$Startup>, I<$Var>, I<$name>, I<\$buf> [,C<filter>])

=back

=item

load() is the constructor of OLE::PropertySet. You can call it
either with a Property Storage id I<$pps> and a Structured Storage 
document handle I<$Doc> as parameters, or with an PropertySetName I<$name>
and a reference to a PropertySetBuffer I<\$buf>.

=item NewVar

I<$Var> == I<$PS> -> NewVar ()

Creates a new Variable handling object and returns it. (see also: open)

=item property

I<Property>||I<scalar> = I<$PS> -> property (I<$id1> [,I<$id2> [...]])

Returns a I<$Property> or a list of I<@Properties>. (See 
OLE::Storage::Property to look what to do with it / them). If you applied a
filter when loading I<$PS>, property returns a scalar or a list of scalars.

=item type

I<$type>||0 = PropertySet -> type (I<$Doc>, I<$pps>)

I<$type>||0 = PropertySet -> type ($name)

Returns the type of a PropertySet according to its name. The type is
a OLE::PropertySet internal. It can be used to determine, if a property
is a PropertySet or not. Momentarily are existing:

 type    meaning
 ---------------------------------------------------
 0x01    property is a "\05" PropertySet
 0x10    property is a "\01CompObj" fake PropertySet
 0x00    property is no PropertySet at all

=back

=head1 SEE ALSO

L<OLE::Storage::Property>, demonstration program "ldat"

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut

