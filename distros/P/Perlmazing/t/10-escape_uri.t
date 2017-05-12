use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing;

my @uris = (
	qw(
		http://www.cpan.org
		https://www.google.com/?q=perl%20modules
	),
	'some spaced text
		with newlines',
);
my $scalar = escape_uri @uris;
is $scalar, 'http%3A%2F%2Fwww.cpan.org', 'scalar';
is scalar(join "\n", escape_uri @uris), 'http%3A%2F%2Fwww.cpan.org
https%3A%2F%2Fwww.google.com%2F%3Fq%3Dperl%2520modules
some%20spaced%20text%0A%09%09with%20newlines', 'list';
is join("\n", @uris), 'http://www.cpan.org
https://www.google.com/?q=perl%20modules
some spaced text
		with newlines', 'untouched array';
escape_uri @uris;
is join("\n", @uris), 'http%3A%2F%2Fwww.cpan.org
https%3A%2F%2Fwww.google.com%2F%3Fq%3Dperl%2520modules
some%20spaced%20text%0A%09%09with%20newlines', 'changed array';
