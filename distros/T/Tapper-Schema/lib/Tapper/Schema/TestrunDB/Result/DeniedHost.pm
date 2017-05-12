package Tapper::Schema::TestrunDB::Result::DeniedHost;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::DeniedHost::VERSION = '5.0.9';
# ABSTRACT: Tapper - Relation for hosts that are denied for testruns of a certain queue

use strict;
use warnings;

use parent 'DBIx::Class';

# Note: Technically, it would also be possible to extend QueueHost with another element that defines
# whether the QueueHost is bound or denied for the queue. Unfortunatelly, in this case all code using
# QueueHost would have to check this new flag and thus become more complicated. A new table may seem
# to introduce more complexity at first but in the end its the easier solution.

__PACKAGE__->load_components("Core");
__PACKAGE__->table("denied_host");
__PACKAGE__->add_columns
    (
     "id",              { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_auto_increment => 1, },
     "queue_id",        { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_foreign_key    => 1, },
     "host_id",         { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_foreign_key    => 1, },
    );

__PACKAGE__->set_primary_key(qw/id/);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->belongs_to( queue             => "${basepkg}::Queue",   { 'foreign.id' => 'self.queue_id' });
__PACKAGE__->belongs_to( host              => "${basepkg}::Host",    { 'foreign.id' => 'self.host_id'  });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::DeniedHost - Tapper - Relation for hosts that are denied for testruns of a certain queue

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
