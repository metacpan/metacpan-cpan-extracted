package Mojolicious::Plugin::Fondation::Workflow::Schema::Result::Workflow;
$Mojolicious::Plugin::Fondation::Workflow::Schema::Result::Workflow::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result for the `workflow` table
#
# Column names match Workflow::Persister::DBI expectations:
#   workflow_id, type, state, last_update
# Bonus columns: resource_type, resource_id

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('workflow');

__PACKAGE__->add_columns(
    workflow_id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    type => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    state => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    last_update => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    resource_type => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },
    resource_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('workflow_id');

__PACKAGE__->has_many(
    'workflow_histories',
    'Mojolicious::Plugin::Fondation::Workflow::Schema::Result::WorkflowHistory',
    'workflow_id',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow::Schema::Result::Workflow - DBIx::Class Result for the `workflow` table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
