# NAME

MojoX::Session - Session management for Mojo

# SYNOPSIS

    my $session = MojoX::Session->new(
        tx        => $tx,
        store     => MojoX::Session::Store::Dbi->new(dbh  => $dbh),
        transport => MojoX::Session::Transport::Cookie->new,
        ip_match  => 1
    );

    # or
    my $session = MojoX::Session->new(
        tx        => $tx,
        store     => [dbi => {dbh => $dbh}],  # use MojoX::Session::Store::Dbi
        transport => 'cookie',                # this is by default
        ip_match  => 1
    );

    $session->create; # creates new session
    $session->load;   # tries to find session

    $session->sid; # session id

    $session->data('foo' => 'bar'); # set foo to bar
    $session->data('foo'); # get foo value

    $session->data('foo' => undef); # works
    $session->clear('foo'); # delete foo from data

    $session->flush; # writes session to the store

# DESCRIPTION

[MojoX::Session](https://metacpan.org/pod/MojoX::Session) is a session management for [Mojo](https://metacpan.org/pod/Mojo). Based on [CGI::Session](https://metacpan.org/pod/CGI::Session)
and [HTTP::Session](https://metacpan.org/pod/HTTP::Session) but without any dependencies except the core ones.

# ATTRIBUTES

[MojoX::Session](https://metacpan.org/pod/MojoX::Session) implements the following attributes.

## `tx`

    Mojo::Transaction object

    my $tx = $session->tx;
    $tx    = $session->tx(Mojo::Transaction->new);

## `store`

    Store object

    my $store = $session->store;
    $session  = $session->store(MojoX::Session::Store::Dbi->new(dbh => $dbh));
    $session  = $session->store(dbi => {dbh => $dbh});

## `transport`

    Transport to find and store session id

    my $transport = $session->transport;
    $session
        = $session->transport(MojoX::Session::Transport::Cookie->new);
    $session = $session->transport('cookie'); # by default

## `ip_match`

    Check if ip matches, default is 0

    my $ip_match = $session->ip_match;
    $ip_match    = $session->ip_match(0);

## `expires_delta`

    Seconds until session is considered expired

    my $expires_delta = $session->expires_delta;
    $expires_delta    = $session->expires_delta(3600);

# METHODS

[MojoX::Session](https://metacpan.org/pod/MojoX::Session) inherits all methods from [Mojo::Base](https://metacpan.org/pod/Mojo::Base) and implements the
following new ones.

## `new`

    my $session = MojoX::Session->new(...);

    Returns new L<MojoX::Session> object.

## `create`

    my $sid = $session->create;
    $session->flush;

Creates new session. Puts sid into the transport. Call flush if you want to
store it.

## `load`

    $session->load;
    $session->load($sid);

Tries to load session from the store, gets sid from transport unless it is
provided. If sesssion is expired it will loaded also.

## `flush`

    $session->flush;

Flush actually writes to the store in these situations:
\- new session was created (inserts it);
\- any value was changed (updates it)
\- session is expired (deletes it)

Returns the value from the corresponding store method call.

## `sid`

    my $sid = $session->sid;

Returns session id.

## `data`

    my $foo = $session->data('foo');
    $session->data('foo' => 'bar');
    $session->data('foo' => 'bar', 'bar' => 'foo');
    $session->data('foo' => undef);

    # or
    my $foo = $session->data->{foo};
    $session->data->{foo} = 'bar';

Get and set values to the session.

## `flash`

    my $foo = $session->data('foo');
    $session->data('foo' => 'bar');
    $session->flash('foo'); # get foo and delete it from data
    $session->data('foo');  # undef

Get value and delete it from data. Usefull when you want to store error messages
etc.

## `clear`

    $session->clear('bar');
    $session->clear;
    $session->flush;

Clear session values. Delete only one value if argument is provided.  Call flush
if you want to clear it in the store.

## `expires`

    $session->expires;
    $session->expires(123456789);

Get/set session expire time.

## `expire`

    $session->expire;
    $session->flush;

Force session to expire. Call flush if you want to remove it from the store.

## `is_expired`

Check if session is expired.

## `extend_expires`

Entend session expires time. Set it to current\_time + expires\_delta.

# SEE ALSO

[CGI::Session](https://metacpan.org/pod/CGI::Session), [HTTP::Session](https://metacpan.org/pod/HTTP::Session)

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# CREDITS

Daniel Mascarenhas

David Davis

Maxim Vuets

Sergey Zasenko

William Ono

Yaroslav Korshak

Alex Hutton

Sergey Homenkow

# COPYRIGHT

Copyright (C) 2008-2013, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.
