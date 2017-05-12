use strict;
use warnings;

use Test::More;
use DBI;
use PDL;
use PDL::IO::DBI ':all';
use Test::Number::Delta relative => 0.000_000_000_000_1;
use Config;

plan skip_all => "DBD::SQLite not installed" unless eval { require DBD::SQLite } ;

use constant NO64BITINT => $Config{ivsize} < 8 ? 1 : 0;
use constant NODATETIME => eval { require PDL::DateTime; require Time::Moment; 1 } ? 0 : 1;
diag "No support for 64bitint - some tests will be skipped" if NO64BITINT;

my $db = "temp.db";
unlink($db) or die "unlink($db): $!" if -f $db;
my $dsn = "dbi:SQLite:dbname=$db";

# populate database, first column are integers 1 .. $n, second column are squared integers
my $N = 30;
{
  my $dbh = DBI->connect($dsn);
  $dbh->do('CREATE TABLE tab (
                c1 INT,
                c2 INT
            )');
  $dbh->do('INSERT INTO tab VALUES (?, ?)', undef, $_, $_*$_) for 1 .. $N;
  $dbh->disconnect;
}

#
note 'retrieve all rows at once';
{
  my ($p, $q, $r) = rdbi1D($dsn, "SELECT * FROM tab");
  is($r, undef, 'only 2 columns');
  cmp_ok($p->nelem, '==', $N, 'N rows for column 1');
  cmp_ok($q->nelem, '==', $N, 'N rows for column 2');
  delta_ok($p->sum, $N*($N + 1)/2, 'sum of column 1');
  delta_ok($q->sum, $N*($N + 1)*(2*$N + 1)/6, 'sum of column 2');
}

#
note 'retrieve chunk by chunk';
{
  my $sth;
  my $chunk = 5;
  my $former_sum = 0;
  my $former_sum2 = 0;
  my $n;
  for ($n = $chunk; $n <= $N; $n += $chunk) {
    note "rows from last point up to $n";
    my ($p, $q, $r) = rdbi1D($dsn, "SELECT * FROM tab", { fetch_chunk => $chunk, reuse_sth => \$sth });
    last unless $sth;
    is($r, undef, 'only 2 columns');
    cmp_ok($p->nelem, '==', $q->nelem, 'equal number of rows');
    cmp_ok($p->nelem, '<=', $chunk, 'not more than $chunk rows at a time');
    my $sum = $n*($n + 1)/2;
    my $sum2 = $n*($n + 1)*(2*$n + 1)/6;
    delta_ok($p->sum, $sum - $former_sum, '(partial) sum of column 1');
    delta_ok($q->sum, $sum2 - $former_sum2, '(partial) sum of column 2');
    $former_sum = $sum;
    $former_sum2 = $sum2;
  }
}

#
note 'test normal use case as recommended in the documentation';
{
  cmp_ok $N % 5, '==', 0;
  cmp_ok $N % 11, '!=', 0;
  # try the test with two different sizes
  # $N should be divisible by one size but not the other; this allows us to
  # test the case where the last chunk is partially filled, or completely empty
  for my $chunk_size (5, 11) {
    my ($minimum, $maximum);
    my $sth;
    while (1) {
      my ($values) = rdbi1D($dsn, "SELECT c1 FROM tab", { reuse_sth => \$sth, fetch_chunk => $chunk_size, reshape_inc => $chunk_size });
      last unless $sth;
      if (!defined($minimum) || $values->minimum->sclr < $minimum) { $minimum = $values->minimum->sclr }
      if (!defined($maximum) || $values->maximum->sclr > $maximum) { $maximum = $values->maximum->sclr }
    }
    cmp_ok $minimum, '==', 1, 'minimum';
    cmp_ok $maximum, '==', $N, 'maximum';
  }
}

#
note 'test option guessing/setting';
{
  # temporarily wrap _proc_args to inspect its return values (options, in
  # particular)
  local *old_func = \&PDL::IO::DBI::_proc_args;
  my %opt;
  my $name = 'PDL::IO::DBI::_proc_args';
  {
    no strict 'refs';
    no warnings 'redefine';
    *$name = sub {
      my @ret = &old_func(@_);
      %opt = %{$ret[-1]}; # last arg is hash with options
      return @ret;
    };
  }
  my ($values);
  ($values) = do { rdbi1D($dsn, "SELECT c1 FROM tab", {reuse_sth => \my $sth, fetch_chunk => 11_000}) };
  cmp_ok $opt{fetch_chunk}, '==', 11_000;
  cmp_ok $opt{reshape_inc}, '==', 11_000, 'reshape_inc set to same size as fetch_chunk';
  ($values) = do { rdbi1D($dsn, "SELECT c1 FROM tab", {reuse_sth => \my $sth, fetch_chunk => 11_000, reshape_inc => 13_000}) };
  cmp_ok $opt{fetch_chunk}, '==', 11_000;
  cmp_ok $opt{reshape_inc}, '==', 13_000, '... unless the user sets reshape_inc to something else';
  ($values) = do { rdbi1D($dsn, "SELECT c1 FROM tab", {reuse_sth => \my $sth, fetch_chunk => 11_000, reshape_inc => 3_000}) };
  cmp_ok $opt{fetch_chunk}, '==', 11_000;
  cmp_ok $opt{reshape_inc}, '==', 11_000, '... and reshape_inc is not less than fetch_chunk';
  {
    no strict 'refs';
    no warnings 'redefine';
    *$name = \&old_func;
  }
}

#
note 'the documentation says rdbi2D does not support reuse_sth, so check this';
{
  my $sth;
  my $r = eval { rdbi2D($dsn, "SELECT * FROM tab", { reuse_sth => \$sth }); 1 };
  is($r, undef, 'not supported for rdbi2D yet');
}

unlink($db);

done_testing;
