package Mooish::Base;
$Mooish::Base::VERSION = '1.000';
use v5.10;
use strict;
use warnings;
use Import::Into;

require Mooish::AttributeBuilder;
require Type::Tiny;
require namespace::autoclean;

use constant FLAVOUR => $ENV{MOOISH_BASE_FLAVOUR} // 'Moo';
use constant ROLE_FLAVOUR => $ENV{MOOISH_BASE_ROLE_FLAVOUR} // (FLAVOUR . '::Role');

use constant HAS_HOOK_AFTERRUNTIME => eval { require Hook::AfterRuntime; 1 };
use constant HAS_MOOX_TYPETINY => eval { require MooX::TypeTiny; 1 };
use constant HAS_MOOX_XSCONSTRUCTOR => eval { require MooX::XSConstructor; 1 };
use constant HAS_MOOSEX_XSACCESSOR => eval { require MooseX::XSAccessor; 1 };

BEGIN {
	eval 'require ' . FLAVOUR or die $@;
	eval 'require ' . ROLE_FLAVOUR or die $@;
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

	my $engine = $role ? $role_type : $class_type;
	$engine->import::into($pkg);
	Mooish::AttributeBuilder->import::into($pkg, ($standard ? (-standard) : ()));
	Types::Common->import::into($pkg, -types);
	namespace::autoclean->import(-cleanee => $pkg);

	if ($class_type eq 'Moo' && !$role) {
		if (HAS_MOOX_TYPETINY) {
			MooX::TypeTiny->import::into($pkg);
		}

		if (HAS_MOOX_XSCONSTRUCTOR) {
			MooX::XSConstructor->import::into($pkg);
		}
	}

	if ($class_type eq 'Moose' && !$role) {
		if (HAS_MOOSEX_XSACCESSOR) {
			MooseX::XSAccessor->import::into($pkg);
		}

		if (HAS_HOOK_AFTERRUNTIME) {
			Hook::AfterRuntime::after_runtime { $pkg->meta->make_immutable };
		}
		else {
			warn "Mooish::Base can't make $pkg Moose class immutable - please install Hook::AfterRuntime module";
		}
	}
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

=head3 Moo

=over

=item * L<MooX::TypeTiny>

This module speeds up Type::Tiny checks in Moo code.

=item * L<MooX::XSConstructor>

This module attempts to use L<Class::XSConstructor> to speed up the constructor.

=back

=head3 Moose

=over

=item * L<MooseX::XSAccessor>

This module attempts to use L<Class::XSAccessor> to speed up the accessors.

=item * L<Hook::AfterRuntime>

Since the module attempts to deliver a unified API for each flavour of Moose,
Moose itself must be made immutable automatically after the class is built.
This is done with the help of this module. Mooish::Base will warn if this
module is not installed and Moose flavour is used.

=back

=head2 For module authors

If you wish to use Mooish::Base in your module, please use it with C<-standard>
flag. This flag will prevent custom behavior from propagating into the module.
Currently, it will only cause L<Mooish::AttributeBuilder> to be imported with
C<-standard> flag. If some other custom behavior prove undesirable in the
future, it may be included as well.

Please be aware that having a variable OO engine may not be good for all
modules. Obvious example of where it is bad is the case where your code mixes
in roles which were not written using Mooish::Base. If this ever becomes a
pressing problem, a way to force flavour (regardless of environmental flags)
may be added in the future, and it may be included as a part of C<-standard>
flag behavior. If you expect your code to be sensitive to changes in the
flavour environmental flag, avoid depending on this module in your module.

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

