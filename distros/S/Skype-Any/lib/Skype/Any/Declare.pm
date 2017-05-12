package Skype::Any::Declare;
use strict;
use warnings;
use parent qw/Exporter/;
use Skype::Any;

our @EXPORT = qw/skype respond hear run/;

my $_SKYPE;
sub skype {
    $_SKYPE ||= Skype::Any->new(@_);
}

sub _router {
    my ($status, $reg, $code) = @_;
    unless (ref $reg eq 'Regexp') {
        $reg = qr/^\Q$reg\E$/;
    }
    skype->message_received(sub {
        my ($chatmessage) = @_;
        if ($chatmessage->chat->status eq $status) {
            if (my @capture = $chatmessage->body =~ $reg) {
                # Regexp matches but if there is no capturing parentheses:
                @capture = () unless $#+;

                $code->($chatmessage, @capture);
            }
        }
    });
}

sub respond {
    my @args = @_;
    while (my ($reg, $code) = splice @args, 0, 2) {
        _router('DIALOG', $reg, $code);
    }
}

sub hear {
    my @args = @_;
    while (my ($reg, $code) = splice @args, 0, 2) {
        _router('MULTI_SUBSCRIBED', $reg, $code);
    }
}

sub run() {
    skype->run;
}

1;
__END__

=head1 NAME

Skype::Any::Declare - Addition of an interface similar to hubot for Skype::Any

=head1 SYNOPSIS

  use Skype::Any::Declare;

  skype(name => 'ping-pong');

  hear 'ping' => sub {
      my ($msg) = @_;
      $msg->chat->send_message('pong');
  };

  run;

=head1 DESCRIPTION

Skype::Any::Declare has interface similar to hubot.

=head1 FUNCTIONS

=head2 skype

Return L<Skype::Any> object. Also, this function can specify arguments to pass to the object.

=head2 respond

  respond qr/pattern/ => sub { my ($chatmessage, @match) = @_; ... };
  respond 'string' => sub { my ($chatmessage, @match) = @_; ... };

Register handlers which is called if a message matches regexp. (Only when you received a message from 1:1 chat)

$chatmessage is L<Skype::Any::Object::ChatMessage> object, @match is subgroups in regexp.

  respond 'yes'     => sub { $_[0]->chat->send_message('no') },
          'stop'    => sub { $_[0]->chat->send_message('go go go') },
          'goodbye' => sub { $_[0]->chat->send_message('hello') };

=head2 hear

  hear qr/pattern/ => sub { my ($chatmessage, @match) = @_; ... };
  hear 'string' => sub { my ($chatmessage, @match) = @_; ... };

Register handlers which is called if a message matches regexp. (Only when you received a message from group chat)

$chatmessage is L<Skype::Any::Object::ChatMessage> object, @match is subgroups in regexp.

  hear qr/\A([0-9]{1,2}) : ([0-9]{1,2}) \s+ (.+)\z/xms => sub {
      my ($msg, $hour, $min, $reminder) = @_;
      ...
  };

=head2 run

  run;

Running event loop.

=head1 SEE ALSO

L<Skype::Any>

=cut
