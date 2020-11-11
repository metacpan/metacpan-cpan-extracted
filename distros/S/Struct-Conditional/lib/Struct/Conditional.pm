package Struct::Conditional;
use 5.006; use strict; use warnings; our $VERSION = 0.03;
use Clone qw/clone/;

sub new {
	bless ($_[1] || {}), $_[0];
}

sub compile {
	my ($self, $struct, $params, $return_struct) = @_;
	$struct = $self->itterate(clone($struct), $params);
	die "failed to compile conditional json"
		if (defined $struct && ! ref $struct && $struct eq 'compiled_null');
	return $struct;
}

sub itterate {
	my ($self, $json, $params) = @_;
	my $ref = ref $json;
	if ($ref eq 'HASH') {
		$json = $self->loops(
			$self->conditionals($json, $params),
			$params
		);
		for my $key ( keys %{$json} ) {
			my $value = $self->itterate($json->{$key}, $params);
			$value && $value eq 'compiled_null'
				? delete $json->{$key}
				: do {
					$json->{$key} = $value;
				};
		}
		return keys %{$json} ? $json : 'compiled_null';
	} elsif ($ref eq 'ARRAY') {
		my $i = 0;
		for my $item (@{ $json }) {
			my $value = $self->itterate($item, $params);
			$value && $value eq 'compiled_null'
				? do {
					splice @{$json}, $i, 1;
				}
				: $i++;
		}
	}
	return $self->make_replacement($json, $params);
}

sub loops {
	my ($self, $json, $params) = @_;
	my %loops = map {
		($_ => delete $json->{$_})
	} qw/for/;
	if ($loops{for}) {
		my $key = delete $loops{for}{key};
		die "no key defined for loop" unless defined $key;
		if ($loops{for}{each}) {
			my @each = ();
			my $map = delete $loops{for}{each};
			die "param $key must be an arrayref"
				unless (ref($params->{$key}) || "") eq 'ARRAY';
			for (@{$params->{$key}}) {
				my $jsn = $self->conditionals(clone($loops{for}), $_);
				push @each, $self->make_replacement($jsn, $_) if scalar keys %{$jsn};
			}
			$json->{$map} = \@each if scalar @each;
		}
		if ($loops{for}{keys}) {
			my %keys = ();
			my $map = delete $loops{for}{keys};
			die "param $key muse be an hashref"
				unless (ref($params->{$key}) || "") eq 'HASH';
			for my $k (keys %{$params->{$key}}) {
				my $jsn = $self->conditionals(
					clone($loops{for}),
					$params->{$key}->{$k}
				);
				$keys{$k} = $self->make_replacement($jsn, $params->{$key}->{$k}) if scalar keys %{$jsn};
			}
			if (scalar %keys) {
				$map =~ m/^1$/ ? do {
					for my $k (keys %keys) {
						$json->{$k} = $keys{$k};
					}
				} : do {
					$json->{$map} = \%keys;
				}
			}
		}
	}
	return $json;
}

sub conditionals {
	my ($self, $json, $params) = @_;
	my %keywords = map {
		($_ => delete $json->{$_})
	} qw/if elsif else given/;
	my $expression;
	if ($keywords{if}) {
		($expression) = $self->expressions($keywords{if}, $params);
		unless ($expression) {
			if ($keywords{elsif}) {
				($expression) = $self->expressions($keywords{elsif}, $params);
			}
			unless ($expression) {
				if ($keywords{else}) {
					($expression) = $keywords{else}->{then};
				}
			}
		}
		if ($expression) {
			$json->{$_} = $expression->{$_} for ( keys %{$expression} );
		}
	}
	if ($keywords{given}) {
		die "no key provided for given" if ! $keywords{given}{key};
		die "no when provided for given" if ! ref $keywords{given}{when};
		my $default = delete $keywords{given}{default};
		my $ref = ref $keywords{given}{when};
		if ($ref eq 'ARRAY') {
			for (@{ $keywords{given}{when} }) {
				$_->{key} ||= $keywords{given}{key};
				($expression) = $self->expressions($_, $params);
				last if $expression;
			}
		} elsif ($ref eq 'HASH') {
			$default ||= delete $keywords{given}{when}{default};
			for my $k (keys %{ $keywords{given}{when} }) {
				($expression) = $self->expressions(
					{
						key => $keywords{given}{key},
						m => $k,
						then => $keywords{given}{when}{$k}
					},
					$params
				);
				last if $expression;
			}
		} else {
			die "given cannot handle ref $ref";
		}
		$expression = $default if ! $expression;
		if ($expression) {
			$json->{$_} = $expression->{$_} for ( keys %{$expression} );
		}
	}
	return $json;
}

sub expressions {
	my ($self, $keyword, $params) = @_;
	my $success = 0;
	$success = exists $params->{$keyword->{key}}
		if defined $keyword->{exists};
	my $key = $params->{$keyword->{key}};
	if (defined $key) {
		$success = $key =~ m/\Q$keyword->{m}\E/
			if !$success && defined $keyword->{m};
		$success = $key =~ m/\Q$keyword->{m}\E/i
			if !$success && defined $keyword->{im};
		$success = $key !~ m/\Q$keyword->{nm}\E/
			if !$success && defined $keyword->{nm};
		$success = $key !~ m/\Q$keyword->{nm}\E/i
			if !$success && defined $keyword->{inm};
		$success = $key eq $keyword->{eq}
			if !$success && defined $keyword->{eq};
		$success = $key ne $keyword->{ne}
			if !$success && defined $keyword->{ne};
		$success = $key > $keyword->{gt}
			if !$success && defined $keyword->{gt};
		$success = $key < $keyword->{lt}
			if !$success && defined $keyword->{lt}
	}
	if ($keyword->{or} && !$success) {
		$keyword->{or}->{then} = $keyword->{then};
		($success, $keyword) = $self->expressions($keyword->{or}, $params)
	}
	if ($keyword->{and} && $success) {
		$keyword->{and}->{then} = $keyword->{then};
		($success, $keyword) = $self->expressions($keyword->{and}, $params)
	}
	if ($keyword->{elsif} && !$success) {
		$keyword = $keyword->{elsif};
		($success, $keyword) = $self->expressions($keyword, $params);
	}
	($success, $keyword) = ($keyword->{else}->{then}, $keyword->{else})
		if ($keyword->{else} && !$success);
	return (($success ? $keyword->{then} : 0), $keyword);
}

sub make_replacement {
	my ($self, $then, $params, $params_reg) = @_;
	$params_reg ||= join "|", keys %{$params};
	my $ref = ref $then || "";
	if ($ref eq 'HASH') {
		$then->{$_} = $self->make_replacement($then->{$_}, $params, $params_reg)
			for keys %{$then};
	} elsif ($ref eq 'ARRAY') {
		$then = [map { $self->make_replacement($_, $params, $params_reg) } @{ $then }];
	} elsif (defined $then && $then =~ m/\{($params_reg)\}/) {
		$then = $params->{$1};
	}
	return $then;
}

1;

__END__

=head1 NAME

Struct::Conditional - A Conditional language within a perl struct.

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Struct::Conditional;

	my $c = Struct::Conditional->new();

	my $struct = {
		for => {
			key => "countries",
			each => "countries",
			if => {
				m => "Thailand",
				key => "country",
				then => {
					"rank": 1
				}
			},
			elsif => {
				m => "Indonesia",
				key => "country",
				then => {
					rank => 2
				}
			},
			else => {
				then => {
					rank => null
				}
			},
			country => "{country}"
		}
	};

	$struct = $c->compile($struct, {
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	}, 1);

	...

	{
		countries => [
			{
				rank => 1,
				country => "Thailand"
			},
			{
				rank => 2,
				country => 'Indonesia'
			},
			{
				rank => undef
				country => 'Japan',
			},
			{
				rank => undef,
				country => 'Cambodia'
			}
		]
	};

=head1 METHODS

=head2 new

Instantiate a new Struct::Conditional object. Currently this expects no arguments.

	my $c = Struct::Conditional->new;

=head2 compile

Compile a struct containing valid Struct::Conditional markup into a perl struct based upon the passed params.

	$c->compile($struct, $params); 

=head2 itterate

Itterate a perl struct that contains valid Struct::Conditional markup and return a perl struct based upon the passed params.

	$c->itterate($perl_struct, $params);

=head1 Markup or Markdown

=head2 keywords

=head3 if, elsif, else

If, elsif and else conditionals are logical blocks used within Struct::Conditional. They are comprised of a minimum of four parts, the keyword, the expression, 'key' and 'then'. The expression can be any that are defined in the expression section of this document. The 'key' is the value in the params that will be evaluated and the 'then' is the response that is returned if the expression is true.

	my $struct = {
		if => {
			m => "Thailand",
			key => "country",
			then => {
				rank => 1
			}
		},
		elsif => {
			m => "Indonesia",
			key => "country",
			then => {
				rank => 2
			}
		},
		else => {
			then => {
				rank => null
			}
		},
		country => "{country}"
	};

	$struct = $c->compile($struct, {
		country => "Thailand"
	}, 1);

	...

	{
		country => "Thailand",
		rank => 1
	}

You can also write this like the following:

	my $struct = {
		if => {
			m => "Thailand",
			key => "country",
			then => {
				rank => 1
			},
			elsif => {
				m => "Indonesia",
				key => "country",
				then => {
					rank => 2
				},
				else => {
					then => {
						rank => null
					}
				}
			}
		},
		country => "{country}"
	};

	$struct = $c->compile($struct, {
		country => "Indonesia"
	}, 1);

	...

	{
		country => "Indonesia",
		rank => 2
	}

=head3 given

Given conditionals are logical blocks used within Struct::Conditional. They are comprised of a minimum of three parts, the keyword, 'when' and'key'. The 'when' can either be an array or a hash of expression that are defined in the expression section of this document. The 'key' is the value in the params that will be evaluated. You can optionally provide a default which will be used when no 'when' expressions are matched.

	my $struct = {
		given => {
			key => "country",
			default => {
				rank => null
			},
			when => [
				{
					m => "Thailand",
					then => {
						rank => 1
					}
				},
				{
					m => "Indonesia",
					then => {
						rank => 2
					}
				}
			]
		},
		country => "{country}"
	};

	my $compiled = $c->compile($struct, {
		country => "Thailand"
	}, 1);

	...

	{
		country => "Thailand"
		rank => 1
	}

You can also write this like the following:

	my $struct = {
		given => {
			key => "country",
			when => {
				Thailand => {
					rank => 1
				},
				Indonesia => {
					rank => 2
				},
				default => {
					rank => null
				}
			}
		},
		country => "{country}"
	};

	my $compiled = $c->compile($struct, {
		country => "Indonesia"
	}, 1);

	...

	{
		country => "Indonesia"
		rank => 1
	}

=head3 or

The 'or' keyword allows you to chain expression checks, where only one expression has to match.

	my $struct = {
		if => {
			m => "Thailand",
			key => "country",
			then => {
				rank => 1,
				country => "{country}"
			},
			or => {
				key => "country",
				m => "Maldives",
				or => {
					key => "country",
					m => "Greece"
				}
			}
		},
	};


	my $compiled = $c->compile($struct, {
		country => "Greece"
	}, 1);

	...

	{
		country => "Greece"
		rank => 1
	}

=head3 and

The 'and' keyword allows you to chain expression checks, where only all expression has to match.

	my $struct = {
		if => {
			m => "Thailand",
			key => "country",
			then => {
				rank => 1,
				country => "{country}"
			},
			and => {
				key => "season",
				m => "Summer",
			}
		}
	};


	my $compiled = $c->compile($struct, {
		country => "Thailand",
		season => "Summer"
	}, 1);

	...

	{
		country => "Thailand",
		rank => 1
	}


=head2 expressions

=head3 m

Does the params key value match the provided regex value.

	{
		key => $param_key,
		m => $regex,
		then => \%then
	}

=head3 im

Does the params key value match the provided regex value case insensative.

	{
		key => $param_key,
		im => $regex,
		then => \%then
	}

=head3 nm

Does the params key value not match the provided regex value.

	{
		key => $param_key,
		nm => $regex,
		then => \%then
	}

=head3 inm

Does the params key value not match the provided regex value case insensative.

	{
		key => $param_key,
		inm => $regex,
		then => \%then
	}


=head3 eq

Does the params key value equal the provided value.

	{
		key => $param_key,
		eq => $equals,
		then => \%then
	}

=head3 ne

Does the params key value not equal the provided value.

	{
		key => $param_key,
		ne => $equals,
		then => \%then
	}

=head3 gt

Is the params key value greater than the provided value.

	{
		key => $param_key,
		gt => $greater_than,
		then => \%then
	}

=head3 lt

Is the params key value less than the provided value.

	{
		key => $param_key,
		lt => $greater_than,
		then => \%then
	}

=head2 placeholders

All parameters that are passed into compile can be used as placeholders within the struct. You can define a placeholder by enclosing a key in braces.

	{
		placeholder => "{param_key}"
	}

=head2 loops

=head3 for

=head4 each

Expects key to reference a array in the passed params. It will then itterate each item in the array and build an array based upon which conditions/expressions are met.

	my $struct = {
		for => {
			key => "countries",
			each => "countries",
			country => "{country}"
		}
	};

	$struct = $c->compile($struct, {
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	}, 1);

	...

	{
		countries => [
			{
				country => "Thailand"
			},
			{
				country => 'Indonesia'
			},
			{
				country => 'Japan',
			},
			{
				country => 'Cambodia'
			}
		]
	};

=head4 keys

Expects key to reference a hash in the passed params. It will then itterate keys in the hash and build an hash based upon which conditions/expressions are met.

	my $struct = {
		for => {
			key => "countries",
			keys => 1,
			country => "{country}"
		},
	};

	$struct = $c->compile($struct, {
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}, 1);

	...

	{
		1 => { country => "Thailand" },
		2 => { country => "Indonesia" },
		3 => { country => "Japan" },
		4 => { country => "Cambodia" },
	}

	===================================================

	my $struct = {
		for => {
			key => "countries",
			keys => "countries",
			country => "{country}"
		},
	};

	$struct = $c->compile($struct, {
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}, 1);

	...

	{
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-conditional at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Conditional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Struct::Conditional

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Conditional>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Struct-Conditional>

=item * Search CPAN

L<https://metacpan.org/release/Struct-Conditional>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Struct::Conditional
