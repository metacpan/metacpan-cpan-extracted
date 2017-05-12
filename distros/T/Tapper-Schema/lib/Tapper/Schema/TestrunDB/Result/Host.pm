package Tapper::Schema::TestrunDB::Result::Host;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Host::VERSION = '5.0.9';
# ABSTRACT: Tapper - Containing hosts used by Tapper

use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table("host");
__PACKAGE__->add_columns
    (
     "id",         { data_type => "INT",       default_value => undef,                is_nullable => 0, size => 11,    is_auto_increment => 1, },
     "name",       { data_type => "VARCHAR",   default_value => "",                   is_nullable => 1, size => 255,                           },
     "comment",    { data_type => "VARCHAR",   default_value => "",                   is_nullable => 1, size => 255,                           },
     "free",       { data_type => "TINYINT",   default_value => "0",                  is_nullable => 1,                                        },
     "active",     { data_type => "TINYINT",   default_value => "0",                  is_nullable => 1,                                        },
     "is_deleted", { data_type => "TINYINT",   default_value => "0",                  is_nullable => 1,                                        }, # deleted hosts need to be kept in db to show old testruns correctly
     "pool_free",  { data_type => "INT",       default_value => undef,                is_nullable => 1,                                        }, # number of free hosts in pool
     "pool_id",    { data_type => "INT",       default_value => undef,                is_nullable => 1, is_foreign_key => 1,                   }, # pool host that this host is element of
     "created_at", { data_type => "TIMESTAMP", default_value => \'CURRENT_TIMESTAMP', is_nullable => 1,                                        }, # '
     "updated_at", { data_type => "DATETIME",  default_value => undef,                is_nullable => 1,                                        },

    );

__PACKAGE__->set_primary_key("id");

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;
__PACKAGE__->add_unique_constraint( constraint_name => [ qw/name/ ] );
__PACKAGE__->has_many ( testrunschedulings   => "${basepkg}::TestrunScheduling",    { 'foreign.host_id' => 'self.id' });
__PACKAGE__->has_many ( testrunrequestedhost => "${basepkg}::TestrunRequestedHost", { 'foreign.host_id' => 'self.id' });
__PACKAGE__->has_many ( queuehosts           => "${basepkg}::QueueHost",            { 'foreign.host_id' => 'self.id' });
__PACKAGE__->has_many ( denied_from_queue    => "${basepkg}::DeniedHost",           { 'foreign.host_id' => 'self.id' });
__PACKAGE__->has_many ( features             => "${basepkg}::HostFeature",          { 'foreign.host_id' => 'self.id' });


__PACKAGE__->belongs_to( pool_master         => "${basepkg}::Host",                 { 'foreign.id'      => 'self.pool_id'},{ join_type => 'left' });
__PACKAGE__->has_many  ( pool_elements       => "${basepkg}::Host",                 { 'foreign.pool_id' => 'self.id'   });



sub is_pool
{
        my($self) = @_;
        return defined($self->pool_free) || $self->pool_elements->count != 0;
}


sub pool_count
{
        my ($self, $new_count) = @_;
        if (defined $new_count) {
                # if host is not a pool yet, we make it a pool but don't need to care for existing elements
                if (not $self->is_pool) {
                        $self->pool_free($new_count);
                        $self->free(1);
                        $self->update;
                } else {
                        # need a transaction because its possible that the number
                        # of running tests changes between query and setting
                        my $guard = $self->result_source->schema->txn_scope_guard;

                        my $new_free = $new_count - $self->testrunschedulings->search({status => 'running'})->count;
                        $self->pool_free($new_free);
                        if ($self->pool_free > 0) {
                                $self->free(1);
                        } else {
                                $self->free(0);
                        }
                        $self->update;
                        $guard->commit;
                }
        } else {
                return undef unless $self->is_pool;
                return($self->pool_free + $self->testrunschedulings->search({status => 'running'})->count);
        }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Host - Tapper - Containing hosts used by Tapper

=head2 is_pool

Tell me whether the given host is a pool host or not.

=head2 pool_count

Setter/getter for all elements in a pool

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
