#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;
use Path::Tiny qw(path);
use Feature::Compat::Try;

use TestHelper;

use constant ONTO => 'corpus/example_pizza.owl';
use constant IMPORT => 'import.owl';

sub load_import {
	my ($iri) = @_; # (CowlIRI)
	my $import = undef;   # CowlOntology
	my $manager = RDF::Cowl::Manager->new;

	if ($manager) {
		$import = $manager->read_path(IMPORT);
	}

	return $import;
}

sub handle_error {
	my ($error) = @_; # CowlError
	print $error->to_string, "\n";
}

# See <sisinflab-swot/cowl/examples/01_errors_imports.c>
subtest "Set import loader and error handler" => sub {
	my $loader = RDF::Cowl::ImportLoader->new( \&load_import );
	RDF::Cowl->set_import_loader( $loader );

	my $handler = RDF::Cowl::ErrorHandler->new( \&handle_error );
	RDF::Cowl->set_error_handler( $handler );

	my $manager = do { try { RDF::Cowl::Manager->new; }
		catch ($e) { die "Could not create manager: $e"; }
	};

	my $onto = do { try { $manager->read_path(ONTO); }
		catch ($e) { die "Failed to load ontology @{[ ONTO ]}"; }
	};

	my $tmp = Path::Tiny->tempfile;
	my $file = FFI::C::File->fopen("$tmp", 'w');
	$manager->write_FILE( $onto, $file );
	$file->fclose;

	note $tmp->lines_utf8({ count => 32 });

	my $input_lines  = TestHelper->normalize_and_sort_input(ONTO);
	my $output_lines = TestHelper->normalize_and_sort_output($tmp);

	# compare tmp file
	is $output_lines, $input_lines, 'input and output are identical';
};

done_testing;
