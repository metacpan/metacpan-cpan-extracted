#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use Test::More 'no_plan';
use Test::Differences;
use Test::NoWarnings;
use Test::Pod;
use Path::Class::Dir;

use_ok('Pod::Inherit');

use lib 't/lib';

## Remove all existing/old pod files in t/doc
my $dir = Path::Class::Dir->new('t/output/files');
$dir->rmtree;
$dir->mkpath;

## Run over entire t/lib dir
my $pi = Pod::Inherit->new({
                            input_files => ["t/lib/"],
                            out_dir => $dir,
                           });

isa_ok($pi, 'Pod::Inherit');
$pi->write_pod();

sub check_file {
  my ($outfile) = @_;
  (my $blfile = $outfile) =~ s!output!baseline!;

  eq_or_diff(do {local (@ARGV, $/) = $outfile; scalar <> || 'NO OUTPUT?'},
             do {local (@ARGV, $/) = $blfile;  scalar <> || 'NO BASELINE'},
             "Running on directory: $outfile");
  pod_file_ok($outfile, "Running on directory: $outfile - Test::Pod");
}

# Check that for each output file, it matches the baseline file...
my @todo = $dir;
while (@todo) {
  $_ = shift @todo;
  if (-d $_) {
    push @todo, glob("$_/*");
  } else {
    check_file($_);
  }
}

# ...and for each baseline file, there is a corresponding output file.
@todo = "t/baseline/files";
while (@todo) {
  $_ = shift @todo;
  if (/~$/) {
    # Skip editor backup files, eh?
  } elsif (/\.was$/) {
    # ...and byhand backup files.
  } elsif (-d $_) {
    push @todo, glob("$_/*");
  } else {
    (my $outfile = $_) =~ s!baseline!output!;
    ok(-e $outfile, "baseline file $_ has matching output");
  }
}

## test lack of foo.txt in output dir


# foreach my $outfile (<t/output/files/*.pod>) {
#   my $origfile = Path::Class::Dir->new("t/baseline")->file(Path::Class::File->new($outfile)->basename);

#   eq_or_diff( do { local (@ARGV, $/) = "$outfile"; scalar <> },
#               do { local (@ARGV, $/) = "$origfile"; scalar <> },
#               "Running on directory: $outfile - matches");

#   pod_file_ok("$outfile", "Running on directory: $outfile - Test::Pod passes");
# }

# ## should we do this with no out_dir as well?

$dir->rmtree;
