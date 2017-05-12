use strict;
use warnings;
package TestPlackApp;

use Carp;
use parent 'Exporter';
use Plack::Builder;
use HTTP::Request;
use Test::More;
use Plack::Test;

our @EXPORT = qw(test_app);

sub is_like {
    my ($got, $expected, $message) = @_;
    if ( ref $expected and ref $expected eq 'Regexp' ) {
        like( $got, $expected, $message );
    } else {
        is( $got, $expected, $message );
    }
}

# run an array of tests with expected response on an app
sub test_app {
    my %arg = ref($_[0]) ? (app => $_[0], tests => $_[1], name => $_[2]) : @_;

    my $app = $arg{app};

    my $run = sub {
        foreach my $test (@{$arg{tests}}) {

            my @log;

            pass( '---- ' . $test->{name} . ' ----' ) if $test->{name};
            my $handler = builder {
                enable sub {
                    my $app = shift;
                    sub {
                        my $env = shift;
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

                my $res = $cb->( HTTP::Request->new( @{$test->{request}} ) );

                if ( defined $test->{code} ) {
                    is( $res->code, $test->{code},
                        'Got status code '.$res->code.' as expected' );
                }

                if ( defined $test->{content} ) {
                    is_like( $res->content, $test->{content},
                        'Got content as expected' );
                }

                if ( defined $test->{headers} ) {
                    my $h = $res->headers;

                    while ( my ( $header, $value ) = each %{ $test->{headers} } )
                    {
                        is $res->header($header), $value, "Header $header - ok";
                        $h->remove_header($header);
                    }

                    is $h->as_string, '', 'No extra headers were set';
                }

                if ( $test->{logged} ) {
                    my $n = @{$test->{logged}};
                    for (my $i=0; $i < $n; $i++) {
                        if ($i >= @log) {
                            ok( 0, "Got ".@log." logging actions, expected $n");
                            last;
                        }
                        my $expected = $test->{logged}->[$i];
                        my $got  = $log[$i];
                        if ( $expected->{level} ) {
                            is( $got->{level}, $expected->{level},
                                "Got logging level as expected" );
                        }
                        if ( defined $expected->{message} ) {
                            is_like( $got->{message}, $expected->{message},
                                "Got logging message as expected" );
                        }
                    }
                    if (@log > $n) {
                        ok( 0, "Got ".@log." logging actions, expected $n" );
                    }
                }
            };
        }
    };

    if ($arg{name}) {
        subtest $arg{name} => $run;
    } else {
        $run->();
    }
}

1;

=head1 NAME

TestPlackApp - Test PSGI applications with Plack::Test

=head1 SEE ALSO

L<Test::WWW::Mechanize::Plack>.

This module is located at L<https://gist.github.com/1024502> until it is
merged into another Perl module or published as tested module.

=cut
