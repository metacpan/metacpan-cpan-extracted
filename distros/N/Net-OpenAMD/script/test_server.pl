#!/usr/bin/env perl

use 5.010;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/../mojo/lib";
    use lib "$FindBin::Bin/../../mojo/lib";
}

use Mojolicious::Lite;
use Mojo::JSON;

app->renderer->add_helper(
    action => sub {
        my ( $self, $action ) = @_;

        state %Actions;

        my $path = app->home->rel_file( '../t/data/' . $action );

        return if !-e $path;
        my $mtime = ( stat _ )[9];

        $Actions{$action}{mtime} //= 0;

        if ( $mtime != $Actions{$action}{mtime} ) {
            open my $fh, $path or die "Couldn't open [$path]: $!";
            my $content = do { local $/; <$fh> };
            close $fh;

            my $json = Mojo::JSON->new;
            my $data = $json->decode($content);
            if ( $json->error ) {
                die $json->error;
            }

            $Actions{$action} = {
                mtime => $mtime,
                data  => $data,
            };
        }

        return $Actions{$action}{data};
    }
);

get '/' => 'index';

get '/api/:action' => sub {
    my $self = shift;

    my $data = $self->helper( 'action', $self->stash('action') );
    return if !ref $data;

    my @data = @{$data};

    my $p = $self->req->params->to_hash;
    while ( my ( $param, $value ) = each(%$p) ) {
        @data = grep {
                   ref $_ ne 'HASH'
                || ( !exists $_->{$param} )
                || $value ~~ $_->{$param}
        } @data;
    }

    $self->render_json( \@data );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
Please try /api/action, or see
<a href="http://amd.home.net">amd.hope.net</a>.

@@ layouts/default.html.ep
<!doctype html><html>
    <head><title>Test OpenAMD API!</title></head>
    <body><%== content %></body>
</html>

@@ exception.html.ep
<!doctype html><html>
    <head><title>Exception</title></head>
    <body><%== $exception %></body>
</html>
