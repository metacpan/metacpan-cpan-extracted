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
package SVK::View;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(base name revision anchor view_map pool));

use Path::Class;

sub spec {
    my $self = shift;
    # XXX: ->relative('/') is broken with File::Spec 3.14
    my $viewspec = $self->base->subdir($self->name);
    $viewspec =~ s{^/}{};
    '/^'.$viewspec.'@'.$self->revision;
}

sub add_map {
    my ($self, $path, $dest) = @_;
    $self->view_map([]) unless $self->view_map;
    $self->adjust_anchor($dest) if defined $dest;
    push @{$self->view_map}, [$path, $dest];
}

sub adjust_anchor {
    my ($self, $dest) = @_;

    # XXX: Path::Class doesn't think '/' subsumes anything
    until ($self->anchor eq '/' or $self->anchor->subsumes($dest)) {
	$self->anchor($self->anchor->parent);
    }

}

sub rename_map {
    my ($self, $anchor) = @_;
    $anchor = $self->anchor unless defined $anchor;

    # return absolute map (without delets) with given anchor
    return [grep { defined $_->[1] } @{$self->view_map}] unless length $anchor;

    # return relative map
    return [map {
	($_->[1]->subsumes($anchor)) ?
	    [ map {
		Path::Class::Dir->new_foreign('Unix', $_)->relative($anchor)
		} @$_ ] : ()
    } grep { defined $_->[1] && $_->[0] ne $_->[1] } @{$self->view_map}];
}


sub rename_map2 {
    my ($self, $anchor, $actual_anchor) = @_;

    # return absolute map (without delets) with given anchor
    return [grep { defined $_->[1] } @{$self->view_map}] unless length $anchor;

    # return relative map
    return [map {
	($anchor ne $_->[0] && $anchor->subsumes($_->[0]) &&
	 $actual_anchor ne $_->[1] && $actual_anchor->subsumes($_->[1])) ?
	    [Path::Class::Dir->new_foreign('Unix', $_->[0])->relative($actual),
	     Path::Class::Dir->new_foreign('Unix', $_->[1])->relative($actual_anchor)]
	: ()
    } grep { defined $_->[1] && $_->[0] ne $_->[1] } @{$self->view_map}];

}

1;
