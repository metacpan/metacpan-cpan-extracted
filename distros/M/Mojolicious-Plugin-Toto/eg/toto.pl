#!/usr/bin/env perl

use Mojolicious::Lite;

get '/' => "about";

my @menu = (
        nav => [ qw{overview examples source feedback} ],
        sidebar => {
            overview => [
                qw{toto/elements element toto/quickstart toto/inspiration toto/examples toto/download}
            ],
            examples => [
                qw{example/list example},
            ],
            source => [
                qw{file/list file},
            ],
            feedback => [
                qw{comments/view comments/add},
            ],
        },
        tabs => {
                element => [ qw/description example/ ],
                example => [ qw/description source/ ],
                file => [ qw/pod raw git/ ],
        }
);

plugin toto => @menu;

app->start;

__DATA__

@@ about.html.ep
<br>
<div class="hero-unit">
  <h1>Toto</h1>
  <p>A navigational structure based on tabs and objects.</p>
<br>
<h6>
<%= link_to "https://metacpan.org/module/Mojolicious::Plugin::Toto" => begin %>Mojolicious-Plugin-Toto<%= end %> 
uses
<%= link_to "http://mojolicio.us" => begin %>Mojolicious<%= end %> and
twitter bootstrap's <%= link_to "http://twitter.github.com/bootstrap/examples/fluid.html" => begin %>fluid layout example<%= end %>
to create a navigational structure and set of routes for a web application.
</h6>
<br>
  <p style='text-align:right;'>
    <%= link_to "toto/elements", class =>"btn btn-primary btn-large" => begin %>
      Learn more
    <%= end %>
  </p>
</div>

@@ toto/elements.html.ep
<p>
Each page in an application created with toto has :
<ul>
<li>a <%= link_to "element/default", { key => "navbar" } => begin %>nav bar<%= end %> at the top
<li>a <%= link_to "element/default", { key => "sidebar" } => begin %>side bar<%= end %> for secondary navigation
<li>a row of <%= link_to "element/default", { key => "tabs" } => begin %>tabs<%= end %>.
  There are only tabs on pages for which an <%= link_to "element/default", { key => 'object' } => begin %>object<%= end %>
 has been selected.
</ul>
</p>
<p>Pages are created using
<%= link_to "element/default" => { key => "template" } => begin %>
templates<%= end %>.</p>
<p>The toto
<%= link_to "element/default" => { key => "layout" } => begin %>
layout<%= end %> generates the navigational structure.</p>
<p>A number of
<%= link_to "element/default" => { key => "helpers" } => begin %>
helpers
<%= end %>
are added for use within templates.</p>
<p>A number of
<%= link_to "element/default" => { key => "stashkey" } => begin %>
stash keys
%= end
are set which may also be accessed from within the templates.</p>
@@ toto/quickstart.html.ep
<p>
To get a sample toto site running, just <%= link_to "toto/download" => begin %>download<%= end %> toto, and run one of
the <%= link_to "toto/examples" => begin %>examples<%= end %>.
</p>
<pre class="code">
$ cpanm Mojolicious::Plugin::Toto
$ cpanm --look Mojolicious::Plugin::Toto
$ ./eg/toto.pl daemon
</pre>
</div>

@@ toto/download.html.ep
<p><%= link_to "https://metacpan.org/module/Mojolicious::Plugin::Toto" => begin %>Mojolicious-Plugin-Toto<%= end %> is
 available on <%= link_to "http://cpan.org" => begin %>CPAN<%= end %>.</p>
<p>It can be downloaded from there directly, or using a tool, such as
 <%= link_to "https://metacpan.org/module/cpanm" => begin %>cpanm<%= end %>.
<pre class="code">
curl http://cpanmin.us > ~/bin/cpanm
chmod +x ~/bin/cpanm
~/bin/cpanm Mojolicious::Plugin::Toto
</pre>

@@ element/navbar/description.html.ep
The nav bar is created from a list of words.
The words are used for a few purposes :
<ol>
<li>as labels in the tool bar at the top of every page.
<li>as URLs for which a 302 redirect will be generated, sending the
user to the first item in the corresponding 
<%= link_to 'element/default', { key => 'sidebar' } => begin %>
sidebar<%= end %>.
</ol>
@@ element/sidebar/description.html.ep
<p>The side bar is a hash mapping nav bar items to lists of elements
in the side bar.</p>
<p>
Keys in the hash are elements of the nav bar array.
Values in the hash may take one of two forms :</p>
<ol>
<li>foo/bar : means that the route will be handled by controller foo, and action bar.
<li>baz : means that the route will generate a row of
<%= link_to 'element/default', { key => 'tabs' } => begin %>
tabs<%= end %>.  The tabs all act on a baz object.
</ol>
@@ element/tabs/description.html.ep
Tabs are specified as a hash whose keys are the type of object
and whose values are lists of words.  The words are used as
<ol>
<li>labels for the tabs
<li>portions of the URL paths (the paths are of the form object/action/instance)
<li>names of the routes.
</ol>
@@ element/example.html.ep
Sample <%= current_instance->key %> configuration :
% my $what = current_instance->key;
% $what = 'nav' if $what eq 'navbar';
<pre class="code">
%= dumper( toto_config->{$what} )
</pre>
@@ element/template/description.html.ep
<p>Templates in a toto application may be found in several locations, depending on how generic
the template is.  templates from the following paths are loaded :
<ol>
<li>class/object/instance.html.ep (if applicable)
<li>class/object.html
<li>object.html
</ol>
@@ element/template/example.html.ep
For example, the code for this template is :
<pre class="code">
%= $self->app->renderer->get_data_template({},'element/template/example.html.ep');
</pre>
but the code for the more generic "example" template, used by most of the other
example pages on this site
(
<%= link_to 'element/example', { key  => 'navbar' } => begin %>navbar<%= end %>,
<%= link_to 'element/example', { key  => 'sidebar' } => begin %>sidebar<%= end %>, etc.
)
 is :
<pre class='code'>
%= $self->app->renderer->get_data_template({},'element/example.html.ep');
</pre>
@@ element/object/description.html.ep
<p>Toto makes use of the objects in your application, by using the namespace
you provide when you initilize the plugin.  When a route of the form "$noun/$key/$action"
is encountered, $noun will be camelcased and appended to the namespace.  Then
a constructor will be called which uses $key, like so :
</p>
<pre class="code">
$c->model_class->new(key => $key);
</pre>
<p>This behavior is encapsulated in a helper called "current_instance".   To
change this default behavior, write another "current_instance" helper to
replace the default one.</p>
<p>Besides new(), the following methods may be implemented :</p>

<dl>
<dt>autocomplete</dt>
<dd>
Receives the named parameters: q, object, c and tab.  Returns an array
of names and hrefs to be used on an autocomplete dropdown.
<dd>
<dt>stringification</dt>
<dd>
Overload stringification to change the way instances are displayed at
the top of pages.
<dd>
</ul>
@@ element/object/example.html.ep
The default object class is Mojolicious::Plugin::Toto::Model.
<pre class="code">
%= Mojo::Asset::File->new(path => $INC{q[Mojolicious/Plugin/Toto/Model.pm]})->slurp;
</pre>
@@ element/helpers/description.html.ep
<dl>
<dt>toto_config</dt><dd>The configuration (defined when the plugin is loaded).</dd>
<dt>model_class</dt><dd>The default model class.</dd>
<dt>tabs</dt><dd>The list of current tabs being displayed.</dd>
<dt>current_object</dt><dd>The current object's class.</dd>
<dt>current_tab</dt><dd>The current tab.</dd>
<dt>current_instance</dt><dd>The current instance.</dd>
</dl>
@@ element/helpers/example.html.ep
<dl>
% for (qw/toto_config model_class tabs current_object current_tab current_instance/) {
<dt><%= $_ %></dt>
<dd><%= dumper(eval "$_()") %></dd>
% }
</dl>
@@ element/stashkey/description.html.ep
A number of keys are set in the stash for use within templates :
<dl>
<dt>$object</dt><dd>The current object type.</dd>
<dt>$noun</dt><dd>Synonym for $object.</dd>
<dt>$tab</dt><dd>The current tab.</dd>
<dt>$nav_item</dt><dd>The current item in the top nav bar.</dd>
<dt>$$noun</dt><dd>The variable whose name is "$noun" is a synonym for
<%= link_to 'element/description', { key  => 'helpers' } => begin %>
current_instance.
%= end
 </dd>
</dl>
@@ element/stashkey/example.html.ep
<dl>
% for (qw[object tab nav_item noun]) {
<dt>$<%= $_ %> </dt>
<dd><%= eval '$'.$_; %></dd>
% }
<dt>$<%= $noun %> (==${$noun})</dt>
<dd><%= eval '$'.$noun %></dd>
</dl>

@@ element/layout/description.html.ep
Toto sets the default layout to be "toto", e.g.
<pre class="code">
  $app->defaults(layout => "toto")
</pre>
The layout and supporting files, are builded with
the plugin and used as defaults, but may be overridden.
Some stash values may be set for minimal customization :
<ul>
<li>head</li>
<li>brand</li>
</ul>
(or of course another layout can used in place of the
provided one).

@@ element/layout/example.html.ep
Below is the default layout (layouts/toto.html.ep).
<pre class="code">
% my $path = $self->app->renderer->template_path({template => "layouts/toto", format => "html", handler => 'ep'});
%= Mojo::Asset::File->new(path => $path)->slurp;
</pre>



