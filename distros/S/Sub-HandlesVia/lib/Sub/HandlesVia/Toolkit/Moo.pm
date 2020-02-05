use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moo;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.013';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

use Data::Dumper;
use Types::Standard qw( is_ArrayRef is_Str assert_HashRef is_CodeRef is_Undef );
use Types::Standard qw( ArrayRef HashRef Str Num Int CodeRef Bool );

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	$me->install_has_wrapper($target);
}

sub install_has_wrapper {
	my $me = shift;
	my ($target) = @_;

	my ($installer, $orig);
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		$installer = 'Moo::Role::_install_tracked';
		$orig = $Moo::Role::INFO{$target}{exports}{has};
	}
	else {
		$installer = 'Moo::_install_tracked';
		$orig = $Moo::MAKERS{$target}{exports}{has} || $Moo::MAKERS{$target}{non_methods}{has};
	}
	
	$orig ||= $target->can('has');
	ref($orig) or croak("$target doesn't have a `has` function");
	
	$target->$installer(has => sub {
		if (@_ % 2 == 0) {
			require Carp;
			Carp::croak("Invalid options for attribute(s): even number of arguments expected, got " . scalar @_);
		}
		my ($attrs, %spec) = @_;
		return $orig->($attrs, %spec) unless $spec{handles}; # shortcut
		$attrs = [$attrs] unless ref $attrs;
		for my $attr (@$attrs) {
			my $shv = $me->clean_spec($target, $attr, \%spec);
			$orig->($attr, %spec);
			$me->install_delegations($shv) if $shv;
		}
		return;
	});
}

my %standard_callbacks = (
	args => sub {
		'@_[1..$#_]';
	},
	arg => sub {
		@_==1 or die;
		my $n = shift;
		"\$_[$n]";
	},
	argc => sub {
		'(@_-1)';
	},
	curry => sub {
		@_==1 or die;
		my $arr = shift;
		"splice(\@_,1,0,$arr);";
	},
	usage_string => sub {
		@_==2 or die;
		my $method_name = shift;
		my $guts = shift;
		"\$instance->$method_name($guts)";
	},
	self => sub {
		'$_[0]';
	},
);

sub make_callbacks {
	my ($me, $target, $attrname) = (shift, @_);
	
	if (ref $attrname) {
		@$attrname==1 or die;
		($attrname) = @$attrname;
	}
	
	my $ctor_maker = Moo->_constructor_maker_for($target);
	
	if (!$ctor_maker) {
		return $me->_make_callbacks_role($target, $attrname);
	}
	
	my $spec = $ctor_maker->all_attribute_specs->{$attrname};
	my $maker = Moo->_accessor_maker_for($target);

	my $type   = $spec->{isa} ? Types::TypeTiny::to_TypeTiny($spec->{isa}) : undef;
	my $coerce = exists($spec->{coerce}) ? $spec->{coerce} : 0;
	if ((ref($coerce)||'') eq 'CODE') {
		$type   = $type->plus_coercions(Types::Standard::Any(), $coerce);
		$coerce = 1;
	}
	
	my ($slot) = $maker->generate_simple_get('$_[0]', $attrname, $spec);
	
	my ($is_simple_get, $get, $captures) = $maker->is_simple_get($attrname, $spec)
		? (1, $maker->generate_simple_get('$_[0]', $attrname, $spec))
		: (0, $maker->_generate_get($attrname, $spec), delete($maker->{captures})||{});
	my ($is_simple_set, $set) = $maker->is_simple_set($attrname, $spec)
		? (1, sub {
			my ($var) = @_;
			$maker->_generate_simple_set('$_[0]', $attrname, $spec, $var);
		})
		: (0, sub { # that allows us to avoid going down this yucky code path
			my ($var) = @_;
			my $code = $maker->_generate_set($attrname, $spec);
			$captures = { %$captures, %{ delete($maker->{captures}) or {} } };  # merge environments
			$code = "do { local \@_ = (\$_[0], $var); $code }";
			$code;
		});
	
	# force $captures to be updated
	$set->('$dummy') if !$is_simple_set;
	
	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}
	
	if (is_CodeRef $default->[1]) {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}
	
	return {
		%standard_callbacks,
		is_method      => !!1,
		slot           => sub { $slot },
		get            => sub { $get },
		get_is_lvalue  => $is_simple_get,
		set            => $set,
		set_checks_isa => !$is_simple_set,
		isa            => $type,
		coerce         => !!$coerce,
		env            => $captures,
		be_strict      => $spec->{weak_ref}||$spec->{trigger},
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and is_CodeRef $default->[1]) {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and is_Undef $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and is_Str $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	};
}

sub _make_callbacks_role {
	my ($me, $target, $attrname) = (shift, @_);
	
	if (ref $attrname) {
		@$attrname==1 or die;
		($attrname) = @$attrname;
	}
	
	require B;
	
	my %all_specs = @{ $Moo::Role::INFO{$target}{attributes} };
	my $spec      = $all_specs{$attrname};

	my ($reader_name, $writer_name);
	
	if ($spec->{is} eq 'ro') {
		$reader_name = $attrname;
	}
	elsif ($spec->{is} eq 'rw') {
		$reader_name = $attrname;
		$writer_name = $attrname;
	}
	elsif ($spec->{is} eq 'rwp') {
		$reader_name = $attrname;
		$writer_name = "_set_$attrname";
	}
	if (exists $spec->{reader}) {
		$reader_name = $spec->{reader};
	}
	if (exists $spec->{writer}) {
		$writer_name = $spec->{reader};
	}
	if (exists $spec->{accessor}) {
		$reader_name = $spec->{accessor} unless defined $reader_name;
		$writer_name = $spec->{accessor} unless defined $writer_name;
	}
	
	my $type = $spec->{isa} ? Types::TypeTiny::to_TypeTiny($spec->{isa}) : undef;
	my $coerce = $spec->{coerce};
	if ((ref($coerce)||'') eq 'CODE') {
		$type   = $type->plus_coercions(Types::Standard::Any(), $coerce);
		$coerce = 1;
	}
	
	my $captures = {};
	my ($get, $set);
	
	if (defined $reader_name) {
		$get = ($reader_name =~ /^[\W0-9]\w*$/s)
			? sub { sprintf "\$_[0]->%s", $reader_name }
			: sub { sprintf "\$_[0]->\${\\ %s }", B::perlstring($reader_name) };
	}
	else {
		my ($default, $default_literal) = (undef, 0);
		if (is_Coderef $spec->{default}) {
			$default = $spec->{default};
		}
		elsif (exists $spec->{default}) {
			++$default_literal;
			$default = $spec->{default};
		}
		elsif (is_CodeRef $spec->{builder} or (($spec->{builder}||0) eq 1)) {
			$default = '_build_'.$attrname;
		}
		elsif ($spec->{builder}) {
			$default = $spec->{builder};
		}
		else {
			++$default_literal;
		}
		my $dammit_i_need_to_build_a_reader = sub {
			my $instance = shift;
			exists($instance->{$attrname}) or do {
				$instance->{$attrname} ||= $default_literal ? $default : $instance->$default;
			};
			$instance->{$attrname};
		};
		$captures->{'$shv_reader'} = \$dammit_i_need_to_build_a_reader;
		$get = sub { '$_[0]->$shv_reader()' };
	}
	
	
	if (defined $writer_name) {
		$set = $writer_name =~ /^[\W0-9]\w*$/s
			? sub { my $val = shift; sprintf "\$_[0]->%s(%s)", $writer_name, $val }
			: sub { my $val = shift; sprintf "\$_[0]->\${\\ %s }(%s)", B::perlstring($writer_name), $val };
	}
	else {
		my $trigger;
		if (($spec->{trigger}||0) eq 1) {
			$trigger = "_trigger_$attrname";
		}
		my $weaken = $spec->{weak_ref} || 0;
		my $dammit_i_need_to_build_a_writer = sub {
			my ($instance, $new_value) = (shift, @_);
			if ($type) {
				($type->has_coercion && $coerce)
					? ($new_value = $type->assert_coerce($new_value))
					: $type->assert_valid($new_value);
			}
			if ($trigger) {
				$instance->$trigger($new_value, exists($instance->{$attrname}) ? $instance->{$attrname} : ())
			}
			$instance->{$attrname} = $new_value;
			if ($weaken and ref $new_value) {
				Scalar::Util::weaken($instance->{$attrname});
			}
			$instance->{$attrname};
		};
		$captures->{'$shv_writer'} = \$dammit_i_need_to_build_a_writer;
		$set = sub { my $val = shift; "\$_[0]->\$shv_writer($val)" };
	}

	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}
	
	if (is_CodeRef $default->[1]) {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}

	return {
		%standard_callbacks,
		is_method      => !!1,
		slot           => sub { '$_[0]{'.B::perlstring($attrname).'}' }, # icky
		get            => $get,
		get_is_lvalue  => !!0,
		set            => $set,
		set_checks_isa => !!1,
		isa            => $type,
		coerce         => !!$coerce,
		env            => $captures,
		be_strict      => !!0,
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and is_CodeRef $default->[1]) {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and is_Undef $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and is_Str $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	};
}

1;
