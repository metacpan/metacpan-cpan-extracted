use Test2::V0;

plan 1;

use Regexp::Pattern::License;

my %RE = %Regexp::Pattern::License::RE;

# dirty dump (needs manually stripping bogus entries):
# curl 'https://tldrlegal.com/search?reverse=true' | perl -nE 'm{<a href="/license/([^"]+)"><h3 class="nomargin-v">([^<]+)</h3></a>} and say '"\"\\t\\tfield '\$2' => '\$1'\"" | sort > tldr.t

# Key is page title (including shortname).
# Value is page name.
my %names = map {
	my $key = $_;
	my $id  = $RE{$key}{'iri.alt.org.tldr.synth.nogrant'}
		// $RE{$key}{'iri.alt.org.tldr'};
	$id =~ s!https://tldrlegal.com/license/!!;
	my $maincaption = $RE{$key}{'caption.alt.org.tldr.synth.nogrant'}
		// $RE{$key}{'caption.alt.org.tldr'} // $RE{$key}{caption};
	my @altcaptions = map { $RE{$key}{$_} } (
		sort grep {
			/^(?:(?:name|caption)\.alt\.org\.tldr\.alt\.|summary\.alt\.org\.tldr)/
				and !/\.version\./
		} keys %{ $RE{$key} }
	);
	map { $_ => $id } $maincaption, @altcaptions;
	}
	grep {
	grep {/^iri\.alt\.org\.tldr(?:\.synth\.nogrant)?$/}
		keys %{ $RE{$_} }
	}
	keys %RE;

like(
	\%names,
	hash {
		field '3dfx Glide License' => '3dfx-glide-license';
		field '4-Clause BSD'       => '4-clause-bsd';

#		field '4k Video Downloader EULA' => '4k-video-downloader';
		field 'Abstyles License' => 'abstyles-license';
		field 'Academic Free License 2.1 (AFL-2.1)' =>
			'academic-free-license-v.-2.1';
		field 'Academic Free License 3.0 (AFL)' =>
			'academic-free-license-3.0-(afl)';
		field 'Academy of Motion Picture Arts and Sciences BSD' =>
			'academy-of-motion-picture-arts-and-sciences-bsd';
		field 'Adaptive Public License 1.0 (APL-1.0)' =>
			'adaptive-public-license-1.0-(apl-1.0)';
		field 'Adobe Glyph List License' => 'adobe-glyph-list-license';
		field 'Adobe Postscript AFM License' =>
			'adobe-postscript-afm-license';
		field 'Adobe Systems Incorporated Source Code License Agreement' =>
			'adobe-systems-incorporated-source-code-license-agreement';
		field 'Afmparse License' => 'afmparse-license';

#		field 'Agate License' => 'agate-license';
#		field 'Air Software EULA' => 'air-software-eula';
		field 'Aladdin Free Public License' => 'aladdin-free-public-license';

#		field 'All rights served' => 'all-rights-served';
#		field 'Amazon Digital Services License' => 'amazon-digital-services-license';
		field 'ANTLR Software Rights Notice (ANTLR-PD)' =>
			'antlr-software-rights-notice-(antlr-pd)';
		field 'Apache License 1.0 (Apache-1.0)' =>
			'apache-license-1.0-(apache-1.0)';
		field 'Apache License 1.1 (Apache-1.1)' => 'apache-license-1.1';
		field 'Apache License 2.0 (Apache-2.0)' =>
			'apache-license-2.0-(apache-2.0)';

#		field 'Apple Inc. Xcode and Apple SDKs Agreement' => 'apple-inc.-xcode-and-apple-sdks-agreement';
		field 'Apple MIT License (AML)' => 'apple-mit-license-(aml)';
		field 'Apple Public Source License 2.0 (APSL)' =>
			'apple-public-source-license-2.0-(apsl)';
		field 'Artistic License 1.0' => 'artistic-license-1.0';
		field 'Artistic License 2.0 (Artistic-2.0)' =>
			'artistic-license-2.0-(artistic)';
		field 'Attribution Assurance License (AAL)' =>
			'attribution-assurance-license-(aal)';
		field 'Bahyph License' => 'bahyph-license';
		field 'Barr License'   => 'barr-license';

#		field 'Beer Recipe License (BRL)' => 'beer-recipe';
		field 'Beerware License' => 'beerware-license';
		field 'BitTorrent Open Source License v1.1 (BitTorrent-1.1)' =>
			'bittorrent-open-source-license-v1.1-(bittorrent-1.1)';
		field 'Boost Software License 1.0 (BSL-1.0)' =>
			'boost-software-license-1.0-explained';
		field 'Borceux license'             => 'borceux-license';
		field 'BSD 0-Clause License (0BSD)' => 'bsd-0-clause-license';
		field 'BSD 2-Clause License (FreeBSD/Simplified)' =>
			'bsd-2-clause-license-(freebsd)';
		field 'BSD 3-Clause License (Revised)' =>
			'bsd-3-clause-license-(revised)';
		field 'bzip2 (original)' => 'bzip2';
		field 'Caldera License'  => 'caldera-license';
		field 'CeCILL Free Software License Agreement v1.0 (CECILL-1.0)' =>
			'cecill-free-software-license-agreement-v1.0-(cecill-1.0)';
		field 'CeCILL Free Software License Agreement v1.1 (CECILL-1.1)' =>
			'cecill-free-software-license-agreement-v1.1-(cecill-1.1)';
		field 'CeCILL Free Software License Agreement v2.0 (CECILL-2.0)' =>
			'cecill-v2';

#		field 'Charity Software License' => 'charity-software-license';
		field 'Clarified Artistic License' => 'clarified-artistic-license';
		field 'CMU License'                => 'cmu-license';
		field 'CNRI Jython License'        => 'cnri-jython-license';
		field 'CNRI Python License (CNRI-Python)' =>
			'cnri-python-license-(cnri-python)';

#		field 'Code Energy Public License (CEPL-1.0)' => 'code-energy-public-license-(cepl-1.0)';
		field 'Common Development and Distribution License (CDDL-1.0)' =>
			'common-development-and-distribution-license-(cddl-1.0)-explained';
		field 'Common Public Attribution License Version 1.0 (CPAL-1.0)' =>
			'common-public-attribution-license-version-1.0-(cpal-1.0)';
		field 'Common Public License 1.0 (CPL-1.0)' =>
			'common-public-license-1.0-(cpl-1.0)';

#		field '“Commons Clause” License Condition v1.0' => 'commons-clause';
		field
			'Computer Associates Trusted Open Source License 1.1 (CATOSL-1.1)'
			=> 'computer-associates-trusted-open-source-license-1.1-(catosl-1.1)';
		field 'Condor Public License v1.1 (Condor-1.1)' =>
			'condor-public-license-v1.1-(condor-1.1)';

#		field 'Copyfree Open Innovation License 0.3 (COIL-0.3)' => 'coil-v0.3';
		field 'Creative Commons Attribution 3.0 Unported (CC-BY)' =>
			'creative-commons-attribution-(cc)';
		field 'Creative Commons Attribution 4.0 International (CC BY 4.0)' =>
			'creative-commons-attribution-4.0-international-(cc-by-4)';
		field
			'Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)'
			=> 'creative-commons-attribution-noderivatives-4.0-international-(cc-by-nd-4.0)';
		field 'Creative Commons Attribution NoDerivs (CC-ND)' =>
			'creative-commons-attribution-noderivs-(cc-nd)';
		field
			'Creative Commons Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)'
			=> 'creative-commons-public-license-(ccpl)';
		field
			'Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)'
			=> 'creative-commons-attribution-noncommercial-4.0-international-(cc-by-nc-4.0)';
		field 'Creative Commons Attribution NonCommercial (CC-BY-NC)' =>
			'creative-commons-attribution-noncommercial-(cc-nc)';
		field 'Creative Commons Attribution NonCommercial NoDerivs (CC-NC-ND)'
			=> 'creative-commons-attribution-noncommercial-noderivs-(cc-nc-nd)';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)'
			=> 'creative-commons-attribution-noncommercial-sharealike-4.0-international-(cc-by-nc-sa-4.0)';
		field
			'Creative Commons Attribution NonCommercial ShareAlike (CC-NC-SA)'
			=> 'creative-commons-attribution-noncommercial-sharealike-(cc-nc-sa)';
		field
			'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)'
			=> 'creative-commons-attribution-sharealike-4.0-international-(cc-by-sa-4.0)';
		field 'Creative Commons Attribution Share Alike (CC-SA)' =>
			'creative-commons-attribution-share-alike-(cc-sa)';
		field 'Creative Commons CC0 1.0 Universal (CC-0)' =>
			'creative-commons-cc0-1.0-universal';
		field 'Crossword License' => 'crossword-license';

#		field 'CrystalStacker License' => 'crystalstacker-license';
		field 'CUA Office Public License v1.0 (CUA-OPL-1.0)' =>
			'cua-office-public-license-v1.0-(cua-opl-1.0)';
		field 'Cube License' => 'cube-license';
		field 'curl License' => 'curl-license';

		field 'DBAD Public License' => 'dbad-public-license';

#		field 'DejaVu Fonts License v1.00' => 'dejavu-fonts-license-v1.00';
#		field 'diffmark license' => 'diffmark-license';
#		field 'DOC License' => 'doc-license';
		field 'DON\'T BE A DICK PUBLIC LICENSE' =>
			'don\'t-be-a-dick-public-license';

#		field 'Doom Source Licence' => 'doom-source-licence';
#		field 'Dotseqn License' => 'dotseqn-license';
		field 'Do What The F*ck You Want To Public License v2 (WTFPL-2.0)' =>
			'do-wtf-you-want-to-public-license-v2-(wtfpl-2.0)';
		field 'Do What The F*ck You Want To Public License (WTFPL)' =>
			'do-what-the-f*ck-you-want-to-public-license-(wtfpl)';
		field
			'Do What The Fuck You Want To But It\'s Not My Fault Public License v1 (WTFNMFPL-1.0)'
			=> 'do-what-the-fuck-you-want-to-but-it\'s-not-my-fault-public-license-v1-(wtfnmfpl-1.0)';
		field 'DSDP License' => 'dsdp-license';

#		field 'dvipdfm License' => 'dvipdfm-license';
		field 'Eclipse Public License 1.0 (EPL-1.0)' =>
			'eclipse-public-license-1.0-(epl-1.0)';
		field 'Educational Community License, Version 2.0 (ECL-2.0)' =>
			'educational-community-license,-version-2.0-(ecl-2.0)';

#		field 'Egreen Open Source ' => 'egreen-open-source-';
		field 'Eiffel Forum License v2.0 (EFL-2.0)' =>
			'eiffel-forum-license-v2.0-(efl-2.0)';
		field 'enna License' => 'enna-license';
		field 'Entessa Public License v1.0 (Entessa)' =>
			'entessa-public-license-v1.0-(entessa)';
		field 'Erlang Public License v1.1 (ErlPL-1.1)' =>
			'erlang-public-license-v1.1-(erlpl-1.1)';
		field 'EU DataGrid Software License (EUDatagrid)' =>
			'eu-datagrid-software-license-(eudatagrid)';
		field 'European Union Public License 1.1 (EUPL-1.1)' =>
			'european-union-public-licence';
		field 'Eurosym License'     => 'eurosym-license';
		field 'Fair License (Fair)' => 'fair-license';
		field 'Fair Source License 0.9 (Fair-Source-0.9)' =>
			'fair-source-license-0.9-(fair-source-0.9)';
		field 'feh License' => 'feh-license';

#		field 'FlatStone Tech Custom License' => 'flatstone-tech-custom-license';
#		field 'Foxit EULA' => 'foxit-reader-7';
		field 'Frameworx Open License 1.0 (Frameworx-1.0)' =>
			'frameworx-open-license-1.0-(frameworx-1.0)';
		field 'Free Art License (FAL)' => 'free-art-license-(fal)';

# TODO: have this test proprly handle alternate entries
#		field 'Free Public License 1.0.0' => 'free-public-license-1.0.0';
		field 'Freetype Project License (FTL)' =>
			'freetype-project-license-(ftl)';

#		field 'FusionLord Custom License' => 'fusionlord-customer-license';
#		field 'Getindor Glee License [GGL]' => 'getindor-glee-license-[ggl]';
#		field 'GG License 1.0 (GG1)' => 'gg-license-1.0-(gg1)';
#		field 'Giftware License' => 'giftware-license';
#		field 'Glulxe License' => 'glulxe-license';
		field 'GNU Affero General Public License v3 (AGPL-3.0)' =>
			'gnu-affero-general-public-license-v3-(agpl-3.0)';
		field 'GNU Free Documentation License v1.3 (FDL-1.3)' =>
			'gnu-free-documentation-license';
		field 'GNU General Public License v2.0 (GPL-2.0)' =>
			'gnu-general-public-license-v2';
		field 'GNU General Public License v3 (GPL-3)' =>
			'gnu-general-public-license-v3-(gpl-3)';
		field 'GNU Lesser General Public License v2.1 (LGPL-2.1)' =>
			'gnu-lesser-general-public-license-v2.1-(lgpl-2.1)';
		field 'GNU Lesser General Public License v3 (LGPL-3.0)' =>
			'gnu-lesser-general-public-license-v3-(lgpl-3)';

#		field 'gSOAP Public License v1.3b (gSOAP-1.3b)' => 'gsoap-public-license-v1.3b-(gsoap-1.3b)';
#		field 'Haskell Language Report License' => 'haskell-language-report-license';
		field 'Historic Permission Notice and Disclaimer (HPND)' =>
			'historic-permission-notice-and-disclaimer-(hpnd)';
		field 'IBM PowerPC Initialization and Boot Software (IBM-pibs)' =>
			'ibm-powerpc-initialization-and-boot-software-(ibm-pibs)';
		field 'IBM Public License 1.0 (IPL)' =>
			'ibm-public-license-1.0-(ipl)';

#		field 'IDGAF v1.0' => 'idgaf-v1.0';
		field 'Imlib2 License (Imlib2)' => 'imlib2-license-(imlib2)';
		field 'Independent JPEG Group License (IJG)' =>
			'independent-jpeg-group-license-(ijg)';
		field 'Intel Open Source License (Intel)' =>
			'intel-open-source-license-(intel)';
		field 'IPA Font License (IPA)' => 'ipa-font-license-(ipa)';
		field 'ISC License'            => '-isc-license';

#		field 'itos systems ' => 'itos-systems-';
#		field 'Jared M.F. Open Source Public License' => 'jared-m.f.-open-source-public-license';
#		field 'Jared M.F. Public License' => 'jared-m.f.-public-license';
#		field 'JAVA DISTRIBUTION LICENSE (JDL-1.1.X)' => 'java-advanced-imaging-distribution-license-(ver.-1.1.x)';
#		field 'Jetbrains' => 'jetbrains';
#		field 'JZLib' => 'jzlib';
#		field 'Kingsoft Office 2013 License Agreement' => 'kingsoft-office-2013-license-agreement';
		field 'LaTeX Project Public License v1.3c (LPPL-1.3c)' =>
			'latex-project-public-license-v1.3c-(lppl-1.3c)';

#		field 'Liason License Agreement' => 'liason-license-agreement';
		field 'libtiff License' => 'libtiff-license';

#		field 'Licence for 6 box js' => 'licence-for-6-box-js';
		field 'Lisp Lesser General Public License (LLGPL)' =>
			'lisp-lesser-general-public-license';
		field 'Lucent Public License v1.02 (LPL-1.02)' =>
			'lucent-public-license-v1.02-(lpl-1.02)';
		field 'Microsoft Public License (Ms-PL)' =>
			'microsoft-public-license-(ms-pl)';
		field 'Microsoft Reciprocal License (Ms-RL)' =>
			'microsoft-reciprocal-license-(ms-rl)';
		field 'Microsoft Shared Source Community License (MS-CL)' =>
			'microsoft-shared-source-community-license-(ms-cl)';

#		field 'MinecraftForge License' => 'minecraftforge-license';
		field 'MirOS License (MirOS)' => 'miros-license-(miros)';
		field 'MIT License (Expat)'   => 'mit-license';

#		field 'MiTTY' => 'mitty';
#		field 'Motif - New Modification Principle V1 (NMPV1) License' => 'motif---new-modification-principle-v1-(nmpv1)-license';
		field 'Mozilla Public License 1.0 (MPL-1.0)' =>
			'mozilla-public-license-1.0-(mpl-1.0)';
		field 'Mozilla Public License 1.1 (MPL-1.1)' =>
			'mozilla-public-license-1.1-(mpl-1.1)';
		field 'Mozilla Public License 2.0 (MPL-2.0)' =>
			'mozilla-public-license-2.0-(mpl-2)';

#		field 'Mug Foundation open formats license' => 'mug-foundation-open-formats-license';
		field 'Multics License (Multics)' => 'multics-license-(multics)';

#		field 'Mup License' => 'mup-license';
		field 'NASA Open Source Agreement 1.3 (NASA-1.3)' =>
			'nasa-open-source-agreement-1.3-(nasa-1.3)';
		field 'Naumen Public License (Naumen)' =>
			'naumen-public-license-(naumen)';
		field 'Net Boolean Public License v1 (NBPL-1.0)' =>
			'net-boolean-public-license-v1-(nbpl-1.0)';
		field 'Nethack General Public License (NGPL)' =>
			'nethack-general-public-license-(ngpl)';
		field 'Netizen Open Source License (NOSL)' =>
			'netizen-open-source-license-(nosl)';
		field 'Netscape Public License v1.1 (NPL-1.1)' =>
			'netscape-public-license-v1.1-(npl-1.1)';

#		field 'New Relic Agent License' => 'new-relic-agent-license';
#		field 'Newsletr License' => 'newsletr-license';
		field 'Nokia Open Source License (Nokia Open Source License)' =>
			'nokia-open-source-license-(nokia-open-source-license)';

#		field 'No Limit Public License' => 'no-limit-public-license';
		field 'Non-Profit Open Software License 3.0 (NPOSL-3.0)' =>
			'non-profit-open-software-license-3.0-(nposl-3.0)';

#		field 'Noweb License' => 'noweb-license';
		field 'NTP License (NTP)' => 'ntp-license-(ntp)';
		field 'OCLC Research Public License 2.0 (OCLC-2.0)' =>
			'oclc-research-public-license-2.0-(oclc-2.0)';
		field 'ODC Open Database License (ODbL)' =>
			'odc-open-database-license-(odbl)';
		field 'ODC Public Domain Dedication & License 1.0 (PDDL-1.0)' =>
			'odc-public-domain-dedication-&-license-1.0-(pddl-1.0)';

#		field 'Open CASCADE Technology Public License v6.5' => 'open-cascade-technology-public-license-v6.5';
#		field 'OPEN GAME LICENSE (OGL)' => 'open-game-license-(ogl)';
#		field 'Open Government Licence v3 (UK)' => 'open-government-licence-v3-(uk)';
		field 'Open Group Test Suite License (OGTSL)' =>
			'open-group-test-suite-license-(ogtsl)';
		field 'OpenLDAP Public License v2.8 (OLDAP-2.8)' =>
			'openldap-public-license-v2.8-(oldap-2.8)';

#		field 'OpenMRS Public License' => 'openmrs-public-license';
		field 'Open Public License v1.0 (OPL-1.0)' =>
			'open-public-license-v1.0-(opl-1.0)';
		field 'Open Software Licence 3.0' => 'open-software-licence-3.0';
		field 'Open Software License 1.0 (OSL-1.0)' =>
			'open-software-license-1.0-(opl-1.0)';
		field 'Open Software License 1.1 (OSL-1.1)' =>
			'open-software-license-1.1-(osl-1.1)';
		field 'Open Software License 2.0 (OSL-2.0)' =>
			'open-software-license-2.0-(osl-2.0)';
		field 'Open Software License 2.1 (OSL-2.1)' =>
			'open-software-license-2.1-(osl-2.1)';
		field 'OpenSSL License (OpenSSL)' => 'openssl-license-(openssl)';

#		field 'Oracle Binary Code License Agreement for the Java SE Platform Products and JavaFX' => 'oracle-binary-code-license-agreement-for-the-java-se-platform-products-and-javafx';
		field 'Peer Production License' => 'peer-production-license';
		field 'PHP License 3.0.1'       => 'the-php-license-3.0.1';
		field 'PHP License 3.0 (PHP)'   => 'php-license-3.0-(php)';
		field 'PostgreSQL License (PostgreSQL)' =>
			'postgresql-license-(postgresql)';

#		field 'psfrag License' => 'psfrag-license';
#		field 'psutils License' => 'psutils-license';
		field 'Python License 2.0' => 'python-license-2.0';

#		field 'Qhull License' => 'qhull-license';
		field 'Q Public License 1.0 (QPL-1.0)' =>
			'q-public-license-1.0-(qpl-1.0)';

#		field 'Rdisc License' => 'rdisc-license';
		field 'RealNetworks Public Source License v1.0 (RPSL-1.0)' =>
			'realnetworks-public-source-license-v1.0-(rpsl-1.0)';
		field 'Reciprocal Public License 1.5 (RPL-1.5)' =>
			'reciprocal-public-license-1.5-(rpl-1.5)';
		field 'Red Hat eCos Public License v1.1 (RHeCos-1.1)' =>
			'red-hat-ecos-public-license-v1.1-(rhecos-1.1)';
		field 'Ricoh Source Code Public License (RSCPL)' =>
			'ricoh-source-code-public-license-(rscpl)';
		field 'Ruby License (Ruby)' => 'ruby-license-(ruby)';
		field 'Sax Public Domain Notice (SAX-PD)' =>
			'sax-public-domain-notice-(sax-pd)';

#		field 'ScheduALL Software License' => 'scheduall-software-license';
#		field 'Sendmail License' => 'sendmail-license';
		field 'SGI Free Software License B v2.0 (SGI-B-2.0)' =>
			'sgi-free-software-license-b-v2.0-(sgi-b-2.0)';

#		field 'ShinobiControls license' => 'shinobicontrols-license';
		field 'SIL Open Font License v1.1 (OFL-1.1)' =>
			'open-font-license-(ofl)-explained';
		field 'Simple Non Code License (SNCL) 2.1.0' =>
			'simple-non-code-license-2.0.2';
		field 'Simple non code license (SNCL)' =>
			'simple-non-code-license-(sncl)';
		field 'Simple Public License 2.0 (SimPL)' =>
			'simple-public-license-2.0-(simpl)';

#		field 'Skype Terms of Use' => 'skype-terms-of-use';
		field 'Sleepycat License' => 'sleepycat-license';

#		field 'SolidWorks EULA' => 'solidworks-eula';
#		field 'Space Engineers End User License Agreement' => 'space-engineers-end-user-license-agreement';
		field 'Standard ML of New Jersey License (SMLNJ)' =>
			'standard-ml-of-new-jersey-license-(smlnj)';
		field 'SugarCRM Public License v1.1.3 (SugarCRM-1.1.3)' =>
			'sugarcrm-public-license-v1.1.3-(sugarcrm-1.1.3)';
		field 'Sun Industry Standards Source License v1.2 (SISSL-1.2)' =>
			'sun-industry-standards-source-license-v1.2-(sissl-1.2)';
		field 'Sun Public License v1.0 (SPL-1.0)' =>
			'sun-public-license-v1.0-(spl-1.0)';
		field 'Sybase Open Watcom Public License 1.0 (Watcom-1.0)' =>
			'sybase-open-watcom-public-license-1.0-(watcom-1.0)';

#		field 'Tcl' => 'tcl';
		field 'The Code Project Open License (CPOL) 1.02' =>
			'the-code-project-open-license-(cpol)-1.02';
		field 'The Don\'t Ask Me About It License' =>
			'the-don\'t-ask-me-about-it-license';
		field 'The JSON License' => 'the-json-license';

#		field 'Themeforest Regular License' => 'themeforest-regular-license';
#		field 'The Spice Software License Version 1.1 (Spice-1.1)' => 'the-spice-software-license-version-1.1';
#		field 'Tóca Operating System General License 2.0 (TOSG-2.00)' => 'tosg-2.00-(toca-operating-system-general-license)';
#		field 'TORQUE v2.5+ Software License v1.1' => 'torque-v2.5+-software-license-v1.1';
#		field 'TrackingTeam Licence' => 'trackingteam-licence';
		field 'TrueCrypt License Version 3.0' =>
			'truecrypt-license-version-3.0';

#		field 'Ubuntu Font License 1.0 (UFL-1.0)' => 'ubuntu-font-license,-1.0';
		field 'Universal Permissive License 1.0 (UPL-1.0)' =>
			'universal-permissive-license-1.0-(upl-1.0)';
		field 'University of Illinois - NCSA Open Source License (NCSA)' =>
			'university-of-illinois---ncsa-open-source-license-(ncsa)';

# TODO: have this test properly handle alternate entries
#		field 'Unlicence' => 'unlicence';
		field 'Unlicense' => 'unlicense';

#		field 'Unreal Engine End User License Agreement v9' => 'unreal-engine-end-user-license-agreement-version-9';
#		field 'Use License' => 'use-license';
#		field 'VatSpy EULA' => 'vatspy-eula';
		field 'Very Simple Public License (VSPL)' =>
			'very-simple-public-license-(vspl)';

#		field 'Vivaldi Browser EULA' => 'vivaldi-browser-eula';
#		field 'VMware vSphere End User License Agreement' => 'vmware-vsphere-end-user-license-agreement';
		field 'Vovida Software License v1.0 (VSL-1.0)' =>
			'vovida-software-license-v1.0-(vsl-1.0)';
		field 'W3C Software Notice and License (W3C)' =>
			'w3c-software-notice-and-license-(w3c)';

#		field 'Wizardry License' => 'wizardry-license';
		field 'wxWindows Library License (WXwindows)' =>
			'wxwindows-library-license-(wxwindows)';
		field 'X11 License' => 'x11-license';

#		field 'Xerox License (Xerox)' => 'xerox-license-(xerox)';
		field 'XFree86 License 1.1 (XFree86-1.1)' =>
			'xfree86-license-1.1-(xfree86-1.1)';
		field 'X.Net License (Xnet)' => 'x.net-license-(xnet)';

#		field 'XSkat License' => 'xskat-license';
		field 'Yahoo! Public License v1.1 (YPL-1.1)' =>
			'yahoo!-public-license-v1.1-(ypl-1.1)';

#		field 'Zebra SDK' => 'zebra-sdk';
		field 'Zed License' => 'zed-license';
		field 'Zimbra Public License v1.3 (Zimbra-1.3)' =>
			'zimbra-public-license-v1.3-(zimbra-1.3)';
		field 'zimbra public license'      => 'zimbra-public-license';
		field 'Zlib-Libpng License (Zlib)' => 'zlib-libpng-license-(zlib)';
		field 'Zope Public License 1.1 (ZPL-1.1)' =>
			'zope-public-license-1.1-(zpl-1.1)';
		field 'Zope Public License 2.0 (ZPL-2.0)' =>
			'zope-public-license-2.0-(zpl-2.0)';
		field 'Zope Public License 2.1 (ZPL-2.1)' =>
			'zope-public-license-2.1-(zpl-2.1)';

#		field 'Zunga license' => 'zunga-license';

		end();
	},
	'coverage of <https://tldrlegal.com/search?reverse=true> (except bogus entries)'
);

done_testing;
