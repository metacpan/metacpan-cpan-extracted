use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Array;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.037';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( ArrayRef Optional Str CodeRef Int Item Any Ref Defined FileHandle );

our @METHODS = qw( count is_empty all elements flatten get pop push shift
	unshift clear first first_index reduce set accessor natatime any
	shallow_clone map grep sort reverse sort_in_place splice shuffle
	shuffle_in_place uniq uniq_in_place delete insert flatten flatten_deep
	join print head tail apply pick_random for_each for_each_pair
	all_true not_all_true min minstr max maxstr sum product
	reductions sample uniqnum uniqnum_in_place uniqstr uniqstr_in_place
	pairs pairkeys pairvalues pairgrep pairfirst pairmap reset );

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type == ArrayRef or $type == Defined or $type == Ref) {
		return {
			trust_mutated => 'always',
		};
	}
	if ($type->is_parameterized
	and $type->parent->name eq 'ArrayRef'
	and $type->parent->library eq 'Types::Standard'
	and 1==@{$type->parameters}) {
		return {
			trust_mutated => 'maybe',
			value_type    => $type->type_parameter,
		};
	}
	return $me->SUPER::_type_inspector($type);
}

my $additional_validation_for_push_and_unshift = sub {
	my $self = CORE::shift;
	my ($sig_was_checked, $gen) = @_;
	my $ti = __PACKAGE__->_type_inspector($gen->isa);
	
	if ($ti and $ti->{trust_mutated} eq 'always') {
		return { code => '1;', env => {} };
	}
	
	if ($ti and $ti->{trust_mutated} eq 'maybe') {
		my $coercion = ( $gen->coerce and $ti->{value_type}->has_coercion );
		if ( $coercion ) {
			my $env = {};
			my $code = sprintf(
				'my @shv_values = map { my $shv_value = $_; %s } %s;',
				$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
				$gen->generate_args,
			);
			return {
				code      => $code,
				env       => $env,
				arg       => sub { "\$shv_values[($_[0])-1]" },
				args      => sub { '@shv_values' },
				argc      => sub { 'scalar(@shv_values)' },
			};
		}
		else {
			my $env = {};
			my $code = sprintf(
				'for my $shv_value (%s) { %s }',
				$gen->generate_args,
				$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
			);
			return {
				code      => $code,
				env       => $env,
			};
		}
	}
	return;
};

my $additional_validation_for_set_and_insert = sub {
	my $self = CORE::shift;
	my ($sig_was_checked, $gen) = @_;
	my $ti = __PACKAGE__->_type_inspector($gen->isa);
	
	if ($ti and $ti->{trust_mutated} eq 'always') {
		return { code => '1;', env => {} };
	}
	
	my ( $arg, $code, $env );
	$env = {};
	if ($ti and $ti->{trust_mutated} eq 'maybe') {
		$arg = sub {
			my $gen = CORE::shift;
			return '$shv_index' if $_[0]=='1';
			return '$shv_value' if $_[0]=='2';
			$gen->generate_arg( @_ );
		};
		if ( $sig_was_checked ) {
			$code = sprintf(
				'my($shv_index,$shv_value)=%s; %s;',
				$gen->generate_args,
				$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
			);
		}
		else {
			$code = sprintf(
				'my($shv_index,$shv_value)=%s; %s; %s;',
				$gen->generate_args,
				$gen->generate_type_assertion( $env, Int, '$shv_index' ),
				$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
			);
		}
	}
	return {
		code      => $code,
		env       => $env,
		arg       => $arg,
	};
};

sub count {
	handler
		name      => 'Array:count',
		args      => 0,
		template  => 'scalar(@{$GET})',
		documentation => 'The number of elements in the referenced array.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar' ] );\n",
				"  say \$object->$method; ## ==> 2\n",
				"\n";
		},
}

sub is_empty {
	handler
		name      => 'Array:is_empty',
		args      => 0,
		template  => '!scalar(@{$GET})',
		documentation => 'Boolean indicating if the referenced array is empty.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar' ] );\n",
				"  say \$object->$method; ## ==> false\n",
				"  \$object->_set_$attr( [] );\n",
				"  say \$object->$method; ## ==> true\n",
				"\n";
		},
}

sub all {
	handler
		name      => 'Array:all',
		args      => 0,
		template  => '@{$GET}',
		documentation => 'All elements in the array, in list context.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar' ] );\n",
				"  my \@list = \$object->$method;\n",
				"  say Dumper( \\\@list ); ## ==> [ 'foo', 'bar' ]\n",
				"\n";
		},
}

sub elements {
	handler
		name      => 'Array:elements',
		args      => 0,
		template  => '@{$GET}',
		documentation => 'All elements in the array, in list context. (Essentially the same as C<all>.)',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar' ] );\n",
				"  my \@list = \$object->$method;\n",
				"  say Dumper( \\\@list ); ## ==> [ 'foo', 'bar' ]\n",
				"\n";
		},
}

sub flatten {
	handler
		name      => 'Array:flatten',
		args      => 0,
		template  => '@{$GET}',
		documentation => 'All elements in the array, in list context. (Essentially the same as C<all>.)',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar' ] );\n",
				"  my \@list = \$object->$method;\n",
				"  say Dumper( \\\@list ); ## ==> [ 'foo', 'bar' ]\n",
				"\n";
		},
}

sub get {
	handler
		name      => 'Array:get',
		args      => 1,
		signature => [Int],
		usage     => '$index',
		template  => '($GET)->[$ARG]',
		documentation => 'Returns a single element from the array by index.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  say \$object->$method(  0 ); ## ==> 'foo'\n",
				"  say \$object->$method(  1 ); ## ==> 'bar'\n",
				"  say \$object->$method( -1 ); ## ==> 'baz'\n",
				"\n";
		},
}

sub pop {
	my $me = CORE::shift;
	handler
		name      => 'Array:pop',
		args      => 0,
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = pop @shv_tmp; «\\@shv_tmp»; $shv_return',
		lvalue_template => 'pop(@{$GET})',
		additional_validation => 'no incoming values',
		documentation => 'Removes the last element from the array and returns it.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  say \$object->$method; ## ==> 'baz'\n",
				"  say \$object->$method; ## ==> 'bar'\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'foo' ]\n",
				"\n";
		},
}

sub push {
	my $me = CORE::shift;
	handler
		name      => 'Array:push',
		usage     => '@values',
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = push(@shv_tmp, @ARG); «\\@shv_tmp»; $shv_return',
		lvalue_template => 'push(@{$GET}, @ARG)',
		prefer_shift_self => 1,
		additional_validation => $additional_validation_for_push_and_unshift,
		documentation => 'Adds elements to the end of the array.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo' ] );\n",
				"  \$object->$method( 'bar', 'baz' );\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'foo', 'bar', 'baz' ]\n",
				"\n";
		},
}

sub shift {
	my $me = CORE::shift;
	handler
		name      => 'Array:shift',
		args      => 0,
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = shift @shv_tmp; «\\@shv_tmp»; $shv_return',
		lvalue_template => 'shift(@{$GET})',
		additional_validation => 'no incoming values',
		documentation => 'Removes an element from the start of the array and returns it.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  say \$object->$method; ## ==> 'foo'\n",
				"  say \$object->$method; ## ==> 'bar'\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'baz' ]\n",
				"\n";
		},
}

sub unshift {
	my $me = CORE::shift;
	handler
		name      => 'Array:unshift',
		usage     => '@values',
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = unshift(@shv_tmp, @ARG); «\\@shv_tmp»; $shv_return',
		lvalue_template => 'unshift(@{$GET}, @ARG)',
		prefer_shift_self => 1,
		additional_validation => $additional_validation_for_push_and_unshift,
		documentation => 'Adds an element to the start of the array.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo' ] );\n",
				"  \$object->$method( 'bar', 'baz' );\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'bar', 'baz', 'foo' ]\n",
				"\n";
		},
}

sub clear {
	my $me = CORE::shift;
	handler
		name      => 'Array:clear',
		args      => 0,
		template  => '«[]»',
		lvalue_template => '@{$GET} = ()',
		additional_validation => 'no incoming values',
		documentation => 'Empties the array.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo' ] );\n",
				"  \$object->$method;\n",
				"  say Dumper( \$object->$attr ); ## ==> []\n",
				"\n";
		},
}

sub first {
	require List::Util;
	handler
		name      => 'Array:first',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => '&List::Util::first($ARG, @{$GET})',
		documentation => 'Like C<< List::Util::first() >>.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  my \$found  = \$object->$method( sub { /a/ } );\n",
				"  say \$found; ## ==> 'bar'\n",
				"\n";
		},
}

sub any {
	require List::Util;
	handler
		name      => 'Array:any',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => '&List::Util::any($ARG, @{$GET})',
		documentation => 'Like C<< List::Util::any() >>.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  my \$truth  = \$object->$method( sub { /a/ } );\n",
				"  say \$truth; ## ==> true\n",
				"\n";
		},
}

sub first_index {
	my $me = __PACKAGE__;
	handler
		name      => 'Array:first_index',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'for my $i ( 0 .. $#{$GET} ) { local *_ = \$GET->[$i]; return $i if $ARG->($_) }; return -1;',
		documentation => 'Like C<< List::MoreUtils::first_index() >>.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  my \$found  = \$object->$method( sub { /z\$/ } );\n",
				"  say \$found; ## ==> 2\n",
				"\n";
		},
}

sub reduce {
	require List::Util;
	handler
		name      => 'Array:reduce',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'my $shv_callback = $ARG; List::Util::reduce { $shv_callback->($a,$b) } @{$GET}',
		documentation => 'Like C<< List::Util::reduce() >>.',
}

sub set {
	my $me = CORE::shift;
	handler
		name      => 'Array:set',
		args      => 2,
		signature => [Int, Any],
		usage     => '$index, $value',
		template  => 'my @shv_tmp = @{$GET}; $shv_tmp[$ARG[1]] = $ARG[2]; «\\@shv_tmp»; $ARG[2]',
		lvalue_template => '($GET)->[ $ARG[1] ] = $ARG[2]',
		additional_validation => $additional_validation_for_set_and_insert,
		documentation => 'Sets the element with the given index to the supplied value.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  \$object->$method( 1, 'quux' );\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'foo', 'quux', 'baz' ]\n",
				"\n";
		},
}

sub accessor {
	handler
		name      => 'Array:accessor',
		min_args  => 1,
		max_args  => 2,
		signature => [Int, Optional[Any]],
		usage     => '$index, $value?',
		template  => 'if (#ARG == 1) { ($GET)->[ $ARG[1] ] } else { my @shv_tmp = @{$GET}; $shv_tmp[$ARG[1]] = $ARG[2]; «\\@shv_tmp»; $ARG[2] }',
		lvalue_template => '(#ARG == 1) ? ($GET)->[ $ARG[1] ] : (($GET)->[ $ARG[1] ] = $ARG[2])',
		additional_validation => sub {
			my $self = CORE::shift;
			my ($sig_was_checked, $gen) = @_;
			my $ti = __PACKAGE__->_type_inspector($gen->isa);
			if ($ti and $ti->{trust_mutated} eq 'always') {
				return { code => '1;', env => {} };
			}
			my ( $code, $env, $arg );
			$env = {};
			if ($ti and $ti->{trust_mutated} eq 'maybe') {
				$arg = sub {
					my $gen = CORE::shift;
					return '$shv_index' if $_[0]=='1';
					return '$shv_value' if $_[0]=='2';
					$gen->generate_arg( @_ );
				};
				if ( $sig_was_checked ) {
					$code = sprintf(
						'my($shv_index,$shv_value)=%s; if (%s>1) { %s };',
						$gen->generate_args,
						$gen->generate_argc,
						$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
					);
				}
				else {
					$code = sprintf(
						'my($shv_index,$shv_value)=%s; %s; if (%s>1) { %s };',
						$gen->generate_args,
						$gen->generate_type_assertion( $env, Int, '$shv_index' ),
						$gen->generate_argc,
						$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
					);
				}
			}
			return {
				code => $code,
				env => $env,
				arg => $arg,
			};
		},
	documentation => 'Acts like C<get> if given one argument, or C<set> if given two arguments.',
	_examples => sub {
		my ( $class, $attr, $method ) = @_;
		return CORE::join "",
			"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
			"  \$object->$method( 1, 'quux' );\n",
			"  say Dumper( \$object->$attr ); ## ==> [ 'foo', 'quux', 'baz' ]\n",
			"  say \$object->$method( 2 ); ## ==> 'baz'\n",
			"\n";
	},
}

sub natatime {
	my $me = __PACKAGE__;
	handler
		name      => 'Array:natatime',
		min_args  => 1,
		max_args  => 2,
		signature => [Int, Optional[CodeRef]],
		usage     => '$n, $callback?',
		template  => 'my @shv_remaining = @{$GET}; my $shv_n = $ARG[1]; my $shv_iterator = sub { CORE::splice @shv_remaining, 0, $shv_n }; if ($ARG[2]) { while (my @shv_values = $shv_iterator->()) { $ARG[2]->(@shv_values) } } else { $shv_iterator }',
		documentation => 'Given just a number, returns an iterator which reads that many elements from the array at a time. If also given a callback, calls the callback repeatedly with those values.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  my \$iter   = \$object->$method( 2 );\n",
				"  say Dumper( [ \$iter->() ] ); ## ==> [ 'foo', 'bar' ]\n",
				"  say Dumper( [ \$iter->() ] ); ## ==> [ 'baz' ]\n",
				"\n";
		},
}

sub shallow_clone {
	handler
		name      => 'Array:shallow_clone',
		args      => 0,
		template  => '[@{$GET}]',
		documentation => 'Creates a new arrayref with the same elements as the original.',
}

sub map {
	handler
		name      => 'Array:map',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'map($ARG->($_), @{$GET})',
		documentation => 'Like C<map> from L<perlfunc>.',
}

sub grep {
	handler
		name      => 'Array:grep',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'grep($ARG->($_), @{$GET})',
		documentation => 'Like C<grep> from L<perlfunc>.',
}

sub sort {
	handler
		name      => 'Array:sort',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[CodeRef]],
		usage     => '$coderef?',
		template  => 'my @shv_return = $ARG ? (sort {$ARG->($a,$b)} @{$GET}) : (sort @{$GET})',
		documentation => 'Like C<sort> from L<perlfunc>.',
}

sub reverse {
	handler
		name      => 'Array:reverse',
		args      => 0,
		template  => 'reverse @{$GET}',
		documentation => 'Returns the reversed array in list context.',
}

sub sort_in_place {
	handler
		name      => 'Array:sort_in_place',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[CodeRef]],
		usage     => '$coderef?',
		template  => 'my @shv_return = $ARG ? (sort {$ARG->($a,$b)} @{$GET}) : (sort @{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
		documentation => 'Like C<sort> from L<perlfunc>, but changes the attribute to point to the newly sorted array.',
}

sub shuffle {
	require List::Util;
	handler
		name      => 'Array:shuffle',
		args      => 0,
		template  => 'my @shv_return = List::Util::shuffle(@{$GET}); wantarray ? @shv_return : \@shv_return',
		documentation => 'Returns the array in a random order; can be called in list context or scalar context and will return an arrayref in the latter case.',
}

sub shuffle_in_place {
	require List::Util;
	handler
		name      => 'Array:shuffle_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::shuffle(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
		documentation => 'Rearranges the array in a random order, and changes the attribute to point to the new order.',
}

sub uniq {
	require List::Util;
	handler
		name      => 'Array:uniq',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniq(@{$GET}); wantarray ? @shv_return : \@shv_return',
		documentation => 'Returns the array filtered to remove duplicates; can be called in list context or scalar context and will return an arrayref in the latter case.',
}

sub uniq_in_place {
	require List::Util;
	handler
		name      => 'Array:uniq_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniq(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
		documentation => 'Filters the array to remove duplicates, and changes the attribute to point to the filtered array.',
}

sub uniqnum {
	require List::Util;
	handler
		name      => 'Array:uniqnum',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniqnum(@{$GET}); wantarray ? @shv_return : \@shv_return',
		documentation => 'Returns the array filtered to remove duplicates numerically; can be called in list context or scalar context and will return an arrayref in the latter case.',
}

sub uniqnum_in_place {
	require List::Util;
	handler
		name      => 'Array:uniqnum_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniqnum(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
		documentation => 'Filters the array to remove duplicates numerically, and changes the attribute to point to the filtered array.',
}

sub uniqstr {
	require List::Util;
	handler
		name      => 'Array:uniqstr',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniqstr(@{$GET}); wantarray ? @shv_return : \@shv_return',
		documentation => 'Returns the array filtered to remove duplicates stringwise; can be called in list context or scalar context and will return an arrayref in the latter case.',
}

sub uniqstr_in_place {
	require List::Util;
	handler
		name      => 'Array:uniqstr_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniqstr(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
		documentation => 'Filters the array to remove duplicates stringwise, and changes the attribute to point to the filtered array.',
}

sub splice {
	handler
		name      => 'Array:splice',
		min_args  => 1,
		usage     => '$index, $length, @values',
		template  => 'my @shv_tmp = @{$GET}; my ($shv_index, $shv_length, @shv_values) = @ARG;defined($shv_index) or $shv_index=0; defined($shv_length) or $shv_length=0; my @shv_return = splice(@shv_tmp, $shv_index, $shv_length, @shv_values); «\\@shv_tmp»; wantarray ? @shv_return : $shv_return[-1]',
		lvalue_template => 'my ($shv_index, $shv_length, @shv_values) = @ARG;splice(@{$GET}, $shv_index, $shv_length, @shv_values)',
		additional_validation => sub {
			my $self = CORE::shift;
			my ($sig_was_checked, $gen) = @_;
			my $env = {};
			my $code = sprintf 'if (%s >= 1) { %s }; if (%s >= 2) { %s };',
				$gen->generate_argc,
				$gen->generate_type_assertion( $env, Int, $gen->generate_arg( 1 ) ),
				$gen->generate_argc,
				$gen->generate_type_assertion( $env, Int, $gen->generate_arg( 2 ) );
			my $ti = __PACKAGE__->_type_inspector($gen->isa);
			if ($ti and $ti->{trust_mutated} eq 'always') {
				return { code => $code, env => $env };
			}
			if ($ti and $ti->{trust_mutated} eq 'maybe') {
				my $coercion = ( $gen->coerce and $ti->{value_type}->has_coercion );
				if ( $coercion ) {
					$code .= sprintf(
						'my @shv_unprocessed=%s;my @shv_processed=splice(@shv_unprocessed,0,2); push @shv_processed, map { my $shv_value = $_; %s } @shv_unprocessed;',
						$gen->generate_args,
						$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
					);
				}
				else {
					$code .= sprintf(
						'my @shv_unprocessed=%s;my @shv_processed=splice(@shv_unprocessed,0,2);for my $shv_value (@shv_unprocessed) { %s };push @shv_processed, @shv_unprocessed;',
						$gen->generate_args,
						$gen->generate_type_assertion( $env, $ti->{value_type}, '$shv_value' ),
					);
				}
				return {
					code => $code,
					env  => $env,
					arg  => sub { "\$shv_processed[($_[0])-1]" },
					args => sub { '@shv_processed' },
					argc => sub { 'scalar(@shv_processed)' },
				};
			}
			return { code => $code, env => $env, final_type_check_needed => !!1 };
		},
		documentation => 'Like C<splice> from L<perlfunc>.',
}

sub delete {
	handler
		name      => 'Array:delete',
		args      => 1,
		signature => [Int],
		usage     => '$index',
		template  => 'my @shv_tmp = @{$GET}; my ($shv_return) = splice(@shv_tmp, $ARG, 1); «\\@shv_tmp»; $shv_return',
		lvalue_template => 'splice(@{$GET}, $ARG, 1)',
		additional_validation => 'no incoming values',
		documentation => 'Removes the indexed element from the array and returns it. Elements after it will be "moved up".',
}

sub insert {
	my $me = CORE::shift;
	handler
		name      => 'Array:insert',
		args      => 2,
		signature => [Int, Any],
		usage     => '$index, $value',
		template  => 'my @shv_tmp = @{$GET}; my ($shv_return) = splice(@shv_tmp, $ARG[1], 0, $ARG[2]); «\\@shv_tmp»;',
		lvalue_template => 'splice(@{$GET}, $ARG[1], 0, $ARG[2])',
		additional_validation => $additional_validation_for_set_and_insert,
		documentation => 'Inserts a value into the array with the given index. Elements after it will be "moved down".',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  \$object->$method( 1, 'quux' );\n",
				"  say Dumper( \$object->$attr ); ## ==> [ 'foo', 'quux', 'bar', 'baz' ]\n",
				"\n";
		},
}

sub flatten_deep {
	my $me = __PACKAGE__;
	handler
		name      => 'Array:flatten_deep',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		usage     => '$depth?',
		template  => 'my $shv_fd; $shv_fd = sub { my $d=pop; --$d if defined $d; map ref() eq "ARRAY" ? (defined $d && $d < 0) ? $_ : $shv_fd->(@$_, $d) : $_, @_ }; $shv_fd->(@{$GET}, $ARG)',
		documentation => 'Flattens the arrayref into a list, including any nested arrayrefs. (Has the potential to loop infinitely.)',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', [ 'bar', [ 'baz' ] ] ] );\n",
				"  say Dumper( [ \$object->$method ] ); ## ==> [ 'foo', 'bar', 'baz' ]\n",
				"\n",
				"  my \$object2 = $class\->new( $attr => [ 'foo', [ 'bar', [ 'baz' ] ] ] );\n",
				"  say Dumper( [ \$object->$method(1) ] ); ## ==> [ 'foo', 'bar', [ 'baz' ] ]\n",
				"\n";
		},
}

sub join {
	handler
		name      => 'Array:join',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Str]],
		usage     => '$with?',
		template  => 'my $shv_param_with = #ARG ? $ARG : q[,]; join($shv_param_with, @{$GET})',
		documentation => 'Returns a string joining all the elements in the array; if C<< $with >> is omitted, defaults to a comma.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  say \$object->$method;        ## ==> 'foo,bar,baz'\n",
				"  say \$object->$method( '|' ); ## ==> 'foo|bar|baz'\n",
				"\n";
		},
}

sub print {
	handler
		name      => 'Array:print',
		min_args  => 0,
		max_args  => 2,
		signature => [Optional[FileHandle], Optional[Str]],
		usage     => '$fh?, $with?',
		template  => 'my $shv_param_with = (#ARG>1) ? $ARG[2] : q[,]; print {$ARG[1]||*STDOUT} join($shv_param_with, @{$GET})',
		documentation => 'Prints a string joining all the elements in the array; if C<< $fh >> is omitted, defaults to STDOUT; if C<< $with >> is omitted, defaults to a comma.',
}

sub head {
	handler
		name      => 'Array:head',
		args      => 1,
		signature => [Int],
		usage     => '$count',
		template  => 'my $shv_count=$ARG; $shv_count=@{$GET} if $shv_count>@{$GET}; $shv_count=@{$GET}+$shv_count if $shv_count<0; (@{$GET})[0..($shv_count-1)]',
		documentation => 'Returns the first C<< $count >> elements of the array in list context.',
}

sub tail {
	handler
		name      => 'Array:tail',
		args      => 1,
		signature => [Int],
		usage     => '$count',
		template  => 'my $shv_count=$ARG; $shv_count=@{$GET} if $shv_count>@{$GET}; $shv_count=@{$GET}+$shv_count if $shv_count<0; my $shv_start = scalar(@{$GET})-$shv_count; my $shv_end = scalar(@{$GET})-1; (@{$GET})[$shv_start..$shv_end]',
		documentation => 'Returns the last C<< $count >> elements of the array in list context.',
}

sub apply {
	handler
		name      => 'Array:apply',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'my @shv_tmp = @{$GET}; &{$ARG} foreach @shv_tmp; wantarray ? @shv_tmp : $shv_tmp[-1]',
		documentation => 'Executes the coderef (which should modify C<< $_ >>) against each element of the array; returns the resulting array in list context.',
}

sub pick_random {
	require List::Util;
	handler
		name      => 'Array:pick_random',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		usage     => '$count',
		template  => 'my @shv_tmp = List::Util::shuffle(@{$GET}); my $shv_count = $ARG; $shv_count=@{$GET} if $shv_count > @{$GET}; $shv_count=@{$GET}+$shv_count if $shv_count<0; if (wantarray and #ARG) { @shv_tmp[0..$shv_count-1] } elsif (#ARG) { [@shv_tmp[0..$shv_count-1]] } else { $shv_tmp[0] }',
		documentation => 'If no C<< $count >> is given, returns one element of the array at random. If C<< $count >> is given, creates a new array with that many random elements from the original array (or fewer if the original array is not long enough) and returns that as an arrayref or list depending on context',
}

sub for_each {
	handler
		name      => 'Array:for_each',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'foreach my $shv_index (0 .. $#{$GET}) { &{$ARG}(($GET)->[$shv_index], $shv_index) }; $SELF',
		documentation => 'Chainable method which executes the coderef on each element of the array. The coderef will be passed two values: the element and its index.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  \$object->$method( sub { say \"Item \$_[1] is \$_[0].\" } );\n",
				"\n";
		},
}

sub for_each_pair {
	handler
		name      => 'Array:for_each_pair',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'for (my $shv_index=0; $shv_index<@{$GET}; $shv_index+=2) { &{$ARG}(($GET)->[$shv_index], ($GET)->[$shv_index+1]) }; $SELF',
		documentation => 'Chainable method which executes the coderef on each pair of elements in the array. The coderef will be passed the two elements.',
}

sub all_true {
	require List::Util;
	handler
		name      => 'Array:all_true',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => '&List::Util::all($ARG, @{$GET})',
		documentation => 'Like C<< List::Util::all() >>.',
}

sub not_all_true {
	require List::Util;
	handler
		name      => 'Array:not_all_true',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => '&List::Util::notall($ARG, @{$GET})',
		documentation => 'Like C<< List::Util::notall() >>.',
}

sub min {
	require List::Util;
	handler
		name      => 'Array:min',
		args      => 0,
		template  => '&List::Util::min(@{$GET})',
		documentation => 'Like C<< List::Util::min() >>.',
}

sub max {
	require List::Util;
	handler
		name      => 'Array:max',
		args      => 0,
		template  => '&List::Util::max(@{$GET})',
		documentation => 'Like C<< List::Util::max() >>.',
}

sub minstr {
	require List::Util;
	handler
		name      => 'Array:minstr',
		args      => 0,
		template  => '&List::Util::minstr(@{$GET})',
		documentation => 'Like C<< List::Util::minstr() >>.',
}

sub maxstr {
	require List::Util;
	handler
		name      => 'Array:maxstr',
		args      => 0,
		template  => '&List::Util::maxstr(@{$GET})',
		documentation => 'Like C<< List::Util::maxstr() >>.',
}

sub sum {
	require List::Util;
	handler
		name      => 'Array:sum',
		args      => 0,
		template  => '&List::Util::sum(0, @{$GET})',
		documentation => 'Like C<< List::Util::sum0() >>.',
}

sub product {
	require List::Util;
	handler
		name      => 'Array:product',
		args      => 0,
		template  => '&List::Util::product(1, @{$GET})',
		documentation => 'Like C<< List::Util::product() >>.',
}

sub sample {
	require List::Util;
	handler
		name      => 'Array:sample',
		args      => 1,
		signature => [Int],
		usage     => '$count',
		template  => '&List::Util::sample($ARG, @{$GET})',
		documentation => 'Like C<< List::Util::sample() >>.',
}

sub reductions {
	require List::Util;
	handler
		name      => 'Array:reductions',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'my $shv_callback = $ARG; List::Util::reductions { $shv_callback->($a,$b) } @{$GET}',
		documentation => 'Like C<< List::Util::reductions() >>.',
}

sub pairs {
	require List::Util;
	handler
		name      => 'Array:pairs',
		args      => 0,
		template  => '&List::Util::pairs(@{$GET})',
		documentation => 'Like C<< List::Util::pairs() >>.',
}

sub pairkeys {
	require List::Util;
	handler
		name      => 'Array:pairkeys',
		args      => 0,
		template  => '&List::Util::pairkeys(@{$GET})',
		documentation => 'Like C<< List::Util::pairkeys() >>.',
}

sub pairvalues {
	require List::Util;
	handler
		name      => 'Array:pairvalues',
		args      => 0,
		template  => '&List::Util::pairvalues(@{$GET})',
		documentation => 'Like C<< List::Util::pairvalues() >>.',
}

sub pairgrep {
	require List::Util;
	handler
		name      => 'Array:pairgrep',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'List::Util::pairgrep { $ARG->($_) } @{$GET}',
		documentation => 'Like C<< List::Util::pairgrep() >>.',
}

sub pairfirst {
	require List::Util;
	handler
		name      => 'Array:pairfirst',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'List::Util::pairfirst { $ARG->($_) } @{$GET}',
		documentation => 'Like C<< List::Util::pairfirst() >>.',
}

sub pairmap {
	require List::Util;
	handler
		name      => 'Array:pairmap',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'List::Util::pairmap { $ARG->($_) } @{$GET}',
		documentation => 'Like C<< List::Util::pairmap() >>.',
}

sub reset {
	handler
		name      => 'Array:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { '[]' },
		documentation => 'Resets the attribute to its default value, or an empty arrayref if it has no default.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => [ 'foo', 'bar', 'baz' ] );\n",
				"  \$object->$method;\n",
				"  say Dumper( \$object->$attr ); ## ==> []\n",
				"\n";
		},
}

1;
