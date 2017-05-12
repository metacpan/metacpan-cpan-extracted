package PAR::Dist::InstallPPD::GUI::Config;
use strict;
use warnings;

our $VERSION = '0.05';

sub _init_config_tab {
	my $self = shift;
	my $tabs = $self->{tabs};
	my $fr = $tabs->{config}->Frame()->pack(qw/-side top -fill both/);

	$self->_make_entry($fr, '"parinstallppd" command:', $self->{parinstallppd});
	$self->_make_entry($fr, '--selectarch Regular Expression (leave blank for default):', $self->{saregex});
	$self->_make_entry($fr, '--selectperl Regular Expression (leave blank for default):', $self->{spregex});

}

sub _make_entry {
	my $self = shift;
	my $frame = shift;
	my $label = shift;
	my $ref = shift;
	my $width = shift||80;

	my $fr = $frame->Frame()->pack(qw/-side top -fill x -pady 3/);
	$fr->Label(qw/-text/, $label.' ')->pack(qw/-side left/);
	return $fr->Entry(-width => $width, -textvariable => $ref)->pack(qw/-side left -fill x/);
}



sub _save_config {
	my $self = shift;
	my $cfg = $self->{cfg};
	$cfg->{main}{verbose} = $self->{verbose} || 0;
	$cfg->{main}{ppduri} = $self->{ppduri} || 'http://';
	$cfg->{main}{shouldwrap} = $self->{shouldwrap} || 0;
	$cfg->{main}{parinstallppd} = $self->{parinstallppd} || 'parinstallppd';
	$cfg->{main}{spregex} = $self->{spregex} || '';
	$cfg->{main}{saregex} = $self->{saregex} || '';
	tied(%$cfg)->RewriteConfig();
}


1;

__END__

=head1 NAME

PAR::Dist::InstallPPD::GUI::Config - Implements the Config tab

=head1 SYNOPSIS

  use PAR::Dist::InstallPPD::GUI;
  my $gui = PAR::Dist::InstallPPD::GUI->new();
  $gui->run();

=head1 DESCRIPTION

This module is B<for internal use only>.

=head1 SEE ALSO

L<PAR::Dist::InstallPPD::GUI>

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

