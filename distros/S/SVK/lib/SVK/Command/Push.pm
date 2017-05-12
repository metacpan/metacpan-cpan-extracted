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
package SVK::Command::Push;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Smerge );
use SVK::XD;

sub options {
    ('f|from=s'         => 'from_path',
     'l|lump'           => 'lump',
     'C|check-only'     => 'check_only',
     'summary'		=> 'summary',
     'S|sign'	        => 'sign',
     'P|patch=s'        => 'patch',
     'verbatim'		=> 'verbatim',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;

    if (!$self->{from_path}) {
        $self->{from}++;
    }
    else {
        unshift @arg, $self->{from_path};
    }

    # "svk push -P" has the same effect as "svk push -l",
    # because incremental patches is not yet implemented.
    if ($self->{lump} or $self->{patch}) {
        $self->{log}++;
        $self->{message} = '';
        delete $self->{incremental};
    }
    else {
        $self->{incremental}++;
    }

    $self->SUPER::parse_arg (@arg);
}

1;

__DATA__

=head1 NAME

SVK::Command::Push - Move changes into another repository

=head1 SYNOPSIS

 push [DEPOTPATH | PATH]

=head1 OPTIONS

 -f [--from] PATH       : push from the specified path
 -l [--lump]            : merge everything into a single commit log
 -C [--check-only]      : try operation but make no changes
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 --verbatim             : verbatim merge log without indents and header

=head1 DESCRIPTION

This command is a wrapper around the C<smerge> subcommand. 

C<svk push> is exactly the same as running 

   svk smerge -If .

