use strict;
use warnings;

package PortageXS::Useflags;
BEGIN {
  $PortageXS::Useflags::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::Useflags::VERSION = '0.3.1';
}
# ABSTRACT: Useflag parsing utilities role for PortageXS
# -----------------------------------------------------------------------------
#
# PortageXS::Useflags
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS/Useflags.pm,v 1.7 2008/12/01 20:30:23 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------

use Path::Tiny qw(path);
use Role::Tiny;


# Description:
# Returns useflag description of the given useflag and repository.
# Returns only global usedescs.
# $usedesc=getUsedesc($use,$repo);
# Example:
# $usedesc=getUsedesc('perl','/usr/portage');
sub getUsedesc {
	my $self	= shift;

	return ($self->getUsedescs(@_))[0];
}

# Description:
# Returns useflag descriptions of the given useflag and repository.
# Returns global and local usedescs. (Local usedescs only if the optional parameter $categoryPackage is set.)
# @usedescs=getUsedescs($use,$repo[,$categoryPackage]);
# Example:
# @usedescs=getUsedescs('perl','/usr/portage'[,'dev-lang/perl']);
sub getUsedescs {
	my $self	= shift;
	my $use		= shift;
	my $repo	= shift;
	my $package	= shift;
	my @p		= ();
	my @descs	= ();

	my $usedesc = path($repo)->child('profiles/use.desc' );
	my $uselocaldesc = path($repo)->child('profiles/use.local.desc' );

	if (-e $usedesc ) {
		if (!$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.desc'}{'initialized'}) {
			foreach my $desc ($usedesc->lines({ chomp => 1 })) {
				if ($desc) {
					@p=split(/ - /,$desc);
					$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.desc'}{'use'}{$p[0]}=$p[1];
				}
			}
			$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.desc'}{'initialized'}=1;
		}

		if ($self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.desc'}{'use'}{$use}) {
			push(@descs,$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.desc'}{'use'}{$use});
		}
	}

	if ($package) {
		if (-e $uselocaldesc) {
			if (!$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.local.desc'}) {
				$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.local.desc'}=$uselocaldesc->slurp();
			}

			foreach (split(/\n/,$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$repo}{'use.local.desc'})) {
				if ($_) {
					@p=split(/ - /,$_);
					if ($p[0] eq $package.':'.$use) {
						push(@descs,$p[1]);
					}
				}
			}
		}
	}

	return @descs;
}

# Description:
# Sorts useflags the way portages does.
# @sortedUseflags = sortUseflags(@useflags);
sub sortUseflags {
	my $self	= shift;
	my @useflags	= @_;
	my (@use1,@use2);

	foreach my $useflag (sort @useflags) {
		if (substr($useflag,0,1) eq '-') {
			push @use1, $useflag;
		}
		else {
			push @use2, $useflag;
		}
	}
	return (@use2,@use1);
}

# Description:
# Helper for getUsemasksFromProfile()
sub getUsemasksFromProfileHelper {
	my $self	= shift;
	my $curPath	= shift;
	my @files	= ();
	my $parent	= '';


	if (-e ( my $file = path($curPath)->child('use.mask')) ) {
		push(@files,$file);
	}
	if (! -e path($curPath)->child('parent')) {
		return @files;
	}
	for my $parent ( path($curPath)->child('parent')->lines({chomp => 1}) ){
		push(@files,$self->getUsemasksFromProfileHelper($parent));
	}
	return @files;
}

# Description:
# Returnvalue is an array containing all masked useflags set in the system-profile.
#
# Example:
# @maskedUseflags=$pxs->getUsemasksFromProfile();
sub getUsemasksFromProfile {
	my $self	= shift;
	my $curPath	= '';
	my @files	= ();
	my $parent	= '';
	my $c		= 0;
	my %maskedUses	= ();
	my @useflags	= ();

	if (!$self->{'CACHE'}{'Useflags'}{'getUsemasksFromProfile'}{'useflags'}) {
		if(!-e $self->{'MAKE_PROFILE_PATH'}) {
			$self->print_err('Profile not set!');
			exit(0);
		}
		else {
			$curPath=$self->getProfilePath();
		}

# 		while(1) {
# 			print "-->".$curPath."<--\n";
# 			if (-e $curPath.'/use.mask') {
# 				push(@files,$curPath.'/use.mask');
# 			}
# 			if (! -e $curPath.'/parent') { last; }
# 			$parent=$self->getFileContents($curPath.'/parent');
# 			chomp($parent);
# 			$curPath.='/'.$parent;
# 		}
		@files = $self->getUsemasksFromProfileHelper($curPath);

		my @lines;

		push @lines, $self->portdir->child('profiles/base/use.mask')->lines({ chomp => 1 });
		for my $file (reverse(@files)) {
			push @lines, path($file)->lines({ chomp => 1 });
		}


		for($c=0;$c<=$#lines;$c++) {
			next if $lines[$c]=~m/^#/;
			next if $lines[$c] eq "\n";
			next if $lines[$c] eq '';

			if (substr($lines[$c],0,1) eq '-') {
				# - unmask use >
				$maskedUses{substr($lines[$c],1,length($lines[$c])-1)}=0;
			}
			else {
				$maskedUses{$lines[$c]}=1;
			}
		}

		foreach (keys %maskedUses) {
			if ($maskedUses{$_}) {
				push(@useflags,$_);
			}
		}

		# - Setup cache >
		$self->{'CACHE'}{'Useflags'}{'getUsemasksFromProfile'}{'useflags'}=join(' ',@useflags);
	}
	else {
		@useflags=split(/ /,$self->{'CACHE'}{'Useflags'}{'getUsemasksFromProfile'}{'useflags'});
	}

	return @useflags;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::Useflags - Useflag parsing utilities role for PortageXS

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::Useflags",
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
