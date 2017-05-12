#########################


use Test::More tests => 19;

BEGIN { 
	use_ok('Nokia::File::NFB'); 
}

BEGIN {
	use_ok('Nokia::File::NFB::Element');
}

#########################
## create an directory element.
my $nfb_dir_element = Nokia::File::NFB::Element->new({
	'type'	=> 2,
	'name'	=> '\\Test',
});
isa_ok($nfb_dir_element,'Nokia::File::NFB::Element');

is($nfb_dir_element->type(),2,'file type');

is($nfb_dir_element->name(),'\\Test','directory name');


#########################
## create an file element.
my $nfb_file_element = Nokia::File::NFB::Element->new({
	'type'	=> 1,
	'name'	=> '\\Test\\TestData',
	'data'	=> 'testtesttesttesttest',
});
isa_ok($nfb_file_element,'Nokia::File::NFB::Element');

is($nfb_file_element->type(),1,'file type');

is($nfb_file_element->name(),'\\Test\\TestData','file name');


#########################
## create a file now.
my $nfb = Nokia::File::NFB->new();
isa_ok($nfb,'Nokia::File::NFB');

$nfb->phone('PerlPhone');
is($nfb->phone(),'PerlPhone','phone type');

$nfb->firmware('Perl');
is($nfb->firmware(),'Perl','firmware');

$nfb->version(3);
is($nfb->version(),3,'version');

my @elements = ();
push @elements, $nfb_dir_element;
push @elements, $nfb_file_element;

$nfb->elements(\@elements);
ok($nfb->elements(),'elements');

ok($nfb->write('t/test2.nfb'),'write');

my $newnfb = Nokia::File::NFB->new();
isa_ok($newnfb,'Nokia::File::NFB');

ok($newnfb->read('t/test.nfb'),'read');

is($nfb->phone(),$newnfb->phone(),'phone type');

is($nfb->firmware(),$newnfb->firmware(),'firmware');

is($nfb->version(),$newnfb->version(),'version');

