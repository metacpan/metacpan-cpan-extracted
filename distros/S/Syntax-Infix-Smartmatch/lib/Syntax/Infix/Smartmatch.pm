package Syntax::Infix::Smartmatch;
$Syntax::Infix::Smartmatch::VERSION = '0.010';
use strict;
use warnings;

use XSLoader;
use overload ();

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use constant PERL_VERSION => $];

sub import {
	$^H |= 0x020000;
	$^H{"Syntax::Infix::Smartmatch/enabled"} = 1;

	if (PERL_VERSION < 5.041001 || PERL_VERSION >= 5.018) {
		my $warning = PERL_VERSION >= 5.038 ? 'deprecated::smartmatch' : 'experimental::smartmatch';
		warnings->unimport($warning);
	}
}

sub unimport {
	$^H |= 0x020000;
	delete $^H{"Syntax::Infix::Smartmatch/enabled"};
}

1;

# ABSTRACT: Smartmatch done right

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::Infix::Smartmatch - Smartmatch done right

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 say "YES" if $value ~~ [1, 2, qr/42/];

=head1 DESCRIPTION

B<NOTE: This module is currently still experimental and the details of its behavior may still change>.

This module implements a new, much simplified version of smartmatch. In particular the behavior only depends on the right side argument. In particular it will do the following based on the right side argument:

=over 4

=item * undef

This will return C<not defined $left>.

=item * object

If the object has smartmatch overloading (note: this might disappear in a future Perl version), that is called. Otherwise it returns object identity.

=item * regex

This is equivalent to C<$left =~ $right>.

=item * sub

It will return the value of C<< $right->($left) >>

=item * array

This will return true if C<$left> smartmatches any of the members of C<@$right>.

=item * other

This will return C<$left equ $right> (C<defined $left and $left eq $right>).

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
