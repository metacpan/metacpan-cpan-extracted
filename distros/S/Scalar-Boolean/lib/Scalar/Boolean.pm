use strict;
use warnings;

# ABSTRACT: Makes scalar variables store Boolean values only
package Scalar::Boolean;

use base qw( Exporter );
our @EXPORT = qw(
  boolean
  bool   booleanise   booleanize
  unbool unbooleanise unbooleanize
);

my $use_variable_magic = 1;

eval { require Variable::Magic };
if ($@) {
    $use_variable_magic = 0;
}

if ($use_variable_magic) {
    require Scalar::Boolean::VM;

    *booleanise   = *Scalar::Boolean::VM::booleanise;
    *unbooleanise = *Scalar::Boolean::VM::unbooleanise;
}
else {
    require Scalar::Boolean::Tie;

    *booleanise   = *Scalar::Boolean::Tie::booleanise;
    *unbooleanise = *Scalar::Boolean::Tie::unbooleanise;
}

*bool   = *booleanize   = *booleanise;
*unbool = *unbooleanize = *unbooleanise;
*boolean = *Scalar::Boolean::Value::boolean;

1;



=pod

=head1 NAME

Scalar::Boolean - Makes scalar variables store Boolean values only

=head1 VERSION

version 1.02

=head1 SYNOPSIS

    use Scalar::Boolean;

    bool my $value;
    $value = [];       # $value gets set to 1
    $value = 'Perl';   # $value gets set to 1
    $value = '';       # $value gets set to 0
    $value = '0';      # $value gets set to 0
    $value = undef;    # $value gets set to 0
    $value = ();       # $value gets set to 0

    unbool $value;
    $value = 'foo';  # $value gets set to 'foo'

    boolean [];     # returns 1
    boolean undef;  # returns 0

=head1 METHODS

=head2 C<bool> or C<booleanise> or C<booleanize>

Accepts scalar variables which will be C<booleanise>d. Once C<booleanise>d,
the variable will convert all values that are assigned to it to their
corresponding Boolean values. No effect on already C<booleanise>d variables.

=head2 C<unbool> or C<unbooleanise> or C<unbooleanize>

Accepts scalar variables which will be C<unbooleanise>d if already
C<booleanise>d. No effect on not already C<booleanise>d variables.

=head2 C<boolean>

Accepts a single value and returns its boolean value without affecting its
original value.

=head1 PERFORMANCE

For performance reasons, Scalar::Boolean prefers L<Variable::Magic> if it is
installed, else uses L<Tie::Scalar> for magic.

=head1 ACKNOWLEDGEMENT

Many thanks to B<Eric Brine> (B<ikegami>) for suggesting several improvements, for
valuable suggestions and also for sending sample code. Thank you Eric! :-)

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

