### Net::CLI::Interact - Toolkit for CLI Automation ###

Automating command line interface (CLI) interactions is not a new idea, but
can be tricky to implement. This module aims to provide a simple and
manageable interface to CLI interactions, supporting:

* SSH, Telnet and Serial-Line connections
* Unix and Windows support
* Reuseable device command phrasebooks

If you're a new user, please read the
[Tutorial](https://metacpan.org/pod/Net::CLI::Interact::Manual::Tutorial).
There's also a
[Cookbook](https://metacpan.org/pod/Net::CLI::Interact::Manual::Cookbook)
and a
[Phrasebook Listing](https://metacpan.org/pod/Net::CLI::Interact::Manual::Phrasebook).

#### Installation ####

Using cpanm:

    cpanm Net::CLI::Interact

Or manually, from the source:

    perl Makefile.PL
    make test && make install

#### Example Usage ####

```perl
    use Net::CLI::Interact;

    my $s = Net::CLI::Interact->new({
        personality     => 'cisco',
        transport       => 'Telnet',
        connect_options => { host => '192.0.2.1' },
    });

    # respond to a usename/password prompt
    $s->macro('to_user_exec', {
        params => ['my_username', 'my_password'],
    });

    my $interfaces = $s->cmd('show ip interfaces brief');

    $s->macro('to_priv_exec', {
        params => ['my_password'],
    });
    # matched prompt is updated automatically

    # paged output is slurped into one response
    $s->macro('show_run');
    my $config = $s->last_response;
```

For a more complete worked example check out the
[Net::Appliance::Session](https://metacpan.org/pod/Net::Appliance::Session)
distribution, for which this module was written.

For more information on the API, please check out
[Net::CLI::Interact's complete documentation](https://metacpan.org/pod/Net::CLI::Interact)
on CPAN.

#### Copyright and License

This software is copyright (c) 2014-2015 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

