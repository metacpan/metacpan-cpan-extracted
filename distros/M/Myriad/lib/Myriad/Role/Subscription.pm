package Myriad::Role::Subscription;

use Myriad::Class type => 'role';

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Subscription - microservice subscription abstraction

=head1 SYNOPSIS

 my $storage = $myriad->subscription;

=head1 DESCRIPTION

=head1 Implementation

Note that this is defined as a rôle, so it does not provide
a concrete implementation - instead, see classes such as:

=over 4

=item * L<Myriad::Subscription::Implementation::Redis>

=item * L<Myriad::Subscription::Implementation::Memory>

=back

=cut

=head1 METHODS

=head2 create_from_sink

Register a new C<Receiver> to notify it when there is new data.

it takes a hash as an argument that should have the following

=over 4

=item * C<sink> - a L<Ryu::Sink> that the subscription will emit new messages to.

=item * C<channel> - The events channel name where the C<Emitter> will emit the new events.

=item * C<client> - The name that this C<Receiver> should use while fetching new events.

=back

=cut

method create_from_sink;

=head2 create_from_source

Register a new C<Emitter> to receive events from.

it takes a hash as an argument that should have the following

=over 4

=item * C<source> - a L<Ryu::Source> where the messages will be emitted to.

=item * C<channel> - The name of the events channel that should be used to send the messages to.

=back

=cut

method create_from_source;

=head2 start

Start processing the subscriptions.

=cut

method start;

=head2 stop

Stop processing the subscriptions.

=cut

method stop;

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

