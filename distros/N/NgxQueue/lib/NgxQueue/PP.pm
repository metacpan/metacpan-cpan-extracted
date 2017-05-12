package NgxQueue::PP;
use strict;
use warnings;

use Scalar::Util;

sub new {
    my ($class, $data) = @_;
    my $self = bless {data => $data}, $class;

    $self->prev($self);
    $self->next($self);

    $self;
}

sub data { shift->{data} }

for my $accessor (qw/next prev/) {
    no strict 'refs';
    *{__PACKAGE__."::$accessor"} = sub {
        use strict 'refs';
        my ($self, $arg) = @_;
        if ($arg) {
            $self->{$accessor} = $arg;
            Scalar::Util::weaken($self->{$accessor}) if $self eq $arg;
        }
        $self->{$accessor};
    };
}

sub empty {
    my $self = shift;
    $self->prev eq $self;
}

sub insert_head {
    my ($self, $queue) = @_;

    $queue->next($self->next);
    $queue->next->prev($queue);
    $queue->prev($self);
    $self->next($queue);
}
*insert_after = \&insert_head;

sub insert_tail {
    my ($self, $queue) = @_;

    $queue->prev($self->prev);
    $queue->prev->next($queue);
    $queue->next($self);
    $self->prev($queue);
}

sub head {
    shift->next;
}

sub last {
    shift->prev;
}

sub remove {
    my $self = shift;

    $self->next->prev($self->prev);
    $self->prev->next($self->next);
    $self->next(undef);
    $self->prev(undef);
}

sub split {
    my ($self, $splitter, $new) = @_;

    $new->prev($self->prev);
    $new->prev->next($new);

    $new->next($splitter);
    $self->prev($splitter->prev);
    $self->prev->next($self);

    $splitter->prev($new);
}

sub add {
    my ($self, $queue) = @_;

    $self->prev->next($queue->next);
    $queue->next->prev($self->prev);
    $self->prev($queue->prev);
    $self->prev->next($self);
}

sub foreach {
    my ($self, $cb) = @_;

    for (my $q = $self->head; $q ne $self && !$self->empty; $q = $q->next) {
        local $_ = $q;
        $cb->();
    }
}

1;

__END__

=head1 NAME

NgxQueue::PP - NgxQueue Pure-Perl backend

=head1 SYNOPSIS

See L<NgxQueue> documentation for detail.

=cut

