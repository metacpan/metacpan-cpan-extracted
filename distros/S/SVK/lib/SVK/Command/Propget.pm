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
package SVK::Command::Propget;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use SVK::Logger;
use base qw( SVK::Command::Proplist );
use constant opt_recursive => 0;
use SVK::XD;

sub options {
    ('strict' => 'strict',
     'r|revision=i' => 'rev',
     'revprop' => 'revprop',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if @arg < 1;
    push @arg, '' if @arg == 1;
    return ($arg[0], map { $self->_arg_revprop ($_) } @arg[1..$#arg]);
}

sub run {
    my ( $self, $pname, @targets ) = @_;

    my $errs = [];
    $self->run_command_recursively(
        $_,
        sub {
            my $target   = shift;
            my $proplist = $self->_proplist($target);
            exists $proplist->{$pname} or return;

	    if ( $self->{strict} ) {
		print $proplist->{$pname};
	    } else { # !self->{strict}
		if ( $self->{recursive} || @targets > 1 ) {
		    $logger->info( $target->report, ' - ', $proplist->{$pname}, "\n" );
		} else {
		    $logger->info( $proplist->{$pname}, "\n" );
		}
	    }
        }, $errs, 0,
    ) for @targets;

    return scalar @$errs;
}

1;

__DATA__

=head1 NAME

SVK::Command::Propget - Display a property on path

=head1 SYNOPSIS

 propget PROPNAME [DEPOTPATH | PATH...]

=head1 OPTIONS

 -R [--recursive]       : descend recursively
 -r [--revision] REV    : act on revision REV instead of the head revision
 --revprop              : operate on a revision property (use with -r)
 --strict               : do not print an extra newline at the end of the
                          property values; when there are multiple paths
                          involved, do not prefix path names before values

