=head1 PURPOSE

Test Data::Printer support for structs.

Skipped if Data::Printer is not installed.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use if !eval{ require Data::Printer; $Data::Printer::VERSION >= 0.36 },
	'Test::More', skip_all => 'need Data::Printer';

use Test::More;

use Data::Printer colored => 0, return_value => 'dump';
use MooX::Struct Something => [qw( $foo bar )];

my $obj = Something->new(foo => 1, bar => 2);
my $str = p $obj;

is($str, 'Something[ 1, 2 ]');

my $ob2 = Something->new(foo => "Hello\nWorld", bar => ["A","B\nC","D"]);
my $st2 = p $ob2;
like("$st2\n", qr{^Something\[\n}s, 'dump including line breaks');

my $ext = Something->EXTEND('$baz')->new([1, 2, 3]);
my $pxt = p $ext;

is($pxt, 'Something[ 1, 2, 3 ]');

my $bas = MooX::Struct->new;
my $pas = p $bas;

is($pas, 'struct[  ]');

done_testing;
