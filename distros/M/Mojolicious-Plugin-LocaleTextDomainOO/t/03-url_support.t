use Mojo::Base -strict;
use File::Spec;
use File::Basename;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use utf8;

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

get '/hello' => 'hello';

my $t = Test::Mojo->new;

$t->get_ok('/hello')->status_is(200)
  ->content_is( "こんにちはこんにちはmsgctxtja\n", 'right msgid' );

$t->get_ok('/ja/hello')->status_is(200)
  ->content_is( "こんにちはこんにちはmsgctxtja\n", 'right msgid' );

$t->get_ok('/en/hello')->status_is(200)
  ->content_is( "hellohelloen\n", 'right msgid' );

$t->get_ok('/es/hello')->status_is(404);

done_testing();

__DATA__

@@ hello.html.ep
<%= __ 'hello' %><%= __p 'ctxt', 'hello' %><%= language %>
