=encoding UTF-8

=head1 NAME

Photonic::Iterator

=head1 VERSION

version 0.016

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 SYNOPSYS

     use Photonic::Iterator qw(iterator nextval);
     sub makeiterator {
         my $a=shift;
         my $n=0;
         my $it = iterator {
              return $a->[$n++];
         };
         return $it;
     }
     sub makebiterator { #blessed version
         my $a=shift;
         my $n=0;
         my $it=Photonic::Iterator->new(sub {
              return $a->[$n++];
         });
         return $it;
     }
     my @a=(1..100);
     my $it=makeiterator(\@a);
     my $bit=makebiterator(\@a);
     while(my $x=nextval($it)){
        #do something with $x
     }
     while(my $x=$bit->nextval){
        #do something with $x
     }

=head1 DESCRIPTION

Facilitate the creation of iterators. Iterators are objects that
produce data items, one at a time, until depleted. They are
implemented as functions (closures) that have state (implemented as
lexical variables) to know which is the next item. The example above
creates an iterator for walking over the elements of an array
reference. The method or function nextval produces the next element if
available or undef when there is no more data. Used in Photonic to
iterate over Haydock states without caring whether they are stored in
an array or in an external file.

=head1 EXPORTABLE FUNCTIONS

=over 4

=item iterator

    my $i=iterator {...}

creates an iterator from the function {...}

=item new

   my $it=Photonic::Iterator->new(sub {...});

creates a blessed iterator from the function sub {...}

=item nextval

   my $x=nextval($i)
   my $x=$i->nextval

returns the next value from iterator $i. The second form works for
blessed iterators, so you don't have to import the function nextval.

=back

=cut

package Photonic::Iterator;
$Photonic::Iterator::VERSION='0.016';

use strict;
use warnings;

use base "Exporter";
our @EXPORT_OK=qw(iterator nextval);
our %EXPORT_TAGS=(all=>\@EXPORT_OK);

sub nextval ($) { $_[0]->(); }
sub iterator(&) { return $_[0] }
sub new(&) { return bless $_[1]=>$_[0] }
