use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

# Mojolicious::Lite
plugin 'TagHelpers::ContentBlock';

# Add snippets to a named content block, e.g. from a plugin
app->content_block(
  admin => {
    inline => "<%= link_to 'Edit' => '/edit' %>"
  }
);

# or in a controller:
get '/' => sub {
  my $c = shift;
  $c->content_block(
    admin => {
      inline => "<%= link_to 'Logout' => '/logout' %>",
      position => 20
    }
  );
  $c->render(template => 'home');
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->text_is('a:nth-of-type(1)', 'Edit')
  ->text_is('a:nth-of-type(2)', 'Logout')
  ->text_is('p', 'Welcome!');

done_testing;

# Call in a template
__DATA__
@@ home.html.ep
%= content_block 'admin'
<p>Welcome!</p>
