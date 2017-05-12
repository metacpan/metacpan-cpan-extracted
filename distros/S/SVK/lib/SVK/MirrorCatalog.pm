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
package SVK::MirrorCatalog;
use strict;

use base 'Class::Accessor::Fast';
use SVK::Path;
use SVK::Mirror;
use SVK::Config;

__PACKAGE__->mk_accessors(qw(depot repos cb_lock revprop _cached_mirror));

=head1 NAME

SVK::MirrorCatalog - mirror handling

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

# this is the cached and faster version of svn::mirror::has_local,
# which should be deprecated eventually.

my %mirror_cached;

sub entries {
    my $self = shift;
    return sort keys %{$self->_entries} if wantarray;
    return scalar keys %{$self->_entries};
}

sub _entries {
    my $self = shift;
    my $repos  = $self->repos;
    my $rev = $repos->fs->youngest_rev;
    delete $mirror_cached{$repos}
	unless ($mirror_cached{$repos}{rev} || -1) == $rev;
    return $mirror_cached{$repos}{hash}
	if exists $mirror_cached{$repos};

    if ($repos->fs->revision_prop(0, 'svn:svnsync:from-url')) {
	$mirror_cached{$repos} = { rev => $rev, hash => { '/' => undef } };
	return { '/' => undef };
    }

    my @mirrors = grep length,
        ( $repos->fs->revision_root($rev)->node_prop( '/', 'svm:mirror' )
            || '' ) =~ m/^(.*)$/mg;

    my %mirrored = map {
	local $@;
	my $m = eval {
            SVK::Mirror->load( { path => $_, depot => $self->depot, pool => SVN::Pool->new });
	};
        $@ ? () : ($_ => $m)

    } @mirrors;

    $mirror_cached{$repos} = { rev => $rev, hash => \%mirrored};
    return \%mirrored;
}

sub get {
    my ($self, $path) = @_;
    return $self->_entries->{$path} || SVK::Mirror->load( { path => $path, depot => $self->depot, pool => SVN::Pool->new });;
}

sub unlock {
    my ($self, $path) = @_;
    $self->get($path)->unlock('force');
}


# note that the additional path returned is to be concat to mirror url
sub is_mirrored {
    my ($self, $path) = @_;
    # XXX: check there's only one
    my ($mpath) = grep { SVK::Path->_to_pclass($_, 'Unix')->subsumes($path) } $self->entries;
    return unless $mpath;

    my $m = $self->get($mpath);
    if ( $mpath eq '/' ) {
	$path = '' if $path eq '/';
    } else {
        $path =~ s/^\Q$mpath\E//;
    }
    return wantarray ? ( $m, $path ) : $m;
}

=head1 SEE ALSO

L<SVN::Mirror>

=cut

1;
