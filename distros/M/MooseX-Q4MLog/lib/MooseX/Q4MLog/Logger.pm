# $Id: /mirror/coderepos/lang/perl/MooseX-Q4MLog/trunk/lib/MooseX/Q4MLog/Logger.pm 66297 2008-07-16T13:33:55.974156Z daisuke  $

package MooseX::Q4MLog::Logger;
use Moose;
use Queue::Q4M;

has 'table' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'q_log'
);

has 'connect_info' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    auto_deref => 1,
);

has 'q4m' => (
    is => 'rw',
    isa => 'Queue::Q4M'
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILD {
    my $self = shift;
    $self->q4m( Queue::Q4M->new( connect_info => [ $self->connect_info ] ) );
}

sub log {
    my ($self, %args) = @_;
    $self->q4m->insert( $self->table, $args{q4m_args} );
}

1;

__END__

=head1 NAME

MooseX::Q4MLog::Logger - Workhorse For Q4MLog

=head1 SYNOPSIS

  # Internal use only 

=head1 METHODS

=head2 log(q4m_args => \%hash)

=cut