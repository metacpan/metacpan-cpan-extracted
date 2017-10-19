package Net::Mailboxlayer;

use strict;
use warnings;

$Net::Mailboxlayer::VERSION = '0.003';

use URI::URL;
use LWP::UserAgent;
use Scalar::Util 'blessed';
use JSON::MaybeXS qw(JSON);

use Net::Mailboxlayer::Error;
use Net::Mailboxlayer::Response;

sub new
{
    my ($class, %props) = @_;

    # set defaults
    my $self = bless {
        _endpoint => 'https://apilayer.net/api/check',
        _smtp => 1,
        _format => 0,
        _catch_all => 0,
        _user_agent_opts => {},
        _user_agent => undef,
        _optional_querystring_parts => [qw(smtp format callback catch_all)],
        _json => JSON->new,
    }, $class;

    foreach my $prop (qw (endpoint access_key email_address smtp format callback catch_all user_agent_opts user_agent json_decoder))
    {
        next if not exists $props{$prop};
        $self->$prop($props{$prop});
    }
    return $self;
}

sub endpoint
{
    my ($self, $val) = @_;
    $self->{_endpoint} = $val if defined $val;
    return $self->{_endpoint};
}

sub access_key
{
    my ($self, $val) = @_;
    $self->{_access_key} = $val if defined $val;
    return $self->{_access_key};
}

sub email_address
{
    my ($self, $val) = @_;
    $self->{_email_address} = $val if defined $val;
    return $self->{_email_address};
}

sub smtp
{
    my ($self, $val) = @_;
    $self->{_smtp} = $val if defined $val;
    return $self->{_smtp};
}

sub format
{
    my ($self, $val) = @_;
    $self->{_format} = $val if defined $val;
    return $self->{_format};
}
sub callback
{
    my ($self, $val) = @_;
    $self->{_callback} = $val if defined $val;
    return $self->{_callback};
}

sub catch_all
{
    my ($self, $val) = @_;
    $self->{_catch_all} = $val if defined $val;
    return $self->{_catch_all};
}

sub user_agent_opts
{
    my ($self, $val) = @_;
    $self->{_user_agent_opts} = $val if defined $val;
    return $self->{_user_agent_opts};
}

sub user_agent
{
    my ($self, $val) = @_;

    if ($val and blessed $val and $val->can('get'))
    {
        $self->{_user_agent} = $val;
    }
    if (not $self->{_user_agent})
    {
        $self->{_user_agent} = LWP::UserAgent->new(%{$self->{_user_agent_opts}});
    }
    return $self->{_user_agent};
}

sub json_decoder
{
    my ($self, $val) = @_;

    if ($val and blessed $val and $val->can('decode'))
    {
        $self->{_json} = $val;
    }
    return $self->{_json};
}

sub _build_url
{
    my ($self) = @_;

    my $url = URI::URL->new($self->endpoint);

    my @parts = (
        access_key => $self->access_key,
        email => $self->email_address,
    );
    foreach my $part (@{$self->{_optional_querystring_parts}})
    {
        if ($self->$part)
        {
            push @parts, $part => $self->$part;
        }
    }

    $url->query_form(@parts);

    return $url;
}

sub check
{
    my ($self) = @_;

    my $url = $self->_build_url;

    my $response = $self->user_agent->get($url);

    if ($response->is_error)
    {
        return Net::Mailboxlayer::Error->new(
            success => 0,
            error => {
                code => $response->code,
                type => $response->status_line,
                info => $response->message,
            },
        );
    }

    # todo: try catch here in case we have invalid json
    my $data = $self->json_decoder->decode($response->decoded_content);
    $data->{_response} = $response;

    if (exists $data->{success} and not $data->{success})
    {
        return Net::Mailboxlayer::Error->new(%{$data});
    }

    return Net::Mailboxlayer::Response->new(%{$data});
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Mailboxlayer - Implements mailboxlayer.com's REST API, which a simple REST API measuring email deliverability and quality.

=head1 SYNOPSIS

 use Net::Mailboxlayer;

 my $mailboxlayer = Net::Mailboxlayer->new(access_key => 'YOUR_ACCESS_KEY', email_address => 'support@apilayer.com');
 my $result = $mailboxlayer->check;

 $result->email;        # support@apilayer.com
 $result->did_you_mean; # ""
 $result->user;         # support
 $result->domain;       # apilayer.net
 $result->format_valid; # 1
 $result->mx_found;     # 1
 $result->smtp_check;   # 1
 $result->catch_all;    # undef
 $result->role;         # 1
 $result->disposable;   # 0
 $result->free;         # 0
 $result->score;        # 0.8

See F<Net::Mailboxlayer::Response> for more details.

=head1 DESCRIPTION

This module is a simple wrapper for mailboxlayer.com's REST API.

=head2 USAGE

=head2 new

Creates a new Net::Mailboxlayer object.  Minimum required options are C<access_key> and C<email_address>, which must be set before C<check> is called.

 my $mailboxlayer = Net::Mailboxlayer->new(access_key => 'YOUR_ACCESS_KEY', email_address => 'support@apilayer.com');

=over 4

=item * C<access_key> (required)

See also method C<access_key>.  You can get an API KEY from https://mailboxlayer.com when you created an account.

=item * C<email_address> (required)

See also method C<email_address>.  This is the email address you want to measure.

=item * C<endpoint> (optional)

See also method C<endpoint>.  The endpoint of the api call.  Defaults to https://apilayer.net/api/check.

=item * C<smtp> (optional)

See also method C<smtp>.  Defaults to 1 (enabled).

Enables the MX-Records and SMTP checks.

Reasons to turn off SMTP Check:

The mailboxlayer SMTP Check feature takes up around 75% of the API's entire response time. If you would like to skip SMTP and speed up the API response, you may turn it off by setting the API's smtp parameter to 0.

=item * C<format> (optional)

See also method C<format>. Defaults to 0 (disabled).

Causes the response from the api to be prettified.  Use this only for debugging.

=item * C<callback> (optional)

See also method C<callback>.  Sets your preferred JSONP callback function.  See the official docs for more information.

Provided for completeness and who knows, you might have some use for it!  Let me know if you do.

=item * C<catch_all> (optional)

See also method C<catch_all>.  Enables catch-all detection functionality on the recipient SMTP server.  Defaults to 0 (disabled).

This has a heavy impact on response time, so is disabled by default.

=item * C<user_agent_opts> (optional)

See also method C<user_agent_opts>.  Sets default options for construction of a F<LWP::UserAgent> object.  Takes a hashref.

Example:

 my $mailboxlayer = Net::Mailboxlayer->new(
   access_key => 'YOUR_ACCESS_KEY',
   email_address => 'support@apilayer.com',
   user_agent_opts => {
     ssl_opts => {verify_hostname => 1},
     timeout => 10,
   },
 );

=item * C<user_agent>

See also method C<user_agent>.  This will allow you to override the default useragent F<LWP::UserAgent>.  The given value must be blessed and have a 'get' method.

=item * <json_decoder>

See also method C<json_decoder>.  This will allow you to override the default json decoder F<JSON::MaybeXS>, which itself defaults to F<Cpanel::JSON::XS>.  The given value must be blessed and have a 'decode' method.

=back

=head2 access_key

Allows you to set/change the access_key that you optionally provide with C<new>.  You must provide it before calling C<check>.  API KEYS are provided when you setup an account with https://mailboxlayer.com.

 $mailboxlayer->access_key('YOUR_ACCESS_KEY');

=head2 email_address

Allows you to set/change the email_address to measure.  It must be provided before calling C<check>.

 $mailboxlayer->email_address('support@apilayer.com');

=head2 endpoint

Allows you to set/change the endpoint that you optionally provide with C<new>.  Must be set before calling C<check>.  Defaults to https://apilayer.net/api/check.

 $mailboxlayer->endpoint('http://apilayer.net/api/check'); # don't use SSL for the endpoint
 $mailboxlayer->endpoint('https://apilayer.net/api/check'); # use SSL for the endpoint

=head2 smtp

Enables/disables the MX-Records and SMTP checks.  Defaults to 1 (emabled).

 $mailboxlayer->smtp(0); # disable
 $mailboxlayer->smtp(1); # enable

Reasons to turn off SMTP Check:

The mailboxlayer SMTP Check feature takes up around 75% of the API's entire response time. If you would like to skip SMTP and speed up the API response, you may turn it off by setting the API's smtp parameter to 0.

=head2 format

Prettifies the JSON that is provided to F<Net::Mailboxlayer::Response>.  Use this only for debugging.

 $mailboxlayer->format(0); # disable
 $mailboxlayer->format(1); # enable

=head2 callback

Sets the preferred JSONP callback function.  See the official docs (https://mailboxlayer.com/documentation) for more information.  Provided for completeness.

=head2 catch_all

Enables catch-all detection on the recipient SMTP server.  Defaults to 0 (disabled);

 $mailboxlayer->catch_all(0); # disable
 $mailboxlayer->catch_all(1); # enable

Note that as of 2016-08-12 this functionality is disabled for free accounts and will return an error if you enable it.

=head2 user_agent_opts

Sets default options for construction of a F<LWP::UserAgent> object.  Takes a hashref.

 $mailboxlayer->user_agent_opts({
  ssl_opts => {verify_hostname => 1},
  timeout => 10,
 });

The above tells F<LWP::UserAgent> to verify ssl hostnames and sets the timeout to 10 seconds.  See the F<LWP::UserAgent> docs for more information and options.

=head2 user_agent

This will override the default F<LWP::UserAgent> completely.  Perhaps you want to construct your own, or you want to use an alternative module such as F<HTTP::Tiny>.

 my $http = HTTP::Tiny->new(%attributes);
 $mailboxlayer->user_agent($http);

The only restriction is that you pass a blessed object that has a 'get' method.

=head2 json_decoder

This will override the default F<JSON::MaybeXS> module.  If you want to use JSON::XS instead, this would allow you.

 my $json = JSON::XS->new;
 $mailboxlayer->json_decoder($json);

The only restriction is that you pass a blessed ovject that has a 'decode' method.

=head2 check

Make the api call to measure the C<email_address>.

This method will return either a F<Net::Mailboxlayer::Response> object on success or a F<Net::Mailboxlayer::Error> when an error occurs.

You can call $result->has_error to determine if there was an error or not.

 my $result = $mailboxlayer->check;
 if ($result->has_error)
 {
   # $result is a F<Net::Mailboxlayer::Error> object.
   print "There was an error: ". $result->info . "\n";
 }
 else
 {
   # $result is a F<Net::Mailboxlayer::Response> object.
   $result->score;
 }



=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT & LICENSE

Copyright 2016 Tom Heady.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

=item * the Artistic License.

=back

=cut
