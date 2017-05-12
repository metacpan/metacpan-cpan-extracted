Redis::Handle
=============

A file**handle** tie for **Redis**.

(c) 2011 Traian Nedelea

This is licensed under the Do What The Fuck You Want Public License.
You may obtain a copy of the license [here](http://sam.zoy.org/wtfpl).

What is it?
-----------

`Redis::Handle` allows you to use a Redis queue as if it were a filehandle. You
can print to it, read a record (line) from it, or read all the records into an
array.

Features
--------

*   Pop elements off the queue one-at-a-time
*   Push elements to the queue
*   Flush the whole queue into an array
*   Now on [CPAN](http://search.cpan.org/~tron/Redis-Handle-0.1.1/lib/Redis/Handle.pm)!

How do I use it?
----------------

    tie *REDIS, 'Redis::Handle';
    print REDIS "Foo bar baz\n";
    print while <REDIS>;        # Prints "Foo bar baz\n"
    
    print REDIS "Foo", "Bar";
    my @baz = <REDIS>;          # @baz is now ("Foo", "Bar")
