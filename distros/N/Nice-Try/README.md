# NAME

Nice::Try - A real Try Catch Block Implementation Using Perl Filter

# SYNOPSIS

    use Nice::Try;

    print( "Hello, I want to try\n" );
    # Try out {
    print( "this piece of code\n" );
    try 
    {
        # Not so sure }
        print( "I am trying!\n" );
        die( "Bye cruel world..." );
        # Never going to reach this
        return( 1 );
    }
    # Some comment
    catch( Exception $e ) {
        return( "Caught an exception $e" );
    }
    # More comment with space too

    catch( $e ) {
        print( "Got an error: $e\n" );
    }
    finally
    {
        print( "Cleaning up\n" );
    }
    print( "Ok, then\n" );

When run, this would produce, as one would expect:

    Hello, I want to try
    this piece of code
    I am trying!
    Got an error: Bye cruel world... at ./some/script.pl line 18.
    Cleaning up
    Ok, then

Also since version 1.0.0, [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) is **extended** context aware:

    use Want; # an awesome module which extends wantarray
    sub info
    {
        my $self = shift( @_ );
        try
        {
            # Do something
            if( want('OBJECT') )
            {
                return( $self );
            }
            elsif( want('CODE') )
            {
                # dummy code ref for example
                return( sub{ return( $name ); } );
            }
            elsif( want('LIST') )
            {
                return( @some_data );
            }
            elsif( want('ARRAY') )
            {
                return( \@some_data );
            }
            elsif( want('HASH') )
            {
                return({ name => $name, location => $city });
            }
            elsif( want('REFSCALAR') )
            {
                return( \$name );
            }
            elsif( want('SCALAR' ) )
            {
                return( $name ); # regular string
            }
            elsif( want('VOID') )
            {
                return;
            }
        }
        catch( $e )
        {
            $Logger->( "Caught exception: $e" );
        }
    }

    # regular string context
    my $name = $o->info;
    # code context
    my $name = $o->info->();
    # list context like wantarray
    my @data = $o->info;
    # hash context
    my $name = $o->info->{name};
    # array context
    my $name = $o->info->[2];
    # object context
    my $name = $o->info->another_method;
    # scalar reference context
    my $name = ${$o->info};

And you also have granular power in the catch block to filter which exception to handle. See more on this in ["EXCEPTION CLASS"](#exception-class)

    try
    {
        die( Exception->new( "Arghhh" => 401 ) );
    }
    # can also write this as:
    # catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        # Do something to deal with some server error
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        # should reach here.
    }
    catch( $oh_well isa("Exception") ) # or you can also write catch( Exception $oh_well )
    {
        # Default using another way to filter by Exception
    }
    catch( $oopsie where { /Oh no/ } )
    {
        # Do something based on the value of a simple error; not an exception class
    }
    # Default
    catch( $default )
    {
        print( "Unknown error: $default\n" );
    }

# VERSION

    v1.3.5

# DESCRIPTION

[Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) is a lightweight implementation of Try-Catch exception trapping block using [perl filter](https://metacpan.org/pod/perlfilter). It behaves like you would expect. 

Here is a list of its distinctive features:

- No routine to import like `Nice::Try qw( try catch )`. Just add `use Nice::Try` in your script
- Properly report the right line number for the original error message
- Allows embedded try-catch block within try-catch block, such as:

        use Nice::Try;

        print( "Wow, something went awry: ", &gotcha, "\n" );

        sub gotcha
        {
            print( "Hello, I want to try\n" );
            # Try out {
            CORE::say( 'this piece' );
            try 
            {
                # Not so sure }
                print( "I am trying!\n" );
                try
                {
                    die( "Bye cruel world..." );
                    return( 1 );
                }
                catch( $err )
                {
                    die( "Dying again with embedded error: '$err'" );
                }
            }
            catch( Exception $e ) {
                return( "Caught an exception \$e" );
            }
            catch( $e ) {
                try
                {
                    print( "Got an error: $e\n" );
                    print( "Trying something else.\n" );
                    die( "No really, dying out... with error: $e\n" );
                }
                catch( $err2 )
                {
                    return( "Returning from catch L2 with error '$err2'" );
                }
            }
            CORE::say( "Ok, then" );
        }

- No need for semicolon on the last closing brace
- It does not rely on perl regular expression, but instead uses [PPI](https://metacpan.org/pod/PPI) (short for "Perl Parsing Interface").
- Variable assignment in the catch block works. For example:

        try
        {
            # Something or
            die( "Oops\n" );
        }
        catch( $funky_variable_name )
        {
            return( "Oh no: $funky_variable_name" );
        }

- `catch` can filter by exception class. For example:

        try
        {
            die( My::Exception->new( "Not alllowed here.", { code => 401 }) );
        }
        catch( My::Exception $e where { $_->code == 500 })
        {
            print( "Oopsie\n" );
        }
        catch( My::Exception $e where { $_->code == 401 })
        {
            print( "Get away!\n" );
        }
        catch( My::Exception $e )
        {
            print( "Got an exception: $e\n" );
        }
        catch( $default )
        {
            print( "Something weird has happened: $default\n" );
        }
        finally
        {
            $dbh->disconnect;
        }

    See more on this in ["EXCEPTION CLASS"](#exception-class)

- `$@` is always available too
- You can return a value from try-catch blocks, even with embedded try-catch blocks
- It recognises `@_` inside try-catch blocks, so you can do something like:

        print( &gotme( 'Jacques' ), "\n" );

        sub gotme
        {
            try
            {
                print( "I am trying my best $_[0]!\n" );
                die( "But I failed\n" );
            }
            catch( $some_reason )
            {
                return( "Failed: $some_reason" );
            }
        }

    Would produce:

        I am trying my best Jacques!
        Failed: But I failed

- `try` or `catch` blocks can contain flow control keywords such as `next`, `last` and `redo`

        while( defined( my $product = $items->[++$i] ) )
        {
            try
            {
                # Do something
                last if( !$product->active );
            }
            catch( $oops )
            {
                $log->( "Error: $oops" );
                last;
            }
        }
        continue
        {
            try
            {
                if( $product->region eq 'Asia' )
                {
                    push( @asia, $product );
                }
                else
                {
                    next;
                }
            }
            catch( $e )
            {
                $log->( "An unexpected error has occurred. Is $product an object? $e" );
                last;
            }
        }

- Can be used with or without a `catch` block
- Supports a `finally` block called in void context for cleanup for example. The `finally` block will always be called, if present.

        #!/usr/local/bin/perl
        use v5.36;
        use strict;
        use warnings;
        use Nice::Try;
        
        try
        {
            die( "Oops" );
        }
        catch( $e )
        {
            say "Caught an error: $e";
            die( "Oops again" );
        }
        finally
        {
            # Some code here that will be executed after the catch block dies
            say "Got here in finally with \$\@ -> $@";
        }

    The above would yield something like:

        Caught error: Oops at ./test.pl line 9.
        Oops again at ./test.pl line 14.
        Got here in finally with $@ -> Oops again at ./test.pl line 14.

- [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) is rich context aware, which means it can provide you with a super granular context on how to return data back to the caller based on the caller's expectation, by using a module like [Want](https://metacpan.org/pod/Want).
- Call to ["caller" in perlfunc](https://metacpan.org/pod/perlfunc#caller) will return the correct entry in call stack

        #!/usr/bin/perl
        BEGIN
        {
            use strict;
            use warnings;
            use Nice::Try;
        };

        {
            &callme();
        }

        sub callme
        {
            try
            {
                my @info = caller(1); # or my @info = caller;
                print( "Called from package $info[0] in file $info[1] at line $info[2]\n" );
            }
            catch( $e )
            {
                print( "Got an error: $e\n" );
            }
        }

    Will yield: `Called from package main in file ./test.pl at line 10`

# WHY USE IT?

There are quite a few implementations of try-catch blocks in perl, and they can be grouped in 4 categories:

- 1 Try-Catch as subroutines

    For example [Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny)

- 2 Using Perl Filter

    For example [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry), [Try::Harder](https://metacpan.org/pod/Try%3A%3AHarder)

- 3 Using [Devel::Declare](https://metacpan.org/pod/Devel%3A%3ADeclare)

    For example [TryCatch](https://metacpan.org/pod/TryCatch)

- 4 Others

    For example [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry) and now perl with [version 5.34.0 using experimental feature](https://perldoc.perl.org/5.34.0/perldelta#Experimental-Try/Catch-Syntax).

Group 1 requires the use of semi-colons like:

    try
    {
        # Something
    }
    catch
    {
        # More code
    };

It also imports the subroutines `try` and `catch` in your namespace.

And you cannot do exception variable assignment like `catch( $err )`

In group 2, [Try::Harder](https://metacpan.org/pod/Try%3A%3AHarder) does a very nice work, but relies on perl regular expression with [Text::Balanced](https://metacpan.org/pod/Text%3A%3ABalanced) and that makes it susceptible to failure if the try-catch block is not written as it expects it to be. For example if you put comments between try and catch, it would not work anymore. This is because parsing perl is famously difficult. Also, it does not do exception variable assignment, or catch filtered based on exception class like:

    try
    {
        # Something
        die( Exception->new( "Failed!" ) );
    }
    catch( Exception $e )
    {
        # Do something if exception is an Exception class
    }

See ["die" in perlfunc](https://metacpan.org/pod/perlfunc#die) for more information on dying with an object.

Also [Try::Harder](https://metacpan.org/pod/Try%3A%3AHarder) will die if you use only `try` with no catch, such as:

    use Try::Harder;
    try
    {
        die( "Oops\n" );
    }
    # Will never reach this
    print( "Got here with $@\n" );

In this example, the print line will never get executed. With [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) you can use `try` alone as an equivalent of ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) and the `$@` will be available too. So:

    use Nice::Try;
    try
    {
        die( "Oops\n" );
    }
    print( "Got here with $@\n" );

will produces:

    Got here with Oops

In group 3, [TryCatch](https://metacpan.org/pod/TryCatch) was working wonderfully, but was relying on [Devel::Declare](https://metacpan.org/pod/Devel%3A%3ADeclare) which was doing some esoteric stuff and eventually the version 0.006020 broke [TryCatch](https://metacpan.org/pod/TryCatch) and there seems to be no intention of correcting this breaking change. Besides, [Devel::Declare](https://metacpan.org/pod/Devel%3A%3ADeclare) is now marked as deprecated and its use is officially discouraged.

[TryCatch](https://metacpan.org/pod/TryCatch) does not support any `finally` block.

In group 4, there is [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry), which is a great alternative if you do not care about exception class filter (it supports class exception since 2020-07-21 with version 0.15 and variable assignment since 2020-08-01 with version 0.18).

Although, the following script would not work under [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry) :

    BEGIN
    {
        use strict;
        use warnings;
        use Syntax::Keyword::Try;
    };

    {
        &callme();
    }

    sub callme
    {
        try {
            print( "Hello there\n" );
        }
        catch ($e) {
            print( "Got an error: $e\n" );
        }
    }

This will trigger the following error:

    syntax error at ./test.pl line 18, near ") {"
    syntax error at ./test.pl line 21, near "}"
    Execution of ./test.pl aborted due to compilation errors.

That is because [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry) expects to be `used` outside of a BEGIN block like this:

    use strict;
    use warnings;
    use Syntax::Keyword::Try;

    # Rest of the script, same as above

Of course, with [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry), there is no such constraint. You can ["use" in perlfunc](https://metacpan.org/pod/perlfunc#use) [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) inside or outside of a `BEGIN` block indistinctively.

Since [perl version 5.33.7](https://perldoc.perl.org/blead/perlsyn#Try-Catch-Exception-Handling) and now in [perl v5.34.0](https://perldoc.perl.org/5.34.0/perldelta#Experimental-Try/Catch-Syntax) you can use the try-catch block using an experimental feature which may be removed in future versions, by writing:

    use feature 'try'; # will emit a warning this is experimental

This new feature supports try-catch block and variable assignment, but no exception class, nor support for `finally` block until version [perl 5.36 released on 2022-05-28](https://perldoc.perl.org/5.36.0/perldelta) of perl, so you can do:

    try
    {
        # Oh no!
        die( "Argh...\n" );
    }
    catch( $oh_well )
    {
        return( $self->error( "Something went awry: $oh_well" ) );
    }

But **you cannot do**:

    try
    {
        # Oh no!
        die( MyException->new( "Argh..." ) );
    }
    catch( MyException $oh_well )
    {
        return( $self->error( "Something went awry with MyException: $oh_well" ) );
    }
    # Support for 'finally' has been implemented in perl 5.36 released on 2022-05-28
    finally
    {
        # do some cleanup here
    }

An update as of 2022-05-28, [perl-v5.36](https://perldoc.perl.org/5.36.0/perldelta#try/catch-can-now-have-a-finally-block-\(experimental\)) now supports the experimental `finally` block.

Also, the `use feature 'try'` expression must be in the relevant block where you use `try-catch`. You cannot just put it in your `BEGIN` block at the beginning of your script. If you have 3 subroutines using `try-catch`, you need to put `use feature 'try'` in each of them. See [perl documentation on lexical effect](https://perldoc.perl.org/feature#Lexical-effect) for more explanation on this.

It is probably a matter of time until this is fully implemented in perl as a regular non-experimental feature.

See more information about perl's featured implementation of try-catch in [perlsyn](https://perldoc.perl.org/perlsyn#Try-Catch-Exception-Handling)

So, [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) is quite unique and fills the missing features, and since it uses XS modules for a one-time filtering, it is quite fast.

# FINALLY

Like with other language such as Java or JavaScript, the `finally` block will be executed even if the `try` or `catch` block contains a return statement.

This is useful to do some clean-up. For example:

    try
    {
        # Something worth dying
    }
    catch( $e )
    {
        return( "I failed: $e" );
    }
    finally
    {
        # Do some mop up
        # This would be reached even if catch already returned
        # Putting return statement here does not actually return anything.
        # This is only for clean-up
    }

However, because this is designed for clean-up, it is called in void context, so any `return` statement there will not actually return anything back to the caller.

# CATCHING OR NOT CATCHING?

[Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) can be used with a single `try` block which will, in effect, behaves like an eval and the special variable `$@` will be available as always.

    try
    {
        die( "Oh no, something went wrong!\n" );
    }
    print( "Got here with $@\n" );

or even:

    try
    {
        die( "Oh no, something went wrong!\n" );
    }
    catch( $e ); # Not very meaningful, but it will work
    print( "Got here with $@\n" );

However, if you decide to catch class exceptions, make sure to add a default `catch( $e )`. For example:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    print( "Got here with $@\n" );

will work and `print` will display "Got here with Oh no". However:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    catch( Some::Exception $e )
    {
        # won't reach here
    }

will make your process die because of the exception not being caught, thus you might want to do instead:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    catch( Some::Exception $e )
    {
        # won't reach here
    }
    catch( $default )
    {
        print( "Got you! Error was: $default\n" );
    }

And the last catch will catch the exception.

Since, try-catch block can be nested, the following would work too:

    try
    {
        try
        {
            die( MyException->new( "Oh no" ) );
        }
        catch( Some::Exception $e )
        {
            # won't reach here
        }
    }
    catch( MyException $e )
    {
        print( "Got you! MyException was: $e\n" );
    }
    # to play it safe
    catch( $e )
    {
        # do something about it
    }

# EXCEPTION CLASS

As mentioned above, you can use class when raising exceptions and you can filter them in a variety of ways when you catch them.

Here are your options (replace `Exception::Class` with your favorite exception class):

- 1. catch( Exception::Class $error\_variable ) { }
- 2. catch( Exception::Class $error\_variable where { $condition } ) { }

    Here `$condition` could be anything that fits in a legitimate perl block, such as:

        try
        {
            die( Exception->new( "Oh no!", { code => 401 } ) );
        }
        catch( Exception $oopsie where { $_->code >= 400 && $_->code <= 499 })
        {
            # some more handling here
        }

    In the condition block `$_` will always be made available and will correspond to the exception object thrown, just like `$oopsie` in this example. `$@` is also available with the exception object as its value.

- 3. catch( $e isa Exception::Class ) { }

    This is a variant of the `catch( Exception::Class $e ) {}` form

- 4. catch( $e isa('Exception::Class') ) { }

    A variant of the one above if you want to use single quotes.

- 5. catch( $e isa("Exception::Class") ) { }

    A variant of the one above if you want to use double quotes.

- 6. catch( $e isa Exception::Class where { $condition } ) { }
- 7. catch( $e isa('Exception::Class') where { $condition } ) { }
- 8. catch( $e isa("Exception::Class") where { $condition } ) { }
- 9. catch( $e where { $condition } ) { }

    This is not a class exception catching, but worth mentioning. For example:

        try
        {
            die( "Something bad happened.\n" );
        }
        catch( $e where { /something bad/i })
        {
            # Do something about it
        }
        catch( $e )
        {
            # Default here
        }

# LOOPS

Since version v0.2.0 [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) supports the use of flow control keywords such as `next`, `last` and `redo` inside try-catch blocks. For example:

    my @names = qw( John Jack Peter Paul Mark );
    for( $i..$#names )
    {
        try
        {
            next if( $i == 2 );
            # some more code...
        }
        catch( $e )
        {
            print( "Got exception: $e\n" );
        }
    }

It also works inside the catch block or inside the `continue` block:

    while( defined( my $product = $items->[++$i] ) )
    {
        # Do something
    }
    continue
    {
        try
        {
            if( $product->region eq 'Asia' )
            {
                push( @asia, $product );
            }
            else
            {
                next;
            }
        }
        catch( $e )
        {
            $log->( "An unexpected error has occurred. Is $product an object? $e" );
            last;
        }
    }

Control flow with labels also work

    ELEM: foreach my $n ( @names )
    {
        try
        {
            $n->moveAfter( $this );
            next ELEM if( $n->value == 1234567 );
        }
        catch( $oops )
        {
            last ELEM;
        }
    }

However, if you enclose a try-catch block inside another block, use of `next`, `last` or `redo` will silently not work. This is due to perl control flow. See [perlsyn](https://metacpan.org/pod/perlsyn) for more information on this. For example, the following would not yield the desired outcome:

    ELEM: foreach my $n ( @names )
    {
        { # <--- Here is the culprit
            try
            {
                $n->moveAfter( $this );
                # This next statement will not do anything.
                next ELEM if( $n->value == 1234567 );
            }
            catch( $oops )
            {
                # Neither would this one.
                last ELEM;
            }
        }
    }

# CONTEXT AWARENESS

[Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) provides a high level of granularity about the context in which your subroutine was called.

Normally, you would write something like this, and it works as always:

    sub info
    {
        try
        {
            # do something here
            if( wantarray() )
            {
                return( @list_of_values );
            }
            # caller just want a scalar
            elsif( defined( wantarray() ) )
            {
                return( $name );
            }
            # otherwise if undefined, it means we are called in void context, like:
            # $o->info; with no expectation of return value
        }
        catch( $e )
        {
            print( "Caught an error: $e\n" );
        }
    }

The above is nice, but how do you differentiate cases were your caller wants a simple returned value and the one where the caller wants an object for chaining purpose, or if the caller wants an hash or array reference in return?

For example:

    my $val = $o->info->[2]; # wants an array reference
    my $val = $o->info->{name} # wants an hash reference
    # etc...

Now, you can do the following:

    use Want; # an awesome module which extends wantarray
    sub info
    {
        my $self = shift( @_ );
        try
        {
            # Do something
            # 
            # same as wantarray() == 1
            if( want('LIST') )
            {
                return( @some_data );
            }
            # same as: if( defined( wantarray() ) && !wantarray() )
            elsif( want('SCALAR' ) )
            {
                return( $name ); # regular string
            }
            # same as if( !defined( wantarray() ) )
            elsif( want('VOID') )
            {
                return;
            }
            # For the other contexts below, wantarray is of no help
            if( want('OBJECT') )
            {
                return( $obj ); # useful for chaining
            }
            elsif( want('CODE') )
            {
                # dummy code ref for example
                return( sub{ return( $name ); } );
            }
            elsif( want('ARRAY') )
            {
                return( \@some_data );
            }
            elsif( want('HASH') )
            {
                return({ name => $name, location => $city });
            }
        }
        catch( $e )
        {
            $Logger->( "Caught exception: $e" );
        }
    }

Thus this is particularly useful if, for example, you want to differentiate if the caller just wants a return string, or an object for chaining.

["wantarray" in perlfunc](https://metacpan.org/pod/perlfunc#wantarray) would not know the difference, and other try-catch implementation would not let you benefit from using [Want](https://metacpan.org/pod/Want).

For example:

    my $val = $o->info; # simple regular scalar context; but...
    # here, we are called in object context and wantarray is of no help to tell the difference
    my $val = $o->info->another_method;

Other cases are:

    # regular string context
    my $name = $o->info;
    # list context like wantarray
    my @data = $o->info;

    # code context
    my $name = $o->info->();
    # hash context
    my $name = $o->info->{name};
    # array context
    my $name = $o->info->[2];
    # object context
    my $name = $o->info->another_method;

See [Want](https://metacpan.org/pod/Want) for more information on how you can benefit from it.

Currently lvalues are no implemented and will be in future releases. Also note that [Want](https://metacpan.org/pod/Want) does not work within tie-handlers. It would trigger a segmentation fault. [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) detects this and disable automatically support for [Want](https://metacpan.org/pod/Want) if used inside a tie-handler, reverting to regular ["wantarray" in perlfunc](https://metacpan.org/pod/perlfunc#wantarray) context.

Also, for this rich context awareness to be used, obviously try-catch would need to be inside a subroutine, otherwise there is no rich context other than the one the regular ["wantarray" in perlfunc](https://metacpan.org/pod/perlfunc#wantarray) provides.

This is particularly true when running within an Apache modperl handler which has no caller. If you use [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) in such handler, it will kill Apache process, so you need to disable the use of [Want](https://metacpan.org/pod/Want), by calling:

    use Nice::Try dont_want => 1;

When there is an update to correct this bug from [Want](https://metacpan.org/pod/Want), I will issue a new version.

The use of [Want](https://metacpan.org/pod/Want) is also automatically disabled when running under a package that use overloading.

# LIMITATIONS

Before version `v1.3.5`, there was a limitation on using signature on a subroutine, but since version `v1.3.5`, it has been fixed and there is no more any limitation. Thus the following works nicely too.

    use strict;
    use warnings;
    use experimental 'signatures';
    use Nice::Try;

    sub test { 1 }

    sub foo ($f = test()) { 1 }

    try {
        my $k = sub ($f = foo()) {}; # <-- this sub routine attribute inside try-catch block will disrupt Nice::Try and make it fail.
        print( "worked\n" );
    }
    catch($e) {
        warn "caught: $e";
    }

    __END__

# PERFORMANCE

`Nice::Try` is quite fast, but as with any class implementing a `try-catch` block, it is of course a bit slower than the natural `eval` block.

Because `Nice::Try` relies on [PPI](https://metacpan.org/pod/PPI) for parsing the perl code, if your code is very long, there will be an execution time penalty.

If you use framework such as [mod\_perl2](https://metacpan.org/pod/mod_perl2), then it will only affect the first time the code is run, since afterward, the code will be loaded in memory.

Still, if you use perl version `v5.34` or higher, and have simple need of `try-catch`, then simply use instead perl experimental implementation, such as:

    use v5.34;
    use strict;
    use warnings;
    use feature 'try';
    no warnings 'experimental';

    try
    {
        # do something
    }
    catch( $e )
    {
        # catch fatal error here
    }

# DEBUGGING

And to have [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) save the filtered code to a file, pass it the `debug_file` parameter like this:

    use Nice::Try debug_file => './updated_script.pl';

You can also call your script using [Filter::ExtractSource](https://metacpan.org/pod/Filter%3A%3AExtractSource) like this:

    perl -MFilter::ExtractSource script.pl > updated_script.pl

or add `use Filter::ExtractSource` inside it.

In the updated script produced, you can add the line calling [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) to:

    use Nice::Try no_filter => 1;

to avoid [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) from filtering your script

If you want [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) to produce human readable code, pass it the `debug_code` parameter like this:

    use Nice::Try debug_code => 1;

# CLASS FUNCTIONS

The following class functions can be used.

## implement

    my $new_code = Nice::Try->implement( $perl_code );
    eval( $new_code );

Provided with a perl code having one or more try-catch blocks and this will return a perl code converted to support try-catch blocks.

This is designed to be used for perl code you store, such as subroutines dynamically loaded or eval'ed.

For example:

    my $code = Nice::Try->implement( <<EOT );
    sub $method
    {
        my \$self = shift( \@_ );
        try
        {
            # doing something that may die here
        }
        catch( \$e )
        {
            return( \$self->error( "Oops: \$e ) );
        }
    }
    EOT

You can also pass an optional hash or hash reference of options to ["implement"](#implement) and it will be used to instantiate a new [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry) method. The options accepted are the same ones that can be passed when using `use Nice::Try`

# CREDITS

Credits to Stephen R. Scaffidi for his implementation of [Try::Harder](https://metacpan.org/pod/Try%3A%3AHarder) from which I borrowed some code.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[PPI](https://metacpan.org/pod/PPI), [Filter::Util::Call](https://metacpan.org/pod/Filter%3A%3AUtil%3A%3ACall), [Try::Harder](https://metacpan.org/pod/Try%3A%3AHarder), [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry), [Exception::Class](https://metacpan.org/pod/Exception%3A%3AClass)

[JavaScript implementation of nice-try](https://javascript.info/try-catch)

# COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.
