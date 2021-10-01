#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util qw( _dump );
use Mock::Data::Plugin::SQLTypes;
use Mock::Data;

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
	tinyint => [
		[],                                      sub { $_ >= -0x80 && $_ < 0x80 },
		[{ unsigned => 1 }],                     sub { $_ >= 0 && $_ < 0x10000 },
	],
	smallint => [
		[],                                      sub { $_ >= -0x8000 && $_ < 0x8000 },
		[{ unsigned => 1 }],                     sub { $_ >= 0 && $_ < 0x10000 },
	],
	bigint => [
		[],                                      qr/^-?[0-9]+$/,
		[{ unsigned => 1 }],                     qr/^[0-9]+$/,
	],

	sequence => [
		['X'],                                   sub { $_ == $x_seq++ },
		['Y'],                                   sub { $_ == $y_seq++ },
	],
	serial => [
		[{ sequence_name => 'Y'}],               sub { $_ == $y_seq++ },
	],
	smallserial => [
		[{ sequence_name => 'Y'}],               sub { $_ == $y_seq++ },
	],
	bigserial => [
		[{ sequence_name => 'Y'}],               sub { $_ == $y_seq++ },
	],

	numeric => [
		[],                                      qr/^-?[0-9]+$/,
		[5],                                     qr/^-?[0-9]{1,5}$/,
		[[4,2]],                                 qr/^-?[0-9]{0,2}\.[0-9]{2}$/,
	],
	decimal => [
		[[7,6]],                                 qr/^-?[0-9]\.[0-9]{6}$/,
	],

	float => [
		[],                                      \&check_float32,
	],
	double => [
		[],                                      \&check_float64,
	],
	double_precision => [
		[],                                      \&check_float64,
	],
	float4 => [
		[],                                      \&check_float32,
	],
	float8 => [
		[],                                      \&check_float64,
	],
	real => [
		[],                                      \&check_float32,
	],

	bit => [
		[],                                      qr/^[01]$/,
	],
	bool => [
		[],                                      qr/^[01]$/,
	],
	boolean => [
		[],                                      qr/^[01]$/,
	],

	varchar => [
		[],                                      qr/^[\w ]*$/,
		[4],                                     qr/^[\w ]{0,4}$/,
		[{ size => 3 }],                         qr/^[\w ]{0,3}$/,
	],
	text => [
		[],                                      qr/^[\w ]*$/,
	],
	char => [
		[],                                      qr/^\w$/,
		[10],                                    qr/^[\w ]{10}$/,
	],

	datetime => [
		[],                                      qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
		[{ before => '2020-01-02', after => '2020-01-01' }], qr/^2020-01-01 \d{2}:\d{2}:\d{2}$/,
	],
	date => [
		[],                                      qr/^\d{4}-\d{2}-\d{2}$/,
		[{ before => '2020-01-02', after => '2020-01-01' }], qr/^2020-01-01$/,
	],

	blob => [
		[],                                      sub { length $_ && !utf8::is_utf8($_) },
		[50],                                    sub { length $_ <= 50 && !utf8::is_utf8($_) },
	],
	uuid => [
		[],                                      qr/^[0-9a-f]{8} - [0-9a-f]{4} - 4 [0-9a-f]{3} - [89ab] [0-9a-f]{3} - [0-9a-f]{12}$/x,
	],
	json => [
		[],                                      '{}',
		(eval 'require JSON'? (
		[{data => [4]}],                         '[4]',
		):()),
	],
	jsonb => [
		[],                                      '{}',
	],
	inet => [
		[],                                      qr/^127\.\d+\.\d+\.\d+/,
	],
	cidr => [
		[],                                      qr,^127\.\d+\.\d+\.\d+/\d+,,
	],
	macaddr => [
		[],                                      qr/^(?: [0-9a-f]{2} : ){5} [0-9a-f]{2} $/x,
	],
);
my $mock= Mock::Data->new([qw( SQLTypes )]);
for (my $i= 0; $i < @tests; $i += 2) {
	my ($generator, $subtests)= @tests[$i, $i+1];
	subtest $generator => sub {
		for (my $j= 0; $j < @$subtests; $j += 2) {
			my ($args, $expected)= @{$subtests}[$j,$j+1];
			my $name= '(' . join(',', map _dump, @$args) . ')';
			for (1 .. $reps) {
				like( $mock->$generator(@$args), $expected, $name );
			}
		}
	};
}

done_testing;
