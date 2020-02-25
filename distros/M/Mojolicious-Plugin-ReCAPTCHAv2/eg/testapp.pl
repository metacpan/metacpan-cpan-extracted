#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Mojolicious::Lite;
use Mojo::IOLoop::Delay;

app->log->level( 'error' );

plugin 'ReCAPTCHAv2' => {
    sitekey  => $ENV{'RECAPTCHA_SITEKEY'},
    secret   => $ENV{'RECAPTCHA_SECRET'},
    language => 'de',
};

get '/test' => sub {
    my $self = shift;
    $self->stash( nocap => $self->recaptcha_get_html );
};

post '/run' => sub {
    my $self = shift;
    my ( $result, $err ) = $self->recaptcha_verify;
    if ( $result ) {
        warn "success";
    }
    else {
        warn "failed";
        use Data::Dumper;
        warn Dumper $err;
    }
    $self->stash( result => $result );
};

post '/run_cb' => sub {
    my $self = shift;

    my $d = Mojo::IOLoop::Delay->new();

    $d->steps(
        sub {
            my $d = shift;
            $self->recaptcha_verify( $d->begin( 0 ) );
        },
        sub {
            my ( $d, $result, $err ) = @_;
            if ( $result ) {
                warn "success";
            }
            else {
                warn "failed";
                use Data::Dumper;
                warn Dumper $err;
            }
            $self->render( 'run', result => $result );
        }
    );
    $self->render_later();
};
app->start;

__DATA__

@@ test.html.ep
<!DOCTYPE html>
<head>
<title>test</title>
</head>
<body>
<form action="/run" method="POST">
<%= $nocap %>
<button type="submit">run</button>
</form>
<form action="/run_cb" method="POST">
<%= $nocap %>
<button type="submit">run async</button>
</form>
</body>
</html>

@@ run.html.ep
<!DOCTYPE html>
<head>
<title>run</title>
</head>
<body>
<b><%= $result %></b>
</body>
</html>
