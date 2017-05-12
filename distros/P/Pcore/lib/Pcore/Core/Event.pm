package Pcore::Core::Event;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Core::Event::Listener;

has listeners => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub listen_events ( $self, $events, $cb ) {
    $events = [$events] if ref $events ne 'ARRAY';

    my $listener = Pcore::Core::Event::Listener->new(
        {   broker => $self,
            events => $events,
            cb     => $cb,
        }
    );

    my $wantarray = defined wantarray;

    for my $event ( $events->@* ) {
        push $self->{listeners}->{$event}->@*, $listener;

        weaken $self->{listeners}->{$event}->[-1] if $wantarray;
    }

    return $wantarray ? $listener : ();
}

sub has_listeners ( $self, $events ) {
    $events = [$events] if ref $events ne 'ARRAY';

    for my $event ( $events->@* ) {
        return 1 if exists $self->{listeners}->{$event};
    }

    return 0;
}

sub fire_event ( $self, $event, $data = undef ) {
    if ( my $listeners = $self->{listeners}->{$event} ) {
        for my $listener ( $listeners->@* ) {
            $listener->{cb}->( $event, $data );
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event - Pcore event broker

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
