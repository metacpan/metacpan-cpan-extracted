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
package SVK::Merge::Info;

=head1 NAME

SVK::Merge::Info - Container for merge ticket information

=head1 SYNOPSIS

  use SVK::Merge::Info;
  my $minfo = SVK::Merge::Info->new( $svk_merge_property );

=head1 DESCRIPTION

An C<SVK::Merge::Info> object represents a collection of merge tickets, 
including repository UUID, path and revision.

=head1 CONSTRUCTORS

=head2 new

Takes a single argument with the value of an "svk:merge" property.

=head1 METHODS

=over

=cut

sub new {
    my ( $class, $merge ) = @_;
    my $minfo = {
        map {
            my ( $uuid, $path, $rev ) = m/(.*?):(.*):(\d+$)/;
            ( "$uuid:$path" =>
                    SVK::Target::Universal->new( $uuid, $path, $rev ) )
        } grep { length $_ } split( /\n/, $merge || '' )
    };
    bless $minfo, $class;
    return $minfo;
}

=item add_target

Add a single L<SVK::Target::Universal> or L<SVK::Path> to the
collection of merge tickets.

=cut

sub add_target {
    my ( $self, $target ) = @_;
    $target = $target->universal
        if $target->can('universal');
    $self->{ $target->ukey } = $target;
    return $self;
}

=item del_target

Remove a single L<SVK::Target::Universal> or L<SVK::Path> from the
collection of merge tickets.

=cut

sub del_target {
    my ( $self, $target ) = @_;
    $target = $target->universal
        if $target->can('universal');
    delete $self->{ $target->ukey };
    return $self;
}

=item remove_duplicated

Takes a single L<SVK::Merge::Info> object as an argument.  Removes merge
tickets which are present in the argument and for which the argument's
revision is less than or equal to our revision.

=cut

sub remove_duplicated {
    my ( $self, $other ) = @_;
    for ( keys %$other ) {
        if ( $self->{$_} && $self->{$_}{rev} <= $other->{$_}{rev} ) {
            delete $self->{$_};
        }
    }
    return $self;
}

=item subset_of

Takes a single L<SVK::Merge::Info> object as an argument.  Returns true if our
set of merge tickets is a subset of the argument's merge tickets.  Otherwise,
returns false.

=cut

sub subset_of {
    my ( $self, $other ) = @_;
    my $subset = 1;
    for ( keys %$self ) {
        return
            unless exists $other->{$_}
            && $self->{$_}{rev} <= $other->{$_}{rev};
    }
    return 1;
}

=item is_equal

Takes a single L<SVK::Merge::Info> object as an argument.  Returns true if
our set of merge tickets is equal to argument's. Otherwise, returns false.

=cut

sub is_equal {
    my ( $self, $other ) = @_;
    my $subset = 1;
    for ( keys %$self, keys %$other ) {
        return 0 unless
            exists $other->{$_}
            && exists $self->{$_}
            && $self->{$_}{rev} == $other->{$_}{rev};
    }
    return 1;
}

=item union

Return a new L<SVK::Merge::Info> object representing the union of ourself and
the L<SVK::Merge::Info> object given as the argument.

=cut

sub union {
    my ( $self, $other ) = @_;

    # bring merge history up to date as from source
    my $new = SVK::Merge::Info->new;
    for ( keys %{ { %$self, %$other } } ) {
        if ( $self->{$_} && $other->{$_} ) {
            $new->{$_} = $self->{$_}{rev} > $other->{$_}{rev}
                ? $self->{$_}
                : $other->{$_};
        }
        else {
            $new->{$_} = $self->{$_} ? $self->{$_} : $other->{$_};
        }
    }
    return $new;
}

sub intersect {
    my ($self, $other) = @_;
    # bring merge history up to date as from source
    my $new = SVK::Merge::Info->new;
    for ( keys %{ { %$self, %$other } } ) {
        if ( $self->{$_} && $other->{$_} ) {
            $new->{$_} = $self->{$_}{rev} < $other->{$_}{rev}
                ? $self->{$_}
                : $other->{$_};
        }
    }
    return $new;
}

=item resolve

=cut

sub resolve {
    my ( $self, $depot ) = @_;

    my $uuid = $depot->repos->fs->get_uuid;
    return {
        map {
            my $local = $self->{$_}->local($depot);
            $local
                ? ( "$uuid:" . $local->path_anchor => $local->revision )
                : ()
        } keys %$self
    };
}

=item verbatim

=cut

sub verbatim {
    my ($self) = @_;
    return { map { $_ => $self->{$_}{rev} } keys %$self };
}

=item as_string

Serializes this collection of merge tickets in a form suitable for storing as
an svk:merge property.

=cut

sub as_string {
    my $self = shift;
    return join( "\n", map {"$_:$self->{$_}{rev}"} sort keys %$self );
}

=back

=head1 TODO

Document the merge and ticket tracking mechanism.

=head1 SEE ALSO

L<SVK::Editor::Merge>, L<SVK::Command::Merge>, Star-merge from GNU Arch

=cut

1;
