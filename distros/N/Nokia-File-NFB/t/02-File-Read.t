
#########################


use Test::More tests => 7;

BEGIN { 
	use_ok('Nokia::File::NFB'); 
}

BEGIN {
	use_ok('Nokia::File::NFB::Element');
}

#########################
## Read a file
my $nfb = Nokia::File::NFB->new();
isa_ok($nfb,'Nokia::File::NFB');

ok($nfb->read('t/test.nfb'), 'read file');

is($nfb->phone(),'PerlPhone','phone type');

$nfb->firmware('Perl');
is($nfb->firmware(),'Perl','firmware');

$nfb->version(3);
is($nfb->version(),3,'version');

