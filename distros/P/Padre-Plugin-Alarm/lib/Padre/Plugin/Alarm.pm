package Padre::Plugin::Alarm;
BEGIN {
  $Padre::Plugin::Alarm::VERSION = '0.14';
}

# ABSTRACT: Alarm Clock in Padre

use warnings;
use strict;

use base 'Padre::Plugin';

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Padre::Util       ();

our $alarm_timer_id;

sub padre_interfaces {
	'Padre::Plugin' => '0.47',;
}

sub menu_plugins_simple {
	my $self = shift;

	# check if we need set timer on
	my $config = $self->config_read;
	if ( $config and exists $config->{alarms} and scalar @{ $config->{alarms} } ) {
		_set_alarm();
	}

	return (
		Wx::gettext('Alarm Clock') => [
			Wx::gettext('Set Alarm Time'), sub { $self->set_alarm_time },
			Wx::gettext('Stop Alarm'),     sub { $self->stop_alarm },
			Wx::gettext('Clear Alarm'),    sub { $self->clear_alarm },
		]
	);
}

sub set_alarm_time {
	my ($self) = shift;
	my $main = $self->main;

	my @frequency = ( 'once', 'daily' );
	my @layout = (
		[   [ 'Wx::StaticText', undef,          Wx::gettext('Time (eg: 23:55):') ],
			[ 'Wx::TextCtrl',   '_alarm_time_', '' ],
		],
		[   [ 'Wx::StaticText', undef, Wx::gettext('Frequency:') ],
			[ 'Wx::ComboBox', '_frequency_', 'once', \@frequency ],
		],
		[   [ 'Wx::Button', '_ok_',     Wx::wxID_OK ],
			[ 'Wx::Button', '_cancel_', Wx::wxID_CANCEL ],
		],
	);
	my $dialog = Padre::Wx::Dialog->new(
		parent => $main,
		title  => Wx::gettext("Set Alarm Time"),
		layout => \@layout,
		width  => [ 100, 200 ],
		bottom => 20,
	);
	$dialog->{_widgets_}{_ok_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_},     \&ok_clicked );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, \&cancel_clicked );

	$dialog->{_widgets_}{_alarm_time_}->SetFocus;
	$dialog->Show(1);

	return 1;
}

sub cancel_clicked {
	my ( $dialog, $event ) = @_;

	$dialog->Destroy;

	return;
}

sub ok_clicked {
	my ( $dialog, $event ) = @_;

	my $data = $dialog->get_data;
	$dialog->Destroy;

	my $main = Padre->ide->wx->main;

	my $alarm_time = $data->{_alarm_time_};
	if ( $alarm_time !~ /^\d{1,2}\:\d{2}$/ ) {
		Wx::MessageBox(
			Wx::gettext('Possible Value Format: \d:\d\d or \d\d:\d\d like 6:13 or 23:55'),
			Wx::gettext("Wrong Alarm Time"),
			Wx::wxOK, $main
		);
		return;
	}

	my $frequency = $data->{_frequency_};

	# stupid hack to get $self for config_read
	my $self = bless {}, __PACKAGE__;
	my $config = $self->config_read;
	push @{ $config->{alarms} },
		{
		time      => $alarm_time,
		frequency => $frequency,
		status    => 'enabled',
		};
	$self->config_write($config);

	_set_alarm();
}

sub _set_alarm {
	my $main = Padre->ide->wx->main;

	$alarm_timer_id = Wx::NewId unless $alarm_timer_id;

	my $timer = Wx::Timer->new( $main, $alarm_timer_id );
	unless ( $timer->IsRunning ) {
		Wx::Event::EVT_TIMER( $main, $alarm_timer_id, \&on_timer_alarm );
		$timer->Start( 1000, 0 ); # every second
	}
}

sub stop_alarm {
	my ( $self, $opts ) = @_;
	my $main = $self->main;

	if ( not $opts->{no_message} ) {
		$main->message( Wx::gettext('All Alarms are stopped'), Wx::gettext('Stop Alarm') );
	}

	return unless $alarm_timer_id;
	my $timer = Wx::Timer->new( $main, $alarm_timer_id );
	if ( $timer->IsRunning ) {
		$timer->Stop();
	}
}

sub clear_alarm {
	my ($self) = shift;
	my $main = $self->main;

	my $config = $self->config_read;
	$config->{alarms} = [];
	$self->config_write($config);

	$self->stop_alarm( { no_message => 1 } );
	$main->message( Wx::gettext('All Alarms are cleared'), Wx::gettext('Clear Alarm') );
}

sub on_timer_alarm {

	# stupid hack to get $self for config_read
	my $self = bless {}, __PACKAGE__;

	my $config = $self->config_read;

	return unless ( $config and exists $config->{alarms} );

	# get now-time;
	my @ntime = localtime();
	my $ntime = sprintf( '%d:%02d', $ntime[2], $ntime[1] );

	my $did_something = 0;
	foreach ( @{ $config->{alarms} } ) {
		return unless ( $_->{status} eq 'enabled' );

		# check if it's the time
		my $time = $_->{time};
		$time =~ s/^0//;

		if ( $time eq $ntime ) {
			$did_something = 1;
			play_alarm();
			my $frequency = $_->{frequency};
			if ( $frequency eq 'once' ) {
				$_->{status} = 'disabled';
			}
		}
	}

	if ($did_something) {
		$config->{alarms} = [ grep { $_->{status} eq 'enabled' } @{ $config->{alarms} } ];
		$self->config_write($config);
	}
}

sub play_alarm {
	my $audio_dir = File::Spec->catdir( Padre::Util::share('Alarm'), 'audio' );
	my $file = File::Spec->catfile( $audio_dir, 'alarm.wav' );
	$file = '' unless -f $file;
	my $sound = Wx::Sound->new($file);
	$sound->Play(Wx::wxSOUND_ASYNC);
}

1;


=pod

=head1 NAME

Padre::Plugin::Alarm - Alarm Clock in Padre

=head1 VERSION

version 0.14

=head1 SYNOPSIS

	$>padre
	Plugins -> Alarm Clock -> *

=head1 DESCRIPTION

A simple Alarm Clock plugin

=head1 THANKS

The alarm sound sample was taken from L<http://www.freesound.org/>.
It was made by ryansnook - L<http://www.freesound.org/usersViewSingle.php?id=430094> and
is being licensed under L<http://creativecommons.org/licenses/sampling+/1.0/>.

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

