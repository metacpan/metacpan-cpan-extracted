package Path::Resolver::Role::Converter;
{
  $Path::Resolver::Role::Converter::VERSION = '3.100454';
}
# ABSTRACT: something that converts from one type to another
use Moose::Role;

use namespace::autoclean;


requires 'input_type';
requires 'output_type';
requires 'convert';

1;

__END__

=pod

=head1 NAME

Path::Resolver::Role::Converter - something that converts from one type to another

=head1 VERSION

version 3.100454

=head1 METHODS

=head2 input_type

This method must return the type of input that's expected.

=head2 output_type

This method must return the type of input that's promised to be returned.

=head2 convert

This method performs the actual converstion.  It's passed an object of
C<input_type> and returns an object of C<output_type>.

=head1 IMPLEMENTING

Classes implementing the Converter role must provide three methods:

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
