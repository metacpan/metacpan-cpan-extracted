use strict;
use warnings;
use Plack::Builder;

builder {
    enable 'DevFilter',
        filters => [
            {
                match => sub {
                    my ($self, $env, $res) = @_;
                    return 1 if $env->{PATH_INFO} eq '/favicon.ico';
                },
                proc  => sub {
                    my ($self, $env, $res,
                            $body_ref, $imager, $image_type) = @_;
                    if ($imager) {
                        $imager = $imager->convert(preset => 'gray')
                                        or die Imager->errstr;
                        my $out;
                        $imager->write(data => \$out, type => $image_type);
                        $res->[2] = [$out];
                    }
                },
            },
            {
                match => sub {
                    my ($self, $env, $res) = @_;
                    return 1 if $env->{PATH_INFO} eq '/';
                },
                proc  => sub {
                    my ($self, $env, $res,
                            $body_ref, $imager, $image_type) = @_;
                    $$body_ref .= ' How are you?';
                    $res->[2] = [$$body_ref];
                },
            },
            {
                match => sub {
                    my ($self, $env, $res) = @_;
                    return 1 if $env->{PATH_INFO} eq '/style.css';
                },
                proc  => sub {
                    my ($self, $env, $res,
                            $body_ref, $imager, $image_type) = @_;
                    $$body_ref =~ s/#ffffff/#ffffcc/g;
                    $res->[2] = [$$body_ref];
                },
            },
        ],
    ;

    enable 'Static',
        path => qr{\.(?:ico|css|png|gif|jpeg)$},
        root => 'share',
    ;

    return sub {
        my $plack_env = $ENV{PLACK_ENV} || '';
        [200, ['Content-Type' => 'text/plain'], ["Hello, $plack_env!"]];
    };
};
