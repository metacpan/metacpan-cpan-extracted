#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;
use FFI::C::File;
use Capture::Tiny qw(capture_stdout);
use Path::Tiny;

use constant ONTO => 'corpus/example_pizza.owl';

# See <sisinflab-swot/cowl/examples/00_base.c>
subtest "Read ontology and log axioms and annotations" => sub {
	my $manager = RDF::Cowl::Manager->new;
	my $ustring = ONTO;
	my $onto = $manager->read_path($ustring);

	my $tmp = Path::Tiny->tempfile;
	my $file = FFI::C::File->fopen("$tmp", 'w');
	$manager->write_FILE( $onto, $file );
	$file->fclose;

	like $tmp->slurp_utf8, qr/\Qdc:description\E.*\QAn ontology about pizzas and their toppings.\E/, 'contains dc:description';

	undef $manager;
	undef $onto;
};

done_testing;
