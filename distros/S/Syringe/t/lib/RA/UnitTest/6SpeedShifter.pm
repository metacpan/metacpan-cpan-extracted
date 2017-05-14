use MooseX::Declare;

# test class for unit tests for RA::DI::Container

class RA::UnitTest::6SpeedShifter with RA::UnitTest::ShifterInterface {
    has 'pattern' => (
        isa      => 'Str',
        is       => 'ro',
        required => 1,
    );

    method up_shift {
        return 1;
    }

    method down_shift {
        return 1;
    }

    method reverse_shift {
        return 1;
    }

    method put_in_neutral {
        return 1;
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
