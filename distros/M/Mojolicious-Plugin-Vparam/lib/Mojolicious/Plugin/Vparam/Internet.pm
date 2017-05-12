package Mojolicious::Plugin::Vparam::Internet;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

use Mojo::URL;

sub check_email($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format' unless Mail::RFC822::Address::valid( $_[0] );
    return 0;
}

sub check_url($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Protocol not set'           unless $_[0]->scheme;
    return 'Host not set'               unless $_[0]->host;
    return 0;
}

sub parse_address($) {
    my ($str) = @_;
    return undef unless defined $str;
    return Mojolicious::Plugin::Vparam::Address->parse( $str );
}

sub parse_url($) {
    my ($str) = @_;
    return undef unless defined $str;
    return Mojo::URL->new( $str );
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        email       =>
            load    => 'Mail::RFC822::Address',
            pre     => sub { trim               $_[1] },
            valid   => sub { check_email        $_[1] },
    );

    $app->vtype(
        url         =>
            pre     => sub { parse_url trim     $_[1] },
            valid   => sub { check_url          $_[1] },
            post    => sub {
                return unless defined $_[1];
                return ref($_[1]) && ! $_[2]->{blessed}
                    ? $_[1]->to_string
                    : $_[1]
                ;
            },
    );

    return;
}

1;
