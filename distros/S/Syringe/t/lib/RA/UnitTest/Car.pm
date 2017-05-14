use MooseX::Declare;

# test class for unit tests for RA::DI::Container

class RA::UnitTest::Car with RA::UnitTest::CarInterface {
    has 'been_raced_on_track' => (
        isa      => 'Bool',
        is       => 'ro',
        required => 1,
        default  => 0,
    );

    method warranty {
        if ($self->been_raced_on_track) {
            return "I'm sorry, you're warranty is void.";
        }
        else {
            return "I'm sorry, most likely you're warranty is void anyways.";
        }
    }
}

1;

__END__

=head1 NAME

RA::DI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Rick Apichairuk <rick.apichairuk@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2012

=head1 LICENSE

Same as Perl

=cut
