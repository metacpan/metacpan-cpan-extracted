package Uncruft;

my $CLASS = __PACKAGE__;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(uncruft);

my $html_xml_tags_re = qr/<\/?(?:p|br|ref)(?:\s[^>]*)?>/i;

sub uncruft
{
	($_) = @_;

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	my @matches = m/^[ \t]*([^a-zA-Z0-9\s]{1,3})[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/^[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/m;
		s/$comment_re//g;
	}

	my @wordmatches = m/^[ \t]*(dnl|REM|COMMENT)[ \t]+\S/mg;
	if ( @wordmatches >= 4 ) {
		my $comment_re = qr/^[ \t]*\Q$wordmatches[0]\E[ \t]*/m;
		s/$comment_re//g;
	}

	# Remove other side of "boxed" comments
	s/[ \t]*[*#][ \t]*$//gm;

	# Remove Fortran comments
	s/^[cC]$//gm;
	s/^[cC] //gm;

	# Remove C / C++ comments
	s#(\*/|/\*|(?<!:)//)##g;

	# Strip escaped newline
	s/\s*\\n\s*/ /g;

	# strip trailing dash, assuming it is soft-wrap
	# (example: disclaimers in GNU autotools file "install-sh")
	s/-\r?\n//g;

	# strip common html and xml tags
	s/$html_xml_tags_re//g;

	tr/\t\r\n/ /;

	# this also removes quotes
	tr% A-Za-z.,:@;0-9\(\)/-%%cd;
	tr/ //s;

	return $_;
}

1;
