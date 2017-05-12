NAME
----
Redis::SQLite - Redis-Compatible module which writes to SQLite.


LINKS
-----

* Github
   * https://github.com/skx/Redis--SQLite
* Mirror
   * https://git.steve.org.uk/cpan/Redis--SQLite


SYNOPSIS
--------

    use Redis::SQLite;

    my $r = Redis::SQLite->new();
    $r->set( "foo", "bar" );

    $r->incr( "counter");


DESCRIPTION
------------
This module allows you to easily migrate your applications from storing
their data in Redis to using SQLite instead.

Simply change from `use Redis` to `use Redis::SQLite` and your code
should continue to work.

This module is compatible with the original Redis client-library,
providing you're only performing SET-related operations, and simple
operations.

Specifically this means we do not support the following:

* Hashes.
* Hyperlog
* Lists.
* Pub/Sub
* Scripting
* Transactions.
* Zsets.


MOTIVATION
----------
I had a server which was unexpectedly popular, and this service was
using too much RAM because of all the data stored in Redis.

Although popular in terms of volume the service wasn't so stressed
that using SQLite would cause problems - but I didn't want to rewrite
it unnecessarily.

Instead it seemed like cloning the Redis API but writing all the data
to an SQLite database in the background would be a good approach.


AUTHOR
------
Steve Kemp <steve@steve.org.uk>


COPYRIGHT AND LICENSE
---------------------
Copyright (C) 2016 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.
