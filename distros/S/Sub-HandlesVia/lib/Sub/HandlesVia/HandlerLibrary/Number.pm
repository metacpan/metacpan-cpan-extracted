use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Number;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Num Any Item Defined );

our @METHODS = qw( set get add sub mul div mod abs );

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type==Num or $type==Defined) {
		return {
			trust_mutated => 'maybe',
			value_type    => $type,
		};
	}
	return $me->SUPER::_type_inspector($type);
}

sub set {
	handler
		name      => 'Number:set',
		args      => 1,
		signature => [Num],
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
}

sub get {
	handler
		name      => 'Number:get',
		args      => 0,
		template  => '$GET',
}

sub add {
	handler
		name      => 'Number:add',
		args      => 1,
		signature => [Num],
		template  => '« $GET + $ARG »',
}

sub sub {
	handler
		name      => 'Number:sub',
		args      => 1,
		signature => [Num],
		template  => '« $GET - $ARG »',
}

sub mul {
	handler
		name      => 'Number:mul',
		args      => 1,
		signature => [Num],
		template  => '« $GET * $ARG »',
}

sub div {
	handler
		name      => 'Number:div',
		args      => 1,
		signature => [Num],
		template  => '« $GET / $ARG »',
}

sub mod {
	handler
		name      => 'Number:mod',
		args      => 1,
		signature => [Num],
		template  => '« $GET % $ARG »',
}

sub abs {
	handler
		name      => 'Number:abs',
		args      => 0,
		template  => '« abs($GET) »',
		additional_validation => 'no incoming values',
}

1;
