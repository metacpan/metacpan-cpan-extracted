package Regexp::Pattern::License;

use utf8;
use strict;
use warnings;

my $CAN_RE2;

BEGIN {
	eval { require re::engine::RE2 };
	$CAN_RE2 = $@ ? '' : 1;
}

use Regexp::Pattern::License::Parts;

=head1 NAME

Regexp::Pattern::License - Regular expressions for legal licenses

=head1 VERSION

Version v3.10.1

=cut

our $VERSION = version->declare("v3.10.1");

=head1 SYNOPSIS

    use Regexp::Pattern::License;
    use Regexp::Pattern;

    my $string = 'GNU General Public License version 3 or later';

    print "Found!\n" if $string =~ re( 'License::gpl_3' );  # prints "Found!"

=head1 DESCRIPTION

L<Regexp::Pattern::License> provides a hash of regular expression patterns
related to legal software licenses.

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=cut

# internal patterns compiled into patterns
#  * must be unique, to not collide at their final use in gen_pat sub
#  * must be a unit, so that e.g. suffix "?" applies to whole chunk

# [  ]          end-of-paragraph space
# [ ]           end-of-sentence space
# [.]           full stop
# [. ]          full stop and either one or two spaces or newline
# [, ]          comma and space (space optional for wide comma)
# [:]           colon
# [:"]          colon and maybe one or two quotes
# [;]           semicolon or colon or comma
# [']           apostrophe
# ["]           quote
# [". ]         full stop and either one or two spaces or newline, maybe quote before
# ["*]          quote or bullet
# [*]           bullet
# [*)]          start-of-sentence bullet or count
# [/]           slash or space or none
# [ / ]         slash, maybe space around
# [-]           dash, maybe space after, or none
# [--]          dash or two dashes
# [-#]          dash or number
# [- ]          dash or space
# [ - ]         dash with space around
# [+]           plus
# [(]           parens-open
# [)]           parens-close
# [<]           less-than
# [>]           greater-than
# [> ]          greater-than, maybe space after, or none
# [#.]          digits and maybe one infix dot
# [#-,]         digits, infix maybe one dash, suffix maybe comma maybe space
# [c]           copyright mark, maybe space before
# [as is]       as is, maybe quote around
# [eg]          exempli gratia, abbreviated
# [http://]     http or https protocol, or none
# [ie]          id est, abbreviated
# [r]           registered trademark, maybe space before
# [tm]          trademark, maybe space before
# [word]        word
# [ word]       space and word

my %_ANNOTATIONS = (
	'[. ]'  => '(?:\.\s{1,3})',
	'[, ]'  => '(?:, |[、，] ?)',
	'[*)]'  => '(?:\W{0,5}\S{0,2}\W{0,3})',
	'[:]'   => ':',
	'[:"]'  => '(?::\W{0,2})',
	'[-]'   => '(?:(?:[-–]\s{0,3})?)',
	'[--]'  => '(?:[-–—][-–]?)',
	'[-#]'  => '[-–\d]',
	'[- ]'  => '[-– ]',
	'[ - ]' => '(?: [-–—]{1,2} )',
	'[(]'   => '[(（]',
	'[)]'   => '[)）]',
	'[> ]'  => '(?:> ?|)',
	'[#.]'  => '(?:\d+(?:\.\d+)?)',
	'[#-,]' => '(?:\d+(?: ?[-–] ?\d+)?,? ?)',
	'[ ]'   => '(?:\s{1,3})',
	'[  ]'  => '(?:\s{1,3})',
	'["]'   => '(?:["«»˝̏“”„]|[\'<>`´‘’‹›‚]{0,2})',
	'[". ]' =>
		'(?:(?:["«»˝̏“”„]|[\'<>`´‘’‹›‚]{0,2})?\.\s{1,3})',
	'[\']'  => '(?:[\'`´‘’]?)',
	'["*]'  => '(?:\W{0,2})',
	'[;]'   => '[;:,、，]',
	'[/]'   => '(?:[ /]?)',
	'[ / ]' => '(?: ?[/] ?)',

	'[à]' => '(?:[àa]?)',
	'[è]' => '(?:[èe]?)',
	'[é]' => '(?:[ée]?)',
	'[ê]' => '(?:[êe]?)',
	'[l-]' => '(?:[łl]?)',

	'[c]'       => '(?: ?©| ?\([Cc]\))',
	'[as is]'   => '(?:\W{0,2}[Aa][Ss][- ][Ii][Ss]\W{0,2})',
	'[eg]'      => '(?:ex?\.? ?gr?\.?)',
	'[http://]' => '(?:https?://)?',
	'[ie]'      => '(?:i\.? ?e\.?)',
	'[r]'       => '(?: ?®| ?\([Rr]\))',
	'[tm]'      => '(?: ?™| ?\([Tt][Mm]\))',
	'[word]'    => '(?:\S+)',
	'[ word]'   => '(?: \S+)',
);

my %P;
while ( my ( $key, $val ) = each %Regexp::Pattern::License::Parts::RE ) {
	$P{$key} = $val->{pat};
}

my $the = '(?:[Tt]he )';

my $cc_no_law_firm
	= 'CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE LEGAL SERVICES[. ]';
my $cc_dist_no_rel
	= 'DISTRIBUTION OF THIS LICENSE DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[. ]';
my $cc_dist_no_rel_draft
	= 'DISTRIBUTION OF THIS DRAFT LICENSE DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[. ]';
my $cc_dist_no_rel_doc
	= 'DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[. ]';
my $cc_info_asis_discl
	= 'CREATIVE COMMONS PROVIDES THIS INFORMATION ON AN [as is] BASIS[. ]'
	. 'CREATIVE COMMONS MAKES NO WARRANTIES REGARDING THE INFORMATION PROVIDED, '
	. 'AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM ITS USE[.]';
my $cc_info_asis_discl_doc
	= 'CREATIVE COMMONS PROVIDES THIS INFORMATION ON AN [as is] BASIS[. ]'
	. 'CREATIVE COMMONS MAKES NO WARRANTIES REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED HEREUNDER, '
	. 'AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED HEREUNDER[.]';
my $cc_work_protected
	= 'THE WORK [(]?AS DEFINED BELOW[)]? IS PROVIDED UNDER THE TERMS OF THIS CREATIVE COMMONS PUBLIC LICENSE [(]?["]?CCPL["]? OR ["]?LICENSE["]?[)]?[. ]'
	. 'THE WORK IS PROTECTED BY COPYRIGHT AND[/]OR OTHER APPLICABLE LAW[. ]';
my $cc_auth_lic_prohib
	= 'ANY USE OF THE WORK OTHER THAN AS AUTHORIZED UNDER THIS LICENSE IS PROHIBITED[.][  ]?';
my $cc_auth_lic_copylaw_prohib
	= 'ANY USE OF THE WORK OTHER THAN AS AUTHORIZED UNDER THIS LICENSE OR COPYRIGHT LAW IS PROHIBITED[.][  ]?';
my $laws_confer
	= 'The laws of most jurisdictions throughout the world automatically confer';

my $cc_intro_1
	= '(?:(?:\S+ )?'
	. $cc_no_law_firm
	. $cc_dist_no_rel_draft
	. $cc_info_asis_discl
	. '(?: \S+)?[  ])?License[  ]'
	. $cc_work_protected
	. $cc_auth_lic_prohib;
my $cc_intro
	= '(?:(?:\S+ )?'
	. $cc_no_law_firm
	. $cc_dist_no_rel
	. $cc_info_asis_discl
	. '(?: \S+)?[  ])?License[  ]'
	. $cc_work_protected
	. $cc_auth_lic_copylaw_prohib;
my $cc_intro_cc0
	= '(?:(?:\S+ )?'
	. $cc_no_law_firm
	. $cc_dist_no_rel_doc
	. $cc_info_asis_discl_doc
	. '(?: \S+)?[  ])?Statement of Purpose[  ]'
	. $laws_confer;

my $cc_by_exercising_you_accept_this
	= '(?:By exercising the Licensed Rights [(]?defined below[)]?, You accept and agree to be bound by the terms and conditions of this '
	. '|BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGREE TO BE BOUND BY THE TERMS OF THIS )';
my $clisp_they_only_ref_clisp
	= 'They only reference external symbols in CLISP[\']s public packages '
	. 'that define API also provided by many other Common Lisp implementations '
	. '[(]namely the packages '
	. 'COMMON[-]LISP, COMMON[-]LISP[-]USER, KEYWORD, CLOS, GRAY, EXT[)] ';
my $gnu = '(?:GNU )';
my $gpl = '(?:General Public [Ll]icen[cs]e|GENERAL PUBLIC LICEN[CS]E)';
my $fsf = "(?:$the?Free Software Foundation)";
my $niv
	= 'with no Invariant Sections(?:, with no Front[-]Cover Texts, and with no Back[-]Cover Texts)?';
my $fsf_ul
	= "$fsf gives unlimited permission to copy, distribute and modify it";
my $fsf_ullr
	= "$fsf gives unlimited permission to copy and[/]or distribute it, "
	. 'with or without modifications, as long as this notice is preserved';

# internal-only patterns
my $_prop = '(?:[A-Za-z][A-Za-z0-9_]*)';
my $_any  = '[A-Za-z0-9_.]';

our %RE;

=head1 PATTERNS

=head2 Licensing traits

Patterns each covering a single trait occuring in licenses.

Each of these patterns has the tag B< type:trait >.

=over

=item * addr_fsf

I<Since v3.4.0.>

=item * addr_fsf_franklin

I<Since v3.4.0.>

=item * addr_fsf_franklin_steet

I<Since v3.4.0.>

=item * addr_fsf_mass

I<Since v3.4.0.>

=item * addr_fsf_temple

I<Since v3.4.0.>

=cut

$RE{addr_fsf} = {
	caption => 'FSF postal address',
	tags    => [
		'type:trait:address:gnu',
	],
};

$RE{addr_fsf_franklin} = {
	caption => 'FSF postal address (Franklin Street)',
	tags    => [
		'type:trait:address:gnu',
	],

	'pat.alt.subject.trait' =>
		'(?P<_addr_fsf_franklin>51 Franklin [Ss]t(?:reet|(?P<_addr_fsf_franklin_steet>eet)|\.)?, '
		. '(?:Fifth|5th) [Ff]loor(?:[;]? |[ - ])'
		. 'Boston,? MA 02110[-]1301,? USA[.]?)',
};

$RE{addr_fsf_franklin_steet} = {
	caption => 'mis-spelled FSF postal address (Franklin Steet)',
	tags    => [
		'type:trait:address:gnu',
		'type:trait:flaw:gnu',
	],

	'pat.alt.subject.trait' =>
		'(?P<_addr_fsf_franklin_steet>51 Franklin [Ss]teet, '
		. '(?:Fifth|5th) [Ff]loor(?:[;]? |[ - ])'
		. 'Boston,? MA 02110[-]1301,? USA[.]?)',
};

$RE{addr_fsf_mass} = {
	caption => 'obsolete FSF postal address (Mass Ave)',
	tags    => [
		'type:trait:address:gnu',
		'type:trait:flaw:gnu',
	],

	'pat.alt.subject.trait' =>
		'(?P<_addr_fsf_mass>675 [Mm]ass(?:achusett?ss?|\.)? [Aa]ve(?:nue|\.)?(?:(?:[;]? |[ - ])'
		. '[Cc]ambridge,? (?:MA|ma) 02139,? (?:USA|usa))?[.]?)',
};

$RE{addr_fsf_temple} = {
	caption => 'obsolete FSF postal address (Temple Place)',
	tags    => [
		'type:trait:address:gnu',
		'type:trait:flaw:gnu',
	],

	'pat.alt.subject.trait' =>
		'(?P<_addr_fsf_temple>5[39] Temple Place,? S(?:ui)?te 330(?:[;]? |[ - ])'
		. 'Boston,? MA 02111[-]1307,? USA[.]?)',
};

$RE{addr_fsf}{'pat.alt.subject.trait'} = _join_pats(
	{ label => '_addr_fsf' },
	$RE{addr_fsf_franklin}{'pat.alt.subject.trait'},
	$RE{addr_fsf_temple}{'pat.alt.subject.trait'},
	$RE{addr_fsf_mass}{'pat.alt.subject.trait'},
);

=item * any_of

I<Since v3.1.92.>

=cut

$RE{any_of} = {
	caption => 'license grant "any of the following" phrase',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' =>
		'(?P<_any_of>(?:any|one or more) of the following(?: licen[cs]es(?: at your choice)?)?)[.:]? ?',
};

=item * by

I<Since v3.3.0.>

=item * by_apache

I<Since v3.3.0.>

=item * by_fsf

I<Since v3.3.0.>

=item * by_james_clark

I<Since v3.3.0.>

=item * by_psf

I<Since v3.3.0.>

=item * by_sam_hocevar

I<Since v3.3.0.>

=cut

$RE{by} = {
	caption => 'license grant " as published by ..." phrase',
	tags    => [
		'type:trait:publisher',
	],

	'pat.alt.subject.trait' => '(?P<_by> ?(?:as )?published by[ word]{1,6})',
};

$RE{by_apache} = {
	caption =>
		'license grant "as published by the Apache Software Foundation" phrase',
	tags => [
		'type:trait:publisher:apache',
	],

	'pat.alt.subject.trait' =>
		'(?P<_by_apache> ?(?:as )?published by the Apache Software Foundation)',
};

$RE{by_fsf} = {
	caption =>
		'license grant "as published by the Free Software Foundation" phrase',
	tags => [
		'type:trait:publisher:gnu',
	],

	'pat.alt.subject.trait' => '(?P<_by_fsf> ?(?:as )?published by '
		. $fsf
		. '(?: [(]'
		. $P{fsf_url}
		. '[)])?(?:,? Inc\.?)?'
		. '(?:,? ?'
		. $RE{addr_fsf}{'pat.alt.subject.trait'} . ')?)',
};

$RE{by_james_clark} = {
	caption => 'license grant "as published by James Clark" phrase',
	tags    => [
		'type:trait:publisher:mit_new',
	],

	'pat.alt.subject.trait' =>
		'(?P<_by_hames_clark> ?(?:as )?published by James Clark)',
};

$RE{by_psf} = {
	caption =>
		'license grant "as published by the Python Software Foundation" phrase',
	tags => [
		'type:trait:publisher:python',
	],

	'pat.alt.subject.trait' =>
		'(?P<_by_psf> ?(?:as )?published by the Python Software Foundation)',
};

$RE{by_sam_hocevar} = {
	caption => 'license grant "as published by Sam Hocevar" phrase',
	tags    => [
		'type:trait:publisher:wtfpl',
	],

	'pat.alt.subject.trait' =>
		'(?P<_by_sam_hocevar> ?(?:as )?published by Sam Hocevar)',
};

=item * clause_retention

=cut

$RE{clause_retention} = {
	caption => 'retention clause',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $P{retain_notice_cond_discl},
};

=item * clause_reproduction

=cut

$RE{clause_reproduction} = {
	caption => 'reproduction clause',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $P{repro_copr_cond_discl},
};

=item * clause_advertising

=item * clause_advertising_always

=cut

$RE{clause_advertising} = {
	caption => 'advertising clause',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $P{ad_mat_ack_this},
};

$RE{clause_advertising_always} = {
	caption => 'advertising clause (always)',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $P{redist_ack_this},
};

=item * clause_non_endorsement

=cut

$RE{clause_non_endorsement} = {
	caption => 'non-endorsement clause',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $P{nopromo_neither},
};

=item * except_389

=cut

$RE{except_389} = {
	name                                    => '389-exception',
	'name.alt.org.debian'                   => '389',
	'name.alt.org.spdx.since.date_20150730' => '389-exception',
	caption                  => '389 Directory Server Exception',
	'caption.alt.org.fedora' => 'Fedora Directory Server License',
	'iri.alt.org.fedora.archive.time_20140723121431' =>
		'http://directory.fedoraproject.org/wiki/GPL_Exception_License_Text',
	tags => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'Red Hat, Inc\. gives You the additional right '
		. 'to link the code of this Program '
		. 'with code not covered under the GNU General Public License '
		. '[(]["]Non-GPL Code["][)] '
		. 'and to distribute linked combinations including the two, '
		. 'subject to the limitations in this paragraph[. ]'
		. 'Non[-]GPL Code permitted under this exception '
		. 'must only link to the code of this Program '
		. 'through those well defined interfaces identified '
		. 'in the file named EXCEPTION found in the source code files '
		. '[(]the ["]Approved Interfaces["][)][.]',
};

=item * except_autoconf_data

I<Since v3.4.0.>

=item * except_autoconf_2

I<Since v3.4.0.>

=item * except_autoconf_2_archive

I<Since v3.4.0.>

=item * except_autoconf_2_autotroll

I<Since v3.4.0.>

=item * except_autoconf_2_g10

I<Since v3.4.0.>

=item * except_autoconf_3

I<Since v3.4.0.>

=cut

$RE{except_autoconf_data} = {
	name    => 'Autoconf-data',
	caption => 'Autoconf data exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'if you distribute this file as part of a program '
		. 'that contains a configuration script generated by Autoconf, '
		. 'you may include it under the same distribution terms '
		. 'that you use for the rest of that program',
};

$RE{except_autoconf_2} = {
	name                                    => 'Autoconf-exception-2.0',
	'name.alt.org.debian'                   => 'Autoconf-2.0',
	'name.alt.org.spdx.until.date_20150513' =>
		'GPL-2.0-with-autoconf-exception',
	'name.alt.org.spdx.since.date_20150513'    => 'Autoconf-exception-2.0',
	caption                                    => 'Autoconf exception 2.0',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v2.0 w/Autoconf exception',
	'caption.alt.org.spdx.since.date_20150513' => 'Autoconf exception 2.0',
	tags                                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		'the Free Software Foundation gives unlimited permission '
		. 'to copy, distribute and modify configure scripts ',
	'pat.alt.subject.trait.part.part2' =>
		'This special exception to the GPL applies '
		. 'to versions of Autoconf',
};

$RE{except_autoconf_2_archive} = {
	name                  => 'Autoconf-exception-2.0~Archive',
	'name.alt.org.debian' => 'Autoconf-2.0~Archive',
	caption               => 'Autoconf exception 2.0 (Autoconf Archive)',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		'the respective Autoconf Macro[\']s copyright owner '
		. 'gives unlimited permission ',
	'pat.alt.subject.trait.part.part2' =>
		'This special exception to the GPL applies '
		. 'to versions of the Autoconf',
};

$RE{except_autoconf_2_autotroll} = {
	name                  => 'Autoconf-exception-2.0~AutoTroll',
	'name.alt.org.debian' => 'Autoconf-2.0~AutoTroll',
	caption               => 'Autoconf exception 2.0 (AutoTroll)',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		'the copyright holders of AutoTroll '
		. 'give you unlimited permission ',
	'pat.alt.subject.trait.part.part2' =>
		'This special exception to the GPL applies '
		. 'to versions of AutoTroll',
};

$RE{except_autoconf_2_g10} = {
	name                  => 'Autoconf-exception-2.0~g10',
	'name.alt.org.debian' => 'Autoconf-2.0~g10',
	caption               => 'Autoconf exception 2.0 (g10 Code)',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.part.part1' =>
		'g10 Code GmbH gives unlimited permission',
	'pat.alt.subject.trait.part.part2' =>
		'Certain portions of the mk[word]\.awk source text are designed',
	'pat.alt.subject.trait.part.part3' =>
		'If your modification has such potential, you must delete',
};

$RE{except_autoconf_3} = {
	name                                    => 'Autoconf-exception-3.0',
	'name.alt.org.debian'                   => 'Autoconf-3.0',
	'name.alt.org.spdx.until.date_20150513' =>
		'GPL-3.0-with-autoconf-exception',
	'name.alt.org.spdx.since.date_20150513'    => 'Autoconf-exception-3.0',
	caption                                    => 'Autoconf exception 3.0',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v3.0 w/Autoconf exception',
	'caption.alt.org.spdx.since.date_20150513' => 'Autoconf exception 3.0',
	tags                                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		"The purpose of this Exception is to allow distribution of Autoconf[']s",
};

=item * except_bison_1_24

I<Since v3.4.0.>

=item * except_bison_2_2

I<Since v3.4.0.>

=cut

$RE{except_bison_1_24} = {
	name    => 'Bison-1.24',
	caption => 'Bison exception 1.24',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'when this file is copied by Bison into a Bison output file',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'when this file is copied by Bison into a Bison output file, '
		. 'you may use that output file without restriction[. ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'This special exception was added by the Free Software Foundation'
		. 'in version 1\.24 of Bison[.]'
};

$RE{except_bison_2_2} = {
	name                                    => 'Bison-exception-2.2',
	'name.alt.org.debian'                   => 'Bison-2.2',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-2.0-with-bison-exception',
	'name.alt.org.spdx.since.date_20150513' => 'Bison-exception-2.2',
	caption                                 => 'Bison exception 2.2',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v2.0 w/Bison exception',
	'caption.alt.org.spdx.since.date_20150513' => 'Bison exception 2.2',
	tags                                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you may create a larger work that contains '
		. 'part or all of the Bison parser skeleton',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'you may create a larger work that contains '
		. 'part or all of the Bison parser skeleton'
		. 'and distribute that work under terms of your choice, '
		. 'so long as that work isn[\']t itself a parser generator'
		. 'using the skeleton or a modified version thereof '
		. 'as a parser skeleton[.]'
		. 'Alternatively, if you modify or redistribute the parser skeleton itself, '
		. 'yoy may [(]at your option[)] remove this special exception, '
		. 'which will cause the skeleton and the resulting Bison output files '
		. 'to be licensed under the GNU General Public License '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'This special exception was added by the Free Software Foundation'
		. 'in version 2\.2 of Bison[.]'
};

=item * except_classpath_2

=cut

$RE{except_classpath_2} = {
	name                                    => 'Classpath-exception-2.0',
	'name.alt.org.debian'                   => 'Classpath-2.0',
	'name.alt.org.spdx.until.date_20150513' =>
		'GPL-2.0-with-classpath-exception',
	'name.alt.org.spdx.since.date_20150513'    => 'Classpath-exception-2.0',
	'name.alt.org.wikidata.synth.nogrant'      => 'Q1486447',
	caption                                    => 'Classpath exception 2.0',
	'caption.alt.org.fedora'                   => 'Classpath exception',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v2.0 w/Classpath exception',
	'caption.alt.org.spdx.since.date_20150513' => 'Classpath exception 2.0',
	'caption.alt.org.wikidata'                 => 'GPL linking exception',
	tags                                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'link this library with independent modules',
	'pat.alt.subject.trait.scope.multisection.part.intro' =>
		'Linking this library statically or dynamically with other modules '
		. 'is making a combined work based on this library[. ]'
		. 'Thus, the terms and conditions of the GNU General Public License '
		. 'cover the whole combination[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'the copyright holders of this library give you permission '
		. 'to link this library with independent modules to produce an executable, '
		. 'regardless of the license terms of these independent modules, '
		. 'and to copy and distribute the resulting executable '
		. 'under terms of your choice, '
		. 'provided that you also meet, '
		. 'for each linked independent module, '
		. 'the terms and conditions of the license of that module[. ]?',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'An independent module is a module '
		. 'which is not derived from or based on this library[. ]'
		. 'If you modify this library, '
		. 'you may extend this exception to your version of the library, '
		. 'but you are not obligated to do so[. ]'
		. 'If you do not wish to do so, '
		. 'delete this exception statement from your version[.]',
};

=item * except_ecos_2

I<Since v3.6.0.>

=cut

$RE{except_ecos_2} = {
	name                                    => 'eCos-exception-2.0',
	'name.alt.org.spdx.since.date_20150513' => 'eCos-exception-2.0',
	caption                                 => 'eCos exception 2.0',
	description                             => <<'END',
Identical to Macros and Inline Functions Exception, except...
* drop explicit permission to use without restriction
* replace "files" and "excecutable" with "works"
* add reference to GPL section 3
END
	iri  => 'http://sources.redhat.com/ecos/ecos-license/',
	tags => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		'if other files instantiate templates or use macros or inline functions from this file, '
		. 'or you compile this file and link it with other works',
	'pat.alt.subject.trait.scope.line.scope.sentence.part.part2' =>
		'However the source code for this file must still be made available',
	'pat.alt.subject.trait.scope.line.scope.sentence.part.part3' =>
		'This exception does not invalidate any other reasons why',
};

=item * except_epl

=cut

$RE{except_epl} = {
	name    => 'EPL-library',
	caption => 'EPL-library exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you have the permission to link the code of this program '
		. 'with any library released under the EPL license '
		. 'and distribute linked combinations including the two[.]',
	'pat.alt.subject.trait.scope.paragraph.part.all' =>
		'you have the permission to link the code of this program '
		. 'with any library released under the EPL license '
		. 'and distribute linked combinations including the two[. ]'
		. 'If you modify this file, '
		. 'you may extend this exception to your version of the file, '
		. 'but you are not obligated to do so[. ]'
		. 'If you do not wish to do so, '
		. 'delete this exception statement from your version[.]',
};

=item * except_epl_mpl

=cut

$RE{except_epl_mpl} = {
	name    => 'EPL-MPL-library',
	caption => 'EPL-MPL-library exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you have the permission to link the code of this program '
		. 'with any library released under the EPL license '
		. 'and distribute linked combinations including the two[;] '
		. 'the MPL [(]Mozilla Public License[)], '
		. 'which EPL [(]Erlang Public License[)] is based on, '
		. 'is included in this exception.',
};

=item * except_faust

I<Since v3.4.0.>

=cut

$RE{except_faust} = {
	name    => 'FAUST',
	caption => 'FAUST exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you may create a larger work that contains '
		. 'this FAUST architecture section',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'you may create a larger work that contains '
		. 'this FAUST architecture section '
		. 'and distribute that work under terms of your choice, '
		. 'so long as this FAUST architecture section is not modified[.]',
};

=item * except_font_2

I<Since v3.7.0.>

=cut

$RE{except_font_2} = {
	name                                    => 'Font-exception-2.0',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-2.0-with-font-exception',
	'name.alt.org.spdx.since.date_20150513' => 'Font-exception-2.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q5514182',
	caption                                 => 'Font exception 2.0',
	'caption.alt.org.fedora'                => 'font embedding exception',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v2.0 w/Font exception',
	'caption.alt.org.spdx.since.date_20150513' => 'Font exception 2.0',
	'caption.alt.org.wikidata'                 => 'GPL font exception',
	tags                                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'if you create a document which uses this font, ',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'if you create a document which uses this font, '
		. 'and embed this font or unaltered portions of this font into the document, '
		. 'this font does not by itself cause the resulting document '
		. 'to be covered by the GNU General Public License' . '[. ]'
		. 'This exception does not however invalidate any other reasons why '
		. 'the document might be covered by the GNU General Public License'
		. '[. ]'
		. 'If you modify this font, '
		. 'you may extend this exception to your version of the font, '
		. 'but you are not obligated to do so' . '[. ]'
		. 'If you do not wish to do so, delete this exception statement from your version[.]',
};

=item * except_gcc_2

I<Since v3.7.0.>

=item * except_gcc_3_1

I<Since v3.7.0.>

=cut

$RE{except_gcc_2} = {
	name                                    => 'GCC-exception-2.0',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-2.0-with-GCC-exception',
	'name.alt.org.spdx.since.date_20150513' => 'GCC-exception-2.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q89706542',
	caption => 'GCC Runtime Library exception 2.0',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v2.0 w/GCC Runtime Library exception',
	'caption.alt.org.spdx.since.date_20150513' =>
		'GCC Runtime Library exception 2.0',
	'caption.alt.org.wikidata' =>
		'GNU General Public License, version 2.0 or later with library exception',
	tags => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'the Free Software Foundation gives you unlimited permission '
		. 'to link the compiled version of this file into combinations with other programs',
};

$RE{except_gcc_3_1} = {
	name                                    => 'GCC-exception-3.1',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-3.0-with-GCC-exception',
	'name.alt.org.spdx.since.date_20150513' => 'GCC-exception-3.1',
	caption => 'GCC Runtime Library exception 3.1',
	'caption.alt.org.spdx.until.date_20150513' =>
		'GNU General Public License v3.0 w/GCC Runtime Library exception',
	'caption.alt.org.spdx.since.date_20150513' =>
		'GCC Runtime Library exception 3.1',
	tags => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'You have permission to propagate a work of Target Code formed',
};

=item * except_gstreamer

=cut

$RE{except_gstreamer} = {
	name    => 'GStreamer',
	caption => 'GStreamer exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'The[ word]{1,3} project hereby grant permission '
		. 'for non-gpl compatible GStreamer plugins '
		. 'to be used and distributed together with GStreamer and[ word]{1,3}[. ]'
		. 'This permission are above and beyond '
		. 'the permissions granted by the GPL license[ word]{1,3} is covered by[.]',
};

=item * except_libtool

=cut

$RE{except_libtool} = {
	name                                    => 'Libtool-exception',
	'name.alt.org.debian'                   => 'Libtool',
	'name.alt.org.spdx.since.date_20150730' => 'Libtool-exception',
	caption                                 => 'Libtool Exception',
	tags                                    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'if you distribute this file as part of a program or library '
		. 'that is built using GNU Libtool, '
		. 'you may include this file under the same distribution terms '
		. 'that you use for the rest of that program[.]',
};

=item * except_mif

=cut

$RE{except_mif} = {
	name                                    => 'mif-exception',
	'name.alt.org.debian'                   => 'mif',
	'name.alt.org.spdx.since.date_20150730' => 'mif-exception',
	caption => 'Macros and Inline Functions Exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.multisection.part.first' =>
		'you may use this file '
		. 'as part of a free software library without restriction[. ]'
		. 'Specifically, if other files instantiate templates ',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'you may use this file '
		. 'as part of a free software library without restriction[. ]'
		. 'Specifically, if other files instantiate templates '
		. 'or use macros or inline functions from this file, '
		. 'or you compile this file and link it with other files '
		. 'to produce an executable, '
		. 'this file does not by itself cause the resulting executable '
		. 'to be covered by the GNU General Public License[. ]'
		. 'This exception does not however invalidate any other reasons '
		. 'why the executable file might be covered '
		. 'by the GNU General Public License[.]',
};

=item * except_openssl

I<Since v3.4.0.>

=cut

$RE{except_openssl} = {
	name                  => 'OpenSSL-exception',
	'name.alt.org.debian' => 'OpenSSL',
	caption               => 'OpenSSL exception',
	tags                  => [
		'family:gnu',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'SSLeay licenses, (?:the (?:author|copyright holder|licensors|Free Software)|you are granted)',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'If you modify (?:the|this) program, or any covered work, '
		. 'by linking or combining it '
		. 'with the OpenSSL project[\']s ["]OpenSSL["] library '
		. '[(]or a modified version of that library[)], '
		. 'containing parts covered '
		. 'by the terms of the OpenSSL or SSLeay licenses, '
		. '(?:the authors of[ word]{1,8} grant you'
		. '|the (?:copyright holder|licensors|Free Software Foundation) grants? you'
		. '|you are granted) '
		. 'additional permission to convey the resulting work[. ]'
		. 'Corresponding Source for a non-source form '
		. 'of such a combination '
		. 'shall include the source code for the parts of OpenSSL used '
		. 'as well as that of the covered work[.]'
};

=item * except_ocaml-lgpl

=cut

$RE{except_ocaml_lgpl} = {
	name                  => 'OCaml-LGPL-linking-exception',
	'name.alt.org.debian' => 'OCaml-LGPL-linking',
	caption               => 'OCaml LGPL Linking Exception',
	tags                  => [
		'family:gnu:lgpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'you may link, statically or dynamically, '
		. 'a ["]work that uses the Library["] '
		. 'with a publicly distributed version of the Library '
		. 'to produce an executable file '
		. 'containing portions of the Library, '
		. 'and distribute that executable file '
		. 'under terms of your choice, '
		. 'without any of the additional requirements '
		. 'listed in clause 6 of the GNU Library General Public License[.]',
};

=item * except_openssl-lgpl

I<Since v3.4.0.>

=item * except_openssl_s3

I<Since v3.4.0.>

=cut

$RE{except_openssl_lgpl} = {
	name                  => 'OpenSSL~LGPL-exception',
	'name.alt.org.debian' => 'OpenSSL~LGPL',
	caption               => 'OpenSSL~LGPL exception',
	tags                  => [
		'family:gnu:lgpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'the copyright holders give permission '
		. 'to link the code of portions of this program '
		. 'with the OpenSSL library '
		. 'under certain conditions as described '
		. 'in each individual source file, '
		. 'and distribute linked combinations including the two[.][  ]'
		. 'You must obey the GNU Lesser General Public License '
		. 'in all respects '
		. 'for all of the code used other than OpenSSL[.]'
};

$RE{except_openssl_s3} = {
	name                  => 'OpenSSL~s3-exception',
	'name.alt.org.debian' => 'OpenSSL~s3',
	caption               => 'OpenSSL~s3 exception',
	tags                  => [
		'family:gnu',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'link the code of this library and its programs with the OpenSSL library',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'the copyright holders give permission '
		. 'to link the code of portions of this program '
		. 'with the OpenSSL project[\']s ["]OpenSSL["] library '
		. '[(]or with modified versions of it '
		. 'that use the same license as the ["]OpenSSL["] library'
		. '[ - ]see [http://]www.openssl.org/[)], '
		. 'and distribute linked combinations including the two[.]'
};

=item * except_prefix_agpl

I<Since v3.4.0.>

=item * except_prefix_generic

I<Since v3.4.0.>

=item * except_prefix_gpl

I<Since v3.4.0.>

=item * except_prefix_gpl_clisp

I<Since v3.4.0.>

=item * except_prefix_lgpl

I<Since v3.4.0.>

=cut

$RE{except_prefix_agpl} = {
	caption => 'AGPL exception prefix',
	tags    => [
		'family:gnu:agpl',
		'type:trait:exception:prefix',
	],

	'pat.alt.subject.trait.target.generic' =>
		'In addition to the permissions in the GNU General Public License, ',
	'pat.alt.subject.trait.target.agpl_3' => 'Additional permissions? under '
		. "$the?(?:GNU )?A(?:ffero )?GPL(?: version 3|v3) section 7"
};

$RE{except_prefix_generic} = {
	caption => 'generic exception prefix',
	tags    => [
		'type:trait:exception:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'(?:In addition, as a special exception, '
		. '|As a special exception, )',
	'pat.alt.subject.trait.scope.paragraph' =>
		'(?:In addition, as a special exception, '
		. '|(?:Exception [*)]FIXME[  ])?'
		. 'As a special exception, '
		. '|Grant of Additional Permission[. ])',
};

$RE{except_prefix_gpl} = {
	caption => 'GPL exception prefix',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception:prefix',
	],

	'pat.alt.subject.trait.target.generic' =>
		'In addition to the permissions in the GNU General Public License, ',
	'pat.alt.subject.trait.target.gpl_3' =>
		'(?:the file is governed by GPLv3 along with this Exception'
		. '|Additional permissions? under '
		. "$the?(?:GNU )?GPL(?: version 3|v3) section 7)"
};

$RE{except_prefix_gpl_clisp} = {
	caption => 'CLISP exception prefix',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' => 'Note[:"][  ]'
		. 'This copyright does NOT cover user programs '
		. 'that run in CLISP and third-party packages not part of CLISP, '
		. "if [*)]$clisp_they_only_ref_clisp, "
		. '[ie] if they don[\']t rely on CLISP internals '
		. 'and would as well run in any other Common Lisp implementation[. ]'
		. "Or [*)]$clisp_they_only_ref_clisp "
		. 'and some external, not CLISP specific, symbols '
		. 'in third[-]party packages '
		. 'that are released with source code under a GPL compatible license '
		. 'and that run in a great number of Common Lisp implementations, '
		. '[ie] if they rely on CLISP internals only to the extent needed '
		. 'for gaining some functionality also available '
		. 'in a great number of Common Lisp implementations[. ]'
		. 'Such user programs are not covered '
		. 'by the term ["]derived work["] used in the GNU GPL[. ]'
		. 'Neither is their compiled code, '
		. '[ie] the result of compiling them '
		. 'by use of the function COMPILE-FILE[. ]'
		. 'We refer to such user programs '
		. 'as ["]independent work["][.][  ]',
};

$RE{except_prefix_lgpl} = {
	caption => 'LGPL exception prefix',
	tags    => [
		'family:gnu:lgpl',
		'type:trait:exception:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'In addition to the permissions in '
		. 'the GNU (?:Lesser|Library) General Public License, '
};

=item * except_proguard

I<Since v3.4.0.>

=cut

$RE{except_proguard} = {
	name    => 'Proguard',
	caption => 'Proguard exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'this program with the following stand-alone applications',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'(?:Eric Lafortune|Guardsquare NV) gives permission '
		. 'to link the code of this program '
		. 'with the following stand[-]alone applications[:]?'
};

=item * except_qt_gpl_1

I<Since v3.4.0.>

=item * except_qt_gpl_eclipse

I<Since v3.4.0.>

=item * except_qt_gpl_openssl

I<Since v3.4.0.>

=cut

$RE{except_qt_gpl_1} = {
	name                  => 'Qt-GPL-exception-1.0',
	'name.alt.org.debian' => 'Qt-GPL-1.0',
	caption               => 'Qt GPL exception 1.0',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.part1' =>
		'you may create a larger work which contains '
		. 'the output of this application '
		. 'and distribute that work under terms of your choice, '
		. 'so long as the work is not otherwise derived from or based on this application '
		. 'and so long as the work does not in itself generate output '
		. 'that contains the output from this application in its original or modified form',
	'pat.alt.subject.trait.scope.paragraph.part.part2' =>
		'you have permission to combine this application with Plugins '
		. 'licensed under the terms of your choice, '
		. 'to produce an executable, and to copy and distribute the resulting executable '
		. 'under the terms of your choice[. ]'
		. 'However, the executable must be accompanied by a prominent notice '
		. 'offering all users of the executable the entire source code to this application, '
		. 'excluding the source code of the independent modules, '
		. 'but including any changes you have made to this application, '
		. 'under the terms of this license[.]',
};

$RE{except_qt_gpl_eclipse} = {
	name    => 'Qt-GPL-Eclipse',
	caption => 'Qt GPL Eclipse exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'Qt Designer, grants users of the Qt/Eclipse',
	'pat.alt.subject.trait.scope.paragraph.part.part1' =>
		'Trolltech, as the sole copyright holder for Qt Designer, '
		. 'grants users of the Qt[/]Eclipse Integration plug-in '
		. 'the right for the Qt[/]Eclipse Integration to link '
		. 'to functionality provided by Qt Designer '
		. 'and its related libraries[.][  ]'
};

$RE{except_qt_gpl_openssl} = {
	name    => 'Qt-GPL-OpenSSL',
	caption => 'Qt GPL OpenSSL exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'its release of Qt with the OpenSSL',
	'pat.alt.subject.trait.scope.paragraph.part.part1' =>
		'Nokia gives permission to link the code of its release of Qt '
		. 'with the OpenSSL project[\']s ["]OpenSSL["] library '
		. '[(]or modified versions of the ["]OpenSSL["] library '
		. 'that use the same license as the original version[)], '
		. 'and distribute the linked executables[.][  ]',
	'pat.alt.subject.trait.scope.paragraph.part.part2' =>
		' You must comply with the GNU General Public License version 2 '
		. 'in all respects for all of the code used '
		. 'other than the ["]OpenSSL["] code[. ]'
		. 'If you modify this file, '
		. 'you may extend this exception to your version of the file, '
		. 'but you are not obligated to do so[. ]'
		. 'If you do not wish to do so, '
		. 'delete this exception statement '
		. 'from your version of this file[.]'
};

=item * except_qt_kernel

I<Since v3.4.0.>

=cut

$RE{except_qt_kernel} = {
	name    => 'Qt-kernel',
	caption => 'Qt-kernel exception',
	tags    => [
		'family:gnu',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'Permission is also granted to link this program with the Qt library, '
		. 'treating Qt like a library that normally accompanies the operating system kernel, '
		. 'whether or not that is in fact the case',
};

=item * except_qt_lgpl_1_1

I<Since v3.4.0.>

=cut

$RE{except_qt_lgpl_1_1} = {
	name                  => 'Qt-LGPL-exception-1.1',
	'name.alt.org.debian' => 'Qt-LGPL-1.1',
	caption               => 'Qt LGPL exception 1.1',
	tags                  => [
		'family:gnu:lgpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.type.reference' =>
		'(?:Digia|Nokia|The Qt Company) gives you certain',
	'pat.alt.subject.trait.scope.sentence.type.reference' =>
		'(?:Digia|Nokia|The Qt Company) gives you certain additional rights[. ]'
		. 'These rights are described '
		. 'in The (?:Digia Qt|Nokia Qt|Qt Company) LGPL Exception version 1\.1, '
		. 'included in the file [word] in this package'
};

=item * except_qt_nosource

I<Since v3.4.0.>

=cut

$RE{except_qt_nosource} = {
	name    => 'Qt-no-source',
	caption => 'Qt-no-source exception',
	tags    => [
		'family:gnu',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'permission is given to link this program with any edition of Qt, '
		. 'and distribute the resulting executable, '
		. 'without including the source code for Qt in the source distribution',
};

=item * except_sdc

I<Since v3.4.0.>

=cut

$RE{except_sdc} = {
	name    => 'SDC',
	caption => 'SDC exception',
	tags    => [
		'family:gnu:lgpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you may create a larger work that contains '
		. 'code generated by the Shared Data Compiler',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'you may create a larger work that contains '
		. 'code generated by the Shared Data Compiler'
		. 'and distribute that work under terms of '
		. 'the GNU Lesser General Public License [(]LGPL[)]'
		. 'by the Free Software Foundation; '
		. 'either version 2\.1 of the License, '
		. 'or [(]at your option[)] any later version '
		. 'or under terms that are fully compatible with these licenses[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'Alternatively, if you modify or redistribute '
		. 'the Shared Data Compiler tool itself, '
		. 'you may [(]at your option[)] remove this special exception, '
		. 'which will cause the resulting generted source code files '
		. 'to be licensed under the GNU General Public License '
		. '[(]either version 2 of the License, '
		. 'or at your option under any later version[)] '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part3' =>
		'This special exception was added by Jaros[l-]aw Staniek[. ]'
		. 'Contact him for more licensing options, '
		. '[eg] using in non-Open Source projects[.]',
};

=item * except_sollya_4_1

I<Since v3.4.0.>

=cut

$RE{except_sollya_4_1} = {
	name                  => 'Sollya-exception-4.1',
	'name.alt.org.debian' => 'Sollya-4.1',
	caption               => 'Sollya exception 4.1',
	tags                  => [
		'family:cecill',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you may create a larger work that contains '
		. 'part or all of this software generated using Sollya',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'you may create a larger work that contains '
		. 'part or all of this software generated using Sollya'
		. 'and distribute that work under terms of your choice, '
		. 'so long as that work isn[\']t itself a numerical code generator '
		. 'using the skeleton of this code or a modified version thereof '
		. 'as a code skeleton[.]'
		. 'Alternatively, if you modify or redistribute this code itself, '
		. 'or its skeleton, '
		. 'you may [(]at your option[)] remove this special exception, '
		. 'which will cause this generated code and its skeleton '
		. 'and the resulting Sollya output files'
		. 'to be licensed under the CeCILL-C License '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'This special exception was added by the Sollya copyright holders '
		. 'in version 4\.1 of Sollya[.]'
};

=item * except_warzone

I<Since v3.4.0.>

=cut

$RE{except_warzone} = {
	name    => 'Warzone',
	caption => 'Warzone exception',
	tags    => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'the copyright holders of Warzone 2100 '
		. 'give you permission to combine',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'the copyright holders of Warzone 2100 '
		. 'give you permission to combine Warzone 2100 '
		. 'with code included in the standard release of libraries '
		. 'that are accessible, redistributable and linkable '
		. 'free of charge[. ]'
		. 'You may copy and distribute such a system '
		. 'following the terms of the GNU GPL '
		. 'for Warzone 2100 '
		. 'and the licenses of the other code concerned[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'Note that people who make modified versions of Warzone 2100 '
		. 'are not obligated to grant this special exception '
		. 'for their modified versions; '
		. 'it is their choice whether to do so[. ]'
		. 'The GNU General Public License gives permission '
		. 'to release a modified version without this exception; '
		. 'this exception also makes it possible '
		. 'to release a modified version '
		. 'which carries forward this exception[.]'
};

=item * except_wxwindows

I<Since v3.6.0.>

=cut

$RE{except_wxwindows} = {
	name                  => 'WxWindows-exception-3.1',
	'name.alt.org.debian' => 'WxWindows-3.1',
	'name.alt.org.osi'    => 'WXwindows',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'wxwindows',
	'name.alt.org.spdx.until.date_20150513'         => 'WXwindows',
	'name.alt.org.spdx.since.date_20150513' => 'WxWindows-exception-3.1',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q38347878',
	caption                         => 'WxWindows Library Exception 3.1',
	'caption.alt.org.osi'           => 'The wxWindows Library Licence',
	'caption.alt.org.osi.misc.list' => 'wxWindows Library License',
	'caption.alt.org.spdx.until.date_20150513' => 'wxWindows Library License',
	'caption.alt.org.spdx.since.date_20150513' =>
		'WxWindows Library Exception 3.1',
	'caption.alt.org.tldr'     => 'wxWindows Library License (WXwindows)',
	'caption.alt.org.wikidata' => 'wxWindows Library License',
	tags                       => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'the copyright holders of this library give permission '
		. 'for additional uses of the text '
		. 'contained in this release of the library '
		. 'as licenced under the wxWindows Library Licence',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'the copyright holders of this library give permission '
		. 'for additional uses of the text '
		. 'contained in this release of the library '
		. 'as licenced under the wxWindows Library Licence, '
		. 'applying either version 3\.1 of the Licence, '
		. 'or [(]at your option[)] any later version of the Licence '
		. 'as published by the copyright holders '
		. 'of version 3\.1 of the Licence document[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'[*)]The exception is that you may use, copy, link, modify and distribute '
		. 'under your own terms, '
		. 'binary object code versions of works based on the Library[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part3' =>
		'[*)]If you copy code from files '
		. 'distributed under the terms of the GNU General Public Licence '
		. 'or the GNU Library General Public Licence '
		. 'into a copy of this library, as this licence permits, '
		. 'the exception does not apply to the code that you add in this way[. ]'
		. 'To avoid misleading anyone as to the status of such modified files, '
		. 'you must delete this exception notice from such code '
		. 'and[/]or adjust the licensing conditions notice accordingly[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part4' =>
		'[*)]If you write modifications of your own for this library, '
		. 'it is your choice whether to permit this exception '
		. 'to apply to your modifications[. ]'
		. 'If you do not wish that, '
		. 'you must delete the exception notice from such code '
		. 'and[/]or adjust the licensing conditions notice accordingly[.]',
};

=item * except_xerces

I<Since v3.4.0.>

=cut

$RE{except_xerces} = {
	name                  => 'Xerces-exception',
	'name.alt.org.debian' => 'Xerces',
	caption               => 'Xerces exception',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'Code Synthesis Tools CC gives permission '
		. 'to link this program with the Xerces-C\+\+ library ',
	'pat.alt.subject.trait.scope.multisection.part.part1' =>
		'Code Synthesis Tools CC gives permission '
		. 'to link this program with the Xerces-C\+\+ library '
		. '[(]or with modified versions of Xerces-C\+\+ '
		. 'that use the same license as Xerces-C\+\+[)], '
		. 'and distribute linked combinations including the two[. ]'
		. 'You must obey the GNU General Public License version 2 '
		. 'in all respects '
		. 'for all of the code used other than Xerces-C\+\+[. ]'
		. 'If you modify this copy of the program, '
		. 'you may extend this exception '
		. 'to your version of the program, '
		. 'but you are not obligated to do so[. ]'
		. 'If you do not wish to do so, '
		. 'delete this exception statement from your version[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.part2' =>
		'Furthermore, Code Synthesis Tools CC makes a special exception '
		. 'for the Free[/]Libre and Open Source Software [(]FLOSS[)] '
		. 'which is described in the accompanying FLOSSE file[. ]'
};

=item * fsf_unlimited

=item * fsf_unlimited_retention

=cut

$RE{fsf_unlimited} = {
	tags => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $fsf_ul,
};

$RE{fsf_unlimited_retention} = {
	tags => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.sentence' => $fsf_ullr,
};

=item * generated

I<Since v3.4.0.>

=cut

$RE{generated} = {
	name    => 'generated',
	caption => 'generated file',
	tags    => [
		'type:trait:flaw',
	],

	'_pat.alt.subject.trait.scope.sentence' => [
		'this is (?:a )?generated (?:file|manifest)',
		'This file (?:has been|is|was) (?:[*]{1,3})?(?:auto(?:matically |[-])|tool[-])?generated(?:[*]{1,3})?',
		'All changes made in this file will be lost',
		'generated file(?:[.] |[ - ])do not (?:edit|modify)[!.]',
		'DO NOT (?:EDIT|MODIFY) THIS FILE',
		'generated by[ word](?: [(][word][ word]{0,2}[)])?[  ]'
			. '(?:Please )?DO NOT delete this file[!]',

# weak, but seems to catch no false positives at end of line
		'Generated by running[:]$',

# too weak: does not mention file explicitly, so may reflect only a subset
#		'Generated (?:automatically|by|from|data|with)',
#		'generated (?:by|from|using)(?: the)?[ word]{1,2}(?: compiler)?[. ]'
#			. '(please )?Do not (edit|modify)',
#		'Machine generated[. ](please )?Do not (edit|modify)',
#		'Do not (edit|modify)[. ]Generated (?:by|from|using)',
#		'(?:created with|trained by)[ word][. ](please )?Do not edit',
	],
	'_pat.alt.subject.trait.scope.sentence.target.autotools' => [
		'Makefile\.in generated by automake [#.]+ from Makefile\.am[.]',
		'generated automatically by aclocal [#.]+ -\*?- Autoconf',
		'Generated(?: from[ word])? by GNU Autoconf',
		'(?:Attempt to guess a canonical system name|Configuration validation subroutine script)[. ]'
			. 'Copyright[c] [#-,]+Free Software Foundation',
		'Calling this script install[-]sh is preferred over install[.]sh, to prevent',
		'depcomp - compile a program generating dependencies as side-effects[  ]'
			. 'scriptversion',
		'Common wrapper for a few potentially missing GNU programs[.][  ]'
			. 'scriptversion',
		'DO NOT EDIT[!] GENERATED AUTOMATICALLY[!][ ]'
			. 'Process this file with automake to produce Makefile\.in',
		'This file is maintained in Automake, ',
	],
};

=item * license_label

=item * license_label_spdx

I<Since v3.9.0.>

=item * license_label_trove

I<Since v3.1.100.>

=cut

$RE{license_label} = {
	caption => 'license grant "License:" phrase',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait' => '(?P<_license_label>[Ll]i[cz]en[scz]e) ?[:"]',
};

$RE{license_label_spdx} = {
	caption => 'license grant "SPDX-License-Identifier:" phrase',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait' =>
		'(?P<_license_label_spdx>SPDX[-]License[-]Identifier[:] )',
};

$RE{license_label_trove} = {
	caption => 'license grant "License:" phrase',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait' =>
		'(?P<_license_label_trove>License(?: ::)? OSI Approved(?: ::)? )',
};

=item * licensed_under

I<Since v3.1.92.>

=cut

$RE{licensed_under} = {
	caption => 'license grant "licensed under" phrase',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait' => '(?P<_licensed_under>'
		. '(?:(?:[Ll]icen[sc]ed(?: for use)?|available|[Dd]istribut(?:able|ed)|[Ff]or distribution|permitted|provided|[Pp]ublished|[Rr]eleased) under'
		. '|[Ll]icen[sc]ed using'
		. '|(?:in form of source code|may be copied|placed their code|to [Yy]ou) under'
		. '|(?:[Tt]his|[Mm]y) (?:software|file|work) is under' # vague preposition prepended by object
		. '|(?:are|is) release under' # vague preposition prepended by verb and vague object/action
		. '|which I release under'    # vague preposition prepended by actor and vague action
		. '|distribute(?: it)?(?: and[/]or modify)? it under' # vague preposition prepended by action and vague object
		. '|(?:according|[Ss]ubject) to|in accordance with'
		. '|[Ss]ubject to'
		. '|(?:[Cc]overed|governed) by)'
		. '(?: (?:either )?(?:the )?(?:conditions|terms(?: and conditions)?|provisions) (?:described in|of))?' # terms optionally appended
		. '|[Uu]nder (?:either )?(?:the )?(?:terms|(?:terms and )?conditions) (?:described in|of)(?: either)?' # vague preposition + terms
		. ')[:]? ',
};

=item * or_at_option

I<Since v3.1.92.>

=cut

$RE{or_at_option} = {
	caption => 'license grant "or at your option" phrase',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' =>
		'(?P<_or_at_option>(?:and|or)(?: ?[(]?at your (?:option|choice)[)]?)?)',
};

=item * usage_rfn

I<Since v3.2.0.>

=cut

$RE{usage_rfn} = {
	caption => 'license usage "with Reserved Font Name" phrase',
	tags    => [
		'type:trait:usage:rfn',
	],

	'pat.alt.subject.trait' => '(?P<_usage_rfn>with Reserved Font Name)',
};

=item * version

I<Since v3.1.92.>

=cut

$RE{version} = {
	tags => [
		'type:trait',
	],
};

=item * version_later

=item * version_later_paragraph

=item * version_later_postfix

=cut

$RE{version_later} = {
	caption => 'version "or later"',
	tags    => [
		'type:trait',
	],
};

$RE{version_later_paragraph} = {
	caption => 'version "or later" postfix (paragraphs)',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.paragraph' =>
		'(?P<_version_later_paragraph>Later versions are permitted)',
};

$RE{version_later_postfix} = {
	caption => 'version "or later" (postfix)',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' => '[(]?(?P<_version_later_postfix>'
		. $RE{or_at_option}{'pat.alt.subject.trait'}
		. '(?: any)? (?:later|above|newer)(?: version)?'
		. '|or any later at your option)[)]?',
};

$RE{version_later}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= '(?:,? )?(?P<version_later>'
	. $RE{version_later_postfix}{'pat.alt.subject.trait'} . ')';
$RE{version_later}{'pat.alt.subject.trait.scope.paragraph'}
	= '(?:[.]?[ ])?(?P<version_later>'
	. $RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'}
	. ')';
$RE{version_later}{'pat.alt.subject.trait'} = _join_pats(
	{ label => 'version_later', prefix => '(?:[.]?[ ]|,? )?' },
	$RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'},
	$RE{version_later_postfix}{'pat.alt.subject.trait'},
);

=item * version_number

=item * version_number_suffix

=cut

$RE{version_number} = {
	caption => 'version number',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' => '(?P<version_number>\d(?:\.\d+)*\b)',
};

$RE{version_number_suffix} = {
	caption => 'version "of the License" suffix',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' => ' ?(?:(?:of the )?Licen[cs]e)?',
};

=item * version_only

=cut

$RE{version_only} = {
	caption => 'version "only"',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' =>
		' ?(?P<_version_only>(?:only|[(]no other versions[)]))',
};

=item * version_prefix

=cut

$RE{version_prefix} = {
	caption => 'version prefix',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?:[-]|[;]? ?(?:(?:only |either )?)?|[ - ])?[(]?(?:[Vv]ersion [Vv]?|VERSION |rev(?:ision)? |[Vv]\.? ?)?',
	'pat.alt.subject.trait.scope.paragraph' =>
		'[:]?[ ][(]?(?:Version [Vv]?|VERSION )?',
	'pat.alt.subject.trait' =>
		'(?:[-]|[;](?: (?:either )?)?|[ - ]|[:]?[ ])?[(]?(?:[Vv]ersion [Vv]?|VERSION |[Vv]\.? ?)?',
};

=item * version_numberstring

I<Since v3.1.92.>

=cut

$RE{version_numberstring} = {
	caption => 'version numberstring',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		$RE{version_prefix}{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. $RE{version_number}{'pat.alt.subject.trait'}
		. $RE{version_number_suffix}{'pat.alt.subject.trait'},
	'pat.alt.subject.trait.scope.paragraph' =>
		$RE{version_prefix}{'pat.alt.subject.trait.scope.paragraph'}
		. $RE{version_number}{'pat.alt.subject.trait'}
		. $RE{version_number_suffix}{'pat.alt.subject.trait'},
	'pat.alt.subject.trait' => $RE{version_prefix}{'pat.alt.subject.trait'}
		. $RE{version_number}{'pat.alt.subject.trait'}
		. $RE{version_number_suffix}{'pat.alt.subject.trait'},
};

$RE{version}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= '(?P<_version>'
	. $RE{version_numberstring}
	{'pat.alt.subject.trait.scope.line.scope.sentence'} . '(?:'
	. $RE{version_later}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	. ')?)[)]?(?: of)? ?';
$RE{version}{'pat.alt.subject.trait.scope.paragraph'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait.scope.paragraph'}
	. '(?:'
	. $RE{version_later}{'pat.alt.subject.trait.scope.paragraph'}
	. ')?)[)]?';
$RE{version}{'pat.alt.subject.trait'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait'} . '(?:'
	. $RE{version_later}{'pat.alt.subject.trait'}
	. ')?)[)]?(?: of)? ?';

=back

=head2 Single licenses

Patterns each covering a single license.

Each of these patterns has exactly one of these tags:
B< type:unversioned >
B< type:versioned:decimal >
B< type:singleversion:* >
B< type:usage:*:* >
.

=over

=item * aal

=cut

$RE{aal} = {
	name                                                          => 'AAL',
	'name.alt.org.fedora'                                         => 'AAL',
	'name.alt.org.osi'                                            => 'AAL',
	'name.alt.org.osi.iri.stem.until.date_20110430.synth.nogrant' =>
		'attribution',
	'name.alt.org.spdx'                   => 'AAL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38364310',
	caption                               => 'Attribution Assurance License',
	'caption.alt.org.tldr'  => 'Attribution Assurance License (AAL)',
	'caption.alt.org.trove' => 'Attribution Assurance License',
	tags                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'must prominently display this GPG-signed text',
};

=item * abstyles

=cut

$RE{abstyles} = {
	name                                    => 'Abstyles',
	'name.alt.org.fedora.iri.self'          => 'Abstyles',
	'name.alt.org.spdx.since.date_20140807' => 'Abstyles',
	caption                                 => 'Abstyles License',
	'caption.alt.org.tldr'                  => 'Abstyles License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Permission is granted to copy and distribute '
		. 'modified versions of this document '
		. 'under the conditions for verbatim copying, '
		. 'provided that the entire resulting derived work '
		. 'is distributed under the terms of a permission notice '
		. 'identical to this one[.]',
};

=item * adobe_2006

=cut

$RE{adobe_2006} = {
	name                                    => 'Adobe-2006',
	'name.alt.misc.scancode'                => 'adobe-scl',
	'name.alt.org.fedora.synth.nogrant'     => 'Adobe',
	'name.alt.org.fedora.iri.self'          => 'AdobeLicense',
	'name.alt.org.spdx.since.date_20140807' => 'Adobe-2006',
	'name.alt.org.tldr'                     =>
		'adobe-systems-incorporated-source-code-license-agreement',
	caption => 'Adobe Systems Incorporated Source Code License Agreement',
	'caption.alt.org.fedora.misc.web.synth.nogrant' => 'Adobe License',
	tags                                            => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'You agree to indemnify, hold harmless and defend',
};

=item * adobe_glyph

=cut

$RE{adobe_glyph} = {
	name                                    => 'Adobe-Glyph',
	'name.alt.org.fedora.iri.mit_short'     => 'AdobeGlyph',
	'name.alt.org.spdx.since.date_20140807' => 'Adobe-Glyph',
	caption                                 => 'Adobe Glyph List License',
	'caption.alt.org.tldr'                  => 'Adobe Glyph List License',
	'summary.alt.org.fedora.iri.mit'        =>
		'MIT-style license, Adobe Glyph List Variant',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'and to permit others to do the same, provided that the derived work is not represented as being a copy',
};

=item * adsl

=cut

$RE{adsl} = {
	name                                    => 'ADSL',
	'name.alt.org.fedora'                   => 'ADSL',
	'name.alt.org.fedora.iri.self'          => 'AmazonDigitalServicesLicense',
	'name.alt.org.spdx.since.date_20140807' => 'ADSL',
	caption => 'Amazon Digital Services License',
	tags    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Your use of this software code is at your own risk '
		. 'and you waive any claim against Amazon Digital Services, Inc[.]',
};

=item * afl

=item * afl_1_1

I<Since v3.1.95.>

=item * afl_1_2

I<Since v3.1.95.>

=item * afl_2

I<Since v3.1.95.>

=item * afl_2_1

I<Since v3.1.95.>

=item * afl_3

I<Since v3.1.95.>

=cut

my $termination_for_patent_including_counterclaim
	= '[*)]Termination for Patent Action[. ]'
	. 'This License shall terminate automatically '
	. 'and You may no longer exercise any of the rights '
	. 'granted to You by this License '
	. 'as of the date You commence an action, '
	. 'including a cross-claim or counterclaim,';

$RE{afl} = {
	name                                            => 'AFL',
	'name.alt.org.osi.iri.stem.until.date_20021204' => 'academic',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q337279',
	caption                     => 'Academic Free License',
	'caption.alt.org.trove'     => 'Academic Free License (AFL)',
	'caption.alt.org.wikipedia' => 'Academic Free License',
	tags                        => [
		'type:versioned:decimal',
	],

# TODO: readd when children cover same region
#	'pat.alt.subject.license.scope.line.scope.paragraph' =>
#		'Exclusions [Ff]rom License Grant[. ]Neither',
};

$RE{afl_1_1} = {
	name                             => 'AFL-1.1',
	'name.alt.org.spdx'              => 'AFL-1.1',
	'name.alt.misc.fossology_old'    => 'AFL_v1.1',
	caption                          => 'Academic Free License v1.1',
	'caption.alt.misc.fossology_old' => 'AFL 1.1',
	tags                             => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' => 'The Academic Free License applies to',
};

$RE{afl_1_2} = {
	name                             => 'AFL-1.2',
	'name.alt.org.spdx'              => 'AFL-1.2',
	'name.alt.misc.fossology_old'    => 'AFL_v1.2',
	caption                          => 'Academic Free License v1.2',
	'caption.alt.misc.fossology_old' => 'AFL 1.2',
	tags                             => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license' => 'This Academic Free License applies to',
};

$RE{afl_2} = {
	name                             => 'AFL-2.0',
	'name.alt.org.spdx'              => 'AFL-2.0',
	'name.alt.misc.fossology_old'    => 'AFL_v2.0',
	caption                          => 'Academic Free License v2.0',
	'caption.alt.misc.fossology_old' => 'AFL 2.0',
	tags                             => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection' =>
		'its terms and conditions[.][  ]'
		. $termination_for_patent_including_counterclaim
		. ' for patent infringement',
};

$RE{afl_2_1} = {
	name                              => 'AFL-2.1',
	'name.alt.org.spdx'               => 'AFL-2.1',
	'name.alt.org.tldr.synth.nogrant' => 'academic-free-license-v.-2.1',
	'name.alt.misc.fossology_old'     => 'AFL_v2.1',
	caption                           => 'Academic Free License v2.1',
	'caption.alt.misc.fossology_old'  => 'AFL 2.1',
	'caption.alt.org.tldr' => 'Academic Free License 2.1 (AFL-2.1)',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection' =>
		'its terms and conditions[.][  ]'
		. $termination_for_patent_including_counterclaim
		. ' against Licensor or any licensee',
};

$RE{afl_3} = {
	name                                            => 'AFL-3.0',
	'name.alt.org.fedora.synth.nogrant'             => 'AFL',
	'name.alt.org.osi'                              => 'AFL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'afl-3.0',
	'name.alt.org.spdx'                             => 'AFL-3.0',
	'name.alt.org.tldr.path.short'                  => 'afl3',
	'name.alt.misc.fossology_old'                   => 'AFL_v3.0',
	caption                                => 'Academic Free License v3.0',
	'caption.alt.org.fedora.synth.nogrant' => 'Academic Free License',
	'caption.alt.org.fsf'                  => 'Academic Free License 3.0',
	'caption.alt.org.osi'           => 'Academic Free License ("AFL") v. 3.0',
	'caption.alt.org.osi.misc.list' => 'Academic Free License 3.0',
	'caption.alt.org.tldr'          => 'Academic Free License 3.0 (AFL)',
	'caption.alt.misc.fossology_old' => 'AFL 3.0',
	tags                             => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Academic Free License version 3\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
};

=item * afmparse

=cut

$RE{afmparse} = {
	name                                    => 'Afmparse',
	'name.alt.org.fedora.iri.self'          => 'Afmparse',
	'name.alt.org.spdx.since.date_20140807' => 'Afmparse',
	caption                                 => 'Afmparse License',
	'caption.alt.org.tldr'                  => 'Afmparse License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'If the file has been modified in any way, '
		. 'a notice of such modification is conspicuously indicated[.]',
};

=item * agpl

=item * agpl_1

I<Since v3.1.102.>

=item * agpl_1_only

=item * agpl_1_or_later

=item * agpl_2

=item * agpl_3

=item * agpl_3_only

=item * agpl_3_or_later

=cut

$RE{agpl} = {
	name                                  => 'AGPL',
	'name.alt.org.fsf'                    => 'AGPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1131681',
	'name.alt.misc.fossology_old'         => 'Affero',
	caption                     => 'GNU Affero General Public License',
	'caption.alt.misc.short'    => 'Affero GPL',
	'caption.alt.misc.informal' => 'Affero License',
	'caption.alt.org.fsf'       => 'GNU Affero General Public License (AGPL)',
	'caption.alt.org.wikipedia' => 'GNU Affero General Public License',
	tags                        => [
		'family:gpl',
		'license:contains:grant',
		'type:versioned:decimal',
	],
};

$RE{agpl_1} = {
	name                                    => 'AGPLv1',
	'name.alt.org.debian'                   => 'AGPL-1',
	'name.alt.org.fedora'                   => 'AGPLv1',
	'name.alt.org.spdx.since.date_20130410' => 'AGPL-1.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27017230',
	'name.alt.misc.fossology_old'           => 'Affero_v1',
	caption                  => 'Affero General Public License v1.0',
	'caption.alt.org.fedora' => 'Affero General Public License 1.0',
	'caption.alt.org.spdx.until.date_20140807' =>
		'GNU Affero General Public License v1.0',
	'caption.alt.org.spdx.since.date_20140807' =>
		'Affero General Public License v1.0',
	'caption.alt.misc.fossology_old' => 'AGPL 1.0',
	'caption.alt.org.wikidata'       =>
		'Affero General Public License, version 1.0',
	iri  => 'http://www.affero.org/oagpl.html',
	tags => [
		'family:gpl',
		'type:singleversion:agpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.title' =>
		'AFFERO GENERAL PUBLIC LICENSE[ ]Version 1',
	'pat.alt.subject.license.part.intro' =>
		'This license is a modified version of the GNU General Public License',
	'pat.alt.subject.license.scope.sentence.part.preamble' =>
		'Some other Affero software is covered '
		. 'by the GNU Library General Public License instead[.]',
	'pat.alt.subject.license.part.part2_d' =>
		'[*)]If the Program as you received it is intended to interact',
};

$RE{agpl_1_only} = {
	name    => 'AGPL-1.0-only',
	caption => 'Affero General Public License v1.0 only',
	tags    => [
		'family:gpl',
		'type:usage:agpl_1:only'
	],
};

$RE{agpl_1_or_later} = {
	name                                    => 'AGPL-1.0-or-later',
	'name.alt.org.debian'                   => 'AGPL-1+',
	'name.alt.org.spdx.since.date_20180414' => 'AGPL-1-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q54571707',
	caption => 'Affero General Public License v1.0 or later',
	'caption.alt.org.wikidata' =>
		'Affero General Public License, version 1.0 or later',
	tags => [
		'family:gpl',
		'type:usage:agpl_1:or_later'
	],
};

$RE{agpl_2} = {
	name                                  => 'AGPLv2',
	'name.alt.org.debian'                 => 'AGPL-2',
	'name.alt.org.wikidata.synth.nogrant' => 'Q54365943',
	caption                    => 'Affero General Public License, Version 2',
	'caption.alt.org.wikidata' =>
		'Affero General Public License, version 2.0',
	iri  => 'http://www.affero.org/agpl2.html',
	tags => [
		'family:gpl',
		'type:singleversion:agpl'
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.part1' =>
		'This is version 2 of the Affero General Public License[.]',
	'pat.alt.subject.license.part.part2' =>
		'If the Program was licensed under version 1 of the Affero GPL',
};

$RE{agpl_3} = {
	name                                            => 'AGPLv3',
	'name.alt.org.debian'                           => 'AGPL-3',
	'name.alt.org.fsf'                              => 'AGPLv3.0',
	'name.alt.org.fedora'                           => 'AGPLv3',
	'name.alt.org.osi'                              => 'AGPL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'agpl-v3',
	'name.alt.org.perl'                             => 'agpl_3',
	'name.alt.org.spdx.until.date_20171228'         => 'AGPL-3.0',
	'name.alt.org.tldr.path.short'                  => 'agpl3',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q27017232',
	'name.alt.misc.fossology_old'                   => 'Affero_v3',
	caption                  => 'GNU Affero General Public License v3.0',
	'caption.alt.org.fedora' => 'Affero General Public License 3.0',
	'caption.alt.org.fsf'    =>
		'GNU Affero General Public License (AGPL) version 3',
	'caption.alt.org.osi'   => 'GNU Affero General Public License version 3',
	'caption.alt.org.perl'  => 'GNU Affero General Public License, Version 3',
	'caption.alt.org.trove' => 'GNU Affero General Public License v3',
	'caption.alt.org.tldr'  =>
		'GNU Affero General Public License v3 (AGPL-3.0)',
	'caption.alt.org.wikidata' =>
		'GNU Affero General Public License, version 3.0',
	'caption.alt.misc.fossology_old' => 'AGPL 3.0',
	iri                              => 'https://www.gnu.org/licenses/agpl',
	'iri.alt.format.txt'      => 'https://www.gnu.org/licenses/agpl.txt',
	'iri.alt.path.fragmented' =>
		'https://www.gnu.org/licenses/licenses.html#AGPL',
	'iri.alt.path.versioned' => 'http://www.gnu.org/licenses/agpl-3.0.html',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:agpl'
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.title' =>
		'GNU AFFERO GENERAL PUBLIC LICENSE[ ]Version 3',
	'pat.alt.subject.license.part.intro' =>
		'["]This License["] refers to version 3 of the GNU Affero',
	'pat.alt.subject.license.scope.sentence.part.part13_1' =>
		'This Corresponding Source shall include '
		. 'the Corresponding Source for any work '
		. 'covered by '
		. 'version 3 of the GNU General Public License',
	'pat.alt.subject.license.scope.sentence.part.part13_2_1' =>
		'Notwithstanding any other provision of this License, '
		. 'you have permission to link or combine any covered work '
		. 'with a work licensed under '
		. 'version 3 of the GNU General',
	'pat.alt.subject.license.scope.sentence.part.part13_2_2' =>
		'The terms of this License will continue to apply '
		. 'to the part which is the covered work, '
		. 'but the work with which it is combined '
		. 'will remain governed by '
		. 'version 3 of the GNU General',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This program is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU Affero General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 3 of the License, or',
};

#FIXME $RE{agpl_3}{_pat_word} = '(?:AGPL|agpl)[-]?3';

$RE{agpl_3_only} = {
	name                                    => 'AGPL-3.0-only',
	'name.alt.org.spdx.since.date_20171228' => 'AGPL-3.0-only',
	caption => 'GNU Affero General Public License v3.0 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:agpl_3:only',
	],
};

$RE{agpl_3_or_later} = {
	name                                    => 'AGPL-3.0-or-later',
	'name.alt.org.debian'                   => 'AGPL-3+',
	'name.alt.org.fedora'                   => 'AGPLv3+',
	'name.alt.org.spdx.since.date_20171228' => 'AGPL-3.0-or-later',
	'name.alt.org.trove'                    => 'AGPLv3+',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27020062',
	'name.alt.misc.fossology_old'           => 'Affero_v3+',
	caption => 'GNU Affero General Public License v3.0 or later',
	'caption.alt.org.fedora' => 'Affero General Public License 3.0 or later',
	'caption.alt.org.trove'  =>
		'GNU Affero General Public License v3 or later (AGPLv3+)',
	'caption.alt.org.wikidata' =>
		'GNU Affero General Public License, version 3.0 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:agpl_3:or_later',
	],
};

=item * aladdin

=item * aladdin_8

I<Since v3.1.91.>

=item * aladdin_9

I<Since v3.1.91.>

=cut

$RE{aladdin} = {
	name                                  => 'Aladdin',
	'name.alt.org.trove'                  => 'AFPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q979794',
	caption                               => 'Aladdin Free Public License',
	'caption.alt.org.fedora'              => 'Aladdin Free Public License',
	'caption.alt.org.trove' => 'Aladdin Free Public License (AFPL)',
	tags                    => [
		'type:versioned:decimal',
	],
};

$RE{aladdin_8} = {
	name                                                  => 'Aladdin-8',
	'name.alt.org.scancode'                               => 'afpl-8',
	'name.alt.org.spdx.since.date_20130117.synth.nogrant' => 'Aladdin',
	'name.alt.org.debian'                                 => 'Aladdin-8',
	caption => 'Aladdin Free Public License, Version 8',
	'caption.alt.org.spdx.synth.nogrant' => 'Aladdin Free Public License',
	tags                                 => [
		'type:singleversion:aladdin',
	],
	licenseversion => '8.0',

	'pat.alt.subject.license.scope.multisection' =>
		'laws of the appropriate country[.][  ]0[. ]Subject Matter',
};

$RE{aladdin_9} = {
	name                           => 'Aladdin-9',
	'name.alt.org.scancode'        => 'afpl-9',
	'name.alt.org.tldr.path.short' => 'aladdin',
	caption                => 'Aladdin Free Public License, Version 9',
	'caption.alt.org.tldr' => 'Aladdin Free Public License',
	'iri.alt.archive.time_20130804020135' =>
		'http://www.artifex.com/downloads/doc/Public.htm',
	tags => [
		'type:singleversion:aladdin',
	],
	licenseversion => '9.0',

	'pat.alt.subject.license' =>
		'This License is not an Open Source license[:][ ]among other things',
};

=item * amdplpa

=cut

$RE{amdplpa} = {
	name                                    => 'AMDPLPA',
	'name.alt.org.fedora'                   => 'AMDPLPA',
	'name.alt.org.spdx.since.date_20140807' => 'AMDPLPA',
	caption                                 => 'AMD\'s plpa_map.c License',
	'caption.alt.org.fedora.iri.self'       => 'AMD plpa map License',
	'caption.alt.org.spdx.since.date_20140807.until.date_20201125' =>
		'AMD\'s plpa_map.c License',
	'caption.alt.org.spdx.since.date_20201125.until.date_20210307' =>
		'AMDs plpa_map.c License',
	'caption.alt.org.spdx.since.date_20210307' => 'AMD\'s plpa_map.c License',
	tags                                       => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Neither the names nor trademarks of Advanced Micro Devices, Inc\.',
};

=item * aml

=cut

$RE{aml} = {
	name                                    => 'AML',
	'name.alt.org.fedora'                   => 'AML',
	'name.alt.org.spdx.since.date_20140807' => 'AML',
	caption                                 => 'Apple MIT License',
	'caption.alt.org.fedora.iri.self'       => 'Apple MIT License',
	'caption.alt.org.tldr'                  => 'Apple MIT License (AML)',
	tags                                    => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Apple grants you a personal, non-exclusive license',
};

=item * ampas

=cut

$RE{ampas} = {
	name                                    => 'AMPAS',
	'name.alt.org.fedora.iri.bsd'           => 'AMPASBSD',
	'name.alt.org.spdx.since.date_20140807' => 'AMPAS',
	caption => 'Academy of Motion Picture Arts and Sciences BSD',
	'caption.alt.org.fedora.misc.short' => 'AMPAS BSD',
	'caption.alt.org.tldr'              =>
		'Academy of Motion Picture Arts and Sciences BSD',
	'summary.alt.org.fedora' =>
		'Academy of Motion Picture Arts and Sciences BSD Variant',
	tags => [
		'family:bsd',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl_warr}
		. '[.][  ]'
		. $P{repro_copr_cond_discl_warr}
		. '[.][  ]'
		. $P{nopromo_nothing_deemed},
};

=item * antlr_pd

=cut

$RE{antlr_pd} = {
	name                           => 'ANTLR-PD',
	'name.alt.org.fedora.iri.self' => 'ANTLR-PD',
	'name.alt.org.spdx'            => 'ANTLR-PD',
	caption                        => 'ANTLR Software Rights Notice',
	'caption.alt.org.tldr' => 'ANTLR Software Rights Notice (ANTLR-PD)',
	tags                   => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'We reserve no legal rights to the ANTLR[--]?it is fully in the public domain[.]',
};

=item * apache

=item * apache_1

I<Since v3.1.95.>

=item * apache_1_1

I<Since v3.1.95.>

=item * apache_2

I<Since v3.1.95.>

=cut

$RE{apache} = {
	name                                                 => 'Apache',
	'name.alt.org.osi.iri.stem_only.until.date_20080202' => 'apachepl',
	'name.alt.org.wikidata.synth.nogrant'                => 'Q616526',
	caption                                              => 'Apache License',
	'caption.alt.org.trove'     => 'Apache Software License',
	'caption.alt.org.wikipedia' => 'Apache License',
	'caption.alt.misc.public'   => 'Apache Public License',
	iri  => 'https://www.apache.org/licenses/LICENSE-2.0',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{apache_1} = {
	name                                  => 'Apache-1.0',
	'name.alt.org.fedora'                 => 'Apache-1.0',
	'name.alt.org.spdx'                   => 'Apache-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q26897902',
	'name.alt.misc.fossology_old'         => 'Apache_v1.0',
	caption                               => 'Apache License 1.0',
	'caption.alt.org.fedora'              => 'Apache Software License 1.0',
	'caption.alt.org.fedora.misc.short'   => 'ASL 1.0',
	'caption.alt.org.tldr'     => 'Apache License 1.0 (Apache-1.0)',
	'caption.alt.org.wikidata' => 'Apache Software License, Version 1.0',
	description                => <<'END',
Identical to BSD (4 clause), except...
* extend advertising clause to also require advertising purpose
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause
* add redistribution-acknowledgement clause
END
	iri  => 'https://www.apache.org/licenses/LICENSE-1.0',
	tags => [
		'license:contains:license:bsd_4_clause',
		'license:is:grant',
		'type:singleversion:apache',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' => $P{redist_ack_this},
	'pat.alt.subject.license.scope.multisection.part.head' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]?'
		. $P{ad_mat_ack_this}
		. '[word][ word]{0,14}'
		. '[.][  ][*)]?'
		. $P{nopromo_neither}
		. '[. ]For written permission, please contact [word]'
		. '[.][  ]' . '[*)]?'
		. 'Products derived from this software may not be called'
};

$RE{apache_1_1} = {
	name                                            => 'Apache-1.1',
	'name.alt.org.osi'                              => 'Apache-1.1',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'apachepl-1.1',
	'name.alt.org.perl'                             => 'apache_1_1',
	'name.alt.org.spdx'                             => 'Apache-1.1',
	'name.alt.org.tldr'                             => 'apache-license-1.1',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q17817999',
	'name.alt.misc.fossology_old'                   => 'Apache_v1.1',
	caption                                         => 'Apache License 1.1',
	'caption.alt.org.fedora'            => 'Apache Software License 1.1',
	'caption.alt.org.fedora.misc.short' => 'ASL 1.1',
	'caption.alt.org.osi'           => 'Apache Software License, version 1.1',
	'caption.alt.org.osi.misc.list' => 'Apache Software License 1.1',
	'caption.alt.org.perl'          => 'Apache Software License, Version 1.1',
	'caption.alt.org.tldr'          => 'Apache License 1.1 (Apache-1.1)',
	'caption.alt.org.wikidata'      => 'Apache Software License, Version 1.1',
	'caption.alt.misc.fossology_old' => 'Apache 1.1',
	'caption.alt.misc.software'      => 'Apache Software License 1.1',
	description                      => <<'END',
Identical to BSD (3 clause), except...
* add documentation-acknowledgement clause (as 3rd clause similar to BSD-4-clause advertising clause)
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause
END
	iri                     => 'https://www.apache.org/licenses/LICENSE-1.1',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Apache_License#Version_1.1',
	tags => [
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'license:published:by_apache',
		'type:singleversion:apache',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection' =>
		'without prior written permission of[ word]{1,5}[.][  ]'
		. 'THIS SOFTWARE IS PROVIDED',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Apache License 1\.1[  ]'
		. 'Copyright[c] 2000 The Apache Software Foundation[.]'
		. ' All rights reserved[.][  ])?'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. '[*)]?The end-user documentation included',
};

$RE{apache_2} = {
	name                                            => 'Apache-2.0',
	'name.alt.org.osi'                              => 'Apache-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'apache2.0',
	'name.alt.org.perl'                             => 'apache_2_0',
	'name.alt.org.spdx'                             => 'Apache-2.0',
	'name.alt.org.tldr.path.short'                  => 'apache2',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q13785927',
	'name.alt.misc.fossology_old'                   => 'Apache_v2.0',
	'name.alt.misc.fossology_old_short'             => 'Apache2.0',
	caption                                         => 'Apache License 2.0',
	'caption.alt.org.fedora'            => 'Apache Software License 2.0',
	'caption.alt.org.fedora.misc.short' => 'ASL 2.0',
	'caption.alt.org.osi'               => 'Apache License, Version 2.0',
	'caption.alt.org.osi.misc.list'     => 'Apache License 2.0',
	'caption.alt.org.perl'              => 'Apache License, Version 2.0',
	'caption.alt.org.tldr'              => 'Apache License 2.0 (Apache-2.0)',
	'caption.alt.org.wikidata'  => 'Apache Software License, Version 2.0',
	'caption.alt.misc.public'   => 'Apache Public License 2.0',
	'caption.alt.misc.software' => 'Apache Software License 2.0',
	iri                     => 'https://www.apache.org/licenses/LICENSE-2.0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Apache_License#Version_2.0',
	tags => [
		'license:contains:grant',
		'license:published:by_apache',
		'type:singleversion:apache',
	],
	licenseversion => '2.0',

	'pat.alt.subject.grant.misc.extra' =>
		'Apache Software License, Version 2\.0',
	'pat.alt.subject.license.part.appendix' =>
		'How to apply the Apache License to your work',
	'pat.alt.subject.license.scope.multisection' => 'Apache License[ ]'
		. 'Version 2\.0, January 2004[ ]',
};

=item * apafml

=cut

$RE{apafml} = {
	name                                    => 'APAFML',
	'name.alt.org.fedora'                   => 'APAFML',
	'name.alt.org.fedora.iri.self'          => 'AdobePostscriptAFM',
	'name.alt.org.spdx.since.date_20140807' => 'APAFML',
	'name.alt.misc.fossology'               => 'AdobeAFM',
	'name.alt.misc.fossology_old'           => 'Adobe-AFM',
	caption                                 => 'Adobe Postscript AFM License',
	'caption.alt.org.tldr'                  => 'Adobe Postscript AFM License',
	tags                                    => [
		'type:unversioned',
	],

	'_pat.alt.subject.license' => [
		'AFM files it accompanies may be used',
		'that the AFM files are not distributed',
	],
};

=item * apl

=item * apl_1

=cut

$RE{apl} = {
	name                                  => 'APL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q4680711',
	'name.alt.misc.fossology_old'         => 'Adaptive',
	caption                               => 'Adaptive Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{apl_1} = {
	name                                            => 'APL-1.0',
	'name.alt.org.osi'                              => 'APL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'apl-1.0',
	'name.alt.org.spdx'                             => 'APL-1.0',
	caption => 'Adaptive Public License 1.0',
	'caption.alt.org.osi.misc.list.synth.nogrant' =>
		'Adaptive Public License',
	'caption.alt.org.tldr' => 'Adaptive Public License 1.0 (APL-1.0)',
	'caption.alt.misc.fossology_old' => 'Adaptive v1.0',
	tags                             => [
		'type:singleversion:apl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'THE LICENSED WORK IS PROVIDED UNDER THE TERMS OF THIS ADAPTIVE PUBLIC LICENSE',
};

=item * apsl

=item * apsl_1

=item * apsl_1_1

=item * apsl_1_2

=item * apsl_2

=cut

$RE{apsl} = {
	name                                  => 'APSL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q621330',
	caption                               => 'Apple Public Source License',
	'caption.alt.org.trove'               => 'Apple Public Source License',
	'caption.alt.org.wikipedia'           => 'Apple Public Source License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{apsl_1} = {
	name                                              => 'APSL-1.0',
	'name.alt.org.spdx'                               => 'APSL-1.0',
	'name.alt.misc.fossology_old'                     => 'APSL_v1.0',
	'name.alt.misc.fossology_old_short'               => 'APSL1.0',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'Apple',
	caption                           => 'Apple Public Source License 1.0',
	'caption.alt.org.fedora.iri.self' => 'Apple Public Source License 1.0',
	tags                              => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 1\.0(?:[ - ]March 16, ?1999)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.part1' =>
		'subject to the terms of this Apple Public Source License version 1\.0 ',
};

$RE{apsl_1_1} = {
	name                                => 'APSL-1.1',
	'name.alt.org.spdx'                 => 'APSL-1.1',
	'name.alt.misc.fossology_old'       => 'APSL_v1.',
	'name.alt.misc.fossology_old_short' => 'APSL1.1',
	caption                             => 'Apple Public Source License 1.1',
	'caption.alt.org.fedora.iri.self'   => 'Apple Public Source License 1.1',
	tags                                => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 1\.1(?:[ - ]April 19, ?1999)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.part1' =>
		'subject to the terms of this Apple Public Source License version 1\.1 ',
};

$RE{apsl_1_2} = {
	name                                => 'APSL-1.2',
	'name.alt.org.spdx'                 => 'APSL-1.2',
	'name.alt.misc.fossology_old'       => 'APSL_v1.2',
	'name.alt.misc.fossology_old_short' => 'APSL1.2',
	caption                             => 'Apple Public Source License 1.2',
	'caption.alt.org.fedora.iri.self'   => 'Apple Public Source License 1.2',
	tags                                => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. ' Ver(?:sion|\.) 1\.2(?:[ - ]January 4, ?2001)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.part1' =>
		'subject to the terms of this Apple Public Source License version 1\.2 ',
};

$RE{apsl_2} = {
	name                                            => 'APSL-2.0',
	'name.alt.org.osi'                              => 'APSL-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'apsl-2.0',
	'name.alt.org.spdx'                             => 'APSL-2.0',
	'name.alt.org.tldr.path.short.synth.nogrant'    => 'aspl2',
	'name.alt.misc.fossology_old'                   => 'APSL_v2.0',
	caption                             => 'Apple Public Source License 2.0',
	'caption.alt.org.fedora'            => 'Apple Public Source License 2.0',
	'caption.alt.org.fedora.misc.short' => 'APSL 2.0',
	'caption.alt.org.tldr' => 'Apple Public Source License 2.0 (APSL)',
	'caption.alt.org.osi.misc.cat_list.synth.nogrant' =>
		'Apple Public Source License',
	tags => [
		'type:singleversion:apsl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 2\.0(?:[ - ]August 6, ?2003)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.part1' =>
		'subject to the terms of this Apple Public Source License version 2\.0 ',
};

=item * artistic

=item * artistic_1

I<Since v3.1.95.>

=item * artistic_1_cl8

I<Since v3.1.95.>

=item * artistic_1_perl

I<Since v3.1.95.>

=item * artistic_2

=cut

$RE{artistic} = {
	name                                            => 'Artistic',
	'name.alt.org.osi.iri.stem.until.date_20080202' => 'artistic-license',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q713244',
	caption                                         => 'Artistic License',
	'caption.alt.org.trove'                         => 'Artistic License',
	'caption.alt.org.wikipedia'                     => 'Artistic License',
	tags                                            => [
		'type:versioned:complex',
	],
};

$RE{artistic_1} = {
	name                                            => 'Artistic-1.0',
	'name.alt.org.osi'                              => 'Artistic-1.0',
	'name.alt.org.osi.iri.stem.until.date_20090218' => 'artistic-license-1.0',
	'name.alt.org.spdx'                             => 'Artistic-1.0',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q14624823',
	'name.alt.misc.fossology_old'                   => 'Artistic1.0',
	caption                                         => 'Artistic License 1.0',
	'caption.alt.org.osi.misc.list'                 => 'Artistic license 1.0',
	'caption.alt.org.osi.misc.do_not_use_list'      =>
		'Artistic license, version 1.0',
	'caption.alt.org.wikipedia' => 'Artistic License 1.0',
	'iri.alt.old.osi'           =>
		'https://opensource.org/licenses/artistic-license-1.0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Artistic_License#Artistic_License_1.0',
	tags => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection' =>
		'[*)]C or perl subroutines supplied by you and linked into this Package shall not be considered part of this Package[.][  ]'
		. '[*)]The name of the Copyright Holder',
};

$RE{artistic_1_cl8} = {
	name                                    => 'Artistic-1.0-cl8',
	'name.alt.org.spdx.since.date_20130912' => 'Artistic-1.0-cl8',
	summary                              => 'Artistic License 1.0 w/clause 8',
	'caption.alt.org.tldr.synth.nogrant' => 'Artistic License 1.0',
	tags                                 => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0-cl8',

	'pat.alt.subject.license.scope.multisection' => 'this Package[.][  ]'
		. '[*)]Aggregation of this Package',
};

$RE{artistic_1_clarified} = {
	name                                => 'Artistic-1.0-clarified',
	'name.alt.org.fedora.iri.self'      => 'ArtisticClarified',
	'name.alt.org.spdx'                 => 'ClArtistic',
	caption                             => 'Clarified Artistic License',
	'caption.alt.org.fedora'            => 'Artistic (clarified)',
	'caption.alt.org.fedora.misc.short' => 'Artistic clarified',
	'caption.alt.org.spdx'              => 'Clarified Artistic License',
	'caption.alt.org.tldr'              => 'Clarified Artistic License',
	iri                                 =>
		'http://gianluca.dellavedova.org/2011/01/03/clarified-artistic-license/',
	tags => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0-clarified',

	'pat.alt.subject.license' =>
		'Aggregation of the Standard Version of the Package',
};

$RE{artistic_1_perl} = {
	name                                    => 'Artistic-1.0-Perl',
	'name.alt.org.perl.synth.nogrant'       => 'artistic_1',
	'name.alt.org.osi'                      => 'Artistic-1.0-Perl',
	'name.alt.org.spdx.since.date_20130912' => 'Artistic-1.0-Perl',
	caption                                 => 'Artistic License 1.0 (Perl)',
	'caption.alt.org.fedora'                => 'Artistic 1.0 (original)',
	'caption.alt.org.osi'                   => 'Artistic License 1.0 (Perl)',
	'caption.alt.org.perl.synth.nogrant' => 'Artistic License, (Version 1)',
	'caption.alt.org.spdx'               => 'Artistic License 1.0 (Perl)',
	iri                => 'http://dev.perl.org/licenses/artistic.html',
	'iri.alt.old.perl' =>
		'http://www.perl.com/pub/a/language/misc/Artistic.html',
	tags => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0-Perl',

	'pat.alt.subject.license.scope.multisection' => 'the language[.][  ]'
		. '[*)]Aggregation of this Package',
};

$RE{artistic_2} = {
	name                                            => 'Artistic-2.0',
	'name.alt.org.osi'                              => 'Artistic-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'artistic-license-2.0',
	'name.alt.org.perl'                             => 'artistic_2',
	'name.alt.org.spdx'                             => 'Artistic-2.0',
	'name.alt.org.tldr' => 'artistic-license-2.0-(artistic)',
	'name.alt.org.tldr.path.short.synth.nogrant' => 'artistic',
	'name.alt.org.wikidata.synth.nogrant'        => 'Q14624826',
	'name.alt.misc.fossology_old'                => 'Artistic_v2.0',
	'name.alt.misc.fossology_old_short'          => 'Artistic2.0',
	caption                                      => 'Artistic License 2.0',
	'caption.alt.org.fedora'                     => 'Artistic 2.0',
	'caption.alt.org.osi.misc.cat_list'          => 'Artistic license 2.0',
	'caption.alt.org.perl'      => 'Artistic License, Version 2.0',
	'caption.alt.org.tldr'      => 'Artistic License 2.0 (Artistic-2.0)',
	'caption.alt.org.wikipedia' => 'Artistic License 2.0',
	iri => 'http://www.perlfoundation.org/artistic_license_2_0',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Artistic_License#Artistic_License_2.0',
	tags => [
		'type:singleversion:artistic',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license' => 'is governed by this Artistic License[.]',
};

=item * bahyph

=cut

$RE{bahyph} = {
	name                                    => 'Bahyph',
	'name.alt.org.fedora.iri.self'          => 'Bahyph',
	'name.alt.org.spdx.since.date_20140807' => 'Bahyph',
	caption                                 => 'Bahyph License',
	'caption.alt.org.tldr'                  => 'Bahyph License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'These patterns were developed for internal GMV use and are made public',
};

=item * barr

=cut

$RE{barr} = {
	name                                    => 'Barr',
	'name.alt.org.fedora.iri.self'          => 'Barr',
	'name.alt.org.spdx.since.date_20140807' => 'Barr',
	caption                                 => 'Barr License',
	'caption.alt.org.tldr'                  => 'Barr License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'This is a package of commutative diagram macros built on top of Xy[-]pic',
};

=item * bdwgc

I<Since v3.1.0.>

=cut

$RE{bdwgc} = {
	'name.alt.org.debian'            => 'MIT~Boehm',
	caption                          => 'Boehm GC License',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, Another Minimal variant (found in libatomic_ops)',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	iri  => 'http://www.hboehm.info/gc/license.txt',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{to_copy_prg}
		. $P{any_purpose}
		. $P{retain_notices_all} . '[. ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_notices}
		. $P{note_mod_inc_with_copr} . '[.]',
};

=item * bdwgc_matlab

I<Since v3.1.0.>

=cut

$RE{bdwgc_matlab} = {
	name        => 'bdwgc-matlab',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{to_copy_prg}
		. $P{any_purpose}
		. $P{retain_notices_all} . '[. ]'
		. $P{repro_code_cite_authors_copr}
		. $P{and_used_by_perm} . '[". ]'
		. $P{repro_matlab_cite_authors} . '[. ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_notices}
		. $P{note_mod_inc_with_copr} . '[. ]'
		. $P{retain_you_avail_orig} . '[.]',
	'pat.alt.subject.license.part.credit' => 'must cite the Authors',
};

=item * beerware

=cut

$RE{beerware} = {
	name                                    => 'Beerware',
	'name.alt.misc.dash'                    => 'Beer-ware',
	'name.alt.org.fedora.iri.self'          => 'Beerware',
	'name.alt.org.spdx.since.date_20140807' => 'Beerware',
	'name.alt.org.tldr.path.short'          => 'beerware',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q10249',
	caption                                 => 'Beerware License',
	'caption.alt.org.tldr'                  => 'Beerware License',
	'caption.alt.org.wikidata'              => 'Beerware',
	'caption.alt.org.wikipedia'             => 'Beerware',
	iri  => 'https://people.freebsd.org/~phk/',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => 'you can buy me a beer in return',

	#<<<  do not let perltidy touch this (keep long regex on one line)
	examples => [
		{   summary => 'pattern with subject "license" matches canonical license',
			gen_args => { subject => 'license' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match canonical license',
			gen_args => { subject => 'grant' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" matches a license grant',
			gen_args => { subject => 'grant' },
			str => 'Licensed under the Beerware License.',
			matches => 1,
		},
		{   summary => 'pattern with subject "name" matches canonical license',
			gen_args => { subject => 'name' },
			str => 'Beerware License',
			matches => 1,
		},
		{   summary => 'pattern with subject "name" doesn\'t match canonical license',
			gen_args => { subject => 'name' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 0,
		},
		{   summary => 'pattern with subject "name" matches a license grant',
			gen_args => { subject => 'name' },
			str => 'Licensed under the Beerware License.',
			matches => 1,
		},
		{   summary => 'pattern with subject "name" doesn\'t match canonical license IRI',
			gen_args => { subject => 'name' },
			str => 'https://people.freebsd.org/~phk/',
			matches => 0,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match original license',
			gen_args => { subject => 'iri' },
			str => 'As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.',
			matches => 0,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match canonical license name',
			gen_args => { subject => 'iri' },
			str => 'Beerware License',
			matches => 0,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match a license shortname',
			gen_args => { subject => 'iri' },
			str => 'Beerware',
			matches => 0,
		},
	],
	#>>>

};

=item * bittorrent

=item * bittorrent_1

=item * bittorrent_1_1

=cut

$RE{bittorrent} = {
	name                                  => 'BitTorrent',
	'name.alt.misc.fossology_old'         => 'Bittorrent',
	'name.alt.org.wikidata.synth.nogrant' => 'Q4918693',
	caption                               => 'BitTorrent Open Source License',
	'caption.alt.org.fedora'              => 'BitTorrent License',
	'caption.alt.org.fedora.iri.self'     => 'BitTorrent Open Source License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{bittorrent_1} = {
	name                                    => 'BitTorrent-1.0',
	'name.alt.org.spdx.since.date_20130117' => 'BitTorrent-1.0',
	'name.alt.misc.fossology_old'           => 'Bittorrent1.0',
	caption     => 'BitTorrent Open Source License v1.0',
	description => <<'END',
Identical to Jabber Open Source License, except...
* drop description-of-modifications clause
* drop retain-copyright-notices clause
* replace references, e.g. "Jabber Server" -> "BitTorrent client"
* document that license is derived from Jabber Open Source License
END
	tags => [
		'license:contains:grant',
		'type:singleversion:bittorrent',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'BitTorrent Open Source License[  ]'
		. 'Version 1\.0[  ]'
		. 'This BitTorrent Open Source License',
	'pat.alt.subject.license.scope.multisection.part.part4' =>
		' has been made available'
		. '[. ]You are responsible for ensuring'
		. ' that the Source Code version remains available'
		. ' even if the Electronic Distribution Mechanism is maintained by a third party'
		. '[.][  ][*)]'
		. 'Intellectual Property Matters[.]',
};

$RE{bittorrent_1_1} = {
	name                                    => 'BitTorrent-1.1',
	'name.alt.org.spdx.since.date_20130117' => 'BitTorrent-1.1',
	'name.alt.misc.fossology_old'           => 'Bittorrent_v1.1',
	caption                => 'BitTorrent Open Source License v1.1',
	'caption.alt.org.tldr' =>
		'BitTorrent Open Source License v1.1 (BitTorrent-1.1)',
	tags => [
		'license:contains:grant:bittorrent_1',
		'type:singleversion:bittorrent',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'BitTorrent Open Source License[  ]'
		. 'Version 1\.1[  ]'
		. 'This BitTorrent Open Source License',
	'pat.alt.subject.license.scope.multisection.part.part4' =>
		' is distributed by you'
		. '[. ]You are responsible for ensuring'
		. ' that the Source Code version remains available'
		. ' even if the Electronic Distribution Mechanism is maintained by a third party'
		. '[.][  ][*)]'
		. 'Intellectual Property Matters[.]',
};

=item * borceux

=cut

$RE{borceux} = {
	name                                    => 'Borceux',
	'name.alt.org.fedora.iri.self'          => 'Borceux',
	'name.alt.org.spdx.since.date_20140807' => 'Borceux',
	caption                                 => 'Borceux license',
	'caption.alt.org.tldr'                  => 'Borceux license',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'distribute each of the files in this package',
};

=item * bsd_0_clause

I<Since v3.5.0.>

=cut

$RE{bsd_0_clause} = {
	name                                    => '0BSD',
	'name.alt.org.fedora'                   => '0BSD',
	'name.alt.org.fedora.iri.self'          => 'ZeroClauseBSD',
	'name.alt.org.osi'                      => '0BSD',
	'name.alt.org.osi.misc.free'            => 'FPL-1.0.0',
	'name.alt.org.spdx.since.date_20150930' => '0BSD',
	'name.alt.org.tldr'                     => 'bsd-0-clause-license',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q48271011',
	caption                                 => 'BSD 0-Clause License',
	'caption.alt.org.fedora'                => 'Zero-Clause BSD',
	'caption.alt.org.osi'                   => 'Zero-Clause BSD',
	'caption.alt.org.osi.misc.old'          =>
		'Zero-Clause BSD / Free Public License 1.0.0',
	'caption.alt.org.osi.misc.list'      => '0-clause BSD License',
	'caption.alt.org.osi.misc.list_bsd'  => '0-clause BSD license',
	'caption.alt.org.osi.misc.list_free' => 'Free Public License 1.0.0',
	'caption.alt.org.spdx'               => 'BSD Zero Clause License',
	'caption.alt.org.tldr'               => 'BSD 0-Clause License (0BSD)',
	'caption.alt.org.wikidata'           => 'Zero-clause BSD License',
	'caption.alt.misc.parens'            => 'BSD (0 clause)',
	description                          => <<'END',
Identical to ISC, except...
* Redistribution of source need not retain any legal text
* omit requirement of notices appearing in copies

Origin: By Rob Landley in 2013 for toybox.
Details at <https://github.com/github/choosealicense.com/issues/464>.
END
	'iri.alt.misc.origin' =>
		'https://github.com/landley/toybox/blob/master/LICENSE',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.name.misc.free' => '(?:Free Public License|FPL)'
		. '(?:'
		. $RE{version_prefix}
		{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. '1(?:\.0){0,2})?',
	'pat.alt.subject.license.scope.multisection' => $P{granted}
		. '[.][  ]'
		. $P{asis_sw_name_discl},
};

=item * bsd_1_clause

I<Since v3.6.0.>

=cut

$RE{bsd_1_clause} = {
	name                                    => 'BSD-1-Clause',
	'name.alt.org.osi'                      => 'BSD-1-Clause',
	'name.alt.org.spdx.since.date_20171228' => 'BSD-1-Clause',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q19292556',
	caption                                 => 'BSD 1-Clause License',
	'caption.alt.org.osi'                   => '1-clause BSD License',
	'caption.alt.org.wikidata'              => '1-clause BSD License',
	'caption.alt.misc.parens'               => 'BSD (1 clause)',
	tags                                    => [
		'family:bsd',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl} . '[.][  ]' . $P{asis_sw_by},
};

=item * bsd_2_clause

=cut

$RE{bsd_2_clause} = {
	name                                  => 'BSD-2-Clause',
	'name.alt.org.debian'                 => 'BSD-2-clause',
	'name.alt.org.osi'                    => 'BSD-2-Clause',
	'name.alt.org.perl'                   => 'freebsd',
	'name.alt.org.spdx'                   => 'BSD-2-Clause',
	'name.alt.org.tldr'                   => 'bsd-2-clause-license-(freebsd)',
	'name.alt.org.tldr.path.short'        => 'freebsd',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18517294',
	'name.alt.misc.clauses'               => '2-clause-BSD',
	'name.alt.misc.freebsd'               => 'FreeBSD',
	'name.alt.misc.simplified'            => 'Simplified-BSD',
	caption                               => 'BSD 2-Clause License',
	'caption.alt.org.fedora.misc.cc'      => 'Creative Commons BSD',
	'caption.alt.org.osi'                 => 'The 2-Clause BSD License',
	'caption.alt.org.osi.misc.list'       => '2-clause BSD License',
	'caption.alt.org.osi.misc.cat_list'   => '2-clause BSD license',
	'caption.alt.org.perl'                => 'FreeBSD License (two-clause)',
	'caption.alt.org.spdx.until.date_20171228' =>
		'BSD 2-clause "Simplified" License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 2-Clause "Simplified" License',
	'caption.alt.org.tldr'     => 'BSD 2-Clause License (FreeBSD/Simplified)',
	'caption.alt.org.wikidata' => '2-clause BSD License',
	'caption.alt.org.wikipedia.iri.bsd' =>
		'2-clause license ("Simplified BSD License" or "FreeBSD License")',
	'caption.alt.misc.parens'     => 'BSD (2 clause)',
	'caption.alt.misc.simplified' => 'Simplified BSD License',
	'caption.alt.misc.qemu'       =>
		'BSD Licence (without advertising or endorsement clauses)',
	'iri.alt.org.cc.archive.time_20110401183132.until.date_20110401' =>
		'http://creativecommons.org/licenses/BSD/', # TODO: find official date
	tags => [
		'family:bsd',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl}
		. '[.][  ]'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. $P{asis_sw_by},
};

=item * bsd_2_clause_freebsd

I<Since v3.6.0.>

=cut

$RE{bsd_2_clause_freebsd} = {
	name                                    => 'BSD-2-Clause-FreeBSD',
	'name.alt.org.fedora.iri.bsd_short'     => '2ClauseBSD',
	'name.alt.org.spdx.until.date_20200803' => 'BSD-2-Clause-FreeBSD',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q90408476',
	caption                                 => 'BSD 2-clause FreeBSD License',
	'caption.alt.org.fedora'                => 'BSD License (two clause)',
	'caption.alt.org.steward'               => 'FreeBSD License',
	'caption.alt.org.spdx.until.date_20130117' =>
		'BSD 2-clause "FreeBSD" License',
	'caption.alt.org.spdx.since.date_20130117.until.date_20171228' =>
		'BSD 2-clause FreeBSD License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 2-Clause FreeBSD License',
	'caption.alt.org.wikidata'       => 'FreeBSD license',
	'summary.alt.org.fedora.iri.bsd' => 'FreeBSD BSD Variant (2 clause BSD)',
	tags                             => [
		'family:bsd',
		'license:contains:license:bsd_2_clause_views',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl}
		. '[.][  ]'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'The views and conclusions contained in the software and documentation '
		. 'are those of the authors and should not be interpreted '
		. 'as representing official policies, either expressed or implied, '
		. 'of the FreeBSD Project[.]',
	'pat.alt.subject.license.scope.line.scope.sentence.part.last' =>
		'expressed or implied, of the FreeBSD Project',
};

=item * bsd_2_clause_netbsd

I<Since v3.6.0.>

=cut

$RE{bsd_2_clause_netbsd} = {
	name                                    => 'BSD-2-Clause-NetBSD',
	'name.alt.org.spdx.until.date_20200515' => 'BSD-2-Clause-NetBSD',
	caption                                 => 'BSD 2-clause NetBSD License',
	'caption.alt.org.spdx.until.date_20130117' =>
		'BSD 2-clause "NetBSD" License',
	'caption.alt.org.spdx.since.date_20130117.until.date_20171228' =>
		'BSD 2-clause NetBSD License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 2-Clause NetBSD License',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.first' =>
		'This code is derived from software contributed to The NetBSD Foundation by',
	'pat.alt.subject.license.scope.multisection' =>
		'This code is derived from software contributed to The NetBSD Foundation by[ word]{0,15}'
		. '[  ]'
		. $P{retain_notice_cond_discl}
		. '[.][  ]'
		. $P{repro_copr_cond_discl},
};

=item * bsd_2_clause_patent

I<Since v3.6.0.>

=cut

$RE{bsd_2_clause_patent} = {
	name                                    => 'BSD+Patent',
	'name.alt.org.fedora'                   => 'BSD-2-Clause-Patent',
	'name.alt.org.fedora.iri.self'          => 'BSD-2-Clause-Patent',
	'name.alt.org.osi'                      => 'BSDplusPatent',
	'name.alt.org.osi.misc.shortname'       => 'BSD-2-Clause-Patent',
	'name.alt.org.spdx.since.date_20171228' => 'BSD-2-Clause-Patent',
	caption                  => 'BSD 2-Clause Plus Patent License',
	'caption.alt.org.fedora' => 'BSD + Patent',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 2-Clause Plus Patent License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD-2-Clause Plus Patent License',
	'caption.alt.org.osi' => 'BSD+Patent',
	tags                  => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.last_but_disclaimers'
		=> 'Except as expressly stated above, no rights or licenses',
	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl}
		. '[.][  ]'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. 'Subject to the terms and conditions of this license, '
		. 'each copyright holder and contributor hereby grants',
};

=item * bsd_2_clause_views

=cut

$RE{bsd_2_clause_views} = {
	name                                   => 'BSD-2-Clause-Views',
	'iri.alt.org.spdx.since.date_20200803' => 'BSD-2-Clause-Views',
	caption                    => 'BSD 2-Clause with views sentence',
	'caption.alt.misc.freebsd' => 'FreeBSD License',
	tags                       => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl}
		. '[.][  ]'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'The views and conclusions contained in the software and documentation '
		. 'are those of the authors and should not be interpreted '
		. 'as representing official policies, either expressed or implied, '
		. 'of',
};

=item * bsd_3_clause

=cut

$RE{bsd_3_clause} = {
	name                                  => 'BSD-3-Clause',
	'name.alt.org.debian'                 => 'BSD-3-clause',
	'name.alt.org.fedora.iri.bsd'         => '3ClauseBSD',
	'name.alt.org.osi'                    => 'BSD-3-Clause',
	'name.alt.org.perl.synth.nogrant'     => 'bsd',
	'name.alt.org.spdx'                   => 'BSD-3-Clause',
	'name.alt.org.tldr.path.short'        => 'bsd3',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18491847',
	'name.alt.misc.clauses'               => '3-clause-BSD',
	'name.alt.misc.modified'              => 'Modified-BSD',
	caption                               => 'BSD 3-Clause License',
	'caption.alt.org.fedora'              => 'New BSD',
	'caption.alt.org.osi'                 => 'The 3-Clause BSD License',
	'caption.alt.org.osi.misc.list'       => '3-clause BSD License',
	'caption.alt.org.osi.misc.list_lower' => '3-clause BSD license',
	'caption.alt.org.perl'                => 'BSD License (three-clause)',
	'caption.alt.org.spdx.until.date_20171228' =>
		'BSD 3-clause "New" or "Revised" License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 3-Clause "New" or "Revised" License',
	'caption.alt.org.tldr'              => 'BSD 3-Clause License (Revised)',
	'caption.alt.org.wikidata'          => '3-clause BSD License',
	'caption.alt.org.wikipedia.iri.bsd' =>
		'3-clause license ("BSD License 2.0", "Revised BSD License", "New BSD License", or "Modified BSD License")',
	'caption.alt.misc.modified'   => 'Modified BSD License',
	'caption.alt.misc.new_lower'  => 'new BSD License',
	'caption.alt.misc.new_parens' => '(new) BSD License',
	'caption.alt.misc.parens'     => 'BSD (3 clause)',
	'caption.alt.misc.qemu'  => 'BSD Licence (without advertising clause)',
	'summary.alt.org.fedora' => 'BSD License (no advertising)',
	'summary.alt.org.fedora.misc.new_bsd' =>
		'New BSD (no advertising, 3 clause)',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '[.]?[  ]'
		. '(?:[*)]\[?(?:rescinded 22 July 1999'
		. '|This condition was removed[.])\]?)?' . '[*)]'
		. $P{nopromo_neither},
};

=item * bsd_3_clause_attribution

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_attribution} = {
	name                                    => 'BSD-3-Clause-Attribution',
	'name.alt.org.spdx.since.date_20140807' => 'BSD-3-Clause-Attribution',
	caption                                 => 'BSD with attribution',
	'caption.alt.org.fedora.iri.self'       => 'BSD with attribution',

	# has word "Attribution title-cased, unlike caption
	'iri.alt.org.fedora.iri.self' =>
		'https://fedoraproject.org/wiki/Licensing/BSD_with_Attribution',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither} . '[.][  ][*)]' . $P{redist_ack_this},
};

=item * bsd_3_clause_clear

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_clear} = {
	name                                    => 'BSD-3-Clause-Clear',
	'name.alt.org.spdx.since.date_20130117' => 'BSD-3-Clause-Clear',
	caption                                 => 'BSD 3-Clause Clear License',
	'caption.alt.org.spdx.until.date_20130410' =>
		'BSD 2-clause "Clear" License',
	'caption.alt.org.spdx.since.date_20130410.until.date_20171228' =>
		'BSD 3-clause Clear License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 3-Clause Clear License',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. 'NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY[\']S PATENT RIGHTS ARE GRANTED BY THIS LICENSE'
		. '[. ]'
		. $P{discl_warranties},
};

=item * bsd_3_clause_eclipse

I<Since v3.9.0.>

=cut

# license scheme is unversioned, despite versioned name
$RE{bsd_3_clause_eclipse} = {
	name                                  => 'EDL-1.0',
	'name.alt.org.debian'                 => 'BSD-3-clause~Eclipse',
	'name.alt.org.steward'                => 'EDL-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q26245522',
	caption                    => 'Eclipse Distribution License 1.0',
	'caption.alt.org.fedora'   => 'Eclipse Distribution License 1.0',
	'caption.alt.org.steward'  => 'Eclipse Distribution License - v 1.0',
	'caption.alt.org.wikidata' => 'Eclipse Distribution License',
	description                => <<'END',
Specific instance of BSD 3-Clause License,
tied to "Eclipse Foundation, Inc.".
END
	iri  => 'http://www.eclipse.org/org/documents/edl-v10.php',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause_3' =>
		'Neither the name of the Eclipse Foundation, Inc\. nor',
};

=item * bsd_3_clause_lbnl

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_lbnl} = {
	name                                    => 'BSD-3-Clause-LBNL',
	'name.alt.org.fedora.iri.self'          => 'LBNLBSD',
	'name.alt.org.osi'                      => 'BSD-3-Clause-LBNL',
	'name.alt.org.spdx.since.date_20140807' => 'BSD-3-Clause-LBNL',
	caption => 'Lawrence Berkeley National Labs BSD variant license',
	'caption.alt.org.fedora.misc.short' => 'LBNL BSD',
	'caption.alt.org.osi'               =>
		'Lawrence Berkeley National Labs BSD Variant License',
	'caption.alt.org.osi.misc.list_bsd' => 'BSD-3-Clause-LBNL',
	tags                                => [
		'family:bsd',
		'license:is:grant',
		'type:unversioned',
	],
	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. 'NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY[\']S PATENT RIGHTS ARE GRANTED BY THIS LICENSE'
		. '[. ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'You are under no obligation whatsoever to provide any bug fixes',
	'pat.alt.subject.license.scope.line.scope.sentence.part.last_disclaimer'
		=> 'You are under no obligation whatsoever to provide any bug fixes',
};

=item * bsd_3_clause_modification

=cut

$RE{bsd_3_clause_modification} = {
	name                                    => 'BSD-3-Clause-Modification',
	'name.alt.org.spdx.since.date_20210307' => 'BSD-3-Clause-Modification',
	caption                                 => 'BSD 3-Clause Modification',
	tags                                    => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. ' from the copyright holders'
		. '[.][  ]'
		. '[*)]If any files are modified'
		. ', you must cause the modified files to carry prominent notices'
		. ' stating that you changed the files and the date of any change',
};

=item * bsd_3_clause_no_military_license

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_no_military_license} = {
	name => 'BSD-3-Clause-No-Military-License',
	'name.alt.org.spdx.since.date_20210520' =>
		'BSD-3-Clause-No-Military-License',
	caption => 'BSD 3-Clause No Military License',
	tags    => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'YOU ACKNOWLEDGE THAT THIS SOFTWARE'
		. ' IS NOT DESIGNED, LICENSED OR INTENDED'
		. ' FOR USE IN THE DESIGN, CONSTRUCTION, OPERATION OR MAINTENANCE'
		. ' OF ANY MILITARY FACILITY[.]',
};

=item * bsd_3_clause_no_nuclear_license

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_no_nuclear_license} = {
	name => 'BSD-3-Clause-No-Nuclear-License',
	'name.alt.org.spdx.since.date_20160721' =>
		'BSD-3-Clause-No-Nuclear-License',
	caption => 'BSD 3-Clause No Nuclear License',
	tags    => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. $P{discl_warranties_any_kind} . '[. ]'
		. $P{discl_warranties_excluded} . '[. ]'
		. $P{discl_liability_suffered} . '[. ]'
		. $P{discl_liability_revenue}
		. '[.][  ]'
		. 'You acknowledge that this software'
		. ' is not designed, licensed or intended for use'
		. ' in the design, construction, operation or maintenance'
		. ' of any nuclear facility[.]',
};

=item * bsd_3_clause_no_nuclear_license_2014

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_no_nuclear_license_2014} = {
	name => 'BSD-3-Clause-No-Nuclear-License-2014',
	'name.alt.org.spdx.since.date_20160721' =>
		'BSD-3-Clause-No-Nuclear-License-2014',
	caption => 'BSD 3-Clause No Nuclear License 2014',
	tags    => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'You acknowledge that this software'
		. ' is not designed, licensed or intended for use'
		. ' in the design, construction, operation or maintenance'
		. ' of any nuclear facility[.]',
};

=item * bsd_3_clause_no_nuclear_warranty

I<Since v3.6.0.>

=cut

$RE{bsd_3_clause_no_nuclear_warranty} = {
	name => 'BSD-3-Clause-No-Nuclear-Warranty',
	'name.alt.org.spdx.since.date_20160721' =>
		'BSD-3-Clause-No-Nuclear-Warranty',
	caption => 'BSD 3-Clause No Nuclear Warranty',
	tags    => [
		'family:bsd',
		'type:unversioned',
	],
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{nopromo_neither}
		. '[.][  ]'
		. $P{discl_warranties_any_kind} . '[. ]'
		. $P{discl_warranties_excluded} . '[. ]'
		. $P{discl_liability_suffered} . '[. ]'
		. $P{discl_liability_revenue}
		. '[.][  ]'
		. 'You acknowledge that this software'
		. ' is not designed or intended for use'
		. ' in the design, construction, operation or maintenance'
		. ' of any nuclear facility[.]',
};

=item * bsd_3_clause_refractions

I<Since v3.9.0.>

=cut

# license scheme is unversioned, despite versioned name
$RE{bsd_3_clause_refractions} = {
	'name.alt.org.debian'     => 'BSD-3-clause~Refractions',
	caption                   => 'Refractions BSD License v1.0',
	'caption.alt.org.steward' =>
		'Refractions BSD 3 Clause License (BSD) - v 1.0',
	description => <<'END',
Specific instance of BSD 3-Clause License,
tied to "Refractions Research".
END
	iri  => 'http://udig.refractions.net/files/bsd3-v10.html',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause_3' =>
		'Neither the name of the Refractions Research nor',
};

=item * bsd_4_clause

=cut

$RE{bsd_4_clause} = {
	name                                       => 'BSD-4-Clause',
	'name.alt.org.debian'                      => 'BSD-4-clause',
	'name.alt.org.fedora.iri.bsd_short'        => 'BSDwithAdvertising',
	'name.alt.org.spdx'                        => 'BSD-4-Clause',
	'name.alt.org.tldr'                        => '4-clause-bsd',
	'name.alt.org.wikidata.synth.nogrant'      => 'Q21503790',
	'name.alt.misc.clauses'                    => '4-clause-BSD',
	caption                                    => 'BSD 4-Clause License',
	'caption.alt.org.fedora'                   => 'BSD License (original)',
	'caption.alt.org.fedora.misc.summary'      => 'Original BSD License',
	'caption.alt.org.spdx.until.date_20171228' =>
		'BSD 4-clause "Original" or "Old" License',
	'caption.alt.org.spdx.since.date_20171228' =>
		'BSD 4-Clause "Original" or "Old" License',
	'caption.alt.org.tldr'              => '4-Clause BSD',
	'caption.alt.org.wikidata'          => '4-clause BSD License',
	'caption.alt.org.wikipedia.iri.bsd' =>
		'4-clause license (original "BSD License")',
	'caption.alt.misc.qemu'   => 'BSD Licence (with advertising clause)',
	'caption.alt.misc.parens' => 'BSD (4 clause)',
	'summary.alt.org.fedora.iri.bsd' =>
		'Original BSD License (BSD with advertising)',
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => $P{ad_mat_ack_this},

# TODO: enable when possible to skip based on dependency graph
#	'pat.alt.subject.license.scope.multisection.part.head' =>
#		$P{repro_copr_cond_discl} . '[.][  ]' . '[*)]?' . $P{ad_mat_ack_this},
	'pat.alt.subject.license.scope.multisection.part.tail' => '[*)]?'
		. $P{ad_mat_ack_this}
		. '[word][ word]{0,14}'
		. '[.][  ]' . '[*)]?'
		. $P{nopromo_neither},
	'pat.alt.subject.license.scope.multisection.part.most' =>
		$P{repro_copr_cond_discl}
		. '[.][  ][*)]?'
		. $P{ad_mat_ack_this}
		. '[word][ word]{0,14}'
		. '[.][  ][*)]?'
		. $P{nopromo_neither},
};

=item * bsd_4_clause_uc

I<Since v3.7.0.>

=cut

$RE{bsd_4_clause_uc} = {
	name                => 'BSD-4-Clause-UC',
	'name.alt.org.spdx' => 'BSD-4-Clause-UC',
	caption             => 'BSD-4-Clause (University of California-Specific)',
	description         => <<'END',
Specific instance of BSD 4-Clause License,
tied to "University of California, Berkeley".
END
	tags => [
		'family:bsd',
		'license:contains:license:bsd_4_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.tail' => '[*)]?'
		. $P{ad_mat_ack_this}
		. 'the University of California, Berkeley and its contributors'
		. '[.][  ]' . '[*)]?'
		. $P{nopromo_university},
	'pat.alt.subject.license.scope.multisection.part.most' =>
		$P{repro_copr_cond_discl}
		. '[.][  ][*)]?'
		. $P{ad_mat_ack_this}
		. 'the University of California, Berkeley and its contributors'
		. '[.][  ][*)]?'
		. $P{nopromo_university},
};

=item * bsd_protection

I<Since v3.8.0.>

=cut

$RE{bsd_protection} = {
	name                                    => 'BSD-Protection',
	'name.alt.org.spdx.since.date_20140807' => 'BSD-Protection',
	caption                                 => 'BSD Protection License',
	'caption.alt.org.fedora.iri.self'       => 'BSD Protection License',
	'caption.alt.org.fedora.misc.short'     => 'BSD Protection',
	tags                                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.section1' =>
		'This license governs the copying, distribution, and modification',
};

=item * bsl

I<Since v3.1.90.>

=item * bsl_1

I<Since v3.1.90.>

=cut

$RE{bsl} = {
	name                                  => 'BSL',
	'name.alt.misc.fossology_old'         => 'Boost',
	'name.alt.org.wikidata.synth.nogrant' => 'Q2353141',
	caption                               => 'Boost Software License',
	'caption.alt.misc.mixedcase'          => 'boost Software License',
	'iri.alt.org.wikipedia'               =>
		'https://en.wikipedia.org/wiki/Boost_Software_License#License',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{bsl_1} = {
	name                                            => 'BSL-1.0',
	'name.alt.org.osi'                              => 'BSL-1.0',
	'name.alt.org.fedora.synth.nogrant'             => 'Boost',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'bsl1.0',
	'name.alt.org.spdx'                             => 'BSL-1.0',
	'name.alt.org.tldr' => 'boost-software-license-1.0-explained',
	'name.alt.org.tldr.path.short.synth.nogrant' => 'boost',
	'name.alt.misc.fossology_old'                => 'Boost_v1.0',
	caption                                => 'Boost Software License 1.0',
	'caption.alt.org.fedora.synth.nogrant' => 'Boost Software License',
	'caption.alt.misc.mixedcase' => 'boost Software License, Version 1.0',
	'caption.alt.org.osi.misc.list.synth.nogrant' => 'Boost Software License',
	'caption.alt.org.tldr'  => 'Boost Software License 1.0 (BSL-1.0)',
	'caption.alt.org.trove' => 'Boost Software License 1.0 (BSL-1.0)',
	iri                     => 'http://www.boost.org/LICENSE_1_0.txt',
	tags                    => [
		'license:is:grant',
		'type:singleversion:bsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'this license [(]the ["]Software["][)] to use, reproduce',
};

=item * bzip2

=item * bzip2_1_0_5

=item * bzip2_1_0_6

=cut

$RE{bzip2} = {
	name    => 'bzip2',
	caption => 'bzip2 and libbzip2 License',
	tags    => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.license' =>
		'[*)]Redistributions of source code must retain '
		. 'the above copyright notice, this list of conditions '
		. 'and the following disclaimer[.][  ]'
		. '[*)]The origin of this software must not be misrepresented[;] '
		. 'you must not claim that you wrote the original software[. ]'
		. 'If you use this software in a product, '
		. 'an acknowledgment in the product documentation '
		. 'would be appreciated but is not required[.][  ]'
		. '[*)]Altered source versions must be plainly marked as such, '
		. 'and must not be misrepresented as being the original software[.][  ]'
		. '[*)]The name of the author may not be used '
		. 'to endorse or promote products derived from this software '
		. 'without specific prior written permission[.]',
};

$RE{bzip2_1_0_5} = {
	name                                    => 'bzip2-1.0.5',
	'name.alt.org.spdx.since.date_20140807' => 'bzip2-1.0.5',
	caption => 'bzip2 and libbzip2 License v1.0.5',
	tags    => [
		'license:is:grant',
		'type:singleversion:bzip2',
	],
	licenseversion => '1.0.5',

	'pat.alt.subject.license' =>
		'This program, ["]?bzip2["]?(?: and|, the) associated library ["]?libbzip2["]?, '
		. '(?:and all documentation, )?'
		. 'are copyright[c] 1996[-]2007',
};

$RE{bzip2_1_0_6} = {
	name                                    => 'bzip2-1.0.6',
	'name.alt.org.spdx.since.date_20140807' => 'bzip2-1.0.6',
	'name.alt.org.tldr.synth.nogrant'       => 'bzip2',
	caption => 'bzip2 and libbzip2 License v1.0.6',
	'caption.alt.org.tldr.synth.nogrant' => 'bzip2 (original)',
	tags                                 => [
		'license:is:grant',
		'type:singleversion:bzip2',
	],
	licenseversion => '1.0.6',

	'pat.alt.subject.license' =>
		'This program, ["]?bzip2["]?(?: and|, the) associated library ["]?libbzip2["]?, '
		. '(?:and all documentation, )?'
		. 'are copyright[c] 1996[-]2010',
};

=item * cal

I<Since v3.5.0.>

=item * cal_1

I<Since v3.5.0.>

=cut

$RE{cal} = {
	name    => 'CAL',
	caption => 'Cryptographic Autonomy License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cal_1} = {
	name                                    => 'CAL-1.0',
	'name.alt.org.osi'                      => 'CAL-1.0',
	'name.alt.org.spdx.since.date_20200515' => 'CAL-1.0',
	caption               => 'Cryptographic Autonomy License 1.0',
	'caption.alt.org.osi' => 'Cryptographic Autonomy License version 1.0',
	'caption.alt.org.osi.misc.list' => 'Cryptographic Autonomy License v.1.0',
	'caption.alt.misc.legal' => 'The Cryptographic Autonomy License, v. 1.0',
	'iri.alt.misc.github'    =>
		'https://github.com/holochain/cryptographic-autonomy-license',
	tags => [
		'type:singleversion:cal',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'This Cryptographic Autonomy License [(]the ["]License["][)] '
		. 'applies to any Work '
		. 'whose owner has marked it',
};

=item * caldera

=cut

$RE{caldera} = {
	name                                    => 'Caldera',
	'name.alt.org.spdx.since.date_20140807' => 'Caldera',
	caption                                 => 'Caldera License',
	'caption.alt.org.tldr'                  => 'Caldera License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Caldera International, Inc\. hereby grants a fee free license',
};

=item * catosl

=item * catosl_1_1

=cut

$RE{catosl} = {
	name    => 'CATOSL',
	caption => 'Computer Associates Trusted Open Source License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{catosl_1_1} = {
	name                                            => 'CATOSL-1.1',
	'name.alt.org.fedora.synth.nogrant'             => 'CATOSL',
	'name.alt.org.osi'                              => 'CATOSL-1.1',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ca-tosl1.0',
	'name.alt.org.spdx'                             => 'CATOSL-1.1',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38365570',
	'name.alt.misc.fossology_old'                   => 'CA1.1',
	caption => 'Computer Associates Trusted Open Source License 1.1',
	'caption.alt.org.tldr' =>
		'Computer Associates Trusted Open Source License 1.1 (CATOSL-1.1)',
	'caption.alt.org.wikidata' =>
		'Computer Associates Trusted Open Source License, Version 1.1',
	tags => [
		'type:singleversion:catosl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'Contribution means[*)]in the case of CA, the Original Program',
};

=item * cc_by

=item * cc_by_1

I<Since v3.1.101.>

=item * cc_by_2

I<Since v3.1.101.>

=item * cc_by_2_5

I<Since v3.1.101.>

=item * cc_by_3

I<Since v3.1.101.>

=item * cc_by_4

I<Since v3.1.101.>

=cut

# sources of introduction and expiry dates:
# <https://wiki.creativecommons.org/wiki/License_Versions#License_Versioning_History>
# <https://wiki.creativecommons.org/wiki/Launches>
# <https://wiki.creativecommons.org/wiki/CC_Ports_by_Jurisdiction>

my $if_dist_work_or_works_keep_intact_notices
	= 'If you distribute, publicly display, publicly perform, or publicly digitally perform the Work or any Derivative Works or Collective Works, You must keep intact all copyright notices for the Work and';
my $if_dist_work_or_collections_keep_intact_notices
	= 'If You Distribute, or Publicly Perform the Work or any Adaptations or Collections, You must, unless a request has been made pursuant to Section 4[(]a[)], keep intact all copyright notices for the Work and';
my $credit_author_if_supplied
	= ' give the Original Author credit reasonable to the medium or means You are utilizing by conveying the name [(]or pseudonym if applicable[)] of the Original Author if supplied;';
my $credit_author_or_designated_party
	= ' provide, reasonable to the medium or means You are utilizing[:]?'
	. ' [*)] the name of the Original Author [(]or pseudonym, if applicable[)] if supplied, and[/]or'
	. ' [*)] if the Original Author and[/]or Licensor designate another party or parties'
	. ' [(][eg] a sponsor institute, publishing entity, journal[)]'
	. ' for attribution in Licensor[\']?s copyright notice, terms of service or by other reasonable means,'
	. ' the name of such party or parties;';

#" if the Original Author and[/]or Licensor designate another party or parties [(][eg], a sponsor institute, publishing entity, journal[)] for attribution [(]["]Attribution Parties["][)] in Licensor[']?s copyright notice, terms of service or by other reasonable means, the name of such party or parties;";
#' [*)] the title of the Work if supplied;';
my $to_extend_URI
	= ' to the extent reasonably practicable, the Uniform Resource Identifier, if any, that Licensor specifies to be associated with the Work,'
	. ' unless such URI does not refer to the copyright notice or licensing information for the Work; and';

#    ' (iii) to the extent reasonably practicable, the URI, if any, that Licensor specifies to be associated with the Work, unless such URI does not refer to the copyright notice or licensing information for the Work; and'
#" (iv) , consistent with Section 3(b), in the case of an Adaptation, a credit identifying the use of the Work in the Adaptation (e.g., "French translation of the Work by Original Author," or "Screenplay based on original Work by Original Author"). The credit required by this Section 4 (b) may be implemented in any reasonable manner; provided, however, that in the case of a Adaptation or Collection, at a minimum such credit will appear, if a credit for all contributing authors of the Adaptation or Collection appears, then as part of these credits and in a manner at least as prominent as the credits for the other contributing authors. For the avoidance of doubt, You may only use the credit required by this Section for the purpose of attribution in the manner set out above and, by exercising Your rights under this License, You may not implicitly or explicitly assert or imply any connection with, sponsorship or endorsement by the Original Author, Licensor and[/]or Attribution Parties, as appropriate, of You or Your use of the Work, without the separate, express prior written permission of the Original Author, Licensor and[/]or Attribution Parties.

$RE{cc_by} = {
	name                                                    => 'CC-BY',
	'name.alt.org.fedora'                                   => 'CC-BY',
	'name.alt.org.cc'                                       => 'CC-BY',
	'name.alt.org.wikidata.synth.nogrant'                   => 'Q6905323',
	'name.alt.misc.fossology_old_vague.synth.nogrant'       => 'CCPL',
	'name.alt.misc.fossology_old_vague_short.synth.nogrant' => 'CCA',
	caption                  => 'Creative Commons Attribution',
	'caption.alt.org.fedora' => 'Creative Commons Attribution license',
	tags                     => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '|BY|'
		. $P{cc_url} . 'by))',
};

$RE{cc_by_1} = {
	name                                              => 'CC-BY-1.0',
	'name.alt.org.cc'                                 => 'CC-BY-1.0',
	'name.alt.org.spdx'                               => 'CC-BY-1.0',
	'name.alt.org.wikidata.synth.nogrant'             => 'Q30942811',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'CCA1.0',
	caption              => 'Creative Commons Attribution 1.0 Generic',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution 1.0 Generic License',
	'caption.alt.org.cc.misc.legal.synth.nogrant' => 'Attribution 1.0',
	'caption.alt.org.cc.misc.shortname'           => 'CC BY 1.0',
	'caption.alt.org.cc.misc.deed' => 'Attribution 1.0 Generic (CC BY 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution 1.0',
	'caption.alt.org.wikidata' => 'Creative Commons Attribution 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.part4' =>
		'as requested[. ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_if_supplied
		. ' the title of the Work if supplied;'
		. ' in the case of a Derivative',
};

$RE{cc_by_2} = {
	name                                              => 'CC-BY-2.0',
	'name.alt.org.cc.since.date_20040525'             => 'CC-BY-2.0',
	'name.alt.org.spdx'                               => 'CC-BY-2.0',
	'name.alt.org.wikidata.synth.nogrant'             => 'Q19125117',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'CCPL_v2.0',
	caption              => 'Creative Commons Attribution 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution 2.0 Generic License',
	'caption.alt.org.cc.misc.legal.synth.nogrant' => 'Attribution 2.0',
	'caption.alt.org.cc.misc.shortname'           => 'CC BY 2.0',
	'caption.alt.org.cc.misc.deed' => 'Attribution 2.0 Generic (CC BY 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution 2.0',
	'caption.alt.org.wikidata' => 'Creative Commons Attribution 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.part4' =>
		'as requested[. ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_if_supplied
		. ' the title of the Work if supplied;'
		. $to_extend_URI
		. ' in the case of a Derivative',
};

$RE{cc_by_2_5} = {
	name                                                      => 'CC-BY-2.5',
	'name.alt.org.cc.since.date_20050600'                     => 'CC-BY-2.5',
	'name.alt.org.spdx'                                       => 'CC-BY-2.5',
	'name.alt.org.wikidata.synth.nogrant'                     => 'Q18810333',
	'name.alt.misc.fossology_old_vague.synth.nogrant'         => 'CCPL_v2.5',
	'name.alt.misc.fossology_old_vague_short.synth.nogrant'   => 'CCA_v2.5',
	'name.alt.misc.fossology_old_vague_shorter.synth.nogrant' => 'CCA2.5',
	caption              => 'Creative Commons Attribution 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution 2.5 Generic License',
	'caption.alt.org.cc.misc.legal.synth.nogrant' => 'Attribution 2.5',
	'caption.alt.org.cc.misc.shortname'           => 'CC BY 2.5',
	'caption.alt.org.cc.misc.deed' => 'Attribution 2.5 Generic (CC BY 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution 2.5',
	'caption.alt.org.wikidata' => 'Creative Commons Attribution 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by',
	],
	licenseversion => '2.5',

	'pat.alt.subject.license.scope.multisection.part.part4' =>
		'as requested[. ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_or_designated_party
		. ' the title of the Work if supplied;'
		. $to_extend_URI
		. ' in the case of a Derivative',
};

$RE{cc_by_3} = {
	name                                  => 'CC-BY-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-3.0',
	'name.alt.org.tldr.synth.nogrant' => 'creative-commons-attribution-(cc)',
	'name.alt.org.wikidata.synth.nogrant'                   => 'Q14947546',
	'name.alt.misc.fossology_old_vague.synth.nogrant'       => 'CCPL_v3.0',
	'name.alt.misc.fossology_old_vague_short.synth.nogrant' => 'CCA3.0',
	caption              => 'Creative Commons Attribution 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution 3.0 International License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY 3.0',
	'caption.alt.org.cc.misc.deed' => 'Attribution 3.0 Unported (CC BY 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution 3.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution 3.0 Unported (CC-BY)',
	'caption.alt.org.wikidata' => 'Creative Commons Attribution 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.part4' =>
		'as requested[. ]' . '[*)]?'
		. $if_dist_work_or_collections_keep_intact_notices

#              . $credit_author_or_designated_party
#              . ' the title of the Work if supplied;'
#              . ' to the extent reasonably practicable, the Uniform Resource Identifier, if any, that Licensor specifies to be associated with the Work, unless such URI does not refer to the copyright notice or licensing information for the Work; and'
#              . ' in the case of a Derivative',
};

$RE{cc_by_4} = {
	name                                    => 'CC-BY-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-4.0',
	'name.alt.org.tldr'                     =>
		'creative-commons-attribution-4.0-international-(cc-by-4)',
	'name.alt.org.tldr.path.short'        => 'ccby4',
	'name.alt.org.wikidata.synth.nogrant' => 'Q20007257',
	caption              => 'Creative Commons Attribution 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution 4.0 International License',
	'caption.alt.org.cc.misc.legal.synth.nogrant' =>
		'Attribution 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution 4.0 International (CC BY 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution 4.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution 4.0 International (CC BY 4.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution 4.0',
};

=item * cc_by_nc

=item * cc_by_nc_1

I<Since v3.1.101.>

=item * cc_by_nc_2

I<Since v3.1.101.>

=item * cc_by_nc_2_5

I<Since v3.1.101.>

=item * cc_by_nc_3

I<Since v3.1.101.>

=item * cc_by_nc_4

I<Since v3.1.101.>

=cut

$RE{cc_by_nc} = {
	name                                  => 'CC-BY-NC',
	'name.alt.org.cc'                     => 'CC-BY-NC',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6936496',
	caption                  => 'Creative Commons Attribution-NonCommercial',
	'caption.alt.org.fedora' => 'Creative Commons Attribution-NonCommercial',
	tags                     => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '[- ]'
		. $P{cc_nc}
		. '|BY[- ]NC|'
		. $P{cc_url}
		. 'by-nc))',
};

$RE{cc_by_nc_1} = {
	name                                  => 'CC-BY-NC-1.0',
	'name.alt.org.cc'                     => 'CC-BY-NC-1.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q44283370',
	caption              => 'Creative Commons Attribution-NonCommercial 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NonCommercial 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial 1.0 Generic (CC BY-NC 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial 1.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_2} = {
	name                                  => 'CC-BY-NC-2.0',
	'name.alt.org.cc.since.date_20040525' => 'CC-BY-NC-2.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-2.0',
	'name.alt.org.tldr' => 'creative-commons-public-license-(ccpl)',
	'name.alt.org.wikidata.synth.nogrant' => 'Q44128984',
	caption              => 'Creative Commons Attribution-NonCommercial 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial 2.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NonCommercial 2.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC 2.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial 2.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_2_5} = {
	name                                  => 'CC-BY-NC-2.5',
	'name.alt.org.cc.since.date_20050600' => 'CC-BY-NC-2.5',
	'name.alt.org.spdx'                   => 'CC-BY-NC-2.5',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19113746',
	caption              => 'Creative Commons Attribution-NonCommercial 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial 2.5 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NonCommercial 2.5',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC 2.5',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial 2.5 Generic (CC BY-NC 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial 2.5',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_3} = {
	name                                  => 'CC-BY-NC-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-NC-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-3.0',
	'name.alt.org.tldr.synth.nogrant'     =>
		'creative-commons-attribution-noncommercial-(cc-nc)',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18810331',
	caption              => 'Creative Commons Attribution-NonCommercial 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution-NonCommercial 3.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC 3.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial 3.0 Unported (CC BY-NC 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial 3.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'Creative Commons Attribution NonCommercial (CC-BY-NC)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_4} = {
	name                                    => 'CC-BY-NC-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-NC-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-NC-4.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q34179348',
	caption              => 'Creative Commons Attribution-NonCommercial 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial 4.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial 4.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-nc/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution-NonCommercial 4.0',
};

=item * cc_by_nc_nd

=item * cc_by_nc_nd_1

I<Since v3.1.101.>

=item * cc_by_nc_nd_2

I<Since v3.1.101.>

=item * cc_by_nc_nd_2_5

I<Since v3.1.101.>

=item * cc_by_nc_nd_3

I<Since v3.1.101.>

=item * cc_by_nc_nd_4

I<Since v3.1.101.>

=cut

$RE{cc_by_nc_nd} = {
	name                                  => 'CC-BY-NC-ND',
	'name.alt.org.cc'                     => 'CC-BY-NC-ND',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6937225',
	caption => 'Creative Commons Attribution-NonCommercial-NoDerivatives',
	'caption.alt.org.cc.misc.abbrev' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs',
	'caption.alt.org.cc.misc.abbrev_flipped' =>
		'Creative Commons Attribution-NoDerivs-NonCommercial',
	'caption.alt.org.fedora' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs',
	tags => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by}
		. '[- ](?:'
		. $P{cc_nc} . '[- ]'
		. $P{cc_nd} . '|'
		. $P{cc_nd} . '[- ]'
		. $P{cc_nc}
		. ')|BY[- ]NC[- ]ND|'
		. $P{cc_url}
		. 'by-nc-nd))',
};

$RE{cc_by_nc_nd_1} = {
	name                                  => 'CC-BY-NC-ND-1.0',
	'name.alt.org.cc'                     => 'CC-BY-ND-NC-1.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-ND-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q47008926',
	caption => 'Creative Commons Attribution-NoDerivs-NonCommercial 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivs-NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NoDerivs-NonCommercial 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND-NC 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivs-NonCommercial 1.0 Generic (CC BY-ND-NC 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial No Derivatives 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 1.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nd-nc/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_nd_2} = {
	name                                  => 'CC-BY-NC-ND-2.0',
	'name.alt.org.cc.since.date_20040525' => 'CC-BY-NC-ND-2.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-ND-2.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q47008927',
	caption => 'Creative Commons Attribution-NonCommercial-NoDerivs 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-NoDerivs 2.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-ND 2.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-NoDerivs 2.0 Generic (CC BY-NC-ND 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_nd_2_5} = {
	name                                  => 'CC-BY-NC-ND-2.5',
	'name.alt.org.cc.since.date_20050600' => 'CC-BY-NC-ND-2.5',
	'name.alt.org.spdx'                   => 'CC-BY-NC-ND-2.5',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19068204',
	caption => 'Creative Commons Attribution-NonCommercial-NoDerivs 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-NoDerivs 2.5',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-ND 2.5',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-NoDerivs 2.5 Generic (CC BY-NC-ND 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 2.5',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_nd_3} = {
	name                                  => 'CC-BY-NC-ND-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-NC-ND-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-ND-3.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19125045',
	caption => 'Creative Commons Attribution-NonCommercial-NoDerivs 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-NoDerivs 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-ND 3.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-NoDerivs 3.0 Unported (CC BY-NC-ND 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial No Derivatives 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 3.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'Creative Commons Attribution NonCommercial NoDerivs (CC-NC-ND)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_nd_4} = {
	name                                    => 'CC-BY-NC-ND-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-NC-ND-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-NC-ND-4.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q24082749',
	caption => 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-NoDerivatives 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-ND 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial No Derivatives 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial No Derivatives 4.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0',
};

=item * cc_by_nc_sa

=item * cc_by_nc_sa_1

I<Since v3.1.101.>

=item * cc_by_nc_sa_2

I<Since v3.1.101.>

=item * cc_by_nc_sa_2_5

I<Since v3.1.101.>

=item * cc_by_nc_sa_3

I<Since v3.1.101.>

=item * cc_by_nc_sa_4

I<Since v3.1.101.>

=cut

$RE{cc_by_nc_sa} = {
	name                                  => 'CC-BY-NC-SA',
	'name.alt.org.cc'                     => 'CC-BY-NC-SA',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6998997',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike',
	'caption.alt.org.fedora' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike',
	'caption.alt.org.wikidata.until.date_20210809' =>
		'Creative Commons Attribution–NonCommercial-ShareAlike',
	'caption.alt.org.wikidata.since.date_20210809' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike',
	tags => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '[- ]'
		. $P{cc_nc} . '[- ]'
		. $P{cc_sa}
		. '|BY[- ]NC[- ]SA|'
		. $P{cc_url}
		. 'by-nc-sa))',
};

$RE{cc_by_nc_sa_1} = {
	name                                  => 'CC-BY-NC-SA-1.0',
	'name.alt.org.cc'                     => 'CC-BY-NC-SA-1.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-SA-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q47008954',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-ShareAlike 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-SA 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-ShareAlike 1.0 Generic (CC BY-NC-SA 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial Share Alike 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 1.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_sa_2} = {
	name                                  => 'CC-BY-NC-SA-2.0',
	'name.alt.org.cc.since.date_20040525' => 'CC-BY-NC-SA-2.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-SA-2.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q28050835',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-ShareAlike 2.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-SA 2.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-ShareAlike 2.0 Generic (CC BY-NC-SA 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_sa_2_5} = {
	name                                  => 'CC-BY-NC-SA-2.5',
	'name.alt.org.cc.since.date_20050600' => 'CC-BY-NC-SA-2.5',
	'name.alt.org.spdx'                   => 'CC-BY-NC-SA-2.5',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19068212',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-ShareAlike 2.5',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-SA 2.5',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-ShareAlike 2.5 Generic (CC BY-NC-SA 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 2.5',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_sa_3} = {
	name                                  => 'CC-BY-NC-SA-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-NC-SA-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-NC-SA-3.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q15643954',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-ShareAlike 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-SA 3.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial Share Alike 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 3.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'Creative Commons Attribution NonCommercial ShareAlike (CC-NC-SA)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_sa_4} = {
	name                                    => 'CC-BY-NC-SA-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-NC-SA-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-NC-SA-4.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q42553662',
	caption => 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NonCommercial-ShareAlike 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-NC-SA 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Non Commercial Share Alike 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Non Commercial Share Alike 4.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0',
};

=item * cc_by_nd

=item * cc_by_nd_1

I<Since v3.1.101.>

=item * cc_by_nd_2

I<Since v3.1.101.>

=item * cc_by_nd_2_5

I<Since v3.1.101.>

=item * cc_by_nd_3

I<Since v3.1.101.>

=item * cc_by_nd_4

I<Since v3.1.101.>

=cut

$RE{cc_by_nd} = {
	name                                  => 'CC-BY-ND',
	'name.alt.org.cc'                     => 'CC-BY-ND',
	'name.alt.org.fedora'                 => 'CC-BY-ND',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6999319',
	caption => 'Creative Commons Attribution-NoDerivatives',
	'caption.alt.org.cc.misc.abbrev' =>
		'Creative Commons Attribution-NoDerivs',
	'caption.alt.org.fedora'   => 'Creative Commons Attribution-NoDerivs',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivatives',
	tags => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '[- ]'
		. $P{cc_nd}
		. '|BY[- ]ND|'
		. $P{cc_url}
		. 'by-nd))',
};

$RE{cc_by_nd_1} = {
	name                                  => 'CC-BY-ND-1.0',
	'name.alt.org.cc'                     => 'CC-BY-ND-1.0',
	'name.alt.org.spdx'                   => 'CC-BY-ND-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q47008966',
	caption              => 'Creative Commons Attribution-NoDerivs 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivs 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NoDerivs 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivs 1.0 Generic (CC BY-ND 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution No Derivatives 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution No Derivatives 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution No Derivatives 1.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivs 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nd/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nd_2} = {
	name                                  => 'CC-BY-ND-2.0',
	'name.alt.org.cc.since.date_20040525' => 'CC-BY-ND-2.0',
	'name.alt.org.spdx'                   => 'CC-BY-ND-2.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q35254645',
	caption              => 'Creative Commons Attribution-NoDerivs 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivs 2.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NoDerivs 2.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND 2.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivs 2.0 Generic (CC BY-ND 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution No Derivatives 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution No Derivatives 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution No Derivatives 2.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivs 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nd/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nd_2_5} = {
	name                                  => 'CC-BY-ND-2.5',
	'name.alt.org.cc.since.date_20050600' => 'CC-BY-ND-2.5',
	'name.alt.org.spdx'                   => 'CC-BY-ND-2.5',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18810338',
	caption              => 'Creative Commons Attribution-NoDerivs 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivs 2.5 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-NoDerivs 2.5',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND 2.5',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivs 2.5 Generic (CC BY-ND 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution No Derivatives 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution No Derivatives 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution No Derivatives 2.5',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivs 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by-nd/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nd_3} = {
	name                                  => 'CC-BY-ND-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-ND-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-ND-3.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18810160',
	caption              => 'Creative Commons Attribution-NoDerivs 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivs 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution-NoDerivs 3.0 International License',
	'caption.alt.org.cc.misc.legal' => 'Attribution-NoDerivs 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND 3.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivs 3.0 Unported (CC BY-ND 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution No Derivatives 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution No Derivatives 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution No Derivatives 3.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'Creative Commons Attribution NoDerivs (CC-ND)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivs 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nd/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nd_4} = {
	name                                    => 'CC-BY-ND-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-ND-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-ND-4.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q36795408',
	caption              => 'Creative Commons Attribution-NoDerivatives 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-NoDerivatives 4.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-NoDerivatives 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-ND 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution No Derivatives 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution No Derivatives 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution No Derivatives 4.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-NoDerivs 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-nd/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution-NoDerivatives 4.0',
};

=item * cc_by_sa

=item * cc_by_sa_1

I<Since v3.1.101.>

=item * cc_by_sa_2

I<Since v3.1.101.>

=item * cc_by_sa_2_5

I<Since v3.1.101.>

=item * cc_by_sa_3

I<Since v3.1.101.>

=item * cc_by_sa_4

I<Since v3.1.101.>

=cut

$RE{cc_by_sa} = {
	name                                  => 'CC-BY-SA',
	'name.alt.org.cc'                     => 'CC-BY-SA',
	'name.alt.org.fedora'                 => 'CC-BY-SA',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6905942',
	'name.alt.misc.fossology_old'         => 'CCA_SA',
	caption => 'Creative Commons Attribution-ShareAlike',
	tags    => [
		'family:cc:standard',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '[- ]'
		. $P{cc_sa}
		. '|BY[- ]SA|'
		. $P{cc_url}
		. 'by-sa))',
};

$RE{cc_by_sa_1} = {
	name                                  => 'CC-BY-SA-1.0',
	'name.alt.org.cc'                     => 'CC-BY-SA-1.0',
	'name.alt.org.spdx'                   => 'CC-BY-SA-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q47001652',
	'name.alt.misc.fossology_old'         => 'CCA_SA_v1.0',
	'name.alt.misc.fossology_old_short'   => 'CCA_SA1.0',
	caption              => 'Creative Commons Attribution-ShareAlike 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-ShareAlike 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-SA 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-ShareAlike 1.0 Generic (CC BY-SA 1.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Share Alike 1.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Share Alike 1.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Share Alike 1.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-ShareAlike 1.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-sa/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '1.0',
};

$RE{cc_by_sa_2} = {
	name                                  => 'CC-BY-SA-2.0',
	'name.alt.org.cc.since.date_20040525' => 'CC-BY-SA-2.0',
	'name.alt.org.spdx'                   => 'CC-BY-SA-2.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19068220',
	caption              => 'Creative Commons Attribution-ShareAlike 2.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-ShareAlike 2.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-ShareAlike 2.0',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-SA 2.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-ShareAlike 2.0 Generic (CC BY-SA 2.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Share Alike 2.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Share Alike 2.0 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Share Alike 2.0',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-ShareAlike 2.0 Generic',
	iri  => 'https://creativecommons.org/licenses/by-sa/2.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '2.0',
};

$RE{cc_by_sa_2_5} = {
	name                                  => 'CC-BY-SA-2.5',
	'name.alt.org.cc.since.date_20050600' => 'CC-BY-SA-2.5',
	'name.alt.org.spdx'                   => 'CC-BY-SA-2.5',
	'name.alt.org.wikidata.synth.nogrant' => 'Q19113751',
	'name.alt.misc.fossology_old'         => 'CCA_SA_v2.5',
	'name.alt.misc.fossology_old_short'   => 'CCA_SA2.5',
	caption              => 'Creative Commons Attribution-ShareAlike 2.5',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-ShareAlike 2.5 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'Attribution-ShareAlike 2.5',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-SA 2.5',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-ShareAlike 2.5 Generic (CC BY-SA 2.5)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Share Alike 2.5',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Share Alike 2.5 Generic',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Share Alike 2.5',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-ShareAlike 2.5 Generic',
	iri  => 'https://creativecommons.org/licenses/by-sa/2.5/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '2.5',
};

$RE{cc_by_sa_3} = {
	name                                  => 'CC-BY-SA-3.0',
	'name.alt.org.cc.since.date_20070223' => 'CC-BY-SA-3.0',
	'name.alt.org.spdx'                   => 'CC-BY-SA-3.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q14946043',
	'name.alt.misc.fossology_old'         => 'CCA_SA_v3.0',
	'name.alt.misc.fossology_old_short'   => 'CCA_SA3.0',
	caption              => 'Creative Commons Attribution-ShareAlike 3.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-ShareAlike 3.0 Unported License',
	'caption.alt.org.cc.misc.modern' =>
		'Creative Commons Attribution-ShareAlike 3.0 International License',
	'caption.alt.org.cc.misc.legal' => 'Attribution-ShareAlike 3.0 Unported',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-SA 3.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Share Alike 3.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Share Alike 3.0 Unported',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Share Alike 3.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'Creative Commons Attribution Share Alike (CC-SA)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-ShareAlike 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-sa/3.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '3.0',
};

$RE{cc_by_sa_4} = {
	name                                    => 'CC-BY-SA-4.0',
	'name.alt.org.cc.since.date_20131125'   => 'CC-BY-SA-4.0',
	'name.alt.org.spdx.since.date_20140807' => 'CC-BY-SA-4.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q18199165',
	caption              => 'Creative Commons Attribution-ShareAlike 4.0',
	'caption.alt.org.cc' =>
		'Creative Commons Attribution-ShareAlike 4.0 International License',
	'caption.alt.org.cc.misc.legal' =>
		'Attribution-ShareAlike 4.0 International',
	'caption.alt.org.cc.misc.shortname' => 'CC BY-SA 4.0',
	'caption.alt.org.cc.misc.deed'      =>
		'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
	'caption.alt.org.spdx.until.date_20150513' =>
		'Creative Commons Attribution Share Alike 4.0',
	'caption.alt.org.spdx.since.date_20150513.until.date_20150730' =>
		'Creative Commons Attribution Share Alike 4.0 International',
	'caption.alt.org.spdx.since.date_20150730' =>
		'Creative Commons Attribution Share Alike 4.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
	'caption.alt.org.wikidata' =>
		'Creative Commons Attribution-ShareAlike 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-sa/4.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '4.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		$cc_by_exercising_you_accept_this
		. 'Creative Commons Attribution-ShareAlike 4.0',
};

=item * cc_cc0

=item * cc_cc0_1

I<Since v3.1.101.>

=cut

$RE{cc_cc0} = {
	name                                  => 'CC0',
	'name.alt.org.cc'                     => 'CC0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6938433',
	caption                               => 'Creative Commons CC0',
	'caption.alt.org.fedora'   => 'Creative Commons Zero 1.0 Universal',
	'caption.alt.org.wikidata' => 'CC0',
	'caption.alt.misc.zero'    => 'Creative Commons Zero',
	'iri.alt.org.wikipedia'    =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	tags => [
		'family:cc:zero',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_cc0}
		. '(?: [(]?["]?CC0["]?[)]?)?|CC0|'
		. $P{cc_url_pd}
		. 'zero))',
	'pat.alt.subject.grant' =>
		'has waived all copyright and related or neighboring rights',
};

$RE{cc_cc0_1} = {
	name                            => 'CC0-1.0',
	'name.alt.org.cc'               => 'CC0-1.0',
	'name.alt.org.spdx'             => 'CC0-1.0',
	'name.alt.org.tldr'             => 'creative-commons-cc0-1.0-universal',
	'name.alt.org.tldr.path.short'  => 'cc0-1.0',
	caption                         => 'Creative Commons CC0 1.0',
	'caption.alt.org.cc.misc.legal' => 'CC0 1.0 Universal',
	'caption.alt.org.cc.misc.shortname' => 'CC0 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication',
	'caption.alt.org.spdx'  => 'Creative Commons Zero v1.0 Universal',
	'caption.alt.org.tldr'  => 'Creative Commons CC0 1.0 Universal (CC-0)',
	'caption.alt.org.trove' => 'CC0 1.0 Universal (CC0 1.0)',
	'caption.alt.org.trove.misc.short' => 'CC0 1.0',
	iri => 'https://creativecommons.org/publicdomain/zero/1.0/',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	tags => [
		'family:cc:zero',
		'type:singleversion:cc_cc0',
	],
	licenseversion => '1.0',

	'pat.alt.subject.grant' =>
		'has waived all copyright and related or neighboring rights',
};

=item * cc_devnations

I<Since v3.7.0.>

=item * cc_devnations_2

I<Since v3.7.0.>

=cut

$RE{cc_devnations} = {
	name                                  => 'CC-DevNations',
	'name.alt.org.cc.until.date_20070604' => 'CC-DevNations',
	caption => 'Creative Commons Developing Nations',
	tags    => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_devnations_2} = {
	name => 'CC-DevNations-2.0',
	'name.alt.org.cc.since.date_20040913.until.date_20070604' =>
		'CC-DevNations-2.0',
	caption => 'Creative Commons Developing Nations 2.0',
	'caption.alt.org.cc.synth.nogrant' => 'Developing Nations License',
	'caption.alt.org.cc.misc.legal'    => 'Developing Nations 2.0',
	iri         => 'https://creativecommons.org/licenses/devnations/2.0/',
	description => <<'END',
Release: <https://creativecommons.org/2004/09/13/developingnationslicenselaunched/>

Expiry: <https://creativecommons.org/2007/06/04/retiring-standalone-devnations-and-one-sampling-license/>
END
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_devnations',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence.part.definition_c' =>
		'["]Developing Nation["] means any nation that is not classified',
};

=item * cc_nc

I<Since v3.1.101.>

=item * cc_nc_1

I<Since v3.1.101.>

=cut

$RE{cc_nc} = {
	name                                  => 'CC-NC',
	'name.alt.org.cc.until.date_20040525' => 'CC-NC',
	'name.alt.org.wikidata.synth.nogrant' => 'Q65071627',
	caption                               => 'Creative Commons NonCommercial',
	tags                                  => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_nc_1} = {
	name                                  => 'CC-NC-1.0',
	'name.alt.org.cc.until.date_20040525' => 'CC-NC-1.0',
	caption              => 'Creative Commons NonCommercial 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'NonCommercial 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC NC 1.0',
	'caption.alt.org.cc.misc.deed' => 'NonCommercial 1.0 Generic (CC NC 1.0)',
	iri  => 'https://creativecommons.org/licenses/nc/1.0/',
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_nc',
	],
	licenseversion => '1.0',
};

=item * cc_nc_sa

I<Since v3.7.0.>

=item * cc_nc_sa_1

I<Since v3.7.0.>

=cut

$RE{cc_nc_sa} = {
	name                                  => 'CC-NC-SA',
	'name.alt.org.cc.until.date_20040525' => 'CC-NC-SA',
	caption => 'Creative Commons NonCommercial-ShareAlike',
	tags    => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_nc_sa_1} = {
	name                                  => 'CC-NC-SA-1.0',
	'name.alt.org.cc.until.date_20040525' => 'CC-NC-SA-1.0',
	caption              => 'Creative Commons NonCommercial-ShareAlike 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons NonCommercial-ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'NonCommercial-ShareAlike 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC NC-SA 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'NonCommercial-ShareAlike 1.0 Generic (CC NC-SA 1.0)',
	iri         => 'https://creativecommons.org/licenses/nc-sa/1.0/',
	description => <<'END',
Expiry: <https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>
END
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_nc_sa',
	],
	licenseversion => '1.0',
};

=item * cc_nc_sp

I<Since v3.7.0.>

=item * cc_nc_sp_1

I<Since v3.7.0.>

=cut

$RE{cc_nc_sp} = {
	name                                                      => 'CC-NC-SP',
	'name.alt.org.cc.since.date_20041112.until.date_20110912' =>
		'CC-NC-Sampling+',
	caption => 'Creative Commons NonCommercial Sampling Plus',
	tags    => [
		'family:cc:recombo',
		'type:versioned:decimal',
	],
};

$RE{cc_nc_sp_1} = {
	name => 'CC-NC-SP-1.0',
	'name.alt.org.cc.since.date_20041112.until.date_20110912' =>
		'CC-NC-Sampling+-1.0',
	caption => 'Creative Commons NonCommercial Sampling Plus 1.0',
	'caption.alt.org.cc'                => 'NonCommercial Sampling Plus 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC NC-Sampling+ 1.0',
	iri         => 'https://creativecommons.org/licenses/nc-sampling+/1.0/',
	description => <<'END',
Release: <https://web.archive.org/web/20130403002648/http://creativecommons.org/wired/>

Expiry: <https://creativecommons.org/2011/09/12/celebrating-freesound-2-0-retiring-sampling-licenses/>
END
	tags => [
		'family:cc:recombo',
		'type:singleversion:cc_nc_sp',
	],
	licenseversion => '1.0',
};

=item * cc_nd_nc

I<Since v3.7.0.>

=item * cc_nd_nc_1

I<Since v3.7.0.>

=cut

$RE{cc_nd_nc} = {
	name                                  => 'CC-ND-NC',
	'name.alt.org.cc.until.date_20040525' => 'CC-ND-NC',
	caption => 'Creative Commons NoDerivs-NonCommercial',
	'caption.alt.org.cc.misc.long' =>
		'Creative Commons NoDerivatives-NonCommercial',
	'caption.alt.org.cc.misc.flipped' =>
		'Creative Commons NonCommercial-NoDerivs',
	tags => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_nd_nc_1} = {
	name                                  => 'CC-ND-NC-1.0',
	'name.alt.org.cc.until.date_20040525' => 'CC-ND-NC-1.0',
	caption              => 'Creative Commons NoDerivs-NonCommercial 1.0',
	'caption.alt.org.cc' =>
		'Creative Commons NoDerivs-NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'NoDerivs-NonCommercial 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC ND-NC 1.0',
	'caption.alt.org.cc.misc.deed'      =>
		'NoDerivs-NonCommercial 1.0 Generic (CC ND-NC 1.0)',
	iri         => 'https://creativecommons.org/licenses/nd-nc/1.0/',
	description => <<'END',
Expiry: <https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>
END
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_nd_nc',
	],
	licenseversion => '1.0',
};

=item * cc_nd

I<Since v3.1.101.>

=item * cc_nd_1

I<Since v3.1.101.>

=cut

$RE{cc_nd} = {
	name                                  => 'CC-ND',
	'name.alt.org.cc.until.date_20040525' => 'CC-ND',
	caption                               => 'Creative Commons NoDerivs',
	'caption.alt.org.cc.misc.long'        => 'Creative Commons NoDerivatives',
	tags                                  => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_nd_1} = {
	name                                  => 'CC-ND-1.0',
	'name.alt.org.cc.until.date_20040525' => 'CC-ND-1.0',
	caption                               => 'Creative Commons NoDerivs 1.0',
	'caption.alt.org.cc' => 'Creative Commons NoDerivs 1.0 Generic License',
	'caption.alt.org.cc.misc.legal'     => 'NoDerivs 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC ND 1.0',
	'caption.alt.org.cc.misc.deed'      => 'NoDerivs 1.0 Generic (CC ND 1.0)',
	iri         => 'https://creativecommons.org/licenses/nd/1.0/',
	description => <<'END',
Expiry: <https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>
END
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_nd',
	],
	licenseversion => '1.0',
};

=item * cc_pd

I<Since v3.7.0.>

=item * cc_pdd

I<Since v3.7.0.>

=item * cc_pddc

I<Since v3.7.0.>

=cut

$RE{cc_pd} = {
	name                                  => 'CC-PD',
	'name.alt.org.cc.until.date_20101011' => 'CC-PD',
	caption                               => 'Creative Commons Public Domain',
	description                           => <<'END',
Casual name
for either "Public Domain Dedication and Certification"
or its predecessor "Public Domain Dedication".
END
	iri  => 'https://creativecommons.org/licenses/publicdomain/',
	tags => [
		'family:cc:publicdomain',
		'type:unversioned',
	],
};

$RE{cc_pdd} = {
	name                                  => 'CC-PDD',
	'name.alt.org.cc.until.date_20040525' => 'CC-PDD',
	caption => 'Creative Commons Public Domain Dedication',
	'caption.alt.org.cc.misc.deed' =>
		'Creative Commons Copyright-Only Dedication (based on United States law)',
	'iri.alt.archive.time_20040202011504' =>
		'https://creativecommons.org/licenses/publicdomain/',
	description => <<'END',
Expiry: Possibly with revision 2.0 of the main licenses.
<https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>
END
	tags => [
		'family:cc:publicdomain',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The person or persons who have associated their work with this document',
};

$RE{cc_pddc} = {
	name                                                      => 'CC-PDDC',
	'name.alt.org.cc.since.date_20040525.until.date_20101011' => 'CC-PDDC',
	'name.alt.org.spdx.since.date_20190710'                   => 'CC-PDDC',
	caption => 'Creative Commons Public Domain Dedication and Certification',
	'caption.alt.org.cc.misc.long' =>
		'Creative Commons Copyright-Only Dedication (based on United States law) or Public Domain Certification',
	description => <<'END',
Expiry: Possibly with revision 2.0 of the main licenses.
<https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>

Expiry: <https://creativecommons.org/2010/10/11/improving-access-to-the-public-domain-the-public-domain-mark/>
END
	tags => [
		'family:cc:publicdomain',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The person or persons who have associated work with this document',
};

=item * cc_sa

I<Since v3.1.101.>

=item * cc_sa_1

I<Since v3.1.101.>

=cut

$RE{cc_sa} = {
	name                                  => 'CC-SA',
	'name.alt.org.cc.until.date_20040525' => 'CC-SA',
	caption                               => 'Creative Commons ShareAlike',
	tags                                  => [
		'family:cc:standard',
		'type:versioned:decimal',
	],
};

$RE{cc_sa_1} = {
	name                                  => 'CC-SA-1.0',
	'name.alt.org.cc.until.date_20040525' => 'CC-SA-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q75209430',
	caption              => 'Creative Commons ShareAlike 1.0',
	'caption.alt.org.cc' => 'Creative Commons ShareAlike 1.0 Generic License',
	'caption.alt.org.wikidata'          => 'Creative Commons ShareAlike 1.0',
	'caption.alt.org.cc.misc.legal'     => 'ShareAlike 1.0',
	'caption.alt.org.cc.misc.shortname' => 'CC SA 1.0',
	'caption.alt.org.cc.misc.deed' => 'ShareAlike 1.0 Generic (CC SA 1.0)',
	iri         => 'https://creativecommons.org/licenses/sa/1.0/',
	description => <<'END',
Expiry: <https://creativecommons.org/2004/05/25/announcingandexplainingournew20licenses/>
END
	tags => [
		'family:cc:standard',
		'type:singleversion:cc_sa',
	],
	licenseversion => '1.0',
};

=item * cc_sampling

I<Since v3.7.0.>

=item * cc_sampling_1

I<Since v3.7.0.>

=cut

$RE{cc_sampling} = {
	name => 'CC-Sampling',
	'name.alt.org.cc.since.date_20031216.until.date_20070604' =>
		'CC-Sampling',
	caption => 'Creative Commons Sampling',
	tags    => [
		'family:cc:recombo',
		'type:versioned:decimal',
	],
};

$RE{cc_sampling_1} = {
	name => 'CC-Sampling-1.0',
	'name.alt.org.cc.since.date_20031216.until.date_20070604' =>
		'CC-Sampling-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q100509915',
	caption                               => 'Creative Commons Sampling 1.0',
	'caption.alt.org.cc.synth.nogrant'    => 'Sampling 1.0',
	'caption.alt.org.wikidata'            => 'Sampling 1.0',
	iri         => 'https://creativecommons.org/licenses/sampling/1.0/',
	description => <<'END',
Release: <https://creativecommons.org/2003/10/20/samplinglicenses/>

Rebranding as recombo: <https://creativecommons.org/2004/06/04/recombobrazil/>

Use with recombo logo: <https://web.archive.org/web/20060514160705/http://creativecommons.org:80/license/results-one?lang=en&license_code=sampling&stylesheet=%2fincludes%2fccliss%2ecss&partner_icon_url=%2fimages%2fremote_logo%2egif>

Expiry: <https://creativecommons.org/2007/06/04/retiring-standalone-devnations-and-one-sampling-license/>
END
	tags => [
		'family:cc:recombo',
		'type:singleversion:cc_sampling',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.paragraph.part.part3a' =>
		'Re-creativity[. ]You may',
};

=item * cc_sp

=item * cc_sp_1

I<Since v3.7.0.>

=cut

$RE{cc_sp} = {
	name                                                      => 'CC-SP',
	'name.alt.org.cc.since.date_20031216.until.date_20110912' =>
		'CC-Sampling+',
	caption => 'Creative Commons Sampling Plus',
	tags    => [
		'family:cc:recombo',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_sp} . '|'
		. $P{cc_url}
		. 'sampling\+))',
};

$RE{cc_sp_1} = {
	name                                                      => 'CC-SP-1.0',
	'name.alt.org.cc.since.date_20031216.until.date_20110912' =>
		'CC-Sampling+-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q26913038',
	caption              => 'Creative Commons Sampling Plus 1.0',
	'caption.alt.org.cc' => 'Sampling Plus 1.0',
	'caption.alt.org.cc.misc.shortname.synth.nogrant' => 'CC Sampling+ 1.0',
	'caption.alt.org.fedora' => 'Creative Commons Sampling Plus 1.0',
	iri         => 'https://creativecommons.org/licenses/sampling+/1.0/',
	description => <<'END',
Release: <https://creativecommons.org/2003/10/20/samplinglicenses/>

Expiry: <https://creativecommons.org/2011/09/12/celebrating-freesound-2-0-retiring-sampling-licenses/>
END
	tags => [
		'family:cc:recombo',
		'type:singleversion:cc_sp',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part3a' =>
		'Re-creativity permitted',
};

=item * cddl

=item * cddl_1

I<Since v3.1.101.>

=item * cddl_1_1

I<Since v3.1.101.>

=cut

$RE{cddl} = {
	name                                  => 'CDDL',
	'name.alt.org.fedora.iri.self'        => 'CDDL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q304628',
	caption => 'Common Development and Distribution License',
	'caption.alt.org.wikipedia' =>
		'Common Development and Distribution License',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{cddl_1} = {
	name                  => 'CDDL-1.0',
	'name.alt.org.fedora' => 'CDDL-1.0',
	'name.alt.org.osi'    => 'CDDL-1.0',
	'name.alt.org.osi.iri.stem_plain.until.date_20110430.archive.time_20110426131805'
		=> 'cddl1',
	'name.alt.org.spdx'               => 'CDDL-1.0',
	'name.alt.org.tldr.synth.nogrant' =>
		'common-development-and-distribution-license-(cddl-1.0)-explained',
	'name.alt.org.tldr.path.short'        => 'cddl',
	'name.alt.org.wikidata.synth.nogrant' => 'Q26996811',
	'name.alt.misc.fossology_old'         => 'CDDL_v1.0',
	'name.alt.misc.fossology_old_short'   => 'CDDL1.0',
	caption => 'Common Development and Distribution License 1.0',
	'caption.alt.org.fedora' => 'Common Development Distribution License 1.0',
	'caption.alt.org.fedora.iri.cddl' => 'CDDL 1.0',
	'caption.alt.org.osi'             =>
		'Common Development and Distribution License 1.0',
	'caption.alt.org.tldr' =>
		'Common Development and Distribution License (CDDL-1.0)',
	'caption.alt.org.trove' =>
		'Common Development and Distribution License 1.0 (CDDL-1.0)',
	'caption.alt.org.wikidata' =>
		'Common Development and Distribution License version 1.0',
	tags => [
		'type:singleversion:cddl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Sun Microsystems, Inc[.] is the initial license steward',
};

$RE{cddl_1_1} = {
	name                                  => 'CDDL-1.1',
	'name.alt.org.fedora'                 => 'CDDL-1.1',
	'name.alt.org.spdx'                   => 'CDDL-1.1',
	'name.alt.org.wikidata.synth.nogrant' => 'Q26996804',
	caption => 'Common Development and Distribution License 1.1',
	'caption.alt.org.fedora' => 'Common Development Distribution License 1.1',
	'caption.alt.org.fedora.iri.cddl' => 'CDDL 1.1',
	'caption.alt.org.wikidata'        =>
		'Common Development and Distribution License version 1.1',
	tags => [
		'type:singleversion:cddl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		'Oracle is the initial license steward',
};

=item * cecill

=item * cecill_1

=item * cecill_1_1

=item * cecill_2

=item * cecill_2_1

=cut

$RE{cecill} = {
	name                                  => 'CECILL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1052189',
	'name.alt.misc.short_camelcase'       => 'CeCILL',
	caption                               => 'CeCILL License',
	'caption.alt.misc.last.lang.en'       =>
		'FREE SOFTWARE LICENSE AGREEMENT CeCILL',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL',
	'caption.alt.org.wikidata'  => 'CeCILL',
	'caption.alt.org.wikipedia' => 'CeCILL',
	'iri.alt.path.sloppy'       => 'http://www.cecill.info',
	tags                        => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name.lang.fr'  => '(?:la )?licence CeCILL',
	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'_pat.alt.subject.license.lang.en' => [
		'Version 1\.1 of 10[/]26[/]2004',
		'Version 2\.0 dated 2006[-]09[-]05',
		'Version 2\.1 dated 2013[-]06[-]21',
	],
	'_pat.alt.subject.license.lang.fr' => [
		'Version 1 du 21[/]06[/]2004',
		'Version 2\.0 du 2006[-]09[-]05',
		'Version 2\.1 du 2013[-]06[-]21',
	],
};

$RE{cecill_1} = {
	name                            => 'CECILL-1.0',
	'name.alt.org.spdx'             => 'CECILL-1.0',
	'name.alt.misc.fossology_old'   => 'CeCILL1.0',
	'name.alt.misc.short_camelcase' => 'CeCILL-1.0',
	caption => 'CeCILL Free Software License Agreement v1.0',
	'caption.alt.org.steward' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 1',
	'caption.alt.org.tldr' =>
		'CeCILL Free Software License Agreement v1.0 (CECILL-1.0)',
	'caption.alt.misc.short' => 'CeCILL License 1.0',
	iri => 'https://cecill.info/licences/Licence_CeCILL_V1-fr.html',
	'iri.alt.format.txt' =>
		'https://cecill.info/licences/Licence_CeCILL_V1-fr.txt',
	'iri.alt.format.pdf' =>
		'https://cecill.info/licences/Licence_CeCILL-V1_VF.pdf',
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.lang.fr' => 'Version 1 du 21[/]06[/]2004',
};

$RE{cecill_1_1} = {
	name                                => 'CECILL-1.1',
	'name.alt.org.fedora.synth.nogrant' => 'CeCILL',
	'name.alt.org.spdx'                 => 'CECILL-1.1',
	'name.alt.misc.fossology_old'       => 'CeCILL_v1.1',
	'name.alt.misc.fossology_old_short' => 'CeCILL1.1',
	'name.alt.misc.short_camelcase'     => 'CeCILL-1.1',
	caption                  => 'CeCILL Free Software License Agreement v1.1',
	'caption.alt.org.fedora' => 'CeCILL License v1.1',
	'caption.alt.org.steward' =>
		'FREE SOFTWARE LICENSING AGREEMENT CeCILL Version 1.1',
	'caption.alt.org.tldr' =>
		'CeCILL Free Software License Agreement v1.1 (CECILL-1.1)',
	'caption.alt.misc.short' => 'CeCILL License 1.1',
	iri => 'https://cecill.info/licences/Licence_CeCILL_V1.1-US.html',
	'iri.alt.format.txt' =>
		'https://cecill.info/licences/Licence_CeCILL_V1.1-US.txt',
	'iri.alt.format.pdf' =>
		'https://cecill.info/licences/Licence_CeCILL-V1.1-VA.pdf',
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.part.header' => 'Version 1\.1 of 10[/]26[/]2004',
	'pat.alt.subject.license.scope.sentence.part.part1_initial_sw_en' =>
		'for the first time '
		. 'under the terms and conditions of the Agreement',
	'pat.alt.subject.license.scope.sentence.part.part2_en' =>
		'Agreement is to grant users the right '
		. 'to modify and redistribute the software governed',
	'pat.alt.subject.license.scope.sentence.part.part5_3_en' =>
		'redistribute copies '
		. 'of the modified or unmodified Software to third parties ',
	'pat.alt.subject.license.scope.sentence.part.part5_3_2_en' =>
		'to all the provisions hereof',
	'pat.alt.subject.license.scope.sentence.part.part5_3_3_en' =>
		'may be distributed under a separate Licensing Agreement',
	'pat.alt.subject.license.part.part5_3_4_en' =>
		'is subject to the provisions of the GPL License',
	'pat.alt.subject.license.scope.sentence.part.part6_1_1_en' =>
		'compliance with the terms and conditions '
		. 'under which the Holder has elected to distribute its work '
		. 'and no one shall be entitled to and',
	'pat.alt.subject.license.scope.sentence.part.part6_1_2_en' =>
		'the Agreement, for the duration',
	'pat.alt.subject.license.scope.sentence.part.part7_2_en' =>
		'shall be subject to a separate',
	'pat.alt.subject.license.part.part8_1_en' =>
		'(?:Subject to the provisions of Article 8\.2, should'
		. '|subject to providing evidence of it)',
	'pat.alt.subject.license.scope.sentence.part.part10_2_en' =>
		'all licenses that it may have granted '
		. 'prior to termination of the Agreement '
		. 'shall remain valid subject to their',
	'pat.alt.subject.license.scope.sentence.part.part12_3_en' =>
		'Any or all Software distributed '
		. 'under a given version of the Agreement '
		. 'may only be subsequently distributed '
		. 'under the same version of the Agreement, '
		. 'or a subsequent version, '
		. 'subject to the provisions of article',
	'pat.alt.subject.license.scope.paragraph.part.part13_1_en' =>
		'The Agreement is governed by French law[. ]'
		. 'The Parties agree to endeavor to settle',
};

$RE{cecill_2} = {
	name                                  => 'CECILL-2.0',
	'name.alt.org.fedora.synth.nogrant'   => 'CeCILL',
	'name.alt.org.spdx'                   => 'CECILL-2.0',
	'name.alt.org.tldr'                   => 'cecill-v2',
	'name.alt.misc.fossology_old'         => 'CeCILL_v2.0',
	'name.alt.misc.fossology_old_short'   => 'CeCILL2.0',
	'name.alt.misc.fossology_old_shorter' => 'CeCILL_v2',
	'name.alt.misc.short_camelcase'       => 'CeCILL-2.0',
	caption                  => 'CeCILL Free Software License Agreement v2.0',
	'caption.alt.org.fedora' => 'CeCILL License v2',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL FREE SOFTWARE LICENSE AGREEMENT Version 2.0',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 2.0',
	'caption.alt.org.tldr' =>
		'CeCILL Free Software License Agreement v2.0 (CECILL-2.0)',
	'caption.alt.misc.short' => 'CeCILL License 2.0',
	'iri.alt.lang.en'        =>
		'https://cecill.info/licences/Licence_CeCILL_V2-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL_V2-fr.html',
	'iri.alt.format.txt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL_V2-en.txt',
	'iri.alt.format.txt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL_V2-fr.txt',
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.lang.en'  => 'Version 2\.0 dated 2006[-]09[-]05',
	'pat.alt.subject.license.lang.fr'  => 'Version 2\.0 du 2006[-]09[-]05',
	'pat.alt.subject.license.part.gpl' =>
		'subject to the provisions of one of the versions of the GNU GPL, and',
};

$RE{cecill_2_1} = {
	name                                    => 'CECILL-2.1',
	'name.alt.org.osi'                      => 'CECILL-2.1',
	'name.alt.org.spdx.since.date_20150930' => 'CECILL-2.1',
	'name.alt.org.trove'                    => 'CeCILL-2.1',
	caption => 'CeCILL Free Software License Agreement v2.1',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL FREE SOFTWARE LICENSE AGREEMENT Version 2.1',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL Version 2.1',
	'caption.alt.org.osi' =>
		'Cea Cnrs Inria Logiciel Libre License, version 2.1',
	'caption.alt.org.osi.misc.list' => 'CeCILL License 2.1',
	'caption.alt.org.trove'         =>
		'CEA CNRS Inria Logiciel Libre License, version 2.1 (CeCILL-2.1)',
	'iri.alt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-fr.html',
	'iri.alt.format.txt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-en.txt',
	'iri.alt.format.txt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL_V2.1-fr.txt',
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '2.1',

	'pat.alt.subject.grant.lang.en' => 'governed by the CeCILL  ?license',
	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'pat.alt.subject.license.lang.en'  => 'Version 2\.1 dated 2013[-]06[-]21',
	'pat.alt.subject.license.lang.fr'  => 'Version 2\.1 du 2013[-]06[-]21',
	'pat.alt.subject.license.part.gpl' =>
		'subject to the provisions of one of the versions of the GNU GPL, GNU',
};

=item * cecill_b

=item * cecill_b_1

I<Since v3.1.95.>

=cut

$RE{cecill_b} = {
	name                              => 'CECILL-B',
	'name.alt.org.fedora'             => 'CeCILL-B',
	'name.alt.misc.short_camelcase'   => 'CeCILL-B',
	caption                           => 'CeCILL-B License',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL-B FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-B',
	'caption.alt.org.trove' =>
		'CeCILL-B Free Software License Agreement (CECILL-B)',
	'iri.alt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.format.txt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.txt',
	'iri.alt.format.txt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-fr.txt',
	tags => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license.lang.en' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license.lang.fr' =>
		'aux utilisateurs une tr[è]s large libert[é] de',
};

$RE{cecill_b_1} = {
	name                              => 'CECILL-B-1.0',
	'name.alt.misc.short_camelcase'   => 'CeCILL-B-1.0',
	'name.alt.org.spdx.synth.nogrant' => 'CECILL-B',
	caption => 'CeCILL-B Free Software License Agreement v1.0',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL-B FREE SOFTWARE LICENSE AGREEMENT Version 1.0',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-B Version 1.0',
	'caption.alt.org.spdx.synth.nogrant' =>
		'CeCILL-B Free Software License Agreement',
	'caption.alt.misc.short' => 'CeCILL-B License 1.0',
	'iri.alt.lang.en'        =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	'iri.alt.format.txt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-en.txt',
	'iri.alt.format.txt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-B_V1-fr.txt',
	tags => [
		'type:singleversion:cecill_b',
	],
	licenseversion => '1.0',

	'pat.alt.subject.grant.lang.en' => 'governed by the CeCILL-B license',
	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license.lang.en' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license.lang.fr' =>
		'aux utilisateurs une tr[è]s large libert[é] de',
};

=item * cecill_c

=item * cecill_c_1

I<Since v3.1.95.>

=cut

# TODO: synthesize patterns (except name) from cecill_c_1: they are all duplicates
$RE{cecill_c} = {
	name                              => 'CECILL-C',
	'name.alt.org.fedora'             => 'CeCILL-C',
	'name.alt.misc.short_camelcase'   => 'CeCILL-C',
	caption                           => 'CeCILL-C License',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL-C FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-C',
	'caption.alt.org.trove' =>
		'CeCILL-C Free Software License Agreement (CECILL-C)',
	'iri.alt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.html',
	tags => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license.lang.en' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license.lang.fr' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license.lang.en' => 'the Software modified or not;[  ]'
		. '[*)]to ensure that use of',
	'pat.alt.subject.license.lang.fr' => 'Logiciel modifi[é] ou non;[  ]'
		. '[*)][à] faire en sorte que',
};

$RE{cecill_c_1} = {
	name                              => 'CECILL-C-1.0',
	'name.alt.org.spdx.synth.nogrant' => 'CECILL-C',
	'name.alt.misc.short_camelcase'   => 'CeCILL-C-1.0',
	caption => 'CeCILL-C Free Software License Agreement v1.0',
	'caption.alt.org.steward.lang.en' =>
		'CeCILL-C FREE SOFTWARE LICENSE AGREEMENT Version 1.0',
	'caption.alt.org.steward.lang.fr' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL-C Version 1.0',
	'caption.alt.org.spdx.synth.nogrant' =>
		'CeCILL-C Free Software License Agreement',
	'caption.alt.misc.short' => 'CeCILL-C License 1.0',
	'iri.alt.lang.en'        =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-en.html',
	'iri.alt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.html',
	'iri.alt.format.txt.lang.en' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-en.txt',
	'iri.alt.format.txt.lang.fr' =>
		'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.txt',
	tags => [
		'type:singleversion:cecill_c',
	],
	licenseversion => '1.0',

	'_pat.alt.subject.grant.lang.en' => [
		'under the terms of the CeCILL-C license',
		'governed by the CeCILL-C license',
	],
	'pat.alt.subject.grant.lang.fr' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license.lang.en' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license.lang.fr' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license.scope.all.lang.en' =>
		'the Software modified or not;[  ]' . '[*)]to ensure that use of',
	'pat.alt.subject.license.scope.all.lang.fr' =>
		'Logiciel modifi[é] ou non;[  ]' . '[*)][à] faire en sorte que',
};

=item * cnri_jython

=cut

$RE{cnri_jython} = {
	name                                    => 'CNRI-Jython',
	'name.alt.org.fedora'                   => 'JPython',
	'name.alt.org.spdx.since.date_20150730' => 'CNRI-Jython',
	caption                                 => 'CNRI Jython License',
	'caption.alt.org.fedora'                => 'JPython License (old)',
	'caption.alt.org.tldr'                  => 'CNRI Jython License',
	'caption.alt.org.steward'               => 'JPython License',
	iri => 'http://www.jython.org/license.html',

	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'[*)]CNRI is making the Software available to Licensee',
};

=item * cnri_python

=cut

$RE{cnri_python} = {
	name                                            => 'CNRI-Python',
	'name.alt.org.fedora'                           => 'CNRI',
	'name.alt.org.osi'                              => 'CNRI-Python',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'pythonpl',
	'name.alt.org.spdx'                             => 'CNRI-Python',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38365646',
	caption                                         => 'CNRI Python License',
	'caption.alt.org.fedora'             => 'CNRI License (Old Python)',
	'caption.alt.org.osi'                => 'CNRI Python license',
	'caption.alt.org.osi.misc.shortname' => 'CNRI portion of Python License',
	'caption.alt.org.tldr'     => 'CNRI Python License (CNRI-Python)',
	'caption.alt.org.wikidata' =>
		'CNRI portion of the multi-part Python License',
	'caption.alt.org.wikipedia' => 'Python License',
	'summary.alt.org.osi'       =>
		'The CNRI portion of the multi-part Python License',
	iri =>
		'https://docs.python.org/3/license.html#cnri-license-agreement-for-python-1-6-1',
	'iri.alt.misc.handle' => 'http://hdl.handle.net/1895.22/1011',

	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'[*)]CNRI is making Python 1\.6(?:b1)? available to Licensee',
};

=item * cnri_python_gpl_compat

=cut

$RE{cnri_python_gpl_compat} = {
	name                => 'CNRI-Python-GPL-Compatible',
	'name.alt.org.spdx' => 'CNRI-Python-GPL-Compatible',
	caption => 'CNRI Python Open Source GPL Compatible License Agreement',
	iri     => 'http://www.python.org/download/releases/1.6.1/download_win/',
	'iri.alt.misc.handle' => 'http://hdl.handle.net/1895.22/1013',

	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.part.part4' =>
		'[*)]CNRI is making Python 1\.6\.1 available to Licensee',
	'pat.alt.subject.license.scope.sentence.part.part7' =>
		'with regard to derivative works based on Python 1\.6\.1 '
		. 'that incorporate non-separable material '
		. 'that was previously distributed under the GNU General Public License',
};

=item * condor

I<Since v3.8.0.>

=item * condor_1_1

I<Since v3.8.0.>

=cut

$RE{condor} = {
	name                   => 'Condor',
	'name.alt.org.fedora'  => 'Condor',
	caption                => 'Condor Public License',
	'caption.alt.org.tldr' => 'Condor Public License v1.1 (Condor-1.1)',
	tags                   => [
		'type:versioned:decimal',
	],
};

$RE{condor_1_1} = {
	name                                    => 'Condor-1.1',
	'name.alt.org.spdx.since.date_20130117' => 'Condor-1.1',
	caption                                 => 'Condor Public License v1.1',
	tags                                    => [
		'type:singleversion:condor',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause5' =>
		'To the extent that patent claims licensable by',
};

=item * cpal

=item * cpal_1

=cut

$RE{cpal} = {
	name                                  => 'CPAL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1116195',
	caption => 'Common Public Attribution License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cpal_1} = {
	name                                            => 'CPAL-1.0',
	'name.alt.org.fedora.synth.nogrant'             => 'CPAL',
	'name.alt.org.osi'                              => 'CPAL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'cpal_1.0',
	'name.alt.org.spdx'                             => 'CPAL-1.0',
	'name.alt.misc.fossology_old'                   => 'CPAL_v1.0',
	caption                  => 'Common Public Attribution License 1.0',
	'caption.alt.org.fedora' => 'CPAL License 1.0',
	'caption.alt.org.osi' => 'Common Public Attribution License Version 1.0',
	'caption.alt.org.osi.misc.list' =>
		'Common Public Attribution License 1.0',
	'caption.alt.org.tldr' =>
		'Common Public Attribution License Version 1.0 (CPAL-1.0)',
	'caption.alt.misc.fossology_old_short' => 'CPAL 1.0',
	tags                                   => [
		'type:singleversion:cpal',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Common Public Attribution License Version 1\.0 [(]CPAL[)][  ]'
		. '[*)]["]?Definitions["]?',
};

=item * cpl

I<Since v3.1.101.>

=item * cpl_1

I<Since v3.1.101.>

=cut

$RE{cpl} = {
	name                                   => 'CPL',
	'name.alt.org.fedora'                  => 'CPL',
	'name.alt.org.wikidata.synth.nogrant'  => 'Q2477807',
	'name.alt.misc.fossology_old'          => 'CPL_v1.0',
	caption                                => 'Common Public License',
	'caption.alt.org.trove'                => 'Common Public License',
	'caption.alt.org.wikipedia'            => 'Common Public License',
	'caption.alt.misc.fossology_old_short' => 'CPL 1.0',
	description                            => <<'END',
Origin: IBM Public License (IPL)
END
	tags => [
		'type:versioned:decimal',
	],
};

$RE{cpl_1} = {
	name                  => 'CPL-1.0',
	'name.alt.org.osi'    => 'CPL-1.0',
	'name.alt.org.spdx'   => 'CPL-1.0',
	caption               => 'Common Public License 1.0',
	'caption.alt.org.osi' => 'Common Public License, version 1.0',
	'name.alt.org.osi.iri.stem_plain.until.date_20110430.archive.time_20110426131805'
		=> 'cpl1.0',
	'caption.alt.org.osi.misc.list' => 'Common Public License 1.0',
	'caption.alt.org.tldr'          => 'Common Public License 1.0 (CPL-1.0)',
	'caption.alt.misc.legal'        => 'Common Public License Version 1.0',
	iri  => 'https://www.ibm.com/developerworks/library/os-cpl.html',
	tags => [
		'type:singleversion:cpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'IBM is the initial Agreement Steward',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Common Public License Version 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS COMMON PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. 'ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[\']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])'
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial code',
};

=item * cpol

=item * cpol_1_02

=cut

$RE{cpol} = {
	name                                  => 'CPOL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q5140041',
	caption                               => 'The Code Project Open License',
	'caption.alt.org.fedora'   => 'CodeProject Open License (CPOL)',
	'caption.alt.org.wikidata' => 'Code Project Open License',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{cpol_1_02} = {
	name                                    => 'CPOL-1.02',
	'name.alt.org.spdx.since.date_20130410' => 'CPOL-1.02',
	'name.alt.misc.fossology_old'           => 'CPOL1.2',
	caption                => 'Code Project Open License 1.02',
	'caption.alt.org.tldr' => 'The Code Project Open License (CPOL) 1.02',
	tags                   => [
		'type:singleversion:cpol',
	],
	licenseversion => '1.02',

	'pat.alt.subject.license' => 'This License governs Your use of the Work',
};

=item * crossword

I<Since v3.8.0.>

=cut

$RE{crossword} = {
	name                                    => 'Crossword',
	'name.alt.org.fedora.iri.self'          => 'Crossword',
	'name.alt.org.spdx.since.date_20140807' => 'Crossword',
	caption                                 => 'Crossword License',
	'caption.alt.org.tldr'                  => 'Crossword License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'No author or distributor  accepts responsibility to anyone for the consequences of using it',
};

=item * cryptix

=cut

$RE{cryptix} = {
	name                                  => 'Cryptix',
	'name.alt.org.fsf'                    => 'CryptixGeneralLicense',
	'name.alt.org.wikidata.synth.nogrant' => 'Q5190781',
	caption                               => 'Cryptix Public License',
	'caption.alt.org.fedora'              => 'Cryptix General License',
	'caption.alt.org.fsf'                 => 'Cryptix General License',
	'caption.alt.org.wikidata'            => 'Cryptix General License',
	'caption.alt.org.wikipedia'           => 'Cryptix General License',
	iri                                   => 'http://cryptix.org/LICENSE.TXT',
	description                           => <<'END',
Identical to BSD 2 Clause, except...
* Redistribution of source must retain any (not only "above") legal text
END
	tags => [
		'family:bsd',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{retain_notice_cond_discl_anywhere}
		. '[.][  ]'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. $P{asis_sw_by},
};

=item * cua_opl

=item * cua_opl_1

=cut

$RE{cua_opl} = {
	name                                  => 'CPAL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38365770',
	'name.alt.misc.fossology_old'         => 'CUA',
	caption                               => 'CUA Office Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{cua_opl_1} = {
	name                                            => 'CPAL-1.0',
	'name.alt.org.fedora.synth.nogrant'             => 'MPLv1.1',
	'name.alt.org.osi'                              => 'CUA-OPL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'cuaoffice',
	'name.alt.org.spdx'                             => 'CUA-OPL-1.0',
	'name.alt.misc.fossology_old'                   => 'CUA_v1.0',
	caption                  => 'CUA Office Public License v1.0',
	'caption.alt.org.fedora' => 'CUA Office Public License Version 1.0',
	'caption.alt.org.osi.synth.nogrant' => 'CUA Office Public License',
	'caption.alt.org.osi.misc.list'     =>
		'CUA Office Public License Version 1.0',
	'caption.alt.org.tldr' => 'CUA Office Public License v1.0 (CUA-OPL-1.0)',
	description            => <<'END',
Origin: Mozilla Public License Version 1.1
END
	tags => [
		'type:singleversion:cua_opl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'CUA Office Public Attribution License Version 1\.0[  ]'
		. '[*)]["]?Definitions["]?',
};

=item * cube

=cut

$RE{cube} = {
	name                                    => 'Cube',
	'name.alt.org.fedora.iri.self'          => 'Cube',
	'name.alt.org.spdx.since.date_20140807' => 'Cube',
	caption                                 => 'Cube License',
	'caption.alt.org.tldr'                  => 'Cube License',
	tags                                    => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote} . '[. ]'
		. $P{use_ack_apprec_not_req}
		. '[.][  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter_any}
		. '[.][  ]additional clause specific to Cube[:]?[ ]'
		. $P{src_no_relicense},
};

=item * curl

=cut

$RE{curl} = {
	'name.alt.org.spdx.since.date_20160103' => 'curl',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q33042394',
	caption                                 => 'curl License',
	'caption.alt.org.tldr'                  => 'curl License',
	'caption.alt.org.wikidata'              => 'curl license',
	tags                                    => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. '[.][  ]'
		. $P{asis_sw_warranty},
};

=item * cvw

I<Since v3.5.0.>

=cut

$RE{cvw} = {
	name                                            => 'CVW',
	'name.alt.org.osi'                              => 'CVW',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'mitrepl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38365796',
	caption => 'MITRE Collaborative Virtual Workspace License',
	'caption.alt.org.fedora' =>
		'MITRE Collaborative Virtual Workspace License (CVW)',
	'caption.alt.org.osi' =>
		'The MITRE Collaborative Virtual Workspace License',
	'caption.alt.org.trove' =>
		'MITRE Collaborative Virtual Workspace License (CVW)',
	'caption.alt.org.osi.misc.list' =>
		'MITRE Collaborative Virtual Workspace License',
	'caption.alt.org.wikidata' =>
		'The MITRE Collaborative Virtual Workspace License',
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Redistribution of the CVW software or derived works'
		. ' must reproduce MITRE[\']s copyright designation',
};

=item * d_fsl

I<Since v3.8.0.>

=item * d_fsl_1

I<Since v3.8.0.>

=cut

$RE{d_fsl} = {
	name    => 'D-FSL',
	caption => 'Deutsche Freie Software Lizenz',
	'caption.alt.misc.legal_grant.lang.de' =>
		'Deutschen Freien Software Lizenz',
	'caption.alt.misc.legal_grant.lang.en' => 'German Free Software License',
	'iri.alt.archive.time_20050208012625'  => 'http://www.d-fsl.de/',
	'iri.alt.lang.de'                      =>
		'https://www.hbz-nrw.de/produkte/open-access/lizenzen/dfsl/deutsche-freie-software-lizenz',
	'iri.alt.lang.en' =>
		'https://www.hbz-nrw.de/produkte/open-access/lizenzen/dfsl/german-free-software-license',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{d_fsl_1} = {
	name                                    => 'D-FSL-1.0',
	'name.alt.org.spdx.since.date_20130410' => 'D-FSL-1.0',
	caption => 'Deutsche Freie Software Lizenz 1.0',
	'caption.alt.org.spdx.since.date_20130410.synth.nogrant' =>
		'Deutsche Freie Software Lizenz',
	tags => [
		'type:singleversion:d_fsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.section0.lang.de'
		=> 'Die Beschreibung des Aufbaus und[/]oder der Struktur',
	'pat.alt.subject.license.scope.line.scope.sentence.part.section0.lang.en'
		=> 'Description of composition, architecture and[/]or structure',
};

=item * dbad

I<Since v3.8.0.>

=item * dbad_0_2

I<Since v3.8.0.>

=item * dbad_0_3

I<Since v3.8.0.>

=item * dbad_1

I<Since v3.8.0.>

=item * dbad_1_1

I<Since v3.8.0.>

=cut

# TODO: include translations at http://www.dbad-license.org/
$RE{dbad} = {
	name                       => 'DBAD',
	caption                    => 'DON\'T BE A DICK PUBLIC LICENSE',
	'caption.alt.misc.longer'  => 'The "Dont Be a Dick" Public License',
	'caption.alt.misc.shorter' => 'the DBAD license',
	'caption.alt.org.tldr'     => 'DON\'T BE A DICK PUBLIC LICENSE',
	iri                        => 'http://www.dbad-license.org/',
	tags                       => [
		'type:versioned:decimal',
	],

	'_pat.alt.subject.license.scope.line.scope.sentence' => [
		'For legal purposes, the DBAD license is a(?: strict)? superset',
		"Do whatever you like with the original work, just don[']t be a dick",
	],
};

$RE{dbad_0_2} = {
	name                                  => 'DBAD-0.2',
	caption                               => 'DBAD Public License v0.2',
	'iri.alt.archive.time_20110112205017' =>
		'http://dbad-license.org/license',
	tags => [
		'type:singleversion:dbad',
	],
	licenseversion => '0.2',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'For legal purposes, the DBAD license is a superset',
};

$RE{dbad_0_3} = {
	name                                  => 'DBAD-0.3',
	caption                               => 'DBAD Public License v0.3',
	'iri.alt.archive.time_20120322202702' =>
		'http://dbad-license.org/license',
	tags => [
		'type:singleversion:dbad',
	],
	licenseversion => '0.3',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'For legal purposes, the DBAD license is a strict superset',
};

$RE{dbad_1} = {
	name                                  => 'DBAD-1',
	caption                               => 'DBAD Public License v1.0',
	'caption.alt.org.tldr.synth.nogrant'  => 'DBAD Public License',
	'iri.alt.archive.time_20150618172510' => 'http://dbad-license.org/',
	tags                                  => [
		'type:singleversion:dbad',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.multisection' =>
		'Everyone is permitted'
		. ' to copy and distribute verbatim or modified copies of this license document'
		. ', and changing it is allowed as long as the name is changed'
		. '[.][  ]'
		. "[> ]DON[']T BE A DICK PUBLIC LICENSE"
		. '[ ][> ]TERMS AND CONDITIONS'
		. ' FOR COPYING, DISTRIBUTION AND MODIFICATION' . '[  ]'
		. '[*)]Do whatever you like with the original work, '
		. "just don[']t be a dick[.]",
};

$RE{dbad_1_1} = {
	name                                 => 'DBAD-1.1',
	caption                              => 'DBAD Public License v1.1',
	'caption.alt.org.tldr.synth.nogrant' => "DON'T BE A DICK PUBLIC LICENSE",
	tags                                 => [
		'type:singleversion:dbad',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.multisection' =>
		'Everyone is permitted '
		. 'to copy and distribute verbatim or modified copies of this license document'
		. '[.][  ]'
		. "[> ]DON[']T BE A DICK PUBLIC LICENSE"
		. '[ ][> ]TERMS AND CONDITIONS'
		. ' FOR COPYING, DISTRIBUTION AND MODIFICATION' . '[  ]'
		. '[*)]Do whatever you like with the original work, '
		. "just don[']t be a dick[.]",
};

=item * dont_ask

I<Since v3.8.0.>

=cut

$RE{dont_ask} = {
	name                   => 'Dont-Ask',
	caption                => "The Don't Ask Me About It License",
	'caption.alt.org.tldr' => "The Don't Ask Me About It License",
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Copying and distribution of this file, '
		. 'with or without modification, '
		. 'are permitted in any medium '
		. 'provided you do not contact the author '
		. 'about the file or any problems you are having with the file[.]',
};

=item * dsdp

=cut

$RE{dsdp} = {
	name                                    => 'DSDP',
	'name.alt.org.fedora.iri.self'          => 'DSDP',
	'name.alt.org.spdx.since.date_20140807' => 'DSDP',
	caption                                 => 'DSDP License',
	'caption.alt.org.tldr'                  => 'DSDP License',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, PetSC Variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.part1' =>
		'This program discloses material protectable',
	'pat.alt.subject.license.scope.paragraph' => $P{asis_expr_warranty}
		. '[. ]'
		. $P{perm_granted},
};

=item * ecl

=item * ecl_1

=item * ecl_2

=cut

$RE{ecl} = {
	name                                  => 'ECL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q5341236',
	caption                               => 'Educational Community License',
	'caption.alt.org.wikidata'            => 'Educational Community License',
	'caption.alt.misc.long' => 'Educational Community License (ECL)',
	tags                    => [
		'type:versioned:decimal',
	],
};

$RE{ecl_1} = {
	name                                            => 'ECL-1.0',
	'name.alt.org.osi'                              => 'ECL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20070704' => 'ecl1',
	'name.alt.org.spdx'                             => 'ECL-1.0',
	'name.alt.misc.fossology_old'                   => 'ECL1.0',
	caption                  => 'Educational Community License, Version 1.0',
	'caption.alt.org.fedora' => 'Educational Community License 1.0',
	'caption.alt.org.fedora.misc.short' => 'ECL 1.0',
	'caption.alt.org.osi'  => 'Educational Community License, Version 1.0',
	'caption.alt.org.spdx' => 'Educational Community License v1.0',
	tags                   => [
		'type:singleversion:ecl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Licensed under the Educational Community License version 1.0',
};

$RE{ecl_2} = {
	name                                            => 'ECL-2.0',
	'name.alt.org.osi'                              => 'ECL-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ecl2',
	'name.alt.org.spdx'                             => 'ECL-2.0',
	'name.alt.org.tldr.path.short'                  => 'ecl-2.0',
	'name.alt.misc.fossology_old'                   => 'ECL2.0',
	caption                  => 'Educational Community License, Version 2.0',
	'caption.alt.org.fedora' => 'Educational Community License 2.0',
	'caption.alt.org.fedora.misc.short' => 'ECL 2.0',
	'caption.alt.org.spdx' => 'Educational Community License v2.0',
	'caption.alt.org.tldr' =>
		'Educational Community License, Version 2.0 (ECL-2.0)',
	'caption.alt.misc.short' => 'ECLv2',
	tags                     => [
		'type:singleversion:ecl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence' =>
		'Licensed under the[ ]Educational Community License, Version 2\.0',
};

=item * ecos_1_1

I<Since v3.6.0.>

=cut

# Yes, it is unversioned
$RE{ecos_1_1} = {
	name                          => 'RHEPL',
	'name.alt.org.spdx'           => 'RHeCos-1.1',
	caption                       => 'Red Hat eCos Public License v1.1',
	'caption.alt.misc.ecos_2_ref' => 'Red Hat eCos Public License',
	'caption.alt.org.tldr' => 'Red Hat eCos Public License v1.1 (RHeCos-1.1)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence.part.section_1_13' =>
		'["]Red Hat Branded Code["] is code that Red Hat distributes',
};

=item * ecos_2

I<Since v3.6.0.>

=cut

# Yes, it is unversioned
$RE{ecos_2} = {
	name                                    => 'eCos-2.0',
	'name.alt.org.fedora.synth.nogrant'     => 'eCos',
	'name.alt.org.osi'                      => 'eCos-2.0',
	'name.alt.org.spdx.until.date_20150513' => 'eCos-2.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q26904555',
	caption                                 => 'eCos license version 2.0',
	'caption.alt.org.fedora'                => 'eCos License v2.0',
	'caption.alt.org.osi'                   => 'eCos License version 2.0',
	'caption.alt.org.wikidata'              => 'eCos-2.0',
	tags                                    => [
		'contains.grant.gpl_2',
		'contains.trait.except_ecos_2',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence.part.grant' =>
		'eCos is free software; '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU General Public License',
	'pat.alt.subject.license.scope.sentence.part.except_1' =>
		'if other files instantiate templates or use macros or inline functions from this file, '
		. 'or you compile this file and link it with other works',
	'pat.alt.subject.license.scope.line.scope.sentence.part.except_2' =>
		'However the source code for this file must still be made available',
	'pat.alt.subject.license.scope.line.scope.sentence.part.except_3' =>
		'This exception does not invalidate any other reasons why',
};

=item * efl

I<Since v3.6.0.>

=item * efl_1

I<Since v3.6.0.>

=item * efl_2

I<Since v3.6.0.>

=cut

$RE{efl} = {
	name                                  => 'EFL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q17011832',
	caption                               => 'Eiffel Forum License',
	'caption.alt.org.trove'               => 'Eiffel Forum License',
	'caption.alt.org.trove.misc.long'     => 'Eiffel Forum License (EFL)',
	'caption.alt.org.wikipedia'           => 'Eiffel Forum License',
	'iri.alt.old.osi' => 'https://opensource.org/licenses/eiffel.html',
	tags              => [
		'type:versioned:decimal',
	],
};

$RE{efl_1} = {
	name                                            => 'EFL-1',
	'name.alt.org.osi'                              => 'EFL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ver1_eiffel',
	'name.alt.org.spdx'                             => 'EFL-1.0',
	'name.alt.misc.fossology_old'                   => 'Eiffel_1.0',
	'name.alt.misc.fossology_old_short'             => 'Eiffel_v1',
	caption                           => 'Eiffel Forum License v1.0',
	'caption.alt.org.fedora'          => 'Eiffel Forum License 1.0',
	'caption.alt.org.fedora.iri.self' => 'Eiffel Forum License V1',
	'caption.alt.org.osi'           => 'The Eiffel Forum License, version 1',
	'caption.alt.org.osi.misc.list' => 'Eiffel Forum License V1.0',
	'caption.alt.org.osi.misc.do_not_use_list' =>
		'Eiffel Forum License, version 1.0',
	iri                  => 'http://www.opensource.org/licenses/eiffel.php',
	'iri.alt.format.txt' => 'http://www.eiffel-nice.org/license/forum.txt',
	tags                 => [
		'license:is:grant',
		'type:singleversion:efl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence.part.publish_clause' =>
		'you must publicly release the modified version of this package',
};

$RE{efl_2} = {
	name                                            => 'EFL-2',
	'name.alt.org.osi'                              => 'EFL-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ver2_eiffel',
	'name.alt.org.spdx'                             => 'EFL-2.0',
	'name.alt.misc.fossology_old'                   => 'Eiffel_2.0',
	'name.alt.misc.fossology_old_short'             => 'Eiffel_v2',
	caption                             => 'Eiffel Forum License v2.0',
	'caption.alt.org.fedora'            => 'Eiffel Forum License 2.0',
	'caption.alt.org.fedora.misc.short' => 'EFL 2.0',
	'caption.alt.org.osi'               => 'Eiffel Forum License, Version 2',
	'caption.alt.org.osi.misc.list'     => 'Eiffel Forum License V2.0',
	'caption.alt.org.tldr' => 'Eiffel Forum License v2.0 (EFL-2.0)',
	iri => 'http://www.eiffel-nice.org/license/eiffel-forum-license-2.html',
	'iri.alt.format.txt' =>
		'http://www.eiffel-nice.org/license/eiffel-forum-license-2.txt',
	tags => [
		'license:is:grant',
		'type:singleversion:efl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence.part.publish_clause' =>
		'you are encouraged to publicly release the modified version of this package',
};

=item * entessa

I<Since v3.6.0.>

=cut

$RE{entessa} = {
	name                                            => 'Entessa',
	'name.alt.org.fedora'                           => 'Entessa',
	'name.alt.org.osi'                              => 'Entessa',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'entessa',
	'name.alt.org.spdx'                             => 'Entessa',
	'name.alt.misc.fossology_old'                   => 'Entessa1.0',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38366115',
	caption                         => 'Entessa Public License v1.0',
	'caption.alt.org.fedora'        => 'Entessa Public License',
	'caption.alt.org.osi'           => 'Entessa Public License Version. 1.0',
	'caption.alt.org.osi.misc.list' => 'Entessa Public License',
	'caption.alt.org.tldr'     => 'Entessa Public License v1.0 (Entessa)',
	'caption.alt.org.wikidata' => 'Entessa Public License',
	description                => <<'END',
Identical to Apache 1.1, except...
* replace "Apache" and "Apache Software Foundation" with "Entessa" and "OpenSeal"
* replace "software" with "open source software" in notice inclusion clause
END
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence.part.notice_inclusion_clause' =>
		'This product includes open source software developed by openSEAL',
};

=item * epl

=item * epl_1

=item * epl_2

=cut

$RE{epl} = {
	name                                  => 'EPL',
	'name.alt.misc.fossology_old'         => 'Eclipse',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1281977',
	caption                               => 'Eclipse Public License',
	'caption.alt.org.wikipedia'           => 'Eclipse Public License',
	description                           => <<'END',
Origin: Common Public License (CPL)
END
	tags => [
		'type:versioned:decimal',
	],

# TODO: readd when children cover same region
#	'pat.alt.subject.license.scope.sentence' =>
#		'The Eclipse Foundation is the initial Agreement Steward',
};

$RE{epl_1} = {
	name                  => 'EPL-1.0',
	'name.alt.org.fedora' => 'EPL-1.0',
	'name.alt.org.osi'    => 'EPL-1.0',
	'name.alt.org.osi.iri.stem_plain.until.date_20110430.archive.time_20110426131805'
		=> 'eclipse-1.0',
	'name.alt.org.spdx'                   => 'EPL-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q55633170',
	'name.alt.misc.fossology_old'         => 'Eclipse_1.0',
	caption                               => 'Eclipse Public License 1.0',
	'caption.alt.org.tldr'   => 'Eclipse Public License 1.0 (EPL-1.0)',
	'caption.alt.org.trove'  => 'Eclipse Public License 1.0 (EPL-1.0)',
	'caption.alt.misc.legal' => 'Eclipse Public License - v 1.0',
	tags                     => [
		'type:singleversion:epl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'Eclipse Public License[ - ]v 1\.0[  ]THE ACCOMPANYING',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Eclipse Public License[ - ]v 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. 'ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[\']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])'
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial code',
};

$RE{epl_2} = {
	name                                    => 'EPL-2.0',
	'name.alt.org.fedora'                   => 'EPL-2.0',
	'name.alt.org.osi'                      => 'EPL-2.0',
	'name.alt.org.spdx.since.date_20171228' => 'EPL-2.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q55633295',
	caption                                 => 'Eclipse Public License 2.0',
	'caption.alt.org.osi'           => 'Eclipse Public License version 2.0',
	'caption.alt.org.osi.misc.list' => 'Eclipse Public License 2.0',
	'caption.alt.org.trove'         => 'Eclipse Public License 2.0 (EPL-2.0)',
	'caption.alt.misc.legal'        => 'Eclipse Public License - v 2.0',
	tags                            => [
		'type:singleversion:epl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence' =>
		'Eclipse Public License[ - ]v 2\.0[  ]THE ACCOMPANYING',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Eclipse Public License[ - ]v 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. 'ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[\']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])'
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial content',
};

=item * erlpl

I<Since v3.7.0.>

=item * erlpl_1_1

I<Since v3.7.0.>

=cut

$RE{erlpl} = {
	name                                  => 'ErlPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q3731857',
	caption                               => 'Erlang Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{erlpl_1_1} = {
	name                                         => 'ErlPL-1.1',
	'name.alt.org.fedora.synth.nogrant'          => 'ERPL',
	'name.alt.org.fedora.iri.self.synth.nogrant' => 'ErlangPublicLicense',
	'name.alt.org.spdx'                          => 'ErlPL-1.1',
	caption                  => 'Erlang Public License v1.1',
	'caption.alt.org.fedora' => 'Erlang Public License 1.1',
	'caption.alt.org.tldr'   => 'Erlang Public License v1.1 (ErlPL-1.1)',
	description              => <<'END',
Origin: Mozilla Public License 1.0
END
	tags => [
		'type:singleversion:erlpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'ERLANG PUBLIC LICENSE[ ]Version 1\.1[  ]' . '[*)]Definitions',
};

=item * eudatagrid

I<Since v3.6.0.>

=cut

$RE{eudatagrid} = {
	name                                            => 'EUDatagrid',
	'name.alt.org.osi'                              => 'EUDatagrid',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'eudatagrid',
	'name.alt.org.spdx'                             => 'EUDatagrid',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38365944',
	'name.alt.misc.fossology_old_short'             => 'Datagrid',
	caption                             => 'EU DataGrid Software License',
	'caption.alt.org.fedora'            => 'EU Datagrid Software License',
	'caption.alt.org.fedora.misc.short' => 'EU Datagrid',
	'caption.alt.org.tldr' => 'EU DataGrid Software License (EUDatagrid)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This software includes voluntary contributions made to the EU DataGrid',
};

=item * eupl

=item * eupl_1

=item * eupl_1_1

=item * eupl_1_2

=cut

$RE{eupl} = {
	name                                  => 'EUPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1376919',
	caption                               => 'European Union Public License',
	'caption.alt.org.wikidata'            => 'European Union Public Licence',
	'caption.alt.org.wikipedia'           => 'European Union Public Licence',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{eupl_1} = {
	name                     => 'EUPL-1.0',
	'name.alt.org.spdx'      => 'EUPL-1.0',
	caption                  => 'European Union Public License, Version 1.0',
	'caption.alt.org.fedora' => 'European Union Public License v1.0',
	'caption.alt.org.spdx'   => 'European Union Public License 1.0',
	'caption.alt.org.trove' => 'European Union Public Licence 1.0 (EUPL 1.0)',
	'caption.alt.org.trove.misc.short' => 'EUPL 1.0',
	tags                               => [
		'license:contains:grant',
		'type:singleversion:eupl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Licensed under the EUPL V\.1\.0[  ]or has expressed'
};

$RE{eupl_1_1} = {
	name                           => 'EUPL-1.1',
	'name.alt.org.spdx'            => 'EUPL-1.1',
	'name.alt.org.tldr'            => 'european-union-public-licence',
	'name.alt.org.tldr.path.short' => 'eupl-1.1',
	caption                  => 'European Union Public License, Version 1.1',
	'caption.alt.org.fedora' => 'European Union Public License 1.1',
	'caption.alt.org.fedora.misc.short' => 'EUPL 1.1',
	'caption.alt.org.spdx'  => 'European Union Public License 1.1',
	'caption.alt.org.tldr'  => 'European Union Public License 1.1 (EUPL-1.1)',
	'caption.alt.org.trove' => 'European Union Public Licence 1.1 (EUPL 1.1)',
	'caption.alt.org.trove.misc.short' => 'EUPL 1.1',
	tags                               => [
		'license:contains:grant',
		'type:singleversion:eupl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Licensed under the EUPL V\.1\.1[  ]or has expressed'
};

$RE{eupl_1_2} = {
	name                                    => 'EUPL-1.2',
	'name.alt.org.osi'                      => 'EUPL-1.2',
	'name.alt.org.spdx.since.date_20171228' => 'EUPL-1.2',
	caption                  => 'European Union Public License, Version 1.2',
	'caption.alt.org.fedora' => 'European Union Public License 1.2',
	'caption.alt.org.fedora.misc.short' => 'EUPL 1.2',
	'caption.alt.org.osi' => 'European Union Public License, version 1.2',
	'caption.alt.org.osi.misc.list' => 'European Union Public License 1.2',
	'caption.alt.org.osi.misc.cat_list.synth.nogrant' =>
		'European Union Public License',
	'caption.alt.org.spdx'  => 'European Union Public License 1.2',
	'caption.alt.org.trove' => 'European Union Public Licence 1.2 (EUPL 1.2)',
	'caption.alt.org.trove.misc.short' => 'EUPL 1.2',
	'iri.alt.org.wikipedia'            =>
		'https://en.wikipedia.org/wiki/European_Union_Public_Licence#Version_1.2',
	tags => [
		'license:contains:grant',
		'type:singleversion:eupl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Licensed under the EUPL[  ]or has expressed'
};

=item * eurosym

=cut

$RE{eurosym} = {
	name                                    => 'Eurosym',
	'name.alt.org.fedora.iri.self'          => 'Eurosym',
	'name.alt.org.spdx.since.date_20140807' => 'Eurosym',
	caption                                 => 'Eurosym License',
	'caption.alt.org.tldr'                  => 'Eurosym License',
	tags                                    => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote} . '[. ]'
		. $P{use_ack_apprec}
		. '[.][  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]' . '[*)]?'
		. $P{you_not_use_ad_dist}
		. $P{without_written_prior}
		. '[.][  ]' . '[*)]?'
		. $P{change_redist_share}
		. '[.][  ]'
		. $P{notice_no_alter},
};

=item * fair

I<Since v3.6.0.>

=cut

$RE{fair} = {
	name                                            => 'Fair',
	'name.alt.org.fedora'                           => 'Fair',
	'name.alt.org.osi'                              => 'Fair',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'fair',
	'name.alt.org.spdx'                             => 'Fair',
	'name.alt.org.tldr'                             => 'fair-license',
	'name.alt.org.tldr.path.short'                  => 'fair',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q22682017',
	caption                                         => 'Fair License',
	'caption.alt.org.tldr'                          => 'Fair License (Fair)',
	tags                                            => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Usage of the works is permitted provided that this instrument',
};

=item * fair_source

I<Since v3.8.0.>

=item * fair_source_0_9

I<Since v3.8.0.>

=cut

$RE{fair_source} = {
	name    => 'Fair-Source',
	caption => 'Fair Source License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{fair_source_0_9} = {
	name                   => 'Fair-Source-0.9',
	caption                => 'Fair Source License, version 0.9',
	'caption.alt.org.tldr' => 'Fair Source License 0.9 (Fair-Source-0.9)',
	iri                    => 'https://fair.io/#license',
	'iri.alt.format.txt'   => 'https://fair.io/v0.9.txt',
	tags                   => [
		'type:singleversion:fair_source',
	],
	licenseversion => '0.9',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Licensor hereby grants to each recipient',
};

=item * fal

I<Since v3.8.0.>

=item * fal_1_1

I<Since v3.8.0.>

=item * fal_1_2

I<Since v3.8.0.>

=item * fal_1_3

I<Since v3.8.0.>

=cut

$RE{fal} = {
	name                                => 'FAL',
	caption                             => 'Free Art License',
	'caption.alt.org.fedora'            => 'Free Art License',
	'caption.alt.org.fedora.misc.short' => 'Free Art',
	'caption.alt.misc.legal.lang.de'    => 'Lizenz Freie Kunst',
	'caption.alt.misc.legal.lang.es'    => 'Licencia Arte Libre',
	'caption.alt.misc.legal.lang.fr'    => 'Licence Art Libre',
	'caption.alt.misc.legal.lang.it'    => 'Licenza Arte Libera',
	'caption.alt.misc.legal.lang.pl'    => 'Licencja Wolnej Sztuki',
	iri                                 => 'https://artlibre.org/',
	tags                                => [
		'type:versioned:decimal',
	],
};

$RE{fal_1_1} = {
	name                             => 'FAL-1.1',
	caption                          => 'Free Art License 1.1',
	'caption.alt.misc.legal.lang.de' => 'Lizenz Freie Kunst 1.1',
	tags                             => [
		'type:singleversion:fal',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.lang.de' =>
		'Durch die Lizenz ["] ?Freie Kunst ?["] wird die Erlaubnis verliehen',
};

$RE{fal_1_2} = {
	name                             => 'FAL-1.2',
	caption                          => 'Free Art License 1.2',
	'caption.alt.misc.legal.lang.es' => 'Licencia Arte Libre 1.2',
	'caption.alt.misc.legal.lang.fr' => 'Licence Art Libre 1.2',
	'caption.alt.misc.legal.lang.it' => 'Licenza Arte Libera 1.2',
	iri => 'https://artlibre.org/licence/lal/licence-art-libre-12/',
	'iri.alt.archive.time_20051027003023.lang.en' =>
		'https://artlibre.org/licence/lal/en/',
	tags => [
		'type:singleversion:fal',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.line.scope.sentence.lang.en' =>
		'With this Free Art License, you are authorised',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.es' =>
		'La Licencia Arte Libre [(]LAL[)] le autoriza a copiar',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.fr' =>
		'Avec cette Licence Art Libre, l’autorisation est',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.it' =>
		'Con questa licenza Arte Libera è permesso copiare',
};

$RE{fal_1_3} = {
	name                                         => 'FAL-1.3',
	'name.alt.org.tldr.path.short.synth.nogrant' => 'fal',
	caption                                      => 'Free Art License 1.3',
	'caption.alt.misc.legal.lang.de'             => 'Lizenz Freie Kunst 1.3',
	'caption.alt.misc.legal.lang.en'     => 'Free Art License 1.3 (FAL 1.3)',
	'caption.alt.misc.legal.lang.fr'     => 'Licence Art Libre 1.3 (LAL 1.3)',
	'caption.alt.misc.legal.lang.pl'     => 'Licencja Wolnej Sztuki 1.3',
	'caption.alt.misc.legal.lang.pt'     => 'Licença da Arte Livre 1.3',
	'caption.alt.org.tldr.synth.nogrant' => 'Free Art License (FAL)',
	'iri.alt.misc.canonical.lang.de'     =>
		'https://artlibre.org/licence/lal/de1-3/',
	tags => [
		'type:singleversion:fal',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.line.scope.sentence.lang.de' =>
		'Mit der Lizenz Freie Kunst wird die Genehmigung erteilt',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.en' =>
		'The Free Art License grants the right to freely copy',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.fr' =>
		'Avec la Licence Art Libre, l’autorisation est',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.pl' =>
		'Licencja Wolnej Sztuki przyznaje prawo do swobodnego kopiowania',
	'pat.alt.subject.license.scope.line.scope.sentence.lang.pt' =>
		'A Licença da Arte Livre autoriza você a copiar livremente',
};

=item * festival

I<Since v3.8.0.>

=cut

$RE{festival} = {
	name                                => 'Festival',
	'name.alt.org.fedora.iri.mit_short' => 'Festival',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Festival variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause2' =>
		"Original authors['] names are not deleted",
};

=item * frameworx

I<Since v3.6.0.>

=item * frameworx_1

I<Since v3.6.0.>

=cut

$RE{frameworx} = {
	name                                  => 'Frameworx',
	'name.alt.org.wikidata.synth.nogrant' => 'Q5477987',
	caption                               => 'Frameworx License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{frameworx_1} = {
	name               => 'Frameworx-1.0',
	'name.alt.org.osi' => 'Frameworx-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430.synth.nogrant' =>
		'frameworx',
	'name.alt.org.spdx'                    => 'Frameworx-1.0',
	'name.alt.misc.fossology_old'          => 'Frameworx_v1.0',
	'name.alt.misc.fossology_old_short'    => 'Frameworx1.0',
	caption                                => 'Frameworx Open License 1.0',
	'caption.alt.org.fedora.synth.nogrant' => 'Frameworx License',
	'caption.alt.org.osi'                  => 'Frameworx License 1.0',
	'caption.alt.org.osi.misc.list.synth.nogrant' => 'Frameworx License',
	'caption.alt.org.tldr' => 'Frameworx Open License 1.0 (Frameworx-1.0)',
	tags                   => [
		'type:singleversion:frameworx',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This License Agreement, The Frameworx Open License 1.0, has',
	'pat.alt.subject.license.scope.sentence.part.license_file_clause' =>
		'contain an unaltered copy of the text file named the_frameworx_license\.txt',
};

=item * fsfap

=cut

$RE{fsfap} = {
	name                                    => 'FSFAP',
	'name.alt.org.fedora.iri.self'          => 'FSFAP',
	'name.alt.org.fsf'                      => 'GNUAllPermissive',
	'name.alt.org.spdx.since.date_20160323' => 'FSFAP',
	caption                                 => 'FSF All Permissive License',
	'caption.alt.org.fedora'                => 'FSF All Permissive license',
	'caption.alt.org.fsf'                   => 'GNU All-Permissive License',
	iri                                     =>
		'https://www.gnu.org/prep/maintain/html_node/License-Notices-for-Other-Files.html',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved',
};

=item * fsful

=cut

$RE{fsful} = {
	name                                    => 'FSFUL',
	'name.alt.org.fedora'                   => 'FSFUL',
	'name.alt.org.spdx.since.date_20140807' => 'FSFUL',
	caption                                 => 'FSF Unlimited License',
	'caption.alt.org.fedora.iri.self'       => 'FSF Unlimited License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		"This configure script is free software; $fsf_ul",
};

=item * fsfullr

=cut

$RE{fsfullr} = {
	name                                    => 'FSFULLR',
	'name.alt.org.fedora'                   => 'FSFULLR',
	'name.alt.org.spdx.since.date_20140807' => 'FSFULLR',
	caption => 'FSF Unlimited License (with License Retention)',
	tags    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		"This file is free software; $fsf_ullr",
};

=item * ftl

=cut

$RE{ftl} = {
	name                                    => 'FTL',
	'name.alt.org.fedora'                   => 'FTL',
	'name.alt.org.spdx.since.date_20130117' => 'FTL',
	'name.alt.misc.fossology_old'           => 'Freetype',
	'name.alt.misc.fossology_old_upper'     => 'FreeType',
	caption                                 => 'Freetype Project License',
	'caption.alt.misc.short_camelcase'      => 'FreeType License',
	'caption.alt.misc.legal_license'        => 'The Freetype Project LICENSE',
	'caption.alt.org.fedora'                => 'Freetype License',
	'caption.alt.org.tldr' => 'Freetype Project License (FTL)',
	iri                    => 'https://www.freetype.org/license.html',
	description            => <<'END',
Origin: BSD License family, Artistic License, and Independent JPEG Group License.
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'This license applies to all files found in such packages',
};

=item * gfdl

=item * gfdl_1_1

=item * gfdl_1_1_only

=item * gfdl_1_1_or_later

=item * gfdl_1_2

=item * gfdl_1_2_only

=item * gfdl_1_2_or_later

=item * gfdl_1_3

=item * gfdl_1_3_only

=item * gfdl_1_3_or_later

=cut

$RE{gfdl} = {
	name                                  => 'GFDL',
	'name.alt.org.fedora'                 => 'GFDL',
	'name.alt.org.fsf'                    => 'FDL',
	'name.alt.org.trove'                  => 'FDL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q22169',
	caption                               => 'GNU Free Documentation License',
	'caption.alt.org.trove'    => 'GNU Free Documentation License (FDL)',
	'caption.alt.org.wikidata' => 'GNU Free Documentation License',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{gfdl_1_1} = {
	name                                    => 'GFDL-1.1',
	'name.alt.org.fsf'                      => 'fdl-1.1',
	'name.alt.org.spdx.until.date_20171228' => 'GFDL-1.1',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q26921685',
	'name.alt.misc.fossology_old'           => 'GFDL_v1.1',
	caption                    => 'GNU Free Documentation License v1.1',
	'caption.alt.org.wikidata' =>
		'GNU Free Documentation License, version 1.1',
	tags => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]' . 'Version 1\.1, March 2000',
	'pat.alt.subject.license.part.part1' =>
		'This License applies to any manual or other work that contains',
	'pat.alt.subject.license.scope.multisection.part.part9' =>
		'the original English version will prevail[.][  ]'
		. '[*)]TERMINATION',
};

$RE{gfdl_1_1_only} = {
	name                                    => 'GFDL-1.1-only',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.1-only',
	caption                  => 'GNU Free Documentation License v1.1 only',
	'caption.alt.misc.short' => 'GFDLv1.1 only',
	tags                     => [
		'type:usage:gfdl_1_1:only',
	],
};

$RE{gfdl_1_1_or_later} = {
	name                                    => 'GFDL-1.1-or-later',
	'name.alt.org.debian'                   => 'GFDL-1.1+',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.1-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q50829096',
	'name.alt.misc.fossology_old'           => 'GFDL_v1.1+',
	caption => 'GNU Free Documentation License v1.1 or later',
	'caption.alt.org.wikidata' =>
		'GNU Free Documentation License, version 1.1 or later',
	'caption.alt.misc.short' => 'GFDLv1.1 or later',
	tags                     => [
		'type:usage:gfdl_1_1:or_later',
	],
};

$RE{gfdl_1_2} = {
	name                                    => 'GFDL-1.2',
	'name.alt.org.fsf'                      => 'fdl-1.2',
	'name.alt.org.perl'                     => 'gfdl_1_2',
	'name.alt.org.spdx.until.date_20171228' => 'GFDL-1.2',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q26921686',
	'name.alt.misc.fossology_old'           => 'GFDL_v1.2',
	'name.alt.misc.fossology_old_short'     => 'GFDL1.2',
	caption                => 'GNU Free Documentation License v1.2',
	'caption.alt.org.perl' => 'GNU Free Documentation License, Version 1.2',
	'caption.alt.org.wikidata' =>
		'GNU Free Documentation License, version 1.2',
	tags => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]' . 'Version 1\.2, November 2002',
	'pat.alt.subject.license.scope.sentence.part.part9' =>
		'You may not copy, modify, sublicense, or distribute the Document '
		. 'except as expressly provided for under this License',
};

$RE{gfdl_1_2_only} = {
	name                                    => 'GFDL-1.2-only',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.2-only',
	caption                  => 'GNU Free Documentation License v1.2 only',
	'caption.alt.misc.short' => 'GFDLv1.2 only',
	tags                     => [
		'type:usage:gfdl_1_2:only',
	],
};

$RE{gfdl_1_2_or_later} = {
	name                                    => 'GFDL-1.2-or-later',
	'name.alt.org.debian'                   => 'GFDL-1.2+',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.2-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q50829104',
	'name.alt.misc.fossology_old'           => 'GFDL_v1.2+',
	caption => 'GNU Free Documentation License v1.2 or later',
	'caption.alt.org.wikidata' =>
		'GNU Free Documentation License, version 1.2 or later',
	'caption.alt.misc.short' => 'GFDLv1.2 or later',
	tags                     => [
		'type:usage:gfdl_1_2:or_later',
	],
};

$RE{gfdl_1_3} = {
	name                                    => 'GFDL-1.3',
	'name.alt.org.fsf'                      => 'fdl-1.3',
	'name.alt.org.perl'                     => 'gfdl_1_3',
	'name.alt.org.spdx.until.date_20171228' => 'GFDL-1.3',
	'name.alt.org.tldr' => 'gnu-free-documentation-license',
	'name.alt.org.tldr.path.short.synth.nogrant' => 'fdl',
	'name.alt.org.wikidata.synth.nogrant'        => 'Q26921691',
	'caption.alt.org.wikidata'                   =>
		'GNU Free Documentation License, version 1.3',
	'name.alt.misc.fossology_old' => 'GFDL1.3',
	caption                       => 'GNU Free Documentation License v1.3',
	'caption.alt.org.perl' => 'GNU Free Documentation License, Version 1.3',
	'caption.alt.org.tldr' => 'GNU Free Documentation License v1.3 (FDL-1.3)',
	tags                   => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]'
		. 'Version 1\.3, 3 November 2008',
	'pat.alt.subject.license.scope.sentence.part.part9' =>
		'You may not copy, modify, sublicense, or distribute the Document '
		. 'except as expressly provided for under this License',
};

$RE{gfdl_1_3_only} = {
	name                                    => 'GFDL-1.3-only',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.3-only',
	caption                  => 'GNU Free Documentation License v1.3 only',
	'caption.alt.misc.short' => 'GFDLv1.3 only',
	tags                     => [
		'type:usage:gfdl_1_3:only',
	],
};

$RE{gfdl_1_3_or_later} = {
	name                                    => 'GFDL-1.3-or-later',
	'name.alt.org.debian'                   => 'GFDL-1.3+',
	'name.alt.org.spdx.since.date_20171228' => 'GFDL-1.3-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27019786',
	caption => 'GNU Free Documentation License v1.3 or later',
	'caption.alt.org.wikidata' =>
		'GNU Free Documentation License, version 1.3 or later',
	'caption.alt.misc.short' => 'GFDLv1.3 or later',
	tags                     => [
		'type:usage:gfdl_1_3:or_later',
	],
};

=item * gfdl_niv

=cut

$RE{gfdl_niv} = {
	name    => 'GFDL-NIV',
	caption => 'GNU Free Documentation License (no invariant sections)',
	summary =>
		'GNU Free Documentation License, with no Front-Cover or Back-Cover Texts or Invariant Sections',
	tags => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' =>
		"$the?$gnu?Free Documentation Licen[cs]e(?: [(]GFDL[)])?"
		. $RE{by_fsf}{'pat.alt.subject.trait'}
		. "?[;]? $niv",
};

=item * glide

I<Since v3.8.0.>

=cut

$RE{glide} = {
	name                                    => 'Glide',
	'name.alt.org.fedora'                   => 'Glide',
	'name.alt.org.spdx.since.date_20140807' => 'Glide',
	caption                                 => '3dfx Glide License',
	'caption.alt.org.tldr'                  => '3dfx Glide License',
	'caption.alt.misc.legal_grant' => 'THE 3DFX GLIDE GENERAL PUBLIC LICENSE',
	tags                           => [
		'license.contains.grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This license is for software that provides a 3D graphics',
};

=item * gpl

=item * gpl_1

I<Since v3.3.0.>

=item * gpl_1_only

=item * gpl_1_or_later

=item * gpl_2

I<Since v3.3.0.>

=item * gpl_2_only

=item * gpl_2_or_later

=item * gpl_3

I<Since v3.3.0.>

=item * gpl_3_only

=item * gpl_3_or_later

=cut

$RE{gpl} = {
	name                                  => 'GPL',
	'name.alt.org.fsf'                    => 'GNUGPL',
	'name.alt.org.osi'                    => 'gpl-license',
	'name.alt.org.osi.misc.shortname'     => 'GPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q7603',
	'name.alt.misc.fossology_old'         => 'CC_GPL',
	caption                               => 'GNU General Public License',
	'caption.alt.org.fedora'              => 'GNU General Public License',
	'caption.alt.org.fsf'       => 'GNU General Public License (GPL)',
	'caption.alt.org.osi'       => 'GNU General Public License',
	'caption.alt.org.trove'     => 'GNU General Public License (GPL)',
	'caption.alt.org.wikipedia' => 'GNU General Public License',
	tags                        => [
		'family:gpl',
		'license:contains:grant',
		'type:versioned:decimal',
	],

	'_pat.alt.subject.name' => [
		"$the?$gnu?$gpl(?: [(]GPL[)])?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the$gnu?GPL",
		"${the}GNU [Ll]icense",
		"${gnu}GPL",
	],
};

$RE{gpl_1} = {
	name                                  => 'GPL-1.0',
	'name.alt.org.debian'                 => 'GPL-1',
	'name.alt.org.perl'                   => 'gpl_1',
	'name.alt.org.fsf'                    => 'GPLv1',
	'name.alt.org.wikidata.synth.nogrant' => 'Q10513452',
	'name.alt.misc.fossology_old'         => 'GPL1.0',
	'name.alt.misc.fossology_old_short'   => 'GPL_v1',
	caption                    => 'GNU General Public License, Version 1',
	'caption.alt.org.wikidata' => 'GNU General Public License, version 1.0',
	iri => 'https://www.gnu.org/licenses/old-licenses/gpl-1.0.html',
	'iri.alt.format.txt' =>
		'https://www.gnu.org/licenses/old-licenses/gpl-1.0.txt',
	'iri.alt.path.short' => 'http://www.gnu.org/licenses/gpl-1.0.html',
	tags                 => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:gpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This program is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 1, or',
};

$RE{gpl_1_only} = {
	name                                                  => 'GPL-1.0-only',
	'name.alt.org.fedora.synth.nogrant'                   => 'GPLv1',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'GPL-1.0',
	'name.alt.org.spdx.since.date_20171228'               => 'GPL-1.0-only',
	caption                  => 'GNU General Public License v1.0 only',
	'caption.alt.misc.short' => 'GPLv1 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_1:only',
	],
};

$RE{gpl_1_or_later} = {
	name                                    => 'GPL-1.0-or-later',
	'name.alt.org.fedora'                   => 'GPL+',
	'name.alt.org.debian'                   => 'GPL-1+',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-1.0+',
	'name.alt.org.spdx.since.date_20171228' => 'GPL-1.0-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016750',
	'name.alt.misc.fossology_old_short'     => 'GPL_v1+',
	caption                    => 'GNU General Public License v1.0 or later',
	'caption.alt.org.wikidata' =>
		'GNU General Public License, version 1.0 or later',
	'caption.alt.misc.short' => 'GPLv1 or later',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_1:or_later',
	],
};

$RE{gpl_2} = {
	name                                            => 'GPL-2',
	'name.alt.misc.short'                           => 'GPLv2',
	'name.alt.org.debian'                           => 'GPL-2',
	'name.alt.org.fsf'                              => 'GNUGPLv2',
	'name.alt.org.osi'                              => 'GPL-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'gpl-2.0',
	'name.alt.org.perl'                             => 'gpl_2',
	'name.alt.org.tldr'                   => 'gnu-general-public-license-v2',
	'name.alt.org.tldr.path.short'        => 'gpl2',
	'name.alt.org.trove'                  => 'GPLv2',
	'name.alt.org.wikidata.synth.nogrant' => 'Q10513450',
	'name.alt.misc.fossology_old'         => 'GPL2.0',
	'name.alt.misc.fossology_old_cc'      => 'CC_GPL_v2',
	'name.alt.misc.fossology_old_short'   => 'GPL_v2',
	caption => 'GNU General Public License, Version 2',
	'caption.alt.org.cc.until.date_20100915' =>
		'Creative Commons GNU GPL',    # TODO: find official date
	'caption.alt.org.cc.misc.short.until.date_20100915' =>
		'CC-GNU GPL',                  # TODO: find official date
	'caption.alt.org.fedora.misc.cc' => 'Creative Commons GNU GPL',
	'caption.alt.org.fsf'   => 'GNU General Public License (GPL) version 2',
	'caption.alt.org.trove' => 'GNU General Public License v2 (GPLv2)',
	'caption.alt.org.osi'   => 'GNU General Public License version 2',
	'caption.alt.org.osi.misc.list' =>
		'GNU General Public License, version 2',
	'caption.alt.org.tldr'     => 'GNU General Public License v2.0 (GPL-2.0)',
	'caption.alt.org.wikidata' => 'GNU General Public License, version 2.0',
	iri => 'https://www.gnu.org/licenses/old-licenses/gpl-2.0.html',
	'iri.alt.format.txt' =>
		'https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt',
	'iri.alt.path.short' => 'http://www.gnu.org/licenses/gpl-2.0.html',
	'iri.alt.org.cc.archive.time_20101028012914.until.date_20101028' =>
		'http://creativecommons.org/licenses/GPL/2.0/'
	,    # TODO: find official date
	'iri.alt.org.cc.archive.time_20100915084134.until.date_20100915' =>
		'http://creativecommons.org/choose/cc-gpl', # TODO: find official date
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:gpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence.part.preamble' =>
		'[(]Some other Free Software Foundation software is covered by t?he GNU (Library|Lesser)',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This program is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 2 of the License, or',
};

$RE{gpl_2_only} = {
	name                                                  => 'GPL-2.0-only',
	'name.alt.org.fedora.synth.nogrant'                   => 'GPLv2',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'GPL-2.0',
	'name.alt.org.spdx.since.date_20171228'               => 'GPL-2.0-only',
	caption                  => 'GNU General Public License v2.0 only',
	'caption.alt.misc.short' => 'GPLv2 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_2:only',
	],
};

$RE{gpl_2_or_later} = {
	name                                    => 'GPL-2.0-or-later',
	'name.alt.org.fedora'                   => 'GPLv2+',
	'name.alt.org.debian'                   => 'GPL-2+',
	'name.alt.org.fedora'                   => 'GPLv2+',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-2.0+',
	'name.alt.org.spdx.since.date_20171228' => 'GPL-2.0-or-later',
	'name.alt.org.trove'                    => 'GPLv2+',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016752',
	'name.alt.misc.fossology_old_short'     => 'GPL_v2+',
	caption                  => 'GNU General Public License v2.0 or later',
	'caption.alt.misc.short' => 'GPLv2 or later',
	'caption.alt.org.trove'  =>
		'GNU General Public License v2 or later (GPLv2+)',
	'caption.alt.org.wikidata' =>
		'GNU General Public License, version 2.0 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_2:or_later',
	],
};

$RE{gpl_3} = {
	name                                            => 'GPL-3',
	'name.alt.misc.short'                           => 'GPLv3',
	'name.alt.org.debian'                           => 'GPL-3',
	'name.alt.org.fsf'                              => 'GNUGPLv3',
	'name.alt.org.osi'                              => 'GPL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'gpl-3.0',
	'name.alt.org.perl'                             => 'gpl_3',
	'name.alt.org.tldr.path.short'                  => 'gpl-3.0',
	'name.alt.org.trove'                            => 'GPLv3',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q10513445',
	'name.alt.misc.fossology_old'                   => 'GPL3.0',
	'name.alt.misc.fossology_old_short'             => 'GPL_v3',
	caption               => 'GNU General Public License, Version 3',
	'caption.alt.org.fsf' => 'GNU General Public License (GPL) version 3',
	'caption.alt.org.osi' => 'GNU General Public License version 3',
	'caption.alt.org.osi.misc.list' =>
		'GNU General Public License, version 3',
	'caption.alt.org.tldr'     => 'GNU General Public License v3 (GPL-3)',
	'caption.alt.org.trove'    => 'GNU General Public License v3 (GPLv3)',
	'caption.alt.org.wikidata' => 'GNU General Public License, version 3.0',
	iri                        => 'https://www.gnu.org/licenses/gpl.html',
	'iri.alt.format.txt'       => 'https://www.gnu.org/licenses/gpl.txt',
	'iri.alt.path.fragmented'  =>
		'https://www.gnu.org/licenses/licenses.html#GPL',
	'iri.alt.path.versioned' => 'http://www.gnu.org/licenses/gpl-3.0.html',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:gpl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.part.part0' =>
		'["]This License["] refers to version 3 of the GNU General',
	'pat.alt.subject.license.scope.sentence.part.part13' =>
		'Notwithstanding any other provision of this License, '
		. 'you have permission to link or combine any covered work '
		. 'with a work licensed under version 3 of the GNU Affero',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This program is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 3 of the License, or',

	#<<<  do not let perltidy touch this (keep long regex on one line)
	examples => [
		{   summary => 'pattern with subject "license" matches canonical license grant with adequate context',
			gen_args => { subject => 'license' },
			## no Test::Tabs
			str => <<'END',
Copyright (C) <year>  <name of author>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
END
			## use Test::Tabs
			matches => 1,
		},
		{   summary => 'pattern with subject "license" doesn\'t match canonical license grant only',
			gen_args => { subject => 'license' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" matches canonical license grant',
			gen_args => { subject => 'grant' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" matches a license grant without usage specified',
			gen_args => { subject => 'grant' },
			str => 'Licensed under the GNU General Public License version 3.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match license grant with usage in front',
			gen_args => { subject => 'grant' },
			str => 'Licensed under v3 or newer of the GNU General Public License.',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match license name only',
			gen_args => { subject => 'grant' },
			str => 'GNU General Public License v3',
			matches => 0,
		},
		{   summary => 'pattern with subject "name" matches license name',
			gen_args => { subject => 'name' },
			str => 'GNU General Public License v3',
			matches => 1,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match license name',
			gen_args => { subject => 'iri' },
			str => 'GNU General Public License v3',
			matches => 0,
		},
	],
	#>>>
};

$RE{gpl_3_only} = {
	name                                                  => 'GPL-3.0-only',
	'name.alt.org.fedora.synth.nogrant'                   => 'GPLv3',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'GPL-3.0',
	'name.alt.org.spdx.since.date_20171228'               => 'GPL-3.0-only',
	caption                  => 'GNU General Public License v3.0 only',
	'caption.alt.misc.short' => 'GPLv3 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_3:only',
	],

	#<<<  do not let perltidy touch this (keep long regex on one line)
	examples => [
		{   summary => 'pattern with subject "license" doesn\'t match canonical license grant even with context',
			gen_args => { subject => 'license' },
			## no Test::Tabs
			str => <<'END',
Copyright (C) <year>  <name of author>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
END
			## use Test::Tabs
			matches => 0,
		},
		{   summary => 'pattern with subject "license" doesn\'t match canonical license grant only',
			gen_args => { subject => 'license' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 only of the License.',
			matches => 0,
		},
		{   summary => 'pattern with subject "license" doesn\'t match a non-canonical license grant',
			gen_args => { subject => 'license' },
			str => 'modify it under the terms of the GNU General Public License',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" matches canonical license grant',
			gen_args => { subject => 'grant' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 only of the License.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" matches license grant with usage in front',
			gen_args => { subject => 'grant' },
			str => 'Licensed under v3 only of the GNU General Public License.',
			matches => 1,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match a license grant without usage specified',
			gen_args => { subject => 'grant' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match license grant with different usage',
			gen_args => { subject => 'grant' },
			str => 'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.',
			matches => 0,
		},
		{   summary => 'pattern with subject "grant" doesn\'t match license name only',
			gen_args => { subject => 'grant' },
			str => 'GNU General Public License v3.0 only',
			matches => 0,
		},
		{   summary => 'pattern with subject "name" matches canonical license name',
			gen_args => { subject => 'name' },
			str => 'GNU General Public License v3.0 only',
			matches => 1,
		},
		{   summary => 'pattern with subject "name" doesn\'t match a license name without usage specified',
			gen_args => { subject => 'name' },
			str => 'GNU General Public License v3.0',
			matches => 0,
		},
		{   summary => 'pattern with subject "name" doesn\'t match a license name with different usage',
			gen_args => { subject => 'name' },
			str => 'GNU General Public License v3.0 or later',
			matches => 0,
		},
		{   summary => 'pattern with subject "iri" doesn\'t match canonical license name',
			gen_args => { subject => 'iri' },
			str => 'GNU General Public License v3.0 only',
			matches => 0,
		},
	],
	#>>>
};

$RE{gpl_3_or_later} = {
	name                                    => 'GPL-3.0-or-later',
	'name.alt.org.fedora'                   => 'GPLv3+',
	'name.alt.org.debian'                   => 'GPL-3+',
	'name.alt.org.spdx.until.date_20150513' => 'GPL-3.0+',
	'name.alt.org.spdx.since.date_20171228' => 'GPL-3.0-or-later',
	'name.alt.org.trove'                    => 'GPLv3+',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016754',
	'name.alt.misc.fossology_old_short'     => 'GPL_v3+',
	caption                  => 'GNU General Public License v3.0 or later',
	'caption.alt.misc.short' => 'GPLv3 or later',
	'caption.alt.org.trove'  =>
		'GNU General Public License v3 or later (GPLv3+)',
	'caption.alt.org.wikidata' =>
		'GNU General Public License, version 3.0 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_3:or_later',
	],
};

=item * gsoap

I<Since v3.7.0.>

=item * gsoap_1.3b

I<Since v3.7.0.>

=cut

$RE{gsoap} = {
	name                                  => 'gSOAP',
	'name.alt.org.wikidata.synth.nogrant' => 'Q3756289',
	caption                               => 'gSOAP Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{gsoap_1_3b} = {
	name                                   => 'gSOAP-1.3b',
	'name.alt.org.spdx'                    => 'gSOAP-1.3b',
	caption                                => 'gSOAP Public License v1.3b',
	'caption.alt.org.fedora.synth.nogrant' => 'gSOAP Public License',
	description                            => <<'END',
Origin: Mozilla Public License Version 1.1
END
	tags => [
		'type:singleversion:gsoap',
	],
	licenseversion => '1.3b',

	'pat.alt.subject.license.scope.line.scope.sentence.part.head' =>
		'The gSOAP public license is derived from the Mozilla Public License',
	'pat.alt.subject.license.scope.line.scope.sentence.part.section_3_8' =>
		'You may not remove any product identification',
};

=item * hpnd

I<Since v3.6.0.>

=cut

$RE{hpnd} = {
	name                                            => 'HPND',
	'name.alt.org.osi'                              => 'HPND',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'historical',
	'name.alt.org.spdx'                             => 'HPND',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q5773924',
	caption                  => 'Historical Permission Notice and Disclaimer',
	'caption.alt.org.fedora' => 'Historical Permission Notice and Disclaimer',
	'caption.alt.org.spdx.until.date_20171228' =>
		'Historic Permission Notice and Disclaimer',
	'caption.alt.org.spdx.since.date_20171228' =>
		'Historical Permission Notice and Disclaimer',
	'caption.alt.org.tldr' =>
		'Historic Permission Notice and Disclaimer (HPND)',
	'caption.alt.org.trove' =>
		'Historical Permission Notice and Disclaimer (HPND)',
	'caption.alt.org.wikipedia' =>
		'Historical Permission Notice and Disclaimer',
	description => <<'END',
Identical to NTP, except...
* omit explicit permission to charge fee
* relax suitability disclaimer and terse "as is" warranty disclaimer as optional
* add optional elaborate warranty disclaimer and liability disclaimer
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Permission to use, copy, modify and distribute '
		. 'this software and its documentation '
		. 'for any purpose and without fee',
	'pat.alt.subject.license.scope.paragraph' =>
		'Permission to use, copy, modify and distribute '
		. 'this software and its documentation '
		. 'for any purpose and without fee is hereby granted, '
		. 'provided that the above copyright notice appears? in all copies,?(?: and)? '
		. 'that both(?: that)?(?: the)? copyright notice '
		. 'and this permission notice appear in supporting documentation'
		. '(?:, and that the name [word][ word]{0,14} not be used '
		. 'in advertising or publicity pertaining to distribution '
		. 'of the software without specific, written prior permission'
		. '[. ][word][ word]{0,14} makes no representations '
		. 'about the suitability of this software for any purpose'
		. '[. ]It is provided [as is] without express or implied warranty[.])?',
};

=item * hpnd_sell

I<Since v3.6.0.>

=cut

$RE{hpnd_sell} = {
	name                                    => 'HPND-sell-variant',
	'name.alt.org.spdx.since.date_20190402' => 'HPND-sell-variant',
	caption => 'Historical Permission Notice and Disclaimer - sell variant',
	description => <<'END',
Identical to HPND, except...
* add explicit permission to sell
* omit explicit permission to charge fee
* extend permissions with note that they are granted without fee

Identical to NTP, except...
* add explicit permission to sell
* omit explicit permission to charge or not charge fee
* extend permissions with note that they are granted without fee
* relax suitability disclaimer and terse "as is" warranty disclaimer as optional
* add optional elaborate warranty disclaimer and liability disclaimer
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' =>
		'Permission to use, copy, modify, distribute, and sell '
		. 'this software and its documentation '
		. 'for any purpose is hereby granted without fee, '
		. 'provided that the above copyright notice appears? in all copies,?(?: and)? '
		. 'that both(?: that)?(?: the)? copyright notice '
		. 'and this permission notice appear in supporting documentation'
		. '(?:, and that the name [word][ word]{0,14} not be used '
		. 'in advertising or publicity pertaining to distribution '
		. 'of the software without specific, written prior permission'
		. '[. ][word][ word]{0,14} makes no representations '
		. 'about the suitability of this software for any purpose'
		. '[. ]It is provided [as is] without express or implied warranty[.])?',
};

=item * ibm_pibs

I<Since v3.8.0.>

=cut

$RE{ibm_pibs} = {
	name                                    => 'IBM-pibs',
	'name.alt.org.spdx.since.date_20130912' => 'IBM-pibs',
	caption                => 'IBM PowerPC Initialization and Boot Software',
	'caption.alt.org.tldr' =>
		'IBM PowerPC Initialization and Boot Software (IBM-pibs)',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Any user of this software should understand that IBM cannot',
};

=item * icu

=cut

$RE{icu} = {
	name                                    => 'ICU',
	'name.alt.org.spdx.since.date_20150513' => 'ICU',
	caption                                 => 'ICU License',
	'summary.alt.org.fedora.iri.mit'        =>
		'MIT-style license, Modern style (ICU Variant)',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. ' of the Software and that '
		. $P{repro_copr_perm_appear_doc}
		. '[.][  ]'
		. $P{asis_sw_warranty}
		. '(?:[^.]+[. ]){2}'
		. $P{nopromo_except},
};

=item * ijg

I<Since v3.8.0.>

=cut

$RE{ijg} = {
	name                                    => 'IJG',
	'name.alt.org.fedora.iri.self'          => 'IJG',
	'name.alt.org.spdx.since.date_20130117' => 'IJG',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q106186423',
	caption                => 'Independent JPEG Group License',
	'caption.alt.org.tldr' => 'Independent JPEG Group License (IJG)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.section.part.intro' =>
		"We don[']t promise that this software works" . '[. ]'
		. '[(]But if you find any bugs, please let us know[!][)]',
};

=item * imlib2

I<Since v3.8.0.>

=cut

$RE{imlib2} = {
	name                                    => 'Imlib2',
	'name.alt.org.fedora.iri.self'          => 'Imlib2',
	'name.alt.org.spdx.since.date_20130117' => 'Imlib2',
	caption                                 => 'Imlib2 License',
	'caption.alt.org.tldr'                  => 'Imlib2 License (Imlib2)',
	description                             => <<'END',
Identical to enna License, except...
* Define meaning of making source available
* Describe purpose of copyright notice
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.section' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_sw}
		. $P{to_deal_the_sw_rights}
		. $P{subj_cond}
		. $P{to_copy_sublicence_conditions}
		. '[:]?[ ]'
		. $P{retain_copr_perm_sw_copr} . '[. ]'
		. $P{ack_pub_use_nosrc} . '[. ]'
		. 'Making the source available publicly means '
		. 'including the source for this software with the distribution, '
		. 'or a method to get this software via some reasonable mechanism '
		. '[(]electronic transfer via a network or media[)] '
		. 'as well as making an offer to supply the source on request'
		. '[. ]'
		. 'This Copyright notice serves as an offer to supply the source on on request as well'
		. '[. ]'
		. 'Instead of this, supplying acknowledgments of use of this software '
		. 'in either Copyright notices, Manuals, Publicity and Marketing documents '
		. 'or any documentation provided '
		. 'with any product containing this software[. ]'
		. $P{license_not_lib} . '[.]',
	'pat.alt.subject.license.scope.line' =>
		'Making the source available publicly means including',
};

=item * intel

I<Since v3.5.0.>

=cut

$RE{intel} = {
	name                                            => 'Intel',
	'name.alt.org.osi'                              => 'Intel',
	'name.alt.org.osi.iri.stem.until.date_20110430' =>
		'intel-open-source-license',
	'name.alt.org.spdx.since.date_20130117' => 'Intel',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q6043507',
	caption                                 => 'Intel Open Source License',
	'caption.alt.org.fedora'                => 'Intel Open Source License',
	'caption.alt.org.osi'           => 'The Intel Open Source License',
	'caption.alt.org.osi.misc.list' => 'Intel Open Source License',
	'caption.alt.org.tldr'          => 'Intel Open Source License (Intel)',
	'caption.alt.org.trove'         => 'Intel Open Source License',
	description                     => <<'END',
Identical to BSD 3 Clause, except...
* Add export law disclaimer
END
	tags => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '[.]?[  ]'
		. '(?:[*)]\[?(?:rescinded 22 July 1999'
		. '|This condition was removed[.])\]?)?' . '[*)]'
		. $P{nopromo_neither}
		. '[.][  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'EXPORT LAWS[:] THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT LAWS',
	'pat.alt.subject.license.scope.line.scope.sentence.part.last' =>
		'THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT LAWS',
};

=item * ipa

I<Since v3.6.0.>

=cut

$RE{ipa} = {
	name                                            => 'IPA',
	'name.alt.org.fedora'                           => 'IPA',
	'name.alt.org.osi'                              => 'IPA',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ipafont',
	'name.alt.org.spdx'                             => 'IPA',
	'name.alt.org.tldr.path.short'                  => 'ipa',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38366264',
	caption                                         => 'IPA Font License',
	'caption.alt.org.tldr' => 'IPA Font License (IPA)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The Licensor provides the Licensed Program',
};

=item * ipl

=item * ipl_1

=cut

$RE{ipl} = {
	name                                              => 'IPL',
	'name.alt.org.fedora.synth.nogrant'               => 'IBM',
	'name.alt.org.osi.iri.stem.until.date_20110430'   => 'ibmpl',
	'name.alt.org.wikidata.synth.nogrant'             => 'Q288745',
	'name.alt.misc.fossology_old'                     => 'IBM-PL',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'IBM',
	caption                                           => 'IBM Public License',
	'caption.alt.org.trove'                           => 'IBM Public License',
	'caption.alt.org.wikipedia'                       => 'IBM Public License',
	tags                                              => [
		'type:versioned:decimal',
	],
};

$RE{ipl_1} = {
	name                             => 'IPL-1.0',
	'name.alt.org.osi'               => 'IPL-1.0',
	'name.alt.org.spdx'              => 'IPL-1.0',
	'name.alt.org.tldr.path.short'   => 'ipl',
	caption                          => 'IBM Public License v1.0',
	'caption.alt.org.osi'            => 'IBM Public License 1.0',
	'caption.alt.org.osi.misc.list'  => 'IBM Public License Version 1.0',
	'caption.alt.org.tldr'           => 'IBM Public License 1.0 (IPL)',
	'caption.alt.misc.legal'         => 'IBM Public License Version 1.0',
	'caption.alt.misc.fossology_old' => 'IBM-PL 1.0',
	description                      => <<'END',
Origin: Possibly Lucent Public License Version 1.0
END
	tags => [
		'type:singleversion:ipl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' => 'UNDER THE TERMS OF THIS IBM',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:IBM Public License Version 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS IBM PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. 'ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[\']S ACCEPTANCE OF THIS AGREEMENT[.][  ]'
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of International Business Machines Corporation [(]["]IBM["][)], the Original Program',
};

=item * isc

=cut

$RE{isc} = {
	name                  => 'ISC',
	'name.alt.org.fedora' => 'ISC',
	'name.alt.org.osi'    => 'ISC',
	'name.alt.org.osi.iri.stem_plain.until.date_20110430.archive.time_20110426131805'
		=> 'isc-license',
	'name.alt.org.spdx'                   => 'ISC',
	'name.alt.org.tldr'                   => '-isc-license',
	'name.alt.org.tldr.path.short'        => 'isc',
	'name.alt.org.trove'                  => 'ISCL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q386474',
	caption                               => 'ISC License',
	'caption.alt.misc.openbsd'            => 'OpenBSD License',
	'caption.alt.org.tldr'                => 'ISC License',
	'caption.alt.org.trove'               => 'ISC License (ISCL)',
	'caption.alt.org.wikidata'            => 'ISC license',
	'caption.alt.org.wikipedia'           => 'ISC license',
	'summary.alt.org.fedora' => 'ISC License (Bind, DHCP Server)',
	tags                     => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. '[.][  ]'
		. $P{asis_sw_name_discl},
};

=item * jabberpl

I<Since v3.5.0.>

=cut

$RE{jabberpl} = {
	name                                            => 'jabberpl',
	'name.alt.org.fedora'                           => 'Jabber',
	'name.alt.org.osi'                              => 'jabberpl',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'jabberpl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1149006',
	'name.alt.misc.fossology_old'                   => 'Jabber',
	caption                 => 'Jabber Open Source License',
	'caption.alt.org.trove' => 'Jabber Open Source License',
	tags                    => [
		'license:contains:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.intro' =>
		'This Jabber Open Source License [(]the ["]License["][)]'
		. ' applies to Jabber Server and related software products',
};

=item * json

I<Since v3.1.90.>

=cut

$RE{json} = {
	name                                    => 'JSON',
	'name.alt.org.spdx.since.date_20130117' => 'JSON',
	caption                                 => 'JSON License',
	'caption.alt.org.fedora'                => 'JSON License',
	'caption.alt.org.tldr'                  => 'The JSON License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'The Software shall be used for Good, not Evil[.]',
};

=item * jython

I<Since v3.1.90.>

=cut

$RE{jython} = {
	name                                    => 'Jython',
	'name.alt.org.spdx.since.date_20150730' => 'CNRI-Jython',
	caption                                 => 'Jython License',
	'caption.alt.org.spdx'                  => 'CNRI Jython License',
	'caption.alt.legal.license'             => 'The Jython License',
	iri  => 'http://www.jython.org/license.txt',
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'[*)]PSF is making Jython available to Licensee',
};

=item * kevlin_henney

I<Since v3.1.90.>

=cut

$RE{kevlin_henney} = {
	name    => 'Kevlin-Henney',
	caption => 'Kevlin Henney License',
	tags    => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perms_deriv}
		. '[.][  ]'
		. $P{asis_sw_expr_warranty},
};

=item * leptonica

I<Since v3.8.0.>

=cut

$RE{leptonica} = {
	name                                    => 'Leptonica',
	'name.alt.org.fedora.iri.self'          => 'Leptonica',
	'name.alt.org.spdx.since.date_20140807' => 'Leptonica',
	caption                                 => 'Leptonica License',
	description                             => <<'END',
Identical to Crossword License, except...
* Expand disclaimer slightly
* Replace "he" with "he or she"
* Extend permissions clause to explicitly permit commercial and non-commercial use
* Add source-no-misrepresentation clause
* Add mark-modified-source clause, replacing no-misrepresentation passage in permissions clause
* Add retain-notice clause
END
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'No author or distributor accepts responsibility to anyone '
		. 'for the consequences of using this software',
};

=item * lgpl

=item * lgpl_2

=item * lgpl_2_only

=item * lgpl_2_or_later

=item * lgpl_2_1

=item * lgpl_2_1_only

=item * lgpl_2_1_or_later

=item * lgpl_3

=item * lgpl_3_only

=item * lgpl_3_or_later

=cut

$RE{lgpl} = {
	name                                  => 'LGPL',
	'name.alt.org.fsf'                    => 'LGPL',
	'name.alt.org.osi'                    => 'lgpl-license',
	'name.alt.org.osi.misc.shortname'     => 'LGPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q192897',
	'name.alt.misc.fossology_old'         => 'CC_LGPL',
	caption               => 'GNU Lesser General Public License',
	'caption.alt.org.fsf' => 'GNU Lesser General Public License (LGPL)',
	'caption.alt.org.osi' => 'GNU LGPL',
	'caption.alt.org.osi.misc.list' => 'GNU Lesser General Public License',
	'caption.alt.org.trove'         =>
		'GNU Library or Lesser General Public License (LGPL)',
	'caption.alt.org.wikipedia'     => 'GNU Lesser General Public License',
	'caption.alt.org.osi'           => 'GNU LGPL',
	'caption.alt.org.osi.misc.list' => 'GNU Lesser General Public License',
	tags                            => [
		'type:versioned:decimal',
	],

	'_pat.alt.subject.name' => [
		"$the?$gnu?Library $gpl(?: [(]LGPL[)])?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?Lesser(?: [(]Library[)])? $gpl(?: [(]LGPL[)])?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?LIBRARY GENERAL PUBLIC LICEN[CS]E(?: [(]LGPL[)])?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?LESSER GENERAL PUBLIC LICEN[CS]E(?: [(]LGPL[)])?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the$gnu?LGPL",
		"${gnu}LGPL",
	],
};

$RE{lgpl_2} = {
	name                                  => 'LGPL-2',
	'name.alt.misc.short'                 => 'LGPLv2',
	'name.alt.org.debian'                 => 'LGPL-2',
	'name.alt.org.fsf'                    => 'LGPLv2.0',
	'name.alt.org.osi'                    => 'LGPL-2.0',
	'name.alt.org.trove'                  => 'LGPLv2',
	'name.alt.org.wikidata.synth.nogrant' => 'Q23035974',
	'name.alt.misc.fossology_old'         => 'LGPL_v2',
	caption => 'GNU Library General Public License, Version 2.0',
	'caption.alt.org.fsf' =>
		'GNU Library General Public License (LGPL) version 2.0',
	'caption.alt.org.osi'   => 'GNU Library General Public License version 2',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v2 (LGPLv2)',
	'caption.alt.org.wikidata' =>
		'GNU Library General Public License, version 2.0',
	iri                  => 'https://www.gnu.org/licenses/lgpl-2.0.html',
	'iri.alt.format.txt' => 'https://www.gnu.org/licenses/lgpl-2.0.txt',
	tags                 => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:lgpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.preample' =>
		'This license, the Library General Public License, applies to',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This library is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU Library General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 2 of the License, or',
};

$RE{lgpl_2_only} = {
	name                                                  => 'LGPL-2-only',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'LGPL-2.0',
	'name.alt.org.spdx.since.date_20171228'               => 'LGPL-2.0-only',
	caption => 'GNU Library General Public License v2 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2:only',
	],
};

$RE{lgpl_2_or_later} = {
	name                                    => 'LGPL-2-or-later',
	'name.alt.org.fedora.synth.nogrant'     => 'LGPLv2+',
	'name.alt.org.debian'                   => 'LGPL-2+',
	'name.alt.org.spdx.until.date_20150513' => 'LGPL-2.0+',
	'name.alt.org.spdx.since.date_20171228' => 'LGPL-2.0-or-later',
	'name.alt.org.trove'                    => 'LGPLv2+',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016756',
	'name.alt.misc.fossology_old'           => 'LGPL_v2+',
	caption => 'GNU Library General Public License v2 or later',
	'caption.alt.org.fedora' =>
		'GNU Lesser General Public License v2 (or 2.1) or later',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v2 or later (LGPLv2+)',
	'caption.alt.org.wikidata' =>
		'GNU Library General Public License, version 2.0 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2:or_later',
	],
};

$RE{lgpl_2_1} = {
	name                                            => 'LGPL-2.1',
	'name.alt.misc.short'                           => 'LGPLv2.1',
	'name.alt.org.fsf'                              => 'LGPLv2.1',
	'name.alt.org.osi'                              => 'LGPL-2.1',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'lgpl-2.1',
	'name.alt.org.perl'                             => 'lgpl_2_1',
	'name.alt.org.tldr.path.short'                  => 'lgpl2',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q18534390',
	'name.alt.misc.fossology_old'                   => 'CC_LGPL_v2.1',
	'name.alt.misc.fossology_old'                   => 'LGPL_v2.1',
	'name.alt.misc.fossology_old_cc'                => 'CCGPL2.1',
	'name.alt.misc.fossology_old_short'             => 'LGPL2.1',
	caption => 'GNU Lesser General Public License, Version 2.1',
	'caption.alt.org.cc.until.date_20100912' =>
		'Creative Commons GNU LGPL',    # TODO: find official date
	'caption.alt.org.cc.misc.short.until.date_20100912' =>
		'CC-GNU LGPL',                  # TODO: find official date
	'caption.alt.org.fedora.misc.cc' => 'Creative Commons GNU LGPL',
	'caption.alt.org.fsf'            =>
		'GNU Lesser General Public License (LGPL) version 2.1',
	'caption.alt.org.osi'  => 'GNU Lesser General Public License version 2.1',
	'caption.alt.org.tldr' =>
		'GNU Lesser General Public License v2.1 (LGPL-2.1)',
	'caption.alt.org.wikidata' =>
		'GNU Lesser General Public License, version 2.1',
	'caption.alt.misc.uppercase' => 'GNU LESSER GENERAL PUBLIC LICENSE',
	iri                  => 'https://www.gnu.org/licenses/lgpl-2.1.html',
	'iri.alt.format.txt' => 'https://www.gnu.org/licenses/lgpl-2.1.txt',
	'iri.alt.org.cc.archive.time_20101027034910.until.date_20101027' =>
		'http://creativecommons.org/licenses/LGPL/2.1/'
	,    # TODO: find official date
	'iri.alt.org.cc.archive.time_20100912081720.until.date_20100912' =>
		'http://creativecommons.org/choose/cc-lgpl'
	,    # TODO: find official date
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:lgpl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.part.preample' =>
		'This license, the Lesser General Public License, applies to',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This library is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU Lesser General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 2\.1 of the License, or',
};

$RE{lgpl_2_1_only} = {
	name                                                  => 'LGPL-2.1-only',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'LGPL-2.1',
	'name.alt.org.spdx.since.date_20171228'               => 'LGPL-2.1-only',
	caption => 'GNU Lesser General Public License v2.1 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2_1:only',
	],
};

$RE{lgpl_2_1_or_later} = {
	name                                    => 'LGPL-2.1-or-later',
	'name.alt.org.debian'                   => 'LGPL-2.1+',
	'name.alt.org.spdx.until.date_20150513' => 'LGPL-2.1+',
	'name.alt.org.spdx.since.date_20171228' => 'LGPL-2.1-or-later',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016757',
	'name.alt.misc.fossology_old'           => 'LGPL_v2.1+',
	caption => 'GNU Lesser General Public License v2.1 or later',
	'caption.alt.org.wikidata' =>
		'GNU Lesser General Public License, version 2.1 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2_1:or_later',
	],
};

$RE{lgpl_3} = {
	name                                            => 'LGPL-3',
	'name.alt.misc.short'                           => 'LGPLv3',
	'name.alt.org.debian'                           => 'LGPL-3',
	'name.alt.org.fsf'                              => 'LGPLv3',
	'name.alt.org.osi'                              => 'LGPL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'lgpl-3.0',
	'name.alt.org.perl'                             => 'lgpl_3_0',
	'name.alt.org.tldr' => 'gnu-lesser-general-public-license-v3-(lgpl-3)',
	'name.alt.org.tldr.path.short'        => 'lgpl-3.0',
	'name.alt.org.trove'                  => 'LGPLv3',
	'name.alt.org.wikidata.synth.nogrant' => 'Q18534393',
	'name.alt.misc.fossology_old'         => 'LGPL_v3',
	'name.alt.misc.fossology_old_short'   => 'LGPL3.0',
	caption               => 'GNU Lesser General Public License, Version 3',
	'caption.alt.org.fsf' =>
		'GNU Lesser General Public License (LGPL) version 3',
	'caption.alt.org.osi'  => 'GNU Lesser General Public License version 3',
	'caption.alt.org.perl' =>
		'GNU Lesser General Public License, Version 3.0',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v3 (LGPLv3)',
	'caption.alt.org.osi'  => 'GNU Lesser General Public License version 3',
	'caption.alt.org.tldr' =>
		'GNU Lesser General Public License v3 (LGPL-3.0)',
	'caption.alt.org.wikidata' =>
		'GNU Lesser General Public License, version 3.0',
	iri                  => 'https://www.gnu.org/licenses/lgpl-3.0.html',
	'iri.alt.format.txt' => 'https://www.gnu.org/licenses/lgpl-3.0.txt',
	tags                 => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:lgpl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license' =>
		'["][Tt]his License["] refers to version 3 of the GNU Lesser General',
};

$RE{lgpl_3_only} = {
	name                                                  => 'LGPL-3.0-only',
	'name.alt.org.fedora.synth.nogrant'                   => 'LGPLv3',
	'name.alt.org.spdx.until.date_20171228.synth.nogrant' => 'LGPL-3.0',
	'name.alt.org.spdx.since.date_20171228'               => 'LGPL-3.0-only',
	caption => 'GNU Lesser General Public License v3.0 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_3:only',
	],
};

$RE{lgpl_3_or_later} = {
	name                                    => 'LGPL-3.0-or-later',
	'name.alt.org.fedora'                   => 'LGPLv3+',
	'name.alt.org.debian'                   => 'LGPL-3+',
	'name.alt.org.spdx.until.date_20150513' => 'LGPL-3.0+',
	'name.alt.org.spdx.since.date_20171228' => 'LGPL-3.0-or-later',
	'name.alt.org.trove'                    => 'LGPLv3+',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q27016762',
	'name.alt.misc.fossology_old'           => 'LGPL_v3+',
	caption => 'GNU Lesser General Public License v3.0 or later',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v3 or later (LGPLv3+)',
	'caption.alt.org.wikidata' =>
		'GNU Lesser General Public License, version 3.0 or later',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_3:or_later',
	],
};

=item * lgpl_bdwgc

I<Since v3.1.0.>

=cut

$RE{lgpl_bdwgc} = {
	name    => 'LGPL-bdwgc',
	caption =>
		'GNU Lesser General Public License (modified-code-notice clause)',
	summary =>
		'The GNU Lesser General Public License, with modified-code-notice clause',
	description => <<'END',
Origin: Possibly Boehm-Demers-Weiser conservative C/C++ Garbage Collector (libgc, bdwgc, boehm-gc).
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{perm_granted}
		. $P{to_copy_prg}
		. "under the terms of $the${gnu}LGPL, "
		. $P{retain_copr_avail_orig}
		. '[.][  ]'
		. $P{repro_code_modcode_cite_copr_avail_note}
		. $P{and_used_by_perm} . '[". ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_copr_avail_note}
		. $P{note_mod_inc} . '[.]',
	'pat.alt.subject.license.part.credit' => 'code must cite the Copyright',
};

=item * libpng

=cut

$RE{libpng} = {
	name                                  => 'Libpng',
	'name.alt.org.spdx'                   => 'Libpng',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6542418',
	caption                               => 'libpng License',
	'caption.alt.org.wikidata'            => 'Libpng License',
	tags                                  => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_src_no_misrepresent}
		. '[.][  ]'
		. $P{altered_ver_mark}
		. '[.][  ]'
		. $P{copr_no_alter},
};

=item * libtiff

I<Since v3.8.0.>

=cut

$RE{libtiff} = {
	name                                    => 'libtiff',
	'name.alt.org.fedora.iri.self'          => 'libtiff',
	'name.alt.org.fedora.iri.mit_short'     => 'Hylafax',
	'name.alt.org.spdx.since.date_20140807' => 'libtiff',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q105688056',
	caption                                 => 'libtiff License',
	'caption.alt.org.tldr'                  => 'libtiff License',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Hylafax Variant',
	tags                             => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'relating to the software without the specific',
};

=item * liliq_p

I<Since v3.6.0.>

=item * liliq_p_1_1

I<Since v3.6.0.>

=cut

$RE{liliq_p} = {
	name                                  => 'LiLiQ-P',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38493399',
	caption => 'Licence Libre du Québec – Permissive (LiLiQ-P)',
	'caption.alt.org.wikidata' => 'Licence Libre du Québec – Permissive',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{liliq_p_1_1} = {
	name                                    => 'LiLiQ-P-1.1',
	'name.alt.org.osi'                      => 'LiLiQ-P-1.1',
	'name.alt.org.spdx.since.date_20160323' => 'LiLiQ-P-1.1',
	caption => 'Licence Libre du Québec – Permissive version 1.1',
	'caption.alt.org.osi' =>
		'Licence Libre du Québec – Permissive (LiLiQ-P) version 1.1',
	tags => [
		'type:singleversion:liliq_p',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part8' =>
		'Le conc[é]dant ne saurait [ê]tre tenu responsable de dommages subis',
	'pat.alt.subject.license.scope.line.scope.sentence.part.part9' =>
		'La pr[é]sente licence est automatiquement r[é]sili[é]e',
};

=item * liliq_r

I<Since v3.6.0.>

=item * liliq_r_1_1

I<Since v3.6.0.>

=cut

$RE{liliq_r} = {
	name                                  => 'LiLiQ-R',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38490890',
	caption => 'Licence Libre du Québec – Réciprocité (LiLiQ-R)',
	'caption.alt.org.wikidata' =>
		'Licence Libre du Québec – Réciprocité',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{liliq_r_1_1} = {
	name                                    => 'LiLiQ-R-1.1',
	'name.alt.org.osi'                      => 'LiLiQ-R-1.1',
	'name.alt.org.spdx.since.date_20160323' => 'LiLiQ-R-1.1',
	caption => 'Licence Libre du Québec – Réciprocité version 1.1',
	'caption.alt.org.osi' =>
		'Licence Libre du Québec – Réciprocité (LiLiQ-R) version 1.1',
	tags => [
		'license:contains:name:cddl_1',
		'license:contains:name:cecill_2_1',
		'license:contains:name:cecill_c',
		'license:contains:name:cpl_1',
		'license:contains:name:epl_1',
		'license:contains:name:eupl_1_1',
		'license:contains:name:gpl_2',
		'license:contains:name:gpl_3',
		'license:contains:name:lgpl_2_1',
		'license:contains:name:lgpl_3',
		'license:contains:name:liliq_r_plus_1_1',
		'license:contains:name:mpl_2',
		'type:singleversion:liliq_r',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part4_1' =>
		'Chaque fois que le licenci[é] distribue le logiciel ou un logiciel modifi[é]',
};

=item * liliq_r_plus

I<Since v3.6.0.>

=item * liliq_r_plus_1_1

I<Since v3.6.0.>

=cut

$RE{liliq_r_plus} = {
	name                                  => 'LiLiQ-R+',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38493724',
	caption => 'Licence Libre du Québec – Réciprocité forte (LiLiQ-R+)',
	'caption.alt.org.wikidata' =>
		'Licence Libre du Québec – Réciprocité forte',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{liliq_r_plus_1_1} = {
	name                                    => 'LiLiQ-R+-1.1',
	'name.alt.org.osi'                      => 'LiLiQ-Rplus-1.1',
	'name.alt.org.spdx.since.date_20160323' => 'LiLiQ-Rplus-1.1',
	caption => 'Licence Libre du Québec – Réciprocité forte version 1.1',
	'caption.alt.org.osi' =>
		'Licence Libre du Québec – Réciprocité forte (LiLiQ-R+) version 1.1',
	tags => [
		'license:contains:name:cecill_2_1',
		'license:contains:name:cpl_1',
		'license:contains:name:epl_1',
		'license:contains:name:eupl_1_1',
		'license:contains:name:gpl_2',
		'license:contains:name:gpl_3',
		'type:singleversion:liliq_r_plus',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part4_1' =>
		'Chaque fois que le licenci[é] distribue le logiciel, un logiciel modifi[é], ou',
};

=item * llgpl

=cut

$RE{llgpl} = {
	name                     => 'LLGPL',
	'name.alt.org.fedora'    => 'LLGPL',
	'name.alt.org.tldr'      => 'lisp-lesser-general-public-license',
	caption                  => 'Lisp Lesser General Public License',
	'caption.alt.org.fedora' => 'Lisp Library General Public License',
	'caption.alt.org.tldr'   => 'Lisp Lesser General Public License (LLGPL)',
	iri                      => 'http://opensource.franz.com/preamble.html',
	'iri.alt.misc.cliki'     => 'http://www.cliki.net/LLGPL',
	tags                     => [
		'license:contains:license:lgpl_2_1',
		'type:unversioned',
	],
};

=item * lpl

I<Since v3.6.0.>

=item * lpl_1

I<Since v3.6.0.>

=item * lpl_1_02

I<Since v3.6.0.>

=cut

$RE{lpl} = {
	name                                            => 'LPL',
	'name.alt.org.fedora'                           => 'LPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'plan9',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q6696468',
	caption                  => 'Lucent Public License',
	'caption.alt.org.fedora' => 'Lucent Public License (Plan9)',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{lpl_1} = {
	name                                => 'LPL-1.0',
	'name.alt.org.osi'                  => 'LPL-1.0',
	'name.alt.org.spdx'                 => 'LPL-1.0',
	'name.alt.misc.fossology_old'       => 'Lucent_v1.0',
	'name.alt.misc.fossology_old_short' => 'Lucent1.0',
	caption               => 'Lucent Public License Version 1.0',
	'caption.alt.org.osi' => 'Lucent Public License, Plan 9, version 1.0',
	'caption.alt.org.spdx.until.date_20130117' =>
		'Lucent Public License Version 1.0 (Plan9)',
	'caption.alt.org.spdx.since.date_20130117' =>
		'Lucent Public License Version 1.0',
	'caption.alt.org.osi.misc.list' =>
		'Lucent Public License ("Plan9"), version 1.0',
	tags => [
		'type:singleversion:lpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Lucent Public License Version 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.][  ]"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of[ word]{0,15}, the Original Program, and[ ]'
		. '[*)]in the case of each Contributor,[  ]'
		. '[*)]changes to the Program, and[ ]'
		. '[*)]additions to the Program[;]'
		. '[ ]where such changes and[/]or additions to the Program originate from',
};

$RE{lpl_1_02} = {
	name                                            => 'LPL-1.02',
	'name.alt.org.osi'                              => 'LPL-1.02',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'lucent1.02',
	'name.alt.org.spdx'                             => 'LPL-1.02',
	'name.alt.misc.fossology_old'                   => 'Lucent_v1.02',
	'name.alt.misc.fossology_old_short'             => 'Lucent1.02',
	caption                => 'Lucent Public License v1.02',
	'caption.alt.org.osi'  => 'Lucent Public License Version 1.02',
	'caption.alt.org.tldr' => 'Lucent Public License v1.02 (LPL-1.02)',
	description            => <<'END',
Identical to Lucent Public License Version 1.0, except...
* rephrase Contribution definition
* rephrase Contributor identification clause in section 3.C
* add export-control clause as section 7
END
	tags => [
		'type:singleversion:lpl',
	],
	licenseversion => '1.02',

	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Lucent Public License Version 1\.02[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS PUBLIC LICENSE [(]["]AGREEMENT["][)][. ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.][  ]"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of Lucent Technologies Inc\. [(]["]LUCENT["][)], the Original Program, and[ ]'
		. '[*)]in the case of each Contributor,[  ]'
		. '[*)]changes to the Program, and[ ]'
		. '[*)]additions to the Program[;]'
		. '[  ]where such changes and[/]or additions to the Program were added',
};

=item * lppl

=item * lppl_1

=item * lppl_1_1

=item * lppl_1_2

=item * lppl_1_3a

=item * lppl_1_3c

=cut

$RE{lppl} = {
	name                                            => 'LPPL',
	'name.alt.org.fedora'                           => 'LPPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'lppl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1050635',
	caption                     => 'LaTeX Project Public License',
	'caption.alt.org.wikipedia' => 'LaTeX Project Public License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{lppl_1} = {
	name                                => 'LPPL-1.0',
	'name.alt.org.spdx'                 => 'LPPL-1.0',
	'name.alt.misc.fossology_old'       => 'LPPL_v1.0',
	'name.alt.misc.fossology_old_short' => 'LaTeX1.0',
	caption                             => 'LaTeX Project Public License 1',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.0',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' => 'LPPL Version 1\.0 1999[-]03[-]01',
};

$RE{lppl_1_1} = {
	name                                => 'LPPL-1.1',
	'name.alt.org.spdx'                 => 'LPPL-1.1',
	'name.alt.misc.fossology_old'       => 'LPPL_v1.1',
	'name.alt.misc.fossology_old_short' => 'LaTeX1.1',
	caption                             => 'LaTeX Project Public License 1.1',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.1',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' => 'LPPL Version 1\.1 1999[-]07[-]10',
};

$RE{lppl_1_2} = {
	name                                => 'LPPL-1.2',
	'name.alt.org.spdx'                 => 'LPPL-1.2',
	'name.alt.misc.fossology_old'       => 'LPPL_v1.2',
	'name.alt.misc.fossology_old_short' => 'LaTeX1.2',
	caption                             => 'LaTeX Project Public License 1.2',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.2',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license' => 'LPPL Version 1\.2 1999[-]09[-]03',
};

$RE{lppl_1_3a} = {
	name                                    => 'LPPL-1.3a',
	'name.alt.org.spdx.since.date_20130117' => 'LPPL-1.3a',
	'name.alt.misc.fossology_old'           => 'LPPL_v1.3a',
	'name.alt.misc.fossology_old_short'     => 'LaTeX1.3a',
	caption => 'LaTeX Project Public License 1.3a',
	'caption.alt.org.spdx.until.date_20160103' =>
		'LaTeX Project Public License 1.3a',
	'caption.alt.org.spdx.since.date_20160103' =>
		'LaTeX Project Public License v1.3a',
	tags => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.3a',

	'pat.alt.subject.license' => 'LPPL Version 1\.3a 2004[-]10[-]01',
};

$RE{lppl_1_3c} = {
	name                                => 'LPPL-1.3c',
	'name.alt.org.osi'                  => 'LPPL-1.3c',
	'name.alt.org.spdx'                 => 'LPPL-1.3c',
	'name.alt.misc.fossology_old'       => 'LPPL_v1.3c',
	'name.alt.misc.fossology_old_short' => 'LaTeX1.3c',
	caption               => 'LaTeX Project Public License 1.3c',
	'caption.alt.org.osi' => 'LaTeX Project Public License, Version 1.3c',
	'caption.alt.org.osi.misc.list' => 'LaTeX Project Public License 1.3c',
	'caption.alt.org.spdx'          => 'LaTeX Project Public License v1.3c',
	'caption.alt.org.tldr'          =>
		'LaTeX Project Public License v1.3c (LPPL-1.3c)',
	iri  => 'https://www.latex-project.org/lppl.txt',
	tags => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.3c',

	'pat.alt.subject.license' => 'LPPL Version 1\.3c 2008[-]05[-]04',
};

=item * miros

I<Since v3.6.0.>

=cut

$RE{miros} = {
	name                                            => 'MirOS',
	'name.alt.org.fedora'                           => 'MirOS',
	'name.alt.org.osi'                              => 'MirOS',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'miros',
	'name.alt.org.spdx'                             => 'MirOS',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1951343',
	caption                                         => 'The MirOS License',
	'caption.alt.org.fedora'                        => 'MirOS License',
	'caption.alt.org.osi'                           => 'MirOS Licence',
	'caption.alt.org.spdx.until.date_20171228'      => 'MirOS Licence',
	'caption.alt.org.spdx.since.date_20171228.until.date_20191022' =>
		'MirOS License',
	'caption.alt.org.spdx.since.date_20191022' => 'The MirOS License',
	'caption.alt.org.tldr'                     => 'MirOS License (MirOS)',
	'caption.alt.org.trove'                    => 'MirOS License (MirOS)',
	'caption.alt.org.wikidata'                 => 'MirOS Licence',
	tags                                       => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'merge, give away, or sublicence',
};

=item * mit_0

I<Since v3.6.0.>

=cut

$RE{mit_0} = {
	name                                               => 'MIT-0',
	'name.alt.org.fedora.iri.self.since.date_20210215' => 'MIT-0',
	'name.alt.org.osi'                                 => 'MIT-0',
	'name.alt.org.spdx.since.date_20180414'            => 'MIT-0',
	'name.alt.org.wikidata.synth.nogrant'              => 'Q67538600',
	caption                                      => 'MIT No Attribution',
	'caption.alt.org.fedora.since.date_20210215' =>
		'MIT No Attribution (MIT-0)',
	'caption.alt.org.osi'      => 'MIT No Attribution License',
	'caption.alt.org.trove'    => 'MIT No Attribution License (MIT-0)',
	'caption.alt.org.wikidata' => 'MIT No Attribution License',
	description                => <<'END',
Identical to MIT (Expat), except...
* omit retention clause
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'to whom the Software is furnished to do so[.][  ]'
		. $P{asis_sw_warranty},
};

=item * mit_advertising

=cut

$RE{mit_advertising} = {
	name                                    => 'MIT-advertising',
	'name.alt.org.spdx.since.date_20140807' => 'MIT-advertising',
	caption                                 => 'Enlightenment License (e16)',
	'caption.alt.org.fedora.iri.self'       => 'MIT With Advertising',
	tags                                    => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => $P{note_marketing}
		. '\b[^.,]+, and '
		. $P{ack_doc_mat_pkg_use},
};

=item * mit_cmu

=cut

$RE{mit_cmu} = {
	name                                    => 'MIT-CMU',
	'name.alt.org.spdx.since.date_20140807' => 'MIT-CMU',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q2939745',
	caption                                 => 'CMU License',
	'caption.alt.org.fedora'                => 'CMU License (BSD like)',
	'caption.alt.org.fedora.iri.mit'        => 'CMU Style',
	'caption.alt.org.tldr'                  => 'CMU License',
	'caption.alt.org.wikidata' => 'Carnegie Mellon University License',
	description                => <<'END',
Identical to NTP, except...
* omit explicit permission for charging fee
* exclude suitability disclaimer
* exclude terse "as is" warranty disclaimer
* include elaborate warranty disclaimer
* include liability disclaimer

SPDX and fedora sample seem not generic but the unique file COPYING from project net-snmp.
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => 'Permission '
		. $P{to_dist}
		. $P{sw_doc_nofee}
		. $P{granted}
		. $P{retain_copr_appear}
		. ' and that '
		. $P{repro_copr_perm_appear_doc}
		. ', and that '
		. $P{nopromo_name_written} . '[.]',
	'pat.alt.subject.license.part.endorsement' =>
		'without specific written permission',
};

=item * mit_cmu_warranty

=cut

$RE{mit_cmu_warranty} = {
	name                                    => 'SMLNJ',
	'name.alt.org.debian'                   => 'MIT-CMU~warranty',
	'name.alt.org.spdx.since.date_20130117' => 'SMLNJ',
	'name.alt.org.spdx.misc.long.since.date_20140807.until.date_20150513' =>
		'StandardML-NJ',
	'name.alt.org.wikidata.synth.nogrant' => 'Q99635287',
	caption                => 'Standard ML of New Jersey License',
	'caption.alt.org.tldr' => 'Standard ML of New Jersey License (SMLNJ)',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, Standard ML of New Jersey Variant',
	'summary.alt.org.fedora.iri.mit_semishort' =>
		'MIT-style license, MLton variant',
	description => <<'END',
Identical to MIT-CMU, except...
* add requirement of "warranty disclaimer" appearing in documentation
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => 'Permission '
		. $P{to_dist}
		. $P{sw_doc_nofee}
		. $P{granted}
		. $P{retain_copr_appear}
		. ' and that '
		. $P{repro_copr_perm_warr_appear_doc}
		. ', and that '
		. $P{nopromo_name_written_prior} . '[.]',
	'pat.alt.subject.license.part.disclaimer' => 'warranty disclaimer appear',
};

=item * mit_enna

=cut

$RE{mit_enna} = {
	name                                    => 'MIT-enna',
	'name.alt.org.fedora.iri.mit_short'     => 'enna',
	'name.alt.org.spdx.since.date_20140807' => 'MIT-enna',
	caption                                 => 'enna License',
	'caption.alt.org.tldr'                  => 'enna License',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, enna variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.section' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_sw}
		. $P{to_deal_the_sw_rights}
		. $P{subj_cond}
		. $P{to_copy_sublicence_conditions}
		. '[:]?[ ]'
		. $P{retain_copr_perm_sw_copr} . '[. ]'
		. $P{ack_pub_use_nosrc} . '[. ]'
		. 'This includes acknowledgments '
		. 'in either Copyright notices, Manuals, Publicity and Marketing documents '
		. 'or any documentation provided '
		. 'with any product containing this software[. ]'
		. $P{license_not_lib} . '[.]',
	'pat.alt.subject.license.scope.line' => $P{ack_pub_use_nosrc},
};

=item * mit_epinions

I<Since v3.7.0.>

=cut

$RE{mit_epinions} = {
	'name.alt.org.debian'            => 'MIT~Epinions',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Epinions Variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Subject to the following 3 conditions',
};

=item * mit_feh

=cut

$RE{mit_feh} = {
	name                                    => 'MIT-feh',
	'name.alt.org.fedora.iri.mit_short'     => 'feh',
	'name.alt.org.spdx.since.date_20140807' => 'MIT-feh',
	caption                                 => 'feh License',
	'caption.alt.org.tldr'                  => 'feh License',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, feh variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_sw}
		. $P{to_deal_the_sw_rights}
		. $P{to_copy_sublicence_conditions}
		. '[:]?[ ]'
		. $P{retain_copr_perm_sw_doc} . ' and '
		. $P{ack_doc_pkg_use} . '[.]',
};

=item * mit_new

=cut

$RE{mit_new} = {
	'name.alt.org.debian'                           => 'Expat',
	'name.alt.org.osi'                              => 'MIT',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'mit-license',
	'name.alt.org.perl'                             => 'mit',
	'name.alt.org.spdx'                             => 'MIT',
	'name.alt.org.tldr'                             => 'mit-license',
	'name.alt.org.tldr.path.short'                  => 'mit',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q18526198',
	caption                                         => 'MIT License',
	'caption.alt.org.debian'                        => 'Expat License',
	'caption.alt.org.fedora'            => 'MIT license (also X11)',
	'caption.alt.org.osi'               => 'The MIT License',
	'caption.alt.org.osi.misc.list'     => 'MIT License',
	'caption.alt.org.osi.misc.cat_list' => 'MIT license',
	'caption.alt.org.perl'              => 'MIT (aka X11) License',
	'caption.alt.org.tldr'              => 'MIT License (Expat)',
	'summary.alt.org.fedora.iri.mit'    =>
		'MIT-style license, Modern Style with sublicense',
	'caption.alt.org.wikidata'    => 'Expat license',
	'caption.alt.org.wikipedia'   => 'MIT License',
	'caption.alt.misc.wayland'    => 'the MIT Expat license',
	'caption.alt.misc.mono'       => 'the MIT X11 license',
	'caption.alt.misc.mono_slash' => 'the MIT/X11 license',
	iri                           => 'http://www.jclark.com/xml/copying.txt',
	description                   => <<'END',
Origin: X11 Licene

Identical to X11 License, except...
* drop non-endorsement clause at the end
* drop trademark notice at the end
END
	tags => [
		'family:mit',
		'license:is:grant',
		'license:published:by_james_clark',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{to_copy_sublicence_conditions}
		. '[:][ ]'
		. $P{retain_copr_perm_subst},
};

=item * mit_new_materials

=cut

$RE{mit_new_materials} = {
	name    => 'Khronos',
	caption => 'Khronos License',
	tags    => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_material}
		. $P{to_deal_mat},
};

=item * mit_old

=cut

$RE{mit_old} = {
	'name.alt.org.debian' => 'MIT~old',
	'name.alt.org.gentoo' => 'Old-MIT',
	caption               => 'MIT (old)',
	tags                  => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => $P{perm_granted} . $P{free_agree_fee},
};

=item * mit_oldstyle

=cut

$RE{mit_oldstyle} = {
	'name.alt.org.debian'            => 'MIT~oldstyle',
	caption                          => 'MIT (Old Style)',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Old Style',
	description                      => <<'END',
Origin: Possibly by Jamie Zawinski in 1993 for xscreensaver.
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		'documentation[. ]No representations are made',
};

=item * mit_oldstyle_disclaimer

=cut

$RE{mit_oldstyle_disclaimer} = {
	'name.alt.org.debian'            => 'MIT~oldstyle~disclaimer',
	caption                          => 'MIT (Old Style, legal disclaimer)',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, Old Style with legal disclaimer',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		'supporting documentation[.][  ]' . $P{asis_name_sw},
};

=item * mit_oldstyle_permission

=cut

$RE{mit_oldstyle_permission} = {
	'name.alt.org.debian'            => 'MIT~oldstyle~permission',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, Old Style (no advertising without permission)',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{without_written_prior}
		. '[.][  ]'
		. $P{asis_name_sw},
};

=item * mit_open_group

I<Since v3.6.0.>

=cut

$RE{mit_open_group} = {
	name                                    => 'MIT-Open-Group',
	'name.alt.org.spdx.since.date_20201125' => 'MIT-Open-Group',
	caption                                 => 'MIT Open Group variant',
	description                             => <<'END',
Identical to NTP, except...
* add explicit permission to sell
* omit explicit permission to charge or not charge fee
* extend permissions with note that they are granted without fee
* add retain-copyright-notices clause
* rephrase disclaimers
* rephrase non-endorsement clause and move it to the end
END
	tags => [
		'family:mit',
		'license:contains:license:hpnd_sell',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' =>
		'Permission to use, copy, modify, distribute, and sell '
		. 'this software and its documentation '
		. 'for any purpose is hereby granted without fee, '
		. 'provided that the above copyright notice appears? in all copies,?(?: and)? '
		. 'that both(?: that)?(?: the)? copyright notice '
		. 'and this permission notice appear in supporting documentation[.]',
};

=item * mit_openvision

I<Since v3.7.0.>

=cut

$RE{mit_openvision} = {
	'name.alt.org.debian'            => 'MIT~OpenVision',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, OpenVision Variant',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'You may freely use and distribute the Source Code and Object Code',
};

=item * mit_osf

I<Since v3.7.0.>

=cut

$RE{mit_osf} = {
	'name.alt.org.debian'            => 'MIT~OSF',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, HP Variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'To anyone who acknowledges that this file is provided',
};

=item * mit_unixcrypt

I<Since v3.7.0.>

=cut

$RE{mit_unixcrypt} = {
	'name.alt.org.debian'            => 'MIT~UnixCrypt',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, UnixCrypt Variant',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'for non-commercial or commercial purposes and without fee',
};

=item * mit_whatever

I<Since v3.7.0.>

=cut

$RE{mit_whatever} = {
	'name.alt.org.debian'            => 'MIT~whatever',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Whatever Variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'and to alter it and redistribute it freely[.]',
};

=item * mit_widget

I<Since v3.7.0.>

=cut

$RE{mit_widget} = {
	'name.alt.org.debian'            => 'MIT~Widget',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Nuclear Variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'its documentation for NON-COMMERCIAL or COMMERCIAL purposes',
};

=item * mit_xfig

I<Since v3.7.0.>

=cut

$RE{mit_xfig} = {
	'name.alt.org.debian'               => 'MIT~Xfig',
	'name.alt.org.fedora.iri.mit_short' => 'Xfig',
	'summary.alt.org.fedora.iri.mit'    => 'MIT-style license, Xfig Variant',
	tags                                => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Any party obtaining a copy of these files is granted, free of charge',
};

=item * motosoto

I<Since v3.5.0.>

=cut

$RE{motosoto} = {
	name                                            => 'Motosoto',
	'name.alt.org.fedora'                           => 'Motosoto',
	'name.alt.org.osi'                              => 'Motosoto',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'motosoto',
	'name.alt.org.spdx'                             => 'Motosoto',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38494497',
	'name.alt.misc.fossology_old'                   => 'Motosoto_v0.9.1',
	caption                                         => 'Motosoto License',
	'caption.alt.org.osi' => 'Motosoto Open Source License - Version 0.9.1',
	'caption.alt.org.osi.misc.list' => 'Motosoto License',
	'caption.alt.org.trove'         => 'Motosoto License',
	'caption.alt.org.wikidata'      => 'Motosoto Open Source License',
	description                     => <<'END',
Identical to Jabber Open Source License, except...
* rephrase grant clause to explicitly cover whole product (not only modified parts)
* extend grant clause to explicitly cover creation of derivative works
* replace references, e.g. "Jabber Server" -> "Community Portal Server"
* document that license is derived from Jabber Open Source License
* drop some disclaimers
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.part.header' =>
		'MOTOSOTO OPEN SOURCE LICENSE[ - ]Version 0\.9\.1',
	'pat.alt.subject.license.part.intro' =>
		'This Motosoto Open Source License [(]the ["]License["][)]'
		. ' applies to ["]Community Portal Server["] and related software products',
	'pat.alt.subject.license.scope.multisection.part.part7' =>
		'Versions of This License'
		. '[.][  ][*)]'
		. 'Version[. ]The Motosoto Open Source License is derived',
};

=item * mpich2

I<Since v3.8.0.>

=cut

$RE{mpich2} = {
	name                                    => 'mpich2',
	'name.alt.org.spdx.since.date_20140807' => 'mpich2',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q17070027',
	caption                                 => 'mpich2 License',
	'caption.alt.org.fedora'                => 'mpich2 License',
	'caption.alt.org.wikidata'              => 'MPICH2 license',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, mpich2 variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{to_reproduce} . '[. ]'
		. 'This software was authored by',
};

=item * mpl

=item * mpl_1

I<Since v3.1.101.>

=item * mpl_1_1

I<Since v3.1.101.>

=item * mpl_2

I<Since v3.1.101.>

=item * mpl_2_no_copyleft_exception

I<Since v3.8.0.>

=cut

$RE{mpl} = {
	name                                  => 'MPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q308915',
	caption                               => 'Mozilla Public License',
	'caption.alt.org.wikipedia'           => 'Mozilla Public License',
	iri                                   => 'https://www.mozilla.org/MPL',
	tags                                  => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => "$the?Mozilla Public Licen[cs]e"
		. '(?: [(]["]?(?:[http://]mozilla.org/)?MPL["]?[)])?'
		. "(?: (?:as )?published by $the\{0,2}Mozilla Foundation)?",
};

$RE{mpl_1} = {
	name                                            => 'MPL-1.0',
	'name.alt.org.fedora'                           => 'MPLv1.0',
	'name.alt.org.osi'                              => 'MPL-1.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'mozilla1.0',
	'name.alt.org.perl'                             => 'mozilla_1_0',
	'name.alt.org.spdx'                             => 'MPL-1.0',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q26737738',
	'name.alt.misc.fossology_old'                   => 'Mozilla1.0',
	'name.alt.misc.fossology_old_short'             => 'MPL_v1.0',
	caption                  => 'Mozilla Public License 1.0',
	'caption.alt.org.fedora' => 'Mozilla Public License v1.0',
	'caption.alt.org.osi' => 'The Mozilla Public License (MPL), version 1.0',
	'caption.alt.org.osi.misc.list' => 'Mozilla Public License 1.0',
	'caption.alt.org.osi.misc.do_not_use_list' =>
		'Mozilla Public License, version 1.0',
	'caption.alt.org.perl'     => 'Mozilla Public License, Version 1.0',
	'caption.alt.org.tldr'     => 'Mozilla Public License 1.0 (MPL-1.0)',
	'caption.alt.org.trove'    => 'Mozilla Public License 1.0 (MPL)',
	'caption.alt.org.wikidata' => 'Mozilla Public License, version 1.0',
	'caption.alt.misc.trove'   => 'Mozilla Public License 1.0 (MPL)',
	description                => <<'END',
Origin: Netscape Public License 1.0
END
	tags => [
		'license:contains:grant',
		'type:singleversion:mpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'MOZILLA PUBLIC LICENSE[ ]Version 1\.0[  ]' . '[*)]Definitions',
};

$RE{mpl_1_1} = {
	name                                            => 'MPL-1.1',
	'name.alt.org.fedora'                           => 'MPLv1.1',
	'name.alt.org.osi'                              => 'MPL-1.1',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'mozilla1.1',
	'name.alt.org.perl'                             => 'mozilla_1_1',
	'name.alt.org.spdx'                             => 'MPL-1.1',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q26737735',
	'name.alt.misc.fossology_old'                   => 'Mozilla1.1',
	'name.alt.misc.fossology_old_short'             => 'MPL_v1.1',
	caption                  => 'Mozilla Public License 1.1',
	'caption.alt.org.fedora' => 'Mozilla Public License v1.1',
	'caption.alt.org.osi.misc.do_not_use_list' =>
		'Mozilla Public License, version 1.1',
	'caption.alt.org.perl'  => 'Mozilla Public License, Version 1.1',
	'caption.alt.org.tldr'  => 'Mozilla Public License 1.1 (MPL-1.1)',
	'caption.alt.org.trove' => 'Mozilla Public License 1.1 (MPL 1.1)',
	'caption.alt.org.trove.misc.short' => 'MPL 1.1',
	'caption.alt.org.wikidata' => 'Mozilla Public License, version 1.1',
	'caption.alt.misc.trove'   => 'Mozilla Public License 1.1 (MPL 1.1)',
	tags                       => [
		'license:contains:grant',
		'type:singleversion:mpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'Mozilla Public License Version 1\.1[  ]' . '[*)]Definitions',
};

$RE{mpl_2} = {
	name                  => 'MPL-2.0',
	'name.alt.org.fedora' => 'MPLv2.0',
	'name.alt.org.osi'    => 'MPL-2.0',
	'name.alt.org.spdx'   => 'MPL-2.0',
	'name.alt.org.tldr'   => 'mozilla-public-license-2.0-(mpl-2)',
	'name.alt.org.wikidata.synth.nogrant' => 'Q25428413',
	'name.alt.misc.fossology_old'         => 'MPL_v2.0',
	caption                               => 'Mozilla Public License 2.0',
	'caption.alt.org.fedora'              => 'Mozilla Public License v2.0',
	'caption.alt.org.osi'                 => 'Mozilla Public License 2.0',
	'caption.alt.org.tldr'  => 'Mozilla Public License 2.0 (MPL-2.0)',
	'caption.alt.org.trove' => 'Mozilla Public License 2.0 (MPL 2.0)',
	'caption.alt.org.trove.misc.short' => 'MPL 2.0',
	'caption.alt.org.wikidata' => 'Mozilla Public License, version 2.0',
	'caption.alt.misc.trove'   => 'Mozilla Public License 2.0 (MPL 2.0)',
	tags                       => [
		'license:contains:grant',
		'type:singleversion:mpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'Mozilla Public License Version 2\.0[  ]' . '[*)]Definitions',
};

$RE{mpl_2_no_copyleft_exception} = {
	name                => 'MPL-2.0-no-copyleft-exception',
	'name.alt.org.spdx' => 'MPL-2.0-no-copyleft-exception',
	caption     => 'Mozilla Public License 2.0 (no copyleft exception)',
	description => <<'END',
Usage: When the MPL\'s Exhibit B is used,
which effectively negates the copyleft compatibility clause in section 3.3.
END
	tags => [
		'type:usage:ofl_1:no_copyleft_exception',
	],
};

=item * ms_cl

I<Since v3.8.0.>

=cut

$RE{ms_cl} = {
	name    => 'MS-CL',
	caption => 'Microsoft Shared Source Community License',
	caption => 'Microsoft Shared Source Community License (MS-CL)',
	'caption.alt.org.tldr' =>
		'Microsoft Shared Source Community License (MS-CL)',
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'If you distribute the larger work as a series of files, you must grant',
};

=item * ms_pl

=cut

$RE{ms_pl} = {
	name                                            => 'MS-PL',
	'name.alt.org.fedora'                           => 'MS-PL',
	'name.alt.org.osi'                              => 'MS-PL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ms-pl',
	'name.alt.org.spdx'                             => 'MS-PL',
	'name.alt.org.tldr.path.short'                  => 'mspl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q15477153',
	'name.alt.misc.fossology_old'                   => 'Ms-PL',
	caption                 => 'Microsoft Public License',
	'caption.alt.org.tldr'  => 'Microsoft Public License (Ms-PL)',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Public_License_(Ms-PL)',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multiparagraph' =>
		'Microsoft Public License [(]Ms-PL[)][  ]This license governs use',
};

=item * ms_rl

=cut

$RE{ms_rl} = {
	name                                            => 'MS-RL',
	'name.alt.org.fedora'                           => 'MS-RL',
	'name.alt.org.osi'                              => 'MS-RL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ms-rl',
	'name.alt.org.spdx'                             => 'MS-RL',
	'name.alt.org.tldr.path.short'                  => 'nsrl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1772828',
	'name.alt.misc.fossology_old'                   => 'Ms-RL',
	caption                 => 'Microsoft Reciprocal License',
	'caption.alt.org.tldr'  => 'Microsoft Reciprocal License (Ms-RL)',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Reciprocal_License_(Ms-RL)',
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.part3a' =>
		'Reciprocal Grants[-]For any file you distribute that contains code',
	'pat.alt.subject.license.scope.multiparagraph' =>
		'Microsoft Reciprocal License [(]Ms[-]RL[)][  ]This license governs use',
};

=item * mulan

I<Since v3.5.0.>

=item * mulan_1

I<Since v3.5.0.>

=item * mulan_2

I<Since v3.5.0.>

=cut

$RE{mulan} = {
	name                     => 'MulanPSL',
	caption                  => 'Mulan Permissive Software License',
	'caption.alt.lang.zh_CN' => '木兰宽松许可证',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{mulan_1} = {
	name                                    => 'MulanPSL-1',
	'name.alt.org.spdx.since.date_20191022' => 'MulanPSL-1.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q66563953',
	caption => 'Mulan Permissive Software License, Version 1',
	'caption.alt.lang.zh_CN'     => '木兰宽松许可证， 第1版',
	'caption.alt.misc.shortname' => 'Mulan PSL v1',
	iri                          => 'https://license.coscl.org.cn/MulanPSL',
	tags                         => [
		'license:contains:grant',
		'type:singleversion:mulan',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		'Your reproduction, use, modification and distribution'
		. ' of the Software'
		. ' shall be subject to Mulan PSL v1 [(]this License[)]'
		. ' with following',
	'pat.alt.subject.license.scope.sentence.part.intro.lang.zh_CN' =>
		'您对["]软件["]的复制[, ]使用'
		. '[, ]修改及分发受木兰宽松许可证[, ]第1版[(]["]本许可证["][)]'
		. '的如下条款的约束',
	'pat.alt.subject.license.scope.multisection.part.grant' =>
		'[*]Software Name[*] is licensed under the Mulan PSL v1[. ]'
		. 'You can use this software'
		. ' according to the terms and conditions of the Mulan PSL v1'
};

$RE{mulan_2} = {
	name                                    => 'MulanPSL-2',
	'name.alt.org.osi'                      => 'MulanPSL-2.0',
	'name.alt.org.spdx.since.date_20200515' => 'MulanPSL-2.0',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q99634430',
	caption => 'Mulan Permissive Software License, Version 2',
	'caption.alt.lang.zh_CN' => '木兰宽松许可证， 第2版',
	'caption.alt.org.osi'    => 'Mulan Permissive Software License v2',
	'caption.alt.org.osi.misc.shortname' => 'MulanPSL - 2.0',
	'caption.alt.misc.shortname'         => 'Mulan PSL v2',
	iri  => 'https://license.coscl.org.cn/MulanPSL2',
	tags => [
		'license:contains:grant',
		'type:singleversion:mulan',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		'Your reproduction, use, modification and distribution'
		. ' of the Software'
		. ' shall be subject to Mulan PSL v2 [(]this License[)]'
		. ' with the following terms and conditions',
	'pat.alt.subject.license.scope.sentence.part.intro.lang.zh_CN' =>
		'您对["]软件["]的复制[, ]使用'
		. '[, ]修改及分发受木兰宽松许可证[, ]第2版[(]["]本许可证["][)]'
		. '的如下条款的约束',
	'pat.alt.subject.license.scope.multisection.part.grant' =>
		'[*]Software Name[*] is licensed under Mulan PSL v2[. ]'
		. 'You can use this software'
		. ' according to the terms and conditions of the Mulan PSL v2',
};

=item * multics

I<Since v3.6.0.>

=cut

$RE{multics} = {
	name                                            => 'Multics',
	'name.alt.org.osi'                              => 'Multics',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'multics',
	'name.alt.org.spdx'                             => 'Multics',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38494754',
	caption                                         => 'Multics License',
	'caption.alt.org.tldr' => 'Multics License (Multics)',
	description            => <<'END',
Identical to NTP, except...
* add Paragraph "Historical Background"
* omit explicit permission to charge fee
* replace "software" with "programs"
* extend things to retain to include historical background
* omit suitability disclaimer and terse "as is" warranty disclaimer
* list copyrights at bottom
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This edition of the Multics software materials and documentation',
	'pat.alt.subject.license.scope.line.scope.sentence.part.permissions_first'
		=> 'Permission to use, copy, modify, and distribute these programs',
	'pat.alt.subject.license.scope.sentence.part.permissions_middle' =>
		'copyright notice and(?: this)? historical background appear',
};

=item * nasa

I<Since v3.6.0.>

=item * nasa_1_3

I<Since v3.6.0.>

=cut

$RE{nasa} = {
	name                                  => 'NASA',
	'name.alt.misc.abbrev'                => 'NOSA',
	'name.alt.org.wikidata.synth.nogrant' => 'Q6952418',
	caption                               => 'NASA Open Source Agreement',
	'caption.alt.org.wikipedia'           => 'NASA Open Source Agreement',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{nasa_1_3} = {
	name                                            => 'NASA-1.3',
	'name.alt.org.osi'                              => 'NASA-1.3',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'nasa1.3',
	'name.alt.org.spdx'                             => 'NASA-1.3',
	'name.alt.misc.fossology_old'                   => 'NASA_v1.3',
	'name.alt.misc.fossology_old_short'             => 'NASA1.3',
	caption                  => 'NASA Open Source Agreement 1.3',
	'caption.alt.org.fedora' => 'NASA Open Source Agreement v1.3',
	'caption.alt.org.fedora.iri.self.synth.nogrant' =>
		'NASA Open Source Agreement',
	'caption.alt.org.osi'           => 'NASA Open Source Agreement v1.3',
	'caption.alt.org.osi.misc.list' => 'NASA Open Source Agreement 1.3',
	'caption.alt.org.tldr' => 'NASA Open Source Agreement 1.3 (NASA-1.3)',
	iri                    => 'https://ti.arc.nasa.gov/opensource/nosa/',
	tags                   => [
		'type:singleversion:nasa',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.line.scope.sentence.part.definitions' =>
		'["]Contributor["] means Government Agency',
};

=item * naumen

I<Since v3.6.0.>

=cut

$RE{naumen} = {
	name                                            => 'Naumen',
	'name.alt.org.fedora'                           => 'Naumen',
	'name.alt.org.osi'                              => 'Naumen',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'naumen',
	'name.alt.org.spdx'                             => 'Naumen',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38495690',
	'name.alt.misc.fossology_old'                   => 'NAUMEN',
	caption                         => 'Naumen Public License',
	'caption.alt.org.osi'           => 'NAUMEN Public License',
	'caption.alt.org.osi.misc.list' => 'Naumen Public License',
	'caption.alt.org.tldr'          => 'Naumen Public License (Naumen)',
	'caption.alt.org.wikidata'      => 'NAUMEN Public License',
	tags                            => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.part2_3' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]'
		. 'The name Zope Corporation[tm] must not '
		. $P{used_endorse_deriv}
		. $P{without_prior_written},
	'pat.alt.subject.license.scope.sentence.part.part3' =>
		'The name NAUMEN[tm] must not be used to endorse',
};

=item * nbpl

I<Since v3.8.0.>

=item * nbpl_1

I<Since v3.8.0.>

=cut

$RE{nbpl} = {
	name    => 'NBPL',
	caption => 'Net Boolean Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{nbpl_1} = {
	name                => 'NBPL-1.0',
	'name.alt.org.spdx' => 'NBPL-1.0',
	caption             => 'Net Boolean Public License v1',
	'caption.alt.org.spdx.since.date_20130117' =>
		'Net Boolean Public License v1',
	'caption.alt.org.tldr' => 'Net Boolean Public License v1 (NBPL-1.0)',
	description            => <<'END',
Identical to OLDAP-1.1, exept...
* title
* copyright holder
END
	tags => [
		'type:singleversion:nbpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The Net Boolean Public License[  ]Version 1, 22 August 1998',
};

=item * ncsa

I<Since v3.6.0.>

=cut

$RE{ncsa} = {
	name                                            => 'NCSA',
	'name.alt.org.fedora'                           => 'NCSA',
	'name.alt.org.osi'                              => 'NCSA',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'UoI-NCSA',
	'name.alt.org.spdx'                             => 'NCSA',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q2495855',
	caption => 'University of Illinois/NCSA Open Source License',
	'caption.alt.org.fedora' =>
		'NCSA/University of Illinois Open Source License',
	'caption.alt.misc.short' => 'UIUC license',
	'caption.alt.org.osi'    =>
		'The University of Illinois/NCSA Open Source License',
	'caption.alt.org.osi.misc.list' =>
		'University of Illinois/NCSA Open Source License',
	'caption.alt.org.tldr' =>
		'University of Illinois - NCSA Open Source License (NCSA)',
	'caption.alt.org.tldr.path.short' => 'ncsa',
	'caption.alt.org.trove'           =>
		'University of Illinois/NCSA Open Source License',
	'caption.alt.org.wikipedia' =>
		'University of Illinois/NCSA Open Source License',
	description => <<'END',
Identical to MIT (Expat), except...
* replace retain-copyright-notices clause with BSD 3 Clause clauses

Identical to BSD 3 Clause, except...
* add MIT permissions clause
* replace disclaimers with MIT disclaimers
END
	iri =>
		'http://otm.illinois.edu/disclose-protect/illinois-open-source-license',
	tags => [
		'license:contains:license:bsd_3_clause',
		'license:contains:license:mit_new',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		$P{to_copy_sublicence_conditions}
		. '[:]?[  ][*)]'
		. $P{retain_notice_cond_discl},
};

=item * ngpl

=cut

$RE{ngpl} = {
	name                                            => 'NGPL',
	'name.alt.org.fedora'                           => 'NGPL',
	'name.alt.org.osi'                              => 'NGPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'nethack',
	'name.alt.org.spdx'                             => 'NGPL',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q20764732',
	'name.alt.misc.fossology_old'                   => 'Nethack',
	caption                         => 'Nethack General Public License',
	'caption.alt.org.osi'           => 'The Nethack General Public License',
	'caption.alt.org.osi.misc.list' => 'Nethack General Public License',
	'caption.alt.org.tldr'  => 'Nethack General Public License (NGPL)',
	'caption.alt.org.trove' => 'Nethack General Public License',
	tags                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'You may copy and distribute verbatim copies of NetHack',
};

=item * nokia

I<Since v3.6.0.>

=cut

$RE{nokia} = {
	name                                            => 'Nokia',
	'name.alt.org.fedora'                           => 'Nokia',
	'name.alt.org.osi'                              => 'Nokia',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'nokia',
	'name.alt.org.osi.misc.upper'                   => 'NOKIA',
	'name.alt.org.spdx'                             => 'Nokia',
	'name.alt.org.trove'                            => 'NOKOS',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38495954',
	'name.alt.misc.fossology_old'                   => 'Nokia_v1.0a',
	caption               => 'Nokia Open Source License',
	'caption.alt.org.osi' => 'Nokia Open Source License Version 1.0a',
	'caption.alt.org.osi.misc.list' => 'Nokia Open Source License',
	'caption.alt.org.trove'         => 'Nokia Open Source License',
	'caption.alt.misc.legal'        => 'NOKOS License Version 1.0',
	'caption.alt.org.tldr'          =>
		'Nokia Open Source License (Nokia Open Source License)',
	'caption.alt.org.trove'           => 'Nokia Open Source License',
	'caption.alt.org.trove.misc.long' => 'Nokia Open Source License (NOKOS)',
	description                       => <<'END',
Origin: Possibly Mozilla Public License
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.name.misc.free' =>
		'(?:Nokia|NOKOS)(?: Open Source)?(?: [Ll]icen[cs]e)?' . '(?:'
		. $RE{version_prefix}
		{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. '1\.0a?)?',
	'pat.alt.subject.license.scope.line.scope.sentence.part.definitions' =>
		'["]Affiliates["] of a party shall mean an entity',
};

=item * nosl

I<Since v3.8.0.>

=item * nosl_1

I<Since v3.8.0.>

=cut

$RE{nosl} = {
	name                   => 'NOSL',
	caption                => 'Netizen Open Source License',
	'caption.alt.org.tldr' => 'Netizen Open Source License (NOSL)',
	tags                   => [
		'type:versioned:decimal',
	],
};

$RE{nosl_1} = {
	name                                => 'NOSL-1.0',
	'name.alt.org.fedora.synth.nogrant' => 'NOSL',
	'name.alt.org.spdx.synth.nogrant'   => 'NOSL',
	caption                             => 'Netizen Open Source License 1.0',
	'caption.alt.org.fedora.synth.nogrant' => 'Netizen Open Source License',
	'caption.alt.org.spdx.since.date_20130117.synth.nogrant' =>
		'Netizen Open Source License',
	description => <<'END',
Origin: Mozilla Public License 1.1

Identical to Mozilla Pulbic License 1.0, except...
* replace "Mozilla", "Netscape", "MPL" etc. with "Netizen" and "NOSL" in section 6
* add disclaimer as section 7.1
* change requirement of governance from California to Australia in section 11
END
	tags => [
		'license:contains:grant',
		'type:singleversion:nosl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'NETIZEN OPEN SOURCE LICENSE[ ]Version 1\.0[  ]' . '[*)]Definitions',
};

=item * npl

=item * npl_1

=item * npl_1_1

=cut

$RE{npl} = {
	name                                              => 'NPL',
	'name.alt.org.wikidata.synth.nogrant'             => 'Q2306611',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'Netscape',
	caption                     => 'Netscape Public License',
	'caption.alt.org.trove'     => 'Netscape Public License (NPL)',
	'caption.alt.org.wikipedia' => 'Netscape Public License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{npl_1} = {
	name                                    => 'NPL-1.0',
	'name.alt.org.fedora.synth.nogrant'     => 'Netscape',
	'name.alt.org.spdx.since.date_20130117' => 'NPL-1.0',
	'name.alt.misc.fossology_old'           => 'NPL_v1.0',
	caption                                 => 'Netscape Public License v1.0',
	'caption.alt.org.fedora.synth.nogrant'  => 'Netscape Public License',
	iri                                     =>
		'https://website-archive.mozilla.org/www.mozilla.org/mpl/MPL/NPL/1.0/',
	tags => [
		'type:singleversion:npl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multiparagraph' =>
		'NETSCAPE PUBLIC LICENSE[ ]Version 1\.0[  ][*)]Definitions[.]',
};

$RE{npl_1_1} = {
	name                                    => 'NPL-1.1',
	'name.alt.org.spdx.since.date_20130117' => 'NPL-1.1',
	caption                                 => 'Netscape Public License v1.1',
	'caption.alt.org.tldr'        => 'Netscape Public License v1.1 (NPL-1.1)',
	'name.alt.misc.fossology_old' => 'NPL_v1.1',
	'name.alt.misc.fossology_old_long' => 'Netscape1.1',
	iri                                =>
		'https://website-archive.mozilla.org/www.mozilla.org/mpl/MPL/NPL/1.1/',
	tags => [
		'type:singleversion:npl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'The Netscape Public License Version 1\.1 [(]["]NPL["][)] consists of',
};

=item * nposl

I<Since v3.6.0.>

=item * nposl_3

I<Since v3.6.0.>

=cut

$RE{nposl} = {
	name                                  => 'NPOSL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38495282',
	caption => 'Non-Profit Open Software License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{nposl_3} = {
	name                                            => 'NPOSL-3.0',
	'name.alt.org.osi'                              => 'NPOSL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'NOSL3.0',
	'name.alt.org.spdx'                             => 'NPOSL-3.0',
	caption               => 'Non-Profit Open Software License 3.0',
	'caption.alt.org.osi' =>
		'The Non-Profit Open Software License version 3.0',
	'caption.alt.org.osi.misc.list' => 'Non-Profit Open Software License 3.0',
	'caption.alt.org.tldr'          =>
		'Non-Profit Open Software License 3.0 (NPOSL-3.0)',
	description => <<'END',
Identical to Open Software License 3.0, except...
* drop provenance warranty
* add Non-Profit Amendment
* rename license name
END
	tags => [
		'license:contains:grant',
		'type:singleversion:nposl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Non-Profit Open Software License version 3\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
	'pat.alt.subject.license.scope.paragraph' =>
		'Warranty of Provenance and Disclaimer of Warranty'
		. '[. ]The Original Work is provided',
};

=item * ntp

=cut

$RE{ntp} = {
	name                                            => 'NTP',
	'name.alt.org.osi'                              => 'NTP',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ntp-license',
	'name.alt.org.spdx'                             => 'NTP',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38495487',
	caption                                         => 'NTP License',
	'caption.alt.org.tldr'                          => 'NTP License (NTP)',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, NTP variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => $P{asis_expr_warranty},
};

=item * ntp_disclaimer

=cut

$RE{ntp_disclaimer} = {
	'name.alt.org.debian' => 'NTP~disclaimer',
	caption               => 'NTP License (legal disclaimer)',
	tags                  => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{asis_expr_warranty}
		. '[. ]'
		. $P{discl_name_warranties},
};

=item * oclc

=item * oclc_1

=item * oclc_2

=cut

$RE{oclc} = {
	name                                  => 'OCLC',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38496210',
	caption                               => 'OCLC Research Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{oclc_1} = {
	name                          => 'OCLC-1.0',
	'name.alt.misc.fossology_old' => 'OCLC_v1.0',
	caption                       => 'OCLC Research Public License 1.0',
	tags                          => [
		'type:singleversion:oclc',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'If you distribute the Program or any derivative work of',
};

$RE{oclc_2} = {
	name                                            => 'OCLC-2.0',
	'name.alt.org.osi'                              => 'OCLC-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'oclc2',
	'name.alt.org.spdx'                             => 'OCLC-2.0',
	'name.alt.misc.fossology_old'                   => 'OCLC_v2.0',
	caption                  => 'OCLC Research Public License 2.0',
	'caption.alt.org.fedora' => 'OCLC Public Research License 2.0',
	'caption.alt.org.osi' => 'The OCLC Research Public License 2.0 License',
	'caption.alt.org.osi.misc.list' => 'OCLC Research Public License 2.0',
	'caption.alt.org.tldr' => 'OCLC Research Public License 2.0 (OCLC-2.0)',
	tags                   => [
		'type:singleversion:oclc',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license' =>
		'The Program must be distributed without charge beyond',
};

=item * odbl

I<Since v3.8.0.>

=item * odbl_1

I<Since v3.8.0.>

=cut

$RE{odbl} = {
	name                                  => 'ODbL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q1224853',
	caption                               => 'ODC Open Database License',
	'caption.alt.org.wikidata'            => 'Open Database License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{odbl_1} = {
	name                                 => 'ODbL-1.0',
	'name.alt.org.spdx'                  => 'ODbL-1.0',
	caption                              => 'ODC Open Database License v1.0',
	'caption.alt.org.tldr.synth.nogrant' =>
		'ODC Open Database License (ODbL)',
	tags => [
		'type:singleversion:odbl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The Open Database License [(]ODbL[)] is a license agreement',
};

=item * odc_by

I<Since v3.8.0.>

=item * odc_by_1

I<Since v3.8.0.>

=cut

$RE{odc_by} = {
	name    => 'ODC-By',
	caption => 'Open Data Commons Attribution License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{odc_by_1} = {
	name                                    => 'ODC-By-1.0',
	'name.alt.org.spdx.since.date_20180710' => 'ODC-By-1.0',
	caption => 'Open Data Commons Attribution License v1.0',
	tags    => [
		'type:singleversion:odc_by',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The Open Data Commons Attribution License is a license agreement',
};

=item * ofl

=item * ofl_1

I<Since v3.1.101.>

=item * ofl_1_no_rfn

I<Since v3.2.0.>

=item * ofl_1_rfn

I<Since v3.2.0.>

=item * ofl_1_1

I<Since v3.1.101.>

=item * ofl_1_1_no_rfn

I<Since v3.2.0.>

=item * ofl_1_1_rfn

I<Since v3.2.0.>

=cut

$RE{ofl} = {
	name                                            => 'OFL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'openfont',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1150837',
	caption                    => 'SIL Open Font License',
	'caption.alt.misc.shorter' => 'Open Font License',
	iri                        => 'http://scripts.sil.org/OFL',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{ofl_1} = {
	name                => 'OFL-1.0',
	'name.alt.org.spdx' => 'OFL-1.0',
	caption             => 'SIL Open Font License 1.0',
	tags                => [
		'type:singleversion:ofl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'["]Font Software["] refers to any and all of the following',
};

$RE{ofl_1_no_rfn} = {
	name                                    => 'OFL-1.0-no-RFN',
	'name.alt.org.spdx.since.date_20200209' => 'OFL-1.0-no-RFN',
	caption     => 'SIL Open Font License 1.0 with no Reserved Font Name',
	description => <<'END',
Usage: Should only be used when there is no Reserved Font Name.
END
	tags => [
		'type:usage:ofl_1:no_rfn',
	],
};

$RE{ofl_1_rfn} = {
	name                                    => 'OFL-1.0-RFN',
	'name.alt.org.spdx.since.date_20200209' => 'OFL-1.0-RFN',
	caption     => 'SIL Open Font License 1.0 with Reserved Font Name',
	description => <<'END',
Usage: Should only be used when a Reserved Font Name applies.
END
	tags => [
		'type:usage:ofl_1:rfn',
	],
};

$RE{ofl_1_1} = {
	name                                => 'OFL-1.1',
	'name.alt.org.fedora.synth.nogrant' => 'OFL',
	'name.alt.org.osi'                  => 'OFL-1.1',
	'name.alt.org.spdx'                 => 'OFL-1.1',
	'name.alt.org.tldr.synth.nogrant' => 'open-font-license-(ofl)-explained',
	caption                           => 'SIL Open Font License 1.1',
	'caption.alt.org.osi.synth.nogrant' => 'SIL OPEN FONT LICENSE',
	'caption.alt.org.osi.misc.list'     => 'SIL Open Font License 1.1',
	'caption.alt.org.tldr'  => 'SIL Open Font License v1.1 (OFL-1.1)',
	'caption.alt.org.trove' => 'SIL Open Font License 1.1 (OFL-1.1)',
	tags                    => [
		'type:singleversion:ofl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'["]Font Software["] refers to the set of files released',
};

$RE{ofl_1_1_no_rfn} = {
	name                                    => 'OFL-1.1-no-RFN',
	'name.alt.org.spdx.since.date_20200209' => 'OFL-1.1-no-RFN',
	caption     => 'SIL Open Font License 1.1 with no Reserved Font Name',
	description => <<'END',
Usage: Should only be used when there is no Reserved Font Name.
END
	tags => [
		'type:usage:ofl_1_1:no_rfn',
	],
};

$RE{ofl_1_1_rfn} = {
	name                                    => 'OFL-1.1-RFN',
	'name.alt.org.spdx.since.date_20200209' => 'OFL-1.1-RFN',
	caption     => 'SIL Open Font License 1.1 with Reserved Font Name',
	description => <<'END',
Usage: Should only be used when a Reserved Font Name applies.
END
	tags => [
		'type:usage:ofl_1_1:rfn',
	],
};

=item * ogc

I<Since v3.6.0.>

=item * ogc_1

I<Since v3.6.0.>

=cut

$RE{ogc} = {
	name    => 'OGC',
	caption => 'OGC Software License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{ogc_1} = {
	name                                    => 'OGC-1.0',
	'name.alt.org.spdx.since.date_20200515' => 'OGC-1.0',
	caption => 'OGC Software License, Version 1.0',
	iri     => 'https://www.ogc.org/ogc/software/1.0',
	tags    => [
		'license:is:grant',
		'type:singleversion:ogc',
	],
	licenseversion => '19980720',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This OGC work [(]including software, documents, or other',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause3' =>
		'Notice of any changes or modifications to the OGC files',
};

=item * ogtsl

=cut

$RE{ogtsl} = {
	name                                                          => 'OGTSL',
	'name.alt.org.osi'                                            => 'OGTSL',
	'name.alt.org.osi.iri.stem.until.date_20110430.synth.nogrant' =>
		'opengroup',
	'name.alt.org.spdx'                   => 'OGTSL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38686558',
	caption                               => 'Open Group Test Suite License',
	'caption.alt.org.fedora'              => 'Open Group Test Suite License',
	'caption.alt.org.osi'           => 'The Open Group Test Suite License',
	'caption.alt.org.osi.misc.list' => 'Open Group Test Suite License',
	'caption.alt.org.tldr'  => 'Open Group Test Suite License (OGTSL)',
	'caption.alt.org.trove' => 'Open Group Test Suite License',
	tags                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'rename any non-standard executables and testcases',
};

=item * oldap

I<Since v3.5.0.>

=item * oldap_1_1

I<Since v3.5.0.>

=item * oldap_1_2

I<Since v3.5.0.>

=item * oldap_1_3

I<Since v3.5.0.>

=item * oldap_1_4

I<Since v3.5.0.>

=item * oldap_2

I<Since v3.5.0.>

=item * oldap_2_0_1

I<Since v3.5.0.>

=item * oldap_2_1

I<Since v3.5.0.>

=item * oldap_2_2

I<Since v3.5.0.>

=item * oldap_2_2_1

I<Since v3.5.0.>

=item * oldap_2_2_2

I<Since v3.5.0.>

=item * oldap_2_3

I<Since v3.5.0.>

=item * oldap_2_4

I<Since v3.5.0.>

=item * oldap_2_5

I<Since v3.5.0.>

=item * oldap_2_6

I<Since v3.5.0.>

=item * oldap_2_7

I<Since v3.5.0.>

=item * oldap_2_8

I<Since v3.5.0.>

=cut

$RE{oldap} = {
	name                     => 'OLDAP',
	'name.alt.org.fedora'    => 'OpenLDAP',
	caption                  => 'Open LDAP Public License',
	'caption.alt.org.fedora' => 'OpenLDAP License',
	tags                     => [
		'type:versioned:decimal',
	],
	'_pat.alt.subject.license.scope.line.scope.sentence' => [
		'C subroutines supplied by you',
		'Due credit should be given',
		'may revise this license from time to time',
	]
};

$RE{oldap_1_1} = {
	name                                    => 'OLDAP-1.1',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-1.1',
	caption => 'Open LDAP Public License v1.1',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.1, 25 August 1998',
};

$RE{oldap_1_2} = {
	name                                    => 'OLDAP-1.2',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-1.2',
	'name.alt.misc.fossology_old'           => 'OpenLDAP_v1.2',
	caption => 'Open LDAP Public License v1.2',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.2, 1 September 1998',
};

$RE{oldap_1_3} = {
	name                                    => 'OLDAP-1.3',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-1.3',
	caption => 'Open LDAP Public License v1.3',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.3, 17 January 1999',
	'pat.alt.subject.license.part.part8' =>
		' and do not automatically fall under the copyright of this Package'
		. ', and the executables produced by linking',
};

$RE{oldap_1_4} = {
	name                                    => 'OLDAP-1.4',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-1.4',
	caption => 'Open LDAP Public License v1.4',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.4',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.4, 18 January 1999',
	'pat.alt.subject.license.part.part8' =>
		' and do not automatically fall under the copyright of this Package'
		. '[. ]Executables produced by linking',
};

$RE{oldap_2} = {
	name                                    => 'OLDAP-2.0',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.0',
	caption                                 => 'Open LDAP Public License v2',
	'caption.alt.org.spdx'                  =>
		'Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)',
	'caption.alt.misc.spdx'   => 'Open LDAP Public License v2.0',
	'caption.alt.misc.spdx_a' => 'Open LDAP Public License v2.0A',
	'caption.alt.misc.spdx_b' => 'Open LDAP Public License v2.0B',
	tags                      => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.0, 7 June 1999',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'without prior written permission of the OpenLDAP Foundation'
		. '[. ]OpenLDAP is a registered trademark of the OpenLDAP Foundation',
};

$RE{oldap_2_0_1} = {
	name                                    => 'OLDAP-2.0.1',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.0.1',
	caption => 'Open LDAP Public License v2.0.1',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.0.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.0\.1, 21 December 1999',
};

$RE{oldap_2_1} = {
	name                                    => 'OLDAP-2.1',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.1',
	caption => 'Open LDAP Public License v2.1',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.1, 29 February 2000',
};

$RE{oldap_2_2} = {
	name                                    => 'OLDAP-2.2',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.2',
	caption => 'Open LDAP Public License v2.2',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2, 1 March 2000',
};

$RE{oldap_2_2_1} = {
	name                                    => 'OLDAP-2.2.1',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.2.1',
	caption => 'Open LDAP Public License v2.2.1',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2\.1, 1 March 2000',
};

$RE{oldap_2_2_2} = {
	name                                    => 'OLDAP-2.2.2',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.2.2',
	caption => 'Open LDAP Public License 2.2.2',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2\.2, 28 July 2000',
};

$RE{oldap_2_3} = {
	name                                    => 'OLDAP-2.3',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.3',
	caption => 'Open LDAP Public License v2.3',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.3, 28 July 2000',
};

$RE{oldap_2_4} = {
	name                                    => 'OLDAP-2.4',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.4',
	caption => 'Open LDAP Public License v2.4',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.4',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.4, 8 December 2000',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'Due credit should be given to the OpenLDAP Project[.]',
};

$RE{oldap_2_5} = {
	name                                    => 'OLDAP-2.5',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.5',
	caption => 'Open LDAP Public License v2.5',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.5',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.5, 11 May 2001',
	'pat.alt.subject.license.scope.multisection.part.clauses_minimal' =>
		'Due credit should be given to the authors of the Software'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise',
};

$RE{oldap_2_6} = {
	name                                    => 'OLDAP-2.6',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.6',
	caption => 'Open LDAP Public License v2.6',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.6',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.6, 14 June 2001',
	'pat.alt.subject.license.scope.multisection.part.clauses_minimal' =>
		' without specific, written prior permission'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise',
};

$RE{oldap_2_7} = {
	name                                    => 'OLDAP-2.7',
	'name.alt.org.spdx.since.date_20130117' => 'OLDAP-2.7',
	'name.alt.misc.fossology_old'           => 'OpenLDAP_v2.7',
	caption => 'Open LDAP Public License v2.7',
	tags    => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.7',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.7, 7 September 2001',
};

$RE{oldap_2_8} = {
	name                                  => 'OLDAP-2.8',
	'name.alt.org.osi'                    => 'OLDAP-2.8',
	'name.alt.org.spdx'                   => 'OLDAP-2.8',
	'name.alt.org.wikidata.synth.nogrant' => 'Q25273268',
	'name.alt.misc.fossology_old'         => 'OpenLDAP_v2.8',
	'name.alt.misc.fossology_old_short'   => 'OpenLDAP2.8',
	caption                               => 'Open LDAP Public License v2.8',
	'caption.alt.org.osi' => 'OpenLDAP Public License Version 2.8',
	'caption.alt.org.spdx.until.date_20150513' =>
		'OpenLDAP Public License v2.8',
	'caption.alt.org.spdx.since.date_20150513' =>
		'Open LDAP Public License v2.8',
	'caption.alt.org.tldr'     => 'OpenLDAP Public License v2.8 (OLDAP-2.8)',
	'caption.alt.org.wikidata' => 'OpenLDAP Public License Version 2.8',
	tags                       => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.8',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.8, 17 August 2003',
};

=item * openssl

=cut

$RE{openssl} = {
	name                                  => 'OpenSSL',
	'name.alt.org.fedora'                 => 'OpenSSL',
	'name.alt.org.perl'                   => 'openssl',
	'name.alt.org.spdx'                   => 'OpenSSL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q89948816',
	caption                               => 'OpenSSL License',
	'caption.alt.org.tldr'                => 'OpenSSL License (OpenSSL)',
	description                           => <<'END',
Specific instance of Apache License 1.0
tied to "OpenSSL",
followed by SSLeay License.
END
	tags => [
		'family:bsd',
		'license:contains:license:apache_1',
		'license:contains:license:cryptix',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.apache_1_overlap' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]?'
		. $P{ad_mat_ack_this}
		. 'the OpenSSL Project for use in the OpenSSL Toolkit[. ][(][http://]www\.openssl\.org[/][)]["]'
		. '[  ]' . '[*)]?'
		. $P{nopromo_neither}
		. '[. ]For written permission, please contact openssl[-]core[@]openssl\.org'
		. '[.][  ]' . '[*)]?'
		. 'Products derived from this software may not be called ["]OpenSSL["]',
	'pat.alt.subject.license.scope.paragraph.part.apache_1_overlap' =>
		$P{redist_ack_this}
		. 'the OpenSSL Project for use in the OpenSSL Toolkit',
	'pat.alt.subject.license.scope.multisection.part.second_half' =>
		$P{redist_ack_this}
		. 'the OpenSSL Project for use in the OpenSSL Toolkit[. ][(][http://]www\.openssl\.org[/][)]["]'
		. '[  ]'
		. $P{discl_warranties} . '[. ]'
		. $P{discl_liability}
		. '[.][  ]'
		. 'This product includes cryptographic software written by Eric Young [(]eay[@]cryptsoft\.com[)]'
		. '[. ]'
		. 'This product includes software written by Tim Hudson [(]tjh[@]cryptsoft\.com[)]'
		. '[.][  ]',
};

=item * opl

I<Since v3.6.0.>

=item * opl_1

I<Since v3.6.0.>

=cut

$RE{opl} = {
	name                               => 'OPL',
	'name.alt.misc.shortname'          => 'OpenPL',
	'name.alt.misc.fossology_old'      => 'OpenPublication',
	'name.alt.misc.fossology_old_dash' => 'Open-Publication',
	caption                            => 'Open Public License',
	tags                               => [
		'type:versioned:decimal',
	],
};

$RE{opl_1} = {
	name                                    => 'OPL-1.0',
	'name.alt.org.spdx.since.date_20130117' => 'OPL-1.0',
	'name.alt.misc.fossology_old'           => 'Open-Publication_v1.0',
	'name.alt.misc.fossology_old_short'     => 'OpenPL_v1.0',
	caption                                 => 'Open Public License v1.0',
	'caption.alt.org.fedora.iri.self.synth.nogrant' => 'Open Public License',
	'caption.alt.org.tldr'       => 'Open Public License v1.0 (OPL-1.0)',
	'caption.alt.misc.shortname' => 'OpenPL 1.0',
	description                  => <<'END',
Origin: Possibly Mozilla Public License Version 1.0
END
	tags => [
		'type:singleversion:opl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.definitions' =>
		'["]License Author["] means Lutris Technologies, Inc',
};

=item * oset_pl

I<Since v3.6.0.>

=item * oset_pl_2_1

I<Since v3.6.0.>

=cut

$RE{oset_pl} = {
	name                                  => 'OPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38496558',
	caption                               => 'OSET Public License',
	'caption.alt.org.wikidata'            => 'OSET Foundation Public License',
	iri  => 'https://www.osetfoundation.org/public-license',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{oset_pl_2_1} = {
	name                                    => 'OSET-PL-2.1',
	'name.alt.org.osi.synth.nogrant'        => 'OPL-2.1',
	'name.alt.org.osi.misc.shortname'       => 'OSET-PL-2.1',
	'name.alt.org.spdx.since.date_20160323' => 'OSET-PL-2.1',
	caption              => 'OSET Public License version 2.1',
	'iri.alt.format.pdf' => 'https://www.osetfoundation.org/s/OPL_v21.pdf',
	'iri.alt.format.txt' =>
		'https://www.osetfoundation.org/s/OPL_v21-plain.txt',
	description => <<'END',
Origin: Mozilla Public License Version 2.0
END
	tags => [
		'type:singleversion:oset_pl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.head' =>
		'This license was prepared based on the Mozilla Public License',
	'pat.alt.subject.license.scope.line.scope.sentence.part.section_3_5_2' =>
		'You may place additional conditions upon the rights granted',
};

=item * osl

=item * osl_1

=item * osl_1_1

=item * osl_2

=item * osl_2_1

=item * osl_3

=cut

$RE{osl} = {
	name                                  => 'OSL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q777520',
	'name.alt.misc.fossology_old'         => 'OpenSoftware',
	caption                               => 'Open Software License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{osl_1} = {
	name                              => 'OSL-1.0',
	'name.alt.org.osi'                => 'OSL-1.0',
	'name.alt.org.spdx'               => 'OSL-1.0',
	'name.alt.org.tldr.synth.nogrant' =>
		'open-software-license-1.0-(opl-1.0)',
	'name.alt.misc.fossology_old'       => 'OpenSoftware1.0',
	'name.alt.misc.fossology_old_short' => 'OSL_v1.0',
	caption                             => 'Open Software License 1.0',
	'caption.alt.org.fedora'            => 'Open Software License 1.0',
	'caption.alt.org.fedora.misc.short' => 'OSL 1.0',
	'caption.alt.org.osi'           => 'Open Software License, version 1.0',
	'caption.alt.org.osi.misc.list' => 'Open Software License 1.0',
	'caption.alt.org.tldr'          => 'Open Software License 1.0 (OSL-1.0)',
	tags                            => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection' =>
		'["]Licensed under the Open Software License version 1\.0["][  ]'
		. 'License Terms'
};

$RE{osl_1_1} = {
	name                                    => 'OSL-1.1',
	'name.alt.org.fedora'                   => 'OSL1.1',
	'name.alt.org.spdx.since.date_20140807' => 'OSL-1.1',
	'name.alt.misc.fossology_old'           => 'OpenSoftware1.1',
	'name.alt.misc.fossology_old_short'     => 'OSL_v1.1',
	caption                                 => 'Open Software License 1.1',
	'caption.alt.org.fedora'                => 'Open Software License 1.1',
	'caption.alt.org.fedora.misc.short'     => 'OSL 1.1',
	'caption.alt.org.tldr' => 'Open Software License 1.1 (OSL-1.1)',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection' =>
		'Licensed under the Open Software License version 1\.1[  ]'
		. '[*)]Grant of Copyright License[.]'
};

$RE{osl_2} = {
	name                                => 'OSL-2.0',
	'name.alt.org.spdx'                 => 'OSL-2.0',
	'name.alt.misc.fossology_old'       => 'OpenSoftware2.0',
	'name.alt.misc.fossology_old_short' => 'OSL_v2.0',
	caption                             => 'Open Software License 2.0',
	'caption.alt.org.fedora'            => 'Open Software License 2.0',
	'caption.alt.org.fedora.misc.short' => 'OSL 2.0',
	'caption.alt.org.tldr' => 'Open Software License 2.0 (OSL-2.0)',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Open Software License version 2\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
	'pat.alt.subject.license.scope.multisection.part.part10' =>
		'its terms and conditions[.][  ]'
		. 'This License shall terminate immediately '
		. 'and you may no longer exercise '
		. 'any of the rights granted to You by this License '
		. 'upon Your failure to honor the proviso '
		. 'in Section 1[(]c[)] herein[.][  ]'
		. $termination_for_patent_including_counterclaim
		. ' for patent infringement',
};

$RE{osl_2_1} = {
	name                                => 'OSL-2.1',
	'name.alt.org.fedora'               => 'OSL2.1',
	'name.alt.org.osi'                  => 'OSL-2.1',
	'name.alt.org.spdx'                 => 'OSL-2.1',
	'name.alt.misc.fossology_old'       => 'OpenSoftware2.1',
	'name.alt.misc.fossology_old_short' => 'OSL_v2.1',
	caption                             => 'Open Software License 2.1',
	'caption.alt.org.fedora'            => 'Open Software License 2.1',
	'caption.alt.org.fedora.misc.short' => 'OSL 2.1',
	'caption.alt.org.osi'               => 'The Open Software License 2.1',
	'caption.alt.org.osi.misc.list'     => 'Open Software License 2.1',
	'caption.alt.org.tldr' => 'Open Software License 2.1 (OSL-2.1)',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Open Software License version 2\.1[  ]'
		. '[*)]Grant of Copyright License[.]'
};

$RE{osl_3} = {
	name                                            => 'OSL-3.0',
	'name.alt.org.osi'                              => 'OSL-3.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'osl-3.0',
	'name.alt.org.spdx'                             => 'OSL-3.0',
	'name.alt.misc.fossology_old'                   => 'OpenSoftware3.0',
	'name.alt.misc.fossology_old_short'             => 'OSL_v3.0',
	caption                             => 'Open Software License 3.0',
	'caption.alt.org.fedora'            => 'Open Software License 3.0',
	'caption.alt.org.fedora.misc.short' => 'OSL 3.0',
	'caption.alt.org.osi'               => 'The Open Software License 3.0',
	'caption.alt.org.osi.misc.list'     => 'Open Software License 3.0',
	'caption.alt.org.osi.misc.cat_list.synth.nogrant' =>
		'Open Software License',
	'caption.alt.org.tldr'  => 'Open Software Licence 3.0',
	'caption.alt.org.trove' => 'Open Software License 3.0 (OSL-3.0)',
	tags                    => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Open Software License version 3\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
};

=item * pddl

I<Since v3.8.0.>

=item * pddl_1

I<Since v3.8.0.>

=cut

$RE{pddl} = {
	name    => 'PDDL',
	caption => 'Open Data Commons Public Domain Dedication & License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{pddl_1} = {
	name                                         => 'PDDL-1.0',
	'name.alt.org.fedora'                        => 'PDDL-1.0',
	'name.alt.org.fedora.iri.self.synth.nogrant' => 'PDDL',
	'name.alt.org.spdx'                          => 'PDDL-1.0',
	'name.alt.org.wikidata.synth.nogrant'        => 'Q24273512',
	caption => 'Open Data Commons Public Domain Dedication & License 1.0',
	'caption.alt.org.fedora.synth.nogrant' =>
		'Open Data Commons Public Domain Dedication and Licence',
	'caption.alt.org.spdx.until.date_20210307' =>
		'ODC Public Domain Dedication & License 1.0',
	'caption.alt.org.spdx.since.date_20210307' =>
		'Open Data Commons Public Domain Dedication & License 1.0',
	'caption.alt.org.tldr' =>
		'ODC Public Domain Dedication & License 1.0 (PDDL-1.0)',
	'caption.alt.org.wikidata' => 'Public Domain Dedication and License v1.0',
	tags                       => [
		'type:singleversion:pddl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The Open Data Commons[ - ]Public Domain Dedication & Licence is a document',
};

=item * peer_production

I<Since v3.8.0.>

=cut

$RE{peer_production} = {
	name                   => 'Peer-Production',
	caption                => 'Peer Production License',
	'caption.alt.org.tldr' => 'Peer Production License',
	iri         => 'https://wiki.p2pfoundation.net/Peer_Production_License',
	description => <<'END',
Origin: Creative Commons Attribution-NonCommercial-ShareAlike 3.0
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		'THE WORK [(]AS DEFINED BELOW[)] IS PROVIDED '
		. 'UNDER THE TERMS OF THIS COPYFARLEFT PUBLIC LICENSE',
};

=item * php

I<Since v3.6.0.>

=item * php_3

I<Since v3.6.0.>

=item * php_3_01

I<Since v3.6.0.>

=cut

$RE{php} = {
	name                                            => 'PHP',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'php',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q376841',
	caption                                         => 'PHP License',
	'caption.alt.org.wikipedia'                     => 'PHP License',
	iri  => 'https://secure.php.net/license/',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{php_3} = {
	name                                => 'PHP-3.0',
	'name.alt.org.fedora.synth.nogrant' => 'PHP',
	'name.alt.org.osi'                  => 'PHP-3.0',
	'name.alt.org.spdx'                 => 'PHP-3.0',
	'name.alt.org.tldr.path.short'      => 'php',
	'name.alt.misc.fossology_old'       => 'PHP_v3.0',
	caption                             => 'PHP License v3.0',
	'caption.alt.org.osi'               => 'The PHP License 3.0',
	'caption.alt.org.osi.misc.list'     => 'PHP License 3.0',
	'caption.alt.org.tldr'              => 'PHP License 3.0 (PHP)',
	description                         => <<'END',
Origin: Possibly OpenSSL License
END
	tags => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:singleversion:php',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.last_clauses' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]'
		. '[*)]The name ["]PHP["] must not be used '
		. 'to endorse or promote products derived from this software '
		. 'without prior written permission' . '[. ]'
		. 'For written permission, please contact group\@php\.net'
		. '[.][  ]'
		. '[*)]Products derived from this software may not be called ["]PHP["], '
		. 'nor may ["]PHP["] appear in their name, '
		. 'without prior written permission from group\@php\.net' . '[. ]'
		. 'You may indicate that your software works in conjunction with PHP '
		. 'by saying ["]Foo for PHP["] instead of calling it ["]PHP Foo["] or ["]phpfoo["]'
		. '[  ]'
		. '[*)]The PHP Group may publish revised and[/]or new versions of the license from time to time'
		. '[. ]'
		. 'Each version will be given a distinguishing version number'
		. '[. ]'
		. 'Once covered code has been published under a particular version of the license, '
		. 'you may always continue to use it under the terms of that version'
		. '[. ]'
		. 'You may also choose to use such covered code '
		. 'under the terms of any subsequent version of the license '
		. 'published by the PHP Group' . '[. ]'
		. 'No one other than the PHP Group has the right to modify the terms '
		. 'applicable to covered code created under this License'
		. '[.][  ]'
		. '[*)]Redistributions of any form whatsoever must retain the following acknowledgment'
		. '[:][ ]'
		. '["]This product includes PHP, freely available',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause_6' =>
		'This product includes PHP, freely available',
};

$RE{php_3_01} = {
	name                                       => 'PHP-3.01',
	'name.alt.org.osi'                         => 'PHP-3.01',
	'name.alt.org.spdx'                        => 'PHP-3.01',
	'name.alt.org.tldr'                        => 'the-php-license-3.0.1',
	'name.alt.misc.fossology_old'              => 'PHP_v3.01',
	'name.alt.misc.fossology_old_short'        => 'PHP3.01',
	caption                                    => 'PHP License v3.01',
	'caption.alt.org.osi'                      => 'PHP License 3.01',
	'caption.alt.org.spdx.until.date_20130912' => 'PHP LIcense v3.01',
	'caption.alt.org.spdx.since.date_20130912' => 'PHP License v3.01',
	'caption.alt.org.tldr'                     => 'PHP License 3.0.1',
	'caption.alt.misc.legal' => 'The PHP License, version 3.01',
	iri                      => 'https://secure.php.net/license/3_01.txt',
	tags                     => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:singleversion:php',
	],
	licenseversion => '3.01',

	'pat.alt.subject.license.scope.multisection.part.last_clauses' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]'
		. '[*)]The name ["]PHP["] must not be used '
		. 'to endorse or promote products derived from this software '
		. 'without prior written permission' . '[. ]'
		. 'For written permission, please contact group\@php\.net'
		. '[.][  ]'
		. '[*)]Products derived from this software may not be called ["]PHP["], '
		. 'nor may ["]PHP["] appear in their name, '
		. 'without prior written permission from group\@php\.net' . '[. ]'
		. 'You may indicate that your software works in conjunction with PHP '
		. 'by saying ["]Foo for PHP["] instead of calling it ["]PHP Foo["] or ["]phpfoo["]'
		. '[  ]'
		. '[*)]The PHP Group may publish revised and[/]or new versions of the license from time to time'
		. '[. ]'
		. 'Each version will be given a distinguishing version number'
		. '[. ]'
		. 'Once covered code has been published under a particular version of the license, '
		. 'you may always continue to use it under the terms of that version'
		. '[. ]'
		. 'You may also choose to use such covered code '
		. 'under the terms of any subsequent version of the license '
		. 'published by the PHP Group' . '[. ]'
		. 'No one other than the PHP Group has the right to modify the terms '
		. 'applicable to covered code created under this License'
		. '[.][  ]'
		. '[*)]Redistributions of any form whatsoever must retain the following acknowledgment'
		. '[:][ ]'
		. '["]This product includes PHP software, freely available',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause_6' =>
		'This product includes PHP software, freely available',
};

=item * postgresql

=cut

$RE{postgresql} = {
	name                                            => 'PostgreSQL',
	'name.alt.org.fedora'                           => 'PostgreSQL',
	'name.alt.org.osi'                              => 'PostgreSQL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'postgresql',
	'name.alt.org.spdx'                             => 'PostgreSQL',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q18563589',
	caption                                         => 'PostgreSQL License',
	'caption.alt.org.fedora.iri.self'               => 'PostgreSQL License',
	'caption.alt.org.osi'            => 'The PostgreSQL Licence',
	'caption.alt.org.osi.misc.list'  => 'The PostgreSQL License',
	'caption.alt.org.tldr'           => 'PostgreSQL License (PostgreSQL)',
	'caption.alt.org.trove'          => 'PostgreSQL License',
	'summary.alt.org.fedora.iri.mit' =>
		'MIT-style license, PostgreSQL License (MIT Variant)',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => $P{permission_use_fee_agree},
};

=item * psf_2

I<Since v3.9.0.>

=cut

# license scheme is unversioned, despite versioned name
$RE{psf_2} = {
	name                             => 'PSF-2.0',
	'name.alt.org.debian.misc.short' => 'PSF-2',
	'name.alt.org.wikidata'          => 'Q2600299',
	'name.alt.misc.short'            => 'PSFL',
	'name.alt.misc.shortest'         => 'PSF',
	caption                   => 'Python Software Foundation License 2.0',
	'caption.alt.org.steward' => 'PSF License Agreement',
	'caption.alt.org.trove'   => 'Python Software Foundation License',
	'caption.alt.misc.legal'  =>
		'PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2',
	'caption.alt.org.wikipedia' => 'Python Software Foundation License',
	iri                         =>
		'https://docs.python.org/3/license.html#psf-license-agreement-for-python-release',
	'iri.alt.misc.short' =>
		'https://docs.python.org/3/license.html#psf-license',
	tags => [
		'license:published:by_psf',
		'type:unversioned',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license' =>
		'[*)]PSF is making Python available to Licensee',
};

=item * public_domain

=cut

$RE{public_domain} = {
	name                          => 'public-domain',
	'name.alt.org.fsf'            => 'PublicDomain',
	'name.alt.misc.case_and_dash' => 'Public-Domain',
	caption                       => 'Public domain',
	'caption.alt.org.fedora'      => 'Public Domain',
	'caption.alt.org.trove'       => 'Public Domain',
	'iri.alt.org.linfo'           => 'http://www.linfo.org/publicdomain.html',
	tags                          => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.name' =>
		"$the?(?:[Pp]ublic|PUBLIC)[- ](?:[Dd]omain|DOMAIN)",
};
$RE{public_domain}{'_pat.alt.subject.grant'} = [
	'(?:[Tt]his is|[Tt]hey are|[Ii]t[\']s) in '
		. $RE{public_domain}{'pat.alt.subject.name'},
	'(?:[Tt]his|[Tt]he)[ ](?:(?:source )?code|document|file|library|macros|opening book|work)[ ]is(?: put)?(?: in)? '
		. $RE{public_domain}{'pat.alt.subject.name'},
	'are dedicated to ' . $RE{public_domain}{'pat.alt.subject.name'},
	'for use in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'placed in(?:to)? ' . $RE{public_domain}{'pat.alt.subject.name'},
	'considered to be in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'offered to use in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'provided [as is] into ' . $RE{public_domain}{'pat.alt.subject.name'},
	'released to ' . $RE{public_domain}{'pat.alt.subject.name'},
	'RELEASED INTO ' . $RE{public_domain}{'pat.alt.subject.name'},
];

=item * qpl

=item * qpl_1

=cut

$RE{qpl} = {
	name                                            => 'QPL',
	'name.alt.org.fedora'                           => 'QPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'qtpl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q1396282',
	caption                                         => 'Q Public License',
	'caption.alt.org.trove'     => 'Qt Public License (QPL)',
	'caption.alt.org.wikipedia' => 'Q Public License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{qpl_1} = {
	name                          => 'QPL-1.0',
	'name.alt.org.osi'            => 'QPL-1.0',
	'name.alt.org.spdx'           => 'QPL-1.0',
	'name.alt.org.perl'           => 'qpl_1_0',
	'name.alt.misc.fossology_old' => 'QPL_v1.0',
	caption                       => 'Q Public License 1.0',
	'caption.alt.org.fsf'         => 'Q Public License (QPL), Version 1.0',
	'caption.alt.org.osi.synth.nogrant' => 'The Q Public License Version',
	'caption.alt.org.osi.misc.list.synth.nogrant' => 'Q Public License',
	'caption.alt.org.perl' => 'Q Public License, Version 1.0',
	'caption.alt.org.tldr' => 'Q Public License 1.0 (QPL-1.0)',
	tags                   => [
		'type:singleversion:qpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'This license applies to any software '
		. 'containing a notice placed by the copyright holder '
		. 'saying that it may be distributed '
		. 'under the terms of the Q Public License '
		. 'version 1\.0[.]',
};

=item * rpl

=item * rpl_1

=item * rpl_1_1

=item * rpl_1_3

=item * rpl_1_5

=cut

$RE{rpl} = {
	name                                  => 'RPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q7302458',
	caption                               => 'Reciprocal Public License',
	'caption.alt.org.fedora'              => 'Reciprocal Public License',
	'caption.alt.org.wikipedia'           => 'Reciprocal Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{rpl_1} = {
	name                                            => 'RPL-1',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'rpl1.0',
	caption => 'Reciprocal Public License, Version 1.0',
	'iri.alt.archive.time_20020223190112' =>
		'http://www.technicalpursuit.com/Biz_RPL.html',
	tags => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'This Reciprocal Public License Version 1\.0 [(]["]License["][)] applies to any programs'
};

$RE{rpl_1_1} = {
	name                                    => 'RPL-1.1',
	'name.alt.org.osi'                      => 'RPL-1.1',
	'name.alt.org.spdx.since.date_20130410' => 'RPL-1.1',
	'name.alt.misc.fossology_old'           => 'RPL_v1.1',
	'name.alt.misc.fossology_old_short'     => 'RPL1.1',
	caption               => 'Reciprocal Public License 1.1',
	'caption.alt.org.osi' => 'Reciprocal Public License, version 1.1',
	tags                  => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'This Reciprocal Public License Version 1\.1 [(]["]License["][)] applies to any programs'
};

$RE{rpl_1_3} = {
	name                                  => 'RPL-1.3',
	caption                               => 'Reciprocal Public License 1.3',
	'iri.alt.archive.time_20080828191234' =>
		'http://www.technicalpursuit.com/licenses/RPL_1.3.html',
	tags => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'This Reciprocal Public License Version 1\.3 [(]["]License["][)] applies to any programs'
};

$RE{rpl_1_5} = {
	name                                            => 'RPL-1.5',
	'name.alt.org.osi'                              => 'RPL-1.5',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'rpl1.5',
	'name.alt.org.spdx'                             => 'RPL-1.5',
	'name.alt.misc.fossology_old'                   => 'RPL_v1.5',
	'name.alt.misc.fossology_old_short'             => 'RPL1.5',
	caption                => 'Reciprocal Public License 1.5',
	'caption.alt.org.tldr' => 'Reciprocal Public License 1.5 (RPL-1.5)',
	tags                   => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.5',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'This Reciprocal Public License Version 1\.5 [(]["]License["][)] applies to any programs'
};

=item * rpsl

=item * rpsl_1

I<Since v3.1.95.>

=cut

$RE{rpsl} = {
	name                                            => 'RPSL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'real',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q7300815',
	'name.alt.misc.fossology_old'                   => 'RealNetworks-EULA',
	'name.alt.misc.fossology_old_short'             => 'RealNetworks',
	caption                     => 'RealNetworks Public Source License',
	'caption.alt.org.wikipedia' => 'RealNetworks Public Source License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{rpsl_1} = {
	name                                => 'RPSL-1.0',
	'name.alt.org.osi'                  => 'RPSL-1.0',
	'name.alt.org.spdx'                 => 'RPSL-1.0',
	'name.alt.misc.fossology_old'       => 'RPSL_v1.1',
	'name.alt.misc.fossology_old_short' => 'RPSL1.1',
	caption               => 'RealNetworks Public Source License v1.0',
	'caption.alt.org.osi' => 'RealNetworks Public Source License Version 1.0',
	'caption.alt.org.osi.misc.list' =>
		'RealNetworks Public Source License V1.0',
	'caption.alt.legal.license' =>
		'RealNetworks Public Source License Version 1.0',
	'caption.alt.org.tldr' =>
		'RealNetworks Public Source License v1.0 (RPSL-1.0)',
	tags => [
		'license:contains:name:afl',
		'license:contains:name:apache',
		'license:contains:name:artistic',
		'license:contains:name:bsd',
		'license:contains:name:cpl',
		'license:contains:name:expat',
		'license:contains:name:gpl_1',
		'license:contains:name:intel',
		'license:contains:name:lgpl_1',
		'license:contains:name:libpng',
		'license:contains:name:Motosoto',
		'license:contains:name:mpl_1',
		'license:contains:name:mpl_1_1',
		'license:contains:name:ncsa',
		'license:contains:name:nokia',
		'license:contains:name:python',
		'license:contains:name:rscpl',
		'license:contains:name:siss_1_1',
		'license:contains:name:w3c',
		'license:contains:name:xnet',
		'license:contains:name:zlib',
		'license:contains:name:zpl',
		'type:singleversion:rpsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'General Definitions[. ]This License applies to any program or other work',
};

=item * ruby

=cut

$RE{ruby} = {
	name                                  => 'Ruby',
	'name.alt.org.fedora'                 => 'Ruby',
	'name.alt.org.spdx'                   => 'Ruby',
	'name.alt.org.wikidata.synth.nogrant' => 'Q3066722',
	caption                               => 'Ruby License',
	'caption.alt.org.tldr'                => 'Ruby License (Ruby)',
	tags                                  => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'You may modify and include the part of the software into any',
};

=item * rscpl

=cut

$RE{rscpl} = {
	name                                            => 'RSCPL',
	'name.alt.org.osi'                              => 'RSCPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'ricohpl',
	'name.alt.org.spdx'                             => 'RSCPL',
	'name.alt.misc.fossology_old'                   => 'Ricoh',
	'name.alt.misc.fossology_old_verson'            => 'Ricoh_v1.0',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q7332330',
	caption                         => 'Ricoh Source Code Public License',
	'caption.alt.org.fedora'        => 'Ricoh Source Code Public License',
	'caption.alt.org.osi'           => 'The Ricoh Source Code Public License',
	'caption.alt.org.osi.misc.list' => 'Ricoh Source Code Public License',
	'caption.alt.org.tldr'  => 'Ricoh Source Code Public License (RSCPL)',
	'caption.alt.org.trove' => 'Ricoh Source Code Public License',
	tags                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Endorsements[. ]The names ["]Ricoh,["] ["]Ricoh Silicon Valley,["] and ["]RSV["] must not'
};

=item * sax_pd

I<Since v3.8.0.>

=cut

$RE{sax_pd} = {
	name                   => 'SAX-PD',
	'name.alt.org.spdx'    => 'SAX-PD',
	caption                => 'Sax Public Domain Notice',
	'caption.alt.org.tldr' => 'Sax Public Domain Notice (SAX-PD)',
	tags                   => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'No one owns SAX[:][ ]you may use it freely in both commercial',
};

=item * sds

I<Since v3.8.0.>

=item * sds_1

I<Since v3.8.0.>

=cut

$RE{sds} = {
	name    => 'SdS',
	caption => 'Show don\'t Sell License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{sds_1} = {
	name        => 'SdS-1.0.0',
	caption     => 'Show don\'t Sell License v1.0.0',
	description => <<'END',
Proof:
[Github](https://github.com/SparrowOchon/Humble-dl/blob/master/LICENSE)
END
	tags => [
		'type:singleversion:sds',
	],
	licenseversion => '1.0.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part4_2' =>
		'If the clause 4\.1 becomes true the licensee must pay',
};

=item * sgi_b

=item * sgi_b_1

I<Since v3.1.101.>

=item * sgi_b_1_1

I<Since v3.1.101.>

=item * sgi_b_2

I<Since v3.1.101.>

=cut

$RE{sgi_b} = {
	name                       => 'SGI-B',
	'name.alt.misc.unbranded'  => 'FreeB',
	caption                    => 'SGI Free Software License B',
	'caption.alt.misc.shorter' => 'SGI FreeB',
	iri                        => 'https://www.sgi.com/projects/FreeB/',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{sgi_b_1} = {
	name                                              => 'SGI-B-1.0',
	'name.alt.org.spdx.since.date_20130117'           => 'SGI-B-1.0',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'SGI-v1.0',
	caption => 'SGI Free Software License B v1.0',
	tags    => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		'License Grant[. ]Subject to the provisions',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[ ][(]Version 1\.0 1[/]25[/]2000[)][  ]'
		. '[*)]Definitions[.]',
};

$RE{sgi_b_1_1} = {
	name                                              => 'SGI-B-1.1',
	'name.alt.org.spdx.since.date_20130117'           => 'SGI-B-1.1',
	'name.alt.misc.fossology_old'                     => 'SGI-B1.1',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'SGI-v1.1',
	caption => 'SGI Free Software License B v1.1',
	tags    => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.part.title' => 'SGI License Grant',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[ ][(]Version 1\.1 02[/]22[/]2000[)][  ]'
		. '[*)]Definitions[.]',
};

$RE{sgi_b_2} = {
	name                                    => 'SGI-B-2.0',
	'name.alt.org.spdx.since.date_20130117' => 'SGI-B-2.0',
	caption                  => 'SGI Free Software License B v2.0',
	'caption.alt.org.fedora' => 'SGI Free Software License B 2.0',
	'caption.alt.org.tldr' => 'SGI Free Software License B v2.0 (SGI-B-2.0)',
	'name.alt.misc.fossology_old'                     => 'RPSL_v1.1',
	'name.alt.misc.fossology_old'                     => 'SGI-B2.0',
	'name.alt.misc.fossology_old_vague.synth.nogrant' => 'SGI-2.0',
	tags                                              => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.reproduction' =>
		'The above copyright notice including the dates of first publication',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[  ]'
		. '[(]Version 2\.0, Sept\. 18, 2008[)] '
		. 'Copyright[c] \[dates of first publication\] Silicon Graphics, Inc[. ]'
		. 'All Rights Reserved[.][  ]'
		. $P{perm_granted},
};

=item * simpl

I<Since v3.6.0.>

=item * simpl_2

I<Since v3.6.0.>

=cut

$RE{simpl} = {
	name                                  => 'SimPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38351460',
	caption                               => 'Simple Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{simpl_2} = {
	name                                            => 'SimPL-2.0',
	'name.alt.org.osi'                              => 'SimPL-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'simpl-2.0',
	'name.alt.org.osi.misc.cat_list'                => 'Simple-2.0',
	'name.alt.org.spdx'                             => 'SimPL-2.0',
	'name.alt.org.tldr.path.short'                  => 'simpl',
	caption                             => 'Simple Public License 2.0',
	'caption.alt.org.osi.synth.nogrant' => 'Simple Public License',
	'caption.alt.org.osi.misc.list'     => 'Simple Public License 2.0',
	'caption.alt.org.tldr' => 'Simple Public License 2.0 (SimPL)',
	description            => <<'END',
Origin: by Robert W. Gomulkiewicz in 2005,
inspired by GNU General Public License, Version 2.
Details at <https://web.archive.org/web/20150905060034/http://www.houstonlawreview.org/archive/downloads/42-4_pdf/Gomulkiewicz.pdf>
and at <https://www.thefreelibrary.com/Open+source+license+proliferation%3a+helpful+diversity+or+hopeless...-a0208273638>
END
	tags => [
		'type:singleversion:simpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'The SimPL applies to the software[\']s source and',
};

=item * simple_w3c

I<Since v3.6.0.>

=item * simple_w3c_1_1

I<Since v3.6.0.>

=cut

$RE{simple_w3c} = {
	name    => 'Simple',
	caption => 'Simple Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{simple_w3c_1_1} = {
	name    => 'Simple-1.1',
	caption => 'Simple Public License 1.1',
	iri     => 'https://www.analysisandsolutions.com/software/license.htm',
	description => <<'END',
Origin: W3C Software Notice and License (1998-07-20)
END
	tags => [
		'license:is:grant',
		'type:singleversion:simpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause2' =>
		'The name, servicemarks and trademarks of the copyright',
};

=item * sissl

I<Since v3.5.0.>

=item * sissl_1_1

I<Since v3.5.0.>

=item * sissl_1_2

I<Since v3.5.0.>

=cut

$RE{sissl} = {
	name                                            => 'SISSL',
	'name.alt.org.fedora'                           => 'SISSL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'sisslpl',
	'name.alt.org.perl'                             => 'sun',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q635577',
	caption                => 'Sun Industry Standards Source License',
	'caption.alt.org.perl' => 'Sun Internet Standards Source License (SISSL)',
	'caption.alt.org.trove' =>
		'Sun Industry Standards Source License (SISSL)',
	'caption.alt.org.wikipedia' => 'Sun Industry Standards Source License',
	'caption.alt.misc.long'     =>
		'Sun Industry Standards Source License (SISSL)',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{sissl_1_1} = {
	name                                                  => 'SISSL-1.1',
	'name.alt.org.osi.synth.nogrant'                      => 'SISSL',
	'name.alt.org.spdx.since.date_20130117.synth.nogrant' => 'SISSL',
	'name.alt.misc.fossology_old'                         => 'SISSL_v1.1',
	caption => 'Sun Industry Standards Source License v1.1',
	'caption.alt.org.osi.synth.nogrant' =>
		'Sun Industry Standards Source License',
	'caption.alt.org.spdx.until.date_20130912.synth.nogrant' =>
		'Sun Industry Standards Source License',
	'caption.alt.org.spdx.since.date_20130912' =>
		'Sun Industry Standards Source License v1.1',
	iri  => 'https://www.openoffice.org/licenses/sissl_license.html',
	tags => [
		'type:singleversion:sissl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Sun Industry Standards Source License[ - ]Version 1\.1[  ]'
		. '1\.0 DEFINITIONS',
};

$RE{sissl_1_2} = {
	name                                    => 'SISSL-1.2',
	'name.alt.org.spdx.since.date_20130912' => 'SISSL-1.2',
	caption                => 'Sun Industry Standards Source License v1.2',
	'caption.alt.org.tldr' =>
		'Sun Industry Standards Source License v1.2 (SISSL-1.2)',
	'caption.alt.misc.legal' =>
		'SUN INDUSTRY STANDARDS SOURCE LICENSE Version 1.2',
	iri =>
		'http://gridscheduler.sourceforge.net/Gridengine_SISSL_license.html',
	tags => [
		'type:singleversion:sissl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'SUN INDUSTRY STANDARDS SOURCE LICENSE[  ]'
		. 'Version 1\.2[  ]'
		. '1\.0 DEFINITIONS',
};

=item * sleepycat

I<Since v3.6.0.>

=cut

$RE{sleepycat} = {
	name                                            => 'Sleepycat',
	'name.alt.org.fedora.iri.self'                  => 'Sleepycat',
	'name.alt.org.osi'                              => 'Sleepycat',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'sleepycat',
	'name.alt.org.spdx'                             => 'Sleepycat',
	'name.alt.org.tldr.path.short'                  => 'sleepycat',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q2294050',
	caption                                         => 'Sleepycat License',
	'caption.alt.misc.berkeley'     => 'Berkeley Database License',
	'caption.alt.misc.public'       => 'Sleepycat Public License',
	'caption.alt.org.fedora'        => 'Sleepycat Software Product License',
	'caption.alt.org.osi'           => 'The Sleepycat License',
	'caption.alt.org.osi.misc.list' => 'Sleepycat License',
	'caption.alt.org.tldr'          => 'Sleepycat License',
	'caption.alt.org.trove'         => 'Sleepycat License',
	'caption.alt.org.wikipedia'     => 'Sleepycat License',
	tags                            => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.part.clause4' =>
		'obtain complete source code for the DB software and',
	'pat.alt.subject.license.scope.paragraph.part.clause4' =>
		'Redistributions in any form must be accompanied by information on how to obtain'
		. ' complete source code for the DB software'
		. ' and any accompanying software that uses the DB software',
};

=item * sncl

I<Since v3.8.0.>

=item * sncl_1_10

I<Since v3.8.0.>

=item * sncl_2_0_1

I<Since v3.8.0.>

=item * sncl_2_0_2

I<Since v3.8.0.>

=item * sncl_2_1

I<Since v3.8.0.>

=item * sncl_2_3

I<Since v3.8.0.>

=cut

$RE{sncl} = {
	name    => 'SNCL',
	caption => 'Simple Non Code License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{sncl_1_10} = {
	name                                 => 'SNCL-1.10.0',
	caption                              => 'Simple Non Code License v1.10.0',
	'caption.alt.org.tldr.synth.nogrant' => 'Simple non code license (SNCL)',
	description                          => <<'END',
Proof:
[Github](https://github.com/SiddChugh/Diffie-Hellman-Algorithm/blob/master/License.txt)
END
	tags => [
		'type:singleversion:sncl',
	],
	licenseversion => '1.10.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part1_6' =>
		'If the 1\.5 clause becomes true the licensee must pay',
};

$RE{sncl_2_0_1} = {
	name        => 'SNCL-2.0.1',
	caption     => 'Simple Non Code License v2.0.1',
	description => <<'END',
Proof:
[Github](https://github.com/MysteryDash/Simple-Non-Code-License/blob/af24a92211e3c35392acb21611f228200fd32fd0/License.txt)
END
	tags => [
		'type:singleversion:sncl',
	],
	licenseversion => '2.0.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part3_2' =>
		'If the 3\.1 clause becaumes true the licensee must pay',
};

$RE{sncl_2_0_2} = {
	name        => 'SNCL-2.0.2',
	caption     => 'Simple Non Code License v2.0.2',
	description => <<'END',
Identical to Simple Non Code License v2.0.1, except...
* typo correction in section 3.2

Proof:
[Github](https://github.com/MysteryDash/Simple-Non-Code-License/blob/9a045d0a8dc58341a35d11e4f3d8343c2d498ca5/License.txt)
END
	tags => [
		'type:singleversion:sncl',
	],
	licenseversion => '2.0.2',
};

$RE{sncl_2_1} = {
	name                              => 'SNCL-2.1.0',
	'name.alt.org.tldr.synth.nogrant' => 'simple-non-code-license-2.0.2',
	caption                           => 'Simple Non Code License v2.1.0',
	'caption.alt.org.tldr' => 'Simple Non Code License (SNCL) 2.1.0',
	description            => <<'END',
Proof:
[Github](https://github.com/MysteryDash/Simple-Non-Code-License/blob/480fb558b17aa1d23ad6d61ad420ea19d08d8940/License.txt)
END
	tags => [
		'type:singleversion:sncl',
	],
	licenseversion => '2.1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part1_3_4' =>
		'The same rule about commercial use stated in clause 1\.1 applies here',
};

$RE{sncl_2_3} = {
	name        => 'SNCL-2.3.0',
	caption     => 'Simple Non Code License v2.3.0',
	description => <<'END',
Proof:
[Github](https://github.com/MysteryDash/Simple-Non-Code-License/blob/17766cb9f31240dc04030412b1da94d43097408f/License.txt)
END
	tags => [
		'type:singleversion:sncl',
	],
	licenseversion => '2.3.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.part3_2' =>
		'If the clause 3\.1 becomes true the licensee must pay',
};

=item * spl

=item * spl_1

=cut

$RE{spl} = {
	name                                            => 'SPL',
	'name.alt.org.fedora'                           => 'SPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'sunpublic',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q648252',
	caption                                         => 'Sun Public License',
	'caption.alt.org.trove'                         => 'Sun Public License',
	'caption.alt.org.wikipedia'                     => 'Sun Public License',
	tags                                            => [
		'type:versioned:decimal',
	],
};

$RE{spl_1} = {
	name                                => 'SPL-1.0',
	'name.alt.org.osi'                  => 'SPL-1.0',
	'name.alt.org.spdx'                 => 'SPL-1.0',
	'name.alt.misc.fossology_old'       => 'Sun-PL_v1.0',
	'name.alt.misc.fossology_old_short' => 'SunPL1.0',
	caption                             => 'Sun Public License v1.0',
	'caption.alt.org.osi'               => 'Sun Public License, Version 1.0',
	'caption.alt.org.osi.misc.list'     => 'Sun Public License 1.0',
	'caption.alt.org.tldr' => 'Sun Public License v1.0 (SPL-1.0)',
	tags                   => [
		'type:singleversion:spl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection' =>
		'Exhibit A -Sun Public License Notice[.][  ]'
		. 'The contents of this file are subject to the Sun Public License'
};

=item * ssleay

I<Since v3.2.0.>

=cut

$RE{ssleay} = {
	name                   => 'SSLeay',
	'name.alt.org.perl'    => 'ssleay',
	'caption.alt.org.perl' => 'Original SSLeay License',
	tags                   => [
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.attribution' =>
		'If this package is used in a product',
	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]'
		. $P{ad_mat_ack_ssleay} . '?',
	'pat.alt.subject.license.part.advertising_clause_2' =>
		'The word ["]cryptographic["] can be left out',
};

=item * stlport

I<Since v3.8.0.>

=cut

$RE{stlport} = {
	name                             => 'STLport',
	caption                          => 'STLport License Agreement',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, Cheusov variant',
	iri  => 'http://www.stlport.org/doc/license.html',
	tags => [
		'family:mit',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'The Licensee may distribute binaries compiled',
};

=item * sugarcrm

=item * sugarcrm_1_1_3

=cut

$RE{sugarcrm} = {
	name                                  => 'SugarCRM',
	'name.alt.org.wikidata.synth.nogrant' => 'Q3976707',
	caption                               => 'SugarCRM Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{sugarcrm_1_1_3} = {
	name                           => 'SugarCRM-1.1.3',
	'name.alt.org.spdx'            => 'SugarCRM-1.1.3',
	'name.alt.org.tldr.path.short' => 'sugarcrm-1.1.3',
	caption                        => 'SugarCRM Public License v1.1.3',
	'caption.alt.org.tldr'         =>
		'SugarCRM Public License v1.1.3 (SugarCRM-1.1.3)',
	tags => [
		'type:singleversion:sugarcrm',
	],
	licenseversion => '1.1.3',

	'pat.alt.subject.license' =>
		'The SugarCRM Public License Version [(]["]SPL["][)] consists of',
};

=item * tosl

I<Since v3.6.0.>

=cut

# Yes, it is unversioned
$RE{tosl} = {
	name                                    => 'TOSL',
	'name.alt.org.fedora'                   => 'TOSL',
	'name.alt.org.spdx.since.date_20140807' => 'TOSL',
	'name.alt.misc.legal'                   => 'TRUST',
	caption                                 => 'Trusster Open Source License',
	'caption.alt.org.fedora'                => 'Trusster Open Source License',
	'caption.alt.misc.legal'                =>
		'Trusster Open Source License version 1.0a (TRUST)',
	description => <<'END',
Identical to Sleepycat, except...
* generalize source access clause to cover "this software"

Proof:
[Github](https://github.com/trusster/trusster/blob/master/truss/cpp/src/truss_verification_top.cpp)
END
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.part.clause4' =>
		'obtain complete source code for this software and',
	'pat.alt.subject.license.scope.paragraph.part.clause4' =>
		'Redistributions in any form must be accompanied by information on how to obtain'
		. ' complete source code for this software'
		. ' and any accompanying software that uses this software',
};

=item * truecrypt

I<Since v3.8.0.>

=item * truecrypt_3

I<Since v3.8.0.>

=cut

$RE{truecrypt} = {
	name                     => 'TrueCrypt',
	caption                  => 'TrueCrypt License',
	'caption.alt.org.fedora' => 'TrueCrypt License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{truecrypt_3} = {
	name                   => 'TrueCrypt-3.0',
	caption                => 'TrueCrypt License Version 3.0',
	'caption.alt.org.tldr' => 'TrueCrypt License Version 3.0',
	iri  => 'https://www.truecrypt71a.com/truecrypt-license/',
	tags => [
		'type:singleversion:truecrypt',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'License agreement for Encryption for the Masses',
};

=item * ucl

I<Since v3.6.0.>

=item * ucl_1

I<Since v3.6.0.>

=cut

$RE{ucl} = {
	name    => 'UCL',
	caption => 'Upstream Compatibility License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{ucl_1} = {
	name                                    => 'UCL-1.0',
	'name.alt.org.osi'                      => 'UCL-1.0',
	'name.alt.org.spdx.since.date_20191022' => 'UCL-1.0',
	caption               => 'Upstream Compatibility License v. 1.0',
	'caption.alt.org.osi' => 'Upstream Compatibility License v1.0',
	tags                  => [
		'license:contains:grant',
		'type:singleversion:ucl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.part1' =>
		'Licensed under the Upstream Compatibility License 1\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
};

=item * unicode_dfs

I<Since v3.9.0.>

=item * unicode_dfs_2015

I<Since v3.6.0.>

=item * unicode_dfs_2016

I<Since v3.6.0.>

=cut

$RE{unicode_dfs} = {
	name                                  => 'Unicode-DFS',
	'name.alt.org.wikidata.synth.nogrant' => 'Q67145209',
	caption => 'Unicode License Agreement - Data Files and Software',
	'caption.alt.org.wikidata' => 'Unicode, Inc. License Agreement',
	tags                       => [
		'license:is:grant',
		'type:versioned:decimal',
	],
};

$RE{unicode_dfs_2015} = {
	name                                    => 'Unicode-DFS-2015',
	'name.alt.org.fedora.synth.nogrant'     => 'Unicode',
	'name.alt.org.spdx.since.date_20170106' => 'Unicode-DFS-2015',
	caption => 'Unicode License Agreement - Data Files and Software (2015)',
	'caption.alt.org.fedora'              => 'Unicode License',
	'iri.alt.archive.time_20160426001149' =>
		'http://www.unicode.org/copyright.html#Exhibit1',
	tags => [
		'license:is:grant',
		'type:singleversion:unicode_dfs',
	],
	licenseversion => '2015',

	'pat.alt.subject.license.part.clause_2' =>
		'this copyright and permission notice appear in associated documentation, and',
};

$RE{unicode_dfs_2016} = {
	name                                    => 'Unicode-DFS-2016',
	'name.alt.org.osi'                      => 'Unicode-DFS-2016',
	'name.alt.org.spdx.since.date_20170106' => 'Unicode-DFS-2016',
	caption => 'Unicode License Agreement - Data Files and Software (2016)',
	'caption.alt.org.osi' =>
		'Unicode, Inc. License Agreement - Data Files and Software',
	'caption.alt.org.osi.misc.list' =>
		'Unicode Data Files and Software License',
	'caption.alt.org.osi.misc.cat_list' =>
		'Unicode License Agreement - Data Files and Software',
	iri  => 'https://www.unicode.org/license.html',
	tags => [
		'license:is:grant',
		'type:singleversion:unicode_dfs',
	],
	licenseversion => '2016',

	'pat.alt.subject.license.part.clause_2' =>
		'this copyright and permission notice appear in associated Documentation[.]',
};

=item * unicode_strict

=cut

$RE{unicode_strict} = {
	name                     => 'Unicode-strict',
	'name.alt.misc.scancode' => 'unicode-mappings',
	caption                  => 'Unicode strict',
	tags                     => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => 'hereby grants the right to freely use',
};

=item * unicode_tou

=cut

$RE{unicode_tou} = {
	name                                    => 'Unicode-TOU',
	'name.alt.org.spdx.since.date_20140807' => 'Unicode-TOU',
	caption                                 => 'Unicode Terms of Use',
	tags                                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'distribute all documents and files solely for informational',
};

=item * unlicense

=cut

$RE{unlicense} = {
	name                                    => 'Unlicense',
	'name.alt.org.osi'                      => 'Unlicense',
	'name.alt.org.spdx.since.date_20130912' => 'Unlicense',
	'name.alt.org.wikidata.synth.nogrant'   => 'Q21659044',
	'iri.alt.org.wikipedia'                 => 'Unlicense',
	caption                                 => 'The Unlicense',
	'caption.alt.org.fedora.iri.self'       => 'Unlicense',
	'caption.alt.org.tldr'                  => 'Unlicense',
	'caption.alt.org.trove'                 => 'The Unlicense (Unlicense)',
	'caption.alt.org.wikidata'              => 'Unlicense',
	iri                                     => 'https://unlicense.org/',
	'iri.alt.format.txt' => 'https://unlicense.org/UNLICENSE',
	tags                 => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This is free and unencumbered software released into the public domain',
};

=item * upl

I<Since v3.6.0.>

=item * upl_1

I<Since v3.6.0.>

=cut

$RE{upl} = {
	name                                  => 'UPL',
	'name.alt.org.fedora.iri.self'        => 'UPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38685700',
	caption                               => 'Universal Permissive License',
	'caption.alt.org.trove' => 'Universal Permissive License (UPL)',
	tags                    => [
		'type:versioned:decimal',
	],
};

$RE{upl_1} = {
	name                                    => 'UPL-1.0',
	'name.alt.org.osi.synth.nogrant'        => 'UPL',
	'name.alt.org.spdx.since.date_20150730' => 'UPL-1.0',
	'name.alt.org.tldr.path.short'          => 'upl-1,0',
	caption               => 'Universal Permissive License v1.0',
	'caption.alt.org.osi' =>
		'The Universal Permissive License (UPL), Version 1.0',
	'caption.alt.org.osi.misc.list.synth.nogrant' =>
		'Universal Permissive License',
	'caption.alt.org.tldr' => 'Universal Permissive License 1.0 (UPL-1.0)',
	tags                   => [
		'license:is:grant',
		'type:singleversion:upl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'The above copyright notice and either this complete permission notice',
};

=item * vsl

I<Since v3.6.0.>

=item * vsl_1

I<Since v3.6.0.>

=cut

$RE{vsl} = {
	name                                            => 'VSL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'vovidapl',
	'name.alt.misc.fossology_old'                   => 'Vovida',
	caption => 'Vovida Software License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{vsl_1} = {
	name                                  => 'VSL-1.0',
	'name.alt.org.fedora.synth.nogrant'   => 'VSL',
	'name.alt.org.osi'                    => 'VSL-1.0',
	'name.alt.org.spdx'                   => 'VSL-1.0',
	'name.alt.org.wikidata.synth.nogrant' => 'Q38349857',
	caption                               => 'Vovida Software License v1.0',
	'caption.alt.org.fedora'              => 'Vovida Software License v. 1.0',
	'caption.alt.org.osi'           => 'The Vovida Software License v. 1.0',
	'caption.alt.org.osi.misc.list' => 'Vovida Software License v. 1.0',
	'caption.alt.org.tldr'     => 'Vovida Software License v1.0 (VSL-1.0)',
	'caption.alt.org.trove'    => 'Vovida Software License 1.0',
	'caption.alt.org.wikidata' => 'Vovida Software License Version 1.0',
	description                => <<'END',
Identical to BSD (3 clause), except...
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause

Identical to Apache 1.1, except...
* drop advertisement clause
* replace "Apache" and "Apache Software Foundation" with "VOCAL"
* extend disclaimers to include title and non-infringement, and expensive damages
END
	tags => [
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:singleversion:vsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause4' =>
		'Products derived from this software may not be called ["]VOCAL["],',
};

=item * vspl

I<Since v3.8.0.>

=cut

$RE{vspl} = {
	name                   => 'VSPL',
	caption                => 'Very Simple Public License',
	'caption.alt.org.tldr' => 'Very Simple Public License (VSPL)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'You can modify, distribute and use this software '
		. 'for any purpose without any restrictions '
		. 'as long as you keep this copyright notice intact' . '[. ]'
		. 'The software is provided without any warranty[.]',
};

=item * w3c

I<Since v3.6.0.>

=item * w3c_19980519

I<Since v3.6.0.>

=item * w3c_19980720

I<Since v3.6.0.>

=item * w3c_20021231

I<Since v3.6.0.>

=item * w3c_20150513

I<Since v3.6.0.>

=cut

$RE{w3c} = {
	name                                   => 'W3C',
	'name.alt.org.debian.synth.nogrant'    => 'W3C~unknown',
	'name.alt.org.wikidata.synth.nogrant'  => 'Q3564577',
	caption                                => 'W3C License',
	'caption.alt.org.debian.synth.nogrant' => 'W3C License (unknown version)',
	'caption.alt.org.trove'                => 'W3C License',
	'caption.alt.org.wikidata'  => 'W3C Software Notice and License',
	'caption.alt.org.wikipedia' => 'W3C Software Notice and License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{w3c_19980519} = {
	name    => 'W3C-19980519',
	caption => 'W3C Software Notice and License (1998-05-19)',
	'caption.alt.misc.legal.synth.nogrant' => 'W3C IPR SOFTWARE NOTICE',
	iri                                    =>
		'https://www.w3.org/Consortium/Legal/copyright-software-19980519.html',
	tags => [
		'license:is:grant',
		'type:singleversion:w3c',
	],
	licenseversion => '19980519',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This W3C software is being provided',
	'pat.alt.subject.license.scope.sentence.part.clause2' =>
		'If none exist, then a notice of the form',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause1' =>
		'A link or URL to the original W3C source',
};

$RE{w3c_19980720} = {
	name                                    => 'W3C-19980720',
	'name.alt.org.spdx.since.date_20150513' => 'W3C-19980720',
	caption => 'W3C Software Notice and License (1998-07-20)',
	'caption.alt.misc.legal.synth.nogrant' =>
		'W3C® SOFTWARE NOTICE AND LICENSE',
	'caption.alt.misc.notice' =>
		'W3C\'s Software Intellectual Property License',
	iri  => 'https://www.w3.org/Consortium/Legal/copyright-software-19980720',
	tags => [
		'license:is:grant',
		'type:singleversion:w3c',
	],
	licenseversion => '19980720',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This W3C work [(]including software, documents, or other',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause3' =>
		'Notice of any changes or modifications to the W3C files',
};

$RE{w3c_20021231} = {
	name                                => 'W3C-20021231',
	'name.alt.org.debian'               => 'W3C-20021231',
	'name.alt.org.fedora.synth.nogrant' => 'W3C',
	'name.alt.org.osi.synth.nogrant'    => 'W3C',
	'name.alt.org.spdx.synth.nogrant'   => 'W3C',
	caption => 'W3C Software Notice and License (2002-12-31)',
	'caption.alt.org.fedora.synth.nogrant' =>
		'W3C Software Notice and License',
	'caption.alt.org.osi.synth.nogrant' =>
		'The W3C® SOFTWARE NOTICE AND LICENSE',
	'caption.alt.org.osi.misc.list.synth.nogrant'            => 'W3C License',
	'caption.alt.org.spdx.until.date_20130912.synth.nogrant' =>
		'W3C Software and Notice License',
	'caption.alt.org.spdx.since.date_20130912.until.date_20150513.synth.nogrant'
		=> 'W3C Software Notice and License',
	'caption.alt.org.spdx.since.date_20150513.synth.nogrant' =>
		'W3C Software Notice and License (2002-12-31)',
	'caption.alt.org.tldr.synth.nogrant' =>
		'W3C Software Notice and License (W3C)',
	'caption.alt.misc.notice' => 'W3C® Software License',
	iri                       =>
		'https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231',
	tags => [
		'license:is:grant',
		'type:singleversion:w3c',
	],
	licenseversion => '20021231',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This work [(]and included software, documentation',
	'pat.alt.subject.license.scope.sentence.part.clause2' =>
		'If none exist, the W3C Software Short Notice',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause3' =>
		'Notice of any changes or modifications to the files,',
};

$RE{w3c_20150513} = {
	name                                    => 'W3C-20150513',
	'name.alt.org.spdx.since.date_20170106' => 'W3C-20150513',
	caption => 'W3C Software and Document Notice and License (2015-05-13)',
	'caption.alt.org.spdx' =>
		'W3C Software Notice and Document License (2015-05-13)',
	'caption.alt.misc.notice' => 'W3C® Software and Document License',
	iri                       =>
		'https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document',
	tags => [
		'license:is:grant',
		'type:singleversion:w3c',
	],
	licenseversion => '20150513',

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This work is being provided',
	'pat.alt.subject.license.scope.sentence.part.clause2' =>
		'If none exist, the W3C Software and Document Short Notice',
	'pat.alt.subject.license.scope.line.scope.sentence.part.clause3' =>
		'Notice of any changes or modifications, through',
};

=item * watcom

=item * watcom_1

=cut

$RE{watcom} = {
	name                                            => 'Watcom',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'sybase',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q7659488',
	caption                     => 'Sybase Open Watcom Public License',
	'caption.alt.org.wikipedia' => 'Sybase Open Watcom Public License',
	'caption.alt.misc.source'   => 'The Sybase Open Source License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{watcom_1} = {
	name                => 'Watcom-1.0',
	'name.alt.org.osi'  => 'Watcom-1.0',
	'name.alt.org.spdx' => 'Watcom-1.0',
	'name.alt.org.tldr' =>
		'sybase-open-watcom-public-license-1.0-(watcom-1.0)',
	caption                  => 'Sybase Open Watcom Public License 1.0',
	'caption.alt.org.fedora' => 'Sybase Open Watcom Public License 1.0',
	'caption.alt.org.osi.synth.nogrant' => 'The Sybase Open Source Licence',
	'caption.alt.org.osi.misc.list'     =>
		'Sybase Open Watcom Public License 1.0',
	'caption.alt.org.tldr' =>
		'Sybase Open Watcom Public License 1.0 (Watcom-1.0)',
	iri  => 'ftp://ftp.openwatcom.org/install/license.txt',
	tags => [
		'type:singleversion:watcom',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'USE OF THE SYBASE OPEN WATCOM SOFTWARE DESCRIBED BELOW',
};

=item * wordnet

I<Since v3.8.0.>

=cut

$RE{wordnet} = {
	name                             => 'WordNet',
	caption                          => 'WordNet License',
	'summary.alt.org.fedora.iri.mit' => 'MIT-style license, WordNet Variant',
	iri => 'https://wordnet.princeton.edu/license-and-commercial-use',
	'iri.alt.archive.time_20180118074053' =>
		'https://wordnet.princeton.edu/wordnet/license',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence.part.intro' =>
		'This software and database is being provided',
	'_pat.alt.subject.license.scope.line.scope.sentence.part.permissions' => [

		# cover line wrapping at either side of word "database"
		'distribute this software and database',
		'database and its documentation for any purpose',
	],
};

=item * wtfpl

=item * wtfpl_1

I<Since v3.1.95.>

=item * wtfpl_2

I<Since v3.1.95.>

=cut

$RE{wtfpl} = {
	name                                  => 'WTFPL',
	'name.alt.org.fedora.iri.self'        => 'WTFPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q152481',
	'name.alt.org.wikipedia'              => 'WTFPL',
	caption                  => 'do What The Fuck you want to Public License',
	'caption.alt.org.fedora' => 'Do What The F*ck You Want To Public License',
	'caption.alt.misc.shorter' => 'WTF Public License',
	'caption.alt.org.wikidata' => 'WTFPL',
	iri                        => 'http://www.wtfpl.net/',
	'iri.alt.misc.old'         => 'http://sam.zoy.org/wtfpl/COPYING',
	tags                       => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' =>
		"$the?[Dd]o What The F(?:u|[*])ck [Yy]ou [Ww]ant(?: [Tt]o)? Public License"
		. '(?: [(]WTFPL[)])?',
	'pat.alt.subject.license.scope.sentence' =>
		'[Yy]ou just[  ]DO WHAT THE FUCK YOU WANT TO[.]',
};

$RE{wtfpl_1} = {
	name                                                  => 'WTFPL-1.0',
	'name.alt.org.debian'                                 => 'WTFPL-1.0',
	'name.alt.org.spdx.since.date_20130117.synth.nogrant' => 'WTFPL',
	caption => 'Do What The Fuck You Want To Public License, Version 1',
	'caption.alt.org.spdx.synth.nogrant' =>
		'Do What The F*ck You Want To Public License',
	'caption.alt.org.tldr' =>
		'Do What The F*ck You Want To Public License (WTFPL)',
	iri  => 'http://cvs.windowmaker.org/co.php/wm/COPYING.WTFPL',
	tags => [
		'license:is:grant',
		'license:published:by_sam_hocevar',
		'type:singleversion:wtfpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'simple and you just[  ]DO WHAT THE FUCK YOU WANT TO[.]',
};

$RE{wtfpl_2} = {
	name                => 'WTFPL-2',
	'name.alt.org.tldr' => 'do-wtf-you-want-to-public-license-v2-(wtfpl-2.0)',
	'name.alt.org.tldr.path.short' => 'wtfpl',
	caption => 'Do What The Fuck You Want To Public License, Version 2',
	'caption.alt.legal.license' =>
		'DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2',
	'caption.alt.org.tldr' =>
		'Do What The F*ck You Want To Public License v2 (WTFPL-2.0)',
	iri                => 'http://www.wtfpl.net/',
	'iri.alt.misc.old' => 'http://sam.zoy.org/wtfpl/COPYING',
	tags               => [
		'license:is:grant',
		'license:published:by_sam_hocevar',
		'type:singleversion:wtfpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.header' =>
		'of the Do What The Fuck You Want To Public License',
	'pat.alt.subject.license.scope.sentence' =>
		'[*)]You just[  ]DO WHAT THE FUCK YOU WANT TO[.]',
};

=item * wtfnmfpl

I<Since v3.1.95.>

=item * wtfnmfpl_1

I<Since v3.1.95.>

=cut

$RE{wtfnmfpl} = {
	name                   => 'WTFNMFPL',
	'caption.alt.org.tldr' =>
		'Do What The Fuck You Want To But It\'s Not My Fault Public License v1 (WTFNMFPL-1.0)',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{wtfnmfpl_1} = {
	name                  => 'WTFNMFPL-1.0',
	'name.alt.misc.short' => 'WTFNMFPLv1',
	caption               =>
		'Do What The Fuck You Want To But It\'s Not My Fault Public License v1',
	'caption.alt.legal.license' =>
		'DO WHAT THE FUCK YOU WANT TO BUT IT\'S NOT MY FAULT PUBLIC LICENSE, Version 1',
	'caption.alt.org.tldr' =>
		'Do What The Fuck You Want To But It\'s Not My Fault Public License v1 (WTFNMFPL-1.0)',
	iri =>
		'http://www.adversary.org/wp/2013/10/14/do-what-the-fuck-you-want-but-its-not-my-fault/',
	'iri.alt.iri.github' => 'https://github.com/adversary-org/wtfnmf',
	tags                 => [
		'license:is:grant',
		'type:singleversion:wtfnmfpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Do not hold the author[(]s[)], creator[(]s[)], developer[(]s[)] or distributor[(]s[)]',
};

=item * x11

I<Since v3.6.0.>

=cut

$RE{x11} = {
	name                                                  => 'X11',
	'name.alt.org.spdx.since.date_20130117.synth.nogrant' => 'X11',
	'name.alt.org.tldr.path.short'                        => 'x11',
	'name.alt.org.wikidata.synth.nogrant'                 => 'Q18526202',
	caption                                               => 'X11 License',
	'caption.alt.org.tldr'                                => 'X11 License',
	'caption.alt.org.wikidata'                            => 'X11 license',
	'caption.alt.misc.wayland' => 'the MIT X11 license',
	description                => <<'END',
Origin: By MIT Laboratory for Computer Science (MIT–LCS) in 1984 for PC/IP.

Proof: <https://ieeexplore.ieee.org/document/9263265>
END
	tags => [
		'family:mit',
		'license:contains:license:mit_new',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection.part.last_half' =>
		$P{to_copy_sublicence_conditions}
		. '[:][  ]'
		. $P{retain_copr_perm_subst}
		. '[.][  ]'
		. $P{discl_warranties_any_kind_noninfringement} . '[. ]'
		. $P{discl_liability_claim}
		. '[.][  ]'
		. 'Except as contained in this notice, the name of the X Consortium'
		. ' shall not be used in advertising',
	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'Except as contained in this notice, the name of the X Consortium',
};

=item * xfree86

I<Since v3.8.0.>

=item * xfree86_1_1

I<Since v3.8.0.>

=cut

$RE{xfree86} = {
	name                                  => 'XFree86',
	'name.alt.org.wikidata.synth.nogrant' => 'Q100375790',
	caption                               => 'XFree86 License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{xfree86_1_1} = {
	name                   => 'XFree86-1.1',
	'name.alt.org.spdx'    => 'XFree86-1.1',
	caption                => 'XFree86 License 1.1',
	'caption.alt.org.tldr' => 'XFree86 License 1.1 (XFree86-1.1)',
	description            => <<'END',
Identical to BSD (4 clause), except...
* replace permissions clause with MIT (Expat) or X11 permissions clause
* extend reproduce-copyright-notices clause to require specific placement
* extend non-endorsement clause to require specific placement
* replace non-endorsement clause with X11 non-endorsement clause
END
	tags => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:singleversion:xfree86',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.sentence' =>
		'in the same place and form as other',
};

=item * xnet

I<Since v3.6.0.>

=cut

$RE{xnet} = {
	name                                            => 'Xnet',
	'name.alt.org.osi'                              => 'Xnet',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'xnet',
	'name.alt.org.spdx'                             => 'Xnet',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q38346089',
	caption                                         => 'X.Net License',
	'caption.alt.org.fedora'                        => 'X.Net License',
	'caption.alt.org.osi'           => 'The X.Net, Inc. License',
	'caption.alt.org.osi.misc.list' => 'X.Net License',
	'caption.alt.org.tldr'          => 'X.Net License (Xnet)',
	'caption.alt.org.trove'         => 'X.Net License',
	'caption.alt.org.wikidata'      => 'X.Net, Inc. License',
	description                     => <<'END',
Identical to MIT (a.k.a. Expat), except...
* add requirement of governance in the State of California
END
	tags => [
		'family:mit',
		'license:contains:license:mit_new',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'This agreement shall be governed in all respects',
};

=item * ypl

I<Since v3.8.0.>

=item * ypl_1

I<Since v3.8.0.>

=item * ypl_1_1

I<Since v3.8.0.>

=cut

$RE{ypl} = {
	name                                  => 'YPL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q16948289',
	caption                               => 'Yahoo! Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{ypl_1} = {
	name                     => 'YPL-1.0',
	'name.alt.org.spdx'      => 'YPL-1.0',
	caption                  => 'Yahoo! Public License v1.0',
	'caption.alt.org.fedora' => 'Yahoo Public License 1.0',
	iri  => 'https://www.zimbra.com/license/yahoo_public_license_1.0.html',
	tags => [
		'type:singleversion:ypl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.sentence.part.section6_2' =>
		'In the event Yahoo! determines that',
};

$RE{ypl_1_1} = {
	name                     => 'YPL-1.1',
	'name.alt.org.fedora'    => 'YPLv1.1',
	'name.alt.org.spdx'      => 'YPL-1.1',
	caption                  => 'Yahoo! Public License v1.1',
	'caption.alt.org.fedora' => 'Yahoo Public License v 1.1',
	'caption.alt.org.tldr'   => 'Yahoo! Public License v1.1 (YPL-1.1)',
	iri  => 'http://www.zimbra.com/license/yahoo_public_license_1.1.html',
	tags => [
		'type:singleversion:ypl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.line.scope.sentence.part.section6_2' =>
		'In the event You violate the terms of this Agreement, Yahoo!',
};

=item * zed

I<Since v3.8.0.>

=cut

$RE{zed} = {
	name                                    => 'Zed',
	'name.alt.org.fedora'                   => 'Zed',
	'name.alt.org.spdx.since.date_20140807' => 'Zed',
	caption                                 => 'Zed License',
	'caption.alt.org.tldr'                  => 'Zed License',
	tags                                    => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'You may copy and distribute this file freely',
};

=item * zend

I<Since v3.8.0.>

=item * zend_2

I<Since v3.8.0.>

=cut

$RE{zend} = {
	name                                  => 'ZEL',
	'name.alt.org.wikidata.synth.nogrant' => 'Q85269786',
	caption                               => 'Zend Engine License',
	'caption.alt.org.wikidata'            => 'Zend license',
	'caption.alt.misc.short'              => 'Zend License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{zend_2} = {
	name                                    => 'ZEL-2.00',
	'name.alt.misc.fsf'                     => 'ZELv2.0',
	'name.alt.org.fedora.synth.nogrant'     => 'Zend',
	'name.alt.org.spdx.since.date_20140807' => 'Zend-2.0',
	caption                                 => 'Zend License v2.0',
	'caption.alt.org.fedora'                => 'Zend License v2.0',
	'caption.alt.misc.legal' => 'The Zend Engine License, version 2.00',
	iri                      => 'http://www.zend.com/license/2_00.txt',
	tags                     => [
		'type:singleversion:zend',
	],
	licenseversion => '2.00',

	'pat.alt.subject.license.scope.line.scope.sentence.part.clause4' =>
		'Zend Technologies Ltd\. may publish revised and[/]or new',
};

=item * zimbra

I<Since v3.8.0.>

=item * zimbra_1_3

I<Since v3.8.0.>

=item * zimbra_1_4

=cut

$RE{zimbra} = {
	name                => 'Zimbra',
	'name.alt.misc.fsf' => 'ZPL',
	caption             => 'Zimbra Public License',
	tags                => [
		'type:versioned:decimal',
	],
};

$RE{zimbra_1_3} = {
	name                     => 'Zimbra-1.3',
	'name.alt.org.fsf'       => 'ZPLv1.3',
	'name.alt.org.spdx'      => 'Zimbra-1.3',
	caption                  => 'Zimbra Public License v1.3',
	'caption.alt.org.fedora' => 'Zimbra Public License 1.3',
	'caption.alt.org.tldr'   => 'Zimbra Public License v1.3 (Zimbra-1.3)',
	'caption.alt.misc.legal' => 'Zimbra Public License, Version 1.3 (ZPL)',
	iri  => 'http://www.zimbra.com/license/zimbra-public-license-1-3.html',
	tags => [
		'type:singleversion:zimbra',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.line.scope.sentence.part.section1_1' =>
		'Subject to the terms and conditions of this Agreement, VMware',
};

$RE{zimbra_1_4} = {
	name                                    => 'Zimbra-1.4',
	'name.alt.org.spdx.since.date_20150513' => 'Zimbra-1.4',
	caption                                 => 'Zimbra Public License v1.4',
	'caption.alt.org.tldr.synth.nogrant'    => 'zimbra public license',
	'caption.alt.misc.legal' => 'Zimbra Public License, Version 1.4 (ZPL)',
	iri  => 'https://www.zimbra.com/legal/zimbra-public-license-1-4/',
	tags => [
		'type:singleversion:zimbra',
	],
	licenseversion => '1.4',

	'pat.alt.subject.license.scope.line.scope.sentence.part.section1_1' =>
		'Subject to the terms and conditions of this Agreement, Zimbra',
};

=item * zlib

=cut

$RE{zlib} = {
	name                                            => 'Zlib',
	'name.alt.org.fedora'                           => 'zlib',
	'name.alt.org.fsf'                              => 'Zlib',
	'name.alt.org.osi'                              => 'Zlib',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'zlib-license',
	'name.alt.org.perl'                             => 'zlib',
	'name.alt.org.spdx'                             => 'Zlib',
	'name.alt.org.tldr.path.short'                  => 'zlib',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q207243',
	caption                                         => 'zlib License',
	'caption.alt.org.fedora'                        => 'zlib/libpng License',
	'caption.alt.org.osi'                 => 'The zlib/libpng License',
	'caption.alt.org.osi.misc.list'       => 'zlib/libpng license',
	'caption.alt.org.tldr'                => 'Zlib-Libpng License (Zlib)',
	'caption.alt.org.trove'               => 'zlib/libpng License',
	'caption.alt.org.wikipedia.misc.case' => 'zlib license',
	iri                   => 'http://zlib.net/zlib_license.html',
	'iri.alt.org.steward' => 'http://www.gzip.org/zlib/zlib_license.html',
	tags                  => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote} . '[. ]'
		. $P{use_ack_apprec_not_req}
		. '[.][  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter},
};

=item * zlib_acknowledgement

=cut

$RE{zlib_acknowledgement} = {
	name                                    => 'zlib-acknowledgement',
	'name.alt.org.fedora.iri.self'          => 'Nunit',
	'name.alt.org.spdx.since.date_20140807' => 'zlib-acknowledgement',
	'name.alt.org.spdx.misc.old.since.date_20140807.until.date_20171228' =>
		'Nunit',
	caption                  => 'zlib/libpng License with Acknowledgement',
	'caption.alt.org.fedora' => 'zlib/libpng License with Acknowledgement',
	'caption.alt.org.fedora.misc.short' => 'zlib with acknowledgement',
	'caption.alt.org.fedora.misc.nunit' => 'Nunit License',
	'caption.alt.org.spdx' => 'zlib/libpng License with Acknowledgement',
	'caption.alt.org.spdx.misc.old.until.date_20171228' => 'Nunit License',
	tags                                                => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote} . '[. ]'
		. $P{use_ack_req}
		. '[.][  ]Portions Copyright \S+ [-#]+ Charlie Poole '
		. 'or Copyright \S+ [-#]+ James W\. Newkirk, Michael C\. Two, Alexei A\. Vorontsov '
		. 'or Copyright \S+ [-#]+ Philip A\. Craig[  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter},
};

=item * zpl

I<Since v3.1.102.>

=item * zpl_1

I<Since v3.1.102.>

=item * zpl_1_1

I<Since v3.1.102.>

=item * zpl_2

I<Since v3.1.102.>

=item * zpl_2_1

I<Since v3.1.102.>

=cut

$RE{zpl} = {
	name                                            => 'ZPL',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'zpl',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q3780982',
	'name.alt.misc.fossology_old'                   => 'Zope',
	caption                                         => 'Zope Public License',
	'caption.alt.org.trove.synth.nogrant'           => 'Zope Public License',
	'caption.alt.org.wikipedia'                     => 'Zope Public License',
	tags                                            => [
		'type:versioned:decimal',
	],
};

$RE{zpl_1} = {
	name                     => 'ZPL-1.0',
	'name.alt.org.fedora'    => 'ZPLv1.0',
	'name.alt.org.fsf'       => 'ZopePLv1.0',
	caption                  => 'Zope Public License (ZPL) Version 1.0',
	'caption.alt.org.fedora' => 'Zope Public License v 1.0',
	'caption.alt.misc.plain' => 'Zope Public License 1.0',
	'iri.alt.archive.time_20000816090640' =>
		'http://www.zope.org/Resources/ZPL',
	tags => [
		'type:singleversion:zpl',
	],
	licenseversion => '1.0',
};

$RE{zpl_1_1} = {
	name                          => 'ZPL-1.1',
	'name.alt.org.spdx'           => 'ZPL-1.1',
	'name.alt.misc.fossology_old' => 'ZPL1.1',
	caption                       => 'Zope Public License 1.1',
	'caption.alt.org.tldr'        => 'Zope Public License 1.1 (ZPL-1.1)',
	tags                          => [
		'type:singleversion:zpl',
	],
	licenseversion => '1.1',
};

$RE{zpl_2} = {
	name                                => 'ZPL-2.0',
	'name.alt.org.fedora'               => 'ZPLv2.0',
	'name.alt.org.osi'                  => 'ZPL-2.0',
	'name.alt.org.spdx'                 => 'ZPL-2.0',
	'name.alt.org.tldr.path.short'      => 'zpl-2.0',
	'name.alt.misc.fossology_old'       => 'Zope-PL_v2.0',
	'name.alt.misc.fossology_old_short' => 'ZPL2.0',
	caption                             => 'Zope Public License 2.0',
	'caption.alt.org.fedora'            => 'Zope Public License v 2.0',
	'caption.alt.org.osi'               => 'The Zope Public License Ver.2.0',
	'caption.alt.org.osi.misc.list'     => 'Zope Public License 2.0',
	'caption.alt.org.osi.misc.cat_list' => 'Zope Public License 2.o',
	'caption.alt.org.tldr' => 'Zope Public License 2.0 (ZPL-2.0)',
	iri                    => 'http://old.zope.org/Resources/License/ZPL-1.1',
	tags                   => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:singleversion:zpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.part2_3' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]'
		. 'The name Zope Corporation[tm] must not '
		. $P{used_endorse_deriv}
		. $P{without_prior_written},
	'pat.alt.subject.license.scope.sentence.part.part3' =>
		'The name Zope Corporation[tm] must not be used to endorse',
};

$RE{zpl_2_1} = {
	name                          => 'ZPL-2.1',
	'name.alt.org.fedora'         => 'ZPLv2.1',
	'name.alt.org.fsf'            => 'ZPL-2.1',
	'name.alt.org.spdx'           => 'ZPL-2.1',
	'name.alt.misc.fossology_old' => 'ZPL2.1',
	caption                       => 'Zope Public License 2.1',
	'caption.alt.org.fedora'      => 'Zope Public License v 2.1',
	'caption.alt.org.fsf'         => 'Zope Public License Version 2.1',
	'caption.alt.org.tldr'        => 'Zope Public License 2.1 (ZPL-2.1)',
	iri                           => 'http://old.zope.org/Resources/ZPL/',
	description                   => <<'END',
Identical to BSD 3-Clause Modification, except...
* add no-ServiceMarks clause
END
	tags => [
		'family:bsd',
		'license:is:grant',
		'type:singleversion:zpl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection.part.part2_3' =>
		$P{nopromo_neither}
		. ' from the copyright holders'
		. '[.][  ]' . '[*)]'
		. 'The right to distribute this software or to use it for any purpose'
		. ' does not give you the right to use Servicemarks',
};

=back

=head2 License combinations

Patterns each covering a combination of multiple licenses.

Each of these patterns has the tag B< type:combo >.

=over

=item * net_snmp

I<Since v3.6.0.>

=cut

$RE{net_snmp} = {
	name                                    => 'Net-SNMP',
	'name.alt.org.spdx.since.date_20170106' => 'Net-SNMP',
	caption                                 => 'Net-SNMP License',
	tags                                    => [
		'license:contains:license:bsd_3_clause',
		'license:contains:license:hpnd',
		'license:contains:license:mit_cmu',
		'type:combo',
	],
};

=item * perl

=cut

$RE{perl} = {
	name                     => 'Perl',
	'name.alt.org.perl'      => 'perl_5',
	'name.alt.misc.spdx'     => 'Artistic or GPL-1+',
	caption                  => 'The Perl 5 License',
	'caption.alt.org.fedora' => 'Perl License',
	'caption.alt.misc.short' => 'Perl License',
	'caption.alt.misc.long'  => 'The Perl 5 programming language License',
	'caption.alt.org.perl'   =>
		'The Perl 5 License (Artistic 1 & GPL 1 or later)',
	summary =>
		'the same terms as the Perl 5 programming language itself (Artistic or GPL)',
	'summary.alt.misc.short'            => 'same terms as Perl',
	'summary.alt.misc.software_license' =>
		'same terms as the Perl 5 programming language system itself',
	tags => [
		'license:includes:license:artistic_1_perl',
		'license:includes:license:gpl_1_or_newer',
		'type:combo',
	],

	'pat.alt.subject.name.misc.summary' =>
		"$the?same terms as $the?Perl(?: 5)?(?: programming language)? itself(?: [(]Artistic or GPL[)])?",
	'pat.alt.subject.license.scope.multisection.part.license' =>
		'(?:under the terms of either[:][  ])?'
		. '[*)]the GNU General Public License '
		. 'as published by the Free Software Foundation[;] '
		. 'either version 1, or [(]at your option[)] any later version, '
		. 'or[  ]'
		. '[*)]the ["]Artistic License["]',
};

=item * python_2

I<Since v3.9.0.>

=cut

# license scheme is combo, despite versioned name
$RE{python_2} = {
	name                  => 'Python-2.0',
	'name.alt.org.fedora' => 'Python',
	'name.alt.org.osi'    => 'Python-2.0',
	'name.alt.org.osi.iri.stem.until.date_20110430.synth.nogrant' =>
		'PythonSoftFoundation',
	'name.alt.org.spdx'            => 'Python-2.0',
	'name.alt.org.tldr.path.short' => 'python2',
	'name.alt.misc.fossology_old'  => 'Python_v2',
	'name.alt.org.wikidata'        => 'Q5975028',
	caption                        => 'Python License 2.0',
	'caption.alt.org.fedora'       => 'Python License',
	'caption.alt.org.osi'          => 'Python License',
	'caption.alt.org.tldr'         => 'Python License 2.0',
	'caption.alt.org.trove'        => 'Python License (CNRI Python License)',
	'caption.alt.org.trove.misc.short' => 'CNRI Python License',
	'summary.alt.org.osi'              => 'overall Python license',
	iri                => 'https://docs.python.org/3/license.html',
	'iri.alt.misc.old' => 'https://www.python.org/psf/license/',
	tags               => [
		'license:contains:license:cnri_python',
		'license:contains:license:psf_2',
		'type:combo',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection' =>
		'[*)]This LICENSE AGREEMENT is between '
		. 'the Python Software Foundation [(]["]PSF["][)], '
		. 'and the Individual or Organization [(]["]Licensee["][)] '
		. 'accessing and otherwise using [word][ word]{0,3} '
		. 'in source or binary form and its associated documentation'
		. '[.][  ]'
		. '[*)]Subject to the terms and conditions of this License Agreement, '
		. 'PSF hereby grants Licensee a nonexclusive, royalty-free, world-wide license '
		. 'to reproduce, analyze, test, perform and[/]or display publicly, '
		. 'prepare derivative works, distribute, and otherwise use Python[ word]? '
		. 'alone or in any derivative version, '
		. 'provided, however, '
		. 'that PSF[\']s License Agreement and PSF[\']s notice of copyright, '
		. '[ie], ["]Copyright [c] [word][ word]{0,5} Python Software Foundation[;] All Rights Reserved["] '
		. 'are retained in Python[ word]? alone or in any derivative version prepared by Licensee'
		. '[.][  ]'
		. '[*)]In the event Licensee prepares a derivative work '
		. 'that is based on or incorporates [word][ word]{0,3} or any part thereof, '
		. 'and wants to make the derivative work available to others as provided herein, '
		. 'then Licensee hereby agrees to include in any such work '
		. 'a brief summary of the changes made to Python[ word]?'
		. '[.][  ]'
		. '[*)]PSF is making Python[ word]? available to Licensee on an [as is] basis'
		. '[.][ ]'
		. 'PSF MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED'
		. '[.][ ]'
		. 'BY WAY OF EXAMPLE, BUT NOT LIMITATION, '
		. 'PSF MAKES NO AND DISCLAIMS ANY REPRESENTATION OR WARRANTY '
		. 'OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE '
		. 'OR THAT THE USE OF PYTHON[ word]? WILL NOT INFRINGE ANY THIRD PARTY RIGHTS'
		. '[.][  ]'
		. '[*)]PSF SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF PYTHON[ word]? '
		. 'FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS '
		. 'AS A RESULT OF MODIFYING, DISTRIBUTING, OR OTHERWISE USING '
		. 'PYTHON[ word]?, OR ANY DERIVATIVE THEREOF, '
		. 'EVEN IF ADVISED OF THE POSSIBILITY THEREOF'
		. '[.][  ]'
		. '[*)]This License Agreement will automatically terminate '
		. 'upon a material breach of its terms and conditions'
		. '[.][  ]'
		. '[*)]Nothing in this License Agreement shall be deemed to create '
		. 'any relationship of agency, partnership, or joint venture between PSF and Licensee'
		. '[.][ ]'
		. 'This License Agreement does not grant permission '
		. 'to use PSF trademarks or trade name in a trademark sense '
		. 'to endorse or promote products or services of Licensee, or any third party'
		. '[.][  ]'
		. '[*)]By copying, installing or otherwise using Python[ word]?, '
		. 'Licensee agrees to be bound by the terms and conditions of this License Agreement'
		. '[.][  ]'
		. 'BEOPEN\.COM LICENSE AGREEMENT FOR PYTHON 2\.0'
		. '([ ][-]+)?[  ]?'
		. 'BEOPEN PYTHON OPEN SOURCE LICENSE AGREEMENT VERSION 1' . '[  ]'
		. '[*)]This LICENSE AGREEMENT is between BeOpen\.com [(]["]BeOpen["][)], '
		. 'having an office at 160 Saratoga Avenue, Santa Clara, CA 95051, '
		. 'and the Individual or Organization [(]["]Licensee["][)] '
		. 'accessing and otherwise using '
		. 'this software in source or binary form and its associated documentation [(]["]the Software["][)]'
		. '[.][  ]'
		. '[*)]Subject to the terms and conditions of this BeOpen Python License Agreement, '
		. 'BeOpen hereby grants Licensee a non-exclusive, royalty-free, world-wide license '
		. 'to reproduce, analyze, test, perform and[/]or display publicly, '
		. 'prepare derivative works, distribute, and otherwise use the Software '
		. 'alone or in any derivative version, '
		. 'provided, however, that the BeOpen Python License is retained in the Software, '
		. 'alone or in any derivative version prepared by Licensee'
		. '[.][  ]'
		. '[*)]BeOpen is making the Software available to Licensee on an [as is] basis'
		. '[.][ ]'
		. 'BEOPEN MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED'
		. '[.][ ]'
		. 'BY WAY OF EXAMPLE, BUT NOT LIMITATION, '
		. 'BEOPEN MAKES NO AND DISCLAIMS ANY REPRESENTATION OR WARRANTY '
		. 'OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE '
		. 'OR THAT THE USE OF THE SOFTWARE WILL NOT INFRINGE ANY THIRD PARTY RIGHTS'
		. '[.][  ]'
		. '[*)]BEOPEN SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF THE SOFTWARE '
		. 'FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS '
		. 'AS A RESULT OF USING, MODIFYING OR DISTRIBUTING '
		. 'THE SOFTWARE, OR ANY DERIVATIVE THEREOF, '
		. 'EVEN IF ADVISED OF THE POSSIBILITY THEREOF'
		. '[.][  ]'
		. '[*)]This License Agreement will automatically terminate '
		. 'upon a material breach of its terms and conditions'
		. '[.][  ]'
		. '[*)]This License Agreement shall be governed by and interpreted in all respects '
		. 'by the law of the State of California, excluding conflict of law provisions'
		. '[.][ ]'
		. 'Nothing in this License Agreement shall be deemed to create '
		. 'any relationship of agency, partnership, or joint venture between BeOpen and Licensee'
		. '[.][ ]'
		. 'This License Agreement does not grant permission '
		. 'to use BeOpen trademarks or trade names in a trademark sense '
		. 'to endorse or promote products or services of Licensee, or any third party'
		. '[.][ ]'
		. 'As an exception, the ["]BeOpen Python["] logos '
		. 'available at [http://]www.pythonlabs\.com[/]logos\.html '
		. 'may be used according to the permissions granted on that web page'
		. '[.][  ]'
		. '[*)]By copying, installing or otherwise using the software, '
		. 'Licensee agrees to be bound by the terms and conditions of this License Agreement'
		. '[.][  ]'
		. 'CNRI OPEN SOURCE LICENSE AGREEMENT [(]for Python 1\.6b1[)]'
		. '([ ][-]+)?[  ]?'
		. 'IMPORTANT[:] PLEASE READ THE FOLLOWING AGREEMENT CAREFULLY'
		. '[.][  ]'
		. 'BY CLICKING ON ["]ACCEPT["] WHERE INDICATED BELOW, '
		. 'OR BY COPYING, INSTALLING OR OTHERWISE USING PYTHON 1\.6, beta 1 SOFTWARE, '
		. 'YOU ARE DEEMED TO HAVE AGREED TO THE TERMS AND CONDITIONS OF THIS LICENSE AGREEMENT'
		. '[.][  ]'
		. '[*)]This LICENSE AGREEMENT is between the Corporation for National Research Initiatives, '
		. 'having an office at 1895 Preston White Drive, Reston, VA 20191 [(]["]CNRI["][)], '
		. 'and the Individual or Organization [(]["]Licensee["][)] '
		. 'accessing and otherwise using Python 1\.6, beta 1 software '
		. 'in source or binary form and its associated documentation, '
		. 'as released at the www\.python\.org Internet site on August 4, 2000 [(]["]Python 1\.6b1["][)]'
		. '[.][  ]'
		. '[*)]Subject to the terms and conditions of this License Agreement, '
		. 'CNRI hereby grants Licensee a non-exclusive, royalty-free, world-wide license '
		. 'to reproduce, analyze, test, perform and[/]or display publicly, '
		. 'prepare derivative works, distribute, and otherwise use Python 1\.6b1 '
		. 'alone or in any derivative version, '
		. 'provided, however, that CNRIs License Agreement is retained in Python 1\.6b1, '
		. 'alone or in any derivative version prepared by Licensee'
		. '[.][  ]'
		. 'Alternately, in lieu of CNRIs License Agreement, '
		. 'Licensee may substitute the following text [(]omitting the quotes[)][:] '
		. '["]Python 1\.6, beta 1, is made available '
		. 'subject to the terms and conditions in CNRIs License Agreement'
		. '[.][ ]'
		. 'This Agreement may be located on the Internet '
		. 'using the following unique, persistent identifier [(]known as a handle[)][:] 1895\.22[/]1011'
		. '[.][ ]'
		. 'This Agreement may also be obtained from a proxy server on the Internet '
		. 'using the URL[:][http://]hdl\.handle\.net[/]1895\.22[/]1011["]'
		. '[.][  ]'
		. '[*)]In the event Licensee prepares a derivative work '
		. 'that is based on or incorporates Python 1\.6b1 or any part thereof, '
		. 'and wants to make the derivative work available to the public as provided herein, '
		. 'then Licensee hereby agrees to indicate in any such work '
		. 'the nature of the modifications made to Python 1\.6b1'
		. '[.][  ]'
		. '[*)]CNRI is making Python 1.6b1 available to Licensee on an [as is] basis',
};

=back

=head2 License groups

Patterns each covering either of multiple licenses.

Each of these patterns has the tag B< type:group >.

=over

=item * bsd

=cut

$RE{bsd} = {
	name                                            => 'BSD',
	'name.alt.org.debian'                           => 'BSD~unspecified',
	'name.alt.org.fedora.iri.self'                  => 'BSD',
	'name.alt.org.osi.iri.stem.until.date_20110430' => 'bsd-license',
	'name.alt.org.wikidata.synth.nogrant'           => 'Q191307',
	'name.alt.misc.style'                           => 'BSD-style',
	caption                                         => 'BSD license',
	'caption.alt.org.debian'                        => 'BSD (unspecified)',
	'caption.alt.org.trove'                         => 'BSD License',
	'caption.alt.org.wikidata'                      => 'BSD licenses',
	'caption.alt.org.wikipedia'                     => 'BSD licenses',
	'caption.alt.misc.long' => 'Berkeley Software Distribution License',
	summary                 => 'a BSD-style license',
	tags                    => [
		'type:group',
	],

	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '(?:[.][  ](?:[*)]?'
		. $P{ad_mat_ack_this}
		. '[word][ word]{0,14}'
		. '[.][  ])?[*)]?'
		. $P{nopromo_neither} . ')?',
};

=item * cc

I<Since v3.6.0.>

=cut

$RE{cc} = {
	name                                  => 'CC',
	'name.alt.org.debian'                 => 'CC~unspecified',
	'name.alt.org.wikidata.synth.nogrant' => 'Q284742',
	caption                               => 'Creative Commons license',
	'caption.alt.org.wikidata'            => 'Creative Commons license',
	'caption.alt.org.wikipedia'           => 'Creative Commons license',
	'caption.alt.misc.short'              => 'CC license',
	'summary.alt.misc.short'              => 'a CC license',
	tags                                  => [
		'group',
		'type:group',
	],
};

=item * gnu

=cut

$RE{gnu} = {
	name                  => 'AGPL/GPL/LGPL',
	'name.alt.org.debian' => 'GNU~unspecified',
	caption               => 'GNU license',
	summary               => 'a GNU license (AGPL or GPL or LGPL)',
	tags                  => [
		'type:group',
	],

	'_pat.alt.subject.name' => [
		$RE{agpl}{'_pat.alt.subject.name'},
		$RE{gpl}{'_pat.alt.subject.name'},
		$RE{lgpl}{'_pat.alt.subject.name'},
	],
};

=item * mit

=cut

$RE{mit} = {
	name                                  => 'MIT',
	'name.alt.org.debian'                 => 'MIT~unspecified',
	'name.alt.org.fedora.iri.self'        => 'MIT',
	'name.alt.org.wikidata.synth.nogrant' => 'Q334661',
	'name.alt.misc.style'                 => 'MIT-style',
	caption                               => 'MIT license',
	'caption.alt.org.trove'               => 'MIT License',
	'caption.alt.org.wikidata'            => 'MIT license',
	'caption.alt.org.wikipedia'           => 'MIT License',
	'iri.alt.org.wikipedia' => 'https://en.wikipedia.org/wiki/MIT_License',
	summary                 => 'an MIT-style license',
	tags                    => [
		'type:group',
	],

	'pat.alt.subject.name'                   => "${the}MIT\\b",
	'pat.alt.subject.license.scope.sentence' => $P{retain_copr_perm_subst},
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

my @gnu_langs
	= qw(en ar ca de el es fr it ja nl pl pt_BR ru sq sr zh_CN zh_TW);

# must be simple word (no underscore), to survive getting joined in cache
# more ideal first: first available is default
my @_SUBJECTSTACK = qw(license grant name iri trait);

my @_OBJECTS;
my %_PUBLISHER;
my %_TYPE;
my %_SERIES;
my %_USAGE;

for (
	qw(license_label_spdx license_label_trove license_label licensed_under version_number_suffix version_only version_later)
	)
{
	$_ANNOTATIONS{"(:$_:)"} = $RE{$_}{'pat.alt.subject.trait'};
	$_ANNOTATIONS{"(:$_:)"} =~ s/\[.+?\]/
		exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;
}
$_ANNOTATIONS{"(:version_prefix:)"}
	= $RE{version_prefix}{'pat.alt.subject.trait.scope.line.scope.sentence'};
$_ANNOTATIONS{"(:version_prefix:)"} =~ s/\[.+?\]/
	exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;

my $tag_license_re    = qr/^license:published:\K$_prop(?::|\z)/;
my $tag_type_re       = qr/^type:($_prop)(?::($_prop)(?::($_prop))?)?/;
my $tag_type_usage_re = qr/^type:usage:\K$_prop/;

my $prop_web_re
	= qr/^(name|caption|summary)\.(alt\.org\.($_prop)((?:\.iri\.($_prop))?$_any*?))(?:\.synth\.nogrant|)$/;

my $pat_subject_re = qr/^_?pat\.alt\.subject\.\K$_prop(?=\.)/;

my $gen_args_capture = {
	summary => 'include capturing parantheses, named or numbered',
	schema  => [ 'str*', in => [qw(named numbered no)] ],
	default => 'no',
	req     => 1,
};

my $gen_args_engine = {
	summary =>
		'Enable custom regexp engine (perl module re::engine::* or pseudo or none)',
	schema => ['str*'],
};

# process metadata tags
@_ = ();
for my $id ( grep {/^[a-z]/} keys %RE ) {
	for ( @{ $RE{$id}{tags} } ) {

		# resolve publisher
		if (/$tag_license_re/) {
			$_PUBLISHER{$id} = $&;
		}

		# resolve series
		/$tag_type_re/
			or next;
		$_TYPE{$id} = $1;
		if ( $2 and $1 eq 'singleversion' ) {
			push @_OBJECTS,          $id;
			push @{ $_SERIES{$id} }, $2;
		}
		else {
			push @_, $id;
		}

		# resolve usage
		if ( $2 and $RE{$2} and $1 eq 'usage' ) {
			$RE{$id}{licenseversion} = $RE{$2}{licenseversion}
				or die "missing version for $id (needed by $1)";
			$_USAGE{$id}{series} //= $2;
			if ( $_USAGE{$id}{series} ne $2 ) {
				die 'multi-origin usage for $id';
			}
			$_USAGE{$id}{type} = $3;
			die "unsupported usage for $id ($_)"
				unless ( grep { $3 eq $_ }
				qw( only or_later rfn no_rfn no_copyleft_exception ) );
		}
	}
}

# ensure versioned objects are processed after single-version objects
push @_OBJECTS, @_;

for my $id (@_OBJECTS) {

	# resolve publisher
	for ( @{ $RE{$id}{tags} } ) {
		if (/$tag_type_usage_re/) {
			if ( exists $_PUBLISHER{$&} ) {
				$_PUBLISHER{$id} = $_PUBLISHER{$&};
				$_ANNOTATIONS{"(:$_PUBLISHER{$&}:)"}
					= $RE{ $_PUBLISHER{$&} }{'pat.alt.subject.trait'};
				$_ANNOTATIONS{"(:$_PUBLISHER{$&}:)"} =~ s/\[.+?\]/
					exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;
			}
		}
	}

	# synthesize metadata: iri from name or caption
	for ( keys %{ $RE{$id} } ) {
		my ( $prop, $slug, $org, $trail, $web ) = (/$prop_web_re/)
			or next;
		next unless $org;
		next
			if $prop eq 'caption'
			and ( exists $RE{$id}{"name.$slug"}
			or exists $RE{$id}{"name.$slug.synth.nogrant"} );

		my ( $base, @variants );
		$_ = $RE{$id}{$_};
		if ( $org eq 'fedora' ) {
			next unless $web;
			$base = 'https://fedoraproject.org/wiki/Licensing/';
			if ( $web eq 'bsd' ) {
				$base .= 'BSD#';
			}
			elsif ( substr( $web, 0, 4 ) eq 'cddl' ) {
				$base .= 'CDDL#';
			}
			elsif ( substr( $web, 0, 3 ) eq 'mit' ) {
				$base .= 'MIT#';
			}
			s/^(?:BSD|MIT)-style license, //go;
			tr/ /_/;
			s/\(/.28/go;
			s/\)/.29/go;
		}
		elsif ( $slug and $slug eq 'alt.org.tldr.path.short' ) {
			$base = 'https://tldrlegal.com/l/';
			$_    = lc $_;
			tr/ /-/;
		}
		elsif ( $slug and $slug eq 'alt.org.tldr' ) {
			$base = 'https://tldrlegal.com/license/';
			$_    = lc $_;
			tr/ /-/;
		}
		elsif ( $org eq 'wikipedia' ) {
			$base = 'https://en.wikipedia.org/wiki/';
			tr/ /_/;
			s/"/%22/go;    #"
		}
		elsif ( $prop eq 'caption' ) {
			next;
		}
		elsif ( $org eq 'fsf' ) {
			$base = 'https://directory.fsf.org/wiki?title=License:';
		}
		elsif ( $org eq 'gnu' ) {
			push @variants, [
				"iri.$slug",
				'https://www.gnu.org/licenses/license-list.html#',
				$_,
				'',
			];
			for my $lang (@gnu_langs) {
				( my $weblang = lc $lang ) =~ tr/_/-/;
				push @variants, [
					"iri.$slug.lang.$lang",
					"https://www.gnu.org/licenses/license-list.$weblang.html#",
					$_,
					'',
				];
			}
		}
		elsif ( $org eq 'osi' ) {
			next unless $prop eq 'name';
			$base = 'https://opensource.org/licenses/';
			if ( $web and substr( $web, 0, 4 ) eq 'stem' ) {
				for my $ext (qw(html php)) {
					push @variants, [
						"iri.$slug.format.$ext",
						'https://opensource.org/licenses/',
						$_,
						".$ext",
					];
				}
				if ( $web eq 'stem_only' ) {
					$base = undef;
				}
			}
			elsif ( $web and $web eq 'stem_plain' ) {
				for my $ext (qw(txt html php)) {
					push @variants, [
						"iri.$slug.format.$ext",
						'https://opensource.org/licenses/',
						$_,
						".$ext",
					];
				}
			}
		}
		elsif ( $org eq 'spdx' ) {
			push @variants, [
				"iri.$slug",
				'https://spdx.org/licenses/',
				$_,
				'',
			];
			for my $ext (qw(txt html json)) {
				push @variants, [
					"iri.$slug.format.$ext",
					'https://spdx.org/licenses/',
					$_,
					".$ext",
				];
			}
		}
		elsif ( $org eq 'wikidata' ) {
			push @variants, [
				"iri.$slug",
				'https://www.wikidata.org/wiki/Special:EntityPage/',
				$_,
				'',
			];
			push @variants, [
				"iri.$slug.path.wiki",
				'https://www.wikidata.org/wiki/',
				$_,
				''
			];
		}
		$RE{$id}{"iri.$slug"} //= "$base$_"
			if defined $base;
		for (@variants) {
			$RE{$id}{ $$_[0] } //= $$_[1] . $$_[2] . $$_[3];
		}
	}

	# synthesize patterns: iri from metadata iri
	unless ( $RE{$id}{'pat.alt.subject.iri'} ) {
		my @subpat;
		for ( sort grep {/^iri(?:[.(]|\z)/} keys %{ $RE{$id} } ) {
			my $val = $RE{$id}{$_};

			$val =~ s/\./\\./g;
			$val =~ s/[+()]/[$&]/g;
			$val =~ s/-/[-]/g;
			$val =~ s!^https?://![http://]!;
			$val =~ s!/$!/?!;
			push @subpat, $val;
		}
		_join_pats( { assign => [ $id, 'pat.alt.subject.iri' ] }, @subpat );
	}

	# synthesize patterns: name and caption from metadata name and caption
	unless ( $_TYPE{$id} eq 'trait' ) {
		my (%singleword_pat, %multiword_pat, %name_pat, %spdx_pat,
			%trove_pat
		);

		my $published_by = '';
		$published_by = '(?: (:' . $_PUBLISHER{$id} . ':)(?: ?[;]?|[\']s))?'
			if $_PUBLISHER{$id}
			and $RE{ $_PUBLISHER{$id} }
			and $RE{ $_PUBLISHER{$id} }{'pat.alt.subject.trait'};

		my ( $is_only_this_version, $is_also_later_versions );
		my @candidates = ($id);
		if ( $_USAGE{$id} ) {
			$is_only_this_version   = ( $_USAGE{$id}{type} eq 'only' );
			$is_also_later_versions = ( $_USAGE{$id}{type} eq 'or_later' );
			push @candidates,
				$_USAGE{$id}{series},
				@{ $_SERIES{ $_USAGE{$id}{series} } };
		}
		elsif ( $_SERIES{$id} ) {
			push @candidates, @{ $_SERIES{$id} };
		}

		my $version             = '';
		my $version_usage       = '';
		my $version_usage_maybe = '';
		my ( $ver, $ver_re, $ver_z_re );
		if ( $_ = $RE{$id}{licenseversion} ) {
			s/\./\\./g;
			s/\\\.0\\\.0$/(?:\\.0(?:\\.0)?)?/;
			s/\\\.0$/(?:\\.0)?/;
			s/\\\.\K0{0,2}0/0{1,3}/g;
			s/\\\.\K0{0,2}(?=[1-9])/0{0,2}/g;
			$version = '(:version_prefix:)' . $_;
			if ($is_only_this_version) {
				$version_usage = '(:version_only:)';
			}
			elsif ($is_also_later_versions) {
				$version_usage = '(:version_later:)';
			}
			$version_usage_maybe = $version_usage . '?'
				if $version_usage;
			$ver = '_?' . $version . $version_usage_maybe;
			$ver =~ s/(?:\[|\(:)[^\]]+?(?:\]|:\))/
				exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;
			$ver_re   = qr/$ver/;
			$ver_z_re = qr/$ver$/;
		}

		my $version_stopgap = '(?:[^+.A-Za-z0-9]|\.[^0-9]|\.\z|\z)';

		foreach my $candidate (@candidates) {
			for ( keys %{ $RE{$candidate} } ) {
				next unless /^name(?:\.|\z)/;
				next if /\.synth\.nogrant(?:\.|\z)/;

				my $val = $RE{$candidate}{$_};

				next if $val =~ /-\(/;

				$val =~ s/$ver_re// if $version;

				# mangle and annotate metadata names
				$val =~ s/\./\\./g;
				$val =~ s/[+]/[$&]/g;

				$singleword_pat{$val} = undef;
			}
		}
		my $shortname = _join_pats(
			{   prefix => "(?: ?[(](?:$the)?" . '["]?',
				suffix => "(?:$version)?" . '(?: [Ll]icen[cs]e)?["]?[)])?'
			},
			sort keys %singleword_pat
		);
		my $shortname_z_re = $shortname;
		$shortname_z_re =~ s/(?:\[|\(:)[^\]]+?(?:\]|:\))/
			exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;
		$shortname_z_re = qr/$shortname_z_re$/;

		my $suffix = $shortname . $published_by;

		for ( keys %{ $RE{$id} } ) {

			if (/^caption\.alt\.org\.trove(?:\.|\z)/) {
				my $trove_val = $RE{$id}{$_};

				# mangle and annotate trove metadata
				$trove_val =~ s/\./\\./g;
				$trove_val =~ s/[-+()]/[$&]/g;

				$trove_val .= $version_stopgap;

				$trove_pat{$trove_val} = undef;
			}

			if (/^name(?:\.|\z)/) {
				next if /\.synth\.nogrant(?:\.|\z)/;

				my $name_val = $RE{$id}{$_};

				$name_pat{$name_val} = undef
					if /^caption\.alt\.org\.spdx(?:\.|\z)/;

				next if $name_val =~ /-\(/;
				$name_val         =~ s/[~.,]/\\$&/g;
				$name_val         =~ s/[-+()\/]/[$&]/g;
				if ( $name_val =~ /\d$/ ) {
					$name_val =~ s/\\\.0$/\(?:\\.0\)?/;
				}

				$name_val .= $version_stopgap;

				$name_pat{$name_val} = undef;
			}

			next unless /^caption(?:\.|\z)/;
			next if /\.synth\.nogrant(?:\.|\z)/;

			my $val = $RE{$id}{$_};

			# strip words later re-added as surrounding pattern
			$val =~ s/$shortname_z_re//;
			if ($version) {
				$val =~ s/$ver_z_re//;
				$val =~ s/$shortname_z_re//;
			}
			$val =~ s/^$the//;
			$val =~ s/ [Ll]icen[cs]e$//;

			# mangle and annotate metadata
			$val =~ tr/–/-/;
			$val =~ s/\./\\./g;
			$val =~ s/[-+()'é]/[$&]/g;    #'
			$val =~ s/,/,?/g;
			$val =~ s/ ?®/[r]/g;
			$val =~ s/， /[, ]/g;         # wide comma
			$val =~ s/ \[-\] /[ - ]/g;
			$val =~ s{ / }{[ / ]}g;

			# generalize commonly varying words
			$val =~ s/^(?:[Aa]n? )/(?:[Aa]n? )?/;            # relax (not add)
			$val =~ s/ [Ll]icen[cs]e/(?: [Ll]icen[cs]e)?/;

			$multiword_pat{$val} = undef;
		}

		my $stem = _join_pats(
			{ prefix => "$the?", suffix => '(?: [Ll]icen[cs]e)?' },
			sort keys %multiword_pat,
			_join_pats(
				{ prefix => '\b', suffix => $version ? '' : '\b' },

				# TODO: use { s/-/[-]/gr } when needing perl 5.14 anyway
				map      { my $s = $_; $s =~ s/-/[-]/g; $s; }
					grep { not exists $multiword_pat{$_} }
					sort keys %singleword_pat,
			),
		);

		unless ( exists $RE{$id}{'_pat.alt.subject.name.synth.caption'} ) {

			if ($version) {

				# extra pattern with (non-optional) leading version
				push @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} },
					'(?:'
					. '(:version_prefix:)'
					. "$version$version_usage"
					. " of $stem"
					. $published_by . ')';

				$suffix
					= '(?:'
					. $version
					. $version_usage_maybe
					. '(:version_number_suffix:)' . ')?'
					. $shortname
					. $published_by
					. $version
					. '(:version_number_suffix:)'
					. $version_usage
					. $shortname
					. $version_stopgap;
			}
			push @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} },
				$stem . $suffix;
		}

		# TODO: maybe include also subject pattern iri
		unless ( exists $RE{$id}{'_pat.alt.subject.grant.synth.name'} ) {
			if ( $RE{$id}{'_pat.alt.subject.name.synth.caption'} ) {
				$name_pat{$_} = undef
					for @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} };
			}
			_join_pats(
				{   assign => [ $id, '_pat.alt.subject.grant.synth.name' ],
					prefix => '(:license_label:) ?'
				},
				sort keys %name_pat
			);
		}

		# synthesize subject pattern grant from SPDX name
		unless ( $RE{$id}{'_pat.alt.subject.grant.synth.spdx'} ) {
			_join_pats(
				{   assign => [ $id, '_pat.alt.subject.grant.synth.spdx' ],
					prefix => '(:license_label_spdx:) ?'
				},
				sort keys %spdx_pat
			);
		}

		# synthesize subject pattern grant from Trove caption
		unless ( $RE{$id}{'_pat.alt.subject.grant.synth.trove'} ) {
			_join_pats(
				{   assign => [ $id, '_pat.alt.subject.grant.synth.trove' ],
					prefix => '(:license_label_trove:) ?'
				},
				sort keys %trove_pat
			);
		}

		# synthesize subject pattern grant from subject pattern name
		unless ( $RE{$id}{'_pat.alt.subject.grant.synth.caption'} ) {

			# TODO: use resolved patterns (not subpatterns)
			_join_pats(
				{   assign => [ $id, '_pat.alt.subject.grant.synth.caption' ],
					prefix => '(:licensed_under:)'
				},
				@{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} }
			);
		}

		# synthesize CC subject pattern license from metadata caption
		if ( $id eq 'cc_cc0_1' ) {
			$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
				//= "(?:$RE{$id}{caption})?" . "[  ]$cc_intro_cc0";
		}
		elsif ( $id =~ /^cc.*_1$/ ) {
			$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
				//= $RE{$id}{caption} . "[  ]$cc_intro_1";
		}
		elsif ( $id =~ /^cc.*_(?:2|2_5)$/ ) {
			$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
				//= $RE{$id}{caption} . "[  ]$cc_intro";
		}
		elsif ( $id =~ /^cc.*_3$/ ) {
			$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
				//= $RE{$id}{caption} . ' Unported' . "[  ]$cc_intro";
		}
		elsif ( $id =~ /^cc.*_4$/ ) {
			$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
				//= $RE{$id}{caption}
				. '(?: Public License)?[  ]'
				. $cc_by_exercising_you_accept_this
				. $RE{$id}{caption};
		}
	}

	# resolve subject patterns from subpatterns
	my %subject_pat;
	for ( keys %{ $RE{$id} } ) {

		# collect alternatives ahead (to traverse once, not once per subject)
		if (/$pat_subject_re/) {
			my $unseed = substr $_, 1;  # seed -> nonseed, or nonseed -> bogus
			$subject_pat{$&}{ exists $RE{$id}{$unseed} ? $unseed : $_ }
				= undef;
		}
	}
	for my $subject (@_SUBJECTSTACK) {

		# if not explicitly defined, synthesize from seed or all alt seeds
		$RE{$id}{"pat.alt.subject.$subject"}
			//= _join_pats( $RE{$id}{"_pat.alt.subject.$subject"} )
			|| _join_pats(
			map { $RE{$id}{$_} }
			sort keys %{ $subject_pat{$subject} }
			) or delete $RE{$id}{"pat.alt.subject.$subject"};
	}

	# resolve available patterns
	my @pat_subject
		= grep { exists $RE{$id}{"pat.alt.subject.$_"} } @_SUBJECTSTACK;

	my $can_capture;
	my $pat = _join_pats(
		map { $RE{$id}{"pat.alt.subject.$_"} } @pat_subject,
	);
	if ( $pat =~ /\(\?P<_/ ) {
		$can_capture = 1;
		push @{ $RE{$id}{tags} }, 'capturing';
	}

	# provide default dynamic pattern: all available patterns
	$RE{$id}{gen} = sub {
		my %args = @_;

		$pat = _join_pats(
			map { $RE{$id}{"pat.alt.subject.$_"} }
				split( /,/, $args{subject} )
		) if $args{subject};

		return ''
			unless ($pat);

		my $capture = $args{capture} || 'no';

		if ($can_capture) {
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
		}

		if ( defined $args{engine} and $args{engine} eq 'pseudo' ) {
		}
		else {
			$pat =~ s/(?:\[|\(:)[^\]]+?(?:\]|:\))/
				exists $_ANNOTATIONS{$&} ? $_ANNOTATIONS{$&} : $&/ego;
		}

		# TODO: document if not obsoleted
		# by <https://github.com/perlancar/perl-Regexp-Pattern/issues/4>
		if ( $args{anchorleft} ) {
			$pat = "^(?:$pat)";
		}

		if ( $args{engine} ) {

			# TODO: support modern Perl with greedy patterns

			if ( $args{engine} eq 'RE2' ) {
				unless ($CAN_RE2) {
					die
						'cannot use regexp engine "RE2": Module "re::engine::RE2" is not installed';
				}

				BEGIN {
					re::engine::RE2->import(
						-strict  => 1,
						-max_mem => 8 << 21,
					);
				}
				return qr/$pat/;
			}
			elsif ( $args{engine} eq 'none' or $args{engine} eq 'pseudo' ) {
				return $pat;
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
	$RE{$id}{gen_args}{capture} = $gen_args_capture
		if $can_capture;

	# option subject: which subject(s) to cover in pattern
	$RE{$id}{gen_args}{subject} = {
		summary => 'Choose subject (or several, comma-separated)',
		schema  => [ 'str*', in => \@pat_subject ],
		default => join( ',', @pat_subject ),
		req     => 1,
	};

	# option engine: which regular expression engine to compile pattern with
	$RE{$id}{gen_args}{engine} = $gen_args_engine;
}

sub _join_pats
{
	my ( @pats, %opts );

	# collect hashref options, skip empty patterns, and expand arrayrefs
	for (@_) {
		next unless defined;
		if    ( !ref )           { push @pats, $_ if length }
		elsif ( ref eq 'ARRAY' ) { push @pats, _join_pats(@$_) || () }
		elsif ( ref eq 'HASH' )  { @opts{ keys %$_ } = values %$_ }
		else                     { die "Bad ref: $_"; }
	}

	my $label
		= $opts{label}
		? 'P<' . $opts{label} . '>'
		: ':';
	my $prefix = $opts{prefix} // '';
	my $suffix = $opts{suffix} // '';

	return $opts{assign} ? 0 : ''
		unless @pats;
	my $result
		= ( @pats > 1 or $label ne ':' )
		? "$prefix(?$label" . join( '|', @pats ) . ")$suffix"
		: $prefix . $pats[0] . $suffix;
	if ( $opts{assign} ) {
		$RE{ $opts{assign}[0] }{ $opts{assign}[1] } = $result;
		return scalar @pats;
	}
	return $result;
}

=head2 OBSOLETE OBJECTS

License objects obsoleted by improved coverage of other objects,
and provided only as dummy objects.

=over

=item * python

I<Since v3.9.0.>

Replaced by L</psf_2> and L</python_2>.

=cut

$RE{python} = {
	pat => qr/^this should never match (except itself) rrompraghtiestur$/,
};

=item * wordnet_3

I<Since v3.9.0.>

Replaced by L</wordnet>.

=cut

$RE{wordnet_3} = {

	pat => qr/^this should never match (except itself) rrompraghtiestur$/,
};

=back

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

=item * license:contains:grant:*

License mentions a preferred form for granting the license.

This implies that license is commonly granted by use of a different (typically far shorter) text.

Fourth part (optional) is the key to corresponding license pattern,
for a grant belonging to a different license
(when omitted then a grant for same license is assumed).

=item * license:contains:license:*

License contains another license.

Wildcard is the key to corresponding license pattern.

=item * license:contains:name:*

License mentions name of another license.

=item * license:includes:license:*

License references coverage of another license.

Wildcard is the key to corresponding license pattern.

=item * license:is:grant

License is commonly granted by stating the whole license.

=item * license:published:*

License grant may include an "as published by..." reference.

Third part is the key to corresponding trait pattern.

=item * type:trait:publisher:*

Pattern covers an "as published by ..." license grant phrase.

Third part (optional) is the key to corresponding license pattern.

=item * type:usage:*:*

Pattern covers a specific usage of a license.

Third part is the key of the corresponding non-usage-specific pattern.

Fourth part is the key of the corresponding usage trait pattern.

=item * type:combo

Pattern covers a combination of multiple licenses.

=item * type:group

Pattern covers either of multiple licenses.

=item * type:singleversion:*

Pattern covers a specific version of a license.

Third part is the key of the corresponding non-version-specific pattern.

=item * type:trait

Pattern covers a single trait occuring in licenses.

=item * type:unversioned

Pattern covers a license without versioning scheme.

=item * type:versioned:decimal

Pattern covers a license using decimal number versioning scheme.

=back

=head1 EXAMPLES

=head2 Browse patterns

The "official" way to browse patterns is using L<App::RegexpPatternUtils>:

    show-regexp-pattern-module --page-result -- License

Unfortunately, L<App::RegexpPatternUtils> has a deep dependency tree.
An alternative is to use L<Data::Printer> and C<less>:

    perl -CS -MRegexp::Pattern::License -MDDP -e 'p %Regexp::Pattern::License::RE, fulldump => 1, output => stdout' | less -RS

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

  Copyright © 2016-2021 Jonas Smedegaard

  Copyright © 2017-2021 Purism SPC

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
