# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Command::Checkout;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Update );
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( get_anchor abs_path move_path splitdir $SEP get_encoding abs_path_noexist catfile );
use File::Path;
use SVK::Logger;

sub options {
    ($_[0]->SUPER::options,
     'l|list' => 'list',
     'd|delete|detach' => 'detach',
     'purge' => 'purge',
     'export' => 'export',
     'relocate' => 'relocate',
     'floating' => 'floating');
}

sub parse_arg {
    my ($self, @arg) = @_;

    return if $#arg < 0 || $#arg > 1;

    my ($src, $dst) = @arg;
    $dst = '' unless defined $dst;

    my $depotpath = $self->arg_uri_maybe
	($src,
	 eval { $self->arg_co_maybe ($dst, 'Checkout destination') }
	 ? "path '$dst' is already a checkout" : undef);
    die loc("don't know where to checkout %1\n", $src) unless length ($dst) || $depotpath->path_anchor ne '/';

    $dst =~ s|/$|| if length $dst;
    $dst = (splitdir($depotpath->path_anchor))[-1]
        if !length($dst) or $dst =~ /^\.?$/;

    return ($depotpath, $dst);
}

sub lock {
    my ($self, $src, $dst) = @_;
    my $abs_path = abs_path_noexist ($dst) or return;
    $self->{xd}->lock ($abs_path);
}

sub run {
    my ($self, $target, $report) = @_;

    $self->_not_if_floating;

    if (-e $report) {
	my $copath = abs_path($report);
	my ($entry, @where) = $self->{xd}{checkout}->get($copath, 1);
        return $self->SUPER::run
	    ( SVK::Path::Checkout->real_new
	      ({ source => $target->mclone(revision => $entry->{revision}),
		 xd => $self->{xd},
		 report => $report,
		 copath_anchor => $copath,
	       }) )
	    if exists $entry->{depotpath} && $entry->{depotpath} eq $target->depotpath;
	die loc("Checkout path %1 already exists.\n", $report);
    }
    else {
	# Cwd is annoying, returning undef for paths whose parent.
	# we can't just mkdir -p $report because it might be a file,
	# so let C::Update take care about it.
	my ($anchor) = get_anchor (0, $report);
	if (length $anchor && !-e $anchor) {
	    mkpath [$anchor] or
		die loc ("Can't create checkout path %1: %2\n", $anchor, $!);
	}
    }

    # abs_path doesn't work until the parent is created.
    my $copath = abs_path ($report);
    my ($entry, @where) = $self->{xd}{checkout}->get ($copath, 1);
    die loc("Overlapping checkout path is not supported (%1); use 'svk checkout --detach' to remove it first.\n", $where[0])
	if exists $entry->{depotpath} && $#where > 0;

    my $xd;
    if ($self->{floating}) {
	my $svkpath = catfile($copath, '.svk');

	mkdir($copath)
	    or die loc("Cannot create checkout directory at '%1': %2\n",
		       $copath, $!);
	$xd = SVK::XD->new ( giantlock => catfile($svkpath, 'lock'),
			     statefile => catfile($svkpath, 'config'),
			     svkpath => $svkpath,
			     depotmap => { $target->depotname => $target->repospath },
			     floating => $copath,
			   );
	$xd->giant_lock;
	my $magic = catfile($svkpath, 'floating');
	open my $magic_fh, '>', $magic or die $!;
	print $magic_fh "This is an SVK floating checkout.";
	close $magic_fh;

	$xd->lock($copath);
    } else {
	$xd = $self->{xd};
    }

    $xd->{checkout}->store ( $copath,
			     { depotpath => $target->depotpath,
			       encoding => get_encoding,
			       revision => 0,
			       '.schedule' => undef,
			       '.newprop' => undef,
			       '.deleted' => undef,
			       '.conflict' => undef,
			     },
			     {override_sticky_descendents => 1});

    my $source = $target->can('source') ? $target->source : $target;
    my $cotarget = SVK::Path::Checkout->real_new
	({ copath_anchor => $copath, report => $report,
	   xd => $xd, source => $source->mclone( revision => 0 ) });
    $self->do_update( $cotarget,
		      $target->new->as_depotpath($self->{rev}) );

    $self->rebless ('checkout::detach')->run ($copath)
	if $self->{export};

    $xd->unlock($copath) if $self->{floating};

    return;
}

sub _find_copath {
    my ($self, $path) = @_;
    my $abs_path = abs_path_noexist($path);
    my $map = $self->{xd}{checkout}{hash};

    # Check if this is a checkout path
    return $abs_path if defined $abs_path and $map->{$abs_path};

    # Find all copaths that matches this depotpath
    return sort grep {
        defined $map->{$_}{depotpath}
            and $map->{$_}{depotpath} eq $path
    } keys %$map;
}

sub _not_if_floating {
    my ($self, $op) = @_;
    $op = 'svk checkout ' . $op if $op;
    $op ||= 'svk checkout';
    die loc("%1 is not supported inside a floating checkout.\n", $op)
	if $self->{xd}->{floating};
}

package SVK::Command::Checkout::list;
use base qw( SVK::Command::Checkout );
use SVK::Logger;
use SVK::I18N;

sub parse_arg { undef }

sub lock {}

sub run {
    my ($self) = @_;
    my $map = $self->{xd}{checkout}{hash};
    my $fmt = "%1s %-30s\t%-s\n";
    $logger->info(sprintf $fmt, ' ', loc('Depot Path'), loc('Path')); 
     $logger->info('=' x 72, "\n");
    $logger->info( sort(map sprintf($fmt, -e $_ ? ' ' : '?', $map->{$_}{depotpath}, $_), grep $map->{$_}{depotpath}, keys %$map));
    return;
}

package SVK::Command::Checkout::relocate;
use base qw( SVK::Command::Checkout );
use SVK::Util qw( get_anchor abs_path move_path splitdir $SEP );
use SVK::Logger;
use SVK::I18N;

sub parse_arg {
    my ($self, @arg) = @_;
    die loc("Do you mean svk switch %1?\n", $arg[0]) if @arg == 1;
    return if @arg > 2;
    return @arg;
}

sub lock { ++$_[0]->{hold_giant} }

sub run {
    my ($self, $path, $report) = @_;

    $self->_not_if_floating('--relocate');

    my @copath = $self->_find_copath($path)
        or die loc("'%1' is not a checkout path.\n", $path);
    @copath == 1
        or die loc("'%1' maps to multiple checkout paths.\n", $path);

    my $target = abs_path ($report);
    if (defined $target) {
        my ($entry, @where) = $self->{xd}{checkout}->get ($target);
        die loc("Overlapping checkout path is not supported (%1); use 'svk checkout --detach' to remove it first.\n", $where[0])
            if exists $entry->{depotpath};
    }

    # Manually relocate all paths
    my $hmap = $self->{xd}{checkout}{hash};

    my $abs_path = abs_path($path);
    if ($hmap->{$abs_path} and -d $abs_path) {
        move_path($path => $report);
        $target = abs_path ($report);
    }

    my $prefix = $copath[0].$SEP;
    my $length = length($copath[0]);
    my $relocate = sub {
        my $map = shift;
        for my $key ( sort grep { index( "$_$SEP", $prefix ) == 0 }
            keys %$map ) {
            $map->{ $target . substr( $key, $length ) } = delete $map->{$key};
        }
    };
    $relocate->($hmap);
    $relocate->($self->{xd}{checkout}{sticky});

    $logger->info( loc("Checkout '%1' relocated to '%2'.\n", $path, $target));

    return;
}

package SVK::Command::Checkout::detach;
use base qw( SVK::Command::Checkout );
use SVK::Logger;
use SVK::I18N;

sub parse_arg {
    my ($self, @arg) = @_;
    return @arg ? @arg : '';
}

sub lock { ++$_[0]->{hold_giant} }

sub _remove_entry { (depotpath => undef, revision => undef, encoding => undef) }

sub run {
    my ($self, @paths) = @_;

    # Alternatively we could delete the entire .svk directory if floating.
    $self->_not_if_floating('--detach');

    for my $path (@paths) {
        my @copath = $self->_find_copath($path)
          or die loc("'%1' is not a checkout path.\n", $path);

        my $checkout = $self->{xd}{checkout};
        foreach my $copath (sort @copath) {
            $checkout->store ($copath, {_remove_entry, $self->_schedule_empty},
                             {override_sticky_descendents => 1});
            $logger->info( loc("Checkout path '%1' detached.\n", $copath));
        }
    }

    return;
}

package SVK::Command::Checkout::purge;
use base qw( SVK::Command::Checkout );
use SVK::Util qw( get_prompt );
use SVK::I18N;

sub parse_arg { undef }

sub lock { ++$_[0]->{hold_giant} }

sub run {
    my ($self) = @_;
    my $map = $self->{xd}{checkout}{hash};

    $self->_not_if_floating('--purge');

    $self->rebless('checkout::detach');

    for my $path (sort grep $map->{$_}{depotpath}, keys %$map) {
	next if -e $path;

	my $depotpath = $map->{$path}{depotpath};

	get_prompt(loc(
	    "Purge checkout of %1 to non-existing directory %2? (y/n) ",
	    $depotpath, $path
	), qr/^[YyNn]/) =~ /^[Yy]/ or next;
	
	# Recall that we are now an SVK::Command::Checkout::detach
	$self->run($path);
    } 
    
    return;
}

1;
__DATA__

=head1 NAME

SVK::Command::Checkout - Checkout the depotpath

=head1 SYNOPSIS

 checkout DEPOTPATH [PATH]
 checkout --list
 checkout --detach [DEPOTPATH | PATH]
 checkout --relocate DEPOTPATH|PATH PATH
 checkout --purge

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -N [--non-recursive]   : do not descend recursively
 -l [--list]            : list checkout paths
 -d [--detach]          : mark a path as no longer checked out
 -q [--quiet]           : quiet mode
 --export               : export mode; checkout a detached copy
 --floating             : create a floating checkout
 --relocate             : relocate the checkout to another path
 --purge                : detach checkout directories which no longer exist

