# package Plack::Test::App; # put this into a dedicated testing module?

sub is_like {    # I wonder why this is not part of Test::More
    my ( $got, $expected, $message ) = @_;
    if ( ref $expected and ref $expected eq 'Regexp' ) {
        like( $got, $expected, $message );
    } else {
        is( $got, $expected, $message );
    }
}

# run an array of tests with expected response on an app
sub app_tests {
    my %arg = @_;

    my $app = $arg{app};

    my $run = sub {

        foreach my $test ( @{ $arg{tests} } ) {

            my @log;

            pass( '---- ' . $test->{name} . ' ----' ) if $test->{name};
            my $handler = builder {
                enable sub {
                    my $app = shift;
                    sub {
                        my $env     = shift;
                        my $env_ref = $env;
                        Scalar::Util::weaken($env_ref);
                        $env->{'psgix.logger'} = sub {
                            push @log, shift;
                        };
                        $app->($env);
                    };
                };
                $app;
            };

            test_psgi $handler, sub {
                my $cb = shift;

                my $res
                    = $cb->( HTTP::Request->new( @{ $test->{request} } ) );

                if ( defined $test->{content} ) {
                    is_like( $res->content, $test->{content},
                        "Got content as expected" );
                }

                if ( defined $test->{code} ) {
                    is( $res->code, $test->{code},
                        "Got status code as expected" );
                }

                if ( defined $test->{headers} ) {
                    my $h = $res->headers;

                    while ( my ( $header, $value )
                        = each %{ $test->{headers} } )
                    {
                        is $res->header($header), $value,
                            "Header $header - ok";
                        $h->remove_header($header);
                    }

                }

                if ( $test->{logged} ) {
                    my $n = @{ $test->{logged} };
                    for ( my $i = 0; $i < $n; $i++ ) {
                        if ( $i >= @log ) {
                            ok( 0,
                                      "Got "
                                    . @log
                                    . " logging actions, expected $n" );
                            last;
                        }
                        my $expected = $test->{logged}->[$i];
                        my $got      = $log[$i];
                        if ( $expected->{level} ) {
                            is( $got->{level}, $expected->{level},
                                "Got logging level as expected" );
                        }
                        if ( defined $expected->{message} ) {
                            is_like( $got->{message}, $expected->{message},
                                "Got logging message as expected" );
                        }
                    }
                    if ( @log > $n ) {
                        ok( 0,
                            "Got " . @log . " logging actions, expected $n" );
                    }
                }
            };
        }
    };

    if ( $arg{'name'} ) {
        subtest $arg{'name'} => $run;
    } else {
        $run->();
    }
}

1;
