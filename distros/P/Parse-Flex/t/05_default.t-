use Test::More qw( no_plan );
use Parse::Flex;

my $dir       =  ( $0 =~ m!^t/!) ? 't' : '.';
$dir eq 't' and chdir 't' ;
unlink qw( Flex7.so Flex7.pm) ;

my $grammar   =  "default.l";
my $makelexer =  "../script/makelexer.pl";


-f $grammar   or die "$grammar $!";
-e $makelexer or die "$makelexer $!";


system qq( perl -Mblib=../blib "$makelexer"  -n Flex7  $grammar );
is  1,  -f "Flex7.so" ;
is  1,  -f "Flex7.pm" ;

require 'Flex7.pm';
my $data = "hello ioannis\@earthlink.net\n7";

my $walker = &Flex7::gen_walker( \$data ) ;

is_deeply [ $walker->()], [qw( WORD hello)]; 
is_deeply [ $walker->()], [qw( EMAIL ioannis@earthlink.net)];
is_deeply [ $walker->()], [qw( NUM 7)]; 
is_deeply [ $walker->()], [ "" , ""];


unlink qw( Flex7.so Flex7.pm);
