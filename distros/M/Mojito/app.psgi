package MojitoApp;
use Web::Simple;
use Mojito;
use Mojito::Auth;
use Mojito::Model::Config;
use Mojito::Model::DB;
use JSON ();
use Encode ();
use Plack::Builder;
use Data::Dumper::Concise;

has 'my_config' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojito::Model::Config->new->config },
);
has 'my_db' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojito::Model::DB->new(config => $_[0]->my_config)->db },
);

sub dispatch_request {
    my ($self, $env) = @_;
    my $mojito = Mojito->new(
        base_url => $env->{mojito}->base_url,
        username => $env->{mojito}->username,
        config   => $env->{mojito}->config,
        db       => $self->my_db,
    );

    # A Benchmark URI
    sub (GET + /bench ) {
        my ($self) = @_;
        my $rendered_content = $mojito->bench;
        [ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
      },

      # PRESENT CREATE Page Form
      sub (GET + /page ) {
        my ($self) = @_;
        my $output = $mojito->fillin_create_page;
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },

      # CREATE New Page, redirect to Edit Page mode
      sub (POST + /page + %* ) {
        my ($self, $params) = @_;
        my $redirect_url = $mojito->create_page($params);
        [ 301, [ Location => $redirect_url ], [] ];
      },

      # VIEW a Page
      sub (GET + /page/* ) {
        my ($self, $id) = @_;
        my $rendered_page = Encode::encode_utf8($mojito->view_page({ id => $id }));
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$rendered_page] ];
      },

      sub (GET + /public/page/* ) {
        my ($self, $id) = @_;
        [
            200,
            [ 'Content-type', 'text/html; charset=utf-8' ],
            [ Encode::encode_utf8($mojito->view_page_public({ id => $id })) ]
        ];
      },

      # LIST Pages in chrono order
      sub (GET + /recent ) {
        my ($self) = @_;
        my $links = Encode::encode_utf8($mojito->recent_links);
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$links] ];
      },

      # PREVIEW Handler (and will save if save button is pushed).
      sub (POST + /preview + %*) {
        my ($self, $params) = @_;

        my $response_href = $mojito->preview_page($params);
        my $JSON_response = JSON::encode_json($response_href);

        [ 200, [ 'Content-type' => 'application/json; charset=utf-8' ], [$JSON_response] ];
      },

      # Present UPDATE Page Form
      sub (GET + /page/*/edit ) {
        my ($self, $id) = @_;
        my $output = Encode::encode_utf8($mojito->edit_page_form({ id => $id }));
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$output] ];
      },

      # UPDATE a Page
      sub (POST + /page/*/edit + %@collection_select~&*) {
        my ($self, $id, $collection_select, $params) = @_;
        $params->{collection_select} = $collection_select;
        $params->{id} = $id;
        my $redirect_url = $mojito->update_page($params);

        [ 301, [ Location => $redirect_url ], [] ];
      },

      # DELETE a Page
      sub (GET + /page/*/delete ) {
        my ($self, $id) = @_;
        [ 301, [ Location => $mojito->delete_page({ id => $id }) ], [] ];
      },

      # Diff a Page: $m and $n are the number of ^ we'll use from HEAD.
      # e.g diff/3/1 would mean git diff HEAD^^^ HEAD^ $page_id
      sub (GET + /page/*/diff/*/* ) {
        my ($self, $id, $m, $n) = @_;
        my $output = $mojito->view_page_diff({ id => $id, m => $m, n => $n });
        $output = Encode::encode_utf8($output);
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$output] ];
      },

      # Single word search
      sub (GET + /search/* ) {
        my ($self, $word) = @_;
        my $output = Encode::encode_utf8($mojito->search({ word => $word }));
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$output] ];
      },

      sub ( POST + /search + %* ) {
        my ($self, $params) = @_;
        my $output = $mojito->search($params);
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },

      sub ( GET + /collect ) {
        my ($self,) = @_;
        my $output = Encode::encode_utf8($mojito->collect_page_form());
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$output] ];
      },

      sub ( POST + /collect + %* ) {
        my ($self, $params) = @_;
        my $redirect_url = $mojito->collect($params);
        [ 301, [ Location => $redirect_url ], [] ];
      },

      sub ( GET + /collections ) {
        my ($self, $params) = @_;
        my $output = Encode::encode_utf8($mojito->collections_index());
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [$output] ];
      }, 

      sub ( GET + /collection/* ) {
        my ($self, $collection_id) = @_;
        my $output = $mojito->collection_page({ id => $collection_id });
        [ 200, [ 'Content-type', 'text/html; charset=utf-8' ], [Encode::encode_utf8($output)] ];
      },

      sub ( GET + /public/collection/* ) {
        my ($self, $collection_id) = @_;
        my $output =
          $mojito->collection_page({ public => 1, id => $collection_id });
          
        [ 200, [ 'Content-type' => 'text/html; charset=utf-8' ], [Encode::encode_utf8($output)] ];
      },

      sub ( GET + /collection/*/sort ) {
        my ($self, $collection_id) = @_;
        my $output = $mojito->sort_collection_form({ id => $collection_id });
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },

      sub ( POST + /collection/*/sort + %* ) {
        my ($self, $id, $params) = @_;
        $params->{id} = $id;
        my $redirect_url = $mojito->sort_collection($params);
        [ 301, [ Location => $redirect_url ], [] ];
      },

      sub ( GET + /collection/*/page/* ) {
        my ($self, $collection_id, $page_id) = @_;
        my $params = {
            collection_id => $collection_id,
            page_id       => $page_id
        };
        my $output = $mojito->view_page_collected($params);
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },

      sub ( GET + /public/collection/*/page/* ) {
        my ($self, $collection_id, $page_id) = @_;
        my $params = {
            public        => 1,
            collection_id => $collection_id,
            page_id       => $page_id
        };
        my $output = $mojito->view_page_collected($params);
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },

      sub ( GET + /collection/*/merge ) {
        my ($self, $collection_id) = @_;
        my $params = { collection_id => $collection_id, };
        my $output = $mojito->merge_collection($params);
        $output = Encode::encode_utf8($output);
        [ 200, [ 'Content-type', 'text/html; charset=utf-8' ], [$output] ];
      },

      sub ( GET + /collection/*/delete ) {
        my ($self, $collection_id) = @_;
        my $redirect_url =
          $mojito->delete_collection({ collection_id => $collection_id });
        [ 301, [ Location => $redirect_url ], [] ];
      },

      sub ( GET + /collection/*/epub ) {
        my ($self, $collection_id) = (shift, shift);

        my $output =
          $mojito->epub_collection({ collection_id => $collection_id });
        [
            200,
            [
                'Content-type' => 'application/octet-stream',
                'Content-Disposition' =>
                  "attachment; filename=collection_${collection_id}.epub",
            ],
            [$output]
        ];
      },

      sub ( POST + /publish + %* ) {
        my ($self, $params) = @_;
        my $response_href = $mojito->publish_page($params);
        my $JSON_response = JSON::encode_json($response_href);
        [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
      },
      
      sub ( GET + /calendar ) {
        [ 200, ['Content-type' => 'text/html; charset=utf-8'], [Encode::encode_utf8($mojito->calendar_month_page)] ];
      },

      sub ( GET + /calendar/year/*/month/* ) {
        my ($self, $year, $month) = @_;
        my $params;
        $params->{year} = $year;
        $params->{month} = $month;
        my $output = $mojito->calendar_month_page($params);
        $output = Encode::encode_utf8($output);
        [ 200, ['Content-type', 'text/html; charset=utf-8'], [$output] ];
      },
    
      sub (GET + /hola/* ) {
        my ($self, $name) = @_;
        [ 200, [ 'Content-type', 'text/plain' ], ["Ola $name"] ];
      },

      sub (GET + /) {
        my ($self) = @_;
        [ 200, [ 'Content-type', 'text/html; charset=utf-8' ], [ Encode::encode_utf8($mojito->view_home_page) ] ];
      },

      sub ( GET + /public/feed/*/format/* ) {
        my ($self, $feed_name, $feed_format) = @_;
        my $params;
        $params->{feed_name} = $feed_name;
        $params->{feed_format} = $feed_format;
        if (my $output = $mojito->feed_page($params)) {
            return [ 200, [ 'Content-type' => 'application/atom+xml' ], [$output] ];
        }
        else {
            return [ 200, [ 'Content-type' => 'text/html' ], ['No Feed Found'] ];
        }
      },

      sub (GET + /public/feed/*) {
        my ($self, $feed) = @_;
        [
            200,
            [ 'Content-type' => 'text/html; charset=utf-8' ],
            [ Encode::encode_utf8($mojito->get_feed_links($feed)) ]
        ];
      },

      sub (GET) {
        [ 200, [ 'Content-type', 'text/plain' ], ['Hola world!'] ];
      },

      sub () {
        [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
      },;
}

# Wrap in middleware here.
around 'to_psgi_app', sub {
    my ($orig, $self) = (shift, shift);
    my $app    = $self->$orig(@_);
    my $config = Mojito::Model::Config->new->config;
    my $auth   = Mojito::Auth->new(config => $config) ;
    builder {
        enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ }
        "Auth::Digest",
          realm           => "Mojito",
          secret          => $auth->_secret,
          password_hashed => 1,
          authenticator   => $auth->digest_authen_cb;
        enable "+Mojito::Middleware", config => $config;
        $app;
    };
};

__PACKAGE__->run_if_script;
