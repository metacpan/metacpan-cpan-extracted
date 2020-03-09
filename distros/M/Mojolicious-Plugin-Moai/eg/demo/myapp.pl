
use Mojolicious::Lite;
use FindBin qw( $Bin );
use Mojo::File qw( path );
use lib path( $Bin, '..', '..', 'lib' )->to_string;
use lib path( $Bin, '..', '..', 't', 'lib' )->to_string;

plugin Config =>;
plugin Moai => app->config->{moai};
plugin AutoReload =>;

app->defaults({ layout => 'default' });

get '/' => 'index';
get '/elements' => 'elements';
get '/components' => 'components';
get '/elements/table' => 'table';
get '/components/pager' => 'pager';
get '/components/menu' => 'menu';

app->start;

__DATA__
@@ layouts/default.html.ep
<!DOCTYPE html>
<!-- XXX This is until we get a default layout in Moai -->
<head>
%= include 'moai/lib'
%= stylesheet 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css'
<style>
    .example {
        border: 3px solid #f8f9fa;
        border-radius: 5px;
        margin-bottom: 2.5rem;
        padding: 2em 2em 0;
    }
    .example figure {
        background-color: #f8f9fa;
        margin: 0 -2em;
        padding: 2em;
    }
    .container {
        padding: 1em 3em 1em 0;
    }
</style>
</head>
<%= include 'moai/menu/navbar',
    class => {
        navbar => 'navbar-light bg-light',
    },
    brand => [ 'Moai' => '/' ],
    menu => [
        [ Elements => 'elements' ],
        [ Components => 'components' ],
        # [ Layout => 'layout' ],
        # [ Icons => 'icons' ],
    ],
%>
<%= include 'moai/container', class => 'mt-2', content => begin %>
%= content
<% end %>

@@ elements.html.ep
<h1>Moai Elements</h1>

<p>These elements allow for rapid development of pages.</p>
%= include 'element_list'

@@ components.html.ep
<h1>Moai Components</h1>

<p>These components provide a rich, intuitive UI for users.</p>
%= include 'component_list'

@@ moai/container.html.ep
<div class="container"><%= $content->() %></div>

@@ index.html.ep
<h1>Moai</h1>
<h2>Mojolicious UI Library</h1>

Moai is a library of templates for the <a
href="http://mojolicious.org">Mojolicious web framework</a>.

<ul>
    <li>Provides standard elements and components from popular CSS UI libraries</li>
    <li>Integrates with Mojolicious CMSes like <a href="http://preaction.me/yancy">Yancy</a>
        and plugins like <a href="http://metacpan.org/pod/Mojolicious::Plugin::DBIC">Mojolicious::Plugin::DBIC</a>
    <li>Allows templates to be shared even between sites using different UI libraries</li>
</ul>

<h2>Supported Libraries</h2>
<%= link_to 'Bulma', 'http://bulma.io' %>,
<%= link_to 'Bootstrap 4', 'http://getbootstrap.com' %>

<h2>Elements</h2>
%= include 'element_list'

<h2>Components</h2>
%= include 'component_list'

@@ element_list.html.ep
%= link_to 'Table', 'table'

@@ component_list.html.ep
%= link_to 'Pager', 'pager'
%= link_to 'Menu', 'menu'

@@ table.html.ep
<h1>Table</h1>

<p>The table element provides easy display of tabular data. You can
define the columns and items that the table will display as stash values
to the template.</p>

<section class="example">
<%= include 'moai/table',
    columns => [
        { key => 'name' },
        { key => 'storage', title => 'Storage' },
        { key => 'transfer', title => 'Transfer' },
        { key => 'price', title => 'Price' },
    ],
    items => [
        {
            name => 'Tall',
            storage => '1 GB',
            transfer => '10 GB',
            price => '$5/mo',
        },
        {
            name => 'Venti',
            storage => '2 GB',
            transfer => '20 GB',
            price => '$10/mo',
        },
        {
            name => 'Grande',
            storage => '5 GB',
            transfer => '50 GB',
            price => '$20/mo',
        },
    ],
%>
<figure><pre><code><%%= include 'moai/table',
    columns => [
        { key => 'name' },
        { key => 'storage', title => 'Storage' },
        { key => 'transfer', title => 'Transfer' },
        { key => 'price', title => 'Price' },
    ],
    items => [
        {
            name => 'Tall',
            storage => '1 GB',
            transfer => '10 GB',
            price => '$5/mo',
        },
        {
            name => 'Venti',
            storage => '2 GB',
            transfer => '20 GB',
            price => '$10/mo',
        },
        {
            name => 'Grande',
            storage => '5 GB',
            transfer => '50 GB',
            price => '$20/mo',
        },
    ],
%%></pre></code></figure>
</section>

<p>Table values can be links to other pages using the <code>link_to</code> helper.</p>

<section class="example">
<%= include 'moai/table',
    columns => [
        { key => 'id' },
        { key => 'name', title => 'Username', link_to => 'user' },
    ],
    items => [
        {
            id => 1,
            name => 'Alice',
        },
        {
            id => 2,
            name => 'Bob',
        },
        {
            id => 3,
            name => 'Charlie',
        },
    ],
%>
<figure><pre><code><%%= include 'moai/table',
    columns => [
        { key => 'id' },
        { key => 'name', title => 'Username', link_to => 'user' },
    ],
    items => [
        {
            id => 1,
            name => 'Alice',
        },
        {
            id => 2,
            name => 'Bob',
        },
        {
            id => 3,
            name => 'Charlie',
        },
    ],
%%></pre></code></figure>
</section>

@@ pager.html.ep
<h1>Pager</h1>

<p>The default pager takes the current page from the <code>page</code> query parameter
and the total pages to produce a list of clickable page links</p>
<section class="example">
<p>Page <%= param( 'page' ) || 1 %></p>
<%= include 'moai/pager',
    total_pages => 5,
%>
<figure><pre><code><%%= include 'moai/pager', total_pages => 5 %></code></pre></figure>
</section>

<p>The mini pager shows only links to move to the next page or the previous page.</p>
<section class="example">
<p>Page <%= param( 'page' ) || 1 %></p>
<%= include 'moai/pager/mini',
    total_pages => 5,
%>
<figure><pre><code><%%= include 'moai/pager/mini', total_pages => 5 %></code></pre></figure>
</section>

@@ menu.html.ep
<h1>Menu</h1>

<p>Menus integrate with <a href="https://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Named-routes">Mojolicious's named routes</a>
to ensure that your menus get updated when your routes change.</p>

<h2>Buttons</h2>

<p>Menu buttons are good for general use as a single drop-down menu or
a full toolbar.</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [ 'Elements'    => '#' ],
        [ 'Components'  => '#' ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [ 'Elements'    => '#' ],
        [ 'Components'  => '#' ],
    ],
%%></pre></code></figure>
</section>

<p>Extra attributes can be added to the link element like
<code>disabled</code> or <code>style</code>.</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [ 'Elements'    => '#', disabled => 'disabled'            ],
        [ 'Components'  => '#', style    => 'background: skyblue' ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [ 'Elements'    => '#', disabled => 'disabled'            ],
        [ 'Components'  => '#', style    => 'background: skyblue' ],
    ],
%%></pre></code></figure>
</section>

<p>The current route will be highlighted automatically.</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [ Table => 'table' ],
        [ Menu  => 'menu'  ], # -- the current route
        [ Pager => 'pager' ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [ Table => 'table' ],
        [ Menu  => 'menu'  ], # -- the current route
        [ Pager => 'pager' ],
    ],
%%></pre></code></figure>
</section>

<!--
    XXX Idea for labelled colors later...
    <p>Colors can be added...</p>
    <section class="example">
    <%= include 'moai/menu/buttons',
        items => [
            [ Primary   => '#', color => -primary   ],
            [ Secondary => '#', color => -secondary ],
            [ Success   => '#', color => -success   ],
            [ Warning   => '#', color => -warning   ],
            [ Danger    => '#', color => -danger    ],
            [ Info      => '#', color => -info      ],
        ],
    %>
    <figure><pre><code><%%= include 'moai/menu/buttons',
        items => [
            [ Primary   => '#', color => -primary   ],
            [ Secondary => '#', color => -secondary ],
            [ Success   => '#', color => -success   ],
            [ Warning   => '#', color => -warning   ],
            [ Danger    => '#', color => -danger    ],
            [ Info      => '#', color => -info      ],
        ],
    %%></pre></code></figure>
    </section>
-->

<p>Any HTML content can be used as the link text with
<a href="https://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#b">the
<code>b()</code> helper</a>.</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        # XXX: Build an icon helper!
        [ b('<i class="fa fa-cube "></i> Elements'  ) => '#' ],
        [ b('<i class="fa fa-cubes"></i> Components') => '#' ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        # XXX: Build an icon helper!
        [ b('&lt;i class="fa fa-cube ">&lt;/i> Elements'  ) => '#' ],
        [ b('&lt;i class="fa fa-cubes">&lt;/i> Components') => '#' ],
    ],
%%></pre></code></figure>
</section>

<p>Buttons can turn in to dropdown menus.</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [
            Elements => [
                [ Table => 'table' ],
            ],
        ],
        [
            Components => [
                [ Pager => 'pager' ],
                [ Menu  => 'menu'  ],
            ],
        ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [
            Elements => [
                [ Table => 'table' ],
            ],
        ],
        [
            Components => [
                [ Pager => 'pager' ],
                [ Menu  => 'menu'  ],
            ],
        ],
    ],
%%></pre></code></figure>
</section>

<p>Dropdowns can have plain text elements and dividers, and dropdown items
can be given attributes. If a dropdown menu is the current route, it will
be highlighted!</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [
            Elements => [
                'Elements',
                [ b('<i class="fa fa-table"></i> Table') => 'table' ],
                [ Form => 'form', disabled => 'disabled' ],
            ],
        ],
        [
            Components => [
                'Components',
                [ Pager => 'pager', style => 'background: #ccccff' ],
                undef,
                [ Menu  => 'menu' ], # -- the current route
            ],
        ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [
            Elements => [
                'Elements',
                [ b('&lt;i class="fa fa-table">&lt;/i> Table') => 'table' ],
                [ Form => 'form', disabled => 'disabled' ],
            ],
        ],
        [
            Components => [
                'Components',
                [ Pager => 'pager', style => 'background: #ccccff' ],
                undef,
                [ Menu  => 'menu' ], # -- the current route
            ],
        ],
    ],
%%></pre></code></figure>
</section>

<p>Dropdowns can even have any content you want!</p>
<section class="example">
<%= include 'moai/menu/buttons',
    items => [
        [
            b('<i class="fa fa-user"></i> preaction') => [
                b(q{
                    <span style="border-radius: 50px">
                    <img src="https://www.gravatar.com/avatar/}
                        . Mojo::Util::md5_sum( 'doug@preaction.me' )
                        . q{.jpg?s=200">
                    </span>
                    Doug Bell
                }),
                [ b('Inbox <span class="badge badge-info pull-right">5</span>') => '#' ],
                undef,
                [ 'Edit Profile' => '#' ],
            ],
        ],
        [ b('<i class="fa fa-sign-out"></i>') => '#' ],
    ],
%>
<figure><pre><code><%%= include 'moai/menu/buttons',
    items => [
        [
            b('&lt;i class="fa fa-user">&lt;/i> preaction') => [
                b(q{
                    &lt;span style="border-radius: 50px">
                    &lt;img src="https://www.gravatar.com/avatar/}
                        . Mojo::Util::md5_sum( 'doug@preaction.me' )
                        . q{.jpg?s=200">
                    &lt;/span>
                    Doug Bell
                }),
                [ b('Inbox &lt;span class="badge badge-info pull-right">5&lt;/span>') => '#' ],
                undef,
                [ 'Edit Profile' => '#' ],
            ],
        ],
        [ b('&lt;i class="fa fa-sign-out">&lt;/i>') => '#' ],
    ],
%%></pre></code></figure>
</section>
