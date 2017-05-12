package Puncheur::Lite;
use 5.010;
use strict;
use warnings;

use File::Spec;
use Data::Section::Simple ();

use Puncheur ();
use Puncheur::Dispatcher::Lite ();

sub import {
    my ($class) = @_;
    my $caller = caller;

    {
        no strict 'refs';
        push @{"$caller\::ISA"}, 'Puncheur';

        $caller->load_plugin('HandleStatic');
        my $to_psgi = $caller->can('to_psgi');

        no warnings 'redefine';
        *{"$caller\::to_psgi"} = sub {
            use strict 'refs';
            my $app = $to_psgi->(@_);
            {
                no strict 'refs';
                if (my @middlewares = @{"$caller\::_MIDDLEWARES"}) {
                    use strict 'refs';
                    for my $middleware (@middlewares) {
                        my ($klass, $args) = @$middleware;
                        $klass = Plack::Util::load_class($klass, 'Plack::Middleware');
                        $app = $klass->wrap($app, %$args);
                    }
                }
            }
            $app;
        };

        *{"$caller\::enable_middleware"} = sub {
            my ($klass, %args) = @_;
            push @{"$caller\::_MIDDLEWARES"}, [$klass, \%args];
        };
        *{"$caller\::enable_session"} = sub {
            use strict 'refs';
            my (%args) = @_;
            $args{state} ||= do {
                require Plack::Session::State::Cookie;
                Plack::Session::State::Cookie->new(httponly => 1); # for security
            };
            require Plack::Middleware::Session;

            my $func = $caller->can('enable_middleware');
            $func->('Plack::Middleware::Session', %args);
        };
    }

    my $tmpl = sub {
        File::Spec->catdir($caller->asset_dir, 'tmpl');
    };
    $caller->setting(
        template_dir => [sub {Data::Section::Simple->new($caller)->get_data_section}, $tmpl],
    );

    strict->import;
    warnings->import;
    utf8->import;
    require feature;
    feature->import(':5.10');

    goto do { Puncheur::Dispatcher::Lite->can('import') };
}

1;
