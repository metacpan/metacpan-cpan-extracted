
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{'A1:A8'} = '10' ;
$ss{'A1:A8'} = UserData(NAME => 'private data', ARRAY => ['hi']) ;

print "@{$ss{'A1:A8'}}\n" ;

print $ss->Dump() ;

use Data::TreeDumper ;
print DumpTree($ss{'A1.USER_DATA'}, "User data dump for 'A1'", USE_ASCII => 0) ;

