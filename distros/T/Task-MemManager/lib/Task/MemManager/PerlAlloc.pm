package Task::MemManager::PerlAlloc;
$Task::MemManager::PerlAlloc::VERSION = '0.09';
use strict;
use warnings;

use Convert::Scalar qw(len readonly grow readonly_on);
use Inline ( C => 'DATA', );
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

Inline->init()
  ; ## prevents warning "One or more DATA sections were not processed by Inline"


###############################################################################
# Usage       : Task::MemManager::PerlAlloc::free($buffer);
# Purpose     : Frees the buffer allocated by malloc
# Returns     : n/a
# Parameters  : $buffer - Reference to the buffer
# Throws      : n/a
# Comments    : None
# See Also    : n/a

sub free {

    # Do nothing

}

###############################################################################
# Usage       : my $buffer_address =
#               Task::MemManager::PerlAlloc::get_buffer_address($buffer);
# Purpose     : Returns the memory address of the buffer
# Returns     : The memory address of the buffer
# Parameters  : $buffer - A buffer allocated by malloc
# Throws      : n/a
# Comments    : None
# See Also    : n/a

sub get_buffer_address {
    my ($buffer) = @_;
    return _get_buffer_address($buffer);
}

###############################################################################
# Usage       : my $buffer = Task::MemManager::PerlAlloc::malloc(10, 1, 'A');
# Purpose     : Allocates a buffer using Perl's string functions
# Returns     : A reference to the buffer (to be used by Task::MemManager)
# Parameters  : $num_of_items     - Number of items in the buffer
#               $size_of_each_item - Size of each item in the buffer
#               $init_value        - Value to initialize the buffer with (0-255)
# Throws      : dies if the buffer allocation fails
# Comments    : None
# See Also    : n/a

sub malloc {
    my ( $num_of_items, $size_of_each_item, $init_value ) = @_;
    my $buffer_size = $num_of_items * $size_of_each_item;

    die "Invalid $buffer_size, should be between [0,$MAX_ADDR]\n"
      if ( !defined($buffer_size)
        || $buffer_size <= 0
        || $buffer_size > $MAX_ADDR );

    my $buffer = ( pack "C", $init_value ) x $buffer_size;

    return \$buffer;
}

###############################################################################
# Usage       : my $buffer =
# Task::MemManager::PerlAlloc::consume($external_buffer_ref, $length);
# Purpose     : Consumes an external buffer, stored in a scalar variable
#               (provided as a reference to simulate pass-by-reference)
# Returns     : A reference to a (copy of the) external buffer
# Parameters  : $external_buffer - A reference to the external buffer
#               $length          - The length of the buffer to consume. If the
#                                  length is greater than the actual length of
#                                  the buffer, the buffer will grow to the size.
#                                  If the length is less than the actual length
#                                  of the buffer, only the specified length
#                                  will be consumed.
# Throws      : Dies if the external buffer is not defined, or if it is not a
#               scalar reference or if the length of the external buffer is
#               non-positive.
# Comments    : The Perl buffer is *copied* into a new scalar variable, so the
#               original buffer can be freed or go out of scope without
#               affecting the buffer managed by Task::MemManager.
# See Also    : n/a

sub consume {
    my ( $external_buffer_ref, $length ) = @_;
    if (DEBUG) {
        die "External buffer is not defined"
          unless defined $external_buffer_ref;
        die "External buffer is not a scalar reference"
          unless ref($external_buffer_ref) eq 'SCALAR';
    }

    my $current_length = length($$external_buffer_ref);
    if (DEBUG) {
        die "Length of external buffer is not positive"
          unless $current_length > 0;
    }
    my $returned_buffer = $$external_buffer_ref;
    grow( $returned_buffer, $length )
      if $length != $current_length;
    substr( $returned_buffer, 0, 1 ) =
      substr( $returned_buffer, 0, 1 );    #force Perl to make a copy
    return \$returned_buffer;
}

1;

=head1 NAME

Task::MemManager::PerlAlloc - Allocates buffers using Perl's string functions

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Task::MemManager::PerlAlloc;

    my $buffer = Task::MemManager::PerlAlloc::malloc(10, 1, 'A');
    my $buffer_address = Task::MemManager::PerlAlloc::get_buffer_address($buffer);
    Task::MemManager::PerlAlloc::free($buffer);

=head1 DESCRIPTION

This module provides a way to allocate buffers using Perl's string functions.
The module is intended to be used in conjunction with the C<Task::MemManager>
module, and thus it is probably best not to use these functions directly. 

=head1 FUNCTIONS

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

=item * C<consume($external_buffer_ref, $length)>

Consumes an external buffer, stored in a scalar variable (provided as a
reference to simulate pass-by-reference). The external buffer is copied into a
new scalar variable, so the original buffer can be freed or go out of scope
without affecting the buffer managed by C<Task::MemManager>.

=back

=head1 DIAGNOSTICS

There are no diagnostics that one can use. The module will die if the
allocation fails, so you don't have to worry about error handling. 
If you set up the environment variable DEBUG to a non-zero value, then
a number of sanity checks will be performed, and the module will croak
with an (informative message ?) if something is wrong.

=head1 DEPENDENCIES

This module depends on the C<Convert::Scalar> module to grow the buffer.
The module depends on the C<Inline::C> module to access the memory buffer 
of the Perl scalar using the PerlAPI.

=head1 SEE ALSO

=over 4

=item * L<https://metacpan.org/pod/Convert::Scalar>

This module exports various internal perl methods that change the internal 
representation or state of a perl scalar. All of these work in-place, that is,
they modify their scalar argument. 

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

/*
    * This is the C code that is used to obtain the memory address of the 
    * buffer
    
*/

/**
 * @brief Retrieves the memory address of a buffer from a Perl scalar.
 *
 * This function takes a Perl scalar as input and checks if it is a string scalar.
 * If it is not a string scalar, returns under back to perl
 * If it is a string scalar, it retrieves the memory address of the buffer 
 * associated with the scalar.
 *
 * @param sv The Perl scalar from which to retrieve the buffer address.
 * @return The memory address of the buffer as a Perl scalar.
 */

SV* _get_buffer_address(SV* sv) {
    if (!SvPOK(sv)) {
        return &PL_sv_undef;
    }
    char* buffer = SvPVbyte_nolen(sv);
    return newSVuv(PTR2UV(buffer));
}
