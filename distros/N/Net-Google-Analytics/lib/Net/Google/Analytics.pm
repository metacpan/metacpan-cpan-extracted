package Net::Google::Analytics;
$Net::Google::Analytics::VERSION = '3.05';
use strict;
use warnings;

# ABSTRACT: Simple interface to the Google Analytics Core Reporting API

use JSON;
use LWP::UserAgent;
use Net::Google::Analytics::Request;
use Net::Google::Analytics::Response;
use Net::Google::Analytics::Row;
use URI;

sub new {
    my $package = shift;

    my $self = bless({}, $package);

    return $self;
}

sub auth_params {
    my $self = shift;

    my $auth_params = $self->{auth_params} || [];

    if (@_) {
        $self->{auth_params} = [ @_ ];
    }

    return @$auth_params;
}

sub token {
    my ($self, $token) = @_;

    $self->{auth_params} = [
        Authorization => "$token->{token_type} $token->{access_token}",
    ];
}

sub user_agent {
    my $self = $_[0];

    my $ua = $self->{user_agent};

    if (@_ > 1) {
        $self->{user_agent} = $_[1];
    }
    elsif (!defined($ua)) {
        $ua = LWP::UserAgent->new();
        $self->{user_agent} = $ua;
    }

    return $ua;
}

sub new_request {
    my $self = shift;

    return Net::Google::Analytics::Request->new(@_);
}

sub _uri {
    my ($self, $req, $start_index, $max_results) = @_;

    my $service = $req->realtime ? 'realtime' : 'ga';
    my $uri = URI->new(
        "https://www.googleapis.com/analytics/v3/data/$service"
    );
    my @params;
    push(@params, 'start-index' => $start_index) if defined($start_index);
    push(@params, 'max-results' => $max_results) if defined($max_results);

    $uri->query_form(
        $req->_params,
        @params,
    );

    return $uri;
}

sub uri {
    my ($self, $req) = @_;

    return $self->_uri($req, $req->start_index, $req->max_results);
}

sub _retrieve_http {
    my ($self, $req, $start_index, $max_results) = @_;

    my $uri         = $self->_uri($req, $start_index, $max_results);
    my @auth_params = $self->auth_params;

    return $self->user_agent->get($uri->as_string, @auth_params);
}

sub retrieve_http {
    my ($self, $req) = @_;

    return $self->_retrieve_http($req, $req->start_index, $req->max_results);
}

sub _retrieve {
    my ($self, $req, $start_index, $max_results) = @_;

    my $http_res = $self->_retrieve_http($req, $start_index, $max_results);
    my $res = Net::Google::Analytics::Response->new;
    $res->code($http_res->code);
    $res->message($http_res->message);

    if (!$http_res->is_success) {
        $res->content($http_res->decoded_content);
        return $res;
    }

    my $json = from_json($http_res->decoded_content);
    $res->_parse_json($json);

    $res->start_index($start_index);
    $res->is_success(1);

    return $res;
}

sub retrieve {
    my ($self, $req) = @_;

    return $self->_retrieve($req, $req->start_index, $req->max_results);
}

sub retrieve_paged {
    my ($self, $req) = @_;

    my $start_index = $req->start_index;
    $start_index = 1 if !defined($start_index);
    my $remaining_items = $req->max_results;
    my $max_items_per_page = 10_000;
    my $res;

    while (!defined($remaining_items) || $remaining_items > 0) {
        my $max_results =
            defined($remaining_items) &&
            $remaining_items < $max_items_per_page ?
                $remaining_items : $max_items_per_page;

        my $page = $self->_retrieve($req, $start_index, $max_results);
        return $page if !$page->is_success;

        if (!defined($res)) {
            $res = $page;
        }
        else {
            push(@{ $res->rows }, @{ $page->rows });
        }

        my $num_items = @{ $page->rows };
        last if $num_items < $max_results;

        $remaining_items -= $num_items if defined($remaining_items);
        $start_index     += $num_items;
    }

    my $total_items = @{ $res->rows };
    $res->items_per_page($total_items);
    # The total result count of the first page isn't always accurate
    $res->total_results($total_items);

    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::Analytics - Simple interface to the Google Analytics Core Reporting API

=head1 VERSION

version 3.05

=head1 SYNOPSIS

    use Net::Google::Analytics;
    use Net::Google::Analytics::OAuth2;

    # Insert your numeric Analytics profile ID here. You can find it under
    # profile settings. DO NOT use your account or property ID (UA-nnnnnn).
    my $profile_id    = "1234567";

    # See GETTING STARTED for how to get a client id, client secret, and
    # refresh token
    my $client_id     = "123456789012.apps.googleusercontent.com";
    my $client_secret = "rAnDoMsEcReTrAnDoMsEcReT";
    my $refresh_token = "RaNdOmSeCrEtRaNdOmSeCrEt";

    my $analytics = Net::Google::Analytics->new;

    # Authenticate
    my $oauth = Net::Google::Analytics::OAuth2->new(
        client_id     => $client_id,
        client_secret => $client_secret,
    );
    my $token = $oauth->refresh_access_token($refresh_token);
    $analytics->token($token);

    # Build request
    my $req = $analytics->new_request(
        ids         => "ga:$profile_id",
        dimensions  => "ga:medium,ga:source",
        metrics     => "ga:bounces,ga:visits",
        filters     => "ga:medium==referral",
        sort        => "-ga:visits",
        start_date  => "2011-10-01",
        end_date    => "2011-10-31",
        max_results => 5,
    );

    # Send request
    my $res = $analytics->retrieve($req);
    die("GA error: " . $res->error_message) if !$res->is_success;

    # Print results

    print
        "Results: 1 - ", $res->num_rows,
        " of ", $res->total_results, "\n\n";

    for my $row (@{ $res->rows }) {
        print
            $row->get_source,  ": ",
            $row->get_visits,  " visits, ",
            $row->get_bounces, " bounces\n";
    }

    print
        "\nTotal: ",
        $res->totals("visits"),  " visits, ",
        $res->totals("bounces"), " bounces\n";

=head1 DESCRIPTION

This module provides a simple, straight-forward interface to the Google
Analytics Core Reporting API, Version 3.

See L<http://code.google.com/apis/analytics/docs/gdata/home.html>
for the complete API documentation.

B<WARNING:> This module is not API compatible with the 0.x releases which target
the legacy v2 API.

=head1 GETTING STARTED

This module uses Google Analytics' API from a single Google User Account.
This means you will need a Google account user that has (at least) read
access to the Google Analytics profile you want to query. What we'll do
is, through L<OAuth2|Net::Google::Analytics::OAuth2>, have that user
grant Analytics access to your Perl app.

First, you have to register your project through the
L<Google Developers Console|https://console.developers.google.com/>.

Next, on your project's API Manager page, go over to "credentials" and click
on the "I<Create credentials>" button. When the drop down menu appears,
click on "I<Help me choose>".

=for html <p>
<img src="https://raw.githubusercontent.com/nwellnhof/Net-Google-Analytics/master/doc_images/credentials-howto-1.png" alt="screenshot of Google's API Manager menu" />
</p>

Select "Analytics API" under "I<Which API are you using?>", and select
"Other UI (CLI)" under "I<Where will you be calling the API from?>". Finally,
when they ask you "I<What data will you be accessing?>", choose "User data".

=for html <p>
<img src="https://raw.githubusercontent.com/nwellnhof/Net-Google-Analytics/master/doc_images/credentials-howto-2.png" alt="screenshot of Google's API options" />
</p>

At the end of this process, you will receive a client id and a client
secret for your application in the API Manager Console.

The final step is to get a refresh token. This is required because OAuth
access is granted only for a limited time, and the refresh token allows your
app to renew that access whenever it needs.

You can obtain a refresh token for your application by running the following
script with your client id and secret:

    use Net::Google::Analytics::OAuth2;

    my $oauth = Net::Google::Analytics::OAuth2->new(
        client_id     => 'Your client id',
        client_secret => 'Your client secret',
    );

    $oauth->interactive;

The script will display a URL and prompt for a code. Visit the URL in a
browser and follow the directions to grant access to your application. You will
be shown the code that you should enter in the Perl script. Then the script
retrieves and prints a refresh token which can be used for non-interactive
access.

You also have to provide the view ID (formerly profile ID) of your Analytics
view with every request. You can find this decimal number under "Admin >
View Settings" in Google Analytics. Note that this ID is different from your
tracking ID of the form UA-nnnnnn-n. Prepend your view ID with "ga:" and
pass it as "ids" parameter to the request object.

The "ids", "metrics", "start_date", and "end_date" parameters are required for
every request.

For the exact parameter syntax and a list of supported dimensions and metrics
you should consult the Google API documentation.

=head1 CONSTRUCTOR

=head2 new

    my $analytics = Net::Google::Analytics->new;

The constructor doesn't take any arguments.

=head1 METHODS

=head2 auth_params

    $analytics->auth_params(@auth_params);

Set the raw authentication parameters as key/value pairs. These will we sent
as HTTP headers.

=head2 token

    $analytics->token($token);

Authenticate using a token returned from L<Net::Google::Analytics::OAuth2>.

=head2 new_request

    my $req = $analytics->new_request(param => $value, ...);

Creates and returns a new L<Net::Google::Analytics::Request> object.

=head2 retrieve

    my $res = $analytics->retrieve($req);

Sends the request. $req must be a L<Net::Google::Analytics::Request>
object. This method returns a L<Net::Google::Analytics::Response> object.

=head2 retrieve_http

    my $res = $analytics->retrieve_http($req);

Sends the request and returns an L<HTTP::Response> object. $req must be a
L<Net::Google::Analytics::Request> object.

=head2 retrieve_paged

    my $res = $analytics->retrieve_paged($req);

Works like C<retrieve> but works around the max-results limit. This
method concatenates the results of multiple requests if necessary.

=head2 uri

    my $uri = $analytics->uri($req);

Returns the URI of the request. $req must be a
L<Net::Google::Analytics::Request> object. This method returns a L<URI>
object.

=head2 user_agent

    $analytics->user_agent($ua);

Sets the L<LWP::UserAgent> object to use for HTTP(S) requests. You only
have to call this method if you want to provide your own user agent.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
