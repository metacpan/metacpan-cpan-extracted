use Test::More (
  eval { require Test::Mojo::Role::Selenium; 1 }
    ? ()
    : ( skip_all => 'This test requires Test::Mojo::Role::Selenium' )
);

use Mojolicious::Lite;

plugin 'InlineJSON';

get '/' => sub {
  my $c = shift;
  $c->stash( the_data => { your => 'fez', is => '> 5' });
  $c->render;
}, 'test';

get '/arrayref' => sub {
  my $c = shift;
  $c->stash( the_data => [ your => 'fez' ]);
  $c->render('test');
};

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw/curfile/;

my $t = Test::Mojo->with_roles('+Selenium')
  ->new->setup_or_skip_all;


$t->navigate_ok('/')
  ->wait_for('#js-data-your');
for my $type (qw/js-data js-data-via-json/) {
  $t->live_text_is("#$type-your .key", '"your"')
    ->live_text_is("#$type-your .val", '"fez"')
    ->live_text_is("#$type-is .key", '"is"')
    ->live_text_is("#$type-is .val", '"> 5"');
}

$t->navigate_ok('/arrayref')
  ->wait_for('#js-data-0');

for my $type (qw/js-data js-data-via-json/) {
  $t->live_text_is("#$type-0 .key", '"0"')
    ->live_text_is("#$type-0 .val", '"your"')
    ->live_text_is("#$type-1 .key", '"1"')
    ->live_text_is("#$type-1 .val", '"fez"');
}



done_testing;

__DATA__

@@test.html.ep
<head>
<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
</head>
<body>
  <div id="app">
    <h1> Using js_data </h1>
    <div :id="'js-data-' + key" v-for="(val, key) in jsData" :key="key">
      The key is <span class="key"> "{{ key }}" </span>
        and the value is <span class="val"> "{{ val }}" </val>
    </div>
    <hr>
    <h1> Using js_data_via_json </h1>
    <div :id="'js-data-via-json-' + key" v-for="(val, key) in jsonData"
      :key="key">
      The key is <span class="key"> "{{ key }}" </span>
        and the value is <span class="val"> "{{ val }}" </val>
    </div>
  </div>
</body>
<script>
  var app = new Vue({
    el: '#app',
    data: {
      jsData: <%= js_data($the_data) %>,
      jsonData: <%= js_data_via_json($the_data) %>
    }
  })
</script>
