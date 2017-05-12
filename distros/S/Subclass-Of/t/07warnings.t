=pod

=encoding utf-8

=head1 PURPOSE

Test that warnings are issued for stuff.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warn;

sub Spec { 123 }

warnings_like {
	eval q/ use Subclass::Of "File::Spec" /;
} qr{^Subclass::Of is overwriting function 'Spec'};

warnings_like {
	eval q/ use Subclass::Of "strict"; use Subclass::Of "strict"; /;
} qr{^Subclass::Of is overwriting alias 'strict'; was '\S+'; now '\S+'};

my ($x, $y);
warnings_are {
	eval q/
		{
			use Subclass::Of "Carp", -methods => [ abc => sub{ 1 } ];
			$x = Carp;
		}
		{
			use Subclass::Of "Carp", -methods => [ xyz => sub{ 1 } ];
			$y = Carp;
		}
	/
} [];

ok($x->can("abc") and not $x->can("xyz"));
ok($y->can("xyz") and not $y->can("abc"));

done_testing;
