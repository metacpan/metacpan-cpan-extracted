package PAR::Dist::InstallPPD::GUI;
use strict;
use warnings;

our $VERSION = '0.05';

use File::Spec;
use Config::IniFiles;
use Tk;
use Tk::NoteBook;
use Tk::ROText;
use IPC::Run ();

use File::UserConfig ();
use PAR::Dist::FromPPD ();

use base 'PAR::Dist::InstallPPD::GUI::Install';
use base 'PAR::Dist::InstallPPD::GUI::Installed';
use base 'PAR::Dist::InstallPPD::GUI::Config';

sub new {
	my $proto = shift;
	my $class = ref($proto)||$proto;

	my $cfgdir = File::UserConfig->new(
		dist     => 'PAR-Dist-InstallPPD-GUI',
		module   => 'PAR::Dist::InstallPPD::GUI',
		dirname  => '.PAR-Dist-InstallPPD-GUI',
#		sharedir => 'PARInstallPPDGUI',
	)->configdir();
    my $cfgfile = File::Spec->catfile($cfgdir, 'config.ini');
    chmod(oct('644'), $cfgfile);

    if (not -f $cfgfile) {
        require File::Path;
        File::Path::mkpath($cfgdir);
        open my $fh, '>', $cfgfile
          or die "Could not open configuration file: $!";
        print $fh <DATA>;
        close $fh;
    }
	tie my %cfg => 'Config::IniFiles', -file => $cfgfile;

	my $self = bless {
		ppduri => $cfg{main}{ppduri},
		verbose => $cfg{main}{verbose},
		shouldwrap => $cfg{main}{shouldwrap},
		parinstallppd => $cfg{main}{parinstallppd},
		saregex => $cfg{main}{saregex},
		spregex => $cfg{main}{spregex},
	} => $class;
	$self->{cfg} = \%cfg;
	
	my $mw = MainWindow->new();
    $self->{mw} = $mw;
	$mw->geometry( "800x600" );
	eval { # eval, in case fonts already exist
		$mw->fontCreate(qw/C_normal  -family courier   -size 10/);
		$mw->fontCreate(qw/C_bold    -family courier   -size 10 -weight bold/);
	};

	my $nb = $mw->NoteBook()->pack(qw/-side top -fill both -expand 1/);

    # status bar
    my $statusframe = $mw->Frame(
        qw/-relief sunken/
    )->pack(qw/-fill x -side bottom/);
    my $statuslabel = $statusframe->Label(
        qw/-text/, 'Welcome to PAR::Dist::InstallPPD::GUI'
    )->pack(qw/-side left -fill x -ipadx 4 -ipady 1/);
    $self->{statusbar} = $statuslabel;

    $self->{tabs} = {};
	$self->{tabs}{welcome}   = $nb->add( "welcome",  -label => "Welcome" );
	$self->{tabs}{install}   = $nb->add( "install",  -label => "Install" );
	$self->{tabs}{installed} = $nb->add(
        "installed", -label => "Installed",
        -raisecmd => [$self, '_raise_installed'],
    );
	$self->{tabs}{config}   = $nb->add( "config", -label => "Configuration" );

	$self->{tabs}{welcome}->Label(
        -text=>"Welcome to PAR-Install-PPD-GUI!"
    )->pack( );

	$self->_init_install_tab();
	$self->_init_config_tab();
	$self->_init_installed_tab();

	return $self;
}	

sub run {
	MainLoop;
}

sub _status {
    my $self = shift;
    my $text = shift;
    $self->{statusbar}->configure('-text' => $text);
    $self->{mw}->update();
    return 1;
}

sub DESTROY {
	my $self = shift;
	$self->_save_config();
}


1;

=head1 NAME

PAR::Dist::InstallPPD::GUI - GUI frontend for PAR::Dist::InstallPPD

=head1 SYNOPSIS

  use PAR::Dist::InstallPPD::GUI;
  my $gui = PAR::Dist::InstallPPD::GUI->new();
  $gui->run();

=head1 DESCRIPTION

This module implements a Tk GUI front-end to the L<PAR::Dist::InstallPPD>
module's C<parinstallppd> command. You will generally want to use the
C<parinstallppdgui> command instead of using this module.

The interface to C<parinstallppd> isn't done in code via an API.
Instead C<parinstallppdgui> uses L<IPC::Run> to run C<parinstallppd>.

=head1 SEE ALSO

L<PAR::Dist::InstallPPD>, L<IPC::Run>, L<File::UserConfig>, L<Tk>

PAR has a mailing list, <par@perl.org>, that you can write to; send an empty mail to <par-subscribe@perl.org> to join the list and participate in the discussion.

Please send bug reports to <bug-par-dist-installppd-gui@rt.cpan.org>.

The official PAR website may be of help, too: http://par.perl.org

For details on the I<Perl Package Manager>, please refer to ActiveState's
website at L<http://activestate.com>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
# default config
[main]
parinstallppd=parinstallppd
ppduri=http://
verbose=0
shouldwrap=0
saregex=
spregex=

