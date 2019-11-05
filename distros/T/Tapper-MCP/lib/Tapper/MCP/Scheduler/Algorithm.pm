## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Algorithm;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: name of the queue has to be unique
$Tapper::MCP::Scheduler::Algorithm::VERSION = '5.0.8';
use 5.010;
        use Moose;
        use Tapper::Model 'model';



        sub update_queue {
                my ($self,  $q) = @_;
                # interface
                die "Interface update_queue not implemented";
        }

        sub lookup_next_queue {
                my ($self, $queues) = @_;
                # interface
                die "Interface lookup_next_queue not implemented";
        }

        sub get_next_queue {
                my ($self, $queues) = @_;
                # interface
                die "Interface get_next_queue not implemented";
        }

        with 'MooseX::Traits';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Scheduler::Algorithm - name of the queue has to be unique

=head2 add_queue

Add a new queue to the scheduler.

@param Scheduler::Queue -

@return success - 0
@return error   - error string

=head2 remove_queue

Remove a queue from scheduling

@param string - name of the queue to be removed

@return success - 0
@return error   - error string

=head2 update_queue

Update the time entry of the given queue

@param string - name of the queue

@return success - 0

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
