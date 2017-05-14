use MooseX::Declare;

# test interface for unit tests for RA::DI::Container

role RA::UnitTest::EngineInterface {
    requires qw(
        start_sound
        stop_sound
        idle_sound
        catastrophic_failure_sound
    );

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

    has 'year'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1
    );

    has 'displacement'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1
    );

    has 'cylinders'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1
    );

    has 'horsepower'   => (
        isa      => 'Int',
        is       => 'ro',
        required => 1
    );

    method start {
        $self->start_sound();
        return 1;
    }

    method idle {
        $self->idle_sound();
        return 1;
    }

    method stop {
        $self->stop_sound();
        return 1;
    }

    method catastrophic_failure {
        $self->catastrophic_failure_sound();
        return 1;
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
