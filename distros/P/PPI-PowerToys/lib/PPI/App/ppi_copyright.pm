package PPI::App::ppi_copyright;

use 5.006;
use strict;
use warnings;
use version                ();
use File::Spec             ();
use Getopt::Long           ();
use PPI::Document          ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();

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
	# Capture the author
	@ARGV = @_;
	my $AUTHOR = '';
	Getopt::Long::GetOptions(
		'author=s' => \$AUTHOR,
	);
	if ( $AUTHOR ) {
		$AUTHOR = quotemeta $AUTHOR;
	}

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

		# Filter by author if applicable
		if ( $elements and $AUTHOR ) {
			@$elements = grep {
				$_->{content} =~ /$AUTHOR/
			} @$elements;
		}

		# Find anything?
		unless ( $elements and @$elements ) {
			print " no copyright\n";
			next;
		}

		if ( @$elements ) {
			# Print the raw copyright lines
			print "\n";
			print "\n";
			foreach my $element ( @$elements ) {
				my $pod = $element->content;
				print map {
					"  $_\n"
				} grep {
					/Copyright/
				} split /\n/, $pod;
			}
			print "\n";
			$count++;
		}
	}

	print "Found " . scalar($count) . " copyright(s)\n";
	print "Done.\n";
	return 0;	
}

sub change {
	# Capture the author
	@ARGV = @_;
	my $AUTHOR = '';
	Getopt::Long::GetOptions(
		'author=s' => \$AUTHOR,
	);
	if ( $AUTHOR ) {
		$AUTHOR = quotemeta $AUTHOR;
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
		my $rv = _change_file( $file, $AUTHOR );
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

	# Parse the file
	my $document = PPI::Document->new($file);
	unless ( $document ) {
		error("Failed to parse $file");
	}

	# Apply the changes
	my $rv = _change_document( $document, $_[0] );
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
	my $AUTHOR   = shift;

	# Does the document contain an element
	my $elements = $document->find( \&_wanted );
	if ( $elements and $AUTHOR ) {
		@$elements = grep {
			$_->{content} =~ /$AUTHOR/
		} @$elements;
	}
	unless ( $elements and @$elements ) {
		return '';
	}

	my $pattern = qr/\b(copyright\s+\d{4}(?:\s*-\s*\d{4}))/i;
	foreach my $element ( @$elements ) {
		$element->{content} =~ s/$pattern/_change($1)/eg;
	}

	return 1;
}

# Locate a version number token
sub _wanted {
	return !! (
		$_[1]->isa('PPI::Token::Pod')
		and
		$_[1]->content =~ /\bCopyright\b/
	);
}

sub _change {
	my $copyright = shift;
	my $thisyear  = (localtime time)[5] + 1900;
	my @year      = $copyright =~ m/(\d{4})/g;

	if ( @year == 1 ) {
		# Handle the single year format
		if ( $year[0] == $thisyear ) {
			# No change
			return $copyright;
		} else {
			# Convert from single year to multiple year
			$copyright =~ s/(\d{4})/$1 - $thisyear/;
			return $copyright;
		}
	}

	if ( @year == 2 ) {
		# Handle the range format
		if ( $year[1] == $thisyear ) {
			# No change
			return $copyright;
		} else {
			# Change the second year to the current one
			$copyright =~ s/$year[1]/$thisyear/;
			return $copyright;
		}
	}

	# huh?
	die "Invalid or unknown copyright line $copyright";
}

1;
