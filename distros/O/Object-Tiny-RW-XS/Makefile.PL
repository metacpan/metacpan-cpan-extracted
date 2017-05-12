use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.003_96;
	$VERSION = '0.03';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Object::Tiny::RW::XS',
	ABSTRACT  => 'A date object with as little code as possible (and rw accessors)',
	VERSION   => $VERSION,
	PREREQ_PM => {
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
		'Class::XSAccessor' => '0.11',
	},
	($] >= 5.005 ? (
		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>, ::RW fork by Steffen Schwigon, ::RW::XS fork by Adam Hopkins',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
