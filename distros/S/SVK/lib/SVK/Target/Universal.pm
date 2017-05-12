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
package SVK::Target::Universal;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(uuid path rev));

=head1 NAME

SVK::Target::Universal - svk target that might not be local

=head1 SYNOPSIS

 $target = SVK::Target::Universal->new($uuid, $path, $rev);
 $local_target = $target->local($depot);

=cut

sub new {
    my $class = shift;
    my ($uuid, $path, $rev) = @_;
    $class->SUPER::new( { uuid => $uuid,
                          path => $path,
                          rev  => $rev } );
}

sub local {
    my ($self, $depot) = @_;

    my ($path, $rev) = $self->{uuid} ne $depot->repos->fs->get_uuid ?
	$depot->find_local_mirror(@{$self}{qw/uuid path rev/}) :
	@{$self}{qw/path rev/};

    # $rev can be undefined even if $path is defined.  This is the case
    # that you have a out-of-date mirror of something with a newer merge
    # ticket
    return unless defined $path && defined $rev;

    SVK::Path->real_new
	({ depot => $depot,
	   mirror => $depot->mirror,
	   path => $path, # XXX: use path_anchor accessor
	   revision => $rev,
	 });
}

sub same_resource {
    my ($self, $other) = @_;
    return ($self->uuid eq $other->uuid && $self->path eq $other->path);
}

sub ukey {
    my $self = shift;
    return join(':', $self->uuid, $self->path);
}


1;
