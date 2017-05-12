# $Id$

package Mvalve::QueueSet;
use Moose;
use Time::HiRes();

has 'emergency_queues' => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    auto_deref => 1,
    default => sub {
        +[
            { 
                table => 'q_emerg'
            },
        ]
    }
);

has 'timed_queues' => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    auto_deref => 1,
    default => sub {
        +[
            {
                table => 'q_timed'
            },
        ]
    }
);

has 'normal_queues' => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    auto_deref => 1,
    default => sub {
        +[
            {
                table => 'q_incoming'
            },
        ]
    },
);

__PACKAGE__->meta->make_immutable;

no Moose;

# Retry queue is not counted, as it's special
sub all_queues
{
    my $self = shift;

    my @list = (
        $self->emergency_queues,
        $self->timed_queues,
        $self->normal_queues,
    );
    return wantarray ? @list : \@list;
}

sub all_tables { map { $_->{table} } ($_[0]->all_queues) }

sub choose_table {
    my ($self, $type) = @_;
    $type ||= 'normal';

    my $method = join('_', $type, 'queues');
    my @queues = $self->$method;

    return $queues[ rand(@queues) ]->{table};
}

sub as_q4m_args
{
    my $self = shift;
    my $now = Time::HiRes::time() * 100000;
    my @list = (
        (map { $_->{table} } $self->emergency_queues),
        (map { "$_->{table}:ready<" . $now } $self->timed_queues),
        (map { $_->{table} } $self->normal_queues),
    );

    return wantarray ? @list : \@list;
}

sub is_emergency
{
    my ($self, $table) = @_;
    foreach my $q ($self->emergency_queues) {
        if ($q->{table} eq $table) {
            return 1;
        }
    }
    return 0;
}

sub is_timed
{
    my ($self, $table) = @_;
    foreach my $q ($self->timed_queues) {
        if ($q->{table} eq $table) {
            return 1;
        }
    }
    return 0;
}

1;

__END__

=head1 NAME

Mvalve::QueueSet - QueueSet

=head1 METHODS

=head2 all_queues

=head2 all_tables

=head2 as_q4m_args

=head2 is_emergency

=head2 is_timed

=head2 choose_table

=cut
