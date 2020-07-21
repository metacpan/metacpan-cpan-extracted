use strict;
use warnings;
use File::Spec;

# this script requires administrator privileges

warn "this script requires admin privileges, which you don't appear to have"
  unless eval { require Win32; Win32::IsAdminUser() };

my @list = map { chomp; [split /\t/]->[1] } grep /^120000/, `git ls-files -s `;

foreach my $link (@list)
{
  # in case we ran this before
  system "git checkout $link";

  my $target = do { open my $fh, '<', $link; local $/; <$fh> };
  unlink $link;

  my $cmd = "mklink " . File::Spec->catfile($link) . " " . File::Spec->catfile($target);
  print "> $cmd\n";
  system $cmd;

  if($?)
  {
    warn "failed";
    # revert on failure
    system "git checkout $link";
    next;
  }

  # ignore change so that it won't be committed back
  print "> git update-index --assume-unchanged $link\n";
  system 'git', 'update-index', '--assume-unchanged', $link;
}

print "press <ENTER> to continue.\n";
<STDIN>;
