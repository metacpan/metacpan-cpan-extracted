use common::sense;
use Test::More;

my @tests = (
  sub {
    use_ok('Rhetoric');
  },
  sub {
    use_ok('Rhetoric::Formatters');
  },
  sub {
    use_ok('Rhetoric::Storage::File');
  },
);

plan tests => scalar(@tests);
$_->() for (@tests);
