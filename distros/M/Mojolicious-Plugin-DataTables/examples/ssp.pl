#!perl

use Mojolicious::Lite;
use Mojo::Pg;

helper sql => sub { state $pg = Mojo::Pg->new('postgresql://postgres@/test') };

get '/' => 'index';

get '/ajax' => sub {

    my $c = shift;

    my $dt_ssp = $c->datatable->ssp(
        table   => 'users',
        sql     => $c->sql,
        options => [
            {
                label => 'UID',
                db    => 'uid',
                dt    => 0,
            },
            {
                label => 'e-Mail',
                db    => 'mail',
                dt    => 1,
            },
            {
                label => 'Status',
                db    => 'status',
                dt    => 2,
            },
        ]
    );

    return $c->render( json => $dt_ssp );

};

app->start;
__DATA__
 
@@ index.html.ep
<html>
<head>
  <script src="https://code.jquery.com/jquery-3.4.1.min.js"></script>
  <%= datatable_js %>
  <%= datatable_css %>
</head>
<body>
  <table id="example" class="display" style="width:100%">
    <thead>
      <th>UID</th>
      <th>e-Mail</th>
      <th>Status</th>
    </thead>
  </table>

  <script>
    jQuery('#example').DataTable({
      serverSide : true,
      ajax       : '/ajax',
    });
  </script>
</body>
</html>
