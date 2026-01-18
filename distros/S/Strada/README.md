# Strada - Perl XS Module

This Perl XS module allows Perl programs to load and call functions from compiled Strada shared libraries.

## Overview

The `Strada` module provides a bridge from Perl to Strada, enabling you to:
- Load Strada shared libraries (.so files)
- Call Strada functions with automatic type conversion
- Pass Perl scalars, arrays, and hashes to Strada
- Receive Strada return values as Perl types
- Inspect library metadata (version, function signatures)

## Installation

### Prerequisites

- Perl 5.10 or later
- Strada compiler and runtime (from parent directory)
- C compiler (gcc)

### Build Steps

```bash
cd perl/Strada
perl Makefile.PL
make
make test
make install  # optional, installs system-wide
```

### Specifying Strada Location

By default, the build looks for the Strada runtime in these locations (in order):

1. `STRADA_ROOT` environment variable
2. `STRADA_ROOT=` command line argument
3. System install (`/usr/local/include/strada` or `/usr/include/strada`)
4. Source tree (`../..` - assumes building from within the Strada repo)

If Strada is installed elsewhere, specify the path:

```bash
# Via command line argument
perl Makefile.PL STRADA_ROOT=/path/to/strada

# Via environment variable
STRADA_ROOT=/path/to/strada perl Makefile.PL
```

The path should point to either:
- The Strada source directory (containing `runtime/strada_runtime.h`)
- An installed location (containing `strada_runtime.h` directly)

## Usage

### High-Level API (Recommended)

```perl
use Strada;

# Load a Strada shared library
my $lib = Strada::Library->new('./libmath.so');

# Get library info
print "Version: ", $lib->version(), "\n";
print $lib->describe(), "\n";

# Call functions using package::function syntax (recommended)
my $sum = $lib->call('math_lib::add', 10, 20);       # 30
my $greeting = $lib->call('math_lib::greet', 'Perl'); # "Hello, Perl!"

# Or use the C-style name directly
my $sum2 = $lib->call('math_lib_add', 10, 20);       # 30

# Pass arrays
my $total = $lib->call('math_lib::sum_array', [1, 2, 3, 4, 5]);

# Pass hashes
my $desc = $lib->call('math_lib::describe_person', { name => 'Alice', age => 30 });

# Receive arrays
my $nums = $lib->call('math_lib::get_numbers');  # Returns arrayref

# Receive hashes
my $person = $lib->call('math_lib::get_person'); # Returns hashref

# Unload when done
$lib->unload();
```

### Inspecting Library Functions

```perl
use Strada;

my $lib = Strada::Library->new('./libmath.so');

# Get formatted description (like strada-soinfo tool)
print $lib->describe();
# Output:
# # Strada Library: ./libmath.so
# # Version: 1.0.0
# # Functions: 3
# #
# #   func math_lib_add(int $a, int $b) int
# #   func math_lib_greet(str $a) str
# #   func math_lib_sum_array(scalar $a) int

# Get function details programmatically
my $funcs = $lib->functions();
for my $name (sort keys %$funcs) {
    my $f = $funcs->{$name};
    print "Function: $name\n";
    print "  Returns: $f->{return}\n";
    print "  Params:  ", join(", ", @{$f->{params}}), "\n";
}
```

### Low-Level API

```perl
use Strada;

# Load library, get handle
my $handle = Strada::load('./libmath.so');
die "Failed to load" unless $handle;

# Get function pointer
my $func = Strada::get_func($handle, 'math_lib_add');
die "Function not found" unless $func;

# Call function
my $result = Strada::call($func, 2, 3);
print "2 + 3 = $result\n";

# Unload
Strada::unload($handle);
```

## Creating Strada Shared Libraries

### 1. Write a Strada Library

```strada
# math_lib.strada
package math_lib;
version "1.0.0";

func add(int $a, int $b) int {
    return $a + $b;
}

func greet(str $name) str {
    return "Hello, " . $name . "!";
}

func sum_array(scalar $arr) int {
    my int $total = 0;
    my int $len = length($arr);
    my int $i = 0;
    while ($i < $len) {
        $total = $total + $arr->[$i];
        $i = $i + 1;
    }
    return $total;
}
```

### 2. Compile as Shared Library

```bash
./strada --shared math_lib.strada
# Creates: math_lib.so
```

### 3. Use from Perl

```perl
use Strada;

my $lib = Strada::Library->new('./math_lib.so');
print $lib->call('math_lib::add', 1, 2), "\n";  # 3
$lib->unload();
```

## Function Naming Convention

Strada functions are exported with the naming pattern:
```
<package>_<function>
```

For example:
- `package math_lib` + `func add()` = `math_lib_add`
- `package utils` + `func format_date()` = `utils_format_date`

When calling from Perl, you can use either format:
- `$lib->call('math_lib_add', ...)` - C-style name
- `$lib->call('math_lib::add', ...)` - Perl/Strada style (automatically converted)

## Type Conversion

| Strada Type | Perl Type |
|-------------|-----------|
| int | IV (integer) |
| num | NV (floating point) |
| str | PV (string) |
| array | Array reference |
| hash | Hash reference |
| undef | undef |
| ref | Dereferenced value |

## Limitations

- Maximum of 4 arguments per function call
- Complex nested references may not convert perfectly
- Strada objects/classes are not directly supported

## Example Directory

The `example/` subdirectory contains:
- `math_lib.strada` - Example Strada library source
- `build.sh` - Script to compile the example library
- The compiled `libmath.so` after running build.sh

## API Reference

### Low-Level Functions

#### Strada::load($path)

Load a Strada shared library. Returns a handle (integer) on success, 0 on failure.

#### Strada::unload($handle)

Unload a previously loaded library.

#### Strada::get_func($handle, $name)

Get a function pointer by name. Returns the pointer on success, 0 if not found.

#### Strada::call($func, @args)

Call a Strada function with 0-4 arguments. Returns the result converted to Perl.

#### Strada::get_export_info($handle)

Get the raw export metadata string from a Strada library. Returns empty string for non-Strada libraries.

#### Strada::get_version($handle)

Get the version string from a Strada library. Returns empty string if not available.

### High-Level OO Interface

#### Strada::Library->new($path)

Create a Library object, loading the specified shared library. Dies on failure.

#### $lib->call($func_name, @args)

Call a function by name with arguments. Supports both `package_func` and `package::func` naming styles. Caches function pointers for efficiency.

#### $lib->version()

Returns the library version string, or empty string if not set.

#### $lib->functions()

Returns a hash reference describing all exported functions:

```perl
{
    'math_lib_add' => {
        return      => 'int',
        param_count => 2,
        params      => ['int', 'int'],
    },
    ...
}
```

#### $lib->describe()

Returns a formatted string describing all functions (similar to `strada-soinfo` output):

```
# Strada Library: ./math_lib.so
# Version: 1.0.0
# Functions: 3
#
#   func math_lib_add(int $a, int $b) int
#   func math_lib_greet(str $a) str
#   func math_lib_sum_array(scalar $a) int
```

#### $lib->unload()

Unload the library and clear cached function pointers.

## See Also

- `lib/perl5/` - The reverse integration (calling Perl from Strada)
- `docs/LANGUAGE_GUIDE.md` - Strada language documentation
- `docs/RUNTIME_API.md` - Strada runtime API reference
- `strada-soinfo` - Command-line tool to inspect Strada shared libraries
