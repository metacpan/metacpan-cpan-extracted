use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export qw( filedata );

is( filedata(\'abcdef'), object {
   string 'abcdef';
   call offset => 0;
   call size   => 6;
}, 'scalar ref' );

is( filedata(\'abcdef', 3), object {
   call size => 3;
   string 'def';
   call offset => 3;
   call size => 3;
}, 'scalar ref + offset' );

is( filedata(\'abcdef', 3, 1), object {
   string 'd';
   call offset => 3;
   call size   => 1;
}, 'scalar ref + offset + len' );

my $tmp= File::Temp->new;
my $content= "A"x4096 . "B"x4096 . "C"x4096;
$tmp->print($content);
$tmp->close;

is( filedata("$tmp"), object {
   call size => length $content;
   call offset => 0;
   string $content;
}, 'file' );

is( filedata("$tmp", 4096), object {
   call size => (length $content)-4096;
   call offset => 4096;
   string substr($content, 4096);
}, 'file + offset' );

is( filedata("$tmp", 4096*2, 4096), object {
   call size => 4096;
   call offset => 4096*2;
   string substr($content, 4096*2);
}, 'file + offset + len' );

done_testing;

   