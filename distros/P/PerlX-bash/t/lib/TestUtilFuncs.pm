package TestUtilFuncs;

use PerlX::bash;

use Test::More;
use Test::Builder;
use Test::Exception;

use Capture::Tiny qw< capture >;

use base 'Exporter';
our @EXPORT_OK = qw< throws_error >;


sub throws_error ($$$)
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($cmd, $expected, $test_tag) = @_;

	# make sure our errors come back in English, as that's what our $expected will be
	local $ENV{LC_ALL} = 'C';

	my $result;
	my ($out, $err) = capture
	{
		$result = throws_ok { bash $cmd } qr/unexpectedly returned/, "$test_tag: dies as expected"
	};
	if ($result)
	{
		if (ref $expected eq 'Regexp')
		{
			$result = like $err, $expected, "$test_tag: error matches" or diag "output was: $out";
		}
		else
		{
			$result = is $err, $expected, "$test_tag: error matches" or diag "output was: $out";
		}
	}
	else
	{
		diag "error was: $err";
	}
	return $result;
}



1;
