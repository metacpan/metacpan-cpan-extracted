package MyCPAN::Indexer::Interface::Curses;
use strict;
use warnings;

BEGIN {
	my $rc = eval { require Curses; 1 };

	die "You need to install the Curses module to use MyCPAN::Indexer::Interface::Curses";
	Curses->import;
}

use vars qw($VERSION $logger);
$VERSION = '1.28';

=head1 NAME

MyCPAN::Indexer::Interface::Curses - Present the run info in a terminal

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Curses

=head1 DESCRIPTION

This class presents the information as the indexer runs, using Curses.

=head2 Methods

=over 4

=item do_interface( $Notes )


=cut

BEGIN { $SIG{INT} = sub { exit } }

BEGIN {
	use Log::Log4perl;
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

sub component_type { $_[0]->interface_type }

sub do_interface
	{
	my( $self ) = @_;
	$logger->debug( "Calling do_interface" );

	initscr();
	noecho();
	raw();

	$self->set_note( 'curses', {} );
	my $curses = $self->get_note( 'curses' );
	
	$curses->{rows} = LINES();
	$curses->{cols} = COLS();

	addstr( 0, 0, join " ", $Notes->{Config}{indexer_class}, $Notes->{Config}{indexer_class}->VERSION );
	refresh();

	$curses->{windows}{progress}      = newwin( 3, COLS(),   1,  0 );
	$curses->{windows}{left_tracker}  = newwin( 6, 20,   4,  0 );
	$curses->{windows}{right_tracker} = newwin( 6, COLS() - 21,   4, 21 );
	$curses->{windows}{PID}           = newwin( 7, COLS(),  10,  0 );
	$curses->{windows}{Errors}        = newwin( 7, COLS(), 17,  0 );

	foreach my $value ( values %{ $curses->{windows} } )
		{
		box( $value, 0, 0 );
		refresh( $value );
		}

	my $count = 0;
	while( 1 )
		{
		$self->get_note( 'interface_callback' )->();

		$self->_update_screen( $Notes );

		last if $self->get_note( 'Finished' );
		}

	}

{
no warnings;
my $labels = {
	# Label,           win,        row, column, key, key length, value length
	Total      => [ qw(left_tracker  1  1 Total         6   6) ],
	Done       => [ qw(left_tracker  2  1 Done          6   6) ],
	Left       => [ qw(left_tracker  3  1 Left          6   6) ],
	Errors     => [ qw(left_tracker  4  1 Errors        6   6) ],

	UUID       => [ qw(right_tracker 1  1 UUID          8  30) ],
	Started    => [ qw(right_tracker 2  1 Started       8 -30) ],
	Elapsed    => [ qw(right_tracker 3  1 Elapsed       8 -30) ],
	Rate       => [ qw(right_tracker 4  1 Rate          8 -30) ],
	};

my $headers = {
	'##'       => [ qw(PID           1  1 ##            2   0) ],
	PID        => [ qw(PID           1  5 PID           6   0) ],
	Processing => [ qw(PID           1 13 Processing  -40   0) ],

	ErrorList  => [ qw(Errors        0  1 Errors        7   0) ],
	};

my $values = {};

sub _update_screen
	{
	$_[0]->_update_labels;
	$_[0]->_update_progress;
	$_[0]->_update_values;
	}

sub _update_labels
	{
	my( $self ) = @_;

	#print "Calling _update_screen\n";

	my $curses = $self->get_note( 'curses' );
	
	foreach my $key ( keys %$labels )
		{
		my $tuple = $labels->{$key};

		eval { addstr(
			$curses->{windows}{ $tuple->[0] },
			@$tuple[1,2,3]
			);
		refresh( $curses->{windows}{ $tuple->[0] } );
		};
		}

	foreach my $key ( keys %$headers )
		{
		my $tuple = $headers->{$key};

		eval {

		my $width = $tuple->[4];
		addstr(
			$curses->{windows}{ $tuple->[0] },
			@$tuple[1,2],
			sprintf "%${width}s", $tuple->[3]
			);
		refresh( $curses->{windows}{ $tuple->[0] } );
		};
		}


	foreach my $i ( 1 .. $Notes->{Threads} )
		{
		no warnings;
		my $width = $headers->{'##'}[4];
		addstr(
			$curses->{windows}{PID},
			$i + 1,
			$headers->{'##'}[2] + 1,
			sprintf "%${width}s", $i );
		refresh( $curses->{windows}{PID} );
		}

	refresh( $curses->{windows}{PID} );
	}

sub _update_progress
	{
	my( $self ) = @_;

	my $curses = $self->get_note( 'curses' );

	my $progress = eval { ( COLS() - 2 ) / $Notes->{Total} * $Notes->{Done} } || 0;

	addstr(
		$curses->{windows}{progress},
		1, 1,
		'*' x $progress
		);
	refresh( $curses->{windows}{progress} );
	}

sub _update_values
	{
	my( $self ) = @_;

	my $curses = $self->get_note( 'curses' );

	no warnings;
	foreach my $key ( qw(Total Done Left Errors UUID Started Elapsed Rate) )
		{
		my $tuple = $labels->{$key};

		addstr(
			$curses->{windows}{ $tuple->[0] },
			$tuple->[1],
			$tuple->[2] + $tuple->[4] + 2,
			sprintf "%" . $tuple->[5] . "s", $self->get_notes( $tuple->[3] );
			);
		refresh( $curses->{windows}{ $tuple->[0] } );
		}

	foreach my $i ( 1 .. $self->get_note( 'Threads' ) )
		{
		my $width = $headers->{PID}[4];
		addstr(
			$curses->{windows}{PID},
			$i + 1, $headers->{PID}[2],
			sprintf "%${width}s", $self->get_note('PID')->[$i-1]
			);

		$width = COLS() - $headers->{Processing}[2] - 1;
		addstr(
			$curses->{windows}{PID},
			$i + 1,
			$headers->{Processing}[2],
			' ' x ( COLS() - $headers->{Processing}[2] - 1 )
			);
			
		my $recent = $self->get_note( 'recent' );
		
		addstr(
			$curses->{windows}{PID},
			$i + 1,
			$headers->{Processing}[2],
			sprintf "%-${width}s", substr(
				(defined $recent->[$i-1] ? $recent->[$i-1] : ''), 0, $width )
			);

		refresh( $curses->{windows}{PID} );
		}

	}
}

END { endwin() }

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
