use strict;
use warnings;

package HTTP::Tiny::Objects;

our $VERSION   = '0.001';
our $AUTHORITY = 'cpan:TOBYINK';

use MooX::Press (
	type_library => undef,
	class => [
		'UA' => {
			extends => '::HTTP::Tiny',
			around  => [
				request => sub {
					my $orig = shift;
					my $self = shift;
					__PACKAGE__->new_response($self->$orig(@_));
				},
			],
		},
		'Response' => {
			has => [qw(success url status reason content headers redirects)],
		},
	],
);

1;
