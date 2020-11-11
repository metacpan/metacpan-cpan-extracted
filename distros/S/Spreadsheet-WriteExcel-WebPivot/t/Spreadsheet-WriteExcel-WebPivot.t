
# Note the core function of this module, to make a web pivot table in 
# Internet Explorer can't be tested here so we'll just test a few things
# that we can

use Test::More tests => 5;
BEGIN { use_ok('Spreadsheet::WriteExcel::WebPivot') };

###############################################################################
# use the example given in the documentation

use strict;

my @array;

for(my $i=0; $i < 20; $i++) {      
	push @array, { Name => "a$i", Number => $i }; 
}

my @fields = qw(Name Number);

my $filename = 'exceltest';
makewebpivot(\@array, '', \@fields, 'Count', $filename, 'Test Pivot');
###############################################################################

ok(-f $filename . '.htm', 'htm file created');
ok(-d $filename . '_files', 'files directory created');
ok(-f $filename . '_files/filelist.xml', 'listing file created');
ok(-f $filename . '_files/' . $filename . '_1234_cachedata001.xml', 
'listing file created');
### now clean up the files we created
unlink $filename . '.htm';
unlink $filename . '_files/filelist.xml';
unlink $filename . '_files/' . $filename . '_1234_cachedata001.xml';
rmdir $filename . '_files';
