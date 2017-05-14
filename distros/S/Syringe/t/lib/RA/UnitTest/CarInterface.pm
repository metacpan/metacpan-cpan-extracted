use MooseX::Declare;

# test interface for unit tests for RA::DI::Container

role RA::UnitTest::CarInterface {
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

    has 'engine'   => (
        does     => 'RA::UnitTest::EngineInterface',
        is       => 'ro',
        required => 1
    );

    has 'transmission'   => (
        does     => 'RA::UnitTest::TransmissionInterface',
        is       => 'ro',
        required => 1
    );

    method start_engine {
        $self->engine->start;
    }

    method stop_engine {
        $self->engine->stop;
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
