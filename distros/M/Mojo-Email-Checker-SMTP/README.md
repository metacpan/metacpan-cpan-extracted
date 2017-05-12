Mojo-Email-Checker-SMTP
=======================
Email checking by smtp with Mojo enviroment.


    use strict;
    use Mojolicious::Lite;
    use Mojo::IOLoop::Delay;
    use Mojo::Email::Checker::SMTP;

    my $checker     = Mojo::Email::Checker::SMTP->new;

    post '/' => sub {
        my $self    = shift;
        my $request = $self->req->json;

        my @emails;
        my $delay = Mojo::IOLoop::Delay->new;
        $delay->on(finish => sub {
                $self->render(json => \@emails);
        });

        my $cb = $delay->begin();

        for (@{$request}) {
            my $cb = $delay->begin(0);
            $checker->check($_, sub { push @emails, $_[0] if ($_[0]); $cb->(); });
        }

        $cb->();

    };

    app->start;

