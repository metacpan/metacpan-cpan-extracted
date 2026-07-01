# NAME

Params::Get - Normalise subroutine arguments regardless of calling convention

# VERSION

Version 0.15

# DESCRIPTION

`Params::Get` exports a single function, `get_params`, which accepts a
caller's argument list (or a reference to it) in any of the common Perl
calling conventions and returns a unified hash-ref.  Library authors can
write one normalisation call at the top of every public method rather than
hand-rolling the same conditional chains in each one.

When combined with [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) and [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) you can
formally specify and enforce the input and output contracts of every method.

# SYNOPSIS

    use Params::Get qw(get_params);
    use Params::Validate::Strict;

    sub where_am_i {
        my $params = Params::Validate::Strict::validate_strict({
            args   => get_params(undef, \@_),
            schema => {
                latitude  => { type => 'number', min => -90,  max =>  90 },
                longitude => { type => 'number', min => -180, max => 180 },
            },
        });
        printf "You are at %s, %s\n",
            $params->{latitude}, $params->{longitude};
    }

    where_am_i(latitude => 0.3, longitude => 124);
    where_am_i({ latitude => 3.14, longitude => -155 });

# METHODS

## get\_params

Parse the argument list passed to a subroutine and return a unified hash-ref
regardless of the calling convention used.  Supported conventions:

- Single hash-ref: `foo({ a => 1 })`
- Named key/value pairs: `foo(a => 1, b => 2)`
- Single scalar with a default key: `foo('US')` given `get_params('country', @_)`
- Array-ref shorthand: `foo(\@_)` inside the callee
- Mandatory positional argument plus an options hash-ref:
`Obj->new($val, { opt => 1 })`
- Scalar-ref: `foo(\'text')` -- dereferenced automatically
- Blessed object or CODE ref: mapped under `$default`
- Array-ref of positional key names as `$default`:
`get_params([qw(name age)], @_)`

### ARGUMENTS

- `$default` (scalar string, arrayref of strings, or `undef`)

    Controls how a single non-hash argument is interpreted:

    - **string** -- used as the key name when a lone scalar, ref, or object
    is received.
    - **arrayref of strings** -- positional key names; the _n_th argument
    is mapped to the _n_th name.  Extra arguments are silently discarded;
    missing arguments produce `undef` values.
    - **undef** -- no default key; the caller must pass named pairs or a
    single hash-ref.  An empty argument list returns `undef`.

- `@args`

    The caller's argument list, passed either as a flat list (`@_`) or as a
    reference to the array (`\@_`).  Both forms are accepted transparently.

### RETURNS

A hash-ref on success, or `undef` when `$default` is `undef` and no
arguments are provided.

### SIDE EFFECTS

Croaks from the caller's frame on programming errors (wrong calling
convention, non-ARRAY ref passed as `$default`).  Confesses with a full
stack trace when `$default` is defined but zero arguments are received,
because that almost always indicates a programming error.

### API SPECIFICATION

#### Input

        {
                default => {
                        type => [ 'string', 'stringref' ],
                        optional => 1,
                        position => 0,
                }, args => {
                        type => [ 'array', 'arrayref' ],
                        optional => 1,
                        position => 1,
                }
        }

#### output

    {
        type => 'hashref',
        optional => 1,
    }

### MESSAGES

    Message                                             Meaning                                Resolution
    --------------------------------------------------  -------------------------------------  ----------------------------------------------
    ::get_params: $default must be a scalar or          A non-ARRAY ref was passed as          Pass a plain string, arrayref of strings,
      arrayref                                          $default                               or undef
    Usage: Pkg->method($key => $val)  [stack trace]    $default is defined but no args given  Ensure the caller always passes a value
    Usage: Pkg->method()                               Odd-length or unrecognisable arg list  Correct the calling convention in the caller

### PSEUDOCODE

    1.  Fast-path: if the sole argument is a plain HASH ref, return it
        immediately (fires before $default is inspected -- see LIMITATIONS).

    2.  Shift $default.  Validate: must be undef, a plain scalar, or an
        ARRAY ref.  Any other ref type croaks immediately.

    3.  If $default is an ARRAY ref, map remaining @_ positionally to those
        key names and return.  A single plain HASH ref is still passed
        through unchanged.

    4.  Detect the \@_ calling convention: if exactly one ARRAY ref argument
        remains, check the two-element (key => scalar-val) shorthand and
        return immediately when it matches.  Otherwise unwrap and use the
        array contents as the effective @args.

    5.  Dispatch on argument count:
        0 -- confess (with stack trace) if $default is defined;
             return undef otherwise.
        1 -- if $default is defined, wrap the single arg under $default
             (scalar, arrayref, scalarref->deref, coderef, blessed object).
             Without $default: unwrap REF-of-REF, pass HASH ref through,
             return empty ARRAY ref as-is.  Anything else: croak.
        2 with HASH ref as arg[1]
          -- Mandatory-positional + options-hashref pattern.
        even N -- treat as flat key/value pairs.
        odd N  -- croak.

# LIMITATIONS

- **Single empty arrayref cannot be distinguished from `\@_` of an empty list**

    When the caller does `foo([])` and the callee uses `get_params('key', @_)`,
    the `@_` list is `([])` -- one element, an arrayref.  The function
    interprets the lone arrayref as a `\@_` passthrough, unwraps it to an empty
    list, and then croaks because `$default` is defined but there are zero
    arguments.  Workaround: pass the value as a named pair
    (`key => []`) or ensure the callee always uses `\@_`.

- **Single hash ref always bypasses `$default` key naming**

    `get_params('config', { a => 1 })` returns `{ a => 1 }`, not
    `{ config => { a => 1 } }`.  The fast path fires before `$default`
    is inspected.  To store a hash ref under a default key, pass it as a named
    pair: `get_params('config', config => { a => 1 })`.

- **No mechanism to mark a `$default` argument as optional**

    When `$default` is a string and zero arguments are received, the function
    always confesses.  There is no way to express _"accept zero args and return
    undef gracefully"_.

- **Duplicate keys in a flat list silently overwrite; last value wins**

    `get_params(undef, foo => 1, foo => 2)` returns `{ foo => 2 }`
    with no warning.  If an attacker controls part of the argument list, a
    later duplicate key can silently override an earlier sanitised value.
    Detect and reject duplicate keys in the validation layer (e.g.
    [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)) rather than relying on `get_params` to catch
    them.

- **Positional-names `$default` silently discards extra arguments**

    `get_params([qw(a b)], 1, 2, 3)` returns `{ a => 1, b => 2 }`
    and ignores `3`.  If strict arity is required, validate the returned hash
    with [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs or feature requests to `bug-params-get at rt.cpan.org`
or through [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get).

# SEE ALSO

- [Params::Smart](https://metacpan.org/pod/Params%3A%3ASmart)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)
- [Test Dashboard](https://nigelhorne.github.io/Params-Get/coverage/)

# SUPPORT

- MetaCPAN: [https://metacpan.org/dist/Params-Get](https://metacpan.org/dist/Params-Get)
- RT: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get)
- CPAN Testers: [http://matrix.cpantesters.org/?dist=Params-Get](http://matrix.cpantesters.org/?dist=Params-Get)
- CPAN Testers Dependencies: [http://deps.cpantesters.org/?module=Params::Get](http://deps.cpantesters.org/?module=Params::Get)

## FORMAL SPECIFICATION

### get\_params

    Let D = default key (Str | [Str*] | undef), A = argument tuple.

    get_params : D x A* -> HashRef | Undef

    -- Fast path (fires before D is inspected -- see LIMITATIONS)
    get_params(D, h)            == h             when |A|=1, h:HashRef

    -- Positional-names default
    get_params([n1..nk], v*)    == {ni -> vi}    i in 1..k, vi = undef when missing

    -- Scalar default, single arg
    get_params(d, s)            == {d -> s}      d:Str, s:Scalar
    get_params(d, a)            == {d -> a}      d:Str, a:ArrayRef
    get_params(d, \s)           == {d -> s}      d:Str (scalarref dereferenced)
    get_params(d, c)            == {d -> c}      d:Str, c:CodeRef
    get_params(d, o)            == {d -> o}      d:Str, o:BlessedObject

    -- Mandatory-positional + options-hashref
    get_params(d, v, {k->w..})  == {d->v, k->w..}    non-empty opts
    get_params(d, d, {k->w..})  == {d -> {k->w..}}   first arg IS the key name

    -- Named pairs
    get_params(undef, k1,v1..)  == {ki -> vi}    when |A| is even

    -- Empty / error
    get_params(undef)           == undef
    get_params(d)               => confess       d:Str (missing required arg)
    get_params(D, odd-list)     => croak

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.  If you use this module,
please let me know.
