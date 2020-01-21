use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Array;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( ArrayRef Optional Str CodeRef Int Item Any Ref Defined FileHandle );

our @METHODS = qw( count is_empty all elements flatten get pop push shift
	unshift clear first first_index reduce set accessor natatime
	shallow_clone map grep sort reverse sort_in_place splice shuffle
	shuffle_in_place uniq uniq_in_place delete insert flatten flatten_deep
	join print );

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
	my ($sig_was_checked, $callbacks) = @_;
	my $ti = __PACKAGE__->_type_inspector($callbacks->{isa});
	if ($ti and $ti->{trust_mutated} eq 'always') {
		return ('1;', {});
	}
	if ($ti and $ti->{trust_mutated} eq 'maybe') {
		my $coercion = ($callbacks->{coerce} && $ti->{value_type}->has_coercion);
		my @rv = $coercion
			? (
				$self->_process_template(
					'my @shv_values = map $shv_type_for_values->assert_coerce($_), @ARG',
					%$callbacks,
				),
				{ '$shv_type_for_values' => \$ti->{value_type} },
			)
			: (
				$self->_process_template(
					sprintf(
						'my @shv_values = @ARG; for my $shv_value (@shv_values) { %s }',
						$ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
					),
					%$callbacks,
				),
				{ '$shv_type_for_values' => \$ti->{value_type} },
			);
		$callbacks->{'arg'}  = sub { "\$shv_values[($_[0])-1]" };
		$callbacks->{'args'} = sub { '@shv_values' };
		return @rv;
	}
	return;
};

my $additional_validation_for_set_and_insert = sub {
	my $self = CORE::shift;
	my ($sig_was_checked, $callbacks) = @_;
	my $ti = __PACKAGE__->_type_inspector($callbacks->{isa});
	if ($ti and $ti->{trust_mutated} eq 'always') {
		return ('1;', {});
	}
	if ($ti and $ti->{trust_mutated} eq 'maybe') {
		my $coercion = ($callbacks->{coerce} && $ti->{value_type}->has_coercion);
		my $orig = $callbacks->{'arg'};
		$callbacks->{'arg'} = sub {
			return '$shv_index' if $_[0]=='1';
			return '$shv_value' if $_[0]=='2';
			goto &$orig;
		};
		return (
			$self->_process_template(sprintf(
				'my($shv_index,$shv_value)=@ARG; %s;',
				$coercion
					? '$shv_value=$shv_type_for_values->assert_coerce($shv_value)'
					: $ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
			), %$callbacks),
			{ '$shv_type_for_values' => \$ti->{value_type} },
		) if $sig_was_checked;
		return (
			$self->_process_template(sprintf(
				'my($shv_index,$shv_value)=@ARG; %s; %s;',
				Int->inline_assert('$shv_index', '$Types_Standard_Int'),
				$coercion
					? '$shv_value=$shv_type_for_values->assert_coerce($shv_value)'
					: $ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
			), %$callbacks),
			{ '$Types_Standard_Int' => \(Int), '$shv_type_for_values' => \$ti->{value_type} },
		);
	}
	return;
};

sub count {
	handler
		name      => 'Array:count',
		args      => 0,
		template  => 'scalar(@{$GET})',
}

sub is_empty {
	handler
		name      => 'Array:is_empty',
		args      => 0,
		template  => '!scalar(@{$GET})',
}

sub all {
	handler
		name      => 'Array:all',
		args      => 0,
		template  => '@{$GET}',
}

sub elements {
	handler
		name      => 'Array:elements',
		args      => 0,
		template  => '@{$GET}',
}

sub flatten {
	handler
		name      => 'Array:flatten',
		args      => 0,
		template  => '@{$GET}',
}

sub get {
	handler
		name      => 'Array:get',
		args      => 1,
		signature => [Int],
		usage     => '$index',
		template  => '($GET)->[$ARG]',
}

sub pop {
	my $me = CORE::shift;
	handler
		name      => 'Array:pop',
		args      => 0,
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = pop @shv_tmp; «\\@shv_tmp»; $shv_return',
		lvalue_template => 'pop(@{$GET})',
		additional_validation => 'no incoming values',
}

sub push {
	my $me = CORE::shift;
	handler
		name      => 'Array:push',
		usage     => '@values',
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = push(@shv_tmp, @ARG); «\\@shv_tmp»; $shv_return',
		lvalue_template => 'push(@{$GET}, @ARG)',
		additional_validation => $additional_validation_for_push_and_unshift,
}

sub shift {
	my $me = CORE::shift;
	handler
		name      => 'Array:shift',
		args      => 0,
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = shift @shv_tmp; «\\@shv_tmp»; $shv_return',
		lvalue_template => 'shift(@{$GET})',
		additional_validation => 'no incoming values',
}

sub unshift {
	my $me = CORE::shift;
	handler
		name      => 'Array:unshift',
		usage     => '@values',
		template  => 'my @shv_tmp = @{$GET}; my $shv_return = unshift(@shv_tmp, @ARG); «\\@shv_tmp»; $shv_return',
		lvalue_template => 'unshift(@{$GET}, @ARG)',
		additional_validation => $additional_validation_for_push_and_unshift,
}

sub clear {
	my $me = CORE::shift;
	handler
		name      => 'Array:clear',
		args      => 0,
		template  => '«[]»',
		lvalue_template => '@{$GET} = ()',
		additional_validation => 'no incoming values',
}

sub first {
	require List::Util;
	handler
		name      => 'Array:first',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => '&List::Util::first($ARG, @{$GET})',
}

sub first_index {
	my $me = __PACKAGE__;
	handler
		name      => 'Array:first_index',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => $me.'::_firstidx($ARG, @{$GET})',
}

# Implementation from List::MoreUtils::PP.
# Removed original prototype.
sub _firstidx {
	my $f = CORE::shift;
	foreach my $i (0 .. $#_)
	{
		local *_ = \$_[$i];
		return $i if $f->();
	}
	return -1;
}

sub reduce {
	require List::Util;
	handler
		name      => 'Array:reduce',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'my $shv_callback = $ARG; List::Util::reduce { $shv_callback->($a,$b) } @{$GET}',
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
			my ($sig_was_checked, $callbacks) = @_;
			my $ti = __PACKAGE__->_type_inspector($callbacks->{isa});
			if ($ti and $ti->{trust_mutated} eq 'always') {
				return ('1;', {});
			}
			if ($ti and $ti->{trust_mutated} eq 'maybe') {
				my $coercion = ($callbacks->{coerce} && $ti->{value_type}->has_coercion);
				my $orig = $callbacks->{'arg'};
				$callbacks->{'arg'} = sub {
					return '$shv_index' if $_[0]=='1';
					return '$shv_value' if $_[0]=='2';
					goto &$orig;
				};
				return (
					$self->_process_template(sprintf(
						'my($shv_index,$shv_value)=@ARG; if (#ARG>1) { %s };',
						$coercion
							? '$shv_value=$shv_type_for_values->assert_coerce($shv_value)'
							: $ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
					), %$callbacks),
					{ '$shv_type_for_values' => \$ti->{value_type} },
				) if $sig_was_checked;
				return (
					$self->_process_template(sprintf(
						'my($shv_index,$shv_value)=@ARG; %s; if (#ARG>1) { %s };',
						Int->inline_assert('$shv_index', '$Types_Standard_Int'),
						$coercion
							? '$shv_value=$shv_type_for_values->assert_coerce($shv_value)'
							: $ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
					), %$callbacks),
					{ '$Types_Standard_Int' => \(Int), '$shv_type_for_values' => \$ti->{value_type} },
				);
			}
			return;
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
		template  => 'my $shv_iterator = '.$me.'::_natatime($ARG[1], @{$GET}); if ($ARG[2]) { while (my @shv_values = $shv_iterator->()) { $ARG[2]->(@shv_values) } } else { $shv_iterator }',
}

# Implementation from List::MoreUtils::PP.
# Removed original prototype.
sub _natatime {
	my $n    = CORE::shift;
	my @list = @_;
	return sub { CORE::splice @list, 0, $n }
}

sub shallow_clone {
	handler
		name      => 'Array:shallow_clone',
		args      => 0,
		template  => '[@{$GET}]',
}

sub map {
	handler
		name      => 'Array:map',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'map($ARG->($_), @{$GET})',
}

sub grep {
	handler
		name      => 'Array:grep',
		args      => 1,
		signature => [CodeRef],
		usage     => '$coderef',
		template  => 'grep($ARG->($_), @{$GET})',
}

sub sort {
	handler
		name      => 'Array:sort',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[CodeRef]],
		usage     => '$coderef?',
		template  => 'my @shv_return = $ARG ? (sort {$ARG->($a,$b)} @{$GET}) : (sort @{$GET})',
}

sub reverse {
	handler
		name      => 'Array:reverse',
		args      => 0,
		template  => 'reverse @{$GET}',
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
}

sub shuffle {
	require List::Util;
	handler
		name      => 'Array:shuffle',
		args      => 0,
		template  => 'my @shv_return = List::Util::shuffle(@{$GET}); wantarray ? @shv_return : \@shv_return',
}

sub shuffle_in_place {
	require List::Util;
	handler
		name      => 'Array:shuffle_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::shuffle(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
}

sub uniq {
	require List::Util;
	handler
		name      => 'Array:uniq',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniq(@{$GET}); wantarray ? @shv_return : \@shv_return',
}

sub uniq_in_place {
	require List::Util;
	handler
		name      => 'Array:uniq_in_place',
		args      => 0,
		template  => 'my @shv_return = List::Util::uniq(@{$GET}); «\@shv_return»',
		additional_validation => 'no incoming values',
}

sub splice {
	# luckily Int is fully inlinable because there's no way to
	# add to %environment from here!!!
	my $checks = sprintf(
		'if (#ARG > 0) { %s }; if (#ARG > 1) { %s };',
		Int->inline_assert('$shv_index'),
		Int->inline_assert('$shv_length'),
	);
	handler
		name      => 'Array:splice',
		min_args  => 1,
		usage     => '$index, $length, @values',
		template  => 'my @shv_tmp = @{$GET}; my ($shv_index, $shv_length, @shv_values) = @ARG;'.$checks.'defined($shv_index) or $shv_index=0; defined($shv_length) or $shv_length=0; my @shv_return = splice(@shv_tmp, $shv_index, $shv_length, @shv_values); «\\@shv_tmp»; wantarray ? @shv_return : $shv_return[-1]',
		lvalue_template => 'my ($shv_index, $shv_length, @shv_values) = @ARG;'.$checks.';splice(@{$GET}, $shv_index, $shv_length, @shv_values)',
		additional_validation => sub {
			my $self = CORE::shift;
			my ($sig_was_checked, $callbacks) = @_;
			my $ti = __PACKAGE__->_type_inspector($callbacks->{isa});
			if ($ti and $ti->{trust_mutated} eq 'always') {
				return ('1;', {});
			}
			if ($ti and $ti->{trust_mutated} eq 'maybe') {
				my $coercion = ($callbacks->{coerce} && $ti->{value_type}->has_coercion);
				my @rv = $coercion
					? (
						$self->_process_template(
							'my @shv_unprocessed=@ARG;my @shv_processed=splice(@shv_unprocessed,0,2); push @shv_processed, map $shv_type_for_values->assert_coerce($_), @shv_unprocessed;',
							%$callbacks,
						),
						{ '$shv_type_for_values' => \$ti->{value_type} },
					)
					: (
						$self->_process_template(
							sprintf(
								'my @shv_unprocessed=@ARG;my @shv_processed=splice(@shv_unprocessed,0,2);for my $shv_value (@shv_unprocessed) { %s };push @shv_processed, @shv_unprocessed;',
								$ti->{value_type}->inline_assert('$shv_value', '$shv_type_for_values'),
							),
							%$callbacks,
						),
						{ '$shv_type_for_values' => \$ti->{value_type} },
					);
				$callbacks->{'arg'}  = sub { "\$shv_processed[($_[0])-1]" };
				$callbacks->{'args'} = sub { '@shv_processed' };
				return @rv;
			}
		},
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
}

sub flatten_deep {
	my $me = __PACKAGE__;
	handler
		name      => 'Array:flatten_deep',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		usage     => '$depth?',
		template  => "$me\::_flatten_deep(\@{\$GET}, \$ARG)",
}

# callback!
sub _flatten_deep {
	my @array = @_;
	my $depth = CORE::pop @array;
	--$depth if defined($depth);
	my @elements = CORE::map {
		(ref eq 'ARRAY')
			? (defined($depth) && $depth == -1) ? $_ : _flatten_deep(@$_, $depth)
			: $_
	} @array;
}

sub join {
	handler
		name      => 'Array:join',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Str]],
		usage     => '$with?',
		template  => 'my $shv_param_with = #ARG ? $ARG : q[,]; join($shv_param_with, @{$GET})',
}

sub print {
	handler
		name      => 'Array:print',
		min_args  => 0,
		max_args  => 2,
		signature => [Optional[FileHandle], Optional[Str]],
		usage     => '$fh?, $with?',
		template  => 'my $shv_param_with = (#ARG>1) ? $ARG[2] : q[,]; print {$ARG[1]||*STDOUT} join($shv_param_with, @{$GET})',
}

1;
