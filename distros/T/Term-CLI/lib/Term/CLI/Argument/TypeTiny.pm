#=============================================================================
#
#       Module:  Term::CLI::Argument::TypeTiny
#
#  Description:  Class for Type::Tiny validated arguments in Term::CLI
#
#       Author:  Diab Jerius (DJERIUS), <djerius@cpan.org>
#      Created:  16/Apr/2022
#
#   Copyright (c) 2022 Diab Jerius, Smithsonian Astrophysical Observatory
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument::TypeTiny 0.058002;

use Types::Standard 1.000005 qw(
  Bool
  InstanceOf
);

use Moo 1.000001;

use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has coerce => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has typetiny => (
    is       => 'ro',
    isa      => InstanceOf ['Type::Tiny'],
    required => 1,
);

sub validate {
    my ( $self, $value ) = @_;

    $value = $self->typetiny->coerce( $value ) if $self->coerce;
    my $error = $self->typetiny->validate( $value ) // return $value;
    return $self->set_error( $error );
}


1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::TypeTiny - class for Type::Tiny validated arguments in Term::CLI

=head1 VERSION

version 0.058002

=head1 SYNOPSIS

 use Term::CLI::Argument::TypeTiny;
 use Types::Standard qw( ArrayRef Split );
 use Types::Common::String qw( NonEmptyStr );

 # accept a comma separated list of strings, split them and return an array
 my $arg = Term::CLI::Argument::TypeTiny->new(
     name => 'arg1',
     typetiny => ArrayRef->of(NonEmptyStr)->plus_coercions(Split[qr/,/]),
     coerce => 1,
 );


=head1 DESCRIPTION

Class for Type::Tiny validated arguments in L<Term::CLI|Term::CLI>(3p).

This class inherits from
the L<Term::CLI::Argument|Term::CLI::Argument>(3p) class.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument|Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new>

    OBJ = Term::CLI::Argument::TypeTiny(
        name         => STRING,
        typetiny     => InstanceOf['Type::Tiny'],
        coerce       => Bool,
    );

See also L<Term::CLI::Argument|Term::CLI::Argument>(3p).  The B<typetiny>
argument is mandatory and must be a L<Type::Tiny|Type::Tiny>(3p) object. It
will be used to validate values.

If B<coerce> is true, L<validate|/validate> will call the
L<Type::Tiny|Type::Tiny> object's coercion method to coerce the input value.

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument|Term::CLI::Argument>(3p).

=over

=item B<typetiny>

The L<Type::Tiny|Type::Tiny> object which will validate values.

=item B<coerce>

Boolean that indicates whether L<validate|/validate> will call the
L<Type::Tiny|Type::Tiny> object's coercion method to coerce the input value.

=back

=head1 METHODS

See also L<Term::CLI::Argument|Term::CLI::Argument>(3p).

The following methods are added or overloaded:

=over

=item B<validate>

Overloaded from L<Term::CLI::Argument|Term::CLI::Argument>(3p).

=back

=head1 EXAMPLES

=over

=item * 

Only allow positive or zero numbers for # of zombies seen.
Allow non integers, in case they've lost bits and pieces:

    use Types::Common::Numeric qw( PositiveOrZeroNum);
    my $arg = Term::CLI::Argument::TypeTiny(
        name => 'zombies',
        typetiny => PositiveOrZeroNum
    );

=item *

Accept a URI, convert to a L<URI|URI> object:

    use Types::URI 'URI';
    my $arg = Term::CLI::Argument::TypeTiny(
        name => 'uri',
        typetiny => URI,
        coerce => 1
    );

=item *

Accept a file which must exist, convert to a L<Path::Tiny|Path::Tiny>
object:

    use Types::Path::Tiny 'File';
    my $arg = Term::CLI::Argument::TypeTiny(
        name => 'file',
        typetiny => File,
        coerce => 1
    );

=back

=head1 SEE ALSO

L<Term::CLI::Argument|Term::CLI::Argument>(3p),
L<Term::CLI|Term::CLI>(3p),
L<Type::Tiny|Type::Tiny>(3p).

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>, 2022.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Diab Jerius, Smithsonian Astrophysical Observatory

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
