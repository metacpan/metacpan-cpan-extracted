use Test2::Bundle::Extended;
use Proc::tored::Types -all;
use Path::Tiny 'path';

subtest 'NonEmptyStr' => sub {
  ok is_NonEmptyStr("foo"), 'alpha';
  ok is_NonEmptyStr("123"), 'numeric';
  ok !is_NonEmptyStr(""), '0-length';
  ok !is_NonEmptyStr(" "), 'single space';
  ok !is_NonEmptyStr("\n"), 'newline';
  ok !is_NonEmptyStr(" \n \f \r\t    "), 'multi whitespace';
};

subtest 'Dir' => sub {
  my $path = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
  my $dir  = "$path";

  SKIP: {
    skip 'could not create temp dir' unless -w $dir;
    ok is_Dir($dir), 'dir';
    undef $path;
  };

  ok !is_Dir($dir), 'rmdir';
};

subtest 'SignalList' => sub {
  subtest 'non-mswin32' => sub {
    local $^O = 'Not MSWin32';
    ok is_SignalList([qw(INT TERM HUP PIPE)]), 'signal list';
    ok is_SignalList([]), 'empty list';
    ok !is_SignalList('INT TERM HUP PIPE'), 'string';
  };

  subtest 'mswin32' => sub {
    local $^O = 'MSWin32';
    ok !is_SignalList([qw(INT TERM HUP PIPE)]), 'signal list';
    ok is_SignalList([]), 'empty list';
  }
};

done_testing;
