Here are the updated documentation sections for **Store::Indexed**, reflecting the functional design of the XS and PP backends provided.

---

# Store::Indexed(3)

## NAME

**Store::Indexed** - A fast, key-indexed data store with dual XS and Pure-Perl backends.

## SYNOPSIS

```perl
use Store::Indexed;

# Auto-detects best backend (XS preferred)
my $store = Store::Indexed->new(qw(key1 key2 key3));

# Or force a specific backend
use Store::Indexed ':xs';
my $store = Store::Indexed->new(qw(key1 key2));

# Accessors are generated dynamically based on keys
$store->set_key1(0, "value_for_id_0");
my $val = $store->get_key1(0);

```

## DESCRIPTION

**Store::Indexed** provides an interface for storing and retrieving data points indexed by an integer ID and a column name. It uses a flat array structure under the hood to achieve high performance. It supports both a highly optimized C-based implementation (`XS`) and a portable `Pure-Perl` implementation (`PP`).

## IMPORT TAGS

* `:xs` - Forces the use of the `Store::Indexed::XS` backend.
* `:pp` - Forces the use of the `Store::Indexed::PP` backend.

## METHODS

### new(@keys)

Creates a new `Store::Indexed` instance. The list of `@keys` defines the fixed columns of the data store. This will dynamically generate `get_$key`, `set_$key`, `exists_$key`, and `delete_$key` methods for each key provided.

### Dynamic Accessors

For every key defined in `new()`, the following methods are injected into the class:

* `get_$key($id)`: Returns the value at row `$id` and column `$key`.
* `set_$key($id, $value)`: Sets the value at row `$id` and column `$key`.
* `exists_$key($id)`: Returns true if a value exists at that location.
* `delete_$key($id)`: Removes the value at that location.

---

# Store::Indexed::XS(3)

## DESCRIPTION

The `XS` backend provides a memory-efficient implementation. It uses a blessed scalar reference to point to a C-allocated buffer or a managed array structure, minimizing the memory overhead associated with Perl hashes. It is intended for production environments where performance and memory footprint are critical.

## REQUIREMENTS

* A C compiler (e.g., `gcc`, `clang`)
* Perl 5.10+

---

# Store::Indexed::PP(3)

## DESCRIPTION

The `PP` (Pure-Perl) backend provides a fallback implementation for environments where compiling C extensions is not possible (e.g., restricted hosting, cross-compilation targets).

## IMPLEMENTATION

The `PP` version maintains data in a single, flat Perl array. It calculates indices using the formula `index = row * total_columns + column_offset`. This avoids the overhead of complex data structures while remaining entirely portable.

---

## ENVIRONMENT

* `STORE_BACKEND`: Set to `XS` or `PP` to globally define the preferred backend for the current process.

---

## SEE ALSO

`XSLoader`, `perlxs`, `perlobject`

---

