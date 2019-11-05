package Tapper::Schema::TestrunDB::ResultSet::ReportgroupTestrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::ResultSet::ReportgroupTestrun::VERSION = '5.0.11';
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';


sub groupreports {
        my ($self) = @_;

        $self->search({}, {rows => 1})->first->groupreports;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::ResultSet::ReportgroupTestrun

=head2 groupreports

Return the group of all reports belonging to the first testrun of
current result set.

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
