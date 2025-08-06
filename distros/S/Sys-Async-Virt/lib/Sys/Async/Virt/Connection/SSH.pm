####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.6.0
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
use Object::Pad;

class Sys::Async::Virt::Connection::SSH v0.1.4;

inherit Sys::Async::Virt::Connection '$_in', '$_out';

use Carp qw(croak);
use IO::Async::Stream;
use Log::Any qw($log);

use Protocol::Sys::Virt::UNIXSocket v11.6.0; # imports socket_path
use Protocol::Sys::Virt::URI v11.6.0; # imports parse_url

field $_url      :reader :param;
field $_socket   :reader :param = undef;
field $_readonly :reader :param;
field $_process;

method close() {
    $_process->kill( 'TERM' ) if not $_process->is_exited;
}

method configure(%args) {
    delete $args{url};
    delete $args{socket};
    delete $args{readonly};

    $self->SUPER::configure(%args);
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

async method connect() {
    my %c = parse_url( $_url );
    my @args =  ('-e', 'none');
    push @args, ('-p', $c{port}) if $c{port};
    push @args, ('-l', $c{username}) if $c{username};
    push @args, ('-i', $c{keyfile}) if $c{keyfile};
    push @args, ('-o', 'StrictHostKeyChecking=no') if $c{no_verify};
    push @args, ('-T') if $c{no_tty};

    my $remote_cmd;
    my $proxy_mode  = $c{query}->{proxy} // 'auto';
    my $socket_path = $_socket // $c{query}->{socket} //
        socket_path(readonly => $_readonly,
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
    $_process = $self->loop->open_process(
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

    $_in  = $_process->stdout;
    $_out = $_process->stdin;

    return;
}

method is_secure() {
    return 1;
}

1;


__END__

=head1 NAME

Sys::Async::Virt::Connection::SSH - Connection to LibVirt server over SSH

=head1 VERSION

v0.1.4

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


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
