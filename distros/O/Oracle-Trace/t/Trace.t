#
# $Id: Trace.t,v 1.9 2003/12/24 20:38:54 oratrc Exp $
#

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

my $test = 'tracefiles/test.trc';

BEGIN { use_ok('Oracle::Trace') };

my $o_test = Oracle::Trace->new($test);
ok(ref($o_test), 'new')
	or diag("test: ".Dumper($o_test));

my $o_res = $o_test->parse;
ok($o_res eq $o_test, 'parse') 
	or diag("parsed: ".Dumper($o_res));

my ($s_hdr) = $o_test->header->value('Instance name');
ok($s_hdr eq 'RFI', 'header->value') 
	or diag("s_hdr($s_hdr)");

my $s_ftr = $o_test->footer->value('Instance name');
ok(!defined($s_ftr), 'footer->value') 
	or diag("s_ftr($s_ftr): ".Dumper($s_ftr));

my $i_cnt = my @a_cnt = $o_test->entries;
ok($i_cnt == 4, 'entries') 
	or diag("expected 4 entries (26 - (header + children)) got: $i_cnt");

my $rep = $o_test->test_report('string');
ok($rep =~ /entries:\s+\d+\n/msi, 'test_report')
	or diag("test_report: $rep");

my ($o_one) = $o_test->entries;

=pod
my ($s_one) = $o_one->values('type'=>'other');
ok($s_one =~ /alter session/, '$o_one->value("type"=>"other")')
	or diag("o_one($o_one) s_one($s_one)");

my ($s_stmt) = $o_one->statement;
ok($s_stmt eq $s_one, '$o_one->statment')
	or diag("s_one($s_one) s_stmt($s_stmt)");
=cut

# my ($h_stmt) = $o_test->header->statement;
# my ($f_stmt) = $o_test->footer->statement;

# done.
