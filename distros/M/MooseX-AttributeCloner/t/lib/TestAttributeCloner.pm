#############
# Created By: setitesuk
# Created On: 2009-11-06

package TestAttributeCloner;
use Moose;
use Carp;
use English qw{-no_match_vars};

with qw{MooseX::Getopt MooseX::AttributeCloner};

has q{attr1} => (isa => q{Str}, is => q{ro}, predicate => q{has_attr1});
has q{attr2} => (isa => q{Str}, is => q{ro}, required => 1);
has q{attr3} => (isa => q{Str}, is => q{ro});
has q{attr4} => (isa => q{Str}, is => q{ro});
has q{attr5} => (isa => q{Str}, is => q{ro});
has q{attr6} => (isa => q{Str}, is => q{ro});
has q{attr7} => (isa => q{Str}, is => q{ro});

has q{object_attr} => (isa => q{Object}, is => q{ro});
has q{hash_attr} => (isa => q{HashRef}, is => q{ro});
has q{array_attr} => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef',
        default => sub { [] },
        handles => {
            all_attrs    => 'elements',
            add_attr     => 'push',
            map_attrs    => 'map',
            filter_attrs => 'grep',
            find_attr    => 'first',
            get_attr     => 'get',
            join_attrs   => 'join',
            count_attrs  => 'count',
            has_attrs    => 'count',
            has_no_attrs => 'is_empty',
            sorted_attrs => 'sort',
        },
);
has q{Boolean} => (isa => q{Bool}, is => q{rw});
no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

TestAttributeCloner

=head1 VERSION

0.19

=head1 SYNOPSIS

=head1 DESCRIPTION

This is purely a test case class. Nothing in here should be considered production worthy! Use any of it at your own risk!

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

setitesuk

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Andy Brown (setitesuk@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
