package Syntax::Construct;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.29';

my %introduces = ( '5.024' => [qw[
                                 unicode8.0 \b{lb} sprintf-reorder
                              ]],
                   '5.022' => [qw[
                                 <<>> \b{} /n unicode7.0 attr-const
                                 fileno-dir ()x= hexfloat chr-inf
                                 empty-slice /x-unicode
                              ]],
                   '5.020' => [qw[
                                 attr-prototype drand48 %slice
                                 unicode6.3 \p{Unicode} utf8-locale
                                 s-utf8-delimiters
                              ]],
                   '5.018' => [qw[
                                 computed-labels while-each
                              ]],
                   '5.014' => [qw[
                                 ?^ /r /d /l /u /a auto-deref
                                 ^GLOBAL_PHASE \o package-block
                                 srand-return
                              ]],
                   '5.012' => [qw[
                                 package-version ... each-array
                                 keys-array values-array delete-local
                                 length-undef \N while-readdir
                              ]],
                   '5.010' => [qw[
                                 // ?PARNO ?<> ?| quant+ regex-verbs
                                 \K \R \v \h \gN readline()
                                 stack-file-test recursive-sort /p
                                 lexical-$_
                              ]],
                   old => [qw[
                                 s-utf8-delimiters-hack
                          ]],
                 );

my %removed = ( 'auto-deref'             => '5.024',
                'lexical-$_'             => '5.024',
                's-utf8-delimiters-hack' => '5.020',
              );

my %_introduced = map {
    my $version = $_;
    map { $_ => $version } @{ $introduces{$version} }
} keys %introduces;

my %introduced = %_introduced;
delete @introduced{ @{ $introduces{old} } };

sub _hook {
    { drand48 => sub {
          require Config;
          warn "Unknown rand implementation at ", _position(1), "\n"
              unless 'Perl_drand48' eq $Config::Config{randfunc};
      },
    }
}

sub removed {
    my $construct = shift;
    return $construct ? $removed{$construct} : keys %removed
}


sub introduced {
    my $construct = shift;
    return $construct ? $introduced{$construct} : keys %introduced
}


sub _position {
    join ' line ', (caller(1 + !! shift))[1,2]
}


sub import {
    shift;
    my $min_version = 0;
    my $max_version = 6;
    my ($constr, $d_constr);
    my @actions;
    for (@_) {
        if ($introduced{$_}) {
            ($min_version, $constr) = ($introduced{$_}, $_)
                if $introduced{$_} gt $min_version;
        } else {
            die "Unknown construct `$_' at ", _position(), "\n"
        }

        if ($removed{$_}) {
            ($max_version, $d_constr) = ($removed{$_}, $_)
                if $removed{$_} lt $max_version;
        }

        my $action = _hook()->{$_};
        push @actions, $action if $action;
    }
    die 'Empty construct list at ', _position(), "\n" if $min_version == 0;

    my $nearest_stable = ( my $is_stable = $] =~ /^[0-5]\.[0-9][0-9][02468]/ )
                       ? $]
                       : do {
                           my ($major, $minor)
                               = $] =~ /^([0-5])\.([0-9][0-9][13579])/;
                           ++$minor;
                           "$major.$minor"
                       };
    warn "Faking version $nearest_stable to test removed constructs.\n"
        unless $is_stable;
    die "$d_constr removed in $max_version at ", _position()
        if $max_version le $nearest_stable;

    die "Unsupported construct $constr at ", _position(),
        sprintf " (Perl %.3f needed)\n", $min_version
        unless $min_version le $];

    $_->() for @actions;
}


=head1 NAME

Syntax::Construct - Identify which non-feature constructs are used in the code.

=head1 VERSION

Version 0.29

=head1 SYNOPSIS

For some new syntactic constructs, there is the L<feature> pragma. For
the rest, there is B<Syntax::Construct>.

  use Syntax::Construct qw( // ... /r );

  my $x = shift // 'default';
  my $y = $x =~ s/de(fault)/$1/r;
  if ($y =~ /^fault/) {
      ...
  }

There are two subroutines (not exported) which you can use to query
the lists of constructs programmatically: C<introduced> and
C<removed> (see below).

  my @constructs = Syntax::Construct::introduced();
  say "$_ was introduced in ",
      Syntax::Construct::introduced($_) for @constructs;

=head1 DESCRIPTION

This module provides a simple way of specifying syntactic constructs
that are not implemented via the L<feature> pragma, but are still not
compatible with older versions of Perl.

It's the programmer's responsibility to track the constructs and list
them (but see L<Perl::MinimumVersion> on how to extract the
information from existing code).

Using C<use Syntax::Construct qw( // );> doesn't really change
anything if you're running Perl 5.10+, but it gives much better error
messages in older versions:

  Unsupported construct //

instead of

  Search pattern not terminated

Three groups of people can benefit from the module:

=over 4

=item 1.

The authors of the module using L<Syntax::Construct> win, as they have
all the constructs in one place (i.e. L<Syntax::Construct>'s
documentation) and they don't waste their time searching through
perldeltas and other places.

=item 2.

Users of their modules win as they get meaningful error messages
telling them what Perl version they need to upgrade to.

=item 3.

The programmer they hired to workaround the problem wins as they know
what constructs to replace in the code to make it run in the ancient
version.

=back


=head1 EXPORT

Nothing. Using B<Syntax::Construct> with no parameters is an error,
giving it an empty list is a no-op (but you can then access the
C<introduced> and C<removed> subroutines).

=over 4

=item introduced

Without arguments, returns a list of all the supported
constructs. With an argument, returns the version in which the given
construct was introduced.

=item removed

Same as C<introduced>, but for removed constructs (e.g. auto-deref in
5.24).

=back

=head1 RECOGNISED CONSTRUCTS

=head2 5.010

=head3 recursive-sort

L<perl5100delta/Recursive sort subs>.

=head3 //

L<perl5100delta/Defined-or operator> or L<perlop/Logical Defined-Or>.

=head3 ?PARNO

"Recursive Patterns" under L<perl5100delta/Regular expressions> or
L<perlre/"(?PARNO) (?-PARNO) (?+PARNO) (?R) (?0)">.

=head3 ?<>

"Named Capture Buffers" under L<perl5100delta/Regular expressions> or
L<perlre/"(?E<60>NAMEE<62>pattern)">.


=head3 ?|

Not mentioned in any Delta. See B<(?|pattern)> in L<perlre/Extended Patterns>.

=head3 quant+

"Possessive Quantifiers" under L<perl5100delta/Regular expressions> or
L<perlre/Quantifiers>.

=head3 regex-verbs

"Backtracking control verbs" under L<perl5100delta/Regular
expressions> or L<perlre/Special Backtracking Control Verbs>.


=head3 \K

"\K escape" under L<perl5100delta/Regular expressions> or
L<perlre/Look-Around Assertions>.

=head3 \R \v \h

Covers C<\V> and C<\H>, too. See "Vertical and horizontal whitespace,
and linebreak" under L<perl5100delta/Regular expressions> or
L<perlrebackslash/Misc>.

=head3 \gN

"Relative backreferences" under L<perl5100delta/Regular expressions> or
L<perlre/Capture groups>.

=head3 readline()

L<perl5100delta/Default argument for readline()>.

=head3 stack-file-test

L<perl5100delta/Stacked filetest operators>.

=head3 /p

C</p> (preserve) modifier and C<${^PREMATCH}>, C<${^MATCH}> and
C<${^POSTMATCH}> variables. Not mentioned in any Delta. See
L<perlvar/Variables related to regular expressions>.

=head3 lexical-$_

L<perl5100delta/Lexical $_>.

=head2 5.012

=head3 package-version

L<perl5120delta/New package NAME VERSION syntax>

=head3 ...

L<perl5120delta/The ... operator> or L<perlsyn/The Ellipsis Statement>

=head3 each-array

L<perl5120delta/each, keys, values are now more flexible>

=head3 keys-array

L<perl5120delta/each, keys, values are now more flexible>

=head3 values-array

L<perl5120delta/each, keys, values are now more flexible>

=head3 delete-local

L<perl5120delta/delete local>

=head3 length-undef

See the ninth bullet in L<perl5120delta/Other potentially incompatible
changes>.

=head3 \N

L<perl5120delta/\N experimental regex escape>.

=head3 while-readdir

C<readdir> in a while-loop condition populates C<$_>. Not mentioned in
any delta, but see C<readdir> in L<perlfunc>.

=head2 5.014

=head3 ?^

L<perl5140delta/Regular Expressions>.

=head3 /r

L<perl5140delta/Regular Expressions> and L<perlre/Modifiers>.

=head3 /d

L<perl5140delta/Regular Expressions> and L<perlre/Modifiers>.

=head3 /l

L<perl5140delta/Regular Expressions> and L<perlre/Modifiers>.

=head3 /u

L<perl5140delta/Regular Expressions> and L<perlre/Modifiers>.

=head3 /a

L<perl5140delta/Regular Expressions> and L<perlre/Modifiers>.

=head3 auto-deref

L<perl5140delta/Array and hash container functions accept
references>. See also C<push>, C<pop>, C<shift>, C<unshift>,
C<splice>, C<keys>, C<values>, and C<each> in L<perlfunc>.

=head3 ^GLOBAL_PHASE

See B<New global variable ${^GLOBAL_PHASE}> under
L<perl5140delta/Other Enhancements>.

=head3 \o

L<perl5140delta/Regular Expressions>.

=head3 package-block

See B<package block syntax> under L<perl5140delta/Syntactical Enhancements>.

=head3 srand-return

See B<srand() now returns the seed> under L<perl5140delta/Other Enhancements>.

=head2 5.016

No non-feature constructs were introduced in this version of Perl.

=head2 5.018

=head3 computed-labels

L<perl5180delta/Computed Labels>

=head3 while-each

See in L<perl5180delta/Selected Bug Fixes> or C<each> in L<perlfunc>.

=head2 5.020

=head3 attr-prototype

L<perl5200delta/subs now take a prototype attribute>

=head3 drand48

L<perl5200delta/rand now uses a consistent random number generator>.
Note that on OpenBSD, Perl 5.20+ uses the system's own C<drand48>
unless seeded.

=head3 %slice

L<perl5200delta/New slice syntax>

=head3 unicode6.3

L<perl5200delta/Unicode 6.3 now supported>

=head3 \p{Unicode}

See B<New \p{Unicode} regular expression pattern property> in
L<perl5200delta/Core Enhancements>.

=head3 utf8-locale

See B<use locale now works on UTF-8 locales> in
L<perl5200delta/Core Enhancements>.

=head3 s-utf8-delimiters

See L<perl5200delta/Regular Expressions>: in older Perl versions, a
hack around was possible: to specify the delimiter twice in
substitution. Use C<s-utf8-delimiters-hack> if your code uses it.

=head2 5.022

=head3 <<>>

L<perl5220delta/New double-diamond operator>

=head3 \b{}

L<perl5220delta/New \b boundaries in regular expressions>

=head3 /n

L<perl5220delta/Non-Capturing Regular Expression Flag>

=head3 unicode7.0

See B<Unicode 7.0 (with correction) is now supported> in
L<perl5220delta/Core Enhancements>.

=head3 attr-const

L<perl5220delta/New :const subroutine attribute>

=head3 fileno-dir

L<perl5220delta/fileno now works on directory handles>

=head3 ()x=

L<perl5220delta/Assignment to list repetition>

=head3 hexfloat

L<perl5220delta/Floating point parsing has been improved>

=head3 chr-inf

L<perl5220delta/Packing infinity or not-a-number into a character is now fatal>

=head3 empty-slice

L<perl5220delta/List slices returning empty lists>

=head3 /x-unicode

See B<qr/foo/x now ignores all Unicode pattern white space> in
L<perl5220delta/Incompatible Changes>.

=head2 5.024

=head3 unicode8.0

L<perldelta/Unicode 8.0 is now supported>.

=head3 \b{lb}

L<perldelta/New \b{lb} boundary in regular expressions>.

=head3 sprintf-reorder

L<perldelta/printf and sprintf now allow reordered precision arguments>.

=for completeness
=head2 old
=head3 s-utf8-delimiters-hack

=head1 AUTHOR

E. Choroba, C<< <choroba at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub repository,
see below.

=head2 Unstable Perl versions

In development versions of Perl, the removal of constructs is tested
against the coming stable version -- e.g., 5.23 forbids all the
removed constructs of 5.24. The behaviour of the module in such
circumstances might still be, um, unstable.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Syntax::Construct

You can also look for information at:

=over 4

=item * GitHub Repository

L<https://github.com/choroba/syntactic-construct>

Feel free to report issues and submit pull requests.

=item * MetaCPAN, Open Source Search Engine for CPAN

L<https://metacpan.org/pod/Syntax::Construct>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Syntax-Construct>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Syntax-Construct>

=item * Search CPAN

L<http://search.cpan.org/dist/Syntax-Construct/>

=back

=head1 SEE ALSO

L<Perl::MinimumVersion>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 - 2016 E. Choroba.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__
