package Proc::Safetynet::Event;
use strict;
use warnings;
use Carp;

use Moose;
use POSIX qw/strftime/;

has 'event' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'object' => (
    is          => 'rw',
    isa         => 'Any',
    required    => 1,
);

has 'timestamp' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => sub { time(); },
);

has 'message' => (
    is          => 'rw',
    isa         => 'Any',
    required    => 0,
);


sub as_string {
    my $self = shift;
    my @out = ();
    push @out, sprintf("timestamp:%s", strftime("%Y-%m-%d.%H:%M:%S", localtime($self->timestamp)));
    push @out, sprintf("event:%s", $self->event);
    push @out, sprintf("object:%s", $self->object);
    (defined $self->message) 
        and do { push @out, sprintf("message:%s", $self->message); };
    return join("\t", @out);
}


no Moose;


1;

__END__

