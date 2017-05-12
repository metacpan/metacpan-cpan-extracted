package Tapir::Server;

=head1 NAME

Tapir::Server - An API server

=head1 DESCRIPTION

Mainly subclassed, this offers a base class for any implementation of the API.

=cut

use Moose;
use Params::Validate;
use Carp;
use Data::Dumper;
use Try::Tiny;
use Tapir::Logger;

sub is_valid_request {
    my ($self, %opt) = @_;

    return { };
}

# User specified arguments
has 'thrift_file' => (is => 'ro', required => 1);

has 'handlers'   => (is => 'ro', default => sub { [] });
has 'transports' => (is => 'ro', default => sub { [] });
has 'logger'     => (is => 'ro', lazy_build => 1);

sub add_handler {
    my $self = shift;
    my %opt = validate(@_, {
        class => 1,
    });

    eval "require $opt{class}";
    if ($@) {
        croak "Failed to load class $opt{class}: $@";
    }

    my $service = $opt{class}->service;
    if (! $service) {
        croak "Class $opt{class} doesn't define a service";
    }

    my %methods = %{ $opt{class}->methods };
    if (! %methods) {
        croak "Class $opt{class} doesn't define any methods";
    }

    push @{ $self->handlers }, {
        class   => $opt{class},
        service => $service,
        methods => \%methods,
    };
}

sub add_transport {
    my $self = shift;
    my %opt = validate(@_, {
        class   => 1,
        options => { default => {} },
    });

    eval "require $opt{class}";
    if ($@) {
        croak "Failed to load class $opt{class}: $@";
    }

    my $transport;
    try {
        $transport = $opt{class}->new(
            server => $self, 
            logger => $self->logger,
            %{ $opt{options} }
        );
        $transport->setup();
    } catch {
        croak "Failed to load class $opt{class}: $_";
    };

    push @{ $self->transports }, $transport;
}

sub run {
    my $self = shift;

    if (! int @{ $self->transports }) {
        croak "Can't run() without any transports defined";
    }

    $_->run() foreach @{ $self->transports };
}

sub _build_logger {
    my $self = shift;
    return Tapir::Logger->new(screen => 1);
}

1;
