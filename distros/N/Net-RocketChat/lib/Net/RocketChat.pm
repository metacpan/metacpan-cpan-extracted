package Net::RocketChat;
# ABSTRACT: Implements the REST API for Rocket.Chat
$Net::RocketChat::VERSION = '0.002';
=head1 NAME

Net::RocketChat

=head1 SYNOPSIS

Implements the REST API for Rocket.Chat

=head1 USAGE

You can also specify the username, password and server in the environment variables ROCKETCHAT_USERNAME, ROCKETCHAT_PASSWORD and ROCKETCHAT_SERVER.

Most errors die.  Use eval generously.

   use Net::RocketChat;
   use YAML::XS;
   use strict;

   # specifying connection info directly
   my $chat = Net::RocketChat->new(username => $username, password => $password, server => 'https://your.server.here');
   # or use the environment
   $ENV{ROCKETCHAT_USERNAME} = $username;
   $ENV{ROCKETCHAT_PASSWORD} = $password;
   $ENV{ROCKETCHAT_SERVER} = $server;

   my $chat = Net::RocketChat->new;
   eval {
      $chat->login;
      $chat->join(room => "general");
      my $messages = $chat->messages(room => "general");
      print Dump($messages);
      $chat->send(room => "general",message => "your message goes here");
      $chat->send(room => "general",message => "```\nmulti-line\npastes\nare\nok```");
      $chat->leave(room => "general");
   };
   if ($@) {
      print "caught an error: $@\n";
   }

There are also example scripts in the distribution.

=cut

use Moose;
use Method::Signatures;
use LWP::UserAgent;
use JSON;
use YAML;

=head1 ATTRIBUTES

=over

=item debug

If debug is set, lots of stuff will get dumped to STDERR.

=cut

has 'debug' => (
   is => 'rw',
   default => 0,
);

=item username

If this isn't specified, defaults to $ENV{ROCKETCHAT_USERNAME}

=cut

has 'username' => (
   is => 'rw',
);

=item password

If this isn't specified, defaults to $ENV{ROCKETCHAT_PASSWORD}

=cut

has 'password' => (
   is => 'rw',
);

=item server

The URL for the server, ie. "https://rocketchat.your.domain.here"

If this isn't specified, defaults to $ENV{ROCKETCHAT_SERVER}

=cut

has 'server' => (
   is => 'rw',
);

=item response

Contains the last HTTP response from the server.

=cut

has 'response' => (
   is => 'rw',
);

has 'ua' => (
   is => 'rw',
);

has 'userId' => (
   is => 'rw',
);

has 'authToken' => (
   is => 'rw',
);

has 'rooms' => (
   is => 'rw',
   default => sub { {} },
);

=back

=cut

method BUILD($x) {
   $self->username or $self->username($ENV{ROCKETCHAT_USERNAME});
   $self->password or $self->password($ENV{ROCKETCHAT_PASSWORD});
   $self->server or $self->server($ENV{ROCKETCHAT_SERVER});
   $self->ua(LWP::UserAgent->new);
}

=head1 METHODS

=over

=cut

=item version

Returns a hashref of versions, currently of the API and server.

   "versions": {
      "api": "0.1",
      "rocketchat": "0.5"
   }

=cut

method version {
   $self->response($self->ua->get($self->server . "/api/version"));
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
   my $json = decode_json($self->response->content);
   return $json->{versions};
}

=item login

Logs in.

=cut

method login {
   $self->response($self->ua->post($self->server . "/api/login",{user => $self->username,password => $self->password}));
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
   my $json = decode_json($self->response->content);
   my $userId = $json->{data}{userId};
   my $authToken = $json->{data}{authToken};
   $self->userId($userId);
   $self->authToken($authToken);
}

=item logout

Logs out.

=cut

method logout {
   $self->get($self->server . "/api/logout");
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
}

=item publicRooms

Fetches a list of rooms, and also stores a mapping of names to ids for future use.  Returns the raw decoded JSON response from the server:

   my $rooms = $chat->publicRooms;

   rooms:
   - _id: GENERAL
     default: !!perl/scalar:JSON::PP::Boolean 1
     lm: 2016-04-30T16:45:32.876Z
     msgs: 54
     name: general
     t: c
     ts: 2016-04-30T04:29:53.361Z
     usernames:
     - someuser
     - someotheruser
   - _id: 8L4QMdEFCYqRH3MNP
     lm: 2016-04-30T21:08:27.760Z
     msgs: 2
     name: dev
     t: c
     ts: 2016-04-30T05:30:59.847Z
     u:
       _id: EBbKeYF9Gvppdhhwr
       username: someuser
     usernames:
     - someuser

=cut

method publicRooms {
   $self->get($self->server . "/api/publicRooms");
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
   my $rooms = decode_json($self->response->content);
   foreach my $room (@{$rooms->{rooms}}) {
      $self->{rooms}{$room->{name}}{id} = $room->{_id};
   }
   return $rooms;
}

=item has_room(:$room)

Returns 1 if a room exists on the server, 0 otherwise.

   if ($chat->has_room("general") {
      $chat->join(room => "general");
      $chat->send(room => "general", message => "Hello, world!");
   }
   else {
      ...
   }

=cut

method has_room(:$room) {
   eval {
      $self->get_room_id($room);
   };
   if ($@) {
      return 0;
   }
   else {
      return 1;
   }
}

=item join(:$room,:$room)

Joins a room.  Rooms have a human readable name and an id.  You can use either, but if the name isn't known it will automatically fetch a list of rooms.

   $chat->join(room => "general");

=cut

method join(:$id,:$room) {
   $id //= $self->get_room_id($room);
   $self->post($self->server . "/api/rooms/$id/join","{}");
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
}

=item leave(:$id,:$room)

Leaves a room, specified either by name or id.

   $chat->leave(room => "general");

=cut

method leave(:$id,:$room) {
   $id //= $self->get_room_id($room);
   $self->post($self->server . "/api/rooms/$id/leave","{}");
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
}

=item messages(:$room,:$id)

Gets all the messages from a room, specified either by name or id.

   my $messages = $chat->messages(room => "general");

=cut

method messages(:$id,:$room) {
   $id //= $self->get_room_id($room);
   $self->get($self->server . "/api/rooms/$id/messages");
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
   return decode_json($self->response->content);
}

=item send(:$room,:$id,:$message)

Sends a message to a room.

   $chat->send(room => "general", message => "Hello, world!");

=cut

method send(:$room,:$id,:$message) {
   $id //= $self->get_room_id($room);
   my $msg = {
      msg => $message,
   };
   $self->post($self->server . "/api/rooms/$id/send",encode_json($msg));
   if ($self->debug) {
      print STDERR Dump($self->response);
   }
   return 1;
}

# looks up a room's internal id or fetches from the server if it couldn't be found.  throws an exception if it's an invalid room name.
method get_room_id($room) {
   if (not exists $self->{rooms}{$room}) {
      print STDERR "couldn't find room $room, checking server\n" if ($self->debug);
      $self->publicRooms;
   }
   if (not exists $self->{rooms}{$room}) {
      die "invalid_room";
   }
   return $self->{rooms}{$room}{id};
}

# convenience method that stuffs in some authentication headers into a GET request
method get($url) {
   $self->response($self->ua->get($url,"X-Auth-Token" => $self->authToken, "X-User-Id" => $self->userId));
   $self->response->is_error and die "http_error";
}

# convenience method that stuffs in some authentication headers into a POST request
method post($url,$content) {
   $self->response($self->ua->post($url,"X-Auth-Token" => $self->authToken, "X-User-Id" => $self->userId, "Content-Type" => "application/json", Content => $content));
   $self->response->is_error and die "http_error";
}

=back

=head1 AUTHOR

Dale Evans, C<< <daleevans@github> >> http://devans.mycanadapayday.com

=head1 SEE ALSO

https://rocket.chat/docs/master/developer-guides/rest-api/

=cut

1;

