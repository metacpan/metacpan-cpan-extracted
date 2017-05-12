package Plack::App::PubSubHubbub::Subscriber::Client;
use strict;
use warnings;

use URI;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;

use Plack::App::PubSubHubbub::Subscriber::Client;

=head1 NAME

Plack::App::PubSubHubbub::Subscriber::Client

=head1 SYNOPSIS

 my $client = Plack::App::PubSubHubbub::Subscriber::Client(
     config => $conf,
 );

 my $result = $client->subscribe( $hub, $topic, $token );
 ...

=head2 $class->new( config => $conf )

Take a L<Plack::App::PubSubHubbub::Subscriber::Client> object as parmeter,
ideally the same config used for the Plack App.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
    $self->{config} = $args{config}
        or die "config required";
    return $self;
}

sub config { $_[0]->{config} }

=head2 $self->ua( $user_agent )

Can be used to set the user agent, by default return an L<LWP::UserAgent> object.

=cut

sub ua {
    my $self = shift;
    my ($ua) = @_;
    $self->{__ua} = $ua if $ua;
    $self->{__ua} ||= LWP::UserAgent->new;
    return $self->{__ua};
}

sub _inject_token {
    my ($url, $token) = @_;
    $url = URI->new($url);
    my $path = $url->path;
    $path =~ s/\/$//;
    $url->path($path.'/'.$token);
    return $url->as_string;
}

sub _request {
    my $self = shift;
    my ($hub, $feed, $token, $mode) = @_;

    my %params = (
        "hub.callback"      => $self->config->callback,
        "hub.mode"          => $mode,
        "hub.topic"         => $feed,
        "hub.verify"        => $self->config->verify,
    );

    if (defined $self->config->lease_seconds) {
        $params{"hub.lease_seconds"} = $self->config->lease_seconds;
    }

    if ($token) {
        if ($self->config->token_in_path) {
            # overwrite the callback
            $params{"hub.callback"} = _inject_token($self->config->callback, $token);
        }
        else {
            $params{"hub.verify_token"} = $token;
        }
    }

    my $url = URI->new('http:');
    $url->query_form(%params);
    my $content = $url->query;

    my $req = HTTP::Request->new(POST => $hub, );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($content);
    return $req;
}

=head2 $self->subscribe_request( $hub, $feed, $token )

Prepare and return the subscribe request (L<HTTP::Request> object)
Note that it does not run the request, this is useful
if you want to run the request yourself, in an event
loop client for example.

=cut

sub subscribe_request {
    my $self = shift;
    my ($hub, $feed, $token) = @_;
    return $self->_request($hub, $feed, $token, 'subscribe');
}

=head2 $self->subscribe( $hub, $feed, $token )

Build the request using 'subscribe_request' and run it.
Return { success => 'verified' } if the subscription is active.
Return { success => 'tobeverified' } in case of async verification.
Return { error => $msg } in case of error.

=cut

sub subscribe {
    my $self = shift;
    my $req = $self->subscribe_request(@_);
    my $res = $self->ua->request($req);
    if ($res->code == 204) {
        return { success => 'verified' };
    }
    elsif ($res->code == 202) {
        return { success => 'tobeverified' };
    }
    else {
        return { success => '', error => $res->content };
    }
}

=head2 $self->unsubscribe_request( $hub, $feed, $token )

Same as subscribe_request but for unsubscribe.

=cut

sub unsubscribe_request {
    my $self = shift;
    my ($hub, $feed, $token) = @_;
    return $self->_request($hub, $feed, $token, 'unsubscribe');
}

=head2 $self->unsubscribe( $hub, $feed, $token )

Same as subscribe but for unsubscribe.

=cut

sub unsubscribe {
    my $self = shift;
    my $req = $self->unsubscribe_request(@_);
    my $res = $self->ua->request($req);
    if ($res->code == 204) {
        return { success => 'verified' };
    }
    elsif ($res->code == 202) {
        return { success => 'tobeverified' };
    }
    else {
        return { success => '', error => $res->content };
    }
}

1;
