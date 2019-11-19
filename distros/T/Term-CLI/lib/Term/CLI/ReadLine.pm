#=============================================================================
#
#       Module:  Term::CLI::ReadLine
#
#  Description:  Class for Term::CLI and Term::ReadLine glue
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/01/18
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

package Term::CLI::ReadLine  0.051007 {

use Modern::Perl 1.20140107;

use Carp qw( confess );

use parent 0.228 qw( Term::ReadLine );

use namespace::clean 0.25;

my $Term = undef;

sub new {
    my $class = shift;
    $Term = Term::ReadLine->new(@_);
    my $rlmodule = lc $Term->ReadLine =~ s/.*Term::ReadLine:://r;
    if ($rlmodule ne 'gnu') {
        my $err = "** No 'Term::ReadLine::Gnu' support loaded\n";
        if ($::ENV{PERL_RL} && lc $::ENV{PERL_RL} ne 'gnu') {
            $err .= "** Either unset the PERL_RL environment"
                 .  " variable or set it to 'Gnu'\n";
        }
        else {
            $err .= "** Make sure the Term::ReadLine::Gnu module is installed"
                 .  " and either unset the\n"
                 .  "** PERL_RL environment variable or set it to 'Gnu'\n";
        }
        confess $err;
    }
    return bless $Term, $class;
}

sub term { return $Term }

sub term_width {
    my $self = shift;
    my ($rows, $cols) = $self->term->get_screen_size();
    return $cols;
}

sub term_height {
    my $self = shift;
    my ($rows, $cols) = $self->term->get_screen_size();
    return $rows;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::ReadLine - maintain a single Term::ReadLine object

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::ReadLine;

 sub initialise {
    my $term = Term::CLI::ReadLine->new( ... );
    ... # Use Term::ReadLine methods on $term.
 }

 # The original $term reference is now out of scope, but
 # we can get a reference to it again:

 sub somewhere_else {
    my $term = Term::CLI::ReadLine->term;
    ... # Use Term::ReadLine methods on $term.
 }

=head1 DESCRIPTION

Even though L<Term::ReadLine>(3p) has an object-oriented interface,
the L<Term::ReadLine::Gnu>(3p) library really only keeps a single
instance around (if you create multiple L<Term::ReadLine> objects,
all parameters and history are shared).

This class inherits from L<Term::ReadLine> and keeps a single
instance around with a class accessor to access that single instance.

=head1 CONSTRUCTORS

=over

=item B<new> ( ... )
X<new>

Create a new L<Term::CLI::ReadLine>(3p) object and return a reference to it.

 Check that the newly created newly created L<Term::ReadLine> object is
 of the L<Term::ReadLine::Gnu>(3p) variety. If not, it will call throw a fatal
 exception (using L<Carp::confess|Carp/confess>).

Arguments are identical to L<Term::ReadLine>(3p) and
L<Term::ReadLine::Gnu>(3p).

A reference to the newly created object is stored internally and can be
retrieved later with the L<term|/term> class method. Note that repeated calls
to C<new> will reset this internal reference.

=back

=head1 METHODS

See L<Term::ReadLine>(3p) and L<Term::ReadLine::Gnu>(3p) for the
inherited methods.

=over

=item B<term_width>
X<term_width>

Return the width of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<term_height>
X<term_height>

Return the height of the terminal in characters, as given by
L<Term::ReadLine>.

=back

=head1 CLASS METHODS

=over

=item B<term>
X<term>

Return the latest C<Term::CLI::ReadLine> object created.

=back

=head1 SEE ALSO

L<Term::CLI>(3p).
L<Term::ReadLine>(3p),
L<Term::ReadLine::Gnu>(3p).

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
