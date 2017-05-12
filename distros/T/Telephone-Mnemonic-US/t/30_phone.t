
use Test::More  'no_plan';
use Telephone::Mnemonic::US::Phone;
use Data::Dumper;
use Test::Exception;


note 'Phone class';
new_ok 'Telephone::Mnemonic::Phone';
can_ok 'Telephone::Mnemonic::Phone', qw/ meta num / ;

#subtest 'subclass' => sub {
	#plan tests => 4;
note 'US::Phone subclass';
dies_ok( sub{new Telephone::Mnemonic::US::Phone} );
my $u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'123-111-3333'] ;
can_ok $u1, qw/ meta num area_code station_code house_code /;
can_ok $u1, qw/ beautify / ;

note 'US::Phone autoclean' ;
ok ! $u1->can( 'well_formed_p' ) ;
ok ! $u1->can( 'to_tel_digits' ) ;



#};
note 'US::Phone instance';
$u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'123-111-3333'] ;
is $u1->area_code, 123;
is $u1->station_code, 111;
is $u1->house_code, 3333;
is $u1->without_area_code, '1113333';
is $u1->beautify, '(123) 111 3333';


__END__
