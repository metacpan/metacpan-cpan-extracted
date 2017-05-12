package Plack::App::PubSubHubbub::Subscriber;
use strict;
use warnings;
use parent qw/Plack::Component/;

use URI;
use Plack::Request;
use Plack::Response;
use Plack::Util::Accessor qw( config on_ping on_verify );

use Plack::App::PubSubHubbub::Subscriber::Config;

our $VERSION = 0.2;

=head1 NAME

Plack::App::PubSubHubbub::Subscriber - PubSubHubbub subscriber implementation as a Plack App

=head1 SYNOPSIS

 use Plack::Builder;
 use Plack::App::PubSubHubbub::Subscriber;
 use Plack::App::PubSubHubbub::Subscriber::Config;
 use Plack::App::PubSubHubbub::Subscriber::Client;

 my $conf = Plack::App::PubSubHubbub::Subscriber::Config->new(
     callback => "http://example.tld:8081/callback",
     lease_seconds => 86400,
     verify => 'sync',
 );

 my $app = Plack::App::PubSubHubbub::Subscriber->new(
     config => $conf
     on_verify => sub {
         my ($topic, $token, $mode, $lease) = @_;
         ...
         return 1;
     },
     on_ping => sub {
         my ($content_type, $content, $token) = @_;
         print $content;
     },
 );

 my $client = Plack::App::PubSubHubbub::Subscriber::Client(
     config => $conf,
 );

 builder {
     mount $app->callback_path, $app;
     mount '/subscribe' => sub {
         ...
         $client->subscribe( $hub, $topic, $token );
         ...
     };
     mount '/unsubscribe' => sub {
         ...
         $client->unsubscribe( $hub, $topic, $token );
         ...
     };
 };

=head1 DESCRIPTION

PubSubHubbub subscriber implementation in the form of a Plack app
and a client. Originally developed for L<storyfindr.com|http://storyfindr.com>

=head2 $self->config( $conf )

Get/Set the L<Plack::App::PubSubHubbub::Subscriber::Config> object.
This same config object can be use to instanciate the client L<Plack::App::PubSubHubbub::Subscriber::Client>

=head2 $self->on_ping( sub { my ($content_type, $content, $token) = @_ } )

Triggered when a new ping is received, the parameters are the content type, the raw content, and the token in that order.
Note that the token is available only if the configuration flag C<token_in_path> is set (the default).
Also note that, in any case, the token is undef if you didn't use a token to (un)subcribe.
The return value is ignore.

=head2 $self->on_verify( sub { my ($topic, $token, $mode, $lease) = @_ } )

Triggered when a subscribe/unsubscribe request is received, the parameters are the topic, the token, the mode, and the number of seconds of the lease, in that order.
Note that the token is undef if you didn't use a token to (un)subcribe.
Given these parameters, this coderef must return 1 for verified, or 0 for rejected.

=head2 $self->callback_path

Return the path part of the callback URL. Useful for doing "mount $app->callback_path, $app;"

=cut

sub callback_path {
    my $self = shift;
    return URI->new($self->config->callback)->path;
}

sub call {
    my($self, $env) = @_;
    my $req = Plack::Request->new($env);
    my $token = $self->config->token_in_path ?
        extract_token($req) : undef;

    if ($req->method eq 'POST') {
        if (my $ping_cb = $self->on_ping) {
            $ping_cb->($req->content_type, $req->content, $token);
        }
        return success();
    }
    elsif ($req->method eq 'GET') {
        my $p = $req->parameters;
        my $mode = $p->{'hub.mode'}
            or return error_bad_request('hub.mode is missing');

        if ($mode eq 'subscribe' || $mode eq 'unsubscribe') {

            my $topic = $p->{'hub.topic'}
                or return error_bad_request('hub.topic is missing');
            my $challenge = $p->{'hub.challenge'}
                or return error_bad_request('hub.challenge is missing');
            my $lease = $p->{'hub.lease_seconds'}
                or return error_bad_request('hub.lease_seconds is missing');

            $token //= $p->{'hub.verify_token'};

            if ($self->on_verify->($topic, $token, $mode, $lease)) {
                return success_challenge($challenge);
            }
            else {
                return error_not_found();
            }
        }
        else {
            return error_bad_request('mode unknown');
        }
    }
    return error_bad_request('unsupported method');
}

sub extract_token {
    my ($req) = @_;
    my ($token) = $req->path =~ /^\/(.+)$/;
    return $token;
}

sub success {
    my $res = Plack::Response->new(200);
    return $res->finalize;
}

sub success_challenge {
    my ($challenge) = @_;
    my $res = Plack::Response->new(200);
    $res->body($challenge);
    return $res->finalize;
}

sub error_not_found {
    my ($challenge) = @_;
    return Plack::Response->new(404)->finalize;
}

sub error_bad_request {
    my ($msg) = @_;
    my $res = Plack::Response->new(400);
    $res->body($msg) if $msg;
    # TODO log
    print STDERR "ERROR: $msg\n";
    return $res->finalize;
}

=head1 LIMITATION

the "Authenticated Content Distribution" is not supported.

=head1 SEE ALSO

L<the specs|http://pubsubhubbub.googlecode.com/svn/trunk/pubsubhubbub-core-0.3.html>, L<Net::PubSubHubbub::Publisher>

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
