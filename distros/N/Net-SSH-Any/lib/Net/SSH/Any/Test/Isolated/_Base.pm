package Net::SSH::Any::Test::Isolated::_Base;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Carp;

BEGIN { *debug = \$Net::SSH::Any::Test::Isolated::debug }
our $debug;

sub _debug {
    my $self = shift;
    print STDERR "$self->{side}> " . join(': ', @_) . "\n" if $debug;
}

sub _new {
    my ($class, $side, $in, $out) = @_;
    my $self = { side => $side,
                 in => $in,
                 out => $out,
                 state => 'new'};
    bless $self, $class;
}

sub _send {
    my ($self, $packet) = @_;
    $self->_debug(send => $packet);
    say {$self->{out}} $packet;
}

sub _recv {
    my $self = shift;
    $self->_debug("waiting for data");
    my $in = $self->{in};
    my $packet = <$in> // return;
    $packet =~ s/[\r\n]+$//;
    $self->_debug(recv => $packet);
    $packet;
}

sub _serialize {
    my $self = shift;
    my $dump = Data::Dumper->new([\@_], ['D']);
    $dump->Terse(1)->Indent(0)->Useqq(1);
    my $data = $dump->Dump;
    # $self->_debug("serialized $data");
    $data;
}

sub _deserialize {
    my $self = shift;
    my ($r, $err);
    do {
        local ($@, $SIG{__DIE__});
        #$self->_debug("deserializing $_[0]");
        $r = eval $_[0] // [];
        $err = $@;
    };
    die $err if $err;
    # $self->_debug("deserialized args", Dumper($r));
    wantarray ? @$r : $r->[0];
}

sub _recv_packet {
    my $self = shift;
    while (1) {
        my $packet = $self->_recv // return;
        if (my ($head, $args) = $packet =~ /^(\w+):\s+(.*)$/) {
            my @args = $self->_deserialize($args);
            if ($head eq 'log') {
                $self->_log(@args);
                redo;
            }
            return ($head, @args);
        }
        elsif ($packet =~ /^\w+!$/) {
            return $packet
        }
        elsif ($packet =~ /^\s*(?:#.*)?$/) {
            # Ignore blank lines and comments.
        }
        else {
            $self->_debug("unexpected data packet: $packet");
            die "Internal error: unexpected data packet $packet";
        }
    }
}

sub _send_packet {
    my $self = shift;
    my $head = shift;
    my $args = $self->_serialize(@_);
    $self->_send("$head: $args");
}

sub _log {
    my $self = shift;
    print STDERR join(': ', log => @_);
}

sub _check_state {
    my ($self, $state) = @_;
    $self->{state} eq $state or croak "invalid state for action, current state: $self->{state}, expected: $state";
}

1;
