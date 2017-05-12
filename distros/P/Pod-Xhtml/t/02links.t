#!/usr/local/bin/perl -w
#$Id: 02links.t,v 1.9 2006/08/29 12:48:11 andreww Exp $

use strict;
use lib qw(./lib ../lib);
use Test;
use Pod::Xhtml;
use Getopt::Std;
use File::Basename;

getopts('tTs', \my %opt);
if ($opt{t} || $opt{T}) {
	require Log::Trace;
	import Log::Trace print => {Deep => $opt{T}};
}

chdir ( dirname ( $0 ) );

require Test_LinkParser;

plan tests => 16;

my $pod_links = new Test_LinkParser();
my $parser = new Pod::Xhtml( LinkParser => $pod_links );

# Links to manpages
ok($parser->seqL('Pod::Xhtml') eq '<cite>Pod::Xhtml</cite>');
ok($parser->seqL('XHTML Podlator|Pod::Xhtml') eq '<b>XHTML Podlator</b> (<cite>Pod::Xhtml</cite>)');
ok($parser->seqL('crontab(5)') eq '<cite>crontab</cite>(5)');

# Links to section in other manpages
ok($parser->seqL('Pod::Xhtml/"SEE ALSO"') eq '<b>SEE ALSO</b> in <cite>Pod::Xhtml</cite>');
ok($parser->seqL('alt text|Pod::Xhtml/"SEE ALSO"') eq '<b>alt text</b> (<b>SEE ALSO</b> in <cite>Pod::Xhtml</cite>)');
ok($parser->seqL('Pod::Xhtml/SYNOPSIS') eq '<b>SYNOPSIS</b> in <cite>Pod::Xhtml</cite>');
ok($parser->seqL('alt text|Pod::Xhtml/SYNOPSIS') eq '<b>alt text</b> (<b>SYNOPSIS</b> in <cite>Pod::Xhtml</cite>)');

# Links to sections in this manpage
# Since 1.41, these are fully resolved at the end of the POD parse
ok($parser->seqL('/"User Guide"') eq '<a href="#<<<User Guide>>>">User Guide</a>');
ok($parser->seqL('alt text|/"User Guide"') eq '<a href="#<<<User Guide>>>">alt text</a>');
ok($parser->seqL('/Notes') eq '<a href="#<<<Notes>>>">Notes</a>');
ok($parser->seqL('alt text|/Notes') eq '<a href="#<<<Notes>>>">alt text</a>');
ok($parser->seqL('"Installation Guide"') eq '<a href="#<<<Installation Guide>>>">Installation Guide</a>');
ok($parser->seqL('alt text|"Installation Guide"') eq '<a href="#<<<Installation Guide>>>">alt text</a>');

# Links to web pages
ok($parser->seqL('http://bbc.co.uk/') eq '<a href="http://bbc.co.uk/">http://bbc.co.uk/</a>');
ok($parser->seqL('http://bbc.co.uk/#top') eq '<a href="http://bbc.co.uk/#top">http://bbc.co.uk/#top</a>');

my $pod_output = 'links.out';
open(OUT, '+>'.$pod_output) or die("Can't open $pod_output: $!");
$parser->parse_from_filehandle(\*DATA, \*OUT);
seek OUT, 0, 0;
my $output = do {local $/; <OUT>};
close OUT;
TRACE("Double encoding output ($pod_output):\n", $output);
ok(index($output, canned_links()) > -1);
unlink $pod_output unless $opt{'s'};

sub canned_links {
	return <<LINKS;
<p>Test 1</p>
<p><a href="http://www.bbc.co.uk/opensource/test?ARG=VAL&amp;ARG2=VAL2">http://www.bbc.co.uk/opensource/test?ARG=VAL&amp;ARG2=VAL2</a></p>
<p>Test 2</p>
<p><a href="http://www.bbc.co.uk/opensource/test?ARG=VAL&amp;ARG2=VAL2">Escaping Args &amp; Values</a></p>
<p>Test 3</p>
<p><a href="#whatisan_amp_doinghere">whatisan&amp;doinghere</a></p>
<p>Test 4</p>
<p><b>&quot;AUTHOR &amp; ACKNOWLEDGEMENTS&quot;</b> in <cite>Pod::Xhtml</cite>
</p>
LINKS
}

# Log::Trace stubs
sub TRACE {}
sub DUMP  {}

__DATA__

=head1 DOUBLE ENCODING TEST

Test 1

L<http://www.bbc.co.uk/opensource/test?ARG=VALE<amp>ARG2=VAL2>

Test 2

L<Escaping Args E<amp> Values|http://www.bbc.co.uk/opensource/test?ARG=VALE<amp>ARG2=VAL2>

Test 3

L<whatisanE<amp>doinghere>

Test 4

L<Pod::Xhtml/"AUTHOR E<amp> ACKNOWLEDGEMENTS">
