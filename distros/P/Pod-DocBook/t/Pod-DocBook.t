# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Pod-DocBook.t'

use strict;
use warnings;

use Test;
BEGIN { plan tests => 18 };

use Pod::DocBook;
ok 1;

#-----------------------------------------------------------------------
# test translation
#-----------------------------------------------------------------------

my @samples = qw(head paragraphs indent lists docbook table formatting_codes
		 e_command e_nested_fc e_unknown_fc e_empty_l e_escape
		 e_item e_mismatched_end e_no_end e_colspec);

foreach my $name (@samples) {
    my $parser = Pod::DocBook->new (doctype           => 'section',
				    title             => "$name.pod",
				    fix_double_quotes => 1,
				    header            => 1,
				    spaces            => 2);

    $parser->parse_from_file ("t/$name.pod", "t/test-$name.out");

    ok (check ("t/$name.sgml", "t/test-$name.out"), 1,
	"t/test-$name.out differs from t/$name.sgml") &&
	  unlink "t/test-$name.out";
}

#-----------------------------------------------------------------------
# test header option
#-----------------------------------------------------------------------

Pod::DocBook->new (doctype           => 'section',
		   title             => "no_header.pod",
		   fix_double_quotes => 1,
		   header            => 0,
		   spaces            => 2)
            ->parse_from_file ("t/no_header.pod", "t/test-no_header.out");

ok (check ("t/no_header.sgml", "t/test-no_header.out"), 1,
    "t/test-no_header.out differs from t/no_header.sgml") &&
  unlink "t/test-no_header.out";


sub check
{
    my ($file1, $file2) = @_;
    my (@file1, @file2);

    {
	open my $fh1, $file1 or die "couldn't open $file1: $!\n";
	open my $fh2, $file2 or die "couldn't open $file2: $!\n";

	# omit the module comment, because the local system's
	# modules may differ from the author's
	while (<$fh1>) {
	    push @file1, $_ unless /^<!--/ .. /^-->/;
	}

	while (<$fh2>) {
	    push @file2, $_ unless /^<!--/ .. /^-->/;
	}
    }

    # only files beginning with `e_' should have errors
    return 0 if $file2 !~ m!^t/test-e_! && grep /POD ERRORS/, @file2;

    # if one of the "good" sample files has an error, it's a problem
    # with the module distribution
    die "\n*** $file1 is bad in the distro--please contact the author ***\n"
      if $file1 !~ m!^t/e_! && grep /POD ERRORS/, @file1;

    return 0 if @file1 != @file2;
    for (@file1) { return 0 if $_ ne shift @file2 };
    return 1;
}
