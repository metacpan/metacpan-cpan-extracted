#
# $Id: Iolist.pm,v 1.1.1.1 1998/02/25 21:13:00 schwartz Exp $
#
# Iolist
#
# Copyright (C) 1997, 1998 Martin Schwartz 
#
# (POD documentation at end of file)
#
# Contact: schwartz@cs.tu-berlin.de
#

package OLE::Storage::Iolist;
use strict;
my $VERSION=do{my@R=('$Revision: 1.1.1.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

sub new {
   my ($proto, $oR, $lR) = @_;
   my $class = ref($proto) || $proto;
   my $S = {  
      O => $oR || [],
      L => $lR || []
   };
   bless ($S, $class);
}

sub dump {
   my ($S) = @_;
   if (@{$S->{O}}) {
      print "Iolist = \n";
      for (0..$#{$S->{O}}) {
         printf "  %03x: O=%6x  L=%x\n", $_, $S->{O}->[$_], $S->{L}->[$_];
      }
   } else {
      print "No Iolist.\n";
   }
   print "\n";
1}

sub append {
   my ($S, $o, $l) = @_;
   my $max = max($S);
   my ($o1, $l1) = entry($S, $max) if $max!=-1;
   if (($max==-1) || (($o1+$l1) != $o)) {
      push ( @{$$S{O}}, $o );
      push ( @{$$S{L}}, $l );
   } else {
      entry($S, $max, $o1, $l1+$l);
   }
}

sub push {
   my ($S, $sR) = @_;
   if ($sR && $S) {
      push ( @{$$S{O}}, @{$$sR{O}} );
      push ( @{$$S{L}}, @{$$sR{L}} );
   }
1}

sub entry {
   my ($S, $i) = (shift, shift);
   ($$S{O}[$i], $$S{L}[$i]) = (shift, shift) if @_;
   ($$S{O}[$i], $$S{L}[$i]);
}
sub length {my ($S, $i) = (shift, shift); $$S{L}[$i] = shift if @_; $$S{L}[$i]}
sub offset {my ($S, $i) = (shift, shift); $$S{O}[$i] = shift if @_; $$S{O}[$i]}
sub max    {my $S = shift; $#{$$S{O}} }

#
# ----- aggregate methods -----
#

sub sumlen {
   my $S = shift;
   my $size = 0;
   for (@{$$S{L}}) { 
      $size += $_;
   }
   $size;
}

sub aggregate {
#
# $iolistO = aggregate (method)
#
# method:  
#    1  @offsets shall be sorted, no overlap allowed
#    2  @offsets shall be sorted, overlap is allowed
#    3  @offsets are sorted, no overlap allowed
#    4  @offsets are sorted, overlap is allowed
#
   my ($S, $method) = @_;
   my $empty = $S->new();
   return $empty if ($method<1)||($method>4); # Don't know method!

   my ($o, $o1, $l, $l1);
   my %o_in  = ();
   my $o_in  = $S->new();
   my $o_out = $S->new();

   #
   # Sort
   #
   if ( ($method==1) || ($method==2)) {
      # sort offsets
      for (0 .. $S->max()) {
         ($o, $l) = $S->entry($_);
         next if !$l;
         if (defined $o_in{$o}) {
            return $empty if $method==1; # Data chunks overlap!
            $o_in{$o}=$_ if $l>$o_in{$o};
         } else {
            $o_in{$o}=$_;
         }
      } 
      for (sort {$a <=> $b} keys %o_in) {
         $o_in->append($S->entry($o_in{$_}));
      }
   } else {
      $o_in = $S;
   }

   #
   # Aggregate
   #
   ($o, $l) = $o_in->entry(0);

   for (1 .. $o_in->max()+1) {
      ($o1, $l1) = $o_in->entry($_);

      if ( ($_==($o_in->max()+1)) 
         || ( $o1 < $o )
         || ( $o1 > ($o+$l) )
      ) {
         $o_out->append($o, $l);
         ($o, $l) = ($o1, $l1);
      } elsif ( $o1 < ($o+$l) ) {
         return $empty if ($method==1 || $method==3); # Data chunks overlap! 
         if ( ($o1+$l1) > ($o+$l) ) {
            $l=$o1+$l1-$o;
         }
      } else {
         $l += $l1;
      }
   }
   $o_out;
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Iolist - Data management for OLE::Storage::Io (I<alpha>) 

=head1 SYNOPSIS

use OLE::Storage::Iolist();

s.b.

=head1 DESCRIPTION

B<Note>: OLE::Storage uses Iolists in conjuntion with Io interface for IO
operations. An IO entry is a two element list like (I<$offset>, I<$length>).

=over 4

=item aggregate

I<$NewIolist> = I<$IoL> -> aggregate (I<$method>)

Sorts and merges Iolist I<$IoL>, returns the new packed Iolist
I<$NewIolist>. Returns an empty Iolist on errors (!B<to be changed>!). 
I<$method> can be:

   method	sort offsets	allow offset overlaps
   1		yes		no
   2		yes		yes
   3		no		no
   4		no		yes

=item append

(I<$o1>, I<$l1>) == I<$IoL> -> append (I<$o>, I<$l>)

Appends an entry to Iolist. Tries to merge the Iolists last entry
with the new one. Returns the new last entry of Iolist.

=item entry

(I<$o>, I<$l>) = I<$IoL> -> entry (I<$i>)

rval: Get entry number I<$i>.

(I<$o>, I<$l>) == I<$IoL> -> entry (I<$i>, I<$o>, I<$l>)

lval: Set entry number I<$i> to (I<$o>, I<$l>). 
Returns this entry. 

=item length

(I<$l>) = I<$IoL> -> length (I<$i>)

rval: Get length of entry number I<$i>.

I<$l> == I<$IoL> -> length (I<$i>, I<$l>)

lval: Set length of entry number I<$i> to I<$l>. Returns I<$l>.

=item S<max  >

I<$num> = I<$IoL> -> max ()

Returns number of I<$IoL>'s entries.

=item S<new  >

I<$IoL> = new Iolist ([I<\@offset>, I<\@length>])

Iolist constructor. Returns an Iolist handle. Can be initialized with
references to corresponding offset and length lists.

=item offset

(I<$o>) = I<$IoL> -> offset (I<$i>)

rval: Get offset of entry number I<$i>.

I<$o> == I<$IoL> -> offset (I<$i>, I<$o>)

lval: Set offset of entry number I<$i> to I<$o>. Returns I<$o>.

=item push

C<1> == I<$IoL> -> push (I<$AnotherIolist>)

Appends all entries of I<$AnotherIolist> to I<$IoL>.

=item sumlen

I<$length> = I<$IoL> -> sumlen ()

Returns total length of I<$IoL>'s entries.

=back

=head1 SEE ALSO

L<OLE::Storage::Io>

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>

=cut

