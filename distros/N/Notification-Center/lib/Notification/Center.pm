package Notification::Center;

use Moose;
use Scalar::Util qw(refaddr);
use Set::Object;

our $AUTHORITY = 'CPAN:RLB';
our $VERSION   = '0.0.5';

has observers => (
    is      => 'ro',
    isa     => 'HashRef[Set::Object]',
    default => sub {
        { DEFAULT => Set::Object->new };
    }
);

has method_calls => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} }
);

my $instance;
sub default {
    return $instance ||= Notification::Center->new;
};

sub add {
    my ( $self, $args ) = @_;

    my $event    = $args->{'event'} || 'DEFAULT';
    my $observer = $args->{'observer'};
    my $method   = $args->{'method'} || 'update';

    $self->observers->{$event} ||= Set::Object->new;

    $self->observers->{$event}->insert($observer);
    $self->method_calls->{ refaddr $observer }->{$event} = $method;
}

sub remove {
    my ( $self, $args ) = @_;

    my $event = $args->{'event'} || 'DEFAULT';
    my $observer = $args->{'observer'};

    delete $self->method_calls->{ refaddr $observer }->{$event};
    $self->observers->{$event}->remove($observer);
}

sub notify {
    my ( $self, $args ) = @_;

    my $event = $args->{'event'};

    return if !exists $self->observers->{$event};

    my $observers;
    if ( $event ne 'DEFAULT' ) {
        $observers = Set::Object->new( $self->observers->{$event}->members, $self->observers->{'DEFAULT'}->members );
    }
    else {
        $observers = $self->observers->{$event};
    }

    foreach my $observer ( $observers->members ) {
        my $method = $self->method_calls->{ refaddr $observer }->{$event} ||
            $self->method_calls->{ refaddr $observer }->{'DEFAULT'};
        $observer->$method($args->{'args'}) if $observer->can($method);
    }
}

1;

__END__

=pod

=head1 NAME

Notification::Center - An observer/notification for perl

=head1 SYNOPSIS

    {

        package Counter;

        use Moose;
        use Notification::Center;

        has count => ( is => 'rw', isa => 'Int', default => 0 );

        sub inc {
            my ($self) = @_;
            $self->count( $self->count + 1 );
            my $nc = Notification::Center->default;
            $nc->notify( { event => 'count', args => $self->count } );
        }

        sub dec {
            my ($self) = @_;
            $self->count( $self->count - 1 );
            my $nc = Notification::Center->default;
            $nc->notify( { event => 'count', args => $self->count } );
        }

        no Moose;

        package TrackCount;

        use Moose;

        has count => ( is => 'rw', isa => 'Int', default => 0 );

        sub print {
            my ($self) = @_;
            print $self->count;
        }

        sub get_count {
            my ( $self, $count ) = @_;
            $self->count($count);
        }

        no Moose;
    }

    my $count = Counter->new;

    my $mn = Notification::Center->default;
    my $tc = TrackCount->new;
    $mn->add(
        {
            observer => $tc,
            event    => 'count',
            method   => 'get_count',
        }
    );

    for ( 1 .. 10 ) {
        $count->inc;
    }
    for ( 1 .. 5 ) {
        $count->dec;
    }

    $tc->print;    # 5


    or use IOC using Bread::Board

    use Bread::Board;

    my $c = container 'TestApp' => as {

        service 'fname' => 'Larry';
        service 'lname' => 'Wall';

        service 'notification_center' => (
            class     => 'Notification::Center',
            lifecycle => 'Singleton',
        );

        service 'person' => (
            class        => 'Person',
            dependencies => {
                notification => depends_on('notification_center'),
                fname        => depends_on('fname'),
                lname        => depends_on('lname'),
            },
        );

        service 'upn' => (
            class        => 'UCPrintName',
            dependencies => { notification => depends_on('notification_center') },
        );

        service 'pn' => (
            class        => 'PrintName',
            dependencies => { notification => depends_on('notification_center'), },
        );
    };

    my $pn     = $c->fetch('pn')->get;
    my $upn    = $c->fetch('upn')->get;
    my $person = $c->fetch('person')->get;
    my $nc     = $c->fetch('notification_center')->get;

    $person->print_name;
    $nc->remove( { observer => $upn } );
    $person->print_name;


=head1 DESCRIPTION

An observer/notification center based on the objective-c NSNotificationCenter Class

=over

=item new

The method creates a new instance of Notification::Center object

=item default

This method creates a singleton of the Notification::Center object

=item add

args keys: observer, event, method

observer: the object that will observer events

event: the name of the event that you are assigning the observer. Defaults to DEFAULT

method: the method you want called on the observer when the event is called. Defaults to update

=item remove

args keys: observer, event

observer: the object that you want to remove

event: the name of the event that you are removing the observer. Defaults to DEFAULT

=item notify

args keys : event, args

event: the event you want to trigger

args: data you want to pass into observers

=back

=head1 GIT Repository

http://github.com/rlb3/notification-center/tree/master

=cut
