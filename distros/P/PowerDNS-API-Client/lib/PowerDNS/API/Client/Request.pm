package PowerDNS::API::Client::Request;
BEGIN {
  $PowerDNS::API::Client::Request::VERSION = '0.10';
}
use Moose;
use URI ();
# use Digest::SHA qw(hmac_sha256_hex);
use HTTP::Request ();
use namespace::clean -except => 'meta';

use PowerDNS::API::Client::Response;

has 'api' => (
    isa      => 'PowerDNS::API::Client',
    is       => 'ro',
    required => 1,
);

has method => (
    isa      => 'Str',
    required => 1,
    is       => 'ro',
);

has path => (
    isa      => 'Str',
    required => 1,
    is       => 'ro',
);

has args => (
    isa => 'HashRef[Str]',
    is  => 'rw',
);

sub _query {
    my %args = @_;

    #my $api_secret = delete $args{api_secret};
    #$args{api_ts} = time;
    #$args{api_sig} =
    #  hmac_sha256_hex(_get_parameter_string(\%args), $api_secret);

    my $uri = URI->new();
    $uri->query_form(%args);
    return $uri->query;
}

sub http_request {
    my $self = shift;
    my $uri  = URI->new($self->api->server);
    $uri->path("/api/" . $self->path);

    my $content = _query(
        %{$self->args},
        #api_key    => $self->api->api_key,
        #api_secret => $self->api->api_secret,
    );

    my $request = HTTP::Request->new($self->method => $uri);

    $request->header('Content-Type' => 'application/x-www-form-urlencoded');
    if (defined($content)) {
        $request->header('Content-Length' => length($content));
        $request->content($content);
        warn "PowerDNS::API::Client Request Content: $content\n"
          if $ENV{API_DEBUG};
    }

    return $request;
}

sub _get_parameter_string {
    my $args = shift;

    my $str = "";
    for my $key (sort { $a cmp $b } keys %{$args}) {
        next if $key eq 'api_sig';
        my $value = (defined($args->{$key})) ? $args->{$key} : "";
        $str .= $key . $value;
    }
    return $str;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

PowerDNS::API::Client::Request - Request object for PowerDNS::API::Client

=head1 SYNOPSIS

This class manages setting up requests for the PowerDNS::API::Client,
including signing of requests.

No user servicable parts inside.  This part of the API is subject to change.

    my $req = PowerDNS::API::Client::Request->new
       (api    => $powerdns_api,
        method => 'location/detail',
        args   => { foo => 'bar',
                    fob => 123,
                  },
       );

    my $http_request = $req->http_request;

=head1 METHODS

=head2 api

=head2 http_request

Returns a HTTP::Request version of the request.

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ask Bjørn Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


