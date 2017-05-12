use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::Connector::Local;
use Object::Remote;
use Object::Remote::ModuleSender;

$ENV{PERL5LIB} = join(
  ':', ($ENV{PERL5LIB} ? $ENV{PERL5LIB} : ()), qw(lib)
);

my $ms = Object::Remote::ModuleSender->new(
  dir_list => [ 't/lib' ]
);

my $connection = Object::Remote::Connector::Local->new(
                   module_sender => $ms,
                 )->connect;

my $counter = Object::Remote->new(
  connection => $connection,
  class => 'ORTestClass'
);

isnt($$, $counter->pid, 'Different pid on the other side');

is($counter->counter, 0, 'Counter at 0');

is($counter->increment, 1, 'Increment to 1');

is($counter->counter, 1, 'Counter at 1');

done_testing;
