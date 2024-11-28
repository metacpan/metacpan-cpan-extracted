use Perlmazing qw(croak dir);
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
  if ($on_win32 or $can_run_rm) {
    # We can't return the actual number of deleted items this way. Just 1 for the directory.
    my $dir_count = 0;
    if ($on_win32) {
      system('cmd.exe', '/c', 'rmdir', '/S', '/Q', $path) || $count++;
    } else {
      system($can_run_rm, '-rf', $path) || $count++;
    }
  }
  # If the previous steps didn't seem to work, we try the portable but slow Perl solution:
  unless ($count) {
    # Again, returning just 1 for consistency
    $count++ if File::Path::remove_tree($path);
  }
  $count;
}

1;
