package Net::Google::PicasaWeb::Test::ListAlbums;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

setup setup_list_albums_content => sub {
    my $self = shift;

    # Setup the list albums response
    $self->set_response_content('list_albums');
};

test plan => 29, list_albums_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;

    my @albums = $service->list_albums;
    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/default?kind=album', 
        'URL is user/default');
    is(scalar @albums, 1, 'found 1 albums');

    my $album = $albums[0];
    is($album->title, 'lolcats', 'title is lolcats');
    is($album->summary, 'Hilarious Felines', 'summary is Hilarious Felines');
    is($album->author_name, 'Liz', 'author_name is Liz');
    is($album->author_uri, 'http://picasaweb.google.com/liz', 
        'author_uri is correct');

    my $photo = $album->photo;
    is($photo->title, 'lolcats', 'photo title is correct');
    is($photo->description, "Hilarious Felines", 'photo description is correct');

    my $response = $self->response;
    my $ua       = $self->ua;

    $response->set_always( is_success => 1 );
    $response->set_always( content => 'FAKE DATA' );
    $ua->mock( 
        get => sub { my $self = shift; $self->{get_args} = \@_; $response } 
    );

    my $content = $photo->content;
    is($content->url, 
        'http://lh5.ggpht.com/liz/SI4jmlkNUFE/AAAAAAAAAzU/J1V3PUhHEoI/Lolcats.jpg', 
        'photo content URL is correct');
    is($content->mime_type, 'image/jpeg', 'photo content MIME-Type is image/jpeg');
    is($content->medium, 'image', 'photo content medium is image');
    is($content->fetch, 'FAKE DATA', 'fetched the data');

    is($ua->{get_args}[0], $content->url, 'URL is correct');

    my @thumbnails = $photo->thumbnails;
    is(scalar @thumbnails, 1, 'photo has 1 thumbnail');

    my $thumbnail = $thumbnails[0];
    is($thumbnail->url, 
        'http://lh5.ggpht.com/liz/SI4jmlkNUFE/AAAAAAAAAzU/J1V3PUhHEoI/s160-c/Lolcats.jpg', 
        'photo thumbnail URL is correct');
    is($thumbnail->height, 160, 'photo thumbnail height is 160');
    is($thumbnail->width, 160, 'photo thumbnail width is 160');
    is($thumbnail->fetch, 'FAKE DATA', 'fetched the data');

    is($ua->{get_args}[0], $thumbnail->url, 'URL is correct');
};

test plan => 29, list_albums_for_other_user_ok => sub {
    my $self = shift;

    my $service  = $self->service;
    my $request  = $self->request;
    my $response = $self->response;

    my @albums = $service->list_albums( user_id => 'foobar' );
    is($request->{new_args}[1], 'GET', 'method is GET');
    ok(URI::eq($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/foobar?kind=album'), 
        'URL is user/foobar with expected arguments') or diag $request->{new_args}[2];

    # Setup the list photos response
    $self->set_response_content('list_media_entries');

    my $album = $albums[0];
    my @photos = $album->list_media_entries;
    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/liz/albumid/5228155363249705041?kind=photo', 
        'URL is an album feed');
    is(scalar @photos, 1, 'found 1 photos');

    my $media = $photos[0];
    is($media->title, 'Nash2.jpg', 'title is Nash2.jpg');
    is($media->summary, '', 'summary is empty');
    is($media->author_name, 'Chuck G', 'author_name is Chuck G');
    is($media->author_uri, 'http://picasaweb.google.com/captaincool', 'author_uri is correct');

    my $photo = $media->photo;
    is($photo->title, 'Nash2.jpg', 'photo title is correct');
    is($photo->description, "", 'photo description is empty');

    my $content = $photo->content;
    is($content->url, 'http://lh3.ggpht.com/captaincool/R3qvUUE_CtI/AAAAAAAAAUI/6OfFN8oPdVs/Nash2.jpg', 'photo content URL is correct');
    is($content->mime_type, 'image/jpeg', 'photo content MIME-Type is image/jpeg');
    is($content->medium, 'image', 'photo content medium is image');

    my @thumbnails = $photo->thumbnails;
    is(scalar @thumbnails, 3, 'photo has 3 thumbnails');

    {
        my $thumbnail = $thumbnails[0];
        is($thumbnail->url, 'http://lh3.ggpht.com/captaincool/R3qvUUE_CtI/AAAAAAAAAUI/6OfFN8oPdVs/s72/Nash2.jpg', 'photo thumbnail URL is correct');
        is($thumbnail->height, 54, 'photo thumbnail height is 54');
        is($thumbnail->width, 72, 'photo thumbnail width is 72');
    }

    {
        my $thumbnail = $thumbnails[1];
        is($thumbnail->url, 'http://lh3.ggpht.com/captaincool/R3qvUUE_CtI/AAAAAAAAAUI/6OfFN8oPdVs/s144/Nash2.jpg', 'photo thumbnail URL is correct');
        is($thumbnail->height, 108, 'photo thumbnail height is 108');
        is($thumbnail->width, 144, 'photo thumbnail width is 144');
    }

    {
        my $thumbnail = $thumbnails[2];
        is($thumbnail->url, 'http://lh3.ggpht.com/captaincool/R3qvUUE_CtI/AAAAAAAAAUI/6OfFN8oPdVs/s288/Nash2.jpg', 'photo thumbnail URL is correct');
        is($thumbnail->height, 216, 'photo thumbnail height is 216');
        is($thumbnail->width, 288, 'photo thumbnail width is 288');
    }

    # Setup the list albums response
    $self->set_response_content('list_tags');

    my @tags = $album->list_tags;
    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/liz/albumid/5228155363249705041?kind=tag', 
        'URL is an album feed');
    is(scalar @tags, 2, 'found 2 tags');

    is($tags[0], 'invisible', 'tag 1 is invisible');
    is($tags[1], 'bike', 'tag 2 is bike');
};

1;
