# tests of output to scalar

#########################

use Test::More;
BEGIN {
    eval {
	require 5.8.5;
    };
    if ($@) {
	plan skip_all => "feature not supported by perl version";
    }
    else {
	plan tests => 6;
    }
}

#-----------------------------------------------------------------
sub compare_strings {
    my $str1 = shift;
    my $str2 = shift;

    my @str1 = split(/\n/, $str1);
    my @str2 = split(/\n/, $str2);

    my $res = 1;
    my $count = 0;
    while (@str1)
    {
	$count++;
	my $comp1 = shift @str1;
	$comp1 =~ s/\n//;
	$comp1 =~ s/\r//;

	my $comp2 = shift @str2;
	$comp2 =~ s/\n//;
	$comp2 =~ s/\r//;

	if (!defined $comp2)
	{
	    print "error - line $count does not exist in (2)\n  (1) : $comp1\n";
	    return 0;
	}

	if ($comp1 ne $comp2)
	{
	    print "error - line $count not equal\n  (1) : $comp1\n  (2) : $comp2\n";
	    return 0;
	}
    }
    if (defined($comp2 = shift @str2))
    {
	print "error - extra line in (2) : '$comp2'\n";
	$res = 0;
    }
    return $res;
}

#-----------------------------------------------------------------

use SQLite::Work;
ok(1);

my $result;
my $rep = SQLite::Work->new(
    database=>'tfiles/test1.db',
    row_ids=>{episodes=>title_id},
);
ok($rep, "made object");
$result = $rep->do_connect();
ok($result, "connected to database");

my $test_count = 1;
my $text = '';
$result = $rep->do_report(
    table=>'episodes',
    sort_by=>[qw(category series_title season season_position title sub_title)],
    headers=>[
	'{$category}',
	'{$series_title}',
    ],
    limit=>20,
    page=>10,
    report_style=>'compact',
    outfile=>\$text,
);
ok($result, "($test_count) made report");
ok($text, "($test_count) report had content");

my $goodfile = "tfiles/test2.html";
my $fh;
open($fh, "<", $goodfile) or die "could not open $goodfile";
my $good_text = '';
{
    local $/;
    $good_text = <$fh>;
}
close($fh);
$result = compare_strings($text, $good_text);
ok($result, "($test_count) match content");
