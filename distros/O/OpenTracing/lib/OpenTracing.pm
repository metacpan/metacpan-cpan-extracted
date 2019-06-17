package OpenTracing;
# ABSTRACT: supporting for application process monitoring, as defined by opentracing.io

use strict;
use warnings;

our $VERSION = '0.003';

=encoding utf8

=head1 NAME

OpenTracing - support for L<https://opentracing.io> application tracing

=head1 DESCRIPTION

This is an early implementation, so the API may be subject to change.

In general, you'll want to create an L<OpenTracing::Batch>, then add one
or more L<OpenTracing::Span> instances to it. Those instances can have zero
or more L<OpenTracing::Log> entries.

See the following classes for more information:

=over 4

=item * L<OpenTracing::Tag>

=item * L<OpenTracing::Log>

=item * L<OpenTracing::Span>

=item * L<OpenTracing::SpanProxy>

=item * L<OpenTracing::Process>

=item * L<OpenTracing::Batch>

=back

=cut

use OpenTracing::Tag;
use OpenTracing::Log;
use OpenTracing::Span;
use OpenTracing::SpanProxy;
use OpenTracing::Process;
use OpenTracing::Batch;

1;

__END__

=head1 SEE ALSO

=head2 Tools and specifications

=over 4

=item * L<https://opentracing.io> - documentation and best practices

=item * L<https://www.jaegertracing.io> - the Jæger framework

=item * L<https://www.datadoghq.com> - a commercial product with APM support

=back

=head2 Other modules

Some perl modules of relevance:

=over 4

=item * L<Net::Async::OpenTracing> - an async implementation for sending OpenTracing data
to servers via the binary Thrift protocol

=item * L<NewRelic::Agent> - support for NewRelic's APM system

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

