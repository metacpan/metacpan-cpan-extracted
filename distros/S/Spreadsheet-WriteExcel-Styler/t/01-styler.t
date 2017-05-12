# first a mock package to simulate Spreadsheet::WriteExcel workbooks
package _MockWorkbook;

sub new {
  my $class = shift;
  bless [], $class;
}

sub add_format {
  my $self = shift;
  my $format = [@_];
  push @$self, $format;
  return $format;
}

# now the tests in main package
package main;
use strict;
use warnings;
use Spreadsheet::WriteExcel::Styler;
use Test::More tests => 6;

# create a styler object
my $workbook  = _MockWorkbook->new;
my $styler = Spreadsheet::WriteExcel::Styler->new($workbook);
$styler->add_styles(
    title        => {align       => "center",
                     border      => 1,
                     bold        => 1,
                     color       => 'white',
                     bg_color    => 'blue'},
    right_border => {right       => 6,         # double line
                     right_color => 'blue'},
    highlighted  => {bg_color    => 'silver'},
    rotated      => {rotation    => 90},
  );

# create formats in various ways
my $fmt1 = $styler->(qw/title right_border/);
my $fmt2 = $styler->(qw/right_border title/);
my $fmt3 = $styler->({right_border => 0,
                      highlighted  => 1, 
                      rotated      => 1});
my $fmt4 = $styler->({rotated      => 0,
                      highlighted  => 0, 
                      title        => 1,
                      right_border => 1});
my $fmt5 = $styler->([qw/title right_border/]);

# check if the format cache worked OK
is  (scalar(@$workbook), 2, "workbook contains just 2 different formats");
is  ($fmt1, $fmt2,          "order indifferent");
isnt($fmt1, $fmt3,          "different features");
is  ($fmt1, $fmt4,          "array/hashref are equivalent");
is  ($fmt4, $fmt5,          "arrayref/hashref are equivalent");

# error-checking
eval {$styler->(qw/title foo bar/)};
my $err = $@;
like($err, qr/unknown style/, 'error checking');
