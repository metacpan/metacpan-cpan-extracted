# VERSION 0.008_000
# NEED FIX, CORRELATION #rp002: bug, possibly in Inline, causing inability to declare 3rd count_FOO argument to T_PACKEDARRAY; temporarily solved here
# DEV NOTE: all comments must be on their own line or typemapping will silently fail and typemapped subroutines will fail to bind from Inline to Perl
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures

# SCALAR TYPES
boolean             T_PACKED
nonsigned_integer   T_PACKED
integer             T_PACKED
number              T_PACKED
character           T_PACKED
string              T_PACKED

# ARRAY TYPES
arrayref_integer    T_PACKED
arrayref_number     T_PACKED
arrayref_string     T_PACKED
arrayref_arrayref_integer   T_PACKED
arrayref_arrayref_number    T_PACKED
arrayref_arrayref_string    T_PACKED

# HASH TYPES
hashref_integer     T_PACKED
hashref_number      T_PACKED
hashref_string      T_PACKED
hashref_arrayref_integer    T_PACKED
hashref_arrayref_number     T_PACKED
hashref_arrayref_string     T_PACKED
hashref_hashref_arrayref_integer    T_PACKED
hashref_hashref_arrayref_number     T_PACKED
hashref_hashref_arrayref_string     T_PACKED

# GMP TYPES
gmp_integer_retval  T_PACKED

# GSL TYPES
gsl_matrix*       T_PACKED

# CORRELATION #pp04: attempt to manually define pack/unpack for object return type
# USER TYPES
#PhysicsPerl__Astro__Body T_PACKED

