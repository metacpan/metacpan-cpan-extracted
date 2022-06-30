use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.027';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	
	require Moose::Util;
	my $meta = Moose::Util::find_meta($target);
	Role::Tiny->apply_roles_to_object($meta, $me->package_trait);
	Role::Tiny->apply_roles_to_object($meta, $me->role_trait) if $meta->isa('Moose::Meta::Role');
}

sub package_trait {
	__PACKAGE__ . "::PackageTrait";
}

sub role_trait {
	__PACKAGE__ . "::RoleTrait";
}

sub code_generator_for_attribute {
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
		require Moose::Util;
		$meta = Moose::Util::find_meta($target);
	}

	my $attr = $meta->get_attribute($attrname);
	my $spec = +{%$attr};

	my $captures = {};
	
	my $slot = sub {
		my $gen = shift;
		$meta->get_meta_instance->inline_slot_access($gen->generate_self, $attrname);
	};
	
	my ($get, $set, $get_is_lvalue, $set_checks_isa);
	if (!$spec->{lazy} and !$spec->{traits} and !$spec->{auto_deref}) {
		$get = $slot;
		++$get_is_lvalue;
	}
	elsif ($attr->has_read_method) {
		my $read_method = $attr->get_read_method;
		$get = sub { my $self = shift->generate_self; "scalar($self\->$read_method)" };
	}
	else {
		my $read_method = $attr->get_read_method_ref;
		eval { $read_method = $read_method->{body} };  # Moose docs lie!
		$captures->{'$shv_read_method'} = \$read_method;
		$get = sub { my $self = shift->generate_self; "scalar($self\->\$shv_read_method)" };
	}
	
	if ($attr->has_write_method) {
		my $write_method = $attr->get_write_method;
		$set = sub {
			my ($gen, $val) = @_;
			my $self = $gen->generate_self;
			"$self\->$write_method\($val)"
		};
		++$set_checks_isa;
	}
	else {
		$captures->{'$shv_write_method'} = \(
			$attr->can('set_value')
				? sub { $attr->set_value(@_) }
				: sub { my ($instance, $value) = @_; $instance->meta->get_attribute($attrname)->set_value($instance, $value) }
		);
		$set = sub {
			my ($gen, $val) = @_;
			my $self = $gen->generate_self;
			$self.'->$shv_write_method('.$val.')';
		};
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

	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attrname,
		attribute_spec        => $spec,
		env                   => $captures,
		isa                   => Types::TypeTiny::to_TypeTiny($attr->type_constraint),
		coerce                => !!$spec->{coerce},
		generator_for_slot    => $slot,
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => $set_checks_isa,
		set_strictly          => !!1,
		method_installer      => sub { $meta->add_method(@_) },
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( $default->[0] eq 'builder' ) {
				return sprintf(
					'(%s)->%s',
					$gen->generate_self,
					$default->[1],
				);
			}
			elsif ( $default->[0] eq 'default' and ref $default->[1] eq 'CODE' ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( $default->[0] eq 'default' and !defined $default->[1] ) {
				return 'undef';
			}
			elsif ( $default->[0] eq 'default' and !ref $default->[1] ) {
				require B;
				return B::perlstring( $default->[1] );
			}
			return;
		},
	);
}

package Sub::HandlesVia::Toolkit::Moose::PackageTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.027';

use Role::Tiny;

sub _shv_toolkit {
	'Sub::HandlesVia::Toolkit::Moose',
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
	$spec->{definition_context}{shv} = $self->_shv_toolkit->clean_spec($self->name, $attrname, $spec)
		unless $spec->{definition_context}{shv};
	my $attr = $self->$next($attrobj ? $attrobj : ($attrname, %$spec));
	if ($spec->{definition_context}{shv} and $self->isa('Moose::Meta::Class')) {
		$self->_shv_toolkit->install_delegations(+{
			%{ $spec->{definition_context}{shv} },
			target => $self->name,
		});
	}
	return $attr;
};

package Sub::HandlesVia::Toolkit::Moose::RoleTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.027';

use Role::Tiny;

around apply => sub {
	my ($next, $self, $other, %args) = (shift, shift, @_);
	
	if ($other->isa('Moose::Meta::Role')) {
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
