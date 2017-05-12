package SystemTray::Applet::Win32;

use warnings;
use strict;

use base qw( SystemTray::Applet );

use Win32::GUI();

# this helps the applet die gracefully if windows shuts down
$SIG{QUIT} = "DEFAULT";

sub import
{
    my ( $class , $hidden ) = @_;
    
    if( !defined($hidden))
    {
        $hidden = 1;
    }
    
    if( $hidden )
    {
        my ($DOS) = Win32::GUI::GetPerlWindow();
        Win32::GUI::Hide($DOS);
    }
}

END
{
    my ($DOS) = Win32::GUI::GetPerlWindow();
    Win32::GUI::Show($DOS);
}

=head1 NAME

SystemTray::Applet::Win32 - Windows support for SystemTray::Applet

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module provides windows support for SystemTray::Applet.

    use SystemTray::Applet::Win32;

    my $foo = SystemTray::Applet::Win32->create( "text" => "hello world" );

By default the console window is hidden during program execution.
If you want to leave it visible then pass 0 to the module import.

    use SystemTray::Applet::Win32 qw(0);
    
=head1 FUNCTIONS

=head2 function1

=cut

=head2 init

 $self->init();

Initialize the toolkit env. Creates the notification icon

=cut


sub init
{
	my ( $self ) = @_;

        my $rand = int(rand(1000000));
        $self->{"win32"}->{"id"} = $rand;
        $self->{"win32"}->{"window"} = Win32::GUI::Window->new( -name => 'Main$rand', -width => 100, -height => 100);
        $self->{"win32"}->{"popup"} = Win32::GUI::Menu->new("Options" => "Options", ">Quit" => {-name => "Quit" , -onClick => sub { return -1; } } );
        $self->{"win32"}->{"notify_icon"} = $self->{"win32"}->{"window"}->AddNotifyIcon(-name => "_NI$rand" );
        
        eval "package main; sub _NI" . $rand . "_RightClick { SystemTray::Applet::Win32::_RightClick(\$self);}";
        print $@ . "\n";
        
        eval "package main; sub _Timerd" . $rand . "_Timer { SystemTray::Applet::Win32::_Timer(\$self);}";
        print $@ . "\n";
        
        if( $self->{"frequency"} != -1 )
        {
            $self->{"win32"}->{"timer"} = $self->{"win32"}->{"window"}->AddTimer( "_Timerd$rand" , $self->{"frequency"} * 1000 );
        }
	else
	{
            $self->{"win32"}->{"timer"} = $self->{"win32"}->{"window"}->AddTimer( "_Timerd$rand" , 0 );
	}
        
	return $self;
}

sub _Timer
{
    my ( $self ) = @_;
        
    $self->{"callback"}->($self);
    if( $self->{"frequency"} != -1 )
    {
        $self->{"win32"}->{"timer"}->Interval($self->{"frequency"} * 1000);
    }
}


sub _RightClick
{	
   my ( $self ) = @_;
   
   my ( $x, $y ) = Win32::GUI::GetCursorPos;
   Win32::GUI::TrackPopupMenu($self->{"win32"}->{"window"}->{-handle}, $self->{"win32"}->{"popup"}->{Options}, $x , $y );
}


=head2 start

 $self->start();

Start the gui up by starting the win32 mainloop. Never returns.

=cut

sub start
{
	Win32::GUI::Dialog();
	exit(0);
}


=head2 create_icon

 $self->create_icon("an_icon.jpg" );

Create an icon from a file and return it. Supports whatever Win32::GUI::Icon does.

=cut

sub create_icon
{
	my ( $self , $icon ) = @_;

	if( defined( $icon ) )
	{
		return Win32::GUI::Icon->new($icon);
	}	
	else
	{
		return undef;
	}
}


=head2 display

 $self->display();

Display the icon with the text as hovertext if we have an icon  or hovertext with no icon if none is specified.

=cut

sub display
{
    my ( $self ) = @_;

    if( defined($self->{"icon"}) )
    {
        $self->{"win32"}->{"notify_icon"}->Change( -name => "_NI" . $self->{"win32"}->{"id"} , -icon => $self->{"icon"} , -tip => $self->{"text"} );
    }
    else
    {
        $self->{"win32"}->{"notify_icon"}->Change( -name => "_NI" . $self->{"win32"}->{"id"} , -tip => $self->{"text"} );   
    }
}


=head2 schedule

 $self->schedule();

Schedule the callback.

=cut

sub schedule
{
	my ( $self ) = @_;
	
	if( $self->{"frequency"} != -1 )
	{       
		$self->{"win32"}->{"timer"}->Interval( $self->{"frequency"} * 1000 );
	}
        else
        {
                $self->{"win32"}->{"timer"}->Interval(0);
        }
}


=head2 _order

This specifies the priority used by SystemTray::Applet->new when loading plugin. Win32 is 1 as if it is installed we should probably use it.

=cut

sub _order
{
	return 1;
}

=head1 AUTHOR

Peter Sinnott, C<< <psinnott at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-systemtray-applet-win32 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SystemTray-Applet-Win32>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SystemTray::Applet::Win32


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SystemTray-Applet-Win32>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SystemTray-Applet-Win32>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SystemTray-Applet-Win32>

=item * Search CPAN

L<http://search.cpan.org/dist/SystemTray-Applet-Win32>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Sinnott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SystemTray::Applet::Win32
