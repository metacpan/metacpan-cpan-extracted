package Net::Matrix::Webhook;

# ABSTRACT: A http->matrix webhook
our $VERSION = '0.901'; # VERSION

use strict;
use warnings;
use 5.010;

use Net::Async::HTTP::Server::PSGI;
use Net::Async::Matrix;
use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use IO::Async::SSL;
use Plack::Request;
use Plack::Response;
use Digest::SHA1 qw(sha1_hex);
use Encode;
use Log::Any qw($log);

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(
    matrix_home_server matrix_room matrix_user matrix_password
    http_port
    secret
));

binmode( STDOUT, ':utf8' );

sub run {
    my $self = shift;

    my $loop = IO::Async::Loop->new;

    my $matrix = Net::Async::Matrix->new(
        server => $self->matrix_home_server,
        SSL    => 1,
    );
    $loop->add($matrix);

    $matrix->login(
        user_id  => $self->matrix_user,
        password => $self->matrix_password,
    )->get;
    $log->infof( "Logged in as %s at %s", $self->matrix_user, $self->matrix_home_server );
    my $room = $matrix->join_room( $self->matrix_room )->get;
    $log->infof( "Joined room %s", $room->name );

    my $httpserver = Net::Async::HTTP::Server::PSGI->new(
        app => sub {
            my $env = shift;
            my $req = Plack::Request->new($env);

            my $params = $req->parameters;
            my $msg    = decode_utf8( $params->{message} );
            if ( $self->secret ) {
                my $token = $params->{token};
                my $check = sha1_hex( encode_utf8($msg), $self->secret );
                if ( !$token || ( $token ne $check ) ) {
                    return Plack::Response->new( 401, undef, 'bad token' )->finalize;
                }
            }
            $log->debugf( "got message >%s<", $msg );

            eval { $room->send_message($msg)->get };
            if ($@) {
                return Plack::Response->new( 500, undef, $@ )->finalize;
            }
            return Plack::Response->new( 200, undef, 'message posted to matrix' )->finalize;
        }
    );
    $loop->add($httpserver);

    $httpserver->listen(
        addr => { family => "inet", socktype => "stream", port => $self->http_port }, )->get;

    $log->infof( "Started http server at http://localhost:%s", $self->http_port );

    $loop->run;
}

q{ listening to: Antibalas - Fu Chronicles };

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Matrix::Webhook - A http->matrix webhook

=head1 VERSION

version 0.901

=head1 SYNOPSIS

  Net::Matrix::Webhook->new({
    matrix_home_server => 'matrix.example.com',
    matrix_user        => 'your-bot',
    matrix_password    => '12345',
    http_port          => '8765', # = default
  })->run;

  # or use the wrapper script http2matix.pl included in this distribution
  http2matrix.pl --matrix_home_server matrix.example.com --matrix_user your-bot --matrix_password 12345

  # Then send your requests
  curl http://localhost:8765/?message=hello%2C%20world%21

=head1 DESCRIPTION

L[matrix|https://matrix.org/] is an open network for secure, decentralized communication. A bit like IRC, but less 90ies.

C<Net::Matrix::Webhook> implements a webhook, so you can easily post messages to your matrix chat rooms via HTTP requests. It uses L<IO::Async> to start a web server and connect as a client to matrix. It will then forward your messages.

Per default, everybody can now post to this endpoint. If you want to add a tiny bit of "security", you can pass a C<secret> to C<Net::Matrix::Webhook>. If you do this, you will also have to send a C<token> consisting of a C<sha1_hex> of the message and the secret:

  my $token = sha1_hex( encode_utf8($msg), $secret );
  request('http://localhost:8765/?message=hello%2C%20world%21&token='.$token);

=head1 OPTIONS

If you use L<http2matrix>, you can pass the options either via the commandline as C<--option> or via ENV as C<OPTION>, for example C<--matrix_home_server matrix.example.com> or C<MATRIX_HOME_SERVER=matrix.example.com>

=head2 matrix_home_server

Required.

The hostname of your matrix home server. Without the protocol!

=head2 matrix_room

Required. Example: C<#dev:example.net>

The room you want the bot to join. The bot-user has to be invited to this room.

To get the room address, use L<riot>, go to the "room settings" and find the "main address" in "published addresses". You might need to set it first via "local address" - "add".

=head2 matrix_user

Required.

The user name of your bot. You will have to set up an account for this user on your matrix home server.

=head2 matrix_password

Required.

The password of your bot.

=head2 http_port

Optional. Default: 8765

The HTTP port the webserver will use.

=head2 secret

Optional.

A shared secret to calculate / validate the optional C<token> parameter, for a little bit of "security".

=head1 OUTPUT

Output happens via C<Log::Any>.

If you use L<http2matrix.pl>, you can use  environment vars C<LOGADAPTER> and C<LOGLEVEL> to finetune the output.

=head1 SEE ALSO

=over

=item * L<https://matrix.org/>

=item * L<Net::Async::Matrix>

=back

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|https://www.validad.com/> for supporting Open Source.

=back

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
