package MooseX::RoleQR;

use 5.008;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooseX::RoleQR::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::RoleQR::VERSION   = '0.004';
}

use Moose ();
use Moose::Exporter;
use Scalar::Does qw( does blessed -constants );

Moose::Exporter->setup_import_methods(
	with_meta => [qw/ before after around /],
	also      => 'Moose::Role',
);

my %ROLE_METAROLES = (
	role                       => ['MooseX::RoleQR::Trait::Role'],
	application_to_class       => ['MooseX::RoleQR::Trait::Application::ToClass'],
	application_to_role        => ['MooseX::RoleQR::Trait::Application::ToRole'],
);
my %ARGH;

sub _add_method_modifier
{
	my $type = shift;
	my $meta = shift;

	if (does($_[0], REGEXP) or does($_[0], CODE))
	{
		my $pusher = "add_deferred_${type}_method_modifier";
		return $meta->$pusher(@_);
	}

	Moose::Util::add_method_modifier($meta, $type, \@_);
}

sub before { _add_method_modifier(before => @_) }
sub after  { _add_method_modifier(after  => @_) }
sub around { _add_method_modifier(around => @_) }

sub init_meta
{
	my $class   = shift;
	my %options = @_;
	Moose::Role->init_meta(%options);
	
	Moose::Util::MetaRole::apply_metaroles(
		for            => $options{for_class},
		role_metaroles => \%ROLE_METAROLES,
	);
}

{
	no warnings;
	my $orig = Moose::Meta::Role->can('combine');
	*Moose::Meta::Role::combine = sub {
		my ($meta, @role_specs) = @_;
		my $combo = $meta->$orig(@role_specs);
		return bless(
			$combo,
			Moose::Util::with_traits(
				ref($combo),
				'MooseX::RoleQR::Trait::Role::Composite',
			),
		);
	}
};

BEGIN {
	package MooseX::RoleQR::Meta::DeferredModifier;
	no thanks;
	use Moose;
	use Scalar::Does -constants;
	use namespace::sweep;

	BEGIN {
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.004';
	};

	has [qw/ expression body /] => (is => 'ro', required => 1);
	
#	sub matches_name
#	{
#		my ($meta, $name) = @_;
#		my $return = $meta->_matches_name($name);
#		print ($return ? "@{[$meta->expression]} matches $name\n" : "@{[$meta->expression]} does not match $name\n");
#		return $return;
#	}
#	
#	sub _matches_name
	sub matches_name
	{
		my ($meta, $name, $hints) = @_;
		my $expr = $meta->expression;
		return $name =~ $expr                if does($expr, REGEXP);
		return $expr->($name, @{$hints||[]}) if does($expr, CODE);  # ssh... secret!
		return;
	}
};

BEGIN {
	package MooseX::RoleQR::Trait::Role;
	no thanks;
	use Moose::Role;
	use Scalar::Does -constants;
	use Carp;
	use namespace::sweep;
	
	BEGIN {
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.004';
	};

	has deferred_modifier_class => (
		is      => 'ro',
		isa     => 'ClassName',
		lazy    => 1,
		default => sub { 'MooseX::RoleQR::Meta::DeferredModifier' },
	);
	
	for my $type (qw( after around before )) #override
	{
		no strict 'refs';
		my $attr = "deferred_${type}_method_modifiers";
		has $attr => (
			traits  => ['Array'],
			is      => 'ro',
			isa     => 'ArrayRef[MooseX::RoleQR::Meta::DeferredModifier]',
			lazy    => 1,
			default => sub { +[] },
			handles => {
				"has_deferred_${type}_method_modifiers" => "count",
			},
		);
		
		my $pusher = "add_deferred_${type}_method_modifier";
		*$pusher = sub {
			my ($meta, $expression, $body) = @_;
			my $modifier = does($expression, 'MooseX::RoleQR::Meta::DeferredModifier')
				? $expression
				: $meta->deferred_modifier_class->new(expression => $expression, body => $body);
			push @{ $meta->$attr }, $modifier;
		};
		
		around "add_${type}_method_modifier" => sub {
			my ($orig, $meta, $expression, $body) = @_;
			if (does($expression, 'MooseX::RoleQR::Meta::DeferredModifier')
			or  does($expression, REGEXP))
				{ return $meta->$pusher($expression, $body) }
			else
				{ return $meta->$orig($expression, $body) }
		};
		
		next if $type eq 'override';
		*{"get_deferred_${type}_method_modifiers"} = sub {
			my ($meta, $name, $hints) = @_;
			grep { $_->matches_name($name, $hints) } @{ $meta->$attr };
		};
	}
	
#	sub get_deferred_override_method_modifier
#	{
#		my ($meta, $name) = @_;
#		my @r = grep { $_->matches_name($name) } @{ $meta->deferred_override_method_modifiers };
#		carp sprintf(
#			"%s has multiple override modifiers for method %s",
#			$meta->name,
#			$name,
#		) if @r > 1;
#		return $r[0];
#	}
};

BEGIN {
	package MooseX::RoleQR::Trait::Role::Composite;
	no thanks;
	use Moose::Role;
	use namespace::sweep;
	
	BEGIN {
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.004';
	};

	after apply => sub {
		my ($meta, $class) = @_;
		if ($class->isa('Moose::Meta::Class'))
		{
			foreach my $role (@{ $meta->get_roles })
			{
				foreach my $modifier_type (qw( before after around ))
				{
					MooseX::RoleQR::Trait::Application::ToClass->apply_deferred_method_modifiers(
						$modifier_type,
						$role,
						$class,
					);
				}
			}
		}
		else
		{
			push @{$ARGH{$class->name}}, map { $_->name } @{ $meta->get_roles };
### Commenting the stuff below out helped pass t/03classattribute.t.
### Not completely sure why. :-(
###
#			Moose::Util::MetaRole::apply_metaroles(
#				for            => $class->name,
#				role_metaroles => \%ROLE_METAROLES,
#			);
#			bless(
#				$class,
#				Moose::Util::with_traits(
#					ref($class),
#					'MooseX::RoleQR::Trait::Role',
#				),
#			);
		}
	};
};

BEGIN {
	package MooseX::RoleQR::Trait::Application::ToClass;
	no thanks;
	use Moose::Role;
	use namespace::sweep;

	BEGIN {
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.004';
	};

	before apply => sub {
		my ($self, $role, $class) = @_;
	};

#	after apply_override_method_modifiers => sub {
#		my ($self, $role, $class) = @_;
#		my $modifier_type = 'override';
#		
#		my $add = "add_${modifier_type}_method_modifier";
#		my $get = "get_deferred_${modifier_type}_method_modifiers";
#		
#		my @roles = ($role, map { $_->meta } @{$ARGH{$role->name} || []});
#		
#		METHOD: for my $method ( $class->get_all_method_names )
#		{
#			ROLE: for my $r (@roles)
#			{
#				next ROLE unless $r->can($get);
#				MODIFIER: for ($r->$get($method))
#				{
#					$class->$add($method, $_->body);
#				}
#			}
#		}
#	};
	
	after apply_method_modifiers => sub {
		my ($self, $modifier_type, $role, $class) = @_;
		$self->apply_deferred_method_modifiers(
			$modifier_type,
			$role,
			$class,
		);
	};
	
	sub apply_deferred_method_modifiers
	{
		my ($self, $modifier_type, $role, $class) = @_;
		my $add = "add_${modifier_type}_method_modifier";
		my $get = "get_deferred_${modifier_type}_method_modifiers";
		
		my @roles = ($role, map { $_->meta } @{$ARGH{$role->name} || []});
		
		METHOD: for my $method ( $class->get_all_method_names )
		{
			ROLE: for my $r (@roles)
			{
				next ROLE unless $r->can($get);
				MODIFIER: for ($r->$get($method, \@_))
				{
#					warn "@{[$role->name]} modifying @{[$class->name]} method $method";
					$class->$add($method, $_->body);
				}
			}
		}
	}
};

BEGIN {
	package MooseX::RoleQR::Trait::Application::ToRole;
	no thanks;
	use Moose::Role;
	use namespace::sweep;

	BEGIN {
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.004';
	};

	before apply => sub {
		my ($self, $role1, $role2) = @_;
		push @{$ARGH{$role2->name}}, $role1->name;
		Moose::Util::MetaRole::apply_metaroles(
			for            => $role2->name,
			role_metaroles => \%ROLE_METAROLES,
		);
		bless(
			$role2,
			Moose::Util::with_traits(
				ref($role2),
				'MooseX::RoleQR::Trait::Role',
			),
		);
	};
};

1;

__END__

=head1 NAME

MooseX::RoleQR - allow "before qr{...} => sub {...};" in roles

=head1 SYNOPSIS

   {
      package Local::Role;
      use MooseX::RoleQR;
      after qr{^gr} => sub {
         print " World\n";
      };
   }
   
   {
      package Local::Class;
      use Moose;
      with qw( Local::Role );
      sub greet {
         print "Hello";
      }
   }
   
   Local::Class->new->greet; # prints "Hello World\n"

=head1 DESCRIPTION

Method modifiers in Moose classes can be specified using regular expressions
a la:

   before qr{...} => sub {...};

However, this is not allowed in Moose roles because Moose doesn't know which
class the role will be composed with, and thus doesn't know which method
names match the regular expression. Let's change that.

This module implements regular expression matched method modifiers for Moose
roles. It does so by deferring the calculation of which methods to modify
until role application time.

The current implementation handles only C<before>, C<after> and C<around>
modifiers (not C<override>), and thus it overrides the following standard
Moose::Role keywords:

=over

=item C<< before Str|ArrayRef|RegexpRef => CodeRef >>

=item C<< after Str|ArrayRef|RegexpRef => CodeRef >>

=item C<< around Str|ArrayRef|RegexpRef => CodeRef >>

=back

=begin trustme

=item C<init_meta>

=end trustme

=head2 Caveat Regarding the Order of Method Modifiers

Moose executes method modifiers in a well-defined order (see
L<Moose::Manual::MethodModifiers> for details). This module has the potential
to disrupt that order, as regular expression matched modifiers are always
applied after the role's other modifiers have been applied.

=head2 Caveat: no C<< use Moose::Role >>

You should C<< use MooseX::RoleQR >> I<instead of> Moose::Role; not
I<as well as>.

=head2 General Caveat

There's some pretty nasty stuff under the hood. Let's pretend it's
not there.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-RoleQR>.

=head1 SEE ALSO

L<Moose::Role>.

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

