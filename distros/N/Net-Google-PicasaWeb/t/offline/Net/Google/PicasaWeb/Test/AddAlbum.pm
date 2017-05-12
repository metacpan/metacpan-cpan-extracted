package Net::Google::PicasaWeb::Test::AddAlbum;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

test plan => 8, add_album_ok => sub {
    my $self = shift;

    # Setup the response
    $self->set_response_content('add_album');

    my $service = $self->service;

    my @albums = $service->add_album(
        title => 'Net::PicasaWeb test',
        summary => 'Summary of the album',
        location => 'Finland',
        access => 'private',
        commentingEnabled => 'true',
        timestamp => 1152255600000,
        keywords => ('trip', 'Italy', 'spring'),
    );
    is($self->request->{new_args}[1], 'POST', 'method is POST');
    is($self->request->{new_args}[2],
        'http://picasaweb.google.com/data/feed/api/user/default',
        'URL is correct');
    is(scalar @albums, 1, 'found 1 albums');

    my $album = $albums[0];
    is($album->title, 'Net::PicasaWeb test', 'title is "Net::PicasaWeb test"');
    is($album->summary, 'Summary of the album',
        'summary is "Summary of the album"');
    is($album->author_name, 'Andy Shevchenko',
        'author_name is "Andy Shevchenko"');
    is($album->author_uri,
        'https://picasaweb.google.com/andy.shevchenko',
        'author_uri is correct');
};

1;
