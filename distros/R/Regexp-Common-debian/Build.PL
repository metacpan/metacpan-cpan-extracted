#!/usr/bin/perl
# $Id: Build.PL 508 2014-07-05 20:11:01Z whynot $

use strict;
use warnings;
package main;

use version 0.77; our $VERSION = version->declare( v0.2.15 );

use Module::Build 0.38;

=head1 OVERVIEW

The B<Regexp::Common::debian> is collection of REs for various strings found in
the Debian Porject <http://debian.org>.
It's no way intended to be a validation tool.

B<R::C::d> needs perl C<v5.10.0> or later because:

=over

=item *

4 patterns (29%) make use of decent perls
(one doesn't make it through with anything older);

=item *

It's time to move, C<v5.10.0> is six year old and three years no-support;

=item *

C<lenny> is four year old and a year no-support;

=back

=cut

=head1 INSTALL

The B<R::C::d> builds with B<Module::Build>.

    $ perl Build.PL
    $ perl Build
    $ perl Build test
    $ perl Build install

Since we're about strings we need a lots of strings to test against
(B<Test::More>, unspecified version).
To access them easily (it's all about reuse, not implemented yet) I need an
apropriate storage.
Accidentally it's B<YAML::Tiny> (unspecified version).

C<v0.2.1>
Reading reports of cpantesters I've got to conclusion that B<YAML::Tiny> isn't
popular.
(C<v0.2.13>
Wandering through errors of C<v0.2.12> I should say it totally is.)
And avoiding installing (or unability to install (there could be reasons))
build requirements isn't that uncommon.
Although I experience a strong belief that some YAML reader happens to be
installed anyway.
And still I can't find a way to specify that I<%build_requires> B<one of> but
B<all> known to me YAML reader.
So here is a dirty trick.
B<t::TestSuite> attempts to B<require()> one of known (to me, see below) YAML
reader.
Then (upon initial C<perl Build.PL>) B<t::TestSuite> is asked what it has found
(if nothing then cosmetic C<Compilation failed in require> message will be
seen).
And one what has been found will be added to I<%build_requires>;
If nothing then fair B<YAML::Tiny> will be added.
(I think it's fair because B<YAML::Tiny> is pure-Perl, small footprint, and no
dependencies.)

B<(note)>
I'm talking about "known to me YAML readers" because I've found out that
different YAML readers treat source differently.
So I attempt to keep F<t/*.yaml> files semantically equal and sintactically
correct.
Hopefully there're no differences among versions in wild.

C<v0.2.13>
(Actually, this feature has been here for years.)
Any supported YAML reader can be enforced with C<$ENV{RCD_YAML_ENGINE}> magic
(in spite of any build-time choice):

    RCD_YAML_ENGINE=syck ./Build test

Readers are assigned by nicks.
Here they are:

=over

=item *

C<syck> -- B<YAML::Syck>.

=item *

C<xs> -- B<YAML::XS>.

=item *

C<tiny> -- B<YAML::Tiny>.

=item *

C<old> -- B<YAML>.

=item *

C<data> -- B<Data::YAML::Reader> 'does not support multi-line quoted scalars',
'YAML document header not found' -- unsupported, so far.

=back

C<v0.2.2>
Various (all, except F<t/preferences.t> and F<t/sourceslist.t>)
test-units know a magic command
'C<$ENV{RCD_ASK_DEBIAN}>'.
Apply it this way (enabling all possible external inquiries):

    RCD_ASK_DEBIAN=all ./Build test

or this (separate keys with any non-word):

    RCD_ASK_DEBIAN=binary,architecture ./Build test

When applied a test-unit would ask Debian's commands or inspect Debian specific
files for information the test-unit is interested in.
For obvious reasons that magic will fail on non-Debian system;
So don't.
Although if used correctly that could warn of strange ('not known before')
compatibility problems.
Details:

=over

=item B<architecture> of F<t/architecture.t>

This asks C<dpkg-architecture -L> for list of known architectures
(per Section 11.1 of debian-policy).
That wouldn't find architectures dropped (had that happen ever?)
but omissions won't stay unnoted anymore.

=item B<binary> of F<t/archive.misc.t>

C<v0.2.3>
Inspects all records in F</var/lib/apt/lists/*_Packages>, extracts I<Filename:>
entries and matches all of them against
C<m/^$RE{debian}{archive}{binary}$/>.
All (if any) failure will be reported at the end.

=item B<changelog> of F<t/changelog.t>

C<v0.2.8>
That will inspect F</usr/share/doc/*/changelog.Debian> files.
To do a complete scan it would take B<loads> of time (really).
You should understand, that's not enough to just run through changelogs.
It has to be verified that none entry is skipped.
The only reliable (for sake of interface, and, trivially, presence) source of
verification
is C<dpkg-parsechangelog>.
And here's the fork-mare.
C<perl> forks C<shell>, then C<perl>, then C<perl> again.
There seems to be fork of C<tail> too.
And that for B<each> entry.
(Not to count C<gunzip> to decompress the changelog.)
C<loadavg> climbs over 1.50..2.00
You've got the picture.
Although that's where choice begins.

C<v0.2.12>
That happens that C<urgency=high>, probably when it's that really high, is
expressed in blocks (like this: C<urgency=HIGH>).
B<$RE{d}{changelog}> is case-keeping, and then B<dpkg-parsechangelog(1)>
strikes back and lowercase.
From now on such manipulations won't fail a particular entry.

=over

=item I<changelog>

C<v0.2.9>
That defaults to C<changelog=5>.
See below.

=item I<changelog=package>

Only one changelog will be checked.
The one that C<eq>s.
The package name is picked from directory name.

=item I<changelog=a>

Only those changelogs will be checked that C<m/^a/>.

=item I<changelog=5>

C<v0.2.9>
That will check all changelogs, although it will look no more than requested
number of entries deep.

     v0.2.9 ~15min ~1.2K changelogs
    v0.2.12 ~30min ~1.3K changelogs ~6.0K subchecks;
    v0.2.13 ~35min ~1.3K changelogs ~6.1K subchecks;

And that has a perfect sense.
Do you know that C<cron> once changed it's name to C<Cron>
(beware leading block) (cron_3.0pl1-46)?
C'mon, it has happened 12 (tweleve) years ago!
(And you know what?
That default is pretty fair (liblog-log4perl-perl_1.16-1).
Probably it should look for time passed but entry number.)

=item I<changelog=-5>

C<v0.2.9>
That's different.
It will check as many entries as possible (there are changelogs what
B<$RE{d}{changelog}> finds out more entries than B<dpkg-parsechangelog>
(C<dpkg_1.2.13> vs C<dpkg_0.93.79>),
but if the offending record is more than that far from top then it's reported
and otherwise ignored.

     v0.2.9  ~3h ~1.2K changelogs ~45K subchecks
    v0.2.12 ~5¼h ~1.3K changelogs ~63K subchecks
    v0.2.13 ~5½h ~1.3K changelogs ~59K subckecks

=item I<changelog=_5>

C<v0.2.12>
That's a mix of I<changelog=5> and I<changelog=-5>
(thanks to irda-utils_0.9.18-8.1 and mime-support_3.49-1).
It goes no more than configured entries deep and ignores (and reports) any
errors.

=item I<changelog=0>

B<(bug)>
C<v0.2.9>
That will check all changelogs, check all possible entries and B<BAIL_OUT> off
first failure.
Shortly -- don't.
You're warned.
(Although, do it.
F<t/changelog.t> will give up pretty soon.)

=back

To slightly sweeten all that, F<t/changelog.t> attempts to filter
duplicates.
And it B<BAIL_OUT>s upon first failure.

=item B<package> of F<t/package.t>

C<v0.2.10>
Nothing special.
Output of C<dpkg-query -f '${Package}\n' -W> is matched against
B<m/^$RE{debian}{package}$/>.
Probably should parse F<*_Packagees>.

=item B<source> of F<t/archive.source.t>

C<v0.2.3>
Inspects all records in F</var/lib/apt/lists/*_Sources>, extracts I<Files:>
entries, then collects trailing filenames.
They are matched against
C<m/^$RE{debian}{archive}{source_1_0}$/>,
C<m/^$RE{debian}{archive}{patch_1_0}$/>,
C<m/^$RE{debian}{archive}{source_3_0_native}$/>,
C<m/^$RE{debian}{archive}{source_3_0_quilt}$/>,
C<m/^$RE{debian}{archive}{patch_3_0_quilt}$/>,
and
C<m/^$RE{debian}{archive}{dsc}$/>
(in fact C<||>).
If none matches then it will be reported at the end.
C<m/$RE{debian}{archive}{changes}/> is missing here because there is
no source of such on no-build system.

=item B<version> of F<t/version.t>

C<v0.2.10>
Again nothing special.
Output of C<dpkg-query -f '${Version}\n' -W> is matched against
B<m/^$RE{debian}{version}$/>.
Probably should parse F<*_Packages> too.

=back

If any test string fails I need to know what and how.
To provide that info I've picked B<Test::Differences>
(maybe there's other option I'm not aware of?)
(I'm, B<Test::Deep>).
C<v0.60> of B<T::D> closes
B<[38320@rt.cpan.org]> and B<[41241@rt.cpan.org]>.

=cut

my $engine = Module::Build->new(
  module_name        =>                q|Regexp::Common::debian|,
  dist_author        =>      q|Eric Pozharski <whynot@cpan.org>|,
  license              =>                         q|open_source|,
  meta_merge           => { resources =>
  { license =>    q|http://www.gnu.org/licenses/lgpl-3.0.txt| }},
  sign               =>                                        1,
  requires           =>
  { q|perl|           => qv( v5.10.0 ),
    q|version|        =>   qv( v0.77 ),
    q|Regexp::Common| =>            ''                         },
  build_requires     =>
  { q|File::Temp|        =>          '',
    q|Test::Differences| => qv( v0.60 ),
    q|Test::More|        =>          ''                        },
  dynamic_config         =>                                    1,
  configure_requires => {             q|Module::Build| => 0.38 },
  add_to_cleanup     => [ qw|              *.tmp *.bak skip_* |] );

my $y_choice = qx|perl -Mt::TestSuite -we 't::TestSuite::RCD_show_y_choice'|;
chomp $y_choice;
$engine->build_requires( ($y_choice || q|YAML::Tiny|) => '' );

$engine->create_build_script();

=head1 AVAILABILITY

Distribution --
L<http://search.cpan.org/dist/Regexp-Common-debian/>

=head1 BUGS

Please report here --
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Common-debian>

=head1 COPYRIGHT AND LICENSING

=over

=item *

Copyright 2008--2010, 2014 Eric Pozharski <whynot@cpan.org>

=item *

AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

=item *

GNU Lesser General Public License v3
L<http://www.gnu.org/licenses/lgpl.txt>

=back
