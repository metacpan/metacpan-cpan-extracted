use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Mouse;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	
	require Mouse::Util;
	my $meta = Mouse::Util::find_meta($target);
	Role::Tiny->apply_roles_to_object($meta, $me->package_trait);
	Role::Tiny->apply_roles_to_object($meta, $me->role_trait) if $meta->isa('Mouse::Meta::Role');
}

sub package_trait {
	__PACKAGE__ . "::PackageTrait";
}

sub role_trait {
	__PACKAGE__ . "::RoleTrait";
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
	
	my $meta;
	if (ref $target) {
		$meta   = $target;
		$target = $meta->name;
	}
	else {
		require Mouse::Util;
		$meta = Mouse::Util::find_meta($target);
	}
	
	my $attr = $meta->get_attribute($attrname);
	my $spec = +{%$attr};
	
	my $captures = {};
	
	my ($get, $set, $get_is_lvalue, $set_checks_isa);
	if (!$spec->{lazy} and !$spec->{traits} and !$spec->{auto_deref}) {
		require B;
		my $slot = B::perlstring($attrname);
		$get = sub { "\$_[0]{$slot}" };
		++$get_is_lvalue;
	}
	elsif ($attr->has_read_method) {
		my $read_method = $attr->reader || $attr->accessor;
		$get = sub { "scalar(\$_[0]->$read_method)" };
	}
	else {
		my $read_method = $attr->get_read_method_ref;
		$captures->{'$shv_read_method'} = \$read_method;
		$get = sub { 'scalar($_[0]->$shv_read_method)' };
	}
	if ($attr->has_write_method) {
		my $write_method = $attr->writer || $attr->accessor;
		$set = sub { my $val = shift; "\$_[0]->$write_method\($val)" };
		++$set_checks_isa;
	}
	else {
		my $write_method = $attr->get_write_method_ref;
		$captures->{'$shv_write_method'} = \$write_method;
		$set = sub { my $val = shift; '$_[0]->$shv_write_method('.$val.')' };
		++$set_checks_isa;
	}

	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}

	if (ref $default->[1] eq 'CODE') {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}

	return {
		%standard_callbacks,
		is_method      => !!1,
		slot           => sub { '$_[0]{'.B::perlstring($attrname).'}' }, # icky
		get            => $get,
		get_is_lvalue  => $get_is_lvalue,
		set            => $set,
		set_checks_isa => $set_checks_isa,
		isa            => Types::TypeTiny::to_TypeTiny($attr->type_constraint),
		coerce         => !!$spec->{coerce},
		env            => $captures,
		be_strict      => !!0,
		install_method => sub { $meta->add_method(@_) },
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and ref $default->[1] eq 'CODE') {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and !defined $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and !ref $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	};
}

package Sub::HandlesVia::Toolkit::Mouse::PackageTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Role::Tiny;

sub _shv_toolkit {
	'Sub::HandlesVia::Toolkit::Mouse',
}

around add_attribute => sub {
	my ($next, $self, @args) = (shift, shift, @_);
	my ($spec, $attrobj, $attrname);
	if (@args == 1) {
		$spec = $attrobj = $_[0];
		$attrname = $attrobj->name;
	}
	elsif (@args == 2) {
		($attrname, $spec) = @args;
	}
	else {
		my %spec;
		($attrname, %spec) = @args;
		$spec = \%spec;
	}
	$spec->{provides}{shv} = $self->_shv_toolkit->clean_spec($self->name, $attrname, $spec)
		unless $spec->{provides}{shv};
	my $attr = $self->$next($attrobj ? $attrobj : ($attrname, %$spec));
	if ($spec->{provides}{shv} and $self->isa('Mouse::Meta::Class')) {
		$self->_shv_toolkit->install_delegations(+{
			%{ $spec->{provides}{shv} },
			target => $self->name,
		});
	}
	return $attr;
};

package Sub::HandlesVia::Toolkit::Mouse::RoleTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Role::Tiny;

around apply => sub {
	my ($next, $self, $other, %args) = (shift, shift, @_);
	
	if ($other->isa('Mouse::Meta::Role')) {
		Role::Tiny->apply_roles_to_object(
			$other,
			$self->_shv_toolkit->package_trait,
			$self->_shv_toolkit->role_trait,
		);
	}
	else {
		Role::Tiny->apply_roles_to_object(
			$other,
			$self->_shv_toolkit->package_trait,
		);
	}
	
	$self->$next(@_);
};

1;
