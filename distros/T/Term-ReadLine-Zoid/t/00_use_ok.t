require Test::More;

@modules = qw/
	Term::ReadLine::Zoid::Base
	Term::ReadLine::Zoid
	Term::ReadLine::Zoid::ISearch
	Term::ReadLine::Zoid::ViCommand
	Term::ReadLine::Zoid::FileBrowse
/;

Test::More->import(tests => scalar @modules);

use_ok($_) for @modules;

# should we do a syntax check for the .al files ?
