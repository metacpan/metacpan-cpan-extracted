#=============================================================================
#
#       Module:  Term::CLI::Base
#
#  Description:  Generic role for Term::CLI classes
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  10/02/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

use 5.014_001;

package Term::CLI::Base  0.051007 {

use Modern::Perl 1.20140107;
use Term::CLI::ReadLine;

use Types::Standard 1.000005 qw(
    Str
);

use Moo 1.000001;
use namespace::clean 0.25;

has name => ( is => 'ro', isa => Str, required => 1 );
has error => ( is => 'rwp', isa => Str, default => sub {''} );

sub term { return Term::CLI::ReadLine->term }

sub set_error {
    my ($self, @value) = @_;
    if (!@value or !defined $value[0]) {
        $self->_set_error('');
    }
    else {
        $self->_set_error(join('', @value));
    }
    return;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Base - generic base class for Term::CLI classes

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 package Term::CLI::Something {

    use Moo;

    extends 'Term::CLI::Base';

    ...
 };

=head1 DESCRIPTION

Generic base class for L<Term::CLI>(3p) classes. This class provides some
basic functions and attributes that all classes except L<Term::CLI::ReadLine>
share.

=head1 METHODS

=head2 Accessors

=over

=item B<name>

Element name. Can be any string, but must be specified at construction
time.

=item B<error>

Contains a diagnostic message in case of errors.

=item B<term>

The active L<Term::CLI::ReadLine> object.

=back

=head2 Others

=over

=item B<set_error> ( I<STRING>, ... )

Set the L<error|/error>() attribute to the concatenation of all I<STRING> parameters
and return a "failure" (C<undef> or the empty list, depending on call context).

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Element>(3p),
L<Term::CLI::ReadLine>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
