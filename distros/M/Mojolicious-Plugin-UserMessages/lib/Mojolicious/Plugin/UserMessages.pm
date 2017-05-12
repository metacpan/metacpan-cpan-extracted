package Mojolicious::Plugin::UserMessages;
{
  $Mojolicious::Plugin::UserMessages::VERSION = '0.511';
}

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::UserMessages::Queue;

sub register {
    my ($self, $app) = @_;

    $app->helper( 
        'user_messages' => sub { 
              return Mojolicious::Plugin::UserMessages::Queue->new( $_[0] ); 
    }); 
}

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::UserMessages - Mojolicious Plugin to manage user message queue(s)

=head1 SYNOPSIS

 # Mojolicious Lite
 plugin 'UserMessages'
 
 # Mojolicious 
 $self->plugin('UserMessages')

 # In your code add some messages to the user
 $self->user_messages( info    => 'Just some information' );
 $self->user_messages( success => 'Operation completed' );

 # In your template get and print the messages
 # The messages will stay in the queue until you show them 
 #  to the user

 %  for my $message ( user_messages->get ) {
    <div><%= $message->type %> : <%= $message->message %></div>
 %  }

 # You can also get messages from a specific type
 %  for my $message ( user_messages->get_info ) {
     <div>INFO : <%= $message->message %></div>
 %  }
  
=head1 DESCRIPTION

L<Mojolicous::Plugin::UserMessages> implements a message queue to the user.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Mojolicious::Lite>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Bruno Tavares. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
