use Test2::V0;

use lib 't/lib';
use Test2::Tools::LicenseRegistry;

plan 1;

# Data source: <https://web.archive.org/web/20130927213143/http://spdx.org:80/licenses/>

like(
	license_org_metadata( 'spdx', { date => '20130912', rev => '1_19' } ),
	hash {
		field 'Academic Free License v1.1'          => 'AFL-1.1';
		field 'Academic Free License v1.2'          => 'AFL-1.2';
		field 'Academic Free License v2.0'          => 'AFL-2.0';
		field 'Academic Free License v2.1'          => 'AFL-2.1';
		field 'Academic Free License v3.0'          => 'AFL-3.0';
		field 'Adaptive Public License 1.0'         => 'APL-1.0';
		field 'Aladdin Free Public License'         => 'Aladdin';
		field 'ANTLR Software Rights Notice'        => 'ANTLR-PD';
		field 'Apache License 1.0'                  => 'Apache-1.0';
		field 'Apache License 1.1'                  => 'Apache-1.1';
		field 'Apache License 2.0'                  => 'Apache-2.0';
		field 'Apple Public Source License 1.0'     => 'APSL-1.0';
		field 'Apple Public Source License 1.1'     => 'APSL-1.1';
		field 'Apple Public Source License 1.2'     => 'APSL-1.2';
		field 'Apple Public Source License 2.0'     => 'APSL-2.0';
		field 'Artistic License 1.0'                => 'Artistic-1.0';
		field 'Artistic License 1.0 w/clause 8'     => 'Artistic-1.0-cl8';
		field 'Artistic License 1.0 (Perl)'         => 'Artistic-1.0-Perl';
		field 'Artistic License 2.0'                => 'Artistic-2.0';
		field 'Attribution Assurance License'       => 'AAL';
		field 'BitTorrent Open Source License v1.0' => 'BitTorrent-1.0';
		field 'BitTorrent Open Source License v1.1' => 'BitTorrent-1.1';
		field 'Boost Software License 1.0'          => 'BSL-1.0';
		field 'BSD 2-clause "Simplified" License'   => 'BSD-2-Clause';
		field 'BSD 2-clause FreeBSD License'        => 'BSD-2-Clause-FreeBSD';
		field 'BSD 2-clause NetBSD License'         => 'BSD-2-Clause-NetBSD';
		field 'BSD 3-clause "New" or "Revised" License' => 'BSD-3-Clause';
		field 'BSD 3-clause Clear License' => 'BSD-3-Clause-Clear';
		field 'BSD 4-clause "Original" or "Old" License' => 'BSD-4-Clause';
		field 'BSD-4-Clause (University of California-Specific)' =>
			'BSD-4-Clause-UC';
		field 'CeCILL Free Software License Agreement v1.0' => 'CECILL-1.0';
		field 'CeCILL Free Software License Agreement v1.1' => 'CECILL-1.1';
		field 'CeCILL Free Software License Agreement v2.0' => 'CECILL-2.0';
		field 'CeCILL-B Free Software License Agreement'    => 'CECILL-B';
		field 'CeCILL-C Free Software License Agreement'    => 'CECILL-C';
		field 'Clarified Artistic License'                  => 'ClArtistic';
		field 'CNRI Python License'                         => 'CNRI-Python';
		field 'CNRI Python Open Source GPL Compatible License Agreement' =>
			'CNRI-Python-GPL-Compatible';
		field 'Code Project Open License 1.02' => 'CPOL-1.02';
		field 'Common Development and Distribution License 1.0' => 'CDDL-1.0';
		field 'Common Development and Distribution License 1.1' => 'CDDL-1.1';
		field 'Common Public Attribution License 1.0'           => 'CPAL-1.0';
		field 'Common Public License 1.0'                       => 'CPL-1.0';
		field 'Computer Associates Trusted Open Source License 1.1' =>
			'CATOSL-1.1';
		field 'Condor Public License v1.1'       => 'Condor-1.1';
		field 'Creative Commons Attribution 1.0' => 'CC-BY-1.0';
		field 'Creative Commons Attribution 2.0' => 'CC-BY-2.0';
		field 'Creative Commons Attribution 2.5' => 'CC-BY-2.5';
		field 'Creative Commons Attribution 3.0' => 'CC-BY-3.0';
		field 'Creative Commons Attribution No Derivatives 1.0' =>
			'CC-BY-ND-1.0';
		field 'Creative Commons Attribution No Derivatives 2.0' =>
			'CC-BY-ND-2.0';
		field 'Creative Commons Attribution No Derivatives 2.5' =>
			'CC-BY-ND-2.5';
		field 'Creative Commons Attribution No Derivatives 3.0' =>
			'CC-BY-ND-3.0';
		field 'Creative Commons Attribution Non Commercial 1.0' =>
			'CC-BY-NC-1.0';
		field 'Creative Commons Attribution Non Commercial 2.0' =>
			'CC-BY-NC-2.0';
		field 'Creative Commons Attribution Non Commercial 2.5' =>
			'CC-BY-NC-2.5';
		field 'Creative Commons Attribution Non Commercial 3.0' =>
			'CC-BY-NC-3.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 1.0'
			=> 'CC-BY-NC-ND-1.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 2.0'
			=> 'CC-BY-NC-ND-2.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 2.5'
			=> 'CC-BY-NC-ND-2.5';
		field 'Creative Commons Attribution Non Commercial No Derivatives 3.0'
			=> 'CC-BY-NC-ND-3.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 1.0' =>
			'CC-BY-NC-SA-1.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 2.0' =>
			'CC-BY-NC-SA-2.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 2.5' =>
			'CC-BY-NC-SA-2.5';
		field 'Creative Commons Attribution Non Commercial Share Alike 3.0' =>
			'CC-BY-NC-SA-3.0';
		field 'Creative Commons Attribution Share Alike 1.0' =>
			'CC-BY-SA-1.0';
		field 'Creative Commons Attribution Share Alike 2.0' =>
			'CC-BY-SA-2.0';
		field 'Creative Commons Attribution Share Alike 2.5' =>
			'CC-BY-SA-2.5';
		field 'Creative Commons Attribution Share Alike 3.0' =>
			'CC-BY-SA-3.0';
		field 'Creative Commons Zero v1.0 Universal'        => 'CC0-1.0';
		field 'CUA Office Public License v1.0'              => 'CUA-OPL-1.0';
		field 'Deutsche Freie Software Lizenz'              => 'D-FSL-1.0';
		field 'Do What The F*ck You Want To Public License' => 'WTFPL';
		field 'Eclipse Public License 1.0'                  => 'EPL-1.0';
		field 'eCos license version 2.0'                    => 'eCos-2.0';
		field 'Educational Community License v1.0'          => 'ECL-1.0';
		field 'Educational Community License v2.0'          => 'ECL-2.0';
		field 'Eiffel Forum License v1.0'                   => 'EFL-1.0';
		field 'Eiffel Forum License v2.0'                   => 'EFL-2.0';
		field 'Entessa Public License v1.0'                 => 'Entessa';
		field 'Erlang Public License v1.1'                  => 'ErlPL-1.1';
		field 'EU DataGrid Software License'                => 'EUDatagrid';
		field 'European Union Public License 1.0'           => 'EUPL-1.0';
		field 'European Union Public License 1.1'           => 'EUPL-1.1';
		field 'Fair License'                                => 'Fair';
		field 'Frameworx Open License 1.0'               => 'Frameworx-1.0';
		field 'Freetype Project License'                 => 'FTL';
		field 'GNU Affero General Public License v1.0'   => 'AGPL-1.0';
		field 'GNU Affero General Public License v3.0'   => 'AGPL-3.0';
		field 'GNU Free Documentation License v1.1'      => 'GFDL-1.1';
		field 'GNU Free Documentation License v1.2'      => 'GFDL-1.2';
		field 'GNU Free Documentation License v1.3'      => 'GFDL-1.3';
		field 'GNU General Public License v1.0 only'     => 'GPL-1.0';
		field 'GNU General Public License v1.0 or later' => 'GPL-1.0+';
		field 'GNU General Public License v2.0 only'     => 'GPL-2.0';
		field 'GNU General Public License v2.0 or later' => 'GPL-2.0+';
		field 'GNU General Public License v2.0 w/Autoconf exception' =>
			'GPL-2.0-with-autoconf-exception';
		field 'GNU General Public License v2.0 w/Bison exception' =>
			'GPL-2.0-with-bison-exception';
		field 'GNU General Public License v2.0 w/Classpath exception' =>
			'GPL-2.0-with-classpath-exception';
		field 'GNU General Public License v2.0 w/Font exception' =>
			'GPL-2.0-with-font-exception';
		field
			'GNU General Public License v2.0 w/GCC Runtime Library exception'
			=> 'GPL-2.0-with-GCC-exception';
		field 'GNU General Public License v3.0 only'     => 'GPL-3.0';
		field 'GNU General Public License v3.0 or later' => 'GPL-3.0+';
		field 'GNU General Public License v3.0 w/Autoconf exception' =>
			'GPL-3.0-with-autoconf-exception';
		field
			'GNU General Public License v3.0 w/GCC Runtime Library exception'
			=> 'GPL-3.0-with-GCC-exception';
		field 'GNU Lesser General Public License v2.1 only'     => 'LGPL-2.1';
		field 'GNU Lesser General Public License v2.1 or later' =>
			'LGPL-2.1+';
		field 'GNU Lesser General Public License v3.0 only'     => 'LGPL-3.0';
		field 'GNU Lesser General Public License v3.0 or later' =>
			'LGPL-3.0+';
		field 'GNU Library General Public License v2 only'     => 'LGPL-2.0';
		field 'GNU Library General Public License v2 or later' => 'LGPL-2.0+';
		field 'gSOAP Public License v1.3b'                   => 'gSOAP-1.3b';
		field 'Historic Permission Notice and Disclaimer'    => 'HPND';
		field 'IBM PowerPC Initialization and Boot Software' => 'IBM-pibs';
		field 'IBM Public License v1.0'                      => 'IPL-1.0';
		field 'Imlib2 License'                               => 'Imlib2';
		field 'Independent JPEG Group License'               => 'IJG';
		field 'Intel Open Source License'                    => 'Intel';
		field 'IPA Font License'                             => 'IPA';
		field 'ISC License'                                  => 'ISC';
		field 'JSON License'                                 => 'JSON';
		field 'LaTeX Project Public License 1.3a'            => 'LPPL-1.3a';
		field 'LaTeX Project Public License v1.0'            => 'LPPL-1.0';
		field 'LaTeX Project Public License v1.1'            => 'LPPL-1.1';
		field 'LaTeX Project Public License v1.2'            => 'LPPL-1.2';
		field 'LaTeX Project Public License v1.3c'           => 'LPPL-1.3c';
		field 'libpng License'                               => 'Libpng';
		field 'Lucent Public License v1.02'                  => 'LPL-1.02';
		field 'Lucent Public License Version 1.0'            => 'LPL-1.0';
		field 'Microsoft Public License'                     => 'MS-PL';
		field 'Microsoft Reciprocal License'                 => 'MS-RL';
		field 'MirOS Licence'                                => 'MirOS';
		field 'MIT License'                                  => 'MIT';
		field 'Motosoto License'                             => 'Motosoto';
		field 'Mozilla Public License 1.0'                   => 'MPL-1.0';
		field 'Mozilla Public License 1.1'                   => 'MPL-1.1';
		field 'Mozilla Public License 2.0'                   => 'MPL-2.0';
		field 'Mozilla Public License 2.0 (no copyleft exception)' =>
			'MPL-2.0-no-copyleft-exception';
		field 'Multics License'                            => 'Multics';
		field 'NASA Open Source Agreement 1.3'             => 'NASA-1.3';
		field 'Naumen Public License'                      => 'Naumen';
		field 'Net Boolean Public License v1'              => 'NBPL-1.0';
		field 'Nethack General Public License'             => 'NGPL';
		field 'Netizen Open Source License'                => 'NOSL';
		field 'Netscape Public License v1.0'               => 'NPL-1.0';
		field 'Netscape Public License v1.1'               => 'NPL-1.1';
		field 'Nokia Open Source License'                  => 'Nokia';
		field 'Non-Profit Open Software License 3.0'       => 'NPOSL-3.0';
		field 'NTP License'                                => 'NTP';
		field 'OCLC Research Public License 2.0'           => 'OCLC-2.0';
		field 'ODC Open Database License v1.0'             => 'ODbL-1.0';
		field 'ODC Public Domain Dedication & License 1.0' => 'PDDL-1.0';
		field 'Open Group Test Suite License'              => 'OGTSL';
		field 'Open LDAP Public License 2.2.2'             => 'OLDAP-2.2.2';
		field 'Open LDAP Public License v1.1'              => 'OLDAP-1.1';
		field 'Open LDAP Public License v1.2'              => 'OLDAP-1.2';
		field 'Open LDAP Public License v1.3'              => 'OLDAP-1.3';
		field 'Open LDAP Public License v1.4'              => 'OLDAP-1.4';
		field 'Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)' =>
			'OLDAP-2.0';
		field 'Open LDAP Public License v2.0.1'         => 'OLDAP-2.0.1';
		field 'Open LDAP Public License v2.1'           => 'OLDAP-2.1';
		field 'Open LDAP Public License v2.2'           => 'OLDAP-2.2';
		field 'Open LDAP Public License v2.2.1'         => 'OLDAP-2.2.1';
		field 'Open LDAP Public License v2.3'           => 'OLDAP-2.3';
		field 'Open LDAP Public License v2.4'           => 'OLDAP-2.4';
		field 'Open LDAP Public License v2.5'           => 'OLDAP-2.5';
		field 'Open LDAP Public License v2.6'           => 'OLDAP-2.6';
		field 'Open LDAP Public License v2.7'           => 'OLDAP-2.7';
		field 'Open Public License v1.0'                => 'OPL-1.0';
		field 'Open Software License 1.0'               => 'OSL-1.0';
		field 'Open Software License 2.0'               => 'OSL-2.0';
		field 'Open Software License 2.1'               => 'OSL-2.1';
		field 'Open Software License 3.0'               => 'OSL-3.0';
		field 'OpenLDAP Public License v2.8'            => 'OLDAP-2.8';
		field 'OpenSSL License'                         => 'OpenSSL';
		field 'PHP License v3.0'                        => 'PHP-3.0';
		field 'PHP License v3.01'                       => 'PHP-3.01';
		field 'PostgreSQL License'                      => 'PostgreSQL';
		field 'Python License 2.0'                      => 'Python-2.0';
		field 'Q Public License 1.0'                    => 'QPL-1.0';
		field 'RealNetworks Public Source License v1.0' => 'RPSL-1.0';
		field 'Reciprocal Public License 1.1'           => 'RPL-1.1';
		field 'Reciprocal Public License 1.5'           => 'RPL-1.5';
		field 'Red Hat eCos Public License v1.1'        => 'RHeCos-1.1';
		field 'Ricoh Source Code Public License'        => 'RSCPL';
		field 'Ruby License'                            => 'Ruby';
		field 'Sax Public Domain Notice'                => 'SAX-PD';
		field 'SGI Free Software License B v1.0'        => 'SGI-B-1.0';
		field 'SGI Free Software License B v1.1'        => 'SGI-B-1.1';
		field 'SGI Free Software License B v2.0'        => 'SGI-B-2.0';
		field 'SIL Open Font License 1.0'               => 'OFL-1.0';
		field 'SIL Open Font License 1.1'               => 'OFL-1.1';
		field 'Simple Public License 2.0'               => 'SimPL-2.0';
		field 'Sleepycat License'                       => 'Sleepycat';
		field 'Standard ML of New Jersey License'       => 'SMLNJ';
		field 'SugarCRM Public License v1.1.3'          => 'SugarCRM-1.1.3';
		field 'Sun Industry Standards Source License v1.1' => 'SISSL';
		field 'Sun Industry Standards Source License v1.2' => 'SISSL-1.2';
		field 'Sun Public License v1.0'                    => 'SPL-1.0';
		field 'Sybase Open Watcom Public License 1.0'      => 'Watcom-1.0';
		field 'University of Illinois/NCSA Open Source License' => 'NCSA';
		field 'Vovida Software License v1.0'                    => 'VSL-1.0';
		field 'W3C Software Notice and License'                 => 'W3C';
		field 'wxWindows Library License'  => 'WXwindows';
		field 'X.Net License'              => 'Xnet';
		field 'X11 License'                => 'X11';
		field 'XFree86 License 1.1'        => 'XFree86-1.1';
		field 'Yahoo! Public License v1.0' => 'YPL-1.0';
		field 'Yahoo! Public License v1.1' => 'YPL-1.1';
		field 'Zimbra Public License v1.3' => 'Zimbra-1.3';
		field 'zlib License'               => 'Zlib';
		field 'Zope Public License 1.1'    => 'ZPL-1.1';
		field 'Zope Public License 2.0'    => 'ZPL-2.0';
		field 'Zope Public License 2.1'    => 'ZPL-2.1';
		field 'The Unlicense'              => 'Unlicense';

		end();
	},
	'coverage of SPDX 1.19, git tagged 2013-09-12'
);

done_testing;
