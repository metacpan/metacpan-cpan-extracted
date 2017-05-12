package Net::Google::PicasaWeb::Test::ListComments;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

setup list_comments_data => sub {
    my $self = shift;

    # Setup the list comments response
    $self->set_response_content('list_comments');
};

test plan => 8, list_comments_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;

    my @comments = $service->list_comments;
    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/default?kind=comment', 
        'URL is user/default');
    is(scalar @comments, 1, 'found 1 comments');

    my $comment = $comments[0];
    is($comment->title, 'Liz', 'title is Liz');
    is($comment->content, 'I do say! What an amusing image!', 'content is correct');
    is($comment->author_name, 'Liz', 'author_name is Liz');
    is($comment->author_uri, 'http://picasaweb.google.com/liz', 
        'author_uri is correct');
};


test plan => 2, user_list_comments_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;
    
    $service->list_comments( user_id => 'foobar' );
    is($request->{new_args}[1], 'GET', 'method is GET');
    ok(URI::eq($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/foobar?kind=comment'), 
        'URL is user/foobar') or diag $request->{new_args}[2];
};

1;
