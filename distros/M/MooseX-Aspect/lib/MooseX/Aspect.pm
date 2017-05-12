package MooseX::Aspect;

use 5.010;
use strict;
use warnings;
use utf8;
use namespace::sweep;

BEGIN {
	$MooseX::Aspect::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::Aspect::VERSION   = '0.001';
}

use Carp;
use Moose ();
use MooseX::Aspect::Util ();
use Moose::Exporter;
use MooseX::RoleQR ();
use MooseX::Singleton ();
use Scalar::Does qw( does -constants );

'Moose::Exporter'->setup_import_methods(
	with_meta => [qw(
		create_join_point apply_to optionally_apply_to
		after before around guard whenever has requires with extends
	)],
	as_is => [qw(
		role
	)],
);

sub init_meta
{
	shift;
	'Moose'->init_meta(@_);
	
	my %options = @_;
	Moose::Util::MetaRole::apply_metaroles(
		for             => $options{for_class},
		class_metaroles => {
			class => [ 'MooseX::Aspect::Trait::Aspect' ],
		},
	);
	Moose::Util::MetaRole::apply_base_class_roles(
		for    => $options{for_class},
		roles  => [qw(
			MooseX::Aspect::Trait::Employable
			MooseX::Singleton::Role::Object
		)],
	);
}

sub create_join_point
{
	my $meta = shift;
	for (@_)
	{
		$meta->add_aspect_join_point(
			'MooseX::Aspect::Meta::JoinPoint::Adhoc'->new(
				name              => $_,
				associated_aspect => $meta,
			),
		);
	}
}

sub role (&)
{
	return +{ role => +shift };
}

sub __apply_to
{
	my ($class, $meta, $constraint, $builder) = @_;
	
	my $role = $class->create_anon_role(
		associated_aspect      => $meta,
		application_constraint => $constraint,
	);
	$meta->_building_role($role);
	
	# Hackity hack!
	$role->{application_to_class_class} = Moose::Util::with_traits(
		$role->{application_to_class_class},
		'MooseX::RoleQR::Trait::Application::ToClass',
	);
	$role->{application_to_role_class} = Moose::Util::with_traits(
		$role->{application_to_role_class},
		'MooseX::RoleQR::Trait::Application::ToRole',
	);
	
	my $err;
	eval { $builder->{role}->(); 1 }
		or $err = $@;
	
	$meta->_clear_building_role;
	
	die $err if $err;
	$meta->add_aspect_role($role);
}

sub apply_to
{
	unshift @_, 'MooseX::Aspect::Meta::Role::Required';
	goto \&__apply_to;
}

# Experimental
sub optionally_apply_to
{
	unshift @_, 'MooseX::Aspect::Meta::Role::Optional';
	goto \&__apply_to;
}

BEGIN {
	no strict 'refs';
	foreach my $type (qw(before after around))
	{
		*$type = sub
		{
			my ($meta, $method, $coderef) = @_;
			my $sub = 'Moose'->can($type);
			if (my $r = $meta->_building_role)
			{
				@_ = ($r, $method, $coderef);
				$sub = 'MooseX::RoleQR'->can($type);
			}
			goto $sub;
		}
	}
};

sub guard
{
	my ($meta, $method, $coderef) = @_;
	my $new = sub {
		my $orig = shift;
		goto $orig if $coderef->(@_);
		return;
	};
	@_ = ($meta, $method, $new);
	goto \&around;
}

sub with
{
	my ($meta, @args) = @_;
	Moose::Util::apply_all_roles(
		$meta->_building_role || $meta,
		@args,
	);
}

sub has
{
	my ($meta) = @_;
	confess "Must not use 'has' inside aspect role"
		if $meta->_building_role;
	goto \&Moose::has;
}

sub extends
{
	my ($meta) = @_;
	confess "Must not use 'extends' inside aspect role"
		if $meta->_building_role;
	goto \&Moose::extends;
}

sub requires
{
	my ($meta, @args) = @_;
	my $role = $meta->_building_role
		or confess "Cannot use 'requires' in aspect outside role";
	$role->add_required_methods(@args);
}

sub whenever
{
	my ($meta, $join_point, $coderef) = @_;
	my $role = $meta->_building_role
		or confess "Used 'whenever' outside role";
	
	if (does $join_point, ARRAY)
	{
		whenever($meta, $_, $coderef) for @$join_point;
		return;
	}
	elsif (does $join_point, REGEXP)
	{
		whenever($meta, $_, $coderef)
			for grep { $_->name =~ $join_point } @{ $meta->aspect_join_points };
		return;
	}
	
	$role->add_whenever_modifier($join_point, $coderef);
}

BEGIN {
	package MooseX::Aspect::Trait::Aspect;
	no thanks;
	use Moose::Role;
	use Class::Load qw(load_class);
	use Moose::Util qw(apply_all_roles);
	use Carp;
	use namespace::sweep;
	
	has _building_role => (
		is        => 'rw',
		isa       => 'Object',
		clearer   => '_clear_building_role',
	);
	
	has aspect_roles => (
		traits    => [qw/ Array /],
		is        => 'ro',
		isa       => 'ArrayRef[Moose::Meta::Role]',
		default   => sub { [] },
		handles   => {
			add_aspect_role => 'push',
		},
	);

	has aspect_join_points => (
		traits    => [qw/ Array /],
		is        => 'ro',
		isa       => 'ArrayRef[MooseX::Aspect::Meta::JoinPoint]',
		default   => sub { [] },
		handles   => {
			add_aspect_join_point => 'push',
		},
	);
	
	sub find_aspect_join_point
	{
		my ($meta, $name) = @_;
		return $name if blessed $name;
		my ($r) = grep { $_->name eq $name } @{ $meta->aspect_join_points };
		$r;
	}
	
	sub setup_aspect_employment
	{
		my ($meta, $thing, $required_only) = @_;
		load_class $thing unless blessed $thing;
		
		my @application;
		foreach my $role (@{ $meta->aspect_roles })
		{
			next
				if $required_only
				&& !$role->DOES('MooseX::Aspect::Meta::Role::Required');
			
			push @application, $role
				if $role->should_apply_to($thing);
		}
		
		apply_all_roles($thing, @application) if @application;
		Moose::Util::MetaRole::apply_metaroles(
			for             => ref($thing) || $thing,
			class_metaroles => {
				class  => ['MooseX::Aspect::Trait::Employer'],
			},
		);
		push @{ $thing->meta->employed_aspects }, $meta;
	}
	
	sub run_join_point
	{
		my ($meta, $caller, $join_point, $args) = @_;
		$join_point = $meta->find_aspect_join_point($join_point)
			or confess "Unknown join_point '$_[2]'";
		
		foreach my $role (@{ $meta->aspect_roles })
		{
			next unless $caller->does_role($role);
			foreach my $whenever ($role->get_whenever_modifiers($join_point))
			{
				$whenever->execute($args);
			}
		}
		
		return;
	}
};

BEGIN {
	package MooseX::Aspect::Trait::Employable;
	use Moose::Role;
	use MooseX::ClassAttribute;
	
	class_has is_setup => (
		is       => 'ro',
		isa      => 'Bool',
		writer   => '_set_is_setup',
		default  => sub { 0 },
	);
	
	sub _auto_setup
	{
		my $class = shift;
		return if $class->is_setup;
		my $meta  = $class->meta;
		for my $role (@{ $meta->aspect_roles })
		{
			next unless $role->DOES('MooseX::Aspect::Meta::Role::Required');
			Class::Load::load_class( $role->application_constraint );
			$meta->setup_aspect_employment($role->application_constraint, 1);
		}
		$class->_set_is_setup(1);
	}
	
	sub setup
	{
		my ($class, @args) = @_;
		my @isa = $class->meta->linearized_isa;
		for my $klass (@isa)
		{
			next unless $klass->DOES(__PACKAGE__);
			$klass->_auto_setup;
			next unless $klass->meta->can('setup_aspect_employment');
			$klass->meta->setup_aspect_employment($_) for @args;
		}
	}
};

BEGIN {
	package MooseX::Aspect::Trait::Employer;
	no thanks;
	use Moose::Role;
	
	has employed_aspects => (
		is       => 'ro',
		isa      => 'ArrayRef[Moose::Meta::Class]',
		default  => sub { [] },
	);
	
	sub employs_aspect
	{
		my ($meta, $aspect) = @_;
		$aspect = $aspect->name if blessed $aspect;
		return scalar grep { $_->name eq $aspect } @{ $meta->employed_aspects };
	}
};


BEGIN {
	package MooseX::Aspect::Meta::JoinPoint;
	no thanks;
	use namespace::sweep;
	use Moose;
	has associated_aspect => (is => 'ro', required => 1);
};

BEGIN {
	package MooseX::Aspect::Meta::JoinPoint::Adhoc;
	no thanks;
	use Moose;
	use namespace::sweep;
	extends qw( MooseX::Aspect::Meta::JoinPoint );
	has name => (is => 'ro', required => 1);
};

BEGIN {
	package MooseX::Aspect::Meta::WheneverModifier;
	no thanks;
	use Moose;
	use namespace::sweep;
	
	has associated_role   => (is => 'ro', required => 1);
	has join_point        => (is => 'ro', required => 1);
	has code              => (is => 'ro', required => 1);
	
	sub execute {
		my ($meta, $args) = @_;
		$meta->code->( @$args );
	}
};

BEGIN {
	package MooseX::Aspect::Meta::Role;
	no thanks;
	use Moose;
	use Scalar::Does;
	use namespace::sweep;
	extends qw( Moose::Meta::Role );
	with qw( MooseX::RoleQR::Trait::Role );
	
	has associated_aspect => (is => 'ro', required => 1);
	has application_constraint => (
		is        => 'ro',
		isa       => 'Any',
	);
	has whenever_modifiers => (
		is        => 'ro',
		isa       => 'HashRef',
		default   => sub { +{} },
	);
	
	sub add_whenever_modifier
	{
		my ($meta, $join_point, $code) = @_;
		
		$join_point = $meta->associated_aspect->find_aspect_join_point($join_point)
			unless blessed $join_point;
		
		confess "Unknown join_point" unless $join_point;
				
		$code = 'MooseX::Aspect::Meta::WheneverModifier'->new(
			associated_role => $meta,
			join_point      => $join_point,
			code            => $code,
		) unless blessed $code;
		
		push @{ $meta->whenever_modifiers->{ $join_point->name } }, $code;
	}
	
	sub get_whenever_modifiers
	{
		my ($meta, $join_point) = @_;
		$join_point = $join_point->name if blessed $join_point;
		@{ $meta->whenever_modifiers->{$join_point} };
	}
	
	sub should_apply_to
	{
		my ($meta, $thing) = @_;
		my $constraint = $meta->application_constraint;
		
		return 1 if does($constraint, 'Moose::Meta::TypeConstraint') && $constraint->check($thing);
		return 1 if does($thing, $constraint);
		return;
	}
};

BEGIN {
	package MooseX::Aspect::Meta::Role::Required;
	no thanks;
	use Moose;
	extends qw( MooseX::Aspect::Meta::Role );
	has '+application_constraint' => (isa => 'Str');
}

BEGIN {
	package MooseX::Aspect::Meta::Role::Optional;
	no thanks;
	use Moose;
	extends qw( MooseX::Aspect::Meta::Role );
}

1;

__END__

=head1 NAME

MooseX::Aspect - aspect-oriented programming toolkit for Moose

=head1 SYNOPSIS

  {
    package User;
    use Moose;
    ...;
  }
  
  {
    package Computer;
    use Moose;
    ...;
  }
  
  {
    package Logging;
    use MooseX::Aspect;
    
    has log_file => (is => 'rw');
    
    sub log {
      $_[0]->log_file->append($_[1]);
    }
    
    apply_to 'User', role {
      before login => sub {
        my $self   = shift;
        my $aspect = __PACKAGE__->instance;
        $aspect->log($self->name . " logged in");
      };
    };
    
    apply_to 'Computer', role {
      after connect  => sub {
        my $self   = shift;
        my $aspect = __PACKAGE__->instance;
        $aspect->log($self->id . " connected to network");
      };
      after disconnect  => sub {
        my $self   = shift;
        my $aspect = __PACKAGE__->instance;
        $aspect->log($self->id . " disconnected from network");
      };
    };
  }
  
  Logging->setup;  # apply all the aspect's roles to packages

=head1 DESCRIPTION

Certain parts of code are cross-cutting concerns. A classic example is the
one shown in the example: logging. Other cross-cutting concerns include
access control, change monitoring (e.g. setting dirty flags) and
database transaction management. Aspects help you isolate cross-cutting
concerns into modules.

In Moose terms, an aspect is a package that defines multiple Moose roles,
along with instructions as to what packages the roles should be applied to.

=head2 Sugar

=over

=item C<< apply_to PACKAGE, role { ... }; >>

The C<apply_to> and C<role> functions are designed to be used together.
They define an anonymous role and specify the package (which may be a
class or another role) it is intended to be composed with.

The role definition is a more limited version of a standard Moose role
definition. In particular, it cannot define methods or attributes;
however it can define method modifiers or required methods.

=item C<< create_join_point NAME >>

Defines a "join point". That is, a hook/event that packages employing
this aspect can trigger, and that roles within this aspect can supply
code to handle.

For example, an aspect called Local::DatabaseIntegrity might define join
points called "db-begin" and "db-end" which application code can
trigger using:

   MooseX::Aspect::Util::join_point(
	    'Local::DatabaseIntegrity' => 'db-begin'
   );

Roles within the Local::DatabaseIntegrity aspect can then watch for this
join point (using the C<whenever> sugar - see below) and execute code
when it is reached. That code might for instance, begin and end database
transactions.

=item C<< has ATTR => @OPTS >>

Standard Moose attribute definition. An aspect is a class (albeit a
singleton) so can be instantiated and have attributes.

=item C<< extends CLASS >>

Standard Moose superclass definition. An aspect is a class so can
inherit from other classes. It probably only makes sense to inherit
from other aspects.

May only be used outside role definitions.

=item C<< with ROLE >>

Standard Moose role composition.

May be used inside or outside role definitions.

=item C<< before METHOD => sub { CODE }; >>

Standard Moose before modifier. Within roles, uses L<MooseX::RoleQR>
which means that the method name can be specified as a regular
expression.

May be used inside or outside role definitions.

=item C<< after METHOD => sub { CODE }; >>

Standard Moose after modifier. Within roles, uses L<MooseX::RoleQR>
which means that the method name can be specified as a regular
expression.

May be used inside or outside role definitions.

=item C<< around METHOD => sub { CODE }; >>

Standard Moose around modifier. Within roles, uses L<MooseX::RoleQR>
which means that the method name can be specified as a regular
expression.

May be used inside or outside role definitions.

=item C<< guard METHOD => sub { CODE }; >>

Conceptually similar to C<before>, but if the coderef returns false,
then the original method is not called, and false is returned instead.
See also L<MooseX::Mangle>.

May be used inside or outside role definitions.

=item C<< whenever JOIN_POINT => sub { CODE }; >>

Code that is triggered to run whenever a join point is reached.

May only be used inside role definitions.

=item C<< requires METHOD >>

Standard Moose required method.

May only be used inside role definitions.

=back

=begin undocumented

=item C<< init_meta >>

Moose internal stuff

=item C<< optionally_apply_to PACKAGE, role { ... }; >>

Too experiemental to document.

=end undocumented

=head2 Methods

An aspect is a class (albeit a singleton), and thus can define methods.
By default it has the following methods:

=over

=item C<< new >>, C<< instance >>, C<< initialize(%args) >>

See L<MooseX::Singleton>.

=item C<< setup >>

By default, when an aspect is loaded the roles it defines are not actually
composed with anything. You need to call the C<setup> class method to compose
the roles.

=item C<< is_setup >>

Class method indicating whether C<setup> has happened.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Aspect>.

=head1 SEE ALSO

L<Moose>,
L<Aspect>.

L<MooseX::Aspect::Util>,
L<MooseX::Singleton>,
L<MooseX::RoleQR>.

L<http://en.wikipedia.org/wiki/Aspect-oriented_programming>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

