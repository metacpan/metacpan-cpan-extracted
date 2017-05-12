package Mojolicious::Plugin::Vparam::XML;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(load_class);

sub parse_xml($) {
    my $str = shift;
    return undef unless defined $str;
    return undef unless length  $str;

    my $e = load_class('XML::LibXML');
    die $e if $e;

    my $dom = eval{ XML::LibXML->load_xml(string => $str) };
    warn $@ and return undef if $@;

    return $dom;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    return;
}

1;
