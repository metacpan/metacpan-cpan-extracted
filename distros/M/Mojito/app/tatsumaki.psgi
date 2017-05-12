use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;
use Tatsumaki::Server;
use JSON;

package MainHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;
    $self->write( $self->request->env->{'mojito'}->view_home_page );
}

package HolaNameHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    $self->write(
        "<html><head><tite>$name</title></head><body>Hola $name</body></html>");
}

package BenchHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    $self->write( $self->request->env->{'mojito'}->bench );
}

package CreatePage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;
    $self->write( $self->request->env->{'mojito'}->fillin_create_page );
}

sub post {
    my ($self) = @_;
    my $redirect_url =
      $self->request->env->{'mojito'}
      ->create_page( $self->request->parameters );
    $self->response->redirect($redirect_url);
}

package PreviewPage;
use parent qw(Tatsumaki::Handler);

sub post {
    my ($self) = @_;
    $self->response->content_type('application/json');
    $self->write(
        JSON::encode_json(
            $self->request->env->{'mojito'}
              ->preview_page( $self->request->parameters )
        )
    );
}

package ViewPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write( $self->request->env->{'mojito'}->view_page( { id => $id } ) );
}

package ViewPagePublic;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write(
        $self->request->env->{'mojito'}->view_page_public( { id => $id } ) );
}

package EditPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write(
        $self->request->env->{'mojito'}->edit_page_form( { id => $id } ) );
}

sub post {
    my ( $self, $id ) = @_;

    my $params = $self->request->parameters;
    $params->{id} = $id;
    my $redirect_url = $self->request->env->{'mojito'}->update_page($params);

    $self->response->redirect($redirect_url);
}

package SearchPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $search_word ) = @_;
    $self->write(
        $self->request->env->{'mojito'}->search( { word => $search_word } ) );
}

package LastDiffPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = (shift);
    $self->write(
        $self->request->env->{'mojito'}->view_page_diff( { id => $_[0] } ) );
}

package DiffPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = (shift);
    $self->write( $self->request->env->{'mojito'}
          ->view_page_diff( { id => $_[0], m => $_[1], n => $_[2] } ) );
}

package RecentPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;
    my $links = $self->request->env->{'mojito'}->recent_links;
    $self->write($links);
}

package FeedPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $feed ) = @_;
    my $links = $self->request->env->{'mojito'}->get_feed_links($feed);
    $self->write($links);
}

package DeletePage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->response->redirect(
        $self->request->env->{mojito}->delete_page( { id => $id } ) );
}

package CollectPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, ) = @_;
    $self->write( $self->request->env->{'mojito'}->collect_page_form );
}

sub post {
    my ( $self, ) = @_;
    my $redirect_url = $self->request->env->{'mojito'}->collect($self->request->parameters);
    $self->response->redirect($redirect_url);
}

package CollectionPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $params->{id} = $id;
    $self->write($self->request->env->{'mojito'}->collection_page($params));
}

package PublicCollectionPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $params->{public} = 1;
    $params->{id} = $id;
    $self->write($self->request->env->{'mojito'}->collection_page($params));
}

package CollectionsIndex;
use parent qw(Tatsumaki::Handler);

sub get {
    my $self = (shift);
    $self->write($self->request->env->{'mojito'}->collections_index);
}

package SortCollection;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $params->{id} = $id;
    $self->write($self->request->env->{'mojito'}->sort_collection_form($params));
}

sub post {
    my ($self, $id) = @_;
    $params->{id} = $id;
    @{$params}{ keys %{$self->request->parameters} } = values %{$self->request->parameters};
    my $redirect_url = $self->request->env->{'mojito'}->sort_collection($params);
    $self->response->redirect($redirect_url);
}

package MergeCollection;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $collection_id ) = @_;
    $self->write($self->request->env->{'mojito'}->merge_collection( {collection_id => $collection_id} ));
}

package EPubCollection;
use parent qw(Tatsumaki::Handler);

# Overriding this class method to prevent get_chunk from Encoding the binary file.
sub get_chunk { $_[1] } 

sub get {
    my ( $self, $collection_id ) = @_;
    
    $params->{collection_id} = $collection_id;
    $self->response->headers([
        'content-type'        => 'application/epub+zip',
        'content_disposition' => "attachment; filename=collection_${collection_id}.epub"
    ]);
    my $epub_doc = $self->request->env->{'mojito'}->epub_collection($params);
#-mxh: binary() will work in future version in place of re-defining get_chunk()
#    $self->binary(1);
    $self->write($epub_doc);

}

package DeleteCollection;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self, $collection_id) = @_;
    my $redirect_url = $self->request->env->{'mojito'}->delete_collection({ collection_id => $collection_id });
    $self->response->redirect($redirect_url);
}

package CollectedPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $collection_id, $page_id ) = @_;
    $self->write($self->request->env->{'mojito'}->view_page_collected(
    { 
        collection_id => $collection_id, 
        page_id => $page_id
    }));
}

package PublicCollectedPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $collection_id, $page_id ) = @_;
    $self->write($self->request->env->{'mojito'}->view_page_collected(
    { 
        public        => 1,
        collection_id => $collection_id, 
        page_id       => $page_id
    }));
}

package PublishPage;
use parent qw(Tatsumaki::Handler);

sub post {
    my ($self, ) = @_;
    my $json = JSON::encode_json( $self->request->env->{'mojito'}->publish_page($self->request->parameters) );
    $self->write($json);
}

package CalendarMonth;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $year, $month ) = @_;
    my $params;
    $params->{year} = $year;
    $params->{month} = $month;
    $self->write($self->request->env->{'mojito'}->calendar_month_page($params));
}

package DefaultCalendarMonth;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self,  ) = @_;
    my $params;
    $self->write($self->request->env->{'mojito'}->calendar_month_page);
}

package main;
use Plack::Builder;
use Mojito;
use Mojito::Auth;
use Mojito::Model::Config;

my $app = Tatsumaki::Application->new(
    [
        '/'                            => 'MainHandler',
        '/hola/(\w+)'                  => 'HolaNameHandler',
        '/bench'                       => 'BenchHandler',
        '/recent'                      => 'RecentPage',
        '/page/(\w+)/edit'             => 'EditPage',
        '/page/(\w+)/delete'           => 'DeletePage',
        '/page/(\w+)'                  => 'ViewPage',
        '/public/page/(\w+)'           => 'ViewPagePublic',
        '/page'                        => 'CreatePage',
        '/preview'                     => 'PreviewPage',
        '/search/(\w+)'                => 'SearchPage',
        '/public/feed/(\w+)'           => 'FeedPage',
        '/page/(\w+)/diff/(\w+)/(\w+)' => 'DiffPage',
        '/page/(\w+)/diff'             => 'LastDiffPage',
        '/public/collection/(\w+)/page/(\w+)' => 'PublicCollectedPage',
        '/public/collection/(\w+)'     => 'PublicCollectionPage',
        '/collection/(\w+)/page/(\w+)' => 'CollectedPage',
        '/collection/(\w+)/sort'       => 'SortCollection',
        '/collection/(\w+)/merge'      => 'MergeCollection',
        '/collection/(\w+)/delete'     => 'DeleteCollection',
        '/collection/(\w+)/epub'       => 'EPubCollection',
        '/collection/(\w+)'            => 'CollectionPage',
        '/collections'                 => 'CollectionsIndex',
        '/collect'                     => 'CollectPage',
        '/publish'                     => 'PublishPage',
        '/calendar/year/(\d+)/month/(\d+)' => 'CalendarMonth',
        '/calendar'                    => 'DefaultCalendarMonth',
    ]
);

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

    $app;
};
