package Net::Google::WebmasterTools;
{
    $Net::Google::WebmasterTools::VERSION = '0.03';
}
use strict;

# ABSTRACT: Simple interface to the Google Search Console Core Reporting API

use JSON;
use LWP::UserAgent;
use Net::Google::WebmasterTools::Request;
use Net::Google::WebmasterTools::Response;
use Net::Google::WebmasterTools::Row;
use URI;

sub new {
    my $package = shift;

    my $self = bless( {}, $package );

    return $self;
}

sub auth_params {
    my $self = shift;

    my $auth_params = $self->{auth_params} || [];

    if (@_) {
        $self->{auth_params} = [@_];
    }

    return @$auth_params;
}

sub token {
    my ( $self, $token ) = @_;

    $self->{auth_params}
        = [ Authorization => "$token->{token_type} $token->{access_token}", ];
}

sub user_agent {
    my $self = $_[0];

    my $ua = $self->{user_agent};

    if ( @_ > 1 ) {
        $self->{user_agent} = $_[1];
    }
    elsif ( !defined($ua) ) {
        $ua = LWP::UserAgent->new();
        $self->{user_agent} = $ua;
    }

    return $ua;
}

sub new_request {
    my $self = shift;

    return Net::Google::WebmasterTools::Request->new(@_);
}

sub _uri {
    my ( $self, $req, $row_limit ) = @_;

    my $uri
        = URI->new( 'https://www.googleapis.com/webmasters/v3/sites/'
            . $req->site_url . '/'
            . $req->report_name . '/'
            . $req->method );
    if (   ( $req->report_name =~ m{^(?:sitemaps|urlCrawlErrorsSamples)$} )
        && ( $req->method eq 'list' ) )
    {
        $uri
            = URI->new( 'https://www.googleapis.com/webmasters/v3/sites/'
                . $req->site_url . '/'
                . $req->report_name );
    }
    elsif ( ( $req->report_name eq 'sites' ) && ( $req->method eq 'list' ) ) {
        $uri = URI->new('https://www.googleapis.com/webmasters/v3/sites');
    }
    return $uri;
}

sub uri {
    my ( $self, $req ) = @_;

    return $self->_uri( $req, $req->start_index, $req->row_limit );
}

sub _retrieve_http {
    my ( $self, $req, $start_index, $row_limit ) = @_;

    my $uri = $self->_uri( $req, $start_index, $row_limit );

    my $params      = $req;
    my @auth_params = $self->auth_params;

    my %params = $req->_params;
    my $json   = to_json( \%params );

    my $http_req = HTTP::Request->new( 'POST', $uri->as_string );
    $http_req->header(@auth_params);
    $http_req->header( 'Content-Type' => 'application/json' );
    $http_req->content($json);

    if ( ( $req->report_name eq 'sitemaps' ) && ( $req->method eq 'list' ) ) {
        $http_req = HTTP::Request->new( 'GET', $uri->as_string );
    }
    elsif ( ( $req->report_name eq 'sites' ) && ( $req->method eq 'list' ) ) {
        $http_req = HTTP::Request->new( 'GET', $uri->as_string );
    }

    return $self->user_agent->request($http_req);
}

sub retrieve_http {
    my ( $self, $req ) = @_;

    return $self->_retrieve_http( $req, $req->start_index, $req->row_limit );
}

sub _retrieve {
    my ( $self, $req, $start_index, $row_limit ) = @_;

    my $http_res = $self->_retrieve_http( $req, $start_index, $row_limit );
    my $res      = Net::Google::WebmasterTools::Response->new;
    $res->code( $http_res->code );
    $res->message( $http_res->message );

    if ( !$http_res->is_success ) {
        $res->content( $http_res->decoded_content );
        return $res;
    }

    my $json = from_json( $http_res->decoded_content );
    $res->_parse_json($json);

    $res->start_index($start_index);
    $res->is_success(1);

    return $res;
}

sub retrieve {
    my ( $self, $req ) = @_;

    return $self->_retrieve( $req, $req->start_index, $req->row_limit );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::WebmasterTools - Simple interface to the Google Webmaster Tools (Search Console) Core Reporting API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Net::Google::WebmasterTools;
    use Net::Google::WebmasterTools::OAuth2;

    # Insert your website URL here.
    my $site_url    = "http://www.example.com/";
    # See GETTING STARTED for how to get a client id, client secret, and
    # refresh token
    my $client_id     = "123456789012.apps.googleusercontent.com";
    my $client_secret = "rAnDoMsEcReTrAnDoMsEcReT";
    my $refresh_token = "RaNdOmSeCrEtRaNdOmSeCrEt";

    my $wmt = Net::Google::WebmasterTools->new;

    # Authenticate
    my $oauth = Net::Google::WebmasterTools::OAuth2->new(
        client_id     => $client_id,
        client_secret => $client_secret,
    );
    my $token = $oauth->refresh_access_token($refresh_token);
    $wmt->token($token);

    # Build request
    my $req = $wmt->new_request(
        site_url     => "$site_url",
        report_name  => "searchAnalytics",
        method       => "query",
        dimensions   => ['country','device'],
        search_type  => 'web',
        start_date   => "2019-05-01",
        end_date     => "2019-05-31",
        row_limit    => 1000,
    );

    # Send request
    my $res = $wmt->retrieve($req);
    die("GWMT error: " . $res->error_message) if !$res->is_success;

    # Print results

    for my $row (@{ $res->{'rows'} }) {
        print
            "Query: ", $row->{'keys'}->[0], "\n",
            Position: ", $row->{'position'},  " | ",
            Impressions: ", $row->{'impressions'},  " | ",
            Clicks: ", $row->{'clicks'},  " | ",
            CTR: ", $row->{'ctr'},  "\n---\n";
    }

=head1 DESCRIPTION

This module provides a simple, straight-forward interface to the Google
Webmaster Tools (Search Console) API, Version 3.

See L<https://developers.google.com/webmaster-tools/v3/parameters>
for the complete API documentation.

This module is heavily based on Nick Wellnhofer's 
L<Net::Google::Analytics> module

=head1 NAME

Net::Google::WebmasterTools - Simple interface to the Google Webmaster Tools (Search Console) API

=head1 VERSION

version 0.03

=head1 GETTING STARTED

L<Net::Google::WebmasterTools::OAuth2> provides for easy authentication and
authorization using OAuth 2.0. First, you have to register your application
through the L<Google APIs Console|https://code.google.com/apis/console/>.

You will receive a client id and a client secret for your application in the
APIs Console. For command line testing, you should use "Installed application"
as application type. Then you can obtain a refresh token for your application
by running the following script with your client id and secret:

    use Net::Google::WebmasterTools::OAuth2;

    my $oauth = Net::Google::WebmasterTools::OAuth2->new(
        client_id     => 'Your client id',
        client_secret => 'Your client secret',
    );

    $oauth->interactive;

The script will display a URL and prompt for a code. Visit the URL in a
browser and follow the directions to grant access to your application. You will
be shown the code that you should enter in the Perl script. Then the script
retrieves and prints a refresh token which can be used for non-interactive
access.

=head1 CONSTRUCTOR

=head2 new

    my $wmt = Net::Google::WebmasterTools->new;

The constructor doesn't take any arguments.

=head1 METHODS

=head2 auth_params

    $wmt->auth_params(@auth_params);

Set the raw authentication parameters as key/value pairs. These will we send
as HTTP headers.

=head2 token

    $wmt->token($token);

Authenticate using a token returned from L<Net::Google::WebmasterTools::OAuth2>.

=head2 new_request

    my $req = $wmt->new_request(param => $value, ...);

Creates and returns a new L<Net::Google::WebmasterTools::Request> object.

Valid combinations of report_name and method:

=head3 Search Analytics

Search traffic analytics data (L<documentation|https://developers.google.com/webmaster-tools/v3/searchanalytics>)

    report_name => 'searchAnalytics',
    method => 'query'

=head3 Sitemaps

XML Sitemaps reports (L<documentation|https://developers.google.com/webmaster-tools/v3/sitemaps>)

    report_name => 'sitemaps',
    method => 'list' # or delete, get, submit

=head3 Sites

    report_name => '',
    method => 'add' # or delete, get, list

=head3 URL Crawl Errors Counts

Counts of crawl errors (L<documentation|https://developers.google.com/webmaster-tools/v3/urlcrawlerrorscounts>)

    report_name => 'urlCrawlErrorsCounts',
    method => 'query'

=head3 URL Crawl Errors Samples

Information about specific crawl errors (L<documentation|https://developers.google.com/webmaster-tools/v3/urlcrawlerrorssamples>)

    report_name => 'urlCrawlErrorsSamples',
    method => 'get' # or list, markAsFixed

=head2 retrieve

    my $res = $wmt->retrieve($req);

Sends the request. $req must be a L<Net::Google::WebmasterTools::Request>
object. This method returns a L<Net::Google::WebmasterTools::Response> object.

=head2 retrieve_http

    my $res = $wmt->retrieve_http($req);

Sends the request and returns an L<HTTP::Response> object. $req must be a
L<Net::Google::WebmasterTools::Request> object.

=head2 uri

    my $uri = $wmt->uri($req);

Returns the URI of the request. $req must be a
L<Net::Google::WebmasterTools::Request> object. This method returns a L<URI>
object.

=head2 user_agent

    $wmt->user_agent($ua);

Sets the L<LWP::UserAgent> object to use for HTTP(S) requests. You only
have to call this method if you want to provide your own user agent.

=head1 AUTHOR

Rob Hammond <contact@rjh.am>, Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Hammond <contact@rjh.am>, Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
