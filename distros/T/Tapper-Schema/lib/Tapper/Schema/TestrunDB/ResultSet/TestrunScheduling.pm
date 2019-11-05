package Tapper::Schema::TestrunDB::ResultSet::TestrunScheduling;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::ResultSet::TestrunScheduling::VERSION = '5.0.11';
use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';


sub non_scheduled_jobs
{
        shift->search({ status => "schedule" });
}


sub max_priority_seq {
        my ($self) = @_;

        my $job_with_max_seq = $self->result_source->schema->resultset('TestrunScheduling')->search
          (
           { prioqueue_seq => { '>', 0 } },
           {
            select => [ { max => 'prioqueue_seq' } ],
            as     => [ 'max_seq' ],
            rows   => 1,
           }
          )->first;
        return $job_with_max_seq->get_column('max_seq') if $job_with_max_seq and $job_with_max_seq->get_column('max_seq');
        return 0;
}


sub running_jobs
{
        shift->search({ status => "running" });
}


sub running {
        shift->search({ status => 'running' });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::ResultSet::TestrunScheduling

=head2 non_scheduled_jobs

Return due testruns.

=head2 max_priority_seq

Search for queue with highhest C<max_seq>.

=head2 running_jobs

Return all currently running testruns.

=head2 running

Get all running jobs.

@return __PACKAGE__ object

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
