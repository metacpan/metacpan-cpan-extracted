#
# $Id: Storage.pm,v 1.8 1998/04/28 00:39:43 schwartz Exp $
#
# OLE::Storage, a Structured Storage interface 
#
# Also known as: Laola filesystem.
#
# (POD documentation at end of file)
#
# This perl 5 library gives raw access to "Ole/Com" documents. These are 
# documents like created by Microsoft Word 6.0+ or newer Star Divisions 
# Word by using so called "Structured Storage" technology. Write access 
# still is nearly not supported, but will be done one day. This library 
# should have come along with a couple of other files. The whole 
# distribution can be found at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/index.html
# or
#    http://www.cs.tu-berlin.de/~schwartz/pmh/index.html
#
# Copyright (C) 1996, 1997 Martin Schwartz 
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
# Diese Veröffentlichung erfolgt ohne Berücksichtigung eines eventuellen
# Patentschutzes. Warennamen werden ohne Gewährleistung einer freien 
# Verwendung benutzt. ;-)
#
# Contact: schwartz@cs.tu-berlin.de
#

#
# Really important topics still MISSING until now:
#
#   - Human rights and civil rights where you live.
#
#   - Reformfraktion president for Technische Universität Berlin.
#
#   - creating documents 
#   - many property set things: 
#     *  documentation of variable types
#     *  code page support
#   - consistant name giving, checked against MS'
#

package OLE::Storage;
my $VERSION=do{my@R=('$Revision: 1.8 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};
$[=0;

#  
# Storage.pm has public method interfaces and private functions. Functions
# assume a local($S) as $self. I put some efforts into making it strict-proof,
# especially to "methodize" all functions, but I didn't like the resulting 
# code. May be I'll regret this once ;-), but momentarily I'm quite ok with: 
# 
no strict; $^W=0;

#
# Abbreviations
# 
#    bbd    Big Block Depot
#    pps    Property Storage
#    ppset  Property Set
#    ppss   Property Set Storage
#    sb     Start Block
#    sbd    Small Block Depot
# 

use OLE::Storage::Std;
use OLE::Storage::Var();
use OLE::Storage::Io(); 
use OLE::Storage::Iolist(); 

sub Startup  { my $S=shift; $S->{STARTUP} = shift if @_; $S->{STARTUP} }
sub Var      { my $S=shift; $S->{VAR}     = shift if @_; $S->{VAR} }
sub NewVar   { OLE::Storage::Var::new qw(OLE::Storage::Var) }

sub _error   { $S->{STARTUP} ? $S->{STARTUP}->error(@_) : 0 }

##
## File and directory handling
##

sub check {
#
# 1||0 = check($Startup, $file [,$mode [,\$streambuf]]);
#
   # to do!
   my ($proto, $Startup, $name, $mode, $bufR) = @_;
   my $Io = OLE::Storage::Io->open($Startup, $name, $mode, $bufR)
}

sub open { 
#
# $Doc||0 = open($Startup, $Var, $file [,$mode [,\$streambuf]]);
#
# mode bitmask (0 is default):
#
# Bit 0 (0 read only, 1 read and write)
# Bit 4 (0 file mode, 1 buffer mode)
#
# Own errors:
#
#	1   "'Var' object not specified!"
#	2   IO->open error
#       3   _init_doc error
#
   my ($proto, $Startup, $Var, $name, $mode, $bufR) = @_;
   my $class = ref($proto) || $proto;
   local $S = bless(_init_vars(), $class);

   $S->Startup($Startup);

   unless ($S->Var($Var)) {
      return _error("'Var' object not specified!", 1) 
   }

   unless ($S->{IO} = OLE::Storage::Io->open($Startup, $name, $mode, $bufR)) {
      return _error("", 2);
   }

   unless (_init_doc()) {
      $S->{IO} -> close($bufR);
      return _error("", 3);
   }

   $S;
}

sub close { 
#
# 1 = close([\$streambuf])
#
   my ($S, $bufR) = @_;
   $S->{IO}->close($bufR);
1}

sub is_directory { 
#
# 1||0 = is_directory($pps)
#
   my ($S, $pps) = @_;
   ($S->{PPS}[$pps]->{TYPE} == 1) || $S->is_root($pps);
}

sub is_stream { goto &is_file }

sub is_file { 
#
# 1||0 = is_file($pps)
#
   shift->{PPS}[shift]->{TYPE} == 2;
}

sub is_root { 
#
# 1||0 = is_root($pps)
#
   shift->{PPS}[shift]->{TYPE} == 5;
}

sub dirhandles { 
#
# @pps = dirhandles($pps);
#
   local ($S, $pps) = @_;
   $S->is_directory($pps)
      && _get_ppss_chain($S->{PPS}[$pps]->{DIR})
   ;
}

sub directory { 
#
# 1||0 = directory($pps, \%directory [,property_method]);
#
   my ($S, $pps, $dirR, $method) = @_;
   return 0 if !$S->is_directory($pps);
   for ($S->dirhandles($pps)) {
      if ($method) {
         $$dirR{$S->name($_)->$method()} = $_;
      } else {
         $$dirR{$S->name($_)} = $_;
      }
   }
1}

sub clsid { 
#
# Property(lpwstr) = clsid($pps);
#
   $_[0]->{PPS}[$_[1]]->{CLSID};
}

sub color {
#
# 0(Black)||1(Red) = color($pps);
#
   $_[0]->{PPS}[$_[1]]->{COLOR};
}

sub name { 
#
# Property(lpwstr) = name($pps);
#
   $_[0]->{PPS}[$_[1]]->{NAME};
}

sub date { 
#
# Property(filetime) = date($pps [,$par])
#
   my ($S, $pps, $par) = @_;
   return $S->Var->error("No timestamps on files!") if $S->is_file();
   $S->{PPS}[$pps]->{$par? TS1: TS2};
}

sub size { 
#
# $filesize||undef = size($pps);
#
   my ($S, $pps) = @_;
   $S->is_file($pps) 
      && $S->{PPS}[$pps]->{SIZE}
   || undef;
}

sub read { 
#
# 1||0 = read($pps, \$buf [,$offset, $size]);
#
   local $S=shift; _rw_file("r", @_);
}

sub modify { 
#
# 1||0 = modify($pps, \$buf, $offset, $size);
# 
   local $S=shift; _rw_file("w", @_);
}

##
## Trash handling
##

sub size_trash { 
#
# $sizeof_trash_section = size_trash($type)
#
   local $S = shift; _get_trash_size(@_);
}

sub read_trash { 
#
# 1||0 = read_trash ($type, \$buf [,$offset, $size]);
#
   local $S = shift; _rw_trash("r", @_);
}

sub modify_trash { 
#
# 1||0 = modify_trash ($type, \$buf [,$offset, $size]);
# 
   local $S = shift; _rw_trash("w", @_);
}


##
## ----------------------------- "private" ---------------------------------
##

#
# open ->
#

sub _init_vars {
   {
      IO	   => undef,		# IO.pm object
      CURPPS	   => undef,		# current pps
      CURPPS_IO	   => undef,		# Iolist for current pps
      HEAD         => undef,            # OLE Header struct
      PPS          => [],		# OLE Property structs
      USE => {
         BB    => [],			# big blocks usage  
         SB    => [],			# small blocks usage
         KNOWN => undef
      },
      TRASH => {
         IO    => [],			# array of iolists
         S     => [],			# size of corresponding iolist
         KNOWN => undef
      },
      BL => {
         B_NUM => undef,		# max big block
         B_D   => [],			# big block depot
         B_DL  => [],			# big block depot list
         S_NUM => undef,                # max small block
         S_D   => [],			# small block depot
         S_DL  => [],			# small block depot list
         ROOTL => [],			# root blocks list
         SBL   => [],			# small blocks list
      },
   }
}

sub _init_doc {
#
# read bbd, 
# get bbd -> root-chain,  get bbd -> sbd-chain
#
# Own errors:
# 	1  "$fn is no Ole / Compound Document!"
#       2  "Document is corrupt (size too small)."
#       3  "Document is corrupt (no root entry defined)."
#       4  "Document is corrupt (Cannot read root entry)."
#
   my ($i, $tmp, @tmp);

   # little integrity check 1
   {
      unless (
         (read_long($S->{IO}, 0)==0xe011cfd0) && 
         (read_long($S->{IO}, 4)==0xe11ab1a1) 
      ) {
         my $fn = '"'.$S->{IO}->name().'"';
         return _error("$fn is no Ole / Compound Document!", 1);
      }
   }

   # header data
   {
      $S->{HEAD}->{B_S}      = 2 ** read_word($S->{IO}, 0x1e);
      $S->{HEAD}->{S_S}      = 2 ** read_word($S->{IO}, 0x20);
      $S->{HEAD}->{B_DL_L}   = undef;
      $S->{HEAD}->{B_D_NUM}  = read_long($S->{IO}, 0x2c);
      $S->{HEAD}->{ROOT_SB}  = read_long($S->{IO}, 0x30);
      $S->{HEAD}->{B_S_MIN}  = read_long($S->{IO}, 0x38);
      $S->{HEAD}->{S_D_SB}   = read_long($S->{IO}, 0x3c);
      $S->{HEAD}->{S_D_NUM}  = read_long($S->{IO}, 0x40);
      $S->{HEAD}->{B_XD_SB}  = read_long($S->{IO}, 0x44);
      $S->{HEAD}->{B_XD_NUM} = read_long($S->{IO}, 0x48);

      my $root = _h_s() + ($S->{HEAD}->{ROOT_SB})*_b_s();
      $S->{HEAD}->{S_SB} = read_long($S->{IO}, $root+0x74);
      $S->{BL}->{S_NUM} = int (read_long($S->{IO}, $root+0x78)/_s_s() -1);
   }

   # little integrity check 2
   {
      $S->{BL}->{B_NUM} = int ( ($S->{IO}->size()-_h_s()) / _b_s() -1 );
      return _error("Document is corrupt (size too small).", 2) 
         if $S->{BL}->{B_NUM}<1
      ;
   }

   # construct big block depot Iolist
   {
      my $Iolist = new OLE::Storage::Iolist([0x4c], [_h_s()-0x4c]);
      my $bl = $S->{HEAD}->{B_XD_SB};
      for (1..$S->{HEAD}->{B_XD_NUM}) {
         $Iolist->append(_h_s() + $bl*_b_s(), _b_s()-4);
         $bl = read_long($S->{IO}, _h_s() + $bl*_b_s() + _b_s()-4);
         last if $bl >= _B_EOC();
      }
      $S->{HEAD}->{B_DL_L} = $Iolist;
   }

   # read big block depot
   {
      return 0 if !$S->{IO}->read_iolist(\$tmp, 
         $S->{HEAD}->{B_DL_L}
      );
      @{$S->{BL}->{B_DL}} = get_nlong($S->{HEAD}->{B_D_NUM}, \$tmp, 0);

      return 0 if !$S->{IO}->read_iolist(\$tmp, 
         _get_iolist(3, 0, _S_MAX(), 0, $S->{BL}->{B_DL})
      );
      @{$S->{BL}->{B_D}} = get_nlong($S->{BL}->{B_NUM}+1, \$tmp, 0);
   }

   # read small block depot
   {
      $S->{BL}->{S_DL} = _get_list_from_depot($S->{HEAD}->{S_D_SB}, "B");
      return 0 if !$S->{IO}->read_iolist(\$tmp, 
         _get_iolist(3, 0, _S_MAX(), 0, $S->{BL}->{S_DL})
      );
      @{$S->{BL}->{S_D}} = get_nlong($S->{BL}->{S_NUM}+1, \$tmp, 0);
   }

   # root chain
   {
      return _error("Document is corrupt (no root entry defined).", 3) if !@{
         $S->{BL}->{ROOTL} = _get_list_from_depot($S->{HEAD}->{ROOT_SB}, "B")
      };
   }

   # small block chain
   {
      # An empty small block list is ok.
      $S->{BL}->{SBL} = _get_list_from_depot($S->{HEAD}->{S_SB}, "B");
   }

   # property storages, just read root entry.
   {
      return _error ("Document is corrupt (Cannot read root entry).", 4)
         if !_read_ppss(0)
      ;
   }

1}


##
## -------------------------- File IO ------------------------------
## 

sub _rw_file {
#
# 1||0        = _rw_file ("r"||"w", $pps, \$buf||$buf||undef [,$offset, $size])
# $buf||undef = _rw_file ("r"     , $pps, undef,             [,$offset, $size])
#
   my ($rw, $pps, $buf_or_bufR) = (shift, shift, shift);

   return _error("pps is no file!") if !$S->is_file($pps);
   my $size = $S->{PPS}[$pps]->{SIZE};
   return 0 if !(($o, $l) = $S->{IO}->default_iosize($size, $rw, @_));

   return _error("Bad document structure!") 
      if !_get_curpps_iolist($pps)
   ;

   $S->{IO}->rw_iolist(
      $rw, $buf_or_bufR, _get_iolist(4, $o, $l, 0, $S->{CURPPS_IO})
   );
}

sub _get_curpps_iolist {
#
# 1||0 = _get_curpps_iolist($pps)
#
# Gets Iolist for current $pps
#
   my $pps = shift;
   return 1 if (defined $S->{CURPPS}) && ($S->{CURPPS}==$pps);
   $S->{CURPPS_IO} = _get_iolist(
      _bdepottype($pps), 0, $S->{PPS}[$pps]->{SIZE}, $S->{PPS}[$pps]->{SB}
   );
   $S->{CURPPS} = $pps;
1}

sub _get_all_filehandles {
#
# @file_handles = _get_all_filehandles($starting_directory_pps)
#
# !recursive!
# Recurse over all files and directories, return all file handles.
#
   map ( 
      $S -> is_file($_) ? $_ : _get_all_filehandles($_),
      $S -> dirhandles(shift)
   );
}

#
# -- some macros -----------------------------------------------------------
#

sub _h_s        { 0x200 }			# header size
sub _b_s        { $S->{HEAD}->{B_S} }		# big block size
sub _s_s        { $S->{HEAD}->{S_S} }		# small block size
sub _b_s_min    { $S->{HEAD}->{B_S_MIN} }	# big file minimal size
sub _bdepottype { $S->{PPS}[shift]->{SIZE} >= _b_s_min() }
sub _blocktype  { $S->{PPS}[shift]->{SIZE} >= _b_s_min() ? "B" : "S" }

sub _B_FREE     { 0xffffffff }	# block entry, free block
sub _B_EOC	{ 0xfffffffe }	# block entry, end of chain
sub _B_BD	{ 0xfffffffd }	# block entry, block depot
sub _B_XBD	{ 0xfffffffc }	# block entry, extra block depot

sub _S_MAX      { 0xffffffff }	# maximal stream size (* byte)

##
## --------------------------- IO logic ------------------------------------
##

sub ole_head {
   \{
      MAGIC     => undef,	#      00
      CLSID     => undef,	# guid 08
      REVISION	=> undef,	# word 18
      VERSION	=> undef,	# word 1a
      BYTEORDER => undef,	# word 1c
      B_S_LOG   => undef,	# word 1e	big block size = 2^b_s_log
      S_S_LOG   => undef,	# word 20	small block size = 2^s_s_log
      UK1	=> undef,	# word(5) 22
      B_D_NUM	=> undef,	# long 2c	bbd num of blocks
      ROOT_SB	=> undef,	# long 30	root start block
      UK2	=> undef,	# long 34
      B_S_MIN	=> undef,	# long 38	minimum size of big_block
      S_D_SB	=> undef,	# long 3c	sbd start block
      S_D_NUM	=> undef,	# long 40	number of sbd blocks
      B_XD_SB	=> undef,	# long 44
      B_XD_NUM	=> undef,	# long 48
   };
}

sub _read_ppss_buf {
#
# 1||0 = _read_ppss_buf ($i, \$buf, $bufoffset)
#
# 0..NLEN char()  NAME    
# 40      word    NLEN 
# 42      byte    TYPE        
# 43      byte    COLOR         
# 44      long    PREV        
# 48      long    NEXT        
# 4c      long    DIR         
# 64      char(8) TS1     
# 6c      char(8) TS2         
# 74      long    SB          
# 78      long    SIZE        
#
   my ($i, $bufR, $o) = @_;
   return 0 if !$bufR;

   $o = 0 if !defined $o;
   return 1 if defined $S->{PPS}[$i];

   my $P = {};
   ($P->{NLEN}, $P->{TYPE}, $P->{COLOR}, $P->{PREV}, $P->{NEXT}, $P->{DIR})
      = get_struct("WBBLLL", $bufR, $o+0x40)
   ;

   ($P->{SB}, $P->{SIZE}) 
      = get_struct("LL", $bufR, $o+0x74)
   ;

   $P->{NAME} = $S->Var->property (
       \get_rzwstr($bufR, $o+0, $P->{NLEN}),
       0, "wstring"
   );

   $P->{CLSID} = $S->Var->property ($bufR, 0x50, 0x48);

   if ($P->{TYPE} != 2) { 
      # !!
      # Files (type==2) have no timestamp (until now?). Not reading this 
      # data speeds up tremendously (sigh)...
      # !!
      $P->{TS1} = $S->Var->property($bufR, 0x64, 0x40);
      $P->{TS2} = $S->Var->property($bufR, 0x6c, 0x40);
   }

   $S->{PPS}[$i] = $P;
1}

sub _read_ppss {
#
# 1||() = _read_ppss ($pps)
#
   my $pps = shift;
   return 1 if defined $S->{PPS}[$pps];

   _read_ppss_buf($pps, 
      \$S->{IO}->read_iolist(
         undef, _get_iolist(3, $pps*0x80, 0x80, 0, $S->{BL}->{ROOTL})
      )
   ) || ();
}

sub _get_ppss_chain {
#
# @blocks = _get_ppss_chain($ppss)
#
# !recursive!, doesn't care about red/black sorting  
#
   ($_[0] == 0xffffffff ?
      () : 
      _read_ppss($_[0]) && (
         _get_ppss_chain($S->{PPS}[$_[0]]->{PREV}),
         $_[0],
         _get_ppss_chain($S->{PPS}[$_[0]]->{NEXT}),
      )
   );
}

sub _get_list_from_depot {
#
# [@list] = _get_list_from_depot ($start, depottype)
#
# Read a block chain starting with block $start out of a either
# depot @bbd (for $t=="B") or depot @sbd (for $t=="S").
#
   my ($b, $t) = @_;
   my @list = ();

   while ($b != _B_EOC()) {
      push (@list, $b); 
      $b = $S->{BL}->{$t."_D"}[$b];
   }

   \@list;
}

sub _get_iolist {
# 
# $iolistO = _get_iolist(
#    $depottype, 
#    $offset, $size, 
#    $startblock 
#    [, \@blocklist || $iolistO]
# )
#
# This is the main IO logic. Returns the iolist for a data stream according 
# to depot type $t. The stream may start at offset $offset and can have a 
# size $size. If size is bigger than the total size of the stream according 
# to its depot, it will be cut correctly. (So if you want to read until the
# files end without knowing how many bytes that are, take 0xffffffff as size).
#
# depottype $t:
#    0 small     (for @sbd)      small block depot
#    1 big       (for @bbd)      big block depot
#    2 small     (for \@blocks)  some small blocks
#    3 big       (for \@blocks)  some big blocks
#    4 variable  (for $Iolist)   an Iolist
#
   my $t                    = shift||0;
   my ($offset, $size, $sb) = (shift||0, shift||0, shift||0);
   local ($blockR)          = shift if ($t==2 || $t==3);
   local ($IoL)             = shift if $t==4;
   local ($di);

   my $io_out = new OLE::Storage::Iolist();
   my ($begin, $bs, $done, $len, $max);
   return $io_out if !$size;

   $bs = ($t==1 || $t==3) ? _b_s() : _s_s();

   if ($t<2) {
      # To skip these offsets, stream chains would have to be resolved 
      # before. 
   } elsif ($t<4) {
      $max = $#{$blockR};
      # Skip whole blocks, when offset given
      $sb += int ($offset / $bs);
      $offset -= int ($offset / $bs) * $bs;
   } elsif ($t==4) {
      $max = $IoL->max();
   } else {
      return $io_out;
   }

   $done = 0;
   for ( $di=$sb; 
         ($t<2) ? ($di!=_B_EOC()) : ($di<=$max);
         $di=&{$__next_dl->[$t]}
   ) {
      last if ($done == $size);
      $bs = $IoL->length($di) if $t==4;
      if ($offset) {
         if ($bs <= $offset) {
            $offset -= $bs;
            next;
         } else {
            $begin = &{$__depot_offset->[$t]} + $offset;
            $len   = $bs - $offset;
            $offset = 0;
         }
      } else {
         $begin = &{$__depot_offset->[$t]};
         $len   = $bs;
      }
      if ( ($done+$len) > $size ) {
         $len = $size - $done;
      }
      $io_out->append($begin, $len);
      $done += $len;
   }
   $io_out;
}
$__next_dl = [ 
#
# index = depot ($di==index)
# Returns next chain link 
#
   sub { $S->{BL}->{S_D}[$di] },
   sub { $S->{BL}->{B_D}[$di] },
   sub { $di+1 },
   sub { $di+1 },
   sub { $di+1 },
];
$__depot_offset = [
#
# offset = __depot_offset ($di==index)
#
   sub { (($S->{BL}->{SBL}[$di/8]+1)*8 + ($di%8)) * _s_s() },
   sub { _h_s() + $di*_b_s() },
   sub { (($S->{BL}->{SBL}[$$blockR[$di]/8]+1)*8 + ($$blockR[$di]%8)) * _s_s()},
   sub { _h_s() + $$blockR[$di]*_b_s() },
   sub { $IoL->offset($di) }
];

##
## ------------------------- Trash Handling ------------------------------
##

sub _make_blockuse_statistic {
   #
   # block statistic: 
   #    0 == irregular free (block depot entry != -1) (== undef)
   #    1 == regular free (block depot entry == -1)
   #    2 == used for ole system
   #    3 == used for ole application
   #
   return 1 if $S->{USE}{KNOWN};
   my ($i, @list);
   my $bt;
   my $Bl = $S->{BL};

   # default: all small and big blocks are undef

   #
   # regular system data 
   #

   # ole system blocks
   for (@{$Bl->{B_DL}}, @{$Bl->{S_DL}}, @{$Bl->{ROOTL}}, @{$Bl->{SBL}}) { 
      $S->{USE}->{BB}[$_]=2; 
   }

   # free blocks according to block depots
   for (0..@{$Bl->{B_D}}) { 
      $S->{USE}->{BB}[$_]=1 if $Bl->{B_D}[$_]==_B_FREE() 
   }
   for (0..@{$Bl->{S_D}}) { 
      $S->{USE}->{SB}[$_]=1 if $Bl->{S_D}[$_]==_B_FREE() 
   }

   #
   # OLE application blocks
   #
   foreach $file (_get_all_filehandles(0)) {
      $bt = _blocktype($file);
      for (@{_get_list_from_depot($S->{PPS}[$file]->{SB}, $bt)}) {
         $S->{USE}->{$bt."B"}[$_]=3 
      }
   }

   $S->{USE}{KNOWN}=1;
}

sub _get_trash_info {
#
# 1 = _get_trash_info();
#
# Trash types:
#
#    0 == all
#    1 == unused big blocks
#    2 == unused small blocks 
#    4 == unused file space, according to sizeof pps_size (incl. root_entry)
#    8 == unused system space (header, sb_table, bb_table)
#
   return 1 if $S->{TRASH}{KNOWN};
   _make_blockuse_statistic();
   my ($begin, $len);
 
   unused_big_blocks: {
      _store_trash_iolist(0,
         _get_iolist(
            3, 0, _S_MAX(), 0, 
            [grep {$S->{USE}->{BB}[$_]<=1} (0..$S->{BL}->{B_NUM})]
         )
      );
   }

   unused_small_blocks: {
      _store_trash_iolist(1,
         _get_iolist(
            2, 0, _S_MAX(), 0, 
            [grep {$S->{USE}->{SB}[$_]<=1} (0..$S->{BL}->{S_NUM})]
         )
      );
   }

   unused_file_space: {
      # 3.1. normal files
      for (_get_all_filehandles(0)) {
         _store_trash_iolist(2, _get_iolist(
            _bdepottype($_), $S->{PPS}[$_]->{SIZE}, _S_MAX(), 
            $S->{PPS}[$_]->{SB}
         ));
      }

      # 3.2. system file of root_entry (small block file)
      $begin = $#{$S->{BL}->{S_D}}+1;
      _store_trash_iolist(2,
         _get_iolist(2, 0, _S_MAX(), 0, [$begin .. $begin+(7-$begin%8)])
      );

      # 3.3. unused root list entries
      # _get_all_filehandles is done by 3.1, so array $S->{PPS} is complete.
      $begin = ($#{$S->{PPS}}+1)*0x80;
      _store_trash_iolist(2,
         _get_iolist(3, $begin, _S_MAX(), 0, $S->{BL}->{ROOTL})
      );
   }

   unused_system_space: {
      _store_trash_iolist(3,
        # 4.1. header block
        _get_iolist(4, 
           ($S->{HEAD}->{B_D_NUM}+1)*4, _S_MAX(), 0, $S->{HEAD}->{B_DL_L}
        ),

        # 4.2. big block depot
        _get_iolist(3, ($S->{BL}->{B_NUM}+1)*4, _S_MAX(), 0, $S->{BL}->{B_DL}),

        # 4.3. small block depot
        _get_iolist(3, ($S->{BL}->{S_NUM}+1)*4, _S_MAX(), 0, $S->{BL}->{S_DL})
      );
   }

   $S->{TRASH}{KNOWN} = 1;
1}


sub _store_trash_iolist {
#
# 1 = _store_trash_iolist($index, $Iolist)
#
   my $i = shift;
   my $IoL;
   while (@_) {
      $IoL = shift;
      if (defined $S->{TRASH}{IO}[$i]) {
         $S->{TRASH}{IO}[$i] -> push( $IoL );
      } else {
         $S->{TRASH}{IO}[$i] = $IoL;
      }
      ${$S->{TRASH}{S}[$i]} += $IoL->sumlen();
   }
1}

sub _get_trash_size {
   my $type = shift || (1|2|4|8);
   my $size = 0;

   _get_trash_info();
   for (0..3) {
      $size += ${$S->{TRASH}{S}[$_]} if $type & 2**$_;
   }

   $size;
}

sub _rw_trash {
#
# 1||0        = _rw_trash ("r"||"w", $type, \$buf||$buf||undef [,$offset,$size])
# $buf||undef = _rw_trash ("r"     , $type, undef,             [,$offset,$size])
#
   my ($rw, $type, $buf_or_bufR) = (shift, shift, shift);

   _get_trash_info();
   my $size = $S->size_trash($type || (1|2|4|8));
   return 0 if !(($o, $l) = $S->{IO}->default_iosize($size, $rw, @_));

   my $trR = new OLE::Storage::Iolist();
   for (0..3) {
      $trR -> push ($S->{TRASH}{IO}[$_]) if ($type & 2**$_);
   }

   $S->{IO}->rw_iolist(
      $rw, $buf_or_bufR, _get_iolist(4, $o, $l, 0, $trR->aggregate(1))
   );
}

"Atomkraft? Nein, danke!"

__END__

#
# Methods
#
# basic:
#   open 
#   close 
#   name  
#   date  
#   directory 
#   dirhandles
#   size  
#   read      
#
# status:
#   is_directory  
#   is_file       
#   is_root       
#  
# writing:
#   modify   
#  
# trash handling:
#   size_trash 
#   read_trash     
#   modify_trash  

=head1 NAME

OLE::Storage - An Interface to B<Structured Storage> Documents.

$Revision: 1.8 $ $Date: 1998/04/28 00:39:43 $

=head1 SYNOPSIS

use OLE::Storage()

use Startup;

I<$Var> = OLE::Storage->NewVar ();
I<$Startup> = new Startup;

I<$Doc> = OLE::Storage->open (I<$Startup>, I<$Var>, I<$file> [,I<$m>, I<\$buf>])

I<$Doc> -> directory (I<$pps>, I<\%Names>, "I<string>")

I<$Doc> -> read (I<$pps>, I<\$buf> [,I<$offset>, I<$size>])

I<$Doc> -> close ()

Detailed syntax, descriptions and further methods: below.

=head1 DESCRIPTION

Documents done at Microsoft Windows Systems are tending to be stored in a
persistant data format, that MS calls "Structured Storage". This module gives
access to Structured Storage files. Alas, the current release allows more or
less read access, only. You can modify document contents (streams) with it,
but you cannot create or delete streams, nor rename them or change their
size. Also a file locking mechanism still is missing. I hope to offer write
support with next release.

=over 4

=item close

C<1>||C<O> == I<$D> -> close ()

Close the document.

=item clsid

I<$clsid> == I<$D> -> clsid (I<$pps>)

Returns the CLSID of the property I<$pps> as CLSID Property.

=item color

C<0>||C<1> == I<$D> -> color (I<$pps>)

Returns the "color" of the property I<$pps>.

=item date

I<$Date> == I<$D> -> name (I<$pps>)

Returns a 0x40 Property (filetime) with the creation date of property
storage I<$pps>. See OLE::Storage::Property for more information.

I<Note>: As of now, only directory properties have filetime stamps.

=item directory

C<1>||C<O> == I<$D> -> directory (I<$pps>, I<\%Names> [,I<method>])

Read the directory denoted by property handle I<$pps>. Fills the hash array
I<%Names> with the property names as keys and property handles as values.
The property names are Unicode Properties. To use the directory hash easily
you optionally can apply a Property method. You will probably have to use
I<"string"> or I<"wstring">. See OLE::Storage::Property for more information.

B<Note>:
To get the root directory, call directory (0, I<\%Names>).

=item dirhandles

I<@pps> == I<$D> -> dirhandles (I<$pps>)

Similar to directory (). Returns not the names, but only the property
handles of the directory denoted by property handle I<$pps>.

B<Note>:
Normally you will use directory () instead.
To get the root directory, call dirhandles(0)

=item Startup

I<$Startup> == I<$D> -> Startup ([I<$NewStartup>])

Gets the current I<$Startup> handler. If an optional argument I<$NewStartup> 
is given, this new handler will be installed and returned.

=item is_directory

C<1>||C<O> == I<$D> -> is_directory (I<$pps>)

Returns 1 if the property handle I<$pps> is refering to a directory, 
0 otherwise.

=item is_file

C<1>||C<O> == I<$D> -> is_file (I<$pps>)

Returns 1 if the property handle I<$pps> is refering to a file,
0 otherwise.

=item is_root

C<1>||C<O> == I<$D> -> is_root (I<$pps>)

Returns 1 if the property handle I<$pps> is refering to the document root, 
0 otherwise.

=item modify

C<1>||C<O> == I<$D> -> modify (I<$pps>, I<\$buf>, I<$offset>, I<$size>)

Modifies the contents of the property file I<$pps>. I<$size> bytes of the
file I<$pps> starting at offset I<$offset> will be replaced by I<$size>
bytes of the buf I<$buf> starting at offset 0.

B<Note>: This is still very restrictive, e.g. because the size of a file
cannot be changed. Also missing is a possibility to give an offset to I<$buf>.

=item modify_trash

C<1>||C<O> == I<$D> -> modify_trash (I<$type>, I<\$buf>, I<$offset>, I<$size>)

Modifies the contents of the trash section I<$type>. I<$size> bytes of the
trash section I<$type> starting at offset I<$offset> will be replaced by
I<$size> bytes of the buf I<$buf> starting at offset 0.

=item name

I<$Name> == I<$D> -> name (I<$pps>)

Returns the name of the property I<$pps> as Unicode Property.

=item NewVar

I<$Var> == I<$D> -> NewVar ()

Creates a new Variable handling object and returns it. (see also: open)

=item open

I<$Doc>||C<O> == Storage -> open (I<$Startup>, I<$Var>, I<$file> [,I<$mode>, I<\$buf>])

Constructor. Open the document with document path I<$file>. I<$mode> can be
read or read/write. If you additionally specify modus buffer, the document 
data will be read from the buffer reference you specify with I<$buf>.
Errors will be reported to Startup object I<$Startup> (if present).

Open modes:

   Bit	= 0 		= 1
   0	Read Only	Read and Write
   4	File Mode	Buffer Mode

=item read

C<1>||C<O> == I<$D> -> read (I<$pps>, I<\$buf>, [I<$offset>, I<$size>])

Read the file property I<$pps> into buffer I<$buf>. If there is an optional
I<$offset> and I<$size>, only this part of the file will be read.

=item read_trash

C<1>||C<O> == I<$D> -> read_trash (I<$type>, I<\$buf> [,I<$offset>, I<$size>])

Read the trash section I<$type> into buffer $buf. If there is an optional
I<$offset> and I<$size>, only this part of the trash section will be read.
Trash types can be 0, 1, 2, 4, 8 or a sum of this, like (1+2+8). 0 
is default and yields (1+2+4+8). You can find an explanation of these 
types in L<lclean>.

Trash types:

   #  Type
   -------------------
   1  Big blocks
   2  Small blocks
   4  File end space
   8  System space

=item size

I<$size>||C<undef> == I<$D> -> size (I<$pps>)

Returns the size of the file property I<$pps> in terms of bytes.

=item size_trash

I<$size> == I<$D> -> size_trash (I<$type>)

Returns the byte size of the trash section I<$type>.

=item Var

I<$Var> == I<$D> -> Var ([I<$NewVar>])

Gets the current $Var handler. If an optional argument $NewVar is given,
this new handler will be installed and returned.

=back

=head1 SEE ALSO

L<OLE::Storage::Property>, L<Startup>, L<OLE::Storage::Var>

=head1 EXAMPLES 

I<OLE::Storage> demonstration programs, as there are:

=over 4

=item B<lls>

I<Laola ls>. Lists document structures.

=item B<ldat>

I<Loala Display Authress Title>. Displays content of property sets and
shows, how by principle to fool around with Excel documents.

=item B<lclean>

Cleans and saves garbage in Structured Storage documents. Can also store and
retrieve a file at the garbage sections.

=item B<lhalw>

I<Have a look at Word>. Draws the text out of Word 6 and Word 7 documents,
supports a little bit Word 8.

=back

=head1 WWW

Latest distribution of I<Laola> and I<Elser> at:

	http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh
or
	http://www.cs.tu-berlin.de/~schwartz/pmh

=head1 BUGS

None known. I'm waiting for your hints!

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>. 

=cut

