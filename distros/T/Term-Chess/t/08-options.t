#!perl
use strict;
use warnings;
use Test::More;

use Term::Chess;

my $class = 'Term::Chess';
my @names = qw/level white seat size seed/;
my %type = map { $_ => 1 } qw/int enum flag bool str/;

sub quietly {
	my (@argv) = @_;
	my $said = '';
	open my $out, '>', \$said or die $!;
	local *STDOUT = $out;
	local *STDERR = $out;
	return scalar eval { $class->run(@argv) };
}

my $fields = $class->options;

subtest 'the fields' => sub {
	plan tests => 5 + 3 * @names;
	is ref $fields, 'ARRAY', 'options is a list';
	is_deeply [map { $_->{name} } @{$fields}], \@names, 'of these fields, in this order';
	my $again = $class->options;
	isnt $again, $fields, 'a second call returns another list';
	is_deeply $again, $fields, 'with the same fields in it';
	for my $field (@{$fields}) {
		ok $type{ $field->{type} || '' }, "$field->{name} has a known type";
		ok defined $field->{help} && length $field->{help}, "$field->{name} has help";
		ok $field->{type} eq 'int' ? $field->{min} <= $field->{max}
			: $field->{type} eq 'enum' ? @{ $field->{choices} || [] } >= 2
			: 1, "$field->{name} has what its type needs";
	}
	SKIP: {
		skip 'Game::Terminal::Kit is not installed', 1
			unless eval { require Game::Terminal::Kit::Options; 1 };
		is_deeply [Game::Terminal::Kit::Options::validate($fields)], [], 'and the kit finds nothing wrong';
	}
};

subtest 'every field is an option run takes' => sub {
	my @cases;
	for my $field (@{$fields}) {
		my ($name, $type) = @{$field}{qw/name type/};
		push @cases, map { ["--$name", $_] } $field->{min}, $field->{max} if $type eq 'int';
		push @cases, map { ["--$name", $_] } @{ $field->{choices} } if $type eq 'enum';
		push @cases, ["--$name"] if $type eq 'flag' || $type eq 'bool';
		push @cases, ["--no-$name"] if $type eq 'bool';
		push @cases, ["--$name", '1'] if $type eq 'str';
	}
	plan tests => 2 + @cases;
	is quietly('--help'), 0, '--help alone is 0';
	is quietly('--no-such-option-as-this', '--help'), 2, 'an option run does not take is 2, even beside --help';
	is quietly(@{$_}, '--help'), 0, "@{$_}" for @cases;
};

done_testing;
