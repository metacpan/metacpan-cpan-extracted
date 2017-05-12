package Sub::NonRole;

use 5.008;
use strict;

BEGIN {
	$Sub::NonRole::AUTHORITY = 'cpan:TOBYINK';
	$Sub::NonRole::VERSION   = '0.004';
}

use Hook::AfterRuntime;
use MooX::CaptainHook -all;
use Sub::Identify 'get_code_info';

use base 'Sub::Talisman';

sub import
{
	shift->setup_for(scalar(caller), @_);
}

sub setup_for
{
	my ($class, $caller) = @_;
	$class->SUPER::setup_for($caller, { attribute => 'NonRole'});
	after_runtime { $class->_post_process($caller) };
}

sub _post_process
{
	my ($class, $caller) = @_;
	
	my @subs =
		map { /^\Q$caller\E::([^:]+)$/ ? $1 : () }
		$class->get_subs("$caller\::NonRole");
	push @subs, 'FETCH_CODE_ATTRIBUTES';
	
	if (exists $Role::Tiny::INFO{$caller})
	{
		$Role::Tiny::INFO{$caller}{not_methods}{$_} = $caller->can($_) for @subs;
		
		on_application {
			my ($role, $pkg) = @{ $_[0] };
		} $caller;
		
		on_inflation {
			if ($_->name eq $caller) {
				require Moose::Util::MetaRole;
				_mk_moose_trait();
				$_[0][0] = Moose::Util::MetaRole::apply_metaroles(
					for => $caller,
					role_metaroles => {
						role => ['Sub::NonRole::Trait::Role'],
					},
				);
				@{ $_[0][0]->non_role_methods } = @subs;
			}
		} $caller;
	}
	
	$INC{'Class/MOP.pm'} or return;
	my $class_of = 'Class::MOP'->can('class_of') or return;
	
	require Moose::Util::MetaRole;
	_mk_moose_trait();
	my $meta = $class_of->($caller);
	
	if ($meta->can('has_role_generator')) # lolcat
	{
		_mk_moose_trait_param();
		my $P_mc = $meta->parameters_metaclass;
		my $P_rg = $meta->role_generator;
		$meta = Moose::Util::MetaRole::apply_metaroles(
			for => $caller,
			role_metaroles => {
				role => ['Sub::NonRole::Trait::ParameterizableRole'],
			},
		);
		$meta->parameters_metaclass($P_mc);
		$meta->role_generator($P_rg);
	}
	else # standard Moose role
	{
		$meta = Moose::Util::MetaRole::apply_metaroles(
			for => $caller,
			role_metaroles => {
				role => ['Sub::NonRole::Trait::Role'],
			},
		);
	}
	
	@{ $meta->non_role_methods } = @subs;
}

my $made_it;
sub _mk_moose_trait
{
	return if $made_it++;
	eval q{
		package Sub::NonRole::Trait::Role;
		use Moose::Role;
		has non_role_methods => (
			is      => 'ro',
			isa     => 'ArrayRef',
			default => sub { [] },
		);
		around _get_local_methods => sub {
			my $orig = shift;
			my $self = shift;
			my %return = map { $_->name => $_ } $self->$orig(@_);
			delete @return{ @{$self->non_role_methods} };
			return values %return;
		};
		around get_method_list => sub {
			my $orig = shift;
			my $self = shift;
			my %return = map { $_ => 1 } $self->$orig(@_);
			delete @return{ @{$self->non_role_methods} };
			return keys %return;
		};
	};
}

my $made_it_param;
sub _mk_moose_trait_param
{
	return if $made_it_param++;
	eval q{
		package Sub::NonRole::Trait::ParameterizableRole;
		use Moose::Role;
		with 'Sub::NonRole::Trait::Role';
#		around generate_role => sub {
#			my $orig = shift;
#			my $self = shift;
#			my $role = $self->$orig(@_);
#			return $role;
#		};
	};
}

1;

__END__

=head1 NAME

Sub::NonRole - prevent some subs from appearing in a role's API

=head1 SYNOPSIS

   package My::Role {
      use Moose::Role;
      use Sub::NonRole;
      
      sub some_function {
         ...;
      }
      
      sub other_function : NonRole {
         ...;
      }
   }
   
   package My::Class {
      use Moose;
      with 'My::Role';
   }
   
   My::Class->some_function();    # ok
   My::Class->other_function();   # no such method!

=head1 DESCRIPTION

This module allows you to mark certain subs within a role as not being
part of the role's API. This means that they will not be copied across
into packages which consume the role.

The subs can still be called as:

   My::Role->other_function();
   My::Role::other_function();

It should work with L<Role::Tiny>, L<Moo::Role>, L<Moose::Role> and
L<MooseX::Role::Parameterized> roles.

=head2 Developer API

=over

=item C<< Sub::NonRole->setup_for($role) >>

If you wish to import the Sub::NonRole functionality into another package,
this is how to do it.

=item C<< $role->meta->non_role_methods >>

For Moose roles (but not Moo or Role::Tiny ones) you can access the
C<non_role_methods> attribute on the role's meta object to get an arrayref
of non-role method names.

=back

=head1 BUGS

Currently when consuming a Moo role within a Moose class, Sub::NonRole
can cause a warning to be issued in the global cleanup phase. This is
unlikely to result in serious problems; it's just annoying.

In older Perls (before 5.10.1 I believe), importing Sub::Role into a package
without actually applying the attribute to any subs can cause a crash with
the error message I<< Internal error: Your::Package symbol went missing >>.
Once you've applied the C<:NonRole> attribute to a sub, everything should be
OK.

Please report any other bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-NonRole>.

=head1 SEE ALSO

L<Role::Tiny>, L<Moo::Role>, L<Moose::Role>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

