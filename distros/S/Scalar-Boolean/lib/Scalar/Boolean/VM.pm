use strict;
use warnings;

package    #private
  Scalar::Boolean::VM;

use Variable::Magic qw( wizard cast dispell );

use Scalar::Boolean::Value;

sub fixer {
    my $ref = $_[0];
    $$ref =
      $$ref
      ? Scalar::Boolean::Value::true
      : Scalar::Boolean::Value::false;
}

my $wiz = wizard
  'set' => \&fixer,
  'get' => \&fixer;

sub booleanise {
    cast $_, $wiz for @_;
}

sub unbooleanise {
    dispell $_, $wiz for @_;
}

1;

__END__
=pod

=head1 NAME

Scalar::Boolean::VM

=head1 VERSION

version 1.02

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

