package PulseAudio::Roles::Object;
use strict;
use warnings;

use Moose::Role;

has 'server' => (
	isa        => 'PulseAudio'
	, is       => 'ro'
	, required => 1
);

has '_dump' => (
	isa        => 'HashRef'
	, is       => 'ro'
	, required => 1
	, init_arg => 'dump'
	, traits   => ['Hash']

	, handles  => {
		'get' => 'get'
	}
);

1;
