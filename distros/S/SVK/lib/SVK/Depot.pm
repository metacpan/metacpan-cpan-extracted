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
package SVK::Depot;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(repos repospath depotname));

=head1 NAME

SVK::Depot - Depot class in SVK

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item mirror

Returns the mirror catalog object associated with the current depot.

=cut

sub mirror {
    my $self = shift;
    return SVK::MirrorCatalog->new
	( { repos => $self->repos,
            depot => $self,
	    revprop => ['svk:signature'] });
}

=item find_local_mirror($uuid, $path, [$rev])

Returns the path on the current depot that has the mirror of C<$uuid:$path>.
If C<$rev> is given, returns the local revision as well.

=cut

sub find_local_mirror {
    my ($self, $uuid, $path, $rev) = @_;
    my $myuuid = $self->repos->fs->get_uuid;
    return if $uuid eq $myuuid;

    my ($m, $mpath) = $self->_has_local("$uuid:$path");
    return ($m->path.$mpath,
	    $rev ? $m->find_local_rev($rev) : $rev) if $m;
    return;
}

sub _has_local {
    my ($self, $spec) = @_;
    for my $path ($self->mirror->entries) {
	my $m = $self->mirror->get($path);
	my $mspec = $m->spec;
	my $mpath = $spec;
	return ($m, '') if $mpath eq $mspec;
	next unless $mpath =~ s{^\Q$mspec\E/}{/};

        # the common usage for $mpath is $m->path . $mpath, so if the
        # mirror is anchored on /, we need to get rid of the leading /
        # in $mpath.
        $mpath = substr($mpath, 1) if $m->path eq '/';
	$mpath = '' if $mpath eq '/'; # XXX: why still need this?
	return ($m, $mpath);
    }
    return;
}

1;
