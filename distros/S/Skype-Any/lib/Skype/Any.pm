package Skype::Any;
use strict;
use warnings;
use 5.008001;

our $VERSION = '0.06';

use Module::Runtime qw/use_module/;

our %OBJECT = (
    USER         => 'User',
    CALL         => 'Call',
    MESSAGE      => 'Message',
    CHAT         => 'Chat',
    CHATMEMBER   => 'ChatMember',
    CHATMESSAGE  => 'ChatMessage',
    VOICEMAIL    => 'VoiceMail',
    SMS          => 'SMS',
    APPLICATION  => 'Application',
    GROUP        => 'Group',
    FILETRANSFER => 'FileTransfer',
);

sub new {
    my ($class, %args) = @_;
    return bless {
        name      => __PACKAGE__,
        protocol  => 8,
        api_class => "Skype::Any::API::$^O",
        %args,
    }, $class;
}

sub api {
    my $self = shift;
    unless (defined $self->{api}) {
        my $api = use_module($self->{api_class})->new(skype => $self);
        $self->{api} = $api;
    }
    return $self->{api};
}

sub handler {
    my $self = shift;
    unless (defined $self->{handler}) {
        require Skype::Any::Handler;
        $self->{handler} = Skype::Any::Handler->new();
    }
    return $self->{handler};
}

sub attach { $_[0]->api->attach }
sub run    { $_[0]->api->run }

sub object {
    my ($self, $object, $args) = @_;
    $object = uc $object;
    if (exists $OBJECT{$object}) {
        return $self->_create_object($OBJECT{$object}, $args);
    }
}

sub _object {
    my ($self, $object, @args) = @_;
    if (@args <= 1) {
        if (ref $args[0] eq 'CODE') {
            # Register default (_) handler
            $self->_register_handler($object, $args[0]);
        } else {
            $self->_create_object($object, $args[0]);
        }
    } else {
        $self->_register_handler($object, {@args});
    }
}

sub _register_handler {
    my ($self, $object, $args) = @_;
    $self->handler->register(uc $object, $args);
}

sub _create_object {
    my ($self, $object, $args) = @_;
    return use_module("Skype::Any::Object::$object")->new(
        skype => $self,
        (defined $args ? (id => $args) : ()),
    );
}

sub user         { shift->_object('User', @_) }
sub profile      { shift->_object('Profile', @_) }
sub call         { shift->_object('Call', @_) }
sub message      { shift->_object('Message', @_) }
sub chat         { shift->_object('Chat', @_) }
sub chatmember   { shift->_object('ChatMember', @_) }
sub chatmessage  { shift->_object('ChatMessage', @_) }
sub voicemail    { shift->_object('VoiceMail', @_) }
sub sms          { shift->_object('SMS', @_) }
sub application  { shift->_object('Application', @_) }
sub group        { shift->_object('Group', @_) }
sub filetransfer { shift->_object('FileTransfer', @_) }

sub message_received {
    my ($self, $code) = @_;
    my $wrapped_code = sub {
        my ($chatmessage, $status) = @_;
        if ($status eq 'RECEIVED') {
            $code->($chatmessage);
        }
    };
    $self->handler->register(CHATMESSAGE => {
        STATUS => $wrapped_code,
    });
}

sub create_chat_with {
    my ($self, $username, $message) = @_;
    return $self->user($username)->chat->send_message($message);
}

1;
__END__

=head1 NAME

Skype::Any - Skype API wrapper for Perl

=head1 SYNOPSIS

  use Skype::Any;

  # ping-pong bot

  my $skype = Skype::Any->new();
  $skype->message_received(sub {
      my ($msg) = @_;
      my $body = $msg->body;
      if ($body eq 'ping') {
          $msg->chat->send_message('pong');
      }
  });
  $skype->run;

=head2 STARTING

=over 4

=item 1. Start Skype

If you can use Skype API, you have to start Skype.

=item 2. Allow API access

When you start the script using Skype::Any, "Skype API Security" dialog will open automatically. Select "Allow this application to use Skype".

=begin html

<div><img src="https://raw.github.com/akiym/Skype-Any/master/img/dialog.png" /></div>

=end html

=item 3. Manage API access

You can set the name of your application.

  my $skype = Skype::Any->new(
      name => 'MyApp',
  );

=begin html

<div><img src="https://raw.github.com/akiym/Skype-Any/master/img/myapp-dialog.png" /></div>

=end html

You can manage your application and select allow/disallow API access.

=begin html

<div><img src="https://raw.github.com/akiym/Skype-Any/master/img/manage.png" /></div>

=end html

It described with Mac, but you can do the same with Linux.

=back

=head1 DESCRIPTION

Skype::Any is Skype API wrapper. It was inspired by Skype4Py.

Note that Skype::Any is using Skype Desktop API. However, Skype Desktop API will stop working in December 2013. You can not use lastest version of Skype.

=head1 METHODS

=over 4

=item C<< my $skype = Skype::Any->new() >>

Create an instance of Skype::Any.

=over 4

=item name => 'Skype::Any' : Str

Name of your application. This name will be shown to the user, when your application uses Skype.

=item protocol => 8 : Num

Skype protocol number.

=back

=item C<< $skype->attach() >>

Attach to Skype. However, you need not call this method. When you call C<< $skype->run() >>, it will be attach to Skype automatically.

If you want to manage event loop, you have to call this method. e.g. running with Twiggy:

  $skype->attach;

  my $twiggy = Twiggy::Server->new(
      host => $http_host,
      port => $http_port,
  );
  $twiggy->register_service($app);

  $skype->run;

=item C<< $skype->run() >>

Running an event loop. You have to call this method at the end.

=item C<< $skype->message_received(sub { ... }) >>

  $skype->message_received(sub {
    my ($chatmessage) = @_;

    ...
  });

Register 'chatmessage' handler for when a chat message is coming.

=item C<< $skype->create_chat_with($username, $message) >>

Send a $message to $username.

Alias for:

  $skype->user($username)->chat->send_message($message);

=back

=head2 OBJECTS

=over 4

=item C<< $skype->user($id) >>

Create new instance of L<Skype::Any::Object::User>.

  $skype->user(sub { ... })

Register _ (default) handler.

  $skype->user($name => sub { ... }, ...)

Register $name handler.

  $skype->user($id);
  $skype->user(sub {
  });
  $skype->user($name => sub {
  });

this code similar to:

  $skype->object(user => $id);
  $skype->object(user => sub {
  });
  $skype->object(user => $name => sub {
  });

C<< $skype->profile >>, C<< $skype->call >>, ..., these methods are the same operation.

=item C<< $skype->profile() >>

Note that this method takes no argument. Profile object doesn't have id.

L<Skype::Any::Object::Profile>

=item C<< $skype->call() >>

L<Skype::Any::Object::Call>

=item C<< $skype->message() >>

Deprecated in Skype protocol 3. Use C<Skype::Any::Object::ChatMessage>.

L<Skype::Any::Object::Message>

=item C<< $skype->chat() >>

L<Skype::Any::Object::Chat>

=item C<< $skype->chatmember() >>

L<Skype::Any::Object::ChatMember>

=item C<< $skype->chatmessage() >>

L<Skype::Any::Object::ChatMessage>

=item C<< $skype->voicemail() >>

L<Skype::Any::Object::VoiceMail>

=item C<< $skype->sms() >>

L<Skype::Any::Object::SMS>

=item C<< $skype->application() >>

L<Skype::Any::Object::Application>

=item C<< $skype->group() >>

L<Skype::Any::Object::Group>

=item C<< $skype->filetransfer() >>

L<Skype::Any::Object::FileTransfer>

=back

=head2 ATTRIBUTES

=over 4

=item C<< $skype->api >>

Instance of L<Skype::Any::API>. You can call Skype API directly. e.g. send "Happy new year!" to all recent chats.

  my $reply = $skype->api->send_command('SEARCH RECENTCHATS')->reply;
  $reply =~ s/^CHATS\s+//;
  for my $chatname (split /,\s+/ $reply) {
      my $chat = $skype->chat($chatname);
      $chat->send_message('Happy new year!");
  }

=item C<< $skype->handler >>

Instance of L<Skype::Any::Handler>. You can also register a handler:

  $skype->handler->register($name, sub { ... });

=back

=head1 SUPPORTS

Skype::Any working on Mac and Linux. But it doesn't support Windows. Patches welcome.

=head1 SEE ALSO

L<Public API Reference|https://developer.skype.com/public-api-reference>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
