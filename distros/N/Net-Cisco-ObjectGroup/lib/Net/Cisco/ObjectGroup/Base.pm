package Net::Cisco::ObjectGroup::Base;
use base qw(Class::Data::Inheritable);
use base qw(Class::Accessor::Fast);

use strict;
use warnings FATAL => qw(all);

use Symbol;
use Carp;

__PACKAGE__->mk_classdata('__dict');

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw( type name desc objs ));

sub _init {
    my $self    = shift;
    my $arg_ref = shift;

    return $self unless $arg_ref->{pretty_print};
    my $pkg = ref $self;

    if (!defined $pkg->__dict) {
        $pkg->__dict( {} );

        my $data = Symbol::qualify_to_ref('DATA', $pkg);
        while (my $line = <$data>) {
            next if $line =~ m/^#/;
            next if $line !~ m/:/;

            $line =~ m/^\s*([0-9]+)\s*:\s*([a-z0-9-]{2,})\s*$/;
            if (defined $1 and defined $2) {
                $pkg->__dict->{$1} = $2;
            }
            else {
                # pretty printing is nice but not essential,
                # so just continue if there is some kind of error.
                chomp $line;
                carp "syntax error in __DATA__ portion of $pkg: '$line'";
                next;
            }
        }
    }

    return $self;
}

sub push {
    croak 'attempt to call push() in base class';
}

sub dump {
    my $self = shift;
    my $output;

    $output .= sprintf "object-group %s %s\n",
        $self->get_type, $self->get_name;

    $output .= sprintf "  description %s\n",
        $self->get_desc if defined $self->get_desc;

    $output .= join "\n", map {'  '. $_} @{$self->get_objs};

    chomp $output;
    return $output;
}

1;

# Copyright (c) The University of Oxford 2006. All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
