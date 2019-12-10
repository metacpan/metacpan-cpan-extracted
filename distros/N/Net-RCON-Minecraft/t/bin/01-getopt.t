#!perl
use strict;
use lib qw<bin t/lib>;
use Test::More;
use Test::Exception;
use Test::Warnings qw/:all/;
use Test::Output;
require 'rcon-minecraft';

my $VER = Net::RCON::Minecraft->VERSION;

stdout_like { main('--version')     } qr/^rcon-minecraft version $VER/;
stdout_like { main('--help'   )     } qr/^Usage:/;
warning     { main('--foobar' )     },qr/^Unknown option: foobar/;

warning     { main('--timeout a')   },qr/^Value "a" invalid for option timeout/;
warning     { main('--port 11a')    },qr/^Value "11a" invalid for option port/;
warning     { main("--$_=foo")      },qr/^Option $_ does not take an argument/
    for qw< color quiet echo >;

throws_ok   { main()                } qr/^Password required/;

done_testing;

__END__

=head1 NAME

rcon-minecraft - Dummy POD for testing

=head1 SYNOPSIS

B<rcon-minecraft> --pass=I<password> [I<options>] I<command args> ...

B<rcon-minecraft> --pass=I<password> [I<options>] --command='I<cmd1>' ...

=head1 OPTIONS

 --host=host        Hostname to connect to          [127.0.0.1]
 --port=port        Port number                         [25575]
 --password=pass    Password
 --timeout=sec      Timeout in seconds (float)             [30]
 --command='cmd'    Command to run. May be repeated.
   | --cmd='cmd'
 -c|--color         Use a colored output (modded servers)   [0]
 -q|--quiet         Suppress command output
 --echo             Echo the commands themselves to stdout
 -v|--version       Display version number and exit

Any remaining arguments on the commandline will be concatenated
together and interpreted as a single command, as you might expect.

