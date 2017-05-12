package Osgood::Server::Model::Object;
use strict;

=head1 NAME

Osgood::Server::Model::Object

=head1 DESCRIPTION

Objects are a component of events. The "noun" of the event.

=head1 DATABASE

See 'objects' table for all methods. 

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('objects');
__PACKAGE__->add_columns(
	object_id  => { data_type => 'bigint', is_auto_increment => 1 },
	name       => { data_type => 'varchar', size => 64 }
);
__PACKAGE__->set_primary_key('object_id');
__PACKAGE__->has_many(events => 'Osgood::Server::Model::Event', 'object_id' );

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut

1;
