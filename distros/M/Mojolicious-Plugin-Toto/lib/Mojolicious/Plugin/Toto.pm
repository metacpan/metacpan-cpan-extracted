=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'toto' =>
            nav => [ qw{brewery pub beer} ],
            sidebar => {
                brewery => [ qw{brewery/list brewery/search brewery} ],
                pub     => [ qw{pub/list pub/search pub} ],
                beer    => [ qw{beer/list beer/search beer} ],
            },
            tabs => {
                brewery => [qw/view edit delete/],
                pub     => [qw/view edit delete/],
                beer    => [qw/view edit delete/],
            };

    app->start;

=head1 DESCRIPTION

This plugin provides a navigational structure and a default set
of routes for a Mojolicious or Mojolicious::Lite app

The navigational structure is a slight variation of
L<this|http://twitter.github.com/bootstrap/examples/fluid.html>
example used by twitter's L<bootstrap|http://twitter.github.com/bootstrap>.

The plugin provides a sidebar, a nav bar, and also a
row of tabs underneath the name of an object.

The row of tabs is an extension of BREAD or CRUD -- in a BREAD
application, browse and add are operations on zero or many objects,
while edit, add, and delete are operations on one object.  In
the toto structure, these two types of operations are distinguished
by placing the former in the side nav bar, and the latter in
a row of tabs underneath the object to which the action applies. 

Additionally, a top nav bar contains menu items to take the user
to a particular side bar.

=head1 HOW DOES IT WORK

After loading the toto plugin, the default layout is set to 'toto'.

Defaults routes are generated for every sidebar entry and tab entry.

The names of the routes are of the form "controller/action", where
controller is both the controller class and the model class.

The following templates will be automagically used, if found
(in order of preference) :

  - templates/<controller>/<instance>/<action>.html.ep
  - templates/<controller>/<action>.html.ep
  - templates/<action>.html.ep

Or if no object is selected :

  - templates/<controller>/none_selected.html.ep

(This one links connects to "list" and "search" if
these routes exist, and provides an autocomplete
form if the model class has an autocomplete() method.)

Also the templates "single" and "plural" are built-in
fallbacks for the two cases described above.

The stash values "object" and "tab" are set for each auto-generated route.
Also "noun" is set as an alias to "object".

A version of twitter's L<bootstrap|http://twitter.github.com/bootstrap> is
included in this distribution.

=head1 OPTIONS

In addition to "menu", "nav/sidebar/tabs", the following options are recognized :

=over

=item prefix

    prefix => /my/subpath

A prefix to prepend to the path for the toto routes.

=item head_route

    head_route => $app->routes->find('top_route");

A Mojolicious::Route::Route object to use as the parent for all routes.

=item model_namespace

    model_namespace => "Myapp::Model'

A namespace for model classes : the model class will be camelized and appended to this.

=back

=head1 EXAMPLE

There are two different structures that toto will accept.
One is intended for a simple CRUD structure, where each
object has its own top level navigational item and
a variety of possible actions.  The other form is intended
for a more complex situation in which the list of objects
does not correspond to the list of choices in the navigation
bar.

=head2 Simple structure

The "menu" format can be used to automatically generate
the nav bar, side bar and rows of tabs, using actions
which correspond to many objects or actions which
correspond to one object.

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'toto' =>
         menu => [
            beer => {
                many => [qw/search browse/],
                one  => [qw/picture ingredients pubs/],
            },
            pub => {
                many => [qw/map list search/],
                one  => [qw/info comments/],
            }
        ];

    app->start;

=head2 Complex structure

The "nav/sidebar/tabs" format can be used
for a more versatile structure, in which the
nav bar and side bar are less constrained.

     use Mojolicious::Lite;

     get '/my/url/to/list/beers' => sub {
          shift->render_text("Here is a page for listing beers.");
     } => "beer/list";

     get '/beer/create' => sub {
        shift->render_text("Here is a page to create a beer.");
     } => "beer/create";

     plugin 'toto' =>

          # top nav bar items
          nav => [
              'brewpub',          # Refers to a sidebar entry below
              'beverage'          # Refers to a sidebar entry below
          ],

          # possible sidebars, keyed on nav entries
          sidebar => {
            brewpub => [
                'brewery/phonelist',
                'brewery/mailing_list',
                'pub/search',
                'pub/map',
                'brewery',        # Refers to a "tab" entry below
                'pub',            # Refers to a "tab" entry below
            ],
            beverage =>
              [ 'beer/list',      # This will use the route defined above named "beer/list"
                'beer/create',
                'beer/search',
                'beer/browse',    # This will use the controller at the top (Beer::browse)
                'beer'            # Refers to a "tab" entry below
               ],
          },

          # possible rows of tabs, keyed on sidebar entries without a /
          tabs => {
            brewery => [ 'view', 'edit', 'directions', 'beers', 'info' ],
            pub     => [ 'view', 'info', 'comments', 'hours' ],
            beer    => [ 'view', 'edit', 'pictures', 'notes' ],
          };
     ;

     app->start;


=head1 NOTES

To create pages outside of the toto framework, just set the layout to
something other than "toto', e.g.

    get '/no/toto' => { layout => 'default' } => ...

This module is experimental.  The API may change without notice.  Feedback is welcome!

=head1 TODO

Document the autcomplete API.

=head1 AUTHOR

Brian Duggan C<bduggan@matatu.org>

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojolicious::Plugin::Toto::Model;
use Cwd qw/abs_path/;

use strict;
use warnings;

our $VERSION = "0.25";

sub _render_static {
    my $c = shift;
    my $what = shift;
    $c->render_static($what);
}

sub _cando {
    my ($namespace,$controller,$action) = @_;
    my $package = join '::', ( $namespace || () ), b($controller)->camelize;
    return $package->can($action) ? 1 : 0;
}

sub _to_noun {
    my $word = shift;
    $word =~ s/_/ /g;
    $word;
}

sub _add_sidebar {
    my $self = shift;
    my $app = shift;
    my $routes = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    die "no tab for $object" unless $tab;
    die "no nav item" unless $nav_item;

    my ($template) = (
        ( map { (-e "$_/$object/$tab.html.ep") ? "$object/$tab" : () } @{ $app->renderer->paths } ),
        ( map { (-e "$_/$tab.html.ep"        ) ? "$tab"         : () } @{ $app->renderer->paths } ),
    );
    $template = $tab if $app->renderer->get_data_template({template => $tab, format => 'html', handler => 'ep'});
    $template = "$object/$tab" if $app->renderer->get_data_template({template => "$object/$tab", format => "html", handler => "ep"});

    my $namespaces = $routes->can('namespaces') ? $routes->namespaces : $routes->root->namespaces;
    $namespaces = [ '' ] unless $namespaces && @$namespaces;
    my $found_controller = grep { _cando($_,$object,$tab) } @$namespaces;

    $app->log->debug("Adding sidebar route for $prefix/$object/$tab");
    $app->log->debug("found template $template for $object/$tab ($nav_item)") if $template;

    my $r = $routes->under(
        "$prefix/$object/$tab" => sub {
            my $c = shift;
            $c->stash->{template} = $template || "plural";
            $c->stash(object     => $object);
            $c->stash(noun       => $object);
            $c->stash(tab        => $tab);
            $c->stash(nav_item   => $nav_item);
          })->any;

    $app->log->debug("found controller for $object/$tab (controller : $object, action : $tab)") if $found_controller;
    $r = $r->to(controller => $object, action => $tab) if $found_controller;
    $r->name("$object/$tab");
}

sub _add_tab {
    my $self = shift;
    my $app = shift;
    my $routes = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    my ($default_template) = (
        ( map { (-e "$_/$object/$tab.html.ep") ? "$object/$tab" : () } @{ $app->renderer->paths } ),
        ( map { (-e "$_/$tab.html.ep"        ) ? "$tab"         : () } @{ $app->renderer->paths } ),
    );
    $default_template = $tab if $app->renderer->get_data_template({template => $tab, format => "html", handler => "ep"});
    $default_template = "$object/$tab" if $app->renderer->get_data_template({template => "$object/$tab", format => "html", handler => "ep"});

    my $namespaces = $routes->can('namespaces') ? $routes->namespaces : $routes->root->namespaces;
    $namespaces = [ '' ] unless $namespaces && @$namespaces;
    my $found_controller = grep { _cando($_,$object,$tab) } @$namespaces;
    $app->log->debug("Adding route for $prefix/$object/$tab/*key");
    $app->log->debug("Found controller class for $object/$tab/key") if $found_controller;
    $app->log->debug("Found default template for $object/$tab/key ($default_template)") if $default_template;
    my $r = $routes->under("$prefix/$object/$tab/(*key)"
            => { key => '', show_tabs => 1 }
            => sub {
                my $c = shift;
                my $template = $default_template;
                my $key = lc $c->stash('key');
                $c->stash(object => $object);
                $c->stash(noun => _to_noun($object));
                $c->stash(tab => $tab);
                if ( $key ) {
                    if ( ( grep { -e "$_/$object/$key/$tab.html.ep" } @{ $app->renderer->paths } )
                        || $c->app->renderer->get_data_template( {template => "$object/$key/$tab", format => "html", handler => "ep"}) ) {
                        $template = "$object/$key/$tab";
                    }
                } else {
                    $template = "none_selected";
                    $template = "$object/none_selected" if grep { -e "$_/$object/none_selected.html.ep" } @{ $app->renderer->paths };
                }
                $c->stash->{template} = $template || "single";
                my $instance = $c->current_instance;
                $c->stash( instance => $instance );
                $c->stash( nav_item => $nav_item );
                $c->stash( $object  => $instance );
                $c->render unless $key;
                $key ? 1 : 0;
              }
            )->any;
      $r = $r->to("$object#$tab") if $found_controller;
      $r->name("$object/$tab");
}

sub _menu_to_nav {
    my $self = shift;
    my ($conf,$menu) = @_;
    my $nav;
    my $sidebar;
    my $tabs;
    my $object;
    for (@$menu) {
        unless (ref $_) {
            $object = $_;
            push @$nav, $object;
            next;
        }
        for my $action (@{ $_->{many} || [] }) {
            push @{$sidebar->{$object}}, "$object/$action";
        }
        push @{$sidebar->{$object}}, $object;
        for my $action (@{ $_->{one} || [] }) {
            push @{$tabs->{$object}}, $action;
        }
    }
    $conf->{nav} = $nav;
    $conf->{sidebar} = $sidebar;
    $conf->{tabs} = $tabs;
}

sub register {
    my ($self, $app, $conf) = @_;
    $app->log->debug("registering plugin");

    if (my $menu = $conf->{menu}) {
        $self->_menu_to_nav($conf,$menu);
    }
    for (qw/nav sidebar tabs/) {
        die "missing $_" unless $conf->{$_};
    }
    my ($nav,$sidebar,$tabs) = @$conf{qw/nav sidebar tabs/};

    my $prefix = $conf->{prefix} || '';
    my $routes = $conf->{head_route} || $app->routes;

    my $base = catdir(abs_path(dirname(__FILE__)), qw/Toto Assets/);
    my $default_path = catdir($base,'templates');
    push @{$app->renderer->paths}, catdir($base, 'templates');
    push @{$app->static->paths},   catdir($base, 'public');
    $app->defaults(layout => "toto", toto_prefix => $prefix);

    $app->log->debug("Adding routes");

    my %tab_done;

    die "toto plugin needs a 'nav' entry, please read the pod for more information" unless $nav;
    for my $nav_item ( @$nav ) {
        $app->log->debug("Adding routes for $nav_item");
        my $first;
        my $items = $sidebar->{$nav_item} or die "no sidebar for $nav_item";
        for my $subnav_item ( @$items ) {
            $app->log->debug("routes for $subnav_item");
            my ( $object, $action ) = split '/', $subnav_item;
            if ($action) {
                $first ||= $subnav_item;
                $self->_add_sidebar($app,$routes,$prefix,$nav_item,$object,$action);
            } else {
                my $first_tab;
                $first ||= "$object/default";
                my $tabs = $tabs->{$subnav_item} or
                     do { warn "# no tabs for $subnav_item"; next; };
                die "tab row for '$subnav_item' appears more than once" if $tab_done{$subnav_item}++;
                for my $tab (@$tabs) {
                    $first_tab ||= $tab;
                    $self->_add_tab($app,$routes,$prefix,$nav_item,$object,$tab);
                }
                $app->log->debug("Will redirect $prefix/$object/default/key to $object/$first_tab/\$key");

                $routes->get("$prefix/$object/default/*key" => { key => '' } => sub {
                    my $c = shift;
                    my $key = $c->stash("key");
                    $c->redirect_to("$object/$first_tab", key => $key);
                    } => "$object/default");

                 $routes->get(
                    "$prefix/$object/autocomplete" => { layout => "default" } => sub {
                        my $c = shift;
                        my $query = $c->param('q');
                        return $c->render_not_found unless $c->model_class->can("autocomplete");
                        my $results = $c->model_class->autocomplete( q => $query, object => $object, c => $c, tab => $c->param('tab') );
                        # Expects an array ref of the form
                        #    [ { name => 'foo', href => 'bar' }, ]
                        $c->render( json => $results );
                      } => "$object/autocomplete");
            }
        }
        die "Could not find first route for nav item '$nav_item' : all entries have tabs\n" unless $first;
        $routes->get(
            $nav_item => sub {
                my $c = shift;
                $c->redirect_to($first);
            } => $nav_item );
    }

    my $first_object = $conf->{nav}[0];
    $routes->get("$prefix/" => sub { shift->redirect_to($first_object) } );

    for ($app) {
        $_->helper( toto_config => sub { $conf } );
        $_->helper( model_class => sub {
                my $c = shift;
                if (my $ns = $conf->{model_namespace}) {
                    return join '::', $ns, b($c->current_object)->camelize;
                }
                $conf->{model_class} || "Mojolicious::Plugin::Toto::Model"
             }
         );
        $_->helper(
            tabs => sub {
                my $c    = shift;
                my $for  = shift || $c->current_object or return;
                @{ $conf->{tabs}{$for} || [] };
            }
        );
        $_->helper( current_object => sub {
                my $c = shift;
                $c->stash('object') || [ split '\/', $c->current_route ]->[0]
            } );
        $_->helper( current_tab => sub {
                my $c = shift;
                $c->stash('tab') || [ split '\/', $c->current_route ]->[1]
            } );
        $_->helper( current_instance => sub {
                my $c = shift;
                my $key = $c->stash("key") || [ split '\/', $c->current_route ]->[2];
                return $c->model_class->new(key => $key);
            } );
        $_->helper( printable => sub {
                my $c = shift;
                my $what = shift;
                $what =~ s/_/ /g;
                $what } );
        $_->helper( a_printable => sub {
                my $c = shift;
                my $what = shift;
                return ( ($what =~ /^[aeiou]/ ? "an " : "a ").$c->printable($what));
            } );
    }

    $self;
}

1;
