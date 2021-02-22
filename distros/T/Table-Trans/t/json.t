use warnings;
use strict;
use Table::Trans 'trans_to_json_file';
use Test::More;
use JSON::Parse 'json_file_to_perl';
use FindBin '$Bin';
my $in = "$Bin/test-trans.txt";
my $out = "$Bin/test-trans.json";
use utf8;

del_out ();
trans_to_json_file ($in, $out);
ok (-f $out, "File exists");
my $json = json_file_to_perl ($out);
is ($json->{monkey}->{ja}, '猿', "Got Japanese translation");
is ($json->{fruit}->{es}, 'Fruto', "Got Spanish translation");
del_out ();
done_testing ();
exit;

sub del_out
{
    if (-f $out) {
	unlink $out or die $!;
    }
}

