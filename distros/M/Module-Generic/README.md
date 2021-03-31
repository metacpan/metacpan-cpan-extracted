SYNOPSIS
========

        package MyModule;
        BEGIN
        {
            use strict;
            use Module::Generic;
            our( @ISA ) = qw( Module::Generic );
        };

VERSION
=======

        v0.14.0

DESCRIPTION
===========

[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}
as its name says it all, is a generic module to inherit from. It is
designed to provide a useful framework and speed up coding and
debugging. It contains standard and support methods that may be
superseded by your the module using
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}.

As an added benefit, it also contains a powerfull AUTOLOAD transforming
any hash object key into dynamic methods and also recognize the dynamic
routine a la AutoLoader from which I have shamelessly copied in the
AUTOLOAD code. The reason is that while `AutoLoader` provides the user
with a convenient AUTOLOAD, I wanted a way to also keep the
functionnality of
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}
AUTOLOAD that were not included in `AutoLoader`. So the only solution
was a merger.

METHODS
=======

import
------

**import**() is used for the AutoLoader mechanism and hence is not a
public method. It is just mentionned here for info only.

new
---

**new** will create a new object for the package, pass any argument it
might receive to the special standard routine **init** that *must*
exist. Then it returns what returns [\"init\"](#init){.perl-module}.

To protect object inner content from sneaking by third party, you can
declare the package global variable *OBJECT\_PERMS* and give it a Unix
permission, but only 1 digit. It will then work just like Unix
permission. That is, if permission is 7, then only the module who
generated the object may read/write content of the object. However, if
you set 5, the, other may look into the content of the object, but may
not modify it. 7, as you would have guessed, allow other to modify the
content of an object. If *OBJECT\_PERMS* is not defined, permissions
system is not activated and hence anyone may access and possibly modify
the content of your object.

If the module runs under mod\_perl, it is recognised and a clean up
registered routine is declared to Apache to clean up the content of the
object.

as\_hash
--------

This will recursively transform the object into an hash suitable to be
encoded in json.

It does this by calling each method of the object and build an hash
reference with the method name as the key and the method returned value
as the value.

If the method returned value is an object, it will call its
[\"as\_hash\"](#as_hash){.perl-module} method if it supports it.

It returns the hash reference built

clear\_error
------------

Clear all error from the object and from the available global variable
`$ERROR`.

This is a handy method to use at the beginning of other methods of
calling package, so the end user may do a test such as:

        $obj->some_method( 'some arguments' );
        die( $obj->error() ) if( $obj->error() );

        ## some_method() would then contain something like:
        sub some_method
        {
            my $self = shift( @_ );
            ## Clear all previous error, so we may set our own later one eventually
            $self->clear_error();
            ## ...
        }

This way the end user may be sure that if `$obj-`error()\> returns true
something wrong has occured.

clone
-----

Clone the current object if it is of type hash or array reference. It
returns an error if the type is neither.

It returns the clone.

colour\_closest
---------------

Provided with a colour, this returns the closest standard one supported
by terminal.

A colour provided can be a colour name, or a 9 digits rgb value or an
hexadecimal value

colour\_format
--------------

Provided with a hash reference of parameters, this will return a string
properly formatted to display colours on the command line.

Parameters are:

*text* or *message*

:   This is the text to be formatted in colour.

*bgcolour* or *bgcolor* or *bg\_colour* or *bg\_color*

:   The value for the background colour.

*colour* or *color* or *fg\_colour* or *fg\_color* or *fgcolour* or *fgcolor*

:   The value for the foreground colour.

    Valid value can be a colour name, an rgb value like `255255255`, a
    rgb annotation like `rgb(255, 255, 255)` or a rgba annotation like
    `rgba(255,255,255,0.5)`

    A colour can be preceded by the words `light` or `bright` to provide
    slightly lighter colour where supported.

    Similarly, if an rgba value is provided, and the opacity is less
    than 1, this is equivalent to using the keyword `light`

    It returns the text properly formatted to be outputted in a
    terminal.

*style*

:   The possible values are: *bold*, *italic*, *underline*, *blink*,
    *reverse*, *conceal*, *strike*

colour\_parse
-------------

Provided with a string, this will parse the string for colour
formatting. Formatting can be encapsulated in another formatting, and
can be expressed in 2 different ways. For example:

        $self->colour_parse( "And {style => 'i|b', color => green}what about{/} {style => 'blink', color => yellow}me{/} ?" );

would result with the words `what about` in italic, bold and green
colour and the word `me` in yellow colour blinking (if supported).

Another way is:

        $self->colour_parse( "And {bold light red on white}what about{/} {underline yellow}me too{/} ?" );

would return a string with the words `what about` in light red bold text
on a white background, and the words `me too` in yellow with an
underline.

        $self->colour_parse( "Hello {bold red on white}everyone! This is {underline rgb(0,0,255)}embedded{/}{/} text..." );

would return a string with the words `everyone! This is` in bold red
characters on white background and the word `embedded` in underline blue
color

The idea for this syntax, not the code, is taken from
[Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor){.perl-module}

coloured
--------

Provided with a colouring preference expressed as the first argument as
string, and followed by 1 or more arguments that are concatenated to
form the text string to format. For example:

        print( $o->coloured( 'bold white on red', "Hello it's me!\n" ) );

A colour can be expressed as a rgb, such as :

        print( $o->coloured( 'underline rgb( 0, 0, 255 ) on white', "Hello everyone!" ), "\n" );

rgb can also be rgba with the last decimal, normally an opacity used
here to set light color if the value is less than 1. For example :

        print( $o->coloured( 'underline rgba(255, 0, 0, 0.5)', "Hello everyone!" ), "\n" );

debug
-----

Set or get the debug level. This takes and return an integer.

Based on the value, [\"message\"](#message){.perl-module} will or will
not print out messages. For example :

        $self->debug( 2 );
        $self->message( 2, "Debugging message here." );

Since `2` used in [\"message\"](#message){.perl-module} is equal to the
debug value, the debugging message is printed.

If the debug value is switched to 1, the message will be silenced.

dump
----

Provided with some data, this will return a string representation of the
data formatted by
[Data::Printer](https://metacpan.org/pod/Data::Printer){.perl-module}

dump\_print
-----------

Provided with a file to write to and some data, this will format the
string representation of the data using
[Data::Printer](https://metacpan.org/pod/Data::Printer){.perl-module}
and save it to the given file.

dumper
------

Provided with some data, and optionally an hash reference of parameters
as last argument, this will create a string representation of the data
using
[Data::Dumper](https://metacpan.org/pod/Data::Dumper){.perl-module} and
return it.

This sets
[Data::Dumper](https://metacpan.org/pod/Data::Dumper){.perl-module} to
be terse, to indent, to use `qq` and optionally to not exceed a maximum
*depth* if it is provided in the argument hash reference.

printer
-------

Same as [\"dumper\"](#dumper){.perl-module}, but using
[Data::Printer](https://metacpan.org/pod/Data::Printer){.perl-module} to
format the data.

dumpto\_printer
---------------

Same as [\"dump\_print\"](#dump_print){.perl-module} above that is an
alias of this method.

dumpto\_dumper
--------------

Same as [\"dumpto\_printer\"](#dumpto_printer){.perl-module} above, but
using
[Data::Dumper](https://metacpan.org/pod/Data::Dumper){.perl-module}

error
-----

Set the current error issuing a
[Module::Generic::Exception](https://metacpan.org/pod/Module::Generic::Exception){.perl-module}
object, call [\"warn\" in
perlfunc](https://metacpan.org/pod/perlfunc#warn){.perl-module}, or
`$r-`warn\> under Apache2 modperl, and returns undef() or an empty list
in list context:

        if( $some_condition )
        {
            return( $self->error( "Some error." ) );
        }

Note that you do not have to worry about a trailing line feed sequence.
**error**() takes care of it.

The script calling your module could write calls to your module methods
like this:

        my $cust_name = $object->customer->name ||
            die( "Got an error in file ", $object->error->file, " at line ", $object->error->line, ": ", $object->error->trace, "\n" );
        # or simply:
        my $cust_name = $object->customer->name ||
            die( "Got an error: ", $object->error, "\n" );

Note also that by calling **error**() it will not clear the current
error. For that you have to call **clear\_error**() explicitly.

Also, when an error is set, the global variable *ERROR* is set
accordingly. This is especially usefull, when your initiating an object
and that an error occured. At that time, since the object could not be
initiated, the end user can not use the object to get the error message,
and then can get it using the global module variable *ERROR*, for
example:

        my $obj = Some::Package->new ||
        die( $Some::Package::ERROR, "\n" );

If the caller has disabled warnings using the pragma `no warnings`,
[\"error\"](#error){.perl-module} will respect it and not call **warn**.
Calling **warn** can also be silenced if the object has a property
*quiet* set to true.

The error message can be split in multiple argument.
[\"error\"](#error){.perl-module} will concatenate each argument to form
a complete string. An argument can even be a reference to a sub routine
and will get called to get the resulting string, unless the object
property *\_msg\_no\_exec\_sub* is set to false. This can switched off
with the method [\"noexec\"](#noexec){.perl-module}

If perl runs under Apache2 modperl, and an error handler is set with
[\"error\_handler\"](#error_handler){.perl-module}, this will call the
error handler with the error string.

If an Apache2 modperl log handler has been set, this will also be called
to log the error.

If the object property *fatal* is set to true, this will call die
instead of [\"warn\" in
perlfunc](https://metacpan.org/pod/perlfunc#warn){.perl-module}.

Last, but not least since [\"error\"](#error){.perl-module} returns
undef in scalar context or an empty list in list context, if the method
that triggered the error is chained, it would normally generate a perl
error that the following method cannot be called on an undefined value.
To solve this, when an object is expected,
[\"error\"](#error){.perl-module} returns a special object from module
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}
that will enable all the chained methods to be performed and return the
error when requested to. For example :

        my $o = My::Package->new;
        my $total $o->get_customer(10)->products->total || die( $o->error, "\n" );

Assuming this method here `get_customer` returns an error, the chaining
will continue, but produce nothing and ultimately returns undef.

errors
------

Used by **error**() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and
the last error in scalar context.

errstr
------

Set/get the error string, period. It does not produce any warning like
**error** would do.

get
---

Uset to get an object data key value:

        $obj->set( 'verbose' => 1, 'debug' => 0 );
        ## ...
        my $verbose = $obj->get( 'verbose' );
        my @vals = $obj->get( qw( verbose debug ) );
        print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the
AUTOLOAD generic routine with which you may say:

        $obj->verbose( 1 );
        $obj->debug( 0 );
        ## ...
        my $verbose = $obj->verbose();

Much better, no?

init
----

This is the [\"new\"](#new){.perl-module} package object initializer. It
is called by [\"new\"](#new){.perl-module} and is used to set up any
parameter provided in a hash like fashion:

        my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed [\"init\"](#init){.perl-module} to have suit
your needs.

[\"init\"](#init){.perl-module} needs to returns the object it received
in the first place or an error if something went wrong, such as:

        sub init
        {
            my $self = shift( @_ );
            my $dbh  = DB::Object->connect() ||
            return( $self->error( "Unable to connect to database server." ) );
            $self->{ 'dbh' } = $dbh;
            return( $self );
        }

In this example, using [\"error\"](#error){.perl-module} will set the
global variable `$ERROR` that will contain the error, so user can say:

        my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable *VERBOSE*, *DEBUG*, *VERSION* are defined in the
module, and that they do not exist as an object key, they will be set
automatically and accordingly to those global variable.

The supported data type of the object generated by the
[\"new\"](#new){.perl-module} method may either be a hash reference or a
glob reference. Those supported data types may very well be extended to
an array reference in a near future.

When provided with an hash reference, and when object property
*\_init\_strict\_use\_sub* is set to true,
[\"init\"](#init){.perl-module} will call each method corresponding to
the key name and pass it the key value and it will set an error and skip
it if the corresponding method does not exist. Otherwise if the object
property *\_init\_strict* is set to true, it will check the object
property matching the hash key for the default value type and set an
error and return undef if it does not match. Foe example,
[\"init\"](#init){.perl-module} in your module could be like this:

        sub init
        {
            my $self = shift( @_ );
            $self->{_init_strict} = 1;
            $self->{products} = [];
            return( $self->SUPER::init( @_ ) );
        }

Then, if init is called like this:

        $object->init({ products => $some_string_but_not_array }) || die( $object->error, "\n" );

This would cause your script to die, because `products` value is a
string and not an array reference.

Otherwise, if none of those special object properties are set, the init
will create an object property matching the key of the hash and set its
value accordingly. For example :

        sub init
        {
            my $self = shift( @_ );
            return( $self->SUPER::init( @_ ) );
        }

Then, if init is called like this:

        $object->init( products => $array_ref, first_name => 'John', last_name => 'Doe' });

The object would then contain the properties *products*, *first\_name*
and *last\_name* and can be accessed as methods, such as :

        my $fname = $object->first_name;

log\_handler
------------

Provided a reference to a sub routine or an anonymous sub routine, this
will set the handler that is called by
[\"message\"](#message){.perl-module}

It returns the current value set.

message
-------

**message**() is used to display verbose/debug output. It will display
something to the extend that either *verbose* or *debug* are toggled on.

If so, all debugging message will be prepended by `## ` by default or
the prefix string specified with the *prefix* option, to highlight the
fact that this is a debugging message.

Addionally, if a number is provided as first argument to **message**(),
it will be treated as the minimum required level of debugness. So, if
the current debug state level is not equal or superior to the one
provided as first argument, the message will not be displayed.

For example:

        ## Set debugness to 3
        $obj->debug( 3 );
        ## This message will not be printed
        $obj->message( 4, "Some detailed debugging stuff that we might not want." );
        ## This will be displayed
        $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the
verbose level needs only to be true, that is equal to 1 to be efficient.
You do not really need to have a verbose level greater than 1. However,
the debug level usually may have various level.

Also, the text provided can be separated by comma, and even be a code
reference, such as:

        $self->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

If the object has a property *\_msg\_no\_exec\_sub* set to true, then a
code reference will not be called and instead be added to the string as
is. This can be done simply like this:

        $self->noexec->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

[\"message\"](#message){.perl-module} also takes an optional hash
reference as the last parameter with the following recognised options:

*caller\_info*

:   This is a boolean value, which is true by default.

    When true, this will prepend the debug message with information
    about the caller of [\"message\"](#message){.perl-module}

*level*

:   An integer. Debugging level.

*message*

:   The text of the debugging message. This is optional since this can
    be provided as first or consecutive arguments like in a list as
    demonstrated in the example above. This allows you to do something
    like this:

            $self->message( 2, { message => "Some debug message here", prefix => ">>" });

    or

            $self->message( { message => "Some debug message here", prefix => ">>", level => 2 });

*no\_encoding*

:   Boolean value. If true and when the debugging is set to be printed
    to a file, this will not set the binmode to `utf-8`

*prefix*

:   By default this is set to `##`. This value is used as the prefix
    used in debugging output.

*type*

:   Type of debugging

message\_check
--------------

This is called by [\"message\"](#message){.perl-module}

Provided with a list of arguments, this method will check if the first
argument is an integer and find out if a debug message should be printed
out or not. It returns the list of arguments as an array reference.

message\_colour
---------------

This is the same as [\"message\"](#message){.perl-module}, except this
will check for colour formatting, which
[\"message\"](#message){.perl-module} does not do. For example:

        $self->message_colour( 3, "And {bold light white on red}what about{/} {underline green}me again{/} ?" );

[\"message\_colour\"](#message_colour){.perl-module} can also be called
as **message\_color**

See also [\"colour\_format\"](#colour_format){.perl-module} and
[\"colour\_parse\"](#colour_parse){.perl-module}

messagef
--------

This works like [\"sprintf\" in
perlfunc](https://metacpan.org/pod/perlfunc#sprintf){.perl-module}, so
provided with a format and a list of arguments, this print out the
message. For example :

        $self->messagef( 1, "Customer name is %s", $cust->name );

Where 1 is the debug level set with [\"debug\"](#debug){.perl-module}

messagef\_colour
----------------

This method is same as
[\"message\_colour\"](#message_colour){.perl-module} and
[messagef](https://metacpan.org/pod/messagef){.perl-module} combined.

It enables to pass sprintf-like parameters while enabling colours.

message\_log
------------

This is called from [\"message\"](#message){.perl-module}.

Provided with a message to log, this will check if
[\"message\_log\_io\"](#message_log_io){.perl-module} returns a valid
file handler, presumably to log file, and if so print the message to it.

If no file handle is set, this returns undef, other it returns the value
from `$io-`print\>

message\_log\_io
----------------

Set or get the message log file handle. If set,
[\"message\_log\"](#message_log){.perl-module} will use it to print
messages received from [\"message\"](#message){.perl-module}

If no argument is provided bu your module has a global variable
`LOG_DEBUG` set to true and global variable `DEB_LOG` set presumably to
the file path of a log file, then this attempts to open in write mode
the log file.

It returns the current log file handle, if any.

new\_array
----------

Instantiate a new
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
object. If any arguments are provided, it will pass it to [\"new\" in
Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array#new){.perl-module}
and return the object.

new\_hash
---------

Instantiate a new
[Module::Generic::Hash](https://metacpan.org/pod/Module::Generic::Hash){.perl-module}
object. If any arguments are provided, it will pass it to [\"new\" in
Module::Generic::Hash](https://metacpan.org/pod/Module::Generic::Hash#new){.perl-module}
and return the object.

new\_number
-----------

Instantiate a new
[Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number){.perl-module}
object. If any arguments are provided, it will pass it to [\"new\" in
Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number#new){.perl-module}
and return the object.

new\_scalar
-----------

Instantiate a new
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}
object. If any arguments are provided, it will pass it to [\"new\" in
Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar#new){.perl-module}
and return the object.

noexec
------

Sets the module property *\_msg\_no\_exec\_sub* to true, so that any
call to [\"message\"](#message){.perl-module} whose arguments include a
reference to a sub routine, will not try to execute the code. For
example, imagine you have a sub routine such as:

        sub hello
        {
            return( "Hello !" );
        }

And in your code, you write:

        $self->message( 2, "Someone said: ", \&hello );

If *\_msg\_no\_exec\_sub* is set to false (by default), then the above
would print out the following message:

        Someone said Hello !

But if *\_msg\_no\_exec\_sub* is set to true, then the same would rather
produce the following :

        Someone said CODE(0x7f9103801700)

pass\_error
-----------

Provided with an error, typically a
[Module::Generic::Exception](https://metacpan.org/pod/Module::Generic::Exception){.perl-module}
object, but it could be anything as long as it is an object, hopefully
an exception object, this will set the error value to the error
provided, and without issuing any new warning nor creating a new
[Module::Generic::Exception](https://metacpan.org/pod/Module::Generic::Exception){.perl-module}
object.

It makes it possible to pass the error along so the caller can retrieve
it later. This is typically used by a method calling another one in
another module that produced an error. For example :

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

quiet
-----

Set or get the object property *quiet* to true or false. If this is
true, no warning will be issued when [\"error\"](#error){.perl-module}
is called.

save
----

Provided with some data and a file path, or alternatively an hash
reference of options with the properties *data*, *encoding* and *file*,
this will write to the given file the provided *data* using the encoding
*encoding*.

This is designed to simplify the tedious task of write to files.

If it cannot open the file in write mode, or cannot print to it, this
will set an error and return undef. Otherwise this returns the size of
the file in bytes.

set
---

**set**() sets object inner data type and takes arguments in a hash like
fashion:

        $obj->set( 'verbose' => 1, 'debug' => 0 );

subclasses
----------

Provided with a *CLASS* value, this method try to guess all the existing
sub classes of the provided *CLASS*.

If *CLASS* is not provided, the class into which was blessed the calling
object will be used instead.

It returns an array of subclasses in list context and a reference to an
array of those subclasses in scalar context.

If an error occured, undef is returned and an error is set accordingly.
The latter can be retrieved using the **error** method.

true
----

Returns a `true` variable from
[Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean){.perl-module}

false
-----

Returns a `false` variable from
[Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean){.perl-module}

verbose
-------

Set or get the verbosity level with an integer.

will
----

This will try to find out if an object supports a given method call and
returns the code reference to it or undef if none is found.

AUTOLOAD
--------

The special **AUTOLOAD**() routine is called by perl when no matching
routine was found in the module.

**AUTOLOAD**() will then try hard to process the request. For example,
let\'s assue we have a routine **foo**.

It will first, check if an equivalent entry of the routine name that was
called exist in the hash reference of the object. If there is and that
more than one argument were passed to this non existing routine, those
arguments will be stored as a reference to an array as a value of the
key in the object. Otherwise the single argument will simply be stored
as the value of the key of the object.

Then, if called in list context, it will return a array if the value of
the key entry was an array reference, or a hash list if the value of the
key entry was a hash reference, or finally the value of the key entry.

If this non existing routine that was called is actually defined, the
routine will be redeclared and the arguments passed to it.

If this fails too, it will try to check for an AutoLoadable file in
`auto/PackageName/routine_name.al`

If the filed exists, it will be required, the routine name linked into
the package name space and finally called with the arguments.

If the require process failed or if the AutoLoadable routine file did
not exist, **AUTOLOAD**() will check if the special routine
**EXTRA\_AUTOLOAD**() exists in the module. If it does, it will call it
and pass it the arguments. Otherwise, **AUTOLOAD** will die with a
message explaining that the called routine did not exist and could not
be found in the current class.

SPECIAL METHODS
===============

\_\_instantiate\_object
-----------------------

Provided with an object property name, and a class/package name, this
will attempt to load the module if it is not already loaded. It does so
using [\"load\_class\" in
Class::Load](https://metacpan.org/pod/Class::Load#load_class){.perl-module}.
Once loaded, it will init an object passing it the other arguments
received. It returns the object instantiated upon success or undef and
sets an [\"error\"](#error){.perl-module}

This is a support method used by
[\"\_instantiate\_object\"](#instantiate_object){.perl-module}

\_instantiate\_object
---------------------

This does the same thing as
[\"\_\_instantiate\_object\"](#instantiate_object){.perl-module} and the
purpose is for this method to be potentially superseded in your own
module. In your own module, you would call
[\"\_\_instantiate\_object\"](#instantiate_object){.perl-module}

\_get\_args\_as\_hash
---------------------

Provided with arguments and this support method will return the
arguments provided as hash reference irrespective of whether they were
initially provided as hash reference or a simple hash.

For example:

        my $ref = $self->_get_args_as_hash( first => 'John', last => 'Doe' );
        # returns hash reference { first => 'John', last => 'Doe' }
        my $ref = $self->_get_args_as_hash({ first => 'John', last => 'Doe' });
        # same as above
        my $res = $self->_get_args_as_hash(); # no args provided
        # returns an empty hash reference

However, this will return empty:

        my $ref = $self->_get_args_as_hash( { age => 42, city => 'Tokyo' }, some_other => 'parameter' );

This returns an empty hash reference, because although the first
parameter is an hash reference, there is more than on parameter.

\_is\_a
-------

Provided with an object and a package name and this will return true if
the object is a blessed object from this package name (or a sub package
of it), or false if not.

The value of this is to reduce the burden of having to check whether the
object actually exists, i.e. is not null or undef, if it is an object
and if it is from that class. This allows to do it in just one method
call like this:

        if( $self->_is_a( $obj, 'My::Package' ) )
        {
            # Do something
        }

Of course, if you are sure the object is actually an object, then you
can directly do:

        if( $obj->isa( 'My::Package' ) )
        {
            # Do something
        }

\_is\_class\_loaded
-------------------

Provided with a class/package name, this returns true if the module is
already loaded or false otherwise.

\_is\_array
-----------

Provided with some data, this checks if the data is of type array, even
if it is an object.

This uses [\"reftype\" in
Scalar::Util](https://metacpan.org/pod/Scalar::Util#reftype){.perl-module}
to achieve that purpose. So for example, an object such as :

        package My::Module;

        sub new
        {
            return( bless( [] => ( ref( $_[0] ) || $_[0] ) ) );
        }

This would produce an object like :

        My::Module=ARRAY(0x7f8f3b035c20)

When checked with [\"\_is\_array\"](#is_array){.perl-module} this, would
return true just like an ordinary array.

If you would use :

        ref( $object );

It would rather return the module package name: `My::Module`

\_is\_hash
----------

Same as [\"\_is\_array\"](#is_array){.perl-module}, but for hash
reference.

\_is\_object
------------

Provided with some data, this checks if the data is an object. It uses
[\"blessed\" in
Scalar::Util](https://metacpan.org/pod/Scalar::Util#blessed){.perl-module}
to achieve that purpose.

\_is\_scalar
------------

Provided with some data, this checks if the data is of type scalar
reference, e.g. `SCALAR(0x7fc0d3b7cea0)`, even if it is an object.

\_load\_class
-------------

Provided with a class/package name and this will attempt to load the
module. This uses [\"load\_class\" in
Class::Load](https://metacpan.org/pod/Class::Load#load_class){.perl-module}
to achieve that purpose and return whatever value [\"load\_class\" in
Class::Load](https://metacpan.org/pod/Class::Load#load_class){.perl-module}
returns.

\_obj2h
-------

This ensures the module object is an hash reference, such as when the
module object is based on a file handle for example. This permits
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}
to work no matter what is the underlying data type blessed into an
object.

\_parse\_timestamp
------------------

Provided with a string representing a date or datetime, and this will
try to parse it and return a
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object. It
will also create a
[DateTime::Format::Strptime](https://metacpan.org/pod/DateTime::Format::Strptime){.perl-module}
to preserve the original date/datetime string representation and assign
it to the [DateTime](https://metacpan.org/pod/DateTime){.perl-module}
object. So when the
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object is
stringified, it displays the same string that was originally parsed.

\_set\_get
----------

Provided with an object property name and some value and this will set
or get that value for that property.

However, if the value stored is an array and is called in list context,
it will return the array as a list and not the array reference. Same
thing for an hash reference. It will return an hash in list context. In
scalar context, it returns whatever the value is, such as array
reference, hash reference or string, etc.

\_set\_get\_array
-----------------

Provided with an object property name and some data and this will store
the data as an array reference.

It returns the current value stored, such as an array reference
notwithstanding it is called in list or scalar context.

Example :

        sub products { return( shift->_set_get_array( 'products', @_ ) ); }

\_set\_get\_array\_as\_object
-----------------------------

Provided with an object property name and some data and this will store
the data as an object of
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}

If this is called with no data set, an object is created with no data
inside and returned

Example :

        # In your module
        sub products { return( shift->_set_get_array_as_object( 'products', @_ ) ); }

And using your method:

        printf( "There are %d products\n", $object->products->length );
        $object->products->push( $new_product );

\_set\_get\_boolean
-------------------

Provided with an object property name and some data and this will store
the data as a boolean value.

If the data provided is a
[JSON::PP::Boolean](https://metacpan.org/pod/JSON::PP::Boolean){.perl-module}
or
[Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean){.perl-module}
object, the data is stored as is.

If the data is a scalar reference, its referenced value is check and
[\"true\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#true){.perl-module}
or [\"false\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#false){.perl-module}
is set accordingly.

If the data is a string with value of `true` or `val` [\"true\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#true){.perl-module}
or [\"false\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#false){.perl-module}
is set accordingly.

Otherwise the data provided is checked if it is a true value or not and
[\"true\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#true){.perl-module}
or [\"false\" in
Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean#false){.perl-module}
is set accordingly.

If no value is provided, and the object property has already been set,
this performs the same checks as above and returns either a
[JSON::PP::Boolean](https://metacpan.org/pod/JSON::PP::Boolean){.perl-module}
or a
[Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean){.perl-module}
object.

\_\_create\_class
-----------------

Provided with an object property name and an hash reference representing
a dictionary and this will produce a dynamically created class/module.

If a property *\_class* exists in the dictionary, it will be used as the
class/package name, otherwise a name will be derived from the calling
object class and the object property name. For example, in your module :

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

Using the resulting object `$prod`, we can access this dynamically
created class/module such as :

        printf( <<EOT, $prod->name, $prod->orders->length, $prod->customer->last_name,, $prod->url->path )
        Product name: %s
        No of orders: %d
        Customer name: %s
        Product page path: %s
        EOT

\_set\_get\_class
-----------------

Given an object property name, a dynamic class fiels definition hash
(dictionary), and optional arguments, this special method will create
perl packages on the fly by calling the support method
[\"\_\_create\_class\"](#create_class){.perl-module}

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

The advantage of this over **\_set\_get\_hash\_as\_object** is that here
one controls what fields / method are supported and with which data
type.

\_set\_get\_class\_array
------------------------

Provided with an object property name, a dictionary to create a dynamic
class with [\"\_\_create\_class\"](#create_class){.perl-module} and an
array reference of hash references and this will create an array of
object, each one matching a set of data provided in the array reference.
So for example, imagine you had a method such as below in your module :

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

And this would store an array reference containing 2 objects with the
above data.

\_set\_get\_code
----------------

Provided with an object property name and some code reference and this
stores and retrieve the current value.

It returns under and set an error if the provided value is not a code
reference.

\_set\_get\_datetime
--------------------

Provided with an object property name and asome date or datetime string
and this will attempt to parse it and save it as a
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object.

If the data is a 10 digits integer, this will treat it as a unix
timestamp.

Parsing also recognise special word such as `now`

The created [DateTime](https://metacpan.org/pod/DateTime){.perl-module}
object is associated a
[DateTime::Format::Strptime](https://metacpan.org/pod/DateTime::Format::Strptime){.perl-module}
object which enables the
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object to be
stringified as a unix timestamp using local time stamp, whatever it is.

Even if there is no value set, and this method is called in chain, it
returns a
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}
whose purpose is to enable chaining without doing anything meaningful.
For example, assuming the property *created* of your object is not set
yet, but in your script you call it like this:

        $object->created->iso8601

Of course, the value of `iso8601` will be empty since this is a fake
method produced by
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}.
The return value of a method should always be checked.

\_set\_get\_hash
----------------

Provided with an object property name and an hash reference and this set
the property name with this hash reference.

You can even pass it an associative array, and it will be saved as a
hash reference, such as :

        $object->metadata(
            transaction_id => 123,
            customer_id => 456
        );

        my $hash = $object->metadata;

\_set\_get\_hash\_as\_mix\_object
---------------------------------

Provided with an object property name, and an optional hash reference
and this returns a
[Module::Generic::Hash](https://metacpan.org/pod/Module::Generic::Hash){.perl-module}
object, which allows to manipulate the hash just like any regular hash,
but it provides on top object oriented method described in details in
[Module::Generic::Hash](https://metacpan.org/pod/Module::Generic::Hash){.perl-module}.

This is different from
[\"\_set\_get\_hash\_as\_object\"](#set_get_hash_as_object){.perl-module}
below whose keys and values are accessed as dynamic methods and method
arguments.

\_set\_get\_hash\_as\_object
----------------------------

Provided with an object property name, an optional class name and an
hash reference and this does the same as in
[\"\_set\_get\_hash\"](#set_get_hash){.perl-module}, except it will
create a class/package dynamically with a method for each of the hash
keys, so that you can call the hash keys as method.

Also it does this recursively while handling looping, in which case, it
will reuse the object previously created, and also it takes care of
adapting the hash key to a proper field name, so something like
`99more-options` would become `more_options`. If the value itself is a
hash, it processes it recursively transforming `99more-options` to a
proper package name `MoreOptions` prepended by `$class_name` provided as
argument or whatever upper package was used in recursion processing.

For example in your module :

        sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

Then populating the data :

        $object->metadata({
            first_name => 'John',
            last_name => 'Doe',
            email => 'john.doe@example.com',
        });

        printf( "Customer name is %s\n", $object->metadata->last_name );

\_set\_get\_lvalue
------------------

This helper method makes it very easy to implement a [\"Lvalue
subroutines\" in
perlsub](https://metacpan.org/pod/perlsub#Lvalue subroutines){.perl-module}
method.

        package MyObject;
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        
        sub debug : lvalue { return( shift->_set_get_lvalue( 'debug', @_ ) ); }

And then, this method can be called either as a lvalue method:

        my $obj = MyObject->new;
        $obj->debug = 3;

But also as a regular method:

        $obj->debug( 1 );
        printf( "Debug value is %d\n", $obj->debug );

It uses [Want](https://metacpan.org/pod/Want){.perl-module} to achieve
this. See also
[Sentinel](https://metacpan.org/pod/Sentinel){.perl-module}

\_set\_get\_number
------------------

Provided with an object property name and a number, and this will create
a
[Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number){.perl-module}
object and return it.

As of version v0.13.0 it also works as a lvalue method. See
[perlsub](https://metacpan.org/pod/perlsub){.perl-module}

In your module:

        package MyObject;
        use parent qw( Module::Generic );
        
        sub level : lvalue { return( shift->_set_get_number( 'level', @_ ) ); }

In the script using module `MyObject`:

        my $obj = MyObject->new;
        $obj->level = 3; # level is now 3
        # or
        $obj->level( 4 ) # level is now 4
        print( "Level is: ", $obj->level, "\n" ); # Level is 4
        print( "Is it an odd number: ", $obj->level->is_odd ? 'yes' : 'no', "\n" );
        # Is it an od number: no
        $obj->level++; # level is now 5

\_set\_get\_number\_or\_object
------------------------------

Provided with an object property name and a number or an object and this
call the value using
[\"\_set\_get\_number\"](#set_get_number){.perl-module} or
[\"\_set\_get\_object\"](#set_get_object){.perl-module} respectively

\_set\_get\_object
------------------

Provided with an object property name, a class/package name and some
data and this will initiate a new object of the given class passing it
the data.

If you pass an undefined value, it will set the property as undefined,
removing whatever was set before.

You can also provide an existing object of the given class.
[\"\_set\_get\_object\"](#set_get_object){.perl-module} will check the
object provided does belong to the specified class or it will set an
error and return undef.

It returns the object currently set, if any.

\_set\_get\_object\_array2
--------------------------

Provided with an object property name, a class/package name and some
array reference itself containing array references each containing hash
references or objects, and this will create an array of array of
objects.

\_set\_get\_object\_array
-------------------------

Provided with an object property name and a class/package name and
similar to
[\"\_set\_get\_object\_array2\"](#set_get_object_array2){.perl-module}
this will create an array reference of objects.

\_set\_get\_object\_array\_object
---------------------------------

Provided with an object property name, a class/package name and some
data and this will create an array of object similar to
[\"\_set\_get\_object\_array\"](#set_get_object_array){.perl-module},
except the array produced is a
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}

\_set\_get\_object\_variant
---------------------------

Provided with an object property name, a class/package name and some
data, and depending whether the data provided is an hash reference or an
array reference, this will either instantiate an object for the given
hash reference or an array of objects with the hash references in the
given array.

This means the value stored for the object property will vary between an
hash or array reference.

\_set\_get\_scalar
------------------

Provided with an object property name, and a string, possibly a number
or anything really and this will set the property value accordingly.
Very straightforward.

It returns the currently value stored.

\_set\_get\_scalar\_as\_object
------------------------------

Provided with an object property name, and a string or a scalar
reference and this stores it as an object of
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}

If there is already an object set for this property, the value provided
will be assigned to it using [\"set\" in
Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar#set){.perl-module}

If it is called and not value is set yet, this will instantiate a
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}
object with no value.

So a call to this method can safely be chained to access the
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}
methods. For example :

        sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

Then, calling it :

        $object->name( 'John Doe' );

Getting the value :

        my $cust_name = $object->name;
        print( "Nothing set yet.\n" ) if( !$cust_name->length );

\_set\_get\_scalar\_or\_object
------------------------------

Provided with an object property name, and a class/package name and this
stores the value as an object calling
[\"\_set\_get\_object\"](#set_get_object){.perl-module} if the value is
an object of class *class* or as a string calling
[\"\_set\_get\_scalar\"](#set_get_scalar){.perl-module}

If no value has been set yet, this returns a
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}
object to enable chaining.

\_set\_get\_uri
---------------

Provided with an object property name, and an uri and this creates a
[URI](https://metacpan.org/pod/URI){.perl-module} object and sets the
property value accordingly.

It accepts an [URI](https://metacpan.org/pod/URI){.perl-module} object,
an uri or urn string, or an absolute path, i.e. a string starting with
`/`.

It returns the current value, if any, so the return value could be
undef, thus it cannot be chained. Maybe it should return a
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}
object ?

\_to\_array\_object
-------------------

Provided with arguments or not, and this will return a
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
object of those data.

        my $array = $self->_to_array_object( qw( Hello world ) ); # Becomes an array object of 'Hello' and 'world'
        my $array = $self->_to_array_object( [qw( Hello world )] ); # Becomes an array object of 'Hello' and 'world'

\_\_dbh
-------

if your module has the global variables `DB_DSN`, this will create a
database handler using [DBI](https://metacpan.org/pod/DBI){.perl-module}

It will also use the following global variables in your module to set
the database object: `DB_RAISE_ERROR`, `DB_AUTO_COMMIT`,
`DB_PRINT_ERROR`, `DB_SHOW_ERROR_STATEMENT`, `DB_CLIENT_ENCODING`,
`DB_SERVER_PREPARE`

If `DB_SERVER_PREPARE` is provided and true, `pg_server_prepare` will be
set to true in the database handler.

It returns the database handler object.

DEBUG
-----

Return the value of your global variable *DEBUG*, if any.

VERBOSE
-------

Return the value of your global variable *VERBOSE*, if any.

SEE ALSO
========

[Module::Generic::Exception](https://metacpan.org/pod/Module::Generic::Exception){.perl-module},
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module},
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module},
[Module::Generic::Boolean](https://metacpan.org/pod/Module::Generic::Boolean){.perl-module},
[Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number){.perl-module},
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module},
[Module::Generic::Dynamic](https://metacpan.org/pod/Module::Generic::Dynamic){.perl-module}
and
[Module::Generic::Tie](https://metacpan.org/pod/Module::Generic::Tie){.perl-module}

[Number::Format](https://metacpan.org/pod/Number::Format){.perl-module},
[Class::Load](https://metacpan.org/pod/Class::Load){.perl-module},
[Scalar::Util](https://metacpan.org/pod/Scalar::Util){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55c78dec53f8)"}\>

COPYRIGHT & LICENSE
===================

Copyright (c) 2000-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
