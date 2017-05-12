package Padre::Plugin::InstallPARDist;
use strict;
use warnings;
use base 'Padre::Plugin';

#use Wx         qw(:everything);
#use Wx::Event  qw(:everything);
use Padre::Wx;

sub require_modules {
    require LWP::Simple;
    require ExtUtils::InstallPAR;
    require ExtUtils::InferConfig;
    require Padre::Wx::Dialog;
}

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::InstallPARDist - Installation of .par archives into the system

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.17.

=cut

sub menu_plugins_simple {
    my $self = shift;
    return 'Install PAR dist.' => [
      'Install PAR distribution' => \&on_install_par_dist,
    ];
}


sub dialog {
  my ( $win ) = @_;

  my @layout = (
    [
      [ 'Wx::StaticText', undef,          'Path or URL to install from:'],
      [ 'Wx::TextCtrl',   '_par_uri_',    'your.par'],
    ],
    [
      [ 'Wx::StaticText',      undef,    'Target perl:'],
#      [ 'Wx::FilePickerCtrl',   '_target_perl_', $^X,  'Pick target perl'],
      [ 'Wx::TextCtrl',   '_target_perl_', $^X],
    ],
    [
      [ 'Wx::Button',     '_ok_',           Wx::wxID_OK     ],
      [ 'Wx::Button',     '_cancel_',       Wx::wxID_CANCEL ],
    ],
  );

  my $dialog = Padre::Wx::Dialog->new(
    parent          => $win,
    title           => "Install PAR distribution",
    layout          => \@layout,
    width           => [200, 300],
  );

  $dialog->{_widgets_}{_ok_}->SetDefault;
  Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_},      \&ok_clicked      );
  Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_},  \&cancel_clicked  );

  $dialog->{_widgets_}{_par_uri_}->SetFocus;
  $dialog->Show(1);

  return;
}

sub cancel_clicked {
  my ($dialog, $event) = @_;

  $dialog->Destroy;

  return;
}

sub ok_clicked {
  my ($dialog, $event) = @_;

  my $main_window = Padre->ide->wx->main_window;

  my $data = $dialog->get_data;
  $dialog->Destroy;

  my $perl = $data->{_target_perl_};
  $perl = undef
    if not defined $perl or $perl eq '' or $perl eq $^X;
  
  my $par = $data->{_par_uri_};
  if ( not defined $par or ( not -f $par and not $par =~ /^\w+:/ ) ) {
    Wx::MessageBox( "No PAR URL or path supplied.", "Failed", Wx::wxOK|Wx::wxCENTRE, $main_window );
    return;
  }

  my $success = ExtUtils::InstallPAR::install(
    par => $par,
    perl => $perl,
  );

  if ($success) {
    Wx::MessageBox( "Installed '$par' into '$perl'", "Done", Wx::wxOK|Wx::wxCENTRE, $main_window );
  } else {
    Wx::MessageBox( "Error installing '$par' into '$perl'", "Failed", Wx::wxOK|Wx::wxCENTRE, $main_window );
  }
}




sub on_install_par_dist {
  my ($window, $event) = @_;
  require_modules();

  dialog($window);

}


1;

__END__

=head1 INSTALLATION

You can install this module like any other Perl module and it will
become available in your Padre editor. However, you can also
choose to install it into your user's Padre configuration directory only.
The necessary steps are outlined in the C<README> file in this distribution.
Essentially, you do C<perl Build.PL> and C<./Build installplugin>.

=head1 COPYRIGHT AND LICENSE

(c) 2008 Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut
