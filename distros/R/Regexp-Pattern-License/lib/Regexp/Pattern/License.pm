package Regexp::Pattern::License;

use utf8;
use strict;
use warnings;

use Regexp::Pattern::License::Parts;

=head1 NAME

Regexp::Pattern::License - Regular expressions for legal licenses

=head1 VERSION

Version v3.0.31

=cut

our $VERSION = version->declare("v3.0.31");

=head1 DESCRIPTION

L<Regexp::Pattern::License> provides a hash of regular expression patterns
related to legal software licenses.

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=head2 Single licenses

Patterns each covering a single license.

=over

=item * adobe_2006

=item * adobe_glyph

=item * afl

=item * agpl

=item * apache

=item * apafml

=item * artistic

=item * artistic_2

=item * beerware

=item * bsd_2_clause

=item * bsd_3_clause

=item * bsd_4_clause

=item * cc_by

=item * cc_by_nc

=item * cc_by_nc_nd

=item * cc_by_nc_sa

=item * cc_by_nd

=item * cc_by_sa

=item * cc_cc0

=item * cc_sp

=item * cddl

=item * cecill

=item * cecill_1

=item * cecill_1_1

=item * cecill_2

=item * cecill_2_1

=item * cecill_b

=item * cecill_c

=item * cube

=item * curl

=item * dsdp

=item * epl

=item * eurosym

=item * fsfap

=item * fsful

=item * fsfullr

=item * ftl

=item * gfdl

=item * gfdl_niv

=item * gpl

=item * isc

=item * lgpl

=item * llgpl

=item * libpng

=item * mit_advertising

=item * mit_enna

=item * mit_feh

=item * mit_new

=item * mit_new_materials

=item * mit_old

=item * mit_oldstyle

=item * mit_oldstyle_disclaimer

=item * mit_oldstyle_permission

=item * mpl

=item * ms_pl

=item * ms_rl

=item * ntp

=item * ntp_disclaimer

=item * openssl

=item * postgresql

=item * public_domain

=item * python

=item * qpl

=item * sgi_b

=item * unicode_strict

=item * unicode_tou

=item * wtfpl

=item * zlib

=item * zlib_acknowledgement

=back

=cut

my $D  = qr/[-–]/;     # dash
my $SD = qr/[ -–]/;    # space or dash

my %P;
while ( my ( $key, $val ) = each %Regexp::Pattern::License::Parts::RE ) {
	$P{$key} = $val->{pat};
}

my $the = qr/(?:[Tt]he )/;

my $gnu    = qr/(?:GNU )/;
my $gpl    = qr/General Public License/;
my $fsf    = qr/(?:$the?Free Software Foundation)/;
my $by_fsf = qr/(?: (?:as )?published by $fsf)/;
my $niv
	= qr/with no Invariant Sections(?:, with no Front-Cover Texts, and with no Back-Cover Texts)?/;
my $fsf_ul
	= qr/$fsf gives unlimited permission to copy, distribute and modify it/;
my $fsf_ullr
	= qr/$fsf_ul, with or without modifications, as long as this notice is preserved/;

our %RE = (
	adobe_2006 => {
		name    => 'Adobe-2006',
		caption => 'Adobe',
		pat     => qr/You agree to indemnify, hold harmless and defend/,
	},
	adobe_glyph => {
		name    => 'Adobe-Glyph',
		caption => 'Adobe Glyph List',
		pat =>
			qr/and to permit others to do the same, provided that the derived work is not represented as being a copy/,
	},
	afl => {
		name    => 'AFL',
		summary => 'Academic Free License',
		pat => qr/(?:$the?Academic Free License(?: \(AFL\))?|${the}AFL\b)/,
	},
	agpl => {
		name    => 'AGPL',
		summary => 'GNU Affero General Public License',
		pat =>
			qr/(?:$the?$gnu?Affero $gpl(?: \(AGPL\))?$by_fsf?|(?:$the$gnu?|$gnu)AGPL)/,
	},
	aladdin => {
		name    => 'Aladdin',
		summary => 'Aladdin Free Public License',
		pat     => qr/$the?Aladdin Free Public License/,
	},
	apache => {
		name    => 'Apache',
		summary => 'Apache License',
		pat     => qr/$the?Apache(?: Software)? License/,
	},
	apafml => {
		name    => 'APAFML',
		caption => 'Adobe Postscript AFM',
		pat =>
			qr/(?:AFM files it accompanies may be used|that the AFM files are not distributed)/,
	},
	artistic => {
		name    => 'Artistic',
		summary => 'Artistic License',
		pat     => qr/$the?Artistic License/,
	},
	artistic_2 => {
		name    => 'Artistic-2.0',
		summary => 'Artistic License (v2.0)',
		pat     => qr/is governed by this Artistic License\./,
	},
	beerware => {
		name    => 'Beerware',
		summary => 'Beer-Ware License',
		pat =>
			qr/(?:you can buy me a beer in return|$the?beer-?ware(?: License)?)/,
	},
	bsd_2_clause => {
		name                  => 'BSD-2-Clause',
		'name.alt.org.debian' => 'BSD-2-clause',
		caption               => 'BSD (2 clause)',
		tags                  => ['bsd'],
		pat =>
			qr/$P{repro_copr_cond_discl}\W+$P{asis_sw_by_name}/,
	},
	bsd_3_clause => {
		name                  => 'BSD-3-Clause',
		'name.alt.org.debian' => 'BSD-3-clause',
		caption               => 'BSD (3 clause)',
		tags                  => ['bsd'],
		pat =>
			qr/$P{repro_copr_cond_discl}\W+$P{nopromo_neither}/,
	},
	bsd_4_clause => {
		name                  => 'BSD-4-Clause',
		'name.alt.org.debian' => 'BSD-4-clause',
		caption               => 'BSD (4 clause)',
		tags                  => ['bsd'],
		pat                   => qr/$P{ad_mat_ack_this}/,
	},
	cc_by => {
		name    => 'CC-BY',
		caption => 'CC by',
		summary => 'Creative Commons Attribution Public License',
		tags    => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}|BY|$P{cc_url}by))/,
	},
	cc_by_nc => {
		name    => 'CC-BY-NC',
		caption => 'CC by-nc',
		summary =>
			'Creative Commons Attribution-NonCommercial Public License',
		tags => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nc}|BY${SD}NC|$P{cc_url}by-nc))/,
	},
	cc_by_nc_nd => {
		name    => 'CC-BY-NC-ND',
		caption => 'CC by-nc-nd',
		summary =>
			'Creative Commons Attribution-NonCommercial-NoDerivatives Public License',
		tags => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}$SD(?:$P{cc_nc}$SD$P{cc_nd}|$P{cc_nd}$SD$P{cc_nc})|BY${SD}NC${SD}ND|$P{cc_url}by-nc-nd))/,
	},
	cc_by_nc_sa => {
		name    => 'CC-BY-NC-SA',
		caption => 'CC by-nc-sa',
		summary =>
			'Creative Commons Attribution-NonCommercial-ShareAlike Public License',
		tags => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nc}$SD$P{cc_sa}|BY${SD}NC${SD}SA|$P{cc_url}by-nc-sa))/,
	},
	cc_by_nd => {
		name    => 'CC-BY-ND',
		caption => 'CC by-nd',
		summary =>
			'Creative Commons Attribution-NoDerivatives Public License',
		tags => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_nd}|BY${SD}ND|$P{cc_url}by-nd))/,
	},
	cc_by_sa => {
		name    => 'CC-BY-SA',
		caption => 'CC by-sa',
		summary => 'Creative Commons Attribution-ShareAlike Public License',
		tags    => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_by}$SD$P{cc_sa}|BY${SD}SA|$P{cc_url}by-sa))/,
	},
	cc_cc0 => {
		name    => 'CC0',
		summary => 'Creative Commons CC0 Public License',
		tags    => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_cc0}(?: \(?"CC0"?\)?)?|CC0|$P{cc_url_pd}zero))/,
	},
	cc_sp => {
		caption => 'CC Sampling Plus',
		summary => 'Creative Commons Sampling Plus Public License',
		tags    => ['cc'],
		pat =>
			qr/(?:$P{cc}$SD(?:$P{cc_sp}|$P{cc_url}sampling\+))/,
	},
	cddl => {
		name    => 'CDDL',
		summary => 'Common Development and Distribution License',
		pat =>
			qr/(?:$the?(?:Common Development and Distribution License|COMMON DEVELOPMENT AND DISTRIBUTION LICENSE)(?: \(CDDL\))?|${the}CDDL\b)/,
	},
	cecill => {
		name    => 'CECILL',
		caption => 'CeCILL',
		pat =>
			qr/(?:CONTRAT DE LICENCE DE LOGICIEL LIBRE |(?:la )?licence |$the?FREE SOFTWARE LICENSING AGREEMENT )?CeCILL/,
	},
	cecill_1 => {
		name    => 'CECILL-1.0',
		caption => 'CeCILL-1.0',
		pat =>
			qr/Version 1 du 21\/06\/2004/,
	},
	cecill_1_1 => {
		name    => 'CECILL-1.1',
		caption => 'CeCILL-1.1',
		pat =>
			qr/Version 1\.1 of 10\/26\/2004/,
	},
	cecill_2 => {
		name    => 'CECILL-2.0',
		caption => 'CeCILL-2.0',
		pat =>
			qr/Version 2\.0 (?:du|dated) 2006-09-05/,
	},
	cecill_2_1 => {
		name    => 'CECILL-2.1',
		caption => 'CeCILL-2.1',
		pat =>
			qr/Version 2\.1 (?:du|dated) 2013-06-21/,
	},
	cecill_b => {
		name    => 'CECILL-B',
		caption => 'CeCILL-B',
		pat =>
			qr/the two main principles guiding its drafting|CeCILL-B/,
	},
	cecill_c => {
		name    => 'CECILL-C',
		caption => 'CeCILL-C',
		pat =>
			qr/CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-C/,
	},
	cube => {
		name => 'Cube',
		tags => ['zlib'],
		pat =>
			qr/$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}\. $P{use_ack_nonreq}\. $P{altered_srcver_mark}\. $P{notice_no_alter_any}\. additional clause specific to Cube:? $P{src_no_relicense}/,
	},
	curl => {
		tags => ['mit'],
		pat  => qr/$P{note_copr_perm}\.\s+$P{asis_sw_warranty}/,
	},
	dsdp => {
		name                     => 'DSDP',
		'caption.alt.org.fedora' => 'DSDP a.k.a. MIT (PetSC variant)',
		tags                     => ['mit'],
		pat => qr/This program discloses material protectable/,
	},
	epl => {
		name    => 'EPL',
		summary => 'Eclipse Public License',
		pat => qr/(?:$the?Eclipse Public License(?: \(EPL\))?|${the}EPL\b)/,
	},
	eurosym => {
		name => 'Eurosym',
		tags => ['zlib'],
		pat =>
			qr/$P{origin_sw_no_misrepresent}.*?$P{altered_srcver_mark}.*?$P{change_redist_share}.*?$P{notice_no_alter}/,
	},
	fsfap => {
		name    => 'FSFAP',
		caption => 'FSF All Permissive',
		pat =>
			qr/Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved/,
	},
	fsful => {
		name    => 'FSFUL',
		caption => 'FSF Unlimited',
		pat     => qr/This configure script is free software; $fsf_ul/,
	},
	fsfullr => {
		name    => 'FSFULLR',
		caption => 'FSF Unlimited (with Retention)',
		pat     => qr/This file is free software; $fsf_ullr/,
	},
	ftl => {
		name    => 'FTL',
		caption => 'Freetype',
		pat =>
			qr/$the?(?:FreeType(?: [Pp]roject)? (?:LICENSE|[Ll]icense)(?: \(FTL\))?)/,
	},
	gfdl => {
		name    => 'GFDL',
		summary => 'GNU Free Documentation License',
		pat =>
			qr/(?:$the?$gnu?Free Documentation License(?: \(GFDL\))?$by_fsf?|(?:$the$gnu?|$gnu)GFDL)/,
	},
	gfdl_niv => {
		name    => 'GFDL-NIV',
		caption => 'GFDL (no invariant sections)',
		summary =>
			'GNU Free Documentation License, with no Front-Cover or Back-Cover Texts or Invariant Sections',
		pat =>
			qr/(?:$the?$gnu?Free Documentation License(?: \(GFDL\))?$by_fsf?[,;]? $niv|(?:$the$gnu?|$gnu)GFDL-NIV)/,
	},
	gpl => {
		name    => 'GPL',
		summary => 'The GNU General Public License',
		pat =>
			qr/(?:$the?$gnu?$gpl(?: \(GPL\))?$by_fsf?|(?:$the$gnu?|$gnu)GPL)/,
	},
	isc => {
		name => 'ISC',
		tags => ['mit'],
		pat  => qr/$P{note_copr_perm}\.\s+$P{asis_sw_name_discl}/,
	},
	icu => {
		name => 'ICU',
		tags => ['mit'],
		pat =>
			qr/$P{note_copr_perm} of the Software and that $P{repro_copr_perm_appear_doc}\.\s+$P{asis_sw_warranty}(?:[^.]+\.\s+){2}$P{nopromo_except}/,
	},
	lgpl => {
		name    => 'LGPL',
		summary => 'The GNU Lesser General Public License',
		pat =>
			qr/(?:$the?$gnu?(?:Library|Lesser(?: \(Library\))?) $gpl(?: \(LGPL\))?$by_fsf?|(?:$the$gnu?|$gnu)LGPL)/,
	},
	llgpl => {
		name    => 'LLGPL',
		summary => 'Lisp Lesser General Public License',
		pat     => qr/(?:$the?Lisp Lesser $gpl(?: \(LLGPL\))?|${the}LLGPL\b)/,
	},
	libpng => {
		name => 'Libpng',
		pat =>
			qr/$P{origin_src_no_misrepresent}\. $P{altered_ver_mark}\. $P{copr_no_alter}/,
	},
	mit_advertising => {
		name    => 'MIT-advertising',
		caption => 'MIT (advertising)',
		tags    => ['mit'],
		pat => qr/$P{note_marketing}\b[^.,]+, and $P{ack_doc_mat_pkg_use}/,
	},
	mit_cmu => {
		name        => 'MIT-CMU',
		description => <<'END',
Identical to NTP, except...
 * omit explicit permission for charging fee
 * exclude suitability disclaimer
 * exclude terse "as is" warranty disclaimer
 * include elaborate warranty disclaimer
 * include liability disclaimer

fingerprint: "without specific written permission"

SPDX and fedora sample seem not generic but the unique file COPYING from project net-snmp.
END
		tags => ['mit'],
		pat =>
			qr/Permission $P{to_dist} $P{sw_doc} $P{any_purpose} and $P{nofee} $P{granted}, $P{retain_copr_appear} and that $P{repro_copr_perm_appear_doc}, and that $P{nopromo_name_written}\./,
	},
	mit_cmu_warranty => {
		'name.alt.org.debian'    => 'MIT-CMU~warranty',
		caption                  => 'MIT (CMU, retain warranty disclaimer)',
		'caption.alt.org.fedora' => 'MIT (MLton / Standard ML of New Jersey)',
		description              => <<'END',
Identical to MIT-CMU, except...
 * add requirement of "warranty disclaimer" appearing in documentation

fingerprint: "warranty disclaimer appear"
END
		tags => ['mit'],
		pat =>
			qr/Permission $P{to_dist} $P{sw_doc} $P{any_purpose} and $P{nofee} $P{granted}, $P{retain_copr_appear} and that $P{repro_copr_perm_warr_appear_doc}, and that $P{nopromo_name_written_prior}\./,
	},
	mit_enna => {
		name    => 'MIT-enna',
		caption => 'MIT (enna)',
		tags    => ['mit'],
		pat     => qr/$P{ack_pub_use_nosrc}/,
		pat =>
			qr/$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_sw}, $P{to_deal_the_sw_rights} $P{to_mod_sublic} $P{sw}, and $P{to_perm_pers}, $P{subj_cond}:? $P{retain_copr_perm_sw_copr}\. $P{ack_pub_use_nosrc}\. This includes acknowledgments in either Copyright notices, Manuals, Publicity and Marketing documents or any documentation provided with any product containing this software\. $P{license_not_lib}\./,
	},
	mit_feh => {
		name    => 'MIT-feh',
		caption => 'MIT (feh)',
		tags    => ['mit'],
		pat =>
			qr/$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_sw}, $P{to_deal_the_sw_rights} $P{to_mod_sublic} $P{sw}, and $P{to_perm_pers}, $P{subj_cond}:? $P{retain_copr_perm_sw_doc} and $P{ack_doc_pkg_use}\./,
	},
	mit_new => {
		'name.alt.org.spdx'      => 'MIT',
		'name.alt.org.debian'    => 'Expat',
		caption                  => 'MIT (Expat)',
		'caption.alt.org.debian' => 'MIT/X11 (BSD like)',
		'caption.alt.org.fedora' => 'MIT (Modern Style with sublicense)',
		tags                     => ['mit'],
		pat =>
			qr/$P{to_mod_sublic} $P{sw}\b[^.]+\s+$P{retain_copr_perm_subst}/,
	},
	mit_new_materials => {
		'name.alt.org.debian' => 'MIT~Khronos',
		caption               => 'MIT (Khronos)',
		tags                  => ['mit'],
		pat =>
			qr/$P{perm_granted}, $P{free_charge}, $P{to_pers} $P{the_material}, $P{to_deal_mat}/,
	},
	mit_old => {
		'name.alt.org.debian' => 'MIT~old',
		'name.alt.org.gentoo' => 'Old-MIT',
		caption               => 'MIT (old)',
		tags                  => ['mit'],
		pat                   => qr/$P{perm_granted}, $P{free_agree_fee}/,
	},
	mit_oldstyle => {
		'name.alt.org.debian' => 'MIT~oldstyle',
		caption               => 'MIT (Old Style)',
		description           => <<'END',
Origin: Possibly by Jamie Zawinski in 1993 for xscreensaver.
END
		tags => ['mit'],
		pat  => qr/documentation\. +No representations are made/,
	},
	mit_oldstyle_disclaimer => {
		'name.alt.org.debian' => 'MIT~oldstyle~disclaimer',
		caption               => 'MIT (Old Style, legal disclaimer)',
		tags                  => ['mit'],
		pat => qr/supporting documentation\.\s+$P{asis_name_sw}/,
	},
	mit_oldstyle_permission => {
		'name.alt.org.debian' => 'MIT~oldstyle~permission',
		tags                  => ['mit'],
		pat => qr/$P{without_written_prior}\.\s+$P{asis_name_sw}/,
	},
	mpl => {
		name    => 'MPL',
		summary => 'Mozilla Public License',
		pat =>
			qr/(?:$the?Mozilla Public License(?: \(\"?(?:https?:?\/\/mozilla.org\/)?MPL\"?\))?(?: (?:as )?published by $the{0,2}Mozilla Foundation)?|${the}MPL\b)/,
	},
	ms_pl => {
		name    => 'MS-PL',
		caption => 'Ms-PL',
		pat =>
			qr/(?:$the?Microsoft Public License(?: \(Ms-PL\))?|${the}Ms-PL\b)/,
	},
	ms_rl => {
		name    => 'MS-RL',
		caption => 'Ms-RL',
		pat =>
			qr/(?:$the?Microsoft Reciprocal License(?: \(Ms-RL\))?|${the}Ms-RL\b)/,
	},
	ntp => {
		name => 'NTP',
		tags => ['mit'],
		pat  => $P{asis_expr_warranty},
	},
	ntp_disclaimer => {
		'name.alt.org.debian' => 'NTP~disclaimer',
		caption               => 'NTP (legal disclaimer)',
		tags                  => ['mit'],
		pat => qr/$P{asis_expr_warranty}\.\s+$P{discl_name_warranties}/,
	},
	openssl => {
		name    => 'OpenSSL',
		summary => 'OpenSSL License',
		pat     => qr/$P{redist_ack_this}/,
	},
	postgresql => {
		name => 'PostgreSQL',
		tags => ['mit'],
		pat  => qr/$P{permission_use_fee_agree}/i,
	},
	public_domain => {
		name    => 'public-domain',
		caption => 'Public domain',
		pat     => qr/$the?public domain/,
	},
	ofl => {
		name                     => 'OFL',
		'caption.alt.org.debian' => 'SIL',
		pat =>
			qr/$the?(?:SIL )?(?:OPEN FONT LICENSE|[Oo]pen [Ff]ont [Ll]icense)(?: \(OFL\))?/,
	},
	python => {
		name    => 'Python',
		caption => 'PSF',
		pat =>
			qr/$the?Python Software Foundation License|PYTHON SOFTWARE FOUNDATION LICENSE/,
	},
	qpl => {
		name    => 'QPL',
		summary => '$the?Q Public License',
		pat =>
			qr/(?:$the?Q Public License(?: \(QPL\))?$by_fsf?|${the}QPL\b)/,
	},
	rpsl => {
		name    => 'RPSL',
		caption => 'RealNetworks Public Source License',
		pat =>
			qr/$the?RealNetworks Public Source License/,
	},
	sgi_b => {
		name    => 'SGI-B',
		caption => 'SGI Free Software License B',
		pat =>
			qr/(?:$the?SGI (?:Free Software License|FREE SOFTWARE LICENSE) B(?: \(SGI-B\))?$by_fsf?|(?:SGI )?FreeB\b|${the}SGI-B\b)/,
	},
	unicode_strict => {
		name    => 'Unicode-strict',
		caption => 'Unicode strict',
		pat     => qr/hereby grants the right to freely use/,
	},
	unicode_tou => {
		name    => 'Unicode-TOU',
		caption => 'Unicode Terms Of Use',
		pat =>
			qr/distribute all documents and files solely for informational/,
	},
	wtfpl => {
		name    => 'WTFPL',
		caption => 'do What The Fuck you want to Public License',
		pat =>
			qr/(?:$the?[Dd]o What The Fuck [Yy]ou [Ww]ant [Tt]o Public License|DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE(?: \(WTFPL\))?|${the}WTFPL\b)/,
	},
	zlib => {
		name    => 'Zlib',
		caption => 'zlib/libpng',
		tags    => ['zlib'],
		pat =>
			qr/$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}\. $P{use_ack_nonreq}\. $P{altered_srcver_mark}\. $P{notice_no_alter}/,
	},
	zlib_acknowledgement => {
		name                => 'NUnit',
		'name.alt.org.SPDF' => 'zlib-acknowledgement',
		tags                => ['zlib'],
		pat =>
			qr/$P{origin_sw_no_misrepresent}; $P{you_not_claim_wrote}\. $P{use_ack_req}\. Portions Copyright \S+ [\d-]+ Charlie Poole or Copyright \S+ [\d-]+ James W\. Newkirk, Michael C\. Two, Alexei A\. Vorontsov or Copyright \S+ [\d-]+ Philip A\. Craig $P{altered_srcver_mark}\. $P{notice_no_alter}/,
	},
);

=head2 Licensing traits

Patterns each covering a single trait occuring in licenses.

=over

=item * clause_retention

=item * clause_reproduction

=item * clause_advertising

=item * clause_advertising_always

=item * clause_non_endorsement

=item * fsf_unlimited

=item * fsf_unlimited_retention

=item * version_later

=item * version_later_paragraph

=item * version_later_postfix

=item * version_number

=item * version_prefix

=back

=cut

$RE{'clause_retention'} = {
	caption => 'retention clause',
	tags    => ['trait'],
	pat     => qr/$P{retain_notice_cond_discl}/,
};

$RE{'clause_reproduction'} = {
	caption => 'reproduction clause',
	tags    => ['trait'],
	pat     => qr/$P{repro_copr_cond_discl}/,
};

$RE{'clause_advertising'} = {
	caption => 'advertising clause',
	tags    => ['trait'],
	pat     => qr/$P{ad_mat_ack_this}/,
};

$RE{'clause_advertising_always'} = {
	caption => 'advertising clause (always)',
	tags    => ['trait'],
	pat     => qr/$P{redist_ack_this}/,
};

$RE{'clause_non_endorsement'} = {
	caption => 'non-endorsement clause',
	tags    => ['trait'],
	pat     => qr/$P{nopromo_neither}/,
};

$RE{'fsf_unlimited'} = {
	tags => ['trait'],
	pat  => qr/$fsf_ul/,
};

$RE{'fsf_unlimited_retention'} = {
	tags => ['trait'],
	pat  => qr/$fsf_ullr/,
};

$RE{'version_later'} = {
	caption => 'version "or later"',
	tags    => ['trait'],
	pat     => qr/,? $P{ver_later_postfix}|\. $P{ver_later_para}/,
};

$RE{'version_later_paragraph'} = {
	caption => 'version "or later" postfix (paragraphs)',
	tags    => ['trait'],
	pat     => qr/$P{ver_later_para}/,
};

$RE{'version_later_postfix'} = {
	caption => 'version "or later" (postfix)',
	tags    => ['trait'],
	pat     => qr/$P{ver_later_postfix}/,
};

$RE{'version_number'} = {
	caption => 'version number',
	tags    => ['trait'],
	pat     => qr/$P{ver_number}/,
};

$RE{'version_prefix'} = {
	caption => 'version prefix',
	tags    => ['trait'],
	pat     => qr/$P{ver_prefix}/,
};

=head2 License combinations

Patterns each covering a single combination of multiple licenses.

=over

=item * perl

=back

=cut

$RE{'perl'} = {
	name    => 'Artistic or GPL-1+',
	caption => 'Perl',
	tags    => ['combo'],
	pat =>
		qr/the same terms as $the?Perl(?: ?5)?( programming| language| system){0,3} itself/,
};

=head2 Multiple licenses

Patterns each covering multiple licenses.

=over

=item * bsd

=item * gnu

=item * mit

=back

=cut

$RE{'bsd'} = {
	name    => 'BSD~unspecified',
	caption => 'BSD (unspecified)',
	tags    => ['group'],
	pat =>
		qr/$P{repro_copr_cond_discl}(?:(?:[\d\W]+$P{ad_mat_ack_this}.*)?[\d\W]+$P{nopromo_neither})?/,
};

$RE{'gnu'} = {
	name    => 'AGPL/GPL/LGPL',
	summary => 'a GNU license (AGPL or GPL or LGPL)',
	tags    => ['group'],
	pat     => qr/(?:$RE{agpl}{pat}|$RE{gpl}{pat}|$RE{lgpl}{pat})/,
};

$RE{'mit'} = {
	name    => 'MIT~unspecified',
	caption => 'MIT (unspecified)',
	tags    => ['group'],
	pat     => qr/${the}MIT\b/,
};

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
