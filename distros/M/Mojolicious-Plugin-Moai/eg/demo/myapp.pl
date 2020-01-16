
use Mojolicious::Lite;
use FindBin qw( $Bin );
use Mojo::File qw( path );
use lib path( $Bin, '..', '..', 'lib' )->to_string;
use lib path( $Bin, '..', '..', 't', 'lib' )->to_string;

plugin Config =>;
plugin Moai => app->config->{moai};

app->defaults({ layout => 'default' });

get '/' => 'index';
get '/table' => 'table';
get '/pager' => 'pager';

app->start;

__DATA__
@@ layouts/default.html.ep
<!-- XXX This is until we get a default layout in Moai -->
<head>
%= include 'moai/lib'
</head>
<%= include 'moai/navbar',

%>
%= content

@@ index.html.ep
<h1>Moai Components</h1>

%= link_to 'Table', 'table'
%= link_to 'Pager', 'pager'

@@ table.html.ep
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

@@ pager.html.ep
<h1>Page <%= param( 'page' ) || 1 %></h1>

<%= include 'moai/pager',
    total_pages => 5,
%>

<%= include 'moai/pager/mini',
    total_pages => 5,
%>
