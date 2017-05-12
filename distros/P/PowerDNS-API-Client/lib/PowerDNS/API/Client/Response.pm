package PowerDNS::API::Client::Response;
BEGIN {
  $PowerDNS::API::Client::Response::VERSION = '0.10';
}
use Moose;
use JSON qw(decode_json);
use namespace::clean -except => 'meta';

has http => (
    is       => 'ro',
    isa      => 'HTTP::Response',
    required => 1,
);

has data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_data {
    my $self = shift;
    if ($self->http->content_type ne 'application/json') {
        if ($ENV{API_DEBUG}) {
            require Data::Dumper;
            warn "PowerDNS::API::Client Response: ", Data::Dumper::Dumper($self->http);
        }
        return +{
            http_status => $self->http->code,
            error       => $self->http->status_line,
        };
    }
    my $data = decode_json($self->http->decoded_content);
    $data->{http_status} = $self->http->code;
    if ($ENV{API_DEBUG}) {
        require Data::Dumper;
        warn "PowerDNS::API::Client Response: ", Data::Dumper::Dumper($data);
    }
    return $data;
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

