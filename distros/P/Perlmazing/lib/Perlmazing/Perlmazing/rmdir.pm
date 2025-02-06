use Perlmazing qw(croak dir devnull);
use File::Path qw();
use IPC::Cmd qw();

my $checked;
my $can_run_rm;
my $on_win32;

sub main {
  if (not $checked) {
    $on_win32 = ($^O eq 'MSWin32' or $^O eq 'WinNT');
    $can_run_rm = IPC::Cmd::can_run('rm');
    $checked++;
  }
  my $path = shift || $_;
  
  # Let's have it behave as expected when the directory doesn't exist
  return CORE::rmdir($path) unless -d $path;
  
  # Why am I doing this? After using a previous implementation for a while
  # and trying many others from CPAN, all of them had a common problem:
  # it takes them 20 or more times to delete a big directory, compared to
  # the native OS tools to remove a dir. So, we try that first.
  my $count = 0;
  # Hide messages printed out to console from commands. Errors should stay in $! only.
  my $devnull = devnull;
  my $stderr = '';
  my $stdout = '';
  {
    local *STDERR;
    local *STDOUT;
    open STDERR, '>>', \$stderr;
    open STDOUT, '>>', \$stdout;
    if ($on_win32 or $can_run_rm) {
      # We can't return the actual number of deleted items (without verifying and taking time) this way. Just 1 for the directory.
      if ($on_win32) {
        unless (system qq[rmdir /S /Q "$path" >$devnull 2>&1]) {
          $count = 1;
        }
      }
      # Not win32, but can rm:
      # Also, some times, rm is present on win32, and some times, it succeeds to delete files that for some reason rmdir fails to delete.
      # In such case, this won't take a noticeable extra time to try:
      if (!$count) {
        unless (system qq[$can_run_rm -rf "$path" >$devnull 2>&1]) {
          $count = 1;
        }
      }
    }
    # If the previous steps didn't seem to work, we try the portable but slow Perl solution:
    unless ($count) {
      $count += eval {
        File::Path::remove_tree($path);
      };
    }
  }
  # If the directory is gone, $count should never be 0
  if (!$count and not -d $path) {
    $count++;
  }
  $count;
}

1;
