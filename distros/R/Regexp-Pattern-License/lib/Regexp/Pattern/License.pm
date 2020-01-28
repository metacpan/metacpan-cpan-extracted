package Regexp::Pattern::License;

use utf8;
use strict;
use warnings;

use Regexp::Pattern::License::Parts;

=head1 NAME

Regexp::Pattern::License - Regular expressions for legal licenses

=head1 VERSION

Version v3.1.100

=cut

our $VERSION = version->declare("v3.1.100");

=head1 DESCRIPTION

L<Regexp::Pattern::License> provides a hash of regular expression patterns
related to legal software licenses.

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=cut

# internal patterns compiled into patterns
#  * must be unique, to not collide at their final use in gen_pat sub
#  * must be a unit, so that e.g. suffix "?" applies to whole chunk
my $B  = '[*]';          # bullet
my $BB = '[*1-9. ]';     # start-of-sentence bullet or count
my $C  = '[(c)]';        # copyright mark
my $CQ = '[:"]';         # colon and maybe one or two quotes
my $D  = '[-]';          # dash
my $DD = '[ - ]';        # dash with space around
my $E  = '[ ]';          # end-of-sentence space
my $EE = '[  ]';         # end-of-paragraph space
my $F  = '[.]';          # full stop
my $HT = '[http://]';    # http/https protocol
my $ND = '[1-9-]';       # number or dash
my $Q  = '["]';          # quote
my $QA = "\['\]";        # apostrophe
my $QB = '["*]';         # quote or bullet
my $SD = '[ -]';         # space or dash

my @_re = (
	[ qr/\Q$BB/, '(?:\W{0,5}\S{0,2}\W{0,3})' ],
	[ qr/\Q$C/,  '(?:©|\(c\))' ],
	[ qr/\Q$CQ/, '(?::\W{0,2})' ],
	[ qr/\Q$D/,  '[–-]' ],
	[ qr/\Q$DD/, '(?: [–—-]{1,2} )' ],
	[ qr/\Q$E/,  '(?:\s{1,3})' ],
	[ qr/\Q$EE/, '(?:\s{1,3})' ],
	[ qr/\Q$F/,  '[.]' ],
	[ qr/\Q$HT/, '(?:(?:https?:?)?(?://)?)' ],
	[ qr/\Q$ND/, '[\d–-]' ],
	[ qr/\Q$Q/,  '(?:\W{0,2})' ],
	[ qr/\Q$QB/, '(?:\W{0,2})' ],
	[ qr/\Q$SD/, '[ –-]' ],

	[ qr/\[à\]/, '(?:[àa]?)' ],
	[ qr/\[é\]/, '(?:[ée]?)' ],
	[ qr/\[è\]/, '(?:[èe]?)' ],
);

my %P;
while ( my ( $key, $val ) = each %Regexp::Pattern::License::Parts::RE ) {
	$P{$key} = $val->{pat};
}

my $the = '(?:[Tt]he )';

my $cc_by_exercising_you_accept_this
	= "By exercising the Licensed Rights \\(defined below\\), You accept and agree to be bound by the terms and conditions of this ";
my $gnu    = '(?:GNU )';
my $gpl    = '(?:General Public Licen[cs]e|GENERAL PUBLIC LICEN[CS]E)';
my $fsf    = "(?:$the?Free Software Foundation)";
my $by_fsf = "(?: (?:as )?published by $fsf)";
my $niv
	= "with no Invariant Sections(?:, with no Front${D}Cover Texts, and with no Back${D}Cover Texts)?";
my $fsf_ul
	= "$fsf gives unlimited permission to copy, distribute and modify it";
my $fsf_ullr
	= "$fsf gives unlimited permission to copy and/or distribute it, with or without modifications, as long as this notice is preserved";

# internal-only patterns
# _lang is "basic variants" regex at <https://stackoverflow.com/a/48300605>
# without upper-case chars (as dictated by DefHash) and no capture groups
my $_delim = '[.(]';
my $_prop  = '(?:[a-z][a-z0-9_]*)';
my $_lang
	= '(?:\([a-z]{2,4}(?:_(?:[a-z]{4}|[0-9]{3}))?(?:_(?:[a-z]{2}|[0-9]{3}))?\))';
my $_notlang = '[a-z0-9_.]';
my $_any     = '[a-z0-9_.()]';

our %RE;

=head1 PATTERNS

=head2 Single licenses

Patterns each covering a single license.

Each of these patterns has exactly one of these tags:
B< type:singleversion:* >
B< type:unversioned >
B< type:versioned:decimal >.

=over

=item * adobe_2006

=cut

$RE{adobe_2006} = {
	name                                => 'Adobe-2006',
	'name.alt.misc.scancode'            => 'adobe-scl',
	'name.alt.org.fedora.synth.nogrant' => 'Adobe',
	'name.alt.org.fedora.web'           => 'AdobeLicense',
	'name.alt.org.spdx'                 => 'Adobe-2006',
	'name.alt.org.tldr' =>
		'adobe-systems-incorporated-source-code-license-agreement',
	caption => 'Adobe Systems Incorporated Source Code License Agreement',
	'caption.alt.org.fedora.web.synth.nogrant' => 'Adobe License',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'You agree to indemnify, hold harmless and defend',
};

=item * adobe_glyph

=cut

$RE{adobe_glyph} = {
	name                                => 'Adobe-Glyph',
	'name.alt.org.fedora.web.mit.short' => 'AdobeGlyph',
	'name.alt.org.spdx'                 => 'Adobe-Glyph',
	caption                             => 'Adobe Glyph List License',
	'caption.alt.org.fedora.web.mit'    => 'Adobe Glyph List Variant',
	'caption.alt.org.tldr'              => 'Adobe Glyph List License',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.sentence' =>
		'and to permit others to do the same, provided that the derived work is not represented as being a copy',
};

=item * afl

=item * afl_1_1

=item * afl_1_2

=item * afl_2

=item * afl_2_1

=item * afl_3

=cut

my $termination_for_patent_including_counterclaim
	= "${BB}Termination for Patent Action$F$E"
	. 'This License shall terminate automatically '
	. 'and You may no longer exercise any of the rights '
	. 'granted to You by this License '
	. 'as of the date You commence an action, '
	. 'including a cross-claim or counterclaim,';

$RE{afl} = {
	name                        => 'AFL',
	'name.alt.org.wikidata'     => 'Q337279',
	caption                     => 'Academic Free License',
	'caption.alt.misc.british'  => 'Academic Free Licence',
	'caption.alt.org.trove'     => 'Academic Free License (AFL)',
	'caption.alt.org.wikipedia' => 'Academic Free License',
	tags                        => ['type:versioned:decimal'],

# TODO: readd when children cover same region
#	'pat.alt.subject.license.scope.line.scope.paragraph' =>
#		"Exclusions [Ff]rom License Grant$F${E}Neither",
};
$RE{afl}{'pat.alt.subject.grant.legal.license'}
	= 'This ' . $RE{afl}{caption} . ' \(the "License"\) applies to';

$RE{afl_1_1} = {
	name                => 'AFL-1.1',
	'name.alt.org.spdx' => 'AFL-1.1',
	caption             => 'Academic Free License Version v1.1',
	tags => [ 'type:singleversion:afl', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'The Academic Free License applies to',
};

$RE{afl_1_2} = {
	name                => 'AFL-1.2',
	'name.alt.org.spdx' => 'AFL-1.2',
	caption             => 'Academic Free License Version v1.2',
	tags => [ 'type:singleversion:afl', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This Academic Free License applies to',
};

$RE{afl_2} = {
	name                => 'AFL-2.0',
	'name.alt.org.spdx' => 'AFL-2.0',
	caption             => 'Academic Free License Version v2.0',
	tags => [ 'type:singleversion:afl', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"its terms and conditions$F$EE"
		. $termination_for_patent_including_counterclaim
		. " for patent infringement",
};

$RE{afl_2_1} = {
	name                => 'AFL-2.1',
	'name.alt.org.spdx' => 'AFL-2.1',
	caption             => 'Academic Free License Version v2.1',
	tags => [ 'type:singleversion:afl', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"its terms and conditions$F$EE"
		. $termination_for_patent_including_counterclaim
		. ' against Licensor or any licensee',
};

$RE{afl_3} = {
	name                           => 'AFL-3.0',
	'name.alt.org.fedora'          => 'AFL',
	'name.alt.org.fsf'             => 'Academic_Free_License_3.0',
	'name.alt.org.osi'             => 'AFL-3.0',
	'name.alt.org.spdx'            => 'AFL-3.0',
	'name.alt.org.tldr.path.short' => 'afl3',
	caption                        => 'Academic Free License version 3.0',
	'caption.alt.org.tldr'         => 'Academic Free License 3.0 (AFL)',
	'iri.alt.old.osi' => 'https://opensource.org/licenses/academic.php',
	tags => [ 'type:singleversion:afl', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"the conditions in Section 1\\(c\\)$F$EE"
		. $termination_for_patent_including_counterclaim
		. ' against Licensor or any licensee',
};

=item * agpl

=cut

$RE{agpl} = {
	name                        => 'AGPL',
	'name.alt.org.gnu'          => 'AGPL',
	'name.alt.org.wikidata'     => 'Q1131681',
	caption                     => 'GNU Affero General Public License',
	'caption.alt.misc.short'    => 'Affero GPL',
	'caption.alt.misc.informal' => 'Affero License',
	'caption.alt.org.gnu'       => 'GNU Affero General Public License (AGPL)',
	'caption.alt.org.wikipedia' => 'GNU Affero General Public License',
	tags =>
		[ 'family:gpl', 'type:versioned:decimal', 'license:contains:grant' ],

	'_pat.alt.subject.name.misc.extra' => [
		"$the?$gnu?Affero $gpl(?: \\(AGPL\\))?$by_fsf?",
		"$the?$gnu?AFFERO $gpl(?: \\(AGPL\\))?$by_fsf?",
		"$the$gnu?AGPL",
		"${gnu}AGPL",
	],
};

=item * aladdin

=item * aladdin_8

=item * aladdin_9

=cut

$RE{aladdin} = {
	name                    => 'Aladdin',
	'name.alt.misc.short'   => 'AFPL',
	caption                 => 'Aladdin Free Public License',
	'caption.alt.org.trove' => 'Aladdin Free Public License (AFPL)',
	tags                    => ['type:versioned:decimal'],

	'pat.alt.subject.grant.scope.line.scope.sentence' =>
		'under the terms of the Aladdin Free Public License',
};

$RE{aladdin_8} = {
	name                    => 'Aladdin-8',
	'name.alt.org.scancode' => 'afpl-8',
	'name.alt.org.spdx'     => 'Aladdin',
	'name.alt.org.debian'   => 'Aladdin-8',
	caption                 => 'Aladdin Free Public License, Version 8',
	tags                    => ['type:singleversion:aladdin'],

	'pat.alt.subject.license.scope.multisection' =>
		"laws of the appropriate country$F${EE}0$F Subject Matter",
};

$RE{aladdin_9} = {
	name                           => 'Aladdin-9',
	'name.alt.org.scancode'        => 'afpl-9',
	'name.alt.org.tldr.path.short' => 'aladdin',
	caption                => 'Aladdin Free Public License, Version 9',
	'caption.alt.org.tldr' => 'Aladdin Free Public License',
	'iri.alt.archive.20130804020135' =>
		'http://www.artifex.com/downloads/doc/Public.htm',
	tags => ['type:singleversion:aladdin'],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This License is not an Open Source license: among other things',
};

=item * apache

=item * apache_1

=item * apache_1_1

=item * apache_2

=cut

$RE{apache} = {
	name                        => 'Apache',
	'name.alt.org.wikidata'     => 'Q616526',
	caption                     => 'Apache License',
	'caption.alt.org.trove'     => 'Apache Software License',
	'caption.alt.org.wikipedia' => 'Apache License',
	'caption.alt.misc.british'  => 'Apache Licence',
	iri  => 'https://www.apache.org/licenses/LICENSE-2.0',
	tags => ['type:versioned:decimal'],

	'.default_pat' => 'name',

# FIXME
	'pat.alt.subject.name' => "$the?Apache(?: Software)? Licen[cs]e",
};

$RE{apache_1} = {
	name                   => 'Apache-1.0',
	'name.alt.org.spdx'    => 'Apache-1.0',
	caption                => 'Apache License 1.0',
	'caption.alt.org.tldr' => 'Apache License 1.0 (Apache-1.0)',
	description            => <<'END',
Identical to BSD (4 clause), except...
* extend advertising clause to also require advertising purpose
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause
* add redistribution-acknowledgement clause
END
	iri  => 'https://www.apache.org/licenses/LICENSE-1.0',
	tags => [
		'type:singleversion:apache',
		'license:contains:license:bsd_4_clause',
		'license:is:grant',
	],

	'pat.alt.subject.license.scope.sentence' => $P{redist_ack_this},
	'pat.alt.subject.license.scope.multisection.part.head' =>
		"$P{repro_copr_cond_discl}$F$EE"
		. "$BB?$P{ad_mat_ack_this}"
		. ' the Apache Group for use in the Apache HTTP server project',
};

$RE{apache_1_1} = {
	name                   => 'Apache-1.1',
	'name.alt.org.osi'     => 'Apache-1.1',
	'name.alt.org.spdx'    => 'Apache-1.1',
	'name.alt.org.tldr'    => 'apache-license-1.1',
	caption                => 'Apache License 1.1',
	'caption.alt.org.osi'  => 'Apache Software License, version 1.1',
	'caption.alt.org.tldr' => 'Apache License 1.1 (Apache-1.1)',
	description            => <<'END',
Identical to BSD (3 clause), except...
* add documentation-acknowledgement clause (as 3rd clause similar to BSD-4-clause advertising clause)
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause
END
	iri => 'https://www.apache.org/licenses/LICENSE-1.1',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Apache_License#Version_1.1',
	tags => [
		'type:singleversion:apache',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
	],

	'pat.alt.subject.license.scope.multisection' =>
		"without prior written permission of(?: \\S+){1,5}$F$EE"
		. 'THIS SOFTWARE IS PROVIDED',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		"(?:Apache License 1${F}1$EE"
		. "Copyright $C 2000 The Apache Software Foundation$F"
		. " All rights reserved$F$EE)?"
		. "$P{repro_copr_cond_discl}$F$EE"
		. "$BB?The end-user documentation included",
};

$RE{apache_2} = {
	name                           => 'Apache-2.0',
	'name.alt.org.osi'             => 'Apache-2.0',
	'name.alt.org.spdx'            => 'Apache-2.0',
	'name.alt.org.tldr.path.short' => 'apache2',
	caption                        => 'Apache License 2.0',
	'caption.alt.org.osi'          => 'Apache License, Version 2.0',
	'caption.alt.org.osi.alt.list' => 'Apache License 2.0 (Apache-2.0)',
	'caption.alt.org.tldr'         => 'Apache License 2.0 (Apache-2.0)',
	iri => 'https://www.apache.org/licenses/LICENSE-2.0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Apache_License#Version_2.0',
	tags => [ 'type:singleversion:apache', 'license:contains:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'How to apply the Apache License to your work',
	'pat.alt.subject.license.scope.multisection' => "Apache License$E"
		. "Version 2.0, January 2004$E"
		. 'How to apply the Apache License to your work',
};

=item * apafml

=cut

$RE{apafml} = {
	name                      => 'APAFML',
	'name.alt.org.fedora'     => 'APAFML',
	'name.alt.org.fedora.web' => 'AdobePostscriptAFM',
	'name.alt.org.spdx'       => 'APAFML',
	caption                   => 'Adobe Postscript AFM License',
	tags                      => ['type:unversioned'],

	'_pat.alt.subject.license.scope.line.scope.sentence' => [
		'AFM files it accompanies may be used',
		'that the AFM files are not distributed',
	],
};

=item * artistic

=item * artistic_1

=item * artistic_1_cl8

=item * artistic_1_perl

=item * artistic_2

=cut

$RE{artistic} = {
	name                        => 'Artistic',
	'name.alt.org.wikidata'     => 'Q713244',
	caption                     => 'Artistic License',
	'caption.alt.org.trove'     => 'Artistic License',
	'caption.alt.org.wikipedia' => 'Artistic License',
	'caption.alt.misc.british'  => 'Artistic Licence',
	tags                        => ['type:versioned:complex'],
};

$RE{artistic_1} = {
	name                        => 'Artistic-1.0',
	'name.alt.org.osi'          => 'Artistic-1.0',
	'name.alt.org.spdx'         => 'Artistic-1.0',
	caption                     => 'Artistic License, version 1.0',
	'caption.alt.org.osi'       => 'Artistic License 1.0 (Artistic-1.0)',
	'caption.alt.org.wikipedia' => 'Artistic License 1.0',
	'caption.alt.misc.british'  => 'Artistic Licence 1.0',
	'iri.alt.old.osi' =>
		'https://opensource.org/licenses/artistic-license-1.0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Artistic_License#Artistic_License_1.0',
	tags => ['type:singleversion:artistic'],

	'pat.alt.subject.license.scope.multisection' =>
		"${BB}C or perl subroutines supplied by you and linked into this Package shall not be considered part of this Package$F$EE"
		. "${BB}The name of the Copyright Holder",
};

$RE{artistic_1_cl8} = {
	name                => 'Artistic-1.0-cl8',
	'name.alt.org.spdx' => 'Artistic-1.0-cl8',
	summary             => 'Artistic License 1.0 w/clause 8',
	tags                => ['type:singleversion:artistic'],

	'pat.alt.subject.license.scope.multisection' =>
		"this Package$F$EE${BB}Aggregation of this Package",
};

$RE{artistic_1_clarified} = {
	name                           => 'Artistic-1.0-clarified',
	'name.alt.org.spdx'            => 'ClArtistic',
	caption                        => 'Clarified Artistic License',
	'caption.alt.org.fedora'       => 'Artistic (clarified)',
	'caption.alt.org.fedora.short' => 'Artistic clarified',
	'caption.alt.org.fedora.web'   => 'Artistic Clarified',
	'caption.alt.org.spdx'         => 'Clarified Artistic License',
	'caption.alt.misc.british'     => 'Clarified Artistic Licence',
	iri =>
		'http://gianluca.dellavedova.org/2011/01/03/clarified-artistic-license/',
	tags => ['type:singleversion:artistic'],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Aggregation of the Standard Version of the Package',
};

$RE{artistic_1_perl} = {
	name                     => 'Artistic-1.0-Perl',
	'name.alt.org.spdx'      => 'Artistic-1.0-Perl',
	caption                  => 'Artistic License 1.0 (Perl)',
	'caption.alt.org.fedora' => 'Artistic 1.0 (original)',
	'caption.alt.org.spdx'   => 'Artistic License 1.0 (Perl)',
	iri                      => 'http://dev.perl.org/licenses/artistic.html',
	'iri.alt.old.perl' =>
		'http://www.perl.com/pub/a/language/misc/Artistic.html',
	tags => ['type:singleversion:artistic'],

	'pat.alt.subject.license.scope.multisection' =>
		"the language$F$EE${BB}Aggregation of this Package",
};

$RE{artistic_2} = {
	name                           => 'Artistic-2.0',
	'name.alt.org.osi'             => 'Artistic-2.0',
	'name.alt.org.tldr'            => 'artistic-license-2.0-(artistic)',
	'name.alt.org.tldr.path.short' => 'artistic',
	caption                        => 'Artistic License (v2.0)',
	'caption.alt.org.tldr'         => 'Artistic License 2.0 (Artistic-2.0)',
	'caption.alt.org.wikipedia'    => 'Artistic License 2.0',
	'caption.alt.misc.british'     => 'Artistic Licence 2.0',
	iri => 'http://www.perlfoundation.org/artistic_license_2_0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Artistic_License#Artistic_License_2.0',
	tags => ['type:singleversion:artistic'],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"is governed by this Artistic License$F",
};

=item * bdwgc

=cut

$RE{bdwgc} = {
	'name.alt.org.debian'               => 'MIT~Boehm',
	'name.alt.org.fedora.web.mit.short' => 'AnotherMinimalVariant',
	caption                             => 'Boehm GC License',
	'caption.alt.org.fedora.web.mit' =>
		'Another Minimal variant (found in libatomic_ops)',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	iri  => 'http://www.hboehm.info/gc/license.txt',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.paragraph' =>
		"$P{perm_granted} $P{to_copy} $P{this_prg} $P{any_purpose}, $P{retain_notices_all}$F$E$P{perm} $P{to_dist_mod} $P{granted}, $P{retain_notices}, and $P{note_mod} with $P{copr}$F",
};

=item * bdwgc_matlab

=cut

$RE{bdwgc_matlab} = {
	name        => 'bdwgc-matlab',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	tags => [ 'type:versioned:decimal', 'license:is:grant' ],

	'pat.alt.subject.license.scope.paragraph' =>
		"$P{perm_granted} $P{to_copy} $P{this_prg} $P{any_purpose}, $P{retain_notices_all}$F$E$P{repro_code_cite_authors_copr}, and $Q$P{used_perm}$F$Q$E$P{repro_matlab_cite_authors}$F$E$P{perm} $P{to_dist_mod} $P{granted}, $P{retain_notices}, and $P{note_mod} with $P{copr}$F$E$P{retain_you_avail_orig}$F",
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'must cite the Authors',
};

=item * beerware

=cut

$RE{beerware} = {
	name                           => 'Beerware',
	'name.alt.org.fedora.web'      => 'Beerware',
	'name.alt.org.spdx'            => 'Beerware',
	'name.alt.org.tldr.path.short' => 'beerware',
	'name.alt.org.wikidata'        => 'Q10249',
	caption                        => 'Beerware License',
	'caption.alt.org.tldr'         => 'Beerware License',
	'caption.alt.org.wikipedia'    => 'Beerware',
	tags => [ 'type:unversioned', 'license:is:grant', ],

	'pat.alt.subject.name' => '$the?[Bb]eer$D?ware(?: License)?',
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'you can buy me a beer in return',

	#<<<  do not let perltidy touch this (keep long regex on one line)
	examples => [
		{   summary => 'pattern with subject "license" matches original license with title omitted',
			gen_args => { grant => 'license' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" matches original license with title omitted (license is commonly granted by stating the whole license)',
			gen_args => { grant => 'grant' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 1,
		},
		{   summary => 'original license with title omitted doesn\'t match name pattern',
			gen_args => { subject => 'name' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 0,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match original license with title omitted',
			gen_args => { subject => 'iri' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 0,
		},
	],
	#>>>

};

=item * bsd_2_clause

=cut

$RE{bsd_2_clause} = {
	name                           => 'BSD-2-Clause',
	'name.alt.org.debian'          => 'BSD-2-clause',
	'name.alt.org.fedora'          => 'BSD',
	'name.alt.org.fedora.web.bsd'  => '2ClauseBSD',
	'name.alt.org.osi'             => 'BSD-2-Clause',
	'name.alt.org.spdx'            => 'BSD-2-Clause',
	'name.alt.org.tldr'            => 'bsd-2-clause-license-(freebsd)',
	'name.alt.org.tldr.path.short' => 'freebsd',
	caption                        => 'BSD (2 clause)',
	'caption.alt.org.fedora'       => 'BSD License (two clause)',
	'caption.alt.org.osi'          => 'The 2-Clause BSD License',
	'caption.alt.org.osi.alt.list' => '2-clause BSD license (BSD-2-Clause)',
	'caption.alt.org.spdx'         => 'BSD 2-clause "Simplified" License',
	'caption.alt.org.tldr' => 'BSD 2-Clause License (FreeBSD/Simplified)',
	'name.alt.org.wikipedia.bsd' =>
		'2-clause license ("Simplified BSD License" or "FreeBSD License")',
	'caption.alt.misc.british'  => '2-clause BSD Licence',
	'caption.alt.misc.british2' => 'FreeBSD Licence',
	'caption.alt.misc.british3' => 'Simplified BSD Licence',
	'caption.alt.misc.qemu' =>
		'BSD Licence (without advertising or endorsement clauses)',
	tags => [ 'family:bsd', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{repro_copr_cond_discl}$F$EE$P{asis_sw_by_name}",
};

=item * bsd_3_clause

=cut

$RE{bsd_3_clause} = {
	name                           => 'BSD-3-Clause',
	'name.alt.org.debian'          => 'BSD-3-clause',
	'name.alt.org.fedora'          => 'BSD',
	'name.alt.org.fedora.web.bsd'  => '3ClauseBSD',
	'name.alt.org.osi'             => 'BSD-3-Clause',
	'name.alt.org.spdx'            => 'BSD-3-Clause',
	'name.alt.org.tldr.path.short' => 'bsd3',
	caption                        => 'BSD (3 clause)',
	'caption.alt.org.fedora'       => 'BSD License (no advertising)',
	'caption.alt.org.osi'          => 'The 3-Clause BSD License',
	'caption.alt.org.osi.alt.list' => '3-clause BSD license (BSD-3-Clause)',
	'caption.alt.org.spdx' => 'BSD 3-clause "New" or "Revised" License',
	'caption.alt.org.tldr' => 'BSD 3-Clause License (Revised)',
	'caption.alt.org.wikipedia.bsd' =>
		'3-clause license ("BSD License 2.0", "Revised BSD License", "New BSD License", or "Modified BSD License")',
	'caption.alt.misc.british'  => '3-Clause BSD Licence',
	'caption.alt.misc.british2' => 'Modified BSD Licence',
	'caption.alt.misc.qemu'     => 'BSD Licence (without advertising clause)',
	tags                        => [
		'family:bsd', 'type:unversioned',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
	],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{repro_copr_cond_discl}$F$EE"
		. "(?:$BB \\[?(?:rescinded 22 July 1999"
		. "|This condition was removed$F)\\]?)?"
		. "$BB$P{nopromo_neither}",
};

=item * bsd_4_clause

=cut

$RE{bsd_4_clause} = {
	name                           => 'BSD-4-Clause',
	'name.alt.org.debian'          => 'BSD-4-clause',
	'name.alt.org.fedora.web.bsd'  => 'BSDwithAdvertising',
	'name.alt.org.spdx'            => 'BSD-4-Clause',
	'name.alt.org.tldr'            => '4-clause-bsd',
	caption                        => 'BSD (4 clause)',
	'caption.alt.org.fedora'       => 'BSD License (original)',
	'caption.alt.org.fedora.short' => 'BSD with advertising',
	'caption.alt.org.spdx' => 'BSD 4-clause "Original" or "Old" License',
	'caption.alt.org.tldr' => '4-Clause BSD',
	'caption.alt.org.wikipedia.bsd' =>
		'4-clause license (original "BSD License")',
	'caption.alt.misc.qemu' => 'BSD Licence (with advertising clause)',
	tags                    => [
		'family:bsd', 'type:unversioned',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
	],

	'pat.alt.subject.license.scope.sentence' => $P{ad_mat_ack_this},
	'pat.alt.subject.license.scope.multisection.part.head' =>
		"$P{repro_copr_cond_discl}$F$EE$BB?$P{ad_mat_ack_this}",
	'pat.alt.subject.license.scope.multisection.part.tail' =>
		"$BB?$P{ad_mat_ack_this}$F$EE$BB?$P{nopromo_neither}",
};

=item * bsl

=item * bsl_1

=cut

$RE{bsl} = {
	name                                => 'BSL',
	'name.alt.org.fedora.web.mit.short' => 'Thrift',
	caption                             => 'Boost Software License',
	'caption.alt.misc.mixedcase'        => 'boost Software License',
	'caption.alt.org.fedora.web.mit'    => 'Thrift variant',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Boost_Software_License#License',
	'caption.alt.misc.british' => 'Boost Software Licence',
	tags                       => ['type:versioned:decimal'],

# FIXME
	'_pat.alt.subject.name' => [
		'Boost Software License',
	],
};

$RE{bsl_1} = {
	name                           => 'BSL-1.0',
	'name.alt.org.osi'             => 'BSL-1.0',
	'name.alt.org.spdx'            => 'BSL-1.0',
	'name.alt.org.tldr'            => 'boost-software-license-1.0-explained',
	'name.alt.org.tldr.path.short' => 'boost',
	caption                        => 'Boost Software License 1.0',
	'caption.alt.misc.mixedcase'   => 'boost Software License, Version 1.0',
	'caption.alt.org.tldr'         => 'Boost Software License 1.0 (BSL-1.0)',
	'caption.alt.org.trove'        => 'Boost Software License 1.0 (BSL-1.0)',
	'caption.alt.org.facebook'     => 'Thrift Software License',
	'caption.alt.misc.british'     => 'Boost Software Licence 1.0',
	iri                            => 'http://www.boost.org/LICENSE_1_0.txt',
	'iri.alt.org.facebook.archive.20070630190325' =>
		'http://developers.facebook.com/thrift/',
	tags => [ 'type:singleversion:bsl', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"this license \\(the ${Q}Software$Q\\) to use, reproduce",
};

=item * cc_by

=cut

$RE{cc_by} = {
	name              => 'CC-BY',
	'name.alt.org.cc' => 'by',
	caption           => 'Creative Commons Attribution Public License',
	tags              => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' => "(?:$P{cc}$SD(?:$P{cc_by}|BY|$P{cc_url}by))",
};

=item * cc_by_nc

=cut

$RE{cc_by_nc} = {
	name              => 'CC-BY-NC',
	'name.alt.org.cc' => 'by-nc',
	caption => 'Creative Commons Attribution-NonCommercial Public License',
	tags    => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nc}|BY${SD}NC|$P{cc_url}by-nc))",
};

=item * cc_by_nc_nd

=cut

$RE{cc_by_nc_nd} = {
	name              => 'CC-BY-NC-ND',
	'name.alt.org.cc' => 'by-nc-nd',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives Public License',
	tags => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_by}$SD(?:$P{cc_nc}$SD$P{cc_nd}|$P{cc_nd}$SD$P{cc_nc})|BY${SD}NC${SD}ND|$P{cc_url}by-nc-nd))",
};

=item * cc_by_nc_sa

=cut

$RE{cc_by_nc_sa} = {
	name              => 'CC-BY-NC-SA',
	'name.alt.org.cc' => 'by-nc-sa',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike Public License',
	tags => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nc}$SD$P{cc_sa}|BY${SD}NC${SD}SA|$P{cc_url}by-nc-sa))",
};

=item * cc_by_nd

=cut

$RE{cc_by_nd} = {
	name              => 'CC-BY-ND',
	'name.alt.org.cc' => 'by-nd',
	caption => 'Creative Commons Attribution-NoDerivatives Public License',
	tags    => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nd}|BY${SD}ND|$P{cc_url}by-nd))",
};

=item * cc_by_sa

=cut

$RE{cc_by_sa} = {
	name              => 'CC-BY-SA',
	'name.alt.org.cc' => 'by-sa',
	caption => 'Creative Commons Attribution-ShareAlike Public License',
	tags    => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_sa}|BY${SD}SA|$P{cc_url}by-sa))",
};

=item * cc_cc0

=cut

$RE{cc_cc0} = {
	name                        => 'CC0',
	'name.alt.org.cc'           => 'zero',
	caption                     => 'Creative Commons CC0 Public License',
	'caption.alt.misc.american' => 'CC0 License',
	'caption.alt.misc.british'  => 'CC0 Licence',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	tags => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_cc0}(?: \\(?$Q?CC0$Q?\\)?)?|CC0|$P{cc_url_pd}zero))",
	'pat.alt.subject.grant.scope.line.scope.sentence' =>
		'has waived all copyright and related or neighboring rights',
};

=item * cc_sp

=cut

$RE{cc_sp} = {
	name              => 'Sampling+',
	'name.alt.org.cc' => 'sampling+',
	caption           => 'Creative Commons Sampling Plus Public License',
	tags              => [ 'family:cc', 'type:versioned:decimal' ],

	'pat.alt.subject.name' =>
		"(?:$P{cc}$SD(?:$P{cc_sp}|$P{cc_url}sampling\\+))",
};

=item * cddl

=cut

$RE{cddl} = {
	name                    => 'CDDL',
	'name.alt.org.wikidata' => 'Q304628',
	caption                 => 'Common Development and Distribution License',
	'caption.alt.org.wikipedia' =>
		'Common Development and Distribution License',
	tags => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?Common Development and Distribution License(?: \\(CDDL\\))?",
		"$the?COMMON DEVELOPMENT AND DISTRIBUTION LICENSE(?: \\(CDDL\\))?",
		"${the}CDDL\\b",
	],
};

=item * cecill

=item * cecill_1

=item * cecill_1_1

=item * cecill_2

=item * cecill_2_1

=cut

$RE{cecill} = {
	name                        => 'CECILL',
	'name.alt.org.wikidata'     => 'Q1052189',
	caption                     => 'CeCILL License',
	'caption.alt.org.inria(en)' => 'CeCILL FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL',
	'caption.alt.org.wikipedia' => 'CeCILL',
	'uri.alt.path.sloppy'       => 'http://www.cecill.info',
	tags                        => ['type:versioned:decimal'],

	'pat.alt.subject.name(en)' =>
		"$the?FREE SOFTWARE LICENSING AGREEMENT CeCILL",
	'_pat.alt.subject.name(fr)' => [
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL',
		'(?:la )?licence CeCILL',
	],
	'pat.alt.subject.name.misc.short' => 'CeCILL',
	'pat.alt.subject.grant.scope.line.scope.sentence.version.none(en)' =>
		'governed by the CeCILL  ?license',
	'pat.alt.subject.grant.scope.line.scope.sentence.version.none(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'_pat.alt.subject.license.scope.line.scope.sentence(en)' => [
		'Version 1\.1 of 10/26/2004',
		"Version 2\\.0 dated 2006${D}09${D}05",
		"Version 2\\.1 dated 2013${D}06${D}21",
	],
	'_pat.alt.subject.license.scope.line.scope.sentence(fr)' => [
		'Version 1 du 21/06/2004',
		"Version 2\\.0 du 2006${D}09${D}05",
		"Version 2\\.1 du 2013${D}06${D}21",
	],
};

$RE{cecill_1} = {
	name    => 'CECILL-1.0',
	caption => 'CeCILL License 1.0',
	'caption.alt.org.inria' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 1',
	'caption.alt.misc.v(en)' => 'CeCILL Free Software License Agreement v1.0',
	iri => 'https://cecill.info/licences/Licence_CeCILL_V1-fr.html',
	'iri.alt.format.txt' =>
		'https://cecill.info/licences/Licence_CeCILL_V1-fr.txt',
	'iri.alt.format.pdf' =>
		'https://cecill.info/licences/Licence_CeCILL-V1_VF.pdf',
	tags => ['type:singleversion:cecill'],

	'pat.alt.subject.name' => "CeCILL(?: License)?${SD}2(?:\.0)?",
	'pat.alt.subject.license.scope.line.scope.sentence(fr)' =>
		'Version 1 du 21/06/2004',
};

$RE{cecill_1_1} = {
	name    => 'CECILL-1.1',
	caption => 'CeCILL License 1.1',
	'caption.alt.org.inria' =>
		'FREE SOFTWARE LICENSING AGREEMENT CeCILL Version 1.1',
	iri => 'https://cecill.info/licences/Licence_CeCILL_V1.1-US.html',
	'iri.alt.format.txt' =>
		'https://cecill.info/licences/Licence_CeCILL_V1.1-US.txt',
	'iri.alt.format.pdf' =>
		'https://cecill.info/licences/Licence_CeCILL-V1.1-VA.pdf',
	tags => ['type:singleversion:cecill'],

	'pat.alt.subject.name' => "CeCILL(?: License)?${SD}1\.1",
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Version 1\.1 of 10/26/2004',
};

$RE{cecill_2} = {
	name                           => 'CECILL-2.0',
	'name.alt.org.tldr.path.short' => 'cecill-v2',
	caption                        => 'CeCILL License 2.0',
	'caption.alt.org.inria(en)' =>
		'CeCILL FREE SOFTWARE LICENSE AGREEMENT Version 2.0',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 2.0',
	'caption.alt.org.tldr' =>
		'CeCILL Free Software License Agreement v2.0 (CECILL-2.0)',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL_V2-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL_V2-fr.html',
	'iri.alt.format.txt(en)' =>
		'https://cecill.info/licences/Licence_CeCILL_V2-en.txt',
	'iri.alt.format.txt(fr)' =>
		'https://cecill.info/licences/Licence_CeCILL_V2-fr.txt',
	tags => ['type:singleversion:cecill'],

	'pat.alt.subject.name' => "CeCILL(?: License)?${SD}2(?:\.0)?",
	'pat.alt.subject.license.scope.line.scope.sentence(en)' =>
		"Version 2\\.0 dated 2006${D}09${D}05",
	'pat.alt.subject.license.scope.line.scope.sentence(fr)' =>
		"Version 2\\.0 du 2006${D}09${D}05",
};

$RE{cecill_2_1} = {
	name               => 'CECILL-2.1',
	'name.alt.org.osi' => 'CECILL-2.1',
	caption            => 'CeCILL License 2.1',
	'caption.alt.org.inria(en)' =>
		'CeCILL FREE SOFTWARE LICENSE AGREEMENT Version 2.1',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 2.1',
	'caption.alt.org.trove' =>
		'CEA CNRS Inria Logiciel Libre License, version 2.1 (CeCILL-2.1)',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL_V2.1-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL_V2.1-fr.html',
	'iri.alt.format.txt(en)' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-en.txt',
	'iri.alt.format.txt(fr)' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-fr.txt',
	tags => ['type:singleversion:cecill'],

	'pat.alt.subject.name' => "CeCILL(?: License)?${SD}2\.1",
	'pat.alt.subject.grant.scope.line.scope.sentence.version.none(en)' =>
		'governed by the CeCILL  ?license',
	'pat.alt.subject.grant.scope.line.scope.sentence.version.none(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'pat.alt.subject.license.scope.line.scope.sentence(en)' =>
		"Version 2\\.1 dated 2013${D}06${D}21",
	'pat.alt.subject.license.scope.line.scope.sentence(fr)' =>
		"Version 2\\.1 du 2013${D}06${D}21",
};

=item * cecill_b

=item * cecill_b_1

=cut

$RE{cecill_b} = {
	name                        => 'CECILL-B',
	caption                     => 'CeCILL-B License',
	'caption.alt.org.inria(en)' => 'CeCILL-B FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-B',
	'caption.alt.org.trove' =>
		'CeCILL-B Free Software License Agreement (CECILL-B)',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.format.txt(en)' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.txt',
	'iri.alt.format.txt(fr)' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-fr.txt',
	tags => ['type:versioned:decimal'],

	'pat.alt.subject.name.misc.short' => "CeCILL${D}B",
	'pat.alt.subject.grant.scope.line.scope.sentence(en)' =>
		'governed by the CeCILL-B license',
	'pat.alt.subject.grant.scope.line.scope.sentence(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license.scope.line.scope.sentence(en)' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license.scope.line.scope.sentence(fr)' =>
		'aux utilisateurs une tr[è]s large libert[é] de',
};

$RE{cecill_b_1} = {
	name                => 'CECILL-B-1.0',
	'name.alt.org.spdx' => 'CECILL-B',
	caption             => 'CeCILL-B License 1.0',
	'caption.alt.org.inria(en)' =>
		'CeCILL-B FREE SOFTWARE LICENSE AGREEMENT Version 1.0',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-B Version 1.0',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.format.txt(en)' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.txt',
	'iri.alt.format.txt(fr)' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-fr.txt',
	tags => ['type:singleversion:cecill_b'],

	'pat.alt.subject.name' => "CeCILL${D}B(?: License)?(?:${SD}1(?:\.0)?)?",
	'pat.alt.subject.grant.scope.line.scope.sentence(en)' =>
		'governed by the CeCILL-B license',
	'pat.alt.subject.grant.license.scope.line.scope.sentence(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license.scope.line.scope.sentence(en)' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license.scope.line.scope.sentence(fr)' =>
		'aux utilisateurs une tr[è]s large libert[é] de',
};

=item * cecill_c

=item * cecill_c_1

=cut

# TODO: synthesize patterns (except name) from cecill_c_1: they are all duplicates
$RE{cecill_c} = {
	name                        => 'CECILL-C',
	caption                     => 'CeCILL-C License',
	'caption.alt.org.inria(en)' => 'CeCILL-C FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-C',
	'caption.alt.org.trove' =>
		'CeCILL-C Free Software License Agreement (CECILL-C)',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL-C_V1-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.html',
	tags      => ['type:versioned:decimal'],

	'pat.alt.subject.name(fr)' =>
		"CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL${D}C",
	'pat.alt.subject.name.misc.short'                      => "CeCILL${D}C",
	'_pat.alt.subject.grant.scope.line.scope.sentence(en)' => [
		'under the terms of the CeCILL-C license',
		'governed by the CeCILL-C license',
	],
	'pat.alt.subject.grant.scope.line.scope.sentence(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license.scope.line.scope.sentence(en)' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license.scope.line.scope.sentence(fr)' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license(en)' =>
		"the Software modified or not;$EE${BB}to ensure that use of",
	'pat.alt.subject.license(fr)' =>
		"Logiciel modifi[é] ou non;$EE${BB}[à] faire en sorte que",
};

$RE{cecill_c_1} = {
	name                => 'CECILL-C-1.0',
	'name.alt.org.spdx' => 'CECILL-C',
	caption             => 'CeCILL-C License 1.0',
	'caption.alt.org.inria(en)' =>
		'CeCILL-C FREE SOFTWARE LICENSE AGREEMENT Version 1.0',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-C Version 1.0',
	'iri(en)' => 'https://cecill.info/licences/Licence_CeCILL-C_V1-en.html',
	'iri(fr)' => 'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.html',
	'iri.alt.format.txt(en)' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-en.txt',
	'iri.alt.format.txt(fr)' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.txt',
	tags => ['type:singleversion:cecill_c'],

	'pat.alt.subject.name.misc.short' =>
		"CeCILL${D}C(?: License)?(?:${SD}1(?:\.0)?)?",
	'_pat.alt.subject.grant.scope.line.scope.sentence(en)' => [
		'under the terms of the CeCILL-C license',
		'governed by the CeCILL-C license',
	],
	'pat.alt.subject.grant.scope.line.scope.sentence(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license.scope.line.scope.sentence(en)' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license.scope.line.scope.sentence(fr)' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license.scope.all(en)' =>
		"the Software modified or not;$EE${BB}to ensure that use of",
	'pat.alt.subject.license.scope.all(fr)' =>
		"Logiciel modifi[é] ou non;$EE${BB}[à] faire en sorte que",
};

=item * cube

=cut

$RE{cube} = {
	name                => 'Cube',
	'name.alt.org.spdx' => 'Cube',
	caption             => 'Cube License',
	tags => [ 'family:zlib', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}$F$E$P{use_ack_apprec_not_req}$F$EE$P{altered_srcver_mark}$F$EE$P{notice_no_alter_any}$F${EE}additional clause specific to Cube:?$E$P{src_no_relicense}",
};

=item * curl

=cut

$RE{curl} = {
	'name.alt.org.spdx' => 'curl',
	caption             => 'curl License',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{note_copr_perm}$F$EE$P{asis_sw_warranty}",
};

=item * dsdp

=cut

$RE{dsdp} = {
	name                             => 'DSDP',
	'name.alt.org.fedora.web'        => 'DSDP',
	'name.alt.org.spdx'              => 'DSDP',
	caption                          => 'DSDP License',
	'caption.alt.org.fedora.web.mit' => 'PetSC variant',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This program discloses material protectable',
	'pat.alt.subject.license.scope.paragraph' =>
		"$P{asis_expr_warranty}$F$E$P{perm_granted}",

};

=item * epl

=cut

$RE{epl} = {
	name                        => 'EPL',
	'name.alt.org.wikidata'     => 'Q1281977',
	caption                     => 'Eclipse Public License',
	'caption.alt.org.wikipedia' => 'Eclipse Public License',
	'caption.alt.misc.british'  => 'Eclipse Public Licence',
	tags                        => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?Eclipse Public Licen[cs]e(?: \\(EPL\\))?",
		"${the}EPL\\b",
	],
};

=item * eurosym

=cut

$RE{eurosym} = {
	name                => 'Eurosym',
	'name.alt.org.spdx' => 'Eurosym',
	caption             => 'Eurosym License',
	tags => [ 'family:zlib', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}$F$E$P{use_ack_apprec}$F$EE$P{altered_srcver_mark}$F$EE$BB?$P{you_not_use_ad_dist} $P{without_written_prior}$F$EE$BB?$P{change_redist_share}$F$EE$P{notice_no_alter}",
};

=item * fsfap

=cut

$RE{fsfap} = {
	name                  => 'FSFAP',
	'name.alt.org.gnu'    => 'GNUAllPermissive',
	'name.alt.org.spdx'   => 'FSFAP',
	caption               => 'FSF All Permissive License',
	'caption.alt.org.gnu' => 'GNU All-Permissive License',
	iri =>
		'https://www.gnu.org/prep/maintain/html_node/License-Notices-for-Other-Files.html',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		'Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved',
};

=item * fsful

=cut

$RE{fsful} = {
	name                => 'FSFUL',
	'name.alt.org.spdx' => 'FSFUL',
	caption             => 'FSF Unlimited License',
	tags                => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		"This configure script is free software; $fsf_ul",
};

=item * fsfullr

=cut

$RE{fsfullr} = {
	name                => 'FSFULLR',
	'name.alt.org.spdx' => 'FSFULLR',
	caption             => 'FSF Unlimited License (with Retention)',
	tags                => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		"This file is free software; $fsf_ullr",
};

=item * ftl

=cut

$RE{ftl} = {
	name                        => 'FTL',
	'name.alt.org.spdx'         => 'FTL',
	caption                     => 'FreeType License',
	'caption.alt.legal.license' => 'The Freetype Project LICENSE',
	'caption.alt.org.tldr'      => 'Freetype Project License (FTL)',
	iri                         => 'https://www.freetype.org/license.html',
	tags                        => ['type:unversioned'],

	'_pat.alt.subject.name' => [
		"$the?FreeType(?: [Pp]roject)? [Ll]icense(?: \\(FTL\\))?",
		'The FreeType Project LICENSE',
	],
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This license applies to all files found in such packages',
};

=item * gfdl

=cut

$RE{gfdl} = {
	name                       => 'GFDL',
	'name.alt.org.gnu'         => 'FDL',
	caption                    => 'GNU Free Documentation License',
	'caption.alt.misc.british' => 'GNU Free Documentation Licence',
	'caption.alt.misc.trove'   => 'GNU Free Documentation License (FDL)',
	tags                       => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?$gnu?Free Documentation Licen[cs]e(?: \\(GFDL\\))?$by_fsf?",
		"$the$gnu?GFDL",
		"${gnu}GFDL",
	],
};

=item * gfdl_niv

=cut

$RE{gfdl_niv} = {
	name    => 'GFDL-NIV',
	caption => 'GNU Free Documentation License (no invariant sections)',
	'caption.alt.misc.british' =>
		'GNU Free Documentation Licence (no invariant sections)',
	summary =>
		'GNU Free Documentation License, with no Front-Cover or Back-Cover Texts or Invariant Sections',
	tags => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?$gnu?Free Documentation Licen[cs]e(?: \\(GFDL\\))?$by_fsf?[,;]? $niv",
		"$the$gnu?GFDL${D}NIV",
		"${gnu}GFDL${D}NIV",
	],
};

=item * gpl

=cut

$RE{gpl} = {
	name                           => 'GPL',
	'name.alt.org.gnu'             => 'GNUGPL',
	'name.alt.org.osi'             => 'GPL',
	'name.alt.org.osi'             => 'gpl-license',
	'name.alt.org.wikidata'        => 'Q7603',
	caption                        => 'GNU General Public License',
	'caption.alt.org.gnu'          => 'GNU General Public License (GPL)',
	'caption.alt.org.osi'          => 'GNU General Public License',
	'caption.alt.org.osi.alt.list' => 'GNU General Public License (GPL)',
	'caption.alt.org.trove'        => 'GNU General Public License (GPL)',
	'caption.alt.org.wikipedia'    => 'GNU General Public License',
	'caption.alt.misc.british'     => 'GNU General Public Licence',
	tags                           => ['type:versioned:decimal'],

	'.default_pat' => 'name',

	'_pat.alt.subject.name' => [
		"$the?$gnu?$gpl(?: \\(GPL\\))?$by_fsf?",
		"$the$gnu?GPL",
		"${the}GNU [Ll]icense",
		"${gnu}GPL",
	],
};

=item * isc

=cut

$RE{isc} = {
	name                           => 'ISC',
	'name.alt.org.osi'             => 'ISC',
	'name.alt.org.spdx'            => 'ISC',
	'name.alt.org.tldr'            => '-isc-license',
	'name.alt.org.tldr.path.short' => 'isc',
	'name.alt.org.wikidata'        => 'Q386474',
	caption                        => 'ISC License',
	'caption.alt.misc.openbsd'     => 'OpenBSD License',
	'caption.alt.org.tldr'         => 'ISC License',
	'caption.alt.org.trove'        => 'ISC License (ISCL)',
	'caption.alt.org.wikipedia'    => 'ISC license',
	'caption.alt.misc.british'     => 'ISC licence',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{note_copr_perm}$F$EE$P{asis_sw_name_discl}",
};

=item * icu

=cut

$RE{icu} = {
	name                             => 'ICU',
	caption                          => 'ICU License',
	'caption.alt.org.fedora.web.mit' => 'Modern style (ICU Variant)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.multisection' =>
		"$P{note_copr_perm} of the Software and that $P{repro_copr_perm_appear_doc}$F$EE$P{asis_sw_warranty}(?:[^.]+$F$E){2}$P{nopromo_except}",
};

=item * json

=cut

$RE{json} = {
	name                   => 'JSON',
	caption                => 'JSON License',
	'caption.alt.org.tldr' => 'The JSON License',
	tags                   => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"The Software shall be used for Good, not Evil$F",
};

=item * jython

=cut

$RE{jython} = {
	name                        => 'Jython',
	'name.alt.org.spdx'         => 'CNRI-Jython',
	caption                     => 'Jython License',
	'caption.alt.org.spdx'      => 'CNRI Jython License',
	'caption.alt.legal.license' => 'The Jython License',
	iri                         => 'http://www.jython.org/license.txt',
	tags                        => ['type:unversioned'],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"${BB}PSF is making Jython available to Licensee",
};

=item * kevlin_henney

=cut

$RE{kevlin_henney} = {
	name    => 'Kevlin-Henney',
	caption => 'Kevlin Henney License',
	tags    => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{note_copr_perms_deriv}$F$EE$P{asis_sw_expr_warranty}",
};

=item * lgpl

=cut

$RE{lgpl} = {
	name                    => 'LGPL',
	'name.alt.org.gnu'      => 'LGPL',
	'name.alt.org.osi'      => 'lgpl-license',
	'name.alt.org.wikidata' => 'Q192897',
	caption                 => 'GNU Lesser General Public License',
	'caption.alt.org.gnu'   => 'GNU Lesser General Public License (LGPL)',
	'caption.alt.org.osi'   => 'GNU LGPL',
	'caption.alt.org.osi.alt.list' =>
		'GNU Lesser General Public License (LGPL)',
	'caption.alt.org.trove' =>
		'GNU Library or Lesser General Public License (LGPL)',
	'caption.alt.org.wikipedia' => 'GNU Lesser General Public License',
	'caption.alt.org.osi'       => 'GNU LGPL',
	'caption.alt.org.osi.alt.list' =>
		'GNU Lesser General Public License (LGPL)',
	'caption.alt.misc.british' => 'GNU Lesser General Public Licence',
	tags                       => ['type:versioned:decimal'],

	'.default_pat' => 'name',

	'_pat.alt.subject.name' => [
		"$the?$gnu?Library $gpl(?: \\(LGPL\\))?$by_fsf?",
		"$the?$gnu?Lesser(?: \\(Library\\))? $gpl(?: \\(LGPL\\))?$by_fsf?",
		"$the?$gnu?LIBRARY GENERAL PUBLIC LICEN[CS]E(?: \\(LGPL\\))?$by_fsf?",
		"$the?$gnu?LESSER GENERAL PUBLIC LICEN[CS]E(?: \\(LGPL\\))?$by_fsf?",
		"$the$gnu?LGPL",
		"${gnu}LGPL",
	],
};

=item * lgpl_bdwgc

=cut

$RE{lgpl_bdwgc} = {
	name => 'LGPL-bdwgc',
	caption =>
		'GNU Lesser General Public License (modified-code-notice clause)',
	summary =>
		'The GNU Lesser General Public License, with modified-code-notice clause',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	tags => ['type:versioned:decimal'],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{perm_granted} $P{to_copy} $P{this_prg} under the terms of $the${gnu}LGPL, $P{retain_copr_avail_orig}$F$EE$P{repro_code_modcode_cite_copr_avail_note}, and $Q$P{used_perm}$F$Q$E$P{perm} $P{to_dist_mod} $P{granted}, $P{retain_copr_avail_note}, and $P{note_mod}$F",
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'code must cite the Copyright',
};

=item * libpng

=cut

$RE{libpng} = {
	name                => 'Libpng',
	'name.alt.org.spdx' => 'Libpng',
	caption             => 'Libpng License',
	tags                => ['type:unversioned'],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{origin_src_no_misrepresent}$F$EE$P{altered_ver_mark}$F$EE$P{copr_no_alter}",
};

=item * llgpl

=cut

$RE{llgpl} = {
	name                   => 'LLGPL',
	'name.alt.org.tldr'    => 'lisp-lesser-general-public-license',
	caption                => 'Lisp Lesser General Public License',
	'caption.alt.org.tldr' => 'Lisp Lesser General Public License (LLGPL)',
	iri                    => 'http://opensource.franz.com/preamble.html',
	'iri.alt.misc.cliki'   => 'http://www.cliki.net/LLGPL',
	tags => [ 'type:unversioned', 'license:contains:license:llgpl_2_1' ],

	'_pat.alt.subject.name' => [
		"$the?Lisp Lesser $gpl(?: \\(LLGPL\\))?",
		"${the}LLGPL\\b",
	],
};

=item * mit_advertising

=cut

$RE{mit_advertising} = {
	name                => 'MIT-advertising',
	'name.alt.org.spdx' => 'MIT-advertising',
	caption             => 'Enlightenment License (e16)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		"$P{note_marketing}\\b[^.,]+, and $P{ack_doc_mat_pkg_use}",
};

=item * mit_cmu

=cut

$RE{mit_cmu} = {
	name                             => 'MIT-CMU',
	'name.alt.org.spdx'              => 'MIT-CMU',
	caption                          => 'CMU License',
	'caption.alt.org.fedora.web.mit' => 'CMU Style',
	description                      => <<'END',
Identical to NTP, except...
* omit explicit permission for charging fee
* exclude suitability disclaimer
* exclude terse "as is" warranty disclaimer
* include elaborate warranty disclaimer
* include liability disclaimer

SPDX and fedora sample seem not generic but the unique file COPYING from project net-snmp.
END
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.sentence' =>
		"Permission $P{to_dist} $P{sw_doc} $P{any_purpose} and $P{nofee} $P{granted}, $P{retain_copr_appear} and that $P{repro_copr_perm_appear_doc}, and that $P{nopromo_name_written}$F",
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'without specific written permission',
};

=item * mit_cmu_warranty

=cut

$RE{mit_cmu_warranty} = {
	'name.alt.org.debian' => 'MIT-CMU~warranty',
	caption               => 'CMU License (retain warranty disclaimer)',
	'caption.alt.org.fedora.web.mit' => 'Standard ML of New Jersey Variant',
	'caption.alt.org.fedora.web.mit.short' => 'MLton variant',
	description                            => <<'END',
Identical to MIT-CMU, except...
* add requirement of "warranty disclaimer" appearing in documentation
END
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.sentence' =>
		"Permission $P{to_dist} $P{sw_doc} $P{any_purpose} and $P{nofee} $P{granted}, $P{retain_copr_appear} and that $P{repro_copr_perm_warr_appear_doc}, and that $P{nopromo_name_written_prior}$F",
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'warranty disclaimer appear',
};

=item * mit_enna

=cut

$RE{mit_enna} = {
	name                                => 'MIT-enna',
	'name.alt.org.fedora.web.mit.short' => 'enna',
	'name.alt.org.spdx'                 => 'MIT-enna',
	caption                             => 'enna License',
	'caption.alt.org.fedora.web.mit'    => 'enna variant',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.section' =>
		"$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_sw}, $P{to_deal_the_sw_rights} $P{to_mod_sublic} $P{sw}, and $P{to_perm_pers}, $P{subj_cond}:?$E$P{retain_copr_perm_sw_copr}$F$E$P{ack_pub_use_nosrc}$F${E}This includes acknowledgments in either Copyright notices, Manuals, Publicity and Marketing documents or any documentation provided with any product containing this software$F$E$P{license_not_lib}$F",
	'pat.alt.subject.license.scope.line' => $P{ack_pub_use_nosrc},
};

=item * mit_feh

=cut

$RE{mit_feh} = {
	name                                => 'MIT-feh',
	'name.alt.org.fedora.web.mit.short' => 'feh',
	'name.alt.org.spdx'                 => 'MIT-feh',
	caption                             => 'feh License',
	'caption.alt.org.fedora.web.mit'    => 'feh variant',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.paragraph' =>
		"$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_sw}, $P{to_deal_the_sw_rights} $P{to_mod_sublic} $P{sw}, and $P{to_perm_pers}, $P{subj_cond}:?$E$P{retain_copr_perm_sw_doc} and $P{ack_doc_pkg_use}$F",
};

=item * mit_new

=cut

$RE{mit_new} = {
	'name.alt.org.debian'            => 'Expat',
	'name.alt.org.fedora'            => 'MIT',
	'name.alt.org.osi'               => 'MIT',
	'name.alt.org.spdx'              => 'MIT',
	'name.alt.org.tldr'              => 'mit-license',
	'name.alt.org.tldr.path.short'   => 'mit',
	caption                          => 'MIT License',
	'caption.alt.org.debian'         => 'Expat License',
	'caption.alt.org.fedora.web.mit' => 'Modern Style with sublicense',
	'caption.alt.org.osi'            => 'The MIT License',
	'caption.alt.org.osi.alt.list'   => 'MIT license (MIT)',
	'caption.alt.org.tldr'           => 'MIT License (Expat)',
	'caption.alt.misc.british'       => 'MIT licence',
	iri                     => 'http://www.jclark.com/xml/copying.txt',
	'iri.alt.org.wikipedia' => 'https://en.wikipedia.org/wiki/MIT_License',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.sentence' =>
		"$P{to_mod_sublic} $P{sw}\\b[^.]+\\s+$P{retain_copr_perm_subst}",
};

=item * mit_new_materials

=cut

$RE{mit_new_materials} = {
	name    => 'Khronos',
	caption => 'Khronos License',
	tags    => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		"$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_material}, $P{to_deal_mat}",
};

=item * mit_old

=cut

$RE{mit_old} = {
	'name.alt.org.debian' => 'MIT~old',
	'name.alt.org.gentoo' => 'Old-MIT',
	caption               => 'MIT (old)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"$P{perm_granted}, $P{free_agree_fee}",
};

=item * mit_oldstyle

=cut

$RE{mit_oldstyle} = {
	'name.alt.org.debian'            => 'MIT~oldstyle',
	caption                          => 'MIT (Old Style)',
	'caption.alt.org.fedora.web.mit' => 'Old Style',
	description                      => <<'END',
Origin: Possibly by Jamie Zawinski in 1993 for xscreensaver.
END
	tags => [ 'mit', 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		"documentation$F${E}No representations are made",
};

=item * mit_oldstyle_disclaimer

=cut

$RE{mit_oldstyle_disclaimer} = {
	'name.alt.org.debian'            => 'MIT~oldstyle~disclaimer',
	caption                          => 'MIT (Old Style, legal disclaimer)',
	'caption.alt.org.fedora.web.mit' => 'Old Style with legal disclaimer',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.multisection' =>
		"supporting documentation$F$EE$P{asis_name_sw}",
};

=item * mit_oldstyle_permission

=cut

$RE{mit_oldstyle_permission} = {
	'name.alt.org.debian' => 'MIT~oldstyle~permission',
	'caption.alt.org.fedora.web.mit' =>
		'Old Style (no advertising without permission)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'.default_pat' => 'license',

	'pat.alt.subject.license.scope.multisection' =>
		"$P{without_written_prior}$F$EE$P{asis_name_sw}",
};

=item * mpl

=cut

$RE{mpl} = {
	name                     => 'MPL',
	'name.alt.org.wikidata'  => 'Q308915',
	caption                  => 'Mozilla Public License',
	'name.alt.org.wikipedia' => 'Mozilla Public License',
	'name.alt.misc.british'  => 'Mozilla Public Licence',
	iri                      => 'https://www.mozilla.org/MPL',
	tags                     => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?Mozilla Public Licen[cs]e(?: \\($Q?(?:https?:?//mozilla.org/)?MPL$Q?\\))?(?: (?:as )?published by $the\{0,2}Mozilla Foundation)?",
		"${the}MPL\\b",
	],
};

=item * ms_pl

=cut

$RE{ms_pl} = {
	name                           => 'MS-PL',
	'name.alt.org.osi'             => 'MS-PL',
	'name.alt.org.spdx'            => 'MS-PL',
	'name.alt.org.tldr.path.short' => 'mspl',
	caption                        => 'Microsoft Public License',
	'caption.alt.org.tldr'         => 'Microsoft Public License (Ms-PL)',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Public_License_(Ms-PL)',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'_pat.alt.subject.name' => [
		"$the?Microsoft Public License(?: \\(Ms${D}PL\\))?",
		"${the}Ms${D}PL\\b",
	],
	'pat.alt.subject.license.scope.multiparagraph' =>
		"Microsoft Public License \\(Ms-PL\\)${EE}This license governs use",
};

=item * ms_rl

=cut

$RE{ms_rl} = {
	name                           => 'MS-RL',
	'name.alt.org.osi'             => 'MS-RL',
	'name.alt.org.spdx'            => 'MS-RL',
	'name.alt.org.tldr.path.short' => 'nsrl',
	caption                        => 'Microsoft Reciprocal License',
	'caption.alt.org.tldr'         => 'Microsoft Reciprocal License (Ms-RL)',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Reciprocal_License_(Ms-RL)',
	tags => [ 'type:unversioned', 'license:is:grant' ],

	'_pat.alt.subject.name' => [
		"$the?Microsoft Reciprocal License(?: \\(Ms${D}RL\\))?",
		"${the}Ms${D}RL\\b",
	],
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"Reciprocal Grants$D For any file you distribute that contains code",
	'pat.alt.subject.license.scope.multiparagraph' =>
		"Microsoft Reciprocal License \\(Ms${D}RL\\)${EE}This license governs use",
};

=item * ntp

=cut

$RE{ntp} = {
	name                   => 'NTP',
	'name.alt.org.osi'     => 'NTP',
	'name.alt.org.spdx'    => 'NTP',
	caption                => 'NTP License',
	'caption.alt.org.tldr' => 'NTP License (NTP)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		$P{asis_expr_warranty},
};

=item * ntp_disclaimer

=cut

$RE{ntp_disclaimer} = {
	'name.alt.org.debian' => 'NTP~disclaimer',
	caption               => 'NTP License (legal disclaimer)',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.paragraph' =>
		"$P{asis_expr_warranty}$F$E$P{discl_name_warranties}",
};

=item * ofl

=cut

$RE{ofl} = {
	name                       => 'OFL',
	caption                    => 'SIL Open Font License',
	'caption.alt.misc.british' => 'SIL Open Font Licence',
	iri                        => 'http://scripts.sil.org/OFL',
	tags                       => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?(?:SIL )?OPEN FONT LICEN[CS]E(?: \\(OFL\\))?",
		"$the?(?:SIL )?[Oo]pen [Ff]ont [Ll]icen[cs]e(?: \\(OFL\\))?",
	],
};

=item * openssl

=cut

$RE{openssl} = {
	name                       => 'OpenSSL',
	'name.alt.org.spdx'        => 'OpenSSL',
	caption                    => 'OpenSSL License',
	'caption.alt.org.tldr'     => 'OpenSSL License (OpenSSL)',
	'caption.alt.misc.british' => 'OpenSSL Licence',
	tags                       => ['type:unversioned'],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{redist_ack_this} the OpenSSL Project for use in the OpenSSL Toolkit \\(${HT}www\\.openssl\\.org/\\)$Q$EE"
		. "THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ${Q}AS IS$Q"
		. " AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED$F"
		. " IN NO EVENT SHALL THE OpenSSL PROJECT OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES"
		. " \\(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\\)"
		. " HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT \\(INCLUDING NEGLIGENCE OR OTHERWISE\\)"
		. " ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE$F$EE"
		. "This product includes cryptographic software written by Eric Young \\(eay[@]cryptsoft\\.com\\)$F${E}This product includes software written by Tim Hudson \\(tjh[@]cryptsoft\\.com\\)$F$EE"
};

=item * postgresql

=cut

$RE{postgresql} = {
	name                             => 'PostgreSQL',
	'name.alt.org.osi'               => 'PostgreSQL',
	'name.alt.org.spdx'              => 'PostgreSQL',
	caption                          => 'PostgreSQL License',
	'caption.alt.org.fedora.web'     => 'PostgreSQL License',
	'caption.alt.org.fedora.web.mit' => 'PostgreSQL License (MIT Variant)',
	'caption.alt.org.tldr'           => 'PostgreSQL License (PostgreSQL)',
	'caption.alt.org.trove'          => 'PostgreSQL License',
	'caption.alt.misc.british'       => 'PostgreSQL Licence',
	tags => [ 'family:mit', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		$P{permission_use_fee_agree},
};

=item * public_domain

=cut

$RE{public_domain} = {
	name                          => 'public-domain',
	'name.alt.org.cc'             => 'publicdomain',
	'name.alt.org.gnu'            => 'PublicDomain',
	'name.alt.misc.case_and_dash' => 'Public-Domain',
	caption                       => 'Public domain',
	'caption.alt.org.trove'       => 'Public Domain',
	'iri.alt.org.cc' => 'https://creativecommons.org/licenses/publicdomain',
	'iri.alt.org.cc' => 'https://creativecommons.org/publicdomain/mark/1.0/',
	'iri.alt.org.linfo' => 'http://www.linfo.org/publicdomain.html',
	tags                => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.name' =>
		"$the?(?:[Pp]ublic|PUBLIC)${SD}(?:[Dd]omain|DOMAIN)",
};
$RE{public_domain}{'pat.alt.subject.grant.scope.line.scope.sentence'} = [
	"(?:[Tt]his is|[Tt]hey are|[Ii]t's) in $RE{public_domain}{'pat.alt.subject.name'}",
	"(?:[Tt]his|[Tt]he) +(?:(?:source )?code|document|file|library|macros|opening book|work) +is(?: put)?(?: in)? $RE{public_domain}{'pat.alt.subject.name'}",
	"are dedicated to $RE{public_domain}{'pat.alt.subject.name'}",
	"for use in $RE{public_domain}{'pat.alt.subject.name'}",
	"placed in(?:to)? $RE{public_domain}{'pat.alt.subject.name'}",
	"considered to be in $RE{public_domain}{'pat.alt.subject.name'}",
	"offered to use in $RE{public_domain}{'pat.alt.subject.name'}",
	"provided ${Q}as${SD}is$Q into $RE{public_domain}{'pat.alt.subject.name'}",
	"released to $RE{public_domain}{'pat.alt.subject.name'}",
	"RELEASED INTO $RE{public_domain}{'pat.alt.subject.name'}",
];

=item * python

=item * python_2

=cut

$RE{python} = {
	name                        => 'Python',
	'name.alt.misc.short'       => 'PSFL',
	'name.alt.misc.shortest'    => 'PSF',
	'name.alt.org.wikidata'     => 'Q2600299',
	caption                     => 'Python Software Foundation License',
	'caption.alt.org.osi'       => 'Python License',
	'caption.alt.org.python'    => 'PSF License Agreement',
	'caption.alt.org.trove'     => 'Python Software Foundation License',
	'caption.alt.misc.desc'     => 'new Python license',
	'caption.alt.org.wikipedia' => 'Python Software Foundation License',
	'summary.alt.org.osi'       => 'Python License (overall Python license)',
	tags                        => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?Python Software Foundation License",
		"PYTHON SOFTWARE FOUNDATION LICENSE",
	],
};

$RE{python_2} = {
	name                             => 'Python-2',
	'name.alt.org.debian.misc.short' => 'PSF-2',
	'name.alt.org.osi'               => 'Python-2.0',
	'name.alt.org.spdx'              => 'Python-2.0',
	'name.alt.org.tldr.path.short'   => 'python2',
	caption => 'Python Software Foundation License version 2',
	'caption.alt.legal.license' =>
		'PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2',
	'caption.alt.org.osi'  => 'Python License, Version 2',
	'caption.alt.org.tldr' => 'Python License 2.0',
	'summary.alt.org.osi' =>
		'Python License (overall Python license), Version 2',
	iri  => 'https://www.python.org/psf/license/',
	tags => [
		'type:singleversion:python', 'license:contains:license:cnri_python'
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"${BB}PSF is making Python available to Licensee",
};

=item * qpl

=cut

$RE{qpl} = {
	name                        => 'QPL',
	'name.alt.org.wikidata'     => 'Q1396282',
	caption                     => 'Q Public License',
	'caption.alt.org.trove'     => 'Qt Public License (QPL)',
	'caption.alt.org.wikipedia' => 'Q Public License',
	'caption.alt.misc.british'  => 'Q Public Licence',
	tags                        => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?Q Public Licen[cs]e(?: \\(QPL\\))?",
		"$the?Q PUBLIC LICEN[CS]E(?: \\(QPL\\))?",
		"${the}QPL\\b",
	],
};

=item * rpsl

=item * rpsl_1

=cut

$RE{rpsl} = {
	name                        => 'RPSL',
	'name.alt.org.wikidata'     => 'Q7300815',
	caption                     => 'RealNetworks Public Source License',
	'caption.alt.org.wikipedia' => 'RealNetworks Public Source License',
	tags                        => ['type:versioned:decimal'],

	'pat.alt.subject.name' => "$the?RealNetworks Public Source License",
};

$RE{rpsl_1} = {
	name                  => 'RPSL-1.0',
	'name.alt.org.osi'    => 'RPSL-1.0',
	'name.alt.org.spdx'   => 'RPSL-1.0',
	caption               => 'RealNetworks Public Source License 1.0',
	'caption.alt.org.osi' => 'RealNetworks Public Source License V1.0',
	'caption.alt.legal.license' =>
		'RealNetworks Public Source License Version 1.0',
	'caption.alt.org.tldr' =>
		'RealNetworks Public Source License v1.0 (RPSL-1.0)',
	tags => [
		'type:singleversion:rpsl', 'license:contains:name:afl',
		'license:contains:name:apache',
		'license:contains:name:artistic', 'license:contains:name:bsd',
		'license:contains:name:cpl',      'license:contains:name:gpl_1',
		'license:contains:name:lgpl_1',   'license:contains:name:intel',
		'license:contains:name:expat',    'license:contains:name:Motosoto',
		'license:contains:name:mpl_1',    'license:contains:name:mpl_1_1',
		'license:contains:name:nokia',    'license:contains:name:python',
		'license:contains:name:rscpl',    'license:contains:name:siss_1_1',
		'license:contains:name:ncsa',     'license:contains:name:zpl',
		'license:contains:name:w3c',      'license:contains:name:xnet',
		'license:contains:name:zlib',     'license:contains:name:libpng'
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		"General Definitions$F This License applies to any program or other work",
};

=item * sgi_b

=cut

$RE{sgi_b} = {
	name    => 'SGI-B',
	caption => 'SGI Free Software License B',
	iri     => 'https://www.sgi.com/projects/FreeB/',
	tags    => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?SGI Free Software License B(?: \\(SGI${D}B\\))?",
		"$the?SGI FREE SOFTWARE LICENSE B(?: \\(SGI${D}B\\))?",
		'(?:SGI )?FreeB\b',
		"${the}SGI${D}B\\b",
	],
};

=item * unicode_strict

=cut

$RE{unicode_strict} = {
	name                     => 'Unicode-strict',
	'name.alt.misc.scancode' => 'unicode-mappings',
	caption                  => 'Unicode strict',
	tags                     => [ 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'hereby grants the right to freely use',
};

=item * unicode_tou

=cut

$RE{unicode_tou} = {
	name                => 'Unicode-TOU',
	'name.alt.org.spdx' => 'Unicode-TOU',
	caption             => 'Unicode Terms of Use',
	tags                => ['type:unversioned'],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'distribute all documents and files solely for informational',
};

=item * wtfpl

=item * wtfpl_1

=item * wtfpl_2

=cut

$RE{wtfpl} = {
	name                     => 'WTFPL',
	'name.alt.org.spdx'      => 'WTFPL',
	'name.alt.org.wikidata'  => 'Q152481',
	'name.alt.org.wikipedia' => 'WTFPL',
	caption                  => 'do What The Fuck you want to Public License',
	'caption.alt.misc.censored' =>
		'Do What The F*ck You Want To Public License',
	'caption.alt.misc.shorter' => 'WTF Public License',
	iri                        => 'http://www.wtfpl.net/',
	'iri.alt.misc.old'         => 'http://sam.zoy.org/wtfpl/COPYING',
	tags                       => ['type:versioned:decimal'],

	'_pat.alt.subject.name' => [
		"$the?[Dd]o What The F(?:u|${B})ck [Yy]ou [Ww]ant(?: [Tt]o)? Public License(?: \\(WTFPL\\))?",
		"$the?DO WHAT THE F(?:U|${B})CK YOU WANT(?: TO)? PUBLIC LICENSE(?: \\(WTFPL\\))?",
		"${the}WTFPL\\b",
	],
	'pat.alt.subject.license.scope.sentence' =>
		"[Yy]ou just${EE}DO WHAT THE FUCK YOU WANT TO$F",
};

$RE{wtfpl_1} = {
	name    => 'WTFPL-1.0',
	caption => 'Do What The Fuck You Want To Public License, Version 1',
	'caption.alt.org.tldr' =>
		'Do What The F*ck You Want To Public License (WTFPL)',
	iri  => 'http://cvs.windowmaker.org/co.php/wm/COPYING.WTFPL',
	tags => [ 'type:singleversion:wtfpl', 'license:is:grant' ],

	'pat.alt.subject.license.scope.sentence' =>
		"simple and you just${EE}DO WHAT THE FUCK YOU WANT TO$F",
};

$RE{wtfpl_2} = {
	name                           => 'WTFPL-2',
	'name.alt.org.tldr.path.short' => 'wtfpl',
	caption => 'Do What The Fuck You Want To Public License, Version 2',
	'caption.alt.legal.license' =>
		'DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2',
	'caption.alt.org.tldr' =>
		'Do What The F*ck You Want To Public License v2 (WTFPL-2.0)',
	iri                => 'http://www.wtfpl.net/',
	'iri.alt.misc.old' => 'http://sam.zoy.org/wtfpl/COPYING',
	tags               => [ 'type:singleversion:wtfpl', 'license:is:grant' ],

	'pat.alt.subject.grant.scope.line.scope.sentence' =>
		'of the Do What The Fuck You Want To Public License',
	'pat.alt.subject.license.scope.sentence' =>
		"${BB}You just${EE}DO WHAT THE FUCK YOU WANT TO$F",
};

=item * wtfnmfpl

=item * wtfnmfpl_1

=cut

$RE{wtfnmfpl} = {
	name => 'WTFNMFPL',
	'caption.alt.org.tldr' =>
		"Do What The Fuck You Want To But It's Not My Fault Public License v1 (WTFNMFPL-1.0)",
	tags => ['type:versioned:decimal'],
};

$RE{wtfnmfpl_1} = {
	name                  => 'WTFNMFPL-1.0',
	'name.alt.misc.short' => 'WTFNMFPLv1',
	caption =>
		"Do What The Fuck You Want To But It's Not My Fault Public License v1",
	'caption.alt.legal.license' =>
		"DO WHAT THE FUCK YOU WANT TO BUT IT'S NOT MY FAULT PUBLIC LICENSE, Version 1",
	'caption.alt.org.tldr' =>
		"Do What The Fuck You Want To But It's Not My Fault Public License v1 (WTFNMFPL-1.0)",
	iri =>
		'http://www.adversary.org/wp/2013/10/14/do-what-the-fuck-you-want-but-its-not-my-fault/',
	'iri.alt.web.github' => 'https://github.com/adversary-org/wtfnmf',
	tags => [ 'type:singleversion:wtfnmfpl', 'license:is:grant' ],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Do not hold the author\(s\), creator\(s\), developer\(s\) or distributor\(s\)',
};

=item * zlib

=cut

$RE{zlib} = {
	name                                  => 'Zlib',
	'name.alt.org.fsf'                    => 'Zlib',
	'name.alt.org.osi'                    => 'Zlib',
	'name.alt.org.spdx'                   => 'Zlib',
	'name.alt.org.tldr.path.short'        => 'zlib',
	'name.alt.org.wikidata'               => 'Q207243',
	caption                               => 'zlib/libpng license',
	'caption.alt.org.osi'                 => 'The zlib/libpng License',
	'caption.alt.org.tldr'                => 'Zlib-Libpng License (Zlib)',
	'caption.alt.org.trove'               => 'zlib/libpng License',
	'caption.alt.org.wikipedia'           => 'zlib License',
	'caption.alt.org.wikipedia.misc.case' => 'zlib license',
	iri                => 'http://zlib.net/zlib_license.html',
	'iri.alt.org.gzip' => 'http://www.gzip.org/zlib/zlib_license.html',
	tags => [ 'family:zlib', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}$F$E$P{use_ack_apprec_not_req}$F$EE$P{altered_srcver_mark}$F$EE$P{notice_no_alter}",
};

=item * zlib_acknowledgement

=cut

$RE{zlib_acknowledgement} = {
	name                    => 'Nunit',
	'name.alt.misc.orig'    => 'NUnit',
	'name.alt.org.spdx'     => 'zlib-acknowledgement',
	caption                 => 'Nunit License',
	'caption.alt.misc.orig' => 'NUnit License',
	'caption.alt.org.spdx'  => 'zlib/libpng License with Acknowledgement',
	tags => [ 'family:zlib', 'type:unversioned', 'license:is:grant' ],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}$F$E$P{use_ack_req}$F${EE}Portions Copyright \\S+ $ND+ Charlie Poole or Copyright \\S+ $ND+ James W\\. Newkirk, Michael C\\. Two, Alexei A\\. Vorontsov or Copyright \\S+ $ND+ Philip A\\. Craig$EE$P{altered_srcver_mark}$F$EE$P{notice_no_alter}",
};

=back

=head2 Licensing traits

Patterns each covering a single trait occuring in licenses.

Each of these patterns has the tag B< type:trait >.

=over

=item * any_of

=cut

$RE{any_of} = {
	caption => 'license grant "any of the following" phrase',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?P<_any_of>(?:any|one or more) of the following(?: licen[cs]es(?: at your choice)?)?)[.:]? ?',
};

=item * clause_retention

=cut

$RE{'clause_retention'} = {
	caption => 'retention clause',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $P{retain_notice_cond_discl},
};

=item * clause_reproduction

=cut

$RE{'clause_reproduction'} = {
	caption => 'reproduction clause',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $P{repro_copr_cond_discl},
};

=item * clause_advertising

=cut

$RE{'clause_advertising'} = {
	caption => 'advertising clause',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $P{ad_mat_ack_this},
};

=item * clause_advertising_always

=cut

$RE{'clause_advertising_always'} = {
	caption => 'advertising clause (always)',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $P{redist_ack_this},
};

=item * clause_non_endorsement

=cut

$RE{'clause_non_endorsement'} = {
	caption => 'non-endorsement clause',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $P{nopromo_neither},
};

=item * fsf_unlimited

=cut

$RE{'fsf_unlimited'} = {
	tags => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $fsf_ul,
};

=item * fsf_unlimited_retention

=cut

$RE{'fsf_unlimited_retention'} = {
	tags => ['type:trait'],

	'pat.alt.subject.trait.scope.sentence' => $fsf_ullr,
};

=item * license_label

=cut

$RE{license_label} = {
	caption => 'license grant "License:" phrase',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		"(?P<_license_label>[Ll]icen[sc]e|[Ii]dentifier)$CQ",
};

=item * license_label_trove

=cut

$RE{license_label_trove} = {
	caption => 'license grant "License:" phrase',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?P<_license_label_trove>License(?: ::)? OSI Approved(?: ::)?)',
};

=item * licensed_under

=cut

$RE{licensed_under} = {
	caption => 'license grant "licensed under" phrase',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?P<_licensed_under>'
		. '(?:(?:[Ll]icen[sc]ed(?: for use)?|[Dd]istribut(?:able|ed)|[Ff]or distribution|permitted|provided|[Pp]ublished|[Rr]eleased) under'
		. '|[Ll]icen[sc]ed using'
		. '|(?:in form of source code|may be copied|placed their code|to [Yy]ou) under'
		. '|(?:[Tt]his|[Mm]y) (?:software|file|work) is under' # vague: object required
		. '|(?:are|is) release under'    # vague: object required
		. '|which I release under'       # vague: subject required
		. '|(?:according|[Ss]ubject) to|in accordance with'
		. '|(?:[Cc]overed|governed) by)'
		. '(?: (?:the )?(?:conditions|terms(?: and conditions)?) (?:described in|of))?' # strong: terms optional
		. '|[Uu]nder (?:the )?(?:terms|(?:terms and )?conditions) (?:described in|of)'  # vague: terms required
		. ') ',
};

=item * or_at_option

=cut

$RE{'or_at_option'} = {
	caption => 'license grant "or at your option" phrase',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?P<_or_at_option>(?:and|or)(?: ?\(?at your (?:option|choice)\)?)?)',
};

=item * version

=cut

$RE{'version'} = {
	tags => ['type:trait'],
};

=item * version_later

=cut

$RE{'version_later'} = {
	caption => 'version "or later"',
	tags    => ['type:trait'],
};

=item * version_later_paragraph

=cut

$RE{'version_later_paragraph'} = {
	caption => 'version "or later" postfix (paragraphs)',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.paragraph' =>
		'(?P<_version_later_paragraph>Later versions are permitted)',
};

=item * version_later_postfix

=cut

$RE{'version_later_postfix'} = {
	caption => 'version "or later" (postfix)',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'\(?(?P<_version_later_postfix>'
		. $RE{or_at_option}{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. '(?: any)? (?:later|above|newer)(?: version)?'
		. '|or any later at your option)\)?',
};

$RE{version_later}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= ",? (?P<version_later>"
	. "$RE{version_later_postfix}{'pat.alt.subject.trait.scope.line.scope.sentence'})";
$RE{version_later}{'pat.alt.subject.trait.scope.paragraph'}
	= "$F$E(?P<version_later>"
	. "$RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'})";
$RE{version_later}{'pat.alt.subject.trait'}
	= "(?:$F$E|,? )(?P<version_later>"
	. $RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'}
	. "|$RE{version_later_postfix}{'pat.alt.subject.trait.scope.line.scope.sentence'})";

=item * version_number

=cut

$RE{'version_number'} = {
	caption => 'version number',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?P<version_number>\d(?:\.\d)*)',
};

=item * version_numberstring

=cut

$RE{'version_numberstring'} = {
	caption => 'version numberstring',
	tags    => ['type:trait'],
};

=item * version_prefix

=cut

$RE{'version_prefix'} = {
	caption => 'version prefix',
	tags    => ['type:trait'],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		"(?:$D|[,;]?(?: (?:only |either )?)?|$DD)?\\(?(?:[Vv]ersion [Vv]?|VERSION |[Vv]\\.? ?)?",
	'pat.alt.subject.trait.scope.paragraph' =>
		":?$E\\(?(?:Version [Vv]?|VERSION )?",
	'pat.alt.subject.trait' =>
		"(?:$D|[,;](?: (?:either )?)?|$DD|:?$E)?\\(?(?:[Vv]ersion [Vv]?|VERSION |[Vv]\\.? ?)?",
};

$RE{version_numberstring}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= $RE{version_prefix}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. $RE{version_number}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. '(?:(?: of the)? Licen[cs]e)?';
$RE{version_numberstring}{'pat.alt.subject.trait.scope.paragraph'}
	= $RE{version_prefix}{'pat.alt.subject.trait.scope.paragraph'}
	. $RE{version_number}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. '(?:(?: of the)? Licen[cs]e)?';
$RE{version_numberstring}{'pat.alt.subject.trait'}
	= $RE{version_prefix}{'pat.alt.subject.trait'}
	. $RE{version_number}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. '(?:(?: of the)? Licen[cs]e)?';

$RE{version}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= '(?P<_version>'
	. $RE{version_numberstring}
	{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. "(?:$RE{version_later}{'pat.alt.subject.trait.scope.line.scope.sentence'})?)\\)?";
$RE{version}{'pat.alt.subject.trait.scope.paragraph'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait.scope.paragraph'}
	. "(?:$RE{version_later}{'pat.alt.subject.trait.scope.paragraph'})?)\\)?";
$RE{version}{'pat.alt.subject.trait'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait'}
	. "(?:$RE{version_later}{'pat.alt.subject.trait'})?)\\)?";

=back

=head2 License combinations

Patterns each covering a combination of multiple licenses.

Each of these patterns has the tag B< type:combo >.

=over

=item * perl

=back

=cut

$RE{'perl'} = {
	name                     => 'Perl',
	'name.alt.org.spdx'      => 'Artistic or GPL-1+',
	caption                  => 'The Perl 5 License',
	'caption.alt.misc.short' => 'Perl License',
	'caption.alt.misc.long'  => 'The Perl 5 programming language License',
	summary =>
		'the same terms as the Perl 5 programming language itself (Artistic or GPL)',
	'summary.alt.misc.short' => 'same terms as Perl',
	tags                     => ['type:combo'],

	'pat.alt.subject.grant.scope.line.scope.sentence.org.software_license' =>
		'same terms as the Perl 5 programming language system itself',
};

=head2 License groups

Patterns each covering either of multiple licenses.

Each of these patterns has the tag B< type:group >.

=over

=item * bsd

=cut

$RE{'bsd'} = {
	name                        => 'BSD',
	'name.alt.org.debian'       => 'BSD~unspecified',
	'name.alt.org.fedora.web'   => 'BSD',
	'name.alt.org.wikidata'     => 'Q191307',
	caption                     => 'BSD license',
	'caption.alt.org.debian'    => 'BSD (unspecified)',
	'caption.alt.org.trove'     => 'BSD License',
	'caption.alt.org.wikipedia' => 'BSD licenses',
	'caption.alt.misc.long'     => 'Berkeley Software Distribution License',
	'caption.alt.misc.british'  => 'BSD licence',
	'caption.alt.misc.british2' => 'Berkeley Software Distribution Licence',
	summary                     => 'a BSD-style license',
	tags                        => ['type:group'],

	'pat.alt.subject.license.scope.multisection' =>
		"$P{repro_copr_cond_discl}(?:$F$EE(?:$BB?$P{ad_mat_ack_this}$F$EE)?$BB?$P{nopromo_neither})?",
};

=item * gnu

=cut

$RE{'gnu'} = {
	name                       => 'AGPL/GPL/LGPL',
	'name.alt.org.debian'      => 'GNU~unspecified',
	caption                    => 'GNU license',
	'caption.alt.misc.british' => 'GNU licence',
	summary                    => 'a GNU license (AGPL or GPL or LGPL)',
	tags                       => ['type:group'],

	'_pat.alt.subject.name' => [
		$RE{agpl}{'_pat.alt.subject.name'},
		$RE{gpl}{'_pat.alt.subject.name'},
		$RE{lgpl}{'_pat.alt.subject.name'},
	],
};

=item * mit

=cut

$RE{'mit'} = {
	name                        => 'MIT',
	'name.alt.org.debian'       => 'MIT~unspecified',
	'name.alt.org.fedora.web'   => 'MIT',
	'name.alt.org.wikidata'     => 'Q334661',
	caption                     => 'MIT license',
	'caption.alt.org.trove'     => 'MIT License',
	'caption.alt.org.wikipedia' => 'MIT License',
	'caption.alt.misc.british'  => 'MIT Licence',
	'iri.alt.org.wikipedia' => 'https://en.wikipedia.org/wiki/MIT_License',
	summary                 => 'an MIT-style license',
	tags                    => ['type:group'],

	'pat.alt.subject.name' => "${the}MIT\\b",
};

=back

=head1 STRUCTURE

The regexp patterns follows the L<DefHash> specification,
and more specifically the structure of L<Regexp::Pattern>,
defining access to one pattern per DefHash object, as C<pat>.

Additionally, (sub)patterns are available in plaintext form, as C<pat.alt.*>.

=head2 SUBJECT

Each pattern targets one or more subjects,
i.e. ways to directly or indirectly represent a license.

Beware that not all pattern objects fully cover all subjects.

=over

=item trait

Distinguishing trait or feature expressed in licensing strings,
e.g. an advertising clause or granting "...or any later version."

Coverage for this subject is currently rather weak.

=item name

Distinguishing name, e.g. usable in license grant.

=item grant

Text granting the license.

=item license

Text containing licensing terms.

Texts containing both license grant and licensing terms
(e.g. BSD- and MIT-style licensing)
may be classified as either subject L<grant> or subject L<license>.
This may change, as needs for distinction is better understood.

=back

=head2 SCOPE

Each pattern can process material within some scope,
i.e. a certain sample size of the full subject.

As an example, L<https://codesearch.debian.net/> use line-based processing,
where patterns spanning multiple lines are not applicable.

=over

=item line

Pattern typically found within a single line.
Typically this means less than 70 characters within scope.

=item sentence

Pattern matching within a sentence.

May span multiple lines, but not across multiple sentences.
Typically this means no full-stop or colon within scope.

=item paragraph

Pattern matching distinguishing paragraph.

May span multiple sentences, but not multiple paragraphs.
Typically this means no newline within scope.

=item section

Pattern matching distinguishing section.

May span multiple paragraphs, but not multiple sections.
Typically this means blank line within scope.

=item multisection

Pattern may span multiple sections.

=back

=cut

my @gnu_locales
	= qw(en ar ca de el es fr it ja nl pl pt-br ru sq sr zh-cn zh-tw);

my @_OBJECTS = grep {/^[a-z]/} keys(%RE);

# must be simple word (no underscore), to survive getting joined in cache
# more ideal first: first available is default
my @_SUBJECTSTACK = qw(license grant name iri trait);

my %_TYPE;
my %_SERIES;

# process metadata tags
for my $id (@_OBJECTS) {

	# resolve series
	for ( @{ $RE{$id}{tags} } ) {
		/^type:($_prop)(?::($_prop))?/;
		$_TYPE{$id} = $1
			if ($1);
		push @{ $_SERIES{$id} }, $2
			if ( $2 and $1 eq 'singleversion' );
	}

	# synthesize type:versioned metadata caption from type:singleversion
	_prop_populate( $id, 'caption', $_ ) for ( @{ $_SERIES{$id} } );
}

# process metadata caption
for my $id (@_OBJECTS) {

	# synthesize metadata: name from caption
	CAPTION: for ( keys %{ $RE{$id} } ) {
		my ( $slug, $org ) = (/^caption\.(alt\.org\.($_prop)$_any*)/);
		next CAPTION unless ($org);
		next CAPTION if ( $RE{$id}{"name.$slug"} );
		if ( $org eq 'fedora' and $slug =~ /alt\.org\.fedora\.web/ ) {
			$_ = $RE{$id}{$_};
			s/\s/_/g;
			s/\(/.28/g;
			s/\)/.29/g;
			$RE{$id}{"name.$slug"} = $_;
			next CAPTION;
		}
		if ( $org eq 'tldr' ) {
			$_ = lc( $RE{$id}{$_} );
			s/ /-/g;
			$RE{$id}{"name.$slug"} = $_
				if ( $slug eq 'alt.org.tldr' );
			$RE{$id}{"name.alt.org.$slug"} = $_
				if ( $slug eq 'alt.org.tldr.path.short' );
			next CAPTION;
		}
		if ( $org eq 'wikipedia' ) {
			$_ = $RE{$id}{$_};
			s/ /_/g;
			s/"/%22/g;    #"
			$RE{$id}{"name.$slug"} = $_;
			next CAPTION;
		}
	}

	# synthesize metadata: series alternate name from name
	_prop_populate( $id, 'name', $_ ) for ( @{ $_SERIES{$id} } );
}

# process metadata name
for my $id (@_OBJECTS) {

	# synthesize metadata: iri from name
	NAME: for ( keys %{ $RE{$id} } ) {
		my ( $slug, $org, $trail, $web, $weborg, $webtrail )
			= (
			/^name\.(alt\.org\.($_prop)((?:\.(web\b)\.?($_prop?))?($_any*)))/
			);

		$RE{$id}{"iri.alt.org.fedora.$weborg$webtrail"}
			||= "https://fedoraproject.org/wiki/Licensing/BSD#$RE{$id}{$_}"
			and next NAME
			if ( $weborg and $org eq 'fedora' and $weborg eq 'bsd' );
		$RE{$id}{"iri.alt.org.fedora.$weborg$webtrail"}
			||= "https://fedoraproject.org/wiki/Licensing/MIT#$RE{$id}{$_}"
			and next NAME
			if ( $weborg and $org eq 'fedora' and $weborg eq 'mit' );
		$RE{$id}{"iri.alt.org.fedora$webtrail"}
			||= "https://fedoraproject.org/wiki/Licensing/$RE{$id}{$_}"
			and next NAME
			if ( $web and !$weborg and $org eq 'fedora' );
		$RE{$id}{"iri.alt.org.fedora$trail"}
			||= "https://fedoraproject.org/wiki/Licensing/$RE{$id}{$_}"
			and next NAME
			if ( $org and !$web and $org eq 'fedora' );

		$RE{$id}{"iri.$slug"}
			||= "https://directory.fsf.org/wiki?title=License:$RE{$id}{$_}"
			and next NAME
			if ( $org and $org eq 'fsf' );
		if ( $org and $org eq 'gnu' ) {
			$RE{$id}{"iri.$slug"}
				||= "https://www.gnu.org/licenses/license-list.html#$RE{$id}{$_}";
			for my $lang (@gnu_locales) {
				$RE{$id}{"iri.$slug($lang)"}
					||= "https://www.gnu.org/licenses/license-list.$lang.html#$RE{$id}{$_}";
			}
			next NAME;
		}
		$RE{$id}{"iri.$slug"} ||= "https://tldrlegal.com/l/$RE{$id}{$_}"
			and next NAME
			if ( $slug and $slug eq 'alt.org.tldr.path.short' );
		$RE{$id}{"iri.$slug"}
			||= "https://tldrlegal.com/license/$RE{$id}{$_}"
			and next NAME
			if ( $slug and $slug eq 'alt.org.tldr' );
		$RE{$id}{"iri.$slug"}
			||= "https://opensource.org/licenses/$RE{$id}{$_}"
			and next NAME
			if ( $org and $org eq 'osi' );
		if ( $org and $org eq 'spdx' ) {
			$RE{$id}{"iri.$slug"}
				||= "https://spdx.org/licenses/$RE{$id}{$_}";
			for my $ext (qw(txt html json)) {
				$RE{$id}{"iri.$slug.format.$ext"}
					||= "https://spdx.org/licenses/$RE{$id}{$_}.$ext";
			}
			next NAME;
		}
		if ( $org and $org eq 'wikidata' ) {
			$RE{$id}{"iri.$slug"}
				||= "https://www.wikidata.org/wiki/Special:EntityPage/$RE{$id}{$_}";
			$RE{$id}{"iri.$slug.path.wiki"}
				||= "https://www.wikidata.org/wiki/$RE{$id}{$_}";
			next NAME;
		}
		$RE{$id}{"iri.$slug"}
			||= "https://en.wikipedia.org/wiki/$RE{$id}{$_}"
			and next NAME
			if ( $org and $org eq 'wikipedia' );
	}

	# synthesize metadata: series alternate iri from iri
	_prop_populate( $id, 'iri', $_ ) for ( @{ $_SERIES{$id} } );
}

# process patterns
for my $id (@_OBJECTS) {

	# synthesize patterns: iri from metadata iri
	unless ( $RE{$id}{'pat.alt.subject.iri'} ) {
		my @subpat;
		for (
			map  { $RE{$id}{$_} }
			grep {/^iri(?:[.(]|\z)/} keys %{ $RE{$id} }
			)
		{
			s/([ .()\[\]])/\\$1/g;
			s/-/$D/g;
			s!^https?://!$HT!;
			s!/$!/?!;
			push @subpat, $_;
		}
		my $pat = _join_pats(@subpat);
		$RE{$id}{'pat.alt.subject.iri'} = $pat
			if ($pat);
	}

	# synthesize subject pattern name from metadata name and caption
	unless ( $RE{$id}{'_pat.alt.subject.name.synth.caption'}
		or $_TYPE{$id} eq 'trait' )
	{
		my @pat;
		for (
			grep { !/-\(/ }
			grep { !/,[_~]/ }
			map  { $RE{$id}{$_} }
			grep { !/^name\.alt\.org\.wikidata(?:$_delim|\z)/ }
			grep {/^(?:caption|name)(?:$_delim|\z)/}
			grep { !/\.synth\.nogrant(?:$_delim|\z)/ }
			keys %{ $RE{$id} }
			)
		{
			s/([()])/\\$1/g;
			unless (/ /) {
				s/^(?:\\b)?/\\b/;
				s/(?:\\b)?$/\\b/;
			}
			s/^$the?/$the?/;
			s/(?: [Ll]icense)/\(?: \[Ll\]icense\)?/;
			s/,/,?/g;
			s/ - /${DD}/g;
			if (/$RE{version}{'pat.alt.subject.trait.scope.line.scope.sentence'}$/
				)
			{
				my $pos = $-[0];
				substr( $_, $pos )
					= $RE{version_prefix}
					{'pat.alt.subject.trait.scope.line.scope.sentence'} . $2
					=~ s/\.0$/\(?:\\.0\)?/r . '(?:[^\d.]|\.\D|\.\z|\z)';
			}
			push @pat, $_;
		}
		push @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} }, @pat
			if (@pat);
	}

# synthesize subject pattern grant from metadata name and subject pattern name
# TODO: maybe include also subject pattern iri
# TODO: separately synthesize SPDX-License-Identifier
	unless ( $RE{$id}{'_pat.alt.subject.grant.synth.name'}
		or $_TYPE{$id} eq 'trait' )
	{
		my %pat;
		for (
			grep { !/-\(/ }
			grep { !/,[_~]/ }
			map  { $RE{$id}{$_} }
			grep { !/^name\.alt\.org\.wikidata(?:$_delim|\z)/ }
			grep {/^name(?:$_delim|\z)/}
			keys %{ $RE{$id} }
			)
		{
			$_ = quotemeta;
			s/\\-/$D/g;
			if (/\d$/) {
				s/\\\.0$/\(?:\\.0\)?/;
				$_ .= '(?:[^\d.]|\.\D|\.\z|\z)';
			}
			else {
				$_ .= '(?:[\s]|\z)';
			}
			$pat{$_} = 1;
		}
		if ( $RE{$id}{'_pat.alt.subject.name.synth.caption'} ) {
			$pat{$_} = 1
				for @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} };
		}
		$RE{$id}{'_pat.alt.subject.grant.synth.name'}
			= $RE{license_label}
			{'pat.alt.subject.trait.scope.line.scope.sentence'} . ' ?'
			. _join_pats( keys %pat );
	}

	# synthesize subject pattern grant from Trove caption
	unless ( $RE{$id}{'_pat.alt.subject.grant.synth.trove'}
		or $_TYPE{$id} eq 'trait' )
	{
		my %pat;
		for (
			grep { !/-\(/ }
			grep { !/,[_~]/ }
			map  { $RE{$id}{$_} }
			grep {/^caption\.alt\.org\.trove(?:$_delim|\z)/}
			keys %{ $RE{$id} }
			)
		{
			$_ = quotemeta;
			s/\\-/$D/g;
			if (/\d$/) {
				s/\\\.0$/\(?:\\.0\)?/;
				$_ .= '(?:[^\d.]|\.\D|\.\z|\z)';
			}
			else {
				$_ .= '(?:[\s]|\z)';
			}
			$pat{$_} = 1;
		}
		$RE{$id}{'_pat.alt.subject.grant.synth.trove'}
			= $RE{license_label_trove}
			{'pat.alt.subject.trait.scope.line.scope.sentence'} . ' ?'
			. _join_pats( keys %pat )
			if (%pat);
	}

	# synthesize subject pattern grant from subject pattern name
	unless ( $RE{$id}{'_pat.alt.subject.grant.synth.caption'}
		or $_TYPE{$id} eq 'trait' )
	{
		# TODO: use resolved patterns (not subpatterns)
		my $pat
			= _join_pats(
			@{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} } )
			or next;
		$RE{$id}{'_pat.alt.subject.grant.synth.caption'}
			= $RE{licensed_under}
			{'pat.alt.subject.trait.scope.line.scope.sentence'} . $pat;
	}

	# synthesize subject pattern license from metadata caption
	$RE{$id}{'pat.alt.subject.license.scope.sentence'}
		||= $cc_by_exercising_you_accept_this
		. $RE{$id}{'caption.alt.org.cc.legal.license'}
		if ( $RE{$id}{'caption.alt.org.cc.legal.license'} );

	# resolve subject patterns from subpatterns
	for my $subject (@_SUBJECTSTACK) {

		# use explicit pattern
		next if $RE{$id}{"pat.alt.subject.$subject"};

		# synthesize from seed pattern
		my $pat = _join_pats( $RE{$id}{"_pat.alt.subject.$subject"} );
		if ($pat) {
			$RE{$id}{"pat.alt.subject.$subject"} = $pat;
			next;
		}

		# synthesize from alternatives or their seeds
		my @pat;
		for (
			grep {/^_?pat\.alt\.subject\.$subject$_delim/}
			keys %{ $RE{$id} }
			)
		{
			s/_\K//;
			push @pat, $RE{$id}{$_} || $RE{$id}{"_$_"};
		}
		$pat ||= _join_pats(@pat);

		$RE{$id}{"pat.alt.subject.$subject"} = $pat
			if ($pat);
	}

	# resolve available patterns
	my @pat_subject = grep { $RE{$id}{"pat.alt.subject.$_"} } @_SUBJECTSTACK;

	# provide default dynamic pattern: all available patterns
	$RE{$id}{gen} = sub {
		my %args = @_;

		my $capture = $args{capture} || 'no';

		my $subjects
			= $args{subject}
			? [ split( /,/, $args{subject} ) ]
			: [ $RE{$id}{'.default_pat'} || @pat_subject ];

		my $pat = _join_pats( map { $RE{$id}{"pat.alt.subject.$_"} }
				@{$subjects} );

		return ''
			unless ($pat);

		$pat =~ s/$_->[0]/$_->[1]/g for (@_re);

		if ( $capture eq 'named' ) {
			$pat =~ s/\(\?P<\K_//g;
		}
		elsif ( $capture eq 'numbered' ) {
			$pat =~ s/\(\?P<_[^>]+>/(?:/g;
			$pat =~ s/\(\?P<[^>]+>/(/g;
		}
		else {
			$pat =~ s/\(\?P<[^>]+>/(?:/g;
		}

		$pat =~ s/$_->[0]/$_->[1]/g for (@_re);

		if ( $args{engine} ) {
			if ( $args{engine} eq 'RE2' ) {
				use re::engine::RE2;
				return qr/$pat/;
			}
			else {
				die "Unsupported regexp engine \"$args{engine}\"";
			}
		}
		else {
			return qr/$pat/;
		}
	};

	# option keep: include capturing parantheses in pattern
	$RE{$id}{'gen_args'}{capture} = {
		summary => 'include capturing parantheses, named or numbered',
		schema  => [ 'str*', in => [qw(named numbered no)] ],
		default => 'no',
		req     => 1,
	};

	# option subject: which subject(s) to cover in pattern
	$RE{$id}{'gen_args'}{subject} = {
		summary => 'Choose subject (or several, comma-separated)',
		schema  => [ 'str*', in => [@pat_subject] ],
		default => $RE{$id}{'.default_pat'} || join ',', @pat_subject,
		req     => 1,
	};

	# option engine: which regular expression engine to compile pattern with
	$RE{$id}{'gen_args'}{engine} = {
		summary => 'Enable custom regexp engine (perl module re::engine::*)',
		schema  => ['str*'],
	};
}

# mirror property + attributes to alternate attributes of series object
sub _prop_populate
{
	my ( $id, $property, $series ) = @_;

	for ( keys %{ $RE{$id} } ) {
		my ( $stem, $slug, $lang )
			= (/^($property)(?:\.alt)?($_notlang?)($_lang?)/);
		$RE{$series}{"$property.alt$slug.version.$id$lang"} ||= $RE{$id}{$_}
			if ($stem);
	}
}

sub _join_pats
{
	return '' unless (@_);

	# skip empty patterns, and expand references
	my @pats = map {
		if    ( !ref )           { ($_) }
		elsif ( ref eq 'ARRAY' ) { _join_pats( @{$_} ) }
		else                     { die "Bad ref: $_"; }
	} grep { defined && ($_) } @_;

	unless (@pats) {
		return '';
	}
	return $pats[0] if ( @pats < 2 );
	return '(?:' . join( '|', @pats ) . ')';
}

=head2 TAGS

Pattern defhashes optionally includes tags,
which may help in selecting multiple related patterns.

Tags are hierarchical,
with C<:> as separator,
and may be extended without notice.
Therefore take care to permit sub-parts when tag-matching,
e.g. using a regex like C< /\Asome:tag(?:\z|:)/ >.

=over

=item * family:bsd

=item * family:cc

=item * family:gpl

=item * family:mit

=item * family:zlib

Pattern covers a license part of a family of licenses.

=item * license:contains:grant

License mentions a preferred form for granting the license.

This implies that license is commonly granted by use of a different (typically far shorter) text.

=item * license:contains:license:*

License contains another license.

Wildcard is the key to corresponding license pattern.

=item * license:contains:name:*

License mentions name of another license.

=item * license:is:grant

License is commonly granted by stating the whole license.

=item * type:combo

Pattern covers a combination of multiple licenses.

=item * type:group

Pattern covers either of multiple licenses.

=item * type:singleversion:*

Pattern covers a specific version of a license.

Last part of tag is the key of the corresponding non-version-specific pattern.

=item * type:trait

Pattern covers a single trait occuring in licenses.

=item * type:unversioned

Pattern covers a license without versioning scheme.

=item * type:versioned:decimal

Pattern covers a license using decimal number versioning scheme.

=back

=head3 DEPRECATED TAGS

Tags not documented in this POD,
specifically non-hierarchical tags,
are deprecated and will be dropped in a future release.

=cut

push @{ $RE{$_}{tags} }, 'bsd'
	for (qw(bsd_2_clause bsd_3_clause bsd_4_clause));
push @{ $RE{$_}{tags} }, 'cc'
	for (
	qw(cc_by cc_by_nc cc_by_nc_nd cc_by_nc_sa cc_by_nd cc_by_sa cc_cc0 cc_sp)
	);
push @{ $RE{$_}{tags} }, 'mit'
	for (
	qw(curl dsdp isc icu mit_advertising mit_cmu mit_cmu_warranty mit_enna
	mit_feh mit_new mit_new_materials mit_old mit_oldstyle mit_oldstyle_disclaimer
	mit_oldstyle_permission ntp ntp_disclaimer postgresql)
	);
push @{ $RE{$_}{tags} }, 'zlib'
	for (qw(cube eurosym zlib zlib_acknowledgement));
push @{ $RE{$_}{tags} }, 'trait'
	for (
	qw(clause_non_endorsement fsf_unlimited fsf_unlimited_retention
	version_later version_later_paragraph version_later_postfix version_number
	version_prefix)
	);
push @{ $RE{perl}{tags} }, 'combo';
push @{ $RE{$_}{tags} }, 'group' for (qw(bsd gnu mit));

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

  Copyright © 2016-2017 Jonas Smedegaard

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>.

=cut

1;
