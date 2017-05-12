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
package SVK::Log::ChangedPaths;

# a "constant" (inlined by the compiler)
sub ROOT () {0}

sub new {
    my ( $class, $root ) = @_;
    return bless [$root], $class;
}

sub paths {
    my ($self) = @_;

    my $root    = $self->[ROOT];
    my $changed = $root->paths_changed();

    my @changed;
    require SVK::Log::ChangedPath;
    for my $path_name ( sort keys %$changed ) {
        my $changed_path = SVK::Log::ChangedPath->new(
            $root,
            $path_name,
            $changed->{$path_name}
        );
        push @changed, $changed_path;
    }

    return @changed;
}

1;

__END__

=head1 NAME
 
SVK::Log::ChangedPaths - partly lazy list of SVK::Log::ChangedPath objects
 
=head1 SYNOPSIS
 
    use SVK::Log::ChangedPaths;
    my $changed_paths = SVK::Log::ChangedPaths->new( $root );
    for my $changed_path ( $changed_paths->paths() ) {
        ...
    }
  
=head1 DESCRIPTION

An object of this class represents a collection of details about the
files/directories that were changed in a particular revision.  Some log
filters want access to information about which paths were affected during a
certain revision and others don't.  Using this object allows the calculation
of path details to be postponed until it's truly needed.
 
 
=head1 METHODS 
 
=head2 new

Accepts the return value of C<< SVK::Path->root() >> as a parameter and constructs a
SVK::Log::ChangedPaths object from it.

=head2 paths

Returns a list of L<SVK::Log::ChangedPath> objects each of which represents
the details of the changes to a particular path.
 
 
=head1 DIAGNOSTICS
 
None
 
=head1 CONFIGURATION AND ENVIRONMENT
 
SVK::Log::ChangedPaths requires no configuration files or environment variables.
 
=head1 DEPENDENCIES
 
=over

=item *

SVK::Log::ChangedPath

=back
 
=head1 INCOMPATIBILITIES
 
None known
 
=head1 BUGS AND LIMITATIONS
 
None known
