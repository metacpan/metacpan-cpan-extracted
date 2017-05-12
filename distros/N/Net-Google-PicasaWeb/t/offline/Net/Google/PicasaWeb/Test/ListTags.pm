package Net::Google::PicasaWeb::Test::ListTags;
use Test::Able;
use Test::More;

use URI;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

setup setup_list_tags => sub {
    my $self = shift;

    # Setup the list albums response
    $self->set_response_content('list_tags');
};

test plan => 6, general_list_tags_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;

    my @tags = $service->list_tags;
    is($request->{new_args}[1], 'GET', 'method is GET');
    is($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/default?kind=tag', 
        'URL is user/default');
    is(scalar @tags, 2, 'found 2 tags');

    is($tags[0], 'invisible', 'tag 1 is invisible');
    is($tags[1], 'bike', 'tag 2 is bike');
};

test plan => 2, user_list_tags_ok => sub {
    my $self = shift;

    my $service = $self->service;
    my $request = $self->request;

    $service->list_tags( user_id => 'foobar' );
    is($request->{new_args}[1], 'GET', 'method is GET');
    ok(URI::eq($request->{new_args}[2], 
        'http://picasaweb.google.com/data/feed/api/user/foobar?kind=tag'), 
        'URL is user/foobar') or diag $request->{new_args}[2];
};

1;
