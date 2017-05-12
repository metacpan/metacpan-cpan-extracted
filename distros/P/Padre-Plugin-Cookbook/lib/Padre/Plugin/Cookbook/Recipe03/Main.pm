package Padre::Plugin::Cookbook::Recipe03::Main;

use v5.10.1;
use strict;
use warnings;

# Version required
our $VERSION = '0.24';
use parent qw( Padre::Plugin::Cookbook::Recipe03::FBP::MainFB );


sub new {
	my $class = shift;
	my $main  = shift;

	# Create the about
	my $self = $class->SUPER::new($main);

	# add package name to main dialog #fails as min size naff
	my @package = split /::/x, __PACKAGE__,;
	$self->package_name->SetLabel( $package[3] );

	$self->CenterOnParent;

	return $self;
}


#######
# Event Handler Button About Clicked
#######
sub about_clicked {
	my $self = shift;
	my $main = $self->main;

	load_dialog_about($self);

	return;
}


#######
# Clean up our Classes, Padre::Plugin, POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Cookbook::Recipe03::About
			Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB
			}
	);

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method,
# Load About Dialog, only once
#######
sub load_dialog_about {
	my $self = shift;
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new about
	require Padre::Plugin::Cookbook::Recipe03::About;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe03::About->new($main);
	$self->{dialog}->ShowModal;

	return;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}
1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Cookbook::Recipe03::Main

=head1 VERSION

version: 0.24

=head1 DESCRIPTION

Recipe03 - Fun with wx widgets

Main is the event handler for MainFB, it's parent class.

It displays a Main dialog with an about button.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 SUBROUTINES/METHODS

=over 4

=item new ()

Constructor. Should be called with $main by CookBook03->load_dialog_main().

=item about_clicked ()

Event handler for button about

=item plugin_disable ()

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Recipe03::About');
    $self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');


=item load_dialog_about ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe03::About;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe03::About->new( $main );
    $self->{dialog}->Show;

=item clean_dialog

=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe03::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe03::About, Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2013 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
