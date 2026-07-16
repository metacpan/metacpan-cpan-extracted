package PAGI::Nano::Context::HTTP;
$PAGI::Nano::Context::HTTP::VERSION = '0.001000';
use strict;
use warnings;
use parent -norequire, 'PAGI::Context::HTTP', 'PAGI::Nano::Context';
use PAGI::Context;          # PAGI::Context::HTTP declares @ISA but does not load
use PAGI::Context::HTTP;    # the base; pull both in when used outside the factory
use PAGI::Nano::Context;    # the shared mixin (uri_for)
use PAGI::StructuredParameters;

# The HTTP context Nano vends. It is a genuine PAGI::Context::HTTP (so the
# inherited request/response/respond/json/text/html/redirect/state sugar all
# work and there is no silo) and adds $c->params, the strong-parameters entry
# point. We bless directly rather than going through PAGI::Context->new so the
# base factory's scope-type resolution does not down-cast us back to the plain
# context class.

sub new {
    my ($class, $scope, $receive, $send) = @_;
    return bless {
        scope   => $scope,
        receive => $receive,
        send    => $send,
    }, $class;
}

sub params {
    my ($self) = @_;
    my $req = $self->req;
    return $req->is_json
        ? PAGI::StructuredParameters->from_data($req, $self)
        : PAGI::StructuredParameters->from_body($req, $self);
}

1;

=encoding utf8

=head1 NAME

PAGI::Nano::Context::HTTP - The HTTP request context vended by PAGI::Nano

=head1 SYNOPSIS

    get '/' => sub ($c) {
        my $name = $c->req->query_param('name');
        $c->json({ hello => $name });
    };

    post '/tasks' => sub ($c) {
        my $attrs = await $c->params->required(
            'title',
            sub ($c, $missing) { $c->json({ error => 'missing', fields => $missing }, status => 400) },
        );
        ...
    };

=head1 DESCRIPTION

A subclass of L<PAGI::Context::HTTP>, so every method of the base HTTP context
is available — C<req>/C<request>, C<response>/C<resp>, C<respond>, C<method>,
C<state>, C<path_param>, and the response sugar C<json>/C<text>/C<html>/
C<redirect>. A Nano handler receives one of these as C<$c>.

The additions are L</params> and L</uri_for>. The inherited
C<< $c->raw_send >> (the raw PAGI C<$send> coderef; see
L<PAGI::Context/raw_send>) is also available for handlers that drop to the
channel directly.

=head1 METHODS

=head2 params

    my $params = $c->params;            # PAGI::StructuredParameters::Request
    my $clean  = await $params->permitted(@rules);
    my $clean  = await $params->required(@rules, $on_missing);

The strong-parameters entry point. Returns a
L<PAGI::StructuredParameters::Request> bound to the current request, selecting
the source by content-type: a JSON request uses C<from_data> (nested data,
arrays kept as-is); any other request uses C<from_body> (form parameters, array
values flattened). The context C<$c> is passed through so C<required>'s
on-missing callback receives it as its first argument.

Because reading a request body is asynchronous, the terminal C<permitted> and
C<required> calls must be awaited.

=head2 uri_for

    my $url = $c->uri_for($name);
    my $url = $c->uri_for($name, \%path_params);
    my $url = $c->uri_for($name, \%path_params, \%query_params);

Builds the URL for a route named with L<PAGI::Nano/name>. Path placeholders
(C<:id>, C<{id}>, C<{id:regex}>, C<*splat>) are filled from C<%path_params>, and
C<%query_params> (if any) is appended as a percent-encoded query string.
Resolution is against the flat name registry PAGI::Nano injects on the scope, so
names defined anywhere in the app — including across a C<mount>, in either
direction — are reachable, with mount prefixes applied. Dies if the name is
unknown.

=head1 SEE ALSO

L<PAGI::Nano>, L<PAGI::StructuredParameters>, L<PAGI::Context::HTTP>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
