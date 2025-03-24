use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Mouse;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050001';

use Sub::HandlesVia::Mite;
extends 'Sub::HandlesVia::Toolkit';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	
	require Mouse::Util;
	my $meta = Mouse::Util::find_meta($target);
	$me->meta_hack( $meta );
}

sub meta_hack {
	my ( $me, $meta ) = ( shift, @_ );
	
	require Mouse::Util::MetaRole;
	
	if ( $meta->isa('Mouse::Meta::Role') ) {
		
		return Mouse::Util::MetaRole::apply_metaroles(
			for             => $meta,
			role_metaroles  => { role => [ $me->package_trait, $me->role_trait ] },
		);
	}
	else {
		
		return Mouse::Util::MetaRole::apply_metaroles(
			for             => $meta,
			class_metaroles => { class => [ $me->package_trait ] },
		);
	}
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
		$get = sub {
			my $self = shift->generate_self;
			"$self\->{$slot}";
		};
		++$get_is_lvalue;
	}
	elsif ($attr->has_read_method) {
		my $read_method = $attr->reader || $attr->accessor;
		$get = sub {
			my $self = shift->generate_self;
			"scalar($self\->$read_method)";
		};
	}
	else {
		my $read_method = $attr->get_read_method_ref;
		$captures->{'$shv_read_method'} = \$read_method;
		$get = sub {
			my $self = shift->generate_self;
			"scalar($self\->\$shv_read_method)";
		};
	}
	if ($attr->has_write_method) {
		my $write_method = $attr->writer || $attr->accessor;
		$set = sub {
			my ($gen, $val) = @_;
			$gen->generate_self . "->$write_method\($val)"
		};
		++$set_checks_isa;
	}
	else {
		my $write_method = $attr->get_write_method_ref;
		$captures->{'$shv_write_method'} = \$write_method;
		$set = sub {
			my ($gen, $val) = @_;
			$gen->generate_self . '->$shv_write_method('.$val.')';
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
		generator_for_slot    => sub { shift->generate_self.'->{'.B::perlstring($attrname).'}' }, # icky
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => $set_checks_isa,
		set_strictly          => !!0,
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

package Sub::HandlesVia::Toolkit::Mouse::PackageTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050001';

use Mouse::Role;

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
	( my $real_attrname = $attrname ) =~ s/^[+]//;
	$spec->{provides}{shv} = $self->_shv_toolkit->clean_spec($self->name, $real_attrname, $spec)
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
our $VERSION   = '0.050001';

use Mouse::Role;
requires '_shv_toolkit';

around apply => sub {
	my ($next, $self, $other, %args) = (shift, shift, @_);
	$other = $self->_shv_toolkit->meta_hack( $other );
	$self->$next( $other, %args );
};

# This is a horrible hack.
do {
	no warnings 'redefine';
	require Mouse::Meta::Role;
	require Scalar::Util;
	my $next = \&Mouse::Meta::Role::combine;
	*Mouse::Meta::Role::combine = sub {
		my ( $class, @roles ) = ( shift, @_ );
		my $combined = $class->$next( @roles );
		my ($hack) = map {
			( ref $_ and blessed $_->[0] and $_->[0]->can( '_shv_toolkit' ) )
				? $_->[0]->_shv_toolkit
				: ();
		} @roles;
		if ($hack) {
			$combined = $hack->meta_hack( $combined );
		}
		return $combined;
	};
};

1;
