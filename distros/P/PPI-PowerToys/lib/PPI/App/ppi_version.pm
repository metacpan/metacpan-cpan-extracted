package PPI::App::ppi_version;

use 5.006;
use strict;
use warnings;
use version                0.74 ();
use File::Spec             0.80 ();
use Getopt::Long           2.36 ();
use PPI::Document         1.201 ();
use File::Find::Rule       0.30 ();
use File::Find::Rule::Perl 0.03 ();

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.14';
}





#####################################################################
# Main Functions

sub main {
	my $cmd = shift @_;
	return usage(@_)  unless defined $cmd;
	return show(@_)   if $cmd eq 'show';
	return change(@_) if $cmd eq 'change';
	return error("Unknown command '$cmd'");
}

sub error {
	my $msg = shift;
	chomp $msg;
	print "\n";
	print "  $msg\n";
	print "\n";
	return 255;
}





#####################################################################
# Command Functions

sub usage {
	print "\n";
	print "ppi_version $VERSION - Copyright 2006 - 2009 Adam Kennedy.\n";
	print "Usage:\n";
	print "  ppi_version show\n";
	print "  ppi_version change 0.02_03 0.54\n";
	print "\n";
	return 0;
}

sub show {
	# Find all modules and scripts below the current directory
	my @files = File::Find::Rule->perl_file->in( File::Spec->curdir );
	print "Found " . scalar(@files) . " file(s)\n";

	my $count = 0;
	foreach my $file ( @files ) {
		print "$file...";
		my $document = PPI::Document->new($file);
		unless ( $document ) {
			print " failed to parse file\n";
			next;
		}

		# Does the document contain a simple version number
		my $elements = $document->find( \&_wanted );
		unless ( $elements ) {
			print " no version\n";
			next;
		}
		if ( @$elements > 1 ) {
			error("$file contains more than one \$VERSION");
		}

		# What is that number
		my $version = _get_version($elements->[0]);
		unless ( defined $version ) {
			error("Failed to get version string");
		}
		print " $version\n";
		$count++;
	}

	print "Found " . scalar($count) . " version(s)\n";
	print "Done.\n";
	return 0;	
}

sub change {
	my $from = shift @_;
	unless ( $from and $from =~ /^[\d\._]+$/ ) {
		error("From is not a number");
	}
	my $to = shift @_;
	unless ( $to and $to =~ /^[\d\._]+$/ ) {
		error("To is not a number");
	}

	# Find all modules and scripts below the current directory
	my @files = File::Find::Rule->perl_file->in( File::Spec->curdir );
	print "Found " . scalar(@files) . " file(s)\n";

	my $count = 0;
	foreach my $file ( @files ) {
		print "$file...";
		if ( ! -w $file ) {
			print " no write permission\n";
			next;
		}
		my $rv = _change_file( $file, $from => $to );
		if ( $rv ) {
			print " updated\n";
			$count++;
		} elsif ( defined $rv ) {
			print " skipped\n";
		} else {
			print " failed to parse file\n";
		}
	}

	print "Updated " . scalar($count) . " file(s)\n";
	print "Done.\n";
	return 0;
}






#####################################################################
# Support Functions

sub _change_file {
	my $file = shift;
	my $from = shift;
	my $to   = shift;

	# Parse the file
	my $document = PPI::Document->new($file);
	unless ( $document ) {
		error("Failed to parse $file");
	}

	# Apply the changes
	my $rv = _change_document( $document, $from => $to );
	unless ( defined $rv ) {
		error("$file contains more than one \$VERSION assignment");
	}
	unless ( $rv ) {
		return '';
	}

	# Save the updated version
	unless ( $document->save($file) ) {
		error("PPI::Document save failed");
	}

	return 1;
}

sub _change_document {
	my $document = shift;
	my $from     = shift;
	my $to       = shift;

	# Does the document contain an element
	my $elements = $document->find( \&_wanted );
	unless ( $elements ) {
		return '';
	}
	if ( @$elements > 1 ) {
		return undef;
	}

	# Find (and if it matches, replace) the version
	my $version = _get_version($elements->[0]);
	unless ( $version eq $from ) {
		return '';
	}

	# Set the new version
	_set_version( $elements->[0], $to );

	return 1;
}

# Extract the version
sub _get_version {
	my $token = shift;
	if ( $token->isa('PPI::Token::Quote') ) {
		if ( $token->can('literal') ) {
			return $token->literal;
		} else {
			return $token->string;
		}
	} elsif ( $token->isa('PPI::Token::Number') ) {
		if ( $token->can('literal') ) {
			return $token->literal;
		} else {
			return $token->content;
		}
	}
	die('Unsupported object ' . ref($token));
}

# Change the version.
# We need to hack some internals to achieve this,
# but it will have to do for now.
sub _set_version {
	my $token = shift;
	my $to    = shift;
	if ( $token->isa('PPI::Token::Number') ) {
		$token->{content} = $to;
	} elsif ( $token->isa('PPI::Token::Quote::Single') ) {
		$token->{content} = qq|'$to'|;
	} elsif ( $token->isa('PPI::Token::Quote::Double') ) {
		$token->{content} = qq|"$to"|;
	} elsif ( $token->isa('PPI::Token::Quote::Literal') ) {
		substr(
			$token->{content},
			$token->{sections}->[0]->{position},
			$token->{sections}->[0]->{size},
			$to,
		);
	} elsif ( $token->isa('PPI::Token::Quote::Interpolate') ) {
		substr(
			$token->{content},
			$token->{sections}->[0]->{position},
			$token->{sections}->[0]->{size},
			$to,
		);
	} else {
		die('Unsupported object ' . ref($token));
	}
	return 1;
}

sub _file_version {
	my $file = shift;
	my $doc  = PPI::Document->new($file);
	unless ( $doc ) {
		return "failed to parse file";
	}

	# Does the document contain a simple version number
	my $elements = $doc->find( \&_find_version );
	unless ( $elements ) {
		return "no version";
	}
	if ( @$elements > 1 ) {
		error("$file contains more than one \$VERSION");
	}
	my $element = $elements->[0];
	my $version = $element->snext_sibling->snext_sibling;
	my $version_string = $version->string;
	unless ( defined $version_string ) {
		error("Failed to get version string");
	}

	return version->new($version_string);
}

# Locate a version number token
sub _wanted {
	# Must be a quote or number
	$_[1]->isa('PPI::Token::Quote')          or
	$_[1]->isa('PPI::Token::Number')         or return '';

	# To the right is a statement terminator or nothing
	my $t = $_[1]->snext_sibling;
	if ( $t ) {
		$t->isa('PPI::Token::Structure') or return '';
		$t->content eq ';'               or return '';
	}

	# To the left is an equals sign
	my $e = $_[1]->sprevious_sibling         or return '';
	$e->isa('PPI::Token::Operator')          or return '';
	$e->content eq '='                       or return '';

	# To the left is a $VERSION symbol
	my $v = $e->sprevious_sibling            or return '';
	$v->isa('PPI::Token::Symbol')            or return '';
	$v->content =~ m/^\$(?:\w+::)*VERSION$/  or return '';

	# To the left is either nothing or "our"
	my $o = $v->sprevious_sibling;
	if ( $o ) {
		$o->content eq 'our'             or return '';
		$o->sprevious_sibling           and return '';
	}

	return 1;
}

1;
