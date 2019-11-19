#=============================================================================
#
#       Module:  Term::CLI::L10N
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  27/02/18
#
#   Copyright (c) 2018 Steven Bakker; All rights reserved.
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

package Term::CLI::L10N  0.051007 {

use Modern::Perl 1.20140107;

use parent 0.228 qw( Locale::Maketext Exporter );

BEGIN {
    our @EXPORT_OK   = qw( __ loc );
    our @EXPORT      = qw( loc );
    our %EXPORT_TAGS = (
        'all' => \@EXPORT_OK
    );
}

our $lh;

sub _init_handle {
    $lh //= __PACKAGE__->get_handle() || __PACKAGE__->get_handle('en')
        or die "No language files for 'en'";
    return $lh;
}

*__ = \&loc;        # Alias __ to loc().

sub handle {
    return _init_handle();
}

sub loc {
    _init_handle();
    return $lh->SUPER::maketext(@_);
}

sub set_language {
    my $self = shift;

    $lh = __PACKAGE__->get_handle(@_)
        or die "No language files for (@_)";
    return $lh;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::L10N - localizations for Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::L10N qw( :all );

 say loc("invalid value"); # "loc" is imported by default.
 
 say __("invalid value");  # "__" is not imported by default.


 my $lh = Term::CLI::L10N->handle();

 say $lh->maketext("invalid value");  # "maketext" is not imported by default.

=head1 DESCRIPTION

The C<Term::CLI::L10N> module implements a localization mechanism based
on L<Locale::Maketext>(3p).

=head1 FUNCTIONS

The module can export a few utility routines.

=over

=item B<__> ( I<Str> [, I<Str> ... ] )
X<__>

Synonym for L<loc|/loc>.

=item B<loc> ( I<Str> [, I<Str> ... ] )
X<loc>

Call L<Locale::Maketext>'s C<maketext> function
on the arguments.

=back

=head1 CLASS METHODS

=over

=item B<handle>

Return the module's L<Locale::Maketext> handle.

=item B<set_language> ( I<Str> [, ... ] )

Set the language to I<Str>, trying multiple if a list is given.

Dies with an error if no language can be loaded.

=back

=head1 EXAMPLES

    use Term::CLI::L10N; # Initialise using current locale.

    Term::CLI::L10N->set_language('nl'); # Force "nl" language.

    say loc("ERROR"); # Should print "FOUT".

=head1 SEE ALSO

L<Term::CLI::L10N::en>(3p),
L<Term::CLI::L10N::nl>(3p),
L<Locale::Maketext>(3p),
L<Locale::Maketext::Lexicon>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
