use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.003_96;
	$VERSION = '1.12';
}
use ExtUtils::MakeMaker;

WriteMakefile1(
	NAME             => 'Template::Tiny',
	ABSTRACT         => 'Template Toolkit reimplemented in as little code as possible',
	VERSION          => $VERSION,
	PREREQ_PM        => { },
	AUTHOR           => 'Adam Kennedy <adamk@cpan.org>',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.00503', # from Tiny.pm
	META_MERGE       => {
		resources => {
			repository => 'http://svn.ali.as/cpan/trunk/Template-Tiny',
		},
	},
	BUILD_REQUIRES => {
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
	},
);

# Written by Alexandr Ciornii, version 0.20. Added by eumm-upgrade.
sub WriteMakefile1 {
	my %params = @_;
	my $eumm_version = $ExtUtils::MakeMaker::VERSION;
	$eumm_version = eval $eumm_version;
	die "License not specified" if not exists $params{LICENSE};
	if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
		#EUMM 6.5502 has problems with BUILD_REQUIRES
		$params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
		delete $params{BUILD_REQUIRES};
	}
	delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
	delete $params{META_MERGE}       if $eumm_version < 6.46;
	delete $params{LICENSE}          if $eumm_version < 6.31;
	delete $params{AUTHOR}           if $] < 5.005;

	WriteMakefile(%params);
}
