
package XMLCompare;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(xml_ok file_ok $show_lines xmltidy);

use XML::Tidy;
use IO::All;

our $show_lines = 40;

sub xmltidy {
    my $xml = shift;
    my $tidy;
    eval {
	my $tidy_obj = XML::Tidy->new(xml => $xml);
	$tidy_obj->tidy;
	$tidy = $tidy_obj->toString;
    };
    return $tidy || $xml;
}

sub xml_ok {
    my $data = shift;
    my $filename = shift;
    my $test_description = shift;

 SKIP:{
	$data = xmltidy($data);
	main::is($@, "", "$test_description - XML is valid")
	    or do {
		main::diag("first few lines of output:\n".
		     substr($data, 0, 400));
		main::skip "diff test", 1;
	    };

	file_ok($data, $filename, $test_description);

    }
}

our $TMP;
BEGIN { $TMP = $ENV{TMP} || "/tmp" }

sub file_ok {
    my $data = shift;
    my $filename = shift;
    my $test_description = shift;

    my $expected = io($filename)->slurp;

    main::ok($data eq $expected, "$test_description - content correct")
	    or do {
		$data > io("$TMP/got.$$")->assert;
		main::diag("early differences:");
		my $rc = system("diff -wu $filename $TMP/got.$$ > $TMP/diff.$$");
		if ( !$rc ) {
		    main::diag("note: differences only in whitespace");
		    system("diff -u $filename $TMP/got.$$ > $TMP/diff.$$");
		}
		system("head -$show_lines $TMP/diff.$$");
		unlink("$TMP/got.$$", "$TMP/diff.$$");
		main::diag("use -v option to show more lines of diff output");
	    };

}

1;
