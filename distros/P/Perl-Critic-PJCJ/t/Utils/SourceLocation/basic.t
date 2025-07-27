#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is isa_ok subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                                 qw( lib t/lib );
use Perl::Critic::Utils::SourceLocation ();

subtest "Constructor with all parameters" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(
    line_number   => 42,
    column_number => 5,
    content       => "sample content",
    filename      => "test.pl"
  );

  isa_ok $location, "Perl::Critic::Utils::SourceLocation";
  isa_ok $location, "PPI::Element";
};

subtest "Constructor with minimal parameters" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(line_number => 10);

  isa_ok $location, "Perl::Critic::Utils::SourceLocation";
  is $location->line_number,   10,    "line_number set correctly";
  is $location->column_number, 1,     "column_number defaults to 1";
  is $location->content,       "",    "content defaults to empty string";
  is $location->filename,      undef, "filename can be undef";
};

subtest "All accessor methods" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(
    line_number   => 123,
    column_number => 45,
    content       => "test line content",
    filename      => "example.pm"
  );

  is $location->line_number,          123, "line_number accessor";
  is $location->column_number,        45,  "column_number accessor";
  is $location->logical_line_number,  123, "logical_line_number accessor";
  is $location->visual_column_number, 45,  "visual_column_number accessor";
  is $location->logical_filename,     "example.pm", "logical_filename accessor";
  is $location->content,  "test line content",      "content accessor";
  is $location->filename, "example.pm",             "filename accessor";
  is $location->top,      $location,                "top accessor returns self";
};

subtest "Location method for violation system" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(
    line_number   => 100,
    column_number => 20,
    filename      => "source.pl"
  );

  my $location_array = $location->location;
  is ref($location_array), "ARRAY",     "location returns array reference";
  is @$location_array,     5,           "location array has 5 elements";
  is $location_array->[0], 100,         "first element is line number";
  is $location_array->[1], 20,          "second element is column number";
  is $location_array->[2], 20,          "third element is visual column number";
  is $location_array->[3], 100,         "fourth element is logical line number";
  is $location_array->[4], "source.pl", "fifth element is filename";
};

subtest "Policy identification" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(line_number => 1);

  is $location->is_policy, 0, "is_policy returns false";
};

subtest "Constructor with explicit undef values" => sub {
  my $location = Perl::Critic::Utils::SourceLocation->new(
    line_number   => 50,
    column_number => undef,
    content       => undef,
    filename      => undef
  );

  is $location->line_number,   50, "line_number set correctly";
  is $location->column_number, 1,  "column_number defaults when undef passed";
  is $location->content,       "", "content defaults when undef passed";
  is $location->filename,         undef, "filename remains undef";
  is $location->logical_filename, undef, "logical_filename remains undef";
};

done_testing;
