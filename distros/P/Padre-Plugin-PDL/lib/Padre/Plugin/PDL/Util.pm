package Padre::Plugin::PDL::Util;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.05';

# Cached items
my $pdl_keywords;
my $pdldoc;

# Adds awesome PDL keywords highlighting
# Not the smartest though at the moment :)
sub add_pdl_keywords_highlighting {
	my $document = shift;
	my $editor   = shift;

	my $keywords = Padre::Wx::Scintilla->keywords($document);
	if ( Params::Util::_ARRAY($keywords) ) {
		foreach my $i ( 0 .. $#$keywords ) {
			my $keyword_list = $keywords->[$i];
			if ( $i == 0 ) {
				$keyword_list .= ' ' . get_pdl_keywords();
			}
			$editor->Wx::Scintilla::TextCtrl::SetKeyWords( $i, $keyword_list );
		}
	}

	return;
}

# Gets a space-seperated PDL keyword list that is used Scintilla's SetKeyWords
sub get_pdl_keywords {

	# Returned cached PDL keywords if it is already defined
	return $pdl_keywords if defined $pdl_keywords;

	# Find the pdl documentation
	my $pdldoc = get_pdldoc();

	# Cache the space seperated keyword list
	$pdl_keywords = defined $pdldoc ? join ' ', keys %{ $pdldoc->gethash } : '';

	# And return it
	return $pdl_keywords;
}

# Returns the cached pdldoc is found
# Otherwise tries to create one
sub get_pdldoc {

	# Returned cached PDL keywords if it is there
	return $pdldoc if defined $pdldoc;


	# Find PDL documentation and return the pdl object
	require PDL::Doc;
	for my $dir (@INC) {
		my $file = "$dir/PDL/pdldoc.db";
		if ( -f $file ) {
			$pdldoc = new PDL::Doc($file);
			last;
		}
	}

	# A simple warn. I wish padre had a better logging facility
	warn "PDL documentation not found\n" unless defined $pdldoc;

	return $pdldoc;
}

1;
