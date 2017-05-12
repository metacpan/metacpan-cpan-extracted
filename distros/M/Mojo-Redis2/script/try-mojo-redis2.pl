#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Redis2;
use Mojo::JSON 'j';

helper redis => sub { shift->stash->{redis} ||= Mojo::Redis2->new; };

get '/' => sub {
  my $c = shift;

  if (my $method = $c->param('method')) {
    my $args = $c->param('args') // '';
    $args =~ s!(\w+)\s*=>!"$1",!g;
    $args = j qq([$args]);
    eval {
      die 'Invalid arguments' unless ref $args;
      die 'Invalid method' unless $method =~ /^\w+$/;
      $c->render('test', output => $c->redis->$method(@$args));
    } or do {
      $@ =~ s!\sat\s\S+.*!.!s;
      $c->render('test', error => $@);
    };
  }
  else {
    $c->render('test');
  }
};

app->defaults(error => '');
app->start;

__DATA__
@@ test.html.ep
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Mojo::Redis2 demo</title>
  <style>
    body { margin: 3em; }
    body { background: #2B2B36; color: #838394; font-family: "Helvetica Neue", sans-serif; font-size: 14px; }
    a { color: #a3a3a4; }
    input, button, pre, .input { background: #2B2B36; color: #838394; font-family: Menlo, "monospace"; font-size: 14px; }
    input, pre { background: #1B1B26; border: 0; }
    button { background: #8B8B96; color: #000; border: 1px solid #1B1B26; }
    .tmp { position: absolute; top: -1000px; }
    #content { max-width: 60em; }
  </style>
  <script>
    window.addEventListener('load', function(e) {
      var inputs = ['method', 'args'];
      for (i = 0; i < inputs.length; i++) {
        var input = document.getElementById(inputs[i]);
        input.addEventListener('keydown', function(e) {
          var tmp = document.createElement('div');
          tmp.appendChild(document.createTextNode(e.target.value + String.fromCharCode(e.keyCode)));
          tmp.className = 'tmp input';
          e.target.parentNode.appendChild(tmp);
          e.target.style.width = (tmp.clientWidth > 24 ? tmp.clientWidth : 24) + 'px';
          e.target.parentNode.removeChild(tmp);
        });
        input.dispatchEvent(new Event('keydown'));
      }
      document.getElementById('method').focus();
    });
  </script>
</head>
<body>
<div id="content">
  %= form_for '/', begin
<h1>Try Mojo::Redis2</h1>
<code>$redis-&gt;</code>\
<%= text_field 'method', id => 'method', value => 'get', autocomplete => 'off' %>\
<code>(</code>\
<%= text_field 'args', id => 'args', value => '"foo"', autocomplete => 'off' %>\
<code>);</code>
<button>Run</button>
% if (exists stash->{output} or $error) {
<h2>Output</h2>
% if ($error) {
<p><%= $error %>
% }
% local $Data::Dumper::Maxdepth = 3;
<pre><%= dumper stash 'output' %></pre>
% } else {
<p>
  Tip:
  Click on the method name and arguments to edit.
  Call the <%= link_to 'method', 'https://github.com/jhthorsen/mojo-redis2#readme' %>
  you like with any given arguments and click on "Run" to run the code.
</p>
% }
  % end
<h2>Examples</h2>
<ul>
  <li><%= link_to '$redis->set(foo => 42)', url_for->query({ method => 'set', args => 'foo => 42' }) %></li>
  <li><%= link_to '$redis->get("foo")', url_for->query({ method => 'get', args => '"foo"' }) %></li>
  <li><%= link_to '$redis->keys("*")', url_for->query({ method => 'keys', args => '"*"' }) %></li>
</ul>
</div>
</body>
</html>
