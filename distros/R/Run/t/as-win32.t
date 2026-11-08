# Every other test file again with RUN_AS_WIN32=1 ($Run::AsWin32): the Win32 code paths on Unix, where FD_CLOEXEC
# stands in for the handle's inheritance (all but the Win32API::File calls run).  One test per file; on Win32 the
# files run so anyway.
use strict; use warnings;
use Test::More;
use File::Basename qw(basename dirname);
use TAP::Parser;
plan skip_all => 'on Win32 these code paths are the default' if $^O eq 'MSWin32';
my @files = grep basename($_) !~ /^(?:as-win32|win32)\.t\z/, sort glob(dirname(__FILE__) . '/*.t');   # (win32.t sets it itself)
my @I = map "-I$_", grep !ref, @INC;
local $ENV{RUN_AS_WIN32} = 1;
is `$^X @I -MRun -e "print \$Run::AsWin32 ? 1 : 0"`, 1, 'RUN_AS_WIN32=1 sets $Run::AsWin32';
for my $f (@files) {
  my $p = TAP::Parser->new({ source => $f, switches => \@I, merge => 1 });   # (its STDERR shown only if it fails)
  my (@bad, @other);
  while (my $r = $p->next) {
    push @bad, $r->as_string if $r->is_test && !$r->is_ok;
    push @other, $r->as_string if $r->is_unknown || $r->is_comment }
  ok !$p->has_problems, basename($f) . ' with $Run::AsWin32'
    or diag join "\n", @bad, @other, 'tests run: ' . $p->tests_run . ', planned: ' . ($p->tests_planned // 'none') . ', exit: ' . ($p->exit // '?');
}
done_testing;
