use 5.006;
use strict;
use warnings;

package Object::AUTHORITY;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.104';

use Role::Commons ();
use Role::Commons::Authority ();

sub import
{
	shift;
	my (undef, $opts) = Role::Commons::->parse_arguments(Authority => @_);
	my @packages = ref $opts->{package}
		? @{ $opts->{package} }
		: ($opts->{package}|| scalar caller);
	
	Role::Commons::->import('Authority', -into => $_) for @packages;
}

*AUTHORITY = Role::Commons::Authority::->can('AUTHORITY');

1;

