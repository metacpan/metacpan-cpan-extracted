####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.0.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;

package Sys::Async::Virt::Connection::SSH v0.0.14;

use parent qw(Sys::Async::Virt::Connection);

use Carp qw(croak);
use IO::Async::Stream;
use Log::Any qw($log);

use Protocol::Sys::Virt::UNIXSocket v11.0.0; # imports socket_path
use Protocol::Sys::Virt::URI v11.0.0; # imports parse_url

sub new($class, $url, %args) {
    return bless {
        url => $url,
        %args{ qw(socket readonly) }
    }, $class;
}

sub close($self) {
    $self->{process}->kill( 'TERM' ) if not $self->{process}->is_exited;
}

sub shell_escape($val) {
    if ($val !~ m/[\s!"'`$<>#&*?;\\\[\]{}()~|^]/) { # no shell chars
        return $val;
    }

    return (q|'| . ($val =~ s/'/'\\''/gr) . q|'|);
}

my $nc_proxy =
    q{if %1$s -q 2>&1 | grep "requires an argument" >/dev/null 2>&1; } .
    q{then A=-q0; } .
    q{else A=; } .
    q{fi; } .
    q{%1$s $A -U %2$s};

my $native_proxy =
    q{virt-ssh-helper %s};

my $auto_proxy =
    q{if which virt-ssh-helper >/dev/null 2>&1; } .
    q{then %s; } .
    q{else %s; } .
    q{fi};

async sub connect($self) {
    my %c = parse_url( $self->{url} );
    my @args =  ('-e', 'none');
    push @args, ('-p', $c{port}) if $c{port};
    push @args, ('-l', $c{username}) if $c{username};
    push @args, ('-i', $c{keyfile}) if $c{keyfile};
    push @args, ('-o', 'StrictHostKeyChecking=no') if $c{no_verify};
    push @args, ('-T') if $c{no_tty};

    my $remote_cmd;
    my $proxy_mode  = $c{query}->{proxy} // 'auto';
    my $socket_path = $self->{socket} // $c{query}->{socket} //
        socket_path(readonly => $self->{readonly},
                    hypervisor => $c{hypervisor},
                    mode => $c{mode},
                    type => $c{type});

    my $nc_command = sprintf($nc_proxy,
                             $c{query}->{netcat} // 'nc',
                             $socket_path);
    my $native_command = 'virt-ssh-helper ' . shell_escape($c{proxy});
    if ($proxy_mode eq 'netcat') {
        $remote_cmd = sprintf(q|sh -c %s|, shell_escape($nc_command));
    }
    elsif ($proxy_mode eq 'native') {
        $remote_cmd = $native_command;
    }
    elsif ($proxy_mode eq 'auto') {
        $remote_cmd = sprintf(q|sh -c %s|,
                              shell_escape(sprintf($auto_proxy,
                                                   $native_command,
                                                   $nc_command)));
    }
    else {
        croak $log->fatal( "Unknown proxy mode '$proxy_mode'" );
    }

    my $local_cmd  = $c{command} // 'ssh';
    my @cmd = ($local_cmd, @args, '--', $c{host}, $remote_cmd);
    $log->trace("SSH remote command: $remote_cmd");
    $log->trace("SSH total command: " . join(' ', @cmd) );
    my $process = $self->loop->open_process(
        command => \@cmd,
        stdout => {
            on_read => sub { 0 },
        },
        stderr => {
            on_read => sub {
                # eat stderr input
                my $bufref = $_[1]; say $bufref; ${$bufref} = ''; 0;
            },
        },
        stdin => {
            via => 'pipe_write'
        },
        on_finish => sub { }, # on_finish is mandatory
        );

    $self->{process} = $process;
    $self->{in}  = $process->stdout;
    $self->{out} = $process->stdin;

    return;
}

sub is_secure($self) {
    return 1;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::SSH - Connection to LibVirt server over SSH

=head1 VERSION

v0.0.14

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu+ssh://localhost/system' );

=head1 DESCRIPTION

This module connects to a local LibVirt server through an ssh binary in
the system PATH.

=head1 URL PARAMETERS

This connection driver supports these parameters in the query string
of the URL, as per L<LibVirt's documentation|https://libvirt.org/uri.html#ssh-transport>:

=over 8

=item * command

=item * keyfile

=item * mode

=item * netcat

=item * no_tty

=item * no_verify

=item * proxy

=item * socket

The path of the socket to be connected to.

=back

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Instantiated via the connection factory
(L<Sys::Async::Virt::Connection::Factory>).

=head1 METHODS

=head2 connect

  await $conn->connect;

=head2 is_secure

  my $bool = $conn->is_secure;

Returns C<true>.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
