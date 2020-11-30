# NAME

PerlX::Let - Syntactic sugar for lexical state constants

# VERSION

version v0.2.8

# SYNOPSIS

```perl
use PerlX::Let;

{

    let $x = 1;
    let $y = "string";

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
{
    let $key = "username";

    if (defined $arg{$key}) {
        $row->update( { $key => $arg{$key} );
    }

}
```

This is roughly equivalent to using

```perl
use Const::Fast ();

{
    use feature 'state';

    state $key = "username";

    unless (state $_flag = 0) {
        Const::Fast::_make_readonly( \$key );
        $_flag = 1;
    }

    if (defined $arg{$key}) {
        $row->update( { $key => $arg{$key} );
    }

}
```

However, if the value contains a sigil, or (for versions of Perl
before 5.28) the value is not a scalar, then this uses a my variable

```perl
use Const::Fast ();

{
    Const::Fast::const my $key => "username";

    if (defined $arg{$key}) {
        $row->update( { $key => $arg{$key} );
    }
}
```

The reason for using state variables is that it takes time to mark a
variable as read-only, particularly for deeper data structures.
However, the tradeoff for using this is that the variables remain
allocated until the process exits.

# DEPRECATED SYNTAX

Adding a code block after the let assignment is deprecated:

```
let $x = "foo" {
  ...
}
```

Instead, put the assignment inside of the block.

Specifying multiple assignments is also deprecated:

```
let $x = "foo",
    $y = "bar";
```

Instead, use multiple let statements.

# KNOWN ISSUES

A let assignment will enable the state feature inside of the current
context.

The parsing of assignments is rudimentary, and may fail when assigning
to another variable or the result of a function.  Because of this,
you may get unusual error messages for syntax errors, e.g.
"Transliteration pattern not terminated".

Because this modifies the source code during compilation, the line
numbers may be changed, particularly if the let assignment(s) are on
multiple lines.

# SEE ALSO

[feature](https://metacpan.org/pod/feature)

[Const::Fast](https://metacpan.org/pod/Const::Fast)

[Keyword::Simple](https://metacpan.org/pod/Keyword::Simple)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
