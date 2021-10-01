#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util qw( _dump );
use Mock::Data::Plugin::Number;
use Mock::Data;
sub _flatten;

my $reps= $ENV{GENERATE_COUNT} || 5;

sub check_float32 {
	unpack('f', pack 'f', $_) == $_
}
sub check_float64 {
	unpack('d', pack 'd', $_) == $_
}

my $x_seq= 1;
my $y_seq= 1;
my @tests= (
	integer => [
		[],                                      qr/^-?[0-9]+$/,
		[ 2 ],                                   qr/^-?[0-9]{1,2}$/,
		[{ size => 2 }],                         qr/^-?[0-9]{1,2}$/,
		[{ size => 2, unsigned => 1 }],          qr/^[0-9]$/,
		[{ bits => 3 }],                         sub { $_ >= -4 && $_ < 4 },
	],

	sequence => [
		['X'],                                   sub { $_ == $x_seq++ },
		['Y'],                                   sub { $_ == $y_seq++ },
	],

	decimal => [
		[],                                      qr/^-?[0-9]+$/,
		[5],                                     qr/^-?[0-9]{1,5}$/,
		[[4,2]],                                 qr/^-?[0-9]{0,2}\.[0-9]{2}$/,
		[[7,7]],                                 qr/^-?0\.[0-9]{7}$/,
	],

	float => [
		[],                                      \&check_float32,
		[10],                                    qr/^-?([0-9]\.?){1,10}$/,
		[{ bits => 23 }],                        \&check_float32,
		[{ bits => 52 }],                        \&check_float64,
		[{ digits => 2 }],                       qr/^-?([0-9]\.?){1,2}$/,
		[{ size   => 2 }],                       qr/^-?([0-9]\.?){1,2}$/,
	],
	
	byte => [
		[],                                      sub { length $_ == 1 && !utf8::is_utf8($_) },
		[100],                                   sub { length $_ <= 100 && !utf8::is_utf8($_) },
	],

	uuid => [
		[],                                      qr/^[0-9a-f]{8} - [0-9a-f]{4} - 4 [0-9a-f]{3} - [89ab] [0-9a-f]{3} - [0-9a-f]{12}$/x,
	],
);
my $mock= Mock::Data->new([qw( Number )]);
for (my $i= 0; $i < @tests; $i += 2) {
	my ($generator, $subtests)= @tests[$i, $i+1];
	subtest $generator => sub {
		for (my $j= 0; $j < @$subtests; $j += 2) {
			my ($args, $expected)= @{$subtests}[$j,$j+1];
			my $name= '('.join(',', map _dump, @$args).')';
			for (1 .. $reps) {
				like( $mock->$generator(@$args), $expected, $name );
			}
		}
	};
}

done_testing;
