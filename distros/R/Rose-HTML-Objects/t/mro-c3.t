#!/usr/bin/perl -w

use strict;

use Cwd qw(abs_path);
use Test::More; 
use File::Find;
use FindBin qw($Bin);
use lib "$Bin/../lib";

eval "use mro 'c3'";

plan(skip_all => 'mro 1.02 or later required for testing c3 class hierarchy')
  if($@ || $mro::VERSION < 1.02); 

plan(tests => 70);

my $dir = abs_path("$Bin/../lib");

find(sub 
{
  return  unless(/\.pm$/);
  my $path = $File::Find::name;
  my $package = $path;

  for($package)
  {
    s{^$dir/}{}o;
    s{\.pm$}{};
    s{/}{::}g;
  }

  my $subclass = "My::$package";

  my $pm_file = "$Bin/mro-test.pm";
  open(my $fh, '>', $pm_file) or die "Could not write '$pm_file' - $!";

  print $fh <<"EOF";
package $subclass;

use mro 'c3';

use base '$package';

sub init
{
  my(\$self) = shift;
  \$self->next::method(\@_);
}

1;
EOF

  close($fh) or die "Could not write '$pm_file' - $!";

  my $pl_file = "$Bin/mro-test.pl";
  open($fh, '>', $pl_file) or die "Could not write '$pl_file' - $!";

  print $fh <<"EOF";
use lib qq($Bin);

require qq($pl_file);

eval
{
  if($subclass->can('name'))
  {
    $subclass->new(name => 'abc');
  }
  else
  {
    $subclass->new;
  }
};

exit(\$@ ? 1 : 0);
EOF

  close($fh) or die "Could not write '$pm_file' - $!";

  system($^X, $pl_file);

  ok(($! == -1 || ($? >> 8) != 0), $package);

  foreach my $file ($pl_file, $pm_file)
  {
    unlink($file) or die "Could not unlink($file) - $!";
  }
},
$dir);
