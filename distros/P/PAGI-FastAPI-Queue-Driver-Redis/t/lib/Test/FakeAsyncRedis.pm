package Test::FakeAsyncRedis;

# A minimal, in-process stand-in for the subset of Async::Redis's
# Future-returning API that PAGI::FastAPI::Queue::Driver::Redis calls
# (connect, rpush, lpop, llen, scan, disconnect). Lets the driver's own
# logic (key prefixing, JSON round-tripping, cursor handling, lazy/
# once-only connect) be tested deterministically without a real Redis
# server or the real Async::Redis module installed.

use v5.38;
use Future;

sub new {
    my ($class, %args) = @_;
    return bless {
        store          => {},
        connect_calls  => 0,
        disconnected   => 0,
        scan_page_size => $args{scan_page_size} // undef, # undef = one page
    }, $class;
}

sub connect_calls { return $_[0]->{connect_calls}       }
sub disconnected  { return $_[0]->{disconnected}        }
sub keys_in_store { return [ keys %{ $_[0]->{store} } ] }

sub connect {
    my ($self) = @_;
    $self->{connect_calls}++;
    return Future->done(1);
}

sub rpush {
    my ($self, $key, @values) = @_;
    push @{ $self->{store}{$key} //= [] }, @values;
    return Future->done(scalar @{ $self->{store}{$key} });
}

sub lpop {
    my ($self, $key) = @_;
    return Future->done(undef)
        unless $self->{store}{$key} && @{ $self->{store}{$key} };
    return Future->done(shift @{ $self->{store}{$key} });
}

sub llen {
    my ($self, $key) = @_;
    return Future->done(scalar @{ $self->{store}{$key} // [] });
}

# Supports pagination (via scan_page_size) so tests can exercise the
# multi-page cursor loop in size(), not just the single-page case.
sub scan {
    my ($self, $cursor, %rest) = @_;
    my $pattern = $rest{MATCH} // '*';
    (my $re = quotemeta($pattern)) =~ s/\\\*/.*/g;

    my @matching = sort grep { /^$re$/ } keys %{ $self->{store} };

    my $page_size = $self->{scan_page_size} // (scalar(@matching) || 1);
    my $start     = $cursor;
    my @page      = @matching[$start .. min($start + $page_size - 1, $#matching)];
    my $next      = ($start + $page_size >= @matching) ? 0 : $start + $page_size;

    return Future->done($next, \@page);
}

sub min { return $_[0] < $_[1] ? $_[0] : $_[1] }

sub disconnect {
    my ($self) = @_;
    $self->{disconnected}++;
    return 1;
}

1;
