package Starch::Plugin::Trace;
use 5.008001;
use strictures 2;
our $VERSION = '0.13';

use Moo;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::Trace::Manager
        ::Trace::State
        ::Trace::Store
    )];
}

1;
__END__

=head1 NAME

Starch::Plugin::Trace - Add extra trace logging to your manager,
states, and stores.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::Trace'],
        ....,
    );

=head1 DESCRIPTION

This plugin logs a lot of debug information to L<Log::Any> under the
C<trace> level.

See the L<Log::Any> documentation for instructions on how to output
these log messages using an adapter.

This plugin is meant for non-production use, as logging will reduce performance.

=head1 MANAGER LOGGING

These messages are logged from the L<Starch::Manager> object.

=head2 new

Every time a L<Starch::Manager> object is created a message is
logged in the format of C<starch.manager.new>.

=head2 state

Every call to L<Starch::Manager/state> is logged in the
format of C<starch.manager.state.$action.$state_id>, where
C<$action> is either C<retrieved> or C<created> depending
on if the state ID was provided.

=head2 generate_state_id

Every call to L<Starch::Manager/generate_state_id>
is logged in the format of C<starch.manager.generate_state_id.$state_id>.

=head1 STATE LOGGING

These messages are logged from the L<Starch::State> object.

=head2 new

Every time a L<Starch::State> object is created a message is
logged in the format of C<starch.state.new.$state_id>.

=head2 save

Every call to L<Starch::State/save> is logged in the format of
C<starch.state.save.$state_id>.

=head2 delete

Every call to L<Starch::State/delete> is logged in the format of
C<starch.state.delete.$state_id>.

=head2 reload

Every call to L<Starch::State/reload> is logged in the format of
C<starch.state.reload.$state_id>.

=head2 rollback

Every call to L<Starch::State/rollback> is logged in the format of
C<starch.state.rollback.$state_id>.

=head2 clear

Every call to L<Starch::State/clear> is logged in the format of
C<starch.state.clear.$state_id>.

=head2 mark_clean

Every call to L<Starch::State/mark_clean> is logged in the format of
C<starch.state.mark_clean.$state_id>.

=head2 mark_dirty

Every call to L<Starch::State/mark_dirty> is logged in the format of
C<starch.state.mark_dirty.$state_id>.

=head2 set_expires

Every call to L<Starch::State/set_expires> is logged in the format of
C<starch.state.set_expires.$state_id>.

=head2 reset_expires

Every call to L<Starch::State/reset_expires> is logged in the format of
C<starch.state.reset_expires.$state_id>.

=head2 reset_id

Every call to L<Starch::State/reset_id> is logged in the format of
C<starch.state.reset_id.$state_id>.

=head1 STORE LOGGING

These messages are logged from the L<Starch::Store> object.

The C<$store_name> bits in the below log messages will be the name
of the store class minus the C<Starch::Store::> bit.

=head2 new

Every time a L<Starch::Store> object is created a message is
logged in the format of C<starch.store.$store_name.new>.

=head2 set

Every call to L<Starch::Store/set> is logged in the
format of C<starch.store.$store_name.set.$state_key>.

=head2 get

Every call to L<Starch::Store/get> is logged in the
format of C<starch.store.$store_name.get.$state_key>.

If the result of calling C<get> is undefined then an additional
log will produced of the format C<starch.store.$store_name.get.$state_key.missing>.

=head2 remove

Every call to L<Starch::Store/remove> is logged in the
format of C<starch.store.$store_name.remove.$state_key>.

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 LICENSE

See L<Starch/LICENSE>.

=cut

