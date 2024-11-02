# Physics/Unit

Version 0.54

This tarball includes the following modules:

* `Physics::Unit`
* `Physics::Unit::Scalar`
* `Physics::Unit::Scalar::Implementation` - pod docs
* `Physics::Unit::Script`
* `Physics::Unit::Script::GenPages`
* `Physics::Unit::Implementation` - pod docs

Objects of class `Physics::Unit` define units of measurement that correspond
to physical quantities.  This module allows you to manipulate these units,
generate new derived units from other units, and convert from one unit
to another.  Each unit is defined by a conversion factor and a
dimensionality vector.

Objects of type `Physics::Unit::Scalar` store physical quantities.  Each
instance of a class that derives from `Physics::Unit::Scalar` holds the value
of some type of measurable quantity.  When you use this module, several new
classes are immediately available.  See the Derived Classes section of the
documentation for a complete list

The module `Physics::Unit::ScalarSubtypes` defines several classes that
derive from `Physics::Unit::Scalar`, each corresponding to a different
physical quantity.

## See also

The perldoc documentation for each of the above modules for more
information.

Example scripts in the eg/ directory.

## Installation

To install this module, on Unix, use the following:

```sh
perl Build.PL
./Build
./Build test
./Build install
```

On Windows, from a command window:

```
perl Build.PL
Build
Build test
Build install
```

## Dependencies

This module is pure Perl, and it depends only on Carp.
