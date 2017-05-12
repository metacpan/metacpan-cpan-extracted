use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub verifyVVDir($)
{
	my $dir = shift @_;
	my $engine = sprintf "%s/bin/engine", $dir;
	return ((-d $dir) and (-f $engine) and (-x $engine));
}

sub printSeparator()
{
	print "\n";
	print '-' x 65;
	print "\n\n";
}


my $sModName = 'Speech::Recognizer::ViaVoice';
my $defaultVVDir = undef;
my @candidateDirs = (
	'/usr/lib/ViaVoice',
	'/usr/ViaVoice',
	'/usr/share/ViaVoice',
	'/usr/local/lib/ViaVoice',
	'/usr/local/ViaVoice',
	'/usr/local/share/ViaVoice'
);


# look for candidate ViaVoice directories
for (my $i = 0; ($i <= $#candidateDirs) and (not defined($defaultVVDir)) and (@candidateDirs > 0); $i++) {
	my $candidate = $candidateDirs[$i];
	if (verifyVVDir($candidate)) {
		$defaultVVDir = $candidate;
	}
}

$| = 1;
if (not defined $defaultVVDir) {
	printSeparator;
	printf "I did not find a ViaVoice installation!  This module requires IBM's\n"
		. "ViaVoice to run.  You can obtain ViaVoice for Linux from\n"
		. "http://www-4.ibm.com/software/speech/enterprise/te_3.html\n\n"
		. "If you wish to continue installing %s, you can,\n"
		. "but the tests in test.pl will fail.\n\n", $sModName;
	$defaultVVDir = $candidateDirs[0];
}

# request user input for ViaVoice directory
printSeparator;
my ($bOk, $vvDir) = (0, undef);
while (0 == $bOk) {
	$vvDir = $defaultVVDir;
	printf "Please enter your ViaVoice installation directory,\n"
		. "or press RETURN to accept the default.\n\n"
		. "ViaVoice directory [ %s ]: ", $vvDir;
	chop(my $s = <STDIN>);
	if (not ($s =~ m/^\s*$/)) {
		$vvDir = $s;
	}
	if (verifyVVDir($vvDir)) {
		$bOk = 1;
	} else {
		printf "\n%s does not contain an insallation that I\n"
			. "recognize.  If you wish to proceed with this setting, you might\n"
			. "need to do some trouble-shooting.\n\n"
			. "Proceed (y/N)? : ", $vvDir;
		chop($s = <STDIN>);
		if ($s =~ m/\s*(?:y(?:es)?)\s*/i) {
			$bOk = 1;
		} else {
			print "\n\n";
		}
	}
}


# request locale
printSeparator;
my ($defaultLocale, $locale) = ('En_US', undef);
	printf "Your locale is represented by the name of the directory in\n"
		. "%s/vocabs/langs/.  For example, \"%s\" for an\n"
		. "installation containing %s/vocabs/langs/%s)\n\n", $vvDir, $defaultLocale, $vvDir, $defaultLocale;
$bOk = 0;
while (0 == $bOk) {
	$locale = $defaultLocale;
	printf "Enter your locale [ %s ]: ", $locale;

	chop(my $s = <STDIN>);
	if (not $s =~ m/^\s*$/) {
		$locale = $s;
	}
	if (not verifyVVDir($vvDir) or (-d "$vvDir/vocabs/langs/$locale")) {
		$bOk = 1;
	} else {
		printf "\n%s/vocabs/langs/%s does not exist.  Proceed (y/N)? : ", $vvDir, $locale;
		chop($s = <STDIN>);
		if ($s =~ m/\s*(?:y(?:es)?)\s*/i) {
			$bOk = 1;
		} else {
			print "\n\n";
		}
	}
}

# create bin/pronunciations.pl
open PRON_IN, '<bin/pronunciations.pl.in' or die "could not open bin/pronunciations.pl.in for reading\n";
open PRON_OUT, '>bin/pronunciations.pl' or die "could not create bin/pronunciations.pl\n";
for (<PRON_IN>) {
	if ('/usr/lib/ViaVoice' ne $vvDir) {
		s,/usr/lib/ViaVoice,$vvDir,g;
	}
	if ('En_US' ne $locale) {
		s/En_US/$locale/g;
	}
	print PRON_OUT $_;
}
close PRON_IN;
close PRON_OUT;
chmod 0755, 'bin/pronunciations.pl';


WriteMakefile(
    'DEFINE'		=> '-DVVDIR=\"' . $vvDir . '\" -DLOCALE=\"' . $locale . '\"',

    'NAME'		=> $sModName,
    'VERSION_FROM'	=> 'ViaVoice.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ViaVoice.pm', # retrieve abstract from module
       AUTHOR     => 'Richard Kilgore <rkilgore@kilgoreSolutions.com>') : ()),
    'LIBS'		=> ['-lsmapi'], # e.g., '-lm'
	# Insert -I. if you add *.h files later:
    'INC'		=> '-I/usr/lib/ViaVoice/include', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'EXE_FILES'    => ['bin/pronunciations.pl'],
	'dist'       => {
		PREOP    => "echo \"Speech::Recognizer::ViaVoice version \$(VERSION)\" > README ;"
					. "echo \"\" >> README ;"
					. "echo \"\" >> README ;"
					. "pod2text ViaVoice.pm >> README ; "
					. "enscript -W html README "
						. "| perl -p -e 's,(http://\[^()\\s]+),<a href=\\1>\\1</a>,g' > README.html"
	},
	'clean' => {
		FILES => 'make.log README.html Speech-Recognizer-ViaVoice-\$(VERSION).tar.gz bin/pronunciations.pl'
	},
);
