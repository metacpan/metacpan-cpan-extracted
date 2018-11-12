package PPIx::Regexp::Structure::RegexSet;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{
    LITERAL_LEFT_CURLY_REMOVED_PHASE_2
    @CARP_NOT
};

our $VERSION = '0.063';

sub __following_literal_left_curly_disallowed_in {
    return LITERAL_LEFT_CURLY_REMOVED_PHASE_2;
}

1;

__END__

=head1 NAME

PPIx::Regexp::Structure::RegexSet - Represent a regexp character set

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?[ \w - [fox] ])}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::RegexSet> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::RegexSet> has no descendants.

=head1 RESTRICTION

When running under Perl 5.6, the extended white space characters are not
recognized as white space.

=begin comment

See the code in PPIx::Regexp::Token::Literal that generates
$regex_set_space for the actual machinery. The reason for the
restriction is that I was, for some reason, not able to get '\x{...}' to
work.

=end comment

=head1 DESCRIPTION

This class represents a regex character set.

These were introduced in Perl 5.17.8, and documented as experimental and
subject to change. If changes introduced in Perl result in changes in
the way C<PPIx::Regexp> parses the regular expression, C<PPIx::Regexp>
will track the change, even if they are incompatible with the previous
parse. If this functionality is retracted and the syntax used for
something else, C<PPIx::Regexp> will forget completely about regex
character sets.

At some point, the documentation started calling these "Extended
Bracketed Character Classes", and documenting them in
L<perlrecharclass|perlrecharclass>.

=head1 METHODS

This class supports no public methods over and above those supported by
the superclasses.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
