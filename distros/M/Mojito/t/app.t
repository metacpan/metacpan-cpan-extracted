use strictures 1;
use 5.010;
use Plack::Test;
use Plack::Util;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use JSON;
use FindBin qw($Bin);
use Data::Dumper::Concise;

# Monkey patch Auth::Digest during testing to let me in the door.
BEGIN {
    if ( !$ENV{AUTHORZ_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for author testing' );
    }

    use Plack::Middleware::Auth::Digest;
    no warnings 'redefine';
    *Plack::Middleware::Auth::Digest::call = sub {
        my ( $self, $env ) = @_;
        $env->{REMOTE_USER} = 'hunter';
        return $self->app->($env);
    };

}
my %framework_scripts = (
    web_simple => '../app.psgi',
#    dancer     => 'dancer.pl',
#    mojo       => 'mojo.pl',
#    tatsumaki  => 'tatsumaki.psgi'
);
my $base_path = "$Bin/../app/";
my @app_files = map { $base_path . $framework_scripts{$_} } keys %framework_scripts;

if ( my $framework = $ARGV[0] ) {
    my $app = "$Bin/../app/" . $framework_scripts{$framework};
    @app_files = ($app);
}

foreach my $app_file (@app_files) {
    my $app = Plack::Util::load_psgi $app_file;
    test_psgi
      app    => $app,
      client => sub {
        my $client_cb = shift;

        my $request = HTTP::Request->new( GET => '/public/feed/ironman' );
        my $response = $client_cb->($request);
        is $response->code, 200, 'feed status';
        like $response->content, qr/(Articles|empty)/, 'feed content';

        $request = HTTP::Request->new( GET => '/' );
        $response = $client_cb->($request);
        is $response->code, 200, 'home page status';
        like $response->content, qr/Recent Articles/, 'home page content';

        $request = HTTP::Request->new( GET => '/page' );
        $response = $client_cb->($request);
        is $response->code, 200, 'create page status';
        like $response->content, qr/id="edit_area"/, 'create page content';

        $request = POST '/page',
          [ content => "h1. Perl Rocks", wiki_language => 'textile' ];
        $response = $client_cb->($request);
        like $response->code, qr/^(?:301|302)$/, 'post create page redirect';
        
        $request = HTTP::Request->new( GET => '/calendar' );
        $response = $client_cb->($request);
        is $response->code,      200,            'calendar page status';
        like $response->content, qr/Previous Month/, 'calendar page navigation content';

        $request = HTTP::Request->new( GET => '/recent' );
        $response = $client_cb->($request);
        is $response->code,      200,            'recent page status';
        like $response->content, qr/Perl Rocks/, 'recent page content';

        # Let's get page id from the recent page
        # so we can request a specific page then delete it.
        my $content = $response->content;
        my ($id) = $content =~ m!<a href="/page/(\w+)">Perl Rocks</a>!;
        $request = HTTP::Request->new( GET => "/page/${id}" );
        $response = $client_cb->($request);
        is $response->code,      200,            "page ${id} GET status";
        like $response->content, qr/Perl Rocks/, "page ${id} content";

        $request = HTTP::Request->new( GET => "/page/${id}/edit" );
        $response = $client_cb->($request);
        is $response->code, 200, 'edit page status';

        $request = POST "/page/${id}/edit",
          [
            content        => "h1. Perl Rolls",
            wiki_language  => 'textile',
            commit_message => 'note the flexibility of Perl',
          ];
        $response = $client_cb->($request);
        like $response->code, qr/^(?:301|302)$/, 'post edit page redirect';

        $request = HTTP::Request->new( GET => "/page/${id}" );
        $response = $client_cb->($request);
        is $response->code,      200,            'get edited page status';
        like $response->content, qr/Perl Rolls/, 'edited page content';

        $request = HTTP::Request->new( GET => "/search/Perl" );
        $response = $client_cb->($request);
        is $response->code,      200,            'search results';
        like $response->content, qr/Perl Rolls/, 'search hit';

        $request = HTTP::Request->new( GET => "/page/${id}/delete" );
        $response = $client_cb->($request);
        like $response->code, qr/^(?:301|302)$/, 'delete page redirect';

        $request = HTTP::Request->new( GET => '/recent' );
        $response = $client_cb->($request);
        is $response->code,        200,       'recent page status';
        unlike $response->content, qr/${id}/, "page ${id} not on recent page";

        $request = POST '/preview',
          [ content => '*Bom dia*', wiki_language => 'textile' ];
        $response = $client_cb->($request);
        is $response->code, 200, 'preview page status';
        my $hashref = decode_json( $response->content );
        is $hashref->{rendered_content}, '<p><strong>Bom dia</strong></p>',
          'preview page content';
      };
}

done_testing;
