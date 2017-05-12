use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

$ENV{DANCER_CONFDIR} = 't/testapp';
$ENV{DANCER_ENVIRONMENT} = 'no_login';
require Strehler::Admin;
require t::testapp::lib::TestSupport;

TestSupport::reset_database();

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    
    #LIST
    my $r = $cb->(GET '/admin/artwork/list');
    is($r->code, 200, "Artworks page correctly accessed");
    #ADD        
    $r = $cb->(POST "/admin/artwork/add",
                    'Content_Type' => 'form-data',
                    'Content' =>  [
			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg'],
			                'thumbnail' => ['t/res/strehler2.jpg', 'strehler2.jpg', 'Content-Type' => 'image/jpg'],
                            'category' => 1,
                            'category-name' => 'dummy',
                            'tags' => 'tag1',
                            'title_it' => 'Automatic test - title - IT',
                            'description_it' => 'Automatic test - body - IT',
                            'title_en' => 'Automatic test - title - EN',
                            'description_en' => 'Automatic test - body - EN',
                            'strehl-action' => 'submit-go' 
                            ]
                 );
    is($r->code, 302, "Image submitted, navigation redirected to list (submit-go)");
    print $r->content;
    my $images = Strehler::Element::Extra::Artwork->get_list();
    my $image = $images->{'to_view'}->[0];
    my $image_id = $image->{'id'};
    my $image_object = Strehler::Element::Extra::Artwork->new($image_id);
    ok($image_object->exists(), "Image correctly inserted");
    $r = $cb->(POST "/admin/artwork/edit/$image_id",
                    'Content_Type' => 'form-data',
                    'Content' =>  [
   			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg'],
			                'thumbnail' => ['t/res/strehler2.jpg', 'strehler2.jpg', 'Content-Type' => 'image/jpg'],
                            'category' => 1,
                            'subcategory' => undef,
                            'tags' => 'tag1',
                            'title_it' => 'Automatic test - title changed - IT',
                            'description_it' => 'Automatic test - body changed - IT',
                            'title_en' => 'Automatic test - title changed - EN',
                            'description_en' => 'Automatic test - body changed - EN',
                            'strehl-action' => 'submit-continue' 
                            ]
                 );
    is($r->code, 200, "Content changed, navigation still on edit page (submit-continue)");                 


    ok(-e "t/testapp/public/upload/strehler.jpg", "Image resource in place [1]");
    ok(-e "t/testapp/public/upload/strehler2.jpg", "Image resource in place [2]");

    #DELETE
    $r = $cb->(POST "/admin/artwork/delete/$image_id");
    $image_object = Strehler::Element::Extra::Artwork->new($image_id);
    ok(! $image_object->exists(), "Artwork correctly deleted");

    unlink 't/testapp/public/upload/strehler.jpg';
    unlink 't/testapp/public/upload/strehler2.jpg';
};
done_testing();
