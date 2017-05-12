#
# Test of PDF::ReportWriter::Report package
# Cosimo Streppone 2006-03-13
#
# $Id: 010_report.t 15 2006-03-27 16:50:11Z cosimo $

use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 13;

use_ok('PDF::ReportWriter::Report');

my $rp = PDF::ReportWriter::Report->new();
ok(defined $rp && ref($rp) eq 'PDF::ReportWriter::Report', 'blank report object created');

$rp = undef;
$rp = PDF::ReportWriter::Report->new('./nonexistent.xml');
diag('$rp=' . (defined $rp ? $rp : 'undef'));
ok(! defined $rp, 'can\'t load non existent xml report file');

$rp = undef;
$rp = PDF::ReportWriter::Report->new('./t/reports/basic.xml');
diag('$rp=' . (defined $rp ? $rp : 'undef'));
ok($rp, 'loaded basic xml report file');

# Try load()ing the basic xml report file
my $cfg;
eval {
    $cfg = $rp->load();
};
diag('load $@='.$@) if $@;
ok(ref($cfg) eq 'HASH', 'data structure loaded');

diag(Dumper($cfg));

# Again, try load()ing the sample report file
$rp = PDF::ReportWriter::Report->new('./t/reports/sample.xml');
ok($rp, 'opened report object');
eval {
    $cfg = $rp->load();
};
diag('load $@='.$@) if $@;
ok(ref($cfg) eq 'HASH', 'data structure loaded');

diag(Dumper($cfg));

# Test of save() method
ok( $rp->save($cfg, './t/reports/sample_out.xml'), 'report saved');

# Now try to reopen the file and compare the two structures
my $rp2 = PDF::ReportWriter::Report->new('./t/reports/sample_out.xml');
ok($rp2, 'opened output xml report');
my $cfg2;
eval {
    $cfg2 = $rp2->load();
};
diag('load $@='.$@) if $@;
ok(ref($cfg2) eq 'HASH', 'data structure loaded');

diag(Dumper($cfg2));

is_deeply($cfg, $cfg2, 'compare data structures after (de)serialization cycle');

# Try to open an empty report xml file
undef $rp2;
undef $cfg2;
$rp = PDF::ReportWriter::Report->new();
ok($rp, 'created new report object');
eval {
    $cfg = $rp->load('./t/reports/empty.xml');
};
ok(! $@ && ref($cfg) eq 'HASH', 'empty report loaded (but is empty)');
diag(Dumper($cfg));
