=pod

=encoding utf-8

=head1 PURPOSE

Test that SpecioX::XS works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use SpecioX::XS;

sub is_xs {
	my $sub = $_[0];
	if (not ref $sub) {
		no strict "refs";
		$sub = \&{$sub};
	}
	require B;
	!! B::svref_2object($sub)->XSUB;
}

use Specio::Library::Builtins;

ok is_xs( t('Defined')->_optimized_constraint );

like t('CodeRef')->inline_check( '$value' ), qr/^Type::Tiny::XS::CodeLike\(\$value\)$/;

like t('ArrayRef', of => t('CodeRef'))->inline_check( '$value' ), qr/^Type::Tiny::XS::AUTO::TC\d+\(\$value\)$/;

done_testing;

