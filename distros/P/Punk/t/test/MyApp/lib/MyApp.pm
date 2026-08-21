package MyApp;

use Punk;
use File::Basename ();

# Phase 1-4 wiring: web routes + an under guard, Stencil views, the
# spec-first API mounted under /api with the docs UI at /docs, and the
# Book model over Punk::Model::DBI. The SQLite dsn comes from the
# environment so t/1340-myapp.t can point it at a fixture it builds.

my $home = File::Basename::dirname(__FILE__) . '/..';
my $root = "$home/root";

views Stencil => {
    template_dir => "$root/templates",
    wrapper      => 'layout.tmpl',
};

database dsn => $ENV{PUNK_MYAPP_DSN} || "dbi:SQLite:dbname=$home/myapp.db";
model 'Book';

get  '/'          => 'Web::Book#home';
get  '/books'     => 'Web::Book#list';
get  '/books/:id' => 'Web::Book#view';
post '/books'     => 'Web::Book#create';

my $admin = under '/admin' => 'Web::Auth#required';
$admin->get('/books' => 'Web::Book#admin_list');

my $books = under('/api')->api("$home/openapi.json");
docs '/docs' => $books if eval { require Open::API::UI; 1 };

1;
