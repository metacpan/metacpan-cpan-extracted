package Task::MemManager;
$Task::MemManager::VERSION = '0.02';
use strict;
use warnings;

use Carp;
use Inline ( C => 'DATA', );
use Module::Find;
use Module::Runtime 'use_module';
use Scalar::Util;

Inline->init()
  ; ## prevents warning "One or more DATA sections were not processed by Inline"
  
*ident = \&Scalar::Util::refaddr
  ;  # alias of refaddr in Ch. 15 & 16 of "Perl Best Practices" (O'Reilly, 2005)

# ABSTRACT: A memory allocator for low level code in Perl.

# Properties of the Memory Manager class (inside out object attributes)
my %buffer;             # Memory buffer
my %size_of_buffer;     # Size of the buffer
my %size_of_element;    # Size of each element in the buffer
my %num_of_elements;    # Number of elements in the buffer
my %delayed_gc_for;     # Objects with delayed garbage collection
my %death_stub;         # Function to call upon object destruction
my %allocator_of;       # Allocator used to allocate the buffer

# Find implemented memory allocators under this namespace
my @alloc_modules = findsubmod 'Task::MemManager';

# Load allocators and store their functions
my %allocator_function;
my @allocator_functions = qw(malloc free get_buffer_address);
TEST_MODULE: foreach my $module_name (@alloc_modules) {
    ( my $key = $module_name ) =~ s/Task::MemManager:://;
    my $alloc_module = use_module($module_name);    # Load the module
    foreach my $function (@allocator_functions) {
        if ( my $code_ref = $alloc_module->can($function) ) {
            $allocator_function{$key}{$function} = $code_ref;
        }
        else {
            carp "Module $alloc_module does not have a $function method\n"
              . "This module will not be used for memory allocation";
            next TEST_MODULE;
        }
    }
}

###############################################################################
# Usage       : my $buffer = Task::MemManager->new(10, 1, {allocator =>
#                'PerlAlloc'});
# Purpose     : Allocates a buffer using the specified allocator
# Returns     : A reference to the buffer
# Parameters  : $num_of_items     - Number of items in the buffer
#               $size_of_each_item - Size of each item in the buffer
#               $opts_ref         - Reference to a hash of options. These are:
#                allocator      - Name of the allocator to use
#                delayed_gc     - Should garbage collection be delayed ?
#                init_value     - Value to initialize the buffer with
#                death_stub     - Function to call upon object destruction
#                  it will receive the object's properties and identifier
#                  as a hash reference if it is defined
# Throws      : Croaks if the buffer allocation fails
# Comments    : Default allocator is PerlAlloc, which uses Perl's string
#                functions,
#               Default init_value is undef ('zero' zeroes out memory, any
#                 byte value will initialize memory with that value)
#               Default delayed_gc is 0 (garbage collection is immediate)
# See Also    : n/a
sub new {
    my ( $self, $num_of_items, $size_of_each_item, $opts_ref ) = @_;

    # exit if the number of items or the number of bytes per item is not defined
    croak "Number of items and size of each item must be defined"
      unless defined $num_of_items and defined $size_of_each_item;

    # Various defaults here
    my $init_value     = $opts_ref->{init_value};
    my $delayed_gc     = $opts_ref->{delayed_gc} // 0;
    my $death_stub     = $opts_ref->{death_stub};
    my $allocator_name = $opts_ref->{allocator} // 'PerlAlloc';
    unless ( exists $allocator_function{$allocator_name} ) {
        croak "Allocator $allocator_name is not implemented";
    }
    my $allocator  = $allocator_function{$allocator_name}{malloc};
    my $new_buffer = bless do {
        my $anon_scalar =
          $allocator->( $num_of_items, $size_of_each_item, $init_value );
    }, $self;
    unless ($new_buffer) {
        croak "Failed to allocate buffer using $allocator_name";
    }
    my $buffer_identifier = ident $new_buffer;

    # store the attributes of the buffer
    $buffer{$buffer_identifier} =
      $allocator_function{$allocator_name}{get_buffer_address}
      ->( ${$new_buffer} )
      or croak "Failed to get buffer address";
    $size_of_buffer{$buffer_identifier}  = $num_of_items * $size_of_each_item;
    $size_of_element{$buffer_identifier} = $size_of_each_item;
    $num_of_elements{$buffer_identifier} = $num_of_items;
    $allocator_of{$buffer_identifier}    = $allocator_name;

    if ($delayed_gc) {
        $delayed_gc_for{$buffer_identifier} = $new_buffer;
    }
    if ($death_stub) {
        $death_stub{$buffer_identifier} = $death_stub;
    }
    return $new_buffer;
}

sub DESTROY {
    my ($self) = @_;
    my $identifier = ident $self;

    # Call the death stub and delete the property if it exists
    if ( exists $death_stub{$identifier} ) {
        $death_stub{$identifier}->(
            {
                buffer_address  => $buffer{$identifier},
                buffer_size     => $size_of_buffer{$identifier},
                element_size    => $size_of_element{$identifier},
                num_of_elements => $num_of_elements{$identifier},
                identifier      => $identifier
            }
        );
        delete $death_stub{$identifier};
    }

    # Free the buffer and delete the properties
    $allocator_function{ $allocator_of{$identifier} }{free}
      ->( $buffer{$identifier} );
    delete $allocator_of{$identifier};
    delete $buffer{$identifier};
    delete $size_of_buffer{$identifier};
    delete $size_of_element{$identifier};
    delete $num_of_elements{$identifier};

}
###############################################################################
# Usage       : Task::MemManager->extract_buffer_region(pos_start, pos_end);
#               Task::MemManager->extract_buffer_region(pos_start);
# Purpose     : Extract a region of the buffer
# Returns     : A Perl string (null terminated) containing the region
# Parameters  : $pos_start - The starting position of the region
#               $pos_end   - The ending position of the region
# Throws      : n/a
# Comments    : Returns undef if attempt to overrun buffer, or
#                if pos_start > pos_end,
#               if pos_end is missing, then it will be set to the end of the
#               buffer,
#               if pos_start is missing, then it will be set to the start of
#               the buffer,
# See Also    : n/a

sub extract_buffer_region {
    my ( $self, $pos_start, $pos_end ) = @_;
    my $buffer_identifier = ident $self;
    my $buffer_size       = $size_of_buffer{$buffer_identifier};
    $pos_start = $pos_start // 0;
    $pos_end   = $pos_end   // $buffer_size - 1;
    return _extact_buffer_region( $buffer{$buffer_identifier},
        $pos_start, $pos_end, $buffer_size );
}

###############################################################################
# Usage       : Task::MemManager->delayed_gc();
# Purpose     : Perform garbage collection on all objects that have delayed GC
# Returns     : The memory address of the buffer as an unsigned integer
# Parameters  : n/a
# Throws      : n/a
# Comments    : None

sub get_buffer {
    my ($self) = @_;
    return $buffer{ ident $self };
}

###############################################################################
# Usage       : Task::MemManager->get_buffer_size();
# Purpose     : Returns the size of the buffer
# Returns     : The size of the buffer in bytes
# Parameters  : n/a
# Throws      : n/a
# Comments    : None

sub get_buffer_size {
    my ($self) = @_;
    return $size_of_buffer{ ident $self };
}

###############################################################################
# Usage       : Task::MemManager->get_element_size();
# Purpose     : Returns the size of each element in the buffer
# Returns     : The size of each element in bytes
# Parameters  : n/a
# Throws      : n/a
# Comments    : None

sub get_element_size {
    my ($self) = @_;
    return $size_of_element{ ident $self };
}

###############################################################################
# Usage       : Task::MemManager->get_num_of_elements();
# Purpose     : Returns the number of elements in the buffer
# Returns     : The number of elements in the buffer
# Parameters  : n/a
# Throws      : n/a
# Comments    : None

sub get_num_of_elements {
    my ($self) = @_;
    return $num_of_elements{ ident $self };
}

###############################################################################
# Usage       : Task::MemManager->delayed_gc();
# Purpose     : Obtain a list of objects that have delayed garbage collection
# Returns     : A reference to an array of objects with delayed GC
# Parameters  : n/a
# Throws      : n/a
# Comments    : None

sub get_delayed_gc_objects {
    my @delayed_gc_objects = keys %delayed_gc_for;
    return \@delayed_gc_objects;
}

1;

=head1 NAME

Task::MemManager - A memory allocated and manager for low level code in Perl.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Task::MemManager;

  my $mem_manager = Task::MemManager->new(10, 1, { allocator => 'PerlAlloc' });

  my $buffer = $mem_manager->get_buffer();
  my $buffer_size = $mem_manager->get_buffer_size();
  my $element_size = $mem_manager->get_element_size();
  my $num_of_elements = $mem_manager->get_num_of_elements();

  my $region = $mem_manager->extract_buffer_region($pos_start, $pos_end);

  my $delayed_gc_objects = $mem_manager->get_delayed_gc_objects();



=head1 DESCRIPTION

Task::MemManager is a memory allocator and manager designed for low level code in Perl. 
It provides functionalities to allocate, manage, and manipulate memory buffers.

=head1 METHODS

=head2 new

  Purpose     : Allocates a buffer using a specified allocator.
  Returns     : A reference to the buffer.
  Parameters  : 
    - $num_of_items: Number of items in the buffer.
    - $size_of_each_item: Size of each item in the buffer.
    - \%opts: Reference to a hash of options. These are:
      - allocator: Name of the allocator to use.
      - delayed_gc: Should garbage collection be delayed?
      - init_value: Value to initialize the buffer with (byte, non UTF!).
      - death_stub: Function to call upon object destruction (if any).
  Throws      : Croaks if the buffer allocation fails.
  Comments    : Default allocator is PerlAlloc, which uses Perl's string functions.
                Default init_value is undef ('zero' zeroes out memory, 
                any other byte value will initialize memory with that value).
                Default delayed_gc is 0 (garbage collection is immediate).

=head2 extract_buffer_region

  Usage       : my $region = Task::MemManager->extract_buffer_region($pos_start, $pos_end);
  Purpose     : Extracts a region of the buffer.
  Returns     : A Perl string (null terminated) containing the region.
  Parameters  : 
    - $pos_start: The starting position of the region.
    - $pos_end: The ending position of the region.
  Throws      : n/a
  Comments    : Returns undef if attempt to overrun buffer, or if $pos_start > $pos_end.

=head2 get_buffer

  Usage       : my $buffer = Task::MemManager->get_buffer();
  Purpose     : Returns the memory address of the buffer.
  Returns     : The memory address of the buffer as an unsigned integer.
  Parameters  : n/a
  Throws      : n/a
  Comments    : None.

=head2 get_buffer_size

  Usage       : my $buffer_size = Task::MemManager->get_buffer_size();
  Purpose     : Returns the size of the buffer.
  Returns     : The size of the buffer in bytes.
  Parameters  : n/a
  Throws      : n/a
  Comments    : None.

=head2 get_element_size

  Usage       : my $element_size = Task::MemManager->get_element_size();
  Purpose     : Returns the size of each element in the buffer.
  Returns     : The size of each element in bytes.
  Parameters  : n/a
  Throws      : n/a
  Comments    : None.

=head2 get_num_of_elements

  Usage       : my $num_of_elements = Task::MemManager->get_num_of_elements();
  Purpose     : Returns the number of elements in the buffer.
  Returns     : The number of elements in the buffer.
  Parameters  : n/a
  Throws      : n/a
  Comments    : None.

=head2 get_delayed_gc_objects

  Usage       : my $delayed_gc_objects = Task::MemManager->get_delayed_gc_objects();
  Purpose     : Obtains a list of objects that have delayed garbage collection.
  Returns     : A reference to an array of objects with delayed GC.
  Parameters  : n/a
  Throws      : n/a
  Comments    : None.

=head1 EXAMPLES

We will illustrate the use of these methods with multiple examples. These will
cover issues like the allocation of memory, the extraction of regions from the
buffer, constant (to the eyes of Perl) memory allocation, delayed garbage
collection, and the use of a death stub, which is a function that is called
upon object destruction and may be used to perform e.g. logging or cleanup , 
operations other than freeing the memory buffer itself. 
The examples are best run sequentially in a single Perl script.

=head2 Example 1: Allocating buffers and killing them 

  use Task::MemManager;
  ## uses the default allocator PerlAlloc
  my $memdeath = Task::MemManager->new(
      40, 1,
      {
          init_value => 'zero',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
      }
  );

  my $mem = Task::MemManager->new(
      20, 1,
      {
          init_value => 'A',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
          allocator => 'CMalloc',
      }
  );
  printf( "%10s object is %s\n", ' mem', $mem );
  $mem = Task::MemManager->new(
    20, 1,
    {
        init_value => 'A',
        death_stub => sub {
            my ($obj_ref) = @_;
            printf "Killing 0x%8x \n", $obj_ref->{identifier};
        },
        allocator => 'CMalloc',
    }
  );

Print the buffer objects

  printf( "%10s object is %s\n", ' memdeath', $memdeath );
  printf( "%10s object is %s\n", ' mem', $mem );

If you would like to kill a buffer immediately, you can undefine it:

  undef $memdeath;
 
Attempting to under (or in general modify a constant or a Readonly)
memory buffer will kill the script. Note that these buffers can be
modified outside of Perl (including the Perl API) but not inside
the main Perl script. Such buffers are useful for keeping a constant
(in space) buffer throughout the lifetime of the script. Attempt
to modify them from within Perl, will kill the script at *runtime*
uncovering the modification attempt.

  use Const::Fast; ## may also use Readonly mutatis mutandis
  const my $mem_cp2 => Task::MemManager->new(
      20, 1,
      {
          init_value => 'D',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
          allocator => 'CMalloc',
      }
  );
  undef $mem_cp2;  # This will kill the script


=head2 Example 2: Extracting and inspecting a region from the buffer

First we will define a subroutine that will print the extracted region
in a nicely formated hexadecimal format.

  sub print_hex_values {
      my ( $string, $bytes_per_line ) = @_;
      $bytes_per_line //= 8;    # Default to 8 bytes per line if not provided

      my @bytes = unpack( 'C*', $string );    # Unpack the string into a list of bytes

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

Now let's extract the region and print it

  my $region = $mem->extract_buffer_region(5, 10);
  print_hex_values( $region, 8 );

=head2 Example 3: Shallow copying defers buffer deallocation

Making a shallow copy of the buffer:

  my $mem_cp = $mem;
  printf( "%10s object is %s\n", ' mem_cp', $mem_cp );
  printf "Buffer %10s with buffer address %s\n", 
    'Alpha', $mem->get_buffer();
  printf "Buffer %10s with buffer address %s\n", 
    'Alpha_copy', $mem_cp->get_buffer();

Killing the original buffer in Perl. Trying to access it after death 
will lead to an error (but we intercept it in the code below)

  undef $mem;
  say "mem : ", ( $mem ? $mem->get_buffer() : "does not exist anymore" );

The shallow copy continues to exist, and so does the buffer region:

  printf "Buffer %10s with buffer address %s\n", 
    'Alpha_copy', $mem_cp->get_buffer();
  print_hex_values( $mem_cp->extract_buffer_region, 10 );

=head2 Example 4: Object modification and object destruction

Attempting to modify an existing buffer object, e.g. by reassiging it to 
a new buffer object, will instantly free the old memory buffer, and allocate
a new buffer with new contents (this Example continues at the end of Example 3)

  $mem_cp = Task::MemManager->new(
      20, 1,
      {
          init_value => 'D',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
          allocator => 'CMalloc',
      }
  );
  printf( "%10s object is %s\n", ' mem_cp', $mem_cp );
  printf "Buffer %10s with buffer address %s\n", 
    'Alpha_copy after modification', $mem_cp->get_buffer();
  print_hex_values( $mem_cp->extract_buffer_region, 10 );

=head2 Example 5: Fine control over garbage collection

Delayed garbage collection is useful when you want to keep a buffer alive
for a while after it goes out of scope. This is useful when you want to
transfer ownership of the memory space to an interfacing code (e.g. C code),
and don't want Perl to free the memory buffer (e.g when a lexical variable
is reassigned to a new buffer object in a loop).  
In this example we will create two buffers, one without and one with delayed
garbage collection and will track when they die relative to the end of the
script. This example is entirely self-contained.

  use Task::MemManager;
  use strict;
  use warnings;

  $mem_cp = Task::MemManager->new(
      20, 1,
      {
          init_value => 'D',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
          allocator => 'PerlAlloc',
      }
  );
  $mem_cp2 = Task::MemManager->new(
      20, 1,
      {
          init_value => 'D',
          death_stub => sub {
              my ($obj_ref) = @_;
              printf "Killing 0x%8x \n", $obj_ref->{identifier};
          },
          delayed_gc => 1,
          allocator => 'CMalloc',
      }
  );

List the objects with delayed garbage collection

  my $delayed_gc_objects = Task::MemManager->get_delayed_gc_objects();
  printf "Objects with delayed GC : " 
    . ("0x%8x " x @$delayed_gc_objects) 
    . "\n", @$delayed_gc_objects;

Time the precise moment of death:

  say "Undefining an object with delayed GC does not kill it!";
  undef $mem_cp2;
  say "End of the program - see how Perl's destroying all "
    . "delayed GC objects along with the rest of the objects";


=head1 DIAGNOSTICS

There are no diagnostics that one can use. The module will croak if the
allocation fails, so you don't have to worry about error handling. 

=head1 DEPENDENCIES

The module depends on the C<Inline::C> module to access the memory buffer 
of the Perl scalar using the PerlAPI. In addition it depends implicitly
on all the dependencies of the memory allocators it uses

=head1 TODO

Open to suggestions. A few foolish ideas of my own include: adding further 
allocators and providing facilities that will *trigger* the delayed garbage 
collection for a specific object, at specific time points in a script 
(emulating for example Go's garbage collector).

=head1 SEE ALSO

=over 4


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

This software is copyright (c) 2024 by Christos Argyropoulos.

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

/**
 * @brief Copies a region of a buffer to a new buffer.
 *
 * @usage SV *buffer = _extact_buffer_region(buffer, pos_start, pos_end, buffer_size);
 *
 * @param buffer The buffer to extract the region from.
 * @param pos_start The starting position of the region.
 * @param pos_end The ending position of the region.
 * @param buffer_size The size of the buffer.
 *
 * @return A Perl scalar (nul terminated string) containing the region.
 *
 * @throws n/a
 *
 * @comments Returns undef if attempt to overrun buffer, assumes zero based indexing into the buffer.
 *
 * @todo Reverse the buffer if pos_start > pos_end.
 */

SV *_extact_buffer_region(size_t buffer, size_t pos_start, size_t pos_end,
                          size_t buffer_size) {

    // attempt to overrun buffer                      
    if (pos_end >= buffer_size) {
            return &PL_sv_undef;
    }
    // can't reverse the buffer (yet)
    if(pos_start > pos_end) {
        return &PL_sv_undef;
    }

    void*  buffer_ptr = (void *)(uintptr_t)buffer; 
    size_t region_size = pos_end - pos_start +1;
    buffer_ptr += pos_start;
    SV* new_buffer = newSV(0); // zero buffer

    // copy the region using Perl's API macros (Newx, Copy, sv_usepvn_flags)
    char *new_buffer_ptr;
    Newx(new_buffer_ptr, region_size + 1, char);
    Copy(buffer_ptr,new_buffer_ptr, region_size, char);
    new_buffer_ptr[region_size] = '\0';
    sv_usepvn_flags(new_buffer, new_buffer_ptr, region_size, SV_SMAGIC | SV_HAS_TRAILING_NUL);

    return new_buffer;
}
