package Tenjin::Preprocessor;

use strict;
use warnings;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

our @ISA = ('Tenjin::Template');

=head1 NAME

Tenjin::Preprocessor - Preprocessing Tenjin templates

=head1 SYNOPSIS

	used internally.

=head1 DESCRIPTION

This module provides some methods needed for preprocessing templates.

=head1 INTERNAL METHODS

=head2 stmt_pattern()

=cut

sub stmt_pattern {
	return shift->SUPER::compile_stmt_pattern('PL');
}

=head2 expr_pattern()

=cut

sub expr_pattern {
	return qr/\[\*=(=?)(.*?)(=?)=\*\]/s;
}

=head2 add_expr()

=cut

sub add_expr {
	my ($self, $bufref, $expr, $flag_escape) = @_;

	$expr = "decode_params($expr)";
	$self->SUPER::add_expr($bufref, $expr, $flag_escape);
}

1;

=head1 SEE ALSO

L<Tenjin>, L<Tenjin::Template>.

=head1 AUTHOR, LICENSE AND COPYRIGHT

    See L<Tenjin>.

=cut
