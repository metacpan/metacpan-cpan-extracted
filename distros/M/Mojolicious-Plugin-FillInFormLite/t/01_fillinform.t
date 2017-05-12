use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;


plugin 'FillInFormLite';

get '/' => sub {
    my $self = shift;
    $self->render_fillinform({body => 'hello'});
} => 'index';


my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr{<input type="text" name="body" value="hello" />});


done_testing;

__DATA__

@@ index.html.ep
<html>
<head>
</head>
<body>
<form action="/" method="post">
<input type="text" name="body" />
<input type="submit" name="post" />
</form>
</body>
</html>
