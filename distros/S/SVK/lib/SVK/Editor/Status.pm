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
package SVK::Editor::Status;
use strict;
use SVN::Delta;
use SVK::Logger;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base 'SVK::Editor';

__PACKAGE__->mk_accessors(qw(report notify tree ignore_absent));

sub new {
    my ($class, @arg) = @_;
    my $self = $class->SUPER::new (@arg);
    $self->notify( SVK::Notify->new_with_report
		   (defined $self->report ? $self->report : '') ) unless $self->notify;
    $self->tree(Data::Hierarchy->new) unless $self->tree;
    use Data::Dumper;
    $logger->debug(Dumper($self));
    return $self;
}

sub _tree_get {
    my $self = shift;
    my $path = shift;
    $path = $self->tree->{sep} . $path;
    return $self->tree->get($path, @_);
}

sub _tree_store {
    my $self = shift;
    my $path = shift;
    $path = $self->tree->{sep} . $path;
    return $self->tree->store($path, @_);
}

sub open_root {
    my ($self, $baserev) = @_;
    $self->notify->node_status ('', '');
    $self->notify->node_baserev ('', $baserev);
    return '';
}

sub add_or_replace {
    my ($self, $path) = @_;
    if ($self->notify->node_status ($path)) {
	$self->notify->node_status ($path, 'R')
	    if $self->notify->node_status ($path) eq 'D';
    }
    else {
	$self->notify->node_status ($path, 'A');
    }
    $self->{info}{$path}{added_or_replaced} = 1;
}

sub add_file {
    my ($self, $path, $pdir, $from_path, $from_rev) = @_;
    $self->add_or_replace ($path);
    $self->notify->hist_status ($path, '+', $from_path, $from_rev)
	if $from_path;
    return $path;
}

sub open_file {
    my $self = shift;
    return $self->open_node(@_);
}

sub apply_textdelta {
    my ($self, $path) = @_;
    return undef if $self->notify->node_status ($path) eq 'R';
    $self->notify->node_status ($path, 'M')
	if !$self->notify->node_status ($path) || $self->notify->hist_status ($path);
    return undef;
}

sub change_file_prop {
    my ($self, $path, $name, $value) = @_;
    $self->notify->prop_status ($path, 'M')
        unless $self->{info}{$path}{added_or_replaced};
}

sub close_file {
    my ($self, $path) = @_;
    $self->notify->flush ($path);
    delete $self->{info}{$path};
}

sub absent_file {
    my ($self, $path) = @_;
    return if $self->ignore_absent;
    $self->notify->node_status ($path, '!');
    $self->notify->flush ($path);
}

sub delete_entry {
    my ($self, $path) = @_;
    $self->notify->node_status ($path, 'D');
    my $info = $self->_tree_get ($path);
    $self->notify->hist_status ($path, '+', $info->{frompath},
	$info->{fromrev}) if $info->{frompath};
}

sub add_directory {
    my ($self, $path, $pdir, $from_path, $from_rev) = @_;
    $self->add_or_replace ($path);
    if ($from_path) {
	$self->notify->hist_status ($path, '+', $from_path, $from_rev);
	$self->_tree_store ($path, {frompath => $from_path,
                                    fromrev => $from_rev});
    }
    $self->notify->flush ($path, 1);
    return $path;
}

sub open_directory {
    my $self = shift;
    return $self->open_node(@_);
}

sub change_dir_prop {
    my ($self, $path, $name, $value) = @_;
    $self->notify->prop_status ($path, 'M')
        unless $self->{info}{$path}{added_or_replaced};
}

sub close_directory {
    my ($self, $path) = @_;
    $self->notify->flush_dir ($path);
    delete $self->{info}{$path};
}

sub open_node {
    my ($self, $path, $pdir, $baserev, $pool) = @_;
    $self->notify->node_status ($path, '')
	unless $self->notify->node_status ($path);
    $self->notify->node_baserev ($path, $baserev);
    my $info = $self->_tree_get ($path);
    $self->notify->hist_status ($path, '+', $info->{frompath},
	$info->{fromrev}) if $info->{frompath};
    return $path;
}

sub absent_directory {
    my ($self, $path) = @_;
    return if $self->ignore_absent;
    $self->notify->node_status ($path, '!');
    $self->notify->flush ($path);
}

sub conflict {
    my ($self, $path, $baton, $type) = @_;
    # backward compatibility
    $type = 'node' if !$type || $type eq '1';
    $self->notify->$_ ($path, 'C')
        foreach map $_ ."_status", split /,/, $type;
}

sub obstruct {
    my ($self, $path) = @_;
    $self->notify->node_status ($path, '~');
}

sub unknown {
    my ($self, $path) = @_;
    $self->notify->node_status ($path, '?');
    $self->notify->flush ($path);
}

sub ignored {
    my ($self, $path) = @_;
    $self->notify->node_status ($path, 'I');
    $self->notify->flush ($path);
}

sub unchanged {
    my ($self, $path, @args) = @_;
    $self->open_node($path, @args);
    $self->notify->flush ($path);
}

1;
