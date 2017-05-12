package Net::DNSServer::ConfParser;

# $Id: ConfParser.pm,v 1.1 2001/05/24 04:46:01 rob Exp $
# This module is only used to load and parse configuration files.

use strict;
use IO::File;
use Carp qw(croak);

sub load_configuration {
  my $self = shift;
  unless ($self &&
          $self -> {opts_callback} &&
          $self -> {zone_callback} &&
          $self -> {conf_file}) {
    croak 'Usage> '.(__PACKAGE__).'::load_configuration {opts_callback => sub { ... }, zone_callback => sub { ... },conf_file => \$conf_file}';
  }

  my $opts_callback = $self -> {opts_callback};
  my $zone_callback = $self -> {zone_callback};
  my $conf_file;
  # Taint clean conf_file
  if ($self->{conf_file} =~ m%^([\w\-/\.]+)%) {
    $conf_file = $1;
  } else {
    croak "Dangerous looking configuration [$self->{conf_file}]";
  }

  my $io = new IO::File $conf_file, "r";
  croak "Could not open [$conf_file]" unless $io;
  my $CONTENTS = "";
  # Slurp entire contents into memory for fast parsing
  while ($io->read($CONTENTS,4096,length $CONTENTS)) {};
  $io->close();

  print STDERR "DEBUG: Removing comments...\n";
  $CONTENTS=~s%/\*[\s\S]*?\*/%%gm;  # remove /* comments */
  $CONTENTS=~s%//.*$%%gm;           # remove // comments
  $CONTENTS=~s%\#.*$%%gm;           # remove #  comments
  my %zone=();
  print STDERR "DEBUG: Scanning CONTENTS...\n";
  while ($CONTENTS=~/[^{}]*?(\w+.*{[^{}]*(?:{[^{}]*}[^{}]*)*};)/g) {
    my $entry=$1;
#    print STDERR "DEBUG: entry[$entry]\n";
    if ($entry=~s/^\s*(\w+)\s//) {
      my $tag=$1;
      if ($tag=~/options/i &&
          $entry=~s%^\{(.*)\};$%$1%s) {
        print STDERR "Reading options ...\n";
        while ($entry=~m%\s*([\w\-]+)\s+([^{};]*?(?:{[^{}]*}[^{};]*?)*);%g) {
          print STDERR " -- Field=[$1] Value=[$2]\n";
          &{$opts_callback}($1,$2);
        }
      } elsif ($tag=~/zone/i &&
               $entry=~s/^\s*"*([\w\-\.]+)"*\s*([A-Z]*)\s+\{(.*)\};$/$3/s) {
        my $this_zone=$1;
        my $this_class=$2 || "IN";
        print STDERR "Reading zone[$this_zone] class[$this_class] ...\n";
        while ($entry=~m%\s*([\w\-]+)\s+([^{};]*?(?:{[^{}]*}[^{};]*?)*);%g) {
          print STDERR " -- Field=[$1] Value=[$2]\n";
          &{$zone_callback}($this_zone,$this_class,$1,$2);
        }
      } else {
        print STDERR "Unimplemented tag [$tag] for entry:$entry\n";
      }
    } else {
      print STDERR "Unrecognized syntax: $entry\n";
    }
  }

  return 1;
}

1;
