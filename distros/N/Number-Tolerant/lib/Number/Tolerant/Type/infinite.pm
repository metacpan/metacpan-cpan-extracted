use strict;
use warnings;
# ABSTRACT: an infinite tolerance

package
  Number::Tolerant::Type::infinite;
use parent qw(Number::Tolerant::Type);

sub construct { shift; { value => 0 } }

sub parse {
  my ($self, $string, $factory) = @_;
  return $factory->new('infinite') if $string =~ m!\Aany\s+number\z!;
  return;
}

sub valid_args { shift;
  return ($_[0]) if @_ == 1 and defined $_[0] and $_[0] eq 'infinite';
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::infinite - an infinite tolerance

=head1 VERSION

version 1.708

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
