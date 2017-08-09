#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use MojoX::Validate::Util; # For the version #.

use Test::More;

use Mojolicious;
use Mojolicious::Validator;
use Moo;
use Params::Classify;
use strict;
use Types::Standard;
use URI::Find::Schemeless;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Mojolicious
	Mojolicious::Validator
	Moo
	Params::Classify
	strict
	Types::Standard
	URI::Find::Schemeless
	warnings
/;

diag "Testing MojoX::Validate::Util V $MojoX::Validate::Util::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
