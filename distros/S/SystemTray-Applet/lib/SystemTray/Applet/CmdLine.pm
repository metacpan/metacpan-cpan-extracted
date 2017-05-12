package SystemTray::Applet::CmdLine;

use warnings;
use strict;

use base qw( SystemTray::Applet );


=head1 NAME

SystemTray::Applet::CmdLine - Sometimes text is all you need

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module supplies a subclass of SystemTray::Applet that allows you to display applets when all you have is a command line.

    use SystemTray::Applet::CmdLine;

    my $foo = SystemTray::Applet::CmdLine->create( "text" => "hello world" );

=head1 FUNCTIONS

=cut


=head2 init

 $self->init();

Initialize the toolkit env. Nothing need to be done for the command line.

=cut

sub init
{
	my ( $self ) = @_;

	return $self;
}


=head2 start

 $self->start();

Start the gui up. The command line doesn't have an event loop of its own so this
just loops around for ever , calling the callback as needed.

=cut

sub start
{
	my ( $self ) = @_;
	
	while(1)
	{
		sleep(1);
		if( $self->{"frequency"} != -1 )
		{
			$self->{"CmdLine"}->{"counter"}--;
			if( $self->{"CmdLine"}->{"counter"} == 0 )
			{
				$self->{"callback"}->($self);
				$self->schedule();
			}
		}
	}
	exit(0);
}


=head2 create_icon
 
 $self->create_icon("what is a text icon" );

Create a command line icon? Text doesn't really have icons

=cut

sub create_icon
{
	my ( $self , $icon ) = @_;

}



=head2 display

 $self->display();

Display the value of the text field to screen.

=cut

sub display
{
	my ( $self ) = @_;
	print $self->{"text"} . "\n";
}


=head2 schedule

 $self->schedule();

Schedule the callback by setting the counter back to the frequency

=cut

sub schedule
{
	my ( $self ) = @_;

	if( $self->{"frequency"} != -1 )
	{
		$self->{"CmdLine"}->{"counter"} =  $self->{"frequency"};
	}
}


=head2 _order

This specifies the priority used by SystemTray::Applet->new when loading plugin. The command line should only be used when nothing else is available.

=cut

sub _order
{
	return 90;
}


=head1 AUTHOR

Peter Sinnott, C<< <psinnott at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-systemtray-applet-gnome at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SystemTray-Applet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SystemTray::Applet::CmdLine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SystemTray-Applet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SystemTray-Applet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SystemTray-Applet>

=item * Search CPAN

L<http://search.cpan.org/dist/SystemTray-Applet>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Sinnott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SystemTray::Applet::CmdLine
