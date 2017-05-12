use Test::Simple 'no_plan';
use File::Path 'rmtree';

rmtree('./t/jpgdir');
rmtree('./t/altdir');

system('rm ./t/testdocs/*.pbm');

ok(1,"made sure jpgdir and altdir are gone.");
