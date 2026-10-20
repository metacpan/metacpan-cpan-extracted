package DocumentTest;

# Helpers for the tests of the document and the document view: build
# documents without a parser. A text may hold marks written as
# <kind>...</kind> for any kind, and <link=TARGET>...</link> for a link;
# the tags nest. sample_document and long_document are the two
# documents several tests share.

use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT = qw(document marked sample_document long_document);    ## no critic (Modules::ProhibitAutomaticExportation) every test uses most helpers

use Term::Fabulous::Document;

# The text without its tags, and the marks the tags stood for, as a text
# the factories of a document take.
sub marked ($tagged) {
	my ( $text, @marks, @open ) = ('');
	foreach my $piece ( split /(<\/?\w+(?:=[^>]*)?>)/, $tagged ) {
		if ( $piece =~ /\A<(\w+)(?:=([^>]*))?>\z/ ) {
			push @open, [ length $text, $1, $2 ];
		}
		elsif ( $piece =~ /\A<\/(\w+)>\z/ ) {
			my $mark = pop @open // die "DocumentTest: a </$1> without a <$1>";
			die "DocumentTest: a </$1> closes a <$mark->[1]>" unless $mark->[1] eq $1;
			push @marks, [ $mark->[0], length $text, $mark->[1], defined $mark->[2] ? $mark->[2] : () ];
		}
		else {
			$text .= $piece;
		}
	}
	die "DocumentTest: a <$open[-1][1]> is never closed" if @open;
	return { text => $text, marks => [ sort { $a->[0] <=> $b->[0] } @marks ] };
}

# A document made by calls of its factories: [ method => arguments ].
sub document (@calls) {
	my $document = Term::Fabulous::Document->new;
	foreach my $call (@calls) {
		my ( $method, @arguments ) = @$call;
		$document->$method(@arguments);
	}
	return $document;
}

# Items: 0 NAME, 1 the name line, 2 SYNOPSIS, 3 code, 4 DESCRIPTION,
# 5 marks and links, 6 Methods, 7 and 9 terms with their definitions 8
# and 10, 11 Lists, 12 and 13 a bulleted list, 14 and 15 a numbered one,
# 16 SEE ALSO, 17 more links.
sub sample_document () {
	return document(
		[ heading   => 1, 'NAME' ],
		[ paragraph => 'Sample - a page to test the document view with' ],
		[ heading   => 1,                                         'SYNOPSIS' ],
		[ code      => "use Sample;\nmy \$sample = Sample->new;", language => 'perl' ],
		[ heading   => 1,                                         'DESCRIPTION' ],
		[
			paragraph => marked(
'Some <bold>bold</bold>, <italic>italic</italic>, <code>code</code> and <file>file.txt</file>, a link to <link=Other>Other</link> and one to <link=/Methods>a section</link>, Grüße and é.'
			)
		],
		[ heading   => 2, 'Methods' ],
		[ term      => 'new' ],
		[ paragraph => 'Creates a sample.', indent => 4 ],
		[ term      => 'frobnicate VALUE' ],
		[ paragraph => marked('Frobnicates the <italic>VALUE</italic>.'), indent => 4 ],
		[ heading   => 2,                                                 'Lists' ],
		[ list_item => "\x{2022}",                                        'First point.' ],
		[ list_item => "\x{2022}",                                        marked('Second point with <link=Other/Details>Details</link>.'), position => 2 ],
		[ list_item => '1.',                                              'One.' ],
		[ list_item => '2.',                                              'Two.', position => 2 ],
		[ heading   => 1,                                                 'SEE ALSO' ],
		[ paragraph => marked('<link=Other>Other</link>, <link=https://example.com/sample>https://example.com/sample</link>, <link=crontab(5)>crontab(5)</link>.') ],
	);
}

# A heading, 120 one-line paragraphs with a needle each, and a last one.
sub long_document () {
	return document( [ heading => 1, 'NAME' ], ( map { [ paragraph => "Paragraph $_ with a needle in it." ] } 1 .. 120 ), [ paragraph => 'The last paragraph.' ] );
}

1;
