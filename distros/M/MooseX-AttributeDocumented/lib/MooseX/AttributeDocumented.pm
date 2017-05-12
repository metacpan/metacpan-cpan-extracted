use 5.10.1;
use strict;
use warnings;

package MooseX::AttributeDocumented;

our $VERSION = '0.1003'; # VERSION
# ABSTRACT: Add Documented trait to all to attributes

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute => ['MooseX::AttributeDocumented::Meta::Attribute::Trait::Documented'],
    },
);

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeDocumented - Add Documented trait to all to attributes

=head1 VERSION

Version 0.1003, released 2015-01-18.

=head1 SYNOPSIS

    package The::Class;

    use Moose;
    use MooseX::AttributeDocumented;

    has gears => (
        is => 'ro',
        isa => 'Int',
        default => 21,
        documentation => 'Number of gears on the bike',
        documentation_order => 2,
    );
    has has_brakes => (
        is => 'ro',
        isa => 'Bool',
        default => 1,
        documentation => 'Does the bike have brakes?',
        documentation_alts => {
            0 => 'Hopefully a track bike',
            1 => 'Always nice to have',
        },
    );

=head1 DESCRIPTION

Adds the L<Documented|MooseX::AttributeDocumented> trait to all attributes in the class.

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=back

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
