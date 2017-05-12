use strict;
use warnings;

package Petal::CodePerl::Expr::DerefTAL;

use base qw( Code::Perl::Expr::Base );

use Class::MethodMaker (
	get_set => [qw( -java Key Ref Strict )]
);

use Scalar::Util qw(blessed reftype );

sub eval
{
	my $self = shift;

	my $ref = $self->getRef->eval;
	my $key = $self->getKey;

	ref($ref) || die "Not a ref";

	if ($self->getStrict)
	{
		return Scalar::Util::blessed($ref) ?
			$ref->$key() :
			reftype($ref) eq 'ARRAY' ? $ref->[$key] : $ref->{$key};
	}
	else
	{
		return Scalar::Util::blessed(\$ref) && (UNIVERSAL::can($ref, $key) or UNIVERSAL::can($ref, "AUTOLOAD")) ?
			$ref->$key() :
			reftype($ref) eq 'ARRAY' ? $ref->[$key] : $ref->{$key};
	}
}

sub perl
{
	my $self = shift;

	my $ref_perl = "(".$self->getRef->perl.")";
	my $key = $self->getKey;

	my $method = 0;
	my $number = 0;
	if ($key =~ /^[a-z_][a-z0-9_-]*/i)
	{
		$method = 1;
	}
	elsif($key =~ /^\d+$/)
	{
		$number = 1;
	}

	my $assign = qq{ref(my \$ref = $ref_perl) || die "Not a ref"};

	if (! $number and ! $method)
	{
		# it must be a hash key
		return qq{($ref_perl)->{"$key"}};
	}
	elsif($number)
	{
		# look like a number but could be a hash key
		return qq{do{$assign; Scalar::Util::reftype(\$ref) eq 'ARRAY' ? \$ref->[$key] : \$ref->{$key}}};
	}
	else
	{
		# looks like a method name but could be a hash key

		if($self->getStrict)
		{
			# strict mode means NEVER treat a blessed object as just a hash

			return qq{Scalar::Util::blessed(\$ref) ? \$ref->$key() : \$ref->{"$key"}};
		}
		else
		{
			# non-strict means check to see if the method exists, if not then fall
			# back to using hash

			return qq{do{$assign; Scalar::Util::blessed(\$ref) && (UNIVERSAL::can(\$ref, "$key") or UNIVERSAL::can(\$ref, "AUTOLOAD")) ? \$ref->$key() : \$ref->{"$key"}}};
		}
	}
}

1;
