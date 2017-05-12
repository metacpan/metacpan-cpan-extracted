package Osgood::Server::Model::EventParameter;
use strict;

=head1 NAME

Osgood::Server::Model::EventParameter

=head1 DESCRIPTION

EventParameters are optional components of an event.

=head1 DATABASE

See 'event_parameters' table for all methods. 

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('event_parameters');
__PACKAGE__->add_columns(
	event_parameter_id => { data_type => 'bigint', is_auto_increment => 1 },
	event_id           => { data_type => 'bigint', is_foreign_key => 1 },
	name               => { data_type => 'varchar', size => 64 },
	value              => { data_type => 'varchar', size => 255 }
);
__PACKAGE__->set_primary_key('event_parameter_id');

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut

1;
