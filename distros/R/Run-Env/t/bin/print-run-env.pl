#!/usr/bin/perl

=head1 NAME

xxx - desc

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut


use strict;
use warnings;

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', '..', 'lib');
use Run::Env;

exit main();

sub main {
	print join(', ',
			Run::Env::current(),
			Run::Env::execution(),
			(Run::Env::testing() ? 'testing' : 'no-testing'),
			(Run::Env::debug() ? 'debug' : 'no-debug'),
		)."\n";
	
	return 0;
}
