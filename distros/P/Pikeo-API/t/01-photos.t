#!perl -T

use Test::More no_plan => 1;

BEGIN {
	use_ok( 'Pikeo::API' );
	use_ok( 'Pikeo::API::Photos' );
}
diag( "Testing Pikeo::API $Pikeo::API::VERSION, Perl $], $^X" );

SKIP: {
     skip "No online tests requested" unless $ENV{"TEST_ONLINE"};      
     require "./t/api.pl";
     
     my $api = api(); 
     
     my $photos = Pikeo::API::Photos->new({ api => $api });
     
     my $dphotos = $photos->search({
                                    tag_id_list=>[1,2],
                                    num_items=>2,
                                    });
     
     my $sphotos = $photos->search({text=>'shozu', num_items=>2});
     test_photos($sphotos);
     my $mvphotos = $photos->getMostViewed({num_items=>2});
     test_photos($mvphotos);
}

sub test_photos {
 my $ps = shift;
 for my $p ( @$ps ) {
   diag($p->original_url());
   isa_ok($p, "Pikeo::API::Photo");
   ok( $p->title, "Photo has title");
   my $owner = $p->owner;
   isa_ok($owner, "Pikeo::API::User");
   
   ok( $owner->username, "owner has username" );

   ok( scalar(@{$owner->getUserPhotos()}), "user has photos" );

   for ( @{$owner->getUserPhotos()} ) { isa_ok( $_, "Pikeo::API::Photo" ); }
   for ( @{$owner->getContactsPublicPhotos()} ) { isa_ok( $_, "Pikeo::API::Photo" ); }
   for ( @{$owner->getPublicPhotos()} ) { isa_ok( $_, "Pikeo::API::Photo" ); }
 }
}
