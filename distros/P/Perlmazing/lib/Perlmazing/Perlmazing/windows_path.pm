use Perlmazing qw(splitdir);
our @ISA = qw(Perlmazing::Listable);
require File::Spec::Win32;

sub main {
  $_[0] = length($_[0]) ? File::Spec::Win32->catdir(splitdir $_[0]) : File::Spec::Win32->catdir('.');
}

1;