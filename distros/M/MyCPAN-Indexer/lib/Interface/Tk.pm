package MyCPAN::Indexer::Interface::Tk;
use strict;
use warnings;

BEGIN {
	my $rc = eval {
		require Tk;
		require Tk::ProgressBar;

		Tk->import;
		Tk::ProgressBar->import;
		1 };

	die "You need to install the Tk and Tk::ProgressBar modules ".
		" to use MyCPAN::Indexer::Interface::Tk" if $@;
}

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Log::Log4perl;
use Tk;

=head1 NAME

MyCPAN::Indexer::Interface::Tk - Index a Perl distribution

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Tk

=head1 DESCRIPTION

This class presents the information as the indexer runs, using Tk.

=head2 Methods

=over 4

=item do_interface( $Notes )


=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

sub component_type { $_[0]->interface_type }

sub do_interface
	{
	my( $self ) = @_;

	my $config = $self->get_config;
	use Tk;

	my $mw = MainWindow->new;
	$mw->geometry('500x375');

	$mw->resizable( 0, 0 );
	$mw->title( join " ", $config->indexer_class, $config->indexer_class->VERSION );
	my $menubar = _menubar( $mw );

	my( $progress, $top, $middle, $bottom ) = map {
		$mw->Frame->pack(
			-anchor => 'w',
			-expand => 1,
			-fill   => 'x',
			);
		} 1 .. 4;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	my $tracker = _make_frame( $top, 'left' );

	my $tracker_left = $tracker->Frame->pack(
		-anchor => 'w',
		-side   => 'left',
		-expand => 1,
		-fill   => 'x',
		);
	foreach my $label ( qw( Total Done Left Errors ) )
		{
		my $frame = $tracker_left->Frame->pack( -side => 'top' );
		$frame->Label(
			-text  => $label,
			-width => 6 )->pack(
				-side => 'left'
				);
		$frame->Entry(
			-width        => 6,
			-textvariable => \ $Notes->{$label},
			-relief       => 'flat',
			)->pack(
				-side => 'right',
				);
		}

	my $tracker_right = $tracker->Frame->pack(
		-anchor => 'w',
		-side   => 'left',
		-expand => 1,
		-fill   => 'x',
		);
	foreach my $label ( qw( UUID Started Elapsed Rate ) )
		{
		$Notes->{$label} ||= ' ' x 60;
		my $frame = $tracker_right->Frame->pack(
			-side   => 'top',
			-anchor => 'w',
			-fill   => 'x',
			);
		$frame->Label(
			-text       => $label,
			-width      => 6,
			)->pack(
				-side => 'left',
				);
		$frame->Entry(
			-textvariable       => \ $Notes->{$label},
			-relief             => 'flat',
			-width              => -1,
			-state              => 'disabled',
			-disabledforeground => '',
			)->pack(
				-side   => 'right',
				-expand => 1,
				-fill   => 'x',
				);
		}

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	require Tk::ProgressBar;

	my $bar = $progress->Frame->pack(
		-anchor => 'w',
		-side   => 'left',
		-expand => 1,
		-fill   => 'x'
		);
	$bar->ProgressBar(
		-from     => 0,
		-to       => $Notes->{Total},
		-variable => \ $Notes->{Done},
		-colors   => [ 0, 'green',],
		-gap      => 0,
		)->pack(
			-side => 'top',
			-fill => 'x',
			);

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	my @recent = qw( a b c d e );
	my $jobs    = $middle->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );

	my $count_frame = _make_frame( $jobs, 'left' );
	$count_frame->Label( -text => '#', -width =>  3 )->pack( -side => 'top' );
	$count_frame->Listbox(
		-height        => $Notes->{Threads},
		-width         => 3,
		-listvariable  => [ 1 .. $Notes->{Threads} ],
		-relief        => 'flat',
		)->pack(
			-side => 'bottom'
			);

	my $pid_frame  = _make_frame( $jobs, 'left' );
	$pid_frame->Label( -text => 'PID', -width =>  6 )->pack( -side => 'top' );
	$pid_frame->Listbox(
		-height        => $Notes->{Threads},
		-width         => 6,
		-listvariable  => $Notes->{PID},
		-relief        => 'flat',
		)->pack(
			-side => 'bottom'
			);

	my $proc_frame = $jobs->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
	$proc_frame->Label( -text => 'Processing', -width => 35 )->pack( -side => 'top' );
	$proc_frame->Listbox(
		-height        => $Notes->{Threads},
		-listvariable  => $Notes->{recent},
		-relief        => 'flat',
		)->pack(
			-side   => 'bottom',
			-expand => 1,
			-fill   => 'x'
			);

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	my @errors = qw( dog bird cat );
	my $errors  = $bottom->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
	$errors->Label( -text => 'Errors', )->pack( -side => 'top', -anchor => 'w');
	$errors->Listbox(
		-height        => 10,
		-listvariable  => $Notes->{errors},
		-relief        => 'flat',
		)->pack(
			-expand => 1,
			-fill   => 'x',
			-side   => 'left',
			-anchor => 'w',
			);


	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	$mw->repeat( 500, $self->get_note( 'interface_callback' ) );

	MainLoop;
	}


sub _make_frame
	{
	my $mw   = shift;
	my $side = shift;

	my $frame = $mw->Frame->pack(
		-anchor => 'n',
		-side   => $side,
		);

	return $frame;
	}

sub _menubar
	{
	my $mw      = shift;

	$mw->configure( -menu => my $menubar = $mw->Menu );
	my $file_items = [
		[qw( command ~Quit -accelerator Ctrl-q -command ) => sub { exit } ]
		];

	my $file = _menu( $menubar, "~File",     $file_items );
	my $edit = _menu( $menubar, "~Edit",     [] );

	return $menubar;
	}

sub _menu
	{
	my $menubar = shift;
	my $title   = shift;
	my $items   = shift;

	my $menu = $menubar->cascade(
		-label     => $title,
		-menuitems => $items,
		-tearoff   => 0,
		 );

	return $menu;
	}


=back


=head1 SEE ALSO

MyCPAN::Indexer

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
