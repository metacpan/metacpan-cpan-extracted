# About Net::RCON::Minecraft

`Net::RCON::Minecraft` is a Minecraft-specific implementation of the RCON
protocol, used to automate sending commands and receiving responses from a
Minecraft server.

With a properly configured server, you can use this module to automate many
tasks, and extend the functionality of your server without the need to mod
the server itself.

# Synopsis

```perl
    use Net::RCON::Minecraft;

    my $rcon = Net::RCON::Minecraft->new(password => 'secret',
                                             host => 'mc.example.com');

    eval { $rcon->connect } or die "Connection failed: $@";

    my $response = eval { $rcon->command('kill @a') };
    if ($@) {
        warn "Command failed: $@";
    } else {
        say "Command response: " . $response->ansi;
        say "  Plain response: " . $response; # or $response->plain
    }
```

# Documentation

Once this module is installed, full documentation is available via `perldoc
Net::RCON::Minecraft` on your local system. Documentation for all public
releases is also available on
[MetaCPAN](https://metacpan.org/pod/Net::RCON::Minecraft)

## `rcon-minecraft`

While the main focus of this distribution is the Net::RCON::Minecraft library
itself, this distribution also contains a utility, `rcon-minecraft`, which
provides a rudimentary commandline interface to the library.

Synopsis:

```sh
    rcon-minecraft --host=mc.example.com --pass=secret \
        --command='command args' --command='command args' ...
```

Help for rcon-minecraft is available via either of the following:

```sh
    perldoc rcon-minecraft  # Preferred, if you have perldoc
    rcon-minecraft --help   # Options summary
```

If for some reason none of those options work for you, you can view the latest
documentation for this script online:
[rcon-minecraft](https://metacpan.org/pod/distribution/Net-RCON-Minecraft/bin/rcon-minecraft)

# Installation

If you simply want the latest public release, install via CPAN.

If you need to build and install from this distribution directory itself,
run the following commands:

```sh
    perl Makefile.PL
    make
    make test
    make install
```

You may need to follow your system's usual build instructions if that doesn't
work. For example, Windows users will probably want to use `gmake` instead of
`make`. Otherwise, the instructions are the same.

# Support

 - [RT, CPAN's request tracker](https://rt.cpan.org/NoAuth/Bugs.html?Queue=Net-RCON-Minecraft): Please report bugs here.
 - [GitHub Repository](https://github.com/rjt-pl/Net-RCON-Minecraft)

# License and Copyright

Copyright (C) Ryan J Thompson <<rjt@cpan.org>>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

[Perl Artistic License](http://dev.perl.org/licenses/artistic.html)
