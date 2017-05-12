use strict;
use warnings;
use FindBin;
use Test::More tests => 1;
use Module::CPANTS::Kwalitee;

my %names = map {$_ => 1} Module::CPANTS::Kwalitee->new->all_indicator_names;
my %files = map {$_ => 1} glob "$FindBin::Bin/kwalitee/*.t";

my @errors;
for (keys %names) {
  my $file = "$FindBin::Bin/kwalitee/$_.t";
  if (exists $files{$file}) {
    delete $files{$file};
  } else {
    push @errors, "$file is missing";
  }
}
push @errors, "$_ is obsolete" for keys %files;

ok !@errors, "no errors" or diag join "\n", @errors;
