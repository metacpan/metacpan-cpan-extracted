# perl_mojox_http_async

### NAME
    MojoX::HTTP::Async - simple package to execute multiple parallel requests to the same host

### SYNOPSIS

```perl
    use MojoX::HTTP::Async ();
    use Mojo::Message::Request ();

    # creates new instance for async requests to the certain domain,
    # restricts max amount of simultaneously executed requests
    my $ua = MojoX::HTTP::Async->new('host' => 'my-site.com', 'slots' => 2);

    # let's fill slots
    $ua->add('/page1.html?lang=en');
    $ua->add('http://my-site.com/page2.html');
    $ua->add( Mojo::Message::Request->new() );

    # non-blocking requests processing
    while ( $ua->not_empty() ) {
        if (my $tx = $ua->next_response) { # returns an instance of Mojo::Transaction::HTTP class
            print $tx->res->headers->to_string;
        } else {
            # do something else
        }
    }

    # blocking requests processing while (my $tx =
    $ua->wait_for_next_response($timeout)) { # do something here }

    # how to process connect timeouts
    if (my $error = $tx->req()->error()) {
        say $error->{code};
        say $error->{message};
    }

    # how to process request timeouts and other errors sucn as broken pipes, etc
    if (my $error = $tx->res()->error()) {
        say $error->{code};
        say $error->{message};
    }

    # makes reconnection if either slot was timeouted or was inactive too long
    $ua->refresh_connections();

    # close everything
    $ua->close_all();
```

### DESCRIPTION

    This library allows to make multiple HTTP/HTTPS request to the particular host in non-blocking mode.

    In comparison with "HTTP::Async", this library doesn't make a new connection on each request.

    And in comparison with "Mojo::AsyncAwait", it's it's more intuitive how
    to use it, and there is no any Singleton restrictions.

    The instance of this class can work only with one domain and scheme: either HTTP or HTTPS.

### LICENSE

    This module is distributed under terms of Artistic Perl 5 license.

##### new($class, %opts)
    The class constructor.

###### host
        It's the obligatory option.
        Sets the name/adress of remote host to be requested.

###### port
        By default it's equal to 80. Sets the port number of remote point.

###### slots
        By default it's equal to 5. Sets the maximum amount of slots.
        These slot will be filled one by one if required.

###### ssl
        By default it's equal to 0 (means HTTP).
        Sets the scheme of requests: HTTP or HTTPS.

###### ssl_opts
        It's a HashRef with options to control SSL Layer.
        See the "IO::Socket::SSL" constructor arguments for details.

###### connect_timeout
        By default it's equal to 1.
        Sets connection timeout in seconds.

        If it's equal to 0, then there will be no timeout restrictions.

###### request_timeout
        By default it's equal to 1 Sets the time in seconds with granular
        accuracy as micro seconds.
        The awaiting time of response will be limited with this value.

        In case of 0 value there will be no time restrictions.

###### sol_socket
        It's a HashRef with socket options. THe possible keys are:

        so_keepalive
            Enables TCP KeepAlive on socket.
            The default value is 1 (means that option is enabled).

###### sol_tcp
        WARNING: These options can be unsupported on some OS platforms.

        It's a HashRef with socket TCP-options.

        If some key is absent in HashRef then system settings will be used.

        The supported key are shown below:

        tcp_keepidle
            the time (in seconds) the connection needs to remain
            idle before TCP starts sending keepalive probes

        tcp_keepintvl
            the time (in seconds) between individual keepalive probes

        tcp_keepcnt
            the maximum number of keepalive probes TCP should send
            before dropping the connection.

###### inactivity_conn_ts
        If last response was received "inactivity_conn_ts" seconds or more
        ago, then such slots will be destroyed in "clear" method.

        By default the value is 0 (disabled).

###### debug
        Enables debug mode. The debug messages will be printed in STDERR.

        By default the value is 0 (disabled).

##### add ($self, $request_or_uri, $timeout = undef)
    Adds HTTP request into empty slot.

    If the request was successfully added, then it will return 1. Otherwise
    it will return 0.

    The request can be not added into slot only in case, if there are no
    empty slots and new slot wasn't created due to the limit of slot's
    amount had been reached (see "new" and "slots".

    It's recommendable always to check result code of this method.

    Example:

```perl
        my $ua = MojoX::HTTP::Async->new('host' => 'my-host.com', 'slots' => 1);

        # let's occupy the only slot
        $ua->add('/page1.html');

        # let's wait until it's become free again
        while ( ! $ua->add('/page2.html') ) {
            while (my $tx = $ua->wait_for_next_response() ) {
                # do something here
            }
        }
```

###### $request_or_uri
        It can be either an instance of "Mojo::Message::Request" class, or
        an instance of "Mojo::URL". It also can be a simple URI string.

        If the resource contains the host, then it must be the same as in
        the constructor "new".

        Using of string with URI or an instance of "Mojo::URL" class assumes
        that GET HTTP method will be used.

###### $timeout
        Time in seconds. Can be fractional with microseconds tolerance.

        The "request_timeout" from construcor will be used by default.

##### not_empty($self)
    Returns 1 if there even one slot is busy or slot contains a not
    processed response. Otherwise the method returns 0.

##### wait_for_next_response($self, $timeout = 0)
    Waits for first received response or time-outed request in any slot.
    Returns the "Mojo::Transaction::HTTP" instance with result.

###### $timeout
        Period of time in seconds. Can be fractional with microsecond
        tolerance. The response will be marked as time-outed after this time is out.

        The default value is 0, which means that request will have been
        blocked until the response is received.

        If all slots are empty, then "undef" will be returned.

##### next_response ($self)
    Returns an instance of "Mojo::Transaction::HTTP" class. If there is no response, it will return "undef".

##### refresh_connections ($self)
    Closes connections in slots in the following cases:

    1. The slot was marked as time-outed

    2. The "inactivity_conn_ts" was set and the connection was expired

    3. There are some errors in socket (for example: Connection reset by peer, Broken pipe, etc)

##### close_all ($self)
    Closes all opened connections and resets all slots with requests.

##### DESTROY($class)
    The class destructor.

    Closes all opened sockets.
