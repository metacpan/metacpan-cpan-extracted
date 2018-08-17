package Parallel::ForkManager::Segmented;
$Parallel::ForkManager::Segmented::VERSION = '0.0.1';
use strict;
use warnings;
use 5.014;

use List::MoreUtils qw/ natatime /;
use Parallel::ForkManager ();

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

sub run
{
    my ( $self, $args ) = @_;

    my $WITH_PM    = !$args->{disable_fork};
    my $items      = $args->{items};
    my $cb         = $args->{process_item};
    my $nproc      = $args->{nproc};
    my $batch_size = $args->{batch_size};

    my $pm;

    if ($WITH_PM)
    {
        $pm = Parallel::ForkManager->new($nproc);
    }
    $cb->( shift @$items );
    my $it = natatime $batch_size, @$items;
ITEMS:
    while ( my @batch = $it->() )
    {
        if ($WITH_PM)
        {
            my $pid = $pm->start;

            if ($pid)
            {
                next ITEMS;
            }
        }
        foreach my $item (@batch)
        {
            $cb->($item);
        }
        if ($WITH_PM)
        {
            $pm->finish;    # Terminates the child process
        }
    }
    if ($WITH_PM)
    {
        $pm->wait_all_children;
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Parallel::ForkManager::Segmented - use Parallel::ForkManager on batches / segments of items.

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    #! /usr/bin/env perl

    use strict;
    use warnings;
    use 5.014;
    use Cwd ();

    use WML_Frontends::Wml::Runner ();
    use Parallel::ForkManager::Segmented ();

    my $UNCOND  = $ENV{UNCOND} // '';
    my $CMD     = shift @ARGV;
    my (@dests) = @ARGV;

    my $PWD       = Cwd::getcwd();
    my @WML_FLAGS = (
        qq%
    --passoption=2,-X3074 --passoption=2,-I../lib/ --passoption=3,-I../lib/ --passoption=3,-w -I../lib/ $ENV{LATEMP_WML_FLAGS} -p1-3,5,7 -DROOT~. -DLATEMP_THEME=sf.org1 -I $HOME/apps/wml
    % =~ /(\S+)/g
    );

    my $T2_SRC_DIR = 't2';
    my $T2_DEST    = "dest/$T2_SRC_DIR";

    chdir($T2_SRC_DIR);

    my $obj = WML_Frontends::Wml::Runner->new;

    sub is_newer
    {
        my $file1 = shift;
        my $file2 = shift;
        my @stat1 = stat($file1);
        my @stat2 = stat($file2);
        if ( !@stat2 )
        {
            return 1;
        }
        return ( $stat1[9] >= $stat2[9] );
    }

    my @queue;
    foreach my $lfn (@dests)
    {
        my $dest     = "$T2_DEST/$lfn";
        my $abs_dest = "$PWD/$dest";
        my $src      = "$lfn.wml";
        if ( $UNCOND or is_newer( $src, $abs_dest ) )
        {
            push @queue, [ [ $abs_dest, "-DLATEMP_FILENAME=$lfn", $src, ], $dest ];
        }
    }
    my $to_proc = [ map $_->[1], @queue ];
    my @FLAGS = ( @WML_FLAGS, '-o', );
    my $proc = sub {
        $obj->run_with_ARGV(
            {
                ARGV => [ @FLAGS, @{ shift(@_)->[0] } ],
            }
        ) and die "$!";
        return;
    };
    Parallel::ForkManager::Segmented->new->run(
        {
            WITH_PM      => 1,
            items        => \@queue,
            nproc        => 4,
            batch_size   => 8,
            process_item => $proc,
        }
    );
    system("cd $PWD && $CMD @{$to_proc}") and die "$!";

=head1 VERSION

version 0.0.1

=head1 METHODS

=head2 my $obj = Parallel::ForkManager::Segmented->new;

Initializes a new object.

=head2 $obj->run(+{ %ARGS });

Runs the processing. Accepts the following named arguments:

=over 4

=item * process_item

A reference to a subroutine that accepts one item and processes it.

=item * items

A reference to the array of items.

=item * nproc

The number of child processes to use.

=item * batch_size

The number of items in each batch.

=item * disable_fork

Disable forking and use of L<Parallel::ForkManager> and process the items
serially.

=back

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/parallel-forkmanager-segmented/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Parallel::ForkManager::Segmented

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Parallel-ForkManager-Segmented>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Parallel-ForkManager-Segmented>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parallel-ForkManager-Segmented>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Parallel-ForkManager-Segmented>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Parallel-ForkManager-Segmented>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Parallel-ForkManager-Segmented>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Parallel-ForkManager-Segmented>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Parallel-ForkManager-Segmented>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Parallel::ForkManager::Segmented>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-parallel-forkmanager-segmented at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Parallel-ForkManager-Segmented>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Parallel-ForkManager-Segmented>

  git clone https://github.com/shlomif/perl-Parallel-ForkManager-Segmented.git

=cut
