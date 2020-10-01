package Parallel::ForkManager::Segmented::Base;
$Parallel::ForkManager::Segmented::Base::VERSION = '0.4.0';
use strict;
use warnings;
use autodie;
use 5.014;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ( $self, $args ) = @_;

    return;
}

sub process_args
{
    my ( $self, $args ) = @_;

    my $WITH_PM   = !$args->{disable_fork};
    my $items     = $args->{items};
    my $stream_cb = $args->{stream_cb};
    my $cb        = $args->{process_item};
    my $batch_cb  = $args->{process_batch};

    if ( $stream_cb && $items )
    {
        die "Do not specify both stream_cb and items!";
    }
    if ( $batch_cb && $cb )
    {
        die "Do not specify both process_item and process_batch!";
    }
    $batch_cb //= sub {
        foreach my $item ( @{ shift() } )
        {
            $cb->($item);
        }
        return;
    };
    my $nproc      = $args->{nproc};
    my $batch_size = $args->{batch_size};

    # Return prematurely on empty input to avoid calling $ch with undef()
    # at least once.
    if ($items)
    {
        if ( not @$items )
        {
            return;
        }
        $stream_cb = sub {
            my ($args) = @_;
            my $size = $args->{size};

            return +{ items =>
                    scalar( @$items ? [ splice @$items, 0, $size ] : undef() ),
            };
        };
    }
    return +{
        WITH_PM    => $WITH_PM,
        batch_cb   => $batch_cb,
        batch_size => $batch_size,
        nproc      => $nproc,
        stream_cb  => $stream_cb,
    };
}

sub serial_run
{
    my ( $self, $processed ) = @_;
    my ( $WITH_PM, $batch_cb, $batch_size, $nproc, $stream_cb, ) =
        @{$processed}{qw/ WITH_PM batch_cb batch_size nproc stream_cb  /};

    while (
        defined( my $batch = $stream_cb->( { size => $batch_size } )->{items} )
        )
    {
        $batch_cb->($batch);
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parallel::ForkManager::Segmented::Base - base class for Parallel::ForkManager::Segmented

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    package Parallel::ForkManager::Segmented::Mine;

    use parent 'Parallel::ForkManager::Segmented::Base';

    sub run
    {
    }

=head1 DESCRIPTION

This module provides the new() and process_args() methods for L<Parallel::ForkManager::Segmented>
and for L<Parallel::Map::Segmented> .

=head1 METHODS

=head2 my $obj = Parallel::ForkManager::Segmented::Base->new;

Initializes a new object.

=head2 my \%ret = $obj->process_args(+{ %ARGS })

Process the arguments passed to run().

=head2 $obj->serial_run($process_args)

Implement a (possibly naïve) serial run.

Added in version 0.4.0.

=head1 SEE ALSO

=over 4

=item * L<Parallel::ForkManager::Segmented>

=item * L<Parallel::ForkManager>

=item * L<Parallel::Map::Segmented>

Based on L<IO::Async::Function> and L<Parallel::Map> - a less snowflake approach.

=item * L<https://perl-begin.org/uses/multitasking/>

=back

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Parallel-ForkManager-Segmented-Base>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parallel-ForkManager-Segmented-Base>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Parallel-ForkManager-Segmented-Base>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Parallel-ForkManager-Segmented-Base>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Parallel-ForkManager-Segmented-Base>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Parallel::ForkManager::Segmented::Base>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-parallel-forkmanager-segmented-base at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Parallel-ForkManager-Segmented-Base>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Parallel-ForkManager-Segmented>

  git clone https://github.com/shlomif/perl-Parallel-ForkManager-Segmented.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/parallel-forkmanager-segmented-base/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
