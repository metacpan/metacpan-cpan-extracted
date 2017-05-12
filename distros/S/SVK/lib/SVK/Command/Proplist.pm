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
package SVK::Command::Proplist;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 0;
use SVK::XD;
use SVK::I18N;
use SVK::Logger;

sub options {
    ('v|verbose' => 'verbose',
     'r|revision=i' => 'rev',
     'revprop' => 'revprop',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;

    @arg = ('') if $#arg < 0;
    return map { $self->_arg_revprop ($_) } @arg;
}

sub run {
    my ( $self, @arg ) = @_;
    if ( $self->{revprop} ) {
        die loc("Revision required.\n")
            unless defined $self->{rev};

        for my $target (@arg) {
            $self->_show_props( $target,
                $target->repos->fs->revision_proplist( $self->{rev} ),
                $self->{rev} );
        }
        return;

    }

    $self->run_command_recursively(
        $_,
        sub {
            my $target = shift;
            $target = $target->as_depotpath( $self->{rev} )
                if defined $self->{rev};
            $self->_show_props( $target,
                $target->root->node_proplist( $target->path ) );
        }
    ) for @arg;

    return;
}

sub _show_props {
    my ($self, $target, $props, $rev) = @_;

    %$props or return;

    if ($self->{revprop}) {
        $logger->info( loc("Unversioned properties on revision %1:\n", $rev));
    }
    else {
        $logger->info( loc("Properties on %1:\n", length $target->report ? $target->report : '.'));
    }

    for my $key (sort keys %$props) {
        my $value = $props->{$key};
        $logger->info( $self->{verbose} ? "  $key: $value\n" : "  $key\n");
    }
}

sub _arg_revprop {
    my $self = $_[0];
    goto &{$self->can($self->{revprop} ? 'arg_depotroot' : 'arg_co_maybe')};
}

sub _proplist {
    my ($self, $target) = @_;

    return $target->repos->fs->revision_proplist($self->{rev})
	if $self->{revprop};

    if (defined $self->{rev}) {
        $target = $target->as_depotpath ($self->{rev});
    }
    return $target->root->node_proplist($target->path);
}


1;

__DATA__

=head1 NAME

SVK::Command::Proplist - List all properties on files or dirs

=head1 SYNOPSIS

 proplist PATH...

=head1 OPTIONS

 -R [--recursive]       : descend recursively
 -v [--verbose]         : print extra information
 -r [--revision] REV    : act on revision REV instead of the head revision
 --revprop              : operate on a revision property (use with -r)

