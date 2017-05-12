package Net::Google::PicasaWeb::Test::ListAlbums;
use Test::Able;
use Test::More;

use List::Util qw( shuffle );

with qw( Net::Google::PicasaWeb::Test::Role::Online );

setup service_login => sub { shift->do_login };

sub limit_to($@) {
    my $max = shift;
    return () unless @_;

    return @_ if @_ <= $max;

    my @list = shuffle(@_);
    return @list[0 .. ($max - 1)];
}

test plan => 'no_plan', happy_login_ok => sub {
    my $self = shift;
    my $service = $self->service;

    my @albums = $service->list_albums;
    
    for my $album (limit_to(3, @albums)) {
        note("ALBUM ".$album->entry_id." - ".$album->title);
        ok($album->entry_id, 'got an entry ID');
        ok($album->title, 'got a title');
        ok(defined $album->summary, 'got a summary');
        ok($album->author_name, 'got an author_name');
        ok($album->author_uri, 'got an author_uri');
        ok(((defined $album->latitude && defined $album->longitude)
            || (!(defined $album->latitude || defined $album->longitude))),
            'lat/long both defined or both not defined');
        if (defined $album->latitude) {
            ok($album->latitude >= -90, 'latitude is not too small');
            ok($album->latitude <= 90, 'latitude is not too big');
        }
        if (defined $album->longitude) {
            ok($album->longitude >= -180, 'longitude is not too small');
            ok($album->longitude <= 180, 'longitude is not too big');
        }
        ok($album->photo, 'got a photo');
        ok($album->bytes_used, 'got bytes used');
        ok($album->number_of_photos, 'got number of photos');

        my @photos = $album->list_photos;
        is($album->number_of_photos, scalar(@photos),
            'number of photos matches returned photos');
        for my $photo (limit_to(3, @photos)) {
            note("PHOTO ".$photo->entry_id." - ".$photo->title);
            ok($photo->entry_id, 'got an entry ID');
            ok($photo->title, 'got a title');
            ok(defined $photo->summary, 'got a summary');
            # ok($photo->author_name, 'got an author name');
            # ok($photo->author_uri, 'got an author URI');
            ok($photo->photo, 'got a photo');
            is($photo->album_id, $album->entry_id,
                'album ID for photo matches entry ID');
            ok($photo->width, 'got a width');
            ok($photo->height, 'got a height');
            ok($photo->size, 'got a size');

            my $media = $photo->photo;
            is($media->title, $photo->title, 'media title matches photo title');
            is($media->description, $photo->summary, 
                'media description matches photo summary');
            ok($media->content, 'got content');

            my $content = $media->content;
            is($content->media, $media, 'content media is same as parent');
            ok($content->url, 'got a content URL');
            ok($content->mime_type, 'got a content MIME type');
            ok($content->medium, 'got a content medium');
            like($content->medium, qr{^(?:image|video)$}, 
                'content medium is either an image or video');
            ok($content->width, 'got a content width');
            ok($content->height, 'got a content height');

            my $content_data = $content->fetch;
            ok($content_data, 'fetched the image data');
            is(bytes::length($content_data), $content->size,
                'image is expected byte size')
                    if $content->size;
            
            for my $thumbnail ($media->thumbnails) {
                is($media, $thumbnail->media, 'thumbnail media matches parent');
                ok($thumbnail->url, 'got a thumbnail URL');
                ok($thumbnail->width, 'got a thumbnail width');
                ok($thumbnail->height, 'got a thumbnail height');

                my $thumbnail_data = $thumbnail->fetch;
                ok($thumbnail_data, 'fetched the thumbnail image data');
            }

            my @tags = $photo->list_tags;
            for my $tag (@tags) {
                ok($tag, 'got a tag');
            }

            my @comments = $photo->list_comments;
            for my $comment (@comments) {
                ok($comment->entry_id, 'got an entry ID');
                ok($comment->title, 'got a title');
                ok($comment->content, 'got content');
                ok($comment->author_name, 'got an author name');
                ok($comment->author_uri, 'got an author URI');
            }
        }
    }
};

1;
