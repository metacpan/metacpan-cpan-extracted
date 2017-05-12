package Net::Riak::Role::REST;
{
  $Net::Riak::Role::REST::VERSION = '0.1702';
}

# ABSTRACT: role for REST operations

use URI;

use Moose::Role;
use MooseX::Types::Moose 'Bool';
use Net::Riak::Types qw/HTTPResponse HTTPRequest/;
use Data::Dump 'pp';
with qw/Net::Riak::Role::REST::Bucket
    Net::Riak::Role::REST::Object
    Net::Riak::Role::REST::Link
    Net::Riak::Role::REST::MapReduce
    Net::Riak::Role::REST::Search
    /;

has http_request => (
    is => 'rw',
    isa => HTTPRequest,
);

has http_response => (
    is => 'rw',
    isa => HTTPResponse,
    handles => {
        is_success => 'is_success',
        status => 'code',
    }
);

has disable_return_body => (
    is => 'rw',
    isa => Bool,
    default => 0
);

has ssl => (
    is => 'rw',
    isa => Bool,
    default => 0
);

sub _build_path {
    my ($self, $path) = @_;
    $path = join('/', @$path);
}

sub _build_uri {
    my ($self, $path, $params) = @_;

    my $uri = URI->new($self->get_host);
    if ( $uri =~ /^https:.+/ ) { $self->ssl(1); }
    $uri->path($self->_build_path($path));
    $uri->query_form(%$params);
    $uri;
}

# constructs a HTTP::Request
sub new_request {
    my ($self, $method, $path, $params) = @_;
    my $uri = $self->_build_uri($path, $params);
    return HTTP::Request->new($method => $uri);
}

# makes a HTTP::Request returns and stores a HTTP::Response
sub send_request {
    my ($self, $req) = @_;

    $self->http_request($req);

    my $r = $self->useragent->request($req);

    $self->http_response($r);

    if ($ENV{RIAK_VERBOSE}) {
        print STDERR pp($r);
    }

    return $r;
}

sub is_alive {
    my $self     = shift;
    my $request  = $self->new_request('HEAD', ['ping']);
    my $response = $self->send_request($request);
    $self->is_success ? return 1 : return 0;
}

sub all_buckets {
    my $self = shift;
    my $request = $self->new_request('GET', [$self->prefix], {buckets => 'true'});
    my $response = $self->send_request($request);
    die "Failed to fetch buckets.. are you running riak 0.14+?"
        unless $response->is_success;
    my $resp = JSON::decode_json($response->content);
    return ref ($resp->{buckets}) eq 'ARRAY' ? @{$resp->{buckets}} : ();
}

sub server_info { die "->server_info not supported by the REST interface" }

sub stats {
    my $self = shift;
    my $request = $self->new_request('GET', ["stats"]);
    my $response = $self->send_request($request);
    return JSON::decode_json($response->content);
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::REST - role for REST operations

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
