# NAME

PerlX::Let - Syntactic sugar for lexical state constants

# VERSION

version v0.3.0

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

# SUPPORT FOR OLDER PERL VERSIONS

The this module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten years.

# SEE ALSO

[feature](https://metacpan.org/pod/feature)

[Const::Fast](https://metacpan.org/pod/Const%3A%3AFast)

[Keyword::Simple](https://metacpan.org/pod/Keyword%3A%3ASimple)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
