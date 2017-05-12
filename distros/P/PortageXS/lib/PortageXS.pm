use strict;
use warnings;

package PortageXS;
BEGIN {
  $PortageXS::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::VERSION = '0.3.1';
}
# ABSTRACT: Portage abstraction layer for perl

# -----------------------------------------------------------------------------
#
# PortageXS
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS.pm,v 1.14 2008/12/01 19:53:27 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------

use Role::Tiny::With;
use Path::Tiny qw(path);


with 'PortageXS::Core';
with 'PortageXS::System';
with 'PortageXS::UI::Console';
with 'PortageXS::Useflags';

use PortageXS::Version;

sub portdir {
	my $self	= shift;
    return path($self->{portdir}) if defined $self->{portdir};
    $self->{portdir} = $self->config->getParam('PORTDIR','lastseen');
    return path($self->{portdir}) if $self->{portdir};
    my $debug = "";
    for my $file ( @{ $self->config->files }) {
        $debug .= sprintf qq[ * %s : %s \n], $file, ( -e $file ? 'ok' : 'missing' );
    }
    die "Could not determine PORTDIR from make.conf family: " . $debug;
}
sub config {
    my $self = shift;
    return $self->{config} if defined $self->{config};
    return $self->{config} = do {
        require PortageXS::MakeConf;
        return PortageXS::MakeConf->new();
    };
}

sub colors {
    my $self = shift;
    return $self->{colors} if defined $self->{colors};
    return $self->{colors} = do {
        require PortageXS::Colors;
        my $colors   = PortageXS::Colors->new();
        my $want_nocolor = $self->config->getParam('NOCOLOR', 'lastseen' );

        if ( $want_nocolor eq 'true' ) {
            $colors->disableColors;
        }
        $colors;
    };
}

sub new {
	my $self	= shift ;

	my $pxs = bless {}, $self;
    require Tie::Hash::Method;
    my %blacklist = (
        'COLORS' => 'please use pxs->colors ( PortageXS::Colors )',
        'PORTDIR' => 'please use pxs->portdir'
    );
    tie %{$pxs}, 'Tie::Hash::Method' => (
        FETCH => sub {
            my ( $self, $key ) = @_;
            if ( exists $blacklist{ $_[1] } ) {
                die "$_[1] is gone: " . $blacklist{ $_[1] };
            }
            $_[0]->base_hash->{ $_[1] };
        },
        STORE => sub {
            my ( $self, $key, $value ) = @_;
            if ( exists $blacklist{ $_[1] } ) {
                die "$_[1] is gone: " . $blacklist{ $_[1] };
            }
            $_[0]->base_hash->{ $_[1] } = $_[2];
        }
    );
	$pxs->{'VERSION'}			= $PortageXS::VERSION;
	my $prefix = $pxs->{'PREFIX'}            = path('/');

	$pxs->{'PKG_DB_DIR'}			= $prefix->child('var/db/pkg');
	$pxs->{'PATH_TO_WORLDFILE'}		= $prefix->child('var/lib/portage/world');
	$pxs->{'IS_INITIALIZED'}		= 1;

	$pxs->{'EXCLUDE_DIRS'}{'.'}		= 1;
	$pxs->{'EXCLUDE_DIRS'}{'..'}		= 1;
	$pxs->{'EXCLUDE_DIRS'}{'metadata'}	= 1;
	$pxs->{'EXCLUDE_DIRS'}{'licenses'}	= 1;
	$pxs->{'EXCLUDE_DIRS'}{'eclass'}	= 1;
	$pxs->{'EXCLUDE_DIRS'}{'distfiles'}	= 1;
	$pxs->{'EXCLUDE_DIRS'}{'profiles'}	= 1;
	$pxs->{'EXCLUDE_DIRS'}{'CVS'}		= 1;
	$pxs->{'EXCLUDE_DIRS'}{'.cache'}	= 1;

	my $etc = $pxs->{'ETC_DIR'}			= $prefix->child('etc');
	$pxs->{'PORTAGEXS_ETC_DIR'}		= $etc->child('pxs');

	$pxs->{'MAKE_PROFILE_PATHS'} = [
		$etc->child('make.profile'),
		$etc->child('portage/make.profile'),
	];

	$pxs->{'MAKE_GLOBALS_PATHS'} = [
		$etc->child('make.globals'),
		$prefix->child('usr/share/portage/config/make.globals'),
	];

	$pxs->{'MAKE_CONF_PATHS'} = [
		$etc->child('make.conf'),
		$etc->child('portage/make.conf'),
	];

	for my $path ( @{ $pxs->{'MAKE_PROFILE_PATHS'} } ) {
		next unless -e $path;
		$pxs->{'MAKE_PROFILE_PATH'} = $path;
	}
	if ( not defined $pxs->{'MAKE_PROFILE_PATH'} ) {
		die "Error, none of paths for `make.profile` exists." . join q{, }, @{ $pxs->{'MAKE_PROFILE_PATHS'} };
	}
	for my $path ( @{ $pxs->{'MAKE_CONF_PATHS'} } ) {
		next unless -e $path;
		$pxs->{'MAKE_CONF_PATH'} = $path;
	}
	if ( not defined $pxs->{'MAKE_CONF_PATH'} ) {
		die "Error, none of paths for `make.conf` exists." . join q{, }, @{ $pxs->{'MAKE_CONF_PATHS'} };
	}
	for my $path ( @{ $pxs->{'MAKE_GLOBALS_PATHS'} } ) {
		next unless -e $path;
		$pxs->{'MAKE_GLOBALS_PATH'} = $path;
	}
	if ( not defined $pxs->{'MAKE_GLOBALS_PATH'} ) {
		die "Error, none of paths for `make.globals` exists." . join q{, }, @{ $pxs->{'MAKE_GLOBALS_PATHS'} };
	}

	return $pxs;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS - Portage abstraction layer for perl

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS",
    "interface":"class",
    "does":[
        "PortageXS::Core",
        "PortageXS::System",
        "PortageXS::UI::Console",
        "PortageXS::Useflags"
    ]
}


=end MetaPOD::JSON

=head1 NAMING

For CPAN users, the name of this module is likely confusing, and annoying.

=over 4

=item * No prefix

Ideally, I'd have a proper prefix like C<Gentoo::>, however, this is a dependency problem, and this package
has lived for a while in the C<Gentoo> ecosystem as this name, and changing a name will have limitations on adopting downstreams.

=item * No XS

Though the name says C<XS> in it, you'll see there is no C<XS> anywhere in the tree. This, I imagine, is a result of naming crossover, and C<XS> here means more C<Access> or something.

=back

As such, my preferred name would be C<Gentoo::Portage::API>, or something like that, but we're stuck for now.

=head1 SIGNIFICANT CHANGES

=head2 0.3.0 Series

=head3 0.3.0

=head4 Slurping Overhaul

This module contains a lot of file slurping magic, in a few various forms, as well as path mangling
and similar things.

This release is a huge overhaul of how that works, and sufficiently more dependence is now placed on L<< C<Path::Tiny>|Path::Tiny >>'s head.

C<getFileContents> is now deprecated, and will warn when called.

However, the nature of this change is likely introduce a few bugs in places I may not have transformed the code properly, which may not be immediately obvservable.

=head1 CHOPPING BLOCK

I've inherited this module from Gentoo Staff, who are now more-or-less retired, and this code has
been bitrotting away for a year.

Its ugly, its crufty, and it has a lot of bad and evil things that need to die.

And much of it is on my mental chopping block.

=head2 Exporter based .... roles.

Yes. You read correctly. This code uses L<Exporter> to implement mixin-style class-composition, like roles. Just it uses L<Exporter> to do it instead of a more sane C<Role> based tool.

This has the nasty side effect that everywhere you C<use PortageXS>, you inadvertently inject a whole load of functions you don't want, and will never want, and couldn't use if you did want them, because they all require an invocant in C<$_[0]>

Will be changed evenutally.

=head2 Poor encapsulation and many classes directly modifying hash keys.

All over the codebase there are weird tricks to make sure specific hash keys are present,
and populate them lazily, and some tricks are implemented the same way a dozen times.

All direct hash manipulation is scheduled to be ripped out unceremoniously in a future release,
in favour of more sane tools like C<Moo> based accessors, lazy loading and things like that.

=head2 Poor concern seperation

Every module that has in it its own routine for loading files into strings, is reinventing a bad wheel.

This module is no exception.

I plan to remove 90% of the filesystem interaction in favour of using L<< C<Path::Tiny>|Path::Tiny >> B<everywhere>

Its 1 more dep, and a whole load of better, and much more throughrougly tested code.

So if you use C<PortageXS> already, and you're using things of the above types, stop now.

    PortageXS::Core::getFileContents <-- will be a deprecated function in a future release.

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
