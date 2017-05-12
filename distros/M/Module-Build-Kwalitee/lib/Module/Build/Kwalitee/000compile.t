#!/usr/bin/perl
#
# Make sure we can "use" every module

use strict;
use warnings;
use Test::More;
use File::Find::Rule;

use constant CONCURRENCY => 5;

eval q/use Test::Builder; 1;/
  or plan skip_all => 'Necessary modules not installed';
  
my @classes = 
  map  { path_to_pkg($_) }
  grep { !/00\d[a-z]+.pm/ }
  File::Find::Rule->file()->name('*.pm')->in('lib');

my @scripts;
eval q{
  use Module::Build;
  Module::Build->current->script_files;
  @scripts = keys %{ Module::Build->current->script_files };
};

push @scripts, grep { !/\.svn\b/ and !/~$/ } File::Find::Rule
    ->file()					# find all files
    ->in('bin') if -d 'bin';			# ... but only if there's a bin/ dir

@scripts = 
  grep { _perl_shebang($_) }            # only check perl scripts.
  keys %{{ map { $_ => 1 } @scripts }}; # only check scripts once.

sub _perl_shebang {
  my $file = shift;
  open FILE, $file or die "Can't read $file: $!";
  return <FILE> =~ /^#!.*\bperl/;
}

plan skip_all => "No modules" unless scalar @classes + @scripts;
plan tests => scalar @classes + @scripts;

# We need to tweak the numbers of the tests

my %waits;
my $current = 0;
while (@classes or keys %waits) {
  while ($current < CONCURRENCY && (my $class = shift @classes)) {
    my $child = fork;
    if ($child) {
      $waits{$child} = $class;
      ++$current;
    }
    else {
      my $null;
      open $null, '>', \(my $str);
      my $test = Test::Builder->new;
      $test->output($null);

      # Ok, now exit. Veeery important, unless we want to drive the load on the
      # machine to, say, 788.55. That would be bad.

      exit !use_ok($class);
    }
  }
  if ($current) {
    my $pid = wait;
    --$current;
    ok(!$?, "use $waits{$pid}" );
  }
  else {
    last;
  }
}

use Config;
my $open3 = eval "use IPC::Open3; 1";
foreach my $script (@scripts) {
  my @lib = -d 'blib' ? '-Iblib/lib' : 
            -d 'lib'  ? '-Ilib'  : ();
  my @cmd = ($Config{perlpath}, "-c", @lib, $script);
  if ($open3) {
    my $pid = open3(my ($in, $out, undef), "@cmd");
    last if wait == -1;
    ok( ! $?, "@cmd" ) or do {
      read($out, my $error, 9999) or die "could not read from file: $!";
      diag $error;
    };
  } else {
    ok( ! system(@cmd), "@cmd" );
  }
}

sub path_to_pkg ($) {
  for (shift) {
    s|.*lib/||;
    s|/|::|g;
    s|\.pm$||;
    return $_;
  }
}

