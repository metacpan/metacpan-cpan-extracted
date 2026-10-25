package BrandingTest;
use strict;
use warnings;
use Exporter qw< import >;
use Test::Mojo;
use Mojo::File qw< tempdir >;
use Mojo::Home;
use Mojolicious;

our @EXPORT = qw< t_for write_files brand_hook %generic %foo %FOO %BAR >;

our %generic = (
   'templates/index.html.ep' => 'generic page',
   'public/site.css'         => 'generic css',
);
our %foo = (
   'brands/foo/templates/index.html.ep' => 'foo page',
   'brands/foo/public/site.css'         => 'foo css',
);
our %FOO = (Host => 'foo.example.com');
our %BAR = (Host => 'bar.example.com');

# write %$files (relative path => content) under $dir
sub write_files {
   my ($dir, $files) = @_;
   for my $rel (keys $files->%*) {
      my $file = $dir->child(split m{/}, $rel);
      $file->dirname->make_path;
      $file->spew($files->{$rel});
   }
   return $dir;
}

# Return a setup sub for t_for that puts the brand in stash key $key
# (default "variant") from a before_dispatch hook, as the application is
# expected to do: query parameter "b" if present, else "foo" for %FOO.
sub brand_hook {
   my ($key) = @_;
   $key //= 'variant';
   return sub {
      my ($app) = @_;
      $app->hook(before_dispatch => sub {
         my $c = shift;
         my $brand = $c->param('b');
         $brand //= 'foo' if $c->req->url->to_abs->host eq $FOO{Host};
         $c->stash($key => $brand) if defined($brand);
      });
   };
}

# Build an app whose home is a fresh temp dir holding %$files;
# "/" serves template "index". Optional $setup is called with the app
# before loading the plugin.
sub t_for {
   my ($files, $conf, $setup) = @_;
   my $home = write_files(tempdir, $files);
   my $app = Mojolicious->new(home => Mojo::Home->new($home));
   $app->log->level('fatal');
   $setup->($app) if $setup;
   $app->plugin(Branding => $conf);
   $app->routes->get('/' => sub { shift->render(template => 'index') });
   return Test::Mojo->new($app);
}

1;
