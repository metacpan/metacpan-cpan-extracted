package MooX::ValidateSubs::Role;

use Moo::Role;
use Carp qw/croak/;
use Type::Utils qw//;
use Type::Params qw/compile compile_named/;
use Types::Standard qw//;

sub _validate_sub {
	my ( $self, $name, $type, $spec, @params ) = @_;
	my $store_spec = sprintf '%s_spec', $name;

	my $compiled_check = ($self->$store_spec->{"compiled_$type"} ||= do {
		if (ref $spec eq 'ARRAY') {
			my @types = map {
				my ($constraint, $default) = (@$_, 0);
				$default eq '1' ? Types::Standard::Optional->of($constraint) : $constraint;
			} @$spec;
			compile(@types);
		}
		else {
			my %types;
			for my $key (keys %$spec) {
				my ($constraint, $default) = (@{$spec->{$key}}, 0);
				$types{$key} =
					$default eq '1' ? Types::Standard::Optional->of($constraint) : $constraint;
			}
			compile_named(%types);
		}
	});

	my @count = ( scalar @params );
	if ( ref $spec eq 'ARRAY' ) {
		push @count, scalar @{$spec};

		if ( $count[0] == 1 && $count[1] != 1 and ref $params[0] eq 'ARRAY' ) {
			@params   = @{ $params[0] };
			$count[0] = scalar @params;
			$count[3] = 'ref';
		}

		$count[2] = $count[1] - grep { $spec->[$_]->[1] } 0 .. $count[1] - 1;
		$count[0] >= $count[2] && $count[0] <= $count[1]
			or croak sprintf 'Error - Invalid count in %s for sub - %s - expected - %s - got - %s',
				$type, $name, $count[1], $count[0];

		foreach ( 0 .. $count[1] - 1 ) {
			not $params[$_] and $spec->[$_]->[1]
			  and ( $spec->[$_]->[1] =~ m/^1$/ and next or $params[$_] = $self->_default( $spec->[$_]->[1] ) );
		}

		@params = $compiled_check->(@params);
		return defined $count[3] ? \@params : @params;
	}

	my %para = $count[0] == 1 ? %{ $params[0] } : @params;
	my %cry = ( %{$spec}, %para );
	foreach ( keys %cry ) {
		not $para{$_} and $spec->{$_}->[1]
			and ( $spec->{$_}->[1] =~ m/^1$/ and next or $para{$_} = $self->_default( $spec->{$_}->[1] ) );
	}

	my $paraRef = $compiled_check->(\%para);

	return $count[0] == 1 ? $paraRef : %{$paraRef};
}

sub _default {
	my ( $self, $default ) = @_;

	if ( ref $default eq 'CODE' ) {
		return $default->();
	}
	return $self->$default;
}

1;

