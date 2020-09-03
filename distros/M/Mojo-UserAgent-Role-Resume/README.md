# NAME

Mojo::UserAgent::Role::Resume - Role for Mojo::UserAgent that provides resuming capability during downloads

# SYNOPSIS

    use Mojo::UserAgent;

    my $class = Mojo::UserAgent->with_roles('+Resume');

    my $ua = $class->new(max_attempts => 5);

    # works with blocking requests:
    my $tx = $ua->get('http://ipv4.download.thinkbroadband.com/100MB.zip');

    # ...as well as with non-blocking ones (including promises, etc):
    $ua->get('http://ipv4.download.thinkbroadband.com/100MB.zip', sub ($ua, $tx) {
        $tx->res->content->asset->move_to('downloaded_file.zip');
        print $tx->res->headers->to_string;
    });

    # The last snippet will save the entire file to downloaded_file.zip regardless of temporary disconnects, and
    # will print something like this:
    Connection: keep-alive
    Content-Length: 103124119
    Server: nginx
    ETag: "48401320-6400000"
    Last-Modified: Fri, 30 May 2008 14:45:52 GMT
    Date: Thu, 27 Aug 2020 16:25:18 GMT
    Content-Range: bytes 1733481-104857599/104857600
    Content-Type: application/zip
    Access-Control-Allow-Origin: *

# DESCRIPTION

Mojo::UserAgent::Role::Resume is a role for Mojo::UserAgent that allows the user-agent to
retry a URL upon failure.

Retries are made after a connection error or after a server error (HTTP status 5xx) occurs.

It will intelligently determine whether the server it's downloading from properly supports ranged requests,
and if it doesn't, then upon failure it will stop asking for a resume and request the complete file again
from scratch.

It will request the original user-provided request in its next attempts, not the one that may have resulted from
redirections of the first attempt.

The `$tx` object returned is the last HTTP transaction that took place.

# ATTRIBUTES

[Mojo::UserAgent::Role::Resume](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3ARole%3A%3AResume) adds the following attribute to the [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) object:

## max\_attempts

    my $ua = $class->new;
    $ua->max_attempts(5);

The number of attempts it will try (at most). Defaults to 1.

What matters for each download is the value this attribute held at the time the first attempt of that download was
started.

# TODO

- Write tests
- Check whether the module should also check whether "content received < total\_size\_based\_on\_headers" when
determining whether to retry
- Add events

Other than the above, this module works.

# SPONSORS

This module was sponsored.

# LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KARJALA Corp <karjala@cpan.org>
