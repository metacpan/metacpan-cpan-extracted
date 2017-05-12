#
# This file is part of MooseX-CascadeClearing
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::CascadeClearing;
{
  $MooseX::CascadeClearing::VERSION = '0.05';
}

# ABSTRACT: Cascade clearer actions across attributes

use warnings;
use strict;

use namespace::autoclean;
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use Carp;

# debugging
#use Smart::Comments '###', '####';

Moose::Exporter->setup_import_methods(
    trait_aliases => [
        [ 'MooseX::CascadeClearing::Role::Meta::Attribute' => 'CascadeClearing' ],
    ],
    class_metaroles => {
        attribute => [
            'MooseX::CascadeClearing::Role::Meta::Attribute',
        ],
    },
    role_metaroles => {
        applied_attribute => [
            'MooseX::CascadeClearing::Role::Meta::Attribute',
        ],
    },
);

{
    package MooseX::CascadeClearing::Role::Meta::Attribute;
{
  $MooseX::CascadeClearing::Role::Meta::Attribute::VERSION = '0.05';
}
    use namespace::autoclean;
    use Moose::Role;

    has clear_master    => (is => 'rw', isa => 'Str', predicate => 'has_clear_master');
    has is_clear_master => (is => 'rw', isa => 'Bool', default => 0);

    after install_accessors => sub {
        my ($self, $inline) = @_;

        ### in install_accessors, installing if: $self->is_clear_master
        return unless $self->is_clear_master;


        my $clearer = $self->clearer;
        my $name    = $self->name;
        my $att     = $self; # right??

        confess "clear_master attribute '$name' MUST have a clearer defined!"
            unless $self->has_clearer;

        ### installing master clearer...
        $self->associated_class->add_after_method_modifier($self->clearer, sub {
            my $self = shift @_;

            ### in clear_value...
            return unless $att->is_clear_master;

            ### looping over our attributes...
            my @attributes = $self->meta->get_all_attributes;

            for my $attr (@attributes) {

                ### working on: $attr->name
                # ->does() seems to be giving us weird results
                if ($attr->can('clear_master')
                    && $attr->has_clear_master
                    && $attr->clear_master eq $name) {

                    ### clearing...
                    if (my $clearer = $attr->clearer) { $self->$clearer }
                    else { $attr->clear_value($self)                    }
                }
            }
        });
    };
}

# can we prevent the clearer from being inlined?  Do we need to?  Are we?

1;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

MooseX::CascadeClearing - Cascade clearer actions across attributes

=head1 VERSION

This document describes version 0.05 of MooseX::CascadeClearing - released September 15, 2012 as part of MooseX-CascadeClearing.

=head1 SYNOPSIS

    use Moose;
    use MooseX::CascadeClearing;

    has master => (
        is              => 'rw',
        isa             => 'Str',
        lazy_build      => 1,
        is_clear_master => 1,
    );

    my @opts => (
        is           => 'ro',
        isa          => 'Str',
        clear_master => 'master',
        lazy_build   => 1,
    );

    has sub1 => @opts;
    has sub2 => @opts;
    has sub3 => @opts;

    sub _build_sub1 { shift->master . "1" }
    sub _build_sub2 { shift->master . "2" }
    sub _build_sub3 { shift->master . "3" }

    sub some_sub {
        # ...

        # clear master, sub[123] in one fell swoop
        $self->clear_master;

    }

=head1 DESCRIPTION

MooseX::CascadeClearing does the necessary metaclass fiddling to allow an
clearing one attribute to be cascaded through to other attributes as well,
calling their clear accessors.

The intended purpose of this is to assist in situations where the value of one
attribute is derived from the value of another attribute -- say a situation
where the secondary value is expensive to derive and is thus lazily built.  A
change to the primary attribute's value would invalidate the secondary value
and as such the secondary should be cleared.  While it could be argued that
this is trivial to do manually for a few attributes, once we consider
subclassing and adding in roles the ability to "auto-clear", as it were, is
a valuable trait.  (Sorry, couldn't resist.)

=for Pod::Coverage init_meta

=head1 CAVEAT

We don't yet trigger a cascade clear on a master attribute's value being set
through a setter/accessor accessor.  This will likely be available as an
option in the not-too-distant-future.

=head1 ATTRIBUTE OPTIONS

We install an attribute metaclass trait that provides two additional
attribute options, as well as wraps the generated clearer method for a
designated "master" attribute.  By default, using this module causes this
trait to be installed for all attributes in the package.

=over 4

=item is_clear_master => (0|1)

If set to 1, we wrap this attribute's clearer with a sub that looks for other
attributes to clear.

=item clear_master => < attribute_name >

Marks this attribute as one that should be cleared when the named attribute's
clearer is called.  Note that no checking is done to ensure that the named
master is actually an attribute in the class.

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/moosex-cascadeclearing>
and may be cloned from L<git://github.com/RsrchBoy/moosex-cascadeclearing.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-cascadeclearing/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
