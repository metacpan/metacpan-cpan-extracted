# NAME

Module::Generic - Generic Module to inherit from

# SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
    };

    sub init
    {
        my $self = shift( @_ );
        # Requires parameters provided to have their equivalent method
        $self->{_init_strict_use_sub} = 1;
        # Smartly accepts key-value pairs as list or hash reference
        $self->SUPER::init( @_ );
        # This won't be affected by parameters provided during instantiation
        $self->{_private_param} = 'some value';
        return( $self );
    }

    sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }
    sub address { return( shift->_set_get_object( 'address', 'My::Address', @_ ) ); }
    sub age { return( shift->_set_get_number( 'age', @_ ) ); }
    sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }
    sub uuid { return( shift->_set_get_uuid( 'uuid', @_ ) ); }
    sub remote_addr { return( shift->_set_get_ip( 'remote_addr', @_ ) ); }
    sub discount
    {
        return( shift->_set_get_class_array( 'discount',
        {
        amount      => { type => 'number' },
        discount    => { type => 'object', class => 'My::Discount' },
        }, @_ ) );
    }
    sub settings 
    {
        return( shift->_set_get_class( 'settings',
        {
        # Will create a Module::Generic::Array array object of objects of class MY::Item
        items => { type => 'object_array_object', class => 'My::Item' },
        notify => { type => 'boolean' },
        resumes_at => { type => 'datetime' },
        timeout => { type => 'integer' },
        customer => {
                definition => {
                    billing_address => { package => "My::Address", type => "object" },
                    email => { type => "scalar" },
                    name => { type => "scalar" },
                    shipping_address => { package => "My::Address", type => "object" },
                },
                type => "class",
            },
        }, @_ ) );
    }

Quick way to create a class with feature-rich methods

    create_class My::Package extends => 'Other::Package';
    # or, maybe
    create_class My::Package extends => 'Other::Package', method =>
    {
        since => 'datetime',
        uri => 'uri',
        tags => 'array_object',
        meta => 'hash',
        active => 'boolean',
        callback => 'code',
        config => 'file',
        allowed_from => 'ip',
        total => 'number',
        id => 'uuid',
        version => 'version',
        filehandle => 'glob',
        object => { type => 'object', class => 'Some::Class' },
        customer => 
        {
            type => 'class',
            def =>
            {
                id => 'uuid',
                since => 'datetime',
                name => 'scalar_as_object',
                age => 'decimal',
            }
        }
    };
    my $obj = My::Package->new;
    my $cust = $obj->customer(
        name => 'John Doe',
        age => 32,
        since => 'now',
    );
    $obj->customer->id( '44d9a3ab-32e2-4c46-b6c9-8b307f273d47' );

# VERSION

    v1.0.6

# DESCRIPTION

[Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) as its name says it all, is a generic module to inherit from.
It is designed to be fast and provide a useful framework and speed up coding and debugging.
It contains standard and support methods that may be superseded by your module.

It also contains an AUTOLOAD transforming any hash object key into dynamic methods and also recognize the dynamic routine a la AutoLoader. The reason is that while `AutoLoader` provides the user with a convenient AUTOLOAD, I wanted a way to also keep the functionnality of [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) AUTOLOAD that were not included in `AutoLoader`. So the only solution was a merger.

# METHODS

## import

**import**() is used for the AutoLoader mechanism and hence is not a public method.
It is just mentionned here for info only.

## new

**new** will create a new object for the package, pass any argument it might receive to the special standard routine **init** that _must_ exist. 
Then it returns what returns ["init"](#init).

To protect object inner content from sneaking by third party, you can declare the package global variable _OBJECT\_PERMS_ and give it a Unix permission, but only 1 digit.
It will then work just like Unix permission. That is, if permission is 7, then only the module who generated the object may read/write content of the object. However, if you set 5, the, other may look into the content of the object, but may not modify it.
7, as you would have guessed, allow other to modify the content of an object.
If _OBJECT\_PERMS_ is not defined, permissions system is not activated and hence anyone may access and possibly modify the content of your object.

If the module runs under mod\_perl, and assuming you have set the variable `GlobalRequest` in your Apache configuration, it is recognised and a clean up registered routine is declared to Apache to clean up the content of the object.

This methods calls ["init"](#init), which does all the work of setting object properties and calling methods to that effect.

## as\_hash

This will recursively transform the object into an hash suitable to be encoded in json.

It does this by calling each method of the object and build an hash reference with the method name as the key and the method returned value as the value.

If the method returned value is an object, it will call its ["as\_hash"](#as_hash) method if it supports it.

It returns the hash reference built

## clear

Alias for ["clear\_error"](#clear_error)

## clear\_error

Clear all error from the object and from the available global variable `$ERROR`.

This is a handy method to use at the beginning of other methods of calling package, so the end user may do a test such as:

    $obj->some_method( 'some arguments' );
    die( $obj->error() ) if( $obj->error() );

    # some_method() would then contain something like:
    sub some_method
    {
        my $self = shift( @_ );
        ## Clear all previous error, so we may set our own later one eventually
        $self->clear_error();
        # ...
    }

This way the end user may be sure that if `$obj-`error()> returns true something wrong has occured.

Note that all helper method such as `_set_get_*` use this method when used as mutator. This means that if those methods are used to set some value, and they do so successfully, they will reset any previous error. When used as accessor, any previous error set will remain.

## clone

Clone the current object if it is of type hash or array reference. It returns an error if the type is neither.

It returns the clone.

## colour\_close

The marker to be used to set the closing of a command line colour sequence.

Defaults to ">"

## colour\_closest

Provided with a colour, this returns the closest standard one supported by terminal.

A colour provided can be a colour name, or a 9 digits rgb value or an hexadecimal value

## colour\_format

Provided with a hash reference of parameters, this will return a string properly formatted to display colours on the command line.

Parameters are:

- `text` or _message_

    This is the text to be formatted in colour.

- `bgcolour` or _bgcolor_ or _bg\_colour_ or _bg\_color_

    The value for the background colour.

- `colour` or _color_ or _fg\_colour_ or _fg\_color_ or _fgcolour_ or _fgcolor_

    The value for the foreground colour.

    Valid value can be a colour name, an rgb value like `255255255`, a rgb annotation like `rgb(255, 255, 255)` or a rgba annotation like `rgba(255,255,255,0.5)`

    A colour can be preceded by the words `light` or `bright` to provide slightly lighter colour where supported.

    Similarly, if an rgba value is provided, and the opacity is less than 1, this is equivalent to using the keyword `light`

    It returns the text properly formatted to be outputted in a terminal.

- `style`

    The possible values are: _bold_, _italic_, _underline_, _blink_, _reverse_, _conceal_, _strike_

## colour\_open

The marker to be used to set the opening of a command line colour sequence.

Defaults to "<"

## colour\_parse

Provided with a string, this will parse the string for colour formatting. Formatting can be encapsulated in another formatting, and can be expressed in 2 different ways. For example:

    $self->colour_parse( "And {style => 'i|b', color => green}what about{/} {style => 'blink', color => yellow}me{/} ?" );

would result with the words `what about` in italic, bold and green colour and the word `me` in yellow colour blinking (if supported).

Another way is:

    $self->colour_parse( "And {bold light red on white}what about{/} {underline yellow}me too{/} ?" );

would return a string with the words `what about` in light red bold text on a white background, and the words `me too` in yellow with an underline.

    $self->colour_parse( "Hello {bold red on white}everyone! This is {underline rgb(0,0,255)}embedded{/}{/} text..." );

would return a string with the words `everyone! This is` in bold red characters on white background and the word `embedded` in underline blue color

The idea for this syntax, not the code, is taken from [Term::ANSIColor](https://metacpan.org/pod/Term%3A%3AANSIColor)

## colour\_to\_rgb

Convert a human colour keyword like `red`, `green` into a rgb equivalent.

## coloured

Provided with a colouring preference expressed as the first argument as string, and followed by 1 or more arguments that are concatenated to form the text string to format. For example:

    print( $o->coloured( 'bold white on red', "Hello it's me!\n" ) );

A colour can be expressed as a rgb, such as :

    print( $o->coloured( 'underline rgb( 0, 0, 255 ) on white', "Hello everyone!" ), "\n" );

rgb can also be rgba with the last decimal, normally an opacity used here to set light color if the value is less than 1. For example :

    print( $o->coloured( 'underline rgba(255, 0, 0, 0.5)', "Hello everyone!" ), "\n" );

## debug

Set or get the debug level. This takes and return an integer.

Based on the value, ["message"](#message) will or will not print out messages. For example :

    $self->debug( 2 );
    $self->message( 2, "Debugging message here." );

Since `2` used in ["message"](#message) is equal to the debug value, the debugging message is printed.

If the debug value is switched to 1, the message will be silenced.

## deserialise

    my $ref = $self->deserialise( %hash_of_options );
    my $ref = $self->deserialise( $hash_reference_of_options );
    my $ref = $self->deserialise( $serialised_data, %hash_of_options );
    my $ref = $self->deserialise( $serialised_data, $hash_reference_of_options );

This method use a specified serialiser class and deserialise the given data either directly from a specified file or being provided, and returns the perl data.

The serialisers currently supported are: [CBOR::Free](https://metacpan.org/pod/CBOR%3A%3AFree), [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS), [JSON](https://metacpan.org/pod/JSON), [Sereal](https://metacpan.org/pod/Sereal) and [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) (or the legacy [Storable](https://metacpan.org/pod/Storable)). They are not required by [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric), so you must install them yourself. If the serialiser chosen is not installed, this will set an [errr](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`.

It takes an hash or hash reference of options. You can also provide the data to deserialise as the first argument followed by an hash or hash reference of options.

It can then:

- retrieve data directly from File
- retrieve data from a file handle (only with [Storable](https://metacpan.org/pod/Storable))
- Return the deserialised data

The supported options are:

- `base64`

    Thise can be set to a true value like `1`, or to your preferred base64 encoder/decoder, or to an array reference containing 2 code references, the first one for encoding and the second one for decoding.

    If this is set simply to a true value, `deserialise` will call ["\_has\_base64"](#_has_base64) to find out any installed base64 modules. Currently the ones supported are: [Crypt::Misc](https://metacpan.org/pod/Crypt%3A%3AMisc) and [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64). Of course, you need to have one of those modules installed first before it can be used.

    If this option is set and no appropriate module could be found, `deserialise` will return an error.

- `data`

    Data to be deserialised.

- `file`

    Provides a file path from which to read the serialised data.

- `io`

    A file handle. This is used when the serialiser is [Storable](https://metacpan.org/pod/Storable) to call its function ["store\_fd" in Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved#store_fd) and ["fd\_retrieve" in Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved#fd_retrieve)

- _lock_

    Boolean. If true, this will lock the file before reading from it. This works only in conjonction with _file_ and the serialiser [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved)

- `serialiser`

    Specify the class name of the serialiser to use. Supported serialiser can either be `CBOR` or [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS), [Sereal](https://metacpan.org/pod/Sereal) and [Storable](https://metacpan.org/pod/Storable%3A%3AImproved)

    If the serialiser is [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS) the following additional options are supported: `max_depth`, `max_size`, `allow_unknown`, `allow_sharing`, `allow_cycles`, `forbid_objects`, `pack_strings`, `text_keys`, `text_strings`, `validate_utf8`, `filter`

    See [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS) for detail on those options.

    If the serialiser is [Sereal](https://metacpan.org/pod/Sereal), the following additional options are supported: `refuse_snappy`, `refuse_objects`, `no_bless_objects`, `validate_utf8`, `max_recursion_depth`, `max_num_hash_entries`, `max_num_array_entries`, `max_string_length`, `max_uncompressed_size`, `incremental`, `alias_smallint`, `alias_varint_under`, `use_undef`, `set_readonly`, `set_readonly_scalars`

    See [Sereal](https://metacpan.org/pod/Sereal) for detail on those options.

If an error occurs, this sets an [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`

## deserialize

Alias for ["deserialise"](#deserialise)

## dump

Provided with some data, this will return a string representation of the data formatted by [Data::Printer](https://metacpan.org/pod/Data%3A%3APrinter)

## dump\_hex

Returns an hexadecimal dump of the data provided.

This requires the module [Devel::Hexdump](https://metacpan.org/pod/Devel%3A%3AHexdump) and will return `undef` and set an ["error"](#error) if not found.

## dump\_print

Provided with a file to write to and some data, this will format the string representation of the data using [Data::Printer](https://metacpan.org/pod/Data%3A%3APrinter) and save it to the given file.

## dumper

Provided with some data, and optionally an hash reference of parameters as last argument, this will create a string representation of the data using [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) and return it.

This sets [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) to be terse, to indent, to use `qq` and optionally to not exceed a maximum _depth_ if it is provided in the argument hash reference.

## dumpto

Alias for ["dumpto\_dumper"](#dumpto_dumper)

## printer

Same as ["dumper"](#dumper), but using [Data::Printer](https://metacpan.org/pod/Data%3A%3APrinter) to format the data.

## dumpto\_printer

Same as ["dump\_print"](#dump_print) above that is an alias of this method.

## dumpto\_dumper

Same as ["dumpto\_printer"](#dumpto_printer) above, but using [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)

## errno

Sets or gets an error number.

## error

    my $o = Foo::Bar->new;
    $o->do_something || return( $self->error( "Some error", "message." ) );
    # or
    $o->do_something || return( $self->error({
        message => "Some error message.",
        # will be loaded if necessary
        class => 'My::Exception::Class',
        # by default 'object' only
        # it could also be simply 'all' to imply all the ones below
        want => [qw( array code glob hash object scalar )],
        debug => 4,
        # code to execute upon error
        callback => sub
        {
            # do some cleanup
            $dbh->rollback if( $dbh->transaction );
        },
        # make it fatal
        fatal => 1,
        # When used inside an lvalue method
        # lvalue => 1,
        # assign => 1,
    }) );

Provided with a list of strings or an hash reference of parameters and this will set the current error issuing a [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object, call ["warn" in perlfunc](https://metacpan.org/pod/perlfunc#warn), or `$r-`warn> under Apache2 modperl, and returns undef() or an empty list in list context:

    if( $some_condition )
    {
        return( $self->error( "Some error." ) );
    }

Note that you do not have to worry about a trailing line feed sequence.
["error"](#error) takes care of it.

The script calling your module could write calls to your module methods like this:

    my $cust_name = $object->customer->name ||
        die( "Got an error in file ", $object->error->file, " at line ", $object->error->line, ": ", $object->error->trace, "\n" );
    # or simply:
    my $cust_name = $object->customer->name ||
        die( "Got an error: ", $object->error, "\n" );

If you want to use an hash reference instead, you can pass the following parameters. Any other parameters will be passed to the exception class.

- `assign`

    Boolean. Set this to a true value if this is called within an assign method, such as one using lvalue.

- `callback`

    Specify a code reference such as a reference to a subroutine. This is designed to be called upon error to do some cleanup for example.

- `class`

    The package name or class to use to instantiate the error object. By default, it will use [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) class or the one specified with the object property `_exception_class`

        $self->do_something_bad ||
            return( $self->error({
                code => 500,
                message => "Oopsie",
                class => "My::NoWayException",
            }) );
        my $exception = $self->error; # an My::NoWayException object

    Note, however, that if the class specified cannot be loaded for some reason, ["error" in Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric#error) will die since this would be an error within another error.

- `debug`

    Integer. Specify a value to set the debugging value for this exception.

- `fatal`

    Boolean. Specify a true value to make this error fatal. This means that instead of issuing a `warn`, it will die.

- `lvalue`

    Boolean. Set this to a true value if this is called within an assign method, such as one using lvalue.

- `message`

    Specify a string for the error message.

    The error message.

- `want`

    An array reference of data types that you allow this method to return when such data type is expected by the original caller.

    Supported data types are: `ARRAY`, `CODE`, `GLOB`, `HASH`, `OBJECT`, `SCALAR`

    Note that, actually, the data type you provide is case insensitive.

    For example, you have a method that returns an array, but an error occurs, and it returns `undef` instead:

        sub your_method
        {
            my $self = shift( @_ );
            return( $self->error( "Something is wrong" ) ) if( $self->something_is_missing );
            return( $self->{array} );
        }

        my $array = $obj->your_method; # array is undef

    If the user does:

        $obj->your_method->[0]; # perl error occurs

    This would trigger a perl error `Can't use an undefined value as an ARRAY reference`, which may be fine if this is what you want, but if you want instead to ensure the user does not get an error, but instead an empty array, in your method `your_method`, you could write this `your_method` this way instead, passing the `want` parameter:

        sub your_method
        {
            my $self = shift( @_ );
            return( $self->error( { message => "Something is wrong", want => [qw( array )] ) ) if( $self->something_is_missing );
            return( $self->{array} );
        }

    Then, if the user calls this method in array context and an error occurs, it would now return instead an empty array.

        my $array = $obj->your_method->[0]; # undef

    Note that, by default, the `object` call context is always activated, so you do not have to specify it.

Note also that by calling ["error"](#error) it will not clear the current error. For that
you have to call ["clear\_error"](#clear_error) explicitly.

Also, when an error is set, the global variable _ERROR_ in the inheriting package is set accordingly. This is
especially usefull, when your initiating an object and that an error occured. At that
time, since the object could not be initiated, the end user can not use the object to 
get the error message, and then can get it using the global module variable 
_ERROR_, for example:

    my $obj = Some::Package->new ||
    die( $Some::Package::ERROR, "\n" );

If the caller has disabled warnings using the pragma `no warnings`, ["error"](#error) will 
respect it and not call **warn**. Calling **warn** can also be silenced if the object has
a property _quiet_ set to true.

The error message can be split in multiple argument. ["error"](#error) will concatenate each argument to form a complete string. An argument can even be a reference to a sub routine and will get called to get the resulting string, unless the object property _\_msg\_no\_exec\_sub_ is set to false. This can switched off with the method ["noexec"](#noexec)

If perl runs under Apache2 modperl, and an error handler is set with ["error\_handler"](#error_handler), this will call the error handler with the error string.

If an Apache2 modperl log handler has been set, this will also be called to log the error.

If the object property _fatal_ is set to true, this will call die instead of ["warn" in perlfunc](https://metacpan.org/pod/perlfunc#warn).

Last, but not least since ["error"](#error) returns undef in scalar context or an empty list in list context, if the method that triggered the error is chained, it would normally generate a perl error that the following method cannot be called on an undefined value. To solve this, when an object is expected, ["error"](#error) returns a special object from module [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) that will enable all the chained methods to be performed and return the error when requested to. For example:

    my $o = My::Package->new;
    my $total $o->get_customer(10)->products->total || die( $o->error, "\n" );

Assuming this method here `get_customer` returns an error, the chaining will continue, but produce nothing and ultimately returns undef.

## error\_handler

Sets or gets a code reference that will be called to handle errors that have been triggered when calling ["error"](#error)

## errors

Used by **error**() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and the last 
error in scalar context.

## errstr

Set/get the error string, period. It does not produce any warning like **error** would do.

## fatal

Boolean. If enabled, any error will call ["die" in perlfunc](https://metacpan.org/pod/perlfunc#die) instead of returning ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) and setting an [error](https://metacpan.org/pod/Module%3A%3AGeneric#error).

Defaults to false.

You can enable it in your own package by initialising it in your own `init` method like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        return( $self->SUPER::init( @_ ) );
    }

## get

Uset to get an object data key value:

    $obj->set( 'verbose' => 1, 'debug' => 0 );
    ## ...
    my $verbose = $obj->get( 'verbose' );
    my @vals = $obj->get( qw( verbose debug ) );
    print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the AUTOLOAD
generic routine with which you may say:

    $obj->verbose(1);
    $obj->debug(0);
    ## ...
    my $verbose = $obj->verbose();

Much better, no?

## init

This is the ["new"](#new) package object initializer. It is called by ["new"](#new)
and is used to set up any parameter provided in a hash like fashion:

    my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed ["init"](#init) to have it suit your needs.

["init"](#init) needs to returns the object it received in the first place or an error if
something went wrong, such as:

    sub init
    {
        my $self = shift( @_ );
        my $dbh  = DB::Object->connect() ||
        return( $self->error( "Unable to connect to database server." ) );
        $self->{dbh} = $dbh;
        return( $self );
    }

In this example, using ["error"](#error) will set the global variable `$ERROR` that will
contain the error, so user can say:

    my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable _VERBOSE_, _DEBUG_, _VERSION_ are defined in the module,
and that they do not exist as an object key, they will be set automatically and
accordingly to those global variable.

The supported data type of the object generated by the ["new"](#new) method may either be
a hash reference or a glob reference. Those supported data types may very well be
extended to an array reference in a near future.

When provided with an hash reference, and when object property _\_init\_strict\_use\_sub_ is set to true, ["init"](#init) will call each method corresponding to the key name and pass it the key value and it will set an error and skip it if the corresponding method does not exist. Otherwise, it calls each corresponding method and pass it whatever value was provided and check for that method return value. If the return value is ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) and the value provided is **not** itself `undef`, then it issues a warning and return the ["error"](#error) that is assumed having being set by that method.

Otherwise if the object property _\_init\_strict_ is set to true, it will check the object property matching the hash key for the default value type and set an error and return undef if it does not match. Foe example, ["init"](#init) in your module could be like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{_init_strict} = 1;
        $self->{products} = [];
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init({ products => $some_string_but_not_array }) || die( $object->error, "\n" );

This would cause your script to die, because `products` value is a string and not an array reference.

Otherwise, if none of those special object properties are set, the init will create an object property matching the key of the hash and set its value accordingly. For example :

    sub init
    {
        my $self = shift( @_ );
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init( products => $array_ref, first_name => 'John', last_name => 'Doe' });

The object would then contain the properties _products_, _first\_name_ and _last\_name_ and can be accessed as methods, such as :

    my $fname = $object->first_name;

You can also alter the way ["init"](#init) process the parameters received using the following properties you can set in your own `init` method, for example:

    sub init
    {
        my $self = shift( @_ );
        # Set the order in which the parameters are processed, because some methods may rely on other methods' value
        $self->{_init_params_order} [qw( method1 method2 )];
        # Enable strict sub, which means the corresponding method must exist for the parameter provided
        $self->{_init_strict_use_sub} = 1;
        # Set the class name of the exception to use in error()
        # Here My::Package::Exception should inherit from Module::Generic::Exception or some other Exception package
        $self->{_exception_class} = 'My::Package::Exception';
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        return( $self );
    }

You can also specify a default exception class that will be used by ["error"](#error) to create exception object, by setting the object property `_exception_class`:

    sub init
    {
        my $self = shift( @_ );
        $self->{name} = 'default_name';
        # For any key-value pairs to be matched by a corresponding method
        $self->{_init_strict_use_sub} = 1;
        $self->{_exception_class} = 'My::Exception';
        return( $self->SUPER::init( @_ ) );
    }

## log\_handler

Provided a reference to a sub routine or an anonymous sub routine, this will set the handler that is called by ["message"](#message)

It returns the current value set.

## message

**message**() is used to display verbose/debug output. It will display something to the extend that either _verbose_ or _debug_ are toggled on.

If so, all debugging message will be prepended by ` ## ` by default or the prefix string specified with the _prefix_ option, to highlight the fact that this is a debugging message.

Addionally, if a number is provided as first argument to **message**(), it will be treated as the minimum required level of debugness. So, if the current debug state level is not equal or superior to the one provided as first argument, the message will not be displayed.

For example:

    # Set debugness to 3
    $obj->debug( 3 );
    # This message will not be printed
    $obj->message( 4, "Some detailed debugging stuff that we might not want." );
    # This will be displayed
    $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the verbose level needs only to be true, that is equal to 1 to be efficient. You do not really need to have a verbose level greater than 1. However, the debug level usually may have various level.

Also, the text provided can be separated by comma, and even be a code reference, such as:

    $self->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

If the object has a property _\_msg\_no\_exec\_sub_ set to true, then a code reference will not be called and instead be added to the string as is. This can be done simply like this:

    $self->noexec->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

["message"](#message) also takes an optional hash reference as the last parameter with the following recognised options:

- `caller_info`

    This is a boolean value, which is true by default.

    When true, this will prepend the debug message with information about the caller of ["message"](#message)

- `level`

    An integer. Debugging level.

- `message`

    The text of the debugging message. This is optional since this can be provided as first or consecutive arguments like in a list as demonstrated in the example above. This allows you to do something like this:

        $self->message( 2, { message => "Some debug message here", prefix => ">>" });

    or

        $self->message( { message => "Some debug message here", prefix => ">>", level => 2 });

- `no_encoding`

    Boolean value. If true and when the debugging is set to be printed to a file, this will not set the binmode to `utf-8`

- `prefix`

    By default this is set to `##`. This value is used as the prefix used in debugging output.

- `type`

    Type of debugging

## message\_check

This is called by ["message"](#message)

Provided with a list of arguments, this method will check if the first argument is an integer and find out if a debug message should be printed out or not. It returns the list of arguments as an array reference.

## message\_color

Alias for ["message\_colour"](#message_colour)

## message\_colour

This is the same as ["message"](#message), except this will check for colour formatting, which
["message"](#message) does not do. For example:

    $self->message_colour( 3, "And {bold light white on red}what about{/} {underline green}me again{/} ?" );

["message\_colour"](#message_colour) can also be called as **message\_color**

See also ["colour\_format"](#colour_format) and ["colour\_parse"](#colour_parse)

## message\_frame

Return the optional hash reference of parameters, if any, that can be provided as the last argument to ["message"](#message)

## messagec

This is an alias for ["message\_colour"](#message_colour)

## messagef

This works like ["sprintf" in perlfunc](https://metacpan.org/pod/perlfunc#sprintf), so provided with a format and a list of arguments, this print out the message. For example :

    $self->messagef( 1, "Customer name is %s", $cust->name );

Where 1 is the debug level set with ["debug"](#debug)

## messagef\_colour

This method is same as ["message\_colour"](#message_colour) and [messagef](https://metacpan.org/pod/messagef) combined.

It enables to pass sprintf-like parameters while enabling colours.

## message\_log

This is called from ["message"](#message).

Provided with a message to log, this will check if ["message\_log\_io"](#message_log_io) returns a valid file handler, presumably to log file, and if so print the message to it.

If no file handle is set, this returns undef, other it returns the value from `$io-`print>

## message\_log\_io

Set or get the message log file handle. If set, ["message\_log"](#message_log) will use it to print messages received from ["message"](#message)

If no argument is provided bu your module has a global variable `LOG_DEBUG` set to true and global variable `DEB_LOG` set presumably to the file path of a log file, then this attempts to open in write mode the log file.

It returns the current log file handle, if any.

## new\_array

Instantiate a new [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) object. If any arguments are provided, it will pass it to ["new" in Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray#new) and return the object.

## new\_datetime

Provided with some optional arguments and this will instantiate a new [Module::Generic::DateTime](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ADateTime) object, passing it whatever argument was provided.

Example:

    my $dt = DateTime->now( time_zone => 'Asia/Tokyo' );
    # Returns a new Module::Generic::DateTime object
    my $d = $o->new_datetime( $dt );

    # Returns a new Module::Generic::DateTime object with DateTime initiated automatically
    # to now with time zone set by default to UTC
    my $d = $o->new_datetime;

## new\_file

Instantiate a new [Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile) object. If any arguments are provided, it will pass it to ["new" in Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile#new) and return the object.

## new\_glob

This method is called instead of ["new"](#new) in your package for GLOB type module.

It will set an hash of options provided and call ["init"](#init) and return the newly instantiated object upon success, or `undef` upon error.

## new\_hash

Instantiate a new [Module::Generic::Hash](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash) object. If any arguments are provided, it will pass it to ["new" in Module::Generic::Hash](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash#new) and return the object.

## new\_json

This method tries to load [JSON](https://metacpan.org/pod/JSON) and create a new object.

By default it enables the following [JSON](https://metacpan.org/pod/JSON) object properties:

- ["allow\_blessed" in JSON](https://metacpan.org/pod/JSON#allow_blessed)
- ["allow\_nonref" in JSON](https://metacpan.org/pod/JSON#allow_nonref)
- ["convert\_blessed" in JSON](https://metacpan.org/pod/JSON#convert_blessed)
- ["relaxed" in JSON](https://metacpan.org/pod/JSON#relaxed)

Additional supported options are as follows, including any of the [JSON](https://metacpan.org/pod/JSON) supported options:

- `allow_blessed`

    Boolean. When enabled, this will not return an error when it encounters a blessed reference that [JSON](https://metacpan.org/pod/JSON) cannot convert otherwise. Instead, a JSON `null` value is encoded instead of the object.

- `allow_nonref`

    Boolean. When enabled, this will convert a non-reference into its corresponding string, number or null [JSON](https://metacpan.org/pod/JSON) value. Default is enabled.

- `allow_tags`

    Boolean. When enabled, upon encountering a blessed object, this will check for the availability of the `FREEZE` method on the object's class. If found, it will be used to serialise the object into a nonstandard tagged [JSON](https://metacpan.org/pod/JSON) value (that [JSON](https://metacpan.org/pod/JSON) decoders cannot decode). 

- `allow_unknown`

    Boolean. When enabled, this will not return an error when [JSON](https://metacpan.org/pod/JSON) encounters values it cannot represent in JSON (for example, filehandles) but instead will encode a [JSON](https://metacpan.org/pod/JSON) "null" value.

- `ascii`

    Boolean. When enabled, will not generate characters outside the code range 0..127 (which is ASCII).

- `canonical` or `ordered`

    Boolean value. If true, the JSON data will be ordered. Note that it will be slower, especially on a large set of data.

- `convert_blessed`

    Boolean. When enabled, upon encountering a blessed object, [JSON](https://metacpan.org/pod/JSON) will check for the availability of the `TO_JSON` method on the object's class. If found, it will be called in scalar context and the resulting scalar will be encoded instead of the object.

- `indent`

    Boolean. When enabled, this will use a multiline format as output, putting every array member or object/hash key-value pair into its own line, indenting them properly.

- `latin1`

    Boolean. When enabled, this will encode the resulting [JSON](https://metacpan.org/pod/JSON) text as latin1 (or iso-8859-1),

- `max_depth`

    Integer. This sets the maximum nesting level (default 512) accepted while encoding or decoding. When the limit is reached, this will return an error.

- `pretty`

    Boolean value. If true, the JSON data will be generated in a human readable format. Note that this will take considerably more space.

- `space_after`

    Boolean. When enabled, this will add an extra optional space after the ":" separating keys from values.

- `space_before`

    Boolean. When enabled, this will add an extra optional space before the ":" separating keys from values.

- `utf8`

    Boolean. This option is ignored, because the JSON data are saved to file using UTF-8 and double encoding would produce mojibake.

## new\_json\_safe

This is the same as [new\_json](#new_json), except that it uses [Module::Generic::JSON](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AJSON), which is a thin, and reliable wrapper around [JSON](https://metacpan.org/pod/JSON). [Module::Generic::JSON](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AJSON) never dies, but instead sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException), and returns `undef`, or an empty list depending on the caller context.

## new\_null

Returns a null value based on the expectations of the caller and thus without breaking the caller's call flow.

You can also optionally provide an hash or hash reference containing the option `type` with a value being either `ARRAY`, `CODE`, `HASH`, `OBJECT` or `SCALARREF` to force `new_null` to return the corresponding data without using the caller's context.

If the caller wants an hash reference, it returns an empty hash reference.

If the caller wants an array reference, it returns an empty array reference.

If the caller wants a code reference, it returns an anonymous subroutine that returns `undef` or an empty list.

If the caller is calling another method right after, this means this is an object context and ["new\_null"](#new_null) will instantiate a new [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) object. If any arguments were provided to ["new\_null"](#new_null), they will be passed along to ["new" in Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull#new) and the new object will be returned.

In any other context, `undef` is returned or an empty list.

Without using ["new\_null"](#new_null), if you return simply undef, like:

    my $val = $object->return_false->[0];

    sub return_false { return }

The above would trigger an error that the value returned by `return_false` is not an array reference.
Instead of checking on the recipient end what kind of returned value was returned, the caller only need to check if it is defined or not, no matter the context in which it is called.

For example:

    my $this = My::Object->new;
    my $val  = $this->call1;
    # return undef)

    # object context
    $val = $this->call1->call_again;
    # $val is undefined

    # hash reference context
    $val = $this->call1->fake->{name};
    # $val is undefined

    # array reference context
    $val = $this->call1->fake->[0];
    # $val is undefined

    # code reference context
    $val = $this->call1->fake->();
    # $val is undefined

    # scalar reference context
    $val = ${$this->call1->fake};
    # $val is undefined

    # simple scalar
    $val = $this->call1->fake;
    # $val is undefined

    package My::Object;
    use parent qw( Module::Generic );

    sub call1
    {
        return( shift->call2 );
    }

    sub call2 { return( shift->new_null ); }

    sub call_again
    {
        my $self = shift( @_ );
        print( "Got here in call_again\n" );
        return( $self );
    }

This technique is also used by ["error"](#error) to set an error object and return undef but still allow chaining beyond the error. See ["error"](#error) and [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) for more information.

## new\_number

Instantiate a new [Module::Generic::Number](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANumber) object. If any arguments are provided, it will pass it to ["new" in Module::Generic::Number](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANumber#new) and return the object.

## new\_scalar

Instantiate a new [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) object. If any arguments are provided, it will pass it to ["new" in Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar#new) and return the object.

## new\_tempdir

Returns a new temporary directory by calling ["tempdir" in Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile#tempdir)

## new\_tempfile

Returns a new temporary directory by calling ["tempfile" in Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile#tempfile)

## new\_version

Provided with a version and this will return a new [version](https://metacpan.org/pod/version) object.

If the value provided is not a suitable version, this will set an [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`

## noexec

Sets the module property _\_msg\_no\_exec\_sub_ to true, so that any call to ["message"](#message) whose arguments include a reference to a sub routine, will not try to execute the code. For example, imagine you have a sub routine such as:

    sub hello
    {
        return( "Hello !" );
    }

And in your code, you write:

    $self->message( 2, "Someone said: ", \&hello );

If _\_msg\_no\_exec\_sub_ is set to false (by default), then the above would print out the following message:

    Someone said Hello !

But if _\_msg\_no\_exec\_sub_ is set to true, then the same would rather produce the following :

    Someone said CODE(0x7f9103801700)

## pass\_error

Provided with an error, typically a [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object, but it could be anything as long as it is an object, hopefully an exception object, this will set the error value to the error provided, and without issuing any new warning nor creating a new [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object.

It makes it possible to pass the error along so the caller can retrieve it later. This is typically used by a method calling another one in another module that produced an error. For example :

    sub getCustomerInfo
    {
        my $self = shift( @_ );
        # Maybe a LWP::UserAgent sub class?
        my $client = $self->lwp_client_object;
        my $res = $client->get( $remote_api_endpoint ) ||
            return( $self->pass_error( $client->error ) );
    }

Then :

    my $client_info = $object->getCustomerInfo || die( $object->error, "\n" );

Which would return the http client error that has been passed along

You can optionally provide an hash of parameters as the last argument, such as:

    return( $self->pass_error( $obj->error, { class => 'My::Exception', code => 400 } ) );

Or, you could also pass all parameters as an hash reference, such as:

    return( $self->pass_error({
        error => $obj->error,
        class => 'My::Exception',
        code => 400,
    }) );

Supported options are:

- `callback`

    A code reference, such as a subroutine reference or an anonymous code that will be executed. This is designed to be used to do some cleanup.

- `class`

    The name of a class name to re-bless the error object provided.

- `code`

    The error code to set in the error object being passed.

- `error`

    The error object to be passed on.

    If this is not provided, it will get it with the object `error` method, or the class global variable `$ERROR`

## quiet

Set or get the object property _quiet_ to true or false. If this is true, no warning will be issued when ["error"](#error) is called.

## save

Provided with some data and a file path, or alternatively an hash reference of options with the properties _data_, _encoding_ and _file_, this will write to the given file the provided _data_ using the encoding _encoding_.

This is designed to simplify the tedious task of write to files.

If it cannot open the file in write mode, or cannot print to it, this will set an error and return undef. Otherwise this returns the size of the file in bytes.

## serialise

This method use a specified serialiser class and serialise the given data either by returning it or by saving it directly to a given file.

The serialisers currently supported are: [CBOR::Free](https://metacpan.org/pod/CBOR%3A%3AFree), [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS), [JSON](https://metacpan.org/pod/JSON), [Sereal](https://metacpan.org/pod/Sereal) and [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) (or the legacy version [Storable](https://metacpan.org/pod/Storable)). They are not required by [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric), so you must install them yourself. If the serialiser chosen is not installed, this will set an [errr](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`.

This method takes some data and an optional hash or hash reference of parameters. It can then:

- save data directly to File
- save data to a file handle (only with [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) / [Storable](https://metacpan.org/pod/Storable))
- Return the serialised data

The supported parameters are:

- `append`

    Boolean. If true, the serialised data will be appended to the given file. This works only in conjonction with _file_

- `base64`

    Thise can be set to a true value like `1`, or to your preferred base64 encoder/decoder, or to an array reference containing 2 code references, the first one for encoding and the second one for decoding.

    If this is set simply to a true value, `serialise` will call ["\_has\_base64"](#_has_base64) to find out any installed base64 modules. Currently the ones supported are: [Crypt::Misc](https://metacpan.org/pod/Crypt%3A%3AMisc) and [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64). Of course, you need to have one of those modules installed first before it can be used.

    If this option is set and no appropriate module could be found, `serialise` will return an error.

- `file`

    String. A file path where to store the serialised data.

- `io`

    A file handle. This is used when the serialiser is [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) / [Storable](https://metacpan.org/pod/Storable) to call its function ["store\_fd" in Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved#store_fd) and ["fd\_retrieve" in Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved#fd_retrieve)

- `lock`

    Boolean. If true, this will lock the file before writing to it. This works only in conjonction with _file_ and the serialiser [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved)

- `serialiser` or `serializer`

    A string being the class of the serialiser to use. This can be only either [Sereal](https://metacpan.org/pod/Sereal) or [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved)

Additionally the following options are supported and passed through directly for each serialiser:

- [CBOR::Free](https://metacpan.org/pod/CBOR%3A%3AFree): `canonical`, `string_encode_mode`, `preserve_references`, `scalar_references`
- [CBOR](https://metacpan.org/pod/CBOR%3A%3AXS): `max_depth`, `max_size`, `allow_unknown`, `allow_sharing`, `allow_cycles`, `forbid_objects`, `pack_strings`, `text_keys`, `text_strings`, `validate_utf8`, `filter`
- [JSON](https://metacpan.org/pod/JSON): `allow_blessed` `allow_nonref` `allow_unknown` `allow_tags` `ascii` `boolean_values` `canonical` `convert_blessed` `filter_json_object` `filter_json_single_key_object` `indent` `latin1` `max_depth` `max_size` `pretty` `relaxed` `space_after` `space_before` `utf8`
- ["encode" in Sereal::Decoder](https://metacpan.org/pod/Sereal%3A%3ADecoder#encode) if the serialiser is [Sereal](https://metacpan.org/pod/Sereal): `aliased_dedupe_strings`, `canonical`, `canonical_refs`, `compress`, `compress_level`, `compress_threshold`, `croak_on_bless`, `dedupe_strings`, `freeze_callbacks`, `max_recursion_depth`, `no_bless_objects`, `no_shared_hashkeys`, `protocol_version`, `snappy`, `snappy_incr`, `snappy_threshold`, `sort_keys`, `stringify_unknown`, `undef_unknown`, `use_protocol_v1`, `warn_unknown`
- [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) / [Storable](https://metacpan.org/pod/Storable): no option available

If an error occurs, this sets an [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`

## serialize

Alias for ["serialise"](#serialise)

## set

**set**() sets object inner data type and takes arguments in a hash like fashion:

    $obj->set( 'verbose' => 1, 'debug' => 0 );

## subclasses

Provided with a _CLASS_ value, this method try to guess all the existing sub classes of the provided _CLASS_.

If _CLASS_ is not provided, the class into which was blessed the calling object will
be used instead.

It returns an array of subclasses in list context and a reference to an array of those
subclasses in scalar context.

If an error occured, undef is returned and an error is set accordingly. The latter can
be retrieved using the **error** method.

## true

Returns a `true` variable from [Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean)

## false

Returns a `false` variable from [Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean)

## verbose

Set or get the verbosity level with an integer.

## will

This will try to find out if an object supports a given method call and returns the code reference to it or undef if none is found.

## AUTOLOAD

The special **AUTOLOAD**() routine is called by perl when no matching routine was found
in the module.

**AUTOLOAD**() will then try hard to process the request.
For example, let's assue we have a routine **foo**.

It will first, check if an equivalent entry of the routine name that was called exist in
the hash reference of the object. If there is and that more than one argument were
passed to this non existing routine, those arguments will be stored as a reference to an
array as a value of the key in the object. Otherwise the single argument will simply be stored
as the value of the key of the object.

Then, if called in list context, it will return a array if the value of the key entry was an array
reference, or a hash list if the value of the key entry was a hash reference, or finally the value
of the key entry.

If this non existing routine that was called is actually defined, the routine will be redeclared and
the arguments passed to it.

If this fails too, it will try to check for an AutoLoadable file in `auto/PackageName/routine_name.al`

If the filed exists, it will be required, the routine name linked into the package name space and finally
called with the arguments.

If the require process failed or if the AutoLoadable routine file did not exist, **AUTOLOAD**() will
check if the special routine **EXTRA\_AUTOLOAD**() exists in the module. If it does, it will call it and pass
it the arguments. Otherwise, **AUTOLOAD** will die with a message explaining that the called routine did 
not exist and could not be found in the current class.

# SUPPORT METHODS

Those methods are designed to be called from the package inheriting from [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) to perform various function and speed up development.

## \_\_create\_class

Provided with an object property name and an hash reference representing a dictionary and this will produce a dynamically created class/module.

If a property _\_class_ exists in the dictionary, it will be used as the class/package name, otherwise a name will be derived from the calling object class and the object property name. For example, in your module :

    sub products { return( 'products', shift->_set_get_class(
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then calling your module method **products** such as :

    my $prod = $object->products({
        name => 'Cool product',
        customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' },
        orders => [qw( 123 987 456 654 )],
        active => 1,
        metadata => { transaction_id => 123, api_call_id => 456 },
        stock => 10,
        uri => 'https://example.com/p/20'
    });

Using the resulting object `$prod`, we can access this dynamically created class/module such as :

    printf( <<EOT, $prod->name, $prod->orders->length, $prod->customer->last_name,, $prod->url->path )
    Product name: %s
    No of orders: %d
    Customer name: %s
    Product page path: %s
    EOT

## \_\_instantiate\_object

    my $o = $self->__instantiate_object( 'emails', 'Some::Module', @_ );
    # or, with a callback
    my $o = $self->__instantiate_object({ field => 'emails', callback => sub
    {
        my( $class, $args ) = @_;
        return( $class->parse_bare_address( $args->[0] ) );
    }}, 'Email::Address::XS', @_ );

Provided with an object property name, and a class/package name, this will attempt to load the module if it is not already loaded. It does so using ["load\_class" in Class::Load](https://metacpan.org/pod/Class%3A%3ALoad#load_class). Once loaded, it will init an object passing it the other arguments received. It returns the object instantiated upon success or undef and sets an ["error"](#error)

This is a support method used by ["\_instantiate\_object"](#_instantiate_object)

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

- `field`

    Mandatory. The object property name.

- `callback`

    Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

    The current object is accessible in the callback as the special variable `$_`

This is a useful callback when the module instantiation either does not use the `new` method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as [Email::Address::XS](https://metacpan.org/pod/Email%3A%3AAddress%3A%3AXS)

## \_instantiate\_object

This does the same thing as ["\_\_instantiate\_object"](#__instantiate_object) and the purpose is for this method to be potentially superseded in your own module. In your own module, you would call ["\_\_instantiate\_object"](#__instantiate_object)

## \_can

Provided with a value and a method name, and this will return true if the value provided is an object that ["can" in UNIVERSAL](https://metacpan.org/pod/UNIVERSAL#can) perform the method specified, or false otherwise.

You can also provide an array of method names to check instead of just a method name. In that case, all method names provided must be supported by the object otherwise it will return false.

This makes it more convenient to write:

    if( $self->_can( $obj, 'some_method' ) )
    {
        # ...
    }

or

    if( $self->_can( $obj, [qw(some_method other_method )] ) )
    {
        # ...
    }

than to write:

    if( Scalar::Util::bless( $obj ) && $obj->can( 'some_method' )
    {
        # ...
    }

## \_can\_overload

    my $rv = $self->_can_overload( undef, '""' ); # false
    my $rv = $self->_can_overload( '', '""' ); # false
    my $rv = $self->_can_overload( $some_object_not_overloaded, '""' ); # false
    # In this example, it would return false, because, although it is an overloaded value provided, that object has no support for the operators specified.
    my $rv = $self->_can_overload( $some_object_overloaded, '""' ); # false
    my $rv = $self->_can_overload( $some_good_object_overloaded, '""' ); # true
    my $rv = $self->_can_overload( $some_good_object_overloaded, [ '""', 'bool' ] ); # true

Provided with some value and a string representing an operator, or an array reference of operators, and this will return true if the value is an object that has the specified operator, or operators in case of an array reference of operators provided, overloaded.

It returns false otherwise.

## \_get\_args\_as\_array

Provided with arguments and this support method will return the arguments provided as an array reference irrespective of whether they were initially provided as array reference or a simple array.

For example:

    my $array = $self->_get_args_as_array(qw( those are arguments ));
    # returns an array reference containing: 'those', 'are', 'arguments'
    my $array = $self->_get_args_as_array( [qw( those are arguments )] );
    # same result as previous example
    my $array = $self->_get_args_as_array(); # no args provided
    # returns an empty array reference

## \_get\_args\_as\_hash

Provided with arguments and this support method will return the arguments provided as hash reference irrespective of whether they were initially provided as hash reference or a simple hash.

In list context, this returns an hash reference and an array reference containing the order of the properties provided.

For example:

    my $ref = $self->_get_args_as_hash( first => 'John', last => 'Doe' );
    # returns hash reference { first => 'John', last => 'Doe' }
    my $ref = $self->_get_args_as_hash({ first => 'John', last => 'Doe' });
    # same result as previous example
    my $ref = $self->_get_args_as_hash(); # no args provided
    # returns an empty hash reference
    my( $ref, $keys ) = $self->_get_args_as_hash( first => 'John', last => 'Doe' );

In the last example, `$keys` is an [array object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) containing the list of properties passed an in the order they were provided, i.e. `first` and `last`. If the properties were provided as an hash reference, the `$keys` returned will be the sorted list of properties, such as:

    my( $ref, $keys ) = $self->_get_args_as_hash({ last => 'Doe', first => 'John' });

Here, `$keys` will be sorted and contain the properties in their alphabetical order.

However, this will return empty:

    my $ref = $self->_get_args_as_hash( { age => 42, city => 'Tokyo' }, some_other => 'parameter' );

This returns an empty hash reference, because although the first parameter is an hash reference, there is more than one parameter.

As of version v0.24.0, this utility method allows for more advanced use and permits embedding parameters among arguments, remove them from the list and return them.

For example:

Assuming `@_` contains: `foo bar debug 4 baz`

    my $ref = $self->_get_args_as_hash( @_, args_list => [qw( debug )] );

This will set `$ref` with `debug` only.

Even the special parameter `args_list` does not have to be at the end and could be anywhere:

    my $ref = $self->_get_args_as_hash( 'foo', 'bar', args_list => [qw( debug )], 'debug', 4, 'baz' );

If you want to modify `@_`,because you need its content without any params, pass `@_` as an array reference.

    my $ref = $self->_get_args_as_hash( \@_, args_list => [qw( debug )] );
    say "@_";

`$ref` is an hash reference that would contain `debug` and `@_` only contains `foo bar baz`

You can also simply pass `@_` as a reference to simply save memory.

Assuming `@_` is `foo bar baz 3 debug 4`

    my $ref = $self->_get_args_as_hash( \@_ );

This would set `$ref` to be an hash reference with keys `foo baz debug`

## \_get\_symbol

    my $obj = My::Class->new;
    my $sym = $obj->_get_symbol( '$VERSION' );
    my $sym = $obj->_get_symbol( 'Other::Class' => '$VERSION' );

This returns the symbol for the given variable in the current package, or, if a package is explicitly specified, in that package.

Variables can be `scalar` with `$`, `array` with `@`, `hash` with `%`, or `code` with `&`

It returns a reference if found, otherwise, if not found, `undef` in scalar context or an empty list in list context.

If an error occurs, it sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context or an empty list in list context.

## \_get\_stack\_trace

This will return a [Devel::StackTrace](https://metacpan.org/pod/Devel%3A%3AStackTrace) object initiated with the following options set:

- `indent` 1

    This will set an initial indent tab

- `skip_frames` 1

    This is set to 1 so this very method is not included in the frames stack

## \_has\_base64

Provided with a value and this returns an array reference containing 2 code references: one for encoding and one for decoding.

Value provided can be a simple true value, such as `1`, and then `_has_base64` will check if [Crypt::Misc](https://metacpan.org/pod/Crypt%3A%3AMisc) and [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64) are installed on the system and will use in priority [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64)

The value provided can also be an array reference already containing 2 code references, and in such case, that value is simply returned. Nothing more is done.

Finally, the value provided can be a module class name. `_has_base64` knows only of [Crypt::Misc](https://metacpan.org/pod/Crypt%3A%3AMisc) and [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64), so if you want to use any other one, arrange yourself to pass to `_has_base64` an array reference of 2 code references as explained above.

## \_has\_symbol

    my $obj = My::Class->new;
    my $bool = $obj->_has_symbol( '$VERSION' );
    my $bool = $obj->_has_symbol( 'Other::Class' => '$VERSION' );

This returns true (1) if the specified variable exists in the current package, or, if a package is explicitly specified, in that package. It returns false (0) if the package does not have that variable.

Variables can be `scalar` with `$`, `array` with `@`, `hash` with `%`, or `code` with `&`

If an error occurs, it sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context or an empty list in list context.

## \_implement\_freeze\_thaw

Provided with a list of package names and this method will implement in each of them the subroutines necessary to handle [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) (or the legacy [Storable](https://metacpan.org/pod/Storable)), [CBOR](https://metacpan.org/pod/CBOR%3A%3AXS) and [Sereal](https://metacpan.org/pod/Sereal) serialisation.

In effect, it will check that the subroutines `FREEZE`, `THAW`, `STORABLE_freeze` and `STORABLE_thaw` exists or sets up simple ones if they are not defined.

This works for packages that use hash-based objects. However, you need to make sure there is no specific package requirements, and if there is, you might need to customise those subroutines by yourself.

## \_is\_a

Provided with an object and a package name and this will return true if the object is a blessed object from this package name (or a sub package of it), or false if not.

The value of this is to reduce the burden of having to check whether the object actually exists, i.e. is not null or undef, if it is an object and if it is from that class. This allows to do it in just one method call like this:

    if( $self->_is_a( $obj, 'My::Package' ) )
    {
        # Do something
    }

Of course, if you are sure the object is actually an object, then you can directly do:

    if( $obj->isa( 'My::Package' ) )
    {
        # Do something
    }

## \_is\_array

Provided with some data, this checks if the data is of type array, even if it is an object.

This uses ["reftype" in Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil#reftype) to achieve that purpose. So for example, an object such as :

    package My::Module;

    sub new
    {
        return( bless( [] => ( ref( $_[0] ) || $_[0] ) ) );
    }

This would produce an object like :

    My::Module=ARRAY(0x7f8f3b035c20)

When checked with ["\_is\_array"](#_is_array) this, would return true just like an ordinary array.

If you would use :

    ref( $object );

It would rather return the module package name: `My::Module`

## \_is\_class\_loadable

Takes a module name and an optional version number and this will check if the module exist and can be loaded by looking at the `@INC` and using [version](https://metacpan.org/pod/version) to compare required version and existing version.

It returns true if the module can be loaded or false otherwise.

## \_is\_class\_loaded

Provided with a class/package name, this returns true if the module is already loaded or false otherwise.

It performs this test by checking if the module is already in `%INC`.

## \_is\_class\_loadable

Provided with a package name, a.k.a. a class, and an optional version and this will endeavour to check if that class is installed and if a version is provided, if it is greater or equal to the version provided.

If the module is not already loaded and a version was provided, it uses [Module::Metadata](https://metacpan.org/pod/Module%3A%3AMetadata) to get that module version.

It returns true if the module can be loaded or false otherwise.

If an error occurred, it sets an [error](#error) and returns `undef`, so be sure to check whether the return value is defined.

## \_is\_class\_loaded

Provided with a package name, a.k.a. a class, and this returns true if the class has already been loaded or false otherwise.

If you are running under mod\_perl, this method will use ["loaded" in Apache2::Module](https://metacpan.org/pod/Apache2%3A%3AModule#loaded) to find out, otherwise, it will simply check if the class exists in `%INC`

## \_is\_code

Provided with some value, possibly, undefined, and this returns true if it is a `CODE`, such as a subroutine reference or an anonymous subroutine, or false otherwise.

## \_is\_empty

This checks if a value was provided, and if it is defined, or if it has a positive length, or is a scalar object that has the method `defined`, which returns false.

Based on those checks, it returns true (1) if it appears the value is undefined or empty, and false (0) otherwise.

## \_is\_glob

Provided with some value, possibly, undefined, and this returns true if it is a filehandle, or false otherwise.

## \_is\_hash

Same as ["\_is\_array"](#_is_array), but for hash reference.

You can pass also the additional argument `strict`, in which case, this will apply only to non-objects.

For example:

    my $hash = {};
    say $this->_is_hash( $hash ); # true
    my $obj = Foo::Bar->new;
    say $this->_is_hash( $obj ); # true
    # but...
    say $this->_is_hash( $obj => 'strict' ); # false

## \_is\_integer

Returns true if the value provided is an integer, or false otherwise. A valid value includes an integer starting with `+` or `-`

## \_is\_ip

Returns true if the given IP has a syntax compliant with IPv4 or IPv6 including CIDR notation or not, false otherwise.

For this method to work, you need to have installed [Regexp::Common::net](https://metacpan.org/pod/Regexp%3A%3ACommon%3A%3Anet)

## \_is\_number

Returns true if the provided value looks like a number, false otherwise.

## \_is\_object

Provided with some data, this checks if the data is an object. It uses ["blessed" in Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil#blessed) to achieve that purpose.

## \_is\_overloaded

Provided with some value, presumably an object, and this will return true if it is overloaded in some way, or false if it is not.

## \_is\_scalar

Provided with some data, this checks if the data is of type scalar reference, e.g. `SCALAR(0x7fc0d3b7cea0)`, even if it is an object.

## \_is\_tty

Returns true if the program is attached to a tty (terminal), meaning that it is run interactively, or false otherwise, such as when its output is piped.

## \_is\_uuid

Provided with a non-zero length value and this will check if it looks like a valid `UUID`, i.e. a unique universal ID, and upon successful validation will set the value and return its representation as a [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) object.

An empty string or `undef` can be provided and will not be checked.

## \_list\_symbols

    my $obj = My::Class->new;
    my @symbols = $obj->_list_symbols;
    my @symbols = $obj->_list_symbols( 'Other::Class' );
    # possible types are: scalar, array, hash and code
    # specify a type to get only the symbols of that type
    my @symbols = $obj->_list_symbols( 'My::Class' => 'scalar' );

This returns a list of all the symbols for the current package, or, if a package is explicitly specified, from that package.

A symbol type can optionally be specified to limit the list of symbols returned. However, if you want to specify a type, you also need to specify a package, even if it is for the current package.

If an error occurs, it sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context or an empty list in list context.

## \_load\_class

    $self->_load_class( 'My::Module' ) || die( $self->error );
    $self->_load_class( 'My::Module', qw( :some_tags SOME_CONSTANTS_TO_IMPORT ) ) || die( $self->error );
    $self->_load_class(
        'My::Module',
        qw( :some_tags SOME_CONSTANTS_TO_IMPORT ),
        { version => 'v1.2.3', caller => 'Its::Me' }
    ) || die( $self->error );
    $self->_load_class( 'My::Module', { no_import => 1 } ) || die( $self->error );

Provided with a class/package name, some optional list of semantics to import, and, as the last parameter, an optional hash reference of options and this will attempt to load the module. This uses ["use" in perlfunc](https://metacpan.org/pod/perlfunc#use), no external module.

Upon success, it returns the package name loaded.

It traps any error with an eval and return ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) if an error occurred and sets an ["error"](#error) accordingly.

Possible options are:

- `caller`

    The package name of the caller. If this is not provided, it will default to the value provided with ["caller" in perlfunc](https://metacpan.org/pod/perlfunc#caller)

- `no_import`

    Set to a true value and this will prevent the loaded module from importing anything into your namespace.

    This is the equivalent of doing:

        use My::Module ();

- `version`

    The minimum version for this class to load. This value is passed directly to ["use" in perlfunc](https://metacpan.org/pod/perlfunc#use)

### THREAD SAFETY WARNING

**\_load\_class** is mostly thread-safe, but dynamic class loading using `eval` and `use` at runtime can pose risks in threaded environments.

Perl caches loaded modules, but if two threads try to load the same module simultaneously, and the module performs initialization in `BEGIN` blocks or via side effects in its import mechanism, this can lead to race conditions or partial loading.

#### Safe Usage Recommendations

- Call `_load_class` during application startup or before any threads are spawned.
- Avoid dynamically loading classes at runtime inside threads unless you are certain the modules being loaded are themselves thread-safe and have no side effects on import.
- To ensure full safety, preload modules at initialization time using `use` or call `_load_class` during the main thread's setup phase.

## \_load\_classes

This will load multiple classes by providing it an array reference of class name to load and an optional hash or hash reference of options, similar to those provided to ["\_load\_class"](#_load_class)

If one of those classes failed to load, it will return immediately after setting an ["error"](#error).

## \_lvalue

This provides a generic [lvalue](https://metacpan.org/pod/perlsub) method that can be used both in assign context or lvalue context.

As of version `0.29.6`, this is an alias for ["\_set\_get\_callback"](#_set_get_callback), which provides more extensive features.

## \_obj2h

This ensures the module object is an hash reference, such as when the module object is based on a file handle for example. This permits [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) to work no matter what is the underlying data type blessed into an object.

## \_on\_error

Sets or gets a code reference, acting as a callback that will be triggered upon call to ["error"](#error) or ["pass\_error"](#pass_error) with an error.

    return( $self->error( "Oops" ) ) if( $something_bad_happened );
    # or
    return( $self->pass_error( $another_error_object ) ) if( $something_bad_happened );

## \_parse\_timestamp

Provided with a string representing a date or datetime, and this will try to parse it and return a [DateTime](https://metacpan.org/pod/DateTime) object. It will also create a [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime) to preserve the original date/datetime string representation and assign it to the [DateTime](https://metacpan.org/pod/DateTime) object. So when the [DateTime](https://metacpan.org/pod/DateTime) object is stringified, it displays the same string that was originally parsed.

Supported formats are:

- `2019-10-03 19-44+0000` or `2019-10-03 19:44:01+0000`

    Found in GNU PO files for example.

- `2019-06-19 23:23:57.000000000+0900`

    Found in PostgreSQL

- `2019-06-20T11:08:27`

    Matching ISO8601 format

- `2019-06-20 02:03:14`

    Found in SQLite

- `2019-06-20 11:04:01`

    Found in MySQL

- `Sun, 06 Oct 2019 06:41:11 GMT`

    Standard HTTP dates

- `12 March 2001 17:07:30 JST`
- `12-March-2001 17:07:30 JST`
- `12/March/2001 17:07:30 JST`
- `12 March 2001 17:07`
- `12 March 2001 17:07 JST`
- `12 March 2001 17:07:30+0900`
- `12 March 2001 17:07:30 +0900`
- `Monday, 12 March 2001 17:07:30 JST`
- `Monday, 12 Mar 2001 17:07:30 JST`
- `03/Feb/1994:00:00:00 0000`
- `2019-06-20`
- `2019/06/20`
- `2016.04.22`
- `2014, Feb 17`
- `17 Feb, 2014`
- `February 17, 2009`
- `15 July 2021`
- `22.04.2016`
- `22-04-2016`
- `17. 3. 2018.`
- `17.III.2020`
- `17. III. 2018.`
- `20030613`
- `2021年7月14日`

    Japanese regular date using occidental years

- `令和3年7月14日`

    Japanese regular date using Japanese era years

- Unix timestamp possibly followed by a dot and milliseconds
- Relative date to current date and time

    Example:

        -5Y - 5 years
        +2M + 2 months
        +3D + 3 days
        -2h - 2 hours
        -4m - 4 minutes
        -10s - 10 seconds

- 'now'

    The word now will set the return value to the current date and time

## \_set\_get

    sub name { return( shift->_set_get( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and some value and this will set or get that value for that property.

However, if the value stored is an array and is called in list context, it will return the array as a list and not the array reference. Same thing for an hash reference. It will return an hash in list context. In scalar context, it returns whatever the value is, such as array reference, hash reference or string, etc.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

## \_set\_get\_array

    sub my_array { return( shift->_set_get_array( 'my_array', @_ ) ); }
    my $ref = $self->my_array( @some_values );
    my $ref = $self->my_array( $array_ref );

or

    sub name { return( shift->_set_get_array({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and some data and this will store the data as an array reference.

It returns the current value stored, such as an array reference notwithstanding it is called in list or scalar context.

Example :

    sub products { return( shift->_set_get_array( 'products', @_ ) ); }

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

## \_set\_get\_array\_as\_object

    sub name { return( shift->_set_get_array_as_object( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get_array_as_object({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and some data and this will store the data as an object of [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray)

If this is called with no data set, an object is created with no data inside and returned

Example :

    # In your module
    sub products { return( shift->_set_get_array_as_object( 'products', @_ ) ); }

And using your method:

    printf( "There are %d products\n", $object->products->length );
    $object->products->push( $new_product );

Alternatively, you can pass an hash reference instead of an object property to provide additional parameters, such as:

- callbacks

    An hash reference of operation type `add` (or `set`)) to callback subroutine name or code reference pairs.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- field

    The object property name

- wantlist

    Boolean. If true, then it will return a list in list context instead of the array object.

For example:

    sub children { return( shift->set_get_array_as_object({
        field => 'children',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

## \_set\_get\_boolean

    sub is_true { return( shift->_set_get_boolean( 'is_true', @_ ) ); }

or

    sub name { return( shift->_set_get_boolean({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and some data and this will store the data as a boolean value.

If the data provided is a [JSON::PP::Boolean](https://metacpan.org/pod/JSON%3A%3APP%3A%3ABoolean) or [Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean) object, the data is stored as is.

If the data is a scalar reference, its referenced value is check and ["true" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#true) or ["false" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#false) is set accordingly.

If the data is a string with value of `true` or `val` ["true" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#true) or ["false" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#false) is set accordingly.

Otherwise the data provided is checked if it is a true value or not and ["true" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#true) or ["false" in Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean#false) is set accordingly.

If no value is provided, and the object property has already been set, this performs the same checks as above and returns either a [JSON::PP::Boolean](https://metacpan.org/pod/JSON%3A%3APP%3A%3ABoolean) or a [Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean) object.

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

- `field`

    The object property name

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

For example:

    sub is_valid { return( shift->set_get_boolean({
        field => 'is_valid',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

## \_set\_get\_callback

    sub name : lvalue { return( shift->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            # The context hash is available with $_
            if( $_->{list} )
            {
                return( @{$self->{name}} );
            }
            else
            {
                return( $self->{name} );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            $self->message( 1, "Got here for 'name' in setter callback" );
            return( $self->{name} = shift( @_ ) );
        },
        field => 'name'
    }, @_ ) ); }
    # ^^^^
    # Don't forget the @_ !

Then, it can be called indifferently as:

    my $rv = $obj->name( 'John' );
    # $rv is John
    $rv = $obj->name;
    # $rv is John
    $obj->name = 'Peter';
    $rv = $obj->name;
    # $rv is Peter

    $obj->colours( qw( orange blue ) );
    my @colours = $obj->colours;
    # returns a list of colours orange and blue
    my $colour = $obj->colours;
    # $colour is 'orange'

Given an hash reference of parameters, and this support method will call the accessor `get` callback or mutator `set` callback depending on whether any arguments were provided.

This support method supports `lvalue` methods as described in ["Lvalue subroutines" in perlfunc](https://metacpan.org/pod/perlfunc#Lvalue-subroutines)

It is similar as [Sentinel](https://metacpan.org/pod/Sentinel), but on steroid, since it handles exception, and provides context, which is often critical.

If a fatal exception occurs in a callback, it is trapped using [try-catch block](https://metacpan.org/pod/Nice%3A%3ATry) and an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) is set and `undef` is returned.

However if an error occurs while operating in an `lvalue` assigned context, such as:

    $obj->name = 'Peter';

Then, to check if there was an error, you could do:

    if( $obj->error )
    {
        # Do something here
    }

If the `fatal` option is set to true, then it would simply die instead.

Supported options are:

- `fatal`

    Boolean. If true, this will result in any exception becoming fatal and thus die.

- `field`

    The name of the object field for which this helper method is used. This is optional.

- `get`

    The accessor subroutine reference or anonymous subroutine that will handle retrieving data.

    This is a mandatory option and this support method will die if this is not provided.

    It will be passed the current object, and return whatever is returned in list context, or in any other context, the first value that this callback would return.

    Also the special variable `$_` will be available and contain the call context.

- `set`

    The mutator subroutine reference or anonymous subroutine that will handle storing data.

    This is an optional option. This means you can set only an accessor `get` callback without specifying a mutator `set` callback.

    It will be passed the current object, and the list of arguments. If the method is used as a regular method, as opposed to an lvalue subroutine, then multiple arguments may be passed:

        $obj->colours( qw( blue orange ) );

    but, if used as an `lvalue` method, of course, only one argument will be available:

        $obj->name = 'John';

    Also the special variable `$_` will be available and contain the call context.

    The value returned is passed back to the caller.

The `context` provided with the special variable `$_` inside the callback may have the following properties:

- `assign`

    This is true when the call context is an `lvalue` subroutine to which a value is being assigned, such as:

        $obj->name = 'John';

- `boolean`

    This is true when the call context is a boolean, such as:

        if( $obj->active )
        {
            # Do something
        }

- `code`

    This is true when the call context is a code reference, such as:

        $obj->my_callback->();

- `count`

    Contains the number of arguments expected by the caller. This is especially interesting when in list context.

- `glob`

    This is true when the call context is a glob.

- `hash`

    This is true when the call context is an hash reference, such as:

        $obj->meta({ client_id => 1234567 });
        my $id = $obj->meta->{client_id};

- `list`

    This is true when the call context is a list, such as:

        my @colours = $obj->colours;

- `lvalue`

    This is true when the call context is an `lvalue` subroutine, such as:

        $obj->name = 'John';

- `object`

    This is true when the call context is an object, such as:

        $obj->something->another_method();

- `refscalar`

        my $name = ${$obj->name};

- `rvalue`

    This is true when the call context is from the right-hand side.

        my $name = $obj->name;

- `scalar`

    This is true when the call context is a scalar:

        my $name = $obj->name;
        say $name; # John

- `void`

    This is true when the call context is void, such as:

        $obj->pointless();

See also [Wanted](https://metacpan.org/pod/Wanted) for more on this context-rich information.

## \_set\_get\_class

Given an object property name, a dynamic class fiels definition hash (dictionary), and optional arguments, this special method will create perl packages on the fly by calling the support method ["\_\_create\_class"](#__create_class)

For example, consider the following:

    #!/usr/local/bin/perl
    BEGIN
    {
        use strict;
        use Data::Dumper;
    };

    {
        my $o = MyClass->new( debug => 3 );
        $o->setup->age( 42 );
        print( "Age is: ", $o->setup->age, "\n" );
        print( "Setup object is: ", $o->setup, "\n" );
        $o->setup->billing->interval( 'month' );
        print( "Billing interval is: ", $o->setup->billing->interval, "\n" );
        print( "Billing object is: ", $o->setup->billing, "\n" );
        $o->setup->rgb( 255, 122, 100 );
        print( "rgb: ", join( ', ', @{$o->setup->rgb} ), "\n" );
        exit( 0 );
    }

    package MyClass;
    BEGIN
    {
        use strict;
        use lib './lib';
        use parent qw( Module::Generic );
    };

    sub setup 
    {
        return( shift->_set_get_class( 'setup',
        {
        name => { type => 'scalar' },
        # or being lazy:
        # name => 'scalar',
        age => { type => 'number' },
        metadata => { type => 'hash' },
        rgb => { type => 'array' },
        url => { type => 'uri' },
        online => { type => 'boolean' },
        created => { type => 'datetime' },
        billing => { type => 'class', definition =>
            {
            interval => { type => 'scalar' },
            frequency => { type => 'number' },
            nickname => { type => 'scalar' },
            }}
        }) );
    }

    1;

    __END__

This will yield:

    Age is: 42
    Setup object is: MyClass::Setup=HASH(0x7fa805abcb20)
    Billing interval is: month
    Billing object is: MyClass::Setup::Billing=HASH(0x7fa804ec3f40)
    rgb: 255, 122, 100

The advantage of this over **\_set\_get\_hash\_as\_object** is that here one controls what fields / method are supported and with which data type.

## \_set\_get\_class\_array

Provided with an object property name, a dictionary to create a dynamic class with ["\_\_create\_class"](#__create_class) and an array reference of hash references and this will create an array of object, each one matching a set of data provided in the array reference. So for example, imagine you had a method such as below in your module :

    sub products { return( shift->_set_get_class_array( 'products', 
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then your script would call this method like this :

    $object->products([
    { name => 'Cool product', customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' }, active => 1, stock => 10, created => '2020-04-12T07:10:30' },
    { name => 'Awesome tool', customer => { first_name => 'Mary', last_name => 'Donald', email => 'm.donald@example.com' }, active => 1, stock => 15, created => '2020-05-12T15:20:10' },
    ]);

And this would store an array reference containing 2 objects with the above data.

## \_set\_get\_class\_array\_object

Same as ["\_set\_get\_class\_array"](#_set_get_class_array), but this returns an [array object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) instead of just a perl array.

When called in list context, it will return its values as a list, otherwise it will return an [array object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray)

## \_set\_get\_code

    sub name { return( shift->_set_get_code( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get_code({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and some code reference and this stores and retrieve the current value.

It returns `undef` and set an error if the provided value is not a code reference.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_datetime

    sub created_on { return( shift->_set_get_datetime( 'created_on', @_ ) ); }

or

    sub created_on { return( shift->_set_get_datetime({
        field => 'created_on',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
        # optionally specify a format to use for all objects
        format => '%FT%TZ',
        # Can also use 'time_zone'
        tz => 'UTC',
    }, @_ ) ); }

Provided with an object property name and asome date or datetime string and this will attempt to parse it and save it as a [DateTime](https://metacpan.org/pod/DateTime) object.

If the data is a 10 digits integer, this will treat it as a unix timestamp.

Parsing also recognise special word such as `now`

The created [DateTime](https://metacpan.org/pod/DateTime) object is associated a [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime) object which enables the [DateTime](https://metacpan.org/pod/DateTime) object to be stringified as a unix timestamp using local time stamp, whatever it is.

Even if there is no value set, and this method is called in chain, it returns a [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) whose purpose is to enable chaining without doing anything meaningful. For example, assuming the property _created_ of your object is not set yet, but in your script you call it like this:

    $object->created->iso8601

Of course, the value of `iso8601` will be empty since this is a fake method produced by [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull). The return value of a method should always be checked.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

- `format`

    An optional format that will be used to create a [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime) that will be attached to the [DateTime](https://metacpan.org/pod/DateTime) object.

- `tz`

    A string representing the time zone for the the datetime.

## \_set\_get\_enum

    sub choice { return( shift->_set_get_enum( 'choice', [qw( yes no )], @_ ) ); }
    # or
    sub choice : lvalue { return( shift->_set_get_enum({
        field   => 'choice',
        allowed => [qw( yes no )],
        # case insensitive
        case    => 0,
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

This support method handles `enum` values, i.e. a list of allowed values that can be set.

It takes either a `field` name, and an array of `allowed` values; or an hash reference with the following supported options:

- `allowed`

    An array reference of allowed values.

- `case`

    A boolean value as to whether the value received should be compared in a case sensitive (true) or case insensitive (false) way against the allowed value.

    Thus, if true, an hypothetical value `yes` would match against the `allowed` values `['yes', 'no']`, but would fail if that value were `YES`

    Default is true.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The field name.

## \_set\_get\_file

    sub file { return( shift->_set_get_file( 'file', @_ ) ); }

or

    sub file { return( shift->_set_get_file({
        field => 'file',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and a file and this will store the given file as a [Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile) object.

It returns `undef` and set an [error](#error) if the provided value is not a proper file.

Note that the files does not need to exist and it can also be a directory or a symbolic link or any other file on the system.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_glob

    sub handle { return( shift->_set_get_glob( 'handle', @_ ) ); }

or

    sub handle { return( shift->_se_set_get_globt_get({
        field => 'handle',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and a glob (file handle) and this will store the given glob.

It returns `undef` and set an [error](#error) if the provided value is not a glob.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_hash

    sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

or

    sub metadata { return( shift->_set_get_hash({
        field => 'metadata',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name and an hash reference and this set the property name with this hash reference.

You can even pass it an associative array, and it will be saved as a hash reference, such as :

    $object->metadata(
        transaction_id => 123,
        customer_id => 456
    );

    my $hash = $object->metadata;

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_hash\_as\_mix\_object

    sub metadata { return( shift->_set_get_hash_as_mix_object( 'metadata', @_ ) ); }

or

    sub metadata { return( shift->_set_get_hash_as_mix_object({
        field => 'metadata',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name, and an optional hash reference and this returns a [Module::Generic::Hash](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash) object, which allows to manipulate the hash just like any regular hash, but it provides on top object oriented method described in details in [Module::Generic::Hash](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash).

This is different from ["\_set\_get\_hash\_as\_object"](#_set_get_hash_as_object) below whose keys and values are accessed as dynamic methods and method arguments.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_hash\_as\_object

Provided with an object property name, an optional class name and an hash reference and this does the same as in ["\_set\_get\_hash"](#_set_get_hash), except it will create a class/package dynamically with a method for each of the hash keys, so that you can call the hash keys as method.

Also it does this recursively while handling looping, in which case, it will reuse the object previously created, and also it takes care of adapting the hash key to a proper field name, so something like `99more-options` would become `more_options`. If the value itself is a hash, it processes it recursively transforming `99more-options` to a proper package name `MoreOptions` prepended by `$class_name` provided as argument or whatever upper package was used in recursion processing.

For example in your module :

    sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

Then populating the data :

    $object->metadata({
        first_name => 'John',
        last_name => 'Doe',
        email => 'john.doe@example.com',
    });

    printf( "Customer name is %s\n", $object->metadata->last_name );

### THREAD SAFETY

This method uses [Module::Generic::Dynamic](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ADynamic), and thus is not thread-safe. It should be invoked only during initialization, before any threads are spawned.

For safe usage in multi-threaded environments, avoid using dynamic class creation features at runtime.

## \_set\_get\_ip

    sub ip { return( shift->_set_get_ip( 'ip', @_ ) ); }

or

    sub ip { return( shift->_set_get_ip({
        field => 'ip',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

This helper method takes a value and check if it is a valid IP address using ["\_is\_ip"](#_is_ip). If `undef` or zero-byte value is provided, it will merely accept it, as it can be used to reset the value by the caller.

If a value is successfully set, it returns a [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) object representing the string passed.

From there you can pass the result to [Net::IP](https://metacpan.org/pod/Net%3A%3AIP) in your own code, assuming you have that module installed.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_lvalue

This is now an alias for ["\_set\_get\_callback"](#_set_get_callback)

## \_set\_get\_number

Provided with an object property name and a number, and this will create a [Module::Generic::Number](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANumber) object and return it.

If an invalid value is provided (e.g., empty string, non-stringifiable reference, or value failing the constraint), an error is returned, accessible via the object's ["error"](#error) method.

As of version `v0.13.0` it also works as a lvalue method. See [perlsub](https://metacpan.org/pod/perlsub)

In your module:

    package MyObject;
    use parent qw( Module::Generic );

    sub level : lvalue { return( shift->_set_get_number( 'level', @_ ) ); }

\# or

    sub level : lvalue { return( shift->_set_get_number({
        field => 'level',
        check => sub {
            my( $self, $value ) = @_;
            # do some check here
            return(1); # Do not forget to return true
        },
        constraint => 'unsigned_int',
        # or
        # constraint => qr/\d+/,
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

In the script using module `MyObject`:

    my $obj = MyObject->new;
    $obj->level = 3; # level is now 3
    # or
    $obj->level(4) # level is now 4
    print( "Level is: ", $obj->level, "\n" ); # Level is 4
    print( "Is it an odd number: ", $obj->level->is_odd ? 'yes' : 'no', "\n" );
    # Is it an od number: no
    $obj->level++; # level is now 5

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `constraint`

    Either a regular expression provided using the operator `qr//`, or a known token:

    - `bin`, `binary`

        A binary, supporting fractional values (e.g., `101.11`) and scientific notation (e.g., `101.11E-2`).

    - `hex`, `hexadecimal`

        A hexadecimal, supporting fractional values (e.g., `FF.1A`) and scientific notation (e.g., `FF.1AE-2`).

    - `int`, `integer`
    - `long`

        A long integer, i.e. an integer between `-2,147,483,648`, and `2,147,483,647`

    - `negative_int`

        A negative integer

    - `oct`, `octal`

        An octal number, supporting fractional values (e.g., `77.33`) and scientific notation (e.g., `77.33E-2`).

    - `short`

        A short integer, i.e. an integer between `-32,768`, and `32,767`

    - `unsigned_int`, `unsigned_integer`, `positive_int`

        An unsigned integer, on which is aliased a positive integer

    - `unsigned_long`

        An unsigned long integer, i.e. an integer between `0`, and `4,294,967,295` (2^32-1)

    - `unsigned_real`, `unsigned_dec`, `unsigned_decimal`, `unsigned_float`, `unsigned_double`, `positive_real`, `positive_dec`, `positive_decimal`, `positive_float`, `positive_double`

        A positive decimal number.

    - `unsigned_short`

        An unsigned short integer, i.e. an integer between `0`, and `65,535` (2^16-1)

    - `real`, `dec`, `decimal`, `double`, `float`

        A real number, on which is aliased decimal number, double-precision number, and floating-point number

    - `signed_byte`, `byte`

        A signed byte, i.e., an integer between `-128` and `127`.

    - `unsigned_byte`

        An unsigned byte, i.e., an integer between `0` and `255`.

- `field`

    The object property name

- `undef_ok`

    If this is set to a true value, this support method will allow undef to be set. Default to false, which means an undefined value passed will be ignored.

For example:

    sub length { return( shift->_set_get_number({
        field => 'length',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

## \_set\_get\_number\_as\_scalar

    sub name { return( shift->_set_get_number_as_scalar( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

This sets or gets a number as a regular string, but checking the value is indeed a number by using [Regexp::Common](https://metacpan.org/pod/Regexp%3A%3ACommon)

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_number\_or\_object

Provided with an object property name and a number or an object and this call the value using ["\_set\_get\_number"](#_set_get_number) or ["\_set\_get\_object"](#_set_get_object) respectively

## \_set\_get\_object

    sub myobject { return( shift->_set_get_object({ field => 'myobject', no_init => 1 }, My::Class, @_ ) ); }

    sub myobject { return( shift->_set_get_object({
        field => 'myobject',
        no_init => 1,
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
    }, My::Class, @_ ) ); }

    sub myobject { return( shift->_set_get_object( 'myobject', My::Class, @_ ) ); }

Provided with an object property name, a class/package name and some data and this will initiate a new object of the given class passing it the data.

The property name can also be an hash reference that will be used to provide more granular settings:

- `callback`

    A callback code reference that will be passed the module class name and the arguments as an array reference.

    This is used to instantiate the module object in a particular way and/or to have finer control about object instantiation.

    Any fatal error during object instantiation is caught and an [error](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) would be set and `undef` would be returned in scalar context, or an empty list in list context.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `field`

    The actual property name

- `no_init`

    Boolean that, when set, instruct to not instantiate a class object if one is not instantiated yet.

If you pass an undefined value, it will set the property as undefined, removing whatever was set before.

You can also provide an existing object of the given class. ["\_set\_get\_object"](#_set_get_object) will check the object provided does belong to the specified class or it will set an error and return undef.

It returns the object currently set, if any.

## \_set\_get\_object\_array

    sub mymethod { return( shift->_set_get_object_array( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_array({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks =>
        {
            array_add => sub
            {
                my $def = shift( @_ );
                my( $pos, $ref ) = @$def{qw( start added )};
                return unless( blessed( $ref->[0] ) && $ref->[0]->isa( 'MyPackage') );
                return(1);
            },
            array_remove => sub
            {
                my $def = shift( @_ );
                my( $start, $end ) = @$def{qw( start end )};
                printf( STDERR "Called from package %s at line %d\n", @{$def->{caller}}[0,2] );
                # Do some check to accept or reject
                return(1); # always return true to accept
            },
        },
    }, 'Some::Module', @_ ) ); }

Provided with an object property name and a class/package name and similar to ["\_set\_get\_object\_array2"](#_set_get_object_array2) this will create an array reference of objects.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

- `field`

    Mandatory. The object property name.

- `callback`

    Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

- `callbacks`

    Optional. An hash of keys-callbacks pairs. The supported callback types are: `array_add`, and `array_remove`

    When set, those callbacks will be called when data is added or removed to the array. Be careful that this may slow down your application depending on the frequency of the array call, and what the callback routine does.

    See the ["callback" in Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray#callback) for more information, and also the methods ["get\_callback" in Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray#get_callback), and ["has\_callback" in Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray#has_callback)

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

This is a useful callback when the module instantiation either does not use the `new` method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as [Email::Address::XS](https://metacpan.org/pod/Email%3A%3AAddress%3A%3AXS)

    sub emails { return( shift->_set_get_object_array({
        field => 'emails',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->parse_bare_address( $args->[0] ) );
        },
    }, 'Email::Address::XS', @_ ) ); }

## \_set\_get\_object\_array2

    sub mymethod { return( shift->_set_get_object_array2( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_array2({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
    }, 'Some::Module', @_ ) ); }

Provided with an object property name, a class/package name and some array reference itself containing array references each containing hash references or objects, and this will create an array of array of objects.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

- `field`

    Mandatory. The object property name.

- `callback`

    Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

This is a useful callback when the module instantiation either does not use the `new` method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as [Email::Address::XS](https://metacpan.org/pod/Email%3A%3AAddress%3A%3AXS)

## \_set\_get\_object\_array\_object

Provided with an object property name, a class/package name and some data and this will create an array of object similar to ["\_set\_get\_object\_array"](#_set_get_object_array), except the array produced is a [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray)

This method accepts the same arguments as ["\_set\_get\_object\_array"](#_set_get_object_array)

## \_set\_get\_object\_lvalue

Same as ["\_set\_get\_object\_without\_init"](#_set_get_object_without_init) but with the possibility of setting the object value as an lvalue method:

    $o->my_property = $my_object;

## \_set\_get\_object\_variant

    sub name { return( shift->_set_get_object_variant( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get_object_variant({
        field => 'name',
        check => sub {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name, a class/package name and some data, and depending whether the data provided is an hash reference or an array reference, this will either instantiate an object for the given hash reference or an array of objects with the hash references in the given array.

This means the value stored for the object property will vary between an hash or array reference.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

- `field`

    Mandatory. The object property name.

- `callback`

    Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

This is a useful callback when the module instantiation either does not use the `new` method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as [Email::Address::XS](https://metacpan.org/pod/Email%3A%3AAddress%3A%3AXS)

    sub emails { return( shift->_set_get_object_variant({
        field => 'emails',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->parse_bare_address( $args->[0] ) );
        },
    }, 'Email::Address::XS', @_ ) ); }

## \_set\_get\_object\_without\_init

    sub mymethod { return( shift->_set_get_object_without_init( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_without_init({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
    }, 'Some::Module', @_ ) ); }
    # then
    my $this = $obj->mymethod; # possibly undef if it was never instantiated
    # return the C<Some::Module> object after having instantiated it
    my $this = $obj->mymethod( some => parameters );

Sets or gets an object, but contrary to ["\_set\_get\_object"](#_set_get_object) this method will not try to instantiate the object, unless of course you pass it some values.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

- `field`

    Mandatory. The object property name.

- `callback`

    Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

    Whatever this returns will set the value for this object property.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

This is a useful callback when the module instantiation either does not use the `new` method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as [Email::Address::XS](https://metacpan.org/pod/Email%3A%3AAddress%3A%3AXS)

## \_set\_get\_scalar

    sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get_scalar({
        field => 'name',
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks =>
        {
            set => sub
            {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name, and a string, possibly a number or anything really and this will set the property value accordingly. Very straightforward.

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

- `field`

    The object property name

- `callbacks`

    An hash reference of operation type `add` (or `set`), or `get` to callback subroutine name or code reference pairs.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

For example:

    sub name { return( shift->set_get_scalar({
        field => 'name',
        callbacks => 
        {
            set => '_some_add_callback',
            get => sub
            {
                my $self = shift( @_ );
                # do something that returns a value.
            },
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

It returns the currently value stored.

## \_set\_get\_scalar\_as\_object

    sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

or

    sub name { return( shift->_set_get_scalar_as_object({
        field => 'name',
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => 
        {
            set => sub
            {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name, and a string or a scalar reference and this stores it as an object of [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar)

If there is already an object set for this property, the value provided will be assigned to it using ["set" in Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar#set)

If it is called and not value is set yet, this will instantiate a [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) object with no value.

So a call to this method can safely be chained to access the [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) methods. For example :

    sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

Then, calling it :

    $object->name( 'John Doe' );

Getting the value :

    my $cust_name = $object->name;
    print( "Nothing set yet.\n" ) if( !$cust_name->length );

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

- `field`

    The object property name

- `callbacks`

    An hash reference of operation type `add` (or `set`), or `get` to callback subroutine name or code reference pairs.

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

For example:

    sub name { return( shift->set_get_scalar_as_object({
        field => 'name',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

## \_set\_get\_scalar\_or\_object

Provided with an object property name, and a class/package name and this stores the value as an object calling ["\_set\_get\_object"](#_set_get_object) if the value is an object of class _class_ or as a string calling ["\_set\_get\_scalar"](#_set_get_scalar)

If no value has been set yet, this returns a [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) object to enable chaining.

## \_set\_get\_uri

    sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }
    sub uri { return( shift->_set_get_uri( { field => 'uri', class => 'URI::Fast' }, @_ ) ); }

or

    sub uri { return( shift->_set_get_uri({
        field => 'uri',
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks => 
        {
            set => sub
            {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object property name, and an uri and this creates an [URI](https://metacpan.org/pod/URI) object and sets the property value accordingly.

Alternatively, the property name can be an hash with the following properties:

- `field`

    The object property name

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `class`

    The URI class to use. By default, [URI](https://metacpan.org/pod/URI), but you could also use [URI::Fast](https://metacpan.org/pod/URI%3A%3AFast), or other class of your choice. That class will be loaded, if it is not loaded already.

It accepts an [URI](https://metacpan.org/pod/URI) object (or any other URI class object), an uri or urn string, or an absolute path, i.e. a string starting with `/`.

It returns the current value, if any, so the return value could be undef, thus it cannot be chained. Maybe it should return a [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) object ?

## \_set\_get\_uuid

    sub id { return( shift->_set_get_uuid( 'id', @_ ) ); }

or

    sub id { return( shift->_set_get_uuid({
        field => 'id',
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks =>
        {
            set => sub
            {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object, a property name, and an UUID (Universal Unique Identifier) and this stores it as an object of [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar).

If an empty or undefined value is provided, it will be stored as is.

However, if there is no value and this method is called in object context, such as in chaining, this will return a special [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull) object that prevents perl error that whatever method follows was called on an undefined value.

Alternatively, you can provide an hash reference instead of a field name, and pass additional parameters, such as:

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `field`

    The object property name

## \_set\_get\_version

    sub version { return( shift->_set_get_version( 'version', @_ ) ); }
    # or
    sub version : lvalue { return( shift->_set_get_version( 'version', @_ ) ); }
    # or
    sub version : lvalue { return( shift->_set_get_version( { field => 'version', class => 'Perl::Version' }, @_ ) ); }

or

    sub version { return( shift->_set_get_version({
        field => 'version',
        check => sub
        {
            my( $self, $value ) = @_; # do some check
            return(1); # Do not forget to return true
        },
        callbacks =>
        {
            set => sub {
                my( $self, $value ) = @_;
                # Do something here with the value set.
            },
        },
    }, @_ ) ); }

Provided with an object, a property name, and a version string and this stores it as an object of [version](https://metacpan.org/pod/version) by default.

Alternatively, the property name can be an hash with the following properties:

- `field`

    The object property name

- `check`

    A `check` anonymous subroutine that will be called with 2 arguments, the current object, and the value being set, but before it is set.

    If this callback returns false, then an error of `Invalid value provided.` will be returned, so make sure to return true to indicate that the check passed.

    The callback can die, and it will be caught, and be interpreted as `false`

- `callbacks`

    An hash reference of callbacks. You can use either `set` or `add` whichever you prefer.

    The callback will be called with the current object, and the value that has already been set.

    Any fatal exception during the callback will not be caught.

- `class`

    The version class to use. By default, [version](https://metacpan.org/pod/version), but you could also use [Perl::Version](https://metacpan.org/pod/Perl%3A%3AVersion), or other class of your choice. That class will be loaded, if it is not loaded already.

The value can also be assigned as an lvalue. Assuming you have a method `version` that implements `_set_get_version`:

    $obj->version = $version;

would work, but of course also:

    $obj->version( $version );

The value can be a legitimate version string, or a version object matching the `class` to be used, which is by default [version](https://metacpan.org/pod/version). If it is a string, it will be made an object of the class specified using `parse` if that class supports it, or by simply calling `new`.

When called in get mode, it will convert any value pre-set, if any, into a version object of the specified class if the value is not an object of that class already, and return it, or else it will return an empty string or undef whatever you will have set in your object for this property.

## \_set\_symbol

    $o->_set_symbol(
        # class defaults to the current object class
        variable => '$some_scalar_ref',
        # variable value defaults to scalar reference to undef
        # or [], {}, sub{} depending on the variable type
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '$some_scalar_name',
        value => \"some string reference",
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '@some_array_name',
        value => $an_array_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '%some_array_name',
        value => $an_hash_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '&some_sub_name',
        value => $a_code_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        # explicitly specify the variable type
        type => 'hash',
        variable => '$some_hash_name',
        value => $an_hash_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'array',
        variable => '$some_array_name',
        value => $an_array_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'scalar',
        variable => '$some_array_name',
        value => $a_scalar_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'code',
        variable => '$some_sub_name',
        # Like \&some_thing, or maybe sub{ # do something here }
        value => $a_code_reference,
    );

This method is used to dynamically add a new symbol to a given class, a.k.a. package. A proper symbol type can only be an array reference, an hash reference, a scalar, a code reference, or a glob. This is useful for metaprogramming or creating dynamically extensible APIs.

This takes the following options:

- `class`

    The class, or package name to add the new symbol to.

- `end_line`

    An integer to specify the end line of the the code reference, represented by the variable, in the class provided. If none is provided, the value for `start_line` will be used.

- `filename`

    An optional filename to associate the new symbol with. For example `/some/where/file.pl`

    This is only used when perl debugging is enabled and for variables that are code reference.

    If no filename is provided, it will default to the value returned by ["caller" in perlfunc](https://metacpan.org/pod/perlfunc#caller)

- `start_line`

    An integer to specify the start line of the code reference, represented by the variable, in the class provided.

    If no start line is provided, it will default to 0.

- `type`

    Optional. Explicitly define the type of the symbol: `scalar`, `array`, `hash`, `code`, or `glob`. This can override the sigil detection logic.

    If this is not explicitly specified, the type will be derived from the sigil, i.e. the first character of the variable name.

    The sigil will determine how the variable will be accessed from the package name. For example:

        $o->_set_symbol(
            class => 'Foo::Bar',
            variable => '@some_array',
            value => [qw( John Peter Paul )],
        );

    The `@Foo::Bar::some_array` is accessible, but not `$Foo::Bar::some_array`, but if you do:

        $o->_set_symbol(
            class => 'Foo::Bar',
            variable => '$some_array',
            value => [qw( John Peter Paul )],
        );

    then, `$Foo::Bar::some_array` is accessible, but not `@Foo::Bar::some_array`

    If you prefer providing a variable with a dollar for the name, because you use a reference, it is ok too. The type will be derived from the value you provide if the value is an array, a code reference or an hash.

    There will be a slight difference in the symbol table. Variable starting with `%`, or `@` can only then be retrieved with the same sigil. If an array, hash or code reference variable is stored with `$`, it will be stored as `REF`, and must be dereferenced when the symbol is later retrieved. For example:

        $o->_set_symbol(
            variable => '$some_array_name',
            value => [qw( John Peter Paul )],
        );
        my $sym = $o->_get_symbol( '$some_array_name' );
        my $ref = $$sym;
        say "@$ref"; # John Peter Paul

    Whereas:

        $o->_set_symbol(
            variable => '@some_array_name',
            value => [qw( John Peter Paul )],
        );
        my $sym = $o->_get_symbol( '@some_array_name' );
        say "@$sym"; # John Peter Paul

    Acceptable value types are: `array`, `code`, `glob`, `hash`, or `scalar`, but also `lvalue`, `regexp`, and `vstring`

- `value`

    A reference to the value you want to assign to that new symbol. For example, a scalar reference, an arrayref, a coderef, etc.

    If the value is not suitable for the new symbol, an error is returned.

- `variable`

    A variable including its `sigil`, i.e. the first character of a variable name, such as `$`, `%`, `@`, or `&`

See also ["\_get\_symbol"](#_get_symbol) to retrieve the symbol set.

### THREAD SAFETY WARNING

**\_set\_symbol is not thread-safe.** It modifies the package's symbol table (via `*{...}` operations), which is global and shared across all threads.

Injecting or redefining symbols dynamically after threads have been created can cause race conditions, unexpected behavior, or crashes.

#### Safe Usage Recommendations

- Call `_set_symbol` _only before_ any threads are created (i.e., during startup/init phase).
- Avoid calling this method at runtime inside threads or shared libraries if thread safety is a concern.
- If using with threads, consider guarding symbol modification with external synchronization (e.g., a global mutex). However, this cannot prevent race conditions if the symbol is already in use.

#### Possible Safer Alternatives

Per-object or closure-based dispatch may be preferable if your use case allows:

    $object->{some_accessor} = sub { ... };

Or use a dynamic delegation pattern via AUTOLOAD:

    sub AUTOLOAD {
        my $method = our $AUTOLOAD;
        return $self->{dynamic_methods}{$method}->(@_);
    }

However, if you truly need to define package-level symbols, this method remains appropriate — just observe the threading caveats above.

## \_str\_val

    my $str = $self->_str_val( $some_object );

This takes a value, possibly an object, especially one that stringifies, and it returns its string representation.

This does the same thing as `overload::StrVal`, expect it handles undefined value, and is called on your class object.

If the value provided is `undef`, or if no value was provided at all, this will simply return an empty string `''`. This is designed so perl will not warn of undefined value being used.

## \_to\_array\_object

Provided with arguments or not, and this will return a [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) object of those data.

    my $array = $self->_to_array_object( qw( Hello world ) ); # Becomes an array object of 'Hello' and 'world'
    my $array = $self->_to_array_object( [qw( Hello world )] ); # Becomes an array object of 'Hello' and 'world'

## \_warnings\_is\_enabled

Called with the class object or providing another class object as argument, and this returns true if warnings are enabled for the given class, false otherwise.

Example:

    $self->_warnings_is_enabled();
    # Providing another class object
    $self->_warnings_is_enabled( $other_object );

## \_warnings\_is\_registered

Called with the class object or providing another class object as argument, and this returns true if warnings are registered for the given class, false otherwise.

This is useful, because calling `warnings::enabled()` to check if warnings are enabled for a given class when that class has not registered for warnings using the pragma `use warnings::register` will produce an error `Unknown warnings category`.

Example:

    $self->_warnings_is_registered();
    # Providing another class object
    $self->_warnings_is_registered( $other_object );

## \_\_dbh

if your module has the global variables `DB_DSN`, this will create a database handler using [DBI](https://metacpan.org/pod/DBI)

It will also use the following global variables in your module to set the database object: `DB_RAISE_ERROR`, `DB_AUTO_COMMIT`, `DB_PRINT_ERROR`, `DB_SHOW_ERROR_STATEMENT`, `DB_CLIENT_ENCODING`, `DB_SERVER_PREPARE`

If `DB_SERVER_PREPARE` is provided and true, `pg_server_prepare` will be set to true in the database handler.

It returns the database handler object.

## DEBUG

Return the value of your global variable _DEBUG_, if any.

## VERBOSE

Return the value of your global variable _VERBOSE_, if any.

# ERROR & EXCEPTION HANDLING

This module has been developed on the idea that only the main part of the application should control the flow and trigger exit. Thus, this module and all the others in this distribution do not die, but rather set and [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return undef. So you should always check for the return value.

Error triggered are transformed into an [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object, or any exception class that is specified by the object property `_exception_class`. For example:

    sub init
    {
        my $self = shift( @_ );
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

Those error objects can then be retrieved by calling ["error"](#error)

If, however, you wanted errors triggered to be fatal, you can set the object property `fatal` to a true value and/or set your package global variable `$FATAL_ERROR` to true. When ["error"](#error) is called with an error, it will ["die" in perlfunc](https://metacpan.org/pod/perlfunc#die) with the error object rather than merely returning `undef`. For example:

    package My::Module;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        our $VERSION = 'v0.1.0';
        our $FATAL_ERROR = 1;
    };

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

To catch fatal error you can use a `try-catch` block such as implemented by [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry).

Since [perl version 5.33.7](https://perldoc.perl.org/blead/perlsyn#Try-Catch-Exception-Handling) you can use the try-catch block using an experimental feature `use feature 'try';`, but this does not support `catch` by exception class.

Note that all helper methods such as `_set_get_*`. when used as mutator, meaning when some values are set successfully, will clear any previous error set. When used as accessor, any previous error set will remain.

# SERIALISATION

The modules in the [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) distribution all supports [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) (or the legacy [Storable](https://metacpan.org/pod/Storable)), [Sereal](https://metacpan.org/pod/Sereal) and [CBOR](https://metacpan.org/pod/CBOR%3A%3AXS) serialisation, by implementing the methods `FREEZE`, `THAW`, `STORABLE_freeze`, `STORABLE_thaw`

Even the IO modules like [Module::Generic::File::IO](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile%3A%3AIO) and [Module::Generic::Scalar::IO](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar%3A%3AIO) can be serialised and deserialised if the methods `FREEZE` and `THAW` are used. By design the methods `STORABLE_freeze` and `STORABLE_thaw` are not implemented in those modules because it would trigger a [Storable](https://metacpan.org/pod/Storable) exception "Unexpected object type (8) in store\_hook()". Instead it is strongly encouraged you use the improved [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved) which addresses and mitigate those issues.

For serialisation with [Sereal](https://metacpan.org/pod/Sereal), make sure to instantiate the [Sereal encoder](https://metacpan.org/pod/Sereal%3A%3AEncoder) with the `freeze_callbacks` option set to true, otherwise, `Sereal` will not use the `FREEZE` and `THAW` methods.

See ["FREEZE/THAW CALLBACK MECHANISM" in Sereal::Encoder](https://metacpan.org/pod/Sereal%3A%3AEncoder#FREEZE-THAW-CALLBACK-MECHANISM) for more information.

For [CBOR](https://metacpan.org/pod/CBOR%3A%3AXS), it is recommended to use the option `allow_sharing` to enable the reuse of references, such as:

    my $cbor = CBOR::XS->new->allow_sharing;

Also, if you use the option `allow_tags` with [JSON](https://metacpan.org/pod/JSON), then all of those modules will work too, since this option enables support for the `FREEZE` and `THAW` methods.

# CLASS FUNCTIONS

## create\_class

Dynamically creates a Perl package with inheritance, optionally injecting getter/setter methods for a variety of data types, including objects, arrays, and more.

This method is provided by [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) and can be called directly or via the `UNIVERSAL` namespace.

    create_class My::Package extends => 'Other::Package';
    create_class My::Package extends => 'Other::Package', method =>
    {
        since => 'datetime',
        uri => 'uri',
        tags => 'array_object',
        meta => 'hash',
        active => 'boolean',
        callback => 'code',
        config => 'file',
        allowed_from => 'ip',
        total => 'number',
        id => 'uuid',
        version => 'version',
        filehandle => 'glob',
        object => { type => 'object', class => 'Some::Class' },
        customer => 
        {
            type => 'class',
            def =>
            {
                id => 'uuid',
                since => 'datetime',
                name => 'scalar_as_object',
                age => 'decimal',
            }
        }
    };

Provided with a class name and an optional hash or hash reference of options, and this will create that class possibly with the requested methods.

Supported options are:

- `extends`

    This represents a parent class to inherit from. If none is provided, it will inherit from [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) by default.

    You may also use the synonym `parent` instead of `extends` if you prefer.

- `method` or `methods`

    A hash reference of method name to their definition, which may be either a string representing a method `type`, or a hash reference, including a `type` property.

    Possible method types supported are:

    - `array`

        Will use the method ["\_set\_get\_array"](#_set_get_array)

    - `array_as_object`

        Will use the method ["\_set\_get\_array\_as\_object"](#_set_get_array_as_object)

    - `boolean`

        Will use the method ["\_set\_get\_boolean"](#_set_get_boolean)

    - `class`

            create_class My::Class method =>
            {
                # Will automatically create, when needed, a class My::Class::Customer
                # with the following methods:
                customer => 
                {
                    type => 'class',
                    def =>
                    {
                        id => 'uuid',
                        since => 'datetime',
                        name => 'scalar_as_object',
                        age => 'decimal',
                    }
                }
            };
            # Then, you could use it like this:
            my $obj = My::Class->new;
            my $cust = $obj->customer(
                # A Module::Generic::Scalar object
                name => 'John Doe',
                id => 'c47e1113-8336-4437-ba20-54f8cd0afb18',
                # A DateTime object
                since => 'now',
                # A Module::Generic::Number object
                age => 32,
            );
            say $obj->name, " is ", $obj->age, " years old.";

        Will use the method ["\_set\_get\_class"](#_set_get_class) that dynamically creates object classes based on the method name it is called upon.

        If the class name provided is not already loaded, it will be created dynamically using `create_class`.

        For this `type`, you will also need to provide 1 other property:

        - 1. `def` or `definition`

            A hash reference used for the definition of this dynamic class.

        See also `class_array` and `class_array_object`.

    - `class_array`

        Will use the method ["\_set\_get\_class\_array"](#_set_get_class_array) to return a conventional perl array of specified object class.

        If the class name provided is not already loaded, it will be created dynamically using `create_class`.

        For this `type`, you will also need to provide 1 other property:

        - 1. `def` or `definition`

            A hash reference used for the definition of this dynamic class.

    - `class_array_object`

        Will use the method ["\_set\_get\_class\_array\_object"](#_set_get_class_array_object) to return an [object array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) of specified object class.

        If the class name provided is not already loaded, it will be created dynamically using `create_class`.

        For this `type`, you will also need to provide 1 other property:

        - 1. `def` or `definition`

            A hash reference used for the definition of this dynamic class.

    - `code`

        Will use the method ["\_set\_get\_code"](#_set_get_code)

    - `datetime`

        Will use the method ["\_set\_get\_datetime"](#_set_get_datetime)

    - `decimal`

        Will use the method ["\_set\_get\_number"](#_set_get_number)

    - `file`

        Will use the method ["\_set\_get\_file"](#_set_get_file)

    - `float`

        Will use the method ["\_set\_get\_number"](#_set_get_number)

    - `glob`

        Will use the method ["\_set\_get\_glob"](#_set_get_glob)

    - `hash`

        Will use the method ["\_set\_get\_hash"](#_set_get_hash)

    - `hash_as_object`

        Will use the method ["\_set\_get\_hash\_as\_mix\_object"](#_set_get_hash_as_mix_object)

    - `integer`

        Will use the method ["\_set\_get\_number"](#_set_get_number)

    - `ip`

        Will use the method ["\_set\_get\_ip"](#_set_get_ip)

    - `long`

        Will use the method ["\_set\_get\_number"](#_set_get_number)

    - `number`

        Will use the method ["\_set\_get\_number"](#_set_get_number)

    - `object`

        Will use the method ["\_set\_get\_object"](#_set_get_object)

        This means that if the method is chained, it will instantiate automatically a new object, if none is set yet. If you want to **not** automatically instantiate an object, use the type `object_no_init` instead.

        For this `type`, you will also need to provide 1 other property:

        - 1. `class` or `packages`

            A hash reference used for the definition of this dynamic class.

    - `object_array`

        Will use the method ["\_set\_get\_object\_array"](#_set_get_object_array)

        For this `type`, you will also need to provide 1 other property:

        - 1. `class` or `packages`

            A hash reference used for the definition of this dynamic class.

    - `object_array_object`

        Will use the method ["\_set\_get\_object\_array\_object"](#_set_get_object_array_object)

        For this `type`, you will also need to provide 1 other property:

        - 1. `class` or `packages`

            A hash reference used for the definition of this dynamic class.

    - `object_no_init`

        Will use the method ["\_set\_get\_object\_without\_init"](#_set_get_object_without_init)

        This means that if the method is chained, instead of instantiating automatically a new object, it will return instead [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull). If you want to automatically instantiate an object, use the type `object`

        For this `type`, you will also need to provide 1 other property:

        - 1. `class` or `packages`

            A hash reference used for the definition of this dynamic class.

    - `scalar`

        Will use the method ["\_set\_get\_scalar"](#_set_get_scalar)

    - `scalar_as_object`

        Will use the method ["\_set\_get\_scalar\_as\_object"](#_set_get_scalar_as_object)

    - `scalar_or_object`

        Will use the method ["\_set\_get\_scalar\_or\_object"](#_set_get_scalar_or_object)

        For this `type`, you will also need to provide 1 other property:

        - 1. `class` or `packages`

            A hash reference used for the definition of this dynamic class.

    - `uri`

        Will use the method ["\_set\_get\_uri"](#_set_get_uri)

    - `uuid`

        Will use the method ["\_set\_get\_uuid"](#_set_get_uuid)

    - `version`

        Will use the method ["\_set\_get\_version"](#_set_get_version)

        For this `type`, you will also need to provide 1 other property:

        - 1. `def` or `definition`

            A hash reference used for the definition of this dynamic class.

### Shortcut Usage

Instead of a full method definition, you may use a simple string:

    methods => 
    {
        name => 'scalar',
        age  => 'integer'
    }

This is equivalent to:

    methods => 
    {
        name => { type => 'scalar' },
        age  => { type => 'integer' }
    }

### Return Value

Upon success, it returns the fully qualified class name created, or the already-loaded class if it existed.

Upon error, it sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException), and returns an empty list in list context, or `undef` in scalar context, so you can do:

    create_class( My::Package, @sone_arguments ) || die( Module::Generic->error );

# THREAD & PROCESS SAFETY

This module is thread-safe. All shared internal variables are properly protected using [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal), which employs [threads::shared](https://metacpan.org/pod/threads%3A%3Ashared) and `lock` when Perl ithreads support is available, or [APR::ThreadRWLock](https://metacpan.org/pod/APR%3A%3AThreadRWLock) when running under mod\_perl with threaded MPMs (Worker or Event). In non-threaded environments, locking operations are skipped automatically.

Errors are stored using [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal), which provides thread/process-safe global storage with automatic locking and serialisation.

There are various scenarios under which we need to be careful about global variables and they are:

- 1. Perl is non-threaded

    This is safe. No global variables are shared

- 2. Perl is built as threaded

    If the code runs inside a thread, then we ensure thread-safety of global variables, otherwise they are safe. We check for this even during runtime using `HAS_THREADS` below.

- 3. Perl is running under Apache2/modperl with Prefork

    Apache/modperl creates separate instances of the global variables, and there is no risk of collision.

- 4. Perl is running under Apache/modperl with [Worker or Event MPM](https://httpd.apache.org/docs/2.4/en/mod/worker.html) (Multi-Processing Module)

    This setup requires that your version of Perl be compiled with `ithreads` (Interpreter Threads) enabled as [documented in the modperl documentation](https://perl.apache.org/docs/2.0/user/install/install.html#item_Threaded_MPMs)

    Since there is a risk of collision of global variables, [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal) detects it, and uses [threads::shared](https://metacpan.org/pod/threads%3A%3Ashared) or [APR::ThreadRWLock](https://metacpan.org/pod/APR%3A%3AThreadRWLock) as necessary.

## Thread Checking

This module provides subroutines to check thread support and usage, used internally for thread-safe error handling and other operations. These are imported from [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal) via `use Module::Generic::Global ':const'`.

- CAN\_THREADS

    A constant indicating whether Perl is compiled with thread support (`$Config{useithreads}`). Returns `1` if threads are supported, `0` otherwise.

        if( Module::Generic::CAN_THREADS )
        {
            print( "Perl supports threads\n" );
        }

- HAS\_THREADS

    A subroutine (not a constant) that returns `1` if Perl supports threads and the `threads` module is loaded (`$INC{'threads.pm'}`), `0` otherwise. Evaluated at runtime to detect dynamic loading of `threads`.

        if( Module::Generic::HAS_THREADS )
        {
            print( "Threads are in use\n" );
        }

    Note that some modules, such as [forks](https://metacpan.org/pod/forks), may manipulate `%INC` to emulate `threads`. In such cases, `HAS_THREADS` may return `1` even if `threads.pm` is not loaded. This is typically safe, as `forks` provides a compatible `tid` method, but in untrusted environments, consider additional checks (e.g., verifying `$INC{'threads.pm'}` points to the actual `threads.pm`).

- IN\_THREAD

    A subroutine (not a constant) that returns `1` if Perl supports threads, the `threads` module is loaded, and the current execution is in a child thread (`threads-`tid != 0>), `0` otherwise. Evaluated at runtime.

        if( Module::Generic::IN_THREAD() )
        {
            print( "Running in a child thread\n" );
        }

## Thread-Safety Considerations

The `HAS_THREADS` and `IN_THREAD` subroutines rely on `$INC{'threads.pm'}` to detect thread usage. While this is reliable for standard Perl modules like `threads`, some modules (e.g., [forks](https://metacpan.org/pod/forks)) may set `$INC{'threads.pm'}` to emulate thread behaviour. In such cases, `HAS_THREADS` and `IN_THREAD` may return `1` when [forks](https://metacpan.org/pod/forks) is loaded instead of [threads](https://metacpan.org/pod/threads). Since [forks](https://metacpan.org/pod/forks) provides a compatible `tid` method, this is generally safe.

Errors are stored in both instance-level (`$self->{error}`) and class-level (`Module::Generic::Global` repository under the `errors` namespace) storage to support patterns like `My::Module->new || die( My::Module->error )`. Each class-process-thread combination (keyed by `class;pid;tid` or `class;pid`) has at most one error in the repository, as subsequent errors overwrite the previous entry, preventing memory growth.

In mod\_perl environments with Prefork MPM, errors are per-process, behaving like a non-threaded environment, requiring no additional handling. In threaded MPMs (Worker or Event), threads within a process share the error repository, necessitating thread-safety. Since mod\_perl’s threaded MPMs require Perl to be compiled with thread support (`$Config{useithreads}` is true), the repository is made thread-safe using `threads::shared` and `CORE::lock`. If nevertheless, somehow [threads](https://metacpan.org/pod/threads) is not loaded, a warning is issued, indicating potential data corruption in concurrent access scenarios.

In untrusted or complex environments where `%INC` manipulation is a concern, you may wish to add custom checks (e.g., verifying `$INC{'threads.pm'}` points to `threads.pm` rather than `forks.pm`). For most applications, the default behaviour is sufficient, as [forks](https://metacpan.org/pod/forks) and similar modules are designed to be compatible with [threads](https://metacpan.org/pod/threads).

**Warning**: When using mod\_perl with threaded MPMs, certain Perl functions and operations may be unsafe or affect all threads in a process. Users should consult [perlthrtut](http://perldoc.perl.org/perlthrtut.html) and the [mod\_perl documentation](https://perl.apache.org/docs/2.0/user/coding/coding.html#Thread_environment_Issues) for details on thread-unsafe functions and thread-locality issues.

# SEE ALSO

[Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException), [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray), [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar), [Module::Generic::Boolean](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ABoolean), [Module::Generic::Number](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANumber), [Module::Generic::Null](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ANull), [Module::Generic::Dynamic](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ADynamic) and [Module::Generic::Tie](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ATie), [Module::Generic::File](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile), [Module::Generic::Finfo](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFinfo), [Module::Generic::SharedMem](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3ASharedMem), [Module::Generic::Scalar::IO](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar%3A%3AIO)

[Number::Format](https://metacpan.org/pod/Number%3A%3AFormat), [Class::Load](https://metacpan.org/pod/Class%3A%3ALoad), [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# COPYRIGHT & LICENSE

Copyright (c) 2000-2024 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
