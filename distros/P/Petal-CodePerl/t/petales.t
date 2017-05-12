use strict;
use warnings;

use Test::More 'no_plan';

use lib 't';

use Test::Deep;
use Test::NoWarnings;
use Data::Dumper qw(Dumper);

use Code::Perl::Expr qw( :easy );
use Petal::CodePerl::Expr qw( :easy );
use Petal::CodePerl::Compiler;

$Petal::Hash::MODIFIERS{"oldstyle:"} = 1;
$Petal::Hash::MODIFIERS{"newstyle:"} = "NewStyle";

if (%Petal::Hash::MODIFIERS)
{
}


our $env;

my $root = holder();

my @tests = (
	[
		'single_path',
		['path single', "hello", derefh($root, "hello")],
		[
			'path tal',
			"hello/tal",
			dereft(derefh($root, "hello"), "tal")
		],
		[
			'path hash',
			"hello{hash}",
			derefh(derefh($root, "hello"), "hash")
		],
		[
			'path array',
			"hello[10]",
			derefa(derefh($root, "hello"), 10)
		],
		[
			'path method',
			"hello/method()",
			callm(derefh($root, "hello"), "method")
		],
		[
			'path all',
			"hello/method()/tal{hash}[10]",
			derefa(
				derefh(
					dereft(
						callm(derefh($root, "hello"), "method"),
						"tal"
					),
					"hash",
				),
				10
			)
		],
		[
			'path qq arg method',
			"hello/method \"bye\"",
			callm(derefh($root, "hello"), "method", string("bye"))
		],
		[
			'path q arg method',
			"hello/method 'bye'",
			callm(derefh($root, "hello"), "method", string("bye"))
		],
		[
			'path mm arg method',
			"hello/method --bye",
			callm(derefh($root, "hello"), "method", string("bye"))
		],
		[
			'path expr arg method',
			"hello/method here/there",
			callm(
				derefh($root, "hello"),
				"method",
				alternate(dereft(derefh($root, "here"), "there")),
			)
		],
	],
	[
		'string',
		['simple', "hello", append(string("hello"))],
		['simple', 'hello$$hello', append(string('hello$hello'))],
		[
			'varsub',
			'hello$hello hello',
			append(string('hello'), derefh($root, "hello"), string(' hello'))
		],
		[
			'varsub {}',
			'hello${hello/there}hello',
			append(
				string('hello'),
				dereft(derefh($root, "hello"), "there"),
				string('hello')
			)
		],
	],
	[
		'qual_expr',
		['string', "string:hello", append(string("hello"))],
	],
	[
		'mod_expr',
		['modifier revert', "oldstyle:hello", callm($root, "get", "structure oldstyle:hello")],
		[
			'modifier compile',
			"newstyle:hello",
			callm(
				scal('Petal::Hash::MODIFIERS{"newstyle:"}'),
				"process_value",
				$root,
				alternate(derefh($root, "hello")),
			),
		],
	],
	[
		'only_expr',
		[
			'alternate',
			"hello/there|goodbye/now|string:default",
			alternate(
				dereft(derefh($root, "hello"), "there"),
				dereft(derefh($root, "goodbye"), "now"),
				append(string("default"))
			)	
		],
		[
			'string',
			'string: $number Hello, $user/name, $number + $number = ${math/add number number}',
			alternate(
				append(
					string(" "),
					derefh($root, "number"),
					string(" Hello, "),
					dereft(derefh($root, "user"), "name"),
					string(", "),
					derefh($root, "number"),
					string(" + "),
					derefh($root, "number"),
					string(" = "),
					callm(
						derefh($root, "math"), "add",
						alternate(derefh($root, "number")), alternate(derefh($root, "number"))
					)
				)
			)	
		],
	]
);

my @mod_tests = (
	[
		'mod_expr',
		[
			'modifier inline',
			"newstyle:hello",
			perlsprintf("%s->{%s}", $root, alternate(derefh($root, "hello"))),
		],
	]
);

$Petal::CodePerl::InlineMod = 0;
do_tests(@tests);
$Petal::CodePerl::InlineMod = 1;
do_tests(@mod_tests);

sub empty
{
	return 0;
}

sub testsub
{
	my $hash = shift;
	my $key = shift;
	return $hash->{$key};
}

sub testmethod
{
	my $pkg = shift;
	my $hash = shift;
	my $key = shift;
	return "$pkg, $hash->{$key}";
}

sub do_tests
{
	foreach my $set (@_)
	{
		my ($rule, @rule_tests) = @$set;

		foreach my $test (@rule_tests)
		{
			my ($name, $expr, $exp_comp) = @$test;

			my $comp = Petal::CodePerl::Compiler->compileRule($rule, $expr);

			if (not cmp_deeply($comp, $exp_comp, "$rule - $name"))
			{
				my $perl = eval{$comp->perl};
				if ($@)
				{
					diag "Couldn't make perl from comp, $@";
				}
				else
				{
					diag $perl;
				}
				diag Dumper($comp)
			}
		}
	}
}

package NewStyle;

sub process_value
{
	my $class = shift;
	my $hash = shift;
	my $value = shift;

	return length($value);
}

sub inline
{
	my $self = shift;

	my $hash_expr = shift;
	my $expr = shift;

	my $perlf = <<'EOM';
%s->{%s}
EOM

	chomp($perlf);

	return Petal::CodePerl::Expr::perlsprintf($perlf, $root, $expr);
}

