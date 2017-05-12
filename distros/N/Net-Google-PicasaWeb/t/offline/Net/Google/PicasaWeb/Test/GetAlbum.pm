package Net::Google::PicasaWeb::Test::GetAlbum;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

test plan => 15, get_album_ok => sub {
    my $self = shift;

    # Setup the list albums response
    $self->set_response_content('get_album');

    my $service = $self->service;

    my @albums = $service->get_album( album_id => '1234567890' );
    is($self->request->{new_args}[1], 'GET', 'method is GET');
    is($self->request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/default/albumid/1234567890', 
        'URL is correct');
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

    $self->response->set_always( is_success => 1 );
    $self->response->set_always( content => 'FAKE DATA' );

    my @get_args;
    $self->ua->mock(
        get => sub { shift; @get_args = @_; $self->response } 
    );

    my $content = $photo->content;
    is($content->url, 
        'http://lh5.ggpht.com/liz/SI4jmlkNUFE/AAAAAAAAAzU/J1V3PUhHEoI/Lolcats.jpg', 
        'photo content URL is correct');
    is($content->mime_type, 'image/jpeg', 'photo content MIME-Type is image/jpeg');
    is($content->medium, 'image', 'photo content medium is image');
    is($content->fetch, 'FAKE DATA', 'fetched the data');

    is($get_args[0], $content->url, 'URL is correct');

    my @thumbnails = $photo->thumbnails;
    is(scalar @thumbnails, 1, 'photo has 1 thumbnail');

    my $thumbnail = $thumbnails[0];
    is($thumbnail->url, 
        'http://lh5.ggpht.com/liz/SI4jmlkNUFE/AAAAAAAAAzU/J1V3PUhHEoI/s160-c/Lolcats.jpg', 
        'photo thumbnail URL is correct');
    is($thumbnail->height, 160, 'photo thumbnail height is 160');
    is($thumbnail->width, 160, 'photo thumbnail width is 160');
    is($thumbnail->fetch, 'FAKE DATA', 'fetched the data');

    is($get_args[0], $thumbnail->url, 'URL is correct');
};

1;
