package TestPath;

use strict;
use warnings;
use Env qw( @PATH );

our $WSL = 0;

if($^O eq 'linux')
{
  my $release = do {
    my $release_file = '/proc/sys/kernel/osrelease';
    open my $fh, '<', $release_file;
    my $data = <$fh>;
    close $fh;
    chomp $data;
    $data;
  };
  if($release =~ /-Microsoft$/)
  {
    $WSL = 1;
    @PATH = grep !m{^/mnt/[a-z]/}, @PATH;
  }
}


1;
