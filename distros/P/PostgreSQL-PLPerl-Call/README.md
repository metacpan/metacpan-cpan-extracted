# NAME

PostgreSQL::PLPerl::Call - Simple interface for calling SQL functions from PostgreSQL PL/Perl

# VERSION

version 1.007

# SYNOPSIS

    use PostgreSQL::PLPerl::Call;

Returning single-row single-column values:

    $pi = call('pi'); # 3.14159265358979

    $net = call('network(inet)', '192.168.1.5/24'); # '192.168.1.0/24';

    $seqn = call('nextval(regclass)', $sequence_name);

    $dims = call('array_dims(text[])', '{a,b,c}');   # '[1:3]'

    # array arguments can be perl array references:
    $ary = call('array_cat(int[], int[])', [1,2,3], [2,1]); # '{1,2,3,2,1}'

Returning multi-row single-column values:

    @ary = call('generate_series(int,int)', 10, 15); # (10,11,12,13,14,15)

Returning single-row multi-column values:

    # assuming create function func(int) returns table (r1 text, r2 int) ...
    $row = call('func(int)', 42); # returns hash ref { r1=>..., r2=>... }

Returning multi-row multi-column values:

    @rows = call('pg_get_keywords'); # ({...}, {...}, ...)

Alternative method-call syntax:

    $pi   = PG->pi();
    $seqn = PG->nextval($sequence_name);

Here `PG` simply means PostgreSQL. (`PG` is actually an imported constant whose
value is the name of a package containing an AUTOLOAD function that dispatches
to `call()`. In case you wanted to know.)

# DESCRIPTION

The `call` function provides a simple efficient way to call SQL functions
from PostgreSQL PL/Perl code.

The first parameter is a _signature_ that specifies the name of the function
to call and, optionally, the types of the arguments.

Any further parameters are used as argument values for the function being called.

## Signature

The first parameter to `call()` is a _signature_ that specifies the name of
the function.

Immediately after the function name, in parenthesis, a comma separated list of
type names can be given. For example:

    'pi'
    'generate_series(int,int)'
    'array_cat(int[], int[])'
    'myschema.myfunc(date, float8)'

The types specify how the _arguments_ to the call should be interpreted.
They don't have to exactly match the types used to declare the function you're
calling.

You also don't have to specify types for _all_ the arguments, just the
left-most arguments that need types.

The function name should be given in the same way it would in an SQL statement,
so if identifier quoting is needed it should be specified already enclosed in
double quotes.  For example:

    call('myschema."Foo Bar"');

## Array Arguments

The argument value corresponding to a type that contains '`[]`' can be a
string formated as an array literal, or a reference to a perl array. In the
later case the array reference is automatically converted into an array literal
using the `encode_array_literal()` function.

## Varadic Functions

Functions with `variadic` arguments can be called with a fixed number of
arguments by repeating the type name in the signature the same number of times.
For example, given:

    create function vary(VARIADIC int[]) as ...

you can call that function with three arguments using:

    call('vary(int,int,int)', $int1, $int2, $int3);

Alternatively, you can append the string '`...`' to the last type in the
signature to indicate that the argument is variadic. For example:

    call('vary(int...)', @ints);

Type names must be included in the signature in order to call variadic functions.

Functions with a variadic argument must have at least one value for that
argument. Otherwise you'll get a "function ... does not exist" error.

## Method-call Syntax

An alternative syntax can be used for making calls:

    PG->function_name(@args)

For example:

    $pi   = PG->pi();
    $seqn = PG->nextval($sequence_name);

Using this form you can't easily specify a schema name or argument types, and
you can't call variadic functions. (For various technical reasons.)
In cases where a signature is needed, like variadic or polymorphic functions,
you might get a somewhat confusing error message. For example:

    PG->generate_series(10,20);

fails with the error "there is no parameter $1". The underlying problem is that
`generate_series` is a polymorphic function: different versions of the
function are executed depending on the type of the arguments.

## Wrapping and Currying

It's simple to wrap a call into an anonymous subroutine and pass that code
reference around. For example:

    $nextval_fn = sub { PG->nextval(@_) };
    ...
    $val = $nextval_fn->($sequence_name);

or

    $some_func = sub { call('some_func(int, date[], int)', @_) };
    ...
    $val = $some_func->($foo, \@dates, $debug);

You can take this approach further by specifying some of the arguments in the
anonymous subroutine so they don't all have to be provided in the call:

    $some_func = sub { call('some_func(int, date[], int)', $foo, shift, $debug) };
    ...
    $val = $some_func->(\@dates);

## Results

The `call()` function processes return values in one of four ways depending on
two criteria: single column vs. multi-column results, and list context vs scalar context.

If the results contain a single column with the same name as the function that
was called, then those values are extracted and returned directly. This makes
simple calls very simple:

    @ary = call('generate_series(int,int)', 10, 15); # (10,11,12,13,14,15)

Otherwise, the rows are returned as references to hashes:

    @rows = call('pg_get_keywords'); # ({...}, {...}, ...)

If the `call()` function was executed in list context then all the values/rows
are returned, as shown above.

If the function was executed in scalar context then an exception will be thrown
if more than one row is returned. For example:

    $foo = call('generate_series(int,int)', 10, 10); # 10
    $bar = call('generate_series(int,int)', 10, 11); # dies

If you only want the first result you can use list context;

    ($bar) =  call('generate_series(int,int)', 10, 11);
     $bar  = (call('generate_series(int,int)', 10, 11))[0];

# ENABLING

In order to use this module you need to arrange for it to be loaded when
PostgreSQL initializes a Perl interpreter.

Create a `plperlinit.pl` file in the same directory as your
`postgres.conf` file, if it doesn't exist already.

In the `plperlinit.pl` file write the code to load this module.

## PostgreSQL 8.x

Set the `PERL5OPT` before starting postgres, to something like this:

    PERL5OPT='-e "require q{plperlinit.pl}"'

The code in the `plperlinit.pl` should also include `delete $ENV{PERL5OPT};`
to avoid any problems with nested invocations of perl, e.g., via a `plperlu`
function.

## PostgreSQL 9.0

For PostgreSQL 9.0 you can still use the `PERL5OPT` method described above.
Alternatively, and preferably, you can use the `plperl.on_init` configuration
variable in the `postgres.conf` file.

    plperl.on_init='require q{plperlinit.pl};'

# plperl

You can use the [PostgreSQL::PLPerl::Injector](https://metacpan.org/pod/PostgreSQL%3A%3APLPerl%3A%3AInjector) module to make the
call() function available for use in the `plperlu` language:

    use PostgreSQL::PLPerl::Injector;
    inject_plperl_with_names_from(PostgreSQL::PLPerl::Call => 'call'); 

# OTHER INFORMATION

## Performance

Internally `call()` uses `spi_prepare()` to create a plan to execute the
function with the typed arguments.

The plan is cached using the call 'signature' as the key. Minor variations in
the signature will still reuse the same plan.

For variadic functions, separate plans are created and cached for each distinct
number of arguments the function is called with.

## Limitations and Caveats

Requires PostgreSQL 9.0 or later.

Types that contain a comma can't be used in the call signature. That's not a
problem in practice as it only affects '`numeric(p,s)`' and '`decimal(p,s)`'
and the '`,s`' part isn't needed. Typically the '`(p,s)`' portion isn't used in
signatures.

The return value of functions that have a `void` return type should not be
relied upon, naturally.

## Author and Copyright

Tim Bunce [http://www.tim.bunce.name](http://www.tim.bunce.name)

Copyright (c) Tim Bunce, Ireland, 2010. All rights reserved.
You may use and distribute on the same terms as Perl 5.10.1.

With thanks to [http://www.TigerLead.com](http://www.TigerLead.com) for sponsoring development.

# LICENSE

Copyright (C) Veesh Goldman 2020 -

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Veesh Goldman <rabbiveesh@gmail.com>
