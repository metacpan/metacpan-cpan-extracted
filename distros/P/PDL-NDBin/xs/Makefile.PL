use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME    => 'PDL::NDBin::Iterator',
	VERSION_FROM => '../lib/PDL/NDBin/Iterator.pm', # dzil inserts version in there, so this works right when built/released, despite warnings in clean repo
	NO_MYMETA => 1,
);
