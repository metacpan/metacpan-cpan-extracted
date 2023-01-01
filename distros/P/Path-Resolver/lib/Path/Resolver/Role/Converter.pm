package Path::Resolver::Role::Converter 3.100455;
# ABSTRACT: something that converts from one type to another
use Moose::Role;

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod Classes implementing the Converter role must provide three methods:
#pod
#pod =method input_type
#pod
#pod This method must return the type of input that's expected.
#pod
#pod =method output_type
#pod
#pod This method must return the type of input that's promised to be returned.
#pod
#pod =method convert
#pod
#pod This method performs the actual converstion.  It's passed an object of
#pod C<input_type> and returns an object of C<output_type>.
#pod
#pod =cut

requires 'input_type';
requires 'output_type';
requires 'convert';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Role::Converter - something that converts from one type to another

=head1 VERSION

version 3.100455

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
