use Mojo::Base -strict;

use Mojo::JSON qw(encode_json);

unless ($ENV{TEST_ONLINE}) {
  say STDERR 'set TEST_ONLINE to run this';
  exit 1;
}

require Mojo::PgX::Cursor;;

my $pg = Mojo::PgX::Cursor->new($ENV{TEST_ONLINE});
my $db = $pg->db;
my $results = eval { $db->query('select count(*) from perf_test') };
unless ($results) {
  say STDERR 'creating large table...';
  $db->query(
    'create table if not exists perf_test (
    id   serial primary key,
    name text,
    jdoc jsonb
    )'
  );

  my $tx = $db->begin;
  my @rows = (
    ['foo', encode_json { value => $_ }],
    ['bar', encode_json { value => $_ }],
  );
  for (1..100_000) {
    for (@rows) {
      $tx->db->query('insert into perf_test (name, jdoc) values (?, ?)', $_->[0], $_->[1]);
    }
  }
  $tx->commit;
  say STDERR 'starting tests...';
}

use Time::HiRes qw(nanosleep time);
for my $rows (reverse (1, 10, 100, 1000, 10000)) {
  my $start = time;
  my $cursor = $db->cursor('select * from perf_test');
  $cursor->rows($rows);
  while (my $row = $cursor->hash) {
    nanosleep 10;
  }
  my $elapsed = time - $start;
  say sprintf 'Blocked for %6.3f seconds (%4.1f%%) with rows = %5d',
    $cursor->seconds_blocked, ($cursor->seconds_blocked / $elapsed * 100), $rows;
  $cursor->wait;
}
