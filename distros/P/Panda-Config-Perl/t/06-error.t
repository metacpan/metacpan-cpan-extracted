use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Panda::Config::Perl;
use FindBin qw($Bin);

my $cfg; 

like( 
	exception {$cfg = Panda::Config::Perl->process($Bin.'/configs/no_such_file.conf');}, 
	qr/Panda::Config::Perl: cannot open/, 
	'\'Panda::Config::Perl: cannot open\' appears in the exception' 
);
is (ref($cfg),'');

like( 
	exception {$cfg = Panda::Config::Perl->process($Bin.'/configs/config_with_errors.conf');}, 
	qr/Panda::Config::Perl: error while processing config/, 
	'\'Panda::Config::Perl: error while processing config\' appears in the exception'
);
is (ref($cfg),'');

like( 
	exception {$cfg = Panda::Config::Perl->process($Bin.'/configs/config_with_errors2.conf');}, 
	qr/Panda::Config::Perl: conflict between variable /, 
	'\'Panda::Config::Perl: conflict between variable\' appears in the exception'
);
is (ref($cfg),'');


done_testing();
