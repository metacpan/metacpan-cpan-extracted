=pod

=encoding utf-8

=head1 PURPOSE

Test that enum handles=>2 works.

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
use Test::Fatal;

{
	package My::Class;
	use Mom q{
		attr:enum(foo,bar,baz):handles(2)
	};
}

my $obj = My::Class->new( attr => 'foo' );

can_ok( $obj, $_ ) for qw( attr_is_foo attr_is_bar attr_is_baz );
ok( $obj->attr_is_foo );
ok( not $obj->attr_is_bar );
ok( not $obj->attr_is_baz );

done_testing;

