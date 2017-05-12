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
package SVK::Editor::Serialize;
use strict;
use base 'SVK::Editor';

__PACKAGE__->mk_accessors(qw(cb_serialize_entry textdelta_threshold));

use SVK::Util qw(tmpfile slurp_fh);

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]+$/;
    my $baton;
    pop @arg if ref ($arg[-1]) =~ m/^(?:SVN::Pool|_p_apr_pool_t)$/;

    if ((my $baton_at = $self->baton_at ($func)) >= 0) {
	$baton = $arg[$baton_at];
    }
    else {
	$baton = 0;
    }

    my $ret = $func =~ m/^(?:add|open)/ ? ++$self->{batons} : undef;
    Carp::cluck unless defined $func;
    $self->cb_serialize_entry->([$ret, $func, @arg]);
    return $ret;
}

my $apply_textdelta_entry;

sub close_file {
    my ($self, $baton, $checksum) = @_;
    if (my $entry = $apply_textdelta_entry) {
	my $fh = $entry->[-1];
	close $fh;
	if (defined $self->textdelta_threshold && -s $fh->filename >= $self->textdelta_threshold) {
	    $entry->[-1] = $fh->filename;
	}
	else {
	    # it appears using $entry->[-1] = \$buf and open $entry->[-1]
	    # breaks in 5.8.4
	    my $buf = '';
	    open my ($svndiff), '>', \$buf or die $!;
	    open my $ifh, '<', $fh->filename or die $!;
	    slurp_fh($ifh, $svndiff);
	    unlink $fh->filename;
	    $entry->[-1] = \$buf;
	}
	$self->cb_serialize_entry->($entry);
	$apply_textdelta_entry = undef;
    }
    $self->cb_serialize_entry->([undef, 'close_file', $baton, $checksum]);
}

sub apply_textdelta {
    my ($self, $baton, @arg) = @_;
    pop @arg if ref ($arg[-1]) =~ m/^(?:SVN::Pool|_p_apr_pool_t)$/;
    my $svndiff = tmpfile('serial-svndiff-', UNLINK => 0);
    my $entry = [undef, 'apply_textdelta', $baton, @arg, $svndiff];
    $apply_textdelta_entry = $entry;
    return [SVN::TxDelta::to_svndiff($svndiff)];
}


1;
