use lib "lib";
use Spreadsheet::Wright;

my $excel = Spreadsheet::Wright->new(filename => './example1.xls');
my $xlsx  = Spreadsheet::Wright->new(filename => './example1.xlsx', styles=>{redcell=>{font_style=>'italic',font_color=>'red'}});
my $csv   = Spreadsheet::Wright->new(filename => './example1.csv');
my $ods   = Spreadsheet::Wright->new(filename => './example1.ods');
my $html  = Spreadsheet::Wright->new(filename => './example1.html', styles=>{redcell=>{font_style=>'italic',font_color=>'red'}});
my $xhtml = Spreadsheet::Wright->new(filename => './example1.xhtml');
my $xml   = Spreadsheet::Wright->new(filename => './example1.xml');
my $json  = Spreadsheet::Wright->new(filename => './example1.json', json_options => {pretty=>1});

my @row = (
	'Foo',
	'Bar',
	{ content => 'Baz' , font_weight => 'bold' , header => 1 , style=>'redcell' },
);

$csv->addrows(\@row,\@row);
$excel->addrows(\@row,"Another",\@row);
$ods->addrows(\@row,"Another",\@row);
$html->addrows(\@row,"Another",\@row);
$xhtml->addrows(\@row,"Another",\@row);
$xml->addrows(\@row,"Another",\@row);
$xlsx->addrows(\@row,"Another",\@row);
$json->addrows(\@row,"Another",\@row,"Sheet1",\@row);

