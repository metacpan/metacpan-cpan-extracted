use strict;
use warnings;
use Excel::Writer::XLSX;
use Spreadsheet::WriteExcel::Styler;

my $workbook = Excel::Writer::XLSX->new('output.xlsx');
my $worksheet = $workbook->add_worksheet();

# Create a styler with some styles 
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

# Write data into a cell, with a list of cumulated styles
$worksheet->write(0, 0, 'highlighted right_border', 
                  $styler->(qw/highlighted right_border/));
$worksheet->set_column(0, 0, 40);

# same thing, but styles are expressed as toggles in a hashref
$worksheet->write(2, 1, 'highlighted rotated', 
                  $styler->({ highlighted  => 1,
                              rotated      => 1, }));

$workbook->close();

system('start output.xlsx');


