package Net::Google::PicasaWeb::Test::GetComment;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

setup get_comment_data => sub {
    my $self = shift;

    # Setup the list comments response
    $self->set_response_content('get_comment');
};

test plan => 8, get_comment_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;

    my @comments = $service->get_comment(
        album_id   => '1234567890',
        photo_id   => '0987654321',
        comment_id => 'ABCDEFGHIJ',
    );

    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/default/albumid/1234567890/photoid/0987654321/commentid/ABCDEFGHIJ', 
        'URL is correct');
    is(scalar @comments, 1, 'found 1 comments');

    my $comment = $comments[0];
    is($comment->title, 'Liz', 'title is Liz');
    is($comment->content, 'I do say! What an amusing image!', 'content is correct');
    is($comment->author_name, 'Liz', 'author_name is Liz');
    is($comment->author_uri, 'http://picasaweb.google.com/liz', 'author_uri is correct');
};

1;
