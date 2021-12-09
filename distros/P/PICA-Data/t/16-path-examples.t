use strict;
use Test::More;

# test the examples in PICA::Path documentation

use PICA::Path;
use PICA::Data;

my $record = PICA::Data->new(<<'PP');
005A $01234-5678
005A $01011-1213
009Q $uhttp://example.org/$xA$zB$zC
021A $aTitle$dSupplement
031N $j1600$k1700$j1800$k1900$j2000
045F/01 $a001
045F/02 $a002
045U $e003$e004
045U $e005
PP

# match record
my $path = PICA::Path->new('021A$ad');
my $match = $path->match($record);
is $match, 'TitleSupplement';

is $record->match('021A$ad'), 'TitleSupplement';

# get all subfields
$path  = PICA::Path->new('021A');
$match = $path->match($record);
is $match, 'TitleSupplement';

# get single subfield by code
$path  = PICA::Path->new('021A$a');
$match = $path->match($record);
is $match, 'Title';

# get two subfields by code
$path  = PICA::Path->new('021A$ad');
$match = $path->match($record);
is $match, 'TitleSupplement';

$path  = PICA::Path->new('021A$da');
$match = $path->match($record);
is $match, 'TitleSupplement';

# get two subfields by code in specific order
$path = PICA::Path->new('021A$da');
$match = $path->match($record, pluck => 1);
is $match, 'SupplementTitle';

# pluck with undefined subfield
$path = PICA::Path->new('021A$Xa');
$match = $path->match($record, pluck => 1);
is $match, 'Title';

# join subfields
$path = PICA::Path->new('021A$da');
$match = $path->match($record, pluck => 1, join => ' ');
is $match, 'Supplement Title';

done_testing;

