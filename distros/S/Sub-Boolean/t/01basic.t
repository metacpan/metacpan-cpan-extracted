
=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Boolean works.

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

use Sub::Boolean -all;
use Scalar::Util qw( refaddr );

make_true( __PACKAGE__ . '::foo' );
make_false( __PACKAGE__ . '::bar' );

my $r = make_false( __PACKAGE__ . '::baz' );
is($r, undef);

ok foo();
ok foo( 123 );
ok !bar();
ok !bar( 123 );

isnt refaddr( \&baz ), refaddr( \&bar );

make_undef( __PACKAGE__ . '::quux' );
make_empty( __PACKAGE__ . '::quuux' );

is_deeply [ quux() ],  [undef];
is_deeply [ quuux() ], [];

ok make_true()->();
ok !make_false()->();
is_deeply [ make_undef()->() ], [undef];
is_deeply [ make_empty()->() ], [];

isnt refaddr( make_empty() ), refaddr( make_empty() );

done_testing;
