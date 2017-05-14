use MooseX::Declare;

# test interface for unit tests for RA::DI::Container

role RA::UnitTest::ShifterInterface {
    requires qw(up_shift down_shift reverse_shift put_in_neutral);
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
