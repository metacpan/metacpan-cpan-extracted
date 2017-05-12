#!/usr/bin/env perl

use strict;
use warnings;
use IO::All;

sub with_file (&) {
  my ($code) = @_;
  my $fname = $_;
  my $data < io($fname);
  {
    local $_ = $data;
    $code->();
    $data = $_;
  }
  $data > io($fname);
}

sub with_class_or_role_block (&) {
  my ($code) = @_;
  $_ =~ s{^(class|role)\s*(.*?)which\s*{(.*?)^};}
         {
           local *_ = { type => $1, header => $2, body => $3 };
           $code->();
         }sme;
}

sub parse_header {
  my $h = $_{header};
  $h =~ s/^\s*\S+\s+// || die;
  my @base;
  while ($h =~ /is\s*([^ ,]+),?/g) {
    push(@base, $1);
  }
  return @base;
}

sub build_extends {
  my $base = join(', ', parse_header);
  ($base ? "extends ${base};\n\n" : '');
}

sub sq { # short for 'strip quotes'
  my $copy = $_[0];
  $copy =~ s/^'(.*)'$/$1/;
  $copy =~ s/^"(.*)"$/$1/;
  $copy;
}

sub filtered_body {
  my $is_widget = m/WidgetClass/;
  local $_ = $_{body};
  s/^  //g;
  s/^\s*implements *(\S+).*?{/"sub ${\sq $1} {"/ge unless $is_widget;
  s/^\s*does/with/g;
  s/^\s*overrides/override/g;
  $_;
}

sub top { "use namespace::clean -except => [ qw(meta) ];\n" }
sub tail { $_{type} eq 'class' ? "__PACKAGE__->meta->make_immutable;\n" : ""; }

for (@ARGV) {
  with_file {
    with_class_or_role_block {
      return top.build_extends.filtered_body.tail;
    };
  };
}

1;
