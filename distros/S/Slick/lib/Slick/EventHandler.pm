package Slick::EventHandler;

use 5.036;

use Moo::Role;
use Types::Standard qw(HashRef);
use Carp            qw(croak);
use Slick::Events   qw(EVENTS);
use List::Util      qw(reduce);

has event_handlers => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef,
    default => sub {
        my $r;
        @$r{ @{ EVENTS() } } = map { [] } EVENTS->@*;
        return $r;
    }
);

# Register an event (middleware)
sub on {
    my ( $self, $event, $code ) = @_;

    croak qq{Invalid type specified for event, expected CODE got } . ref($code)
      unless ( ref($code) eq 'CODE' );

    croak qq{Invalid event '$event', I only know of ( }
      . ( reduce { $a . ', ' . $b } EVENTS->@* ) . ' )'
      unless exists $self->event_handlers->{$event};

    push @{ $self->event_handlers->{$event} }, $code;
    return $code;
}

1;

=encoding utf8

=head1 NAME
Slick::EventHandler

=head1 SYNOPSIS

A L<Moo::Role> that allows the registering of events via a C<on> method.

=head1 API

=head2 on

Registers a C<CodeRef> with a given event name. Only allows registering of events
that exist within L<Slick::Events>.

=over 2

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
