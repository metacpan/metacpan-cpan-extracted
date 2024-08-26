package Task::MemManager::CMalloc;
$Task::MemManager::CMalloc::VERSION = '0.01';
use strict;
use warnings;

use Carp qw(carp croak);
use Inline ( C => 'DATA', );

Inline->init()
  ; ## prevents warning "One or more DATA sections were not processed by Inline"

##############################################################################
# Usage       : Task::MemManager::CMalloc::free($buffer);
# Purpose     : Frees the buffer allocated by malloc
# Returns     : n/a
# Parameters  : $buffer - Reference to the buffer
# Throws      : Croaks if the buffer cannot be freed
# Comments    : None
# See Also    : n/a

sub free {
    my ($buffer) = @_;
    my $in_error = _free_buffer($buffer);
    unless ( defined $in_error ) {
        croak "Failed to free buffer using C's free";
    }
}

##############################################################################
# Usage       : my $buffer_address =
#                Task::MemManager::CMalloc::get_buffer_address($buffer);
# Purpose     : Returns the memory address of the buffer
# Returns     : The memory address of the buffer
# Parameters  : $buffer - A buffer allocated by malloc
# Throws      : Croaks if the buffer address cannot be obtained
# Comments    : None
# See Also    : n/a

sub get_buffer_address {
    my ($buffer) = @_;
    return $buffer;
}

##############################################################################
# Usage       : my $buffer = Task::MemManager::CMalloc::malloc(10, 1, 'A');
# Purpose     : Allocates a buffer using C's malloc
# Returns     : A reference to the buffer (to be used by Task::MemManager)
# Parameters  : $num_of_items     - Number of items in the buffer
#               $size_of_each_item - Size of each item in the buffer
#               $init_value        - Value to initialize the buffer with
# Throws      : Croaks if the buffer allocation fails
# Comments    : None
# See Also    : n/a

sub malloc {
    my ( $num_of_items, $size_of_each_item, $init_value ) = @_;
    my $buffer_size = $num_of_items * $size_of_each_item;
    my $buffer;
    if ( lc $init_value eq 'zero' ) {
        $buffer = _alloc_with_calloc($buffer_size);
    }
    elsif ( defined $init_value ) {
        $init_value = ord($init_value);
        $buffer = _alloc_with_malloc_and_set( $buffer_size, $init_value );
    }
    else {
        $buffer = _alloc_with_malloc($buffer_size);
    }

    # Die without nuance if the buffer allocation fails
    unless ( defined $buffer ) {
        croak "Failed to allocate buffer using C's malloc";
    }
    return \$buffer;
}

1;

=head1 NAME

Task::MemManager::CMalloc - Allocates buffers using C's malloc

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Task::MemManager::CMalloc;

    my $buffer = Task::MemManager::CMalloc::malloc(10, 1, 'A');
    my $buffer_address = Task::MemManager::CMalloc::get_buffer_address($buffer);
    Task::MemManager::CMalloc::free($buffer);

=head1 DESCRIPTION

The C<Task::MemManager::CMalloc> module provides access to memory bufffers
allocated using C's malloc function. The buffers are allocated immediately,
i.e., not using the delayed allocation mechanism one would expect from a
garden variety (e.g. glibc) malloc implementation. The module provides
methods to allocate uninitialized, zero initialized or custom initialized
buffers, access to the buffer's memory address and facilities to free the
buffer. The module is intended to be used in conjunction with the
C<Task::MemManager> module, and thus it is probably best not to use these
functions directly. 

=head1 METHODS

=over 4

=item * C<malloc($num_of_items, $size_of_each_item, $init_value)>

Allocates a buffer of size C<$num_of_items * $size_of_each_item> bytes. If
C<$init_value> is not defined, the buffer is not initialized. If C<$init_value>
is the string 'zero', the buffer is zero initialized. Otherwise, the buffer is
initialized with the value of C<$init_value> repeated for the entire buffer.
The value returned is processed by the C<Task::MemManager> module in order to
grab the memory address of the buffer just generated.

=item * C<free($buffer)>

Frees the buffer allocated by C<malloc>.

=item * C<get_buffer_address($buffer)>

Returns the memory address of the buffer as a Perl scalar.

=back

=head1 DIAGNOSTICS

There are no diagnostics that one can use. The module will croak if the
allocation fails, so you don't have to worry about error handling. 

=head1 DEPENDENCIES

The module depends on the C<Inline::C> module to compile the C code for 
the memory allocation and deallocation functions.

=head1 SEE ALSO

=over 4

=item * L<https://metacpan.org/pod/Inline::C>

Inline::C is a module that allows you to write Perl subroutines in C. 

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

/*
    * This is the C code that is used to allocate and free memory buffers
    * using malloc and free. The code is used by the Task::MemManager::CMalloc
    * module. All functions return undef for failure (otherwise the return 
    * value is the address of the buffer).
    
*/

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// allocates a buffer using malloc - contents are not initialized
SV* _alloc_with_malloc(size_t length) {
    // Allocate memory for the array
    char* buffer = (char*)malloc(length * sizeof(char));
    if (buffer == NULL) {
        return &PL_sv_undef;
    }
    buffer[0] = 0;  // Touch the buffer to force allocation
    return newSVuv(PTR2UV(buffer));
}

// allocates a buffer using malloc & initializes to non-zero value
SV* _alloc_with_malloc_and_set(size_t length, short initial_value) {
    // Allocate memory for the array
    char* buffer = (char*)malloc(length * sizeof(char));
    if (buffer == NULL) {
        return &PL_sv_undef;
    }
    memset(buffer, initial_value, length);
    return newSVuv(PTR2UV(buffer));
}

// allocate a zero-initialized buffer
SV* _alloc_with_calloc(size_t length) {
    // Allocate memory for the array
    char* buffer = (char*)malloc(length * sizeof(char));
    if (buffer == NULL) {
        return &PL_sv_undef;
    }
    buffer[0] = 0;
    return newSVuv(PTR2UV(buffer));
}

/* frees the buffer - note we use Inline C to convert the Perl scalar  
*  corresponding to a buffer to a size_t integer, then cast it to a 
*  uintptr_t to save the return value into a Perl scalar, and then 
*  cast the uintptr_t back to a void pointer that is then passed to free.
*  This appears the safest way (to me) to free the buffer.
*/ 

SV* _free_buffer(size_t buffer) {
    void*  buffer_ptr = (void *)(uintptr_t)buffer; 
    if (buffer_ptr == NULL) {
        return &PL_sv_undef;
    }
    SV* return_val = newSVuv(PTR2UV(buffer));
    free(buffer_ptr);
    return return_val;
}

// returns the address of the buffer as a Perl scalar
SV* _get_buffer_address(SV* sv) {
    if (!SvPOK(sv)) {
        return &PL_sv_undef;
    }
    return sv;
}
