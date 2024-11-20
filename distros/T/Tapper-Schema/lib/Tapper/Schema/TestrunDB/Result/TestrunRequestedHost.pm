package Tapper::Schema::TestrunDB::Result::TestrunRequestedHost;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::TestrunRequestedHost::VERSION = '5.0.12';
# ABSTRACT: Tapper - Relate testruns with hosts ( requested )

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("testrun_requested_host");
__PACKAGE__->add_columns
    (
     "id",              { data_type => "INT",     default_value => undef, is_nullable => 0, size => 11, is_auto_increment => 1, },
     "testrun_id",      { data_type => "INT",     default_value => undef, is_nullable => 0, size => 11, is_foreign_key    => 1, },
     "host_id",         { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_foreign_key    => 1, },
    );

__PACKAGE__->set_primary_key(qw/id/);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->belongs_to( testrunscheduling => "${basepkg}::Testrun", { 'foreign.id' => 'self.testrun_id' });
__PACKAGE__->belongs_to( host              => "${basepkg}::Host",    { 'foreign.id' => 'self.host_id'    });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::TestrunRequestedHost - Tapper - Relate testruns with hosts ( requested )

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
