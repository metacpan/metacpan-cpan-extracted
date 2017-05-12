package Net::IPMessenger::Bot;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.05';

use Net::IPMessenger;
use Net::IPMessenger::Bot::EventHandler;

sub new {
    my ( $class, %args ) = @_;

    my $ipmsg   = Net::IPMessenger->new( %{ $args{configure} } );
    my $handler = Net::IPMessenger::Bot::EventHandler->new(
        handler => $args{on_message},
    );
    $ipmsg->add_event_handler($handler);

    my $self = bless { ipmsg => $ipmsg }, $class;
    $self->_set_signal_handlers;

    return $self;
}

sub start {
    my $self = shift;
    $self->join();
    while ( $self->{ipmsg}->recv() ) { }
}

sub join {
    my $self = shift;

    my $cmd = $self->{ipmsg}->messagecommand('BR_ENTRY')->set_broadcast;
    $self->{ipmsg}->send(
        {
            command => $cmd,
            option  => $self->{ipmsg}->my_info,
        }
    );
}

sub _set_signal_handlers {
    my $self = shift;
    $SIG{INT} = $SIG{TERM} = sub { $self->sighandle_INT() };
}

sub sighandle_INT {
    my $self = shift;

    my $cmd = $self->{ipmsg}->messagecommand('BR_EXIT')->set_broadcast;
    $self->{ipmsg}->send( { command => $cmd } );

    exit;
}


1;
__END__

=encoding utf-8

=head1 NAME

Net::IPMessenger::Bot - IPMessenger-Bot building framework

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use Net::IPMessenger::Bot;
  use Sys::Hostname;

  my $bot = Net::IPMessenger::Bot->new(
      configure => {
          UserName  => 'ipmsg_bot',
          NickName  => 'ipmsg_bot',
          GroupName => 'bot',
          HostName  => hostname(),
      },
      on_message => sub {
          my $user = shift;
          "Hello " . $user->nickname;
      },
  );

  $bot->start;

=head1 DESCRIPTION

Net::IPMessenger::Bot is an IPMessenger-Bot building framework.

=head1 METHODS

L<Net::IPMessenger::Bot> implements following methods.

=head2 new

  my $bot = Net::IPMessenger::Bot->new(
      configure => {
          UserName  => 'ipmsg_bot',
          NickName  => 'ipmsg_bot',
          GroupName => 'bot',
          HostName  => hostname(),
      },
      on_message => sub {
          my $user = shift;
          "Hello " . $user->nickname;
      },
  );

Construct a new L<Net::IPMessenger::Bot>.

=over 2

=item configure

  configure => {
      UserName  => 'ipmsg_bot',
      NickName  => 'ipmsg_bot',
      GroupName => 'bot',
      HostName  => hostname(),
  },

options for L<Net::IPMessenger>#new.

=item on_message

  on_message => sub {
      my $user = shift;
      "Hello " . $user->nickname;
  }

or

  on_message => [
      qr/hello/ => sub {
        my $user = shift;
        "Hello " . $user->nickname;
      },
      qr/goodbye/ => sub {
        my $user = shift;
        "Goodbye " . $user->nickname;
      },
  }

register callback.

=back

=head2 start

  $bot->start;

start bot.

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- hayajo

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::IPMessenger>

=cut
