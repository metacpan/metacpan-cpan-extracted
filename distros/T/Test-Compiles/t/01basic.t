=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Compiles compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Compiles;

subtest "compiles works" => sub {
	compiles 'print "hello world"';
	compiles '1 == 2';
	compiles 'die("bad")', 'die() compiles';
	compiles 'use feature qw(say); say "hello world"', 'features pragma'
		if $^V >= 5.010;
};

subtest "doesnt_compile works" => sub {
	doesnt_compile 'print "hello world';
	doesnt_compile '1 = 2';
	doesnt_compile 'BEGIN { die("bad") }', "BEGIN{die()} doesn't compile";
	doesnt_compile 'say "hello world"', 'features pragma'
		if $^V >= 5.010;
};

do {
	my $rand = 100_000 + int rand 900_000;
	doesnt_compile "use Does::Not::Exist::Blhahiushdfisdi$rand", 'loading non-existant module';
};

doesnt_compile '$x = fooble', message => "strict enabled by default";
compiles '$x = fooble', strict => 0, message => "strict can be disabled";
compiles 'my $x; if ($x = 1) { 42 }', message => "fatal warnings not enabled by default";
doesnt_compile 'my $x; if ($x = 1) { 42 }', warnings => 1, message => "fatal warnings can be enabled";

done_testing;
