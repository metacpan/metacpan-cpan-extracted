package Test2::Require::TestCorpus;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Test2::Require::Module qw(File::BaseDir);

use File::BaseDir qw(data_dirs);

use Carp qw/confess/;

use base 'Test2::Require';

sub skip ( $class, $var )
{
	return undef if data_dirs("tests/$var");
	return
		"This test only runs if test corpus is available at the path \${XDG_DATA_DIRS} + tests/$var/";
}

1;
