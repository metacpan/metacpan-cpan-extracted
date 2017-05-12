package Module::Build::TAPArchive;
use warnings;
use strict;
use base 'Module::Build';
use TAP::Harness::Archive;

our $VERSION = '0.04';

__PACKAGE__->add_property(archive_file => 'test_archive.tar.gz');

=head1 NAME

Module::Build::TAPArchive - Extra build targets for creating TAP archives

=head1 SYNOPSIS

Easily add support for extra build targets that create TAP archives of the tests.

In your Build.PL

    use Module::Builder::TAPArchive;
    my $builder = Module::Builder::TAPArchive->new(
        ...
    );

Now you get these build targets

    ]$ perl Build.PL
    ]$ ./Build test_archive

=head1 NEW TARGETS

The following build targets are provided:

=head2 test_archive

Create a TAP archive to the test run. This archive is placed at
F<test_archive.tar.gz> in the current directory by default. You can override this by
specifying the C<--archive_file> parameter.

    ./Build test_archive --archive_file mytests.tar.gz

=cut

sub ACTION_test_archive {
    my $self = shift;
    $self->{properties}{use_tap_harness} = 1;
    my $archive_file = $self->{properties}{archive_file} || 'test_archive.tar.gz';

    # make Module::Build use our archive method instead of run_tap_harness
    local *Module::Build::run_tap_harness = sub {
        my ($self, $tests) = @_;
        TAP::Harness::Archive->new(
            {
                lib       => \@INC,
                verbosity => $self->{properties}{verbose},
                switches  => [$self->harness_switches],
                archive   => $archive_file,
                %{$self->tap_harness_args},
            }
        )->runtests(@$tests);
    };
    $self->add_to_cleanup($archive_file);
    $self->generic_test(type => 'default');
}


=head1 AUTHOR

Michael Peters, C<< <mpeters at plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-build-taparchive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-TAPArchive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Build::TAPArchive

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build-TAPArchive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Build-TAPArchive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Build-TAPArchive>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Build-TAPArchive/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Peters, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
