package POE::Component::IRC::Plugin::MultiProxy::Away;
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::Away::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::Away::VERSION = '0.01';
}

use strict;
use warnings FATAL => 'all';
use POE::Component::IRC::Plugin qw( :ALL );

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . " requires PoCo::IRC::State or a subclass thereof\n";
    }

    $self->{Message} = 'No clients attached' unless defined $self->{Message};
    $self->{clients} = 0;

    if ($irc->connected() && $irc->is_away($irc->nick_name())) {
        $self->{away} = 1;
    }

    $irc->plugin_register($self, 'SERVER', qw(001 proxy_authed proxy_close));
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    if (!$self->{clients}) {
        $irc->yield(away => $self->{Message});
        $self->{away} = 1;
    }
    return PCI_EAT_NONE;
}

sub S_proxy_authed {
    my ($self, $irc) = splice @_, 0, 2;
    my $client = ${ $_[0] };
    $self->{clients}++;
    if ($self->{away}) {
        $irc->yield('away');
        $self->{away} = 0;
    }
    return PCI_EAT_NONE;
}

sub S_proxy_close {
    my ($self, $irc) = splice @_, 0, 2;
    my $client = ${ $_[0] };
    $self->{clients}--;
    if (!$self->{clients}) {
        $irc->yield(away => $self->{Message});
        $self->{away} = 1;
    }
    return PCI_EAT_NONE;
}

sub message {
    my ($self, $value) = @_;
    return $self->{Message} if !defined $value;
    $self->{Message} = $value;
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::MultiProxy::Away - A PoCo-IRC plugin which changes the away status based on the presence of proxy clients

=head1 SYNOPSIS

 use POE::Compoent::IRC::Plugin::MultiProxy::Away;

 $irc->plugin_add('Away', POE::Compoent::IRC::Plugin::MultiProxy::Away->new(Message => "I'm out to lunch"));

=head1 DESCRIPTION

POE::Compoent::IRC::Plugin::MultiProxy::Away is a
L<POE::Component::IRC|POE::Component::IRC> plugin. When the last proxy clien
detaches, it changes the status to away, with the supplied away message.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

One optional argument:

B<'Message'>, the away message you want to use. Defaults to 'No clients
attached'.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add()> method.

=head2 C<message>

One optional argument:

An away message

Changes the away message when called with an argument, returns the current
away message otherwise.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
