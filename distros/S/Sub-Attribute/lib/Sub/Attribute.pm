package Sub::Attribute;

use 5.008_001;
use strict;

our $VERSION = '0.05';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use parent qw(Exporter);
our @EXPORT = qw(ATTR_SUB MODIFY_CODE_ATTRIBUTES);

use attributes ();

1;
__END__

=head1 NAME

Sub::Attribute - Reliable subroutine attribute handlers

=head1 VERSION

This document describes Sub::Attribute version 0.05.

=for test_synopsis BEGIN{ $INC{'Attribute/Foo.pm'} = __FILE__ }

=head1 SYNOPSIS

	package Attribute::Foo;
	use Sub::Attribute;

	sub Foo :ATTR_SUB{
		my($class, $sym_ref, $code_ref, $attr_name, $attr_data) = @_;

		# ...
	}

	# and later
	package main;
	use parent qw(Attribute::Foo);

	sub something :Foo(xyzzy){
		# ...
	}
	# apply: __PACKAGE__->Foo(\*something, \&something, 'Foo', 'xyzzy')

=head1 DESCRIPTION

C<Sub::Attribute> is a role to define attribute handlers for specific
subroutine attributes.

The feature of this module is similar to that of C<Attribute::Handlers>, but
has less functionality and more reliability.
That is, while C<Attribute::Handlers> provides many options for C<ATTR(CODE)>,
C<Sub::Attribute> provides no options for C<ATTR_SUB>.
However, the attribute handlers defined by C<Sub::Attribute> are always called
with informative arguments. C<Attribute::Handlers>'s C<ATTR(CODE)> is not called
in run-time C<eval()>, so C<ATTR(CODE)> is not reliable.

=head1 INTERFACE

=head2 The B<ATTR_SUB> meta attribute

Defines a method as an subroutine attribute handler.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 $ENV{SUB_ATTRIBUTE_DEBUG}

If true, reports how attributes are applied, using C<warn()> function.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<attributes>.

L<perlsub/"Subroutine Attributes">.

L<Attribute::Handlers>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-20010, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
