package Net::Azure::CognitiveServices::Face::Base;
use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Carp;
use URI;

sub new {
    my ($class, %opts) = @_;
    return bless {%opts}, $class;
}

sub access_key {shift->{access_key}}
sub endpoint {shift->{endpoint}}

sub path {''};

sub uri {
    my ($self, $path, %query) = @_;
    my $uri = URI->new($self->endpoint);
    $uri->path($path ? join('/', $self->path, $path) : $self->path);
    if (keys %query) {
        $uri->query_form(%query);
    }
    $uri;
}

sub json {
    my $self = shift;
    $self->{json} ||= JSON->new->utf8(1);
    $self->{json};
}

sub agent {
    my $self = shift;
    $self->{agent} ||= HTTP::Tiny->new(agent => __PACKAGE__, timeout => 60);
    $self->{agent};
}

sub request {
    my ($self, $req) = @_;
    my $res;
    my $try = 0;
    while (1) {
        $res = $self->agent->request(@$req);
        $try++;
        if ($try > 10 || $res->{status} != 429) {
            last;
        }
        carp sprintf('Retry. Because API said %s', $res->{content});
    }
    my $body;
    if ($res->{content}) {
        my $content_type = $res->{headers}{'Content-Type'} || $res->{headers}{'content-type'};
        if ($content_type !~ /application\/json/) {
            croak($res->{content}); 
        }
        $body = $self->json->decode($res->{content});
    }
    if (!$res->{success}) {
        croak($body->{error}{message});
    }
    $body;
}

sub build_headers {
    my ($self, @headers) = @_;
    {
        "Content-Type"              => "application/json", 
        "Ocp-Apim-Subscription-Key" => $self->access_key,
        @headers, 
    };
}

sub build_request {
    my ($self, $method, $uri_param, $header, $hash) = @_;
    my $uri  = $self->uri(@$uri_param);
    my $body = $hash ? $self->json->encode($hash) : undef;
    my $headers = $self->build_headers(defined $header ? @$header : ());
    return [$method, $uri, {headers => $headers, content => $body}];
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Azure::CognitiveServices::Face::Base - Base class of Cognitive Services APIs

=head1 DESCRIPTION

This is a base class for writting wrapper classes of Face APIs more easy. 

=head1 ATTRIBUTES

=head2 access_key

The access key for accessing to Azure Cognitive Services APIs

=head2 endpoint

Endpoint URL string

=head1 METHODS

=head2 path

An interface that returns the endpoint path string.

    my $path_string = $obj->path;

=head2 uri

Build an URI object.

    my $uri = $obj->uri('/base/uri', name => 'foobar', page => 3); ## => '/base/uri?name=foobar&page=3'

=head2 json

Returns a JSON.pm object.

    my $hash = $obj->json->decode('{"name":"foobar","page":3}'); ## => {name => "foobar", page => 3}

=head2 agent

Returns a HTTP::Tiny object.

    my $res = $obj->agent->get('http://example.com');

=head2 request

Send a http request, and returns a json content as a hashref.

    my $method = 'POST';
    my $uri = "https://example.com/endpoint/to/face-api?parameter=foo&other=bar";
    my $options = {
        headers => {
            'Content-Type': 'application/json',
        }, 
        content => '{"key": "value", "key2": "value2"}',
    };
    my $req  = [$method, $uri, $options];
    my $hash = $obj->request($req);

=head2 build_headers

Build and returns http headers with authorization header.

    my $obj = Net::Azure::CognitiveServices::Face::Base->new(access_key => 'SECRET', ...);
    my @headers = $obj->build_headers('Content-Length' => 60);

=head2 build_request

Build and returns a HTTP::Request object.

    ### arguments
    my $path      = '/foo/bar';
    my %param     = (page => 2, name => 'hoge');
    my @headers   = ("X-HTTP-Foobar" => 123);
    my $json_data = {url => 'http://example.com'};
    ### build request object
    my $req = $obj->build_request([$path, %param], [@headers], $json_data);

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut