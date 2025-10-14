package Task::MemManager::Device;
$Task::MemManager::Device::VERSION = '0.02';
use strict;
use warnings;
use Module::Find;
use Module::Runtime 'use_module';
use feature 'say';

BEGIN {
    use constant DEBUG => $ENV{DEBUG} // 0;
    unless ( defined $Task::MemManager::VERSION ) {
        require Task::MemManager;
        if (DEBUG) {
            print
              "Loading Task::MemManager version $Task::MemManager::VERSION\n";
        }
        Task::MemManager->import;
    }
    our $destroyer = *Task::MemManager::DESTROY{CODE};
}

sub import {
    shift;    # Discard the package name;

    # Sanity check: don't install modules > 1 time & PDL is included
    my @requested_device_modules = @_;
    unless (@_) {
        @requested_device_modules = ('NVIDIA_GPU');    # Default view module
    }
    else {
        push @requested_device_modules, 'NVIDIA_GPU';
    }
    my %seen;
    @requested_device_modules = grep { !$seen{$_}++ } @requested_device_modules;
    print "Requested device modules: ", scalar @requested_device_modules, "\n";
    Task::MemManager->install_device_modules(@requested_device_modules);
}

## Switch to Task::MemManager namespace, since we are extending it

package Task::MemManager;
$Task::MemManager::VERSION = '0.02';
use feature 'refaliasing';
no warnings 'experimental::refaliasing';
no warnings 'redefine';    # to avoid warnings about DESTROY redefinition

BEGIN {
    our $device_destroyer = *Task::MemManager::DESTROY{CODE};
}
my %installed_device_modules =
  map { $_ => $_ } findsubmod 'Task::MemManager::Device';

# Device management functions
my @device_functions = qw( enter_to_gpu enter_tofrom_gpu
  enter_alloc_gpu exit_from_gpu exit_tofrom_gpu
  exit_release_gpu exit_delete_gpu update_to_gpu update_from_gpu);

my %memory_movement;     # stores the functions for each device and action
my %mapped_memory_at;    # tracks if the buffer was mapped on a device
my %device_managed_by
  ; # tracks which device is managing which which Task::MemManager::Device module
my %num_buffers_mapped_at;    # tracks how many buffers are mapped at a device

my $compiler_flags =
    "-fno-stack-protector -fcf-protection=none "
  . " -fopenmp  -Iinclude -std=c11 -fPIC "
  . " -Wall -Wextra -Wno-unused-function -Wno-unused-variable"
  . " -Wno-unused-but-set-variable ";
my $linker_flags        = join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} );
my %compilation_options = (
    NVIDIA_GPU => {
        COMPILER_FLAGS     => $compiler_flags,
        CCEXFLAGS          => " -foffload=nvptx-none ",
        LINKER_FLAGS       => $linker_flags,
        LIBRARIES          => ' ',
        OPTIMIZATION_FLAGS => "-O3 -march=native",
    },
    AMD_GPU => {
        COMPILER_FLAGS => $compiler_flags,
        CCEXFLAGS      =>
          q{},    # -> this needs debugging " -foffload=amdgcn-amd-amdhsa ",
        LINKER_FLAGS       => $linker_flags,
        LIBRARIES          => q{ },
        OPTIMIZATION_FLAGS => "-O3 -march=native",
    },
    DEFAULT => {
        COMPILER_FLAGS     => $compiler_flags,
        CCEXFLAGS          => " -fopenmp ",
        LINKER_FLAGS       => $linker_flags,
        LIBRARIES          => ' ',
        OPTIMIZATION_FLAGS => "-O3 -march=native",
    },
);

my $package_code = '
    package Task::MemManager::Device::<DEVICE>; 
    my $c_code;
    BEGIN {
        $c_code = q@
          /*
          * This is the C code that is used to manage memory on specific devices.
          * Uses eval, Inline::C and the preprocessor to create a package
          * named after the device, e.g. <DEVICE>.
          */

          void <DEVICE>_enter_to_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                      int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target enter data map(to : array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_enter_tofrom_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target enter data map(tofrom : array[index1 : index2])  \
              device(dev_id)
          }

          void <DEVICE>_enter_alloc_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target enter data map(alloc : array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_exit_from_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                        int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target exit data map(from : array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_exit_tofrom_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target exit data map(tofrom : array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_exit_release_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target exit data map(release : array[index1 : index2])             \
              device(dev_id)
          }

          void <DEVICE>_exit_delete_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target exit data map(delete : array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_update_to_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                        int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;
          #pragma omp target update to(array[index1 : index2]) device(dev_id)
          }

          void <DEVICE>_update_from_gpu(unsigned long array_addr, size_t index1, size_t index2,
                                          int dev_id) {
            char *array = (char *)(uintptr_t)array_addr;                                          
          #pragma omp target update from(array[index1 : index2]) device(dev_id)
          }
@;
    }
    use Inline (C => Config => 
    ccflags    => "<COMPILER_FLAGS>",
    lddlflags  => "<LINKER_FLAGS>",
    ccflagsex  => "<CCEXFLAGS>",
    libs       => "<LIBRARIES>",
    optimize   => "<OPTIMIZATION_FLAGS>",
    );
    
    use Inline ( C => $c_code,  );
    use Exporter qw(import);
    our @EXPORT_OK = <EXPORTED_FUNCTIONS>;
  1;
';

## Root module for Device functions
my $root_device_module = 'Task::MemManager::Device';

sub install_device_modules {
    shift;

    my (@requested_device_modules) = @_;
    my $device_package_code;
    my $module_for_device;
    foreach my $device (@requested_device_modules) {
        my $device_package_name = "${root_device_module}::$device";

        # Existing module under the root Device namespace
        if ( exists $installed_device_modules{$device_package_name} ) {
            $module_for_device = use_module($device_package_name);
        }

        # Did not find one, so create an OpenMP one dynamically using Inline::C
        else {
            $device_package_code = $package_code =~ s/<DEVICE>/$device/gr;
            my $opts = $compilation_options{$device}
              // $compilation_options{DEFAULT};
            for my $opt_key ( keys %$opts ) {
                my $opt_value = $opts->{$opt_key} // '';
                $device_package_code =~ s/<${opt_key}>/$opt_value/g;
            }
            my $exported_functions = "qw("
              . join( q{ }, map { "${device}_$_" } @device_functions ) . ")";
            $device_package_code =~
              s/<EXPORTED_FUNCTIONS>/$exported_functions/g;
            eval $device_package_code;
            $module_for_device = "${root_device_module}::$device";
        }

        #register the functions for use by the Task::MemManager objects
        for my $function (@device_functions) {
            my $function_in_package =
              $module_for_device->can("${device}_${function}");
            if ($function_in_package) {
                print "Registering function $function in $module_for_device\n";
                $memory_movement{$device}{$function} = $function_in_package;
            }
            else {
                warn "Function $function not found in $module_for_device\n";
            }
        }
    }

}

sub device_movement {
    my $memory_buffer = shift @_;
    my $identifier    = ident $memory_buffer;

    my %opts = (
        device    => 'NVIDIA_GPU',
        device_id => 0,
        start     => 0,
        end       => $memory_buffer->get_buffer_size,
        @_,
    );

    # trying to save repeat evaluations of $opts{} values through aliasing
    \my $device_id = \$opts{device_id};
    \my $device    = \$opts{device};
    \my $action    = \$opts{action};       # one of enter, exit or update
    \my $direction = \$opts{direction};    # one of to, from,
    my $function = $action . "_" . $direction . "_gpu";
    \my $function_call = \$memory_movement{$device}{$function};
    die "Unknown action $action" unless $function_call;

    # One cannot have multiple device modules managing the same device_id
    \my $device_manager = \$device_managed_by{$device_id};
    if ( defined $device_manager ) {
        if ( $device_manager ne $device ) {
            die "Device $device_id is already managed by $device_manager,"
              . " cannot ask for management by $device\n";
        }
    }
    else {
        $device_manager = $device;
    }

# Die if one attempts map enter the same buffer multiple times on the same device
    \my $mapping = \$mapped_memory_at{$identifier}{$device_id};
    if ( defined $mapping && $action eq 'enter' ) {
        die "Buffer $identifier is already managed on device $device_id,"
          . " cannot ask for an additional mapping on $device_id\n";
    }
    else {
        $mapping = $device;
    }

    # Exit action: reduce the count of mapped buffers at this device
    if ( $action eq 'exit' ) {
        if (DEBUG) {
            say "Exiting mapping of buffer $identifier on device $device_id";
        }

        # reduce the count of mapped buffers at this device
        my $num_of_buffers_mapped = $num_buffers_mapped_at{$device_id};
        if ( $num_of_buffers_mapped > 1 ) {
            $num_buffers_mapped_at{$device_id}--;
        }
        else {
            delete $num_buffers_mapped_at{$device_id};
            delete $device_managed_by{$device_id};
        }
    }
    elsif ( $action eq 'enter' ) {
        if (DEBUG) {
            say "Entering mapping of buffer $identifier on device $device_id";
        }
        $num_buffers_mapped_at{$device_id}++;
    }
    else {
        if (DEBUG) {
            say "$action mapping of buffer $identifier on device $device_id";
        }
    }
    $function_call->(
        $memory_buffer->get_buffer,
        $opts{start}, $opts{end}, $device_id
    );

}

sub DESTROY {
    my $self       = shift;
    my $identifier = ident $self;
    while ( my ( $device_id, $device ) = each %device_managed_by ) {
        next unless defined $device;

        # reduce the count of mapped buffers at this device
        my $num_of_buffers_mapped = $num_buffers_mapped_at{$device_id};
        if ( $num_of_buffers_mapped > 0 ) {
            $num_buffers_mapped_at{$device_id}--;
        }
        else {
            delete $device_managed_by{$device_id};
        }

        # perform the action upon the buffer
        $memory_movement{$device}{"exit_release_gpu"}
          ->( $self->get_buffer, 0, $self->get_buffer_size, $device_id );
        delete $mapped_memory_at{$identifier}{$device_id};
    }
    $Task::MemManager::Device::destroyer->($self);
}
1;

=head1 NAME

Task::MemManager::Device - Device-specific memory management extensions for Task::MemManager

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Task::MemManager::Device;
    
    # Use default NVIDIA_GPU device
    my $buffer = Task::MemManager->new(1000, 4);
    
    # Map buffer to GPU
    $buffer->device_movement(
        action    => 'enter',
        direction => 'to',
        device    => 'NVIDIA_GPU',
        device_id => 0
    );
    
    # Perform GPU operations (using your C code)
    my_gpu_function($buffer->get_buffer, $buffer->get_buffer_size);
    
    # Update buffer from GPU back to CPU
    $buffer->device_movement(
        action    => 'update',
        direction => 'from'
    );
    
    # Exit and deallocate from GPU
    $buffer->device_movement(
        action    => 'exit',
        direction => 'from'
    );

=head1 DESCRIPTION

Task::MemManager::Device extends the C<Task::MemManager> module by providing device-specific
memory management capabilities, particularly for GPU computing using OpenMP target directives.
It enables seamless data movement between CPU and GPU memory spaces, supporting various
mapping strategies (to, from, tofrom, alloc) and update operations.

The module dynamically generates device-specific modules using Inline::C and OpenMP pragmas,
allowing for flexible device support. By default, it provides NVIDIA GPU support with
appropriate compilation flags, but can be extended to support AMD GPUs and other devices.

Device modules are automatically loaded and compiled on first use, with the generated
code cached by Inline::C for subsequent runs. Each device module implements a set of
standard functions for entering data regions, exiting data regions, and updating data
between host and device.

=head1 LOADING THE MODULE

The module can be loaded with or without specifying device modules:

    # Load with default NVIDIA_GPU device
    use Task::MemManager::Device;
    
    # Load with specific devices
    use Task::MemManager::Device qw(NVIDIA_GPU AMD_GPU);
    
    # Load via Task::MemManager with device specification
    use Task::MemManager Device => ['NVIDIA_GPU'];
    
    # Combine with allocator and view specifications
    use Task::MemManager
        Allocator => 'CMalloc',
        View      => 'PDL',
        Device    => 'NVIDIA_GPU';

=head1 METHODS

=head2 device_movement

    $buffer->device_movement(%options);

Manages data movement between CPU and device (GPU) memory spaces using OpenMP target
directives. This is the primary method for controlling data placement and updates.

B<Parameters:>

=over 4

=item * C<action> - The type of operation to perform. Required. One of:

=over 4

=item * C<'enter'> - Begin a data mapping region (allocate on device, optionally copy)

=item * C<'exit'> - End a data mapping region (optionally copy back, deallocate)

=item * C<'update'> - Update data between host and device without changing mapping

=back

=item * C<direction> - The data transfer direction. Required. One of:

=over 4

=item * C<'to'> - Copy data from host to device

=item * C<'from'> - Copy data from device to host

=item * C<'tofrom'> - Copy data both ways (enter: to device, exit: from device)

=item * C<'alloc'> - Allocate device memory without copying (enter only)

=item * C<'release'> - Deallocate device memory without copying (exit only)

=item * C<'delete'> - Deallocate device memory, discard changes (exit only)

=back

=item * C<device> - Device module name. Optional. Default: 'NVIDIA_GPU'

=item * C<device_id> - Device ID number for multi-device systems. Optional. Default: 0

=item * C<start> - Starting byte offset in buffer. Optional. Default: 0

=item * C<end> - Ending byte position in buffer. Optional. Default: buffer size

=back

B<Returns:> Nothing (dies on error)

B<Throws:>

=over 4

=item * Dies if action/direction combination is invalid

=item * Dies if attempting to manage same device_id with different device modules

=item * Dies if attempting to enter-map the same buffer twice on same device

=back

B<Examples:>

    # Map buffer to GPU, copying data
    $buffer->device_movement(
        action    => 'enter',
        direction => 'to'
    );
    
    # Allocate GPU memory without copying
    $buffer->device_movement(
        action    => 'enter',
        direction => 'alloc'
    );
    
    # Update partial buffer region from GPU
    $buffer->device_movement(
        action    => 'update',
        direction => 'from',
        start     => 0,
        end       => 1000
    );
    
    # Exit mapping, copying data back and deallocating
    $buffer->device_movement(
        action    => 'exit',
        direction => 'from'
    );
    
    # Exit mapping with release (keep mapping but allow reuse)
    $buffer->device_movement(
        action    => 'exit',
        direction => 'release'
    );

=head1 DEVICE FUNCTIONS

Each device module provides the following functions (where <DEVICE> is replaced with
the device name, e.g., NVIDIA_GPU):

=over 4

=item * C<< <DEVICE>_enter_to_gpu >> - Map data to device (copy from host)

=item * C<< <DEVICE>_enter_tofrom_gpu >> - Map data bidirectionally

=item * C<< <DEVICE>_enter_alloc_gpu >> - Allocate on device without copying

=item * C<< <DEVICE>_exit_from_gpu >> - Unmap data from device (copy to host)

=item * C<< <DEVICE>_exit_tofrom_gpu >> - Unmap bidirectional data

=item * C<< <DEVICE>_exit_release_gpu >> - Release mapping without copying

=item * C<< <DEVICE>_exit_delete_gpu >> - Delete mapping and discard data

=item * C<< <DEVICE>_update_to_gpu >> - Update data to device

=item * C<< <DEVICE>_update_from_gpu >> - Update data from device

=back

These functions are automatically registered and called by the C<device_movement> method.
B<They should not typically be called directly>.

=head1 COMPILATION OPTIONS

The module supports device-specific compilation options for optimal performance:

=head2 NVIDIA_GPU (default)

    COMPILER_FLAGS: -fno-stack-protector -fcf-protection=none -fopenmp 
                    -std=c11 -fPIC -Wall -Wextra
    CCEXFLAGS:      -foffload=nvptx-none
    LINKER_FLAGS:   -fopenmp (with system lddlflags)
    OPTIMIZE:       -O3 -march=native

=head2 AMD_GPU

    COMPILER_FLAGS: (same as NVIDIA_GPU)
    CCEXFLAGS:      (none - AMD offloading under development)
    LINKER_FLAGS:   -fopenmp (with system lddlflags)
    OPTIMIZE:       -O3 -march=native

=head2 DEFAULT (for other devices)

    COMPILER_FLAGS: (same as NVIDIA_GPU)
    CCEXFLAGS:      -fopenmp
    LINKER_FLAGS:   -fopenmp (with system lddlflags)
    OPTIMIZE:       -O3 -march=native

=head1 EXAMPLES

Example 1 is a complete working example demonstrating basic GPU memory mapping,
computation, and retrieval of results. Example 2 shows how to allocate GPU memory without initial data copy. Example 3 illustrates combining device management with PDL views for seamless integration with Perl Data Language.
=head2 Example 1: Basic GPU Memory Mapping

This example demonstrates the fundamental pattern of mapping memory to GPU,
performing computations, and retrieving results.

    use Task::MemManager::Device;
    use Inline (
    C => Config => ccflags => "-fno-stack-protector -fcf-protection=none "
      . " -fopenmp  -Iinclude -std=c11 -fPIC "
      . " -Wall -Wextra -Wno-unused-function -Wno-unused-variable"
      . " -Wno-unused-but-set-variable ",
    lddlflags => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    ccflagsex => " -fopenmp ",
    libs      => q{ -lm -foffload=-lm },
    optimize  => "-O3 -march=native",
    ); # replace with your OpenMP's device flags
    use Inline C => 'DATA';
    
    my $buffer_length = 250000;
    my $buffer = Task::MemManager->new($buffer_length, 4);
    
    # Map buffer to GPU
    $buffer->device_movement(action => 'enter', direction => 'to');
    
    # Perform GPU computation
    assign_as_float($buffer->get_buffer, $buffer->get_buffer_size);
    
    # Update results back to CPU
    $buffer->device_movement(action => 'update', direction => 'from');
    
    # Verify results by printing some values
    my @values = unpack("f*", $buffer->extract_buffer_region(0, 
                        $buffer->get_buffer_size - 1));
    
    print "First 10 values: ", join(", ", @values[0..9]), "\n";
    print "Last 10 values: ", join(", ", @values[-10..-1]), "\n";
    # Exit GPU mapping
    $buffer->device_movement(action => 'exit', direction => 'from');
    
    __DATA__
    __C__
    #include "omp.h"
    
    void assign_as_float(unsigned long arr, size_t n) {
        float *array_addr = (float *)arr;
        size_t len = n / sizeof(float);
        #pragma omp target
        for (int i = 0; i < len; i++) {
            array_addr[i] = (float)i * 2.0f;
        }
    }

=head2 Example 2: GPU Memory Allocation Without Initial Copy

When you want to allocate GPU memory but don't need to copy initial data
(e.g., for output-only computations):

    # look at Example 1 for the use statements and Inline C setup
    my $buffer = Task::MemManager->new(1000000, 4);
    
    # Allocate GPU memory without copying
    $buffer->device_movement(action => 'enter', direction => 'alloc');
    
    # Perform GPU computation that generates results
    alloc_as_float($buffer->get_buffer, $buffer->get_buffer_size);
    
    # Copy results back to CPU
    $buffer->device_movement(action => 'exit', direction => 'from');
    
    __DATA__
    __C__
    #include "omp.h"
    
    void alloc_as_float(unsigned long arr, size_t n) {
        float *array_addr = (float *)arr;
        size_t len = n / sizeof(float);
        #pragma omp target
        for (int i = 0; i < len; i++) {
            array_addr[i] = (float)i * 3.0f;
        }
    }

=head2 Example 3: Working with PDL Views

Combining device management with PDL views for seamless integration with
Perl Data Language:

    use Task::MemManager
        Allocator => 'CMalloc',
        View      => 'PDL',
        Device    => 'NVIDIA_GPU';
    use Inline (
    C => Config => ccflags => "-fno-stack-protector -fcf-protection=none "
      . " -fopenmp  -Iinclude -std=c11 -fPIC "
      . " -Wall -Wextra -Wno-unused-function -Wno-unused-variable"
      . " -Wno-unused-but-set-variable ",
    lddlflags => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    ccflagsex => " -fopenmp ",
    libs      => q{ -lm -foffload=-lm },
    optimize  => "-O3 -march=native",
    ); # replace with your OpenMP's device flags
    use Inline C => 'DATA';  
    
    my $buffer_length = 1000;
    my $buffer = Task::MemManager->new($buffer_length, 4, 
                                      {allocator => 'CMalloc'});
    
    # Create PDL view
    my $pdl_view = $buffer->create_view('PDL',
        {view_name => 'my_pdl_view', pdl_type => 'float'});
    
    # Initialize with random values in PDL
    $pdl_view->inplace->random;
    
    # Clone the view for comparison
    my $cloned_view = $buffer->clone_view('my_pdl_view');
    
    # Move to GPU and modify
    $buffer->device_movement(action => 'enter', direction => 'to');
    mod_as_float($buffer->get_buffer, $buffer->get_buffer_size);
    $buffer->device_movement(action => 'exit', direction => 'from');
    
    # PDL view automatically reflects changes
    my @values = list $pdl_view;
    my @original = list $cloned_view;
    
    # Verify: values should be doubled
    for my $i (0 .. $#values) {
        die "Mismatch!" unless $values[$i] == $original[$i] * 2.0;
    }

    __DATA__
    __C__
    #include "omp.h"
    
    void mod_as_float(unsigned long arr, size_t n) {
        float *array_addr = (float *)arr;
        size_t len = n / sizeof(float);
        #pragma omp target
        for (int i = 0; i < len; i++) {
            array_addr[i] *= 2.0f;
        }
    }

=head2 Example 4: Multiple Device Management

Managing multiple buffers across different devices (code snippet):

    # Create multiple buffers
    my $buf1 = Task::MemManager->new(1000, 4);
    my $buf2 = Task::MemManager->new(2000, 4);
    
    # Map to different devices (if available)
    $buf1->device_movement(
        action    => 'enter',
        direction => 'to',
        device_id => 0
    );
    
    $buf2->device_movement(
        action    => 'enter',
        direction => 'to',
        device_id => 1  # Different device
    );
    
    # Perform operations on each device - fictional C level functions
    process_on_device($buf1->get_buffer, $buf1->get_buffer_size);
    process_on_device($buf2->get_buffer, $buf2->get_buffer_size);
    
    # Retrieve results
    $buf1->device_movement(action => 'exit', direction => 'from', device_id => 0);
    $buf2->device_movement(action => 'exit', direction => 'from', device_id => 1);

=head2 Example 5: Partial Buffer Updates

Update only a portion of the buffer between host and device:

    my $buffer = Task::MemManager->new(10000, 4);
    
    $buffer->device_movement(action => 'enter', direction => 'to');
    
    # Update only first 1000 bytes from GPU
    $buffer->device_movement(
        action    => 'update',
        direction => 'from',
        start     => 0,
        end       => 1000
    );
    
    # Later, update another region to GPU
    $buffer->device_movement(
        action    => 'update',
        direction => 'to',
        start     => 1000,
        end       => 2000
    );
    
    $buffer->device_movement(action => 'exit', direction => 'release');

=head1 AUTOMATIC CLEANUP

The module automatically handles cleanup of device mappings when buffer objects
are destroyed. The DESTROY method ensures that:

=over 4

=item * All device mappings are properly released

=item * Device memory is deallocated

=item * No memory leaks occur on the device

=item * Reference counts are properly maintained

=back

Cleanup uses the C<exit_release_gpu> operation, which allows the runtime to
manage the actual deallocation timing while ensuring proper cleanup.

=head1 DIAGNOSTICS

If you set the environment variable DEBUG to a non-zero value, the module will
provide detailed information about when things go wrong


=head1 DEPENDENCIES

The module depends on:

=over 4

=item * C<Task::MemManager> - Base memory management functionality

=item * C<Inline::C> - For C code integration and compilation

=item * C<Module::Find> - For automatic discovery of device modules

=item * C<Module::Runtime> - For dynamic module loading

=item * OpenMP-capable compiler (e.g., GCC 9+, Clang 10+) for GPU offloading

=back

For NVIDIA GPU support, you need:

=over 4

=item * GCC with nvptx offload support, or

=item * Clang with CUDA/NVPTX target support (not tested yet with the relevant version of perl)

=back

=head1 LIMITATIONS AND CAVEATS

=over 4

=item * Cannot map the same buffer to the same device_id multiple times

=item * Cannot manage the same device_id with different device modules

=item * Device module compilation happens at first use (may take time)

=item * Requires OpenMP 4.5+ for target directives

=item * GPU offloading support varies by compiler and installation

=item * AMD GPU support is experimental and may require additional setup

=back

=head1 TODO

=over 4

=item * Ensure that clang and icx compilers work correctly

=item * Ensure AMD GPU offloading works correctly

=item * Add support for additional devices (e.g., Intel GPUs, FPGAs)

=item * Add support for asynchronous data transfers

=item * Implement device-to-device direct transfers

=item * Add support for unified memory management

=item * Provide device property queries (memory available, etc.)

=item * Add support for interfacing to other parallel programming models (e.g., CUDA, HIP) using OpenMP's interoperability features

=item * Implement automatic workload distribution across multiple devices

=item * Device module loading and registration (when DEBUG = 1)

=item * Function registration for each device (when DEBUG = 1)

=item * Buffer mapping operations (enter/exit/update) (when DEBUG = 1)

=item * Device ID management (when DEBUG = 1)

=item * Buffer lifecycle events (when DEBUG = 1)

=back

=head1 SEE ALSO

=over 4

=item * L<Task::MemManager> - Base memory management module

=item * L<Task::MemManager::View> - Memory view management

=item * L<Inline::C> - Inline C code in Perl

=item * L<OpenMP Specification|https://www.openmp.org/specifications/> - OpenMP target directives

=item * L<GCC Offloading|https://gcc.gnu.org/wiki/Offloading> - GCC offloading setup

=back

=head1 AUTHOR

Christos Argyropoulos, C<< <chrisarg at cpan.org> >>
Initial documentation was created by Claude Sonnet 4.5 after providing the 
human generated test files for the module and the documentation in the 
MemManager distribution as context. 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under the
MIT license. The full text of the license can be found in the LICENSE file.
See L<https://en.wikipedia.org/wiki/MIT_License> for more information.

=cut
