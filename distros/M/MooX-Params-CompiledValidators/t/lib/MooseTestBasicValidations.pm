package MooseTestBasicValidations;
use Moose;

extends 'TestBasicValidations';

use namespace::autoclean;
1;

=head1 NAME

MooseTestBasicValidations - Test module for basic validations

=head1 SYNOPSIS

    use Moose;
    extends 'MooseTestBasicValidations';

    use namespace::autoclean;
    1;

=head1 DESCRIPTION

This is a test class. It shows that the C<ValidationTemplates()> can come from a
I<Role> so one can ensure consistent parameter validation. For cases where
interface consistency is more important than validation rules, those templates
can also be local to the class.

This L<Moose> module C<extends()> the basic L<Moo> module for the tests, no
extra extra code.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

=cut
