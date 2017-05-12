package Ruby::autobox;

our $VEWRSION = '0.01';

use strict;
use warnings;

use autobox ();


use Ruby -class => qw(
	Perl::Scalar
	Perl::Hash
	Perl::Array
	Perl::Code
	Perl::Glob
	Perl::IO
	Perl::Ref
);

our %typemap = (
	SCALAR => 'Perl::Scalar',
	ARRAY  => 'Perl::Array',
	HASH   => 'Perl::Hash',
#	REF    => 'Perl::Ref',
	CODE   => 'Perl::Code',
#	IO     => 'Perl::IO',
	UNDEF  => 'Perl::Scalar',
);

sub import{
	autobox::->import(%typemap);
}
sub unimport{
	autobox::->unimport(keys %typemap);
}

1;
