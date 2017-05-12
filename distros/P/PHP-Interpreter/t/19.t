#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 14;

BEGIN {
    diag "Testing Output Buffering";
    use_ok 'PHP::Interpreter' or die;
}

my $output;
my $data;
ok my $p = PHP::Interpreter->new({
    'BRIC' => { 'special' => 'data', },
    'OUTPUT' => \$output
}), "Create new PHP interpreter";
$p->eval(q/print $BRIC['special'];/);
is $output, 'data', 'check output buffering (scalar pass by ref)';
$p->eval(q/print $BRIC['special'];/);
is $output, 'datadata', 'check output buffering accumulation (scalar pass by ref)';
is $p->get_output, 'datadata', 'check output buffer accessor';
$p->clear_output;
is $output, '', 'check output buffering was cleared (scalar pass by ref)';
$p->eval(q/print $BRIC['special'];/);
is $output, 'data', 'check output buffering, post-clearing (scalar pass by ref)';
$p->clear_output;
$p->eval(q/print $BRIC['special'];/);
is $output, 'data', 'check output buffering (scalar pass by ref 2)';
$p->eval(q/print $BRIC['special'];/);
is $output, 'datadata', 'check output buffering accumulation (scalar pass by ref 2)';
is $p->get_output, 'datadata', 'check output buffer accessor 2';
$p->clear_output;
is $output, '', 'check output buffering was cleared (scalar pass by ref 2)';
$p->eval(q/print $BRIC['special'];/);
is $output, 'data', 'check output buffering, post-clearing (scalar pass by ref 2)';
ok $p->set_output_handler(\&pr), "change output handler";

my $output2;
sub pr { $output2 .= $_[0]; }
$p->eval(q/print $BRIC['special'];/);
is $output2, 'data', 'check output buffering (callback)';

