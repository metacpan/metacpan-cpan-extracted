use strict;
use warnings;

package    #private
  Scalar::Boolean::Tie;

use Tie::Scalar;
use base qw( Tie::StdScalar );

use Scalar::Boolean::Value;

sub STORE {
    my ( $ref, $value ) = @_;
    $$ref =
      $value
      ? Scalar::Boolean::Value::true
      : Scalar::Boolean::Value::false;
    return;
}

sub TIESCALAR {
    my ( $class, $value ) = @_;
    $value =
      $value
      ? Scalar::Boolean::Value::true
      : Scalar::Boolean::Value::false;
    return bless \$value, $class;
}

sub booleanise(\$;\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$) {
    tie $$_, __PACKAGE__, $$_ for @_;
    return;
}

sub unbooleanise(\$;\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$) {
    untie $$_ for @_;
    return;
}

1;

__END__
=pod

=head1 NAME

Scalar::Boolean::Tie

=head1 VERSION

version 1.02

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

