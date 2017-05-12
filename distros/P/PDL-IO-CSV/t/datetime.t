use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::CSV ':all';
use Test::Number::Delta relative => 0.00001;
use Config;

use constant NODATETIME => eval { require PDL::DateTime; require Time::Moment; 1 } ? 0 : 1;

ok(-f 't/_sample4.csv');

if (NODATETIME) {
  diag "SKIP - PDL::DateTime not installed";
}
else {
  # http://ichart.finance.yahoo.com/table.csv?a=8&b=11&e=10&g=d&c=2009&d=2&f=2010&s=YHOO
  my ($Date, $Open, $High, $Low, $Close, $Volume, $AdjClose) = rcsv1D('t/_sample4.csv', { header=>1 });
  is(ref $Date, 'PDL::DateTime');
  is($Date->info, 'PDL::DateTime: LongLong D [124]');
  is($Date->hdr->{col_name}, 'Date');
  is($Date->min,   1252627200000000);
  is($Date->max,   1268179200000000);
  is($Date->sum, 156283344000000000);

  wcsv1D(sequence(3)+0.5, ones(3), PDL::DateTime->new_sequence('2015-12-12', 3, 'day'), \my $out1);
  is($out1, <<'MARKER');
0.5,1,2015-12-12
1.5,1,2015-12-13
2.5,1,2015-12-14
MARKER

  wcsv1D(sequence(3)+0.5, ones(3)+0.5, PDL::DateTime->new_sequence('1955-12-12 23:23:55.123999', 3, 'minute'), \my $out2, { header=>'auto' });
  is($out2, <<'MARKER');
0.5,1.5,1955-12-12T23:23:55.123999
1.5,1.5,1955-12-12T23:24:55.123999
2.5,1.5,1955-12-12T23:25:55.123999
MARKER

  my $x = sequence(3)+0.5; $x->hdr->{col_name} = 'col x';
  my $y = ones(3)+0.5; # without col_name
  my $z = PDL::DateTime->new_sequence('1955-12-12 23:23:55.123999', 3, 'minute'); $z->hdr->{col_name} = 'col z';
  wcsv1D($x, $y, $z, \my $out3, { header=>'auto' });
  is($out3, <<'MARKER');
"col x",,"col z"
0.5,1.5,1955-12-12T23:23:55.123999
1.5,1.5,1955-12-12T23:24:55.123999
2.5,1.5,1955-12-12T23:25:55.123999
MARKER

  my ($px, $py, $pz) = rcsv1D(\<<'MARKER');
"col x",,"col z"
0.5,1.5,1955-12-12T23:23:55.123999
1.5,1.5,1955-12-12T23:24:55.123999
2.5,1.5,1955-12-12T23:25:55.123999
MARKER

  is("$px", "[0.5 1.5 2.5]");
  is("$py", "[1.5 1.5 1.5]");
  is("$pz", "[ 1955-12-12T23:23:55.123999 1955-12-12T23:24:55.123999 1955-12-12T23:25:55.123999 ]");
  is($px->hdr->{col_name}, "col x");
  is($py->hdr->{col_name}, undef);
  is($pz->hdr->{col_name}, "col z");

  {
    my ($px, $py) = rcsv1D(\<<'MARKER', { header=>'auto', detect_datetime=>'%m/%d/%Y' });
Date,Adj Close
3/31/1993,1.13
4/1/1993,1.15
5/3/1993,1.43
MARKER

    is("$py", "[1.13 1.15 1.43]");
    is("$px", "[ 1993-03-31 1993-04-01 1993-05-03 ]");
  
  }
  {
    my ($px, $py) = rcsv1D(\<<'MARKER', { type =>[ '%m/%d/%Y', double ] });
Date,Adj Close
3/31/1993,1.13
4/1/1993,1.15
5/3/1993,1.43
MARKER

    is("$py", "[1.13 1.15 1.43]");
    is("$px", "[ 1993-03-31 1993-04-01 1993-05-03 ]");
  
  }

}

done_testing;