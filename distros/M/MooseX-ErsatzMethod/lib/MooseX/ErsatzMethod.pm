use 5.008;
use strict;
use warnings;

package MooseX::ErsatzMethod;

BEGIN {
	$MooseX::ErsatzMethod::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ErsatzMethod::VERSION   = '0.004';
}

my %METAROLES;
BEGIN {
	%METAROLES = (
		role                    => [ 'MooseX::ErsatzMethod::Trait::Role' ],
		application_to_class    => [ 'MooseX::ErsatzMethod::Trait::ApplicationToClass' ],
		application_to_role     => [ 'MooseX::ErsatzMethod::Trait::ApplicationToRole' ],
		application_to_instance => [ 'MooseX::ErsatzMethod::Trait::ApplicationToInstance' ],
	)
};

use Module::Runtime ();
use Moose ();
use Moose::Exporter;

BEGIN {
	package MooseX::ErsatzMethod::Meta::Method;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose;
	has code => (
		is         => 'ro',
		isa        => 'CodeRef',
		required   => 1,
	);
	has name => (
		is         => 'ro',
		isa        => 'Str',
		required   => 1,
	);
	has associated_role => (
		is         => 'ro',
		isa        => 'Object',
		required   => 0,
	);
	sub apply_to_class
	{
		my ($self, $class) = @_;
		return if $class->find_method_by_name($self->name);
		$class->add_method($self->name, $self->code);
	}
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
}

BEGIN {
	package MooseX::ErsatzMethod::Trait::Role;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose::Role;
	has ersatz_methods => (
		traits     => ['Hash'],
		is         => 'ro',
		isa        => 'HashRef[MooseX::ErsatzMethod::Meta::Method]',
		lazy_build => 1,
		handles    => {
			all_ersatz_methods => 'values',
			_add_ersatz_method => 'set',
		},
	);
	sub _build_ersatz_methods { +{} };
	sub add_ersatz_method
	{
		my ($meta, $method) = @_;
		$meta->_add_ersatz_method($method->name => $method);
	}
	sub apply_all_ersatz_methods_to_class
	{
		my ($self, $class) = @_;
		for ($self->all_ersatz_methods)
		{
			next if $self->has_method($_->name);
			$_->apply_to_class($class);
		}
	}
	sub composition_class_roles
	{
		return 'MooseX::ErsatzMethod::Trait::Composite';
	}
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
};

BEGIN {
	package MooseX::ErsatzMethod::Trait::Composite;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose::Role;
	with qw(MooseX::ErsatzMethod::Trait::Role);
	around apply_params => sub
	{
		my $orig = shift;
		my $self = shift;
		$self->$orig(@_);
		
		$self = Moose::Util::MetaRole::apply_metaroles(
			for            => $self,
			role_metaroles => \%METAROLES,
		);
		$self->_merge_ersatz_methods;
		return $self;
	};
	sub _merge_ersatz_methods
	{
		my $self = shift;
		foreach my $role (@{ $self->get_roles })
		{
			next unless Moose::Util::does_role(
				$role,
				'MooseX::ErsatzMethod::Trait::Role',
			);
			$self->add_ersatz_method($_) for $role->all_ersatz_methods;
		}
	}
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
};

BEGIN {
	package MooseX::ErsatzMethod::Trait::ApplicationToClass;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose::Role;
	before apply => sub
	{
		my ($meta, $role, $class) = @_;
		return unless Moose::Util::does_role(
			$role,
			'MooseX::ErsatzMethod::Trait::Role',
		);
		$role->apply_all_ersatz_methods_to_class($class);
	};
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
};

BEGIN {
	package MooseX::ErsatzMethod::Trait::ApplicationToRole;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose::Role;
	before apply => sub
	{
		my ($meta, $role1, $role2) = @_;
		$role2 = Moose::Util::MetaRole::apply_metaroles(
			for            => $role2,
			role_metaroles => \%METAROLES,
		);
		$role2->add_ersatz_method($_) for $role1->all_ersatz_methods;
	};
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
};

BEGIN {
	package MooseX::ErsatzMethod::Trait::ApplicationToInstance;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	use Moose::Role;
	$INC{ Module::Runtime::module_notional_filename(__PACKAGE__) } ||= __FILE__;
};

Moose::Exporter->setup_import_methods(
	with_meta      => [ 'ersatz' ],
	role_metaroles => \%METAROLES,
);

sub ersatz
{
	my ($meta, $name, $coderef) = @_;
	
	Carp::confess('Ersatz methods can only be created for Moose roles; not classes. Stopped')
		unless $meta->isa('Moose::Meta::Role');
	
	my $method;
	if (Scalar::Util::blessed($name))
	{
		$method = $name;
	}
	else
	{
		$method = 'MooseX::ErsatzMethod::Meta::Method'->new(
			code            => $coderef,
			name            => $name,
			associated_role => $meta,
		);
	}
	
	$meta->add_ersatz_method($method);
}

1;

__END__

=head1 NAME

MooseX::ErsatzMethod - provide a method implementation that isn't as good as the real thing

=head1 SYNOPSIS

  package Greetable;
  use Moose::Role;
  use MooseX::ErsatzMethod;
  
  sub greet {
    my $self = shift;
    say "Hello ", $self->name;
  }
  
  ersatz name => sub {
    my $self = shift;
    return Scalar::Util::refaddr($self);
  };

  package Person;
  use Moose;
  with 'Greetable';
  has name => (is => 'ro', isa => 'Str');
  
  package Termite;
  use Moose;
  with 'Greetable';
  # no need to implement 'name'.

=head1 DESCRIPTION

MooseX::ErsatzMethod provides a mechanism for Moose roles to provide fallback
implementations of methods that they really want for consuming classes to
implement. In the SYNOPSIS section, the C<Greetable> role really wants
consuming classes to implement a C<name> method. The C<Termite> class doesn't
implement C<name>, but it's OK, because C<Greetable> provides a fallback
(albeit rubbish) implementation of the method.

B<< But wait! >> I hear you say. Don't roles already work that way? Can't a
role provide an implementation of a method which consuming classes can
override? Yes, they can. However, the precedence is:

  consuming class's implementation (wins)
  role's implementation
  inherited implementation (e.g. from parent class)

That is, the role's method implementation overrides methods inherited from the
parent class. An ersatz method implementation sits right at the bottom of the
heirarchy; it is only used if the consuming class and its ancestors cannot
provide the method. (It still beats C<AUTOLOAD> though.)

One other feature of ersatz methods is that they can never introduce role
composition conflicts. If you compose two different roles which both provide
ersatz method implementations, an arbitrary method implementation is selected.

=head2 Functions

=over

=item C<< ersatz $name => $coderef >>

Defines an ersatz function.

=back

=head2 Metarole Trait

Your metarole (i.e. C<< $metarole = Greetable->meta >>) will have the
following additional methods:

=over

=item C<< ersatz_methods >>

Returns a name => object hashref of ersatz methods for this class. The
objects are instances of L<< MooseX::ErsatzMethod::Meta::Method >>.

=item C<< all_ersatz_methods >>

Returns just the values (objects) from the C<ersatz_methods> hash.

=item C<< add_ersatz_method($name, $coderef) >>

Given a name and coderef, creates a L<< MooseX::ErsatzMethod::Meta::Method >>
object and adds it to the C<ersatz_methods> hash.

=item C<< apply_all_ersatz_methods_to_class($class) >>

Given a Moose::Meta::Class object, iterates through C<all_ersatz_methods>
applying each to the class. This procedure skips any ersatz method for which
this role can provide a real method.

=back

=head2 MooseX::ErsatzMethod::Meta::Method

Instances of this class represent an ersatz method.

=over

=item C<< new(%attrs) >>

Standard Moose constructor.

=item C<< code >>

The coderef for the method.

=item C<< name >>

The sub name for the method (not including the package).

=item C<< associated_role >>

The metarole associated with this method (if any).

=item C<< apply_to_class($class) >>

Given a Moose::Meta::Class object, installs this method into the class
unless the class (or a superclass) already has a method of that name.

=back

=head1 CAVEATS

If you use one-at-a-time role composition, then ersatz methods in one
role might end up "beating" a proper method provided by another role.

  with 'Role1';  with 'Role2';   # No!
  with qw( Role1 Role2 );        # Yes

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ErsatzMethod>.

=head1 SEE ALSO

L<Moose::Role>.

L<https://speakerdeck.com/u/sartak/p/moose-role-usage-patterns?slide=32>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

