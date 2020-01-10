package TestUtilFuncs;

use PerlX::bash;

use Test::More;
use Test::Command	0.08;
use Test::Builder;
use Test::Exception;

use Capture::Tiny qw< capture >;

use base 'Exporter';
our @EXPORT_OK = qw< throws_error perl_error_is >;


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



# These are stolen shamelessly from my personal test suite for "myperl" (Test::myperl).
# original lives at: https://github.com/barefootcoder/common/blob/master/perl/myperl/t/Test/myperl.pm

sub _perl_command
{
	my $cmd = shift;
	return [ $^X, '-e', $cmd, '--', @_ ];
}

sub perl_error_is
{
	my ($tname, $expected, $cmd, @extra) = @_;

	if ( ref $expected eq 'Regexp' )
	{
		stderr_like(_perl_command($cmd, @extra), $expected, $tname);
	}
	elsif ( $expected =~ /\n\Z/ )
	{
		stderr_is_eq(_perl_command($cmd, @extra), $expected, $tname);
	}
	else
	{
		my $regex = qr/^\Q$expected\E( at \S+ line \d+\.)?\n/;
		stderr_like(_perl_command($cmd, @extra), $regex, $tname);
	}
}



1;
