use Test::More;
use Search::QS;
use File::Basename;
use lib dirname (__FILE__);
use URLEncode;


my $num = 0;

my $sqs = new Search::QS;

isa_ok($sqs->options, 'Search::QS::Options');
$num++;

is($sqs->options->to_qs , '', "Empty options");
$num++;


my $qs = 'start=5';
&test_qs($qs,"Check start options....");
$qs = 'start=5&limit=8';
&test_qs($qs,"add limit....");
$qs = 'start=5&limit=8&sort[name]=asc';
&test_qs($qs,"add one sort....");
$qs = 'start=5&limit=8&sort[name]=asc&sort[type]=desc';
&test_qs($qs,"another sort....");

done_testing($num);

sub test_qs() {
    my $qs = shift;
    my $descr = shift;
    my $struct = url_params_mixed($qs);
    $sqs->options->parse($struct);
    is($sqs->options->to_qs, $qs, $descr);
    $num++;
}
