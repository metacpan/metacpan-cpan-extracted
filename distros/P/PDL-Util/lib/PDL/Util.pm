package PDL::Util;
{
  $PDL::Util::VERSION = '0.010';
}

use strict;
use warnings;

=head1 NAME

PDL::Util

=head1 SYNOPSIS

 use PDL;
 use PDL::Util 'export2d';

 my $pdl = rvals(6,4);

 open my $fh, '>', 'file.dat';
 export2d($pdl, $fh);

=head1 DESCRIPTION

Convenient utility functions/methods for use with PDL.

=cut

use PDL;
use Scalar::Util qw/openhandle blessed/;

use Carp;

use parent 'Exporter';
our %EXPORT_TAGS = (
  functions => [qw/add_pdl_method/],
  methods   => [qw/unroll export2d/],
);

our @EXPORT_OK;
push @EXPORT_OK, @$_ for values %EXPORT_TAGS;

$EXPORT_TAGS{'all'} = \@EXPORT_OK;

=head1 IMPORT

 use PDL:Util 'export2d', ['unroll'] 
 # imports 'export2d', adds 'unroll' as a PDL method

L<PDL::Util> does not export anything by default. A list of symbols may be imported as usual. The exportable symbols come in two types, functions (tag C<:function>) and methods (tag C<:methods>). The word I<methods> here is a strange word. When importing symbols one does not import methods. In this context a 'method' is a function which expects a piddle as its first argument. However, there is a reason ...

If an array reference or hash reference is passed as the last item in the import list, the reference will be passed to the L<add_pdl_method> function below, in which case these functions are imported into the C<PDL> namespace and may be used as method calls. Note, when doing this for symbols from the L<PDL::Util> module, only those listed in the C<:methods> tag may be added as a method (this is the origin of the confusing terminology). Read about the L<add_pdl_method> function carefully before using this functionality.

=cut

sub import {
  my $package = shift;
  return 1 unless @_;

  my $ref_last = ref $_[-1] || '';
  my $method_spec = ( grep {$ref_last eq $_} qw/HASH ARRAY/ ) ? pop : 0;

  add_pdl_method($method_spec) if ($method_spec);

  __PACKAGE__->export_to_level(1, $package, @_) if @_;
}

=head1 TAG :functions

=head2 add_pdl_method

 add_pdl_method({'my_method' => sub { my $self = shift; ... });
 $pdl->my_method 	# calls the anonymous sub on $pdl

 add_pdl_method(['export2d']);
 $pdl->export2d()	# calls 'export2d' on $pdl

 add_pdl_method({'my_unroll' => 'unroll'});
 $pdl->my_unroll()	# calls 'unroll' method on $pdl

C<add_pdl_method> pushes subroutines into the PDL namespace. It takes a single argument, a reference either an array or hash. The keys of the hash reference are the method name that will be used in the call (e.g. C<< $pdl->method_name >>, the values are either a reference to a subroutine or a string containing the name of a method provided by L<PDL::Util>. The array reference form can only take names of C<PDL::Util> methods.

When adding your own subroutine as a L<PDL> method, be aware that the first argument passed will be a self (i.e. C<$self>) reference, in the normal Perl OO manner.

=cut

sub add_pdl_method {
  my $spec = shift;
  croak 'make_pdl_method expects a hash or array reference as its argument' 
    unless grep {ref $spec eq $_} qw/HASH ARRAY/;

  if (ref $spec eq 'ARRAY') {
    $spec = { map { $_ => $_ } @$spec };
  } 

  foreach my $method (keys %$spec) {
    my $function = $spec->{$method};

    # Check to see if PDL already has a method by the same name
    carp <<MESSAGE if PDL->can($method);
PDL already provides a method named '$method', read the PDL::Util documentation to learn to avoid this conflict.
MESSAGE

    unless (ref $function && ref $function eq 'CODE') {
      if ( 1 == grep { $_ eq $function } @{ $EXPORT_TAGS{'methods'} } ) {
        no strict 'refs';
        $function = \&{ 'PDL::Util::' . $function };
      } else {
        croak "value for $method must be either a code reference or the name of one of PDL::Util's exportable functions";
      }
    }
    
    no strict 'refs';
    *{'PDL::'.$method} = $function; 
  }
}

=head1 TAG :methods

Again, the I<functions> provided in the method tag are not automatically methods. They simply are function which are called with a PDL object (piddle) as their first argument. This function ARE available to be imported into the PDL namespace using the L<add_pdl_method> function describe above.

=head2 unroll

 $AoA = unroll($pdl);
   -- or --
 $AoA = $pdl->unroll();

L<PDL> provides a function for constructing a PDL object (piddle) from a Perl nested array, however it does not provide a tool to convert a piddle to a nested array structure. The closest function is the C<list> function, which returns the elements of the piddle as a list, i.e. a 1D flattened array. C<unroll> converts piddles to a native Perl data structure; it can be thought of as the logical inverse of the C<pdl> function in that C<pdl(unroll($pdl))> should return the original data structure, although bad values and data types may be changed. 

When called as a function C<unroll> takes a single argument (the piddle to unroll). When used as a method it takes no arguments. It returns a reference to an array containing the Perl equivalent data structure. 

=cut

sub unroll {
 my $pdl = shift;

 if ( blessed($pdl) and $pdl->isa('PDL') ) {
   if ($pdl->ndims > 1) {
     return [ map {unroll($_)} dog $pdl ];
   } else {
     return [list $pdl];
   }
 } else {
   croak "Attempted to unroll a non-PDL object";
   #return $pdl;
 }

}

=head2 export2d

 export2d($pdl, $fh, ',');
   -- or --
 $pdl->export2d($fh, ',');

C<export2d> may take up to 2 optional arguments (neglecting the object reference), a lexical filehandle (or globref, e.g. C<\*FILE>) to write to, and a string containing a column separator. The defaults, if arguments are not given are to print to STDOUT and use a single space as the column separator. The order does not matter, the method will determine whether an argument refers to a file or not. This is done so that one may call either

 $pdl->export2d($fh);
 $pdl->export2d(',');

and it will do what you mean. Unfortunately this means that unlike C<wcols> one cannot use a filename rather than a filehandle; C<export2d> would interpret the string as the column separator!

The method returns the number of columns that were written.

=cut

sub export2d {
  my ($pdl, $fh, $sep);
  $pdl = shift;
  unless ( blessed($pdl) and $pdl->isa('PDL') ) {
    carp "cannot call export2d without a piddle input";
    return 0;
  }
  unless ($pdl->ndims == 2) {
    carp "export2d may only be called on a 2D piddle";
    return 0;
  }

  # Parse additional input parameters
  while (@_) {
    my $param = shift;
    if (openhandle($param)) {
      $fh = $param;
    } else {
      $sep = $param;
    }
  }

  # Extract columns from piddle
  my @params = map {$pdl->slice("($_),")} (0..$pdl->dim(0)-1);
  my $num_cols = @params;

  # Push additional parameters for wcols
  push @params, $fh if (defined $fh); 
  push @params, {Colsep => $sep} if (defined $sep);

  # Write columns
  wcols @params;

  return $num_cols;
}

1;

=head1 SEE ALSO

L<PDL>
L<Website|http://pdl.perl.org>

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/PDL-Util>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

