SYNOPSIS
========

        use Promise::Me; # exports async, await and share
        my $p = Promise::Me->new(sub
        {
            # Some regular code here
        })->then(sub
        {
            my $res = shift( @_ ); # return value from the code executed above
            # more processing...
        })->then(sub
        {
            my $more = shift( @_ ); # return value from the previous then
            # more processing...
        })->catch(sub
        {
            my $exception = shift( @_ ); # error that occured is caught here
        })->finally(sub
        {
            # final processing
        })->then(sub
        {
            # A last then may be added after finally
        };

        # You can share data among processes for all systems, including Windows
        my $data : shared = {};
        my( $name, %attributes, @options );
        share( $name, %attributes, @options );

        my $p1 = Promise::Me->new( $code_ref )->then(sub
        {
            my $res = shift( @_ );
            # more processing...
        })->catch(sub
        {
            my $err = shift( @_ );
            # Do something with the exception
        });

        my $p2 = Promise::Me->new( $code_ref )->then(sub
        {
            my $res = shift( @_ );
            # more processing...
        })->catch(sub
        {
            my $err = shift( @_ );
            # Do something with the exception
        });

        my @results = await( $p1, $p2 );

        # Wait for all promise to resolve. If one is rejected, this super promise is rejected
        my @results = Promise::Me->all( $p1, $p2 );

        # First promise that is resolved or rejected makes this super promise resolved and 
        # return the result
        my @results = Promise::Me->race( $p1, $p2 );

        # Automatically turns this subroutine into one that runs asynchronously and returns 
        # a promise
        async sub fetch_remote
        {
            # Do some http request that will run asynchronously thanks to 'async'
        }

        sub do_something
        {
            # some code here
            my $p = Promise::Me->new(sub
            {
                # some work that needs to run asynchronously
            })->then(sub
            {
                # More processing here
            })->catch(sub
            {
                # Oops something went wrong
                my $exception = shift( @_ );
            });
            # No need for this subroutine 'do_something' to be prefixed with 'async'.
            # This is not JavaScript you know
            await $p;
        }

        sub do_something
        {
            # some code here
            my $p = Promise::Me->new(sub
            {
                # some work that needs to run asynchronously
            })->then(sub
            {
                # More processing here
            })->catch(sub
            {
                # Oops something went wrong
                my $exception = shift( @_ );
            })->wait;
            # Always returns a reference
            my $result = $p->result;
        }

VERSION
=======

        v0.2.0

DESCRIPTION
===========

[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module} is an
implementation of the JavaScript promise using fork for asynchronous
tasks. Fork is great, because it is well supported by all operating
systems ([except AmigaOS, RISC OS and
VMS](https://metacpan.org/pod/perlport){.perl-module}) and effectively
allows for asynchronous execution.

While JavaScript has asynchronous execution at its core, which means
that two consecutive lines of code will execute simultaneously, under
perl, those two lines would be executed one after the other. For
example:

        # Assuming the function getRemote makes an http query of a remote resource that takes time
        let response = getRemote('https://example.com/api');
        console.log(response);

Under JavaScript, this would yield: `undefined`, but in perl

        my $resp = $ua->get('https://example.com/api');
        say( $resp );

Would correctly return the response object, but it will hang until it
gets the returned object whereas in JavaScript, it would not wait.

In JavaScript, because of this asynchronous execution, before people
were using callback hooks, which resulted in \"callback from hell\",
i.e. something like this\[1\]:

        getData(function(x){
            getMoreData(x, function(y){
                getMoreData(y, function(z){ 
                    ...
                });
            });
        });

\[1\] Taken from this [StackOverflow
discussion](https://stackoverflow.com/questions/25098066/what-is-callback-hell-and-how-and-why-does-rx-solve-it){.perl-module}

And then, they came up with
[Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise){.perl-module},
so that instead of wrapping your code in a callback function you get
instead a promise object that gets called when certain events get
triggered, like so\[2\]:

        const myPromise = new Promise((resolve, reject) => {
          setTimeout(() => {
            resolve('foo');
          }, 300);
        });

        myPromise
          .then(handleResolvedA, handleRejectedA)
          .then(handleResolvedB, handleRejectedB)
          .then(handleResolvedC, handleRejectedC);

\[2\] Taken from [Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise){.perl-module}

Chaining is easy to implement in perl and
[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module} does
it too. Where it gets more tricky is returning a promise immediately
without waiting for further execution, i.e. a deferred promise, like the
following in JavaScript:

        function getRemote(url)
        {
            let promise = new Promise((resolve, reject) => 
            {
                setTimeout(() => reject(new Error("Whoops!")), 1000);
            });
            // Maybe do some other stuff here
            return( promise );
        }

In this example, under JavaScript, the `promise` will be returned
immediately. However, under perl, the equivalent code would be executed
sequentially. For example, using the excellent module
[Promise::ES6](https://metacpan.org/pod/Promise::ES6){.perl-module}:

        sub get_remote
        {
            my $url = shift( @_ );
            my $p = Promise::ES6->new(sub($res)
            {
                $res->( Promise::ES6->resolve(123) );
            });
            # Do some more work that would take some time
            return( $p );
        }

In the example above, the promise `$p` would not be returned until all
the tasks are completed before the `return` statement, contrary to
JavaScript where it would be returned immediately.

So, in perl people have started to use loop such as
[AnyEvent](https://metacpan.org/pod/AnyEvent){.perl-module} or
[IO::Async](https://metacpan.org/pod/IO::Async){.perl-module} with
\"conditional variable\" to get that asynchronous execution, but you
need to use loops. For example (taken from
[Promise::AsyncAwait](https://metacpan.org/pod/Promise::AsyncAwait){.perl-module}):

        use Promise::AsyncAwait;
        use Promise::XS;

        sub delay {
            my $secs = shift;

            my $d = Promise::XS::deferred();

            my $timer; $timer = AnyEvent->timer(
                after => $secs,
                cb => sub {
                    undef $timer;
                    $d->resolve($secs);
                },
            );

            return $d->promise();
        }

        async sub wait_plus_1 {
            my $num = await delay(0.01);

            return 1 + $num;
        }

        my $cv = AnyEvent->condvar();
        wait_plus_1()->then($cv, sub { $cv->croak(@_) });

        my ($got) = $cv->recv();

So, in the midst of this, I have tried to provide something without
event loop by using fork instead as exemplified in the
[\"SYNOPSIS\"](#synopsis){.perl-module}

For a framework to do asynchronous tasks, you might also be interested
in [Coro](https://metacpan.org/pod/Coro){.perl-module}, from [Marc A.
Lehmann](https://metacpan.org/author/MLEHMANN){.perl-module} original
author of [AnyEvent](https://metacpan.org/pod/AnyEvent){.perl-module}
event loop.

METHODS
=======

new
---

        my $p = Promise::Me->new(sub
        {
            # some code to run asynchronously
        });

        # or
        my $p = Promise::Me->new(sub
        {
            # some code to run asynchronously
        }, { debug => 4, result_shared_mem_size => 2097152, timeout => 2 });

Instantiate a new `Promise::Me` object.

It takes a code reference such as an anonymous subroutine or a reference
to a subroutine, and optionally an hash reference of options.

The options supported are:

*debug* integer

:   Sets the debug level. This can be quite verbose and will slow down
    the process, so use with caution.

*result\_shared\_mem\_size* integer

:   Sets the shared memory segment to store the asynchronous process
    results. This default to the value of the constant
    `Module::Generic::SharedMem::SHM_BUFSIZ`, which is 64K bytes.

*timeout* integer

:   Currently unused.

*use\_cache\_file*

:   Boolean. If true,
    [Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}
    will use a cache file instead of shared memory block. If you are on
    system that do not support shared memory,
    [Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}
    will automatically revert to
    [Module::Generic::File::Cache](https://metacpan.org/pod/Module::Generic::File::Cache){.perl-module}
    to handle data shared among processes.

    You can use the global package variable `$SHARE_MEDIUM` to set the
    default value for all object instantiation.

    `$SHARE_MEDIUM` value can be either `memory` for shared memory or
    `file` for shared cache file.

catch
-----

This takes a code reference as its unique argument and is added to the
chain of handlers.

It will be called upon an exception being met or if
[\"reject\"](#reject){.perl-module} is called.

reject
------

This takes one or more arguments that will be passed to the next
[\"catch\"](#catch){.perl-module} handler, if any.

It will mark the promise as `rejected` and will go no further in the
chain.

rejected
--------

Takes a boolean value and sets or gets the `rejected` status of the
promise.

This is typically set by [\"reject\"](#reject){.perl-module} and you
should not call this directly, but use instead
[\"reject\"](#reject){.perl-module}.

resolve
-------

This takes one or more arguments that will be passed to the next
[\"then\"](#then){.perl-module} handler, if any.

It will mark the promise as `resolved` and will the next
[\"then\"](#then){.perl-module} handler.

resolved
--------

Takes a boolean value and sets or gets the `resolved` status of the
promise.

This is typically set by [\"resolve\"](#resolve){.perl-module} and you
should not call this directly, but use instead
[\"resolve\"](#resolve){.perl-module}.

result
------

This sets or gets the result returned by the asynchronous process. The
data is exchanged through shared memory.

This method is used internally in combination with
[\"await\"](#await){.perl-module}, [\"all\"](#all){.perl-module} and
[\"race\"](#race){.perl-module}

The value returned is always a reference, such as array, hash or scalar
reference.

If the asynchronous process returns a simple string for example,
`result` will be an array reference containing that string.

Thus, unless the value returned is 1 element and it is a reference, it
will be made of an array reference.

timeout
-------

Sets gets a timeout. This is currently not used. There is no timeout for
the asynchronous process.

If you want to set a timeout, you can use
[\"wait\"](#wait){.perl-module}, or [\"await\"](#await){.perl-module}

wait
----

This is a chain method whose purpose is to indicate that we must wait
for the asynchronous process to complete.

        Promise::Me->new(sub
        {
            # Some operation to be run asynchronously
        })->then(sub
        {
            # Do some processing of the result
        })->catch(sub
        {
            # Cath any exceptions
        })->wait;

CLASS FUNCTIONS
===============

all
---

Provided with one or more `Promise::Me` objects, and this will wait for
all of them to be resolved.

It returns an array equal in size to the number of promises provided
initially.

However, if one promise is rejected, [\"all\"](#all){.perl-module} stops
and returns it immediately.

        my @results = Promise::Me->all( $p1, $p2, $p3 );

Contrary to its JavaScript equivalent, you do not need to pass an array
reference of promises, although you could.

        # Works too, but not mandatory
        my @results = Promise::Me->all( [ $p1, $p2, $p3 ] );

See also [Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all){.perl-module}
for more information.

race
----

Provided with one or more `Promise::Me` objects, and this will return
the result of the first promise that resolves or is rejected.

Contrary to its JavaScript equivalent, you do not need to pass an array
reference of promises, although you could.

        # Works too, but not mandatory
        my @results = Promise::Me->race( [ $p1, $p2, $p3 ] );

See also [Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race){.perl-module}
for more information.

EXPORTED FUNCTIONS
==================

async
-----

This is a static function exported by default and that wrap the
subroutine thus prefixed into one that returns a promise and return its
code asynchronously.

For example:

        async sub fetch
        {
            my $ua = LWP::UserAgent->new;
            my $res = $ua->get( 'https://example.com' );
        }

This would be equivalent to:

        Promise::Me->new(sub
        {
            my $ua = LWP::UserAgent->new;
            my $res = $ua->get( 'https://example.com' );
        });

Of course, since, in our example above, `fetch` would return a promise,
you could chain [\"then\"](#then){.perl-module},
[\"catch\"](#catch){.perl-module} and
[\"finally\"](#finally){.perl-module}, such as:

        async sub fetch
        {
            my $ua = LWP::UserAgent->new;
            my $res = $ua->get( 'https://example.com' );
        }->then(sub
        {
            my $res = shift( @_ );
            if( !$resp->is_success )
            {
                die( My::Exception->new( "Unable to fetch remote content." ) );
            }
        })->catch(sub
        {
            my $exception = shift( @_ );
            $logger->warn( $exception );
        })->finally(sub
        {
            $dbi->disconnect;
        });

See [Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function){.perl-module}
for more information on `async`

await
-----

Provided with one or more promises and [\"await\"](#await){.perl-module}
will wait until each one of them is completed and return an array of
their result with one entry per promise. Each promise result is a
reference (array, hash, or scalar, or object for example)

        my @results = await( $p1, $p2, $p3 );

lock
----

This locks a shared variable.

        my $data : shared = {};
        lock( $data );
        $data->{location} = 'Tokyo';
        unlock( $data );

See [\"SHARED VARIABLES\"](#shared-variables){.perl-module} for more
information about shared variables.

share
-----

Provided with one or more variables and this will enable them to be
shared with the asynchronous processes.

Currently supported variable types are: array, hash and scalar (string)
reference.

        my( $name, @first_names, %preferences );
        share( $name, @first_names, %preferences );
        $name = 'Momo Taro';

        Promise::Me->new(sub
        {
            $preferences{name} = $name = 'Mr. ' . $name;
            print( "Hello $name\n" );
            $preferences{location} = 'Okayama';
            $preferences{lang} = 'ja_JP';
            $preferences{locale} = '桃太郎'; # Momo Taro
            my $rv = $tbl->insert( \%$preferences )->exec || die( My::Exception->new( $tbl->error ) );
            $rv;
        })->then(sub
        {
            my $mail = My::Mailer->new(
                to => $preferences{email},
                name => $preferences{name},
                body => $welcome_ja_file,
            );
            $mail->send || die( $mail->error );
        })->catch(sub
        {
            my $exception = shift( @_ );
            $logger->write( $exception );
        })->finally(sub
        {
            $dbh->disconnect;
        });

It will try to use shared memory or shared cache file depending on the
value of the global package variable `$SHARE_MEDIUM`

unlock
------

This unlocks a shared variable. It has no effect on variable that have
not already been shared.

See [\"SHARED VARIABLES\"](#shared-variables){.perl-module} for more
information about shared variables.

unshare
-------

Unshare a variable. It has no effect on variable that have not already
been shared.

This should only be called before the promise is created.

INTERNAL METHODS
================

add\_final\_handler
-------------------

This is called each time a [\"finally\"](#finally){.perl-module} method
is called and will add to the chain the code reference provided.

add\_reject\_handler
--------------------

This is called each time a [\"catch\"](#catch){.perl-module} method is
called and will add to the chain the code reference provided.

add\_resolve\_handler
---------------------

This is called each time a [\"then\"](#then){.perl-module} method is
called and will add to the chain the code reference provided.

args
----

This method is called upon promise object instantiation when initially
called by [\"async\"](#async){.perl-module}.

It is used to capture arguments so they can be passed to the code
executed asynchronously.

exec
----

This method is called at the end of the chain. It will prepare shared
variable for the child process, launch a child process using [\"fork\"
in perlfunc](https://metacpan.org/pod/perlfunc#fork){.perl-module} and
will call the next [\"then\"](#then){.perl-module} handler if the code
executed successfully, or [\"reject\"](#reject){.perl-module} if there
was an error.

exit\_bit
---------

This corresponds to `$?`. After the child process exited,
[\"\_set\_exit\_values\"](#set_exit_values){.perl-module} is called and
sets the value for this.

exit\_signal
------------

This corresponds to the integer value of the signal, if any, used to
interrupt the asynchronous process.

exit\_status
------------

This is the integer value of the exit for the asynchronous process. If a
process exited normally, this value should be 0.

filter
------

This is called by the `import` method to filter the code using perl
filter with XS module
[Filter::Util::Call](https://metacpan.org/pod/Filter::Util::Call){.perl-module}
and enables data sharing, and implementation of async subroutine prefix.
It relies on XS module [PPI](https://metacpan.org/pod/PPI){.perl-module}
for parsing perl code.

get\_finally\_handler
---------------------

This is called when all chaining is complete to get the
[\"finally\"](#finally){.perl-module} handler, if any.

get\_next\_by\_type
-------------------

Get the next handler by type, i.e. `then`, `catch` or `finally`

get\_next\_reject\_handler
--------------------------

This is called to get the next [\"catch\"](#catch){.perl-module} handler
when a promise has been rejected, such as when an error has occurred.

get\_next\_resolve\_handler
---------------------------

This is called to get the next [\"then\"](#then){.perl-module} handler
and execute its code passing it the return value from previous block in
the chain.

has\_coredump
-------------

Returns true if the asynchronous process last exited with a core dump,
false otherwise.

is\_child
---------

Returns true if we are called from within the asynchronous process.

is\_parent
----------

Returns true if we are called from within the main parent process.

no\_more\_chaining
------------------

This is set to true automatically when the end of the method chain has
been reached.

pid
---

Returns the pid of the asynchronous process.

share\_auto\_destroy
--------------------

This is a promise instantiation option. When set to true, the shared
variables will be automatically removed from memory upon end of the main
process.

This is true by default. If you want to set it to false, you can do:

        Promise::Me->new(sub
        {
            # some code here
        }, {share_auto_destroy => 0})->then(sub
        {
            # some more work here, etc.
        });

shared\_mem
-----------

This returns the
[Module::Generic::SharedMem](https://metacpan.org/pod/Module::Generic::SharedMem){.perl-module}
object used for sharing data and result between the main parent process
and the asynchronous child process.

shared\_space\_destroy
----------------------

Boolean. Default to true. If true, the shared space used by the parent
and child processes will be destroy automatically. Disable this if you
want to debug or take a sneak peek into the data. The shared space will
be either shared memory of cache file depending on the value of
`$SHARE_MEDIUM`

use\_async
----------

This is a boolean value which is set automatically when a promise is
instantiated from [\"async\"](#async){.perl-module}.

It enables subroutine arguments to be passed to the code being run
asynchronously.

PRIVATE METHODS
===============

\_browse
--------

Used for debugging purpose only, this will print out the
[PPI](https://metacpan.org/pod/PPI){.perl-module} structure of the code
filtered and parsed.

\_parse
-------

After the code has been collected, this method will quickly parse it and
make changes to enable [\"async\"](#async){.perl-module}

\_reject\_resolve
-----------------

This is a common code called by either
[\"resolve\"](#resolve){.perl-module} or
[\"reject\"](#reject){.perl-module}

\_set\_exit\_values
-------------------

This is called upon the exit of the asynchronous process to set some
general value about how the process exited.

See [\"exit\_bit\"](#exit_bit){.perl-module},
[\"exit\_signal\"](#exit_signal){.perl-module} and
[\"exit\_status\"](#exit_status){.perl-module}

\_set\_shared\_space
--------------------

This is called in [\"exec\"](#exec){.perl-module} to share data
including result between main parent process and asynchronous process.

SHARED VARIABLES
================

It is important to be able to share variables between processes in a
seamless way.

When the asynchronous process is executed, the main process first fork
and from this point on all data is being duplicated in an impermeable
way so that if a variable is modified, it would have no effect on its
alter ego in the other process; thus the need for shareable variables.

You can enable shared variables in two ways:

1. declaring the variable as shared

:       my $name : shared;
            # Initiate a value
            my $location : shared = 'Tokyo';
            # you can also use 'pshared'
            my $favorite_programming_language : pshared = 'perl';
            # You can share array, hash and scalar
            my %preferences : shared;
            my @names : shared;

2. calling [\"share\"](#share){.perl-module}

:       my( $name, %prefs, @middle_names );
            share( $name, %prefs, @middle_names );

Once shared, you can use those variables normally and their values will
be shared between the parent process and the asynchronous process.

For example:

        my( $name, @first_names, %preferences );
        share( $name, @first_names, %preferences );
        $name = 'Momo Taro';

        Promise::Me->new(sub
        {
            $preferences{name} = $name = 'Mr. ' . $name;
            print( "Hello $name\n" );
            $preferences{location} = 'Okayama';
            $preferences{lang} = 'ja_JP';
            $preferences{locale} = '桃太郎';
            my $rv = $tbl->insert( \%$preferences )->exec || die( My::Exception->new( $tbl->error ) );
            $rv;
        })->then(sub
        {
            my $mail = My::Mailer->new(
                to => $preferences{email},
                name => $preferences{name},
                body => $welcome_ja_file,
            );
            $mail->send || die( $mail->error );
        })->catch(sub
        {
            my $exception = shift( @_ );
            $logger->write( $exception );
        })->finally(sub
        {
            $dbh->disconnect;
        });

If you want to mix this feature and the usage of threads\' `shared`
feature, use the keyword `pshared` instead of `shared`, such as:

        my $name : pshared;

Otherwise the two keywords would conflict.

SHARED MEMORY
=============

This module uses shared memory using perl core functions, or shared
cache file using
[Module::Generic::File::Cache](https://metacpan.org/pod/Module::Generic::File::Cache){.perl-module}
if shared memory is not supported, or if the value of the global package
variable `$SHARE_MEDIUM` is set to `file` instead of `memory`

Shared memory is used for:

1. shared variables

:   

2. storing results returned by asynchronous processes

:   

You can control how much shared memory is allocated for each by:

1. setting the global variable `$SHARED_MEMORY_SIZE`, which default to 64K bytes.

:   

2. setting the option *result\_shared\_mem\_size* when instantiating a new `Promise::Me` object. If not set, this will default to [Module::Generic::SharedMem::SHM\_BUFSIZ](https://metacpan.org/pod/Module::Generic::SharedMem::SHM_BUFSIZ){.perl-module} constant value which is 64K bytes.

:   If you use [shared cache
    file](https://metacpan.org/pod/Module::Generic::File::Cache){.perl-module},
    then not setting a size is ok. It will use the space on the
    filesystem as needed and obviously return an error if there is no
    space left.

CONCURRENCY
===========

Because
[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module} forks
a separate process to run the code provided in the promise, two promises
can run simultaneously. Let\'s take the following example:

        use Time::HiRes;
        my $result : shared = '';
        my $p1 = Promise::Me->new(sub
        {
            sleep(1);
            $result .= "Peter ";
        })->then(sub
        {
            print( "Promise 1: result is now: '$result'\n" );
        });

        my $p2 = Promise::Me->new(sub
        {
            sleep(0.5);
            $result .= "John ";
        })->then(sub
        {
            print( "Promise 2: result is now: '$result'\n" );
        });
        await( $p1, $p2 );
        print( "Result is: '$result'\n" );

This will yield:

        Promise 2: result is now: 'John '
        Promise 1: result is now: 'John Peter '
        Result is: 'John Peter '

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x555f1974dcb0)"}\>

SEE ALSO
========

[Promise::XS](https://metacpan.org/pod/Promise::XS){.perl-module},
[Promise::E6](https://metacpan.org/pod/Promise::E6){.perl-module},
[Promise::AsyncAwait](https://metacpan.org/pod/Promise::AsyncAwait){.perl-module},
[AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent::XSPromises){.perl-module},
[Async](https://metacpan.org/pod/Async){.perl-module},
[Promises](https://metacpan.org/pod/Promises){.perl-module},
[Mojo::Promise](https://metacpan.org/pod/Mojo::Promise){.perl-module}

[Mozilla documentation on
promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright(c) 2021-2022 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
