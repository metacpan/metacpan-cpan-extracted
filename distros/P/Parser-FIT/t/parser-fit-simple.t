use Test::More;
use FindBin;
use Parser::FIT::Simple;

my $simple = Parser::FIT::Simple->new();

my $result = $simple->parse($FindBin::Bin . "/test-files/activity_multisport.fit");

is(scalar @{$result->{record}}, 78, "expected number of records");
is("activity,device_info,event,file_id,lap,record,session", join(",", sort keys %$result), "expected message types");

done_testing;