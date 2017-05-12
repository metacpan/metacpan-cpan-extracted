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
package SVK::Editor::CopyHandler;
use strict;
use warnings;
use SVK::Version;  our $VERSION = $SVK::VERSION;

require SVN::Delta;
use base 'SVK::Editor::ByPass';

=head1 NAME

SVK::Editor::CopyHandler - intercept copies in editor calls

=head1 SYNOPSIS

=cut

sub _mk_method {
    my $method = shift;

    sub {
        my ( $self, $path, $pbaton, $from_path, $from_rev, $pool ) = @_;
        my $cb;

        ( $from_path, $from_rev, $cb )
            = $self->{cb_copy}
            ->( $self, $from_path, $from_rev, $path, $pbaton );

        my $func = "SUPER::".$method;
        my $ret = $self->$func( $path, $pbaton, $from_path, $from_rev, $pool );
        $cb->($method, $ret) if $cb;
        return $ret;
    }
}

*add_directory = _mk_method("add_directory");
*add_file      = _mk_method("add_file");

1;
