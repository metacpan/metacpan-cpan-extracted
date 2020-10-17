package Test::Data::Split;
$Test::Data::Split::VERSION = '0.2.2';
use strict;
use warnings;
use autodie;

use 5.008;

use IO::All qw/ io /;


use MooX qw/ late /;

has '_target_dir' =>
    ( is => 'ro', isa => 'Str', required => 1, init_arg => 'target_dir', );
has ['_filename_cb'] =>
    ( is => 'ro', isa => 'CodeRef', required => 1, init_arg => 'filename_cb', );
has ['_contents_cb'] =>
    ( is => 'ro', isa => 'CodeRef', required => 1, init_arg => 'contents_cb', );
has '_data_obj' => ( is => 'ro', required => 1, init_arg => 'data_obj' );


sub run
{
    my $self = shift;

    my $target_dir  = $self->_target_dir;
    my $filename_cb = $self->_filename_cb;
    my $contents_cb = $self->_contents_cb;

    my $data_obj = $self->_data_obj;

    foreach my $id ( @{ $data_obj->list_ids() } )
    {
        # Croak on bad IDs.
        if ( $id !~ /\A[A-Za-z_\-0-9]{1,80}\z/ )
        {
            die "Invalid id '$id'.";
        }

        io->catfile( $target_dir, $filename_cb->( $self, { id => $id, }, ) )
            ->assert->print(
            $contents_cb->(
                $self, { id => $id, data => $data_obj->lookup_data($id) },
            )
            );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Split - split data-driven tests into several test scripts.

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

    use Test::Data::Split;

    # Implements Test::Data::Split::Backend::Hash
    use MyTest;

    my $tests_dir = "./t";

    my $obj = Test::Data::Split->new(
        {
            target_dir => $tests_dir,
            filename_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return "valgrind-$id.t";
            },
            contents_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return <<"EOF";
    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::More tests => 1;
    use MyTest;

    @{['# TEST']}
    MyTest->run_id(qq#$id#);

    EOF
            },
            data_obj => MyTest->new,
        }
    );

    $obj->run;

    # And later in the shell:
    prove t/*.t

=head1 DESCRIPTION

This module splits a set of data with IDs and arbitrary values into one
test file per (key+value) for easy parallelisation.

=head1 METHODS

=head2 my $obj = Test::Data::Split->new({ %PARAMS })

Accepts the following parameters:

=over 4

=item * target_dir

The path to the target directory - a string.

=item * filename_cb

A subroutine references that accepts C<< ($self, {id => $id }) >>
and returns the filename.

=item * contents_cb

A subroutine references that accepts
C<< ($self, {id => $id, data => $data }) >> and returns the contents inside
the file.

=item * data_obj

An object reference that implements the C<< ->list_ids() >> methods
that returns an array reference of IDs to generate as files.

=back

An example for using it can be found in the synopsis.

=head2 $self->run()

Generate the files.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Test-Data-Split>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Data-Split>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-Data-Split>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-Data-Split>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-Data-Split>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::Data::Split>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-data-split at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-Data-Split>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Test-Data-Split>

  git clone git://github.com/shlomif/perl-Test-Data-Split.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-Test-Data-Split/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
