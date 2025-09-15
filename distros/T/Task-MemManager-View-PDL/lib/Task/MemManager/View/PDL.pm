use strict;
use warnings;

package Task::MemManager::View::PDL;
$Task::MemManager::View::PDL::VERSION = '0.01';
use Config;
my $MAX_ADDR;

BEGIN {
    use constant DEBUG => $ENV{DEBUG} // 0;
    if (DEBUG) {
        use Carp;
    }
    if ( $Config{ptrsize} == 8 ) {
        $MAX_ADDR = 2**48 - 1;
    }
    elsif ( $Config{ptrsize} == 4 ) {
        $MAX_ADDR = 2**32 - 1;
    }
    else {
        die "Unsupported pointer size: $Config{ptrsize} "
          . "when initializing the package Task::MemManager::View::PDL\n";
    }
}

use PDL::LiteF;
use PDL::Core::Dev;
use Inline with => 'PDL';
use Inline ( C => 'DATA', );
Inline->init()
  ; ## prevents warning "One or more DATA sections were not processed by Inline"

# Hash of PDL types with names, type codes, and sizes
# from PDL::Types documentation and using GCC defaults
my %PDL_types = (
    sbyte     => [ 0,  1 ],
    byte      => [ 1,  1 ],
    short     => [ 2,  2 ],
    ushort    => [ 3,  2 ],
    long      => [ 4,  4 ],
    ulong     => [ 5,  4 ],
    indx      => [ 6,  4 ],
    ulonglong => [ 7,  8 ],
    longlong  => [ 8,  8 ],
    float     => [ 9,  4 ],
    double    => [ 10, 8 ],
    ldouble   => [ 11, 8 ],
    cfloat    => [ 12, 8 ],
    cdouble   => [ 13, 8 ],
    cldouble  => [ 14, 16 ],
);

# Do an update just in case
( $PDL_types{indx}[1], $PDL_types{ldouble}[1], $PDL_types{cldouble}[1] ) =
  get_PDL_types();

## now update those sizes using the sizeof operator

###############################################################################
# Usage       : $view =  $buffer->create_view($buffer_address, $buffer_size \%options);
# Purpose     : Create a PDL view of the specified type for the buffer
# Returns     : The created view (a PDL ndarray) or undef on failure
#               The view is created using the buffer's memory. 
# Parameters  : $buffer_address - address of the buffer's memory
#               $buffer_size    - size of the buffer's memory in bytes
#               \%options - hash reference with options for the view. The 
#               supported options are:
#                   pdl_type - the PDL type of the view. Default is 'byte'.
#                              See the %PDL_types hash for the supported types.
#                   dims     - array reference with the dimensions of the view.
#                              Default is a one-dimensional view with as many
#                              elements as fit in the buffer.
# Throws      : The function will die if an unknown PDL type is specified.
#               It will warn (but not die) if the buffer size is not a
#               multiple of the requested number of elements times the
#               element size.
# Comments    : Returns undef if the view creation fails for any reason (e.g.
#               stuff happening inside PDL).
#               Warnings will be generated if DEBUG is set to a non-zero value.

sub create_view {
    my ( $buffer_address, $buffer_size, $opts_ref ) = @_;
    my $pdl_type      = $opts_ref->{pdl_type} // 'byte';
    my $pdl_type_info = $PDL_types{$pdl_type};
    my $element_size  = $pdl_type_info->[1]
      or die "Unknown PDL type '$pdl_type'\n";
    my $dims_refs = $opts_ref->{dims}
      // [ int( $buffer_size / $element_size ) ];
    my $num_of_requested_elements = 1;
    $num_of_requested_elements *= $_ for @$dims_refs;

    if ( $buffer_size % ( $num_of_requested_elements * $element_size ) ) {
        warn "Buffer size $buffer_size is not a multiple of "
          . "the requested number of elements $num_of_requested_elements "
          . "times the element size $element_size\n";
        return undef;
    }
    my $ndarray = mkndarray( $buffer_address, $pdl_type_info->[0], $dims_refs );

    return $ndarray;
}


###############################################################################
# Usage       : $view_clone = $view->clone_view();
# Purpose     : Clone a PDL view
# Returns     : The cloned view
# Parameters  : $view - the PDL view to clone
# Throws      : Nothing
# Comments    : The cloned view will NOT share memory with the original view.
#               This is a deep copy.

sub clone_view {
    return $_[0]->copy;
}

1;


=head1 NAME

Task::MemManager::View::PDL - Create PDL views of Task::MemManager buffers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Task::MemManager::View::PDL; ## this will also import Task::MemManager

  my $length = 10;
  my $mem = Task::MemManager->new(
    $length, 1,
    {
        init_value => 40,
        death_stub => sub {
            my ($obj_ref) = @_;
            printf "\n ======> Killing 0x%8x <======\n", $obj_ref->{identifier};
        },
        #allocator => 'CMalloc',
    }
  );
  # Create a PDL view of a Task::MemManager buffer
  my $pdl_view =  $mem->create_view('PDL');

  # The same region as uint16_t
  my $pdl_intview =
  $mem->create_view( 'PDL', { pdl_type => 'short', view_name => 'PDL_short' } );

=head1 DESCRIPTION

This module provides an interface to create PDL views of Task::MemManager buffers.
It uses Inline::C to interface with the PDL C API. The created views will share
memory with the Task::MemManager buffers, so any changes made to the view B<may>
be reflected in the buffer and vice versa. The emphasis is on B<may> because
PDL may decide to copy the data to a new memory location for its own purposes,
e.g. during a transformation operation. In that case, the view will no longer
share memory with the original buffer. This opens up some interesting 
possibilities, e.g. using PDL to transform data in a buffer and then having
Task::MemManager manage the transformed data. Refer to the examples to see what
is possible.

=head1 METHODS

=head2 create_view

  Usage       : $view =  $buffer->create_view($buffer_address, $buffer_size \%options);
  Purpose     : Create a PDL view of the specified type for the buffer
  Returns     : The created view (a PDL ndarray) or undef on failure
                The view is created using the buffer's memory.
  Parameters  : $buffer_address - address of the buffer's memory
                $buffer_size    - size of the buffer's memory in bytes
                \%options - hash reference with options for the view. The
                supported options are:
                    pdl_type - the PDL type of the view. Default is 'byte'.
                               See the %PDL_types hash for the supported types.
                    dims     - array reference with the dimensions of the view.
                               Default is a one-dimensional view with as many
                               elements as fit in the buffer.
  Throws      : The function will die if an unknown PDL type is specified.
                It will warn (but not die) if the buffer size is not a
                multiple of the requested number of elements times the
                element size.
  Comments    : Returns undef if the view creation fails for any reason (e.g.
                stuff happening inside PDL).
                Warnings will be generated if DEBUG is set to a non-zero value.

The standard PDL types are supported during view creation. The size of these 
types is hardcoded in the %PDL_types hash, except for 'indx', 'ldouble', and
'cldouble', which are determined at runtime using the sizeof operator. The
sizes below are based on GCC in an x86_64 environment and may need to be 
adjusted for other compilers:

  my %PDL_types = (
      sbyte     => [ 0,  1 ],
      byte      => [ 1,  1 ],
      short     => [ 2,  2 ],
      ushort    => [ 3,  2 ],
      long      => [ 4,  4 ],
      ulong     => [ 5,  4 ],
      indx      => [ 6,  4 ],
      ulonglong => [ 7,  8 ],
      longlong  => [ 8,  8 ],
      float     => [ 9,  4 ],
      double    => [ 10, 8 ],
      ldouble   => [ 11, 8 ],
      cfloat    => [ 12, 8 ],
      cdouble   => [ 13, 8 ],
      cldouble  => [ 14, 16 ],
  );

The hash keys are the PDL type names and the values are [ type_code, size_in_bytes ].

=head2 clone_view

  Usage       : $view_clone = $view->clone_view();
  Purpose     : Clone a PDL view
  Returns     : The cloned view
  Parameters  : $view - the PDL view to clone
  Throws      : Nothing
  Comments    : The cloned view will NOT share memory with the original view.
                This is a deep copy.


=head1 EXAMPLES

Some of the examples are assumed to run sequentially, i.e. the same buffer
is used in multiple examples.

=head2 Example 1: Creating views 

  use Task::MemManager;
  use Task::MemManager::View::PDL;

  my $buffer = Task::MemManager->new_buffer(1024);
  my $view = $buffer->create_view(0, 1024, { pdl_type => 'float', dims => [ 256, 4 ] });

  if ($view) {
      print "Created PDL view successfully\n";
  } else {
      print "Failed to create PDL view\n";
  }

=head2 Example 2: Accessing and modifying data through the view

  use Task::MemManager;
  use Task::MemManager::View ;
  use PDL;
  use PDL::NiceSlice;

  my $length = 10;
  my $mem = Task::MemManager->new(
      $length, 1,
      {
          init_value => 40,
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "\n ======> Killing 0x%8x <======\n", $obj_ref->{identifier};
          },
      }
  );

  # allows to print hex values of a string
  sub print_hex_values {
      my ( $string, $bytes_per_line ) = @_;
      $bytes_per_line //= 8;    # Default to 8 bytes per line if not provided

      my @bytes =
        unpack( 'C*', $string );    # Unpack the string into a list of bytes

      for ( my $i = 0 ; $i < @bytes ; $i++ ) {
          printf( "%02X ", $bytes[$i] );   # Print each byte in hexadecimal format
          print "\n"
            if ( ( $i + 1 ) % $bytes_per_line == 0 )
            ;    # Print a newline after every $bytes_per_line bytes
      }
      print "\n"
        if ( @bytes % $bytes_per_line != 0 )
        ;        # Print a final newline if the last line wasn't complete
  }

  my $task_buffer = $mem->get_buffer();
  my $pdl_view =  $mem->create_view('PDL');

  say $pdl_view;
  print_hex_values($mem->extract_buffer_region(0,9),10);

Output should be (40 is 0x28 in hex):

  [40 40 40 40 40 40 40 40 40 40]
  28 28 28 28 28 28 28 28 28 28 

=head2 Example 3: Modifying the PDL view in place, modifies the buffer

This continues from Example 2.

  $pdl_view(0:4).=20;
  $pdl_view +=1;  # implied in place
  say $pdl_view->inplace->sqrt;
  print_hex_values($mem->extract_buffer_region(0,9),10);

Output should be:

  28 28 28 28 28 28 28 28 28 28 
  [4 4 4 4 4 6 6 6 6 6]

=head2 Example 4: Cloning a view

  say $mem->get_view('PDL_default');
  say "Clone the view and increment it by one";
  my $pdl_clone= $mem->clone_view('PDL_default');
  say "Get an uint16_t view";
  my $pdl_intview=$mem->create_view('PDL',{pdl_type=>'short',view_name=>'PDL_short'});

  say "Initial View : ",$pdl_view;
  say " Cloned View : ", $pdl_clone;
  say "  Int32 View : ",$pdl_intview;


Output should be:

  Clone the view and increment it by one
  Get an uint16_t view
  Initial View : [4 4 4 4 4 6 6 6 6 6]
  Cloned View : [4 4 4 4 4 6 6 6 6 6]
    Int32 View : [1028 1028 1540 1542 1542]


=head1 DIAGNOSTICS

If you set up the environment variable DEBUG to a non-zero value, then
a number of sanity checks will be performed, and the module will carp
with an (informative message ?) if something is wrong.

=head1 DEPENDENCIES

The module extends the C<Task::MemManager::View> module so this is definitely a
dependency. It (obviously) requires the C<PDL> (Perl Data Language) module to be
installed and the C<Inline::C> module to interface with the PDL C API.

=head1 TODO

Open to suggestions. One idea is to add Magic to the views to support
various operations triggered via accessing or modifying the view. For example,
one could support GPU memory mapping. 

=head1 SEE ALSO

=over 4

=item * L<https://metacpan.org/pod/Task::MemManager>

This module exports various internal perl methods that change the internal 
representation or state of a perl scalar. All of these work in-place, that is,
they modify their scalar argument. 

=item * L<https://metacpan.org/pod/Task::MemManager::View>

This module provides an interface to create views of Task::MemManager buffers
using various data processing libraries.

=item * L<https://metacpan.org/pod/Inline::C>

Inline::C is a module that allows you to write Perl subroutines in C. 

=item * L<https://perldoc.perl.org/perlguts> 

Introduction to the Perl API.

=item * L<https://perldoc.perl.org/perlapi>

Autogenerated documentation for the perl public API.

=back

=head1 AUTHOR

Christos Argyropoulos, C<< <chrisarg at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under the
MIT license. The full text of the license can be found in the LICENSE file
See L<https://en.wikipedia.org/wiki/MIT_License> for more information.

=cut

__DATA__

__C__

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


void get_PDL_types() {
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(sizeof (void *))));
  Inline_Stack_Push(sv_2mortal(newSViv(sizeof (long double))));
  Inline_Stack_Push(sv_2mortal(newSViv(sizeof (complex long double))));
  Inline_Stack_Done;
}

#define IsSVValidPtr(sv)  do { \
    if (!SvOK((sv))) { \
        croak("Pointer is not defined"); \
    } \
    if (!SvIOK((sv))) { \
        croak("Pointer does not contain an integer"); \
    } \
    IV value = SvIV((sv)); \
    if (value <= 0) { \
            croak("Pointer is negative or zero"); \
    } \
} while(0)

#define DeclTypedPtr(type, ptr,sv) type *ptr; \
                        ptr = (type *) SvIV((sv))

/*
    Demonstrates the infrastructure for wrapping Task::MemManager buffers in PDL
*/

// Start of material from the PDL::API documentation
void delete_mydata(pdl* pdl, int param) {
    pdl->data = 0;
}

typedef void (*DelMagic)(pdl *, int param);
static void default_magic(pdl *p, int pa) { p->data = 0; }

static pdl* pdl_wrap(void *data, int datatype, PDL_Indx dims[],
int ndims, DelMagic delete_magic, int delparam)
{
  pdl* p = PDL->pdlnew(); /* get the empty container */
  if (!p) return p;
  pdl_error err = PDL->setdims(p, dims, ndims);  /* set dims */
  if (err.error) { PDL->destroy(p); return NULL; }
  p->datatype = datatype;     /* and data type */
  p->data = data;             /* point it to your data */
  /* make sure the core doesn't meddle with your data */
  p->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  if (delete_magic != NULL)
    PDL->add_deletedata_magic(p, delete_magic, delparam);
  else
    PDL->add_deletedata_magic(p, default_magic, 0);
  return p;
}
// End of material straight from the PDL::API documentation

// modified from the PDL::API documentation
pdl *mkndarray(SV *buffer_of_taskmemmgr, int datatype, AV *dims) {
  IsSVValidPtr(buffer_of_taskmemmgr);
  size_t ndims = av_len(dims) + 1;


  pdl *p;
  PDL_Indx dimensions[ndims];
  for (int i = 0; i < ndims; i++) {
    SV **elem = av_fetch_simple(dims, i, 0); // perl 5.36 and above
    dimensions[i] = SvUV(*elem);
  }
  DeclTypedPtr(void, mydata, buffer_of_taskmemmgr);
  p = pdl_wrap(mydata, datatype, dimensions, ndims,
               delete_mydata, 0);
  return p;
}
