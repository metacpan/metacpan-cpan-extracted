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
package SVK::Inspector::Root;

use strict;
use warnings;


use base qw {
	SVK::Inspector
};

__PACKAGE__->mk_accessors(qw{txn anchor});


my $root_accessor = __PACKAGE__->make_accessor('root');

sub root {
    if ($_[0]{txn}) {
	return $_[0]{txn}->root;
    }
    goto $root_accessor;
}

sub exist {
    my ($self, $path, $pool) = @_;
    $path = $self->_anchor_path($path);
    return $self->root->check_path ($path, $pool);
}

sub localmod {
    my ($self, $path, $checksum, $pool) = @_;
    $path = $self->_anchor_path($path);
    my $md5 = $self->root->file_md5_checksum ($path, $pool);
    return if $md5 eq $checksum;
    return [$self->root->file_contents ($path, $pool), undef, $md5];
}

sub localprop {
    my ($self, $path, $propname, $pool) = @_;
    $path = $self->_anchor_path($path);
    local $@;
    return eval { $self->root->node_prop ($path, $propname, $pool) };
}
sub dirdelta {
    my ($self, $path, $base_root, $base_path, $pool) = @_;
    $path = $self->_anchor_path($path);
    my $modified = {};
    my $entries = $self->root->dir_entries($path, $pool);
    my $base_entries = $base_root->dir_entries($base_path, $pool);
    my $spool = SVN::Pool->new_default;
    for (sort keys %$base_entries) {
	$spool->clear;
	my $entry = delete $entries->{$_};
	next if $base_root->check_path("$base_path/$_") == $SVN::Node::dir;
	if ($entry) {
	    $modified->{$_} = 'M'
		if $self->root->file_md5_checksum("$path/$_") ne
		    $base_root->file_md5_checksum("$base_path/$_");
	    next;
	}

	$modified->{$_} = 'D';
    }
    for (keys %$entries) {
	if ($entries->{$_}->kind == $SVN::Node::file) {
	    $modified->{$_} = 'A';
	}
	elsif ($entries->{$_}->kind == $SVN::Node::unknown) {
	    $modified->{$_} = '?';
	}
    }
    return $modified;
}

sub _anchor_path {
    my ($self, $path) = @_;
    $path = $self->translate($path);
    return $path if $path =~ m{^/};
    return $self->anchor unless length $path;
    return $self->anchor eq '/' ? "/$path" : $self->anchor."/$path";
}

1;
