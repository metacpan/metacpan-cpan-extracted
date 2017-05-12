package SystemTray::Applet;

use warnings;
use strict;

use Module::Pluggable::Ordered search_path => [ "SystemTray::Applet" ];

=head1 NAME

SystemTray::Applet - OS agnostic system tray applets

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This code wraps existing gui toolkits and lets you create a system tray applet that doesn't require knowledge of the users toolkit.

    use SystemTray::Applet;

    my $foo = SystemTray::Applet->new("text" => "hello world");

=head1 FUNCTIONS

=cut

=head2 new

 $applet = SystemTray::Applet->new( "text" => "hello world" );

This method looks for the highest priority plugin under the SystemTray::Applet namespace and passes the 
plugin name and any arguments passed in to create. This allows developers to use SystemTray::Applet to construct
one of its system specific subclasses without knowing which ones may be installed.

If no plugins are found or object construction fails undef is returned.

=cut
 
sub new
{
	my ( $class , %args ) = @_;

	my $fake = bless( {} , $class );
	my @plugins = $fake->plugins_ordered();
	if( @plugins )
	{
		return create( $plugins[0] , %args );
	}
	else
	{
		warn( "No plugins available" );
		return undef;
	}
}


=head2 create

 $applet = System::Tray::Applet::CmdLine->create( "text" => "hello world" );

This method is the SystemTray applet constructor. It should not be called directly. It should be called
via SystemTray::Applet->new or as a subclasses constructor e.g. SystemTray::Applet::Create->create();

The following arguments can be passed as name value pairs

=over 4

=item icon - name of a file to use as applet icon 

=item text - text to display in applet or as hover text if an icon is supplied

=item callback - function to update the icon and text over time

=item frequency	- how often in seconds to call the callback function

=item immediate	- if true the callback is called on object creation , usually you need to wait frequency seconds

=back

Note : The callback does not need to call $self->display() or $self->schedule() as the module takes care of that.

If the object can not be constucted undef is returned.

=cut

sub create
{
	my ( $class , %args ) = @_;
	my $self = {};
	bless( $self , $class );


	if( defined( $args{"icon"} ) )
	{
		my $icon = $self->create_icon($args{"icon"});
		if( $icon )
		{
			$self->{"icon"} = $icon;
		}
	}

	if( defined( $args{"text"} ) )
	{
		$self->{"text"} = $args{"text"};
	}

	if( defined( $args{"frequency"} ) )
	{
		if( int($args{"frequency"}) != 0 )
		{
			$self->{"frequency"} = $args{"frequency"};
		}
		else
		{
			$self->{"frequency"} = -1;
		}
	}
	else
	{
		$self->{"frequency"} = -1;
	}

	if( defined( $args{"callback"} ) )
	{
		$self->{"callback"} = sub { my ( $self ) = @_; $args{"callback"}->($self);$self->display();$self->schedule()};	
	}
	else
	{
		$self->{"frequency"} = -1;
	}


	if( defined($args{"immediate"}) && $args{"immediate"} )
	{
		unless( defined($self->{"callback"} ) )
		{
			warn( "No callback available to call" );
			return undef;
		}
	}	
	

	
	unless( defined( $self->init() ) )
	{
		return undef;	
	}

	if( defined($args{"immediate"})  && $args{"immediate"} )
	{
		$args{"callback"}->($self);
	}
	$self->display();
	$self->schedule();
	$self->start();
}


=head2 init

 $self->init();

Subclass specific init method for object initialization.

This should not be call directly as it is only used by system specific subclasses.

This should return true in subclasses.

=cut

sub init
{
	my ( $self ) = @_;

	die( "You can not use " . ref($self) . " directly , you must use a subclass" );
}


=head2 icon

 $self->icon("foo.ico");

This method sets the objects icon by calling the system specific create icon method in the subclass

=cut

sub icon
{
	my ( $self , $icon ) = @_;
	$self->{"icon"} = $self->create_icon($icon);
}


=head2 create_icon

 $self->create_icon();

Subclass specific create_icon method for creating an icon class used by the system specific gui code.

This should not be called directly as it is only provided by the system specific subclass.

=cut

sub create_icon
{
	my ( $self ) = @_;

        die( "You can not use " . ref($self) . " directly , you must use a subclass" );
}


=head2 display

 $self->display();

Subclass specific display method for updating the GUI representation of the applet.

This should not be called directly as it is only provided by the system specific subclass.

=cut

sub display
{
        my ( $self ) = @_;

        die( "You can not use " . ref($self) . " directly , you must use a subclass" );
}


=head2 schedule

 $self->schedule();

Subclass specific schedule method for scheduling the callback.

This should not be called directly as it is only provided by the system specific subclass.

=cut

sub schedule
{
        my ( $self ) = @_;

        die( "You can not use " . ref($self) . " directly , you must use a subclass" );
}


=head2 start
 
 $self->start();

Subclass specific method for starting the gui up. This never returns.

=cut

sub start
{
        my ( $self ) = @_;

        die( "You can not use " . ref($self) . " directly , you must use a subclass" );
}

=head1 AUTHOR

Peter Sinnott, C<< <psinnott at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-systemtray-applet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SystemTray-Applet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SystemTray::Applet


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

1; # End of SystemTray::Applet
