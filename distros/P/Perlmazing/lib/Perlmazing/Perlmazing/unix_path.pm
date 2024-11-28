use Perlmazing qw(splitdir);
our @ISA = qw(Perlmazing::Listable);
require File::Spec::Unix;

sub main {
  $_[0] = length($_[0]) ? File::Spec::Unix->catdir(splitdir $_[0]) : File::Spec::Unix->catdir('.');
  # Fix possible UNC paths
  $_[0] =~ s/^\\\\(\w+)/\/\/$1/ if length $_[0];
}

1;