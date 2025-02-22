package Mooish::Base;
$Mooish::Base::VERSION = '0.001';
use v5.14;
use warnings;
use Import::Into;

require Mooish::AttributeBuilder;
require Type::Tiny;
require namespace::autoclean;

use constant FLAVOUR => $ENV{MOOISH_BASE_FLAVOUR} // 'Moo';
use constant ROLE_FLAVOUR => $ENV{MOOISH_BASE_ROLE_FLAVOUR} // (FLAVOUR . '::Role');

BEGIN {
	eval 'require ' . FLAVOUR or die $@;
	eval 'require ' . ROLE_FLAVOUR or die $@;
}

sub import
{
	my $me = shift;
	my $pkg = caller;

	my $class_type = FLAVOUR;
	if (($_[0] // '') eq -role) {
		$class_type = ROLE_FLAVOUR;
	}

	$class_type->import::into($pkg);
	Mooish::AttributeBuilder->import::into($pkg);
	Types::Common->import::into($pkg, -types);
	namespace::autoclean->import(-cleanee => $pkg);
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

If a C<-role> flag is specified, then the module imports C<Moo::Role> instead.

Environmental variables C<MOOISH_BASE_FLAVOUR> and C<MOOISH_BASE_ROLE_FLAVOUR>
can be used to modify class and role systems used. If not present, C<Moo> and
C<Moo::Role> will be used respectively. Make sure to introduce these variables
before first loading the module.

The purpose of this module is to make it easier to create classes based on
Moose family of modules. The choice of imported modules is meant to provide a
solid base for module development, but still be perfectly compatible at least
with L<Moose>, L<Mouse> and L<Moo>.

Since this module imports L<Mooish::AttributeBuilder> without the C<-standard>
flag, please do not use it as a dependency of other modules. You may use its
code to create your own, similar importer.

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

