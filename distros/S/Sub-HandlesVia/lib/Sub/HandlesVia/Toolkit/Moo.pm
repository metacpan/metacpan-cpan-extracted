use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moo;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

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
			$me->process_spec($target, $attr, \%spec);
			$orig->($attr, %spec);
			if (my $handles = delete $spec{'_sub_handlesvia_handles'}) {
				my $canon_spec = Moo->_constructor_maker_for($target)->all_attribute_specs->{$attr};
				my %callbacks = $me->get_callbacks_for_attribute($target, $attr, $canon_spec);
				foreach my $method_name (sort keys %$handles) {
					$handles->{$method_name}->install_method(
						%callbacks,
						target      => $target,
						method_name => $method_name,
					);
				}
			}
		}
		return;
	});
}

my %default_type = (
	Array     => ArrayRef,
	Hash      => HashRef,
	String    => Str,
	Number    => Num,
	Counter   => Int,
	Code      => CodeRef,
	Bool      => Bool,
);

sub process_spec {
	my $me = shift;
	
	my ($target, $attr, $spec) = @_;
	my @handles_via;
	if (is_ArrayRef $spec->{handles_via}) {
		push @handles_via, @{ $spec->{handles_via} };
	}
	elsif (is_Str $spec->{handles_via}) {
		push @handles_via, $spec->{handles_via};
	}
	elsif (is_ArrayRef $spec->{traits}) {
		push @handles_via, @{ $spec->{traits} };
	}
	return unless @handles_via;
	
	my $joined = join('|', @handles_via);
	return if $joined =~ /^Enum(?:eration)?$/i;
	
	if ($default_type{$joined} and not exists $spec->{isa}) {
		$spec->{isa}    =    $default_type{$joined};
		$spec->{coerce} = !! $default_type{$joined}->has_coercion;
	}
	
	$spec->{handles} = { map +($_ => $_), @{ $spec->{handles} } }
		if is_ArrayRef $spec->{handles};
	
	assert_HashRef $spec->{handles};
	require Sub::HandlesVia::Handler;

	my @method_names = sort keys %{ $spec->{handles} };
	for my $method_name (@method_names) {
		my $target_method = $spec->{handles}{$method_name};
		my $handler = Sub::HandlesVia::Handler->lookup($target_method, \@handles_via);
		
		if ($handler) {
			($spec->{'_sub_handlesvia_handles'} ||= {})->{$method_name} = $handler;
			($spec->{'_sub_handlesvia_orig_handles'} ||= {})->{$method_name}
				= delete $spec->{handles}{$method_name};
		}
	}
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

sub get_callbacks_for_attribute {
	my $me = shift;
	my ($target, $attr, $spec) = @_;
	
	my $maker = $me->_accessor_maker_for($target);
	my ($is_simple_get, $get, $captures) = $maker->is_simple_get($attr, $spec)
		? (1, $maker->generate_simple_get('$_[0]', $attr, $spec))
		: (0, $maker->_generate_get($attr, $spec), delete($maker->{captures})||{});
	my ($is_simple_set, $set) = $maker->is_simple_set($attr, $spec)
		? (1, sub {
			my ($var) = @_;
			$maker->_generate_simple_set('$_[0]', $attr, $spec, $var);
		})
		: (0, sub { # that allows us to avoid going down this yucky code path
			my ($var) = @_;
			my $code = $maker->_generate_set($attr, $spec);
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
	
	my %callbacks = (
		%standard_callbacks,
		is_method      => !!1,
		get            => sub { $get },
		get_is_lvalue  => $is_simple_get,
		set            => $set,
		set_checks_isa => !$is_simple_set,
		isa            => Types::TypeTiny::to_TypeTiny($spec->{isa}),
		coerce         => !!$spec->{coerce},
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
	);
	
	%callbacks;
}

sub _accessor_maker_for {
	my $me = shift;
	my ($target) = @_;
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		my $dummy = 'MooX::Enumeration::____DummyClass____';
		eval('package ' # hide from CPAN indexer
		. "$dummy; use Moo");
		return Moo->_accessor_maker_for($dummy);
	}
	elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
		return Moo->_accessor_maker_for($target);
	}
	else {
		require Carp;
		Carp::croak("Cannot get accessor maker for $target");
	}
}
