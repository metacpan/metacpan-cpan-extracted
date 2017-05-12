use 5.10.1;
use strict;
use warnings;

package MooseX::AttributeDocumented::Meta::Attribute::Trait::Documented;

our $VERSION = '0.1003'; # VERSION
# ABSTRACT: Add documentation to attributes

use Moose::Role;
#Moose::Util::meta_attribute_alias('Documented');
use MooseX::Types::Moose qw/HashRef Str Int/;
use namespace::clean -except => 'meta';

has documentation_alts => (
    is => 'rw',
    isa => HashRef,
    predicate => 'has_documentation_alts',
);

has documentation_default => (
    is => 'rw',
    isa => Str,
    predicate => 'has_documentation_default',
);

has documentation_order => (
    is => 'rw',
    isa => Int,
    default => 1000,
    predicate => 'has_documentation_order',
);

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeDocumented::Meta::Attribute::Trait::Documented - Add documentation to attributes

=head1 VERSION

Version 0.1003, released 2015-01-18.

=head1 SYNOPSIS

    use Moose;

    has gears => (
        is => 'ro',
        isa => 'Int',
        default => 21,
        traits => ['Documented'],
        documentation => 'Number of gears on the bike',
        documentation_order => 2,
    );
    has has_brakes => (
        is => 'ro',
        isa => 'Bool',
        default => 1,
        traits => ['Documented'],
        documentation => 'Does the bike have brakes?',
        documentation_alts => {
            0 => 'Hopefully a track bike',
            1 => 'Always nice to have',
        },
    );
    has undocumented_attr => (
        is => 'ro',
        isa => Str,
        default => 'other',
    );

=head1 DESCRIPTION

L<Moose> already has C<documentation>, this trait adds the following to the attribute specification:

=head2 documentation_alts

A hash reference. Describe the effect of different values, eg. on booleans.

=head2 documentation_default

A string. If the default value is a code ref you can describe it in this field.

=head2 documentation_order

An integer. Defaults to C<1000>.

=head1 SOURCE

L<https://github.com/Csson/p5-MooseX-AttributeDocumented>

=head1 HOMEPAGE

L<https://metacpan.org/release/MooseX-AttributeDocumented>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
