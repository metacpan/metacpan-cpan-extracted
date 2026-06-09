package Strada;

use strict;
use warnings;

our $VERSION = '1.0';

# Load this XS object with RTLD_GLOBAL so the Strada runtime it statically
# links (strada_pending_cleanup_count, strada_decref, the GC/arena globals,
# etc.) is visible to the Strada libraries we dlopen at runtime — otherwise
# they fail with "undefined symbol: strada_*". Must be defined before load().
sub dl_load_flags { 0x01 }

require XSLoader;
XSLoader::load('Strada', $VERSION);

=head1 NAME

Strada - Call compiled Strada shared libraries from Perl

=head1 WEBSITE

L<https://strada-lang.github.io/>

=head1 SYNOPSIS

    use Strada;

    # Load a Strada shared library
    my $lib = Strada::Library->new('path/to/library.so');

    # Call a function with no arguments
    my $result = $lib->call('my_function');

    # Call a function with arguments
    my $result = $lib->call('add_numbers', 1, 2);

    # Unload the library
    $lib->unload();

=head1 DESCRIPTION

This module provides an interface for Perl programs to load and call
functions from compiled Strada shared libraries (.so files).

Strada values are automatically converted to/from Perl types:

    Strada int    <-> Perl integer
    Strada num    <-> Perl number
    Strada str    <-> Perl string
    Strada array  <-> Perl array reference
    Strada hash   <-> Perl hash reference
    Strada undef  <-> Perl undef

=head1 METHODS

=head2 Low-level API

=head3 Strada::load($path)

Load a shared library. Returns a handle (integer) or 0 on failure.

=head3 Strada::unload($handle)

Unload a previously loaded library.

=head3 Strada::get_func($handle, $name)

Get a function pointer from a loaded library.

=head3 Strada::call($func, @args)

Call a Strada function with arguments. With libffi (see Makefile.PL), any
number of arguments is supported; without it, up to 4 (more will croak).

=head2 High-level API

=head3 Strada::Library->new($path)

Create a new Library object and load the shared library.

=head3 $lib->call($func_name, @args)

Call a function by name with arguments. Supports both formats:

    $lib->call('add', 2, 3);           # Direct function name
    $lib->call('math_lib::add', 2, 3); # Package::function format

The C<package::function> format is automatically converted to C<package_function>
to match Strada's internal naming convention.

=head3 $lib->unload()

Unload the library.

=head3 $lib->version()

Returns the library version string, or empty string if not available.

=head3 $lib->functions()

Returns a hash reference describing all exported functions:

    {
        'func_name' => {
            return       => 'int',      # Return type
            param_count  => 2,          # Number of parameters
            params       => ['int', 'str'],  # Parameter types
            variadic_idx => -1,         # Index of variadic param (-1 if not variadic)
            is_variadic  => 0,          # 1 if function is variadic
        },
        ...
    }

=head3 $lib->describe()

Returns a formatted string describing all functions (similar to C<soinfo> output):

    # Strada Library: ./mylib.so
    # Version: 1.0.0
    # Functions: 3
    #
    #   func add(int $a, int $b) int
    #   func greet(str $a) str
    #   func multiply(int $a, int $b) int

=cut

# High-level OO interface
package Strada::Library;

sub new {
    my ($class, $path) = @_;

    my $handle = Strada::load($path);
    die "Failed to load Strada library: $path" unless $handle;

    return bless {
        handle => $handle,
        path   => $path,
        funcs  => {},  # Cache function pointers
    }, $class;
}

sub call {
    my ($self, $func_name, @args) = @_;

    # Convert package::function to package_function (Strada naming convention)
    # Match sanitize_name() from CodeGen.strada: both :: and : become _
    my $c_func_name = $func_name;
    $c_func_name =~ s/::/_/g;  # Replace :: with _ first
    $c_func_name =~ s/:/_/g;   # Then any remaining : with _

    # Get or cache function pointer
    my $func = $self->{funcs}{$c_func_name};
    unless ($func) {
        $func = Strada::get_func($self->{handle}, $c_func_name);
        die "Function not found: $func_name (looked for $c_func_name)" unless $func;
        $self->{funcs}{$c_func_name} = $func;
    }

    # Variadic functions (constructors, @_-style, `...@rest`) take their tail
    # arguments packed into one Strada array. The export metadata records the
    # packing boundary as variadic_idx; route those through _call_variadic.
    my $vidx = $self->_variadic_idx($c_func_name);
    return $vidx >= 0 ? Strada::_call_variadic($func, $vidx, @args)
                      : Strada::call($func, @args);
}

# variadic_idx for a C function name (-1 if not variadic / unknown), cached.
sub _variadic_idx {
    my ($self, $c_name) = @_;
    unless ($self->{vidx}) {
        my $funcs = $self->functions();
        $self->{vidx} = { map { $_ => $funcs->{$_}{variadic_idx} } keys %$funcs };
    }
    return defined($self->{vidx}{$c_name}) ? $self->{vidx}{$c_name} : -1;
}

# Construct a Strada object: calls "${class}::new" and returns the blessed
# Strada::Object (sugar for $lib->call("Counter::new", @args)).
sub new_object {
    my ($self, $class, @args) = @_;
    return $self->call("${class}::new", @args);
}

sub unload {
    my ($self) = @_;

    if ($self->{handle}) {
        Strada::unload($self->{handle});
        $self->{handle} = 0;
        $self->{funcs} = {};
    }
}

sub DESTROY {
    my ($self) = @_;
    $self->unload() if $self->{handle};
}

# Get library version
sub version {
    my ($self) = @_;
    return Strada::get_version($self->{handle});
}

# Get all exported functions with their signatures
# Returns a hash ref: { func_name => { return => 'type', params => [...], param_count => N, variadic_idx => N, is_variadic => 0/1 } }
sub functions {
    my ($self) = @_;

    my $info = Strada::get_export_info($self->{handle});
    return {} unless $info;

    my %funcs;
    for my $line (split /\n/, $info) {
        next unless $line =~ /^func:/;

        # Format: func:name:return_type:param_count:param_types:variadic_idx
        my @parts = split /:/, $line;
        next unless @parts >= 4;

        my $name = $parts[1];
        my $ret = $parts[2];
        my $param_count = $parts[3];
        my @param_types = $parts[4] ? split(/,/, $parts[4]) : ();
        my $variadic_idx = defined($parts[5]) ? $parts[5] : -1;

        $funcs{$name} = {
            return       => $ret,
            param_count  => $param_count,
            params       => \@param_types,
            variadic_idx => $variadic_idx,
            is_variadic  => ($variadic_idx >= 0) ? 1 : 0,
        };
    }

    return \%funcs;
}

# Describe all functions (similar to soinfo output)
sub describe {
    my ($self) = @_;

    my $funcs = $self->functions();
    my $version = $self->version();
    my @lines;

    push @lines, "# Strada Library: $self->{path}";
    push @lines, "# Version: $version" if $version;
    push @lines, "# Functions: " . scalar(keys %$funcs);
    push @lines, "#";

    for my $name (sort keys %$funcs) {
        my $f = $funcs->{$name};
        my @params;
        my $i = 0;
        my $variadic_idx = $f->{variadic_idx};
        for my $type (@{$f->{params}}) {
            my $var = chr(ord('a') + $i);
            $var = "arg$i" if $i >= 26;
            # Check if this is the variadic parameter
            if ($i == $variadic_idx) {
                push @params, "$type ...\@$var";  # Show with ... prefix and @ sigil
            } else {
                push @params, "$type \$$var";
            }
            $i++;
        }
        my $sig = "func $name(" . join(", ", @params) . ") $f->{return}";
        push @lines, "#   $sig";
    }

    return join("\n", @lines);
}

# Wrapper for a blessed Strada object returned from the runtime. Constructed by
# the XS strada_to_sv() when it sees a blessed value; holds the live
# StradaValue* (in {ptr}) and its Strada class name (in {class}). Method calls
# are dispatched through the runtime via Strada::_method_call.
package Strada::Object;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    (my $method = $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';
    return Strada::_method_call($self->{ptr}, $method, @_);
}

# The Strada class this object is blessed into (e.g. "Counter").
sub strada_class { $_[0]->{class} }

# isa/can check the Perl class first (so isa_ok($obj, 'Strada::Object') and other
# UNIVERSAL semantics keep working), then fall back to the Strada class
# hierarchy via the runtime (so $obj->isa('Counter') reflects extends/with).
sub isa {
    my ($self, $class) = @_;
    return 1 if defined($class) && $self->UNIVERSAL::isa($class);
    return Strada::_method_call($self->{ptr}, 'isa', $class) ? 1 : 0;
}

sub can {
    my ($self, $method) = @_;
    my $code = defined($method) ? $self->UNIVERSAL::can($method) : undef;
    return $code if $code;
    return Strada::_method_call($self->{ptr}, 'can', $method) ? 1 : 0;
}

sub DESTROY {
    my $self = shift;
    Strada::_obj_release($self->{ptr}) if $self->{ptr};
    $self->{ptr} = 0;
}

1;

__END__

=head1 EXAMPLE

Create a Strada library (math_lib.strada):

    package math_lib;

    func add(int $a, int $b) int {
        return $a + $b;
    }

    func multiply(int $a, int $b) int {
        return $a * $b;
    }

    func greet(str $name) str {
        return "Hello, " . $name . "!";
    }

    # Variadic function - receives all args as an array
    func sum_all(int ...@nums) int {
        my int $total = 0;
        foreach my int $n (@nums) {
            $total = $total + $n;
        }
        return $total;
    }

Compile it as a shared library:

    ./stradac -shared math_lib.strada libmath.so

Use from Perl:

    use Strada;

    my $lib = Strada::Library->new('./libmath.so');

    # Get library info
    print "Version: ", $lib->version(), "\n";
    print $lib->describe(), "\n";

    # Get function details programmatically
    my $funcs = $lib->functions();
    for my $name (keys %$funcs) {
        print "Function: $name returns $funcs->{$name}{return}";
        print " (variadic)" if $funcs->{$name}{is_variadic};
        print "\n";
    }

    # Both calling conventions work:
    print $lib->call('math_lib_add', 2, 3), "\n";      # 5 (direct C name)
    print $lib->call('math_lib::add', 2, 3), "\n";     # 5 (Perl/Strada style)
    print $lib->call('math_lib::multiply', 4, 5), "\n"; # 20
    print $lib->call('math_lib::greet', 'Perl'), "\n";  # Hello, Perl!

    # Calling variadic functions - pass array reference
    print $lib->call('math_lib::sum_all', [1, 2, 3, 4, 5]), "\n";  # 15

    $lib->unload();

=head1 BUILDING

    perl Makefile.PL
    make
    make test
    make install

=head1 REQUIREMENTS

- Strada runtime headers (strada_runtime.h)
- Perl development headers

=head1 AUTHOR

Michael J. Flickinger

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Michael J. Flickinger

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut
