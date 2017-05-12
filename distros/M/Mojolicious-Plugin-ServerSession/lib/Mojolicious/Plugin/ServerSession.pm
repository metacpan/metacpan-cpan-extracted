package Mojolicious::Plugin::ServerSession;

use 5.010000;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';


sub register {
  my ($self, $app, $conf) = (@_);
  $conf ||= {};

  my $key_name = $conf->{key} || "server_session_key";

  die ref($self), "Missing subref parameter load" unless(ref($conf->{load}) eq "CODE");
  die ref($self), "Missing subref parameter store" unless(ref($conf->{store}) eq "CODE");

  $app->plugins->on(before_dispatch => sub {
        my $this = shift;

        my $key = $this->session($key_name);
        my ($session_key, $session_data) = $conf->{load}->($this, $key);
        $this->stash( server_session => $session_data );
        $this->session( "$key_name" => $session_key );
  });

  $app->plugins->on(after_dispatch => sub {
        my $this = shift;

        my $key = $this->session($key_name);
        $conf->{store}->($this, $key, $this->stash('server_session'));
  });  

  $app->helper(
    server_session => sub {
      my ($self) = @_;

      return $self->stash('server_session');
    }
  );

}


1;
__END__

=head1 NAME

Mojolicious::Plugin::ServerSession - Perl extension to enable an additional server side session in mojolicious

=head1 SYNOPSIS

  #Basic example
  $self->plugin('ServerSession' => {
    key => "server_session_key",
    load => sub { 
      my ($c, $key) = @_;

      my $session_object = MySessionDataStore->find_or_create_by_key($key);

      return( $session_object->key, $session_object->session_hash_ref );
    },
    store => sub { 
      my ($c, $key, $session_hash) = @_;

      my $session_object = MySessionDataStore->find_by_key($key);
      $session_object->session_data($session_hash);
      $session_object->save();
    }
  });

  #Then to use in controller or views
  $c->server_session->{Some_key} = "Value"; #Note: Its just a hash ref for simplicity 


  #Real world example using DBIx::Class
  $app->plugin('ServerSession' => {
    key => "server_session_key",
    load => sub { 
      my ($c, $key) = @_;
      my $session_row;
      use JSON;

      unless($session_row = $c->app->schema->resultset('Session')->find($key)) {
        $session_row = $c->app->schema->resultset('Session')->new({ content => "{}" })->insert();
        $key = $session_row->id();
      }

      return( $key, decode_json($session_row->content));
    },
    store => sub { 
      my ($c, $key, $session_hash) = @_;
      use JSON;

      my $session = $c->app->schema->resultset('Session')->find($key);
      if($session) {
        $session->content( encode_json($session_hash) );
        $session->update();
      }
    }
  });


=head1 DESCRIPTION

This is a little plugin to add an additional session store to your mojolicious app. Useful if you need to store
more data than the cookie size of 4096 bytes will allow.

The existing mojo session is not touched, other than to add a key which is used to lookup data in your server side store.

You need to define two subrefs, one for loading and one for storing. The loading subref is expected to return two values, an ID and a 
hashref containing the server side session data. If the user is new the $key passed in will be undef.

In the DBIx::Class example I either find or create a row in the Session table when &load is called, and I also use JSON to serialise the 
hash.
In the store I simply look up the row, and set its contents to a JSON encoded string.


=head2 EXPORT

None.

=head1 SEE ALSO

https://github.com/benvanstaveren/Mojolicious-Plugin-Session does similar but tries to co-operate with the built in sessions.

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
