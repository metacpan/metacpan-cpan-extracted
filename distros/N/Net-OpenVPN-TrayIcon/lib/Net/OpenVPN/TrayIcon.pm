package Net::OpenVPN::TrayIcon;

use 5.010;
use warnings;
use Moo;
use Gtk2 '-init';
use Gtk2::TrayIcon;
use MIME::Base64;
use Time::HiRes 'usleep';
use Data::Section -setup;
use POSIX ':sys_wait_h';

has icons    => ( is => 'rw' );
has config   => ( is => 'rw' );
has dispatch => ( is => 'rw' );
has gtk_icon => ( is => 'rw' );
has gtk_menu => ( is => 'rw' );
has gtk_tray_icon => ( is => 'rw' );
has gtk_tooltip => ( is => 'rw' );

our $this;

sub _sig_usr1_handler {
    my ($sig) = @_;
    $this->dispatch->{set_icon}->('active') if $sig ~~ 'USR1';
    return 1;
}

sub _sig_usr2_handler {
    my ($sig) = @_;
    $this->dispatch->{set_icon}->('inactive') if $sig ~~ 'USR2';
    return 1;
}

sub BUILD {
    my ($self) = @_;

    if ($self->_first_run){
        my %icons;
        $icons{default} = ${$self->section_data('icon_default')};
        $icons{active} = ${$self->section_data('icon_active')};
        $icons{inactive} = ${$self->section_data('icon_inactive')};

        my $default_config = ${$self->section_data('default_config')};

        mkdir $ENV{HOME} . '/.ovpntray' or die "Could not create config directory: $!";

        open my $fh, '>', $ENV{HOME} . '/.ovpntray/config';
        print $fh $default_config;
        close $fh;

        for (keys %icons){
            open my $bfh, '>', $ENV{HOME} . '/.ovpntray/icon_' . $_ . '.png';
            binmode $bfh;
            print $bfh decode_base64($icons{$_});
            close $bfh;
        }
    }

    $self->_build_config;
    $self->_build_dispatch_table;
    $self->_build_icons;
    $self->_build_tray;
    $self->_build_this;

    $SIG{USR1} = \&_sig_usr1_handler;
    $SIG{USR2} = \&_sig_usr2_handler;

    return 1;
}

sub _build_this {
    my ($self) = @_;
    $this = $self;

    return 1;
}

sub run {
    my ($self) = @_;

    Gtk2->main;
}

sub click {
    my ($self, $gtk_evnt_box, $gtk_evnt_button) = @_;

    given ($gtk_evnt_button->button){
        when (1){   # left click
            $self->menu;
        }
        when (2){   # middle click
            $self->menu;
        }
        when (3){   # right click
            $self->menu;
        }
        default {
        }
    }

    return 1;
}

sub config_view {
    my ($self) = @_;

    # main config window
    my $gtk_window = Gtk2::Window->new('toplevel');
    $gtk_window->set_title('Config');
    $gtk_window->set_position('center');

    # vbox container (rows, columns, homogeneous)
    my $gtk_table = Gtk2::Table->new( 3, 1, 0 );

    # notebook
    my $gtk_notebook = Gtk2::Notebook->new;
    $gtk_notebook->set_tab_pos('top');

    # first page
    my $gtk_vbox_page_1 = Gtk2::VBox->new( 0, 1 );
}

sub menu {
    my ($self) = @_;

    my $gtk_menu = Gtk2::Menu->new();
    my $gtk_menu_start = Gtk2::ImageMenuItem->new_with_label('start VPN');
    $gtk_menu_start->signal_connect(
        activate => sub {
            system 'sudo ' . $self->config->{start_cmnd};
            $self->dispatch->{set_icon}->('default');
            $self->dispatch->{set_tip}->('OpenVPN checking connection..');
            $self->dispatch->{active_if_running}->();
        },
    );

    my $gtk_menu_stop = Gtk2::ImageMenuItem->new_with_label('stop VPN');
    $gtk_menu_stop->signal_connect(
        activate => sub {
            system 'sudo ' . $self->config->{stop_cmnd};
            $self->dispatch->{set_icon}->('default');
            $self->dispatch->{set_tip}->('OpenVPN checking connection..');
            $self->dispatch->{inactive_if_not_running}->();
        },
    );

    $gtk_menu->add($gtk_menu_start);
    $gtk_menu->add($gtk_menu_stop);
    $gtk_menu->show_all;

    $gtk_menu->popup( undef, undef, undef, undef, 0, 0 );
    $self->gtk_menu($gtk_menu);

    return 1;
}

sub _build_dispatch_table {
    my ($self) = @_;

    my %table = (
        set_icon => sub {
            my ($type) = @_;
            $self->gtk_icon->set_from_pixbuf($self->icons->{$type});
            return 1;
        },
        set_tip => sub {
            my ($tip) = @_;
            $self->gtk_tooltip->set_tip( $self->gtk_tray_icon, $tip);
            return 1;
        },
        active_if_running => sub {
            my $parent_pid = $$;
            my $child_pid = fork;

            if ($child_pid == 0){ # the child
                if ($self->_vpn_is_running(200)){
                    if ($self->_check_if_connected(10000)){
                        kill USR1 => $parent_pid;
                    }
                }
                else {
                    kill USR2 => $parent_pid;
                }

                POSIX::_exit(0);
            }
            else {
                # keep going
            }
        },
        inactive_if_not_running => sub {
            my $parent_pid = $$;
            my $child_pid = fork;

            if ($child_pid == 0){ # the child
                if ($self->_vpn_is_not_running(200)){
                    kill USR2 => $parent_pid;
                }
                else {
                    kill USR1 => $parent_pid;
                }

                POSIX::_exit(0);
            }
            else {
                # keep going
            }
        },

    );

    $self->dispatch({ %table });

    return 1;
}

sub _build_tray {
    my ($self) = @_;

    my $gtk_tooltip = Gtk2::Tooltips->new;
    my $gtk_trayicon = Gtk2::TrayIcon->new('VPN Tray');
    my $gtk_icon;
    if ($self->_vpn_is_running(10)){
        $gtk_icon = Gtk2::Image->new_from_pixbuf($self->icons->{'active'});
        $gtk_tooltip->set_tip( $gtk_trayicon, 'OpenVPN started');
    }
    else {
        $gtk_icon = Gtk2::Image->new_from_pixbuf($self->icons->{'inactive'});
        $gtk_tooltip->set_tip( $gtk_trayicon, 'OpenVPN stopped');
    }
    my $gtk_eventbox = Gtk2::EventBox->new;
    $gtk_eventbox->add($gtk_icon);


    $gtk_trayicon->add($gtk_eventbox);

    $self->gtk_icon($gtk_icon);
    $self->gtk_tooltip($gtk_tooltip);
    $self->gtk_tray_icon($gtk_trayicon);

    my $click_callback = sub {
        $self->click(@_);
    };

    $gtk_eventbox->signal_connect( 'button_press_event', $click_callback );

    $gtk_trayicon->show_all;

    return 1;
}

sub _vpn_is_running {
    my ($self, $timeout) = @_;
    return $self->_check_if_running(1, $timeout);
}

sub _vpn_is_not_running {
    my ($self, $timeout) = @_;
    return $self->_check_if_running(0, $timeout);
}

sub _check_if_running {
    my ($self, $condition, $timeout) = @_;

    while ($timeout){
        my $ovpn_pid = qx[pgrep openvpn];
        if ($condition){
            if ($ovpn_pid){
                return 1;
            }
        }
        else {
            if (!$ovpn_pid){
                return 1;
            }
        }
        Time::HiRes::usleep 100;
        $timeout--;
    }

    return 0;
}

sub _check_if_connected { # check if tunnel_interface appears in routes
    my ($self, $timeout) = @_;

    my $tunnel = $self->config->{tunnel_interface};
    while ($timeout){
        my ($routes) = qx[/sbin/ip r]; # first line -> default route

        return 1 if $routes ~~ /default\svia\s\d{0,3}\.\d{0,3}\.\d{0,3}\.\d{0,3}\sdev\s$tunnel/;

        Time::HiRes::usleep 100;
        $timeout--;
    }

    return 0;
}

sub _first_run {
    my ($self) = @_;
    return -f $ENV{HOME} . '/.ovpntray/config' ? 0 : 1;
}

sub _build_config {
    my ($self) = @_;

    my %config;
    open my $fh, '<', $ENV{HOME} . '/.ovpntray/config';
    while (<$fh>){
        my ($key, $value) = split ':', $_;
        chomp $key;
        chomp $value;
        $config{$key} = $value;
    }
    close $fh;

    $self->config({%config});

    return 1;
}

sub _build_icons {
    my ($self) = @_;

    my %icons;
    $icons{'default'} = Gtk2::Gdk::Pixbuf->new_from_file_at_scale(
        $ENV{HOME} . '/.ovpntray/' . $self->config->{icon_file},
        $self->config->{icon_size}, # width
        $self->config->{icon_size}, # height
        1,  # keep aspect
    );
    $icons{'active'} = Gtk2::Gdk::Pixbuf->new_from_file_at_scale(
        $ENV{HOME} . '/.ovpntray/' . $self->config->{icon_file_active},
        $self->config->{icon_size}, # width
        $self->config->{icon_size}, # height
        1,  # keep aspect
    );
    $icons{'inactive'} = Gtk2::Gdk::Pixbuf->new_from_file_at_scale(
        $ENV{HOME} . '/.ovpntray/' . $self->config->{icon_file_inactive},
        $self->config->{icon_size}, # width
        $self->config->{icon_size}, # height
        1,  # keep aspect
    );

    $self->icons({%icons});

    return 1;
}

1;

__DATA__
__[default_config]__
start_cmnd:/etc/init.d/openvpn start
stop_cmnd:/etc/init.d/openvpn stop
tunnel_interface:tun0
icon_file:icon_default.png
icon_file_active:icon_active.png
icon_file_inactive:icon_inactive.png
icon_size:20
__[icon_default]__
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
__[icon_active]__
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
AAABJRU5ErkJggg==
__[icon_inactive]__
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
FTkSuQmCC
__END__
=head1 NAME

Net::OpenVPN::TrayIcon - A simple GTK2 tray icon to start and stop OpenVPN

=head1 WARNING

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.02.02

=head1 SYNOPSIS

Net::OpenVPN::TrayIcon is a simple GTK2 tray icon that can be configured via
config file.

Run ovpntray.pl to get a tray icon. When first run it will create the config
directory in $HOME/.ovpntray including the default icons and a default
config file.

You will most likely have to edit it and set the start and stop commands.
Make sure you have the permission to run those commands.

=head1 ATTRIBUTES/CONSTRUCTION

Net::OpenVPN::TrayIcon currently has no configurable attributes.

=head2 Contruction

    my $trayicon = Net::OpenVPN::TrayIcon->new;

This builds everything needed to run. The config, the dispatch table, the
tray icon object with menu, icon and tooltip.

=head1 METHODS

=head2 run

    $trayicon->run;

This is just a Gtk2->main; that starts the Gtk main loop.

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Net::OpenVPN::TrayIcon issue tracker

L<https://github.com/mugenken/p5-Net-OpenVPN-TrayIcon/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

