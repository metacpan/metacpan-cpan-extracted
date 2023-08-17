package Uncruft;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

my $CLASS = __PACKAGE__;

use base qw(Exporter);
our @EXPORT = qw(uncruft);

my $html_xml_tags_re = qr/<\/?(?:p|br|ref)(?:\s[^>]*)?>/i;

sub uncruft ($string)
{
	my ( @matches, @wordmatches );

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	@matches = $string =~ m/^[ \t]*([^a-zA-Z0-9\s]{1,3})[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/^[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/m;
		$string =~ s/$comment_re//g;
	}

	@wordmatches = $string =~ m/^[ \t]*(dnl|REM|COMMENT)[ \t]+\S/mg;
	if ( @wordmatches >= 4 ) {
		my $comment_re = qr/^[ \t]*\Q$wordmatches[0]\E[ \t]*/m;
		$string =~ s/$comment_re//g;
	}

	# Remove other side of "boxed" comments
	$string =~ s/[ \t]*[*#][ \t]*$//gm;

	# Remove Fortran comments
	$string =~ s/^[cC]$//gm;
	$string =~ s/^[cC] //gm;

	# Remove C / C++ comments
	$string =~ s#(\*/|/\*|(?<!:)//)##g;

	# Strip escaped newline
	$string =~ s/\s*\\n\s*/ /g;

	# strip trailing dash, assuming it is soft-wrap
	# (example: disclaimers in GNU autotools file "install-sh")
	$string =~ s/-\r?\n//g;

	# strip common html and xml tags
	$string =~ s/$html_xml_tags_re//g;

	$string =~ tr/\t\r\n/ /;

	# this also removes quotes
	$string =~ tr% A-Za-z.,:@;0-9\(\)/-%%cd;
	$string =~ tr/ //s;

	return $string;
}

1;
