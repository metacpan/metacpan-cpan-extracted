package Strada;

use strict;
use warnings;

our $VERSION = '0.01';

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

Call a Strada function with arguments. Up to 4 arguments supported.

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
            return      => 'int',      # Return type
            param_count => 2,          # Number of parameters
            params      => ['int', 'str'],  # Parameter types
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

    return Strada::call($func, @args);
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
# Returns a hash ref: { func_name => { return => 'type', params => [...], param_count => N } }
sub functions {
    my ($self) = @_;

    my $info = Strada::get_export_info($self->{handle});
    return {} unless $info;

    my %funcs;
    for my $line (split /\n/, $info) {
        next unless $line =~ /^func:/;

        # Format: func:name:return_type:param_count:param_types
        my @parts = split /:/, $line;
        next unless @parts >= 4;

        my $name = $parts[1];
        my $ret = $parts[2];
        my $param_count = $parts[3];
        my @param_types = $parts[4] ? split(/,/, $parts[4]) : ();

        $funcs{$name} = {
            return      => $ret,
            param_count => $param_count,
            params      => \@param_types,
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
        for my $type (@{$f->{params}}) {
            my $var = chr(ord('a') + $i);
            $var = "arg$i" if $i >= 26;
            push @params, "$type \$$var";
            $i++;
        }
        my $sig = "func $name(" . join(", ", @params) . ") $f->{return}";
        push @lines, "#   $sig";
    }

    return join("\n", @lines);
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
        print "Function: $name returns $funcs->{$name}{return}\n";
    }

    # Both calling conventions work:
    print $lib->call('math_lib_add', 2, 3), "\n";      # 5 (direct C name)
    print $lib->call('math_lib::add', 2, 3), "\n";     # 5 (Perl/Strada style)
    print $lib->call('math_lib::multiply', 4, 5), "\n"; # 20
    print $lib->call('math_lib::greet', 'Perl'), "\n";  # Hello, Perl!

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
