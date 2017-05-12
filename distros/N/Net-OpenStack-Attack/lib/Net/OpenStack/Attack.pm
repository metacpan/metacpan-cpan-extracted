package Net::OpenStack::Attack;
use v5.10;
use Any::Moose;
use HTTP::Async;
use HTTP::Request;
use JSON qw(to_json from_json);

our $VERSION = '1.0500'; # VERSION

has compute => (is => 'ro', isa => 'Net::OpenStack::Compute', required => 1);

sub create_servers {
    my ($self, $num, $image) = @_;
    $image ||= $self->get_any_image();
    my $body = to_json {
        server => {
            name      => 'stackattack',
            imageRef  => $image,
            flavorRef => 1,
        }
    };
    my @reqs = map $self->make_req(POST => '/servers', $body), 1 .. $num;
    return $self->send_reqs(@reqs);
}

sub delete_servers {
    my ($self, $servers) = @_;
    my @reqs = map $self->make_req(DELETE => "/servers/$_->{id}"), @$servers;
    return $self->send_reqs(@reqs);
}

sub rebuild_servers {
    my ($self, $servers, $image) = @_;
    $image ||= $self->get_any_image();
    my $body = to_json {
        rebuild => {
            imageRef  => $image,
        }
    };
    my @reqs = map $self->make_req(POST => "/servers/$_->{id}/action", $body),
        @$servers;
    return $self->send_reqs(@reqs);
}

sub attack {
    my ($self, $method, $resource, $num) = @_;
    my @reqs = map $self->make_req($method => $resource), 1 .. $num;
    return $self->send_reqs(@reqs);
}

sub make_req {
    my ($self, $method, $resource, $body) = @_;
    my $url = $self->compute->base_url . $resource;
    my $headers = [
        x_auth_token => $self->compute->token,
        content_type => 'application/json',
    ];
    return HTTP::Request->new($method => $url, $headers, $body);
}

sub send_reqs {
    my ($self, @reqs) = @_;
    my $async = HTTP::Async->new;
    $async->add(@reqs);
    my ($successes, $failures, @errmsgs) = (0, 0);
    while (my $res = $async->wait_for_next_response) {
        if ($res->is_success) {
            $successes++;
        } else {
            $failures++;
            warn sprintf "Error: %s: %s\n", $res->status_line, $res->content;
        }
    }

    return { successes => $successes, failures => $failures };
}

sub get_any_image { shift->compute->get_images(detail => 0)->[0]{id} }

# ABSTRACT: Tools for stress testing an OpenStack deployment.


1;

__END__
=pod

=head1 NAME

Net::OpenStack::Attack - Tools for stress testing an OpenStack deployment.

=head1 VERSION

version 1.0500

=head1 DESCRIPTION

This class provides methods for making parallel, asynchronous requests to
the OpenStack API.
This distribution comes with a command line tool L<stackattack> which heavily
uses this class.

=head1 SEE ALSO

=over

=item L<stackattack>

=item L<Net::OpenStack::Compute>

=back

=head1 AUTHORS

=over 4

=item *

William Wolf <throughnothing@gmail.com>

=item *

Naveed Massjouni <naveedm9@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

