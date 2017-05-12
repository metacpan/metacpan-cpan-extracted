use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::XLSX ':all';
use Test::Number::Delta relative => 0.00001;
use PDL::DateTime;
use Config;

ok(-f 't/_sample4.xlsx');
ok(-f 't/_sample5.xlsx');

my ($Date, $Open, $High, $Low, $Close, $Volume, $AdjClose) = rxlsx1D('t/_sample4.xlsx', { header=>1 });
is(ref $Date, 'PDL::DateTime');
is($Date->info, 'PDL::DateTime: LongLong D [124]');
is($Date->hdr->{col_name}, 'Date');
is($Date->min,   1252627200000000);
is($Date->max,   1268179200000000);
is($Date->sum, 156283344000000000);

wxlsx1D(sequence(3)+0.5, ones(3), PDL::DateTime->new_sequence('2015-12-12', 3, 'day'), \my $out1);
ok($out1);

wxlsx1D(sequence(3)+0.5, ones(3)+0.5, PDL::DateTime->new_sequence('1955-12-12 23:23:55.123999', 3, 'minute'), \my $out2, { header=>'auto' });
ok($out2);

my $x = sequence(3)+0.5; $x->hdr->{col_name} = 'col x';
my $y = ones(3)+0.5; # without col_name
my $z = PDL::DateTime->new_sequence('1955-12-12 23:23:55.123999', 3, 'minute'); $z->hdr->{col_name} = 'col z';
wxlsx1D($x, $y, $z, \my $out3, { header=>'auto' });
ok($out3);

my ($px, $py, $pz) = rxlsx1D("t/_sample5.xlsx");
is($px->info, "PDL: Double D [3]");
is($py->info, "PDL: Double D [3]");
is($pz->info, "PDL::DateTime: LongLong D [3]");
is("$px", "[0.5 1.5 2.5]");
is("$py", "[1.5 1.5 1.5]");
is("$pz", "[ 1955-12-12T23:23:55.123 1955-12-12T23:24:55.123 1955-12-12T23:25:55.123 ]");
is($px->hdr->{col_name}, "col x");
is($py->hdr->{col_name}, undef);
is($pz->hdr->{col_name}, "col z");

done_testing;