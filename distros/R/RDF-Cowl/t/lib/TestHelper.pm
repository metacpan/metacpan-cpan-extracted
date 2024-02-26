package # hide from PAUSE
	TestHelper;
# ABSTRACT: Helper functions for test

use strict;
use warnings;

use Path::Tiny qw(path);

# Same as:
# diff -s <( grep -v '^#' < corpus/example_pizza.owl | perl -pe 's/^\s*$//; s/\Q^^xsd:string\E//' | sort  ) <( < /tmp/rdf_output.owl perl -pe 's/^\s*$//; s/^(Ontology\(<[^>]+>) (<[^>]+)/$1\n$2/' | sort )
sub normalize_and_sort_input {
	my ($class, $input_owl) = @_;
	my @input_lines =   sort(split /\n/, path($input_owl)->slurp_utf8 =~ s{
			^ \# [^\n]*? $ \n    # comments
			| ^ \s*? $ \n        # empty lines
			| \Q^^xsd:string\E   # extraneous xsd:string data type
		}{}xmsgr);

	\@input_lines;
}

sub normalize_and_sort_output {
	my ($class, $output_owl) = @_;
	my @output_lines =  sort(split /\n/, path($output_owl)->slurp_utf8
		# empty lines
		=~ s{ ^ \s*? $ \n }{}xmsgr
		# insert line break at white space for "Ontology(<IRI> <IRI>"
		=~ s{^ ( Ontology\( <[^>]+>)\ (<[^>]+>)}{$1\n$2}xmgr);

	\@output_lines;
}

1;
