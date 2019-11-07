use strict;
use warnings;

package HTTP::Tiny::Objects;

our ($VERSION, $AUTHORITY);
BEGIN {
	$VERSION   = '0.001';
	$AUTHORITY = 'cpan:TOBYINK';
};

use MooX::Press (
	'class:UA' => {
		extends => '::HTTP::Tiny',  # external, "::" prefix
		around  => [
			request => sub {
				my $orig = shift;
				my $self = shift;
				$self->FACTORY->new_response($self->$orig(@_));
			},
		],
	},
	'class:Response' => {
		has      => [qw(success url status reason content headers redirects)],
#		subclass => [qw(Success Failure)],
#		factory  => [
#			new_response => sub {
#				my ($f, $k) = (shift, shift);
#				my $args = ref($_[0]) ? $_[0] : { @_ };
#				$args->{success} ? $f->new_success($args) : $f->new_failure($args);
#			},
#		],
	},
);

1;

# the commented out bit can be fun
