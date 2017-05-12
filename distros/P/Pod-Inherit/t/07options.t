#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use Test::More 'no_plan';
use Test::Differences;
#use Test::NoWarnings;
use Test::Pod;
use Path::Class::Dir;

use_ok('Pod::Inherit');

use lib 't/lib';

## Remove all existing/old pod files in t/doc
my $dir = Path::Class::Dir->new('t/output/options');
$dir->rmtree;
$dir->mkpath;

## Run over entire t/lib dir, now with a bunch of options
my $pi = Pod::Inherit->new({
  input_files      => ["t/lib/"],
  out_dir          => $dir,
  skip_underscored => 0,
  class_map        => {
    'InlineBaseConfig'  => 'InlineSubConfig',
    'OverloadBaseClass' => 'OverloadSubClass',
  },
  skip_classes    => [
    't/lib/OverrideDoubleSubClass.pm',
    'OverrideSubClass',
    't/lib/Deep',
  ],
  skip_inherits   => 'SimpleBaseClass',
  force_inherits  => {
    't/lib/MooseSub.pod' => 'Deep::Name::Space::Sub',
    'ClassC3Sub' => [
      'Deep::Name::Space::Base',
      'InlineBaseConfig'
    ]
  },
  method_format   => 'L<%m|%c/%m>'
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
@todo = "t/baseline/options";
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

$dir->rmtree;
