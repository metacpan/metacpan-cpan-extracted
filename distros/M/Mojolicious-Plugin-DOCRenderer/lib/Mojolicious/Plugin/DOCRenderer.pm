package Mojolicious::Plugin::DOCRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojo::Asset::File;
use Mojo::ByteStream;
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::URL;
use Pod::Simple::XHTML;
use Pod::Simple::Search;

our $VERSION = '5.01';

# "Futurama - The One Bright Spot in Your Life!"
sub register {
  my ($self, $app, $conf) = @_;

  # Add "doc" handler
  my $preprocess = $conf->{preprocess} || 'ep';
  $app->renderer->add_handler(
    $conf->{name} || 'doc' => sub {
      my ($renderer, $c, $output, $options) = @_;
      $renderer->handlers->{$preprocess}($renderer, $c, $output, $options);
      $$output = _pod_to_html($$output) if defined $$output;
    }
  );

  # Append "templates" and "public" directories
  push @{$app->renderer->paths}, catdir(dirname(__FILE__), 'DOCRenderer', 'templates');

  # Doc
  my $url = $conf->{url} || '/doc';
  my $module = $conf->{module};

  # Detect script location based on 2nd or 3rd parent (in case of Mojolicious::Lite app)
  my ( $package, $script ) = (caller(2))[0, 1];
  if ( $package eq 'Mojolicious::Lite' ) {
        $script = (caller(3))[1];
  }
  else {
        $module ||= $package;
  }

  my $defaults = {url => $url, module => $module, script => $script, format => 'html'};
  return $app->routes->any(
    "$url/:module" => $defaults => [module => qr/[^.]+/] => \&_doc);
}

sub _indentation {
  (sort map {/^(\s+)/} @{shift()})[0];
}

sub _html {
  my ($c, $src) = @_;

  # Rewrite links
  my $dom     = Mojo::DOM->new(_pod_to_html($src));
  my $doc = $c->url_for( $c->param('url') . '/' );
  $_->{href} =~ s!^https://metacpan\.org/pod/!$doc!
    and $_->{href} =~ s!::!/!gi
    for $dom->find('a[href]')->map('attr')->each;

  # Rewrite code blocks for syntax highlighting and correct indentation
  for my $e ($dom->find('pre > code')->each) {
    my $str = $e->content;
    next if $str =~ /^\s*(?:\$|Usage:)\s+/m || $str !~ /[\$\@\%]\w|-&gt;\w/m;
    my $attrs = $e->attr;
    my $class = $attrs->{class};
    $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
  }

  # Rewrite headers
  my $toc = Mojo::URL->new->fragment('toc');
  my @parts;
  for my $e ($dom->find('h1, h2, h3, h4')->each) {

    push @parts, [] if $e->tag eq 'h1' || !@parts;
    my $link = Mojo::URL->new->fragment($e->{id});
    push @{$parts[-1]}, my $text = $e->all_text, $link;
    my $permalink = $c->link_to('#' => $link, class => 'permalink');
    $e->content($permalink . $c->link_to($text => $toc));
  }

  # Try to find a title
  my $title = 'Doc';
  $dom->find('h1 + p')->first(sub { $title = shift->text });

  # Combine everything to a proper response
  $c->content_for(doc => "$dom");
  $c->render(title => $title, parts => \@parts);
}

sub _doc {
  my $c = shift;

  my $path = $c->stash('script');
  my $module = $c->param('module');

  if (defined $module) {
    # Find module or redirect to CPAN
    my $module = join '::', split('/', $c->param('module'));
    $path
      = Pod::Simple::Search->new->find($module, map { $_, "$_/pods" } @INC);
    return $c->redirect_to("https://metacpan.org/pod/$module")
      unless $path && -r $path;
  }

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

  plugin 'DOCRenderer';

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

  sub startup {
    my $self = shift;

    # Enable browsing of "/doc" only in development mode
    $self->plugin( 'DOCRenderer' ) if $self->mode eq 'development';

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
