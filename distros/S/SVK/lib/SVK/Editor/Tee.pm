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
package SVK::Editor::Tee;
use strict;
use base 'SVK::Editor';
use List::MoreUtils qw(any);

__PACKAGE__->mk_accessors(qw(editors baton_maps));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->baton_maps({});
    $self->{batons} = 0;
    return $self;
}

sub run_editors { # if only we have zip..
    my ($self, $baton, $callback) = @_;
    my $i = 0;
    my @ret;
    for (@{$self->editors}) {
	push @ret, scalar $callback->($_, defined $baton ? $self->baton_maps->{$baton}[$i++] : undef);
    }
    return \@ret;
}

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]+$/;
    my $baton;
    my $baton_at = $self->baton_at($func);
    $baton = $arg[$baton_at] if $baton_at >= 0;

    my $rets = $self->run_editors
	( $baton,
	  sub { my ($editor, $baton) = @_;
		$arg[$baton_at] = $baton if defined $baton;
		$editor->$func(@arg);
	    });

    if ($func =~ m/^close_(?:file|directory)/) {
	delete $self->baton_maps->{$baton};
	delete $self->{baton_pools}{$baton};
    }

    if ($func =~ m/^(?:add|open)/) {
	$self->baton_maps->{++$self->{batons}} = $rets;
	return $self->{batons};
    }

    return;
}


sub window_handler {
    my ($self, $handlers, $window) = @_;
    for (@$handlers) {
	next unless $_;
	SVN::TxDelta::invoke_window_handler($_->[0], $window, $_->[1]);
    }
}

#my $pool = SVN::Pool->new;
sub apply_textdelta {
    my ($self, $baton, @arg) = @_;
    my $rets = $self->run_editors($baton,
				  sub { my ($editor, $baton) = @_;
					unless ($baton) {
					    use Data::Dumper;
					}
					$editor->apply_textdelta($baton, @arg);
				    });

    if (any { defined $_ } @$rets) {
	my $foo = sub { $self->window_handler($rets, @_) };
	my $pool = $self->{baton_pools}{$baton} = SVN::Pool->new;
	return [SVN::Delta::wrap_window_handler($foo, $pool)];
    }

    return;
}


1;
