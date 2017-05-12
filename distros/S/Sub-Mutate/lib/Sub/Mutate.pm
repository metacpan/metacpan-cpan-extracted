=head1 NAME

Sub::Mutate - examination and modification of subroutines

=head1 SYNOPSIS

	use Sub::Metadata qw(
		sub_body_type
		sub_closure_role
		sub_is_lvalue
		sub_is_constant
		sub_is_method mutate_sub_is_method
		sub_is_debuggable mutate_sub_is_debuggable
		sub_prototype mutate_sub_prototype
	);

	$type = sub_body_type($sub);
	$type = sub_closure_role($sub);
	if(sub_is_lvalue($sub)) { ...
	if(sub_is_constant($sub)) { ...
	if(sub_is_method($sub)) { ...
	mutate_sub_is_method($sub, 1);
	if(sub_is_debuggable($sub)) { ...
	mutate_sub_is_debuggable($sub, 0);
	$proto = sub_prototype($sub);
	mutate_sub_prototype($sub, $proto);

	use Sub::WhenBodied qw(when_sub_bodied);

	when_sub_bodied($sub, sub { mutate_sub_foo($_[0], ...) });

=head1 DESCRIPTION

This module is a backward-compatibility wrapper repackaging functions that
are now supplied by other modules.  It is deprecated to use this module:
you should instead get the functions directly from L<Sub::Metadata>
or L<Sub::WhenBodied> as appropriate.

=cut

package Sub::Mutate;

{ use 5.006; }
use warnings;
use strict;

use Sub::Metadata 0.000 qw(
	sub_body_type
	sub_closure_role
	sub_is_lvalue
	sub_is_constant
	sub_is_method mutate_sub_is_method
	sub_is_debuggable mutate_sub_is_debuggable
	sub_prototype mutate_sub_prototype
);
use Sub::WhenBodied 0.000 qw(when_sub_bodied);

our $VERSION = "0.007";

use parent "Exporter";
our @EXPORT_OK = qw(
	sub_body_type
	sub_closure_role
	sub_is_lvalue
	sub_is_constant
	sub_is_method mutate_sub_is_method
	sub_is_debuggable mutate_sub_is_debuggable
	sub_prototype mutate_sub_prototype
	when_sub_bodied
);

=head1 FUNCTIONS

=over

=item sub_body_type(SUB)

=item sub_closure_role(SUB)

=item sub_is_lvalue(SUB)

=item sub_is_constant(SUB)

=item sub_is_method(SUB)

=item mutate_sub_is_method(SUB, NEW_METHODNESS)

=item sub_is_debuggable(SUB)

=item mutate_sub_is_debuggable(SUB, NEW_DEBUGGABILITY)

=item sub_prototype(SUB)

=item mutate_sub_prototype(SUB, NEW_PROTOTYPE)

These functions are supplied by L<Sub::Metadata>.  You should use that
module directly.  See that module for documentation.

=item when_sub_bodied(SUB, ACTION)

This function is supplied by L<Sub::WhenBodied>.  You should use that
module directly.  See that module for documentation.

=back

=head1 SEE ALSO

L<Sub::Metadata>,
L<Sub::WhenBodied>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2013, 2015
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
