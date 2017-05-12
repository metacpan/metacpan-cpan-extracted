package PAR::Dist::InstallPPD::GUI::Install;
use strict;
use warnings;

our $VERSION = '0.05';

sub _init_install_tab {
	my $self = shift;
	my $tabs = $self->{tabs};
	my $fr = $tabs->{install}->Frame()->pack(qw/-side top -fill both -expand 1/);

    $self->{install} = {
        urientry => undef,
        resulttext => undef,
    };

	my $urifr = $fr->Frame()->pack(qw/-side top -fill x/);
	$urifr->Label(qw/-text/, "PPD URI: ")->pack(qw/-side left -ipady 10/);
	$self->{install}{urientry} = $urifr->Entry(
		qw/-width 70 -background white -textvariable/, \$self->{ppduri}
	)->pack(qw/-side left -ipadx 10/);

    # view button
	$urifr->Button(
		qw/-text View -command/, [$self, '_view_ppd'],
	)->pack(qw/-side left -padx 5/);

    # install button
	$urifr->Button(
		qw/-text Install -command/, [$self, '_start_installation'],
	)->pack(qw/-side left -padx 5/);

	my $resultfr = $fr->Frame()->pack(qw/-side top -fill both -expand 1/);

	my $tframe = $resultfr->Frame()->pack(qw/-side top -fill x/);
	$tframe->Label(qw/-text/, "Results:")->pack(qw/-side left/);
	$tframe->Checkbutton(
		qw/-text/, "Wrap Lines",
		qw/-variable/, \$self->{shouldwrap},
		qw/-command/, [$self, '_wrap_toggle'],
	)->pack(qw/-side left -padx 3/);
	$tframe->Checkbutton(
		qw/-text/, "Verbose Output",
		qw/-variable/, \$self->{verbose},
	)->pack(qw/-side left -padx 3/);

	$self->{install}{resulttext} = $resultfr->Scrolled(
		qw/ROText -scrollbars osoe -background white/
	)->pack(qw/-side top -fill both -padx 5 -pady 5 -expand 1/);
	$self->{install}{resulttext}->tag(qw/configure output -foreground black -font C_normal/);
	$self->{install}{resulttext}->tag(qw/configure error -foreground red -font C_bold/);

    $self->_wrap_toggle();
}

sub _view_ppd {
    my $self = shift;

    $self->_status('Fetching PPD');
    my $ppduri = $self->{ppduri};

    my $ppd;
    eval {
        $ppd = PAR::Dist::FromPPD::get_ppd_content($ppduri);
    };

    $self->_reset_resulttext();
    if ($@) {
        $self->_warn_resulttext("Error: $@");
    }
    elsif (not defined $ppd) {
        $self->_warn_resulttext("Error: Could not get PPD");
    }
    else {
        $self->_print_resulttext($ppd);
    }

    $self->_status('');
}

sub _reset_resulttext {
    my $self = shift;
    $self->{install}{resulttext}->Contents('');
	$self->{install}{resulttext}->insert('0.0', '');
    $self->{install}{resulttext}->SetCursor('end');
}

sub _print_resulttext {
    my $self = shift;
    my $text = shift;
    $self->{install}{resulttext}->insert('insert', $text, 'output');
    $self->{install}{resulttext}->SetCursor('end');
}

sub _warn_resulttext {
    my $self = shift;
    my $text = shift;
    $self->{install}{resulttext}->insert('insert', $text, 'error');
    $self->{install}{resulttext}->SetCursor('end');
}

sub _start_installation {
	my $self = shift;
    $self->_status('Installing...');
	my $uri = $self->{ppduri};
	my @call = ($self->{parinstallppd}, '--uri', $self->{ppduri});
	push @call, '--verbose' if $self->{verbose};

	if (defined $self->{saregex} and $self->{saregex} =~ /\S/) {
		push @call, '--selectarch', $self->{saregex};
	}
	if (defined $self->{spregex} and $self->{spregex} =~ /\S/) {
		push @call, '--selectperl', $self->{spregex};
	}

	$self->_reset_resulttext();
	my $update_out = sub{
        $self->_print_resulttext(join "", @_);
	};
	my $update_err = sub{
        $self->_warn_resulttext(join "", @_);
	};
	IPC::Run::run(\@call, \undef, $update_out, $update_err);
    $self->_status('');
}

sub _wrap_on {
	my $self = shift;
	$self->{install}{resulttext}->configure(
		qw/-wrap word/
	);
}

sub _wrap_off {
	my $self = shift;
	$self->{install}{resulttext}->configure(
		qw/-wrap none/
	);
}

sub _wrap_toggle {
	my $self = shift;
	if ($self->{shouldwrap}) { $self->_wrap_on()  }
	else                     { $self->_wrap_off() }
}



1;

__END__

=head1 NAME

PAR::Dist::InstallPPD::GUI::Install - Implements the Install tab

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

