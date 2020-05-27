use 5.006;
use strict;
use warnings;

package Role::Inspector;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Exporter::Shiny qw( get_role_info learn does_role );
use Module::Runtime qw( use_package_optimistically );
use Scalar::Util qw( blessed );

BEGIN {
	*uniq = eval { require List::MoreUtils }
		? \&List::MoreUtils::uniq
		: sub { my %already; grep !$already{$_}++, @_ }
}

our @SCANNERS;

sub learn (&)
{
	push @SCANNERS, $_[0];
}

sub get_role_info
{
	my $me = shift;
	use_package_optimistically($_[0]);
	my ($info) = grep defined, map $_->(@_), @SCANNERS;
	$me->_canonicalize($info, @_);
	return $info;
}

sub _generate_get_role_info
{
	my $me = shift;
	my ($name, $args, $globals) = @_;
	return sub {
		my $info = $me->get_role_info(@_);
		delete($info->{meta}) if $args->{no_meta};
		return $info;
	};
}

sub _canonicalize
{
	my $me = shift;
	my ($info) = @_;
	
	if ( $info->{api} and not( $info->{provides} && $info->{requires} ) )
	{
		my @provides;
		my @requires;
		for my $method (@{ $info->{api} })
		{
			push @{
				$info->{name}->can($method) ? \@provides : \@requires
			}, $method;
		}
		$info->{provides} ||= \@provides;
		$info->{requires} ||= \@requires;
	}
	
	if ( not $info->{api} )
	{
		$info->{api} = [
			@{ $info->{provides} ||= [] },
			@{ $info->{requires} ||= [] },
		];
	}
	
	# if a method is in both `provides` and `requires`, remove from `requires`
	my %lookup;
	undef $lookup{$_} for @{$info->{provides}};
	@{$info->{requires}} = grep !exists($lookup{$_}), @{$info->{requires}};
	
	for my $k (qw/ api provides requires /) {
		@{ $info->{$k} } = sort(
			uniq(
				map ref($_) ? $_->{name} : $_,
				@{ $info->{$k} }
			)
		);
	}
}

sub _expand_attributes
{
	my $me = shift;
	my ($role, $meta) = @_;
	
	my @attrs = map {
		my $data = $meta->get_attribute($_);
		$data->{name} = $_ unless exists($data->{name});
		$data;
	} $meta->get_attribute_list;
	my %methods;
	
	for my $attr (@attrs)
	{
		my $is = blessed($attr) && $attr->can('is') ? $attr->is : $attr->{is};
		$methods{blessed($attr) && $attr->can('name') ? $attr->name : $attr->{name} }++
			if $is =~ /\A(ro|rw|lazy|rwp)\z/i;
		
		for my $method_type (qw(reader writer accessor clearer predicate))
		{
			my $method_name = blessed($attr) ? $attr->$method_type : $attr->{$method_type};
			($method_name) = %$method_name if ref($method_name); # HASH :-(
			$methods{$method_name}++ if defined $method_name;
		}
		
		my $handles;
		if (blessed($attr) and $attr->can('_canonicalize_handles'))
		{
			$handles =
				$attr->can('_canonicalize_handles') ? +{ $attr->_canonicalize_handles } :
				$attr->can('handles') ? $attr->handles :
				$attr->{handles};
		}
		else
		{
			$handles = $attr->{handles};
		}
		
		if (!defined $handles)
		{
			# no-op
		}
		elsif (not ref($handles))
		{
			$methods{$_}++ for @{ $me->get_info($handles)->{api} };
		}
		elsif (ref($handles) eq q(ARRAY))
		{
			$methods{$_}++ for @$handles;
		}
		elsif (ref($handles) eq q(HASH))
		{
			$methods{$_}++ for keys %$handles;
		}
		else
		{
			require Carp;
			Carp::carp(
				sprintf(
					"%s contains attribute with delegated methods, but %s cannot determine which methods are being delegated",
					$role,
					$me,
				)
			);
		}
	}
	
	return keys(%methods);
}

# Learn about mop
learn {
	my $role = shift;
	return unless $INC{'mop.pm'};
	
	my $meta = mop::meta($role);
	return unless $meta && $meta->isa('mop::role');
	
	return {
		name     => $role,
		type     => 'mop::role',
		provides => [ sort(map($_->name, $meta->methods)) ],
		requires => [ sort($meta->required_methods) ],
		meta     => $meta,
	};
};

# Learn about Role::Tiny and Moo::Role
learn {
	my $role = shift;
	return unless $INC{'Role/Tiny.pm'};
	
	# Moo 1.003000 added is_role, but that's too new to rely on.
	my @methods;
	return unless eval {
		@methods = 'Role::Tiny'->methods_provided_by($role);
		1;
	};
	
	no warnings qw(once);
	my $type =
		($INC{'Moo/Role.pm'} and $Moo::Role::INFO{$role}{accessor_maker})
		? 'Moo::Role'
		: 'Role::Tiny';
	
	@methods = $type->methods_provided_by($role)
		if $type ne 'Role::Tiny';
	
	my @requires = @{ $Role::Tiny::INFO{$role}{requires} or [] };
	
	my $modifiers = $Role::Tiny::INFO{$role}{modifiers} || [];
	foreach my $modifier (@$modifiers) {
		my @modified = @$modifier[ 1 .. $#$modifier - 1 ];
		# handle: before ['foo', 'bar'] => sub { ... }
		@modified = @{ $modified[0] } if ref $modified[0] eq 'ARRAY';
		push @requires, @modified;
	}
	
	return {
		name     => $role,
		type     => $type,
		api      => [ @methods, @requires ],
		provides => [ keys %{ $type->_concrete_methods_of($role) } ],
		requires => \@requires,
	};
};

# Learn about Moose
learn {
	my $role = shift;
	return unless $INC{'Moose.pm'};
	
	require Moose::Util;
	my $meta = Moose::Util::find_meta($role);
	return unless $meta && $meta->isa('Moose::Meta::Role');
	
	my (@provides, @requires);
	push @provides, $meta->get_method_list;
	push @provides, __PACKAGE__->_expand_attributes($role, $meta);
	push @requires, map($_->name, $meta->get_required_method_list);
	for my $kind (qw/before after around/) {
		my $accessor = "get_${kind}_method_modifiers_map";
		push @requires, keys %{ $meta->$accessor };
	}
	
	return {
		name     => $role,
		type     => 'Moose::Role',
		meta     => $meta,
		provides => \@provides,
		requires => \@requires,
	};
};

# Learn about Mouse
learn {
	my $role = shift;
	return unless $INC{'Mouse.pm'};
	
	require Mouse::Util;
	my $meta = Mouse::Util::find_meta($role);
	return unless $meta && $meta->isa('Mouse::Meta::Role');
	
	my (@provides, @requires);
	push @provides, $meta->get_method_list;
	push @provides, __PACKAGE__->_expand_attributes($role, $meta);
	push @requires, $meta->get_required_method_list;
	for my $kind (qw/before after around/) {
		push @requires, keys %{ $meta->{"${kind}_method_modifiers"} };
	}
	
	return {
		name     => $role,
		type     => 'Mouse::Role',
		meta     => $meta,
		provides => \@provides,
		requires => \@requires,
	};
};

# Learn about Role::Basic
learn {
	my $role = shift;
	return unless $INC{'Role/Basic.pm'};
	
	return unless eval { 'Role::Basic'->_load_role($role) };
	
	return {
		name     => $role,
		type     => 'Role::Basic',
		provides => [ keys %{ 'Role::Basic'->_get_methods($role) } ],
		requires => [ 'Role::Basic'->get_required_by($role) ],
	};
};

sub does_role
{
	my $me = shift;
	my ($thing, $role) = @_;
	
	return !!0 if !defined($thing);
	return !!0 if ref($thing) && !blessed($thing);
	
	ref($_) or use_package_optimistically($_) for @_;
	
	return !!1 if $thing->can('does') && $thing->does($role);
	return !!1 if $thing->can('DOES') && $thing->DOES($role);
	
	my $info = $me->get_role_info($role)
		or return !!0;
	
	if ($info->{type} eq 'Role::Tiny' or $info->{type} eq 'Moo::Role')
	{
		return !!1 if Role::Tiny::does_role($thing, $role);
	}
	
	if ($info->{type} eq 'Moose::Role')
	{
		require Moose::Util;
		return !!1 if Moose::Util::does_role($thing, $role);
	}
	
	if ($info->{type} eq 'Mouse::Role')
	{
		require Mouse::Util;
		return !!1 if Mouse::Util::does_role($thing, $role);
	}
	
	if (not ref $thing)
	{
		my $info2 = $me->get_role_info($thing) || { type => '' };
		
		if ($info2->{type} eq 'Role::Tiny' or $info2->{type} eq 'Moo::Role')
		{
			return !!1 if Role::Tiny::does_role($thing, $role);
		}
		
		if ($info2->{type} eq 'Moose::Role'
		or $INC{'Moose.pm'} && Moose::Util::find_meta($thing))
		{
			require Moose::Util;
			return !!1 if Moose::Util::does_role($thing, $role);
		}
		
		if ($info2->{type} eq 'Mouse::Role'
		or $INC{'Mouse.pm'} && Mouse::Util::find_meta($thing))
		{
			require Mouse::Util;
			return !!1 if Mouse::Util::does_role($thing, $role);
		}
	}
	
	# No special handling for Role::Basic, but hopefully checking
	# `DOES` worked!
	
	!!0;
}

# very simple class method curry
sub _generate_does_role
{
	my $me = shift;
	sub { $me->does_role(@_) };
}


1;

__END__

=pod

=encoding utf-8

=for stopwords metaobject

=head1 NAME

Role::Inspector - introspection for roles

=head1 SYNOPSIS

   use strict;
   use warnings;
   use feature qw(say);
   
   {
      package Local::Role;
      use Role::Tiny;   # or Moose::Role, Mouse::Role, etc...
      
      requires qw( foo );
      
      sub bar { ... }
   }
   
   use Role::Inspector qw( get_role_info );
   
   my $info = get_role_info('Local::Role');
   
   say $info->{name};          # Local::Role
   say $info->{type};          # Role::Tiny
   say for @{$info->{api}};    # bar
                               # foo

=head1 DESCRIPTION

This module allows you to retrieve a hashref of information about a
given role. The following role implementations are supported:

=over

=item *

L<Moose::Role>

=item *

L<Mouse::Role>

=item *

L<Moo::Role>

=item *

L<Role::Tiny>

=item *

L<Role::Basic>

=item *

L<p5-mop-redux|https://github.com/stevan/p5-mop-redux>

=back

=head2 Functions

=over

=item C<< get_role_info($package_name) >>

Returns a hashref of information about a role; returns C<undef> if the
package does not appear to be a role. Attempts to load the package
using L<Module::Runtime> if it's not already loaded.

The hashref may contain the following keys:

=over

=item *

C<name> - the package name of the role

=item *

C<type> - the role implementation used by the role

=item *

C<api> - an arrayref of method names required/provided by the role

=item *

C<provides> and C<requires> - the same as C<api>, but split into lists
of methods provided and required by the role

=item *

C<meta> - a metaobject for the role (e.g. a L<Moose::Meta::Role> object).
This key may be absent if the role implementation does not provide a
metaobject

=back

This function may be exported, but is not exported by default.

=item C<< does_role($thing, $role) >>

Returns a boolean indicating if C<< $thing >> does role C<< $role >>.
C<< $thing >> can be an object, a class name, or a role name.

This should mostly give the same answers as C<< $thing->DOES($role) >>,
but may be slightly more reliable in some cross-implementation (i.e.
Moose roles consuming Moo roles) cases.

This function may be exported, but is not exported by default.

=back

=head2 Methods

If you do not wish to export the functions provided by Role::Inspector,
you may call them as a class methods:

   my $info = Role::Inspector->get_role_info($package_name);

   $thing->blah() if Role::Inspector->does_role($thing, $role);

=head2 Extending Role::Inspector

=over

=item C<< Role::Inspector::learn { BLOCK } >>

In the unlikely situation that you have to deal with some other role
implementation that Role::Inspector doesn't know about, you can teach
it:

   use Role::Inspector qw( learn );
   
   learn {
      my $r = shift;
      return unless My::Implementation::is_role($r);
      return {
         name     => $r,
         type     => 'My::Implementation',
         provides => [ sort(@{My::Implementation::provides($r)}) ],
         requires => [ sort(@{My::Implementation::requires($r)}) ],
      };
   };

An alternative way to do this is:

   push @Role::Inspector::SCANNERS, sub {
      my $r = shift;
      ...;
   };

You can do the C<push> thing without having loaded Role::Inspector.
This makes it suitable for doing inside My::Implementation itself,
without introducing an additional dependency on Role::Inspector.

Note that if you don't provide all of C<provides>, C<requires>, and
C<api>, Role::Inspector will attempt to guess the missing parts.

=back

=head1 CAVEATS

=over

=item *

It is difficult to distinguish between L<Moo::Role> and L<Role::Tiny>
roles. (The distinction is not often important anyway.) Thus sometimes
the C<type> for a Moo::Role may say C<< "Role::Tiny" >>.

=item *

The way that Role::Basic roles are detected and introspected is a bit
dodgy, relying on undocumented methods.

=item *

Where Moose or Mouse roles define attributes, those attributes tend to
result in accessor methods being generated. However neither of these
frameworks provides a decent way of figuring out which accessor methods
will result from composing the role with the class.

Role::Inspector does its damnedest to figure out the list of likely
methods, but (especially in the case of unusual attribute traits) may
get things wrong from time to time.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Inspector>.

=head1 SEE ALSO

L<Class::Inspector>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

