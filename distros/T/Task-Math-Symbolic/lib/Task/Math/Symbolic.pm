package Task::Math::Symbolic;

use strict;

our $VERSION = '1.01';

=head1 NAME

Task::Math::Symbolic - Math::Symbolic with lots of plugins

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Task::Math::Symbolic'>

=head1 DESCRIPTION

This installs Math::Symbolic and a load of easily installable (i.e. pure Perl)
plugins that make the module so much more powerful.

L<Math::Symbolic> - The base module

L<Math::Symbolic::Custom::Contains> - Extension for finding subtrees

L<Math::Symbolic::Custom::ErrorPropagation> - Extension for Gaussian Error Propagation

L<Math::Symbolic::Custom::Pattern> - Pattern matching on Math::Symbolic trees

L<Math::Symbolic::Custom::Simplification> - User defined simplification routines

L<Math::Symbolic::Custom::Transformation> - Transformations using Math::Symbolic trees

L<Math::SymbolicX::BigNum> - Big number support for the Math::Symbolic parser

L<Math::SymbolicX::Complex> - Complex number support for the Math::Symbolic parser

L<Math::SymbolicX::Inline> - Inlined Math::Symbolic functions

L<Math::SymbolicX::NoSimplification> - Turns of Math::Symbolic simplification

L<Math::SymbolicX::ParserExtensionFactory> - Generates parser extensions such as Math::SymbolicX::Complex.

L<Math::SymbolicX::Statistics::Distributions> - Implementation of some statistical distributions

=head1 AUTHOR

Steffen Mueller, C<symbolic-module at steffen-mueller dot net>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
