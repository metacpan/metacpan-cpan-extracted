package RPC::Lite::Threading;

=pod

=head1 Threading in RPC::Lite

RPC::Lite supports threading if you have the Thread::Pool module
installed.  Threading can allow for more robust services but
you must be aware of all the pitfalls threaded programming
entails.  Don't enable threading unless you need it and are
aware of the issues you must take into consideration.

The intention of providing threading is to allow for servers
that can handle both long and short-running requests.  For example,
you might implement a simple Authenticate() method which matches
a given username/password with an entry in a database.  That call
should be relatively trivial and return quickly.  However, you
might also implement a Search() method which can take seconds or
longer to return.  In a non-threaded implementation, any call to
Authenticate will block if a Search call is in progress.  Obviously,
that's not optimal behavior.  With careful programming and threading
support, long-running calls need not make the server unresponsive to
other incoming requests.

All of the caveats that come with multi-threaded programming will
apply to a threaded service, however.  It's important to keep in mind
that you may need locks around certain functionality to avoid the
standard data corruption issues with concurrency.

RPC::Lite::Server has more information on how to enable and configure
threading.

=cut

1;