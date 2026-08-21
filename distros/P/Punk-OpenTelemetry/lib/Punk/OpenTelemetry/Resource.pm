package Punk::OpenTelemetry::Resource;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_resource.h + xs/resource.xs).

1;

__END__


=head1 NAME

Punk::OpenTelemetry::Resource - what produced this telemetry

=head1 SYNOPSIS

    my $resource = Punk::OpenTelemetry::Resource::detect(
        service_name => 'maat',
    );
    my $tracer = Punk::OpenTelemetry::Tracer->new(resource => $resource);

=head1 DESCRIPTION

The resource attributes attached to everything a process exports: what service
this is, which instance of it, and what it is running on.

=head2 service.name

Required, in the sense that everything works without it and nothing can be
found afterwards. With none configured the spec's C<unknown_service> is used
and a warning is emitted once at boot - an unnamed service is
indistinguishable from every other unnamed service in the fleet, which is the
most common reason a trace cannot be found again.

=head2 service.instance.id, and forking

B<Call C<detect> in the process that will do the exporting, after any fork.>

C<service.instance.id> must differ per process, and this is load-bearing
rather than cosmetic. A cumulative metric series is identified by its resource
plus its attributes; if eight prefork workers export under the same instance
id, a collector sees eight contradictory monotonic series claiming to be one.
Depending on the backend it will reset, sum, or take the last write - all
three are wrong, and none of them looks wrong on the dashboard.

Traces survive the mistake more quietly, but the same rule applies, and
getting into the habit here is what makes the metrics phase safe.

Under L<Hyperman>, the right place is C<< Hyperman->on_worker_start >>, which
runs in each worker after the fork.

The id itself comes from the same entropy source as a trace id -
C<getentropy(2)>, or a C</dev/urandom> descriptor that is reopened when the
pid changes - so two processes cannot draw the same one even if you forget the
rule above. That is not merely belt and braces: Perl's C<rand> is seeded
lazily and B<is not reseeded across a fork>, so an earlier version of this
module handed every prefork worker the same instance id whenever anything in
the process had called C<rand> before forking - silently, and exactly in the
deployment shape the attribute exists for.

Calling C<detect> after the fork still matters, because C<process.pid> is
detected too and a child inheriting its parent's is just as wrong.

=head2 Environment

C<OTEL_SERVICE_NAME> and C<OTEL_RESOURCE_ATTRIBUTES> (comma-separated
C<key=value>) are read. Explicit arguments to C<detect> win over both.

A pair is split on its B<first> C<=>, so a value may contain one. A pair with
no C<=>, or an empty key, is skipped rather than guessed at. Whitespace around
both the key and the value is trimmed.

=head1 FUNCTIONS

=head2 detect(%overrides)

The resource, as a hashref. C<service_name> is the one named override; any
other key is used as a literal attribute name.

=head2 instance_id

A fresh UUID-shaped instance id. Called by C<detect>; exposed so a worker can
refresh it after a fork without rebuilding the whole resource.

=head1 SEE ALSO

L<Punk::Plugin::OpenTelemetry>, whose "THE FORK TRAP" section is where the
instance id is refreshed, and L<Punk::OpenTelemetry::Config> for
C<OTEL_SERVICE_NAME> and C<OTEL_RESOURCE_ATTRIBUTES>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
