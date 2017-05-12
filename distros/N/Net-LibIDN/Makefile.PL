use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $options;
my $testno=1;
my %MakeParams = InitMakeParams();

WriteMakefile(%MakeParams);


sub MY::postamble {	
	"
LibIDN.pm: _LibIDN.pm _test.pl
	perl Makefile.PL $options

test.pl: _test.pl
	perl Makefile.PL $options
"
}

sub InitMakeParams
{
	my %Params =
	(
		'NAME'			=> 'Net::LibIDN',
		'VERSION_FROM'	=> 'LibIDN.pm', # finds $VERSION
		'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
		($] >= 5.005 ?	## Add these new keywords supported since 5.005
		(ABSTRACT_FROM	=> 'LibIDN.pm', # retrieve abstract from module
		AUTHOR			=> 'Thomas Jacob <jacob@internet24.de>') : ()),
		PM				=> { 'LibIDN.pm' => '$(INST_LIB)/Net/LibIDN.pm' },
		clean			=> { FILES => "test.pl LibIDN.pm" }
	);
	my ($libdir, $incdir, $disable_tld);

	$options=join(' ', @ARGV);

	GetOptions
	(
		"with-libidn=s" => \$libdir,
		"with-libidn-inc=s" => \$incdir,
		"disable-tld" => \$disable_tld
	);

	if ($libdir)
	{
		$Params{LIBS} = "-L$libdir -lidn";
	}
	else
	{
		$Params{LIBS} = $Config{ldflags} . ' -lidn';
	}

	if ($incdir)
	{
		$Params{INC} = "-I$incdir";
	}
	else
	{
		$Params{INC} = '';
	}

	my $libidn = CheckLibidn($Params{INC}, $Params{LIBS});

	unless($libidn)
	{
		print "This module requires GNU Libidn, which could not be found.\n" unless $libidn;
		exit 0;
	}

	print "Found LibIDN, ";
	print $libidn == 1? "without": "with";
	print " TLD checking support\n";

	if ($libidn == 2 && $disable_tld)
	{
		print "TLD checking support disabled at user request\n";
	}

	$disable_tld = 1 if ($libidn<2);

	if ($disable_tld)
	{
		$Params{DEFINE} = '';
	}
	else
	{
		$Params{DEFINE} = '-DHAVE_TLD';
	}
	FilterTLD("_LibIDN.pm", "LibIDN.pm", !$disable_tld);
	FilterTLD("_test.pl", "test.pl", !$disable_tld);

	return(%Params);
}

sub FilterTLD
{
	my $in = shift;
	my $out = shift;
	my $tld = shift;
	local *IN, *OUT;

	open(IN, "<$in") || die "Can't open file $in\n";
	open(OUT, ">$out") || die "Can't write file $out\n";

	my ($inside, $else);
	while(<IN>)
	{
		if (m/^#IF_TLD/)
		{
			$inside = 1;
			next;
		}
		if (m/^#ELSE_TLD/)
		{
			$else = 1;
			next;
		}
		if (m/^#ENDIF_TLD/)
		{
			$inside = 0;
			$else = 0;
			next;
		}
		if ($inside)
		{
			if ($tld)
			{
				print OUT $_ unless $else;
			}
			elsif($else)
			{
				print OUT $_;
			}
		}
		else
		{
			print OUT $_;
		}
		
	}
}

sub CheckCCode
{
	my $code = shift;
	my $cflags = shift;
	my $ldflags = shift;
	my $output = shift;
	my $test = '__test'.$testno++;
	local * FILE;

	if (open(FILE, ">$test.c"))
	{
		print FILE $code;
		close(FILE);
	}
	else
	{
		return 0;
	}

	foreach my $cc (qw/cc gcc/)
	{
		unlink($test);
		system "$cc $cflags -o $test $test.c $ldflags";
		next if ($? >> 8);

		if (open(FILE, "./$test|"))
		{
			my $match;
			while(<FILE>)
			{
				$match = 1 if $_ eq $output;
				last;
			}
			close(FILE);
			next unless $match;
		}
		else
		{
			next;
		}
		unlink($test);
		unlink("$test.c");
		return 1;
	}
	return 0;
}

sub CheckLibidn
{
	my $cflags = shift;
	my $ldflags = shift;
	my $result;
	my $final;
	local * FILE;

	my $test1 = <<EOT;
#include <idna.h>
#include <stdio.h>
int main(void)
{
	char * output;
	int res;
	
	res = idna_to_ascii_8z("libidn", &output, 0);
	printf("%d-%s", res, output);

	return 0;
}
EOT
	return $result unless CheckCCode($test1, $cflags, $ldflags, "0-libidn");

	$result = 1;

	my $test2 = <<EOT;
#include <tld.h>
#include <stdio.h>
int main(void)
{
	char * output;
	int res;

	res =tld_get_z ("libidn.idn", &output);	
	printf("%d-%s", res, output);
	
	return 0;
}
EOT

	return $result unless CheckCCode($test2, $cflags, $ldflags, "0-idn");
	
	return 2;
}

