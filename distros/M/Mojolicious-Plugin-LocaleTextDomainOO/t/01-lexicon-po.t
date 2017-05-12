use Mojo::Base -strict;
use File::Spec;
use File::Basename;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use utf8;

plugin 'LocaleTextDomainOO',
  {
    file_type => 'po',
    default   => 'ja',
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

get '/'              => 'index';
get '/hello-ja'      => 'hello-ja';
get '/textdomain-ja' => 'textdomain-ja';

subtest 'for controller' => sub {
    is app->language, 'ja', 'right default language';
    is app->__('hello'), 'こんにちは', 'right msgid';
    my $str = app->N__('hello');
    is $str, 'hello', 'right N__';
    is app->__($str), 'こんにちは', 'right msgid';
    is app->language('en'), 'en', 'right change language';
    is app->language('ja'), 'ja', 'right change language';
};

subtest 'for templates' => sub {
    my $t = Test::Mojo->new;
    $t->get_ok('/hello-ja')
      ->text_is( 'div.ja'    => 'こんにちは',        'right msgid' )
      ->text_is( 'div.ja__p' => 'こんにちはmsgctxt', 'right msgctxt' )
      ->text_is(
        'div.ja__d' => 'こんにちはtestdomain',
        'right textdomain'
      )->text_is(
        'div.ja__begin_d' => 'こんにちはtestdomain',
        'right begin domain'
      )->text_is( 'div.en' => 'hello', 'right msgid' )
      ->text_is( 'div.en__x' => 'Hello, World!', 'right xgettext' );
};

subtest 'text domain' => sub {
    my $t = Test::Mojo->new;
    $t->get_ok('/textdomain-ja')
      ->content_is( "こんにちはtestdomain\n", 'right content' );
};

done_testing();

__DATA__

@@ hello-ja.html.ep
<div class="ja"><%= __ 'hello' %></div>
<div class="ja__p"><%= __p 'ctxt', 'hello' %></div>
<div class="ja__d"><%= __d 'testdomain', 'hello' %></div>

<%= __begin_d 'testdomain' %>
    <div class="ja__begin_d"><%= __ 'hello' %></div>
<%= __end_d %>

<%= language 'en' %>
<div class="en"><%= __ 'hello' %></div>
<div class="en__x"><%= __x 'hello, {name}', name => 'World' %></div>

@@ textdomain-ja.html.ep
<%= __begin_d 'testdomain' %><%= __ 'hello' %><%= __end_d %>
