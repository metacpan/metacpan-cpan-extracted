package Scalar::Classify;
#                                doom@kzsu.stanford.edu
#                                30 Jun 2015

=head1 NAME

Scalar::Classify - get type and class information for scalars

=head1 SYNOPSIS

   use Scalar::Classify qw( classify classify_pair );

   # determine the type (e.g. HASH for a hashref) and the object class (if any)
   my ( $type, $class ) = classify( $some_scalar );


  # warn if two args differ, supply default if one is undef
  my $default_value =
    classify_pair( $arg1, $arg2 );

  # Also get type and class; error out if two args differ
  my ( $default_value, $type, $class ) =
    classify_pair( $arg1, $arg2, { mismatch_policy => 'error' });

  # If a given ref was undef, replace it with a default value
  classify_pair( $arg1, $arg2, { also_qualify => 1 });

=head1 DESCRIPTION

Scalar::Classify provides a routine named "classify" that can be used
to examine a given argument to determine it's type and class (if any).

Here "type" means either the return from reftype (, or if it's a scalar,
a code indicating whether it's a string or a number, and "class"
it the object class, the way a reference has been blessed.

This module also provides the routine "classify_pair", which
looks at a pair of variables intended to be of the same type, and
if at least one of them is defined, uses that to get an
appropriate default value for that type.

=head2 MOTIVATION

Perl contains a built-in "ref" function, and has some useful
routines in the standard Scalar::Util library ('ref',
'looks_like_number') which can be used to examine the type of an
argument.  The classify routine provided here internally uses all
three of these, returning a two-values that describe the kind of
thing you're examining.

The immediate goal was to provide support routines for the
L<Data::Math> project.

=head2 EXPORT

None by default. Optionally:

=over

=cut

use 5.008;
use strict;
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;
use Scalar::Util qw( reftype looks_like_number );

our (@ISA, @EXPORT_OK, %EXPORT_TAGS, @EXPORT);
BEGIN {
 require Exporter;
 @ISA = qw(Exporter);
 %EXPORT_TAGS = ( 'all' => [
  qw(
     classify
     classify_pair
    ) ] );
 # The above allows   use Scalar::Classify ':all';

 @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
 @EXPORT = qw(  );
}

our $VERSION = '0.02';

=item classify

Example usage:

   my ( $type, $class ) = classify( $some_var );

Returns two pieces of information, the underlying "type", and the
"class" (if this is a reference blessed into a class).

The type is most often (but not limited to) one of the following:

   ARRAY
   HASH
   :NUMBER:
   :STRING:

Other possibilities are the other potential returns from L<ref>:

   CODE
   GLOB
   LVALUE
   FORMAT
   IO
   VSTRING
   Regexp

Internally, this uses the built-in function L<ref> and the library
functions L<reftype> and L<looks_like_number> (from L<Scalar::Util>).
The type is the return from "reftype" (e.g "ARRAY", "HASH")
except that in the case of a simple scalar the type is a code to
indicate whether it seems to be a number (":NUMBER:") or a string
(":STRING:").

Note: if the argument is undefined, the returned type is undef.

=cut

sub classify {
  my $arg = shift;

  # initialize $type to ref()
  my $type  = ref( $arg );           # '' if undef

  my $basetype = reftype( $arg ) ;   # undef if undef

  my $class;  # default undef
  # it's a blessed ref when ref() not same as reftype()
  if ( defined( $basetype ) && $type ne $basetype ) {
    $class   = $type;
    $type = $basetype;
  }

  if( defined $arg ) {
    # if not reference, we're handling a scalar
    if ( not( defined( $basetype ) ) ) {
      if( looks_like_number( $arg ) ) {
        $type = ':NUMBER:';
      } else {
        $type = ':STRING:';
      }
    }
  } else {
    $type = undef; # more perlish than an empty string
  }

  my @meta = ( $type, $class );
  return wantarray ? @meta : \@meta;
}

=item classify_pair

Examines a pair of arguments that are intended to be processed in
parallel and are expected to be of the same type:

If they're both defined, it checks that their types match.
If at least one is defined, it generates a default of the
same type by using the L<classify> method.  If both are
undef, this default is also undef.

In scalar context, it returns just the default value.

In list context, it returns the default plus the type and
the class (if it's a blessed reference).

An options hashref is accepted as a third argument, with
allowed options:

 o  mismatch_policy

    If argument types mismatch, the behavior is determined by
    the mismatch_policy option, defaulting to 'warn'.
    The other allowed values are 'error' or 'silent'.

 o  also_qualify

    If the "also_qualify" option is set to a true value, then
    the given arguments may be modified in place: if one is
    undef, it will be assigned the determined default.

Examples:

  my $default_value =
    classify_pair( $arg1, $arg2, { mismatch_policy => 'error' });

  my ( $default_value, $type, $class ) =
    classify_pair( $arg1, $arg2, { mismatch_policy => 'error' });

  classify_pair( $arg1, $arg2, { also_qualify => 1 });

Note the slightly unusual polymorphic behavior: in scalar
context returns *just* the default_value, in list context,
returns up to three values, the default, the type and the class.


=cut

sub classify_pair {
  my $subname = ( caller(0) )[3];
  my $opt  = $_[2];

  my $policy     = $opt->{ mismatch_policy } || 'warn';
  my $do_qualify = $opt->{ also_qualify }    || 0;

  my $meta1 = classify( $_[0] );
  my $meta2 = classify( $_[1] );

  # handle mismatched types
  if ( $policy ne 'silent' ) {
    no warnings 'uninitialized';
    if ( defined( $_[0] ) && defined( $_[1] ) ) {
      unless( $meta1->[0] eq $meta2->[0] ) {
        croak "mismatched types: $meta1->[0] and $meta2->[0]"  if $policy eq 'error';
        carp  "mismatched types: $meta1->[0] and $meta2->[0]"  if $policy eq 'warn';
      }
      unless( $meta1->[1] eq $meta2->[1] ) {
        croak "mismatched classes: $meta1->[1] and $meta2->[1]"  if $policy eq 'error';
        carp  "mismatched classes: $meta1->[1] and $meta2->[1]"  if $policy eq 'warn';
      }
    }
  }

  my ( $defval, $class, $type );
  { no warnings 'uninitialized';
    $type = $meta1->[0] || $meta2->[0];
  }
  unless( defined( $type ) ) {
    return wantarray ? ( undef, undef, undef ) : undef;
  }

  if ( $type eq ':NUMBER:' ) {
    $defval = 0;
  } elsif ( $type eq ':STRING:' ) {
    $defval = '';
  } else {
    { no warnings 'uninitialized';
      $class = $meta1->[1] || $meta2->[1];
    }
    if ( $type eq 'ARRAY' ) {
      $defval =  [];
    } elsif ( $type eq 'HASH' ) {
      $defval = {};
    } elsif ( $type eq 'SCALAR' ) {
      my $var;
      $defval = \$var;
    } else { # handle the useless cases: warn and get out of here
      carp "$subname can't do anything useful with ref type $type";
    }
  }

  if( defined( $defval ) && defined( $class ) ) {
    bless( $defval, $class );
  }

  if( $do_qualify ) {
    $_[0] = $defval unless defined( $_[0] );
    $_[1] = $defval unless defined( $_[1] );
  }

  return wantarray ? ( $defval, $type, $class ) : $defval;
}


1;

=back

=head1 SEE ALSO

L<Params::Classify>

This covers the argument checking case, where you want to verify
that something of the correct type was passed.  The perl5-porters
are interested in adding core support for this module: it's fast
and likely to get faster.

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut
