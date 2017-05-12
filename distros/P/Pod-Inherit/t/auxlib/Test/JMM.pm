package Test::JMM;
use warnings;
use strict;
use Module::CoreList;

sub has_module {
  # Modname is the actual name of the module: Class::C3.
  # Shortname is what gets stuck in env vars: C3.
  my ($modname, $shortname) = @_;
  $shortname ||= $modname;
  my $envvar = "TEST_JMM_HAS_".uc($shortname);
  if (exists $ENV{$envvar}) {
    return $ENV{$envvar};
  }
  if (eval "require $modname; 1") {
    return 1;
  } else {
    return 0;
  }
}

sub has_moose {
  has_module('Moose');
}

sub has_c3 {
  has_module('Class::C3', 'C3');
}

sub import {
  if ($ENV{TRACK_MODULES}) {
    print STDERR "# Doing Test::JMM::import\n";
    unshift @INC, sub {
      my ($self, $mod_as_filename) = @_;
      my $modname = $mod_as_filename;
      $modname =~ s!/!::!g;
      $modname =~ s/\.pm$//;
      my $filename;
      my $line;
      my $callerlevel = 0;
      while (1) {
        (my $package, $filename, $line) = caller($callerlevel);
        # print STDERR "# Test::JMM::(\@INC hook) at $callerlevel: $package, $filename, $line\n";
        $callerlevel++;
        next if $filename =~ /^\(eval/;
        next if $package eq 'Test::JMM';
        next if $package eq 'base';
        last;
      }
      my $kind;
      if ($filename =~ m/\bblib\b/) {
        $kind = 'runtime';
        # print STDERR "# In blib -- assuming runtime dependency of thing under test\n";
      } elsif ($filename =~ m!^t\b!) {
        $kind = 'test';
        # print STDERR "# In t/ -- assuming testing dependency.\n";
      } else {
        # print STDERR "# loading $mod_as_filename from $filename line $line - elsewhere?\n";
        return;
      }
      my $first_rel = Module::CoreList->first_release($modname);
      if ($first_rel and $first_rel <= 5.006) {
        # print STDERR "# ($modname is core as of $first_rel)\n";
        return ();
      }
      # print STDERR "# Attempting to find $mod_as_filename from $filename line $line for $kind\n";
      print STDERR "# INC hook: $kind: $mod_as_filename for $kind\n";
      return ();
    }
  }
}

1;

