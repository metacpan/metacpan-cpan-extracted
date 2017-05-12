use Test::More;

use Test::Legal  'license_ok',  
                 'copyright_ok' ,
                 defaults => { base=> $ENV{PWD} =~ m#\/t$#  ? '..' : '.' , actions=>['fix']} ,
;

SKIP: {
	skip 'Test::Legal not installed', 2  if $@;
	license_ok;
	copyright_ok;
}

         

