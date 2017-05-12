package PPIx::Regexp::Constant;

use strict;
use warnings;

our $VERSION = '0.051';

use base qw{ Exporter };

our @EXPORT_OK = qw{
    COOKIE_CLASS
    COOKIE_QUANT
    COOKIE_QUOTE
    COOKIE_REGEX_SET
    LITERAL_LEFT_CURLY_ALLOWED
    LITERAL_LEFT_CURLY_REMOVED_PHASE_1
    LITERAL_LEFT_CURLY_REMOVED_PHASE_2
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
    MSG_PROHIBITED_BY_STRICT
    NODE_UNKNOWN
    RE_CAPTURE_NAME
    STRUCTURE_UNKNOWN
    TOKEN_LITERAL
    TOKEN_UNKNOWN
};

use constant COOKIE_CLASS	=> ']';
use constant COOKIE_QUANT	=> '}';
use constant COOKIE_QUOTE	=> '\\E';
use constant COOKIE_REGEX_SET	=> '])';

use constant LITERAL_LEFT_CURLY_ALLOWED		=> undef;
use constant LITERAL_LEFT_CURLY_REMOVED_PHASE_1	=> '5.025001';
use constant LITERAL_LEFT_CURLY_REMOVED_PHASE_2	=> undef;

use constant MINIMUM_PERL	=> '5.000';

use constant MODIFIER_GROUP_MATCH_SEMANTICS => 'match_semantics';

use constant MSG_PROHIBITED_BY_STRICT	=>
    q<prohibited by "use re 'strict'">;

use constant NODE_UNKNOWN	=> 'PPIx::Regexp::Node::Unknown';

# The perlre for Perl 5.010 says:
#
#      Currently NAME is restricted to simple identifiers only.  In
#      other words, it must match "/^[_A-Za-z][_A-Za-z0-9]*\z/" or
#      its Unicode extension (see utf8), though it isn't extended by
#      the locale (see perllocale).

use constant RE_CAPTURE_NAME => ' [_[:alpha:]] \w* ';

use constant STRUCTURE_UNKNOWN	=> 'PPIx::Regexp::Structure::Unknown';

use constant TOKEN_LITERAL	=> 'PPIx::Regexp::Token::Literal';
use constant TOKEN_UNKNOWN	=> 'PPIx::Regexp::Token::Unknown';

1;

__END__

=head1 NAME

PPIx::Regexp::Constant - Constants for the PPIx::Regexp system

=head1 SYNOPSIS

 use PPIx::Regexp::Constant qw{ TOKEN_UNKNOWN }
 print "An unknown token's class is TOKEN_UNKNOWN\n";

=head1 INHERITANCE

C<PPIx::Regexp::Constant> is an L<Exporter|Exporter>.

C<PPIx::Regexp::Constant> has no descendants.

=head1 DETAILS

This module defines manifest constants for use by the various
C<PPIx::Regexp> modules. These constants are to be considered B<private>
to the C<PPIx::Regexp> system, and the author reserves the right to
change them without notice.

This module exports the following manifest constants:

=head2 COOKIE_CLASS

The name of the cookie used to control the construction of character
classes.

This cookie is set in
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> when
the left square bracket is encountered, and cleared in the same module
when a right square bracket is encountered.

=head2 COOKIE_QUANT

The name of the cookie used to control the construction of curly
bracketed quantifiers.

This cookie is set in
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> when a
left curly bracket is encountered. It requests itself to be cleared on
encountering anything other than a literal comma, a literal digit, or an
interpolation, or if more than one comma is encountered. If it survives
until L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure>
processes the right curly bracket, it is cleared there.

=head2 COOKIE_QUOTE

The name of the cookie used to control the parsing of C<\Q ... \E>
quoted literals.

This cookie is set in
L<PPIx::Regexp::Token::Control|PPIx::Regexp::Token::Control> when a
C<\Q> is encountered, and it persists until the next C<\E>.

=head2 COOKIE_REGEX_SET

The name of the cookie used to control regular expression sets.

=head2 LITERAL_LEFT_CURLY_ALLOWED

The Perl version at which allowed unescaped literal left curly brackets
were removed. This may make more sense if I mention that its value is
C<undef>.

=head2 LITERAL_LEFT_CURLY_REMOVED_PHASE_1

The Perl version at which the first phase of unescaped literal left
curly bracket removal took place. The value of this constant is
C<'5.025001'>.

=head2 LITERAL_LEFT_CURLY_REMOVED_PHASE_2

The Perl version at which the second phase of unescaped literal left
curly bracket removal took place. The value of this constant is
C<undef>, but it will be assigned a value when the timing of the second
phase is known.

=head2 MINIMUM_PERL

The minimum version of Perl understood by this parser, as a float. It is
currently set to 5.000, since that is the minimum version of Perl
accessible to the author.

=head2 MODIFIER_GROUP_MATCH_SEMANTICS

The name of the
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier> group
used to control match semantics.

=head2 MSG_PROHIBITED_BY_STRICT

An appropriate error message for an unknown entity created because
C<'strict'> was in effect. This is rank ad-hocery, and more than usually
subject to being changed, without any notice whatsoever. Caveat user.

=head2 NODE_UNKNOWN

The name of the class that represents an unknown node. That is,
L<PPIx::Regexp::Node::Unknown|PPIx::Regexp::Node::Unknown>.

=head2 RE_CAPTURE_NAME

A string representation of a regular expression that matches the name of
a named capture buffer.

=head2 STRUCTURE_UNKNOWN

The name of the class that represents an unknown structure. That is,
L<PPIx::Regexp::Structure::Unknown|PPIx::Regexp::Structure::Unknown>.

=head2 TOKEN_LITERAL

The name of the class that represents a literal token. That is,
L<PPIx::Regexp::Token::Literal|PPIx::Regexp::Token::Literal>.

=head2 TOKEN_UNKNOWN

The name of the class that represents the unknown token. That is,
L<PPIx::Regexp::Token::Unknown|PPIx::Regexp::Token::Unknown>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2017 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
