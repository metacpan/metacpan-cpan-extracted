#
# $Id: Handler.pm,v 1.1.1.1 1998/02/25 21:13:00 schwartz Exp $
#
# OLE::Storage::Handler
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

package OLE::Storage::Handler;
use strict;
my $VERSION=do{my@R=('$Revision: 1.1.1.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};
my $debug=0;

# $types = {
#    0x1e => {
#       NAME   => "lpstr",
#       FUNC   => {
#          0x1e   => {CODE => \&store,		PAR => undef},
#          string => {CODE => \&0x1e_string,	PAR => undef},
#       }
#    }
#    0x1f => {
#       NAME   => "lpwstr",
#       FUNC   => {
#          0x1f   => {CODE => \&store,		PAR => undef},
#          string => {CODE => \&0x1f_string,	PAR => undef},
#       }
#    }
#    string => {
#       NAME  => "string",
#       FUNC  => {
#          0x1e  => {CODE => \&string_0x1e,	PAR => undef},
#          0x1f  => {CODE => \&string_0x1f,	PAR => undef},
#       }
#    }
# }

sub new { bless ({}, ref($_[0]) || $_[0]) }

sub add {
#
# add ($from_type, $from_typestr||"", $to_type, \&sub, $parameter)
# add ([$from_type, $from_typestr||"" (,$to_type, \&sub, $parameter)+ ])
#
   my $S = shift;
   if (!ref($_[0])) {
      my ($from, $fromstr, $to, $Sub, $par) = splice(@_, 0, 5);
      $S -> typestr ($from, $fromstr);
      $S -> func ($from, $to, $Sub, $par);
   } else {
      my $P = shift;
      my ($from, $fromstr) = splice(@$P, 0, 2);
      $S -> typestr ($from, $fromstr);
      while (@$P) {
         $S->func ($from, splice(@$P, 0, 3));
      }
   }
}

sub convert {
   my ($S, $from, $to, $bufR, $oR) = splice(@_, 0, 5);
   my $code;
   if (!ref($from) && !ref($to)) {
      $code = $S->code($from, $to);
   } elsif (!ref($to)) {
      for (@$from) {
         $from = $_;
         last if $code = $S->code($from, $to);
      }
   } elsif (!ref($from)) {
      for (@$to) {
         $to = $_;
         last if $code = $S->code($from, $to);
      }
   } else {
      my $fromR = $from; $from = undef;
      for (@$to) {
         $to = $_;
         for (@$fromR) {
            if ($code = $S->code($_, $to)) {
               $from = $_; last;
            }
         }
         last if $from;
      }
   }
   if ($code) {
      &$code ($bufR, $oR, $S->par($from, $to), @_);
   } else {
      if ($debug) {
         # The line number will not be correctly for access without "tie"...
         my ($package, $filename, $line) = caller(3);
         print "$filename line $line: Cannot convert \"$from\" to \"$to\".\n";
      }
      "";
   }
}

#
# Member methods
#

sub func {
   my ($S, $from, $to, $Sub, $par) = @_;
   $S->par  ($from, $to, $par);
   $S->code ($from, $to, $Sub);
}

sub code {
   my ($S, $from, $to, $Sub) = @_;
   $S->{$from}->{FUNC}->{$to}->{CODE} = $Sub if defined $Sub;
   $S->{$from}->{FUNC}->{$to}->{CODE};
}

sub par {
   my ($S, $from, $to, $par) = @_;
   $S->{$from}->{FUNC}->{$to}->{PAR} = $par if defined $par;
   $S->{$from}->{FUNC}->{$to}->{PAR};
}

sub typestr {
#
# typestr ($type, $typestr||"")
#
   my ($S, $type, $typestr) = @_;
   $S->{$type}->{NAME} = $typestr if $typestr;
   $S->{$type}->{NAME};
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Handler - Handle functions for OLE::Storage::Var

$Revision: 1.1.1.1 $ $Date: 1998/02/25 21:13:00 $

=head1 SYNOPSIS

use OLE::Storage::Var;

I<$Var> = new Var;

I<$Handle> = I<$Var> -> handle();

Methods will be described below. But be aware, that this package is a 
little bit likely to be removed in future. Actually you should not need 
to deal with it at all.

=head1 DESCRIPTION

OLE::Storage::Handler is the interface used by OLE::Storage::Var. The purpose was to
allow the installation of new Property types easily and even at runtime.
An example of how this could look like can be found in "lls". Anyway,
this all looks pretty superfluous to me, and therefore might be removed
some nice day.

I<\&sub> == I<$Var> -> add (I<$from>, I<$fromstr>||C<0>, I<$to>, I<\&sub> [,I<$par>])

I<$data> = I<$Var> -> convert (I<$from>, I<$to>, I<\$buf>, I<\$o>)

I<\&sub> == I<$Var> -> func (I<$from>, I<$to> [,I<$Sub> [,I<$par>]])

I<\&sub> == I<$Var> -> code (I<$from>, I<$to> [,I<$Sub>])

I<$par> = I<$Var> -> par (I<$from>, I<$to> [,I<$par>])

I<$typestr> = I<$Var> -> typestr (I<$type> [,I<$typestr>])

=head1 SEE ALSO

L<OLE::Storage::Var>, demonstration program "lls"

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut

