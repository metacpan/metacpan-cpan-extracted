## no critic (RequireUseStrict)
package Tapper::Producer::DummyProducer;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Producer::DummyProducer::VERSION = '5.0.1';
use Moose;


        sub produce {
                my ($self, $job, $precondition) = @_;

                die "Need a TestrunScheduling object in producer"
                 unless ref($job) eq 'Tapper::Schema::TestrunDB::Result::TestrunScheduling';
                my $type = $precondition->{options}{type} || 'no_option';
                return {
                        precondition_yaml => "---\nprecondition_type: $type\n---\nprecondition_type: second\n",
                        topic => 'new_topic',
                       };
        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Producer::DummyProducer

=head2 produce

Produce resulting precondition.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
