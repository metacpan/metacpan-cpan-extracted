package Mojolicious::Plugin::DOCRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojo::Asset::File;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::URL;
use Mojo::Util qw(slurp unindent url_escape);
use Pod::Simple::HTML;
use Pod::Simple::Search;

our $VERSION = '4.00';

# "Futurama - The One Bright Spot in Your Life!"
sub register {
  my ($self, $app, $conf) = @_;

  # Add "doc" handler
  my $preprocess = $conf->{preprocess} || 'ep';
  $app->renderer->add_handler(
    $conf->{name} || 'doc' => sub {
      my ($renderer, $c, $output, $options) = @_;

      # Preprocess and render
      my $handler = $renderer->handlers->{$preprocess};
      return undef unless $handler->($renderer, $c, $output, $options);
      $$output = _pod_to_html($$output);
      return 1;
    }
  );

  # Append "templates" and "public" directories
  push @{$app->renderer->paths}, catdir(dirname(__FILE__), 'DOCRenderer', 'templates');

  # Doc
  my $url    = $conf->{url}    || '/doc';
  my $module = $conf->{module} || $ENV{MOJO_APP};
  my $defaults = {url => $url, module => $module, format => 'html'};
  return $app->routes->any(
    "$url/:module" => $defaults => [module => qr/[^.]+/] => \&_doc);
}

sub _html {
  my ($self, $src) = @_;

  # Rewrite links
  my $dom = Mojo::DOM->new(_pod_to_html($src));
  my $doc = $self->url_for( $self->param('url') . '/' );
  for my $e ($dom->find('a[href]')->each) {
    my $attrs = $e->attr;
    $attrs->{href} =~ s!%3A%3A!/!gi
      if $attrs->{href} =~ s!^http://search\.cpan\.org/perldoc\?!$doc!;
  }

  # Rewrite code blocks for syntax highlighting and correct indentation
  for my $e ($dom->find('pre')->each) {
    $e->content(my $str = unindent $e->content);
    next if $str =~ /^\s*(?:\$|Usage:)\s+/m || $str !~ /[\$\@\%]\w|-&gt;\w/m;
    my $attrs = $e->attr;
    my $class = $attrs->{class};
    $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
  }

  # Rewrite headers
  my $toc = Mojo::URL->new->fragment('toc');
  my (%anchors, @parts);
  for my $e ($dom->find('h1, h2, h3')->each) {

    # Anchor and text
    my $name = my $text = $e->all_text;
    $name =~ s/\s+/_/g;
    $name =~ s/[^\w\-]//g;
    my $anchor = $name;
    my $i      = 1;
    $anchor = $name . $i++ while $anchors{$anchor}++;

    # Rewrite
    push @parts, [] if $e->type eq 'h1' || !@parts;
    my $link = Mojo::URL->new->fragment($anchor);
    push @{$parts[-1]}, $text, $link;
    my $permalink = $self->link_to('#' => $link, class => 'permalink');
    $e->content($permalink . $self->link_to($text => $toc, id => $anchor));
  }

  # Try to find a title
  my $title = 'Doc';
  $dom->find('h1 + p')->first(sub { $title = shift->text });

  # Combine everything to a proper response
  $self->content_for(doc => "$dom");
  $self->render(title => $title, parts => \@parts);
}

sub _doc {
  my $self = shift;

  # Find module or redirect to CPAN
  my $module = $self->param('module');
  $module =~ s!/!::!g;
  my $path
    = Pod::Simple::Search->new->find($module, map { $_, "$_/pods" } @INC);
  return $self->redirect_to("http://metacpan.org/module/$module")
    unless $path && -r $path;

  my $src = slurp $path;
  $self->respond_to(txt => {data => $src}, any => sub { _html($self, $src) });
}

sub _pod_to_html {
  return '' unless defined(my $pod = ref $_[0] eq 'CODE' ? shift->() : shift);

  my $parser = Pod::Simple::HTML->new;
  $parser->$_('') for qw(force_title html_header_before_title);
  $parser->$_('') for qw(html_header_after_title html_footer);
  $parser->output_string(\(my $output));
  return $@ unless eval { $parser->parse_string_document("$pod"); 1 };

  # Filter
  $output =~ s!<a name='___top' class='dummyTopAnchor'\s*?></a>\n!!g;
  $output =~ s!<a class='u'.*?name=".*?"\s*>(.*?)</a>!$1!sg;

  return $output;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DOCRenderer - Doc Renderer Plugin

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'DOCRenderer';
  plugin DOCRenderer => {module => 'MyApp'};
  plugin DOCRenderer => {name => 'foo'};
  plugin DOCRenderer => {url => '/mydoc'};
  plugin DOCRenderer => {preprocess => 'epl'};

  # Mojolicious
  $self->plugin('DOCRenderer');
  $self->plugin(DOCRenderer => {module => 'MyApp'});
  $self->plugin(DOCRenderer => {name => 'foo'});
  $self->plugin(DOCRenderer => {url => '/mydoc'});
  $self->plugin(DOCRenderer => {preprocess => 'epl'});

  #############################
  # Mojolicious::Lite example #
  #############################
  use Mojolicious::Lite;
  use File::Basename;

  plugin 'DOCRenderer' => {
      # use this script base name as a default module to show for "/doc"
      module => fileparse( __FILE__, qr/\.[^.]*/ );
  };

  app->start;

  __END__

  =head1 NAME

  MyApp - My Mojolicious::Lite Application

=head1 DESCRIPTION

  This documentation will be available online, for example from L<http://localhost:3000/doc>.

  =cut

  #######################
  # Mojolicious example #
  #######################
  package MyApp;
  use Mojo::Base 'Mojolicious';

  sub development_mode {
    # Enable browsing of "/doc" only in development mode
    shift->plugin( 'DOCRenderer' );
  }

  sub startup {
    my $self = shift;
    # some code
  }

  __END__

  =head1 NAME

  MyApp - My Mojolicious Application

  =head1 DESCRIPTION

  This documentation will be available online, for example from L<http://localhost:3000/doc>.

  =cut

=head1 DESCRIPTION

L<Mojolicious::Plugin::DOCRenderer> generates on-the-fly and browses online
POD documentation directly from your Mojolicious application source codes
and makes it available under I</doc> (customizable).

The plugin expects that you use POD to document your codes of course.

The plugin is simple modification of L<Mojolicious::Plugin::PODRenderer>.

=head1 OPTIONS

=head2 C<module>

  # Mojolicious::Lite
  plugin DOCRenderer => {module => 'MyApp'};

Name of the module to initially display. Default is C<$ENV{MOJO_APP}>.
Mojolicious::Lite application may have undefined C<$ENV{MOJO_APP}>; in such
case you should set C<module>, see Mojolicious::Lite example.

=head2 C<name>

  # Mojolicious::Lite
  plugin DOCRenderer => {name => 'foo'};

Handler name.

=head2 C<preprocess>

  # Mojolicious::Lite
  plugin DOCRenderer => {preprocess => 'epl'};

Handler name of preprocessor.

=head2 C<url>

  # Mojolicious::Lite
  plugin DOCRenderer => {url => '/mydoc'};

URL from which the documentation of your project is available. Default is I</doc>.

=head1 METHODS

L<Mojolicious::Plugin::DOCRenderer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  my $route = $plugin->register(Mojolicious->new);
  my $route = $plugin->register(Mojolicious->new, {name => 'foo'});

Register renderer in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious::Plugin::PODRenderer>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
