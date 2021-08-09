use Test2::V0;

use lib 't/lib';
use Test2::Regexp::Pattern::License;

plan 1;

# Data source: <https://web.archive.org/web/20171230141353/https://spdx.org/licenses/>

like(
	license_org_metadata( 'spdx', { date => '20171228', rev => '3' } ),
	hash {
		field 'BSD Zero Clause License'       => '0BSD';
		field 'Attribution Assurance License' => 'AAL';
		field 'Abstyles License'              => 'Abstyles';
		field 'Adobe Systems Incorporated Source Code License Agreement' =>
			'Adobe-2006';
		field 'Adobe Glyph List License'           => 'Adobe-Glyph';
		field 'Amazon Digital Services License'    => 'ADSL';
		field 'Academic Free License v1.1'         => 'AFL-1.1';
		field 'Academic Free License v1.2'         => 'AFL-1.2';
		field 'Academic Free License v2.0'         => 'AFL-2.0';
		field 'Academic Free License v2.1'         => 'AFL-2.1';
		field 'Academic Free License v3.0'         => 'AFL-3.0';
		field 'Afmparse License'                   => 'Afmparse';
		field 'Affero General Public License v1.0' => 'AGPL-1.0';
		field 'GNU Affero General Public License v3.0 only' =>
			'AGPL-3.0-only';
		field 'GNU Affero General Public License v3.0 or later' =>
			'AGPL-3.0-or-later';
		field 'Aladdin Free Public License'                     => 'Aladdin';
		field 'AMD\'s plpa_map.c License'                       => 'AMDPLPA';
		field 'Apple MIT License'                               => 'AML';
		field 'Academy of Motion Picture Arts and Sciences BSD' => 'AMPAS';
		field 'ANTLR Software Rights Notice'                    => 'ANTLR-PD';
		field 'Apache License 1.0'                  => 'Apache-1.0';
		field 'Apache License 1.1'                  => 'Apache-1.1';
		field 'Apache License 2.0'                  => 'Apache-2.0';
		field 'Adobe Postscript AFM License'        => 'APAFML';
		field 'Adaptive Public License 1.0'         => 'APL-1.0';
		field 'Apple Public Source License 1.0'     => 'APSL-1.0';
		field 'Apple Public Source License 1.1'     => 'APSL-1.1';
		field 'Apple Public Source License 1.2'     => 'APSL-1.2';
		field 'Apple Public Source License 2.0'     => 'APSL-2.0';
		field 'Artistic License 1.0'                => 'Artistic-1.0';
		field 'Artistic License 1.0 w/clause 8'     => 'Artistic-1.0-cl8';
		field 'Artistic License 1.0 (Perl)'         => 'Artistic-1.0-Perl';
		field 'Artistic License 2.0'                => 'Artistic-2.0';
		field 'Bahyph License'                      => 'Bahyph';
		field 'Barr License'                        => 'Barr';
		field 'Beerware License'                    => 'Beerware';
		field 'BitTorrent Open Source License v1.0' => 'BitTorrent-1.0';
		field 'BitTorrent Open Source License v1.1' => 'BitTorrent-1.1';
		field 'Borceux license'                     => 'Borceux';
		field 'BSD 1-Clause License'                => 'BSD-1-Clause';
		field 'BSD 2-Clause "Simplified" License'   => 'BSD-2-Clause';
		field 'BSD 2-Clause FreeBSD License'        => 'BSD-2-Clause-FreeBSD';
		field 'BSD 2-Clause NetBSD License'         => 'BSD-2-Clause-NetBSD';
		field 'BSD-2-Clause Plus Patent License'    => 'BSD-2-Clause-Patent';
		field 'BSD 3-Clause "New" or "Revised" License' => 'BSD-3-Clause';
		field 'BSD with attribution'       => 'BSD-3-Clause-Attribution';
		field 'BSD 3-Clause Clear License' => 'BSD-3-Clause-Clear';
		field 'Lawrence Berkeley National Labs BSD variant license' =>
			'BSD-3-Clause-LBNL';
		field 'BSD 3-Clause No Nuclear License' =>
			'BSD-3-Clause-No-Nuclear-License';
		field 'BSD 3-Clause No Nuclear License 2014' =>
			'BSD-3-Clause-No-Nuclear-License-2014';
		field 'BSD 3-Clause No Nuclear Warranty' =>
			'BSD-3-Clause-No-Nuclear-Warranty';
		field 'BSD 4-Clause "Original" or "Old" License' => 'BSD-4-Clause';
		field 'BSD-4-Clause (University of California-Specific)' =>
			'BSD-4-Clause-UC';
		field 'BSD Protection License' => 'BSD-Protection';

#		field 'BSD Source Code Attribution'       => 'BSD-Source-Code';
		field 'Boost Software License 1.0'        => 'BSL-1.0';
		field 'bzip2 and libbzip2 License v1.0.5' => 'bzip2-1.0.5';
		field 'bzip2 and libbzip2 License v1.0.6' => 'bzip2-1.0.6';
		field 'Caldera License'                   => 'Caldera';
		field 'Computer Associates Trusted Open Source License 1.1' =>
			'CATOSL-1.1';
		field 'Creative Commons Attribution 1.0' => 'CC-BY-1.0';
		field 'Creative Commons Attribution 2.0' => 'CC-BY-2.0';
		field 'Creative Commons Attribution 2.5' => 'CC-BY-2.5';
		field 'Creative Commons Attribution 3.0' => 'CC-BY-3.0';
		field 'Creative Commons Attribution 4.0' => 'CC-BY-4.0';
		field 'Creative Commons Attribution Non Commercial 1.0' =>
			'CC-BY-NC-1.0';
		field 'Creative Commons Attribution Non Commercial 2.0' =>
			'CC-BY-NC-2.0';
		field 'Creative Commons Attribution Non Commercial 2.5' =>
			'CC-BY-NC-2.5';
		field 'Creative Commons Attribution Non Commercial 3.0' =>
			'CC-BY-NC-3.0';
		field 'Creative Commons Attribution Non Commercial 4.0' =>
			'CC-BY-NC-4.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 1.0'
			=> 'CC-BY-NC-ND-1.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 2.0'
			=> 'CC-BY-NC-ND-2.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 2.5'
			=> 'CC-BY-NC-ND-2.5';
		field 'Creative Commons Attribution Non Commercial No Derivatives 3.0'
			=> 'CC-BY-NC-ND-3.0';
		field 'Creative Commons Attribution Non Commercial No Derivatives 4.0'
			=> 'CC-BY-NC-ND-4.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 1.0' =>
			'CC-BY-NC-SA-1.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 2.0' =>
			'CC-BY-NC-SA-2.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 2.5' =>
			'CC-BY-NC-SA-2.5';
		field 'Creative Commons Attribution Non Commercial Share Alike 3.0' =>
			'CC-BY-NC-SA-3.0';
		field 'Creative Commons Attribution Non Commercial Share Alike 4.0' =>
			'CC-BY-NC-SA-4.0';
		field 'Creative Commons Attribution No Derivatives 1.0' =>
			'CC-BY-ND-1.0';
		field 'Creative Commons Attribution No Derivatives 2.0' =>
			'CC-BY-ND-2.0';
		field 'Creative Commons Attribution No Derivatives 2.5' =>
			'CC-BY-ND-2.5';
		field 'Creative Commons Attribution No Derivatives 3.0' =>
			'CC-BY-ND-3.0';
		field 'Creative Commons Attribution No Derivatives 4.0' =>
			'CC-BY-ND-4.0';
		field 'Creative Commons Attribution Share Alike 1.0' =>
			'CC-BY-SA-1.0';
		field 'Creative Commons Attribution Share Alike 2.0' =>
			'CC-BY-SA-2.0';
		field 'Creative Commons Attribution Share Alike 2.5' =>
			'CC-BY-SA-2.5';
		field 'Creative Commons Attribution Share Alike 3.0' =>
			'CC-BY-SA-3.0';
		field 'Creative Commons Attribution Share Alike 4.0' =>
			'CC-BY-SA-4.0';
		field 'Creative Commons Zero v1.0 Universal'            => 'CC0-1.0';
		field 'Common Development and Distribution License 1.0' => 'CDDL-1.0';
		field 'Common Development and Distribution License 1.1' => 'CDDL-1.1';

#		field 'Community Data License Agreement Permissive 1.0' =>
#			'CDLA-Permissive-1.0';
#		field 'Community Data License Agreement Sharing 1.0' =>
#			'CDLA-Sharing-1.0';
		field 'CeCILL Free Software License Agreement v1.0' => 'CECILL-1.0';
		field 'CeCILL Free Software License Agreement v1.1' => 'CECILL-1.1';
		field 'CeCILL Free Software License Agreement v2.0' => 'CECILL-2.0';
		field 'CeCILL Free Software License Agreement v2.1' => 'CECILL-2.1';
		field 'CeCILL-B Free Software License Agreement'    => 'CECILL-B';
		field 'CeCILL-C Free Software License Agreement'    => 'CECILL-C';
		field 'Clarified Artistic License'                  => 'ClArtistic';
		field 'CNRI Jython License'                         => 'CNRI-Jython';
		field 'CNRI Python License'                         => 'CNRI-Python';
		field 'CNRI Python Open Source GPL Compatible License Agreement' =>
			'CNRI-Python-GPL-Compatible';
		field 'Condor Public License v1.1'            => 'Condor-1.1';
		field 'Common Public Attribution License 1.0' => 'CPAL-1.0';
		field 'Common Public License 1.0'             => 'CPL-1.0';
		field 'Code Project Open License 1.02'        => 'CPOL-1.02';
		field 'Crossword License'                     => 'Crossword';

#		field 'CrystalStacker License'                => 'CrystalStacker';
		field 'CUA Office Public License v1.0' => 'CUA-OPL-1.0';
		field 'Cube License'                   => 'Cube';
		field 'curl License'                   => 'curl';
		field 'Deutsche Freie Software Lizenz' => 'D-FSL-1.0';

#		field 'diffmark license'                      => 'diffmark';
#		field 'DOC License'                           => 'DOC';
#		field 'Dotseqn License'                       => 'Dotseqn';
		field 'DSDP License' => 'DSDP';

#		field 'dvipdfm License'                       => 'dvipdfm';
		field 'Educational Community License v1.0' => 'ECL-1.0';
		field 'Educational Community License v2.0' => 'ECL-2.0';
		field 'Eiffel Forum License v1.0'          => 'EFL-1.0';
		field 'Eiffel Forum License v2.0'          => 'EFL-2.0';

#		field 'eGenix.com Public License 1.1.0'       => 'eGenix';
		field 'Entessa Public License v1.0'       => 'Entessa';
		field 'Eclipse Public License 1.0'        => 'EPL-1.0';
		field 'Eclipse Public License 2.0'        => 'EPL-2.0';
		field 'Erlang Public License v1.1'        => 'ErlPL-1.1';
		field 'EU DataGrid Software License'      => 'EUDatagrid';
		field 'European Union Public License 1.0' => 'EUPL-1.0';
		field 'European Union Public License 1.1' => 'EUPL-1.1';
		field 'European Union Public License 1.2' => 'EUPL-1.2';
		field 'Eurosym License'                   => 'Eurosym';
		field 'Fair License'                      => 'Fair';
		field 'Frameworx Open License 1.0'        => 'Frameworx-1.0';

#		field 'FreeImage Public License v1.0'         => 'FreeImage';
		field 'FSF All Permissive License'                     => 'FSFAP';
		field 'FSF Unlimited License'                          => 'FSFUL';
		field 'FSF Unlimited License (with License Retention)' => 'FSFULLR';
		field 'Freetype Project License'                       => 'FTL';
		field 'GNU Free Documentation License v1.1 only' => 'GFDL-1.1-only';
		field 'GNU Free Documentation License v1.1 or later' =>
			'GFDL-1.1-or-later';
		field 'GNU Free Documentation License v1.2 only' => 'GFDL-1.2-only';
		field 'GNU Free Documentation License v1.2 or later' =>
			'GFDL-1.2-or-later';
		field 'GNU Free Documentation License v1.3 only' => 'GFDL-1.3-only';
		field 'GNU Free Documentation License v1.3 or later' =>
			'GFDL-1.3-or-later';

#		field 'Giftware License'                     => 'Giftware';
		field '3dfx Glide License' => 'Glide';

#		field 'GL2PS License'                        => 'GL2PS';
#		field 'Glulxe License'                       => 'Glulxe';
#		field 'gnuplot License'                      => 'gnuplot';
		field 'GNU General Public License v1.0 only' => 'GPL-1.0-only';
		field 'GNU General Public License v1.0 or later' =>
			'GPL-1.0-or-later';
		field 'GNU General Public License v2.0 only' => 'GPL-2.0-only';
		field 'GNU General Public License v2.0 or later' =>
			'GPL-2.0-or-later';
		field 'GNU General Public License v3.0 only' => 'GPL-3.0-only';
		field 'GNU General Public License v3.0 or later' =>
			'GPL-3.0-or-later';
		field 'gSOAP Public License v1.3b' => 'gSOAP-1.3b';

#		field 'Haskell Language Report License' => 'HaskellReport';
		field 'Historical Permission Notice and Disclaimer'  => 'HPND';
		field 'IBM PowerPC Initialization and Boot Software' => 'IBM-pibs';
		field 'ICU License'                                  => 'ICU';
		field 'Independent JPEG Group License'               => 'IJG';

#		field 'ImageMagick License'                          => 'ImageMagick';
#		field 'iMatix Standard Function Library Agreement'   => 'iMatix';
		field 'Imlib2 License' => 'Imlib2';

#		field 'Info-ZIP License'                             => 'Info-ZIP';
		field 'Intel Open Source License' => 'Intel';

#		field 'Intel ACPI Software License Agreement'        => 'Intel-ACPI';
#		field 'Interbase Public License v1.0'              => 'Interbase-1.0';
		field 'IPA Font License'        => 'IPA';
		field 'IBM Public License v1.0' => 'IPL-1.0';
		field 'ISC License'             => 'ISC';

#		field 'JasPer License'                             => 'JasPer-2.0';
		field 'JSON License' => 'JSON';

#		field 'Licence Art Libre 1.2'                      => 'LAL-1.2';
#		field 'Licence Art Libre 1.3'                      => 'LAL-1.3';
#		field 'Latex2e License'                            => 'Latex2e';
		field 'Leptonica License'                          => 'Leptonica';
		field 'GNU Library General Public License v2 only' => 'LGPL-2.0-only';
		field 'GNU Library General Public License v2 or later' =>
			'LGPL-2.0-or-later';
		field 'GNU Lesser General Public License v2.1 only' =>
			'LGPL-2.1-only';
		field 'GNU Lesser General Public License v2.1 or later' =>
			'LGPL-2.1-or-later';
		field 'GNU Lesser General Public License v3.0 only' =>
			'LGPL-3.0-only';
		field 'GNU Lesser General Public License v3.0 or later' =>
			'LGPL-3.0-or-later';

#		field 'Lesser General Public License For Linguistic Resources' =>
#			'LGPLLR';
		field 'libpng License'  => 'Libpng';
		field 'libtiff License' => 'libtiff';
		field 'Licence Libre du Québec – Permissive version 1.1' =>
			'LiLiQ-P-1.1';
		field 'Licence Libre du Québec – Réciprocité version 1.1' =>
			'LiLiQ-R-1.1';
		field
			'Licence Libre du Québec – Réciprocité forte version 1.1' =>
			'LiLiQ-Rplus-1.1';
		field 'Lucent Public License Version 1.0'  => 'LPL-1.0';
		field 'Lucent Public License v1.02'        => 'LPL-1.02';
		field 'LaTeX Project Public License v1.0'  => 'LPPL-1.0';
		field 'LaTeX Project Public License v1.1'  => 'LPPL-1.1';
		field 'LaTeX Project Public License v1.2'  => 'LPPL-1.2';
		field 'LaTeX Project Public License v1.3a' => 'LPPL-1.3a';
		field 'LaTeX Project Public License v1.3c' => 'LPPL-1.3c';

#		field 'MakeIndex License'                  => 'MakeIndex';
		field 'MirOS License'               => 'MirOS';
		field 'MIT License'                 => 'MIT';
		field 'Enlightenment License (e16)' => 'MIT-advertising';
		field 'CMU License'                 => 'MIT-CMU';
		field 'enna License'                => 'MIT-enna';
		field 'feh License'                 => 'MIT-feh';

#		field 'MIT +no-false-attribs license'      => 'MITNFA';
		field 'Motosoto License'           => 'Motosoto';
		field 'mpich2 License'             => 'mpich2';
		field 'Mozilla Public License 1.0' => 'MPL-1.0';
		field 'Mozilla Public License 1.1' => 'MPL-1.1';
		field 'Mozilla Public License 2.0' => 'MPL-2.0';
		field 'Mozilla Public License 2.0 (no copyleft exception)' =>
			'MPL-2.0-no-copyleft-exception';
		field 'Microsoft Public License'     => 'MS-PL';
		field 'Microsoft Reciprocal License' => 'MS-RL';

#		field 'Matrix Template Library License'                 => 'MTLL';
		field 'Multics License' => 'Multics';

#		field 'Mup License'                                     => 'Mup';
		field 'NASA Open Source Agreement 1.3'                  => 'NASA-1.3';
		field 'Naumen Public License'                           => 'Naumen';
		field 'Net Boolean Public License v1'                   => 'NBPL-1.0';
		field 'University of Illinois/NCSA Open Source License' => 'NCSA';
		field 'Net-SNMP License'                                => 'Net-SNMP';

#		field 'NetCDF license'                                  => 'NetCDF';
#		field 'Newsletr License'                                => 'Newsletr';
		field 'Nethack General Public License' => 'NGPL';

#		field 'Norwegian Licence for Open Government Data'      => 'NLOD-1.0';
#		field 'No Limit Public License'                         => 'NLPL';
		field 'Nokia Open Source License'   => 'Nokia';
		field 'Netizen Open Source License' => 'NOSL';

#		field 'Noweb License'                                   => 'Noweb';
		field 'Netscape Public License v1.0'         => 'NPL-1.0';
		field 'Netscape Public License v1.1'         => 'NPL-1.1';
		field 'Non-Profit Open Software License 3.0' => 'NPOSL-3.0';

#		field 'NRL License'                            => 'NRL';
		field 'NTP License' => 'NTP';

#		field 'Open CASCADE Technology Public License' => 'OCCT-PL';
		field 'OCLC Research Public License 2.0' => 'OCLC-2.0';
		field 'ODC Open Database License v1.0'   => 'ODbL-1.0';
		field 'SIL Open Font License 1.0'        => 'OFL-1.0';
		field 'SIL Open Font License 1.1'        => 'OFL-1.1';
		field 'Open Group Test Suite License'    => 'OGTSL';
		field 'Open LDAP Public License v1.1'    => 'OLDAP-1.1';
		field 'Open LDAP Public License v1.2'    => 'OLDAP-1.2';
		field 'Open LDAP Public License v1.3'    => 'OLDAP-1.3';
		field 'Open LDAP Public License v1.4'    => 'OLDAP-1.4';
		field 'Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)' =>
			'OLDAP-2.0';
		field 'Open LDAP Public License v2.0.1' => 'OLDAP-2.0.1';
		field 'Open LDAP Public License v2.1'   => 'OLDAP-2.1';
		field 'Open LDAP Public License v2.2'   => 'OLDAP-2.2';
		field 'Open LDAP Public License v2.2.1' => 'OLDAP-2.2.1';
		field 'Open LDAP Public License 2.2.2'  => 'OLDAP-2.2.2';
		field 'Open LDAP Public License v2.3'   => 'OLDAP-2.3';
		field 'Open LDAP Public License v2.4'   => 'OLDAP-2.4';
		field 'Open LDAP Public License v2.5'   => 'OLDAP-2.5';
		field 'Open LDAP Public License v2.6'   => 'OLDAP-2.6';
		field 'Open LDAP Public License v2.7'   => 'OLDAP-2.7';
		field 'Open LDAP Public License v2.8'   => 'OLDAP-2.8';

#		field 'Open Market License'                        => 'OML';
		field 'OpenSSL License'                            => 'OpenSSL';
		field 'Open Public License v1.0'                   => 'OPL-1.0';
		field 'OSET Public License version 2.1'            => 'OSET-PL-2.1';
		field 'Open Software License 1.0'                  => 'OSL-1.0';
		field 'Open Software License 1.1'                  => 'OSL-1.1';
		field 'Open Software License 2.0'                  => 'OSL-2.0';
		field 'Open Software License 2.1'                  => 'OSL-2.1';
		field 'Open Software License 3.0'                  => 'OSL-3.0';
		field 'ODC Public Domain Dedication & License 1.0' => 'PDDL-1.0';
		field 'PHP License v3.0'                           => 'PHP-3.0';
		field 'PHP License v3.01'                          => 'PHP-3.01';

#		field 'Plexus Classworlds License'                 => 'Plexus';
		field 'PostgreSQL License' => 'PostgreSQL';

#		field 'psfrag License'                             => 'psfrag';
#		field 'psutils License'                            => 'psutils';
		field 'Python License 2.0' => 'Python-2.0';

#		field 'Qhull License'                              => 'Qhull';
		field 'Q Public License 1.0' => 'QPL-1.0';

#		field 'Rdisc License'                              => 'Rdisc';
		field 'Red Hat eCos Public License v1.1'        => 'RHeCos-1.1';
		field 'Reciprocal Public License 1.1'           => 'RPL-1.1';
		field 'Reciprocal Public License 1.5'           => 'RPL-1.5';
		field 'RealNetworks Public Source License v1.0' => 'RPSL-1.0';

#		field 'RSA Message-Digest License'                 => 'RSA-MD';
		field 'Ricoh Source Code Public License' => 'RSCPL';
		field 'Ruby License'                     => 'Ruby';
		field 'Sax Public Domain Notice'         => 'SAX-PD';

#		field 'Saxpath License'                            => 'Saxpath';
#		field 'SCEA Shared Source License'                 => 'SCEA';
#		field 'Sendmail License'                           => 'Sendmail';
		field 'SGI Free Software License B v1.0'           => 'SGI-B-1.0';
		field 'SGI Free Software License B v1.1'           => 'SGI-B-1.1';
		field 'SGI Free Software License B v2.0'           => 'SGI-B-2.0';
		field 'Simple Public License 2.0'                  => 'SimPL-2.0';
		field 'Sun Industry Standards Source License v1.1' => 'SISSL';
		field 'Sun Industry Standards Source License v1.2' => 'SISSL-1.2';
		field 'Sleepycat License'                          => 'Sleepycat';
		field 'Standard ML of New Jersey License'          => 'SMLNJ';

#		field 'Secure Messaging Protocol Public License'   => 'SMPPL';
#		field 'SNIA Public License 1.1'                    => 'SNIA';
#		field 'Spencer License 86'                         => 'Spencer-86';
#		field 'Spencer License 94'                         => 'Spencer-94';
#		field 'Spencer License 99'                         => 'Spencer-99';
		field 'Sun Public License v1.0'        => 'SPL-1.0';
		field 'SugarCRM Public License v1.1.3' => 'SugarCRM-1.1.3';

#		field 'Scheme Widget Library (SWL) Software License Agreement' =>
#			'SWL';
#		field 'TCL/TK License'                     => 'TCL';
#		field 'TCP Wrappers License'               => 'TCP-wrappers';
#		field 'TMate Open Source License'          => 'TMate';
#		field 'TORQUE v2.5+ Software License v1.1' => 'TORQUE-1.1';
		field 'Trusster Open Source License' => 'TOSL';
		field 'Unicode License Agreement - Data Files and Software (2015)' =>
			'Unicode-DFS-2015';
		field 'Unicode License Agreement - Data Files and Software (2016)' =>
			'Unicode-DFS-2016';
		field 'Unicode Terms of Use'              => 'Unicode-TOU';
		field 'The Unlicense'                     => 'Unlicense';
		field 'Universal Permissive License v1.0' => 'UPL-1.0';

#		field 'Vim License'                                  => 'Vim';
#		field 'VOSTROM Public License for Open Source'       => 'VOSTROM';
		field 'Vovida Software License v1.0'                 => 'VSL-1.0';
		field 'W3C Software Notice and License (2002-12-31)' => 'W3C';
		field 'W3C Software Notice and License (1998-07-20)' =>
			'W3C-19980720';
		field 'W3C Software Notice and Document License (2015-05-13)' =>
			'W3C-20150513';
		field 'Sybase Open Watcom Public License 1.0' => 'Watcom-1.0';

#		field 'Wsuipa License'                              => 'Wsuipa';
		field 'Do What The F*ck You Want To Public License' => 'WTFPL';
		field 'X11 License'                                 => 'X11';

#		field 'Xerox License'                               => 'Xerox';
		field 'XFree86 License 1.1' => 'XFree86-1.1';

#		field 'xinetd License'                              => 'xinetd';
		field 'X.Net License' => 'Xnet';

#		field 'XPP License'                                 => 'xpp';
#		field 'XSkat License'                               => 'XSkat';
		field 'Yahoo! Public License v1.0' => 'YPL-1.0';
		field 'Yahoo! Public License v1.1' => 'YPL-1.1';
		field 'Zed License'                => 'Zed';
		field 'Zend License v2.0'          => 'Zend-2.0';
		field 'Zimbra Public License v1.3' => 'Zimbra-1.3';
		field 'Zimbra Public License v1.4' => 'Zimbra-1.4';
		field 'zlib License'               => 'Zlib';
		field 'zlib/libpng License with Acknowledgement' =>
			'zlib-acknowledgement';
		field 'Zope Public License 1.1' => 'ZPL-1.1';
		field 'Zope Public License 2.0' => 'ZPL-2.0';
		field 'Zope Public License 2.1' => 'ZPL-2.1';

		# exceptions
		field '389 Directory Server Exception' => '389-exception';
		field 'Autoconf exception 2.0'         => 'Autoconf-exception-2.0';
		field 'Autoconf exception 3.0'         => 'Autoconf-exception-3.0';
		field 'Bison exception 2.2'            => 'Bison-exception-2.2';

#		field 'Bootloader Distribution Exception' => 'Bootloader-exception';
		field 'Classpath exception 2.0' => 'Classpath-exception-2.0';

# TODO		field 'CLISP exception 2.0' => 'CLISP-exception-2.0';
# TODO		field 'DigiRule FOSS License Exception' => 'DigiRule-FOSS-exception';
		field 'eCos exception 2.0' => 'eCos-exception-2.0';

# TODO		field 'Fawkes Runtime Exception' => 'Fawkes-Runtime-exception';
# TODO		field 'FLTK exception' => 'FLTK-exception';
		field 'Font exception 2.0' => 'Font-exception-2.0';

# TODO		field 'FreeRTOS Exception 2.0' => 'freertos-exception-2.0';
		field 'GCC Runtime Library exception 2.0' => 'GCC-exception-2.0';
		field 'GCC Runtime Library exception 3.1' => 'GCC-exception-3.1';

# TODO		field 'GNU JavaMail exception' => 'gnu-javamail-exception';
# TODO		field 'i2p GPL+Java Exception' => 'i2p-gpl-java-exception';
		field 'Libtool Exception' => 'Libtool-exception';

#		field 'Linux Syscall Note' => 'Linux-syscall-note';
# TODO		field 'LZMA exception' => 'LZMA-exception';
		field 'Macros and Inline Functions Exception' => 'mif-exception';

# TODO		field 'Nokia Qt LGPL exception 1.1' => 'Nokia-Qt-exception-1.1';
# TODO		field 'Open CASCADE Exception 1.0'      => 'OCCT-exception-1.0';
# TODO		field 'OpenVPN OpenSSL Exception' => 'openvpn-openssl-exception';
# TODO		field 'Qwt exception 1.0' => 'Qwt-exception-1.0';
# TODO		field 'U-Boot exception 2.0' => 'u-boot-exception-2.0';
		field 'WxWindows Library Exception 3.1' => 'WxWindows-exception-3.1';

		end();
	},
	'coverage of SPDX 3.0, released 2017-12-28'
);

done_testing;
