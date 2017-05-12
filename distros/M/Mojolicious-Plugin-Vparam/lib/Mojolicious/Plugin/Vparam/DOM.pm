package Mojolicious::Plugin::Vparam::DOM;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

use Mojo::DOM;

sub parse_dom($) {
    my $str = shift;
    return undef unless defined $str;
    return undef unless length  $str;

    my $dom = eval { Mojo::DOM->new( $str ); };
    warn $@ and return undef if $@;

    return $dom;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    return;
}

1;
