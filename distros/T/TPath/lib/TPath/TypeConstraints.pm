package TPath::TypeConstraints;
$TPath::TypeConstraints::VERSION = '1.007';
# ABSTRACT: assorted type constraints

use Moose::Util::TypeConstraints;
use TPath::Grammar qw(%AXES);

sub prefix(@);

class_type $_
  for prefix qw(Attribute Expression AttributeTest Math Function Concatenation);

role_type $_
  for prefix qw(Test::Boolean Selector Forester Predicate Numifiable);

union ATArg => [qw( Num TPath::Numifiable Str TPath::Concatenation )];

union CondArg =>
  [ prefix qw(Attribute Expression AttributeTest Test::Boolean) ];

union ConcatArg =>
  [ qw( Num Str ), prefix qw( Attribute Expression Math ) ];

union MathArg => [qw(TPath::Numifiable Num)];

enum Quantifier => [qw( * + ? e )];

enum Axis => [ keys %AXES ];

sub prefix(@) {
    map { "TPath::$_" } @_;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::TypeConstraints - assorted type constraints

=head1 VERSION

version 1.007

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
