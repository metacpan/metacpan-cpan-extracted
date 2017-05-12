package SystemTray::Applet::Gnome;

use warnings;
use strict;

use base qw( SystemTray::Applet );

use Gtk2;
use Gtk2::TrayIcon;

=head1 NAME

SystemTray::Applet::Gnome - Gnome support for SystemTray::Applet

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module provides gnome support for SystemTray::Applet.

    use SystemTray::Applet::Gnome;

    my $foo = SystemTray::Applet::CmdLine->create( "text" => "hello world" );

=head1 FUNCTIONS

=cut


=head2 init

 $self->init();

Initialize the toolkit env. Sets up Gtk2 and creates a tray icon.

=cut

sub init
{
	my ( $self ) = @_;

	Gtk2->init();

	$self->{"gnome"}->{"applet"} = Gtk2::TrayIcon->new("");
	unless( $self->{"gnome"}->{"applet"} )
	{
		warn( "Unable to create gnome tray icon" );
		return undef;	
	}

        $self->{"gnome"}->{"eventbox"} = Gtk2::EventBox->new();

        my $button_release = sub {
                my ( $self , $e ) = @_;
                if( $e->button() == 3 )
                {
                        my $menu = Gtk2::Menu->new();
                        my $menu_item = Gtk2::MenuItem->new_with_label("Quit");
                        $menu_item->signal_connect( "activate" => sub { Gtk2->main_quit; } );
                        $menu_item->show();
                        $menu->append($menu_item);
                        $menu->popup( undef , undef , undef , undef , $e->button() , $e->time()  );
                        print "Done\n";
                }
        };

        $self->{"gnome"}->{"eventbox"}->signal_connect( "button_release_event" => $button_release );
        $self->{"gnome"}->{"applet"}->add($self->{"gnome"}->{"eventbox"});
        $self->{"gnome"}->{"applet"}->show_all();

	return $self;
}


=head2 start

 $self->start();

Start the gui up by starting the gtk mainloop. Never returns.

=cut

sub start
{
	Gtk2->main();
	exit(0);
}


=head2 create_icon

 $self->create_icon("an_icon.jpg" );

Create an icon from a file and return it. Supports whatever gtk2::Image does.

=cut

sub create_icon
{
	my ( $self , $icon ) = @_;

	if( defined( $icon ) )
	{
		return Gtk2::Image->new_from_file($icon);
	}	
	else
	{
		return undef;
	}
}


=head2 display

 $self->display();

Display the icon with the text as hovertext if we have an icon or just the text if not.

=cut

sub display
{
	my ( $self ) = @_;

	my @children = $self->{"gnome"}->{"eventbox"}->get_children();
	foreach my $child( @children )
        {
                $self->{"gnome"}->{"eventbox"}->remove($child);
        }

	if( $self->{"icon"} )
	{
		$self->{"gnome"}->{"eventbox"}->add( $self->{"icon"} );
		my $tooltip = Gtk2::Tooltips->new();
		$tooltip->enable();
		$tooltip->set_tip(  $self->{"gnome"}->{"eventbox"} , $self->{"text"} );
	}
	else
	{
		my $label = Gtk2::Label->new($self->{"text"});
		$self->{"gnome"}->{"eventbox"}->add($label);
	}


	$self->{"gnome"}->{"applet"}->show_all();
}


=head2 schedule

 $self->schedule();

Schedule the callbackusing Glib::Timeout

=cut

sub schedule
{
	my ( $self ) = @_;
	
	if( $self->{"frequency"} != -1 )
	{
		if($self->{"gnome"}->{"timeout"})
		{	
			Glib::Source->remove($self->{"gnome"}->{"timeout"}) 
		}
		$self->{"gnome"}->{"timeout"} = Glib::Timeout->add ( $self->{"frequency"} * 1000 , sub { $self->{"callback"}->( $self) } );

	}
}


=head2 _order

This specifies the priority used by SystemTray::Applet->new when loading plugin. Gnome is 2 as if it is installed we should probably use it.

=cut

sub _order
{
	return 2;
}

=head1 AUTHOR

Peter Sinnott, C<< <psinnott at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-systemtray-applet-gnome at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SystemTray-Applet-Gnome>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SystemTray::Applet::Gnome


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SystemTray-Applet-Gnome>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SystemTray-Applet-Gnome>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SystemTray-Applet-Gnome>

=item * Search CPAN

L<http://search.cpan.org/dist/SystemTray-Applet-Gnome>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Sinnott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SystemTray::Applet::Gnome
