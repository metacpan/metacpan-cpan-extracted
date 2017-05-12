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
package SVK::Editor::Delay;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

require SVN::Delta;
use base 'SVK::Editor::ByPass';

sub _open_pbaton {
    my ($self, $pbaton, $func) = @_;
    my $baton;

    $func = "SUPER::open_$func";
    unless ($self->{opened}{$pbaton}) {
	my ($path, $ppbaton, @arg) = @{$self->{batoninfo}{$pbaton}};
	$self->{batons}{$pbaton} = $self->$func
	    ($path, $self->_open_pdir ($ppbaton), @arg);
	$self->{opened}{$pbaton} = 1;
    }

    return $self->{batons}{$pbaton};
}

sub _close_baton {
    my ($self, $func, $baton, @arg) = @_;
    $func = "SUPER::close_$func";
    if ($self->{opened}{$baton}) {
	$self->$func ($self->{batons}{$baton}, @arg);
	delete $self->{opened}{$baton};
    }
    delete $self->{batons}{$baton};
    delete $self->{batoninfo}{$baton};
}

sub _open_pdir { _open_pbaton (@_, 'directory') }
sub _open_file { _open_pbaton (@_, 'file') }

sub open_root {
    my ($self, @arg) = @_;
    $self->{nbaton} = 0;
    $self->{batons}{$self->{nbaton}} = $self->SUPER::open_root (@arg);
    $self->{opened}{$self->{nbaton}} = 1;
    return $self->{nbaton}++;
}

sub add_file {
    my ($self, $path, $pbaton, @arg) = @_;
    my $baton = $self->SUPER::add_file ($path, $self->_open_pdir ($pbaton), @arg);
    $self->{batons}{$self->{nbaton}} = $baton;
    $self->{opened}{$self->{nbaton}} = 1;
    return $self->{nbaton}++;
}

sub open_file {
    my ($self, $path, $pbaton, @arg) = @_;
    $self->{batoninfo}{$self->{nbaton}} = [$path, $pbaton, @arg];
    return $self->{nbaton}++;
}

sub apply_textdelta {
    my ($self, $baton, @arg) = @_;
    return $self->SUPER::apply_textdelta ($self->_open_file ($baton), @arg);
}

sub change_file_prop {
    my ($self, $baton, @arg) = @_;
    return $self->SUPER::change_file_prop ($self->_open_file ($baton), @arg);
}

sub close_file {
    my $self = shift;
    $self->_close_baton ('file', @_);
}

sub add_directory {
    my ($self, $path, $pbaton, @arg) = @_;
    my $baton = $self->SUPER::add_directory ($path, $self->_open_pdir ($pbaton), @arg);
    $self->{batons}{$self->{nbaton}} = $baton;
    $self->{opened}{$self->{nbaton}} = 1;
    return $self->{nbaton}++;
}

sub delete_entry {
    my ($self, $path, $rev, $pbaton, $pool) = @_;
    $self->SUPER::delete_entry ($path, $rev, $self->_open_pdir ($pbaton), $pool);
}

sub change_dir_prop {
    my ($self, $baton, @arg) = @_;
    $self->SUPER::change_dir_prop ($self->_open_pdir ($baton), @arg);
}

sub open_directory {
    my ($self, $path, $pbaton, @arg) = @_;
    $self->{batoninfo}{$self->{nbaton}} = [$path, $pbaton, @arg];
    return $self->{nbaton}++;
}

sub close_directory {
    my $self = shift;
    $self->_close_baton ('directory', @_);
}

1;

