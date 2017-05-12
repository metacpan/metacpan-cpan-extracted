package Local::MyLib;

use PERLANCAR::Exporter::Lite qw(import);
our @EXPORT = qw(sub1);
our @EXPORT_OK = qw(sub2 $SCALAR1 @ARRAY1 %HASH1 *GLOB1);

our $SCALAR1 = 42;
our @ARRAY1  = (1,2);
our %HASH1   = (a=>3, b=>4);

sub sub1 {}
sub sub2 {}

*GLOB1   = \&sub1;

1;
