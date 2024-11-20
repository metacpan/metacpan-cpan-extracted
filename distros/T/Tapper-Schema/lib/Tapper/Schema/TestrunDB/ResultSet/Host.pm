package Tapper::Schema::TestrunDB::ResultSet::Host;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::ResultSet::Host::VERSION = '5.0.12';
use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';
use Data::Dumper;


sub free_hosts { shift->search({ free => 1, active => 1 }) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::ResultSet::Host

=head2 free_hosts

Return hosts that are active and free.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
