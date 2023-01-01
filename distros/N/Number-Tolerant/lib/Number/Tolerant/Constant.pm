use strict;
use warnings;
package Number::Tolerant::Constant 1.710;
# ABSTRACT: a blessed constant type

#pod =head1 SYNOPSIS
#pod
#pod  use Number::Tolerant;
#pod  use Number::Tolerant::Constant;
#pod
#pod  my $range  = tolerance(10);
#pod  ref $range; # "Number::Tolerant" -- w/o ::Constant, would be undef
#pod
#pod =head1 DESCRIPTION
#pod
#pod When Number::Tolerant is about to return a tolerance with zero variation, it
#pod will return a constant instead.  This module will register a constant type that
#pod will catch these constants and return them as Number::Tolerant objects.
#pod
#pod I wrote this module to make it simpler to use tolerances with Class::DBI, which
#pod would otherwise complain that the constructor hadn't returned a blessed object.
#pod
#pod =cut

package
  Number::Tolerant::Type::constant_obj;
use parent qw(Number::Tolerant::Type);

sub construct { shift;
  { value => $_[0], min => $_[0], max => $_[0], constant => 1 }
};

sub parse {
  my ($self, $string, $factory) = @_;
  my $number = $self->number_re;
  return $factory->new($string) if ($string =~ m!\A($number)\z!);
  return;
}

sub numify { $_[0]->{value} }

sub stringify { "$_[0]->{value}" }

sub valid_args {
  my $self = shift;
  my $number = $self->normalize_number($_[0]);

  return unless defined $number;

  return $number if @_ == 1;

  return;
}

package Number::Tolerant::Constant;

sub import {
  Number::Tolerant->disable_plugin("Number::Tolerant::Type::constant");
  Number::Tolerant->enable_plugin( "Number::Tolerant::Type::constant_obj");
}

sub _disable {
  Number::Tolerant->disable_plugin("Number::Tolerant::Type::constant_obj");
  Number::Tolerant->enable_plugin( "Number::Tolerant::Type::constant");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Constant - a blessed constant type

=head1 VERSION

version 1.710

=head1 SYNOPSIS

 use Number::Tolerant;
 use Number::Tolerant::Constant;

 my $range  = tolerance(10);
 ref $range; # "Number::Tolerant" -- w/o ::Constant, would be undef

=head1 DESCRIPTION

When Number::Tolerant is about to return a tolerance with zero variation, it
will return a constant instead.  This module will register a constant type that
will catch these constants and return them as Number::Tolerant objects.

I wrote this module to make it simpler to use tolerances with Class::DBI, which
would otherwise complain that the constructor hadn't returned a blessed object.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
