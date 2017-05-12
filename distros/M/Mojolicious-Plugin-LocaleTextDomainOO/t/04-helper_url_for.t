#######################################################
### This test script forked Mojolicious::Plugin::I18N
#######################################################

use Mojo::Base -strict;
use File::Spec;
use File::Basename;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use utf8;

# plugin
plugin 'LocaleTextDomainOO',
  {
    file_type         => 'po',
    default           => 'ja',
    support_url_langs => [qw(ja en de)]
  };

my $locale_dir = File::Spec->catdir( dirname(__FILE__), 'locale' );
app->lexicon(
    {
        search_dirs => [$locale_dir],
        decode      => 1,
        data        => [
            '*::'           => '*.po',
            '*::testdomain' => 'testdomain-*.po',    # TEXT DOMAIN
        ],
    }
);


get '/' => 'index';
get '/auth' => 'auth';
get '/test/:slug' => 'compat';

post '/login' => sub {
  my $self = shift;

  # Do login things ;)
  # ...

  $self->redirect_to($self->param('next') || 'index');
};

#

cmp_ok $Mojolicious::VERSION, '>=', 5.0, 'Check Mojolicious >= 5.0';

#

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
  ->content_is("こんにちはこんにちは２ja\n/\n/?test=1\n");

$t->get_ok('/ja')->status_is(200)
  ->content_is("こんにちはこんにちは２ja\n/ja\n/ja?test=1\n");

$t->get_ok('/en')->status_is(200)
  ->content_is("helloHello twoen\n/en\n/en?test=1\n");

$t->get_ok('/de')->status_is(200)
  ->content_is("こんにちはこんにちは２ja\n/de\n/de?test=1\n");

$t->get_ok('/es')->status_is(404);

$t->get_ok('/test/hello')->status_is(200)
  ->content_is(
	join "\n", qw(
		/test/hello
		/en/test/hello
		/en/test/hello
		/en/test/hello
		/en/test/hello
		/en/perldoc
		//mojolicio.us/en/perldoc
		http://mojolicio.us/perldoc
	), ''
  )
;

my $domain = $t->tx->remote_address;
my $port   = $t->tx->remote_port;

my $auth_next = $Mojolicious::VERSION >= 6.09 ? '%2Fauth' : '/auth';
$t->get_ok('/auth')->status_is(200)
  ->content_is(qq{<a href="http://example.com/widget?lang=ja&token_url=http://$domain:$port/login?next=$auth_next">auth</a>\n});

$t->post_ok('/login?next=/auth')->status_is(302)
  ->header_is('Location' => "/auth");

my $ja_auth_next = $Mojolicious::VERSION >= 6.09 ? '%2Fja%2Fauth' : '/ja/auth';
$t->get_ok('/ja/auth')->status_is(200)
  ->content_is(qq{<a href="http://example.com/widget?lang=ja&token_url=http://$domain:$port/ja/login?next=$ja_auth_next">auth</a>\n});

$t->post_ok('/login?next=/ja/auth')->status_is(302)
  ->header_is('Location' => "/ja/auth");

my $en_auth_next = $Mojolicious::VERSION >= 6.09 ? '%2Fen%2Fauth' : '/en/auth';
$t->get_ok('/en/auth')->status_is(200)
  ->content_is(qq{<a href="http://example.com/widget?lang=en&token_url=http://$domain:$port/en/login?next=$en_auth_next">auth</a>\n});

$t->post_ok('/login?next=/en/auth')->status_is(302)
  ->header_is('Location' => "/en/auth");

$t->post_ok('/login?next=/es/auth')->status_is(302)
  ->header_is('Location' => "/es/auth");

$t->post_ok('/login?next=/ja/en/auth')->status_is(302)
  ->header_is('Location' => "/ja/en/auth");

$t->post_ok('/login?next=/english/auth')->status_is(302)
  ->header_is('Location' => "/english/auth");

done_testing;

__DATA__
@@ index.html.ep
<%=__ 'hello' %><%=__ 'hello2' %><%= language %>
%= url_for
%= url_for->query(test => 1)

@@ auth.html.ep
<a href="http://example.com/widget?lang=<%= language %>&token_url=<%= url_for('login')->query('next' => url_for 'auth')->to_abs() %>">auth</a>

@@ compat.html.ep
%= url_for
%= url_for(slug => stash('slug'), lang => 'en')
%= url_for({slug => stash('slug'), lang => 'en'})
%= url_for('compat', slug => stash('slug'), lang => 'en')
%= url_for('compat', {slug => stash('slug'), lang => 'en'})
%= url_for('/perldoc', lang => 'en')
%= url_for('//mojolicio.us/perldoc', lang => 'en')
%= url_for('http://mojolicio.us/perldoc', lang => 'en')
