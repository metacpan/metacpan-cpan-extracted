package Mojolicious::Plugin::Fondation::Workflow::Schema::Result::WorkflowHistory;
$Mojolicious::Plugin::Fondation::Workflow::Schema::Result::WorkflowHistory::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result for the `workflow_history` table
#
# Column names match Workflow::Persister::DBI expectations:
#   workflow_hist_id, workflow_id, action, description, state, workflow_user, history_date
# Bonus columns: user_id, comment, from_state, to_state

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('workflow_history');

__PACKAGE__->add_columns(
    workflow_hist_id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    workflow_id => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    action => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    description => {
        data_type   => 'text',
        is_nullable => 1,
    },
    state => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    workflow_user => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },
    history_date => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    # ── Fondation bonus columns (not used by Workflow::Persister::DBI) ──
    user_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    comment => {
        data_type   => 'text',
        is_nullable => 1,
    },
    from_state => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 1,
    },
    to_state => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('workflow_hist_id');

__PACKAGE__->belongs_to(
    'workflow',
    'Mojolicious::Plugin::Fondation::Workflow::Schema::Result::Workflow',
    { 'foreign.workflow_id' => 'self.workflow_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow::Schema::Result::WorkflowHistory - DBIx::Class Result for the `workflow_history` table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
