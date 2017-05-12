package POE::Component::Client::Bayeux::Transport;

use strict;
use warnings;
use Data::Dumper;
use Params::Validate;
use POE qw(
    Component::Client::Bayeux::Transport::LongPolling
);

my $child_counter = 0;

sub spawn {
    my $class = shift;
    my %args = validate(@_, {
        type => 1,
        parent => 1,
        parent_heap => 1,
    });

    # TODO: support more than one transport
    die "Support only long-polling at the moment"
        unless $args{type} eq 'long-polling';

    my $package = 'POE::Component::Client::Bayeux::Transport::LongPolling';

    my @extra_states = $package->extra_states();

    my $session = POE::Session->create(
        inline_states => {
            _start => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];

                $heap->{alias} = __PACKAGE__ . '_' . $child_counter++;
                $kernel->alias_set($heap->{alias});
            },
            _stop => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                $kernel->alias_remove($heap->{alias});
            },
            shutdown => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                $kernel->alias_remove($heap->{alias});
            }, 
        },
        package_states => [
            $package => [
                qw(
                    check startup sendMessages deliver disconnect
                    tunnelCollapse tunnelInit
                ),
                @extra_states
            ],
        ],
        heap => {
            %args,
        },
        ($ENV{POE_DEBUG} ? (
        options => { trace => 1, debug => 1 },
        ) : ()),
    );

    return $session->ID;
}

# Placeholder methods for child transports

sub extra_states {
}
sub check {
}
sub startup {
}
sub sendMessages {
}
sub deliver {
}
sub disconnect {
}
sub tunnelCollapse {
}
sub tunnelInit {
    my $class = shift;
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    if (! $heap->{parent_heap}{_initialized} || $heap->{parent_heap}{_connected}) {
        die "Attempting connect() when already connected or not initalized";
    }
}

1;
