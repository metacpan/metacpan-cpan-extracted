package #
	ExampleMoo;

use strict;
use warnings;

use Moo;
use MooX::HandlesVia;
use MooseX::HandlesConstructor;

# HashRef
has header => ( is => 'rw',
	default => sub { {} },
	handles_via => 'Hash',
	handles => {
		session =>  [ accessor => 'session'  ],
		msg_type => [ accessor => 'msg_type' ]
	}
);

1;
