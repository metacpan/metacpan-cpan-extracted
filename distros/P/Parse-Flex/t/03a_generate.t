use Test::More ;
use Parse::Flex::Generate;

plan tests=> 14 ;

local $_ = pm_content('Flex6') ;
ok m/\bFlex6\b/                         =>  'pm_content';


$_ = xs_content 'Flex6'  ;
ok m//                                  =>  'xs_content';
isnt  m/^\t/, 1;

is undef, makefile_content( 'Flex6')    => 'makefile_content';
$_ = makefile_content 'Flex6' , '../john.l'  ;
ok m/Flex6/;
ok m: (?<!/) john.l \b :x;

ok m/fopt \s* = \s* -Cf \s* $/mx;

$_ = makefile_content 'Flex6' , '../john.l' ,  '-d -C'  ;
ok m/fopt \s* = \s* -d\ -C \s* $/mx;

$_ = makefile_content 'Flex6' , '../john.l' ,  '-d' , 0 ;
ok m/^ifdef n\s*$/m ;
$_ = makefile_content 'Flex6' , '../john.l' ,  '-d' , 1 ;
ok m/^ifndef n\s*$/m ;

$_ = Usage  'Flex6' ;
ok m/Flex6/                             => 'Usage()';
ok m/$0/;
ok m/Usage:/x;
ok m/ -h \b/x;
