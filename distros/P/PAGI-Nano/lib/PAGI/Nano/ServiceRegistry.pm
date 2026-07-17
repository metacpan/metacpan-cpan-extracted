package PAGI::Nano::ServiceRegistry;
$PAGI::Nano::ServiceRegistry::VERSION = '0.001001';
use strict;
use warnings;
use Carp ();
use Scalar::Util ();

# One instance per assembled Nano app that declares any services. Holds the
# eagerly-built, per-worker results keyed by name. Vended to builders as the
# single "$app" argument (composition, via service()) and injected onto the
# PAGI scope for request-time resolution (see PAGI::Nano::Context::service).

sub new {
    my ($class) = @_;
    return bless { built => {} }, $class;
}

# Run every declared builder once, in declaration order, storing whatever each
# returns verbatim (a plain value, an unblessed per-request maker coderef, or a
# factory-marked per-call maker; see PAGI::Nano::Context::service for how that
# is later discriminated). Called from a PAGI::Lifespan startup hook, so a
# builder that dies fails lifespan startup rather than a customer request.
sub _build_all {
    my ($self, $services) = @_;
    for my $entry (@$services) {
        my ($name, $builder) = @$entry;
        my $value = $builder->($self);
        # A builder written as `async sub {...}` returns an unresolved Future.
        # Builders are synchronous (they run at startup), so storing that as the
        # service would only fail cryptically later at resolve time -- fail loud
        # here instead. Duck-type on ->can('then') to catch Future and
        # Future::AsyncAwait futures without depending on a specific class.
        Carp::croak(
            "service '$name' builder returned a Future -- service builders must be "
          . "synchronous (they run at lifespan startup). Build the value synchronously, "
          . "or return a per-request maker (a plain coderef) / a factory(...) maker "
          . "if you need per-request/per-call construction."
        ) if Scalar::Util::blessed($value) && $value->can('then');
        $self->{built}{$name} = $value;
    }
}

sub service {
    my ($self, $name) = @_;
    Carp::croak("no service named '$name' (services build in declaration order at startup)")
        unless exists $self->{built}{$name};
    return $self->{built}{$name};
}

# The request-time accessor behind PAGI::Nano::Context::service: applies the
# scope-discrimination rule to the raw builder result. A factory-marked
# coderef (see PAGI::Nano::factory) is invoked fresh on every call. An
# unblessed coderef is a per-request maker, invoked with $ctx and memoized on
# $ctx's scope. Anything else (a plain value, or any other blessed object) is
# an app-scoped singleton, returned as-is.
#
# The memoization cache is a single flat hash on the scope, not sub-keyed by
# registry: mount() refuses to mount a Nano app that declares its own services
# (the outermost app owns lifecycle -- see PAGI::Nano/mount), so only one
# registry is ever in play for a given request.
sub _resolve {
    my ($self, $name, $ctx) = @_;
    my $raw = $self->service($name);

    if (Scalar::Util::blessed($raw) && $raw->isa('PAGI::Nano::Marker::Factory')) {
        return $raw->($ctx);
    }

    if (!Scalar::Util::blessed($raw) && ref($raw) eq 'CODE') {
        my $scope = $ctx->{scope};
        my $cache = $scope->{'pagi.nano.service_cache'} //= {};
        return $cache->{$name} if exists $cache->{$name};

        my $value = $raw->($ctx);
        $cache->{$name} = $value;
        return $value;
    }

    return $raw;
}

1;

=encoding utf8

=head1 NAME

PAGI::Nano::ServiceRegistry - The per-app registry backing PAGI::Nano's service keyword

=head1 DESCRIPTION

One instance is created per assembled L<PAGI::Nano> app that declares any
C<service>. It is never constructed directly by application code; it is the
object passed to every service builder (as C<$app> in the C<service> examples)
and the object C<< $c->service >> resolves against at request time.

=head1 METHODS

=head2 service

    my $value = $app->service('name');

Returns an already-built service, for use inside another service's builder
(composition). Services build eagerly, in declaration order, at lifespan
startup; asking for one declared later in the same C<app { }> block (or not
declared at all) croaks, naming the service.

A test that wants to read an app-scoped service without issuing a request does
not reach this object directly (it is private); it uses the
C<< PAGI::Nano::resolve_service($app, $name) >> seam, which resolves against
this registry after lifespan startup. See L<PAGI::Nano/resolve_service>.

=head1 SEE ALSO

L<PAGI::Nano>, L<PAGI::Nano::Context>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
