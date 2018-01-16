package PDL::Algorithm::Center::Types;
use latest;


# ABSTRACT: Type::Tiny types for PDL::Algorithm::Center

use strict;
use warnings;

our $VERSION = '0.07';

use Types::Standard -types;
use Types::PDL -types;

use Type::Utils -all;
use Type::Library -base,
  -declare =>
  qw[
        Piddle_ne
        Piddle0D_ne
        Piddle1D_ne
        Piddle2D_ne
        Piddle_min1D_ne
        Coords
        Center
        ArrayOfPiddle1D

        Piddle1DFromPiddle0D
        Piddle2DFromPiddle1D
        Piddle2DFromArrayOfPiddle1D
   ];

BEGIN { extends 'Types::PDL' }

declare Piddle_ne,
  as Piddle[ null => 0, empty => 0 ];

Piddle_ne->coercion->add_type_coercions
  (
   map @{$_->type_coercion_map}, PiddleFromAny
   );

declare Piddle0D_ne,
  as Piddle0D[ null => 0 ];

declare Piddle1D_ne,
  as Piddle1D[ null => 0, empty => 0 ];

declare Piddle2D_ne,
  as Piddle2D[ null => 0, empty => 0 ];

coerce Piddle0D_ne,
  from Num,
  q'PDL::Core::topdl( $_ )';

coerce Piddle1D_ne,
  from ArrayRef[Num],
  q'PDL::Core::topdl( $_ )',

  from Piddle0D_ne->coercibles,
  via { to_Piddle0D_ne($_)->dummy(0) };

coerce Piddle2D_ne,
  from Piddle1D_ne->coercibles,
  via { to_Piddle1D_ne($_)->dummy(0) },

  from Tuple[ ArrayRef[Num] ],
  q'PDL::Core::topdl( $_ )';

declare Piddle_min1D_ne,
  as Piddle[ ndims_min => 1, null => 0, empty => 0 ];

coerce Piddle_min1D_ne,
  from Piddle1D_ne->coercibles,
  via { to_Piddle1D_ne( $_ ) };

Piddle_min1D_ne->coercion->add_type_coercions
  ( map @{ $_->type_coercion_map }, PiddleFromAny );

declare_coercion Piddle1DFromPiddle0D,
  to_type Piddle1D_ne,
  from Piddle0D_ne->coercibles,
  via { to_Piddle0D_ne($_)->dummy(0) };

declare_coercion Piddle2DFromPiddle1D,
  to_type Piddle2D_ne,
  from Piddle1D_ne->coercibles,
  via { to_Piddle1D_ne($_)->dummy(0) };

declare ArrayOfPiddle1D,
  as ArrayRef[Piddle1D_ne],
  coercion => 1;

declare_coercion Piddle2DFromArrayOfPiddle1D,
  to_type Piddle2D_ne,
  from ArrayOfPiddle1D->coercibles,
  via {
      my $tmp = to_ArrayOfPiddle1D( $_ );
      my $nelem = $tmp->[0]->nelem;

      return $_ if
        grep { $_->nelem != $nelem } @{ $tmp };

      return PDL::glue( 0, map { $_->dummy( 0 ) } @{ $tmp } );
  };


declare Center,
  as Piddle1D_ne,
  coercion => 1;
Center->coercion->add_type_coercions
  (
   map @{$_->type_coercion_map}, Piddle1DFromPiddle0D,
   );


declare Coords,
  as Piddle2D_ne,
  coercion => 1;
Coords->coercion->add_type_coercions
  (
   map @{$_->type_coercion_map}, Piddle2DFromArrayOfPiddle1D,
   );


1;
