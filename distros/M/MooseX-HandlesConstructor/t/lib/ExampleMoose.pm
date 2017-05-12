package #
	ExampleMoose;

use strict;
use warnings;

use Moose;
use MooseX::HandlesConstructor;

# HashRef
has header => ( is => 'rw',
	default => sub { {} },
	traits => ['Hash'],
	handles => {
		session =>  [ accessor => 'session'  ],
		msg_type => [ accessor => 'msg_type' ]
	}
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
