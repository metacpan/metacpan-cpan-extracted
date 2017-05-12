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
package SVK::Command::Pull;
use strict;
use warnings;

use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Update );
use SVK::XD;

sub options {
   ('a|all'		=> 'all',
    'force-incremental' => 'force_incremental',
    'no-sync'       => 'no_sync',
    'l|lump'		=> 'lump');
}

sub parse_arg {
    my ($self, @arg) = @_;

    @arg = ('') if $#arg < 0;

    # -- XXX -- will break otherwise -- XXX ---
    # (Possibly fixed now, so we'll add an undocumented option to override
    # this, to enable testing.)
    $self->{lump} = 1 unless $self->{force_incremental};
    $self->{incremental} = !$self->{lump};

    if ($self->{all}) {
        my $checkout = $self->{xd}{checkout}{hash};
        @arg = sort grep $checkout->{$_}{depotpath}, keys %$checkout;
    } 
    elsif ( @arg == 1 and !$self->arg_co_maybe($arg[0])->isa('SVK::Path::Checkout')) {
        # If the last argument is a depot path, rather than a copath
        # then we should do a merge to the local depot, rather than 
        # an update to the path
        return $self->rebless (
            smerge => {
                to => 1,
                log => 1,
                message => '',
            }
        )->parse_arg (@arg);
    }


    $self->{sync}++ unless $self->{'no_sync'};
    $self->{merge}++;

    $self->SUPER::parse_arg (@arg);
}

1;

__DATA__

=head1 NAME

SVK::Command::Pull - Bring changes from another repository

=head1 SYNOPSIS

 pull [PATH...]

    Update your local branch and checkout path from the remote
    master repository.

 pull DEPOTPATH

    Update your local branch from the remote master repository.

=head1 OPTIONS

 -a [--all]             : pull into all checkout paths
 -l [--lump]            : merge everything into a single commit log
                          (always enabled by default for now)

