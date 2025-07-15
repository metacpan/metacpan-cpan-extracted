use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050003';

use Types::Standard qw( Any Item );

sub _type_inspector {
	my ($me, $type) = @_;
	if (!$type or $type == Any or $type == Item) {
		return {
			trust_mutated => 'always',
		};
	}
	
	return { trust_mutated => 'never' };
}

{
	my %cache;
	
	sub get_handler {
		my ($me, $handler_name) = @_;
		$cache{$me} ||= $me->_populate_cache;
		$cache{$me}{$handler_name} ? $me->$handler_name : undef;
	}
	
	sub has_handler {
		my ($me, $handler_name) = @_;
		$cache{$me} ||= $me->_populate_cache;
		exists $cache{$me}{$handler_name};
	}
}

# This is not necessarily an exhaustive list, however if it is non-exhaustive
# then subclasses must override get_handler and has_handler.
#
sub handler_names {
	no strict 'refs';
	@{ $_[0] . '::METHODS' }
}

sub _populate_cache {
	my %hash;
	$hash{$_} = 1 for $_[0]->handler_names;
	\%hash;
}

sub expand_shortcut {
	use Carp;
	Carp::croak( "Not implemented" );
}

sub preprocess_spec {
	return;
}

1;
