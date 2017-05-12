package POE::XUL::Window;
# $Id$
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.

use strict;
use warnings;
use Carp;

use POE::XUL::Node;
use POE::XUL::TWindow;
use Scalar::Util qw( blessed );

use constant DEBUG => 0;

use base qw( POE::XUL::Node );

our $VERSION = '0.0601';
our $CM;

##############################################################
sub is_window { 1 }

sub import
{
    my( $package ) = @_;
    my $caller = caller();
	no strict 'refs';
    *{ $caller . "::Window" } = 
        sub { return scalar $package->new( tag=>'Window', @_ ) };
}

##############################################################
## DOM-like window.open( $name, $features );
sub open
{
    my( $self, $winID, $features ) = @_;

    # TODO: make sure $winID doesn't already exist

    # popup_window will allocate a winID if one doesn't exist already
    $winID = $POE::XUL::Node::CM->popup_window( $winID, $features );

    return unless $INC{'POE/XUL/Application.pm'};

    my $server = POE::XUL::Application::server();
    return unless $server;
    
    # Create a temporary window to hold the events until 'connect'
    my $twindow = POE::XUL::TWindow->new( %$features, id => $winID );
    $server->attach_subwindow( $twindow );
    return $twindow;
}

##############################################################
## DOM-like window.close()
sub close
{
    my( $self ) = @_;

    # carp "$self.close";    
    $POE::XUL::Node::CM->close_window( $self->id );
    # this will cause a close instruction, which closes then window
    # which will provoke 'disconnect' request, which is where the 
    # window is finnaly GCed
    $self->closed( 1 );
}

##############################################################
sub getElementById
{
    my( $self, $id ) = @_;
    return $id if blessed $id;      # act like prototype's $()
    croak "getElementById may only be invoked on a Window"
            unless $self->is_window;
    return $POE::XUL::Node::CM->getElementById( $id );
}
*node = \&getElementById;

##############################################################
sub dispose
{
    my( $self ) = @_;
    my $id = $self->id;
    $self->SUPER::dispose;
    return unless $POE::XUL::Node::CM;
    $POE::XUL::Node::CM->unregister_window( $self );
    $self->{attributes} = {};
    return;
}
*destroy = \&dispose;

1;

__END__

=head1 NAME

POE::XUL::Window - XUL window element

=head1 SYNOPSIS

    use POE::XUL::Node;

    # DWIM way
    $window = Window(                            # window with a header,
        HTML_H1(textNode => 'a heading'),         # a label, and a button
        $label = Label(FILL, value => 'a label'),
        Button(label => 'a button'),
    );

    # attributes
    $window->width( 800 );
    $window->height( 600 );


    # Main window is exported
    use POE::XUL::Application;

    my $node = window->getElementById( $id );

    window->open( $winID, $features );

    $window->close();

=head1 DESCRIPTION

POE::XUL::Window is a special sub-class of L<POE::XUL::Node> to handle
window elements.

=head1 METHODS

=head2 getElementById

=head2 node

Shorter name for L</getElementById>.

    my $button = window->node( 'B1' );

=head2 open

=head2 close

=head2 destroy

=head1 SEE ALSO

L<POE::XUL>, L<POE::XUL::Node>, L<POE::XUL::POE>,
L<POE::XUL::Event> presents the list of all possible events.

L<http://developer.mozilla.org/en/docs/XUL>
has a good XUL reference.


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on work by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
