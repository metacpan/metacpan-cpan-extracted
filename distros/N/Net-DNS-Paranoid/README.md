# NAME

Net::DNS::Paranoid - paranoid dns resolver

# SYNOPSIS

    my $dns = Net::DNS::Paranoid->new();
    $dns->blocked_hosts([
        'mixi.jp',
        qr{\.dev\.example\.com$},
    ]);
    $dns->whitelisted_hosts([
        'twitter.com',
    ]);
    my ($addrs, $errmsg) = $dns->resolve('mixi.jp');
    if ($addrs) {
        print @$addrs, $/;
    } else {
        die $errmsg;
    }

# DESCRIPTION

This is a wrapper module for Net::DNS.

This module detects IP address / host names for internal servers.

# METHODS

- my $dns = Net::DNS::Paranoid->new(%args)

    Create new instance with following parameters:

    - timeout

        DNS lookup timeout in secs.

        Default: 15 sec.

    - blocked\_hosts: ArrayRef\[Str|RegExp|Code\]

        List of blocked hosts in string, regexp or coderef.

    - whitelisted\_hosts: ArrayRef\[Str|RegExp|Code\]

        List of white listed hosts in string, regexp or coderef.

    - resolver: Net::DNS::Resolver

        DNS resolver object, have same interface as Net::DNS::Resolver.

- my ($addrs, $err) = $dns->resolve($name\[, $start\_time\[, $timeout\]\])

    Resolve a host name using DNS. If it's bad host, then returns $addrs as undef, and $err is the reason in string.

    $start\_time is a time to start your operation. Timeout value was counted from it.
    Default value is time().

    $timeout is a timeout value. Default value is `$dns-`timeout>.

# USE WITH Furl

You can use [Net::DNS::Paranoid](https://metacpan.org/pod/Net%3A%3ADNS%3A%3AParanoid) with Furl!

    use Furl::HTTP;
    use Net::DNS::Paranoid;

    my $resolver = Net::DNS::Paranoid->new();
    my $furl = Furl->new(
        inet_aton => sub {
            my ($host, $errmsg) = $resolver->resolve($_[0], time(), $_[1]);
            die $errmsg unless $host;
            Socket::inet_aton($host->[0]);
        }
    );

# USE WITH LWP

I shipped [LWPx::ParanoidHandler](https://metacpan.org/pod/LWPx%3A%3AParanoidHandler) to wrap this module.
Please use it.

# THANKS TO

Most of code was taken from [LWPx::ParanoidAgent](https://metacpan.org/pod/LWPx%3A%3AParanoidAgent).

# AUTHOR

Tokuhiro Matsuno < tokuhirom @A gmail DOT. com>

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
