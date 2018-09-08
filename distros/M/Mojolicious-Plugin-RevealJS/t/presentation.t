use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'RevealJS';

get '/' => {
  template => 'hello_talk',
  layout => 'revealjs',
  title => 'Hello World!',
  author => 'JBERGER',
  description => 'Everybody ❤️ Mojolicious',
};

get '/hljs' => {
  template => 'hello_talk',
  layout => 'revealjs',
  hljs_theme_url => 'themes/cool_theme.css',
  title => 'Hello World!',
  author => 'JBERGER',
  description => 'Everybody ❤️ Mojolicious',
};

under '/reveal';

get '/nested_route' => {
  template => 'hello_talk',
  layout => 'revealjs',
  title => 'Hello World!',
  author => 'JBERGER',
  description => 'Everybody ❤️ Mojolicious',
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->text_is(title => 'Hello World!')
  ->element_exists('link[rel="stylesheet"][href="revealjs/css/reveal.css"]')
  ->element_exists('meta[name="author"][content="JBERGER"]')
  ->element_exists('meta[name="description"][content="Everybody ❤️ Mojolicious"]')
  ->text_is('.reveal .slides section:nth-child(1) h1' => 'A Mojolicious Hello World!')
  ->text_like('.reveal .slides section:nth-child(2) pre code.perl' => qr/use Mojolicious::Lite;/)
  ->text_is('.reveal .slides section:nth-child(2) p.filename' => 'code/hello.pl')
  ->text_is('.reveal .slides section:nth-child(3) p.filename' => 'code/raw.html')
  ->element_exists('.reveal .slides pre code.html', 'language class applied')
  ->element_exists_not('.reveal .slides pre code.html #raw', 'contents of included files are html escaped')
  ->text_is('.reveal .slides section#section-test p.filename' => 'code/section.pl')
  ->text_unlike('.reveal .slides section#section-test code' => qr/use/)
  ->text_like('.reveal .slides section#section-test code' => qr/\$this/)
  ->text_unlike('.reveal .slides section#section-test code' => qr/die/)
  ->text_unlike('.reveal .slides section#section-test code' => qr/reveal/)
  ->text_like('.reveal .slides section#no-section-test code' => qr/\$this/)
  ->text_like('.reveal .slides section#no-section-test code' => qr/die/)
  ->text_unlike('.reveal .slides section#no-section-test code' => qr/reveal/)
  ->element_exists_not('.reveal .slides section#no-include-filename p.filename')
  ->text_like('.reveal .slides section[data-markdown] script[type="text/template"]' => qr/An H2/)

  # reveal-sampler
  ->element_exists('.reveal .slides section#sample pre code[data-sample="code/section.pl"]')
  ->text_is('.reveal .slides section#sample p.sample-annotation' => 'code/section.pl')
  ->element_exists('.reveal .slides section#sample-all pre code[data-sample="code/section.pl"][data-sample-mark="3"][data-noescape][data-trim]')
  ->text_is('.reveal .slides section#sample-all p.sample-annotation' => 'my annotation')
  ->element_exists('.reveal .slides section#sample-no-anno pre code[data-sample="code/section.pl"]')
  ->element_exists_not('.reveal .slides section#sample-no-anno p.sample-annotation')
;

$t->get_ok('/hljs')
  ->status_is(200)
  ->text_is(title => 'Hello World!')
  ->element_exists('link[rel="stylesheet"][href="themes/cool_theme.css"]');

$t->get_ok('/reveal/nested_route')
  ->status_is(200)
  ->element_exists('base[href="/"]')
  ->element_exists('link[href="revealjs/css/reveal.css"]')
  ->element_exists('script[src="revealjs/lib/js/head.min.js"]');

done_testing;

__DATA__

@@ hello_talk.html.ep

%= section begin
  <h1>A Mojolicious Hello World!</h1>
% end

<section>
  %= include_code 'code/hello.pl'
</section>

<section>
  %= include_code 'code/raw.html', language => 'html'
<section>

<section id="section-test">
  %= include_code 'code/section.pl', section => 'mysection'
</section>

<section id="no-section-test">
  %= include_code 'code/section.pl'
</section>

<section id="no-include-filename">
  %= include_code 'code/section.pl', include_filename => 0
</section>

%= markdown_section begin
  ## An H2
% end

<section id="sample">
  %= include_sample 'code/section.pl'
</section>

<section id="sample-all">
  %= include_sample 'code/section.pl', mark => 3, noescape => 1, trim => 1, annotation => 'my annotation'
</section>

<section id="sample-no-anno">
  %= include_sample 'code/section.pl', annotation => undef
</section>

