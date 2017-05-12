package t::MockResolver;
use strict;
use parent 'Net::DNS::Resolver';
use Test::More;

sub new {
    my $class = shift;
    return bless {
        proxy => Net::DNS::Resolver->new,
        fake_record => {},
    }, $class;
}

sub set_fake_record {
    my ($self, $host, $packet) = @_;
    $self->{fake_record}{$host} = $packet;
}

sub _make_proxy {
    my $method = shift;
    return sub {
        my $self = shift;
        my $fr = $self->{fake_record};
        if ($method eq "bgsend" && $fr->{$_[0]}) {
            $self->{next_fake_packet} = $fr->{$_[0]};
            Test::More::note("mock DNS resolver doing fake bgsend() of $_[0]\n")
                if $ENV{VERBOSE};
            return "MOCK";  # magic value that'll not be treated as a socket
        }
        if ($method eq "bgread" && $_[0] eq "MOCK") {
            Test::More::note("mock DNS resolver returning mock packet for bgread.")
                if $ENV{VERBOSE};
            return $self->{next_fake_packet};
        }
        # No verbose conditional on this one because it shouldn't happen:
        Test::More::note("Calling through to Net::DNS::Resolver proxy method '$method'");
        return $self->{proxy}->$method(@_);
    };
}

BEGIN {
    *search = _make_proxy("search");
    *query = _make_proxy("query");
    *send = _make_proxy("send");
    *bgsend = _make_proxy("bgsend");
    *bgread = _make_proxy("bgread");
}

1;
