#
# $Id: Io.pm,v 1.2 1998/03/23 02:53:45 schwartz Exp $
#
# Io.pm
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

package OLE::Storage::Io;
use strict;
my $VERSION=do{my@R=('$Revision: 1.2 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};
my $IOnum = 0;

use Symbol;
use OLE::Storage::Iolist(); 

sub close {
#
# 1 = close([\$streambuf])
#
   my ($S, $bufR) = @_;

   if ($S->_mode & 0x10) {
      $$bufR = ${$S->_cache()} if defined $bufR;
   } else {
      $S->flush();
      close ($S->_io);
   }
1}

sub default_iosize {
#
# ($offset, $size) || 0 =
#    default_iosize (defsize, "r"||"w", offset, size)
#
   my ($S, $defsize, $rw, $o, $l) = @_;
   return 0 if !$S->_io_method($rw);

   if (!$l) {
      if ($rw =~ /r/) {
         if (!defined $l) {
            # read default
            $o=0; $l=$defsize;
         } else {
            # read zero size: no problem 
         }
      } else {
         if (!defined $l) {
            # write default: not allowed!
            return _error("Write error! Unknown size.");
         } else {
            # write zero size: no problem
         }
      }
   }
   ($o, $l);
}

sub flush {
#
# 1 = flush()
#
# flush io cache, if caching is turned on
#
   my $S = shift;
   my $bufR = $S->_cache();

   return if !$bufR;

   $S->_cache(undef);
   $S->rw_iolist("w", $bufR, $S->_iolist->aggregate(2));

   $S->_iolist(new OLE::Storage::Iolist());
1}

sub name { 
   shift->_name() 
}

sub open { 
#
# $Io||0 = open ($Startup, $filename [,$openmode [,\$streambuf]]);
#
# openmode bitmask (0 is default):
#
# Bit 0:  0 read only   1 read and write
# Bit 4:  0 file mode   1 buffer mode 
#
   my ($proto, $Startup, $filename, $openmode, $bufR) = @_;
   my $class = ref($proto) || $proto;
   my $S = bless ({}, $class);

   $S->_Startup  ($Startup);			# startup object
   $S->_iolist   (new OLE::Storage::Iolist());	# iolist object
   $S->_mode     ($openmode || 0);		# s.a.
   $S->_name     ($filename || "");		# name of file or buffer
   $S->_size     (-s $filename);		# size of file or buffer
   $S->_writable (0);				# file/buffer is read-only

   if ($openmode & 0x10) {
      return 0 if !$S->_init_stream($bufR);
   } else {
      return 0 if !$S->_init_file($class);
   }

   $S;
}

sub read {
#
# 1||0 = read($file_offset, $num_of_chars, \$buf [,$var_offset])
#
   my ($S, $fo, $num, $buf_or_bufR, $vo) = @_;
   my $bufR = _buf_or_bufR($buf_or_bufR);
   my $status = 0;

   if (!$vo) {
      $vo = 0;
      if (!$num) {
         $$bufR = ""; $status = 1;
      }
   }

   if (!$status) {
      if ($S->_cache()) {
         substr($$bufR, $vo, $num) = substr(${$S->_cache()}, $fo, $num);
         $status = 1;
      } else {
         $status = seek($S->_io, $fo, 0) 
            && (read($S->_io, $$bufR, $num, $vo) == $num)
            || $S->_error("Read error!")
         ;
      }
   }

   if (defined $buf_or_bufR) {
      return $status;
   } else {
      return $status && $$bufR || undef;
   }
}

sub read_iolist {
   shift->rw_iolist("r", @_);
}

sub rw_iolist {
# 
# 1||0        = rw_iolist($S, "r"||"w", \$buf||$buf, $iolistO);
# 1||0        = rw_iolist($S, "w"     , undef,       $iolistO);
# $buf||undef = rw_iolist($S, "r"     , undef,       $iolistO);
#
   my ($S, $rw, $buf_or_bufR, $ioR) = @_;
   my $bufR = _buf_or_bufR($buf_or_bufR);
   my ($o, $l);
   my $done = 0;
   my $status = 1;

   for (0 .. $ioR->max()) {
      ($o, $l) = $ioR->entry($_);
      next if !$l;
      if ($S->_rw_io($rw, $o, $l, $bufR, $done)) {
         $done += $l;
      } else {
         # io error!
         $status = 0; last;
      }
   }
   if ($rw =~ /r/ && !defined $buf_or_bufR) {
      return $status && $$bufR || undef;
   }
   $status;
}

sub size { 
   shift->_size() 
}

sub writable { 
   shift->_writable() 
}

sub write {
#
# 1||0 = write($file_offset, $num_of_bytes, \$buf||$buf||undef [,$var_offset])
#
# Tries to write a $num_of_bytes long string. If $buf ($$buf) is too short,
# the missing rest will be filled with zero chars "\0".
#
   my ($S, $fo, $num, $buf_or_bufR, $vo) = @_;
   my $bufR = _buf_or_bufR($buf_or_bufR);

   return $S->_error ("Cannot write! (File is opened as read-only)") 
      if !$S->_writable
   ;
   if (!$vo) {
      return 1 if !$num; $vo = 0; 
   }

   my $tmp = substr($$bufR, $vo, $num);
   $tmp .= "\0" x ($num-length($tmp));

   if ($S->_cache()) {
      substr(${$S->_cache()}, $fo, $num) = $tmp;
      $S->_iolist->append($fo, $num);
      return 1;
   } else {
      seek($S->_io, $fo, 0) 
         && (print {$S->_io} $tmp)
         || $S->_error("Write error!")
      ;
   }
}

sub write_iolist {
   shift->rw_iolist("w", @_);
}

#
# -- Private ---------------------------------------------------------------
#

sub _buf_or_bufR {
#
# Allow to pass references and scalars as argument. (nice for small scalars)
#
   my $buf_or_bufR = shift;
   my $bufR;
   if (defined $buf_or_bufR) {
      $bufR = ref($buf_or_bufR) && $buf_or_bufR || \$buf_or_bufR;
   } else {
      my $buf="";
      $bufR = \$buf;
   }
}

sub _error { 
   my $S = shift;
   $S->_Startup->error(@_) if $S->_Startup;
}

sub _init_file {
#
# 1||0 = _init_file ($S)
# 
   no strict "refs";
   my ($S, $class) = @_;

   my $status;
   my $fn = $S->_name;
   my $IOname = gensym;

   return $S->_error("File \"$fn\" does not exist!")   if ! -e $fn;
   return $S->_error("\"$fn\" is a directory!")        if   -d $fn;
   return $S->_error("\"$fn\" is no proper file!")     if ! -f $fn;
   return $S->_error("Cannot read \"$fn\"!")           if ! -r $fn;

   if ($S->_mode & 1) {
      return $S->_error("\"$fn\" is write protected!") if ! -w $fn;
      $S->_writable(1);
      $status = open($IOname, '+<'.$fn);
   } else {
      $S->_writable(0);
      $status = open($IOname, $fn);
   }
   return $S->_error("Cannot open \"$fn\"!") if !$status;
   $S->_io($IOname);

   binmode($S->_io); 
   if ($S->_writable) {
      select($S->_io); $|=1; select(STDOUT);
   }

   # here extern check routine belonged...

   if ($S->_cache()) {
      if (!$S->read(0, $S->_size, $S->_cache, 0)) {
         $S->_cache(undef);
      } 
   }
1}

sub _init_stream {
#
# 1||0 = _init_stream ($S, \$streambuf);
#
   my ($S, $bufR) = @_;
   return $S->_error("No stream data available!") if !defined $bufR;
   $S->_size(length($$bufR));
   $S->_cache($bufR);
1}

sub _io_method {
   my ($S, $rw) = @_;
   return $S->_error("Bad IO method \"$rw\"!") if !($rw =~ /^[rw]$/);
1}

sub _rw_io {
#
# 1||0= _rw_io($S,"r"||"w", $file_offset, $num_of_chars, \$buf [,$var_offset])
#
   my ($S, $rw) = (shift, shift);
   return 0 if !$S->_io_method($rw);

   if ($rw =~ /r/) {
      $S->read(@_);
   } elsif ($rw =~ /w/) {
      $S->write(@_);
   } 
}

#
# -- memberEss methods -----------------------------------------------------
#

sub _cache    { my $S = shift; $S->{IOBUFR}  = shift if @_; $S->{IOBUFR} }
sub _Startup  { my $S = shift; $S->{STARTUP} = shift if @_; $S->{STARTUP} }
sub _io       { my $S = shift; $S->{IO}      = shift if @_; $S->{IO} }
sub _iolist   { my $S = shift; $S->{IOLIST}  = shift if @_; $S->{IOLIST} }
sub _mode     { my $S = shift; $S->{MODE}    = shift if @_; $S->{MODE} }
sub _name     { my $S = shift; $S->{NAME}    = shift if @_; $S->{NAME} }
sub _size     { my $S = shift; $S->{SIZE}    = shift if @_; $S->{SIZE} }
sub _writable { my $S = shift; $S->{WRITE}   = shift if @_; $S->{WRITE} }

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Io - Laola's IO interface

=head1 SYNOPSIS

use OLE::Storage::Io();

s.b.

=head1 DESCRIPTION

B<Note>: OLE::Storage is doing IO by maintaining lists consisting of
(I<$offset>, I<$length>) elements.

=over 4

=item close

C<1>||C<O> == I<$Io> -> close ([I<\$streambuf>])

Destructor. Flushes cache and closes file.

=item flush

C<1> == I<$Io> -> flush ()

Flush I<$Io> cache, if caching is turned on.

=item name

I<$name> = I<$Io> -> name ()

Returns name of I<$Io>.

=item open

I<$Io>||C<O> == open (I<$Startup>, I<$name>, [,I<$mode> [,I<\$streambuf>]])

Constructor. Gives access to a file or a buffer. Default I<$mode> is 0,
that is read only. In file mode I<$name> is a filepath. In buffer mode
a reference to a buffer I<\$streambuf> is mandatory. Errors occuring
at Io methods will be reported to Startup object I<$Startup>.

   Bit	Mode
   0	0 read only	1 read/write
   4	0 file mode	1 buffer mode

=item read

C<1>||C<O> == I<$Io> -> read (I<$offset>, I<$len>, I<\$buf> [,I<$var_offset>])

Reads I<$len> bytes starting at offset I<$offset> into buffer referenced by
I<\$buf>. If I<$var_offset> is given, buffer will be filled from this offset
on.

=item rw_iolist

C<1>||C<0> == I<$Io> -> rw_iolist (C<"r">||C<"w">, I<\$buf>, I<$iolistO>);

Read Iolist I<$Io> into buffer I<$buf> ("r"), or write buffer to Iolist
I<$Io>.

=item size

I<$len> = I<$Io> -> size ()

Returns size of I<$Io> in bytes.

=item writable

C<1>||C<O> == I<$Io> -> writable ()

I<$Io> is writable (1) or not (0).

=item write

C<1>||C<O> == I<$Io> -> write (I<$offset>, I<$len>, I<\$buf> [,I<$var_offset>])

Writes I<$len> bytes starting at offset I<$offset> from buffer referenced by
I<\$buf> to I<$Io>. If I<$var_offset> is given, buffer will be read from
this offset on.

=back

=head1 SEE ALSO

L<OLE::Storage::Iolist>, L<Startup>

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>

=cut

