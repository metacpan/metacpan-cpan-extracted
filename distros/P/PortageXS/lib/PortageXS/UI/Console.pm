use strict;
use warnings;

package PortageXS::UI::Console;
BEGIN {
  $PortageXS::UI::Console::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::UI::Console::VERSION = '0.3.1';
}
# ABSTRACT: Console interface role for PortageXS
# -----------------------------------------------------------------------------
#
# PortageXS::UI::Console
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS/UI/Console.pm,v 1.9 2007/04/15 11:13:25 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------


use Role::Tiny;

# Description:
# Prints gentoo-style items.
sub printColored {
    my ( $self , @rest ) = @_;
    warn "please use self->colors->printColored(...)";
    return $_[0]->colors->printColored(@rest);
}

# Description:
# Wrapper for printColored >
sub print_ok {
	my ($self,@rest)	= @_;
    warn "please use self->colors->print_ok(...)";
    return $self->colors->print_ok(@rest);
}

# Description:
# Wrapper for printColored >
sub print_err {
	my ($self,@rest)	= @_;
    warn "please use self->colors->print_err(...)";
    return $self->colors->print_err(@rest);
}

# Description:
# Wrapper for printColored >
sub print_info {
	my ($self,@rest)	= @_;
    warn "please use self->colors->print_err(...)";
    return $self->colors->print_info(@rest);
}

# Description:
# Changes color to given param >
sub setPrintColor {
	my ($self,@rest)	= @_;
    warn "please use self->colors->printColor(...)";
	return $self->colors->printColor(@rest);

}

# Description:
# Asks user to make a decision.
# $usersChoice=$pxs->cmdAskUser($question,$options);
# $question: Text
# $options: Comma separated values (y,n,a,...)
# $usersChoice: one of the values given in $options in lowercase
sub cmdAskUser {
	my $self	= shift;
	my $question	= shift;
	my $option	= shift;
	my @options	= ();
	my $userInput	= "";
	my $valid	= 0;

	# - split comma seperated options >
	@options = split(/,/,$option);

	# - loop until user has entered a valid option >
	do {
		print ' '.$question.' ('.join('/',@options).'): ';
		chomp($userInput = <STDIN>);
		foreach my $this_option (@options) {
			if (lc($this_option) eq lc($userInput)) {
				$valid=1;
				last;
			}
		}
	}
	until($valid);

	return lc($userInput);
}

# Description:
# Formats useflags for output the way portages does.
# @formattedUseflags=$pxs->formatUseflags(@useflags);
sub formatUseflags {
	my $self	= shift;
	my @useflags	= @_;
	my @use1	= (); # +
	my @use2	= (); # -
	my %masked	= ();
	my %c		= ();

	foreach ($self->getUsemasksFromProfile()) {
		$masked{$_}=1;
	}

	# - Sort - Needed for the right display order >
	foreach my $this_use (@useflags) {
		if ($this_use=~m/^-/) {
			push(@use2,$this_use);
		}
		else {
			push(@use1,$this_use);
		}
	}
	@useflags=();
	push(@useflags,sort(@use1));
	push(@useflags,sort(@use2));
	@use1=();
	@use2=();

	# - Apply colors and use.mask >
	foreach my $this_use (@useflags) {
		if ($this_use=~m/^-/) {
			$c{'color'}='BLUE';
			$c{'useflag'}=substr($this_use,1,length($this_use)-1);
			$c{'prefix'}='-';
			$c{'suffix'}='';
			$c{'sort'}=2;
		}
		else {
			$c{'color'}='RED';
			$c{'useflag'}=$this_use;
			$c{'prefix'}='';
			$c{'suffix'}='';
			$c{'sort'}=1;
		}

		if ($this_use=~m/%/) {
			$c{'color'}='YELLOW';
			$c{'suffix'}.='%';
			$c{'useflag'}=~s/%//g;
		}

		if ($this_use=~m/\*/) {
			$c{'color'}='YELLOW';
			$c{'suffix'}.='*';
			$c{'useflag'}=~s/\*//g;
		}

        my $c = $self->colors;

		$c{'compiled'}=
            $c->getColor($c{'color'}) .
            $c{'prefix'}.
            $c{'useflag'}.
            $c->getColor('RESET').$c{'suffix'};

		if ($masked{$c{'useflag'}}) {
			$c{'compiled'}='('.$c{'compiled'}.')';
		}

		if ($c{'sort'}==1) {
			push (@use1,$c{'compiled'});
		}
		else {
			push (@use2,$c{'compiled'});
		}
	}

	return @use1,@use2;
}

# Description:
# Disables colors. / Unsets set colors in PortageXS.pm
# $pxs->disableColors();
sub disableColors {
    my $self	= shift;
    warn "please use self->colors->disableColors";
    return $self->colors->disableColors;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::UI::Console - Console interface role for PortageXS

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::UI::Console",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
