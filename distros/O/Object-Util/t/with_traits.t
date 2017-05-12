=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_with_traits >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use Object::Util;

ok(
	"Module::Runtime"->$_with_traits("MooX::Traits")->can("with_traits"),
	"yay",
);

done_testing;
