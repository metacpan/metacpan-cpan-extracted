package Padre::Plugin::Cookbook::Recipe04::About;

use v5.10.1;
use strict;
use warnings;

# use diagnostics;
# use utf8;
# use autodie;

# Version required
our $VERSION = '0.24';
use parent qw( Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB );

use Data::Dumper ();
my $space = q{ };

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	# add package name to about dialog
	my @package = split /::/smx, __PACKAGE__,;
	$self->name_version->SetLabel( $package[3] . $space . $VERSION );

	# add your name below
	$self->developed_by->SetLabel('developed by bowtie');

	$self->CenterOnParent;
	return $self;
}

#######
# Event Handler for credits_clicked
#######
sub credits_clicked {
	my $self = shift;
	my $main = $self->main;

	$main->show_output(1);
	my $output = $main->output;
	$output->clear;

	my %credits = (
		'BOWTIE'  => '<kevin.dawson@btclick.com>',
		'Alias'   => $space,
		'El_Che'  => $space,
		'claudio' => $space,
		'azawawi' => $space,
		'Sewi'    => $space,
		'garu'    => $space,
		'abc'     => '<abc@abc.com>',
	);

	$output->AppendText("CREDITS\ncredits_clicked \n\tname:\t\t<e-mail>\n");
	while ( my ( $key, $value ) = each %credits ) {
		$output->AppendText("\t$key:\t\t$value\n");
	}
	return;
}

#######
# Event Handler for licence_clicked
#######
sub licence_clicked {
	my $self = shift;
	my $main = $self->main;

	$main->show_output(1);
	my $output = $main->output;
	$output->clear;

	my $licence = <<'END_LICENCE';
LICENSE & COPYRIGHT

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

	a) the GNU General Public License as published by the Free
		Software Foundation; either version 1, or (at your option) any later
		version, or
	b) the "Artistic License"

The full text of the license can be found in the LICENSE file included with
this module.

END_LICENCE

	$output->AppendText($licence);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Cookbook::Recipe04::About

=head1 VERSION

version: 0.24

=head1 DESCRIPTION

About is the event handler for AboutFB, it's parent class.

It displays an About dialog which will display 
credits and licence in Padre Output window.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 SUBROUTINES/METHODS

=over 4

=item new ()

Constructor. Should be called with $main by Main->load_dialog_about().

=item credits_clicked ()

Event handler for button credits, 
Displays credits in Padre Output window

=item licence_clicked ()

Event handler for button licence, 
Displays license in Padre Output window

=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB

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
