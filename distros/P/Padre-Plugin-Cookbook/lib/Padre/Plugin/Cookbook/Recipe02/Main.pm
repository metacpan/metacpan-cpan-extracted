package Padre::Plugin::Cookbook::Recipe02::Main;

use v5.10.1;
use strict;
use warnings;
no if $] > 5.017010, warnings => 'experimental';

# Version required
our $VERSION = '0.24';
use parent qw( Padre::Plugin::Cookbook::Recipe02::FBP::MainFB );

#######
# Method new
#######
sub new {
	my $class = shift;

	# Padre main window integration
	my $main = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	# define where to display main dialog
	$self->CenterOnParent;
	return $self;
}

my @items = qw/ zero one two three four five six /;
state $update_run_yes;

#######
# Event Handler Button Output Clicked
#######
sub output_clicked {
	my $self = shift;
	my $main = $self->main;

	$main->show_output(1);
	my $output = $main->output;
	$output->clear;

	$output->AppendText("output cliked \n");
	$output->AppendText( 'Name: ' . $self->name_value->GetValue() . "\n" );
	if ($update_run_yes) {
		$output->AppendText( 'Choice GetSelection: ' . $items[ $self->choices->GetSelection() ] . "\n" );
	}
	$output->AppendText( 'Choice GetCurrentSelection: ' . $self->choices->GetCurrentSelection() . "\n" );
	$output->AppendText( 'User Name GetStringSelection: ' . $self->user_name->GetStringSelection() . "\n" );

	return;
}

#######
# Event Handler Button Update Clicked
#######
sub update_clicked {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;

	$self->choices->Clear();
	$update_run_yes = 1;
	$self->choices->Append( \@items );
	$self->choices->SetSelection(3);
	$self->heading->SetLabel('I am in Control');

	set_name_label_value($self);

	return;
}

#######
# Event Handler CheckMark TTennis Clicked
#######
sub ttennis_checked {
	my $self = shift;
	my $main = $self->main;

	$main->show_output(1);
	my $output = $main->output;

	$output->AppendText("ttennis cliked \n");
	if ( $self->ttennis->GetValue ) {
		$output->AppendText("TRUE\n");
		$self->ping->Enable;
		$self->pong->Enable;
	} else {
		$output->AppendText("FALSE\n");
		$self->ping->SetValue(0);
		$self->pong->SetValue(0);
		$self->ping->Disable;
		$self->pong->Disable;
	}
	return;
}

#######
# Event Handler CheckMark Ping Clicked
#######
sub ping_checked {
	my $self = shift;
	my $main = $self->main;

	# $main->show_output(1);
	my $output = $main->output;
	$output->AppendText("ping checked \n");
	if ( $self->ping->GetValue ) {
		$output->AppendText("TRUE\n");
		$self->pong->SetValue(0);
	} else {
		$output->AppendText("FALSE\n");
	}
	return;
}

#######
# Event Handler CheckMark Pong Clicked
#######
sub pong_checked {
	my $self = shift;
	my $main = $self->main;

	# $main->show_output(1);
	my $output = $main->output;
	$output->AppendText("pong checked \n");
	if ( $self->pong->GetValue ) {
		$output->AppendText("TRUE\n");
		$self->ping->SetValue(0);
	} else {
		$output->AppendText("FALSE\n");
	}
	return;
}

#######
# Composed Method set_name_label_value
#######
sub set_name_label_value {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;
	my $output = $main->output;

	given ( $self->user_name->GetStringSelection() ) {
		when ('nick') {
			$self->name_label->SetLabel( 'user ' . $_ . ' name' );
			$self->name_value->SetValue( $config->identity_nickname );
		}
		when ('cpan') {
			$self->name_label->SetLabel( 'user ' . $_ . ' name' );
			$self->name_value->SetValue( $config->identity_name );
		}
		when ('e-mail') {
			$self->name_label->SetLabel( 'user ' . $_ . ' name' );
			$self->name_value->SetValue( $config->identity_email );
		}
		default {
			$output->AppendText("huston! we have a problem\n I think you have added another radio button option\n")
		}
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Cookbook::Recipe02::Main

=head1 DESCRIPTION

Recipe02 - Fun with widgets

Main is the event handler for MainFB, it's parent class.
It displays a Main dialog with 'Hello World'.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 VERSION

version: 0.24

=head1 SUBROUTINES/METHODS

=over 4

=item new ()

Constructor. Should be called with $main by CookBook02->load_dialog_main().

=item ttennis_checked ()

Event handler for checkbox ttennis

=item ping_checked ()

Event handler for checkbox ping

=item pong_checked ()

Event handler for checkbox pong

=item set_name_label_value ()

Composed method called by update_clicked

=item output_clicked ()

Event handler for button output

=item update_clicked ()

Event handler for button update

=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe02::FBP::MainFB

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
