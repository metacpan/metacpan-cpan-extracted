#!perl -T

use Test::More no_plan => 1;
use Data::Dumper;

BEGIN {
	use_ok( 'Pikeo::API' );
	use_ok( 'Pikeo::API::User::Logged' );
	use_ok( 'Pikeo::API::User' );
}

diag( "Testing Pikeo::API $Pikeo::API::VERSION, Perl $], $^X" );

SKIP: {
    skip "No online tests requested" unless $ENV{"TEST_ONLINE"};

    require "./t/api.pl";
    
    my $api = api(); 
    
    login($api);
    
    my $user = Pikeo::API::User::Logged->new({ api=>$api});
    ok( $user->id );
    ok( $user->username );
    ok( $user->email );
    ok( $user->getUserPhotos );
    ok( $user->getPublicPhotos );
    
    my $user2 = Pikeo::API::User->new({api=>$api, username=>$user->username});
    
    ok( $user2->id == $user->id );
    
    my $user3 = Pikeo::API::User->new({api=>$api, id=>$user->id});
    
    ok( $user3->username == $user->username );
    
    my @photos = $user->getPicturesCommentedByMe({num_items=>2});
    my @photos2 = $user->getMyCommentedPhotos({num_items=>2});
    
    my $title = 't'.time();
    my $p = $user->uploadPhoto(
                       { picture => 't/pikeo_beta.jpg', 
                         tags => [where=>'lisbon', who=>'donald'],
                         title => $title,
                       });
    
    cmp_ok( $title, 'eq', $p->title, "Uploaded photo data: title" );
    
    cmp_ok( $p->owner_id, 'eq', $user->id, "Uploaded photo data: owner" );
    
    ok( $p->tags );
    
    my $cmid = $p->addComment({text=>'hello'});
    
    for my $c ( @{ $comments } ) {
        next unless $c->id eq $cmid;
        ok($c->delete(), "delete comment");
    }
    
    $p->setPrivacy({access_type=>7, force_quit_group=>1});
    
    print Dumper $user->getContactsList;
}
