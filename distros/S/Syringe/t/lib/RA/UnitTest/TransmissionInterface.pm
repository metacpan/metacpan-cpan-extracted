use MooseX::Declare;

# test interface for unit tests for RA::DI::Container

role RA::UnitTest::TransmissionInterface {
    has 'make'   => (
        isa      => 'Str',
        is       => 'ro',
        required => 1
    );

    has 'model'   => (
        isa      => 'Str',
        is       => 'ro',
        required => 1
    );

    has 'interface'   => (
        does     => 'RA::UnitTest::ShifterInterface',
        is       => 'ro',
        required => 1
    );

    has 'current_gear'   => (
        isa      => 'Int',
        is       => 'rw',
        required => 1,
        default  => 0, # neutral
    );

    has 'forward_gears'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1,
    );

    has 'reverse_gears'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1,
    );

    method upshift {
        if ($self->current_gear == $self->forward_gears) {
            return;
        }
        else {
            $self->current_gear($self->current_gear + 1);
        }
    }

    method downshift {
        if ($self->current_gear < 1) {
            return;
        }
        else {
            $self->current_gear($self->current_gear - 1);
        }
    }

    method put_in_neutral {
        $self->current_gear(0);
    }

    method put_in_reverse {
        if ($self->current_gear < 1) {
            $self->current_gear(-1);
        } else {
            print "CRUNCHHHH!\n";
        }
    }
}

1;

__END__

=head1 AUTHOR

Rick Apichairuk <rick.apichairuk@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2012

=head1 LICENSE

Same as Perl

=cut
