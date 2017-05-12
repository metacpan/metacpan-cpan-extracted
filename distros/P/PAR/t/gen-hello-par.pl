use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES );

my $zip = Archive::Zip->new();
exit($zip->addTree("t/data", "") == AZ_OK
     && $zip->writeToFileNamed("t/hello.par") == AZ_OK ? 0 : 1);
