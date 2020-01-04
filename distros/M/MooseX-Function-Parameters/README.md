# MooseX::Function::Parameters

A lightweight wrapper around [`Function::Parameters`][1] which provides `fun`
and `method` subroutine keywords which integrate with the Moose type system.

Designed to be compatible with Function::Parameters version 1, where newer
versions of Function::Parameters aren't.

#### Usage

Writing functions:

```
use MooseX::Function::Parameters;

fun add (Int $a, Int $b) {
    $a + $b
}
```

Writing methods:

```
package My::Class;
use Moose;
use MooseX::Function::Parameters;

method compare (My::Class $with) {
    $self->value <=> $with->value
}
```

[1]: https://metacpan.org/pod/Function::Parameters
