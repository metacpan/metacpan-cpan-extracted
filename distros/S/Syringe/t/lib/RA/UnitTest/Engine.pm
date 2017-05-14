use MooseX::Declare;

# test class for unit tests for RA::DI::Container

class RA::UnitTest::Engine with RA::UnitTest::EngineInterface {
    method start_sound {
        print "Kchhh vroooooOOOOMmmm..\n";
    }

    method stop_sound {
        print "Bupp bupp";
    }

    method idle_sound {
        print "Bup bup baa bup bup baa bup bup baa bup bup baa.\n";
    }

    method catastrophic_failure_sound {
        print "KAAAAA BOOOOOOOOOOOOOOOOOOOOOOOOMMMMMMMMM!!!!!!\n";
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
