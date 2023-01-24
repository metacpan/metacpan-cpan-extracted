=pod

=encoding utf-8

=head1 PURPOSE

Simple demonstration of the module.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use TOBYINK::Test::Template;

my $o = TOBYINK::Test::Template->new( foo => 'Hello' );
is( $o->foo_bar, 'Hello' );

$o->bar( 'world' );
is( $o->foo_bar, 'Hello world' );

done_testing;
