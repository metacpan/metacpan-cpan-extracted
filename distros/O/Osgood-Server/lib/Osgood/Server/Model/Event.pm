package Osgood::Server::Model::Event;
use strict;

=head1 NAME

Osgood::Server::Model::Event

=head1 DESCRIPTION

Events consist of an action, object, and date. Optionally, it may also include
parameters.

=head1 DATABASE

See 'events' table for all methods. 

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/TimeStamp InflateColumn::DateTime PK::Auto Core/);
__PACKAGE__->table('events');
__PACKAGE__->resultset_class('Osgood::Server::ResultSet::Event');
__PACKAGE__->add_columns(
		event_id      => {data_type => 'bigint', is_auto_increment => 1},
		object_id     => {data_type => 'bigint', is_foreign_key => 1},
		action_id     => {data_type => 'bigint', is_foreign_key => 1},
		date_occurred => {data_type => 'datetime' },
		date_created  => {data_type => 'datetime', set_on_create => 1}
	);
__PACKAGE__->set_primary_key('event_id');
__PACKAGE__->has_many(parameters => 'Osgood::Server::Model::EventParameter', 'event_id' );
__PACKAGE__->add_relationship('object', 'Osgood::Server::Model::Object',
	{'foreign.object_id', 'self.object_id'},
	{'accessor' => 'single'}
);
__PACKAGE__->add_relationship('action', 'Osgood::Server::Model::Action',
	{'foreign.action_id', 'self.action_id'},
	{'accessor' => 'single'}
);

sub get_hash {
	my $self = shift;
	my $self_hash = {};

    # stash the event
    $self_hash->{'id'} = $self->id();
	$self_hash->{'date_occurred'} = $self->date_occurred();
	$self_hash->{'object'} = $self->object->name();
	$self_hash->{'action'} = $self->action->name();
	$self_hash->{'params'} = {};

	$self_hash->{params} = { map {$_->name => $_->value } $self->parameters->all };

	return $self_hash;
}

package Osgood::Server::ResultSet::Event;
use base 'DBIx::Class::ResultSet';

=head1 RESULTSET METHODS

All these method names may be passed as parameter names to event/list

=head2 object

Looks for events with the specified object name

=cut
sub object {
    my $self = shift();

    return $self->search(
		{ 'object.name' => shift() },
		{ 'join' => 'object' }
	);
}

=head2 action

Looks for events with the specified action name

=cut
sub action {
    my $self = shift();

	return $self->search(
		{ 'action.name' => shift() },
		{ 'join' => 'action' }
	);
}

sub id {
    my $self = shift();

    return $self->id_greater(shift());
}

=head2 id_greater

Looks for events with an id greater than the one specified

=cut
sub id_greater {
    my $self = shift();

    return $self->search({
        'me.event_id' => { '>' => shift() }
    });
}

=head2 id_less

Looks for events with an id less than the one specified

=cut
sub id_less {
    my $self = shift();

    return $self->search({
        'me.event_id' => { '<' => shift() }
    });
}

=head2 date_after

Returns events that occurred after the specified date.

=cut
sub date_after {
    my $self = shift();

	return $self->search({
	    'me.date_occurred' => { '>' => shift() }
	});
}

=head2 date_before

Returns events that occurred before the specified date.

=cut
sub date_before {
    my $self = shift();

	return $self->search({
	    'me.date_occurred' => { '<' => shift() }
	});
}

=head2 date_equals

Returns events that occurred before on specified date.

=cut
sub date_equals {
    my $self = shift();

	return $self->search({
	    'me.date_occurred' => shift()
	});
}

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut
1;
