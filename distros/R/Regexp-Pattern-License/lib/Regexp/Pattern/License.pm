package Regexp::Pattern::License;

use utf8;
use strict;
use warnings;

use Regexp::Pattern::License::Parts;
use List::Util 1.45 qw(uniq);

=head1 NAME

Regexp::Pattern::License - Regular expressions for legal licenses

=head1 VERSION

Version v3.5.1

=cut

our $VERSION = version->declare("v3.5.1");

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
# [, ]          comma and space (space optional for wide comma)
# [:"]          colon and maybe one or two quotes
# [;]           semicolon or colon or comma
# [']           apostrophe
# ["]           quote
# ["*]          quote or bullet
# [*]           bullet
# [*)]          start-of-sentence bullet or count
# [/]           slash or space or none
# [-]           dash
# [-#]          dash or number
# [- ]          dash or space
# [ - ]         dash with space around
# [(]           parens-open
# [)]           parens-close
# [<]           less-than
# [>]           greater-than
# [#.]          digits and maybe one infix dot
# [#-,]         digits, infix maybe one dash, suffix maybe comma maybe space
# [c]           copyright mark
# [eg]          exempli gratia, abbreviated
# [http://]     http or https protocol
# [ie]          id est, abbreviated
# [word]        word
# [ word]       space and word

my @_re = (
	[ qr/\Q[, ]/,  '(?:, |[、，] ?)' ],
	[ qr/\Q[*)]/,  '(?:\W{0,5}\S{0,2}\W{0,3})' ],
	[ qr/\Q[:"]/,  '(?::\W{0,2})' ],                    #"
	[ qr/\Q[-]/,   '[-–]' ],
	[ qr/\Q[-#]/,  '[-–\d]' ],
	[ qr/\Q[- ]/,  '[-– ]' ],
	[ qr/\Q[ - ]/, '(?: [-–—]{1,2} )' ],
	[ qr/\Q[(]/,   '[(（]' ],
	[ qr/\Q[)]/,   '[)）]' ],
	[ qr/\Q[#.]/,  '(?:\d+(?:\.\d+)?)' ],
	[ qr/\Q[#-,]/, '(?:\d+(?: ?[-–] ?\d+)?,? ?)' ],
	[ qr/\Q[ ]/,   '(?:\s{1,3})' ],
	[ qr/\Q[  ]/,  '(?:\s{1,3})' ],
	[ qr/\Q["]/, "(?:[\"«»˝̏“”„]|['<>`´‘’‹›‚]{0,2})" ],
	[ qr/\Q[']/, "(?:['`´‘’]?)" ],
	[ qr/\Q["*]/, '(?:\W{0,2})' ],                      #"
	[ qr/\Q[;]/,  '[;:,、，]' ],
	[ qr/\Q[\/]/, '(?:[ /]?)' ],

	[ qr/\[à\]/, '(?:[àa]?)' ],
	[ qr/\[é\]/, '(?:[ée]?)' ],
	[ qr/\[è\]/, '(?:[èe]?)' ],
	[ qr/\[ł\]/, '(?:[łl]?)' ],

	[ qr/\Q[c]/,       '(?:©|\([Cc]\))' ],
	[ qr/\Q[eg]/,      '(?:ex?\.? ?gr?\.?)' ],
	[ qr!\Q[http://]!, '(?:(?:https?:?)?(?://)?)' ],
	[ qr/\Q[ie]/,      '(?:i\.? ?e\.?)' ],
	[ qr/\Q[word]/,    '(?:\S+)' ],
	[ qr/\Q[ word]/,   '(?: \S+)' ],
);

my %P;
while ( my ( $key, $val ) = each %Regexp::Pattern::License::Parts::RE ) {
	$P{$key} = $val->{pat};
}

my $the = '(?:[Tt]he )';

my $cc_no_law_firm
	= 'CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE LEGAL SERVICES[.] ';
my $cc_dist_no_rel
	= 'DISTRIBUTION OF THIS LICENSE DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[.] ';
my $cc_dist_no_rel_draft
	= 'DISTRIBUTION OF THIS DRAFT LICENSE DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[.] ';
my $cc_dist_no_rel_doc
	= 'DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN ATTORNEY[-]CLIENT RELATIONSHIP[.] ';
my $cc_info_asis_discl
	= 'CREATIVE COMMONS PROVIDES THIS INFORMATION ON AN ["]?AS[-]IS["]? BASIS[.] '
	. 'CREATIVE COMMONS MAKES NO WARRANTIES REGARDING THE INFORMATION PROVIDED, '
	. 'AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM ITS USE[.]';
my $cc_info_asis_discl_doc
	= 'CREATIVE COMMONS PROVIDES THIS INFORMATION ON AN ["]?AS[-]IS["]? BASIS[.] '
	. 'CREATIVE COMMONS MAKES NO WARRANTIES REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED HEREUNDER, '
	. 'AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED HEREUNDER[.]';
my $cc_work_protected
	= 'THE WORK \(?AS DEFINED BELOW\)? IS PROVIDED UNDER THE TERMS OF THIS CREATIVE COMMONS PUBLIC LICENSE \(?["]?CCPL["]? OR ["]?LICENSE["]?\)?[.] '
	. 'THE WORK IS PROTECTED BY COPYRIGHT AND[/]OR OTHER APPLICABLE LAW[.] ';
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
	= '(?:By exercising the Licensed Rights \(?defined below\)?, You accept and agree to be bound by the terms and conditions of this '
	. '|BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGREE TO BE BOUND BY THE TERMS OF THIS )';
my $clisp_they_only_ref_clisp
	= "They only reference external symbols in CLISP[']s public packages "
	. 'that define API also provided by many other Common Lisp implementations '
	. '\(namely the packages '
	. 'COMMON[-]LISP, COMMON[-]LISP[-]USER, KEYWORD, CLOS, GRAY, EXT\) ';
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
# _lang is "basic variants" regex at <https://stackoverflow.com/a/48300605>
# TODO: maybe tighten _lang to subset of _prop
# as discussed at <https://github.com/perlancar/perl-DefHash/issues/1>
my $_delim = '[.(]';
my $_prop  = '(?:[a-z][a-z0-9_]*)';
my $_lang
	= '(?:\([A-Za-z]{2,4}([_-][A-Za-z]{4})?([_-]([A-Za-z]{2}|[0-9]{3}))?\))';
my $_notlang = '[a-z0-9_.]';
my $_any     = '[a-z0-9_.()]';

our %RE;

=head1 PATTERNS

=head2 Licensing traits

Patterns each covering a single trait occuring in licenses.

Each of these patterns has the tag B< type:trait >.

=over

=item * addr_fsf

=item * addr_fsf_franklin

=item * addr_fsf_franklin_steet

=item * addr_fsf_mass

=item * addr_fsf_temple

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

$RE{addr_fsf}{'pat.alt.subject.trait'}
	= '(?P<_addr_fsf>'
	. $RE{addr_fsf_franklin}{'pat.alt.subject.trait'} . '|'
	. $RE{addr_fsf_temple}{'pat.alt.subject.trait'} . '|'
	. $RE{addr_fsf_mass}{'pat.alt.subject.trait'} . ')';

=item * any_of

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

=item * by_apache

=item * by_fsf

=item * by_james_clark

=item * by_psf

=item * by_sam_hocevar

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
		. '(?: \('
		. $P{fsf_url}
		. '\))?(?:,? Inc\.?)?'
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
	name                  => '389-exception',
	'name.alt.org.debian' => '389',
	caption               => '389 Directory Server Exception',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'Red Hat, Inc\. gives You the additional right '
		. 'to link the code of this Program '
		. 'with code not covered under the GNU General Public License '
		. '\(["]Non-GPL Code["]\) '
		. 'and to distribute linked combinations including the two, '
		. 'subject to the limitations in this paragraph[.] '
		. 'Non[-]GPL Code permitted under this exception '
		. 'must only link to the code of this Program '
		. 'through those well defined interfaces identified '
		. 'in the file named EXCEPTION found in the source code files '
		. '\(the ["]Approved Interfaces["]\)[.]',
};

=item * except_autoconf_data

=item * except_autoconf_2

=item * except_autoconf_2_archive

=item * except_autoconf_2_autotroll

=item * except_autoconf_2_g10

=item * except_autoconf_3

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
	name                  => 'Autoconf-exception-2.0',
	'name.alt.org.debian' => 'Autoconf-2.0',
	caption               => 'Autoconf exception 2.0',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.1' =>
		'the Free Software Foundation gives unlimited permission '
		. 'to copy, distribute and modify configure scripts ',
	'pat.alt.subject.trait.part.2' =>
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

	'pat.alt.subject.trait.scope.sentence.part.1' =>
		"the respective Autoconf Macro[']s copyright owner "
		. 'gives unlimited permission ',
	'pat.alt.subject.trait.part.2' =>
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

	'pat.alt.subject.trait.scope.sentence.part.1' =>
		'the copyright holders of AutoTroll '
		. 'give you unlimited permission ',
	'pat.alt.subject.trait.part.2' =>
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

	'pat.alt.subject.trait.part.1' =>
		'g10 Code GmbH gives unlimited permission',
	'pat.alt.subject.trait.part.2' =>
		'Certain portions of the mk[word]\.awk source text are designed',
	'pat.alt.subject.trait.part.3' =>
		'If your modification has such potential, you must delete',
};

$RE{except_autoconf_3} = {
	name                  => 'Autoconf-exception-3.0',
	'name.alt.org.debian' => 'Autoconf-3.0',
	caption               => 'Autoconf exception 3.0',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.1' =>
		"The purpose of this Exception is to allow distribution of Autoconf[']s",
};

=item * except_bison_1_24

=item * except_bison_2_2

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'when this file is copied by Bison into a Bison output file, '
		. 'you may use that output file without restriction[.][ ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'This special exception was added by the Free Software Foundation'
		. 'in version 1\.24 of Bison[.]'
};

$RE{except_bison_2_2} = {
	name                  => 'Bison-exception-2.2',
	'name.alt.org.debian' => 'Bison-2.2',
	caption               => 'Bison exception 2.2',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'you may create a larger work that contains '
		. 'part or all of the Bison parser skeleton',
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'you may create a larger work that contains '
		. 'part or all of the Bison parser skeleton'
		. 'and distribute that work under terms of your choice, '
		. "so long as that work isn[']t itself a parser generator"
		. 'using the skeleton or a modified version thereof '
		. 'as a parser skeleton[.]'
		. 'Alternatively, if you modify or redistribute the parser skeleton itself, '
		. 'yoy may \(at your option\) remove this special exception, '
		. 'which will cause the skeleton and the resulting Bison output files '
		. 'to be licensed under the GNU General Public License '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'This special exception was added by the Free Software Foundation'
		. 'in version 2\.2 of Bison[.]'
};

=item * except_classpath_2

=cut

$RE{except_classpath_2} = {
	name                  => 'Classpath-exception-2.0',
	'name.alt.org.debian' => 'Classpath-2.0',
	caption               => 'Classpath exception 2.0',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'link this library with independent modules',
	'pat.alt.subject.trait.scope.multisection.part.intro' =>
		'Linking this library statically or dynamically with other modules '
		. 'is making a combined work based on this library[.][ ]'
		. 'Thus, the terms and conditions of the GNU General Public License '
		. 'cover the whole combination[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'the copyright holders of this library give you permission '
		. 'to link this library with independent modules to produce an executable, '
		. 'regardless of the license terms of these independent modules, '
		. 'and to copy and distribute the resulting executable '
		. 'under terms of your choice, '
		. 'provided that you also meet, '
		. 'for each linked independent module, '
		. 'the terms and conditions of the license of that module[.][ ]?',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'An independent module is a module '
		. 'which is not derived from or based on this library[.] '
		. 'If you modify this library, '
		. 'you may extend this exception to your version of the library, '
		. 'but you are not obligated to do so[.] '
		. 'If you do not wish to do so, '
		. 'delete this exception statement from your version[.]',
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
		. 'and distribute linked combinations including the two[.][ ]'
		. 'If you modify this file, '
		. 'you may extend this exception to your version of the file, '
		. 'but you are not obligated to do so[.][ ]'
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
		. 'the MPL \(Mozilla Public License\), '
		. 'which EPL \(Erlang Public License\) is based on, '
		. 'is included in this exception.',
};

=item * except_faust

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
		. 'to be used and distributed together with GStreamer and[ word]{1,3}[.] '
		. 'This permission are above and beyond '
		. 'the permissions granted by the GPL license[ word]{1,3} is covered by[.]',
};

=item * except_libtool

=cut

$RE{except_libtool} = {
	name                  => 'libtool-exception',
	'name.alt.org.debian' => 'Libtool',
	caption               => 'Libtool Exception',
	tags                  => [
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
	name                  => 'mif-exception',
	'name.alt.org.debian' => 'mif',
	caption               => 'Macros and Inline Functions Exception',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.multisection.part.first' =>
		'you may use this file '
		. 'as part of a free software library without restriction[.][ ]'
		. 'Specifically, if other files instantiate templates ',
	'pat.alt.subject.trait.scope.multisection.part.all' =>
		'you may use this file '
		. 'as part of a free software library without restriction[.][ ]'
		. 'Specifically, if other files instantiate templates '
		. 'or use macros or inline functions from this file, '
		. 'or you compile this file and link it with other files '
		. 'to produce an executable, '
		. 'this file does not by itself cause the resulting executable '
		. 'to be covered by the GNU General Public License[.][ ]'
		. 'This exception does not however invalidate any other reasons '
		. 'why the executable file might be covered '
		. 'by the GNU General Public License[.]',
};

=item * except_openssl

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
		. "with the OpenSSL project[']s [\"]OpenSSL[\"] library "
		. '\(or a modified version of that library\), '
		. 'containing parts covered '
		. 'by the terms of the OpenSSL or SSLeay licenses, '
		. '(?:the authors of[ word]{1,8} grant you'
		. '|the (?:copyright holder|licensors|Free Software Foundation) grants? you'
		. '|you are granted) '
		. 'additional permission to convey the resulting work[.] '
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

=item * except_openssl_s3

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
		. "with the OpenSSL project[']s [\"]OpenSSL[\"] library "
		. '\(or with modified versions of it '
		. 'that use the same license as the ["]OpenSSL["] library '
		. '[-] see [http://]www.openssl.org/\), '
		. 'and distribute linked combinations including the two[.]'
};

=item * except_prefix_agpl

=item * except_prefix_generic

=item * except_prefix_gpl

=item * except_prefix_gpl_clisp

=item * except_prefix_lgpl

=cut

$RE{except_prefix_agpl} = {
	caption => 'AGPL exception prefix',
	tags    => [
		'family:gnu:agpl',
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait.target.generic' =>
		'In addition to the permissions in the GNU General Public License, ',
	'pat.alt.subject.trait.target.agpl_3' => 'Additional permissions? under '
		. "$the?(?:GNU )?A(?:ffero )?GPL(?: version 3|v3) section 7"
};

$RE{except_prefix_generic} = {
	caption => 'generic exception prefix',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'(?:In addition, as a special exception, '
		. '|As a special exception, )',
	'pat.alt.subject.trait.scope.paragraph' =>
		'(?:In addition, as a special exception, '
		. '|(?:Exception [*)]FIXME[  ])?'
		. 'As a special exception, '
		. '|Grant of Additional Permission[.][ ])',
};

$RE{except_prefix_gpl} = {
	caption => 'GPL exception prefix',
	tags    => [
		'family:gnu:gpl',
		'type:trait:grant:prefix',
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
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' => 'Note[:"][  ]'
		. 'This copyright does NOT cover user programs '
		. 'that run in CLISP and third-party packages not part of CLISP, '
		. "if [*)]$clisp_they_only_ref_clisp, "
		. "[ie] if they don[']t rely on CLISP internals "
		. 'and would as well run in any other Common Lisp implementation[.] '
		. "Or [*)]$clisp_they_only_ref_clisp "
		. 'and some external, not CLISP specific, symbols '
		. 'in third[-]party packages '
		. 'that are released with source code under a GPL compatible license '
		. 'and that run in a great number of Common Lisp implementations, '
		. '[ie] if they rely on CLISP internals only to the extent needed '
		. 'for gaining some functionality also available '
		. 'in a great number of Common Lisp implementations[.] '
		. 'Such user programs are not covered '
		. 'by the term ["]derived work["] used in the GNU GPL[.] '
		. 'Neither is their compiled code, '
		. '[ie] the result of compiling them '
		. 'by use of the function COMPILE-FILE[.] '
		. 'We refer to such user programs '
		. 'as ["]independent work["][.][  ]',
};

$RE{except_prefix_lgpl} = {
	caption => 'LGPL exception prefix',
	tags    => [
		'family:gnu:lgpl',
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait.scope.sentence' =>
		'In addition to the permissions in '
		. 'the GNU (?:Lesser|Library) General Public License, '
};

=item * except_proguard

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'(?:Eric Lafortune|Guardsquare NV) gives permission '
		. 'to link the code of this program '
		. "with the following stand[-]alone applications[:]?"
};

=item * except_qt_gpl_1

=item * except_qt_gpl_eclipse

=item * except_qt_gpl_openssl

=cut

$RE{except_qt_gpl_1} = {
	name                  => 'Qt-GPL-exception-1.0',
	'name.alt.org.debian' => 'Qt-GPL-1.0',
	caption               => 'Qt GPL exception 1.0',
	tags                  => [
		'family:gnu:gpl',
		'type:trait:exception',
	],

	'pat.alt.subject.trait.scope.sentence.part.1' =>
		'you may create a larger work which contains '
		. 'the output of this application '
		. 'and distribute that work under terms of your choice, '
		. 'so long as the work is not otherwise derived from or based on this application '
		. 'and so long as the work does not in itself generate output '
		. 'that contains the output from this application in its original or modified form',
	'pat.alt.subject.trait.scope.paragraph.part.2' =>
		'you have permission to combine this application with Plugins '
		. 'licensed under the terms of your choice, '
		. 'to produce an executable, and to copy and distribute the resulting executable '
		. 'under the terms of your choice[.] '
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
	'pat.alt.subject.trait.scope.paragraph.part.1' =>
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
	'pat.alt.subject.trait.scope.paragraph.part.1' =>
		'Nokia gives permission to link the code of its release of Qt '
		. "with the OpenSSL project[']s [\"]OpenSSL[\"] library "
		. '\(or modified versions of the ["]OpenSSL["] library '
		. 'that use the same license as the original version\), '
		. 'and distribute the linked executables[.][  ]',
	'pat.alt.subject.trait.scope.paragraph.part.2' =>
		' You must comply with the GNU General Public License version 2 '
		. 'in all respects for all of the code used '
		. 'other than the ["]OpenSSL["] code[.] '
		. 'If you modify this file, '
		. 'you may extend this exception to your version of the file, '
		. 'but you are not obligated to do so[.] '
		. 'If you do not wish to do so, '
		. 'delete this exception statement '
		. 'from your version of this file[.]'
};

=item * except_qt_kernel

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
		'(?:Digia|Nokia|The Qt Company) gives you certain additional rights[.] '
		. 'These rights are described '
		. 'in The (?:Digia Qt|Nokia Qt|Qt Company) LGPL Exception version 1\.1, '
		. 'included in the file [word] in this package'
};

=item * except_qt_nosource

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'you may create a larger work that contains '
		. 'code generated by the Shared Data Compiler'
		. 'and distribute that work under terms of '
		. 'the GNU Lesser General Public License \(LGPL\)'
		. 'by the Free Software Foundation; '
		. 'either version 2\.1 of the License, '
		. 'or \(at your option\) any later version '
		. 'or under terms that are fully compatible with these licenses[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'Alternatively, if you modify or redistribute '
		. 'the Shared Data Compiler tool itself, '
		. 'you may \(at your option\) remove this special exception, '
		. 'which will cause the resulting generted source code files '
		. 'to be licensed under the GNU General Public License '
		. '\(either version 2 of the License, '
		. 'or at your option under any later version\) '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.3' =>
		'This special exception was added by Jaros[ł]aw Staniek[.][ ]'
		. 'Contact him for more licensing options, '
		. '[eg] using in non-Open Source projects[.]',
};

=item * except_sollya_4_1

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'you may create a larger work that contains '
		. 'part or all of this software generated using Sollya'
		. 'and distribute that work under terms of your choice, '
		. "so long as that work isn[']t itself a numerical code generator "
		. 'using the skeleton of this code or a modified version thereof '
		. 'as a code skeleton[.]'
		. 'Alternatively, if you modify or redistribute this code itself, '
		. 'or its skeleton, '
		. 'you may \(at your option\) remove this special exception, '
		. 'which will cause this generated code and its skeleton '
		. 'and the resulting Sollya output files'
		. 'to be licensed under the CeCILL-C License '
		. 'without this special exception[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'This special exception was added by the Sollya copyright holders '
		. 'in version 4\.1 of Sollya[.]'
};

=item * except_warzone

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'the copyright holders of Warzone 2100 '
		. 'give you permission to combine Warzone 2100 '
		. 'with code included in the standard release of libraries '
		. 'that are accessible, redistributable and linkable '
		. 'free of charge[.] '
		. 'You may copy and distribute such a system '
		. 'following the terms of the GNU GPL '
		. 'for Warzone 2100 '
		. 'and the licenses of the other code concerned[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'Note that people who make modified versions of Warzone 2100 '
		. 'are not obligated to grant this special exception '
		. 'for their modified versions; '
		. 'it is their choice whether to do so[.] '
		. 'The GNU General Public License gives permission '
		. 'to release a modified version without this exception; '
		. 'this exception also makes it possible '
		. 'to release a modified version '
		. 'which carries forward this exception[.]'
};

=item * except_xerces

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
	'pat.alt.subject.trait.scope.multisection.part.1' =>
		'Code Synthesis Tools CC gives permission '
		. 'to link this program with the Xerces-C\+\+ library '
		. '\(or with modified versions of Xerces-C\+\+ '
		. 'that use the same license as Xerces-C\+\+\), '
		. 'and distribute linked combinations including the two[.] '
		. 'You must obey the GNU General Public License version 2 '
		. 'in all respects '
		. 'for all of the code used other than Xerces-C\+\+[.] '
		. 'If you modify this copy of the program, '
		. 'you may extend this exception '
		. 'to your version of the program, '
		. 'but you are not obligated to do so[.] '
		. 'If you do not wish to do so, '
		. 'delete this exception statement from your version[.][  ]',
	'pat.alt.subject.trait.scope.multisection.part.2' =>
		'Furthermore, Code Synthesis Tools CC makes a special exception '
		. 'for the Free[/]Libre and Open Source Software \(FLOSS\) '
		. 'which is described in the accompanying FLOSSE file[.] '
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

=cut

$RE{generated} = {
	name    => 'generated',
	caption => 'generated file',
	tags    => [
		'type:trait:flaw',
	],

	'_pat.alt.subject.trait.scope.sentence' => [
		'this is (?:a )?generated (?:file|manifest)',
		'This file (?:has been|is|was) (?:[*]{1,3})?(?:auto(?:matically |[-]?)|tool[-])?generated(?:[*]{1,3})?',
		'All changes made in this file will be lost',
		'generated file(?:[.] |[ - ])do not (?:edit|modify)[!.]',
		'DO NOT (?:EDIT|MODIFY) THIS FILE',
		'generated by[ word](?: \([word][ word]{0,2}\))?[  ]'
			. '(?:Please )?DO NOT delete this file[!]',

# weak, but seems to catch no false positives at end of line
		'Generated by running[:]$',

# too weak: does not mention file explicitly, so may reflect only a subset
#		'Generated (?:automatically|by|from|data|with)',
#		'generated (?:by|from|using)(?: the)?[ word]{1,2}(?: compiler)?[.][ ]'
#			. '(please )?Do not (edit|modify)',
#		'Machine generated[.][ ](please )?Do not (edit|modify)',
#		'Do not (edit|modify)[.][ ]Generated (?:by|from|using)',
#		'(?:created with|trained by)[ word][.][ ](please )?Do not edit',
	],
	'_pat.alt.subject.trait.scope.sentence.target.autotools' => [
		'Makefile\.in generated by automake [#.]+ from Makefile\.am[.]',
		'generated automatically by aclocal [#.]+ -\*?- Autoconf',
		'Generated(?: from[ word])? by GNU Autoconf',
		'(?:Attempt to guess a canonical system name|Configuration validation subroutine script)[.][ ]'
			. 'Copyright [c] [#-,]+Free Software Foundation',
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

=item * license_label_trove

=cut

$RE{license_label} = {
	caption => 'license grant "License:" phrase',
	tags    => [
		'type:trait:grant:prefix',
	],

	'pat.alt.subject.trait' =>
		'(?P<_license_label>[Ll]icen[sc]e|[Ii]dentifier)[:"]',
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
		. ') ',
};

=item * or_at_option

=cut

$RE{or_at_option} = {
	caption => 'license grant "or at your option" phrase',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' =>
		'(?P<_or_at_option>(?:and|or)(?: ?\(?at your (?:option|choice)\)?)?)',
};

=item * usage_rfn

=cut

$RE{usage_rfn} = {
	caption => 'license usage "with Reserved Font Name" phrase',
	tags    => [
		'type:trait:usage:rfn',
	],

	'pat.alt.subject.trait' => '(?P<_usage_rfn>with Reserved Font Name)',
};

=item * version

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

	'pat.alt.subject.trait' => '\(?(?P<_version_later_postfix>'
		. $RE{or_at_option}{'pat.alt.subject.trait'}
		. '(?: any)? (?:later|above|newer)(?: version)?'
		. '|or any later at your option)\)?',
};

$RE{version_later}{'pat.alt.subject.trait.scope.line.scope.sentence'}
	= '(?:,? )?(?P<version_later>'
	. $RE{version_later_postfix}{'pat.alt.subject.trait'} . ')';
$RE{version_later}{'pat.alt.subject.trait.scope.paragraph'}
	= '(?:[.]?[ ])?(?P<version_later>'
	. $RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'}
	. ')';
$RE{version_later}{'pat.alt.subject.trait'}
	= '(?:[.]?[ ]|,? )?(?P<version_later>'
	. $RE{version_later_paragraph}{'pat.alt.subject.trait.scope.paragraph'}
	. '|'
	. $RE{version_later_postfix}{'pat.alt.subject.trait'} . ')';

=item * version_number

=item * version_number_suffix

=cut

$RE{version_number} = {
	caption => 'version number',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait' => '(?P<version_number>\d(?:\.\d)*\b)',
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
		' ?(?P<_version_only>(?:only|\(no other versions\)))',
};

=item * version_prefix

=cut

$RE{version_prefix} = {
	caption => 'version prefix',
	tags    => [
		'type:trait',
	],

	'pat.alt.subject.trait.scope.line.scope.sentence' =>
		'(?:[-]|[;]? ?(?:(?:only |either )?)?|[ - ])?\(?(?:[Vv]ersion [Vv]?|VERSION |rev(?:ision)? |[Vv]\.? ?)?',
	'pat.alt.subject.trait.scope.paragraph' =>
		':?[ ]\(?(?:Version [Vv]?|VERSION )?',
	'pat.alt.subject.trait' =>
		'(?:[-]|[;](?: (?:either )?)?|[ - ]|:?[ ])?\(?(?:[Vv]ersion [Vv]?|VERSION |[Vv]\.? ?)?',
};

=item * version_numberstring

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
	. ')?)\)?(?: of)? ?';
$RE{version}{'pat.alt.subject.trait.scope.paragraph'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait.scope.paragraph'}
	. '(?:'
	. $RE{version_later}{'pat.alt.subject.trait.scope.paragraph'}
	. ')?)\)?';
$RE{version}{'pat.alt.subject.trait'}
	= '(?P<_version>'
	. $RE{version_numberstring}{'pat.alt.subject.trait'} . '(?:'
	. $RE{version_later}{'pat.alt.subject.trait'}
	. ')?)\)?(?: of)? ?';

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
	name                   => 'AAL',
	'name.alt.org.fedora'  => 'AAL',
	'name.alt.org.osi'     => 'AAL',
	'name.alt.org.spdx'    => 'AAL',
	caption                => 'Attribution Assurance License',
	'caption.alt.org.tldr' => 'Attribution Assurance License (AAL)',
	'iri.alt.old.osi' => 'https://opensource.org/licenses/attribution.php',
	tags              => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'must prominently display this GPG-signed text',
};

=item * abstyles

=cut

$RE{abstyles} = {
	name                      => 'Abstyles',
	'name.alt.org.fedora.web' => 'Abstyles',
	'name.alt.org.spdx'       => 'Abstyles',
	caption                   => 'Abstyles License',
	tags                      => [
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
	name                                => 'Adobe-2006',
	'name.alt.misc.scancode'            => 'adobe-scl',
	'name.alt.org.fedora.synth.nogrant' => 'Adobe',
	'name.alt.org.fedora.web'           => 'AdobeLicense',
	'name.alt.org.spdx'                 => 'Adobe-2006',
	'name.alt.org.tldr' =>
		'adobe-systems-incorporated-source-code-license-agreement',
	caption => 'Adobe Systems Incorporated Source Code License Agreement',
	'caption.alt.org.fedora.web.synth.nogrant' => 'Adobe License',
	tags                                       => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
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
	tags                                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'and to permit others to do the same, provided that the derived work is not represented as being a copy',
};

=item * adsl

=cut

$RE{adsl} = {
	name                      => 'ADSL',
	'name.alt.org.fedora.web' => 'AmazonDigitalServicesLicense',
	'name.alt.org.spdx'       => 'ADSL',
	caption                   => 'Amazon Digital Services License',
	tags                      => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Your use of this software code is at your own risk '
		. 'and you waive any claim against Amazon Digital Services, Inc[.]',
};

=item * afl

=item * afl_1_1

=item * afl_1_2

=item * afl_2

=item * afl_2_1

=item * afl_3

=cut

my $termination_for_patent_including_counterclaim
	= '[*)]Termination for Patent Action[.][ ]'
	. 'This License shall terminate automatically '
	. 'and You may no longer exercise any of the rights '
	. 'granted to You by this License '
	. 'as of the date You commence an action, '
	. 'including a cross-claim or counterclaim,';

$RE{afl} = {
	name                        => 'AFL',
	'name.alt.org.wikidata'     => 'Q337279',
	caption                     => 'Academic Free License',
	'caption.alt.org.trove'     => 'Academic Free License (AFL)',
	'caption.alt.org.wikipedia' => 'Academic Free License',
	tags                        => [
		'type:versioned:decimal',
	],

# TODO: readd when children cover same region
#	'pat.alt.subject.license.scope.line.scope.paragraph' =>
#		'Exclusions [Ff]rom License Grant[.][ ]Neither',
};

$RE{afl_1_1} = {
	name                => 'AFL-1.1',
	'name.alt.org.spdx' => 'AFL-1.1',
	caption             => 'Academic Free License Version v1.1',
	tags                => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' => 'The Academic Free License applies to',
};

$RE{afl_1_2} = {
	name                => 'AFL-1.2',
	'name.alt.org.spdx' => 'AFL-1.2',
	caption             => 'Academic Free License Version v1.2',
	tags                => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license' => 'This Academic Free License applies to',
};

$RE{afl_2} = {
	name                => 'AFL-2.0',
	'name.alt.org.spdx' => 'AFL-2.0',
	caption             => 'Academic Free License Version v2.0',
	tags                => [
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
	name                => 'AFL-2.1',
	'name.alt.org.spdx' => 'AFL-2.1',
	caption             => 'Academic Free License Version v2.1',
	tags                => [
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
	name                           => 'AFL-3.0',
	'name.alt.org.fedora'          => 'AFL',
	'name.alt.org.fsf'             => 'Academic_Free_License_3.0',
	'name.alt.org.osi'             => 'AFL-3.0',
	'name.alt.org.spdx'            => 'AFL-3.0',
	'name.alt.org.tldr.path.short' => 'afl3',
	caption                        => 'Academic Free License version 3.0',
	'caption.alt.org.tldr'         => 'Academic Free License 3.0 (AFL)',
	'iri.alt.old.osi' => 'https://opensource.org/licenses/academic.php',
	tags              => [
		'license:contains:grant',
		'type:singleversion:afl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection' =>
		'the conditions in Section 1\(c\)[.][  ]'
		. $termination_for_patent_including_counterclaim
		. ' against Licensor or any licensee',
};

=item * afmparse

=cut

$RE{afmparse} = {
	name                      => 'Afmparse',
	'name.alt.org.fedora.web' => 'Afmparse',
	'name.alt.org.spdx'       => 'Afmparse',
	caption                   => 'Afmparse License',
	tags                      => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'If the file has been modified in any way, '
		. 'a notice of such modification is conspicuously indicated[.]',
};

=item * agpl

=item * agpl_1

=item * agpl_1_only

=item * agpl_1_or_later

=item * agpl_2

=item * agpl_3

=item * agpl_3_only

=item * agpl_3_or_later

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
	tags                        => [
		'family:gpl',
		'license:contains:grant',
		'type:versioned:decimal',
	],
};

$RE{agpl_1} = {
	name                  => 'AGPLv1',
	'name.alt.org.debian' => 'AGPL-1',
	'name.alt.org.spdx'   => 'AGPL-1.0',
	caption               => 'Affero General Public License, Version 1',
	iri                   => 'http://www.affero.org/oagpl.html',
	tags                  => [
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
	'pat.alt.subject.license.part.2_d' =>
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
	name                  => 'AGPL-1.0-or-later',
	'name.alt.org.debian' => 'AGPL-1+',
	caption               => 'Affero General Public License v1.0 or later',
	tags                  => [
		'family:gpl',
		'type:usage:agpl_1:or_later'
	],
};

$RE{agpl_2} = {
	name                  => 'AGPLv2',
	'name.alt.org.debian' => 'AGPL-2',
	caption               => 'Affero General Public License, Version 2',
	iri                   => 'http://www.affero.org/agpl2.html',
	tags                  => [
		'family:gpl',
		'type:singleversion:agpl'
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.1' =>
		'This is version 2 of the Affero General Public License[.]',
	'pat.alt.subject.license.part.2' =>
		'If the Program was licensed under version 1 of the Affero GPL',
};

$RE{agpl_3} = {
	name                           => 'AGPLv3',
	'name.alt.org.debian'          => 'AGPL-3',
	'name.alt.org.gnu'             => 'AGPLv3.0',
	'name.alt.org.osi'             => 'AGPL-3.0',
	'name.alt.org.perl'            => 'agpl_3',
	'name.alt.org.spdx'            => 'AGPL-3.0',
	'name.alt.org.tldr.path.short' => 'agpl3',
	caption => 'GNU Affero General Public License, Version 3',
	'caption.alt.org.gnu' =>
		'GNU Affero General Public License (AGPL) version 3',
	'caption.alt.org.perl'  => 'GNU Affero General Public License, Version 3',
	'caption.alt.org.trove' => 'GNU Affero General Public License v3',
	'caption.alt.org.tldr' =>
		'GNU Affero General Public License v3 (AGPL-3.0)',
	iri                  => 'https://www.gnu.org/licenses/agpl',
	'iri.alt.format.txt' => 'https://www.gnu.org/licenses/agpl.txt',
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
	'pat.alt.subject.license.scope.sentence.part.13_1' =>
		'This Corresponding Source shall include '
		. 'the Corresponding Source for any work '
		. 'covered by '
		. 'version 3 of the GNU General Public License',
	'pat.alt.subject.license.scope.sentence.part.13_2_1' =>
		'Notwithstanding any other provision of this License, '
		. 'you have permission to link or combine any covered work '
		. 'with a work licensed under '
		. 'version 3 of the GNU General',
	'pat.alt.subject.license.scope.sentence.part.13_2_2' =>
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
	name    => 'AGPL-3.0-only',
	caption => 'GNU Affero General Public License v3.0 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:agpl_3:only',
	],
};

$RE{agpl_3_or_later} = {
	name                  => 'AGPL-3.0-or-later',
	'name.alt.org.debian' => 'AGPL-3+',
	'name.alt.org.trove'  => 'AGPLv3+',
	caption => 'GNU Affero General Public License v3.0 or later',
	'caption.alt.org.trove' =>
		'GNU Affero General Public License v3 or later (AGPLv3+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:agpl_3:or_later',
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
	tags                    => [
		'type:versioned:decimal',
	],
};

$RE{aladdin_8} = {
	name                    => 'Aladdin-8',
	'name.alt.org.scancode' => 'afpl-8',
	'name.alt.org.spdx'     => 'Aladdin',
	'name.alt.org.debian'   => 'Aladdin-8',
	caption                 => 'Aladdin Free Public License, Version 8',
	tags                    => [
		'type:singleversion:aladdin',
	],
	licenseversion => '8',

	'pat.alt.subject.license.scope.multisection' =>
		'laws of the appropriate country[.][  ]0[.] Subject Matter',
};

$RE{aladdin_9} = {
	name                           => 'Aladdin-9',
	'name.alt.org.scancode'        => 'afpl-9',
	'name.alt.org.tldr.path.short' => 'aladdin',
	caption                => 'Aladdin Free Public License, Version 9',
	'caption.alt.org.tldr' => 'Aladdin Free Public License',
	'iri.alt.archive.20130804020135' =>
		'http://www.artifex.com/downloads/doc/Public.htm',
	tags => [
		'type:singleversion:aladdin',
	],
	licenseversion => '9',

	'pat.alt.subject.license' =>
		'This License is not an Open Source license: among other things',
};

=item * amdplpa

=cut

$RE{amdplpa} = {
	name                => 'AMDPLPA',
	'name.alt.org.spdx' => 'AMDPLPA',
	caption             => "AMD's plpa_map.c License",
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Neither the names nor trademarks of Advanced Micro Devices, Inc\.',
};

=item * aml

=cut

$RE{aml} = {
	name                   => 'AML',
	'name.alt.org.spdx'    => 'AML',
	caption                => 'Apple MIT License',
	'caption.alt.org.tldr' => 'Apple MIT License (AML)',
	tags                   => [
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
	name                => 'AMPAS',
	'name.alt.org.spdx' => 'AMPAS',
	caption             => 'Academy of Motion Picture Arts and Sciences BSD',
	tags                => [
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
	name                => 'ANTAL-PD',
	'name.alt.org.spdx' => 'ANTLR-PD',
	caption             => 'ANTLR Software Rights Notice',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'We reserve no legal rights to the ANTLR[-][-]?it is fully in the public domain[.]',
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
	'caption.alt.misc.public'   => 'Apache Public License',
	iri  => 'https://www.apache.org/licenses/LICENSE-2.0',
	tags => [
		'type:versioned:decimal',
	],

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
		. 'the Apache Group for use in the Apache HTTP server project',
};

$RE{apache_1_1} = {
	name                        => 'Apache-1.1',
	'name.alt.org.osi'          => 'Apache-1.1',
	'name.alt.org.perl'         => 'apache_1_1',
	'name.alt.org.spdx'         => 'Apache-1.1',
	'name.alt.org.tldr'         => 'apache-license-1.1',
	caption                     => 'Apache License 1.1',
	'caption.alt.org.osi'       => 'Apache Software License, version 1.1',
	'caption.alt.org.perl'      => 'Apache Software License, Version 1.1',
	'caption.alt.org.tldr'      => 'Apache License 1.1 (Apache-1.1)',
	'caption.alt.misc.software' => 'Apache Software License 1.1',
	description                 => <<'END',
Identical to BSD (3 clause), except...
* add documentation-acknowledgement clause (as 3rd clause similar to BSD-4-clause advertising clause)
* extend non-endorsement clause to include contact info
* add derivatives-must-rename clause
END
	iri => 'https://www.apache.org/licenses/LICENSE-1.1',
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
		. 'Copyright [c] 2000 The Apache Software Foundation[.]'
		. ' All rights reserved[.][  ])?'
		. $P{repro_copr_cond_discl}
		. '[.][  ]'
		. '[*)]?The end-user documentation included',
};

$RE{apache_2} = {
	name                           => 'Apache-2.0',
	'name.alt.org.osi'             => 'Apache-2.0',
	'name.alt.org.perl'            => 'apache_2_0',
	'name.alt.org.spdx'            => 'Apache-2.0',
	'name.alt.org.tldr.path.short' => 'apache2',
	caption                        => 'Apache License 2.0',
	'caption.alt.org.osi'          => 'Apache License, Version 2.0',
	'caption.alt.org.osi.alt.list' => 'Apache License 2.0 (Apache-2.0)',
	'caption.alt.org.perl'         => 'Apache License, Version 2.0',
	'caption.alt.org.tldr'         => 'Apache License 2.0 (Apache-2.0)',
	'caption.alt.misc.public'      => 'Apache Public License 2.0',
	'caption.alt.misc.software'    => 'Apache Software License 2.0',
	iri => 'https://www.apache.org/licenses/LICENSE-2.0',
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
	name                      => 'APAFML',
	'name.alt.org.fedora'     => 'APAFML',
	'name.alt.org.fedora.web' => 'AdobePostscriptAFM',
	'name.alt.org.spdx'       => 'APAFML',
	caption                   => 'Adobe Postscript AFM License',
	tags                      => [
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
	name    => 'APL',
	caption => 'Adaptive Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{apl_1} = {
	name                   => 'APL-1.0',
	'name.alt.org.osi'     => 'APL-1.0',
	'name.alt.org.spdx'    => 'APL-1.0',
	caption                => 'Adaptive Public License 1.0',
	'caption.alt.org.tldr' => 'Adaptive Public License 1.0 (APL-1.0)',
	tags                   => [
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
	name                     => 'APSL',
	'name.alt.org.wikidata'  => 'Q621330',
	'name.alt.org.wikipedia' => 'Apple_Public_Source_License',
	caption                  => 'Apple Public Source License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{apsl_1} = {
	name                => 'APSL-1.0',
	'name.alt.org.spdx' => 'APSL-1.0',
	caption             => 'Apple Public Source License 1.0',
	tags                => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 1\.0(?: [-] March 16, ?1999)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.1' =>
		'subject to the terms of this Apple Public Source License version 1\.0 ',
};

$RE{apsl_1_1} = {
	name                => 'APSL-1.1',
	'name.alt.org.spdx' => 'APSL-1.1',
	caption             => 'Apple Public Source License 1.1',
	tags                => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 1\.1(?: [-] April 19, ?1999)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.1' =>
		'subject to the terms of this Apple Public Source License version 1\.1 ',
};

$RE{apsl_1_2} = {
	name                => 'APSL-1.2',
	'name.alt.org.spdx' => 'APSL-1.2',
	caption             => 'Apple Public Source License 1.2',
	tags                => [
		'type:singleversion:apsl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. ' Ver(?:sion|\.) 1\.2(?: [-] January 4, ?2001)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.1' =>
		'subject to the terms of this Apple Public Source License version 1\.2 ',
};

$RE{apsl_2} = {
	name                           => 'APSL-2.0',
	'name.alt.org.tldr.path.short' => 'aspl2',
	caption                        => 'Apple Public Source License 2.0',
	'caption.alt.org.tldr' => 'Apple Public Source License 2.0 (APSL)',
	'iri.alt.org.osi'      => 'https://opensource.org/licenses/APSL-2.0',
	tags                   => [
		'type:singleversion:apsl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'(?:APPLE PUBLIC SOURCE LICENSE|Apple Public Source License)[ ]'
		. 'Ver(?:sion|\.) 2\.0(?: [-] August 6, ?2003)?[  ]'
		. '(?:Please read this License carefully|[*)]General[;] Definitions[.])',
	'pat.alt.subject.license.scope.sentence.part.1' =>
		'subject to the terms of this Apple Public Source License version 2\.0 ',
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
	tags                        => [
		'type:versioned:complex',
	],
};

$RE{artistic_1} = {
	name                        => 'Artistic-1.0',
	'name.alt.org.osi'          => 'Artistic-1.0',
	'name.alt.org.spdx'         => 'Artistic-1.0',
	caption                     => 'Artistic License, version 1.0',
	'caption.alt.org.osi'       => 'Artistic License 1.0 (Artistic-1.0)',
	'caption.alt.org.wikipedia' => 'Artistic License 1.0',
	'iri.alt.old.osi' =>
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
	name                => 'Artistic-1.0-cl8',
	'name.alt.org.spdx' => 'Artistic-1.0-cl8',
	summary             => 'Artistic License 1.0 w/clause 8',
	tags                => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0-cl8',

	'pat.alt.subject.license.scope.multisection' => 'this Package[.][  ]'
		. '[*)]Aggregation of this Package',
};

$RE{artistic_1_clarified} = {
	name                           => 'Artistic-1.0-clarified',
	'name.alt.org.spdx'            => 'ClArtistic',
	caption                        => 'Clarified Artistic License',
	'caption.alt.org.fedora'       => 'Artistic (clarified)',
	'caption.alt.org.fedora.short' => 'Artistic clarified',
	'caption.alt.org.fedora.web'   => 'Artistic Clarified',
	'caption.alt.org.spdx'         => 'Clarified Artistic License',
	iri =>
		'http://gianluca.dellavedova.org/2011/01/03/clarified-artistic-license/',
	tags => [
		'type:singleversion:artistic',
	],
	licenseversion => '1.0-clarified',

	'pat.alt.subject.license' =>
		'Aggregation of the Standard Version of the Package',
};

$RE{artistic_1_perl} = {
	name                                 => 'Artistic-1.0-Perl',
	'name.alt.org.perl.synth.nogrant'    => 'artistic_1',
	'name.alt.org.spdx'                  => 'Artistic-1.0-Perl',
	caption                              => 'Artistic License 1.0 (Perl)',
	'caption.alt.org.fedora'             => 'Artistic 1.0 (original)',
	'caption.alt.org.perl.synth.nogrant' => 'Artistic License, (Version 1)',
	'caption.alt.org.spdx'               => 'Artistic License 1.0 (Perl)',
	iri => 'http://dev.perl.org/licenses/artistic.html',
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
	name                           => 'Artistic-2.0',
	'name.alt.org.osi'             => 'Artistic-2.0',
	'name.alt.org.perl'            => 'artistic_2',
	'name.alt.org.tldr'            => 'artistic-license-2.0-(artistic)',
	'name.alt.org.tldr.path.short' => 'artistic',
	caption                        => 'Artistic License (v2.0)',
	'caption.alt.org.perl'         => 'Artistic License, Version 2.0',
	'caption.alt.org.tldr'         => 'Artistic License 2.0 (Artistic-2.0)',
	'caption.alt.org.wikipedia'    => 'Artistic License 2.0',
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
	name                => 'Bahyph',
	'name.alt.org.spdx' => 'Bahyph.html',
	caption             => 'Bahyph License',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'These patterns were developed for internal GMV use and are made public',
};

=item * barr

=cut

$RE{barr} = {
	name                => 'Barr',
	'name.alt.org.spdx' => 'Barr',
	caption             => 'Barr License',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'This is a package of commutative diagram macros built on top of Xy[-]pic',
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
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{to_copy_prg}
		. $P{any_purpose}
		. $P{retain_notices_all}
		. '[.][ ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_notices}
		. $P{note_mod_inc_with_copr} . '[.]',
};

=item * bdwgc_matlab

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
		. $P{retain_notices_all}
		. '[.][ ]'
		. $P{repro_code_cite_authors_copr}
		. $P{and_used_by_perm} . '[ ]'
		. $P{repro_matlab_cite_authors}
		. '[.][ ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_notices}
		. $P{note_mod_inc_with_copr}
		. '[.][ ]'
		. $P{retain_you_avail_orig} . '[.]',
	'pat.alt.subject.license.part.credit' => 'must cite the Authors',
};

=item * beerware

=cut

$RE{beerware} = {
	name                           => 'Beerware',
	'name.alt.misc.dash'           => 'Beer-ware',
	'name.alt.org.fedora.web'      => 'Beerware',
	'name.alt.org.spdx'            => 'Beerware',
	'name.alt.org.tldr.path.short' => 'beerware',
	'name.alt.org.wikidata'        => 'Q10249',
	caption                        => 'Beerware License',
	'caption.alt.org.tldr'         => 'Beerware License',
	'caption.alt.org.wikipedia'    => 'Beerware',
	tags                           => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => 'you can buy me a beer in return',

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

=item * bittorrent

=item * bittorrent_1

=item * bittorrent_1_1

=cut

$RE{bittorrent} = {
	name    => 'BitTorrent',
	caption => 'BitTorrent Open Source License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{bittorrent_1} = {
	name                => 'BitTorrent-1.0',
	'name.alt.org.spdx' => 'BitTorrent-1.0',
	caption             => 'BitTorrent Open Source License v1.0',
	description         => <<'END',
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
	'pat.alt.subject.license.scope.multisection.part.4' =>
		' has been made available'
		. '[.][ ]You are responsible for ensuring'
		. ' that the Source Code version remains available'
		. ' even if the Electronic Distribution Mechanism is maintained by a third party'
		. '[.][  ][*)]'
		. 'Intellectual Property Matters[.]',
};

$RE{bittorrent_1_1} = {
	name                => 'BitTorrent-1.1',
	'name.alt.org.spdx' => 'BitTorrent-1.1',
	caption             => 'BitTorrent Open Source License v1.1',
	tags                => [
		'license:contains:grant:bittorrent_1',
		'type:singleversion:bittorrent',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'BitTorrent Open Source License[  ]'
		. 'Version 1\.1[  ]'
		. 'This BitTorrent Open Source License',
	'pat.alt.subject.license.scope.multisection.part.4' =>
		' is distributed by you'
		. '[.][ ]You are responsible for ensuring'
		. ' that the Source Code version remains available'
		. ' even if the Electronic Distribution Mechanism is maintained by a third party'
		. '[.][  ][*)]'
		. 'Intellectual Property Matters[.]',
};

=item * borceux

=cut

$RE{borceux} = {
	name                => 'Borceux',
	'name.alt.org.spdx' => 'Borceux',
	caption             => 'Borceux license',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'distribute each of the files in this package',
};

=item * bsd_0_clause

=cut

$RE{bsd_0_clause} = {
	name                           => '0BSD',
	'name.alt.org.osi'             => 'FPL-1.0.0',
	'name.alt.org.spdx'            => '0BSD',
	'name.alt.org.tldr'            => 'bsd-0-clause-license',
	caption                        => 'BSD (0 clause)',
	'caption.alt.org.osi'          => 'Zero-Clause BSD',
	'caption.alt.org.osi.alt.free' => 'Free Public License 1.0.0',
	'caption.alt.org.osi.alt.dualname' =>
		'Zero-Clause BSD / Free Public License 1.0.0',
	'caption.alt.org.spdx' => 'BSD Zero Clause License',
	'caption.alt.org.tldr' => 'BSD 0-Clause License (0BSD)',
	description            => <<'END',
Identical to ISC, except...
* Redistribution of source need not retain any legal text
* omit requirement of notices appearing in copies
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.name.alt.misc.free' => 'Free Public License' . '(?:'
		. $RE{version_prefix}
		{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. '1(?:\.0){0,2})?',
	'pat.alt.subject.license.scope.multisection' => $P{granted}
		. '[.][  ]'
		. $P{asis_sw_name_discl},
};

=item * bsd_2_clause

=cut

$RE{bsd_2_clause} = {
	name                                => 'BSD-2-Clause',
	'name.alt.org.debian'               => 'BSD-2-clause',
	'name.alt.org.fedora.synth.nogrant' => 'BSD',
	'name.alt.org.fedora.web.bsd'       => '2ClauseBSD',
	'name.alt.org.osi'                  => 'BSD-2-Clause',
	'name.alt.org.perl'                 => 'freebsd',
	'name.alt.org.spdx'                 => 'BSD-2-Clause',
	'name.alt.org.tldr'                 => 'bsd-2-clause-license-(freebsd)',
	'name.alt.org.tldr.path.short'      => 'freebsd',
	'name.alt.misc.clauses'             => '2-clause-BSD',
	'name.alt.misc.freebsd'             => 'FreeBSD',
	'name.alt.misc.simplified'          => 'Simplified-BSD',
	caption                             => 'BSD (2 clause)',
	'caption.alt.org.fedora'            => 'BSD License (two clause)',
	'caption.alt.org.osi'               => 'The 2-Clause BSD License',
	'caption.alt.org.osi.alt.list' => '2-clause BSD license (BSD-2-Clause)',
	'caption.alt.org.perl'         => 'FreeBSD License (two-clause)',
	'caption.alt.org.spdx'         => 'BSD 2-clause "Simplified" License',
	'caption.alt.org.tldr' => 'BSD 2-Clause License (FreeBSD/Simplified)',
	'name.alt.org.wikipedia.bsd' =>
		'2-clause license ("Simplified BSD License" or "FreeBSD License")',
	'caption.alt.misc.qemu' =>
		'BSD Licence (without advertising or endorsement clauses)',
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

=item * bsd_3_clause

=cut

$RE{bsd_3_clause} = {
	name                                => 'BSD-3-Clause',
	'name.alt.org.debian'               => 'BSD-3-clause',
	'name.alt.org.fedora.synth.nogrant' => 'BSD',
	'name.alt.org.fedora.web.bsd'       => '3ClauseBSD',
	'name.alt.org.osi'                  => 'BSD-3-Clause',
	'name.alt.org.perl.synth.nogrant'   => 'bsd',
	'name.alt.org.spdx'                 => 'BSD-3-Clause',
	'name.alt.org.tldr.path.short'      => 'bsd3',
	'name.alt.misc.clauses'             => '3-clause-BSD',
	'name.alt.misc.eclipse'             => 'EPL',
	'name.alt.misc.eclipse_1'           => 'EPL-1.0',
	'name.alt.misc.modified'            => 'Modified-BSD',
	caption                             => 'BSD (3 clause)',
	'caption.alt.org.fedora'            => 'BSD License (no advertising)',
	'caption.alt.org.osi'               => 'The 3-Clause BSD License',
	'caption.alt.org.osi.alt.list' => '3-clause BSD license (BSD-3-Clause)',
	'caption.alt.org.perl'         => 'BSD License (three-clause)',
	'caption.alt.org.spdx' => 'BSD 3-clause "New" or "Revised" License',
	'caption.alt.org.tldr' => 'BSD 3-Clause License (Revised)',
	'caption.alt.org.wikipedia.bsd' =>
		'3-clause license ("BSD License 2.0", "Revised BSD License", "New BSD License", or "Modified BSD License")',
	'caption.alt.misc.eclipse'    => 'Eclipse Distribution License',
	'caption.alt.misc.new'        => 'new BSD License',
	'caption.alt.misc.new_parens' => '(new) BSD License',
	'caption.alt.misc.short'      => 'BSD 3 clause',
	'caption.alt.misc.qemu' => 'BSD Licence (without advertising clause)',
	tags                    => [
		'family:bsd',
		'license:contains:license:bsd_2_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.name.alt.misc.eclipse' => 'Eclipse Distribution License'
		. '(?:'
		. $RE{version_prefix}
		{'pat.alt.subject.trait.scope.line.scope.sentence'}
		. '1(?:\.0)?)?',
	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '[.]?[  ]'
		. '(?:[*)]\[?(?:rescinded 22 July 1999'
		. '|This condition was removed[.])\]?)?' . '[*)]'
		. $P{nopromo_neither},
};

=item * bsd_4_clause

=cut

$RE{bsd_4_clause} = {
	name                           => 'BSD-4-Clause',
	'name.alt.org.debian'          => 'BSD-4-clause',
	'name.alt.org.fedora.web.bsd'  => 'BSDwithAdvertising',
	'name.alt.org.spdx'            => 'BSD-4-Clause',
	'name.alt.org.tldr'            => '4-clause-bsd',
	'name.alt.misc.clauses'        => '4-clause-BSD',
	caption                        => 'BSD (4 clause)',
	'caption.alt.org.fedora'       => 'BSD License (original)',
	'caption.alt.org.fedora.short' => 'BSD with advertising',
	'caption.alt.org.spdx' => 'BSD 4-clause "Original" or "Old" License',
	'caption.alt.org.tldr' => '4-Clause BSD',
	'caption.alt.org.wikipedia.bsd' =>
		'4-clause license (original "BSD License")',
	'caption.alt.misc.qemu' => 'BSD Licence (with advertising clause)',
	tags                    => [
		'family:bsd',
		'license:contains:license:bsd_3_clause',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => $P{ad_mat_ack_this},
	'pat.alt.subject.license.scope.multisection.part.head' =>
		$P{repro_copr_cond_discl} . '[.][  ]' . '[*)]?' . $P{ad_mat_ack_this},
	'pat.alt.subject.license.scope.multisection.part.tail' => '[*)]?'
		. $P{ad_mat_ack_this}
		. '[.][  ]' . '[*)]?'
		. $P{nopromo_neither},
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
	tags => [
		'type:versioned:decimal',
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
	iri                            => 'http://www.boost.org/LICENSE_1_0.txt',
	'iri.alt.org.facebook.archive.20070630190325' =>
		'http://developers.facebook.com/thrift/',
	tags => [
		'license:is:grant',
		'type:singleversion:bsl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'this license \(the ["]Software["]\) to use, reproduce',
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
		. 'you must not claim that you wrote the original software[.] '
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
	name                => 'bzip2-1.0.5',
	'name.alt.org.spdx' => 'bzip2-1.0.5',
	caption             => 'bzip2 and libbzip2 License v1.0.5',
	tags                => [
		'license:is:grant',
		'type:singleversion:bzip2',
	],
	licenseversion => '1.0.5',

	'pat.alt.subject.license' =>
		'This program, ["]?bzip2["]?(?: and|, the) associated library ["]?libbzip2["]?, '
		. '(?:and all documentation, )?'
		. 'are copyright [c] 1996[-]2007',
};

$RE{bzip2_1_0_6} = {
	name                => 'bzip2-1.0.6',
	'name.alt.org.spdx' => 'bzip2-1.0.6',
	caption             => 'bzip2 and libbzip2 License v1.0.6',
	tags                => [
		'license:is:grant',
		'type:singleversion:bzip2',
	],
	licenseversion => '1.0.6',

	'pat.alt.subject.license' =>
		'This program, ["]?bzip2[\"]?(?: and|, the) associated library ["]?libbzip2["]?, '
		. '(?:and all documentation, )?'
		. 'are copyright [c] 1996[-]2010',
};

=item * cal

=item * cal_1

=cut

$RE{cal} = {
	name    => 'CAL',
	caption => 'Cryptographic Autonomy License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cal_1} = {
	name                  => 'CAL-1.0',
	'name.alt.org.osi'    => 'CAL-1.1',
	'name.alt.org.spdx'   => 'CAL-1.1',
	caption               => 'Cryptographic Autonomy License 1.0',
	'caption.alt.org.osi' => 'Cryptographic Autonomy License version 1.0',
	'caption.alt.org.osi.alt.list' => 'Cryptographic Autonomy License v.1.0',
	'caption.alt.misc.legal' => 'The Cryptographic Autonomy License, v. 1.0',
	'iri.alt.misc.github' =>
		'https://github.com/holochain/cryptographic-autonomy-license',
	tags => [
		'type:singleversion:cal',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'This Cryptographic Autonomy License \(the [“]License[”]\) '
		. 'applies to any Work '
		. 'whose owner has marked it',
};

=item * caldera

=cut

$RE{caldera} = {
	name                => 'Caldera',
	'name.alt.org.spdx' => 'Caldera',
	caption             => 'BSD Source Caldera License',
	tags                => [
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
	name               => 'CATOSL-1.1',
	'iri.alt.org.osi'  => 'CATOSL-1.1',
	'iri.alt.org.spdx' => 'CATOSL-1.1',
	caption => 'Computer Associates Trusted Open Source License 1.1',
	'caption.alt.org.tldr' =>
		'Computer Associates Trusted Open Source License 1.1 (CATOSL-1.1)',
	tags => [
		'type:singleversion:catosl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'Contribution means \(a\) in the case of CA, the Original Program',
};

=item * cc_by

=item * cc_by_1

=item * cc_by_2

=item * cc_by_2_5

=item * cc_by_3

=item * cc_by_4

=cut

my $if_dist_work_or_works_keep_intact_notices
	= 'If you distribute, publicly display, publicly perform, or publicly digitally perform the Work or any Derivative Works or Collective Works, You must keep intact all copyright notices for the Work and';
my $if_dist_work_or_collections_keep_intact_notices
	= 'If You Distribute, or Publicly Perform the Work or any Adaptations or Collections, You must, unless a request has been made pursuant to Section 4\(a\), keep intact all copyright notices for the Work and';
my $credit_author_if_supplied
	= ' give the Original Author credit reasonable to the medium or means You are utilizing by conveying the name \(or pseudonym if applicable\) of the Original Author if supplied;';
my $credit_author_or_designated_party
	= ' provide, reasonable to the medium or means You are utilizing:?'
	. ' \(i\) the name of the Original Author \(or pseudonym, if applicable\) if supplied, and[/]or'
	. ' \(ii\) if the Original Author and[/]or Licensor designate another party or parties'
	. ' \([eg] a sponsor institute, publishing entity, journal\)'
	. " for attribution in Licensor[']?s copyright notice, terms of service or by other reasonable means,"
	. ' the name of such party or parties;';

#" if the Original Author and[/]or Licensor designate another party or parties \\(e\\.g\\., a sponsor institute, publishing entity, journal\\) for attribution \\(\"Attribution Parties\"\\) in Licensor[']?s copyright notice, terms of service or by other reasonable means, the name of such party or parties;";
#' \(ii\) the title of the Work if supplied;';
my $to_extend_URI
	= ' to the extent reasonably practicable, the Uniform Resource Identifier, if any, that Licensor specifies to be associated with the Work,'
	. ' unless such URI does not refer to the copyright notice or licensing information for the Work; and';

#    ' (iii) to the extent reasonably practicable, the URI, if any, that Licensor specifies to be associated with the Work, unless such URI does not refer to the copyright notice or licensing information for the Work; and'
#" (iv) , consistent with Section 3(b), in the case of an Adaptation, a credit identifying the use of the Work in the Adaptation (e.g., "French translation of the Work by Original Author," or "Screenplay based on original Work by Original Author"). The credit required by this Section 4 (b) may be implemented in any reasonable manner; provided, however, that in the case of a Adaptation or Collection, at a minimum such credit will appear, if a credit for all contributing authors of the Adaptation or Collection appears, then as part of these credits and in a manner at least as prominent as the credits for the other contributing authors. For the avoidance of doubt, You may only use the credit required by this Section for the purpose of attribution in the manner set out above and, by exercising Your rights under this License, You may not implicitly or explicitly assert or imply any connection with, sponsorship or endorsement by the Original Author, Licensor and[/]or Attribution Parties, as appropriate, of You or Your use of the Work, without the separate, express prior written permission of the Original Author, Licensor and[/]or Attribution Parties.

$RE{cc_by} = {
	name              => 'CC-BY',
	'name.alt.org.cc' => 'by',
	caption           => 'Creative Commons Attribution Public License',
	tags              => [
		'family:cc',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_by} . '|BY|'
		. $P{cc_url} . 'by))',
};

$RE{cc_by_1} = {
	name    => 'CC-BY-1.0',
	caption => 'Creative Commons Attribution 1.0 Generic License',
	'caption.alt.org.cc.legal.license' => 'Creative Commons Attribution 1.0',
	iri  => 'https://creativecommons.org/licenses/by/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.multisection' => 'as requested[.][ ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_if_supplied
		. ' the title of the Work if supplied;'
		. ' in the case of a Derivative',
};

$RE{cc_by_2} = {
	name    => 'CC-BY-2.0',
	caption => 'Creative Commons Attribution 2.0 Generic License',
	'caption.alt.org.cc.legal.license' => 'Creative Commons Attribution 2.0',
	iri  => 'https://creativecommons.org/licenses/by/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.multisection' => 'as requested[.][ ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_if_supplied
		. ' the title of the Work if supplied;'
		. $to_extend_URI
		. ' in the case of a Derivative',
};

$RE{cc_by_2_5} = {
	name    => 'CC-BY-2.5',
	caption => 'Creative Commons Attribution 2.5 Generic License',
	'caption.alt.org.cc.legal.license' => 'Creative Commons Attribution 2.5',
	iri  => 'https://creativecommons.org/licenses/by/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by',
	],
	licenseversion => '2.5',

	'pat.alt.subject.license.multisection' => 'as requested[.][ ]' . '[*)]?'
		. $if_dist_work_or_works_keep_intact_notices
		. $credit_author_or_designated_party
		. ' the title of the Work if supplied;'
		. $to_extend_URI
		. ' in the case of a Derivative',
};

$RE{cc_by_3} = {
	name    => 'CC-BY-3.0',
	caption => 'Creative Commons Attribution 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution 3.0 Unported',
	'caption.alt.org.tldr.version.cc_by_3' =>
		'Creative Commons Attribution 3.0 Unported (CC-BY)',
	iri  => 'https://creativecommons.org/licenses/by/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.multisection' => 'as requested[.][ ]' . '[*)]?'
		. $if_dist_work_or_collections_keep_intact_notices

#              . $credit_author_or_designated_party
#              . ' the title of the Work if supplied;'
#              . ' to the extent reasonably practicable, the Uniform Resource Identifier, if any, that Licensor specifies to be associated with the Work, unless such URI does not refer to the copyright notice or licensing information for the Work; and'
#              . ' in the case of a Derivative',
};

$RE{cc_by_4} = {
	name                           => 'CC-BY-4.0',
	'name.alt.org.tldr.path.short' => 'ccby4',
	caption => 'Creative Commons Attribution 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution 4.0 International',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution 4.0 International (CC BY 4.0)',
	iri  => 'https://creativecommons.org/licenses/by/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by',
	],
	licenseversion => '4.0',
};

=item * cc_by_nc

=item * cc_by_nc_1

=item * cc_by_nc_2

=item * cc_by_nc_2_5

=item * cc_by_nc_3

=item * cc_by_nc_4

=cut

$RE{cc_by_nc} = {
	name              => 'CC-BY-NC',
	'name.alt.org.cc' => 'by-nc',
	caption => 'Creative Commons Attribution-NonCommercial Public License',
	tags    => [
		'family:cc',
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
	name => 'CC-BY-NC-1.0',
	caption =>
		'Creative Commons Attribution-NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial 1.0',
	iri  => 'https://creativecommons.org/licenses/by-nc/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_2} = {
	name                => 'CC-BY-NC-2.0',
	'name.alt.org.tldr' => 'creative-commons-public-license-(ccpl)',
	caption =>
		'Creative Commons Attribution-NonCommercial 2.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial 2.0',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)',
	iri  => 'https://creativecommons.org/licenses/by-nc/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_2_5} = {
	name => 'CC-BY-NC-2.5',
	caption =>
		'Creative Commons Attribution-NonCommercial 2.5 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial 2.5',
	iri  => 'https://creativecommons.org/licenses/by-nc/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_3} = {
	name => 'CC-BY-NC-3.0',
	caption =>
		'Creative Commons Attribution-NonCommercial 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_4} = {
	name => 'CC-BY-NC-4.0',
	caption =>
		'Creative Commons Attribution-NonCommercial 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial 4.0 International',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)',
	iri  => 'https://creativecommons.org/licenses/by-nc/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc',
	],
	licenseversion => '4.0',
};

=item * cc_by_nc_nd

=item * cc_by_nc_nd_1

=item * cc_by_nc_nd_2

=item * cc_by_nc_nd_2_5

=item * cc_by_nc_nd_3

=item * cc_by_nc_nd_4

=cut

$RE{cc_by_nc_nd} = {
	name              => 'CC-BY-NC-ND',
	'name.alt.org.cc' => 'by-nc-nd',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives Public License',
	tags => [
		'family:cc',
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
	name => 'CC-BY-NC-ND-1.0',
	caption =>
		'Creative Commons Attribution-NoDerivs-NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivs-NonCommercial 1.0',
	iri  => 'https://creativecommons.org/licenses/by-nd-nc/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_nd_2} = {
	name => 'CC-BY-NC-ND-2.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.0',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_nd_2_5} = {
	name => 'CC-BY-NC-ND-2.5',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 2.5',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_nd_3} = {
	name => 'CC-BY-NC-ND-3.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_nd_4} = {
	name => 'CC-BY-NC-ND-4.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International',
	iri  => 'https://creativecommons.org/licenses/by-nc-nd/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_nd',
	],
	licenseversion => '4.0',
};

=item * cc_by_nc_sa

=item * cc_by_nc_sa_1

=item * cc_by_nc_sa_2

=item * cc_by_nc_sa_2_5

=item * cc_by_nc_sa_3

=item * cc_by_nc_sa_4

=cut

$RE{cc_by_nc_sa} = {
	name              => 'CC-BY-NC-SA',
	'name.alt.org.cc' => 'by-nc-sa',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike Public License',
	tags => [
		'family:cc',
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
	name => 'CC-BY-NC-SA-1.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 1.0',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nc_sa_2} = {
	name => 'CC-BY-NC-SA-2.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.0',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nc_sa_2_5} = {
	name => 'CC-BY-NC-SA-2.5',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 2.5',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nc_sa_3} = {
	name => 'CC-BY-NC-SA-3.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nc_sa_4} = {
	name => 'CC-BY-NC-SA-4.0',
	caption =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)',
	iri  => 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nc_sa',
	],
	licenseversion => '4.0',
};

=item * cc_by_nd

=item * cc_by_nd_1

=item * cc_by_nd_2

=item * cc_by_nd_2_5

=item * cc_by_nd_3

=item * cc_by_nd_4

=cut

$RE{cc_by_nd} = {
	name              => 'CC-BY-ND',
	'name.alt.org.cc' => 'by-nd',
	caption => 'Creative Commons Attribution-NoDerivatives Public License',
	tags    => [
		'family:cc',
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
	name    => 'CC-BY-ND-1.0',
	caption => 'Creative Commons Attribution-NoDerivs 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivs 1.0',
	iri  => 'https://creativecommons.org/licenses/by-nd/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '1.0',
};

$RE{cc_by_nd_2} = {
	name    => 'CC-BY-ND-2.0',
	caption => 'Creative Commons Attribution-NoDerivs 2.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivs 2.0',
	iri  => 'https://creativecommons.org/licenses/by-nd/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '2.0',
};

$RE{cc_by_nd_2_5} = {
	name    => 'CC-BY-ND-2.5',
	caption => 'Creative Commons Attribution-NoDerivs 2.5 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivs 2.5',
	iri  => 'https://creativecommons.org/licenses/by-nd/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '2.5',
};

$RE{cc_by_nd_3} = {
	name    => 'CC-BY-ND-3.0',
	caption => 'Creative Commons Attribution-NoDerivs 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivs 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-nd/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '3.0',
};

$RE{cc_by_nd_4} = {
	name => 'CC-BY-ND-4.0',
	caption =>
		'Creative Commons Attribution-NoDerivatives 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-NoDerivatives 4.0 International',
	'caption.alt.org.tldr' =>
		'Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)',
	iri  => 'https://creativecommons.org/licenses/by-nd/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_nd',
	],
	licenseversion => '4.0',
};

=item * cc_by_sa

=item * cc_by_sa_1

=item * cc_by_sa_2

=item * cc_by_sa_2_5

=item * cc_by_sa_3

=item * cc_by_sa_4

=cut

$RE{cc_by_sa} = {
	name              => 'CC-BY-SA',
	'name.alt.org.cc' => 'by-sa',
	caption => 'Creative Commons Attribution-ShareAlike Public License',
	tags    => [
		'family:cc',
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
	name    => 'CC-BY-SA-1.0',
	caption => 'Creative Commons Attribution-ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-ShareAlike 1.0',
	iri  => 'https://creativecommons.org/licenses/by-sa/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '1.0',
};

$RE{cc_by_sa_2} = {
	name    => 'CC-BY-SA-2.0',
	caption => 'Creative Commons Attribution-ShareAlike 2.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-ShareAlike 2.0',
	iri  => 'https://creativecommons.org/licenses/by-sa/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '2.0',
};

$RE{cc_by_sa_2_5} = {
	name    => 'CC-BY-SA-2.5',
	caption => 'Creative Commons Attribution-ShareAlike 2.5 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-ShareAlike 2.5',
	iri  => 'https://creativecommons.org/licenses/by-sa/2.5/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '2.5',
};

$RE{cc_by_sa_3} = {
	name    => 'CC-BY-SA-3.0',
	caption => 'Creative Commons Attribution-ShareAlike 3.0 Unported License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-ShareAlike 3.0 Unported',
	iri  => 'https://creativecommons.org/licenses/by-sa/3.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '3.0',
};

$RE{cc_by_sa_4} = {
	name => 'CC-BY-SA-4.0',
	caption =>
		'Creative Commons Attribution-ShareAlike 4.0 International License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons Attribution-ShareAlike 4.0 International',
	'caption.alt.org.tldr' =>
		' Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
	iri  => 'https://creativecommons.org/licenses/by-sa/4.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_by_sa',
	],
	licenseversion => '4.0',
};

=item * cc_cc0

=item * cc_cc0_1

=cut

$RE{cc_cc0} = {
	name                        => 'CC0',
	'name.alt.org.cc'           => 'zero',
	caption                     => 'Creative Commons CC0 Public License',
	'caption.alt.misc.american' => 'CC0 License',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	tags => [
		'family:cc',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_cc0}
		. '(?: \(?[\"]?CC0["]?\)?)?|CC0|'
		. $P{cc_url_pd}
		. 'zero))',
	'pat.alt.subject.grant' =>
		'has waived all copyright and related or neighboring rights',
};

$RE{cc_cc0_1} = {
	name                           => 'CC0-1.0',
	'name.alt.org.spdx'            => 'CC0-1.0',
	'name.alt.org.tldr.path.short' => 'cc0-1.0',
	caption => 'Creative Commons CC0 Universal 1.0 Public Domain Dedication',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons CC0 1.0 Universal',
	'caption.alt.org.tldr' => 'Creative Commons CC0 1.0 Universal (CC-0)',
	iri => 'https://creativecommons.org/publicdomain/zero/1.0/',
	'iri.alt.org.wikipedia' =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	tags => [
		'family:cc',
		'type:singleversion:cc_cc0',
	],
	licenseversion => '1.0',

	'pat.alt.subject.grant' =>
		'has waived all copyright and related or neighboring rights',
};

=item * cc_nc

=item * cc_nc_1

=cut

$RE{cc_nc} = {
	name              => 'CC-NC',
	'name.alt.org.cc' => 'nc',
	caption           => 'Creative Commons NonCommercial Public License',
	tags              => [
		'family:cc',
		'type:versioned:decimal',
	],
};

$RE{cc_nc_1} = {
	name    => 'CC-NC-1.0',
	caption => 'Creative Commons NonCommercial 1.0 Generic License',
	'caption.alt.org.cc.legal.license' =>
		'Creative Commons NonCommercial 1.0',
	iri  => 'https://creativecommons.org/licenses/nc/2.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_nc',
	],
	licenseversion => '1.0',
};

=item * cc_nd

=item * cc_nd_1

=cut

$RE{cc_nd} = {
	name              => 'CC-ND',
	'name.alt.org.cc' => 'nd',
	caption           => 'Creative Commons NoDerivs Public License',
	tags              => [
		'family:cc',
		'type:versioned:decimal',
	],
};

$RE{cc_nd_1} = {
	name    => 'CC-ND-1.0',
	caption => 'Creative Commons NoDerivs 1.0 Generic License',
	'caption.alt.org.cc.legal.license' => 'Creative Commons NoDerivs 1.0',
	iri  => 'https://creativecommons.org/licenses/nd/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_nd',
	],
	licenseversion => '1.0',
};

=item * cc_sa

=item * cc_sa_1

=cut

$RE{cc_sa} = {
	name              => 'CC-SA',
	'name.alt.org.cc' => 'sa',
	caption           => 'Creative Commons ShareAlike Public License',
	tags              => [
		'family:cc',
		'type:versioned:decimal',
	],
};

$RE{cc_sa_1} = {
	name    => 'CC-SA-1.0',
	caption => 'Creative Commons ShareAlike 1.0 Generic License',
	'caption.alt.org.cc.legal.license' => 'Creative Commons ShareAlike 1.0',
	iri  => 'https://creativecommons.org/licenses/sa/1.0/',
	tags => [
		'family:cc',
		'type:singleversion:cc_sa',
	],
	licenseversion => '1.0',
};

=item * cc_sp

=cut

$RE{cc_sp} = {
	name              => 'Sampling+',
	'name.alt.org.cc' => 'sampling+',
	caption           => 'Creative Commons Sampling Plus Public License',
	tags              => [
		'family:cc',
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => '(?:'
		. $P{cc}
		. '[- ](?:'
		. $P{cc_sp} . '|'
		. $P{cc_url}
		. 'sampling\+))',
};

=item * cddl

=item * cddl_1

=item * cddl_1_1

=cut

$RE{cddl} = {
	name                    => 'CDDL',
	'name.alt.org.wikidata' => 'Q304628',
	caption                 => 'Common Development and Distribution License',
	'caption.alt.org.wikipedia' =>
		'Common Development and Distribution License',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{cddl_1} = {
	name                           => 'CDDL-1.0',
	'name.alt.org.osi'             => 'CDDL-1.0',
	'name.alt.org.spdx'            => 'CDDL-1.0',
	'name.alt.org.tldr.path.short' => 'cddl',
	caption => 'Common Development and Distribution License 1.0',
	'caption.alt.org.osi' =>
		'Common Development and Distribution License 1.0',
	'caption.alt.org.osi.alt.list' =>
		'Common Development and Distribution License version 1.0 (CDDL-1.0)',
	'caption.alt.org.tldr' =>
		'Common Development and Distribution License (CDDL-1.0)',
	tags => [
		'type:singleversion:cddl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Sun Microsystems, Inc[.] is the initial license steward',
};

$RE{cddl_1_1} = {
	name                => 'CDDL-1.1',
	'name.alt.org.spdx' => 'CDDL-1.1',
	caption             => 'Common Development and Distribution License 1.1',
	tags                => [
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
	name                        => 'CECILL',
	'name.alt.org.wikidata'     => 'Q1052189',
	caption                     => 'CeCILL License',
	'caption.alt.misc.last(en)' => 'FREE SOFTWARE LICENSE AGREEMENT CeCILL',
	'caption.alt.org.inria(en)' => 'CeCILL FREE SOFTWARE LICENSE AGREEMENT',
	'caption.alt.org.inria(fr)' =>
		'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL',
	'caption.alt.org.wikipedia' => 'CeCILL',
	'iri.alt.path.sloppy'       => 'http://www.cecill.info',
	tags                        => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name(fr)' => '(?:la )?licence CeCILL',
	'pat.alt.subject.grant.version.none(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'_pat.alt.subject.license(en)' => [
		'Version 1\.1 of 10[/]26[/]2004',
		'Version 2\.0 dated 2006[-]09[-]05',
		'Version 2\.1 dated 2013[-]06[-]21',
	],
	'_pat.alt.subject.license(fr)' => [
		'Version 1 du 21[/]06[/]2004',
		'Version 2\.0 du 2006[-]09[-]05',
		'Version 2\.1 du 2013[-]06[-]21',
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
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license(fr)' => 'Version 1 du 21[/]06[/]2004',
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
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.part.header' => 'Version 1\.1 of 10[/]26[/]2004',
	'pat.alt.subject.license.scope.sentence.part.1_initial_sw(en)' =>
		'for the first time '
		. 'under the terms and conditions of the Agreement',
	'pat.alt.subject.license.scope.sentence.part.2(en)' =>
		'Agreement is to grant users the right '
		. 'to modify and redistribute the software governed',
	'pat.alt.subject.license.scope.sentence.part.5_3(en)' =>
		'redistribute copies '
		. 'of the modified or unmodified Software to third parties ',
	'pat.alt.subject.license.scope.sentence.part.5_3_2(en)' =>
		'to all the provisions hereof',
	'pat.alt.subject.license.scope.sentence.part.5_3_3(en)' =>
		'may be distributed under a separate Licensing Agreement',
	'pat.alt.subject.license.part.5_3_4(en)' =>
		'is subject to the provisions of the GPL License',
	'pat.alt.subject.license.scope.sentence.part.6_1_1(en)' =>
		'compliance with the terms and conditions '
		. 'under which the Holder has elected to distribute its work '
		. 'and no one shall be entitled to and',
	'pat.alt.subject.license.scope.sentence.part.6_1_2(en)' =>
		'the Agreement, for the duration',
	'pat.alt.subject.license.scope.sentence.part.7_2(en)' =>
		'shall be subject to a separate',
	'pat.alt.subject.license.part.8_1(en)' =>
		'(?:Subject to the provisions of Article 8\.2, should'
		. '|subject to providing evidence of it)',
	'pat.alt.subject.license.scope.sentence.part.10_2(en)' =>
		'all licenses that it may have granted '
		. 'prior to termination of the Agreement '
		. 'shall remain valid subject to their',
	'pat.alt.subject.license.scope.sentence.part.12_3(en)' =>
		'Any or all Software distributed '
		. 'under a given version of the Agreement '
		. 'may only be subsequently distributed '
		. 'under the same version of the Agreement, '
		. 'or a subsequent version, '
		. 'subject to the provisions of article',
	'pat.alt.subject.license.scope.paragraph.part.13_1(en)' =>
		'The Agreement is governed by French law[.] '
		. 'The Parties agree to endeavor to settle',
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
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license(en)' => 'Version 2\.0 dated 2006[-]09[-]05',
	'pat.alt.subject.license(fr)' => 'Version 2\.0 du 2006[-]09[-]05',
	'pat.alt.subject.license.part.gpl' =>
		'subject to the provisions of one of the versions of the GNU GPL, and',
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
	tags => [
		'type:singleversion:cecill',
	],
	licenseversion => '2.1',

	'pat.alt.subject.grant.version.none(en)' =>
		'governed by the CeCILL  ?license',
	'pat.alt.subject.grant.version.none(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL soumise',
	'pat.alt.subject.license(en)' => 'Version 2\.1 dated 2013[-]06[-]21',
	'pat.alt.subject.license(fr)' => 'Version 2\.1 du 2013[-]06[-]21',
	'pat.alt.subject.license.part.gpl' =>
		'subject to the provisions of one of the versions of the GNU GPL, GNU',
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
	tags => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.grant(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license(en)' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license(fr)' =>
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
	tags => [
		'type:singleversion:cecill_b',
	],
	licenseversion => '1.0',

	'pat.alt.subject.grant(en)' => 'governed by the CeCILL-B license',
	'pat.alt.subject.grant.license(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-B soumise',
	'pat.alt.subject.license(en)' =>
		'The exercising of this freedom is conditional upon a strong',
	'pat.alt.subject.license(fr)' =>
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
	tags      => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.grant(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license(en)' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license(fr)' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license(en)' => 'the Software modified or not;[  ]'
		. '[*)]to ensure that use of',
	'pat.alt.subject.license(fr)' => 'Logiciel modifi[é] ou non;[  ]'
		. '[*)][à] faire en sorte que',
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
	tags => [
		'type:singleversion:cecill_c',
	],
	licenseversion => '1.0',

	'_pat.alt.subject.grant(en)' => [
		'under the terms of the CeCILL-C license',
		'governed by the CeCILL-C license',
	],
	'pat.alt.subject.grant(fr)' =>
		'Ce logiciel est r[é]gi par la licence CeCILL-C soumise',
	'_pat.alt.subject.license(en)' => [
		'The exercising of this right is conditional upon the obligation',
		'the Software modified or not;',
	],
	'_pat.alt.subject.license(fr)' => [
		'aux utilisateurs la libert[é] de modifier et',
		'Logiciel modifi[é] ou non;',
	],
	'pat.alt.subject.license.scope.all(en)' =>
		'the Software modified or not;[  ]' . '[*)]to ensure that use of',
	'pat.alt.subject.license.scope.all(fr)' =>
		'Logiciel modifi[é] ou non;[  ]' . '[*)][à] faire en sorte que',
};

=item * cnri_jython

=cut

$RE{cnri_jython} = {
	name                => 'CNRI-Jython',
	'name.alt.org.spdx' => 'CNRI-Jython',
	caption             => 'CNRI Jython License',
	iri                 => 'http://www.jython.org/license.html',

	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'[*)]CNRI is making the Software available to Licensee',
};

=item * cnri_python

=cut

$RE{cnri_python} = {
	name                     => 'CNRI-Python',
	'name.alt.org.osi'       => 'CNRI-Python',
	'name.alt.org.spdx'      => 'CNRI-Python',
	'name.alt.org.wikidata'  => 'Q5975028',
	'name.alt.org.wikipedia' => 'Python_License',
	caption                  => 'CNRI Python license',
	'summary.alt.org.osi' =>
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

	'pat.alt.subject.license.part.4' =>
		'[*)]CNRI is making Python 1\.6\.1 available to Licensee',
	'pat.alt.subject.license.scope.sentence.part.7' =>
		'with regard to derivative works based on Python 1\.6\.1 '
		. 'that incorporate non-separable material '
		. 'that was previously distributed under the GNU General Public License',
};

=item * cpal

=item * cpal_1

=cut

$RE{cpal} = {
	name    => 'CPAL',
	caption => 'Common Public Attribution License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cpal_1} = {
	name                => 'CPAL-1.0',
	'name.alt.org.osi'  => 'CPAL-1.0',
	'name.alt.org.spdx' => 'CPAL-1.0',
	caption             => 'Common Public Attribution License 1.0',
	'caption.alt.org.tldr' =>
		'Common Public Attribution License Version 1.0 (CPAL-1.0)',
	tags => [
		'type:singleversion:cpal',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Common Public Attribution License Version 1\.0 \(CPAL\)[  ]'
		. '[*)]["]?Definitions["]?',
};

=item * cpl

=item * cpl_1

=cut

$RE{cpl} = {
	name                        => 'CPL',
	'name.alt.org.wikidata'     => 'Q2477807',
	caption                     => 'Common Public License',
	'caption.alt.org.wikipedia' => 'Common Public License',
	description                 => <<'END',
Origin: IBM Public License (IPL)
END
	tags => [
		'type:versioned:decimal',
	],
};

$RE{cpl_1} = {
	name                     => 'CPL-1.0',
	caption                  => 'Common Public License 1.0',
	'caption.alt.org.tldr'   => 'Common Public License 1.0 (CPL-1.0)',
	'caption.alt.misc.legal' => 'Common Public License Version 1.0',
	iri  => 'https://www.ibm.com/developerworks/library/os-cpl.html',
	tags => [
		'type:singleversion:cpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'IBM is the initial Agreement Steward',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Common Public License Version 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS COMMON PUBLIC LICENSE \(["]AGREEMENT["]\)[.][ ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial code',
};

=item * cpol

=item * cpol_1_02

=cut

$RE{cpol} = {
	name    => 'CPOL',
	caption => 'The Code Project Open License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cpol_1_02} = {
	name                   => 'CPOL-1.02',
	caption                => 'The Code Project Open License 1.02',
	'caption.alt.org.tldr' => 'The Code Project Open License (CPOL) 1.02',
	tags                   => [
		'type:singleversion:cpol',
	],
	licenseversion => '1.02',

	'pat.alt.subject.license' => 'This License governs Your use of the Work',
};

=item * cryptix

=cut

$RE{cryptix} = {
	name                     => 'Cryptix',
	'name.alt.org.gnu'       => 'CryptixGeneralLicense',
	'name.alt.org.wikidata'  => 'Q5190781',
	'name.alt.org.wikipedia' => 'Cryptix_General_License',
	caption                  => 'Cryptix Public License',
	'caption.alt.org.gnu'    => 'Cryptix General License',
	iri                      => 'http://cryptix.org/LICENSE.TXT',
	description              => <<'END',
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
	name    => 'CPAL',
	caption => 'CUA Office Public License Version',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{cua_opl_1} = {
	name                => 'CPAL-1.0',
	'name.alt.org.osi'  => 'CUA-OPL-1.0',
	'name.alt.org.spdx' => 'CUA-OPL-1.0',
	caption             => 'CUA Office Public License Version 1.0',
	tags                => [
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
	name                => 'Cube',
	'name.alt.org.spdx' => 'Cube',
	caption             => 'Cube License',
	tags                => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote}
		. '[.][ ]'
		. $P{use_ack_apprec_not_req}
		. '[.][  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter_any}
		. '[.][  ]additional clause specific to Cube:?[ ]'
		. $P{src_no_relicense},
};

=item * curl

=cut

$RE{curl} = {
	'name.alt.org.spdx' => 'curl',
	caption             => 'curl License',
	tags                => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. '[.][  ]'
		. $P{asis_sw_warranty},
};

=item * cvw

=cut

$RE{cvw} = {
	name               => 'CVW',
	'name.alt.org.osi' => 'CVW',
	caption            => 'MITRE Collaborative Virtual Workspace License',
	'caption.alt.org.osi' =>
		'The MITRE Collaborative Virtual Workspace License',
	'caption.alt.org.osi.alt.list' =>
		'MITRE Collaborative Virtual Workspace License',
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'Redistribution of the CVW software or derived works'
		. " must reproduce MITRE[']s copyright designation",
};

=item * dsdp

=cut

$RE{dsdp} = {
	name                             => 'DSDP',
	'name.alt.org.fedora.web'        => 'DSDP',
	'name.alt.org.spdx'              => 'DSDP',
	caption                          => 'DSDP License',
	'caption.alt.org.fedora.web.mit' => 'PetSC variant',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.1' =>
		'This program discloses material protectable',
	'pat.alt.subject.license.scope.paragraph' => $P{asis_expr_warranty}
		. '[.][ ]'
		. $P{perm_granted},

};

=item * ecl

=item * ecl_1

=item * ecl_2

=cut

$RE{ecl} = {
	name                     => 'ECL',
	'name.alt.org.wikidata'  => 'Q5341236',
	'name.alt.org.wikipedia' => 'Educational_Community_License',
	caption                  => 'Educational Community License',
	'caption.alt.misc.long'  => 'Educational Community License (ECL)',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{ecl_1} = {
	name                   => 'ECL-1.0',
	'name.alt.org.osi'     => 'ECL-1.0',
	'name.alt.org.spdx'    => 'ECL-1.0',
	caption                => 'Educational Community License, Version 1.0',
	'caption.alt.org.spdx' => 'Educational Community License v1.0',
	tags                   => [
		'type:singleversion:ecl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Licensed under the Educational Community License version 1.0',
};

$RE{ecl_2} = {
	name                           => 'ECL-2.0',
	'name.alt.org.osi'             => 'ECL-2.0',
	'name.alt.org.spdx'            => 'ECL-2.0',
	'name.alt.org.tldr.path.short' => 'ecl-2.0',
	caption                => 'Educational Community License, Version 2.0',
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

=item * epl

=item * epl_1

=item * epl_2

=cut

$RE{epl} = {
	name                        => 'EPL',
	'name.alt.org.wikidata'     => 'Q1281977',
	caption                     => 'Eclipse Public License',
	'caption.alt.org.wikipedia' => 'Eclipse Public License',
	description                 => <<'END',
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
	name                     => 'EPL-1.0',
	caption                  => 'Eclipse Public License 1.0',
	'caption.alt.misc.legal' => 'Eclipse Public License - v 1.0',
	tags                     => [
		'type:singleversion:epl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' =>
		'Eclipse Public License [-] v 1\.0[  ]THE ACCOMPANYING',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Eclipse Public License [-] v 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC LICENSE \(["]AGREEMENT["]\)[.][ ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial code',
};

$RE{epl_2} = {
	name                     => 'EPL-2.0',
	caption                  => 'Eclipse Public License 2.0',
	'caption.alt.misc.legal' => 'Eclipse Public License - v 2.0',
	tags                     => [
		'type:singleversion:epl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.sentence' =>
		'Eclipse Public License [-] v 2\.0[  ]THE ACCOMPANYING',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:Eclipse Public License [-] v 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC LICENSE \(["]AGREEMENT["]\)[.][ ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.](?: |[  ])"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of the initial Contributor, the initial content',
};

=item * eupl

=item * eupl_1

=item * eupl_1_1

=item * eupl_1_2

=cut

$RE{eupl} = {
	name                     => 'EUPL',
	'name.alt.org.wikidata'  => 'Q1376919',
	'name.alt.org.wikipedia' => 'European_Union_Public_Licence',
	caption                  => 'European Union Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{eupl_1} = {
	name                   => 'EUPL-1.0',
	'name.alt.org.osi'     => 'EUPL-1.0',
	'name.alt.org.spdx'    => 'EUPL-1.0',
	caption                => 'European Union Public License, Version 1.0',
	'caption.alt.org.spdx' => 'European Union Public License 1.0',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:eupl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Licensed under the EUPL V\.1\.0[  ]or has expressed'
};

$RE{eupl_1_1} = {
	name                           => 'EUPL-1.1',
	'name.alt.org.osi'             => 'EUPL-1.1',
	'name.alt.org.spdx'            => 'EUPL-1.1',
	'name.alt.org.tldr'            => 'license/european-union-public-licence',
	'name.alt.org.tldr.path.short' => 'eupl-1.1',
	caption                => 'European Union Public License, Version 1.1',
	'caption.alt.org.spdx' => 'European Union Public License 1.1',
	'caption.alt.org.tldr' => 'European Union Public License 1.1 (EUPL-1.1)',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:eupl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Licensed under the EUPL V\.1\.1[  ]or has expressed'
};

$RE{eupl_1_2} = {
	name                   => 'EUPL-1.2',
	'name.alt.org.spdx'    => 'EUPL-1.2',
	caption                => 'European Union Public License, Version 1.2',
	'caption.alt.org.spdx' => 'European Union Public License 1.2',
	'iri.alt.org.wikipedia' =>
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
	name                => 'Eurosym',
	'name.alt.org.spdx' => 'Eurosym',
	caption             => 'Eurosym License',
	tags                => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote}
		. '[.][ ]'
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
	name                => 'FSFUL',
	'name.alt.org.spdx' => 'FSFUL',
	caption             => 'FSF Unlimited License',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		"This configure script is free software; $fsf_ul",
};

=item * fsfullr

=cut

$RE{fsfullr} = {
	name                => 'FSFULLR',
	'name.alt.org.spdx' => 'FSFULLR',
	caption             => 'FSF Unlimited License (with Retention)',
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

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
	tags                        => [
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
	name                     => 'GFDL',
	'name.alt.org.gnu'       => 'FDL',
	caption                  => 'GNU Free Documentation License',
	'caption.alt.misc.trove' => 'GNU Free Documentation License (FDL)',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{gfdl_1_1} = {
	name               => 'GFDL-1.1',
	'name.alt.org.gnu' => 'fdl-1.1',
	caption            => 'GNU Free Documentation License, Version 1.1',
	tags               => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]' . 'Version 1\.1, March 2000',
	'pat.alt.subject.license.part.1' =>
		'This License applies to any manual or other work that contains',
	'pat.alt.subject.license.scope.multisection.part.9' =>
		'the original English version will prevail[.][  ]'
		. '[*)]TERMINATION',
};

$RE{gfdl_1_1_only} = {
	name                     => 'GFDL-1.1-only',
	caption                  => 'GNU Free Documentation License v1.1 only',
	'caption.alt.misc.short' => 'GFDLv1.1 only',
	tags                     => [
		'type:usage:gfdl_1_1:only',
	],
};

$RE{gfdl_1_1_or_later} = {
	name                  => 'GFDL-1.1-or-later',
	'name.alt.org.debian' => 'GFDL-1.1+',
	caption               => 'GNU Free Documentation License v1.1 or later',
	'caption.alt.misc.short' => 'GFDLv1.1 or later',
	tags                     => [
		'type:usage:gfdl_1_1:or_later',
	],
};

$RE{gfdl_1_2} = {
	name                => 'GFDL-1.2',
	'name.alt.org.gnu'  => 'fdl-1.2',
	'name.alt.org.perl' => 'gfdl_1_2',
	caption             => 'GNU Free Documentation License, Version 1.2',
	tags                => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]' . 'Version 1\.2, November 2002',
	'pat.alt.subject.license.scope.sentence.part.9' =>
		'You may not copy, modify, sublicense, or distribute the Document '
		. 'except as expressly provided for under this License',
};

$RE{gfdl_1_2_only} = {
	name                     => 'GFDL-1.2-only',
	caption                  => 'GNU Free Documentation License v1.2 only',
	'caption.alt.misc.short' => 'GFDLv1.2 only',
	tags                     => [
		'type:usage:gfdl_1_2:only',
	],
};

$RE{gfdl_1_2_or_later} = {
	name                  => 'GFDL-1.2-or-later',
	'name.alt.org.debian' => 'GFDL-1.2+',
	caption               => 'GNU Free Documentation License v1.2 or later',
	'caption.alt.misc.short' => 'GFDLv1.2 or later',
	tags                     => [
		'type:usage:gfdl_1_2:or_later',
	],
};

$RE{gfdl_1_3} = {
	name                => 'GFDL-1.3',
	'name.alt.org.gnu'  => 'fdl-1.3',
	'name.alt.org.perl' => 'gfdl_1_3',
	'name.alt.org.tldr' => 'gnu-free-documentation-license',
	'name.alt.org.tldr.path.short.synth.nogrant' => 'fdl',
	caption                => 'GNU Free Documentation License, Version 1.3',
	'caption.alt.org.tldr' => 'GNU Free Documentation License v1.3 (FDL-1.3)',
	tags                   => [
		'license:published:by_fsf',
		'type:singleversion:gfdl',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'GNU Free Documentation License[  ]'
		. 'Version 1\.3, 3 November 2008',
	'pat.alt.subject.license.scope.sentence.part.9' =>
		'You may not copy, modify, sublicense, or distribute the Document '
		. 'except as expressly provided for under this License',
};

$RE{gfdl_1_3_only} = {
	name                     => 'GFDL-1.3-only',
	caption                  => 'GNU Free Documentation License v1.3 only',
	'caption.alt.misc.short' => 'GFDLv1.3 only',
	tags                     => [
		'type:usage:gfdl_1_3:only',
	],
};

$RE{gfdl_1_3_or_later} = {
	name                  => 'GFDL-1.3-or-later',
	'name.alt.org.debian' => 'GFDL-1.3+',
	caption               => 'GNU Free Documentation License v1.3 or later',
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
		"$the?$gnu?Free Documentation Licen[cs]e(?: \\(GFDL\\))?"
		. $RE{by_fsf}{'pat.alt.subject.trait'}
		. "?[;]? $niv",
};

=item * gpl

=item * gpl_1

=item * gpl_1_only

=item * gpl_1_or_later

=item * gpl_2

=item * gpl_2_only

=item * gpl_2_or_later

=item * gpl_3

=item * gpl_3_only

=item * gpl_3_or_later

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
	tags                           => [
		'family:gpl',
		'license:contains:grant',
		'type:versioned:decimal',
	],

	'_pat.alt.subject.name' => [
		"$the?$gnu?$gpl(?: \\(GPL\\))?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the$gnu?GPL",
		"${the}GNU [Ll]icense",
		"${gnu}GPL",
	],
};

$RE{gpl_1} = {
	name                  => 'GPL-1.0',
	'name.alt.org.debian' => 'GPL-1',
	'name.alt.org.perl'   => 'gpl_1',
	'name.alt.org.fsf'    => 'GPLv1',
	caption               => 'GNU General Public License, Version 1',
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
	name                     => 'GPL-1.0-only',
	caption                  => 'GNU General Public License v1.0 only',
	'caption.alt.misc.short' => 'GPLv1 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_1:only',
	],
};

$RE{gpl_1_or_later} = {
	name                     => 'GPL-1.0-or-later',
	'name.alt.org.debian'    => 'GPL-1+',
	'name.alt.org.trove'     => 'GPLv1+',
	caption                  => 'GNU General Public License v1.0 or later',
	'caption.alt.misc.short' => 'GPLv1 or later',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_1:or_later',
	],
};

$RE{gpl_2} = {
	name                           => 'GPL-2',
	'name.alt.misc.short'          => 'GPLv2',
	'name.alt.org.debian'          => 'GPL-2',
	'name.alt.org.gnu'             => 'GNUGPLv2',
	'name.alt.org.osi'             => 'GPL-2.0',
	'name.alt.org.perl'            => 'gpl_2',
	'name.alt.org.spdx'            => 'GPL-2.0',
	'name.alt.org.tldr'            => 'gnu-general-public-license-v2',
	'name.alt.org.tldr.path.short' => 'gpl2',
	caption                        => 'GNU General Public License, Version 2',
	'caption.alt.org.gnu'   => 'GNU General Public License (GPL) version 2',
	'caption.alt.org.trove' => 'GNU General Public License v2 (GPLv2)',
	'caption.alt.org.osi'   => 'GNU General Public License version 2',
	'caption.alt.org.osi.alt.list' => 'GNU General Public License, version 2',
	'caption.alt.org.tldr' => 'GNU General Public License v2.0 (GPL-2.0)',
	iri => 'https://www.gnu.org/licenses/old-licenses/gpl-2.0.html',
	'iri.alt.format.txt' =>
		'https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt',
	'iri.alt.path.short' => 'http://www.gnu.org/licenses/gpl-2.0.html',
	tags                 => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:gpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.part.preamble' =>
		'\(Some other Free Software Foundation software is covered by t?he GNU (Library|Lesser)',
	'pat.alt.subject.license.scope.multisection.part.tail_sample' =>
		'[<]?name of author[>]?[  ]'
		. 'This program is free software[;]? '
		. 'you can redistribute it and[/]or modify it '
		. 'under the terms of the GNU General Public License '
		. 'as published by the Free Software Foundation[;]? '
		. 'either version 2 of the License, or',
};

$RE{gpl_2_only} = {
	name                     => 'GPL-2.0-only',
	caption                  => 'GNU General Public License v2.0 only',
	'caption.alt.misc.short' => 'GPLv2 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_2:only',
	],
};

$RE{gpl_2_or_later} = {
	name                     => 'GPL-2.0-or-later',
	'name.alt.org.debian'    => 'GPL-2+',
	'name.alt.org.trove'     => 'GPLv2+',
	caption                  => 'GNU General Public License v2.0 or later',
	'caption.alt.misc.short' => 'GPLv2 or later',
	'caption.alt.org.trove' =>
		'GNU General Public License v2 or later (GPLv2+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_2:or_later',
	],
};

$RE{gpl_3} = {
	name                           => 'GPL-3',
	'name.alt.misc.short'          => 'GPLv3',
	'name.alt.org.debian'          => 'GPL-3',
	'name.alt.org.gnu'             => 'GNUGPLv3',
	'name.alt.org.osi'             => 'GPL-3.0',
	'name.alt.org.perl'            => 'gpl_3',
	'name.alt.org.spdx'            => 'GPL-3.0',
	'name.alt.org.tldr.path.short' => 'gpl-3.0',
	caption                        => 'GNU General Public License, Version 3',
	'caption.alt.org.gnu'   => 'GNU General Public License (GPL) version 3',
	'caption.alt.org.trove' => 'GNU General Public License v3 (GPLv3)',
	'caption.alt.org.osi'   => 'GNU General Public License version 3',
	'caption.alt.org.osi.alt.list' => 'GNU General Public License, version 3',
	'caption.alt.org.tldr'         => 'GNU General Public License v3 (GPL-3)',
	iri                            => 'https://www.gnu.org/licenses/gpl.html',
	'iri.alt.format.txt'           => 'https://www.gnu.org/licenses/gpl.txt',
	'iri.alt.path.fragmented' =>
		'https://www.gnu.org/licenses/licenses.html#GPL',
	'iri.alt.path.versioned' => 'http://www.gnu.org/licenses/gpl-3.0.html',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:singleversion:gpl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.part.0' =>
		'["]This License["] refers to version 3 of the GNU General',
	'pat.alt.subject.license.scope.sentence.part.13' =>
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
};

$RE{gpl_3_only} = {
	name                     => 'GPL-3.0-only',
	caption                  => 'GNU General Public License v3.0 only',
	'caption.alt.misc.short' => 'GPLv3 only',
	tags                     => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_3:only',
	],
};

$RE{gpl_3_or_later} = {
	name                     => 'GPL-3.0-or-later',
	'name.alt.org.debian'    => 'GPL-3+',
	'name.alt.org.trove'     => 'GPLv3+',
	caption                  => 'GNU General Public License v3.0 or later',
	'caption.alt.misc.short' => 'GPLv3 or later',
	'caption.alt.org.trove' =>
		'GNU General Public License v3 or later (GPLv3+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:gpl_3:or_later',
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
	tags                           => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. '[.][  ]'
		. $P{asis_sw_name_discl},
};

=item * icu

=cut

$RE{icu} = {
	name                             => 'ICU',
	caption                          => 'ICU License',
	'caption.alt.org.fedora.web.mit' => 'Modern style (ICU Variant)',
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{note_copr_perm}
		. ' of the Software and that '
		. $P{repro_copr_perm_appear_doc}
		. '[.][  ]'
		. $P{asis_sw_warranty}
		. '(?:[^.]+[.][ ]){2}'
		. $P{nopromo_except},
};

=item * intel

=cut

$RE{intel} = {
	name                           => 'Intel',
	caption                        => 'Intel Open Source License',
	'caption.alt.org.osi'          => 'The Intel Open Source License',
	'caption.alt.org.osi.alt.list' => 'Intel Open Source License',
	description                    => <<'END',
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
		. $P{discl_warranties}
		. $P{discl_liability}
		. 'EXPORT LAWS[:] THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT LAWS',
	'pat.alt.subject.license.part.last' =>
		'EXPORT LAWS[:] THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT LAWS',
};

=item * ipl

=item * ipl_1

=cut

$RE{ipl} = {
	name                        => 'IPL',
	'name.alt.org.wikidata'     => 'Q288745',
	caption                     => 'IBM Public License',
	'caption.alt.org.wikipedia' => 'IBM Public License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{ipl_1} = {
	name                     => 'IPL-1.0',
	caption                  => 'IBM Public License 1.0',
	'caption.alt.misc.legal' => 'IBM Public License Version 1.0',
	tags                     => [
		'type:singleversion:ipl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.sentence' => 'UNDER THE TERMS OF THIS IBM',
	'pat.alt.subject.license.scope.multisection.part.head' =>
		'(?:IBM Public License Version 1\.0[  ])?'
		. 'THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS IBM PUBLIC LICENSE \(["]AGREEMENT["]\)[.][ ]'
		. "ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT[']S ACCEPTANCE OF THIS AGREEMENT[.][  ]"
		. '[*)][  ]?DEFINITIONS[  ]'
		. '["]Contribution["] means[:"]?[  ]'
		. '[*)]in the case of International Business Machines Corporation \(["]IBM["]\), the Original Program',
};

=item * jabberpl

=cut

$RE{jabberpl} = {
	name               => 'jabberpl',
	'name.alt.org.osi' => 'jabberpl',
	caption            => 'Jabber Open Source License',
	tags               => [
		'license:contains:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.intro' =>
		'This Jabber Open Source License \(the ["]License["]\)'
		. ' applies to Jabber Server and related software products',
};

=item * json

=cut

$RE{json} = {
	name                   => 'JSON',
	caption                => 'JSON License',
	'caption.alt.org.tldr' => 'The JSON License',
	tags                   => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'The Software shall be used for Good, not Evil[.]',
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
	tags                        => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'[*)]PSF is making Jython available to Licensee',
};

=item * kevlin_henney

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
	tags => [
		'type:versioned:decimal',
	],

	'_pat.alt.subject.name' => [
		"$the?$gnu?Library $gpl(?: \\(LGPL\\))?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?Lesser(?: \\(Library\\))? $gpl(?: \\(LGPL\\))?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?LIBRARY GENERAL PUBLIC LICEN[CS]E(?: \\(LGPL\\))?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the?$gnu?LESSER GENERAL PUBLIC LICEN[CS]E(?: \\(LGPL\\))?"
			. $RE{by_fsf}{'pat.alt.subject.trait'} . '?',
		"$the$gnu?LGPL",
		"${gnu}LGPL",
	],
};

$RE{lgpl_2} = {
	name                  => 'LGPL-2',
	'name.alt.misc.short' => 'LGPLv2',
	'name.alt.org.debian' => 'LGPL-2',
	'name.alt.org.gnu'    => 'LGPLv2.0',
	'name.alt.org.osi'    => 'LGPL-2.0',
	'name.alt.org.spdx'   => 'LGPL-2.0',
	caption => 'GNU Library General Public License, Version 2.0',
	'caption.alt.org.gnu' =>
		'GNU Library General Public License (LGPL) version 2.0',
	'caption.alt.org.osi' => 'GNU Library General Public License version 2',
	'caption.alt.org.osi.alt.list' =>
		'GNU Library General Public License, version 2',
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
	name    => 'LGPL-2-only',
	caption => 'GNU Library General Public License v2 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2:only',
	],
};

$RE{lgpl_2_or_later} = {
	name                  => 'LGPL-2-or-later',
	'name.alt.org.debian' => 'LGPL-2+',
	'name.alt.org.trove'  => 'LGPLv2+',
	caption               => 'GNU Library General Public License v2 or later',
	'caption.alt.org.trove' =>
		'GNU Library General Public License v2 or later (LGPLv2+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2:or_later',
	],
};

$RE{lgpl_2_1} = {
	name                           => 'LGPL-2.1',
	'name.alt.misc.short'          => 'LGPLv2.1',
	'name.alt.org.gnu'             => 'LGPLv2.1',
	'name.alt.org.osi'             => 'LGPL-2.1',
	'name.alt.org.perl'            => 'lgpl_2_1',
	'name.alt.org.spdx'            => 'LGPL-2.1',
	'name.alt.org.tldr.path.short' => 'lgpl2',
	caption => 'GNU Lesser General Public License, Version 2.1',
	'caption.alt.org.gnu' =>
		'GNU Lesser General Public License (LGPL) version 2.1',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v2 (LGPLv2)',
	'caption.alt.org.osi' => 'GNU Lesser General Public License version 2.1',
	'caption.alt.org.osi.alt.list' =>
		'GNU Lesser General Public License, version 2.1',
	'caption.alt.org.tldr' =>
		'GNU Lesser General Public License v2.1 (LGPL-2.1)',
	'caption.alt.misc.uppercase' => 'GNU LESSER GENERAL PUBLIC LICENSE',
	iri                  => 'https://www.gnu.org/licenses/lgpl-2.1.html',
	'iri.alt.format.txt' => 'https://www.gnu.org/licenses/lgpl-2.1.txt',
	tags                 => [
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
	name    => 'LGPL-2.1-only',
	caption => 'GNU Lesser General Public License v2.1 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2_1:only',
	],
};

$RE{lgpl_2_1_or_later} = {
	name                  => 'LGPL-2.1-or-later',
	'name.alt.org.debian' => 'LGPL-2.1+',
	'name.alt.org.trove'  => 'LGPLv2.1+',
	caption => 'GNU Lesser General Public License v2.1 or later',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v2.1 or later (LGPLv2.1+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_2_1:or_later',
	],
};

$RE{lgpl_3} = {
	name                           => 'LGPL-3',
	'name.alt.misc.short'          => 'LGPLv3',
	'name.alt.org.debian'          => 'LGPL-3',
	'name.alt.org.gnu'             => 'LGPLv3',
	'name.alt.org.osi'             => 'LGPL-3.0',
	'name.alt.org.perl'            => 'lgpl_3_0',
	'name.alt.org.spdx'            => 'LGPL-3.0',
	'name.alt.org.tldr.path.short' => 'lgpl-3.0',
	caption => 'GNU Lesser General Public License, Version 3',
	'caption.alt.org.gnu' =>
		'GNU Lesser General Public License (LGPL) version 3',
	'caption.alt.org.perl' =>
		'GNU Lesser General Public License, Version 3.0',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v3 (LGPLv3)',
	'caption.alt.org.osi' => 'GNU Lesser General Public License version 3',
	'caption.alt.org.osi.alt.list' =>
		'GNU Lesser General Public License, version 3',
	'caption.alt.org.tldr' =>
		'GNU Lesser General Public License v3 (LGPL-3.0)',
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
	name    => 'LGPL-3.0-only',
	caption => 'GNU Lesser General Public License v3.0 only',
	tags    => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_3:only',
	],
};

$RE{lgpl_3_or_later} = {
	name                  => 'LGPL-3.0-or-later',
	'name.alt.org.debian' => 'LGPL-3+',
	'name.alt.org.trove'  => 'LGPLv3+',
	caption => 'GNU Lesser General Public License v3.0 or later',
	'caption.alt.org.trove' =>
		'GNU Lesser General Public License v3 or later (LGPLv3+)',
	tags => [
		'family:gpl',
		'license:published:by_fsf',
		'type:usage:lgpl_3:or_later',
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
	tags => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{perm_granted}
		. $P{to_copy_prg}
		. "under the terms of $the${gnu}LGPL, "
		. $P{retain_copr_avail_orig}
		. '[.][  ]'
		. $P{repro_code_modcode_cite_copr_avail_note}
		. $P{and_used_by_perm} . '[ ]'
		. $P{perm_dist_mod}
		. $P{granted}
		. $P{retain_copr_avail_note}
		. $P{note_mod_inc} . '[.]',
	'pat.alt.subject.license.part.credit' => 'code must cite the Copyright',
};

=item * libpng

=cut

$RE{libpng} = {
	name                => 'Libpng',
	'name.alt.org.spdx' => 'Libpng',
	caption             => 'Libpng License',
	tags                => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_src_no_misrepresent}
		. '[.][  ]'
		. $P{altered_ver_mark}
		. '[.][  ]'
		. $P{copr_no_alter},
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
	tags                   => [
		'license:contains:license:lgpl_2_1',
		'type:unversioned',
	],
};

=item * lppl

=item * lppl_1

=item * lppl_1_1

=item * lppl_1_2

=item * lppl_1_3a

=item * lppl_1_3c

=cut

$RE{lppl} = {
	name                     => 'LPPL',
	'name.alt.org.wikidata'  => 'Q1050635',
	'name.alt.org.wikipedia' => 'LaTeX_Project_Public_License',
	caption                  => 'LaTeX Project Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{lppl_1} = {
	name                   => 'LPPL-1.0',
	'name.alt.org.spdx'    => 'LPPL-1.0',
	caption                => 'LaTeX Project Public License 1',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.0',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' => 'LPPL Version 1\.0 1999[-]03[-]01',
};

$RE{lppl_1_1} = {
	name                   => 'LPPL-1.1',
	'name.alt.org.spdx'    => 'LPPL-1.1',
	caption                => 'LaTeX Project Public License 1.1',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.1',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' => 'LPPL Version 1\.1 1999[-]07[-]10',
};

$RE{lppl_1_2} = {
	name                   => 'LPPL-1.2',
	'name.alt.org.spdx'    => 'LPPL-1.2',
	caption                => 'LaTeX Project Public License 1.2',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.2',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license' => 'LPPL Version 1\.2 1999[-]09[-]03',
};

$RE{lppl_1_3a} = {
	name                   => 'LPPL-1.3a',
	'name.alt.org.spdx'    => 'LPPL-1.3a',
	caption                => 'LaTeX Project Public License 1.3a',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.3a',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.3a',

	'pat.alt.subject.license' => 'LPPL Version 1\.3a 2004[-]10[-]01',
};

$RE{lppl_1_3c} = {
	name                   => 'LPPL-1.3c',
	'name.alt.org.osi'     => 'LPPL-1.3c',
	'name.alt.org.spdx'    => 'LPPL-1.3c',
	caption                => 'LaTeX Project Public License 1.3c',
	'caption.alt.org.spdx' => 'LaTeX Project Public License v1.3c',
	'caption.alt.org.tldr' =>
		'LaTeX Project Public License v1.3c (LPPL-1.3c)',
	iri  => 'https://www.latex-project.org/lppl.txt',
	tags => [
		'license:contains:grant',
		'type:singleversion:lppl',
	],
	licenseversion => '1.3c',

	'pat.alt.subject.license' => 'LPPL Version 1\.3c 2008[-]05[-]04',
};

=item * mit_advertising

=cut

$RE{mit_advertising} = {
	name                => 'MIT-advertising',
	'name.alt.org.spdx' => 'MIT-advertising',
	caption             => 'Enlightenment License (e16)',
	tags                => [
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
	'name.alt.org.debian' => 'MIT-CMU~warranty',
	caption               => 'CMU License (retain warranty disclaimer)',
	'caption.alt.org.fedora.web.mit' => 'Standard ML of New Jersey Variant',
	'caption.alt.org.fedora.web.mit.short' => 'MLton variant',
	description                            => <<'END',
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
	name                                => 'MIT-enna',
	'name.alt.org.fedora.web.mit.short' => 'enna',
	'name.alt.org.spdx'                 => 'MIT-enna',
	caption                             => 'enna License',
	'caption.alt.org.fedora.web.mit'    => 'enna variant',
	tags                                => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.section' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_sw}
		. $P{to_deal_the_sw_rights}
		. $P{to_mod_sublic_sw}
		. $P{and_to_perm_pers}
		. $P{subj_cond} . ':?[ ]'
		. $P{retain_copr_perm_sw_copr}
		. '[.][ ]'
		. $P{ack_pub_use_nosrc}
		. '[.][ ]'
		. 'This includes acknowledgments '
		. 'in either Copyright notices, Manuals, Publicity and Marketing documents '
		. 'or any documentation provided '
		. 'with any product containing this software[.][ ]'
		. $P{license_not_lib} . '[.]',
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
	tags                                => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.paragraph' => $P{perm_granted}
		. $P{free_charge}
		. $P{to_pers}
		. $P{the_sw}
		. $P{to_deal_the_sw_rights}
		. $P{to_mod_sublic_sw}
		. $P{and_to_perm_pers}
		. $P{subj_cond} . ':?[ ]'
		. $P{retain_copr_perm_sw_doc} . ' and '
		. $P{ack_doc_pkg_use} . '[.]',
};

=item * mit_new

=cut

$RE{mit_new} = {
	'name.alt.org.debian'            => 'Expat',
	'name.alt.org.fedora'            => 'MIT',
	'name.alt.org.osi'               => 'MIT',
	'name.alt.org.perl'              => 'mit',
	'name.alt.org.spdx'              => 'MIT',
	'name.alt.org.tldr'              => 'mit-license',
	'name.alt.org.tldr.path.short'   => 'mit',
	caption                          => 'MIT License',
	'caption.alt.org.debian'         => 'Expat License',
	'caption.alt.org.fedora.web.mit' => 'Modern Style with sublicense',
	'caption.alt.org.osi'            => 'The MIT License',
	'caption.alt.org.osi.alt.list'   => 'MIT license (MIT)',
	'caption.alt.org.perl'           => 'MIT (aka X11) License',
	'caption.alt.org.tldr'           => 'MIT License (Expat)',
	iri                     => 'http://www.jclark.com/xml/copying.txt',
	'iri.alt.org.wikipedia' => 'https://en.wikipedia.org/wiki/MIT_License',
	tags                    => [
		'family:mit',
		'license:is:grant',
		'license:published:by_james_clark',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' => $P{to_mod_sublic_sw}
		. '\b[^.]+\s+'
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
	'caption.alt.org.fedora.web.mit' => 'Old Style',
	description                      => <<'END',
Origin: Possibly by Jamie Zawinski in 1993 for xscreensaver.
END
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		'documentation[.][ ]No representations are made',
};

=item * mit_oldstyle_disclaimer

=cut

$RE{mit_oldstyle_disclaimer} = {
	'name.alt.org.debian'            => 'MIT~oldstyle~disclaimer',
	caption                          => 'MIT (Old Style, legal disclaimer)',
	'caption.alt.org.fedora.web.mit' => 'Old Style with legal disclaimer',
	tags                             => [
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
	'name.alt.org.debian' => 'MIT~oldstyle~permission',
	'caption.alt.org.fedora.web.mit' =>
		'Old Style (no advertising without permission)',
	tags => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{without_written_prior}
		. '[.][  ]'
		. $P{asis_name_sw},
};

=item * motosoto

=cut

$RE{motosoto} = {
	name                => 'Motosoto',
	'name.alt.org.osi'  => 'Motosoto',
	'name.alt.org.spdx' => 'Motosoto',
	caption             => 'Motosoto License',
	description         => <<'END',
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
		'MOTOSOTO OPEN SOURCE LICENSE [-] Version 0\.9\.1',
	'pat.alt.subject.license.part.intro' =>
		'This Motosoto Open Source License [(]the ["]License["][)]'
		. ' applies to ["]Community Portal Server["] and related software products',
	'pat.alt.subject.license.scope.multisection.part.7' =>
		'Versions of This License'
		. '[.][  ][*)]'
		. 'Version[.][ ]The Motosoto Open Source License is derived',
};

=item * mpl

=item * mpl_1

=item * mpl_1_1

=item * mpl_2

=cut

$RE{mpl} = {
	name                     => 'MPL',
	'name.alt.org.wikidata'  => 'Q308915',
	caption                  => 'Mozilla Public License',
	'name.alt.org.wikipedia' => 'Mozilla Public License',
	iri                      => 'https://www.mozilla.org/MPL',
	tags                     => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' => "$the?Mozilla Public Licen[cs]e"
		. '(?: \(["]?(?:[http://]mozilla.org/)?MPL["]?\))?'
		. "(?: (?:as )?published by $the\{0,2}Mozilla Foundation)?",
};

$RE{mpl_1} = {
	name                     => 'MPL-1.0',
	'name.alt.org.perl'      => 'mozilla_1_0',
	caption                  => 'Mozilla Public License 1.0',
	'caption.alt.org.perl'   => 'Mozilla Public License, Version 1.0',
	'caption.alt.misc.trove' => 'Mozilla Public License 1.0 (MPL)',
	tags                     => [
		'type:singleversion:mpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'MOZILLA PUBLIC LICENSE[ ]Version 1\.0[  ]' . '[*)]Definitions',
};

$RE{mpl_1_1} = {
	name                     => 'MPL-1.1',
	'name.alt.org.perl'      => 'mozilla_1_1',
	caption                  => 'Mozilla Public License 1.1',
	'caption.alt.org.perl'   => 'Mozilla Public License, Version 1.1',
	'caption.alt.misc.trove' => 'Mozilla Public License 1.1 (MPL 1.1)',
	tags                     => [
		'type:singleversion:mpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'Mozilla Public License Version 1\.1[  ]' . '[*)]Definitions',
};

$RE{mpl_2} = {
	name                     => 'MPL-2.0',
	caption                  => 'Mozilla Public License 2.0',
	'caption.alt.misc.trove' => 'Mozilla Public License 2.0 (MPL 2.0)',
	tags                     => [
		'type:singleversion:mpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'Mozilla Public License Version 2\.0[  ]' . '[*)]Definitions',
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
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multiparagraph' =>
		'Microsoft Public License \(Ms-PL\)[  ]This license governs use',
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
	tags => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.part.3a' =>
		'Reciprocal Grants[-] For any file you distribute that contains code',
	'pat.alt.subject.license.scope.multiparagraph' =>
		'Microsoft Reciprocal License \(Ms[-]RL\)[  ]This license governs use',
};

=item * mulan

=item * mulan_1

=item * mulan_2

=cut

$RE{mulan} = {
	name          => 'MulanPSL',
	caption       => 'Mulan Permissive Software License',
	'caption(zh)' => '木兰宽松许可证',
	tags          => [
		'type:versioned:decimal',
	],
};

$RE{mulan_1} = {
	name                => 'MulanPSL-1',
	'name.alt.org.spdx' => 'MulanPSL-1.0',
	caption             => 'Mulan Permissive Software License, Version 1',
	'caption(zh)'       => '木兰宽松许可证， 第1版',
	'caption.alt.misc.shortname' => 'Mulan PSL v1',
	iri                          => 'https://license.coscl.org.cn/MulanPSL',
	tags                         => [
		'license:contains:grant',
		'type:singleversion:mulan',
	],
	licenseversion => '1',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		'Your reproduction, use, modification and distribution'
		. ' of the Software'
		. ' shall be subject to Mulan PSL v1 [(]this License[)]'
		. ' with following',
	'pat.alt.subject.license.scope.sentence.part.intro(zh)' =>
		'您对["]软件["]的复制[, ]使用'
		. '[, ]修改及分发受木兰宽松许可证[, ]第1版[(]["]本许可证["][)]'
		. '的如下条款的约束',
	'pat.alt.subject.license.scope.multisection.part.grant' =>
		'[*]Software Name[*] is licensed under the Mulan PSL v1[.][ ]'
		. 'You can use this software'
		. ' according to the terms and conditions of the Mulan PSL v1'
};

$RE{mulan_2} = {
	name                  => 'MulanPSL-2',
	'name.alt.org.spdx'   => 'MulanPSL-2.0',
	caption               => 'Mulan Permissive Software License, Version 2',
	'caption(zh)'         => '木兰宽松许可证， 第2版',
	'caption.alt.org.osi' => 'Mulan Permissive Software License v2',
	'caption.alt.misc.shortname' => 'Mulan PSL v2',
	iri                          => 'https://license.coscl.org.cn/MulanPSL2',
	tags                         => [
		'license:contains:grant',
		'type:singleversion:mulan',
	],
	licenseversion => '2',

	'pat.alt.subject.license.scope.sentence.part.intro' =>
		'Your reproduction, use, modification and distribution'
		. ' of the Software'
		. ' shall be subject to Mulan PSL v2 [(]this License[)]'
		. ' with the following terms and conditions',
	'pat.alt.subject.license.scope.sentence.part.intro(zh)' =>
		'您对["]软件["]的复制[, ]使用'
		. '[, ]修改及分发受木兰宽松许可证[, ]第2版[(]["]本许可证["][)]'
		. '的如下条款的约束',
	'pat.alt.subject.license.scope.multisection.part.grant' =>
		'[*]Software Name[*] is licensed under Mulan PSL v2[.][ ]'
		. 'You can use this software'
		. ' according to the terms and conditions of the Mulan PSL v2',
};

=item * ngpl

=cut

$RE{ngpl} = {
	name                   => 'NGPL',
	'name.alt.org.spdx'    => 'NGPL',
	caption                => 'Nethack General Public License',
	'caption.alt.org.tldr' => 'Nethack General Public License (NGPL)',
	'iri.alt.org.osi'      => 'https://opensource.org/licenses/NGPL',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'You may copy and distribute verbatim copies of NetHack',
};

=item * npl

=item * npl_1

=item * npl_1_1

=cut

$RE{npl} = {
	name                     => 'NPL',
	'name.alt.org.wikidata'  => 'Q2306611',
	'name.alt.org.wikipedia' => 'Netscape_Public_License',
	caption                  => 'Netscape Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{npl_1} = {
	name                   => 'NPL-1.0',
	'name.alt.org.spdx'    => 'NPL-1.0',
	caption                => 'Netscape Public License version 1.0',
	'caption.alt.org.spdx' => 'Netscape Public License v1.0',
	iri =>
		'https://website-archive.mozilla.org/www.mozilla.org/mpl/MPL/NPL/1.0/',
	tags => [
		'type:singleversion:npl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multiparagraph' =>
		'NETSCAPE PUBLIC LICENSE[ ]Version 1\.0[  ][*)]Definitions[.]',
};

$RE{npl_1_1} = {
	name                   => 'NPL-1.1',
	'name.alt.org.spdx'    => 'NPL-1.1',
	caption                => 'Netscape Public License version 1.1',
	'caption.alt.org.spdx' => 'Netscape Public License v1.1',
	iri =>
		'https://website-archive.mozilla.org/www.mozilla.org/mpl/MPL/NPL/1.1/',
	tags => [
		'type:singleversion:npl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'The Netscape Public License Version 1\.1 \(["]NPL["]\) consists of',
};

=item * ntp

=cut

$RE{ntp} = {
	name                   => 'NTP',
	'name.alt.org.osi'     => 'NTP',
	'name.alt.org.spdx'    => 'NTP',
	caption                => 'NTP License',
	'caption.alt.org.tldr' => 'NTP License (NTP)',
	tags                   => [
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
		. '[.][ ]'
		. $P{discl_name_warranties},
};

=item * oclc

=item * oclc_1

=item * oclc_2

=cut

$RE{oclc} = {
	name    => 'OCLC',
	caption => 'OCLC Research Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{oclc_1} = {
	name    => 'OCLC-1.0',
	caption => 'OCLC Research Public License 1.0',
	tags    => [
		'type:singleversion:oclc',
	],

	'pat.alt.subject.license' =>
		'If you distribute the Program or any derivative work of',
};

$RE{oclc_2} = {
	name                   => 'OCLC-2.0',
	'name.alt.org.osi'     => 'OCLC-2.0',
	'name.alt.org.spdx'    => 'OCLC-2.0',
	caption                => 'OCLC Research Public License 2.0',
	'caption.alt.org.tldr' => 'OCLC Research Public License 2.0 (OCLC-2.0)',
	tags                   => [
		'type:singleversion:oclc',
	],

	'pat.alt.subject.license' =>
		'The Program must be distributed without charge beyond',
};

=item * ofl

=item * ofl_1

=item * ofl_1_no_rfn

=item * ofl_1_rfn

=item * ofl_1_1

=item * ofl_1_1_no_rfn

=item * ofl_1_1_rfn

=cut

$RE{ofl} = {
	name                       => 'OFL',
	caption                    => 'SIL Open Font License',
	'caption.alt.misc.shorter' => 'Open Font License',
	iri                        => 'http://scripts.sil.org/OFL',
	tags                       => [
		'type:versioned:decimal',
	],
};

$RE{ofl_1} = {
	name    => 'OFL-1.0',
	caption => 'SIL Open Font License 1.0',
	tags    => [
		'type:singleversion:ofl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'["]Font Software["] refers to any and all of the following',
};

$RE{ofl_1_no_rfn} = {
	name        => 'OFL-1.0-no-RFN',
	caption     => 'SIL Open Font License 1.0 with no Reserved Font Name',
	description => <<'END',
Usage: Should only be used when there is no Reserved Font Name.
END
	tags => [
		'type:usage:ofl_1:no_rfn',
	],
};

$RE{ofl_1_rfn} = {
	name        => 'OFL-1.0-RFN',
	caption     => 'SIL Open Font License 1.0 with Reserved Font Name',
	description => <<'END',
Usage: Should only be used when a Reserved Font Name applies.
END
	tags => [
		'type:usage:ofl_1:rfn',
	],
};

$RE{ofl_1_1} = {
	name    => 'OFL-1.1',
	caption => 'SIL Open Font License 1.1',
	tags    => [
		'type:singleversion:ofl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license' =>
		'["]Font Software["] refers to the set of files released',
};

$RE{ofl_1_1_no_rfn} = {
	name        => 'OFL-1.1-no-RFN',
	caption     => 'SIL Open Font License 1.1 with no Reserved Font Name',
	description => <<'END',
Usage: Should only be used when there is no Reserved Font Name.
END
	tags => [
		'type:usage:ofl_1_1:no_rfn',
	],
};

$RE{ofl_1_1_rfn} = {
	name        => 'OFL-1.1-RFN',
	caption     => 'SIL Open Font License 1.1 with Reserved Font Name',
	description => <<'END',
Usage: Should only be used when a Reserved Font Name applies.
END
	tags => [
		'type:usage:ofl_1_1:rfn',
	],
};

=item * ogtsl

=cut

$RE{ogtsl} = {
	name                   => 'OGTSL',
	'name.alt.org.osi'     => 'OGTSL',
	'name.alt.org.spdx'    => 'OGTSL',
	caption                => 'Open Group Test Suite License',
	'caption.alt.org.tldr' => 'Open Group Test Suite License (OGTSL)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'rename any non-standard executables and testcases',
};

=item * oldap

=item * oldap_1_1

=item * oldap_1_2

=item * oldap_1_3

=item * oldap_1_4

=item * oldap_2

=item * oldap_2_0_1

=item * oldap_2_1

=item * oldap_2_2

=item * oldap_2_2_1

=item * oldap_2_2_2

=item * oldap_2_3

=item * oldap_2_4

=item * oldap_2_5

=item * oldap_2_6

=item * oldap_2_7

=item * oldap_2_8

=cut

$RE{oldap} = {
	name    => 'OLDAP',
	caption => 'Open LDAP Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{oldap_1_1} = {
	name                => 'OLDAP-1.1',
	'name.alt.org.spdx' => 'OLDAP-1.1',
	caption             => 'Open LDAP Public License v1.1',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.1, 25 August 1998',
	'pat.alt.subject.license.part.intro' =>
		' as distributed with the Perl Programming Language'
		. '[.][ ]Its terms are different from those of the ["]Artistic License[.]["]',
};

$RE{oldap_1_2} = {
	name                => 'OLDAP-1.2',
	'name.alt.org.spdx' => 'OLDAP-1.2',
	caption             => 'Open LDAP Public License v1.2',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.2, 1 September 1998',
};

$RE{oldap_1_3} = {
	name                => 'OLDAP-1.3',
	'name.alt.org.spdx' => 'OLDAP-1.3',
	caption             => 'Open LDAP Public License v1.3',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.3, 17 January 1999',
	'pat.alt.subject.license.part.8' =>
		' and do not automatically fall under the copyright of this Package'
		. ', and the executables produced by linking',
};

$RE{oldap_1_4} = {
	name                => 'OLDAP-1.4',
	'name.alt.org.spdx' => 'OLDAP-1.4',
	caption             => 'Open LDAP Public License v1.4',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '1.4',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 1\.4, 18 January 1999',
	'pat.alt.subject.license.part.8' =>
		' and do not automatically fall under the copyright of this Package'
		. '[.][ ]Executables produced by linking',
};

$RE{oldap_2} = {
	name                => 'OLDAP-2.0',
	'name.alt.org.spdx' => 'OLDAP-2.0',
	caption             => 'Open LDAP Public License v2',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.0, 7 June 1999',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]OpenLDAP is a registered trademark of the OpenLDAP Foundation',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.] Redistributions must also contain a copy of this document'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' the above copyright notice'
		. ', this list of conditions'
		. ' and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]For written permission, please contact foundation\@openldap.org'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]OpenLDAP is a registered trademark of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)]'
		. '[.][  ]THIS SOFTWARE IS PROVIDED BY THE OPENLDAP FOUNDATION AND'
};

$RE{oldap_2_0_1} = {
	name                => 'OLDAP-2.0.1',
	'name.alt.org.spdx' => 'OLDAP-2.0.1',
	caption             => 'Open LDAP Public License v2.0.1',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.0.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.0\.1, 21 December 1999',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.] Redistributions must also contain a copy of this document'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' the above copyright notice'
		. ', this list of conditions'
		. ' and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]For written permission, please contact foundation\@openldap.org'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]OpenLDAP is a trademark of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)]'
		. '[.][  ]THIS SOFTWARE IS PROVIDED BY THE OPENLDAP FOUNDATION AND'
};

$RE{oldap_2_1} = {
	name                => 'OLDAP-2.1',
	'name.alt.org.spdx' => 'OLDAP-2.1',
	caption             => 'Open LDAP Public License v2.1',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.1, 29 February 2000',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent license revision[.]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][ ]Redistributions must also contain a copy of this document'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' the above copyright notice'
		. ', this list of conditions'
		. ' and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]For written permission, please contact foundation\@openldap.org'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][ ]OpenLDAP is a trademark of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(]http://www.openldap.org[/][)]'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent license revision[.]',
};

$RE{oldap_2_2} = {
	name                => 'OLDAP-2.2',
	'name.alt.org.spdx' => 'OLDAP-2.2',
	caption             => 'Open LDAP Public License v2.2',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2, 1 March 2000',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][ ]Redistributions must also contain a copy of this document'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' the above copyright notice'
		. ', this list of conditions'
		. ' and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)]'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent the license[.]',
};

$RE{oldap_2_2_1} = {
	name                => 'OLDAP-2.2.1',
	'name.alt.org.spdx' => 'OLDAP-2.2.1',
	caption             => 'Open LDAP Public License v2.2.1',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2\.1, 1 March 2000',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][ ]Redistributions must also contain a copy of this document'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' the above copyright notice'
		. ', this list of conditions'
		. ' and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(]http://www.openldap.org[/][)]'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_2_2} = {
	name                => 'OLDAP-2.2.2',
	'name.alt.org.spdx' => 'OLDAP-2.2.2',
	caption             => 'Open LDAP Public License v2.2.2',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.2.2',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.2\.2, 28 July 2000',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)][.]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)]'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_3} = {
	name                => 'OLDAP-2.3',
	'name.alt.org.spdx' => 'OLDAP-2.3',
	caption             => 'Open LDAP Public License v2.3',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.3',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.3, 28 July 2000',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)][.]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document'
		. '[.][  ][*)]'
		. 'The name ["]OpenLDAP["] must not be used'
		. ' to endorse or promote products derived from this Software'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Products derived from this Software may not be called ["]OpenLDAP["]'
		. ' nor may ["]OpenLDAP["] appear in their names'
		. ' without prior written permission of the OpenLDAP Foundation'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. ' [(][http://]www.openldap.org[/][)]'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_4} = {
	name                => 'OLDAP-2.4',
	'name.alt.org.spdx' => 'OLDAP-2.4',
	caption             => 'Open LDAP Public License v2.4',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.4',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.4, 8 December 2000',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'Due credit should be given to the OpenLDAP Project[.]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document'
		. '[.][  ][*)]'
		. 'The names and trademarks of the authors and copyright holders'
		. ' must not be used in advertising or otherwise'
		. ' to promote the sale, use or other dealing in this Software'
		. ' without specific, written prior permission'
		. '[.][  ][*)]'
		. 'Due credit should be given to the OpenLDAP Project'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_5} = {
	name                => 'OLDAP-2.5',
	'name.alt.org.spdx' => 'OLDAP-2.5',
	caption             => 'Open LDAP Public License v2.5',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.5',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.5, 11 May 2001',
	'pat.alt.subject.license.scope.multisection.part.clauses_minimal' =>
		'Due credit should be given to the authors of the Software'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document'
		. '[.][  ][*)]'
		. 'The names and trademarks of the authors and copyright holders'
		. ' must not be used in advertising'
		. ' or otherwise to promote the sale, use or other dealing in this Software'
		. ' without specific, written prior permission'
		. '[.][  ][*)]'
		. 'Due credit should be given to the authors of the Software'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_6} = {
	name                => 'OLDAP-2.6',
	'name.alt.org.spdx' => 'OLDAP-2.6',
	caption             => 'Open LDAP Public License v2.6',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.6',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.6, 14 June 2001',
	'pat.alt.subject.license.scope.multisection.part.clauses_minimal' =>
		' without specific, written prior permission'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions of source code must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. '[.][  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document'
		. '[.][  ][*)]'
		. 'The names and trademarks of the authors and copyright holders'
		. ' must not be used in advertising'
		. ' or otherwise to promote the sale, use or other dealing in this Software'
		. ' without specific, written prior permission'
		. '[.][  ][*)]'
		. 'The OpenLDAP Foundation may revise this license from time to time'
		. '[.][ ]'
		. 'Each revision is distinguished by a version number'
		. '[.][ ]'
		. 'You may use the Software under terms of this license revision'
		. ' or under the terms of any subsequent revision of the license[.]',
};

$RE{oldap_2_7} = {
	name                => 'OLDAP-2.7',
	'name.alt.org.spdx' => 'OLDAP-2.7',
	caption             => 'Open LDAP Public License v2.7',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.7',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.7, 7 September 2001',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'[*)]Redistributions in source form must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions in source form must retain'
		. ' copyright statements and notices'
		. ',[  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and[/]or other materials'
		. ' provided with the distribution'
		. ', and[  ][*)]'
		. 'Redistributions must contain a verbatim copy'
		. ' of this document[.]',
};

$RE{oldap_2_8} = {
	name                => 'OLDAP-2.8',
	'name.alt.org.spdx' => 'OLDAP-2.8',
	caption             => 'Open LDAP Public License v2.8',
	tags                => [
		'type:singleversion:oldap',
	],
	licenseversion => '2.8',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'The OpenLDAP Public License[  ]Version 2\.8, 17 August 2003',
	'pat.alt.subject.license.part.clauses_minimal' =>
		'[*)]Redistributions in source form must retain'
		. ' copyright statements and notices[.][  ]',
	'pat.alt.subject.license.scope.multisection.part.clauses' =>
		'[*)]Redistributions in source form must retain'
		. ' copyright statements and notices'
		. '[.][  ][*)]'
		. 'Redistributions in binary form must reproduce'
		. ' applicable copyright statements and notices'
		. ', this list of conditions'
		. ', and the following disclaimer'
		. ' in the documentation and/or other materials'
		. ' provided with the distribution'
		. ', and[  ][*)]'
		. 'Redistributions must contain a verbatim copy of this document[.]',
};

=item * openssl

=cut

$RE{openssl} = {
	name                   => 'OpenSSL',
	'name.alt.org.perl'    => 'openssl',
	'name.alt.org.spdx'    => 'OpenSSL',
	caption                => 'OpenSSL License',
	'caption.alt.org.tldr' => 'OpenSSL License (OpenSSL)',
	tags                   => [
		'license:contains:license:cryptix',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' => $P{redist_ack_this}
		. 'the OpenSSL Project for use in the OpenSSL Toolkit \([http://]www\.openssl\.org/\)["][  ]'
		. 'THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ["]AS IS["]'
		. ' AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED[.]'
		. ' IN NO EVENT SHALL THE OpenSSL PROJECT OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES'
		. ' \(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\)'
		. ' HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT \(INCLUDING NEGLIGENCE OR OTHERWISE\)'
		. ' ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE[.][  ]'
		. 'This product includes cryptographic software written by Eric Young \(eay[@]cryptsoft\.com\)[.][ ]'
		. 'This product includes software written by Tim Hudson \(tjh[@]cryptsoft\.com\)[.][  ]'
};

=item * osl

=item * osl_1

=item * osl_1_1

=item * osl_2

=item * osl_2_1

=item * osl_3

=cut

$RE{osl} = {
	name    => 'OSL',
	caption => 'Open Software License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{osl_1} = {
	name                => 'OSL-1.0',
	'name.alt.org.spdx' => 'OSL-1.0',
	caption             => 'Open Software License 1.0',
	tags                => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection' =>
		'["]Licensed under the Open Software License version 1\.0["][  ]'
		. 'License Terms'
};

$RE{osl_1_1} = {
	name                => 'OSL-1.1',
	'name.alt.org.spdx' => 'OSL-1.1',
	caption             => 'Open Software License 1.1',
	tags                => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection' =>
		'Licensed under the Open Software License version 1\.1[  ]'
		. '[*)]Grant of Copyright License[.]'
};

$RE{osl_2} = {
	name                => 'OSL-2.0',
	'name.alt.org.spdx' => 'OSL-2.0',
	caption             => 'Open Software License 2.0',
	tags                => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'Licensed under the Open Software License version 2\.0[  ]'
		. '[*)]Grant of Copyright License[.]',
	'pat.alt.subject.license.scope.multisection.part.10' =>
		'its terms and conditions[.][  ]'
		. 'This License shall terminate immediately '
		. 'and you may no longer exercise '
		. 'any of the rights granted to You by this License '
		. 'upon Your failure to honor the proviso '
		. 'in Section 1\(c\) herein[.][  ]'
		. $termination_for_patent_including_counterclaim
		. ' for patent infringement',
};

$RE{osl_2_1} = {
	name                => 'OSL-2.1',
	'name.alt.org.spdx' => 'OSL-2.1',
	caption             => 'Open Software License 2.1',
	tags                => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '2.1',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'Licensed under the Open Software License version 2\.1[  ]'
		. '[*)]Grant of Copyright License[.]'
};

$RE{osl_3} = {
	name                   => 'OSL-3.0',
	'name.alt.org.osi'     => 'OSL-3.0',
	'name.alt.org.spdx'    => 'OSL-3.0',
	caption                => 'Open Software License 3.0',
	'caption.alt.org.tldr' => 'Open Software Licence 3.0',
	tags                   => [
		'license:contains:grant',
		'type:singleversion:osl',
	],
	licenseversion => '3.0',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'Licensed under the Open Software License version 3\.0[  ]'
		. '[*)]Grant of Copyright License[.]'
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
	tags                             => [
		'family:mit',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license' => $P{permission_use_fee_agree},
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
	tags                => [
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.name' =>
		"$the?(?:[Pp]ublic|PUBLIC)[- ](?:[Dd]omain|DOMAIN)",
};
$RE{public_domain}{'_pat.alt.subject.grant'} = [
	"(?:[Tt]his is|[Tt]hey are|[Ii]t[']s) in "
		. $RE{public_domain}{'pat.alt.subject.name'},
	'(?:[Tt]his|[Tt]he) +(?:(?:source )?code|document|file|library|macros|opening book|work) +is(?: put)?(?: in)? '
		. $RE{public_domain}{'pat.alt.subject.name'},
	'are dedicated to ' . $RE{public_domain}{'pat.alt.subject.name'},
	'for use in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'placed in(?:to)? ' . $RE{public_domain}{'pat.alt.subject.name'},
	'considered to be in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'offered to use in ' . $RE{public_domain}{'pat.alt.subject.name'},
	'provided ["]as[- ]is["] into '
		. $RE{public_domain}{'pat.alt.subject.name'},
	'released to ' . $RE{public_domain}{'pat.alt.subject.name'},
	'RELEASED INTO ' . $RE{public_domain}{'pat.alt.subject.name'},
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
	tags                        => [
		'type:versioned:decimal',
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
		'license:contains:license:cnri_python',
		'license:published:by_psf',
		'type:singleversion:python',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license' =>
		'[*)]PSF is making Python available to Licensee',
};

=item * qpl

=item * qpl_1

=cut

$RE{qpl} = {
	name                        => 'QPL',
	caption                     => 'Q Public License',
	'caption.alt.org.trove'     => 'Qt Public License (QPL)',
	'caption.alt.org.wikipedia' => 'Q Public License',
	tags                        => [
		'type:versioned:decimal',
	],
};

$RE{qpl_1} = {
	name                    => 'QPL-1.0',
	'name.alt.org.perl'     => 'qpl_1_0',
	'name.alt.org.wikidata' => 'Q1396282',
	caption                 => 'Q Public License 1.0',
	'caption.alt.org.gnu'   => 'Q Public License (QPL), Version 1.0',
	'caption.alt.org.perl'  => 'Q Public License, Version 1.0',
	'caption.alt.org.tldr'  => 'Q Public License 1.0 (QPL-1.0)',
	tags                    => [
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
	name                     => 'RPL',
	'name.alt.org.wikidata'  => 'Q7302458',
	'name.alt.org.wikipedia' => 'Reciprocal_Public_License',
	caption                  => 'Reciprocal Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{rpl_1} = {
	name    => 'RPL-1',
	caption => 'Reciprocal Public License, Version 1.0',
	'iri.alt.archive.20020223190112' =>
		'http://www.technicalpursuit.com/Biz_RPL.html',
	tags => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'This Reciprocal Public License Version 1\.0 \(["]License["]\) applies to any programs'
};

$RE{rpl_1_1} = {
	name                => 'RPL-1.1',
	'name.alt.org.osi'  => 'RPL-1.1',
	'name.alt.org.spdx' => 'RPL-1.1',
	caption             => 'Reciprocal Public License, Version 1.1',
	tags                => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'This Reciprocal Public License Version 1\.1 \(["]License["]\) applies to any programs'
};

$RE{rpl_1_3} = {
	name    => 'RPL-1.3',
	caption => 'Reciprocal Public License, Version 1.3',
	'iri.alt.archive.20080828191234' =>
		'http://www.technicalpursuit.com/licenses/RPL_1.3.html',
	tags => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.3',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'This Reciprocal Public License Version 1\.3 \(["]License["]\) applies to any programs'
};

$RE{rpl_1_5} = {
	name                   => 'RPL-1.5',
	'name.alt.org.osi'     => 'RPL-1.5',
	'name.alt.org.spdx'    => 'RPL-1.5',
	caption                => 'Reciprocal Public License, Version 1.5',
	'caption.alt.org.osi'  => 'Reciprocal Public License 1.5',
	'caption.alt.org.tldr' => 'Reciprocal Public License 1.5 (RPL-1.5)',
	tags                   => [
		'type:singleversion:rpl',
	],
	licenseversion => '1.5',

	'pat.alt.subject.license.scope.multisection.part.1' =>
		'This Reciprocal Public License Version 1\.5 \(["]License["]\) applies to any programs'
};

=item * rpsl

=item * rpsl_1

=cut

$RE{rpsl} = {
	name                        => 'RPSL',
	'name.alt.org.wikidata'     => 'Q7300815',
	caption                     => 'RealNetworks Public Source License',
	'caption.alt.org.wikipedia' => 'RealNetworks Public Source License',
	tags                        => [
		'type:versioned:decimal',
	],
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
		'General Definitions[.] This License applies to any program or other work',
};

=item * ruby

=cut

$RE{ruby} = {
	name                   => 'Ruby',
	caption                => 'Ruby License',
	'caption.alt.org.tldr' => 'Ruby License (Ruby)',
	tags                   => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'You may modify and include the part of the software into any',
};

=item * rscpl

=cut

$RE{rscpl} = {
	name                => 'RSCPL',
	'name.alt.org.osi'  => 'RSCPL',
	'name.alt.org.spdx' => 'RSCPL',
	caption             => 'Ricoh Source Code Public License',
	tags                => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.sentence' =>
		'Endorsements[.] The names ["]Ricoh,["] ["]Ricoh Silicon Valley,["] and ["]RSV["] must not'
};

=item * sgi_b

=item * sgi_b_1

=item * sgi_b_1_1

=item * sgi_b_2

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
	name    => 'SGI-B-1.0',
	caption => 'SGI Free Software License B v1.0',
	tags    => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license.scope.line.scope.paragraph' =>
		'License Grant[.] Subject to the provisions',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[ ]\(Version 1\.0 1[/]25[/]2000\)[  ]'
		. '[*)]Definitions[.]',
};

$RE{sgi_b_1_1} = {
	name    => 'SGI-B-1.1',
	caption => 'SGI Free Software License B v1.1',
	tags    => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.part.title' => 'SGI License Grant',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[ ]\(Version 1\.1 02[/]22[/]2000\)[  ]'
		. '[*)]Definitions[.]',
};

$RE{sgi_b_2} = {
	name    => 'SGI-B-2.0',
	caption => 'SGI Free Software License B v2.0',
	tags    => [
		'type:singleversion:sgi_b',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.part.reproduction' =>
		'The above copyright notice including the dates of first publication',
	'pat.alt.subject.license.scope.multiparagraph.part.head' =>
		'SGI FREE SOFTWARE LICENSE B[  ]'
		. '\(Version 2\.0, Sept\. 18, 2008\) '
		. 'Copyright [c] \[dates of first publication\] Silicon Graphics, Inc\. '
		. 'All Rights Reserved[.][  ]'
		. $P{perm_granted},
};

=item * sissl

=item * sissl_1_1

=item * sissl_1_2

=cut

$RE{sissl} = {
	name                     => 'SISSL',
	'name.alt.org.perl'      => 'sun',
	'name.alt.org.wikipedia' => 'Sun_Industry_Standards_Source_License',
	'name.alt.org.wikidata'  => 'Q635577',
	caption                  => 'Sun Industry Standards Source License',
	'caption.alt.org.perl' => 'Sun Internet Standards Source License (SISSL)',
	'caption.alt.misc.long' =>
		'Sun Industry Standards Source License (SISSL)',
	tags => [
		'type:versioned:decimal',
	],
};

$RE{sissl_1_1} = {
	name                => 'SISSL-1.1',
	'name.alt.org.spdx' => 'SISSL',
	caption => 'Sun Industry Standards Source License - Version 1.1',
	iri     => 'https://www.openoffice.org/licenses/sissl_license.html',
	tags    => [
		'type:singleversion:sissl',
	],
	licenseversion => '1.1',

	'pat.alt.subject.license.scope.multisection.part.header' =>
		'Sun Industry Standards Source License [-] Version 1\.1[  ]'
		. '1\.0 DEFINITIONS',
};

$RE{sissl_1_2} = {
	name                => 'SISSL-1.2',
	'name.alt.org.osi'  => 'SISSL',
	'name.alt.org.spdx' => 'SISSL-1.2',
	caption => 'SUN INDUSTRY STANDARDS SOURCE LICENSE Version 1.2',
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

=item * spl

=item * spl_1

=cut

$RE{spl} = {
	name                     => 'SPL',
	'name.alt.org.wikidata'  => 'Q648252',
	'name.alt.org.wikipedia' => 'Sun_Public_License',
	caption                  => 'Sun Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{spl_1} = {
	name                   => 'SPL-1.0',
	'name.alt.org.spdx'    => 'SPL-1.0',
	'name.alt.org.osi'     => 'SPL-1.0',
	caption                => 'Sun Public License 1.0',
	'caption.alt.org.tldr' => 'Sun Public License v1.0 (SPL-1.0)',
	tags                   => [
		'type:singleversion:spl',
	],

	'pat.alt.subject.license.scope.multisection' =>
		'Exhibit A -Sun Public License Notice[.][  ]'
		. 'The contents of this file are subject to the Sun Public License'
};

=item * ssleay

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

=item * sugarcrm

=item * sugarcrm_1_1_3

=cut

$RE{sugarcrm} = {
	name    => 'SugarCRM',
	caption => 'SugarCRM Public License',
	tags    => [
		'type:versioned:decimal',
	],
};

$RE{sugarcrm_1_1_3} = {
	name                           => 'SugarCRM-1.1.3',
	'name.alt.org.tldr.path.short' => 'sugarcrm-1.1.3',
	caption                        => 'SugarCRM Public License v1.1.3',
	'caption.alt.org.tldr' =>
		'SugarCRM Public License v1.1.3 (SugarCRM-1.1.3)',
	tags => [
		'type:singleversion:sugarcrm',
	],
	licenseversion => '1.1.3',

	'pat.alt.subject.license' =>
		'The SugarCRM Public License Version \(["]SPL["]\) consists of',
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
	name                => 'Unicode-TOU',
	'name.alt.org.spdx' => 'Unicode-TOU',
	caption             => 'Unicode Terms of Use',
	tags                => [
		'type:unversioned',
	],

	'pat.alt.subject.license' =>
		'distribute all documents and files solely for informational',
};

=item * unlicense

=cut

$RE{unlicense} = {
	name                    => 'Unlicense',
	'name.alt.org.spdx'     => 'Unlicense',
	'iri.alt.org.wikidata'  => 'Q21659044',
	'iri.alt.org.wikipedia' => 'Unlicense',
	caption                 => 'the Unlicense',
	'caption.alt.org.tldr'  => 'Unlicense',
	iri                     => 'https://unlicense.org/',
	'iri.alt.format.txt'    => 'https://unlicense.org/UNLICENSE',
	tags                    => [
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.line.scope.sentence' =>
		'This is free and unencumbered software released into the public domain',
};

=item * watcom

=item * watcom_1

=cut

$RE{watcom} = {
	name                     => 'Watcom',
	'name.alt.org.wikidata'  => 'Q7659488',
	'name.alt.org.wikipedia' => 'Sybase_Open_Watcom_Public_License',
	caption                  => 'Sybase Open Watcom Public License',
	tags                     => [
		'type:versioned:decimal',
	],
};

$RE{watcom_1} = {
	name                => 'Watcom-1.0',
	'name.alt.org.osi'  => 'Watcom-1.0',
	'name.alt.org.spdx' => 'Watcom-1.0',
	'name.alt.org.tldr' =>
		'sybase-open-watcom-public-license-1.0-(watcom-1.0)',
	caption => 'Sybase Open Watcom Public License 1.0',
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
	tags                       => [
		'type:versioned:decimal',
	],

	'pat.alt.subject.name' =>
		"$the?[Dd]o What The F(?:u|[*])ck [Yy]ou [Ww]ant(?: [Tt]o)? Public License"
		. '(?: \(WTFPL\))?',
	'pat.alt.subject.license.scope.sentence' =>
		'[Yy]ou just[  ]DO WHAT THE FUCK YOU WANT TO[.]',
};

$RE{wtfpl_1} = {
	name    => 'WTFPL-1.0',
	caption => 'Do What The Fuck You Want To Public License, Version 1',
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
	name                           => 'WTFPL-2',
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

=item * wtfnmfpl_1

=cut

$RE{wtfnmfpl} = {
	name => 'WTFNMFPL',
	'caption.alt.org.tldr' =>
		"Do What The Fuck You Want To But It's Not My Fault Public License v1 (WTFNMFPL-1.0)",
	tags => [
		'type:versioned:decimal',
	],
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
	tags                 => [
		'license:is:grant',
		'type:singleversion:wtfnmfpl',
	],
	licenseversion => '1.0',

	'pat.alt.subject.license' =>
		'Do not hold the author\(s\), creator\(s\), developer\(s\) or distributor\(s\)',
};

=item * zlib

=cut

$RE{zlib} = {
	name                                  => 'Zlib',
	'name.alt.org.fsf'                    => 'Zlib',
	'name.alt.org.osi'                    => 'Zlib',
	'name.alt.org.perl'                   => 'zlib',
	'name.alt.org.spdx'                   => 'Zlib',
	'name.alt.org.tldr.path.short'        => 'zlib',
	'name.alt.org.wikidata'               => 'Q207243',
	caption                               => 'zlib/libpng license',
	'caption.alt.org.osi'                 => 'The zlib/libpng License',
	'caption.alt.org.perl'                => 'zlib License',
	'caption.alt.org.tldr'                => 'Zlib-Libpng License (Zlib)',
	'caption.alt.org.trove'               => 'zlib/libpng License',
	'caption.alt.org.wikipedia'           => 'zlib License',
	'caption.alt.org.wikipedia.misc.case' => 'zlib license',
	iri                => 'http://zlib.net/zlib_license.html',
	'iri.alt.org.gzip' => 'http://www.gzip.org/zlib/zlib_license.html',
	tags               => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote}
		. '[.][ ]'
		. $P{use_ack_apprec_not_req}
		. '[.][  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter},
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
	tags                    => [
		'family:zlib',
		'license:is:grant',
		'type:unversioned',
	],

	'pat.alt.subject.license.scope.multisection' =>
		$P{origin_sw_no_misrepresent}
		. $P{you_not_claim_wrote}
		. '[.][ ]'
		. $P{use_ack_req}
		. '[.][  ]Portions Copyright \S+ [-#]+ Charlie Poole '
		. 'or Copyright \S+ [-#]+ James W\. Newkirk, Michael C\. Two, Alexei A\. Vorontsov '
		. 'or Copyright \S+ [-#]+ Philip A\. Craig[  ]'
		. $P{altered_srcver_mark}
		. '[.][  ]'
		. $P{notice_no_alter},
};

=item * zpl

=item * zpl_1

=item * zpl_1_1

=item * zpl_2

=item * zpl_2_1

=cut

$RE{zpl} = {
	name                                  => 'ZPL',
	'name.alt.org.wikidata'               => 'Q3780982',
	'name.alt.org.wikipedia'              => 'Zope_Public_License',
	caption                               => 'Zope Public License',
	'caption.alt.org.trove.synth.nogrant' => 'Zope Public License',
	'caption.alt.org.wikipedia'           => 'Zope Public License',
	tags                                  => [
		'type:versioned:decimal',
	],
};

$RE{zpl_1} = {
	name                     => 'ZPL-1.0',
	'name.alt.org.fsf'       => 'ZopePLv1.0',
	caption                  => 'Zope Public License (ZPL) Version 1.0',
	'caption.alt.misc.plain' => 'Zope Public License 1.0',
	'iri.alt.archive.20000816090640' => 'http://www.zope.org/Resources/ZPL',
	tags                             => [
		'type:singleversion:zpl',
	],
	licenseversion => '1.0',
};

$RE{zpl_1_1} = {
	name                => 'ZPL-1.1',
	'name.alt.org.spdx' => 'ZPL-1.1',
	caption             => 'Zope Public License 1.1',
	tags                => [
		'type:singleversion:zpl',
	],
	licenseversion => '1.1',
};

$RE{zpl_2} = {
	name                           => 'ZPL-2.0',
	'name.alt.org.osi'             => 'ZPL-2.0',
	'name.alt.org.spdx'            => 'ZPL-2.0',
	'name.alt.org.tldr.path.short' => 'zpl-2.0',
	caption                        => 'Zope Public License 2.0',
	'caption.alt.org.osi'          => 'The Zope Public License Ver.2.0',
	'caption.alt.org.tldr'         => 'Zope Public License 2.0 (ZPL-2.0)',
	iri  => 'http://old.zope.org/Resources/License/ZPL-1.1',
	tags => [
		'type:singleversion:zpl',
	],
	licenseversion => '2.0',

	'pat.alt.subject.license.scope.multisection.part.2_3' =>
		$P{repro_copr_cond_discl}
		. '[.][  ]' . '[*)]'
		. 'The name Zope Corporation \(tm\) must not be used to endorse',
	'pat.alt.subject.license.scope.sentence.part.3' =>
		'The name Zope Corporation \(tm\) must not be used to endorse',
};

$RE{zpl_2_1} = {
	name                  => 'ZPL-2.1',
	'name.alt.org.fsf'    => 'ZPL-2.1',
	'name.alt.org.spdx'   => 'ZPL-2.1',
	caption               => 'Zope Public License 2.1',
	'caption.alt.org.fsf' => 'Zope Public License Version 2.1',
	iri                   => 'http://old.zope.org/Resources/ZPL/',
	tags                  => [
		'type:singleversion:zpl',
	],
	licenseversion => '2.1',
};

=back

=head2 License combinations

Patterns each covering a combination of multiple licenses.

Each of these patterns has the tag B< type:combo >.

=over

=item * perl

=back

=cut

$RE{perl} = {
	name                     => 'Perl',
	'name.alt.org.perl'      => 'perl_5',
	'name.alt.org.spdx'      => 'Artistic or GPL-1+',
	caption                  => 'The Perl 5 License',
	'caption.alt.misc.short' => 'Perl License',
	'caption.alt.misc.long'  => 'The Perl 5 programming language License',
	'caption.alt.org.perl' =>
		'The Perl 5 License (Artistic 1 & GPL 1 or later)',
	'caption.alt.org.software_license' =>
		'same terms as the Perl 5 programming language system itself',
	summary =>
		'the same terms as the Perl 5 programming language itself (Artistic or GPL)',
	'summary.alt.misc.short' => 'same terms as Perl',
	tags                     => [
		'license:includes:license:artistic_1_perl',
		'license:includes:license:gpl_1_or_newer',
		'type:combo',
	],

	'pat.alt.subject.license.scope.multisection.part.license' =>
		'(?:under the terms of either[:][  ])?'
		. '[*)]the GNU General Public License '
		. 'as published by the Free Software Foundation[;] '
		. 'either version 1, or \(at your option\) any later version, '
		. 'or[  ]'
		. '[*)]the ["]Artistic License["]',
};

=head2 License groups

Patterns each covering either of multiple licenses.

Each of these patterns has the tag B< type:group >.

=over

=item * bsd

=cut

$RE{bsd} = {
	name                        => 'BSD',
	'name.alt.org.debian'       => 'BSD~unspecified',
	'name.alt.org.fedora.web'   => 'BSD',
	'name.alt.org.wikidata'     => 'Q191307',
	'name.alt.misc.style'       => 'BSD-style',
	caption                     => 'BSD license',
	'caption.alt.org.debian'    => 'BSD (unspecified)',
	'caption.alt.org.trove'     => 'BSD License',
	'caption.alt.org.wikipedia' => 'BSD licenses',
	'caption.alt.misc.style'    => 'a BSD-style license',
	'caption.alt.misc.long'     => 'Berkeley Software Distribution License',
	summary                     => 'a BSD-style license',
	tags                        => [
		'type:group',
	],

	'pat.alt.subject.license.scope.multisection' => $P{repro_copr_cond_discl}
		. '(?:[.][  ](?:[*)]?'
		. $P{ad_mat_ack_this}
		. '[.][  ])?[*)]?'
		. $P{nopromo_neither} . ')?',
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
	name                        => 'MIT',
	'name.alt.org.debian'       => 'MIT~unspecified',
	'name.alt.org.fedora.web'   => 'MIT',
	'name.alt.org.wikidata'     => 'Q334661',
	'name.alt.misc.style'       => 'MIT-style',
	caption                     => 'MIT license',
	'caption.alt.org.trove'     => 'MIT License',
	'caption.alt.org.wikipedia' => 'MIT License',
	'caption.alt.misc.style'    => 'an MIT-style license',
	'iri.alt.org.wikipedia' => 'https://en.wikipedia.org/wiki/MIT_License',
	summary                 => 'an MIT-style license',
	tags                    => [
		'type:group',
	],

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

my @gnu_langs
	= qw(en ar ca de el es fr it ja nl pl pt_BR ru sq sr zh_CN zh_TW);

my $version_re
	= qr/$RE{version_numberstring}{'pat.alt.subject.trait.scope.line.scope.sentence'}(?:$RE{version_only}{'pat.alt.subject.trait'}|$RE{version_later}{'pat.alt.subject.trait'})?$/;

# must be simple word (no underscore), to survive getting joined in cache
# more ideal first: first available is default
my @_SUBJECTSTACK = qw(license grant name iri trait);

my @_OBJECTS;
my %_PUBLISHER;
my %_TYPE;
my %_SERIES;
my %_USAGE;

# process metadata tags
@_ = ();
for my $id ( grep {/^[a-z]/} keys %RE ) {

	# resolve publisher
	for ( @{ $RE{$id}{tags} } ) {
		/^license:published:($_prop)/;
		$_PUBLISHER{$id} = $1
			if ($1);
	}

	# resolve series
	for ( @{ $RE{$id}{tags} } ) {
		/^type:($_prop)(?::($_prop)(?::($_prop))?)?/;
		$_TYPE{$id} = $1
			if ($1);
		if ( $2 and $1 eq 'singleversion' ) {
			push @_OBJECTS, $id;
			push @{ $_SERIES{$id} }, $2;
		}
		else {
			push @_, $id;
		}
		if ( $2 and $RE{$2} and $1 eq 'usage' ) {
			$RE{$id}{licenseversion} = $RE{$2}{licenseversion}
				|| die "missing version for $id (needed by $1)";
			$_USAGE{$id}{series} //= $2;
			if ( $_USAGE{$id}{series} ne $2 ) {
				die 'multi-origin usage for $id';
			}
			$_USAGE{$id}{type} = $3;
			die "unsupported usage for $id ($_)"
				unless ( grep { $3 eq $_ } qw( only or_later rfn no_rfn ) );
		}
	}

	# synthesize metadata: series alternate caption from caption
	_prop_populate( $id, 'caption', $_ ) for ( @{ $_SERIES{$id} } );
}

# ensure versioned objects are processed after single-version objects
push @_OBJECTS, @_;

for my $id (@_OBJECTS) {

	# resolve publisher
	for ( @{ $RE{$id}{tags} } ) {
		/^type:usage:($_prop)/;
		$_PUBLISHER{$id} = $_PUBLISHER{$1}
			if ( $1 and $_PUBLISHER{$1} );
	}
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
			for my $lang (@gnu_langs) {
				( my $weblang = lc $lang ) =~ tr/_/-/;
				$RE{$id}{"iri.$slug($lang)"}
					||= "https://www.gnu.org/licenses/license-list.$weblang.html#$RE{$id}{$_}";
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
			sort
			map  { $RE{$id}{$_} }
			grep {/^iri(?:[.(]|\z)/}
			keys %{ $RE{$id} }
			)
		{
			s/([ .()\[\]])/\\$1/g;
			s/-/[-]/g;
			s!^https?://![http://]!;
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
		my $published_by = '';
		$published_by
			= '(?: '
			. $RE{ $_PUBLISHER{$id} }{'pat.alt.subject.trait'}
			. "(?: ?[;]?|[']s))?"
			if ( $_PUBLISHER{$id} );

		my ( $only, $later, $rfn, $no_rfn );
		my @candidates = ($id);
		if ( $_USAGE{$id} ) {
			$only   = ( $_USAGE{$id}{type} eq 'only' );
			$later  = ( $_USAGE{$id}{type} eq 'or_later' );
			$rfn    = ( $_USAGE{$id}{type} eq 'rfn' );
			$no_rfn = ( $_USAGE{$id}{type} eq 'no_rfn' );
			push @candidates,
				$_USAGE{$id}{series},
				@{ $_SERIES{ $_USAGE{$id}{series} } };
		}
		elsif ( $_SERIES{$id} ) {
			push @candidates, @{ $_SERIES{$id} };
		}

		my $version = '';
		if ( $RE{$id}{licenseversion} ) {
			$version
				= $RE{version_prefix}
				{'pat.alt.subject.trait.scope.line.scope.sentence'}
				. $RE{$id}{licenseversion};
			$version =~ s/\.0$/(?:\\.0)?/;
		}

		my $version_usage = '';
		$version_usage = $RE{version_only}{'pat.alt.subject.trait'}
			if ($only);
		$version_usage = $RE{version_later}{'pat.alt.subject.trait'}
			if ($later);

		my $version_stopgap = '(?:[^\d.]|\.\D|\.\z|\z)';

		my @shortnames;
		foreach my $obj_id (@candidates) {
			push @shortnames,
				grep { !/-\(/ }
				map  { $RE{$obj_id}{$_} }
				grep { !/^name\.alt\.org\.wikidata(?:$_delim|\z)/ }
				grep {/^name(?:$_delim|\z)/}
				grep { !/\.synth\.nogrant(?:$_delim|\z)/ }
				keys %{ $RE{$obj_id} };
		}
		@shortnames = uniq sort @shortnames;

		my $shortname = '';
		$shortname
			= sprintf '(?: ?\((?:the )?\"?(%s)(?: [Ll]icen[cs]e)?\"?\))?',
			join( '|', @shortnames )
			if (@shortnames);
		my $shortname_re = qr/$shortname$/;

		my $suffix = $shortname . $published_by;

		my @names;
		for (
			sort
			grep { !/-\(/ }
			grep { !/,[_~]/ }
			map  { $RE{$id}{$_} }
			grep { !/^name\.alt\.org\.wikidata(?:$_delim|\z)/ }
			grep {/^(?:caption|name)(?:$_delim|\z)/}
			grep { !/\.synth\.nogrant(?:$_delim|\z)/ }
			keys %{ $RE{$id} }
			)
		{
			# mangle words
			s/$shortname_re//;
			if ($version) {
				s/$version_re//;
				s/$shortname_re//;
			}
			if (/[()]/) {
				$shortname = '';
			}

			# mangle characters
			s/([+()])/\\$1/g;
			unless (/ /) {
				s/^(?:\\b)?/\\b/;
				s/(?:\\b)?$/\\b/;
			}
			s/^(?:[Aa]n? )/(?:[Aa]n? )?/;    # relax (not add)
			s/^$the?/$the?/;
			s/(?: [Ll]icen[cs]e)/(?: [Ll]icen[cs]e)?/;
			s/[、，] ?/[, ]/g;
			s/,/,?/g;
			s/'/[']/g;
			s/-/[-]/g;
			s/ \[-\] /[ - ]/g;

			push @names, $_;
		}

		my $stem = sprintf '(?:%s)',
			join( '|', @names );

		if ($version) {

			# extra pattern with (non-optional) leading version
			push @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} },
				'(?:'
				. $RE{version_prefix}
				{'pat.alt.subject.trait.scope.line.scope.sentence'}
				. "$version$version_usage"
				. " of $stem"
				. $published_by . ')';

			$suffix
				= '(?:'
				. "$version(?:$version_usage)?"
				. $RE{version_number_suffix}{'pat.alt.subject.trait'}
				. ')?'
				. $shortname
				. $published_by
				. $version
				. $RE{version_number_suffix}{'pat.alt.subject.trait'}
				. $version_usage
				. $shortname
				. $version_stopgap;
		}
		push @{ $RE{$id}{'_pat.alt.subject.name.synth.caption'} },
			$stem . $suffix;
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
			s/\\-/[-]/g;
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
			= $RE{license_label}{'pat.alt.subject.trait'} . ' ?'
			. _join_pats( sort keys %pat );
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
			s/\\-/[-]/g;
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
			= $RE{license_label_trove}{'pat.alt.subject.trait'} . ' ?'
			. _join_pats( sort keys %pat )
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
			= $RE{licensed_under}{'pat.alt.subject.trait'} . $pat;
	}

	# synthesize CC subject pattern license from metadata caption
	if ( $id eq 'cc_cc0_1' ) {
		$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
			||= "(?:$RE{$id}{'caption.alt.org.cc.legal.license'})?"
			. "[  ]$cc_intro_cc0";
	}
	elsif ( $id =~ /^cc.*_1$/ ) {
		$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
			||= $RE{$id}{'caption.alt.org.cc.legal.license'}
			. "[  ]$cc_intro_1";
	}
	elsif ( $id =~ /^cc.*_(?:2|2_5|3)$/ ) {
		$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
			||= $RE{$id}{'caption.alt.org.cc.legal.license'}
			. "[  ]$cc_intro";
	}
	elsif ( $id =~ /^cc.*_4$/ ) {
		$RE{$id}{'pat.alt.subject.license.scope.sentence.synth.cc'}
			||= $RE{$id}{'caption.alt.org.cc.legal.license'}
			. '(?: Public License)?[  ]'
			. $cc_by_exercising_you_accept_this
			. $RE{$id}{'caption.alt.org.cc.legal.license'};
	}

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
			sort
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
			: [@pat_subject];

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

		# TODO: document if not obsoleted
		# by <https://github.com/perlancar/perl-Regexp-Pattern/issues/4>
		if ( $args{anchorleft} ) {
			$pat = "^(?:$pat)";
		}

		if ( $args{engine} ) {
			if ( $args{engine} eq 'RE2' ) {

				# TODO: make RE2 optional, with greedy pure-perl too
				use re::engine::RE2 -longest_match => 1, -strict => 1;
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
		default => join ',', @pat_subject,
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
		if (/^$property(?:\.alt)?($_notlang*)($_lang?)/) {
			$RE{$series}{"$property.alt$1.version.$id$2"} ||= $RE{$id}{$_};
		}
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
