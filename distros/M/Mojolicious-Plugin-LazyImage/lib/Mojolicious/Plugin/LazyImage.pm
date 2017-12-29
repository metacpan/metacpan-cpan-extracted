package Mojolicious::Plugin::LazyImage;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader;
use Mojo::URL;

our $VERSION = '0.01';

sub lazy_image {
  my ($c, @args) = @_;
  $c->tag(noscript => class => 'js-lazy-image', sub { $c->image(@args) });
}

sub javascript { Mojo::Loader::data_section(__PACKAGE__, '/js/lazy-image.js') }

sub register {
  my ($self, $app, $config) = @_;
  my $helper = $config->{helper} || 'lazy_image';

  $app->helper($helper => \&lazy_image);

  $app->routes->get($config->{js_url} || '/js/lazy-image.js')
    ->name($config->{js_route_name} || $helper)->to(cb => \&_action_lazy_image_js);
}

sub _action_lazy_image_js { shift->render(data => __PACKAGE__->javascript) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LazyImage - Lazy load images

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin "LazyImage";
  get "/" => {title => "Test"}, "index";
  app->start;

  __DATA__
  @@ index.html.ep
  <html>
    <head>
      <title><%= title %></title>
      <style>
        .lazy-image { opacity: 1; transition: opacity 0.3s; }
        .lazy-image[data-src] { opacity: 0; }
      </style>
    </head>
    <body>
      %= lazy_image '/images/whatever.jpg'
      %= javascript 'lazy_image'
    </body>
  </html>

=head1 DESCRIPTION

L<Mojolicious::Plugin::LazyImage> is a L<Mojolicious> plugin to lazy load
images using JavaScript, but it also falls back to instantly load the images if
the user has disabled JavaScript. The fallback is simply implemented by the IMG
tag inside a NOSCRIPT tag.

For the users that have JavaScript enabled, the "lazy-image" JavaScript will
observer the NOSCRIPT tags and replace them with the IMG tag inside once they
get into the visible viewport.

The JavaScript require support for some recent web technologies, which might
not be supported by your users. The resource below should add the required
polyfills:

  <script src="https://cdn.polyfill.io/v2/polyfill.min.js?features=Element.prototype.classList,IntersectionObserver,MutationObserver"></script>

=head1 HELPERS

=head2 lazy_image

This helper works just like the L<Mojolicious::Plugin::TagHelpers/image>
helper, but wraps the result inside a NOSCRIPT tag.

=head1 METHODS

=head2 javascript

  $text = Mojolicious::Plugin::LazyImage->javascript;

Returns the JavaScript source code. You can also fetch the source code directly
using L<Mojo::Loader>, but this is currently EXPERIMENTAL:

  Mojo::Loader::data_section("Mojolicious::Plugin::LazyImage", "/js/lazy-image.js")

=head2 register

Used to register this plugin into the L<Mojolicious> application.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

__DATA__
@@ /js/lazy-image.js
(function(w, d) {
  var observer;

  w.initLazyImages = function() {
    if (!observer) observer = new IntersectionObserver(function(l) { l.forEach(w.initLazyImages.load) }, w.initLazyImages.observerArgs);

    var img, els = d.querySelectorAll("noscript.js-lazy-image");
    var div = d.createElement("div");
    for (var i = 0; i < els.length; i++) {
      div.innerHTML = els[i].textContent || els[i].innerHTML;
      img = div.firstChild;
      img.classList.add("lazy-image");
      img.setAttribute("data-src", img.src);
      img.setAttribute("src", w.initLazyImages.defaultSource);
      els[i].parentNode.replaceChild(img, els[i]);
      observer.observe(img);
    }
  };

  w.initLazyImages.defaultSource = "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==";
  w.initLazyImages.observerArgs = {rootMargin: "100px"};

  w.initLazyImages.load = function(entry) {
    if (!entry.isIntersecting) return;
    var img = entry.target;
    img.src = img.getAttribute("data-src");
    img.removeAttribute("data-src");
    observer.unobserve(img);
    if (w.initLazyImages.DEBUG) console.log("[lazyImage]", img);
  };

  w.addEventListener("DOMContentLoaded", w.initLazyImages);
})(window, document);
