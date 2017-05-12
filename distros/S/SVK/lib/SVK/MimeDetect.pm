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
package SVK::MimeDetect;
use strict;
use warnings;
use SVK::I18N;

# die if this method is not overriden
sub new {
    my ($self) = @_;
    my $pkg = ref $self || $self;
    die loc(
        "%1 needs to implement new().\n" .
        "Read the documentation of SVK::MimeDetect for details\n",
        $pkg
    );
}

# die if this method is not overriden
sub checktype_filename {
    my ($self) = @_;
    my $pkg = ref $self || $self;
    die loc(
        "%1 needs to implement checktype_filename().\n" .
        "Read the documentation of SVK::MimeDetect for details\n",
        $pkg
    );
}

1;

__END__

=head1 NAME

SVK::MimeDetect - interface for MIME type detection algorithms

=head1 DESCRIPTION

This defines an interface for MIME type detection algorithms.  A MIME type
detection module doesn't need to inherit from this module, but it does need to
provide the same interface.  See L</INTERFACE> for details.

=head1 INTERFACE

=head2 new

C<new> should return a new object which implements the L</checktype_filename>
method described below.  The default implementation simply returns an empty,
blessed hash.

=head2 checktype_filename

Given a single, absolute filename as an argument, this method should return a
scalar with the MIME type of the file or C<undef> if there is an error.

