use 5.008001;
use strict;
use warnings;

package Role::Hooks;

use Class::Method::Modifiers qw( install_modifier );

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

our %CALLBACKS_BEFORE_APPLY;
our %CALLBACKS_AFTER_APPLY;
our %CALLBACKS_AFTER_INFLATE;
our %ARGS;

BEGIN { *DEBUG = $ENV{'PERL_ROLE_HOOKS_DEBUG'} ? sub(){1} : sub(){0} };

# limited version of Safe::Isa
my $_isa = sub { ref( $_[0] ) and $_[0]->isa( $_[1] ) };

sub _croak {
	my ($me, $msg, @args) = @_;
	require Carp;
	Carp::croak( @args ? sprintf($msg, @args) : $msg );
}

sub _carp {
	my ($me, $msg, @args) = @_;
	require Carp;
	Carp::carp( @args ? sprintf($msg, @args) : $msg );
}

sub _debug {
	my ($me, $msg, @args) = @_;
	require Carp;
	Carp::carp( @args ? sprintf($msg, @args) : $msg ) if DEBUG;
}

sub is_role {
	my $target = pop;
	
	if ($INC{'Role/Tiny.pm'}
	and 'Role::Tiny'->can('is_role')
	and 'Role::Tiny'->is_role($target)) {
		return 'Role::Tiny';
	}
	
	# really old versions of Role::Tiny
	if ($INC{'Role/Tiny.pm'}
	and !'Role::Tiny'->can('is_role')
	and $Role::Tiny::INFO{$target}) {
		return 'Role::Tiny'; # uncoverable statement
	}
	
	if ($INC{'Moose/Meta/Role.pm'}
	and do { require Moose::Util; 1 }
	and Moose::Util::find_meta($target)->$_isa('Moose::Meta::Role')) {
		return 'Moose::Role';
	}
	
	if ($INC{'Mouse/Meta/Role.pm'}
	and do { require Mouse::Util; 1 }
	and Mouse::Util::find_meta($target)->$_isa('Mouse::Meta::Role')) {
		return 'Mouse::Role';
	}
	
	if ($INC{'Role/Basic.pm'}
	and eval { 'Role::Basic'->_load_role($target) }) {
		return 'Role::Basic';
	}
	
	return undef;
}

sub before_apply {
	my ($me, $target, @callbacks) = @_;
	return unless @callbacks;
	$me->is_role($target) or $me->_croak('%s is not a role', $target);
	$me->_install_patches($target);
	push @{ $CALLBACKS_BEFORE_APPLY{$target}||=[] }, @callbacks;
	return $me;
}

sub after_apply {
	my ($me, $target, @callbacks) = @_;
	return unless @callbacks;
	$me->is_role($target) or $me->_croak('%s is not a role', $target);
	$me->_install_patches($target);
	push @{ $CALLBACKS_AFTER_APPLY{$target}||=[] }, @callbacks;
	return $me;
}

sub after_inflate {
	no warnings 'uninitialized';
	my ($me, $target, @callbacks) = @_;
	return unless @callbacks;
	$me->is_role($target) eq 'Role::Tiny'
		or $target->isa('Moo::Object')
		or $me->_croak('%s is not a Moo class or role', $target);
	$me->_install_patches($target);
	$me->_install_patches_inflation($target);
	push @{ $CALLBACKS_AFTER_INFLATE{$target}||=[] }, @callbacks;
	return $me;
}

{
	# Internals for monkey-patching role implementations.
	#
	
	my %patched;
	sub _install_patches {
		my ($me, $target) = @_;
		
		if ($INC{'Role/Tiny.pm'}) {
			$patched{'Role::Tiny'} ||= $me->_install_patches_roletiny;
		}
		if ($INC{'Moo/Role.pm'} or $INC{'Moo.pm'}) {
			$patched{'Moo::Role'}  ||= $me->_install_patches_moorole;
		}
		if ($INC{'Moose/Role.pm'} or $INC{'Moose.pm'}) {
			$patched{'Moose::Role'} ||= $me->_install_patches_mooserole;
		}
		if ($INC{'Mouse/Role.pm'} or $INC{'Mouse.pm'}) {
			$patched{'Mouse::Role'} ||= $me->_install_patches_mouserole;
		}
		if ($INC{'Role/Basic.pm'}) {
			$patched{'Role::Basic'} ||= $me->_install_patches_rolebasic;
		}
	}
	
	my %patched_inflation;
	sub _install_patches_inflation {
		my ($me, $target) = @_;
		if ($INC{'Moo/Role.pm'} or $INC{'Moo.pm'}) {
			$patched_inflation{'Moo::Role'}  ||= $me->_install_patches_moorole_inflation;
		}
	}
	
	sub _install_patches_roletiny {
		my ($me) = @_;
		return 1 if $patched{'Role::Tiny'};
		
		$me->_debug("Installing patches for Role::Tiny") if DEBUG;
		
		require Role::Tiny;
		
		install_modifier 'Role::Tiny', around => 'role_application_steps', sub {
			my $orig = shift;
			my @steps = $orig->(@_);
			return (
				__PACKAGE__ . '::_run_role_tiny_before_callbacks',
				@steps,
				__PACKAGE__ . '::_run_role_tiny_after_callbacks',
			);
		};
		
		*_run_role_tiny_before_callbacks = sub {
			my (undef, $to, $role) = @_;
			$me->_debug("Calling role hooks for $role before application to $to") if DEBUG;
			my @callbacks = @{ $CALLBACKS_BEFORE_APPLY{$role} || [] };
			for my $cb (@callbacks) {
				$cb->($role, $to);
			}
			return;
		};
		
		*_run_role_tiny_after_callbacks = sub {
			my (undef, $to, $role) = @_;
			$me->_debug("Calling role hooks for $role after application to $to") if DEBUG;
			my @callbacks = @{ $CALLBACKS_AFTER_APPLY{$role} || [] };
			for my $cb (@callbacks) {
				$cb->($role, $to);
			}
			if (my $is_role = $me->is_role($to)) {
				$me->_debug("Copying role hooks for $role to $to") if DEBUG;
				$me->before_apply($to, @{ $CALLBACKS_BEFORE_APPLY{$role} || [] });
				$me->after_apply($to, @{ $CALLBACKS_AFTER_APPLY{$role} || [] });
				if ($is_role eq 'Role::Tiny' or $to->isa('Moo::Object')) {
					$me->after_inflate($to, @{ $CALLBACKS_AFTER_INFLATE{$role} || [] });
				}
			}
			return;
		};
		
		return 1;
	}
	
	sub _install_patches_moorole {
		my ($me) = @_;
		$patched{'Role::Tiny'} ||= $me->_install_patches_roletiny;
		return 1 if $patched{'Moo::Role'};
		
		$me->_debug("Installing patches for Moo::Role") if DEBUG;
		
		require Moo::Role;
		require List::Util;
		
		# Mostly can just rely on Role::Tiny, but need
		# to move _run_callbacks_before_apply to the
		# front of the queue!
		#
		install_modifier 'Moo::Role', around => 'role_application_steps', sub {
			my $orig = shift;
			my @steps = $orig->(@_);
			return List::Util::uniqstr(
				__PACKAGE__ . '::_run_role_tiny_before_callbacks',
				@steps,
			);
		};
		
		return 1;
	}
	
	sub _install_patches_moorole_inflation {
		my ($me) = @_;
		return 1 if $patched_inflation{'Moo::Role'};
		
		$me->_debug("Installing inflation patches for Moo::Role") if DEBUG;
		
		require Moo::HandleMoose;
		
		install_modifier 'Moo::HandleMoose', after => 'inject_real_metaclass_for', sub {
			my ( $name ) = @_;
			$me->_run_moo_inhale_callbacks( $name );
		};
		
		my %already;
		*_run_moo_inhale_callbacks = sub {
			my (undef, $name) = @_;
			$me->_debug("Calling role hooks for $name after inflation") if DEBUG;
			my @callbacks = @{ $CALLBACKS_AFTER_INFLATE{$name} || [] };
			for my $cb (@callbacks) {
				next if $already{"$name|$cb"}++;
				$cb->($name);
			}
		};
		
		return 1;
	}
	
	sub _install_patches_mooserole {
		my ($me) = @_;
		return 1 if $patched{'Moose::Role'};
		
		$me->_debug("Installing patches for Moose::Role") if DEBUG;
		
		require Moose::Meta::Role;
		
		install_modifier 'Moose::Meta::Role', around => 'apply', sub {
			my ($orig, $role_meta, $to_meta, %args) = @_;
			local *ARGS = \%args;
			my $role = $role_meta->name;
			my $to   = $to_meta->name;
			do {
				$me->_debug("Calling role hooks for $role before application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_BEFORE_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			my $application = $role_meta->$orig($to_meta, %args);
			do {
				$me->_debug("Calling role hooks for $role after application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_AFTER_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			if ($me->is_role($to)) {
				$me->_debug("Copying role hooks for $role to $to") if DEBUG;
				$me->before_apply($to, @{ $CALLBACKS_BEFORE_APPLY{$role} || [] });
				$me->after_apply($to, @{ $CALLBACKS_AFTER_APPLY{$role} || [] });
			}
			return $application;
		};
		
		return 1;
	}
	
	sub _install_patches_mouserole {
		my ($me) = @_;
		return 1 if $patched{'Mouse::Role'};
		
		$me->_debug("Installing patches for Mouse::Role") if DEBUG;
		
		require Mouse::Meta::Role;
		
		install_modifier 'Mouse::Meta::Role', around => 'apply', sub {
			my ($orig, $role_meta, $to_meta, %args) = @_;
			local *ARGS = \%args;
			my $role = $role_meta->name;
			my $to   = $to_meta->name;
			do {
				$me->_debug("Calling role hooks for $role before application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_BEFORE_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			my $application = $role_meta->$orig($to_meta, %args);
			do {
				$me->_debug("Calling role hooks for $role after application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_AFTER_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			if ($me->is_role($to)) {
				$me->_debug("Copying role hooks for $role to $to") if DEBUG;
				$me->before_apply($to, @{ $CALLBACKS_BEFORE_APPLY{$role} || [] });
				$me->after_apply($to, @{ $CALLBACKS_AFTER_APPLY{$role} || [] });
			}
			return $application;
		};
		
		return 1;
	}
	
	sub _install_patches_rolebasic {
		my ($me) = @_;
		return 1 if $patched{'Role::Basic'};
		
		$me->_debug("Installing patches for Role::Basic") if DEBUG;
		
		require Role::Basic;
		
		$me->_carp("Role::Hooks is only tested with Role::Basic 0.07 to 0.13")
			unless $Role::Basic::VERSION =~ /^0\.(?:0[7-9]|1[0-3])/;
		
		install_modifier 'Role::Basic', around => '_add_role_methods_to_target', sub {
			my ($orig, $rb, $role, $to, $modifiers) = @_;
			local *ARGS = $modifiers;
			do {
				$me->_debug("Calling role hooks for $role before application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_BEFORE_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			my $application = $rb->$orig($role, $to, $modifiers);
			do {
				$me->_debug("Calling role hooks for $role after application to $to") if DEBUG;
				my @callbacks = @{ $CALLBACKS_AFTER_APPLY{$role} || [] };
				for my $cb (@callbacks) {
					$cb->($role, $to);
				}
			};
			if ($me->is_role($to)) {
				$me->_debug("Copying role hooks for $role to $to") if DEBUG;
				$me->before_apply($to, @{ $CALLBACKS_BEFORE_APPLY{$role} || [] });
				$me->after_apply($to, @{ $CALLBACKS_AFTER_APPLY{$role} || [] });
			}
			return $application;
		};
		
		return 1;
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Role::Hooks - role callbacks

=head1 SYNOPSIS

  package Local::Role {
    use Moo::Role;
    use Role::Hooks;
    
    Role::Hooks->after_apply(__PACKAGE__, sub {
      my ($role, $target) = @_;
      print "$role has been applied to $target.\n";
    });
  }
  
  package Local::Class {
    use Moo;
    with "Local::Role";   # prints above message
  }

=head1 DESCRIPTION

This module allows a role to run a callback when it is applied to a class or
to another role.

=head2 Compatibility

It should work with L<Role::Tiny>, L<Moo::Role>, L<Moose::Role>,
L<Mouse::Role>, and L<Role::Basic>. Not all class builders work well with
all role builders (for example, a Moose class consuming a Mouse role). But
when they do work together, Role::Hooks should be able to run the callbacks.
(The only combination I've tested is Moo with Moose though.)

Some other role implementations (such as L<Moos::Role>, L<exact::role>,
and L<OX::Role>) are just wrappers around one of the supported role builders,
so should mostly work.

With Role::Basic, the C<after_apply> hook is called a little earlier than
would be ideal; after the role has been fully loaded and its methods have
been copied into the target package, but before handling C<requires>, and
before patching the C<DOES> method in the target package. If you are using
Role::Basic, consider switching to Role::Tiny.

Apart from Role::Tiny/Moo::Role, a hashref of additional arguments (things
like "-excludes" and "-alias") can be passed when consuming a role. Although
I discourage people from using these in general, if you need access to
these arguments in the callback, you can check C<< %Role::Hooks::ARGS >>.

Roles generated via L<Package::Variant> should work; see
F<t/20packagevariant.t> for a demonstration.

=head2 Methods

=over

=item C<< before_apply >>

  Role::Hooks->before_apply($rolename, $callback);

Sets up a callback for a role that will be called before the role is applied
to a target package. The callback will be passed two parameters: the role
being applied and the target package.

The role being applied may not be the same role as the role the callback was
defined in!

  package Local::Role1 {
    use Moo::Role;
    use Role::Hooks;
    Role::Hooks->before_apply(__PACKAGE__, sub {
      my ($role, $target) = @_;
      print "$role has been applied to $target.\n";
    });
  }
  
  package Local::Role2 {
    use Moo::Role;
    with "Local::Role1";
  }
  
  package Local::Class1 {
    use Moo::Role;
    with "Local::Role2";
  }

This will print:

  Local::Role1 has been applied to Local::Role2.
  Local::Role2 has been applied to Local::Class1.

If you only care about direct applications of roles (i.e. the first one):

  Role::Hooks->before_apply(__PACKAGE__, sub {
    my ($role, $target) = @_;
    return if $role ne __PACKAGE__;
    print "$role has been applied to $target.\n";
  });

If you only care about roles being applied to classes (i.e. the second one):

  Role::Hooks->before_apply(__PACKAGE__, sub {
    my ($role, $target) = @_;
    return if Role::Hooks->is_role($target);
    print "$role has been applied to $target.\n";
  });

=item C<< after_apply >>

  Role::Hooks->after_apply($rolename, $callback);

The same as C<< before_apply >>, but called later in the role application
process.

Note that when the callback is called, even though it's after the role has
been applied to the target, it doesn't mean the target has finished being
built. For example, there might be C<has> statements after the C<with>
statement, and those will not have been evaluated yet.

If you want to throw an error when someone applies your role to an
inappropriate target, it is probably better to do that in C<before_apply> if
you can.

=item C<< after_inflate >>

  Role::Hooks->after_inflate($pkg_name, $callback);

Even though this is part of Role::Hooks, it works on classes too.
But it only works on classes and roles built using Moo. This runs
your callback if your Moo class or role gets "inflated" to a Moose
class or role.

If you set up a callback for a role, then the callback will also
get called if any packages that role was applied to get inflated.

=item C<< is_role >>

Will return true if the given package seems to be a role, false otherwise.

(In fact, returns a string representing which role builder the role seems
to be using -- "Role::Tiny", "Moose::Role", "Mouse::Role", or "Role::Basic";
roles built using Moo::Role are detected as "Role::Tiny".)

=back

=head1 ENVIRONMENT

The environment variable C<PERL_ROLE_HOOKS_DEBUG> may be set to true to
enable debugging messages.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Hooks>.

=head1 SEE ALSO

L<Role::Tiny>, L<Moose::Role>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
