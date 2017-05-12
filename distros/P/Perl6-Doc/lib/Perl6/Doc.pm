package Perl6::Doc;
BEGIN {
  $Perl6::Doc::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $Perl6::Doc::VERSION = '0.47';
}
use strict;
use warnings FATAL => 'all';

1;

=encoding utf8

=head1 NAME

Perl6::Doc - Perl 6 documentation

=head1 SYNOPSIS

This distribution is documentation-only. It contains no code for you to run.
Included are various Perl 5 Pod and Perl 6 Pod files describing the Perl 6
language. For a tool to read this documentation, see L<grok|grok>.

=head1 DESCRIPTION

Currently included in this distribution:

=head2 Design docs

=head3 Apocalypses (outdated)

Larry Wall started the Apocalypse (latin for revelation) series as a
systematic way of answering the RFCs (Request For Comments) that
started the design process for Perl 6.  Each Apocalypse corresponds to
a chapter in the book I<Programming Perl, 3rd edition>, and addresses
the features relating to that chapter in the book that are likely to
change.

Larry addresses each relevant RFC, and gives reasons why he accepted
or rejected various pieces of it.  But each Apocalypse also goes
beyond a simple "yes" and "no" response to attack the roots of the
problems identified in the RFCs.

B<Note:> These documents are outdated and and will not be updated to match
the specification (see L</Synopses>).

=head3 Exegeses (outdated)

Damian Conway's Exegeses (latin for I<explanation>) are extensions of
each Apocalypse.  Each Exegesis is built around a practical code
example that applies and explains the new ideas.

B<Note:> These documents are outdated and and will not be updated to match
the specification (see L</Synopses>).

=head3 Synopses

The Synopsis (latin for comparison) started as a fast to read diff
between Perl 5 and 6. Because they are also easier to maintain, all
changes of the language, that are evolving from the design process
are written down here first. The Apocalypses and Exegeses are frozen
as "historic documents".

In other words, these docs may change slightly or radically. But the
expectation is that they are "very close" to the final shape of Perl 6.

The Synopsis documents are to be taken as the formal specification for
Perl 6 implementations, while still being reference documentation for
Perl 6, like I<Programming Perl> is for Perl 5.

Note that while these documents still being subjected to the rigours 
of cross-examination through implementation.

=head2 Magazine articles

These are Pod-ified versions of magazine articles about Perl 6 that have
appeared in print during the design process. Take these with a grain of salt
as they might not describe Perl 6 as it is now. They are mostly from
L<http://www.perl.com> and L<http://www.perl-magazin.de/>.

=head2 Perl 6 Table Index

A Pod-ified version of L<http://www.perlfoundation.org/perl6/index.cgi?perl_6_index_tablet>
is included.

=head2 Man pages

Currently included are draft versions of F<perlintro> and F<perlsyn>.

=head1 HISTORY

As of version 0.40, this distribution has been overhauled and is no longer
maintained by Herbert Breunung, who originally took it over from ingy and
audreyt.

=head1 PACKAGING

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

I'm not the author of the documentation in this distro, of course, I merely
maintain this package.

=head1 SOURCES

All Apocalypses and Exegeses were taken from the official Perl development
site: L<http://dev.perl.org/perl6/>

All Synopese were taken from the Pugs repository:
L<http://svn.pugscode.org/pugs/docs/Perl6/>

The magazine articles are from perl.com:
L<http://perl.com/pub/q/Article_Archive#Perl%206>

=head1 LICENSE AND COPYRIGHT

This copyright applies only to the C<Perl6::Doc> Perl software
distribution, not the documents bundled within.

Copyright (c) 2009, Hinrik Örn Sigurðsson L<hinrik.sig@gmail.com>.

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=head2 Scribes

These are the authors of the included docs, named in the order their work 
was added. This list is not exhaustive.

* Larry Wall L<larry@wall.org>

* Damian Conway L<damian@conway.org>

* Luke Palmer L<luke@luqui.org>

* Allison Randal L<al@shadowed.net>

* Audrey Tang L<autrijus@cpan.org>

* Ingy döt Net L<ingy@cpan.org>

* Sam Vilain L<samv@cpan.org>

* Kirrily "Skud" Robert L<skud@cpan.org>

* Moritz Lenz L<moritz@fau2ik3.org>

* David Koenig L<karhu@u.washington.edu>

* Jonathan Scott Duff L<duff@pobox.com>

* Phil Crow L<philcrow2000@yahoo.com>

* chromatic L<chromatic@oreilly.com>

* Mark-Jason Dominus L<mjd@songline.com>

* Shmarya L<shmarya.rubenstein@gmail.com>

* Pawel Murias L<13pawel@gazeta.pl>

* Herbert Breunung L<lichtkind@cpan.org>

=cut
