#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Module::Metadata::CoreList; # For the version #.

use Test::More;

use Capture::Tiny;
use Config;
use Config::Tiny;
use Date::Simple;
use File::Copy;
use File::HomeDir;
use File::Spec;
use Getopt::Long;
use Module::CoreList;
use Moo;
use Path::Class;
use Pod::Usage;
use strict;
use Text::Xslate;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Capture::Tiny
	Config
	Config::Tiny
	Date::Simple
	File::Copy
	File::HomeDir
	File::Spec
	Getopt::Long
	Module::CoreList
	Moo
	Path::Class
	Pod::Usage
	strict
	Text::Xslate
	Types::Standard
	warnings
/;

diag "Testing Module::Metadata::CoreList V $Module::Metadata::CoreList::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
