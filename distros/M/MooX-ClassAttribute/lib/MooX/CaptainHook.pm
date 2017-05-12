package MooX::CaptainHook;

use 5.008;
use strict;
use warnings;

use Exporter::Shiny qw/ on_application on_inflation is_role /;

BEGIN {
	no warnings 'once';
	$MooX::CaptainHook::AUTHORITY = 'cpan:TOBYINK';
	$MooX::CaptainHook::VERSION   = '0.011';
}

our %on_application;
our %on_inflation;

sub is_role
{
	my $package = shift;
	require Role::Tiny;
	return !!1 if exists $Role::Tiny::INFO{$package};
	return !!0 if exists $Moo::MAKERS{$package};
	if ($INC{'Class/MOP.pm'} and my $classof = 'Class::MOP'->can('class_of')) {
		my $meta = $classof->($package);
		return !!1 if $meta && $meta->isa('Moose::Meta::Role');
	}
	return !!0;
}

{
	my %already;
	sub _fire
	{
		my (undef, $callbacks, $key, $args) = @_;
		return if defined $key && $already{$key}++;
		return unless $callbacks;
		for my $cb (@$callbacks)
		{
			$cb->($args) for $args->[0];  # local $_ aliasing
		}
	}
}

use constant ON_APPLICATION => do {
	package MooX::CaptainHook::OnApplication;
	BEGIN {
		no warnings 'once';
		$MooX::CaptainHook::OnApplication::AUTHORITY = 'cpan:TOBYINK';
		$MooX::CaptainHook::OnApplication::VERSION   = '0.011';
	}
	use Moo::Role;
	after apply_roles_to_package => sub
	{
		my ($toolage, $package, @roles) = @_;
		
		for my $role (@roles)
		{
			'MooX::CaptainHook'->_fire(
				$on_application{$role},
				"OnApplication: $package $role",
				[ $package, $role ],
			);
			
			# This stuff is for internals...
			push @{ $on_application{$package} ||= [] }, @{ $on_application{$role} || [] }
				if MooX::CaptainHook::is_role($package);
			push @{ $on_inflation{$package} ||= [] }, @{ $on_inflation{$role} || [] };
		}
	};
	__PACKAGE__;
};

# This sub makes sure that when a role which has an on_application hook
# gets inflated to a full Moose role (as will happen if the role is
# consumed by a Moose class!) then the generated metarole object will
# have a trait that still triggers the on_application hook.
#
# There are probably numerous edge cases not catered for, but my simple
# tests seem to work.
# 
sub _inflated
{
	my $args = shift;
	my $meta = $args->[0];
	return unless $meta->isa('Moose::Meta::Role');
	require Moose::Util::MetaRole;
	$args->[0] = $meta = Moose::Util::MetaRole::apply_metaroles(
		for            => $meta->name,
		role_metaroles => {
			role => eval q{
				package MooX::CaptainHook::OnApplication::Moose;
				BEGIN {
					no warnings 'once';
					$MooX::CaptainHook::OnApplication::Moose::AUTHORITY = 'cpan:TOBYINK';
					$MooX::CaptainHook::OnApplication::Moose::VERSION   = '0.011';
				}
				use Moose::Role;
				after apply => sub {
					my $role    = $_[0]->name;
					my $package = $_[1]->name;
					
					'MooX::CaptainHook'->_fire(
						$on_application{$role},
						"OnApplication: $package $role",
						[ $package, $role ],
					);
					
					# This stuff is for internals...
					if (MooX::CaptainHook::is_role($_[1]->name)) {
						push @{ $on_application{$package} ||= [] }, @{ $on_application{$role} || [] };
						Moose::Util::MetaRole::apply_metaroles(
							for            => $package,
							role_metaroles => {
								role => [__PACKAGE__],
							},
						);
					}
				};
				[__PACKAGE__];
			},
		},
	);
}

sub on_application (&;$)
{
	my ($code, $role) = @_;
	$role = caller unless defined $role;
	push @{$on_application{$role}||=[]}, $code;
	
	'Moo::Role'->apply_single_role_to_package('Moo::Role', ON_APPLICATION)
		unless Role::Tiny::does_role('Moo::Role', ON_APPLICATION);
	
	return;
}

use constant ON_INFLATION => do {
	package MooX::CaptainHook::OnInflation;
	BEGIN {
		no warnings 'once';
		$MooX::CaptainHook::OnInflation::AUTHORITY = 'cpan:TOBYINK';
		$MooX::CaptainHook::OnInflation::VERSION   = '0.011';
	}
	use Moo::Role;
	around inject_real_metaclass_for => sub
	{
		my ($orig, $pkg) = @_;
		my $args = [ scalar $orig->($pkg) ];
		'MooX::CaptainHook'->_fire(
			[
				'MooX::CaptainHook'->can('_inflated'),
				@{$on_inflation{$pkg}||[]}
			],
			undef,
			$args,
		);
		return $args->[0];
	};
	__PACKAGE__;
};

sub on_inflation (&;$)
{
	my ($code, $pkg) = @_;
	$pkg = caller unless defined $pkg;
	push @{$on_inflation{$pkg}||=[]}, $_[0];

	return;
}

{
	package MooX::CaptainHook::HandleMoose::Hack;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.011';
	use overload qw[bool] => sub { 0 };
	sub DESTROY {
		'Moo::Role'->apply_single_role_to_package('Moo::HandleMoose', MooX::CaptainHook::ON_INFLATION)
			if Moo::HandleMoose->can('inject_real_metaclass_for')
			&& !Role::Tiny::does_role('Moo::HandleMoose', MooX::CaptainHook::ON_INFLATION);
	}
	if ($Moo::HandleMoose::SETUP_DONE)
		{ __PACKAGE__->DESTROY }
	else
		{ $Moo::HandleMoose::SETUP_DONE ||= bless [] }
}

1;

__END__

=pod

=encoding utf8

=for stopwords MooX metaclass

=head1 NAME

MooX::CaptainHook - hooks for MooX modules

=head1 SYNOPSIS

   {
      package Local::Role;
      use Moo::Role;
      use MooX::CaptainHook qw(on_application);
      
      on_application {
         print "Local::Role applied to $_\n";
      };
   }
   
   {
      package Local::Class;
      use Moo;
      with 'Local::Role'; # "Local::Role applied to Local::Class"
   }

=head1 DESCRIPTION

Although developed to support L<MooX::ClassAttribute>, 
C<MooX::CaptainHook> provides a feature which may be of use to other 
people writing Moo roles and MooX modules.

This module allows you to run callback code when various events happen 
to Moo classes and roles. Callback code for a role will also be copied 
as hooks for any packages that consume that role.

=over

=item C<< on_application { BLOCK } >>

The C<on_application> hook allows you to run a callback when your role
is applied to a class or other role. Within the callback C<< $_[0][0] >>
is set to the name of the package that the role is being applied to.

Also C<< $_[0][1] >> is set to the name of the role being applied, which
may not be the same as the role where the hook was initially defined. (For
example, when role X establishes a hook; role X is consumed by role Y; and
role Y is consumed by class Z. Then the callback code will run twice, once
with C<< $_[0] = [qw(Y X)] >> and once with C<< $_[0] = [qw(Z Y)] >>.)

Altering the C<< $_[0] >> arrayref will alter what is passed to subsequent
callbacks, so is not recommended.

=item C<< on_inflation { BLOCK } >>

The C<on_inflation> hook runs if your class or role is "inflated" to a
full Moose class or role. C<< $_[0][0] >> is the associated metaclass.

Setting C<< $_[0][0] >> to a new meta object should "work" (whatever that
means).

=item C<< is_role($package) >>

Returns a boolean indicating whether the package is a role.

=back

Within callback code blocks, C<< $_ >> is also available as a convenient
alias to C<< $_[0][0] >>.

=head2 Installing Hooks for Other Packages

You can pass a package name as an optional second parameter:

   use MooX::CaptainHook;
   
   MooX::CaptainHook::on_application {
      my ($applied_to, $role) = @_;
      ...;
   } 'Your::Role';

=begin private

=item ON_APPLICATION

=item ON_INFLATION

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>.

=head1 SEE ALSO

L<Moo>, L<MooX::ClassAttribute>.

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

