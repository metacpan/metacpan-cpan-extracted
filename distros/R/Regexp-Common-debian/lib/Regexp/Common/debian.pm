# $Id: debian.pm 508 2014-07-05 20:11:01Z whynot $
# Copyright 2008--2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
package Regexp::Common::debian;

use version 0.77; our $VERSION = version->declare( v0.2.14 );

=head1 NAME

Regexp::Common::debian - regexps for Debian specific strings

=head1 SYNOPSIS

    use Regexp::Common qw/ debian /;
    # Read `perldoc Regexp::Common` for base documentation
    # Each pattern provides its own synopsis

=cut

use Regexp::Common qw| no_defaults pattern |;

=head1 DESCRIPTION

Debian GNU/Linux as a management system validates, parses, and generates a lots
of data.
For sake of some other project I've needed some kind of parser.
And, at time of starting, there're reasons to go myself.
Those reasons are moot now but here we are.

When choosing API I had an option -- 

=over

=item B<parsing>

That would be a bunch of error-prone decisions -- pick a backbone parser,
figure out grammar, mix them, build API, implement it,..
And as a net result one more B<xDpkg::> namespace.
I really would like to hear any reasons why.

=item B<comparing>

String on left, regexp on right, add I<{-keep}>, and get an array of parsed out
parts.
Other way: string on left, regexp on right, anchor it properly, and get a
scalar indicating match/mismatch.
The only deficiency I can see is that result is an array, but hash.
Hard to argue.
That seems I've committed a sin.
Should live with it.

=back

As a backbone L<Regexp::Common> was chosen.
It has it's own deficiences, but I've failed to find any
unhappy user
(unsatisfied -- maybe, but unhappy -- no, sir).
Maybe I didn't tried hard enough.
It provides neat and rich interface, but...

I<{-keep}> and I<{-i}> are provided internally.
It's OK with I<{-keep}>, but I<{-i}>...
Look, Debian strings are B<almost> all case-sensitive.
When case shouldn't matter it's explicitly switched off by template itself.
So -- if you play with I<{-i}>, don't blame me then.
(I'll experiment with implicit C<qr/(?i:)/> after that release.
And experiments are going.)

B<(note)> B<Regexp::Common::debian> is very permissive in some cases
(sometime absurdly permissive).
Hopefully, I've noted in docu all such cases.

C<v0.2.10>
The test-suite checks various sources that could be found on Debian system.
Those checks are done B<only> upon request.
Don't be a bit optimistic about success.
F<README> has more.

=over

=cut

=item B<$RE{debian}{package}>

    'the-very.strange.package+name' =~ $RE{debian}{package}{-keep};
    print "package is $1";

This is Debian B<package> name.
Rules are described in S<Section 5.6.7> of Debian policy.

=over

=item I<$1> is a I<package>

=back

=cut

# TODO:20100726182406:whynot: Force casefulnes.
# TODO:201312301927:whynot: Pass test data through B<Dpkg::Package>.
# CHECK:201312301705:whynot: B<debian-policy>, version 3.9.3.1, 5.6.1 5.6.7
# CHECK:201312301842:whynot: B<Dpkg::Package>, version 1.16.10, 0.01

my $pMagic = q|[a-z0-9][a-z0-9+.-]+|;
pattern
  name   => [ qw| debian package | ],
  create =>         qq|(?k:$pMagic)|;

=item B<$RE{debian}{version}>

    '10:1+abc~rc.2-ALPHA:now-rc25+w~t.f' =~ $RE{debian}{version}{-keep};
    ($2 || 0) eq '10'            &&
    $3 eq '1+abc~rc.2-ALPHA:now' &&
    ($4 || 0) eq 'rc25+w~t.f'       or die;

This is Debian B<version>.
Rules are described in S<Section 5.6.12> of Debian policy.
I<upstream_epoch> and I<debian_revision> are implicitly caseles (as required).

=over

=item I<$1> is a I<debian_version>

=item I<$2> is an I<epoch>

if any.
Oterwise -- C<undef>.
Debian policy requires defaulting here to C<0>.
However B<Perl> disallows assigning special variables C<$[1-9][0-9]*>
(they are read-only, L<< perlvar|perlvar/"$<digits> ($1, $2, ...)" >> has more).
So if you have I<epoch> to be C<undef> then assume here C<0>.

=item I<$3> is an I<upstream_version>

If there's no way to match I<upstream_version> than the whole pattern fails.

B<(caveat)>
A string like C<0--1> will end up with I<upstream_version> set to weird C<0->
(hopefully, Debian won't degrade to such versions; though YMMV).

B<(caveat)>
C<v0.2.3>
Look for L<caveat #1|/"caveat #1: I<version> starts with letter"> for
background.
However this RE stayed a bit better than others.
In spite of Debian policy, I<upstream_version> can start with number B<or>
letter but any version forming character.
Should it be configurable?
Probably.
But think about it:  B<$RE{debian}> is for B<working> with strings but
B<verification>.
And such policy-ignorant versions wouldn't go elsewhere
(think F<changelog.Debian>).
So in presense of choice between weak and strict you would alomost ever choose
weak.
And a point of strict then?
Nobody cares.

=item I<$4> is a I<debian_revision>

B<(bug)>
C<0-1-> will end up with I<upstream_version> set to C<0> and
I<debian_revision> set to C<1> (such trailing hyphens will be missing in
I<debian_version>).
C<0-> will end up with I<debian_resion> C<undef>ed.
And the same (as with I<epoch>) -- omitted I<debian_revision> defaults to
C<0>;
I<debian_revision> can't.

B<(caveat)>
The I<debian_revision> is allowed to start with non-digit.
This's solely my reading of Debian Policy.

=back

=cut

# XXX: perl5.10.0 misses C<qr/(?=[$magic-]+)/>.
# XXX: qr/(?{ m,[$magic-]+, })/ segfaults.
# XXX: implicit anchoring must be avoided (as if it would help).
# XXX: C<do { my $x; qr/?{ local $x; }/; }> is weird.
# XXX: C<qr/(??{})/> requires C<use re qw eval ;> inside(?) R::C.
# FIXME: C<q|0-1-|> should fail, but C<(q|0-1-|, undef, 0, 1)>.
# FIXME: C<q|0-|> should fail, but C<(q|0-|, undef, 0, undef)>.
# TODO:201312301955:whynot: Pass test data through B<Dpkg::Version>.
# TODO: Hmm, C<dpkg --compare-versions> compares C<q|0-|>; and what's I<debian_revision> then?
# TODO:20100808185830:whynot: It does compares C<q|-|>, it doesn't C<q|:|> though.
# TODO:201312301955:whynot: Now that's weird.  C<q|0-|> is more then C<q|0-0|>, but less then C<q|0-1|>.
# TODO:201312302004:whynot: Totally weird.  Space is some special tilde that's more then C<0> and less then enything else.
# CHECK:201312301854:whynot: B<debian-policy>, version 3.9.3.1, 5.6.12
# CHECK:201312301916:whynot: B<Dpkg::Version>, version 1.16.10, 1.00

my $anMagic = q|0-9A-Za-z|;
my $spMagic = q|.+~|;
my $Magic = $anMagic . $spMagic;

pattern
  name    => [ qw| debian version | ],
  version => 5.010,
  create  =>
    q{(?k:(?:(?k:[0-9]+):)?(?|}                                   .
      qq{(?<=[0-9]:)(?k:[$anMagic][$Magic:-]*)+-(?k:[$Magic:]+)|} .
      qq{(?<=[0-9]:)(?k:[$anMagic][$Magic:]*)|}                   .
      qq{(?<![0-9]:)(?k:[$anMagic][$Magic-]*)+-(?k:[$Magic]+)|}   .
      qq{(?<![0-9]:)(?k:[$anMagic][$Magic]*)}                     .
# XXX: Is that RE really that fragile?
    qq{)(?![$Magic]))};

=item B<R_C_d_version()>

    use Regexp::Common qw(debian);
    # though that works too
    # use Regexp::Common::debian;
    my $re = Regexp::Common::debian::R_C_d_version;
    $version =~ /^$re$/;
    $2                   and print "has epoch\n";
    $3 || $5 || $6 || $8 and print "has upstream_version\n";
    $4 || $7             and print "has debian_revision\n";
    $3 && !$4 || !$3 && $4 or die;
    $6 && !$7 || !$6 && $7 or die;
    $3 && !$5 && !$6 && !$8 or die;
           $5 && !$6 && !$8 or die;
                  $6 && !$8 or die;

That's a workaround for B<perl5.8.8>
As of C<v0.2.12> it's gone.

=cut

=item B<$RE{debian}{architecture}>

    $arch =~ $RE{debian}{architecture}{-keep};
    $2 && ($3 ||  $4)           and die;
           $3 && !$4            and die;
    $2 and print "that's special: $2";
    $3 and print "OS is: $3";
    $4 and print "CPU is: $4";

This is Debian B<architecture>.
Rules are described in I<Section 5.6.8> of Debian policy.

C<v0.2.12>
At time of writing:
only C<linux> I<os> is present for any I<cpu>;
only C<m68k> I<cpu> is present for any I<os>;
reality had been more straightforward before.
Thus giving up on semantics.
Anything that comprises somehow known I<os> can go on left.
Anything that comprises somehow known I<cpu> can go on right.
C<any> wildcard can take over either I<os> or I<cpu>
(B<(bug)> or both of them (C<any-any> is parsed as correct architecture)).
Neither lowercase, nor digit, nor hyphen can touch a prospect on outside.

=over

=item I<$1> is some of Debian's I<architecture>s

=item I<$2> is any I<special>

Distinguishing special architectures (C<all>, C<any>, and C<source>) and
I<os>-I<cpu> pairs is arguable.
But I've decided that would be good to separate C<all> and e.g. C<i386>
(what in turn is actually C<linux-i386>).

=item I<$3> is I<os>

When C<!$3 && $4> is true then unZ<>B<defined> I<os> actually means C<linux>.
Since I<$digit>s are read-only yielding here anything but C<undef> is
impossible.
More on that in I<Section 11.1> of Debian policy.

=item I<$4> is I<cpu>

B<(note)>
Ocassionally, various sources talk about B<arch> while meaning B<cpu>
component of B<architecure>.
Looks like B<architecture> is always I<os>-I<cpu> pair.
Probably that B<arch>/B<architecture> mess is with us from the beginning.
B<(bug)>
In this docu happens too.

=back

B<(caveat)>
Debian policy by itself doesn't specify what I<os>-I<arch> pairs are valid
(only I<special>s are mentioned).
In turn it relies on C<qx/dpkg-architecture -L/>.
In effect B<R::C::d> can desinchronize;
Hopefully, that wouldn't stay unnoticed too long.

=cut

# FIXME:201401032249:whynot: Architecture mess should be fiexd.
# CHECK:201401022120:whynot: B<debian-policy>, version 3.9.3.1, 5.6.8 and 11.1
# CHECK:201401030018:whynot: L<dpkg-architecture(1)>, version 1.16.10

# (          bsd) -> ( B) (darwi)  ->  (darwin)
# (          net) -> ( N) (sol)    -> (solaris)
# (         free) -> ( F) (solari) -> (solaris)
# (         open) -> ( O) (uclin)  -> (uclinux)
# (       -sparc) -> (-S)
# (     -powerpc) -> (-P)
# (^uclibc-linux) -> (UL)
#       FB NB OB UL darwi hurd kFB kNB kOsol linux mint solar uclin
#     P  X  X  X  X   X    X    X   X    X     X    .     X     X
#  Pspe  .  .  .  .   .    .    .   .    .     X    .     .     .
#     S  X  X  X  X   X    X    X   X    X     X    .     X     X
#   S64  X  X  X  X   X    X    X   X    X     X    .     X     X
# alpha  X  X  X  X   X    X    X   X    X     X    .     X     X
# amd64  X  X  X  X   X    X    X   X    X     X    .     X     X
#   arm  X  X  X  X   X    X    X   X    X     X    .     X     X
# arm64  X  X  X  X   X    X    X   X    X     X    .     X     X
# armeb  X  X  X  X   X    X    X   X    X     X    .     X     X
# armel  .  .  .  X   .    .    .   .    .     X    .     .     X
# armhf  .  .  .  .   .    .    .   .    .     X    .     .     .
# avr32  X  X  X  X   X    X    X   X    X     X    .     X     X
#  hppa  X  X  X  X   X    X    X   X    X     X    .     X     X
#  i386  X  X  X  X   X    X    X   X    X     X    .     X     X
#  ia64  X  X  X  X   X    X    X   X    X     X    .     X     X
#  lpia  .  .  .  .   .    .    .   .    .     X    .     .     .
#  m32r  X  X  X  X   X    X    X   X    X     X    .     X     X
#  m68k  X  X  X  X   X    X    X   X    X     X    X     X     X
#  mips  X  X  X  X   X    X    X   X    X     X    .     X     X
# mipse  X  X  X  X   X    X    X   X    X     X    .     X     X
# ppc64  X  X  X  X   X    X    X   X    X     X    .     X     X
#  s390  X  X  X  X   X    X    X   X    X     X    .     X     X
# s390x  X  X  X  X   X    X    X   X    X     X    .     X     X
#   sh3  X  X  X  X   X    X    X   X    X     X    .     X     X
# sh3eb  X  X  X  X   X    X    X   X    X     X    .     X     X
#   sh4  X  X  X  X   X    X    X   X    X     X    .     X     X
# sh4eb  X  X  X  X   X    X    X   X    X     X    .     X     X
#   x32  .  .  .  .   .    .    .   .    .     X    .     .     .

my $Cpus = join '|', 
  qw| alpha  amd64 arm arm64 armeb  armel armhf avr32 hppa i386 ia64  lpia
      m32r  m68k mips mipsel powerpc powerpcspe ppc64 s390 s390x sh3 sh3eb
      sh4           sh4eb            sparc           sparc64           x32 |;
my $Oses    = join '|',
  qw| darwin freebsd hurd kfreebsd knetbsd kopensolaris mint netbsd openbsd
      solaris                     uclibc-linux                      uclinux |;
my $Extras  = q{all|any|source};

pattern
  name   => [ qw| debian architecture | ],
  create =>
    q|(?<![0-9a-z-])|          .
    qq{(?k:(?k:$Extras)|}      .
    qq{(?:(?k:$Oses|any)-)?}   .
    q|(?k:|                    .
      qq{(?<=-)(?:$Cpus|any)|} .
      qq{(?<!-)(?:$Cpus))}     .
    q|)(?![0-9a-z-])|;

=item B<$RE{debian}{archive}{binary}>

    'abc_1.2.3-512_all.deb' =~ $RE{debian}{archive}{binary}{-keep};
    print "     package is -> $2";
    print "     version is -> $3";
    print "architecture is -> $4";

This is Debian binary archive (even if there's no binary file (in B<-B> sense)
inside it's called "binary" anyway).
When Debian policy and B<deb(5)> talk about "format" it's about internals but
name.
If you think about it, then it's clear that neither B<dpkg(1)> nor B<apt(1)>
nor any other alternative cares what is a B<basename> of particular binary
archive.
It turns out that only authority on naming binary archives is what actualy
creates them.
Indeed, B<dpkg-deb(1)> clearly states its intentions in very first entry
I<-b, --build directory [archive|directory]>.

=over

=item I<$1> is I<deb_filename>

That's the whole archive filename with C<.deb> suffix included
B<(bug)>
C<.udeb> is suffix too.

=item I<$2> is I<package>

=item I<$3> is I<version>

There's a big deal of WTF.
I<Filename:> in F<*_Packages> miss I<epoch> at all.
Archives in F<pool/> miss them too.
Archives in F</var/cache/apt/archives> ...
That seems to be C<apt-get> specific (I don't have reference to code though).
As a feature B<$RE{d}{a}{binary}> provides an I<epoch> hack in filenames.

B<(bug)>
That extra inteligence should be configurable.

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<architecture>

B<(bug)>
That would match surprising C<source> or C<any>.
Actually that's even worse:  I<OS> can prepend any I<arch> or I<special>.
Shortly:  doesn't work with ports.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# FIXME:201401032248:whynot: Architecture mess should be fixed.
# CHECK:201401030019:whynot: B<debian-policy>, version 3.9.3.1, 3.0
# CHECK:201401030019:whynot: L<deb(5)>, version 1.16.10
# CHECK:201401030020:whynot: L<dpkg-deb(1)>, version 1.16.10

pattern
  name   => [ qw| debian archive binary | ],
  create =>
# TODO: Should piggyback on B<package>, B<version>, and B<arch>
    q|(?k:|                                     .
      qq|(?k:$pMagic)_|                         .
      qq|(?k:(?:[0-9]+%3a)?[$Magic-]+)_|        .
      qq{(?k:(?:(?:$Oses)-)?(?:$Cpus|$Extras))} .
    qq|\\.deb)(?![$Magic-])|;

=item B<$RE{debian}{archive}{source_1_0}>

    'xyz_1-ab.25~6.orig.tar.gz' =~ $RE{debian}{archive}{source_1_0}{-keep};
    print "package is $2";
    index($3, '-') && $4 eq 'tar' and die;
    $4 eq 'orig.tar'              and print "there should be patch";

This is Debian upstream (or Debian-native) source tarball.
Naming source archives is outside Debian policy;
although

=over

=item *

S<Section 5.6.21> mentions that "the exact forms of the filenames are described
in" S<Section C.3>.

=item *

S<Section C.3> points that source archive must be in form
F<B<package>_B<upstream-version>.orig.tar.gz>.

=item *

Naming Debian-native packages is left completely.

=item *

B<dpkg-source(1)> (at least of B<1.15.2>) shows real life and makes all that a
bit more complicated.
See section S<B<SOURCE PACKAGE FORMATS>> of B<dpkg_source(1)> for details.

=back

C<v0.2.3>
At that point an incompatible change has been made.
B<$RE{d}{a}{source}> has been renamed to B<$RE{d}{a}{source_1_0}>
(what in fact it always was).
Probably one day there could be an agregating B<$RE{d}{a}{source}> that would
match any source filename (if there would be any purpose for).
More on different formats below.

=over

=item C<Format: 1.0>

It's either set of F<*.orig.tar.gz> and acompaning F<*.diff.gz> or lone
F<*.tar.gz> (then that's 'native').
That is covered by B<$RE{d}{a}{source_1_0}>

=item C<Format: 2.0>

That's supposedly unseen in wild.
B<dpkg-source(1)> doesn't say what filenames represent it.
Probably those of C<Format: 3.0 (quilt)>
(refer to
L<B<$RE{d}{a}{source_3_0_quilt}>|/$RE{debian}{archive}{source_3_0_quilt}> for
details).
Not implemented.

=item C<Format: 3.0 (native)>

At that point C<Format: 1.0> has been split.
Debian B<native> packages (those without F<*.debian.tar.gz>) are of this type.
Implemented in
L<B<$RE{d}{a}{source_3_0_native}>|/$RE{debian}{archive}{source_3_0_native}>.

=item C<Format: 3.0 (quilt)>

Those B<with> F<*.debian.tar.gz> are of this second format.
Very hot.
Implemented in
L<B<$RE{d}{a}{source_3_0_quilt}>|/$RE{debian}{archive}{source_3_0_quilt}> and
L<B<$RE{d}{a}{patch_3_0_quilt}>|/$RE{debian}{archive}{patch_3_0_quilt}>.
Refer to respective sections, details are huge.

=item C<Format: 3.0 (custom)>

A secret format.
Probably
L<B<$RE{d}{a}{source_3_0_quilt}>|/$RE{debian}{archive}{source_3_0_quilt}>
would suffice.
Not implemented.

=item C<Format: 3.0 (git)>

=item C<Format: 3.0 (bzr)>

Those are secret too.
And again, I believe,
L<B<$RE{d}{a}{source_3_0_quilt}>|/$RE{debian}{archive}{source_3_0_quilt}>
would be enough.
Not implemented.

=back

And now miserable notes about B<$RE{d}{a}{source_1_0}>:

=over

=item I<$1> is I<tarball_filename>

Since there's no other suffix, but F<.gz> it's present only in
I<tarball_filename>

=item I<$2> is I<package>

=item I<$3> is I<version>

There's a bit (or pile) of complication.
Look, if I<version> contains minus (C<->), that means that resulting binary
must
have I<debian_revision> set (otherwise that minus must not be here), thus
implying presense of F<*.diff.gz>, thus implying I<type> must be C<orig.tar>
but
simple C<tar> (what would be Debian native package).
OTOH, if there is no minus, then I<type> could be
either C<orig.tar> or C<tar>.
Obviously lack or presence of F<*.diff.gz> falls out of knowledge of
B<$RE{d}{a}{source_1_0}>.

B<(bug)>
That should fail this C<package_0.orig-component.tar.gz>.
It doesn't
(L<B<$RE{d}{a}{source_3_0_native}> for details|/$RE{debian}{archive}{source_3_0_native}>).

B<(caveat)>
Consider this: C<package_0-1.debian.tar.gz>.
Is it debian-native (I<version> would be C<0-1.debian>) of C<Format: 1.0>;
or is it debianization tar (I<version> would be C<0-1>) of
C<Format: 3.0 (quilt)>?
Without checking I<Format:> entry it's impossible to say.
(Are you wondering about hyphen?
Think again (C<unattended-upgrades_0.25.1debian1-0.1> is debian-native).)
The good news is that (at time of writing) I've found none debian-native
package (of either I<Format:>) which I<Version:> would match
C<qr/debian$/>.
(Let's check it tomorrow.)
And back to the subject: C<package_0.debian.tar.gz> is implicitly prohibited.

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<type>

This can hold one of 2 strings (C<orig.tar> (regular package) or C<tar>
(Debian-native package)).

B<(bug)>
Probably that should look behind (if that would be that possible) for hyphen
(C<->) in
I<version>.
It doesn't.
Because it's OK to have hyphen in Debian-native packages
(C<francine_0.99.8orig-6.tar.gz>).

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# TODO:201401091839:whynot: Please backup your bogus claims.
# FIXME:20100803184421:whynot: Exclude C<.orig-component.> (variable-length qr/(?<!)/ is needed for this).
# FIXME:20100731131608:whynot: I<$4> should look behind if that could be C<tar>.

pattern
  name   => [ qw| debian archive source_1_0 | ],
  create =>
    q|(?k:|                                   .
      qq|(?k:$pMagic)_|                       .
# XXX: Yes, must be ungreedy
      qq|(?k:[$Magic-]+?)|                    .
      q|\.(?k:(?:orig\.)?(?<!\.debian\.)tar)| .
    qq|\\.gz)(?![$Magic-])|;

=item B<$RE{debian}{archive}{source_3_0_native}>

    'xyz_1234.tar.lzma' =~ $RE{debian}{archive}{source_3_0_native}{-keep}
    print "package is $2";
    print "version is $3";
    print 'decompress wiht ' .
      $4 eq 'gz'   ? 'gunzip'  :
      $4 eq 'bz2'  ? 'bunzip2' :
      $4 eq 'lzma' ? 'unlzma'  : die;

C<v0.2.5>
That's descandant of
L<B<$RE{d}{a}{source_1_0}>|/$RE{debian}{archive}{source_1_0}> for native
packages (those without F<*.debian.tar.gz>).

=over

=item I<$1> is I<tarball_filename>

C<tar> with delimiting dots (C<.>) is included only here.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(bug)>
That must fail on C<package_0.orig.tar.gz>.
It doesn't because of C<package_0.orig-component.tar.gz>.
It needs variable-length look-behind.

C<package_0.debian.tar.gz> doesn't match.
L<B<$RE{d}{a}{patch_3_0_quilt}>|/$RE{debian}{archive}{patch_3_0_quilt}> matches
instead.

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<suffix>

It's either C<gz>, C<bz2>, C<lzma>, or C<xz>.
Anything else (missing counts as anything) would fail the whole pattern.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# FIXME:20100803184303:whynot: Exclude C<.orig-component.> (variable-length qr/(?<!)/ is needed for this).
# FIXME:20100803184706:whynot: Exclude C<.orig.> (useles with left in the previous one).
# TODO:20100803115330:whynot: Enforce lowercase of I<package>.
# CHECK:201401032007:whynot: L<dpkg-source(1)>, 1.16.10

pattern
  name   => [ qw| debian archive source_3_0_native | ],
  create =>
    q|(?k:|                         .
      qq|(?k:$pMagic)_|             .
      qq|(?k:[$Magic-]+?)|          .
      q|(?<!\.debian)\.tar|         .
      q{\.(?k:gz|bz2|lzma|xz)}      .
    qq|)(?![$Magic-])|;

=item B<$RE{debian}{archive}{source_3_0_quilt}>

    'xyz_1-ab.25~6.orig-cool-stuff.tar.bz2' =~ $RE{debian}{archive}{source_3_0_native}{-keep};
    print "package is $2";
    print "version is $3";
    print "component happens to be $4" if $4;
    print 'decompress with ' .
      $5 eq 'gz'   ? 'gunzip'  :
      $5 eq 'bz2'  ? 'bunzip2' :
      $5 eq 'lzma' ? 'unlzma'  :
      $5 eq 'xz'   ? 'unxz'    : die;

C<v0.2.4>
That's descendant of
L<B<$RE{d}{a}{source_1_0}>|/$RE{debian}{archive}{source_1_0}> for non-native
debian packages (those with F<*.debian.tar.gz>).
B<(note)>
Also C<Format: 3.0 (quilt)> invents a concept of components.

=over

=item I<$1> is I<tarball_filename>

Delimiting dots (C<.>), C<orig>
(with or without (if missing) component delimiting hyphen (C<->)),
and C<tar> are present here only.
The I<component> itself is present in I<component>.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<component>

The 'component' is specially packed piece of upstream
sources (being it packed this way by either upstream or Debian).
It's not a patch.
Thus it's here (B<$RE{d}{a}{source_3_0_quilt}> but
L<B<$RE{d}{a}{patch_3_0_quilt}>|/$RE{debian}{archive}{patch_3_0_quilt}>).
The component name is either present or missing completely, so this is invalid:

    null-component-package_01234.orig-.tar.gz

Although this is perfectly valid:

    strange-component-package_98765.orig--.tar.gz

B<dpkg-source(1)> is unclear about this, but my understanding is that component
name is closer to I<package> (thus lowercase only) then I<version> (mixed
case).
However that's not yet enforced.

=item I<$5> is I<suffix>

It's either C<gz>, C<bz2>, C<lzma>, or C<xz>.
Anything else (missing counts as anything) would fail the whole pattern.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# TODO:20100802182640:whynot: Enforce lowercase of I<package> and I<component>.
# CHECK:201401032010:whynot: L<dpkg-source(1)>, 1.16.10

pattern
  name   => [ qw| debian archive source_3_0_quilt | ],
  create =>
    q|(?k:|                               .
      qq|(?k:$pMagic)_|                   .
      qq|(?k:[$Magic-]+?)|                .
      q|\.orig(?:-(?k:[a-z0-9-]+))?\.tar| .
      q{\.(?k:gz|bz2|lzma|xz)}            .
    qq|)(?![$Magic-])|;

=item B<$RE{debian}{archive}{patch_1_0}>

    'abc_0cba-12.diff.gz' =~ $RE{debian}{archive}{patch_1_0}{-keep};
    print "package is $2";
    -1 == index $3, '-' and die;
    print "debian revision is ", (split /-/, $3)[-1];

This is "debianization diff" (S<Section C.3> of Debian policy).
Naming patches is outside Debian policy;
So we're back to guessing.
There're rumors (or maybe trends) that B<S<Format 1.0>> will be deprecated (or
maybe obsolete).

C<v0.2.6>
Incompatible change.
B<$RE{d}{a}{patch}> has been renamed into B<$RE{d}{a}{patch_1_0}>.

=over

=item I<$1> is I<patch_filename>

Since there's no other suffix, but F<.diff.gz> it's present only in
I<patch_filename>.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(caveat)>  Consider this.
A Debian-native package misses a patch and hyphen in I<version>.
A regular package has a patch and must have hyphen in I<version>.
B<$RE{d}{a}{patch_1_0}> is absolutely ignorant about that
(we are about matching but verifying after all).

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# CHECK:201401032014:whynot: L<dpkg-source(1)>, version 1.16.10

pattern
  name   => [ qw| debian archive patch_1_0 | ],
  create =>
    q|(?k:|                         .
      qq|(?k:$pMagic)_|             .
      qq|(?k:[$Magic-]+?)|          .
    qq{\\.diff\\.gz)(?![$Magic-])};

=item B<$RE{debian}{archive}{patch_3_0_quilt}>

    'abc_0cba-12.debian.tar.lzma' =~ $RE{debian}{archive}{patch_3_0_quilt}{-keep};
    say "package is $2";
    -1 == index $3, '-' and die;
    print "debian revision is ", (split /-/, $3)[-1];
    print 'decompress with ' .
      $4 eq 'gz'   ? 'gunzip'      :
      $4 eq 'bz2'  ? 'bunzip2'     :
      $4 eq 'lzma' ? die 'stinks!' :
      $4 eq 'xz'   ? 'unxz'        : die;

Since C<Format: 3.0 (quilt)> has been invented, debianization stuff has changed
form from one big diff
(F<*.diff.gz>, L<B<$RE{d}{a}{patch_1_0}>|/$RE{debian}{archive}{patch_1_0}>)
to debianization stuff (placed in F<debian/>) and set of diffs (if any)
(intended to be placed in F<debian/patches/>) in form of single
tar-file (F<*.debian.tar.gz>).

=over

=item I<$1> is I<tar_filename>

C<debian.tar> with delimiting dots (C<.>) is seen here only.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<suffix>

It's either C<gz>, C<bz2>, C<lzma>, or C<xz>.
Anything else (missing counts as anything) would fail the whole pattern.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# TODO:20100803141628:whynot: Enforce lowercase apropriately.
# CHECK:201401032058:whynot: L<dpkg-source(1)>, 1.16.10

pattern
  name   => [ qw| debian archive patch_3_0_quilt | ],
  create =>
    q|(?k:|                         .
      qq|(?k:$pMagic)_|             .
      qq|(?k:[$Magic-]+?)|          .
      q|\.debian\.tar|              .
      q{\.(?k:gz|bz2|lzma|xz)}      .
    qq|)(?![$Magic-])|;

=item B<$RE{debian}{archive}{dsc}>

    'abc_0cba-12.dsc' =~ $RE{debian}{archive}{dsc}{-keep};
    print "package is $2";
    print "version is $3";

This is "Debian source control" (S<Section 5.4> describes its contents but
naming).
Statistically based guessing, you know
(once I'll elaborate to point exact lines in B<dpkg-dev> bundle where it's in
use (creating and parsing)).

=over

=item I<$1> is I<dsc_filename>

As usual, since the only suffix can be F<.dsc> it's present in I<dsc_filename>
only.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=back

B<(caveat)>
L<"caveat #2: suffix could be in version">

=cut

# CHECK:201401032237:whynot: B<debian-policy>, version 3.9.3.1, 5.4
# CHECK:201401032240:whynot: L<$RE{d}{a}{source_1_0}> is still valid

pattern
  name   => [ qw| debian archive dsc | ],
  create =>
    q|(?k:|                         .
      qq|(?k:$pMagic)_|             .
      qq|(?k:[$Magic-]+?)|          .
    qq{\\.dsc)(?![$Magic-])};

=item B<$RE{debian}{archive}{changes}>

    'abc_0cba-12.changes' =~ $RE{debian}{archive}{changes}{-keep};
    print "package is $2";
    print "version is $3";

This is "Debian changes file" (S<Section 5.5> describes its contents but
naming).
B<dpkg-genchanges(1)> is silent too.
So this pattern is based on observation too.

=over

=item I<$1> is I<changes_filename>

As usual, since the only suffix can be F<.changes> it's present in
I<changes_filename> only.

=item I<$2> is I<package>

=item I<$3> is I<version>

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<architecture>

B<(caveat)>
L<"caveat #2: suffix could be in version">

=back

=cut

# FIXME:201401032247:whynot: Architecture mess should be fixed.
# CHECK:201401032244:whynot: B<debian-policy>, 3.9.3.1, 5.5
# CHECK:201401032247:whynot: L<$RE{d}{a}{b}> is still valid

pattern
  name   => [ qw| debian archive changes | ],
  create =>
    q|(?k:|                                     .
      qq|(?k:$pMagic)_|                         .
      qq|(?k:[$Magic-]+?)_|                     .
      qq{(?k:(?:(?:$Oses)-)?(?:$Cpus|$Extras))} .
    qq{\\.changes)(?![$Magic-])};

=item B<$RE{debian}{sourceslist}>

    'deb file:/usr/local oldstable main contrib non-free' =~ $RE{debian}{sourceslist}{-keep} and
      system "rm -rf $5" or die;
    ($4 eq 'http' || $4 eq 'rsh' || $4 eq 'ssh') &&
      !index $5, '//' or die;
    ($4 eq 'file' || $4 eq 'cdrom' || $4 eq 'copy') &&
      !index($5, '/') && index($5, '/', 1) > 1 or die;
    index(reverse($6), '/') || $7 or die;

This is one entry in F<sources.list> resource list.
The format is described in B<sources.list(5)> man page
(hence a chance for desincronization provided)
(gosh, it's not B<debian> any more, it's B<APT>).

B<(bug)>
It just come to my attention, between C<deb> and I<uri> there could be
I<options>.
Missing so far.

=over

=item I<$1> is I<resource_entry>

B<$RE{d}{sourceslist}> is very permissive about what would constitute entries,
but you can bet on -- the whole entry stays on one line.

=item I<$2> is I<resource_type>

That can be either C<deb> or C<deb-src>.
Implicit negative lookbehind for C<qr/\w/> provided
(so C<=deb> is accepted, C<_deb> is not;
hey, C<#deb> is accepted too!
explicit anchoring at your option).

=item I<$3> is I<uri>

You think you know what URI is?
Read below...

=item I<$4> is I<scheme>

Schemes that B<APT> knows have nothing to do with B<sources.list(5)> actually.
I<scheme> that B<APT> will use is some executable in F</usr/lib/apt/methods>
(some of them are for transfer, some are not).
B<sources.list(5)> (of C<0.9.7.8>) defines these:

=over

=item local filesystem

C<file>, C<cdrom>, C<copy>.

=item network

C<http>, C<ftp>, C<rsh>, C<ssh>

=back

Delimiting colon C<:> isn't included here
(although I<uri> does).

B<(bug)>
It just come to my attention (C<0.9.7.8>) I<scheme> can be anything
(to some degree).

=item I<$5> is I<hier_path>

The idea is that someday B<$RE{d}{sourceslist}> would look behind at I<uri> to
decide if there should be I<authority>
(that one delimited with C<//>)
or I<path_absolute> would be enough.
Right now that's not the case.
B<(bug)> Any non-space sequence is I<hier_path>.

That's very bad, but that's the way it's done right now.
Look, parsing URI is a task for standalone B<pattern>.
It's not implemented, maybe someday some kind perlist would do that.
Yes, I know about B<Regexp::Common::URI>.
Apparently B<R::C::U> knows nothing about C<cdrom:>.

=item I<$6> is I<distribution>

Debian is full of surprises.
Lots of surprises.
You think you know what I<distribution> is, don't you?
You missed.
I<distribution> can be filesystem path.
Since B<sources.list(5)> doesn't mention space escaping techniques I assume
spaces aren't allowed;
so any no-space is allowed.
You think that's an overkill?
You're obviously wrong
(think C<$ARCH>, B<sources.list(5)> has more).

=item I<$7> is I<component_list>

In misguided attempt not to make them too different with all that crowd,
I<component_list> is space delimited list of non-spaces.
If I<distribution> ends with slash (C</>), then I<component_list> can be
empty
(I've meant, maybe someday that will look-behind too).

=back

=cut

# CHECK:201401040046:whynot: L<sources.list(5)>, version 0.9.7.8

pattern
  name    => [qw| debian sourceslist |],
  version =>                      5.010,
  create  =>
    q|(?k:| .
      q|(?k:(?<!\w)deb(?:-src)?)\h+|                      .
      q|(?k:|                                             .
        q{(?k:file|http|ftp|cdrom|copy|rsh|ssh):}         .
        q|(?k:[[:graph:]]+))\h+|                          .
      q|(?k:[[:graph:]]+)|                                .
      q|(?:\h+|                                           .
      q{(?k:[[:graph:]]+(?=\h|\z)(?:\h+[[:graph:]]+)*))*} .
                                   q|)|;

=item B<$RE{debian}{preferences}>

    <<END_OF_PREFERENCES =~ $RE{debian}{preferences{-keep}} or die;
    Explanation: Stay updated!
    Package: perl
    Pin: version 5.10*
    Pin-Priority: 1001
    END_OF_PREFERENCES
    $2 eq 'perl' and
      print "good, we are looking for perl\n";
    $3 eq 'version' and $4 =~ /^5\.10/ and
      print "good, we are looking for recent\n";
    $5 =~ /^\d+$/ && $5 > 1000 and
      print "good, we'll stay updated\n";

This is one entry in F<preferences> list.
Good news are over, bad news are below.
I've failed to find B<definition> of entry in F<preferences>
(still looking).
B<apt_preferences(5)> suggests on what that looks like providing examples.
It's not enough;
C<apt-cache policy> behaviour leads from understanding either.

After some experimenting I've found that:
In general this is Debian control file format.
With some quirks provided.
So here we are -- some common case of entry in F<preferences>.

B<(bug)>
C<v0.2.12>
Somewhere on the span C<lenny>/C<squeeze>/C<wheezy> treating F<preferences>
has changed so much that B<$RE{d}{p}> needs total rework.
Now there're:  globs, POSIX extended re, star has explict meaning, and
probably more (reading changelog leaves very unhappy feeling).
So, whatever is said hereafter, describes what this re is doing but what
F<preferences> might look like.

Shortly:

=over

=item *

each entry consists of 3 stanzas (I<Package:>, I<Pin:>, I<Pin-Priority:>);

=item *

the order matters, no intermediate stanza is allowed;

=item *

case doesn't matter (for both name and value of stanza (to some degree));

=item *

whatever has gone before I<Package:> or came after I<Pin-Priority:> (line-wise)
is ignored;

=item *

C<apt-cache policy> fails in one case -- I<Package:> stanza has leading spaces;

=item *

misparsed values are ignored,
thus invalidating the whole entry (but see below),
thus the entry is ignored.

=back

That's what B<$RE{debian}{preferences}> does.
More on each stanza below.

B<(bug)>  C<apt-cache policy> will accept newlines -- those are spaces in
Debian control files, while consequent lines proper indentation provided.
B<$RE{d}{preferences}> accepts one line stanzas only.

=over

=item I<$1> is a I<preferences_entry>

That's the whole entry -- with all leading and trailing spaces, and an Easter
Eggs.
B<apt_preferences(5)> invents something called I<Explanation:> stanzas
(they should go before I<Package:>, with no empty lines in between).  
Since we are aware of that, I<Explanation:> sequence is provided in
I<preferences_entry>
(and it won't be ever I<package_stanza>
(1st, obvious compatibility reasons;
2nd, it's somewhat legalized since it's mentioned;
3rd, it can be easily dropped in case I found that useful)).

=item I<$2> is a I<package_stanza>

That's either C<*> (star, match-any-string wildcard) or space separated list of
package names
(alone package name is degenerated list).
That is, if I<package_stanza> is a list, than each (even if there's only one)
non-space sequence is treated as package name.
C<apt-cache policy> doesn't seem to verify its input,
so one can put here anything.
Then those sequences will be matched literally against known package names.

B<(feature)>  In contrary with everything else, in B<$RE{d}{preferences}>,
package names are case-sensitive.

B<(bug)>  C<apt-cache policy> will silently accept star among package names.
Then, since no-one package name matches (there can't be a package named C<*>)
the star will be missing among pinned packages.
B<$RE{d}{preferences}> rejects such strings.

=item I<$3> is a I<context_switch>

I<Pin:> stanza is broken in two parts.
That's the first one.
One of 3 acceptable strings are C<version>, C<origin>, or C<release>.
Bad news below.

=item I<$4> is a I<context_filter>

B<(bug)>  (what else?)  What would be a correct input here depends on
I<context_switch>.
B<$RE{d}{preferences}> takes anything up to the next newline.

=item I<$5> is a I<pin_priority_stanza>

In I<pin_priority_stanza> will be a sequence of decimal numbers
(yes, hexadecimals are rejected and octals aren't converted),
optionally prepended with C<+> (plus) or C<-> (minus) signs up to surprising
C<.> (dot).
Any trailing decimals and dots (after the first one) will be ignored by
C<apt-cache policy>.
So does the B<$RE{d}{preferences}> too.
The optional dot-decimal trailer will be missing in I<pin_priority_stanza>,
but present in I<prererences_entry>.

=back

It's a mess, isn't it?
Go figure.

=cut

# FIXME:201401062348:whynot: Please verify your bogus claims.
# TODO:20100804123053:whynot: Please verify your bogus claims.
# CHECK:20100727194229:whynot: L<apt_preferences(5)>, version 0.7.21

pattern
  name    => [qw| debian preferences |],
  version =>                      5.010,
  create  =>
    q|(?k:(?ism)(?:^Explanation:[^\n]*\n)*|         .
# TODO: Match multiline values.
      q|^Package:\h*|                               .
        q{(?k:\*|}                                  .
# FIXME: Should canibalize B<$RE{debian}{package}>
        qq{(?-i:$pMagic(?:\\h+$pMagic)*)+)}         .
      q|\h*\n|                                      .
      q|Pin:\h*|                                    .
        q{(?k:version|origin|release)\h+}           .
# TODO: Should check I<$3> and then be more strict with I<$4>
        q{(?k:[^\n\h]+(?:\h+[^\n\h]+)*)}            .
      q|\h*\n|                                      .
      q|Pin-Priority:\h*|                           .
        q|(?k:[-+]?\d+)(?:[.\d]+)?|                 .
      q{\h*\n(?=\n|\z)}                             .
                                   q|)|;

=item B<$RE{debian}{changelog}>

    <<END_OF_CHANGELOG =~ $RE{debian}{changelog{-keep}} or die;
    perl (6.0.0-1) unstable; urgency=high
      * Hourah!
     -- John Doe <doe@example.tld>  Thu, 01 Apr 2010 00:00:00 +0300
    END_OF_CHANGELOG
    print <<"END_OF_REPORT"
    package        : $2
    version        : $3
    in archive     : $4
    flags          : $5
    changes        :
    ${6}uploaded by    : $7
    achknowledgment: $8
    at time        : $9

This is one entry in F<debian/changelog>.
The format is described in S<Section 4.4> of Debian Policy.
In real world parsing of this file is done by parser script.
F</usr/lib/dpkg/parsechangelog/debian> is a Perl script,
that's called from B<dpkg-parsechangelog>
(of B<dpkg-dev> package (that in turn is Perl script, again)).

There're 2 special Perl modules
(namely: B<Debian::ParseChangelog> (of CPAN),
and B<Dpkg::Changelog> (of B<dpkg-dev> package)).
And now there'is 3rd one (how cute).
Those former are read/write engines, B<$RE{debian}{changelog}> is
read-only (for obvious reasons).
There's a point of desincronization though.

Until Debian Policy C<v3.8.1.0> there was an option of providing
F<debian/changelog> in different format.
However [489460@bugs.debian.org] had made it.
Now that option has gone.
However, B<dpkg-parsechangelog(1)> describes how those are introduced and
handled.

=over

=item I<$1> is a I<changelog_entry>

That's the whole entry of
header,
delimiting empty lines (if any),
and sig-line (with trailing newline).
That seems (that's not set explicitly in the debian-policy) that there must be
intermediate empty line (what's 'empty line', btw?).
And the latest entry in changelog must start with at the very first line.
B<$RE{d}{a}{changelog}> pays no attention.

=item I<$2> is a I<debian_package>

B<(bug)>
Just a sequence of characters allowed in Debian's package name.
No other restrictions provided.

=item I<$3> is a I<debian_version>

Surrounding braces aren't included.

B<(bug)>
That's a simplified too.

B<(caveat)>
C<v0.2.3>
L<"caveat #1: I<version> starts with letter">.

=item I<$4> is I<distributions>

C<v0.2.8>
That's space (C<S< >>) separated sequence of letters (C<S<a .. z>>)
(caseless, enforced) and hyphens
(C<->) in any order,
except first character should be letter (weird).
Space before terminating semicolon is disallowed
(it's not missing in I<distributions>, it fails entry).
Terminating semicolon isn't included.

=item I<$5> is I<keys> (or I<urgency>, if you like)

B<(note)> Debian Policy explicitly states that that field is supposed to be a
comma (C<,>) separated list of equal (C<=>) separated key-value pairs.
However the only known I<key> is C<urgency>.
Maybe I'm too pesimistic,
but despite the fact that the only I<key> allowed is C<urgency> the whole
I<key>=I<value> pair is put in I<keys> --
so you've better be prepared and pick a I<key> you're looking for
(one day you can get a lot more).

B<(caveat)>
C<v0.1.5>
I wasn't enough pessimistic.
B<perl5.8.8> goes nuts sometimes looking for C<urgency>
(it happens to be an anchor)
(namely: C<libcompress-zlib-perl_2.015-1>)
(B<perl5.10.0> is OK).
In misguided attempt to support oldstable
B<$RE{d}{changelog}> no more looks for C<urgency>,
it looks for a sequence of lowercase letters.
(And anchor is C<\040--\040> of sig-line now.)
Sorry.

B<(caveat)>
C<0.2.8>
Log entry of C<binutils_2.7-5> invents concept of something.
Let's call it comment (or wish).
Thus anything that's not comma-separated equal-separated key-value pair is
skipped (from I<keys>).
Obviously, it's present in I<changelog_entry>

=item I<$6> is I<changes>

That invents concept of empty line.

C<v0.2.8>
For B<$RE{d}{changelog}> "empty line" consists of any number horizontal spaces
(C<qr/\h/>)
followed by newline.
OTOH, "line" is at least two spaces (one tab counts as at least two spaces)
then any non-space character, and anything up to
next newline
(space counts as "anything" for now).
No or one space followed by non-space fails entirely
(but watch for trailing signature line).
As requested by Debian Policy (or stock parser) leading and trailing empty
lines are ignored
(they are included in I<changelog_entry> though).

B<(bug)>
Handling trailing empty lines is broken.
It's useles to describe what empty lines and what number of empty lines will
end up in I<changes>.
B<$RE{d}{changelog}> must be redone.

B<(caveat)>
The recommended way of outlineing I<changes> is starting each subentry with
star (C<*>), then adding at least one space to sub-subentries.
OTOH, the modern way to highlight work done by different maintainers
(or probably non-maintainers at all)
is by placing maintainer name in brackets
(with two leading spaces).
B<$RE{d}{changelog}> accepts anything.

B<(note)> (I can't say is it a bug or feature)
The leading and trailing empty lines are said to be optional.
However one leading and one trailing empty line are present in each (decent?)
entry in Debian changelog file.
B<$RE{d}{changelog}> doesn't insist on that.

=item I<$7> is a I<maintainer_name>

B<$RE{d}{changelog}> is very permissive about what is I<maintainer_name>
(and what it is actually?).
I<email_address> and I<changelog_date> take care of themselves.
A leading space-then-double-hyphen and separating space aren't included.

C<v0.2.10>
Any number of space (but null) could be between double-hyphen and
I<maintainer_name>
(C<libnet-daemon-perl_0.30-1>).

=item I<$8> is an I<email_address>

That one (with option to I<maintainer_address>) is subject to be processed with
B<Regexp::Common::Email::Address>
(or not, under consideration).
Anyway, right now it's a sequence of non-spaces surrounded by angle brackets.
Surrounding brackets aren't included.

=item I<$9> is a I<changelog_date>

That one is subject to be processed with B<Regexp::Common::Time>.
Anyway, right now it's a sequence of RFC822-date forming characters,
starting with capital letter and terminated with decimal number.
Neither leading double-space nor trailing newline are included.

C<v0.2.9>
B<debian-policy> invents an option of 'time zone name or abbreaviation
optionally present as a comment in parentheses'.
Such comment would be included in I<changelog_entry> but missing in
I<changelog_date>.
Moreover, if that comment would fall on the next line it will be ignored.
All that parody will suffer rewrite in next turn.

B<(bug)>
C<v0.2.12>
B<debian-policy> C<v3.9.0.0> states what "date" is.
As usual.

B<(caveat)>
There could be spaces after last number.
They aren't included in I<changelog_date>.
And yes, they are present in I<changelog_entry> though.

=back

Pity on me.

=cut

# FIXME:20100808192152:whynot: C<qr/\G/>
# CHECK:201401062351:whynot: B<debian-policy>, version 3.9.3.1, 4.4
# CHECK:201401070017:whynot: L<dpkg-parsechangelog(1)>, 1.16.10

pattern
  name    => [qw| debian changelog |],
  version =>                    5.010,
  create  =>
# FIXME: Should canibalize B<$RE{d}{package}> and B<$RE{d}{version}>
    q|(?k:(?sm)^|                                                          .
      qq|(?k:$pMagic)\040|                                                 .
      qq|\\((?k:[$Magic:-]+)\\)\\040|                                      .
      q{(?k:(?i)(?:[a-z][a-z\040-]*))(?<!\040);\040}                       .
      q|(?k:[a-z]+=[A-Za-z]+(?:,[a-z]+=[A-Z-a-z]+)*)(?:(?!\n)[^\n]+)*\n+|  .
      q|(?:[\040\011]*\n)*|                                                .
# TODO:20100805130918:whynot: Probably, lines just shouldn't be greedy.
      q|(?k:(?:|                                                           .
        q(^\040{2}[^\n]+\n|)                                               .
        q(^\040?\011[^\n]+\n|)                                             .
        q{^\h*\n(?!\040--)}                                                .
      q|)+)(?:\h*\n)*|                                                     .
      q|\040--\040+|                                                       .
# FIXME: Should use B<Regexp::Common::Email::Address>
        q|(?k:[^\040\n][^\n]+)(?<!\040)\040|                               .
        q|<(?k:[^\s]+)>\040\040|                                           .
# FIXME:201401072142:whynot: Should use B<Regexp::Common::time>.  Or not.
# FIXME:201401062354:whynot: B<debian-policy> has put description what "date" is.
        q|(?k:(?<=>\040\040)[A-Z][A-Za-z0-9\040,:+-]+[0-9])|               .
        q{(?=\h*(?:\n|\050))}                                              .
             q|\h*(?:\([A-Z]+\))*\n)|;

=back

=head1 BUGS AND CAVEATS

Grep this pod for B<(bug)> and/or B<(caveat)>.
They all are placed in appropriate sections.

However two caveats affect multiple patterns.
They are covered here in details.

=over

=item caveat #1: I<version> starts with letter

B<(caveat)>
C<v0.2.3>
Upon checking what I have in F<*_Packages> I've discovered such thing:
C<cnews_cr.g7-40.4_i386.deb>.
C<cnews> is a package, C<i386> is an architecture.
Then version is C<cr.g7-40.4>?
That doesn't look like it starts with number.
Or does it?

Or mine reading of debian-policy has been a bit vague.
Now I see it clearly states: C<should start with a digit>.
I<should> isn't I<must>.
So from now on: version can start with any...
For B<$RE{debian}{version}> it starts with any version forming character except
colon (C<:>) or hyphen (C<->) (that will be fixed in next turn).
For any other it starts with any VFC without exception.
(C<package_+-12_all.deb> is valid.
And that's me troll?)

=item caveat #2: suffix could be in version

B<(caveat)>
Consider this: C<package_0.tar.gz.tar.gz>
Here the I<version> is C<0.tar.gz>.
Such I<version> could be surprising but otherwise is perfectly valid.
In order to parse it every filename pattern looks ahead if after suffix there's
no version forming character while I<version> parsing section is explicitly
ungreedy.
I believe that's easier then implement semantical checks instead
(C<package_0.diff.gz.diff.gz> is semantically incorrect, it should be
C<pacage_0.diff.gz-1.diff.gz>).
However, none such versions has been found so far.

=item bug #1: no C<pos()>

When working on test-booster for B<$RE{d}{changelog}> I've discovered awful
thing.
C<qr/\G$RE{debian}{changelog}{-keep}/sg> fails.
Subsequent C<pos()> returns C<undef>.
Setting C<pos()> is ignored.
Probably all other patterns are affected too.
I can't say what's a cause.
That will be investigated and hopefully fixed in next turn.

=item note #1: pathetic documentattion

I should admit that at time of writing I was high on changelogs, preferences,
and so on.
Not to say that I was totally tripping on versions.

=back

=head1 AUTHOR

Eric Pozharski, <whynot@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008--2010, 2014 by Eric Pozharski

This library is free in sense: AS-IS, NO-WARANRTY, HOPE-TO-BE-USEFUL.
This library is released under LGPLv3.

=head1 SEE ALSO

L<Regexp::Common>,
L<http://www.debian.org/doc/debian-policy>,
dpkg-architecture(1),
deb(5),
dpkg-source(1),
sources.list(5),
apt_preferences(5),
dpkg-parsechangelog(1),
dpkg-deb(1),

=cut

1;
