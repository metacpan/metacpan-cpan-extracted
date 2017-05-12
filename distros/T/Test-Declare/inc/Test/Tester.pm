#line 1
use strict;

package Test::Tester;

BEGIN
{
	if (*Test::Builder::new{CODE})
	{
		warn "You should load Test::Tester before Test::Builder (or anything that loads Test::Builder)" 
	}
}

use Test::Builder;
use Test::Tester::CaptureRunner;
use Test::Tester::Delegate;

require Exporter;

use vars qw( @ISA @EXPORT $VERSION );

$VERSION = "0.107";
@EXPORT = qw( run_tests check_tests check_test cmp_results show_space );
@ISA = qw( Exporter );

my $Test = Test::Builder->new;
my $Capture = Test::Tester::Capture->new;
my $Delegator = Test::Tester::Delegate->new;
$Delegator->{Object} = $Test;

my $runner = Test::Tester::CaptureRunner->new;

my $want_space = $ENV{TESTTESTERSPACE};

sub show_space
{
	$want_space = 1;
}

my $colour = '';
my $reset = '';

if (my $want_colour = $ENV{TESTTESTERCOLOUR} || $ENV{TESTTESTERCOLOUR})
{
	if (eval "require Term::ANSIColor")
	{
		my ($f, $b) = split(",", $want_colour);
		$colour = Term::ANSIColor::color($f).Term::ANSIColor::color("on_$b");
		$reset = Term::ANSIColor::color("reset");
	}

}

sub new_new
{
	return $Delegator;
}

sub capture
{
	return Test::Tester::Capture->new;
}

sub fh
{
	# experiment with capturing output, I don't like it
	$runner = Test::Tester::FHRunner->new;

	return $Test;
}

sub find_run_tests
{
	my $d = 1;
	my $found = 0;
	while ((not $found) and (my ($sub) = (caller($d))[3]) )
	{
#		print "$d: $sub\n";
		$found = ($sub eq "Test::Tester::run_tests");
		$d++;
	}

#	die "Didn't find 'run_tests' in caller stack" unless $found;
	return $d;
}

sub run_tests
{
	local($Delegator->{Object}) = $Capture;

	$runner->run_tests(@_);

	return ($runner->get_premature, $runner->get_results);
}

sub check_test
{
	my $test = shift;
	my $expect = shift;
	my $name = shift;
	$name = "" unless defined($name);

	@_ = ($test, [$expect], $name);
	goto &check_tests;
}

sub check_tests
{
	my $test = shift;
	my $expects = shift;
	my $name = shift;
	$name = "" unless defined($name);

	my ($prem, @results) = eval { run_tests($test, $name) };

	$Test->ok(! $@, "Test '$name' completed") || $Test->diag($@);
	$Test->ok(! length($prem), "Test '$name' no premature diagnostication") ||
		$Test->diag("Before any testing anything, your tests said\n$prem");

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	cmp_results(\@results, $expects, $name);
	return ($prem, @results);
}

sub cmp_field
{
	my ($result, $expect, $field, $desc) = @_;

	if (defined $expect->{$field})
	{
		$Test->is_eq($result->{$field}, $expect->{$field},
			"$desc compare $field");
	}
}

sub cmp_result
{
	my ($result, $expect, $name) = @_;

	my $sub_name = $result->{name};
	$sub_name = "" unless defined($name);

	my $desc = "subtest '$sub_name' of '$name'";

	{
		local $Test::Builder::Level = $Test::Builder::Level + 1;

		cmp_field($result, $expect, "ok", $desc);

		cmp_field($result, $expect, "actual_ok", $desc);

		cmp_field($result, $expect, "type", $desc);

		cmp_field($result, $expect, "reason", $desc);

		cmp_field($result, $expect, "name", $desc);
	}

	# if we got no depth then default to 1
	my $depth = 1;
	if (exists $expect->{depth})
	{
		$depth = $expect->{depth};
	}

	# if depth was explicitly undef then don't test it
	if (defined $depth)
	{
		$Test->is_eq($result->{depth}, $depth, "checking depth") ||
			$Test->diag('You need to change $Test::Builder::Level');
	}

	if (defined(my $exp = $expect->{diag}))
	{
		# if there actually is some diag then put a \n on the end if it's not
		# there already

		$exp .= "\n" if (length($exp) and $exp !~ /\n$/);
		if (not $Test->ok($result->{diag} eq $exp,
			"subtest '$sub_name' of '$name' compare diag")
		)
		{
			my $got = $result->{diag};
			my $glen = length($got);
			my $elen = length($exp);
			for ($got, $exp)
			{
				my @lines = split("\n", $_);
	 			$_ = join("\n", map {
					if ($want_space)
					{
						$_ = $colour.escape($_).$reset;
					}
					else
					{
						"'$colour$_$reset'"
					}
				} @lines);
			}

			$Test->diag(<<EOM);
Got diag ($glen bytes):
$got
Expected diag ($elen bytes):
$exp
EOM

		}
	}
}

sub escape
{
	my $str = shift;
	my $res = '';
	for my $char (split("", $str))
	{
		my $c = ord($char);
		if(($c>32 and $c<125) or $c == 10)
		{
			$res .= $char;
		}
		else
		{
			$res .= sprintf('\x{%x}', $c)
		}
	}
	return $res;
}

sub cmp_results
{
	my ($results, $expects, $name) = @_;

	$Test->is_num(scalar @$results, scalar @$expects, "Test '$name' result count");

	for (my $i = 0; $i < @$expects; $i++)
	{
		my $expect = $expects->[$i];
		my $result = $results->[$i];

		local $Test::Builder::Level = $Test::Builder::Level + 1;
		cmp_result($result, $expect, $name);
	}
}

######## nicked from Test::More
sub plan {
	my(@plan) = @_;

	my $caller = caller;

	$Test->exported_to($caller);

	my @imports = ();
	foreach my $idx (0..$#plan) {
		if( $plan[$idx] eq 'import' ) {
			my($tag, $imports) = splice @plan, $idx, 2;
			@imports = @$imports;
			last;
		}
	}

	$Test->plan(@plan);

	__PACKAGE__->_export_to_level(1, __PACKAGE__, @imports);
}

sub import {
	my($class) = shift;
		{
			no warnings 'redefine';
			*Test::Builder::new = \&new_new;
		}
	goto &plan;
}

sub _export_to_level
{
        my $pkg = shift;
	my $level = shift;
	(undef) = shift;	# redundant arg
	my $callpkg = caller($level);
	$pkg->export($callpkg, @_);
}


############

1;

__END__

#line 645
