package Net::Server::Mail::SMTP::Prefork;
use 5.008005;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use Parallel::Prefork;
use Net::Server::Mail::SMTP;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        host        => $args{host} || 0,
        port        => $args{port} || 25,
        max_workers => $args{max_workers} || 10,
    };

    $self;
}

sub setup_listener {
    my $self = shift;

    $self->{listen_sock} ||= IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalPort => $self->{port},
        LocalAddr => $self->{host},
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or die "failed to listen to port $self->{port}:$!";

    if ($^O eq 'linux') {
        setsockopt($self->{listen_sock}, IPPROTO_TCP, 9, 1)
            and $self->{_using_defer_accept} = 1;
    }
}

sub accept_loop {
    my ($self, $max_reqs_per_child) = @_;

    my $proc_req_count = 0;

    while (! defined $max_reqs_per_child || $proc_req_count < $max_reqs_per_child) {
        if (my $conn = $self->{listen_sock}->accept) {
            $self->{_is_deferred_accept} = $self->{_using_defer_accept};
            $conn->blocking(0)
                or die "failed to set socket to nonblocking mode:$!";
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                or die "setsockopt(TCP_NODELAY) failed:$!";
            $proc_req_count++;
            my $smtp = $self->_prepare_smtp($conn);
            $smtp->process;
            $conn->close;
        }
    }
}

sub set_callback {
    my ($self, $name, $code, $context) = @_;
    confess('bad callback() invocation')
        unless defined $code && ref $code eq 'CODE';
    $self->{callback}->{$name} = [$code, $context];
}

sub run {
    my ($self) = @_;
    $self->setup_listener();
    if ($self->{max_workers} != 0) {
        # use Parallel::Prefork
        my %pm_args = (
            max_workers => $self->{max_workers},
            trap_signals => {
                TERM => 'TERM',
                HUP  => 'TERM',
            },
        );
        my $pm = Parallel::Prefork->new(\%pm_args);
        while ($pm->signal_received !~ /^(TERM|USR1)$/) {
            $pm->start and next;
            $self->accept_loop();
            $pm->finish;
        }
    } else {
        # run directly, mainly for debugging
        local $SIG{TERM} = sub { exit 0; };
        while (1) {
            $self->accept_loop();
        }
    }
}

sub _prepare_smtp {
    my ($self, $conn) = @_;

    my $smtp = Net::Server::Mail::SMTP->new('socket' => $conn);
    if ($self->{callback} && ref $self->{callback}) {
        for my $name (keys %{$self->{callback}}) {
            my ($code, $context) = @{$self->{callback}->{$name}};
            $smtp->set_callback($name, $code, $context);
        }
    }

    return $smtp;
}


1;
__END__

=encoding utf-8

=head1 NAME

Net::Server::Mail::SMTP::Prefork - Prefork SMTP Server

=head1 SYNOPSIS

    use Net::Server::Mail::SMTP::Prefork;

    my $server = Net::Server::Mail::SMTP::Prefork->new(
        host => 'localhost',
        port => 2500,
        max_workers => 20,
    );
    $server->set_callback('RCPT' => sub { return (1) });
    $server->set_callback('DATA' => sub { return (1, 250, 'message queued') });
    $server->run;

=head1 DESCRIPTION

Net::Server::Mail::SMTP::Prefork is preforking SMTP server.

=head1 LICENSE

Copyright (C) uchico.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

uchico E<lt>memememomo@gmail.comE<gt>

=cut

