package PowerDNS::API::Client;
BEGIN {
  $PowerDNS::API::Client::VERSION = '0.10';
}
use strict;
use warnings;

use warnings;
use strict;
use Moose;
use LWP::UserAgent ();
use URI ();

use namespace::clean -except => 'meta';

use PowerDNS::API::Client::Request;

has 'user' => (
    isa => 'Str',
    is  => 'ro',
    required => 1,
);

has 'password' => (
    isa => 'Str',
    is  => 'ro',
    required => 1,
);

has 'server' => (
    isa => 'Str',
    is  => 'rw',
);

has 'ua' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build => 1,
);

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    my $realm = URI->new($self->server)->host_port;
    $ua->credentials($realm, 'PowerDNS::API', $self->user, $self->password);
    return $ua;
}

sub _request {
    my ($self, $method, $path, %args) = @_;
    return PowerDNS::API::Client::Request->new(
        method => $method,
        path   => $path,
        args   => \%args,
        api    => $self,
    );

}

sub call {
    my $self = shift;
    my $http_response = $self->ua->request( $self->_request(@_)->http_request );
    return PowerDNS::API::Client::Response->new(http => $http_response)->data;
}


__PACKAGE__->meta->make_immutable;

local ($PowerDNS::API::Client::VERSION) = ('devel') unless defined $PowerDNS::API::Client::VERSION;

1;

__END__

=pod

=encoding utf8

=head1 NAME

PowerDNS::API::Client - Client for PowerDNS::API

=head1 SYNOPSIS

    my $client = PowerDNS::API::Client->new( server => 'https://api.example.com/' );

=head1 METHODS

=head2 call( $endpoint, %args )

Calls the endpoint (see the API documentation) with the specified
arguments.  Returns a hash data structure with the API results.

=head1 DEBUGGING


=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 BUGS

Please report any bugs or feature requests to the issue tracker at
L<http://github.com/devel/PowerDNS-API-Client/issues>.


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ask Bjørn Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

