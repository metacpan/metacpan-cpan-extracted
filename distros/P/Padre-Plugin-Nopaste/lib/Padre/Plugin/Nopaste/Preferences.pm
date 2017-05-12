package Padre::Plugin::Nopaste::Preferences;

use v5.10;
use strict;
use warnings;

use Padre::Unload                            ();
use Padre::Plugin::Nopaste::Services         ();
use Padre::Plugin::Nopaste::FBP::Preferences ();

our $VERSION = '0.08';
use parent qw(
	Padre::Plugin::Nopaste::FBP::Preferences
	Padre::Plugin
);

#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialogue
	my $self = $class->SUPER::new($main);

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle( sprintf Wx::gettext('Nopaste-Preferences v%s'), $VERSION );
	$self->_set_up;

	return $self;
}

#######
# Method _set_up
#######
sub _set_up {
	my $self      = shift;
	my $main      = $self->main;
	my $config    = $main->config;
	my $config_db = $self->config_read;

	my $services = Padre::Plugin::Nopaste::Services->new;
	$self->{nopaste_services} = $services;

	#Set nickname
	$self->{config_nickname}->SetLabel( $config->identity_nickname );

	#get nopaste preferred server and channel from config db
	$self->{prefered_server}  = $config_db->{Services};
	$self->{prefered_channel} = $config_db->{Channel};

	# update dialogue
	$self->_display_servers;
	$self->_display_channels;

	return;
}

#######
# Method _display_servers
#######
sub _display_servers {
	my $self = shift;

	my $servers = $self->{nopaste_services}->servers;

	# set local_server_index to zero in case predefined not found
	my $local_server_index = 0;

	for ( 0 .. $#{$servers} ) {
		if ( $servers->[$_] eq $self->{prefered_server} ) {
			$local_server_index = $_;
		}
	}

	$self->{nopaste_server}->Clear;
	$self->{nopaste_server}->Append($servers);
	$self->{nopaste_server}->SetSelection($local_server_index);

	return;
}

#######
# Method _display_channels
#######
sub _display_channels {
	my $self = shift;

	my $channels = $self->{nopaste_services}->{ $self->{prefered_server} };

	# set local_server_index to zero in case predefined not found
	my $local_channel_index = 0;

	for ( 0 .. $#{$channels} ) {
		if ( $channels->[$_] eq $self->{prefered_channel} ) {
			$local_channel_index = $_;
		}
	}

	$self->{nopaste_channel}->Clear;
	$self->{nopaste_channel}->Append($channels);
	$self->{nopaste_channel}->SetSelection($local_channel_index);

	return;
}

#######
# event handler on_button_ok_clicked
#######
sub on_button_save_clicked {
	my $self      = shift;
	my $config_db = $self->config_read;

	$config_db->{Services} = $self->{nopaste_services}->servers->[ $self->{nopaste_server}->GetSelection() ];
	$config_db->{Channel} =
		$self->{nopaste_services}->{ $self->{prefered_server} }->[ $self->{nopaste_channel}->GetSelection() ];

	$self->config_write($config_db);

	$self->Hide;
	return;
}

#######
# event handler on_button_ok_clicked
#######
sub on_button_reset_clicked {
	my $self      = shift;
	my $config_db = $self->config_read;

	$config_db->{Services} = 'Shadowcat';
	$config_db->{Channel}  = '#padre';
	$self->config_write($config_db);

	$self->{prefered_server}  = 'Shadowcat';
	$self->{prefered_channel} = '#padre';

	$self->refresh;
	return;
}

#######
# event handler on_server_chosen, save choices and close
#######
sub on_server_chosen {
	my $self = shift;

	$self->{prefered_server}  = $self->{nopaste_services}->servers->[ $self->{nopaste_server}->GetSelection() ];
	$self->{prefered_channel} = 0;

	$self->refresh;

	return;
}

#######
# refresh dialogue with choices
#######
sub refresh {
	my $self = shift;

	$self->_display_servers;
	$self->_display_channels;

	return;
}


1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Nopaste::Preferences - NoPaste plugin for Padre, The Perl IDE.

=head1 VERSION

version: 0.08

=head1 DESCRIPTION

This module handles the Preferences dialogue window that is used to set your
 chosen Nopaste Server and #Channel.


=head1 METHODS

=over 4

=item * new

	$self->{dialog} = Padre::Plugin::SpellCheck::Preferences->new( $self );

Create and return a new dialogue window.

=item * on_server_chosen

event handler, update selection

=item * on_button_save_clicked

event handler, save your choice

=item * on_button_reset_clicked

	Nopaste Server: Shadowcat
	IRC Channel: #padre

=item * refresh

refresh dialog

=back

=head2 INTERNAL METHODS

=over 4

=item * _display_channels

=item * _display_servers

=item * _setup

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre, Padre::Plugin::Nopaste::FBP::Preferences

=head1 SEE ALSO

See L<Padre::Plugin::Nopaste>.

=head1 AUTHOR

See L<Padre::Plugin::Nopaste>

=head2 CONTRIBUTORS

See L<Padre::Plugin::Nopaste>

=head1 COPYRIGHT

See L<Padre::Plugin::Nopaste>

=head1 LICENSE

See L<Padre::Plugin::Nopaste>

=cut

