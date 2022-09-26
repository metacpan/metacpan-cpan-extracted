use Mojo::Base -strict;
use Test::More;

use Mojar::Cron::Date;
use POSIX 'strftime';

plan skip_all => 'Only the linux platform is supported'
  unless $ENV{TEST_PLATFORM} or $^O eq 'linux';

my @dates = (
  ['1903-12-17', 4, 'First flight'],
  ['1929-10-29', 2, 'Black Tuesday'],
  ['1941-12-07', 7, 'Pearl Harbour'],
  ['1944-06-06', 2, 'D-Day'],
  ['1969-07-20', 7, 'Moon landing'],
  ['1970-01-01', 4, 'Epoch'],
  ['1970-03-02', 1, 'Mon'],
  ['2000-03-02', 4, 'Uncommon leap year'],
  ['2017-05-30', 2, 'Another Tuesday'],
);

subtest q{Sorting} => sub {
  my @raw    = map Mojar::Cron::Date->new($_->[0]), @dates;
  my @sorted = sort {$a cmp $b} @raw;
  is join('|', map $_->format('%d'), @sorted), '17|29|07|06|20|01|02|02|30', 'ascending';

  @sorted = sort {$b cmp $a} @raw;
  is join('|', map $_->format('%d'), @sorted), '30|02|02|01|20|06|07|29|17', 'descending';
};


subtest q{Day of the week} => sub {
  is(Mojar::Cron::Date->new($_->[0])->dow, $_->[1], $_->[2]) for @dates;
};

subtest sleeps => sub {
  my $x   = Mojar::Cron::Date->new($dates[0][0]);
  my $now = Mojar::Cron::Date->new('2017-05-30');
  is $x->sleeps($now), 41_438, 'Days since '. $dates[0][1];
};

sub _sft {
  return undef unless $_[0] =~ /^(\d{4})-(\d\d)-(\d\d)\b/;
  my $x = int(strftime('%s', 0, 0, 12, $3, $2 - 1, $1 - 1900)
      / 24 / 60 / 60);
  --$x if $_[0] lt '1970-01-01';
  $x;
}

subtest q{Epoch_days} => sub {
  is(Mojar::Cron::Date->new($_->[0])->epoch_days, _sft($_->[0]), $_->[2]) for @dates;
};

done_testing;
