package Mojolicious::Plugin::PODViewer;
our $VERSION = '0.006';
# ABSTRACT: POD renderer plugin

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # Mojolicious (with documentation browser under "/perldoc")
#pod   my $route = $app->plugin('PODViewer');
#pod   my $route = $app->plugin(PODViewer => {name => 'foo'});
#pod   my $route = $app->plugin(PODViewer => {preprocess => 'epl'});
#pod
#pod   # Mojolicious::Lite (with documentation browser under "/perldoc")
#pod   my $route = plugin 'PODViewer';
#pod   my $route = plugin PODViewer => {name => 'foo'};
#pod   my $route = plugin PODViewer => {preprocess => 'epl'};
#pod
#pod   # Without documentation browser
#pod   plugin PODViewer => {no_perldoc => 1};
#pod
#pod   # foo.html.ep
#pod   %= pod_to_html "=head1 TEST\n\nC<123>"
#pod
#pod   # foo.html.pod
#pod   =head1 <%= uc 'test' %>
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Mojolicious::Plugin::PODViewer> is a renderer for Perl's POD (Plain
#pod Old Documentation) format. It includes a browser to browse the Perl
#pod module documentation as a website.
#pod
#pod This is a fork of the (deprecated) L<Mojolicious::Plugin::PODRenderer>.
#pod
#pod =head1 OPTIONS
#pod
#pod L<Mojolicious::Plugin::PODViewer> supports the following options.
#pod
#pod =head2 name
#pod
#pod   # Mojolicious::Lite
#pod   plugin PODViewer => {name => 'foo'};
#pod
#pod Handler name, defaults to C<pod>.
#pod
#pod =head2 route
#pod
#pod The L<route|Mojolicious::Routes::Route> to add documentation to. Defaults to
#pod C<< $app->routes->any('/perldoc') >>. The new route will have a name of
#pod C<plugin.podviewer>.
#pod
#pod =head2 default_module
#pod
#pod The default module to show. Defaults to C<Mojolicious::Guides>.
#pod
#pod =head2 allow_modules
#pod
#pod An arrayref of regular expressions that match modules to allow. At least
#pod one of the regular expressions must match. Disallowed modules will be
#pod redirected to the appropriate page on L<http://metacpan.org>.
#pod
#pod =head2 layout
#pod
#pod The layout to use. Defaults to C<podviewer>.
#pod
#pod =head2 no_perldoc
#pod
#pod   # Mojolicious::Lite
#pod   plugin PODViewer => {no_perldoc => 1};
#pod
#pod Disable L<Mojolicious::Guides> documentation browser that will otherwise be
#pod available under C</perldoc>.
#pod
#pod =head2 preprocess
#pod
#pod   # Mojolicious::Lite
#pod   plugin PODViewer => {preprocess => 'epl'};
#pod
#pod Name of handler used to preprocess POD, defaults to C<ep>.
#pod
#pod =head1 HELPERS
#pod
#pod L<Mojolicious::Plugin::PODViewer> implements the following helpers.
#pod
#pod =head2 pod_to_html
#pod
#pod   %= pod_to_html '=head2 lalala'
#pod   <%= pod_to_html begin %>=head2 lalala<% end %>
#pod
#pod Render POD to HTML without preprocessing.
#pod
#pod =head1 TEMPLATES
#pod
#pod L<Mojolicious::Plugin::PODViewer> bundles the following templates. To
#pod override this template with your own, create a template with the same name.
#pod
#pod =head2 podviewer/perldoc.html.ep
#pod
#pod This template displays the POD for a module. The HTML for the documentation
#pod is in the C<perldoc> content section (C<< <%= content 'perldoc' %> >>).
#pod The template has the following stash values:
#pod
#pod =over
#pod
#pod =item module
#pod
#pod The current module, with parts separated by C</>.
#pod
#pod =item cpan
#pod
#pod A link to L<http://metacpan.org> for the current module.
#pod
#pod =item topics
#pod
#pod An array of arrays of topics in the documentation. Each inner array is
#pod a set of pairs of C<link text> and C<link href> suitable to be passed
#pod directly to the C<link_to> helper. New topics are started by a C<=head1>
#pod tag, and include all lower-level headings.
#pod
#pod =back
#pod
#pod =head2 layouts/podviewer.html.ep
#pod
#pod The layout for rendering POD pages. Use this to add stylesheets,
#pod JavaScript, and additional navigation. Set the C<layout> option to
#pod change this template.
#pod
#pod =head1 METHODS
#pod
#pod L<Mojolicious::Plugin::PODViewer> inherits all methods from
#pod L<Mojolicious::Plugin> and implements the following new ones.
#pod
#pod =head2 register
#pod
#pod   my $route = $plugin->register(Mojolicious->new);
#pod   my $route = $plugin->register(Mojolicious->new, {name => 'foo'});
#pod
#pod Register renderer and helper in L<Mojolicious> application.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.
#pod
#pod =cut
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Asset::File;
use Mojo::ByteStream;
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::URL;
use Pod::Simple::XHTML;
use Pod::Simple::Search;

sub register {
  my ($self, $app, $conf) = @_;

  my $preprocess = $conf->{preprocess} || 'ep';
  $app->renderer->add_handler(
    $conf->{name} || 'pod' => sub {
      my ($renderer, $c, $output, $options) = @_;
      $renderer->handlers->{$preprocess}($renderer, $c, $output, $options);
      $$output = _pod_to_html($$output) if defined $$output;
    }
  );

  $app->helper(
    pod_to_html => sub { shift; Mojo::ByteStream->new(_pod_to_html(@_)) });

  # Perldoc browser
  return undef if $conf->{no_perldoc};

  push @{ $app->renderer->classes }, __PACKAGE__;
  my $default_module = $conf->{default_module} // 'Mojolicious::Guides';
  $default_module =~ s{::}{/}g;

  my $defaults = {
      module => $default_module,
      ( $conf->{layout} ? ( layout => $conf->{layout} ) : () ),
      allow_modules => $conf->{allow_modules} // [ qr{} ],
  };
  my $route = $conf->{route} ||= $app->routes->any( '/perldoc' );
  return $route->any( '/:module' =>
      $defaults => [module => qr/[^.]+/] => \&_perldoc,
  )->name('plugin.podviewer');
}

sub _indentation {
  (sort map {/^(\s+)/} @{shift()})[0];
}

sub _html {
  my ($c, $src) = @_;

  # Rewrite links
  my $dom  = Mojo::DOM->new(_pod_to_html($src));
  my $base = 'https://metacpan.org/pod/';
  $dom->find('a[href]')->map('attr')->each(sub {
    if ($_->{href} =~ m!^\Q$base\E([:\w]+)!) {
      my $module = $1;
      return undef
        unless grep { $module =~ /$_/ } @{ $c->stash('allow_modules') || [] };
      $_->{href} =~ s{^\Q$base$module\E}{$c->url_for(module => $module)}e;
      $_->{href} =~ s!::!/!gi
    }
  });

  # Rewrite code blocks for syntax highlighting and correct indentation
  for my $e ($dom->find('pre > code')->each) {
    next if (my $str = $e->content) =~ /^\s*(?:\$|Usage:)\s+/m;
    next unless $str =~ /[\$\@\%]\w|-&gt;\w|^use\s+\w/m;
    my $attrs = $e->attr;
    my $class = $attrs->{class};
    $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
  }

  # Rewrite headers
  my $toc = Mojo::URL->new->fragment('toc');
  my @topics;
  for my $e ($dom->find('h1, h2, h3, h4')->each) {

    push @topics, [] if $e->tag eq 'h1' || !@topics;
    my $link = Mojo::URL->new->fragment($e->{id});
    push @{$topics[-1]}, my $text = $e->all_text, $link;
    my $permalink = $c->link_to('#' => $link, class => 'permalink');
    $e->content($permalink . $c->link_to($text => $toc));
  }

  # Try to find a title
  my $title = 'Perldoc';
  $dom->find('h1 + p')->first(sub { $title = shift->all_text });

  # Combine everything to a proper response
  $c->content_for(perldoc => "$dom");
  $c->render('podviewer/perldoc', title => $title, topics => \@topics);
}

sub _perldoc {
  my $c = shift;

  # Find module or redirect to CPAN
  my $module = join '::', split('/', $c->param('module'));
  $c->stash(cpan => "https://metacpan.org/pod/$module");

  return $c->redirect_to( $c->stash( 'cpan' ) )
    unless grep { $module =~ /$_/ } @{ $c->stash( 'allow_modules' ) || [] };

  my $path
    = Pod::Simple::Search->new->find($module, map { $_, "$_/pods" } @INC);
  return $c->redirect_to($c->stash('cpan')) unless $path && -r $path;

  $c->stash->{layout} //= 'podviewer';
  my $src = path($path)->slurp;
  $c->respond_to(txt => {data => $src}, html => sub { _html($c, $src) });
}

sub _pod_to_html {
  return '' unless defined(my $pod = ref $_[0] eq 'CODE' ? shift->() : shift);

  my $parser = Pod::Simple::XHTML->new;
  $parser->perldoc_url_prefix('https://metacpan.org/pod/');
  $parser->$_('') for qw(html_header html_footer);
  $parser->strip_verbatim_indent(\&_indentation);
  $parser->output_string(\(my $output));
  return $@ unless eval { $parser->parse_string_document("$pod"); 1 };

  return $output;
}

1;

=pod

=head1 NAME

Mojolicious::Plugin::PODViewer - POD renderer plugin

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # Mojolicious (with documentation browser under "/perldoc")
  my $route = $app->plugin('PODViewer');
  my $route = $app->plugin(PODViewer => {name => 'foo'});
  my $route = $app->plugin(PODViewer => {preprocess => 'epl'});

  # Mojolicious::Lite (with documentation browser under "/perldoc")
  my $route = plugin 'PODViewer';
  my $route = plugin PODViewer => {name => 'foo'};
  my $route = plugin PODViewer => {preprocess => 'epl'};

  # Without documentation browser
  plugin PODViewer => {no_perldoc => 1};

  # foo.html.ep
  %= pod_to_html "=head1 TEST\n\nC<123>"

  # foo.html.pod
  =head1 <%= uc 'test' %>

=head1 DESCRIPTION

L<Mojolicious::Plugin::PODViewer> is a renderer for Perl's POD (Plain
Old Documentation) format. It includes a browser to browse the Perl
module documentation as a website.

This is a fork of the (deprecated) L<Mojolicious::Plugin::PODRenderer>.

=encoding utf8

=head1 OPTIONS

L<Mojolicious::Plugin::PODViewer> supports the following options.

=head2 name

  # Mojolicious::Lite
  plugin PODViewer => {name => 'foo'};

Handler name, defaults to C<pod>.

=head2 route

The L<route|Mojolicious::Routes::Route> to add documentation to. Defaults to
C<< $app->routes->any('/perldoc') >>. The new route will have a name of
C<plugin.podviewer>.

=head2 default_module

The default module to show. Defaults to C<Mojolicious::Guides>.

=head2 allow_modules

An arrayref of regular expressions that match modules to allow. At least
one of the regular expressions must match. Disallowed modules will be
redirected to the appropriate page on L<http://metacpan.org>.

=head2 layout

The layout to use. Defaults to C<podviewer>.

=head2 no_perldoc

  # Mojolicious::Lite
  plugin PODViewer => {no_perldoc => 1};

Disable L<Mojolicious::Guides> documentation browser that will otherwise be
available under C</perldoc>.

=head2 preprocess

  # Mojolicious::Lite
  plugin PODViewer => {preprocess => 'epl'};

Name of handler used to preprocess POD, defaults to C<ep>.

=head1 HELPERS

L<Mojolicious::Plugin::PODViewer> implements the following helpers.

=head2 pod_to_html

  %= pod_to_html '=head2 lalala'
  <%= pod_to_html begin %>=head2 lalala<% end %>

Render POD to HTML without preprocessing.

=head1 TEMPLATES

L<Mojolicious::Plugin::PODViewer> bundles the following templates. To
override this template with your own, create a template with the same name.

=head2 podviewer/perldoc.html.ep

This template displays the POD for a module. The HTML for the documentation
is in the C<perldoc> content section (C<< <%= content 'perldoc' %> >>).
The template has the following stash values:

=over

=item module

The current module, with parts separated by C</>.

=item cpan

A link to L<http://metacpan.org> for the current module.

=item topics

An array of arrays of topics in the documentation. Each inner array is
a set of pairs of C<link text> and C<link href> suitable to be passed
directly to the C<link_to> helper. New topics are started by a C<=head1>
tag, and include all lower-level headings.

=back

=head2 layouts/podviewer.html.ep

The layout for rendering POD pages. Use this to add stylesheets,
JavaScript, and additional navigation. Set the C<layout> option to
change this template.

=head1 METHODS

L<Mojolicious::Plugin::PODViewer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  my $route = $plugin->register(Mojolicious->new);
  my $route = $plugin->register(Mojolicious->new, {name => 'foo'});

Register renderer and helper in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHORS

=over 4

=item *

Sebastian Riedel <kraih@mojolicious.org>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords brad CandyAngel Luc Didry Oleg Tekki Zoffix Znet

=over 4

=item *

brad <brad@clickmagick.com>

=item *

CandyAngel <candyangel@electricjungle.org>

=item *

Luc Didry <luc@didry.org>

=item *

Oleg <verdrehung@gmail.com>

=item *

Tekki <tekki@tekki.ch>

=item *

Zoffix Znet <cpan@zoffix.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Sebastian Riedel, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ layouts/podviewer.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title><%= title %></title>
    </head>
    <body>
    %= content
    </body>
</html>

@@ podviewer/perldoc.html.ep
<div class="crumbs">
    % my $path = '';
    % for my $part (split '/', $module) {
        %= '::' if $path
        % $path .= $path ? "/$part" : $part;
        %= link_to $part => 'plugin.podviewer', { module => $path }
    % }
    <span class="more">
        (<%= link_to 'source' => 'plugin.podviewer',
          { module => $module, format => 'txt' } %>,
        <%= link_to 'CPAN' => $cpan %>)
    </span>
</div>

<h1><a id="toc">CONTENTS</a></h1>
<ul>
    % for my $topic (@$topics) {
        <li>
            %= link_to splice(@$topic, 0, 2)
            % if (@$topic) {
                <ul>
                    % while (@$topic) {
                        <li><%= link_to splice(@$topic, 0, 2) %></li>
                    % }
                </ul>
            % }
        </li>
    % }
</ul>

%= content 'perldoc'
