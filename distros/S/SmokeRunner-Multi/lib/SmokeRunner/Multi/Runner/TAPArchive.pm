package SmokeRunner::Multi::Runner::TAPArchive;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Runner subclass which creates a TAP archive file
$SmokeRunner::Multi::Runner::TAPArchive::VERSION = '0.21';
use strict;
use warnings;

use base 'SmokeRunner::Multi::Runner';
__PACKAGE__->mk_ro_accessors( 'tap_archive_file' );

use Archive::Tar;
use File::Basename qw( basename );
use File::chdir;
use File::Spec;
use File::Temp qw( tempfile tempdir );
use SmokeRunner::Multi::SafeRun qw( safe_run );
use SmokeRunner::Multi::Validate qw( validate ARRAYREF_TYPE );
use YAML::Syck qw( Dump );


sub new
{
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub run_tests
{
    my $self = shift;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $archive  = Archive::Tar->new();

    my @files     = $self->set()->test_files();
    my %meta_info =
        ( file_order => \@files,
          start_time => time,
        );

    {
        local $CWD = $self->set()->set_dir();
        foreach my $file (@files) {
            my $output;
            safe_run
                ( command       => $self->_perl_bin(),
                  args          => [ $self->_libs(), $file ],
                  stdout_buffer => \$output,
                  stderr_buffer => \$output,
                );

            my $basename = basename( $file, '.t' );
            my $destination
                = File::Spec->catfile( $temp_dir, "$basename.tap" );

            open my $fh, '>', $destination
                or die "Cannot write to $destination: $!";
            print $fh $output
                or die "Cannot write to $destination: $!";
            close $fh
                or die "Cannot write to $destination: $!";
        }
    }

    $meta_info{stop_time} = time;
    open my $meta_fh, '>', File::Spec->catfile( $temp_dir, 'meta.yml' )
        or die "Could not open meta.yml for writing: $!";
    print $meta_fh Dump( \%meta_info );
    close $meta_fh;

    $archive->add_files( glob( File::Spec->catfile( $temp_dir, '*' ) ) );

    my $tar_file = File::Spec->catfile( $temp_dir, "tap-archive-$$.tar.gz" );
    $archive->write( $tar_file, 1 );

    $self->{tap_archive_file} = $tar_file;
}

# adapted from Test::Harness::Straps
sub _perl_bin
{
    return $ENV{HARNESS_PERL}
        if defined $ENV{HARNESS_PERL};

    return qq["$^X"]
        if $^O =~ /^(MS)?Win32$/ && $^X =~ /[^\w\.\/\\]/;

    return $^X;
}

sub _libs
{
    return '-Mblib', '-Mlib=lib';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::Runner::TAPArchive - Runner subclass which creates a TAP archive file

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $runner = SmokeRunner::Multi::Runner::TAPArchive->new( set => $set );

  $runner->run_tests();

  my $archive_file = $runner->tap_archive_file;

=head1 DESCRIPTION

This subclass runs tests to produce a F<.tar.gz> file which contains a
set of TAP files for a test run. Each file contains the output from a
single test file, with a C<.tap> extension. In addition to the TAP
files, a F<meta.yml> file is included which contains extra information
about the test run.

=head1 METHODS

This class provides the following methods:

=head2 SmokeRunner::Multi::Runner::TAPArchive->new()

This method creates a new runner object. It requires one parameter:

=over 4

=item * set

A C<SmokeRunner::Multi::TestSet> object.

=back

=head2 $runner->run_tests()

This method runs the tests.

=head2 $runner->tap_archive_file()

This returns the filename of the resulting TAP archive.

=head1 AUTHOR

Michael Peters, <mpeters@plusthree.com>
Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
