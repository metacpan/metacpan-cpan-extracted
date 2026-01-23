package Mooish::Base;
$Mooish::Base::VERSION = '1.003';
use v5.10;
use strict;
use warnings;
use Import::Into;

require Mooish::AttributeBuilder;
require Type::Tiny;
require namespace::autoclean;

use constant FLAVOUR => $ENV{MOOISH_BASE_FLAVOUR} // 'Moo';
use constant ROLE_FLAVOUR => $ENV{MOOISH_BASE_ROLE_FLAVOUR} // (FLAVOUR . '::Role');

use constant EXTRA_MODULES => $ENV{MOOISH_BASE_EXTRA_MODULES} // join ';', qw(
	Hook::AfterRuntime
	MooX::TypeTiny
	MooX::XSConstructor
	MooseX::XSConstructor
	MooseX::XSAccessor
);

use constant EXTRA_MODULES_AVAILABLE => {
	'Hook::AfterRuntime' => !!eval { require Hook::AfterRuntime; Hook::AfterRuntime->VERSION('0.003'); 1 },
	'MooX::TypeTiny' => !!eval { require MooX::TypeTiny; MooX::TypeTiny->VERSION('0.002002'); 1 },
	'MooX::XSConstructor' => !!eval { require MooX::XSConstructor; MooX::XSConstructor->VERSION('0.003002'); 1 },
	'MooseX::XSConstructor' => !!
		eval { require MooseX::XSConstructor; MooseX::XSConstructor->VERSION('0.001002'); 1 },
	'MooseX::XSAccessor' => !!eval { require MooseX::XSAccessor; MooseX::XSAccessor->VERSION('0.010'); 1 },
};

use constant EXTRA_MODULES_RULES => {
	'Hook::AfterRuntime' => {type => 'Moose'},
	'MooX::TypeTiny' => {type => 'Moo'},
	'MooX::XSConstructor' => {type => 'Moo'},
	'MooseX::XSConstructor' => {type => 'Moose'},
	'MooseX::XSAccessor' => {type => 'Moose', role => !!1},
};

BEGIN {
	eval 'require ' . FLAVOUR or die $@;
	eval 'require ' . ROLE_FLAVOUR or die $@;
}

our $DEBUG;

sub _uses_extra_module
{
	my ($module, $class_type, $role) = @_;

	state $wanted_modules = {
		map { $_ => 1 }
			map { s{^\s+}{}; s{\s+$}{}; $_ }
			split ';', EXTRA_MODULES
	};

	return $wanted_modules->{$module}
		&& EXTRA_MODULES_AVAILABLE->{$module}
		&& EXTRA_MODULES_RULES->{$module}{type} eq $class_type
		&& (!$role || EXTRA_MODULES_RULES->{$module}{role})
		;
}

sub import
{
	my $me = shift;
	my $pkg = caller;

	my $class_type = FLAVOUR;
	my $role_type = ROLE_FLAVOUR;
	my $role = !!0;
	my $standard = !!0;

	foreach my $arg (@_) {
		if ($arg eq -role) {
			$role = !!1;
		}
		elsif ($arg eq -standard) {
			$standard = !!1;
		}
	}

	# Moo is the best choice for module development
	if ($standard) {
		$class_type = 'Moo';
		$role_type = 'Moo::Role';
	}

	my $engine = $role ? $role_type : $class_type;
	$engine->import::into($pkg);
	Mooish::AttributeBuilder->import::into($pkg, ($standard ? (-standard) : ()));
	Types::Common->import::into($pkg, -types);
	namespace::autoclean->import(-cleanee => $pkg);

	# install extra modules

	my %extra_modules = map { $_ => _uses_extra_module($_, $class_type, $role) }
		keys %{(EXTRA_MODULES_RULES)};

	MooX::TypeTiny->import::into($pkg)
		if $extra_modules{'MooX::TypeTiny'};

	MooX::XSConstructor->import::into($pkg)
		if $extra_modules{'MooX::XSConstructor'};

	MooseX::XSConstructor->import::into($pkg)
		if $extra_modules{'MooseX::XSConstructor'};

	MooseX::XSAccessor->import::into($pkg)
		if $extra_modules{'MooseX::XSAccessor'};

	# special handling for Hook::AfterRuntime - warn if it can't be used on Moose
	if ($extra_modules{'Hook::AfterRuntime'}) {
		Hook::AfterRuntime::after_runtime { $pkg->meta->make_immutable };
	}
	elsif ($class_type eq 'Moose' && !$role) {
		warn "Mooish::Base can't make $pkg Moose class immutable - please install Hook::AfterRuntime module";
	}

	# put debug information if requested
	$DEBUG->{$pkg} = {
		class_type => $class_type,
		role_type => $role_type,
		role => $role,
		standard => $standard,
		extra_modules => \%extra_modules,
	} if $DEBUG;
}

1;

__END__

=head1 NAME

Mooish::Base - importer for Mooish classes

=head1 SYNOPSIS

	# for classes
	use Mooish::Base;

	# for roles
	use Mooish::Base -role;

	# create your class / role as usual

=head1 DESCRIPTION

This module is a shortcut that does roughly the same as calling these imports:

	use Moo;
	use Mooish::AttributeBuilder;
	use Types::Common -types;
	use namespace::autoclean;

	# additional optional modules, if they are installed

If a C<-role> flag is specified, then the module imports C<Moo::Role> instead.

Environmental variables C<MOOISH_BASE_FLAVOUR> and C<MOOISH_BASE_ROLE_FLAVOUR>
can be used to modify class and role systems used. If not present, C<Moo> and
C<Moo::Role> will be used respectively. Make sure to introduce these variables
before first loading the module.

The purpose of this module is to make it easier to create classes based on
Moose family of modules. The choice of imported modules is meant to provide a
solid base for module development, but still be perfectly compatible at least
with L<Moose>, L<Mouse> and L<Moo>.

=head2 Extra modules or features loaded

Depending on C<MOOISH_BASE_FLAVOUR> some extra modules will be imported (if
installed). Only modules which B<do not change the behavior> will ever be
added to this list - mostly modules which improve performance for free.

C<MOOISH_BASE_EXTRA_MODULES> environmental variable can be declared to control
which extra modules should be used. It must contain a semicolon-separated a
list of modules to be loaded, for example
C<MooX::TypeTiny;MooX::XSConstructor>. It must be set prior to first loading
the module to take effect. Normally, it should not be needed, but may be a
helpful workaround if one of these modules contain a bug which causes the
resulting class to misbehave.

=head3 Moo

=over

=item * L<MooX::TypeTiny>

This module speeds up Type::Tiny checks in Moo code.

I<minimum required version: 0.002002>

=item * L<MooX::XSConstructor>

This module attempts to use L<Class::XSConstructor> to speed up the constructor.

I<minimum required version: 0.003002>

=back

=head3 Moose

=over

=item * L<MooseX::XSConstructor>

This module attempts to use L<Class::XSConstructor> to speed up the constructor.

I<minimum required version: 0.001002>

=item * L<MooseX::XSAccessor>

This module attempts to use L<Class::XSAccessor> to speed up the accessors.

I<minimum required version: 0.010>

=item * L<Hook::AfterRuntime>

Since the module attempts to deliver a unified API for each flavour of Moose,
Moose itself must be made immutable automatically after the class is built.
This is done with the help of this module. Mooish::Base will warn if this
module is not installed and Moose flavour is used.

I<minimum required version: 0.003>

=back

=head2 Debugging

Mooish::Base can be debugged by setting C<$Mooish::Base::DEBUG> prior to
loading a class. This package variable should be set to a hash reference. If it
is, it will fill it up with keys for each loaded class or role. An example
debug code will look like that:

	BEGIN {
		require Mooish::Base;
		$Mooish::Base::DEBUG = {};
	}

	package MyClass;
	use Mooish::Base;

	use Data::Dumper;
	print Dumper($Mooish::Base::DEBUG);

Example output:

	$VAR1 = {
		'MyClass' => {
			'class_type' => 'Moo',
			'role_type' => 'Moo::Role',
			'role' => !!0,
			'standard' => !!0
			'extra_modules' => {
				'MooX::TypeTiny' => !!1,
				'MooX::XSConstructor' => !!0,
				'Hook::AfterRuntime' => !!0,
				'MooseX::XSConstructor' => !!0,
				'MooseX::XSAccessor' => !!0
			},
		}
	};

If more classes are loaded then more keys will appear in the debug hash,
allowing to easily check what was loaded and where.

=head2 For module authors

If you wish to use Mooish::Base in your module, please use it with C<-standard>
flag. This flag will prevent custom behavior from propagating into the module.
The idea is to have a solid base OO for module development while making sure
that it won't break when users add custom settings.

Currently, it will ensure that:

=over

=item

L<Mooish::AttributeBuilder> will be imported with C<-standard> flag (no
user-defined shortcuts). I<(in effect since version 1.000)>

=item

L<Moo> and L<Moo::Role> will be used regardless of the environment variables.
I<(in effect since version 1.001)>

=back

=head1 SEE ALSO

L<Moo>

L<Mooish::AttributeBuilder>

L<Types::Common>

L<Import::Into>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

