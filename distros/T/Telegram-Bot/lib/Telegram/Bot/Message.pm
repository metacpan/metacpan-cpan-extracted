package Telegram::Bot::Message;
$Telegram::Bot::Message::VERSION = '0.012';
# ABSTRACT: The base class for Telegram messages incoming to the bot

use Mojo::Base -base;
use Mojo::JSON qw/from_json/;

use Telegram::Bot::Object::User;
use Telegram::Bot::Object::UserOrGroup;
use Telegram::Bot::Object::Audio;
use Telegram::Bot::Object::Document;
use Telegram::Bot::Object::Video;
use Telegram::Bot::Object::Sticker;
use Telegram::Bot::Object::PhotoSize;
use Telegram::Bot::Object::Sticker;
use Telegram::Bot::Object::Contact;
use Telegram::Bot::Object::Location;

use Data::Dumper;

# basic message stuff
has 'message_id';
has 'from';
has 'date';
has 'chat';
has 'forward_from';
has 'forward_date';
has 'reply_to_message';


# the message might have several other optional parts
has 'text';
has 'audio';
has 'document';
has 'photo';
has 'sticker';
has 'video';
has 'contact';
has 'location';

has 'new_chat_participant';
has 'left_chat_participant';

sub fields {
  return {
          'scalar'                       => [qw/message_id date text forward_date/],
          'Telegram::Bot::Message'       => [qw/reply_to_message/],
          'Telegram::Bot::Object::User'  => [qw/from
                                                new_chat_participant left_chat_participant
                                                forward_from/],

          'Telegram::Bot::Object::UserOrGroup' => [qw/chat/],

          'Telegram::Bot::Object::Audio'      => [qw/audio/],
          'Telegram::Bot::Object::Document'   => [qw/document/],
          'Telegram::Bot::Object::PhotoSize'  => [qw/photo/],
          'Telegram::Bot::Object::Video'      => [qw/video/],
          'Telegram::Bot::Object::Sticker'    => [qw/sticker/],
          'Telegram::Bot::Object::Contact'    => [qw/contact/],
          'Telegram::Bot::Object::Location'   => [qw/location/],
  };
}

sub is_array { my $field = shift; return $field eq 'photo'; }

sub create_from_json {
  my $class = shift;
  my $json  = shift;
  my $hash  = from_json $json;
  return $class->create_from_hash($hash);
}

sub create_from_hash {
  my $class = shift;
  my $hash  = shift;
  my $msg   = $class->new;

  foreach my $k (keys %{ $class->fields }) {
    if ($k eq 'scalar') {
      foreach my $field (@{ $class->fields->{scalar} } ) {
        $msg->$field($hash->{$field});
      }
    }
    else {
      foreach my $field (@{ $class->fields->{$k} } ) {
        if (is_array($field)) {
          my @items;
          foreach my $item (@{ $hash->{$field} || [] }) {
            my $o = $k->create_from_hash($item)
              if defined $hash->{$field};
            push @items, $o;
          }
          $msg->$field(\@items);
        }
        else {
          my $o = $k->create_from_hash($hash->{$field})
            if defined $hash->{$field};
          $msg->$field($o);
        }
      }
    }
  }
  return $msg;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Message - The base class for Telegram messages incoming to the bot

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
