#
# Test of PDF::ReportWriter::Report package
# Cosimo Streppone 2006-03-13
#
# $Id: 011_datasources.t 15 2006-03-27 16:50:11Z cosimo $

use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 10;

use_ok('PDF::ReportWriter::Report');

my $rp = PDF::ReportWriter::Report->new();
ok(defined $rp && ref($rp) eq 'PDF::ReportWriter::Report', 'blank report object created');

$rp = undef;
$rp = PDF::ReportWriter::Report->new('./t/reports/datasources.xml');
diag('$rp=' . (defined $rp ? $rp : 'undef'));
ok(defined $rp, 'loaded datasources example');

ok( $rp->load(), 'loaded xml config');
ok( $rp->config(), 'loaded xml config');

diag(Dumper($rp));

my $ds = $rp->data_sources();
ok( ref($ds) eq 'HASH' && keys %$ds, 'data sources loaded correctly');

ok( exists $ds->{detail}, 'checks on "detail" data source');
ok( ref $ds->{detail} eq 'HASH', 'checks on "detail" data source');
ok( $ds->{detail}->{type} eq 'DBI', 'checks on "detail" data source');
ok( $ds->{detail}->{sql} ne '', 'checks on "detail" data source');


