package SDL::Tutorial::Tetris::EventManager;

#use base 'SDL::Tutorial::Tetris';

sub new {
    my ($class, %params) = @_;

    my $self = bless {%params}, $class;

    $self->{listeners} ||= {};
    $self->{evt_queue} ||= [];

    return $self;
}

sub listeners : lvalue {
    return shift->{listeners};
}

sub evt_queue : lvalue {
    return shift->{evt_queue};
}

sub reg_listener {
    my ($self, $listener) = (@_);
    $self->listeners->{$listener} = $listener
      if defined $listener;

    return $self->listeners->{$listener};
}

sub un_reg_listener {
    my ($self, $listener) = (@_);

    if (defined $listener) {
        return delete $self->listeners->{$listener};
    }
    else {
        return;
    }
}

sub post {
    my $self = shift;
    my $event = shift;

    #print 'Event' . $event->{name} . "notified\n" if $self->{EDEBUG};

    die "Post needs a Event as parameter" unless defined $event->{name};

#print 'Event' . $event->{name} ." called \n" if (!$event->isa('SDL::Tutorial::Tetris::Event::Tick') && $self->{EFDEBUG});

    foreach my $listener (values %{$self->listeners}) {
        $listener->notify($event);
    }
}

1;

__END__

=head1 NAME

SDL::Tutorial::Tetris::EventManager

=head1 DESCRIPTION

The C<EventManager> is responsible for sending events to
controllers, so they can trigger actions at specific times.

For instance, when you press a key, or the game ticks, it
is an event.

The C<EventManager> will contact all the controllers so they
can take the appropriate action.

=head2 reg_listener

=head2 un_reg_listener

=head2 listeners

=head2 evt_queue

=head2 post
