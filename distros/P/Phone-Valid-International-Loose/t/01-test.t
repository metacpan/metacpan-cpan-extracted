use Test::More;
use strict;
use warnings;
use Phone::Valid::International::Loose qw/all/;

my @invalid = (
	"test",
	"(55)test",
	"(55)333-test",
	"(55)test 22",
	"(123)"
);

my @valid = (
	"+554433221100",
	"+5544332211",
	"+55443322",
	"+55443322",
	"+5544332211",
	"+41443322",
	"+3144332211",
	"+32443322",
	"+4412345678",
	"+301231231234"
);

for (@invalid) {
	my $value = valid_phone($_);
	ok(! $value );
}

for (@valid) {
	my $value = valid_phone($_);
	ok($value);
}

my $obj = Phone::Valid::International::Loose->new();

for (@invalid) {
	my $value = $obj->valid($_);
	ok(! $value );
}

for (@valid) {
	my $value = $obj->valid($_);
	ok($value);
}

done_testing;
