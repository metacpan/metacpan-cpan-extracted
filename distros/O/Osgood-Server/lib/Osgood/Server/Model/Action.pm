package Osgood::Server::Model::Action;
use strict;

=head1 NAME

Osgood::Server::Model::Action

=head1 DESCRIPTION

Actions are a component of events. The "verb" of the event.

=head1 DATABASE

See 'actions' table for all methods. 

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('actions');
__PACKAGE__->add_columns(
		action_id  => { data_type => 'bigint', is_auto_increment => 1 }, 
		name       => { data_type => 'varchar', size => 64 }
);
__PACKAGE__->set_primary_key('action_id');
__PACKAGE__->has_many(events => 'Osgood::Server::Model::Event', 'action_id' );

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut
1;
