package OpenTelemetry;
# ABSTRACT: supporting for application process monitoring, as defined by opentelemetry.io

use strict;
use warnings;

our $VERSION = '0.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTelemetry - support for L<https://opentelemetry.io> application tracing

=head1 DESCRIPTION

OpenTelemetry is due to become the successor to the OpenTracing initiative.
It includes additional functionality relating to metrics,
and at the time of writing is an evolving specification.

Current status of the official spec can be tracked here:

L<https://github.com/open-telemetry/opentelemetry-specification/blob/master/README.md>

Note that the L<https://opentracing.io> specification is currently more widely supported,
but eventually L<OpenTracing::Any> and L<OpenTelemetry::Any>
should be able to coëxist in a codebase and support collectors
for either system.

For metrics, see L<Metrics::Any>.

=cut

1;

__END__

=head1 SEE ALSO

=head2 Tools and specifications

=over 4

=item * L<https://opentelemtry.io> - the new standard

=item * L<https://opentracing.io> - if you want something that works today

=back

=head2 Other modules

Some perl modules of relevance:

=over 4

=item * L<OpenTracing::Manual> - this is an independent Moo-based implementation, probably worth a look
if you're working mostly with synchronous code.

=item * L<NewRelic::Agent> - support for NewRelic's APM system

=back

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2020. Licensed under the same terms as Perl itself.

