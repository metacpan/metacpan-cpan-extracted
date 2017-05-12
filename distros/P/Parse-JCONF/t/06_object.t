use strict;
use utf8;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/object.jconf');

is_deeply($res, {
	dict => {
		elephant  => "слон",
		furneture => "мебель",
		ququmber  => "огурец",
	},
	formatted_somehow => {
		size => 90E2,
		age  => 10E2,
		sex  => "male"
	},
	oneliner => {
		who     => "You&Me",
		action  => "use",
		what    => "Perl",
		version => [5.10,5.12,5.14,5.16,5.18],
		is      => TRUE,
	},
	empty    => {}
}, "parse objects");

done_testing;
