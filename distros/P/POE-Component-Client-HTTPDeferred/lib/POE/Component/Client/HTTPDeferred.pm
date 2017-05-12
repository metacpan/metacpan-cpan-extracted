package POE::Component::Client::HTTPDeferred;
use Any::Moose;

our $VERSION = '0.02';

use POE qw/
    Component::Client::HTTP
    Component::Client::HTTPDeferred::Deferred
    /;

has client_alias => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'ua' },
);

has session => (
    is  => 'rw',
    isa => 'POE::Session',
);

no Any::Moose;

=head1 NAME

POE::Component::Client::HTTPDeferred - Yet another poco http client with twist like deferred interface.

=head1 SYNOPSIS

    use POE qw/Component::Client::HTTPDeferred/;
    use HTTP::Request::Common;
    
    POE::Session->create(
        inline_states => {
            _start => sub {
                my $ua = POE::Component::Client::HTTPDeferred->new;
                my $d  = $ua->request( GET 'http://example.com/' );
    
                $d->addBoth(sub {
                    my $res = shift;
    
                    if ($res->is_success) {
                        print $res->as_string;
                    }
                    else {
                        warn $res->status_line;
                    }
    
                    $ua->shutdown;
                });
            },
        },
    );
    POE::Kernel->run;

=head1 DESCRIPTION

POE::Component::Client::HTTPDeferred is a wrapper module to add twist (or MochiKit) like callback interface to POE::Component::Client::HTTP.

To use this module, you can use code reference as response callback. So you don't have to create POE state for handling response.

=head1 SEE ALSO

L<POE::Component::Client::HTTPDeferred::Deferred>

=head1 METHODS

=head2 new

Create POE::Component::Client::HTTPDeferred instance.

    my $ua = POE::Component::Client::HTTPDeferred->new;

Once you call this, POE::Component::Client::HTTPDeferred will start POE::Session for own use. 
So you need to call ->shutdown method to stop the session.

=cut

sub BUILD {
    my $self = shift;

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                map { $_ => "poe_$_" } qw/_start request response/
            },
        ],
    );
}

=head2 request

Send HTTP request and return Deferred object (L<POE::Component::Client::HTTPDeferred::Deferred>).

    my $d = $ua->request($request);

This $request argument should be HTTP::Request object.

=cut

sub request {
    my ($self, $req) = @_;

    my $d = $req->{_deferred} = POE::Component::Client::HTTPDeferred::Deferred->new(
        request      => $req,
        client_alias => $self->client_alias,
    );

    $poe_kernel->post( $self->session->ID => request => $req );

    $d;
}

=head2 shutdown

Shutdown POE::Component::Client::HTTPDeferred session.

=cut

sub shutdown {
    my $self = shift;
    $poe_kernel->post( $self->client_alias => 'shutdown' );
}

=head1 POE METHODS

Internal POE methods.

=head2 poe__start

=cut

sub poe__start {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    POE::Component::Client::HTTP->spawn( Alias => $self->client_alias );
}

=head2 poe_request

=cut

sub poe_request {
    my ($self, $kernel, $req) = @_[OBJECT, KERNEL, ARG0];

    $kernel->post( $self->client_alias, 'request', 'response', $req );
}

=head2 poe_response

=cut

sub poe_response {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    my ($req, $res)     = ($_[ARG0]->[0], $_[ARG1]->[0]);

    my $d = delete $req->{_deferred} or Carp::confess 'deferred object not found';

    if ($res->is_success) {
        $d->callback($res);
    }
    else {
        $d->errback($res);
    }
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

__PACKAGE__->meta->make_immutable;
