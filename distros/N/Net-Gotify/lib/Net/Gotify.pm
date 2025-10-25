package Net::Gotify;

use 5.010000;
use strict;
use warnings;
use utf8;

use Carp();
use Moo;
use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);

use Net::Gotify::Application;
use Net::Gotify::Client;
use Net::Gotify::Error;
use Net::Gotify::Message;
use Net::Gotify::Plugin;
use Net::Gotify::User;

our $VERSION = '1.00';

$Carp::Internal{(__PACKAGE__)}++;

has base_url     => (is => 'ro', required => 1);
has app_token    => (is => 'ro');
has client_token => (is => 'ro');
has verify_ssl   => (is => 'ro');
has logger       => (is => 'ro');

sub _get_token {

    my ($self, $type) = @_;

    my $token = undef;

    if (lc($type) eq 'app') {
        $token = $self->app_token or Carp::croak 'Missing "app" token';
    }

    if (lc($type) eq 'client') {
        $token = $self->client_token or Carp::croak 'Missing "client" token';
    }

    return $token;
}

sub _hash_to_snake_case {

    my $hash   = shift;
    my $output = {};

    foreach my $key (keys %{$hash}) {
        (my $snake_key = $key) =~ s/([a-z0-9])([A-Z])/$1_\L$2/g;
        $output->{lc($snake_key)} = $hash->{$key};
    }

    return $output;

}

sub request {

    my ($self, %params) = @_;

    my $method     = delete $params{method} or Carp::croak 'Specify request "method"';
    my $token_type = delete $params{token_type} || 'client';
    my $path       = delete $params{path} or Carp::croak 'Specify request "path"';
    my $data       = delete $params{data} || {};
    my $options    = {};

    $method = uc $method;
    $path =~ s{^/}{};

    (my $agent = ref $self) =~ s{::}{-}g;

    my $ua = HTTP::Tiny->new(
        verify_SSL      => $self->verify_ssl,
        default_headers => {'Content-Type' => 'application/json', 'X-Gotify-Key' => $self->_get_token($token_type)},
        agent           => sprintf('%s/%s', $agent, $self->VERSION),
    );

    my $url = sprintf '%s/%s', $self->base_url, $path;

    if (ref $data eq 'HASH') {
        delete @$data{grep { not defined $data->{$_} } keys %{$data}};
        $options = {content => encode_json($data)};
    }

    my $response = $ua->request($method, $url, $options);

    if (my $logger = $self->logger) {
        $logger->info(sprintf('%s %s', $method, $url));
        $logger->debug(sprintf('[%s %s] %s', $response->{status}, $response->{reason}, $response->{content}));
    }

    my $output = eval { decode_json($response->{content}) } || {};

    if (!$response->{success}) {

        my $error = Net::Gotify::Error->new(
            error       => $output->{error}            || $response->{reason},
            code        => $output->{errorCode}        || $response->{status},
            description => $output->{errorDescription} || $response->{content},
        );

        if (my $logger = $self->logger) {
            $logger->error($error->description);
        }

        Carp::croak $error;

    }

    return $output;

}


# Messages

sub create_message {

    my ($self, %params) = @_;

    my $title    = delete $params{title};
    my $message  = delete $params{message} or Carp::croak 'Specify "message"';
    my $priority = delete $params{priority};
    my $extras   = delete $params{extras} || {};

    my $data = {title => $title, message => $message, priority => $priority, extras => $extras};

    my $response = $self->request(method => 'POST', path => '/message', data => $data, token_type => 'app');

    return Net::Gotify::Message->new(%{$response});

}

sub delete_message {

    my ($self, $id) = @_;

    Carp::croak 'Specify message "id"' unless $id;

    $self->request(method => 'DELETE', path => sprintf('/message/%s', $id));

    return 1;

}

sub delete_messages {

    my ($self, %params) = @_;

    my $app_id = delete $params{app_id};
    my $path   = $app_id ? sprintf('/application/%s/message', $app_id) : '/message';

    $self->request(method => 'DELETE', path => $path);

    return 1;

}

sub get_messages {

    my ($self, %params) = @_;

    my $app_id = delete $params{app_id};
    my $limit  = delete $params{limit} || 100;
    my $since  = delete $params{since};

    my $params = HTTP::Tiny->www_form_urlencode({limit => $limit, since => $since});
    my $path   = $app_id ? "/application/$app_id/message" : '/message';

    my $response = $self->request(method => 'GET', path => "$path?$params");

    my @messages = map { Net::Gotify::Message->new(%{$_}) } @{$response->{messages}};

    return wantarray ? @messages : \@messages;

}


# Clients

sub get_clients {

    my ($self) = @_;

    my $response = $self->request(method => 'GET', path => '/client');

    my @clients = map { Net::Gotify::Client->new(%{_hash_to_snake_case($_)}) } @{$response};

    return wantarray ? @clients : \@clients;

}

sub create_client {

    my ($self, %params) = @_;

    my $name = delete $params{name} or Carp::croak 'Specify client "name"';

    my $response = $self->request(method => 'POST', path => '/client', data => {name => $name});

    return Net::Gotify::Client->new(%{_hash_to_snake_case($response)});

}

sub update_client {

    my ($self, $id, %params) = @_;

    Carp::croak 'Specify client "id"' unless $id;

    my $name = delete $params{name} or Carp::croak 'Specify client "name"';

    my $response = $self->request(method => 'PUT', path => "/client/$id", data => {name => $name});

    return Net::Gotify::Client->new(%{_hash_to_snake_case($response)});

}

sub delete_client {

    my ($self, $id) = @_;

    Carp::croak 'Specify client "id"' unless $id;

    $self->request(method => 'DELETE', path => "/client/$id");
    return 1;

}


# Applications

sub get_applications {

    my ($self) = @_;

    my $response     = $self->request(method => 'GET', path => '/application');
    my @applications = map { Net::Gotify::Application->new(%{_hash_to_snake_case($_)}) } @{$response};

    return wantarray ? @applications : \@applications;

}

sub create_application {

    my ($self, %params) = @_;

    my $name             = delete $params{name} or Carp::croak 'Specify application "name"';
    my $description      = delete $params{description};
    my $default_priority = delete $params{default_priority} || 0;

    my $response = $self->request(
        method => 'POST',
        path   => '/application',
        data   => {name => $name, description => $description, default_priority => $default_priority}
    );

    return Net::Gotify::Application->new(%{_hash_to_snake_case($response)});

}

sub update_application {

    my ($self, $id, %params) = @_;

    my $name             = delete $params{name} or Carp::croak 'Specify application "name"';
    my $description      = delete $params{description};
    my $default_priority = delete $params{default_priority} || 0;

    my $response = $self->request(
        method => 'PUT',
        path   => "/application/$id",
        data   => {name => $name, description => $description, default_priority => $default_priority}
    );

    return Net::Gotify::Application->new(%{_hash_to_snake_case($response)});

}

sub delete_application {

    my ($self, $id) = @_;

    Carp::croak 'Specify application "id"' unless $id;

    $self->request(method => 'DELETE', path => "/application/$id");
    return 1;

}

sub update_application_image { Carp::carp 'Method not implemented' }
sub delete_application_image { Carp::carp 'Method not implemented' }


# Plugins

sub get_plugins {

    my ($self) = @_;

    my $response = $self->request(method => 'GET', path => '/plugin');
    my @plugins  = map { Net::Gotify::Plugin->new(%{_hash_to_snake_case($_)}) } @{$response};

    return wantarray ? @plugins : \@plugins;

}

sub get_plugin_config    { Carp::carp 'Method not implemented' }
sub update_plugin_config { Carp::carp 'Method not implemented' }

sub enable_plugin {

    my ($self, $id) = @_;

    Carp::croak 'Specify plugin "id"' unless $id;

    $self->request(method => 'POST', path => "/plugin/$id/enable");
    return 1;

}

sub disable_plugin {

    my ($self, $id) = @_;

    Carp::croak 'Specify plugin "id"' unless $id;

    $self->request(method => 'POST', path => "/plugin/$id/disable");
    return 1;

}

sub get_plugin { Carp::carp 'Method not implemented' }


# Users

sub current_user {

    my ($self) = @_;

    my $response = $self->request(method => 'GET', path => '/current/user');
    return Net::Gotify::User->new(%{_hash_to_snake_case($response)});

}

sub update_current_user_password {

    my ($self, $pass) = @_;

    Carp::croak 'Specify the new "password" for current user' unless $pass;

    my $response = $self->request(method => 'POST', path => '/current/user/password', data => {pass => $pass});

    return 1;

}

sub get_users {

    my ($self) = @_;

    my $response = $self->request(method => 'GET', path => '/user');
    my @users    = map { Net::Gotify::User->new(%{_hash_to_snake_case($_)}) } @{$response};

    return wantarray ? @users : \@users;

}

sub create_user {

    my ($self, %params) = @_;

    my $name  = delete $params{name}  or Carp::croak 'Specify user "name"';
    my $admin = delete $params{admin} or Carp::croak 'Specify user "admin" flag';
    my $pass  = delete $params{pass}  or Carp::croak 'Specify user "pass"';

    my $response
        = $self->request(method => 'POST', path => '/user', data => {name => $name, admin => $admin, pass => $pass});

    return Net::Gotify::User->new(%{_hash_to_snake_case($response)});

}

sub get_user {

    my ($self, $id) = @_;

    Carp::croak 'Specify user "id"' unless $id;

    my $response = $self->request(method => 'GET', path => "/user/$id");

    return Net::Gotify::User->new(%{_hash_to_snake_case($response)});

}

sub update_user {

    my ($self, $id, %params) = @_;

    Carp::croak 'Specify user "id"' unless $id;

    my $name  = delete $params{name}  or Carp::croak 'Specify user "name"';
    my $admin = delete $params{admin} or Carp::croak 'Specify user "admin" flag';
    my $pass  = delete $params{pass};

    my $response = $self->request(method => 'POST', path => "/user/$id",
        data => {name => $name, admin => $admin, pass => $pass});

    return Net::Gotify::User->new(%{_hash_to_snake_case($response)});

}

sub delete_user {

    my ($self, $id) = @_;

    Carp::croak 'Specify user "id"' unless $id;

    $self->request(method => 'DELETE', path => "/user/$id");
    return 1;

}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::Gotify - Gotify client for Perl

=head1 SYNOPSIS

  use Net::Gotify;

  my $gotify = Net::Gotify->new(
      base_url     => 'http://localhost:8088',
      app_token    => '<TOKEN>',
      client_token => '<TOKEN>',
      logger       => $logger
  );

  my $msg = eval {
    $gotify->create_message(
        title    => 'Backup',
        message  => '**Backup** was successfully finished.',
        priority => 2,
        extras   => {
            'client::display' => {contentType => 'text/markdown'}
        }
    )
  };

  if ($@) {
    say $@->description;
  }

  my @messages = $gotify->get_messages();

  foreach my $msg (@messages) {
    say sprintf "[#%d] %s\n%s", $msg->id, $msg->title, $msg->message;
  }

=head1 DESCRIPTION

L<Net::Gotify> allows you to interact with Gotify server via Perl.

L<https://gotify.net/>


=head2 Gotify API

=head3 B<new>

    $gotify = Net::Gotify->new( \%params );

Create a new instance of L<Net::Gotify>.

Parameters:

=over

=item * B<base_url>, Gotify base URL

=item * B<app_token>, Application token

=item * B<client_token>, Client token

=item * B<verify_ssl>, Enable SSL/TLS certificate check

=item * B<logger>, Logger instance (L<Log::Any>, L<Mojo::Log>, etc.)

=back

    my $gotify = Net::Gotify->new(
        base_url     => 'http://localhost:8088',
        app_token    => '<TOKEN>',
        client_token => '<TOKEN>',
        logger       => $logger
    );

=head3 B<request>

    $res = $gotify->request( \%params );

Send a RAW HTTP request to Gotify.

Parameters:

=over

=item * B<method>, Request method

=item * B<token_type>, Token type (default: C<client>)

=item * B<path>, Request path

=item * B<data>, Request data (HASH)

=item * B<options>, Request options (HASH)

=back

    $res = $gotify->request( method     => 'POST', path => '/message',
                             token_type => 'app',  data => \%data );


=head2 Message API

=head3 B<create_message>

    $message = $gotify->create_message( message  => $message );

    $message = $gotify->create_message( message  => $message,  title  => $title,
                                        priority => $priority, extras => \%extras );

Create a message and return the L<Net::Gotify::Message> object.

Pameters:

=over

=item * B<message>, Notify nessage (required)

=item * B<title>, Message title

=item * B<priority>, Message priority

=item * B<extras>, Message extras

=back

Simple notification:

    $gotify->create_message( message => 'Job completed!' );

Notification with title and markdown:

    $gotify->create_message(
        title    => 'Backup',
        message  => '**Backup** was successfully finished.',
        priority => 2,
        extras   => {
            'client::display' => {contentType => 'text/markdown'}
        }
    );

=head3 B<delete_message>

    $gotify->delete_message ( $message_id );

Delete a single message.

=head3 B<delete_messages>

    $gotify->delete_messages( \%params );

    $gotify->delete_messages( app_id => $application_id );

Delete all messages.

Parameters:

=over

=item * B<app_id>, Application ID

=back

=head3 B<get_messages>

    $array = $gotify->get_messages( \%params );

    $array = $gotify->get_messages( app_id => $application_id, 
                                    limit  => $limit,  since => $since );

Fetch all messages and return an ARRAY of L<Net::Gotify::Message> objects.

Parameters:

=over

=item * B<app_id>, Application ID

=item * B<limit>, Result limit (default: C<100>), the maximal amount of messages to return

=item * B<since>, return all messages with an ID less than this value

=back

    my @messages = $gotify->get_messages();

    foreach my $msg (@messages) {
        say sprintf "[#%d] %s\n%s", $msg->id, $msg->title, $msg->message;
    }


=head2 Client API

=head3 B<get_clients>

    $gotify->get_clients( );

Fetch all clients and return an array of L<Net::Gotify::Client> objects.

=head3 B<create_client>

    $gotify->create_client( \%params );

Create a client and return the L<Net::Gotify::Client> object.

Parameters:

=over

=item * B<name>, Client name (required)

=back

=head3 B<update_client>

    $gotify->update_client( $client_id, \%params );

Update a client and return the L<Net::Gotify::Client> object.

Parameters:

=over

=item * B<name>, Client name (required)

=back

=head3 B<delete_client>

    $gotify->delete_client( $client_id );

Delete a client.

=head2 Application API

=head3 B<get_applications>

    $gotify->get_applications( );

Fetch all applications and return an array of L<Net::Gotify::Application> objects.

=head3 B<create_application>

    $gotify->create_application( \%params );

Create an application and return the L<Net::Gotify::Application> object.

Parameters:

=over

=item * B<name>, Application name (required).

=item * B<description>, Application description.

=item * B<default_priority>, Default application priority (default: 0).

=back

=head3 B<update_application>

    $gotify->update_application( $app_id, \%params );

Update an application and return the L<Net::Gotify::Application> object.

=over

=item * B<name>, Application name (required).

=item * B<description>, Application description.

=item * B<default_priority>, Default application priority (default: 0).

=back

=head3 B<delete_application>

    $gotify->delete_application( $app_id );

Delete an application.

=head3 B<update_application_image>

TODO - Method not implemented.

=head3 B<delete_application_image>

TODO - Method not implemented.

=head2 Plugin API

=head3 B<get_plugins>

    $gotify->get_plugins( );

Fetch all plugins and return an array of L<Net::Gotify::Plugin> objects.

=head3 B<get_plugin_config>

TODO - Method not implemented.

=head3 B<update_plugin_config>

TODO - Method not implemented.

=head3 B<enable_plugin>

    $gotify->enable_plugin( );

Enable a plugin.

=head3 B<disable_plugin>

    $gotify->disable_plugin( );

Disable a plugin.

=head3 B<get_plugin>

TODO - Method not implemented.


=head2 User API

=head3 B<current_user>

    $gotify->current_user;

Return the current user and return L<Net::Gotify::User> object.

=head3 B<update_current_user_password>

    $gotify->update_current_user_password( $password );

Update the password of the current user.

=head3 B<get_users>

    $gotify->get_users ( \%params );

Fetch all users and return an ARRAY of L<Net::Gotify::User> objects.

=head3 B<create_user>

    $gotify->create_user( name => $name, pass => $pass, admin => $flag );

Create a user and return L<Net::Gotify::User> object.

Parameters:

=over

=item * B<name>, User name

=item * B<pass>, User password

=item * B<admin>, Admin flag

=back

=head3 B<get_user>

    $gotify->get_user( $user_id );

Get a user and return L<Net::Gotify::User> object.

=head3 B<update_user>


=head3 B<delete_user>

    $gotify->delete_user( $user_id );

Delete a user.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-Gotify/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-Gotify>

    git clone https://github.com/giterlizzi/perl-Net-Gotify.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
