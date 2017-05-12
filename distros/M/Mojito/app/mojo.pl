use Mojolicious::Lite;
use Mojito;
use Mojito::Auth;
use Mojito::Model::Config;
use Plack::Builder;
use JSON;
use Data::Dumper::Concise;

# Make a shortcut the the mojito app object
app->helper(
    mojito => sub {
        return $_[0]->req->env->{mojito};
    }
);

get '/bench' => sub {
    $_[0]->render( text => $_[0]->mojito->bench );
};

get '/hola/:name' => sub {
    $_[0]->render( text => "Hola " . $_[0]->param('name') );
};

get '/page' => sub {
    $_[0]->render( text => $_[0]->mojito->fillin_create_page );
};

post '/page' => sub {
    $_[0]->redirect_to(
        $_[0]->mojito->create_page( $_[0]->req->params->to_hash ) );
};

post '/preview' => sub {
    $_[0]->render(
        json => $_[0]->mojito->preview_page( $_[0]->req->params->to_hash ) );
};

get '/page/:id' => sub {
    $_[0]->render(
        text => $_[0]->mojito->view_page( { id => $_[0]->param('id') } ) );
};

get '/public/page/:id' => sub {
    $_[0]->render(
        text => $_[0]->mojito->view_page_public( { id => $_[0]->param('id') } )
    );
};

get '/page/:id/edit' => sub {
    $_[0]->render(
        text => $_[0]->mojito->edit_page_form( { id => $_[0]->param('id') } ) );
};

post '/page/:id/edit' => sub {

    # $self->req->params doesn't include placeholder $self->param() 's
    my $params = $_[0]->req->params->to_hash;
    $params->{'id'} = $_[0]->param('id');

    $_[0]->redirect_to( $_[0]->mojito->update_page($params) );
};

get '/search/:word' => sub {
    my ($self) = (shift);
    my $params;
    $params->{word} = $self->param('word');
    $self->render( text => $self->mojito->search($params) );
};

get '/page/:id/delete' => sub {
    $_[0]->redirect_to(
        $_[0]->mojito->delete_page( { id => $_[0]->param('id') } ) );
};

get '/page/:id/diff' => sub {
    $_[0]->render(
        text => $_[0]->mojito->view_page_diff( { id => $_[0]->param('id') } ) );
};

get '/page/:id/diff/:m/:n' => sub {

# three params: page_id, start rev (distance from head), stop rev (distance from head)
    $_[0]->render(
        text => $_[0]->mojito->view_page_diff(
            {
                id => $_[0]->param('id'),
                m  => $_[0]->param('m'),
                n  => $_[0]->param('n')
            }
        )
    );
};

get '/collect' => sub {
    my ($self) = (shift);
    $self->render( text => $self->mojito->collect_page_form );
};

post '/collect' => sub {
    my ($self) = (shift);
    $self->redirect_to($self->mojito->collect($self->req->params->to_hash));
};

get '/collection/:id' => sub {
    my ($self) = (shift);
    my $params;
    $params->{id} = $self->param('id');
    $self->render( text => $self->mojito->collection_page($params) );
};

get '/public/collection/:id' => sub {
    my ($self) = (shift);
    my $params;
    $params->{id} = $self->param('id');
    $params->{public} = 1;
    $self->render( text => $self->mojito->collection_page($params) );
};

get '/collections' => sub {
    my ($self) = (shift);
    $self->render( text => $self->mojito->collections_index );
};

get '/collection/:id/sort' => sub {
    my ($self) = (shift);
    my $params;
    $params->{id} = $self->param('id');
    $self->render( text => $self->mojito->sort_collection_form($params) );
};

post '/collection/:id/sort' => sub {
    my ($self) = (shift);
    my $params = $self->req->params->to_hash;
    $params->{id} = $self->param('id');
    $self->redirect_to($self->mojito->sort_collection($params));
};

get '/collection/:collection_id/page/:page_id' => sub {
    my ($self) = @_;

    my $params =  {
        collection_id => $self->param('collection_id'),
        page_id       => $self->param('page_id'),
    };
    my $output = $self->mojito->view_page_collected($params);

    $self->render(text => $output);
};

get '/public/collection/:collection_id/page/:page_id' => sub {
    my $self = shift;

    my $params =  {
        public        => 1,
        collection_id => $self->param('collection_id'),
        page_id       => $self->param('page_id'), 
   };
   my $output = $self->mojito->view_page_collected($params);
    
   $self->render(text => $output);
};

get  '/collection/:collection_id/merge' => sub {
    my $self = shift;
    my $params = {
        collection_id => $self->param('collection_id'),
    };
    my $output = $self->mojito->merge_collection($params);
    $self->render(text => $output);
};

get '/collection/:collection_id/delete' => sub {
    my ($self) = shift;
    my $redirect_url = $self->mojito->delete_collection({ collection_id => $self->param('collection_id') });
    $self->redirect_to($redirect_url);
};

get '/collection/:collection_id/epub' => sub {
    my ($self) = (shift);
    
    my $collection_id = $self->param('collection_id');
    my $output = $self->mojito->epub_collection({ collection_id => $self->param('collection_id') });
    $self->res->headers->add( 'Content-type' => 'application/octet-stream');
    $self->res->headers->add( 'Content-Disposition' => "attachment; filename=collection_${collection_id}.epub" );
    $self->render(data => $output);
};

post '/publish' => sub {
    my ($self) = (shift);
    $self->render( json => $self->mojito->publish_page($self->req->params->to_hash) );
};

get '/calendar/year/:year/month/:month' => sub {
    my ($self) = @_;
    my $params = {
        year  => $self->param('year'),
        month => $self->param('month'),
    };
    $self->render( text => $self->mojito->calendar_month_page($params) );
};

get '/calendar' => sub {
    my ($self) = (shift);
    $self->render( text => $self->mojito->calendar_month_page );
};

get '/recent' => sub {
    $_[0]->render( text => $_[0]->mojito->recent_links );
};

get '/' => sub {
    $_[0]->render( text => $_[0]->mojito->view_home_page );
};

get '/public/feed/:feed' => sub {
    $_[0]
      ->render( text => $_[0]->mojito->get_feed_links( $_[0]->param('feed') ) );
};

builder {
    my $config = Mojito::Model::Config->new->config;
    my $auth   = Mojito::Auth->new(config => $config);
    enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ }
    "Auth::Digest",
      realm           => "Mojito",
      secret          => $auth->_secret,
      password_hashed => 1,
      authenticator   => $auth->digest_authen_cb;
    enable "+Mojito::Middleware", config => $config;

    app->start;
};

