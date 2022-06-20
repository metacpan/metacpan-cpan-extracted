=pod

=encoding utf-8

=head1 PURPOSE

Test that enum handles=>1 works.

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
		attr:enum(foo,bar,baz):handles(1)
	};
}

my $obj = My::Class->new( attr => 'foo' );

can_ok( $obj, $_ ) for qw( is_foo is_bar is_baz );
ok( $obj->is_foo );
ok( not $obj->is_bar );
ok( not $obj->is_baz );

done_testing;

