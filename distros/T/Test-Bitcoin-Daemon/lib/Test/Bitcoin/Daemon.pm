package Test::Bitcoin::Daemon;

use 5.014002;
use strict;
use warnings;

use POSIX ":sys_wait_h";
use File::Temp qw(tempdir);

require Exporter;

our $VERSION = 0.02;

sub new {
    my $class = shift;

    my $dir = tempdir(CLEANUP => 1);
    my $port = int(rand 32768) + 32768;
    my $user = random_string();
    my $pass = random_string();
    my $cmd = "bitcoind -testnet "
        . "-rpcuser=$user -rpcpassword=$pass -rpcport=$port";
    my $clicmd = "$cmd -rpcconnect=127.0.0.1";

    my $pid = fork;
    if ($pid == 0) {
        chdir $dir;
        exec "$cmd -listen=0 -server -datadir='$dir'";
    } elsif ($pid < 0) {
        die "Could not launch bitcoind";
    }

    $SIG{CHLD} = sub {
        while ((my $child = waitpid(-1, WNOHANG)) > 0) {
            if ($child == $pid) {
                die "bitcoind died";
            }
        }
    };

    sleep 1 while system("$clicmd getinfo 2>/dev/null") != 0;

    my $self = {
        clicmd => $clicmd,
        pid => $pid,
        username => $user,
        password => $pass,
        port => $port,
        dir => $dir,
        url => "http://127.0.0.1:$port",
    };

    bless $self, $class;
}

sub clicmd { $_[0]->{clicmd} }
sub pid { $_[0]->{pid} }
sub username { $_[0]->{username} }
sub password { $_[0]->{password} }
sub port { $_[0]->{port} }
sub dir { $_[0]->{dir} }
sub url { $_[0]->{url} }

sub random_string {
    my @chars = ("A".."Z", "a".."z");
    my $string;
    $string .= $chars[rand @chars] for 1..8;
    return $string;
}

sub DESTROY {
    my $self = shift;
    system("$self->{clicmd} stop 2>/dev/null");
    wait;
}

1;
__END__

=head1 NAME

Test::Bitcoin::Daemon - Test RPC commands against a temporary instance of bitcoind

=head1 SYNOPSIS

  use Test::Bitcoin::Daemon;
  my $bitcoind = new Test::Bitcoin::Daemon;
  my $rpc_url = $bitcoind->url;
  my $rpc_user = $bitcoind->username;
  my $rpc_pass = $bitcoind->pass;
  ...

=head1 DESCRIPTION

A Test::Bitcoin::Daemon object will create a bitcoind testnet instance to use
for testing. Once the object gets destroyed, the instance will be stopped and
the temporary directories it used will be removed.

If caller crashes without allowing this module to clean up after itself,
temporary files will be left behind. If your system doesn't purge these files
automatically, look in your temp directory for a subdirectory containing a
testnet3 entry and remove it. In Linux the temp directory is usually in /tmp.

=head1 AUTHOR

Jean-Pierre Rupp E<lt>root@xeno-genesis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jean-Pierre Rupp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
