## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Dummy algorithm for testing
$Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm::VERSION = '5.0.8';
use 5.010;
        use Moose::Role;

        has current_queue_name => (is => "rw");

        sub lookup_next_queue {
                my ($self, $queues) = @_;

                my @ordered_queues   = map { $queues->{$_} } sort keys %{$queues};
                return shift @ordered_queues if not $self->current_queue_name;

                for my $i (0 .. $#ordered_queues) {
                        if ($self->current_queue_name eq $ordered_queues[$i]->name) {
                                return $ordered_queues[($i+1) % int @ordered_queues];
                        }
                }
                return shift @ordered_queues;
        }

        sub get_next_queue {
                my ($self, $queues) = @_;

                my $return_queue = $self->lookup_next_queue($queues);

                $self->update_queue($return_queue);
                return $return_queue;
        }

        sub update_queue {
                my ($self, $Q) = @_;

                $self->current_queue_name( $Q->name );
                return 0;
        }

1; # End of Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm - Dummy algorithm for testing

=head1 SYNOPSIS

Algorithm that returns queues in order it received it. It sorts all
queues it gets by name an remembers which queue it gave out last
time. When the queue chosen last time is still in the list of given
queues the algorithm returns its successor in the order. Otherwise it
returns the first queue in the order.

=head1 FUNCTIONS

=head2 get_next_queue

Evaluate which client has to be scheduled next.

@return success - client name;

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
