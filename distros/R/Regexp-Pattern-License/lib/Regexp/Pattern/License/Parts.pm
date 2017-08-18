package Regexp::Pattern::License::Parts;

use utf8;
use strict;
use warnings;

=head1 NAME

Regexp::Pattern::License::Parts - Regular expressions for licensing sub-parts

=head1 VERSION

Version v3.0.31

=cut

our $VERSION = version->declare("v3.0.31");

=head STATUS

This module is considered part of Regexp-Pattern-License's internals.

=head DESCRIPTION

This is not considered part of Regexp-Pattern-License's public API.

It is a class of internally used patterns.

=cut

my $D  = qr/[-–]/;     # dash
my $SD = qr/[ -–]/;    # space or dash

#my $I  = qr/[iI\d\W]+/; # bullet or count
my $I = qr/\W*\S\W*/;    # bullet or count

our %RE = (

	# assets (original or derived)
	doc_mat_dist => {
		pat =>
			qr/the documentation and\/or other materials provided with the distribution/
	},
	sw           => { pat => qr/the Software/ },
	the_material => {
		pat =>
			qr/this software and associated documentation files \(the "?Material"?\)/
	},
	cp_sw => { pat => qr/all copies of the Software/ },
	cp_sw_copr =>
		{ pat => qr/all copies of the Software and its Copyright notices/ },
	cp_sw_doc =>
		{ pat => qr/all copies of the Software and its documentation/ },
	sw_doc => { pat => qr/this software and its documentation/ },
	the_sw => {
		pat =>
			qr/this software and associated documentation files \(the "?Software"?\)/
	},

	# rights
	perm        => { pat => qr/Permission/ },
	any_purpose => { pat => qr/for any purpose/ },
	to_deal_mat =>
		{ pat => qr/to deal in the Materials without restriction/ },
	granted               => { pat => qr/is hereby granted/ },
	to_deal_the_sw_rights => {
		pat =>
			qr/to deal in the Software without restriction, including without limitation the rights/
	},
	to_dist       => { pat => qr/to use, copy, modify,? and distribute/ },
	to_mod_sublic => {
		pat =>
			qr/to use, copy, modify, merge, publish, distribute, sublicense, and\/or sell copies of/
	},
	to_perm_pers => {
		caption => 'to permit person',
		pat =>
			qr/to permit persons to whom the Software is furnished to do so/
	},

	# agents
	to_pers => { pat => qr/to any person obtaining a copy of/ },

	# charges
	free_charge    => { pat => qr/free of charge/ },
	free_agree_fee => {
		pat =>
			qr/without written agreement and without license or royalty fees/
	},
	nofee => { pat => qr/without fee/ },

	# conditions
	subj_cond           => { pat => qr/subject to the following conditions/ },
	ack_doc_mat_pkg_use => {
		pat =>
			qr/acknowledgment shall be given in the documentation, materials and software packages that this Software was used/
	},
	ack_doc_pkg_use => {
		pat =>
			qr/acknowledgment shall be given in the documentation and software packages that this Software was used/
	},
	ack_pub_use_nosrc => {
		pat =>
			qr/In addition publicly documented acknowledgment must be given that this software has been used if no source code of this software is made available publicly/
	},
	altered_srcver_mark => {
		pat =>
			qr/$I?Altered source versions must be plainly marked as such,? and must not be misrepresented as being the original software/
	},
	altered_ver_mark => {
		pat =>
			qr/$I?Altered versions must be plainly marked as such,? and must not be misrepresented as being the original source/
	},
	change_redist_share => {
		pat =>
			qr/If you change this software and redistribute parts or all of it in any form, you must make the source code of the altered version of this software available/
	},
	incl => { pat => qr/shall be included/ },
	name => { pat => qr/[Tt]he names?(?: \S+){1,15}/ },
	namenot =>
		{ pat => qr/[Tt]he names?(?: \S+){1,15} (?:may|must|shall) not/ },
	neithername => {
		pat =>
			qr/Neither the (?:names?(?: \S+){1,15}|authors?) nor the names of(?: (?:its|their|other|any))? contributors may/
	},
	notice_no_alter =>
		{ pat => qr/$I?This notice may not be removed or altered/ },
	notice_no_alter_any => {
		pat =>
			qr/$I?This notice may not be removed or altered from any source distribution/
	},
	copr_no_alter => {
		pat =>
			qr/$I?This Copyright notice may not be removed or altered from any source or altered source distribution/
	},
	license_not_lib => {
		pat =>
			qr/This License does not apply to any software that links to the libraries provided by this software \(statically or dynamically\), but only to the software provided/,
	},
	redist_bin_repro =>
		{ pat => qr/Redistributions in binary form must reproduce/ },
	src_no_relicense => {
		pat =>
			qr/$I?Source versions may not be "?relicensed"? under a different license without my explicitly written permission/
	},
	used_endorse_deriv => {
		pat =>
			qr/be used to endorse or promote products derived from this software/
	},
	used_ad      => { pat => qr/be used in advertising/ },
	used_ad_dist => {
		pat =>
			qr/be used in (?:any )?advertising or publicity pertaining to distribution of the software/
	},
	without_prior_written =>
		{ pat => qr/without specific prior written permission/ },
	without_written => { pat => qr/without specific written permission/ },
	without_written_prior =>
		{ pat => qr/without specific, written prior permission/ },
	origin_sw_no_misrepresent => {
		pat => qr/$I?The origin of this software must not be misrepresented/
	},
	origin_src_no_misrepresent => {
		pat =>
			qr/$I?The origin of this source code must not be misrepresented/
	},
	you_not_claim_wrote => {
		pat => qr/you must not claim that you wrote the original software/
	},
	use_ack_nonreq => {
		pat =>
			qr/If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required/
	},
	use_ack_req => {
		pat =>
			qr/If you use this software in a product, an acknowledgment \(see the following\) in the product documentation is required/
	},

	# disclaimers
	asis_expr_warranty => { pat => qr/without express or implied warranty/ },
	asis_name_sw    => { pat => qr/(?:\S+ ){1,15}PROVIDES? THIS SOFTWARE/ },
	asis_sw_by_name => { pat => qr/THIS SOFTWARE IS PROVIDED BY/ },
	asis_sw_name_discl => {
		pat =>
			qr/THE SOFTWARE IS PROVIDED \W*AS\W+IS\W*(?:,?|AND) (?:\S+ ){1,15}DISCLAIMS/
	},
	asis_sw_warranty => {
		pat => qr/THE SOFTWARE IS PROVIDED \W*AS\W+IS\W* WITHOUT WARRANTY/
	},

	# versioning
	ver_later_para    => { pat => qr/Later versions are permitted/ },
	ver_later_postfix => {
		pat =>
			qr/(?:and|or)(?: ?\(?at your option\)?)?(?: any)? (?:later|newer)(?: version)?/
	},
	ver_number => { pat => qr/\d(?:\.\d+)*/ },
	ver_prefix => { pat => qr/[Vv](?:ersion |ERSION |\.? ?)/ },

	# Creative Commons
	cc     => { pat => qr/(?:Creative Commons|CC)/ },
	cc_by  => { pat => qr/(?:Attribution)/ },
	cc_cc0 => { pat => qr/(?:CC0|Zero|0)/ },
	cc_nc  => { pat => qr/(?:Non$SD?Commercial)/ },
	cc_nd  => { pat => qr/(?:No$SD?Deriv(?:ative)?s)/ },
	cc_sa  => { pat => qr/(?:Share$SD?Alike)/ },
	cc_sp  => { pat => qr/(?:Sampling$SD?Plus)/ },
	cc_url =>
		{ pat => qr"(?:(?:https?:?)?(?://)?creativecommons.org/licenses/)" },
	cc_url_pd => {
		pat => qr"(?:(?:https?:?)?(?://)?creativecommons.org/publicdomain/)"
	},

	# texts
	ack_name => {
		pat =>
			qr/the following acknowledge?ment\W+This product includes software developed by/
	},
	copr      => { pat => qr/[Tt]he above copyright notice/ },
	copr_perm => {
		pat =>
			qr/(?:both t|t|T)(?:hat|he|he above) copyright notice(?:s|\(s\))? and this permission notice/
	},
	copr_perm_warr => {
		pat =>
			qr/(?:both t|t|T)(?:hat|he|he above) copyright notice(?:s|\(s\))? and this permission notice and warranty disclaimer/
	},
	copr_cond_discl => {
		pat =>
			qr/the above copyright notice, this list of conditions and the following disclaimer/
	},

	# combinations
	discl_name_warranties =>
		{ pat => qr/(?:\S+ ){1,15}DISCLAIMS? ALL WARRANTIES/ },
	permission_use_fee_agree =>
		{ pat => qr/and without a written agreement/ },
);

$RE{perm_granted}{pat} = qr/$RE{perm}{pat} $RE{granted}{pat}/;
$RE{ad_mat_ack_this}{pat}
	= qr/All advertising materials mentioning features or use of this software must display $RE{ack_name}{pat}/;
$RE{note_copr_perm}{pat}
	= qr/provided that$I? $RE{copr_perm}{pat} appear in all copies/;
$RE{repro_copr_perm_warr_appear_doc}{pat}
	= qr/$RE{copr_perm_warr}{pat} appear in supporting documentation/;
$RE{note_marketing}{pat}
	= qr/$RE{incl}{pat} in $RE{cp_sw}{pat}, its documentation and marketing/;
$RE{retain_copr_appear}{pat}
	= qr/provided that $RE{copr}{pat} appears? in all copies/;
$RE{retain_copr_perm_subst}{pat}
	= qr/$RE{copr_perm}{pat} $RE{incl}{pat} in all copies or substantial portions of the Software/;
$RE{retain_copr_perm_sw_copr}{pat}
	= qr/$RE{copr_perm}{pat} $RE{incl}{pat} in $RE{cp_sw_copr}{pat}/;
$RE{retain_copr_perm_sw_doc}{pat}
	= qr/$RE{copr_perm}{pat} $RE{incl}{pat} in $RE{cp_sw_doc}{pat}/;
$RE{retain_notice_cond_discl}{pat}
	= qr/Redistributions of source code must retain $RE{copr_cond_discl}{pat}/;
$RE{nopromo_except}{pat}
	= qr/Except as contained in this notice, $RE{namenot}{pat} $RE{used_ad}{pat}/;
$RE{nopromo_name_written}{pat}
	= qr/$RE{name}{pat} not $RE{used_ad_dist}{pat} $RE{without_written}{pat}/;
$RE{nopromo_name_written_prior}{pat}
	= qr/$RE{name}{pat} not $RE{used_ad_dist}{pat} $RE{without_written_prior}{pat}/;
$RE{repro_copr_cond_discl}{pat}
	= qr/$RE{redist_bin_repro}{pat} $RE{copr_cond_discl}{pat} in $RE{doc_mat_dist}{pat}/;
$RE{repro_copr_perm_appear_doc}{pat}
	= qr/$RE{copr_perm}{pat} appear in supporting documentation/;
$RE{nopromo_neither}{pat}
	= qr/(?:$RE{neithername}{pat}|$RE{namenot}{pat}) $RE{used_endorse_deriv}{pat} $RE{without_prior_written}{pat}/;
$RE{redist_ack_this}{pat}
	= qr/Redistributions of any form whatsoever must retain $RE{ack_name}{pat}/;

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
