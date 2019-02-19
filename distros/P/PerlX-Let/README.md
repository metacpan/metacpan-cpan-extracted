# NAME

PerlX::Let - Syntactic sugar for lexical constants

# VERSION

version v0.2.5

# SYNOPSIS

```perl
use PerlX::Let;

let $x = 1,
    $y = "string" {

    if ( ($a->($y} - $x) > ($b->{$y} + $x) )
    {
      something( $y, $x );
    }

}
```

# DESCRIPTION

This module allows you to define lexical constants using a new `let`
keyword, for example, code such as

```perl
if (defined $arg{username}) {
  $row->update( { username => $arg{username} );
}
```

is liable to typos. You could simplify it with

```perl
let $key = "username" {

  if (defined $arg{$key}) {
    $row->update( { $key => $arg{$key} );
  }

}
```

This is roughly equivalent to using

```perl
use Const::Fast;

{
  const $key => "username";

  if (defined $arg{$key}) {
    $row->update( { $key => $arg{$key} );
  }

}
```

However, if the value does not contain a sigil, and the variable is a
scalar, or you are using Perl v5.28 or later, this uses state
variables so that the value is only set once.

If the code block is omitted, then this can be used to declare a
state constant in the current scope, e.g.

```
let $x = "foo";

say $x;
```

# KNOWN ISSUES

The parsing of assignments is rudimentary, and may fail when assigning
to another variable or the result of a function.

Because this modifies the source code during compilation, the line
numbers may be changed.

# SEE ALSO

[Const::Fast](https://metacpan.org/pod/Const::Fast)

[Keyword::Simple](https://metacpan.org/pod/Keyword::Simple)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
