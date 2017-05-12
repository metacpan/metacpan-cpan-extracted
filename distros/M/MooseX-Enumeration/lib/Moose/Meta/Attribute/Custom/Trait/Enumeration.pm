use 5.008001;
use strict;
use warnings;

package Moose::Meta::Attribute::Custom::Trait::Enumeration;
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

sub register_implementation {
	'MooseX::Enumeration::Meta::Attribute::Native::Trait::Enumeration';
}

1;
