package Regexp::Pattern::License::Parts;

use utf8;
use strict;
use warnings;

=head1 NAME

Regexp::Pattern::License::Parts - Regular expressions for licensing sub-parts

=head1 VERSION

Version v3.1.95

=cut

our $VERSION = version->declare("v3.1.95");

=head STATUS

This module is considered part of Regexp-Pattern-License's internals.

=head DESCRIPTION

This is not considered part of Regexp-Pattern-License's public API.

It is a class of internally used patterns.

=cut

# internal patterns compiled into patterns
#  * must be unique, to not collide at their final use in gen_pat sub
#  * must be a unit, so that e.g. suffix "?" applies to whole chunk
my $BB = '[*1-9. ]';    # start-of-sentence bullet or count
my $E  = '[ ]';         # end-of-sentence space
my $Q  = '["]';         # quote
my $QB = '["*]';        # quote or bullet
my $SD = '[ -]';        # space or dash

our %RE = (

	# assets (original or derived)
	doc_mat_dist => {
		pat =>
			'the documentation and/or other materials provided with the distribution'
	},
	sw           => { pat => 'the Software' },
	the_material => {
		pat =>
			"this software and(?:/or)? associated documentation files \\(?the ${Q}Materials?$Q\\)?"
	},
	cp_sw => { pat => 'all copies of the Software' },
	cp_sw_copr =>
		{ pat => 'all copies of the Software and its Copyright notices' },
	cp_sw_doc =>
		{ pat => 'all copies of the Software and its documentation' },
	sw_doc => { pat => 'this software and its documentation' },
	the_sw => {
		pat =>
			"this software and associated documentation files \\(the ${Q}Software$Q\\)"
	},
	this_prg => { pat => 'this program' },

	# rights
	perm        => { pat => 'Permission' },
	any_purpose => { pat => 'for any purpose' },
	to_deal_mat => { pat => 'to deal in the Materials without restriction' },
	granted     => { pat => 'is(?: hereby)? granted' },
	to_deal_the_sw_rights => {
		pat =>
			'to deal in the Software without restriction, including without limitation the rights'
	},
	to_copy => { pat => 'to use or copy' },
	to_dist => { pat => 'to use, copy, modify,? and distribute' },
	to_dist_mod =>
		{ pat => 'to modify the code and to distribute modified code' },
	to_mod_sublic => {
		pat =>
			'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of'
	},
	to_perm_pers => {
		caption => 'to permit person',
		pat => 'to permit persons to whom the Software is furnished to do so'
	},

	# agents
	to_pers => { pat => 'to any person obtaining a copy of' },

	# charges
	free_charge    => { pat => 'free of charge' },
	free_agree_fee => {
		pat =>
			'without written agreement and without license or royalty fees'
	},
	nofee => { pat => 'without fee' },

	# conditions
	subj_cond           => { pat => 'subject to the following conditions' },
	ack_doc_mat_pkg_use => {
		pat =>
			'acknowledgment shall be given in the documentation, materials and software packages that this Software was used'
	},
	ack_doc_pkg_use => {
		pat =>
			'acknowledgment shall be given in the documentation and software packages that this Software was used'
	},
	ack_pub_use_nosrc => {
		pat =>
			'In addition publicly documented acknowledgment must be given that this software has been used if no source code of this software is made available publicly'
	},
	altered_srcver_mark => {
		pat =>
			"$BB?Altered source versions must be plainly marked as such,? and must not be misrepresented as being the original software"
	},
	altered_ver_mark => {
		pat =>
			"$BB?Altered versions must be plainly marked as such,? and must not be misrepresented as being the original source"
	},
	change_redist_share => {
		pat =>
			'If you change this software and redistribute parts or all of it in any form, you must make the source code of the altered version of this software available'
	},
	incl => { pat => 'shall be included' },
	name => { pat => '[Tt]he names?(?: \S+){1,15}' },
	namenot =>
		{ pat => '[Tt]he names?(?: \S+){1,15} (?:may|must|shall) not' },
	neithername => {
		pat =>
			'Neither the (?:names?(?: \S+){1,15}|authors?) nor the names of(?: (?:its|their|other|any))? contributors\W? may'
	},
	notice_no_alter =>
		{ pat => "$BB?This notice may not be removed or altered" },
	notice_no_alter_any => {
		pat =>
			"$BB?This notice may not be removed or altered from any source distribution"
	},
	copr_no_alter => {
		pat =>
			"$BB?This Copyright notice may not be removed or altered from any source or altered source distribution"
	},
	license_not_lib => {
		pat =>
			'This License does not apply to any software that links to the libraries provided by this software \(statically or dynamically\), but only to the software provided'
	},
	redist_bin_repro =>
		{ pat => 'Redistributions in binary form must reproduce' },
	src_no_relicense => {
		pat =>
			"$BB?Source versions may not be ${Q}relicensed$Q under a different license without my explicitly written permission"
	},
	used_endorse_deriv => {
		pat =>
			'be used to endorse or promote products derived from this software'
	},
	used_ad      => { pat => 'be used in advertising' },
	used_ad_dist => {
		pat =>
			'be used in (?:any )?advertising or publicity pertaining to distribution of the software'
	},
	you_not_use_ad_dist => {
		pat =>
			'You must not use any of the names of the authors or copyright holders of the original software for advertising or publicity pertaining to distribution'
	},
	without_prior_written =>
		{ pat => 'without specific prior written permission' },
	without_written => { pat => 'without specific written permission' },
	without_written_prior =>
		{ pat => 'without specific, written prior permission' },
	origin_sw_no_misrepresent => {
		pat => "$BB?The origin of this software must not be misrepresented"
	},
	origin_src_no_misrepresent => {
		pat =>
			"$BB?The origin of this source code must not be misrepresented"
	},
	you_not_claim_wrote =>
		{ pat => 'you must not claim that you wrote the original software' },
	use_ack_apprec => {
		pat =>
			'If you use this software in a product, an acknowledgment in the product documentation would be appreciated'
	},
	use_ack_apprec_not_req => {
		pat =>
			'If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required'
	},
	use_ack_req => {
		pat =>
			'If you use this software in a product, an acknowledgment \(see the following\) in the product documentation is required'
	},

	# disclaimers
	asis_expr_warranty => {
		pat => "provided $Q?as${SD}is$Q? without express or implied warranty"
	},
	asis_name_sw    => { pat => '(?:\S+ ){1,15}PROVIDES? THIS SOFTWARE' },
	asis_sw_by_name => { pat => 'THIS SOFTWARE IS PROVIDED BY' },
	asis_sw_expr_warranty => {
		pat =>
			"This software is supplied $Q?as${SD}is$Q? without express or implied warranty"
	},
	asis_sw_name_discl => {
		pat =>
			"THE SOFTWARE IS PROVIDED ${QB}AS$QB?$SD$QB?IS$QB(?:,?|AND) (?:\\S+ ){1,15}DISCLAIMS"
	},
	asis_sw_warranty => {
		pat =>
			"THE SOFTWARE IS PROVIDED ${QB}AS$QB?$SD$QB?IS$QB,? WITHOUT WARRANTY"
	},

	# Creative Commons
	cc     => { pat => '(?:Creative Commons|CC)' },
	cc_by  => { pat => '(?:Attribution)' },
	cc_cc0 => { pat => '(?:CC0|Zero|0)' },
	cc_nc  => { pat => "(?:Non$SD?Commercial)" },
	cc_nd  => { pat => "(?:No$SD?Deriv(?:ative)?s)" },
	cc_sa  => { pat => "(?:Share$SD?Alike)" },
	cc_sp  => { pat => "(?:Sampling$SD?Plus)" },
	cc_url =>
		{ pat => '(?:(?:https?:?)?(?://)?creativecommons.org/licenses/)' },
	cc_url_pd => {
		pat => '(?:(?:https?:?)?(?://)?creativecommons.org/publicdomain/)'
	},

	# texts
	ack_name => {
		pat =>
			"the following acknowledge?ments?:?$E$Q?This product includes software developed by"
	},
	authors_copr    => { pat => 'the Authors, the Copyright' },
	copr            => { pat => '[Tt]he above copyright notice' },
	copr_avail_orig => {
		pat =>
			'the Copyright, this License, and the Availability of the original version'
	},
	copr_avail_note => {
		pat => 'the Copyright, this License, (?:and )?the Availability note'
	},
	copr_perm => {
		pat =>
			'(?:both t|t|T)(?:hat|he|he above) copyright notice(?:s|\(s\))? and this permission notice'
	},
	copr_perm_warr => {
		pat =>
			'(?:both t|t|T)(?:hat|he|he above) copyright notice(?:s|\(s\))? and this permission notice and warranty disclaimer'
	},
	copr_perms      => { pat => 'this copyright and permissions notice' },
	copr_cond_discl => {
		pat =>
			'the above copyright notice, this list of conditions and the following disclaimer'
	},
	notices   => { pat => '[Tt]he above notices' },
	used_perm => { pat => '[Uu]sed by permission' },

	# combinations
	discl_name_warranties =>
		{ pat => '(?:\S+ ){1,15}DISCLAIMS? ALL WARRANTIES' },
	permission_use_fee_agree => { pat => 'and without a written agreement' },
);

$RE{perm_granted}{pat} = "$RE{perm}{pat} $RE{granted}{pat}";
$RE{ad_mat_ack_this}{pat}
	= "All advertising materials mentioning features or use of this software must display $RE{ack_name}{pat}";
$RE{note_copr_perm}{pat}
	= "provided that$BB? $RE{copr_perm}{pat} appear in all copies";
$RE{note_copr_perms_deriv}{pat}
	= "provided that$BB? $RE{copr_perms}{pat} appear in all copies and derivatives";
$RE{repro_code_cite_authors_copr}{pat}
	= "User documentation of any code that uses this code must cite $RE{authors_copr}{pat}";
$RE{repro_code_modcode_cite_copr_avail_note}{pat}
	= "User documentation of any code that uses this code or any modified version of this code must cite $RE{copr_avail_note}{pat}";
$RE{repro_copr_perm_warr_appear_doc}{pat}
	= "$RE{copr_perm_warr}{pat} appear in supporting documentation";
$RE{repro_matlab_cite_authors}{pat}
	= 'If this code is accessible from within Matlab, then typing(?: \S+){2,5} \(with no arguments\) must cite the Authors';
$RE{note_marketing}{pat}
	= "$RE{incl}{pat} in $RE{cp_sw}{pat}, its documentation and marketing";
$RE{note_mod}{pat} = 'a notice that the code was modified is included';
$RE{retain_copr_appear}{pat}
	= "provided that $RE{copr}{pat} appears? in all copies";
$RE{retain_copr_avail_note}{pat}
	= "provided $RE{copr_avail_note}{pat} are retained";
$RE{retain_copr_avail_orig}{pat}
	= "provided that $RE{copr_avail_orig}{pat} is retained on all copies";
$RE{retain_copr_perm_subst}{pat}
	= "$RE{copr_perm}{pat} $RE{incl}{pat} in all copies or substantial portions of the Software";
$RE{retain_copr_perm_sw_copr}{pat}
	= "$RE{copr_perm}{pat} $RE{incl}{pat} in $RE{cp_sw_copr}{pat}";
$RE{retain_copr_perm_sw_doc}{pat}
	= "$RE{copr_perm}{pat} $RE{incl}{pat} in $RE{cp_sw_doc}{pat}";
$RE{retain_notice_cond_discl}{pat}
	= "Redistributions of source code must retain $RE{copr_cond_discl}{pat}";
$RE{retain_notices}{pat}     = "provided $RE{notices}{pat} are retained";
$RE{retain_notices_all}{pat} = "$RE{retain_notices}{pat} on all copies";
$RE{retain_you_avail_orig}{pat}
	= 'You must also retain the Availability information below, of the original version';
$RE{nopromo_except}{pat}
	= "Except as contained in this notice, $RE{namenot}{pat} $RE{used_ad}{pat}";
$RE{nopromo_name_written}{pat}
	= "$RE{name}{pat} not $RE{used_ad_dist}{pat} $RE{without_written}{pat}";
$RE{nopromo_name_written_prior}{pat}
	= "$RE{name}{pat} not $RE{used_ad_dist}{pat} $RE{without_written_prior}{pat}";
$RE{repro_copr_cond_discl}{pat}
	= "$RE{redist_bin_repro}{pat} $RE{copr_cond_discl}{pat} in $RE{doc_mat_dist}{pat}";
$RE{repro_copr_perm_appear_doc}{pat}
	= "$RE{copr_perm}{pat} appear in supporting documentation";
$RE{nopromo_neither}{pat}
	= "(?:$RE{neithername}{pat}|$RE{namenot}{pat}) $RE{used_endorse_deriv}{pat} $RE{without_prior_written}{pat}";
$RE{redist_ack_this}{pat}
	= "Redistributions of any form whatsoever must retain $RE{ack_name}{pat}";

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
