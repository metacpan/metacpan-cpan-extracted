use Test::More;
use strict;
use warnings;
use Syntax::Keyword::Combine::Keys qw/ckeys/;

my @keys = ckeys { $_ }
	a => 1,
	b => 2,
	c => 3,
	a => 4,
	b => 5,
	c => 6;
use Data::Dumper;

is_deeply(\@keys, [qw/a b c/]);


my $first_hash = {
	a => 1,
	b => 2,
	c => 3
};

my %second_hash = (
	c => 3,
	d => 4,
	e => 5
);

@keys = ckeys {
	uc $_;
} %second_hash, %{$first_hash};

is_deeply(\@keys, [qw/A B C D E/]);

my %hash = ckeys {
	$_ => $HASH{$_}->{value}
} (
	a => {
		value => 100,
	},
	b => {
		value =>  200,
	},
	c => {
		value =>  300,
	},
	d => {
		value => 400,
	},
	e => {
		value => 500,
	}	
);

is_deeply(\%hash, {
	a => 100,
	b => 200,
	c => 300,
	d => 400,
	e => 500
});

done_testing;
