package Net::Radio::oFono::Helpers::EventMgr;

use strict;
use warnings;

use 5.010;

use Carp::Assert;
use Hash::MoreUtils qw(slice_grep);
use Params::Util qw(_ARRAY0 _ARRAY _CODELIKE _HASH _STRING);
use Scalar::Util qw(blessed refaddr);

use Log::Any qw($log);

=head1 NAME

Net::Radio::oFono::Helpers::EventMgr - simple event manager

DESCRIPTION

Base class for classes which want be able to trigger events and want to
delegate the event management.

=head1 METHODS

=head2 new

Constructs a new instance of a C<BDCtask>. C<BDCtask> is an abstract base
class, so instantiating this class directly is prohibited.

B<Parameters>:

This constructor expects a hash containing the named parameters:

=over 4

=item C<ON_*>

Event handler. See L<add_event> for further details.

The value for this parameter can be either a code reference, then an
event without a I<MEMO> item is generated, or a hash reference with
following items:

=over 8

=item C<FUNC>

Code reference to the callback routine.

=item C<MEMO>

Memo given to the callback routine when event is triggered.

=back

=back

B<Supported events>:

None by default - all added by derived classes ...

=cut

sub new
{
    my ( $class, %params ) = @_;

    $log->is_debug() and $log->debugf( '%s::new( %s )', $class, [ keys %params ] );

    my $self = bless( {}, $class );

    my %event_params = slice_grep( sub { $_ =~ m/^ON_/ }, \%params, keys(%params) );
    my %events;

    foreach my $event ( keys(%event_params) )
    {
        affirm { _CODELIKE( $event_params{$event} ) or _HASH( $event_params{$event} ) };
        $events{$event} =
          _CODELIKE( $event_params{$event} )
          ? [ { FUNC => $event_params{$event} } ]
          : [ $event_params{$event} ];
        affirm { _CODELIKE( $events{$event}->[0]->{FUNC} ) };
    }

    $self->{events}    = \%events;
    $self->{triggered} = {};

    return $self;
}

=head2 add_event

Adds an event to the list of actions to be executed when an event point
is reached.

B<Parameters>:

Expects following parameters in order of appearance:

=over 8

=item string

The name of the event for this callback

=item coderef

Specifies a code reference which should be called when the event is triggered.
The parameters passed to the callback are:

=over 12

=item *

C<$memo> when specified

=item *

C<$event_mgr>

=item *

C<$event_name>

=item

C<$event_info> when given

=back

Whereby the first parameter is the I<MEMO> parameter specified here and
it's omitted when not specified. The fourth parameter is an optional
information field given by the triggering routine.

=item scalar

Specifies a scalar which will be given as first argument to the callback
function which is specified with I<FUNC>.

=back

B<Return values>:

This method returns C<$self>.

=cut

sub add_event
{
    my ( $self, $event, $func, $memo ) = @_;

    _HASH($func) and ( $func, $memo ) = @$func{ "FUNC", "MEMO" };

    affirm { _CODELIKE($func) };
    $self->{events}->{$event} //= [];

    my $elem = {
                 FUNC => $func,
                 MEMO => $memo
               };
    Net::Radio::oFono::Helpers::EventMgr::Container->_add_to( $elem, $self->{events}->{$event} );

    return $self;
}

=head2 add_events(%)

Runs add_event for each key => value pair given.

=cut

sub add_events
{
    my ( $self, %event_params ) = @_;

    foreach my $event ( keys(%event_params) )
    {
        $self->add_event( $event, $event_params{$event} );
    }

    return;
}

=head2 remove_event

Removed a previously added event handler from the list of actions to be
executed when an event point is reached.

B<Parameters>:

Expects following parameters in order of appearance:

=over 8

=item string

The name of the event for this callback.

=item coderef

Specifies a code reference which should be called when the event is triggered.
The parameters passed to the callback are:

=over 12

=item *

C<$memo> when specified

=back

=back

=cut

sub remove_event
{
    my ( $self, $event, $func, $memo ) = @_;

    _HASH($func) and ( $func, $memo ) = @$func{ "FUNC", "MEMO" };

    affirm { _CODELIKE($func) };
    $self->{events}->{$event} //= [];

    my $elem = {
                 FUNC => $func,
                 MEMO => $memo
               };
    Net::Radio::oFono::Helpers::EventMgr::Container->_remove_from( $elem,
                                                                   $self->{events}->{$event} );

    return $self;
}

=head2 set_event

Sets the list of actions to be executed when an event point is reached
to a list containing just the specified event callback.

Any previously set or added event notification callback is silently
discarded.

B<Parameters>:

Expects following parameters in order of appearance:

=over 8

=item string

The name of the event for this callback

=item coderef

Specifies a code reference which should be called when the event is triggered.
The parameters passed to the callback are:

=over 12

=item *

C<$memo> when specified

=item *

C<$event_mgr>

=item *

C<$event_name>

=item

C<$event_info> when given

=back

Whereby the first parameter is the I<MEMO> parameter specified here and
it's omitted when not specified. The fourth parameter is an optional
information field given by the triggering routine.

=item scalar

Specifies a scalar which will be given as first argument to the callback
function which is specified with I<FUNC>.

=back

B<Return values>:

This method returns C<$self>.

=cut

sub set_event
{
    my ( $self, $event, $func, $memo ) = @_;

    _HASH($func) and ( $func, $memo ) = @$func{ "FUNC", "MEMO" };

    affirm { _CODELIKE($func) };
    $self->{events}->{$event} = [
                                  {
                                    FUNC => $func,
                                    MEMO => $memo
                                  }
                                ];

    return $self;
}

=head2 trigger_event

The C<event> method handles the triggering of events. Every notification
callback noted for an event is invoked when the event is triggered first
time.

When an event is tried to be triggered twice, an exception is thrown to
tell, it's forbidden.

B<Parameter>:

=over 4

=item string

The name of the event which should be triggered.

=back

B<Return values>:

This method returns C<$self>.

B<Note>:

It's strongly prohibited to override this method in derived classes. The
expected behaviour may change without notification to the authors or
maintainers of derived classes.

=cut

sub trigger_event
{
    my ( $self, $event, $info ) = @_;

    my $handled = 0;
    $log
      and $log->is_debug()
      and
      $log->debugf( 'Event <%s> reached for %s ( %s )', $event, ref($self) || __PACKAGE__, $info );

    if ( defined( $self->{events}->{$event} ) )
    {
        foreach my $eventHandler ( @{ $self->{events}->{$event} } )
        {
            my @event_params = (
                                 (
                                    defined( $eventHandler->{MEMO} ) ? ( $eventHandler->{MEMO} )
                                    : ()
                                 ),
                                 $self, $event,
                                 (
                                    defined($info) ? ($info)
                                    : ()
                                 ),
                               );
            &{ $eventHandler->{FUNC} }(@event_params);
            ++$handled;
        }

        $log
          and $log->is_debug()
          and $log->debugf( 'Event <%s> got triggered for %s ( %s ) -- %d handlers',
                            $event, ref($self) || __PACKAGE__,
                            $info, $handled );
    }

    return $self;
}

sub DESTROY { delete $_[0]->{events}; return; }

{    # hide from CPAN

    package Net::Radio::oFono::Helpers::EventMgr::Container;

    use base qw(Net::Radio::oFono::Helpers::Container);

    sub _where
    {
        my ( $self, $elem, $ary ) = @_;

        my $reffunc = refaddr( $elem->{FUNC} );
        my $refmemo = refaddr( $elem->{MEMO} );

        my $match =
          sub { refaddr( $_->{FUNC} ) == $reffunc and refaddr( $_->{MEMO} ) == $refmemo; };
        return firstidx( $match, @{$ary} );
    }
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-ofono at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-oFono>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-oFono/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
