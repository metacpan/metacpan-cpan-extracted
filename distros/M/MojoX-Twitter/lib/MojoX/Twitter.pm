package MojoX::Twitter;

use strict;
use warnings;
use v5.10;
use Carp qw/croak/;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON 'j';
use Digest::SHA 'hmac_sha1';
use MIME::Base64 'encode_base64';
use URI::Escape 'uri_escape_utf8';

our $VERSION = '0.06';

has 'ua' => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name("MojoX-Twitter $VERSION");
    return $ua;
};

has 'consumer_key';
has 'consumer_secret';
has 'access_token';
has 'access_token_secret';

sub request {
    my ($self, $method, $command, $params) = @_;

    $command = '/' . $command if $command !~ m{^/};
    my $url = "https://api.twitter.com/1.1" . $command . ".json";

    my $auth_str = $self->__build_auth_header($method, $url, $params);

    my @extra;
    if ($method eq 'GET') {
        my $uri = Mojo::URL->new($url);
        $uri->query($params);
        $url = $uri->to_string();
    } elsif ($method eq 'POST') {
        @extra = (form => $params);
    }

    my $tx = $self->ua->build_tx($method => $url => { Authorization => "OAuth $auth_str" } => @extra );
    $tx = $self->ua->start($tx);

    my $remaing = $tx->res->headers->header('X-Rate-Limit-Remaining');
    if (defined $remaing and $remaing < 1) {
        my $sleep = $tx->res->headers->header('X-Rate-Limit-Reset') - time();
        sleep $sleep; # wait until limit reset
    }

    if (my $res = $tx->success) {
        # check Rate Limit
        # print Dumper(\$res); use Data::Dumper;

        return $res->json;
    } else {
        my $err = $tx->error;

        # for 429 response: Too Many Requests
        if ( ($err->{code} || 0) == 429 ) {
            return $self->request($method, $command, $params); # REDO
        }

        croak "$err->{code} response: $err->{message}" if $err->{code};
        croak "Connection error: $err->{message}";
    }
}

sub streaming {
    my ($self, $url, $params, $callback) = @_;

    my $auth_str = $self->__build_auth_header('GET', $url, $params);

    if ($params) {
        my $uri = Mojo::URL->new($url);
        $uri->query($params);
        $url = $uri->to_string();
    }

    # The Streaming API will send a keep-alive newline every 30 seconds
    # to prevent your application from timing out the connection.
    $self->ua->inactivity_timeout(61);

    my $tx = $self->ua->build_tx(GET => $url => {
        Authorization => "OAuth $auth_str"
    });
    $tx->res->max_message_size(0);

    # Replace "read" events to disable default content parser
    my $input;
    $tx->res->content->unsubscribe('read')->on(read => sub {
        my ($content, $bytes) = @_;

        # https://dev.twitter.com/streaming/overview/processing
        # The body of a streaming API response consists of a series of newline-delimited messages, where “newline” is considered to be \r\n (in hex, 0x0D 0x0A) and “message” is a JSON encoded data structure or a blank line.
        $input .= $bytes;
        while ($input =~ s/^(.*?)\r\n//) {
            my ($json_raw) = $1;
            if (length($json_raw)) {
                $callback->(j($json_raw));
            }
        }
    });

    # Process transaction
    $self->ua->start($tx);
}

sub __build_auth_header {
    my ($self, $method, $url, $params) = @_;

    my ($consumer_key, $consumer_secret, $access_token, $access_token_secret) =
        ($self->consumer_key, $self->consumer_secret, $self->access_token, $self->access_token_secret);

    croak 'consumer_key, consumer_secret, access_token and access_token_secret are all required'
        unless $consumer_key and $consumer_secret and $access_token and $access_token_secret;

    my %oauth_params = (
        oauth_consumer_key => $consumer_key,
        oauth_nonce => __nonce(),
        oauth_signature_method => 'HMAC-SHA1',
        oauth_timestamp => time(),
        oauth_token   => $access_token,
        oauth_version => '1.0',
    );

    ## sign
    my %params = ( %{$params || {}}, %oauth_params );
    my $params_str = join('&', map { $_ . '=' . uri_escape_utf8($params{$_}) } sort keys %params);
    my $base_str = uc($method) . '&' . uri_escape_utf8($url) . '&' . uri_escape_utf8($params_str);
    my $signing_key = uri_escape_utf8($consumer_secret) . '&' . uri_escape_utf8($access_token_secret);
    my $sign = encode_base64(hmac_sha1($base_str, $signing_key), '');

    $oauth_params{oauth_signature} = $sign;
    return join ', ', map { $_ . '="' . uri_escape_utf8($oauth_params{$_}) . '"' } sort keys %oauth_params;
}

sub __nonce {
    return time ^ $$ ^ int(rand 2**32);
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Twitter - Simple Twitter Client

=head1 SYNOPSIS

  use MojoX::Twitter;

    my $twitter = MojoX::Twitter->new(
        consumer_key    => 'x',
        consumer_secret => 'z',
        access_token        => '1-z',
        access_token_secret => 'x',
    );

    my $users = $twitter->request('GET', 'users/show', { screen_name => 'support' });

    ## streaming
    $twitter->streaming('https://userstream.twitter.com/1.1/user.json', { with => 'followings' }, sub {
        my ($tweet) = @_;
        say Dumper(\$tweet);
    });

=head1 DESCRIPTION

MojoX::Twitter is a simple Twitter client:

=over 4

=item * without OAuth authentication

=item * auto sleep when X-Rate-Limit-Remaining is 0

=back

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
