use ExtUtils::MakeMaker;

my $mod = my $pm = "Parse::DebControl";
$pm =~ s/::/\//g;
$pm = "lib/$pm.pm";

unless(-e "CHANGES")
{
	open CHANGES,">>CHANGES";
	print CHANGES "Temp CHANGES file\n";
	close CHANGES;
}

WriteMakefile(
	'NAME'		=> $mod,
	'VERSION_FROM'	=> $pm, # finds $VERSION
	'PREREQ_PM'	=>
		{ 
			'Test::More' => '0.45',
			'IO::Scalar' => '2.104',
			'Compress::Zlib' => '0',
			'LWP::UserAgent' => '0',
			'LWP::Simple' => '0',
		},

	'dist'		=>
		{
			#Auto-generate the CHANGES file
			PREOP => "podselect $pm -section CHANGES | pod2text -w 1000 -i 5 | perl -pe \"s/^\s+(Version.*)/\$1/g;\" > CHANGES",
		},

	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(
			ABSTRACT_FROM	=> $pm, # retrieve abstract from module
			AUTHOR     	=> 'Jay Bonci <jaybonci@cpan.org>') 
		: ()),
);



