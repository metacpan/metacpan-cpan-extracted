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
package SVK::Accessor;
use strict;

use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Storable;

__PACKAGE__->mk_classdata('_shared_accessors');
__PACKAGE__->mk_classdata('_clonable_accessors');

sub mk_shared_accessors {
    my $class = shift;
    $class->mk_accessors(@_);
    my $fun =  $class->SUPER::can('_shared_accessors');
    no strict 'refs';
    unless (${$class.'::_shared_accessors_init'}) {
	my $y = $fun->($class) || [];
	$class->_shared_accessors(Storable::dclone($y));
	${$class.'::_shared_accessors_init'} = 1;
    }

    push @{$class->_shared_accessors}, @_;
}

sub mk_clonable_accessors {
    my $class = shift;
    $class->mk_accessors(@_);
    my $fun =  $class->SUPER::can('_clonable_accessors');
    no strict 'refs';
    unless (${$class.'::_clonable_accessors_init'}) {
	my $y = $fun->($class) || [];
	$class->_clonable_accessors(Storable::dclone($y));
	${$class.'::_clonable_accessors_init'} = 1;
    }

    push @{$class->_clonable_accessors}, @_;
}

sub clonable_accessors {
    my $self = shift;
    return (@{$self->_clonable_accessors});
}

sub shared_accessors {
    my $self = shift;
    return (@{$self->_shared_accessors});
}


sub real_new {
    my $self = shift;
    $self->SUPER::new(@_);
}

sub new {
    my ($self, @arg) = @_;
    Carp::cluck "bad usage" unless ref($self);

    return $self->mclone(@arg);
}

sub clone {
    my ($self) = @_;

    my $cloned = ref($self)->real_new;
    for my $key ($self->shared_accessors) {
	$cloned->$key($self->$key);
    }
    for my $key ($self->clonable_accessors) {
        next if $key =~ m/^_/;
	Carp::cluck unless $self->can($key);
	my $value = $self->$key;
	if (UNIVERSAL::can($value, 'clone')) {
	    $cloned->$key($value->clone);
	}
	else {
	    $cloned->$key(ref $value ? Storable::dclone($value) : $value);
	}
    }
    return $cloned;
}

sub mclone {
    my $self = shift;
    my $args = ref($_[0]) ? $_[0] : { @_ };
    my $cloned = $self->clone;
    for my $key (keys %$args) {
	Carp::cluck unless $cloned->can($key);
	$cloned->$key($args->{$key});
    }
    return $cloned;
}

1;

