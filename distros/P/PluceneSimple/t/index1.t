#!/usr/bin/perl -w

=head1 NAME 

t/index1.t - test Plucene::Simple with larger files

=head1 DESCRIPTION

In order to index bigger files, this builds and index using 
Plucene::Simple's own test scripts.

=cut

use strict;
use warnings;

use Plucene::Simple;

use File::Find::Rule;
use File::Path;
use File::Slurp;

use Test::More tests => 4;

use constant DIRECTORY => "/tmp/testindex$$";

END { rmtree DIRECTORY }

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub files { File::Find::Rule->file()->name('*.t')->in('.') }

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

our @files = files();

{    # Add some stuff into the index
	isa_ok my $plucy = Plucene::Simple->open(DIRECTORY) => 'Plucene::Simple';

	#my @files = files();
	for my $file (@files) {
		my $data = read_file($file);
		$plucy->index_document($file, $data);
	}
	$plucy->optimize;
}

{    # search the index
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs  = $plucy->search("bogus");
	is @docs, 2, "2 results for bogus";
}

{    # is indexed?
	my $plucy = Plucene::Simple->open(DIRECTORY);
	ok $plucy->indexed($files[0]), "$files[0] is indexed";
	ok !$plucy->indexed('NotTheRealID'), "Fake id is not indexed";
}
