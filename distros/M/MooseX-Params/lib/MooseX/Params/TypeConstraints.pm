package MooseX::Params::TypeConstraints;
$MooseX::Params::TypeConstraints::VERSION = '0.011';
use strict;
use warnings;

use Moose::Util::TypeConstraints;
use MooseX::Params::Meta::TypeConstraint::Listable;
use List::Util 1.33 ();

my $registry = Moose::Util::TypeConstraints::get_type_constraint_registry;

$registry->add_type_constraint(
    MooseX::Params::Meta::TypeConstraint::Listable->new(
        name               => 'Array',
        package_defined_in => __PACKAGE__,
        parent =>
            Moose::Util::TypeConstraints::find_type_constraint('Ref'),
        listable => 1,
        constraint => sub { ref($_) eq 'ARRAY' },
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check = $type_parameter->_compiled_type_constraint;
            return sub {
                foreach my $x (@$_) {
                    ( $check->($x) ) || return;
                }
                1;
                }
        },
        inlined          => sub { 'ref(' . $_[1] . ') eq "ARRAY"' },
        inline_generator => sub {
            my $self           = shift;
            my $type_parameter = shift;
            my $val            = shift;

            'do {'
                . 'my $check = ' . $val . ';'
                . 'ref($check) eq "ARRAY" '
                    . '&& &List::Util::all('
                        . 'sub { ' . $type_parameter->_inline_check('$_') . ' }, '
                        . '@{$check}'
                    . ')'
            . '}';
        },
    )
);

$registry->add_type_constraint(
    MooseX::Params::Meta::TypeConstraint::Listable->new(
        name               => 'Hash',
        package_defined_in => __PACKAGE__,
        parent =>
            Moose::Util::TypeConstraints::find_type_constraint('Ref'),
        listable => 1,
        constraint => sub { ref($_) eq 'HASH' },
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check = $type_parameter->_compiled_type_constraint;
            return sub {
                foreach my $x ( values %$_ ) {
                    ( $check->($x) ) || return;
                }
                1;
                }
        },
        inlined          => sub { 'ref(' . $_[1] . ') eq "HASH"' },
        inline_generator => sub {
            my $self           = shift;
            my $type_parameter = shift;
            my $val            = shift;

            'do {'
                . 'my $check = ' . $val . ';'
                . 'ref($check) eq "HASH" '
                    . '&& &List::Util::all('
                        . 'sub { ' . $type_parameter->_inline_check('$_') . ' }, '
                        . 'values %{$check}'
                    . ')'
            . '}';
        },
    )
);

package # hide from Dist::Zilla::Plugin::PkgVersion
    Moose::Util::TypeConstraints;

my @NEW_PARAMETERIZABLE_TYPES
    = map { $registry->get_type_constraint($_) } qw[ScalarRef Array ArrayRef Hash HashRef Maybe];

no warnings 'redefine';
sub get_all_parameterizable_types {@NEW_PARAMETERIZABLE_TYPES}
use warnings 'redefine';

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Peter Shangov TODO invocant isa metaroles metarole multimethods sourcecode
backwards buildargs checkargs slurpy preprocess

=head1 NAME

MooseX::Params::TypeConstraints

=head1 VERSION

version 0.011

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
