use Test2::V0;

use lib 't/lib';
use Test2::Regexp::Pattern::License;

plan 1;

# Data sources:
# <https://web.archive.org/web/20151002033058/https://spdx.org/licenses/>
# <https://web.archive.org/web/20151002195058/http://spdx.org/licenses/exceptions-index.html>

like(
	license_org_metadata( 'spdx', '20150930', '2_2' ),
	hash {
		field '3dfx Glide License'                              => 'Glide';
		field 'Abstyles License'                                => 'Abstyles';
		field 'Academic Free License v1.1'                      => 'AFL-1.1';
		field 'Academic Free License v1.2'                      => 'AFL-1.2';
		field 'Academic Free License v2.0'                      => 'AFL-2.0';
		field 'Academic Free License v2.1'                      => 'AFL-2.1';
		field 'Academic Free License v3.0'                      => 'AFL-3.0';
		field 'Academy of Motion Picture Arts and Sciences BSD' => 'AMPAS';
		field 'Adaptive Public License 1.0'                     => 'APL-1.0';
		field 'Adobe Glyph List License'     => 'Adobe-Glyph';
		field 'Adobe Postscript AFM License' => 'APAFML';
		field 'Adobe Systems Incorporated Source Code License Agreement' =>
			'Adobe-2006';
		field 'Affero General Public License v1.0'  => 'AGPL-1.0';
		field 'Afmparse License'                    => 'Afmparse';
		field 'Aladdin Free Public License'         => 'Aladdin';
		field 'Amazon Digital Services License'     => 'ADSL';
		field 'AMD\'s plpa_map.c License'           => 'AMDPLPA';
		field 'ANTLR Software Rights Notice'        => 'ANTLR-PD';
		field 'Apache License 1.0'                  => 'Apache-1.0';
		field 'Apache License 1.1'                  => 'Apache-1.1';
		field 'Apache License 2.0'                  => 'Apache-2.0';
		field 'Apple MIT License'                   => 'AML';
		field 'Apple Public Source License 1.0'     => 'APSL-1.0';
		field 'Apple Public Source License 1.1'     => 'APSL-1.1';
		field 'Apple Public Source License 1.2'     => 'APSL-1.2';
		field 'Apple Public Source License 2.0'     => 'APSL-2.0';
		field 'Artistic License 1.0'                => 'Artistic-1.0';
		field 'Artistic License 1.0 (Perl)'         => 'Artistic-1.0-Perl';
		field 'Artistic License 1.0 w/clause 8'     => 'Artistic-1.0-cl8';
		field 'Artistic License 2.0'                => 'Artistic-2.0';
		field 'Attribution Assurance License'       => 'AAL';
		field 'Bahyph License'                      => 'Bahyph';
		field 'Barr License'                        => 'Barr';
		field 'Beerware License'                    => 'Beerware';
		field 'BitTorrent Open Source License v1.0' => 'BitTorrent-1.0';
		field 'BitTorrent Open Source License v1.1' => 'BitTorrent-1.1';
		field 'Boost Software License 1.0'          => 'BSL-1.0';
		field 'Borceux license'                     => 'Borceux';
		field 'BSD 2-clause "Simplified" License'   => 'BSD-2-Clause';
		field 'BSD 2-clause FreeBSD License'        => 'BSD-2-Clause-FreeBSD';
		field 'BSD 2-clause NetBSD License'         => 'BSD-2-Clause-NetBSD';
		field 'BSD 3-clause "New" or "Revised" License' => 'BSD-3-Clause';
		field 'BSD 3-clause Clear License' => 'BSD-3-Clause-Clear';
		field 'BSD 4-clause "Original" or "Old" License' => 'BSD-4-Clause';
		field 'BSD Protection License'                   => 'BSD-Protection';
		field 'BSD with attribution'    => 'BSD-3-Clause-Attribution';
		field 'BSD Zero Clause License' => '0BSD';
		field 'BSD-4-Clause (University of California-Specific)' =>
			'BSD-4-Clause-UC';
		field 'bzip2 and libbzip2 License v1.0.5'           => 'bzip2-1.0.5';
		field 'bzip2 and libbzip2 License v1.0.6'           => 'bzip2-1.0.6';
		field 'Caldera License'                             => 'Caldera';
		field 'CeCILL Free Software License Agreement v1.0' => 'CECILL-1.0';
		field 'CeCILL Free Software License Agreement v1.1' => 'CECILL-1.1';
		field 'CeCILL Free Software License Agreement v2.0' => 'CECILL-2.0';
		field 'CeCILL Free Software License Agreement v2.1' => 'CECILL-2.1';
		field 'CeCILL-B Free Software License Agreement'    => 'CECILL-B';
		field 'CeCILL-C Free Software License Agreement'    => 'CECILL-C';
		field 'Clarified Artistic License'                  => 'ClArtistic';
		field 'CMU License'                                 => 'MIT-CMU';
		field 'CNRI Jython License'                         => 'CNRI-Jython';
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
		field 'Creative Commons Attribution 4.0' => 'CC-BY-4.0';
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
		field 'Creative Commons Zero v1.0 Universal' => 'CC0-1.0';
		field 'Crossword License'                    => 'Crossword';

# TODO		field 'CrystalStacker License'               => 'CrystalStacker';
		field 'CUA Office Public License v1.0' => 'CUA-OPL-1.0';
		field 'Cube License'                   => 'Cube';
		field 'Deutsche Freie Software Lizenz' => 'D-FSL-1.0';

# TODO		field 'diffmark license'                     => 'diffmark';
		field 'Do What The F*ck You Want To Public License' => 'WTFPL';

# TODO		field 'DOC License'                                 => 'DOC';
# TODO		field 'Dotseqn License'                             => 'Dotseqn';
		field 'DSDP License' => 'DSDP';

# TODO		field 'dvipdfm License'                             => 'dvipdfm';
		field 'Eclipse Public License 1.0'         => 'EPL-1.0';
		field 'Educational Community License v1.0' => 'ECL-1.0';
		field 'Educational Community License v2.0' => 'ECL-2.0';

# TODO		field 'eGenix.com Public License 1.1.0'             => 'eGenix';
		field 'Eiffel Forum License v1.0'         => 'EFL-1.0';
		field 'Eiffel Forum License v2.0'         => 'EFL-2.0';
		field 'Enlightenment License (e16)'       => 'MIT-advertising';
		field 'enna License'                      => 'MIT-enna';
		field 'Entessa Public License v1.0'       => 'Entessa';
		field 'Erlang Public License v1.1'        => 'ErlPL-1.1';
		field 'EU DataGrid Software License'      => 'EUDatagrid';
		field 'European Union Public License 1.0' => 'EUPL-1.0';
		field 'European Union Public License 1.1' => 'EUPL-1.1';
		field 'Eurosym License'                   => 'Eurosym';
		field 'Fair License'                      => 'Fair';
		field 'feh License'                       => 'MIT-feh';
		field 'Frameworx Open License 1.0'        => 'Frameworx-1.0';

# TODO		field 'FreeImage Public License v1.0'     => 'FreeImage';
		field 'Freetype Project License'                       => 'FTL';
		field 'FSF Unlimited License'                          => 'FSFUL';
		field 'FSF Unlimited License (with License Retention)' => 'FSFULLR';

# TODO		field 'Giftware License'                               => 'Giftware';
# TODO		field 'GL2PS License'                                  => 'GL2PS';
# TODO		field 'Glulxe License'                                 => 'Glulxe';
		field 'GNU Affero General Public License v3.0'      => 'AGPL-3.0';
		field 'GNU Free Documentation License v1.1'         => 'GFDL-1.1';
		field 'GNU Free Documentation License v1.2'         => 'GFDL-1.2';
		field 'GNU Free Documentation License v1.3'         => 'GFDL-1.3';
		field 'GNU General Public License v1.0 only'        => 'GPL-1.0';
		field 'GNU General Public License v2.0 only'        => 'GPL-2.0';
		field 'GNU General Public License v3.0 only'        => 'GPL-3.0';
		field 'GNU Lesser General Public License v2.1 only' => 'LGPL-2.1';
		field 'GNU Lesser General Public License v3.0 only' => 'LGPL-3.0';
		field 'GNU Library General Public License v2 only'  => 'LGPL-2.0';

# TODO		field 'gnuplot License'                                => 'gnuplot';
		field 'gSOAP Public License v1.3b' => 'gSOAP-1.3b';

# TODO		field 'Haskell Language Report License'           => 'HaskellReport';
		field 'Historic Permission Notice and Disclaimer'    => 'HPND';
		field 'IBM PowerPC Initialization and Boot Software' => 'IBM-pibs';
		field 'IBM Public License v1.0'                      => 'IPL-1.0';
		field 'ICU License'                                  => 'ICU';

# TODO		field 'ImageMagick License'                          => 'ImageMagick';
# TODO		field 'iMatix Standard Function Library Agreement'   => 'iMatix';
		field 'Imlib2 License'                 => 'Imlib2';
		field 'Independent JPEG Group License' => 'IJG';

# TODO		field 'Intel ACPI Software License Agreement'        => 'Intel-ACPI';
		field 'Intel Open Source License' => 'Intel';

# TODO		field 'Interbase Public License v1.0'      => 'Interbase-1.0';
		field 'IPA Font License' => 'IPA';
		field 'ISC License'      => 'ISC';

# TODO		field 'JasPer License'                     => 'JasPer-2.0';
		field 'JSON License'                       => 'JSON';
		field 'LaTeX Project Public License 1.3a'  => 'LPPL-1.3a';
		field 'LaTeX Project Public License v1.0'  => 'LPPL-1.0';
		field 'LaTeX Project Public License v1.1'  => 'LPPL-1.1';
		field 'LaTeX Project Public License v1.2'  => 'LPPL-1.2';
		field 'LaTeX Project Public License v1.3c' => 'LPPL-1.3c';

# TODO		field 'Latex2e License'                    => 'Latex2e';
		field 'Lawrence Berkeley National Labs BSD variant license' =>
			'BSD-3-Clause-LBNL';
		field 'Leptonica License' => 'Leptonica';

# TODO		field 'Lesser General Public License For Linguistic Resources' =>
#			'LGPLLR';
		field 'libpng License'                    => 'Libpng';
		field 'libtiff License'                   => 'libtiff';
		field 'Lucent Public License v1.02'       => 'LPL-1.02';
		field 'Lucent Public License Version 1.0' => 'LPL-1.0';

# TODO		field 'MakeIndex License'                 => 'MakeIndex';
# TODO		field 'Matrix Template Library License'   => 'MTLL';
		field 'Microsoft Public License'     => 'MS-PL';
		field 'Microsoft Reciprocal License' => 'MS-RL';
		field 'MirOS Licence'                => 'MirOS';

# TODO		field 'MIT +no-false-attribs license'     => 'MITNFA';
		field 'MIT License'                => 'MIT';
		field 'Motosoto License'           => 'Motosoto';
		field 'Mozilla Public License 1.0' => 'MPL-1.0';
		field 'Mozilla Public License 1.1' => 'MPL-1.1';
		field 'Mozilla Public License 2.0' => 'MPL-2.0';
		field 'Mozilla Public License 2.0 (no copyleft exception)' =>
			'MPL-2.0-no-copyleft-exception';
		field 'mpich2 License'  => 'mpich2';
		field 'Multics License' => 'Multics';

# TODO		field 'Mup License'                          => 'Mup';
		field 'NASA Open Source Agreement 1.3' => 'NASA-1.3';
		field 'Naumen Public License'          => 'Naumen';
		field 'Net Boolean Public License v1'  => 'NBPL-1.0';

# TODO		field 'NetCDF license'                       => 'NetCDF';
		field 'Nethack General Public License' => 'NGPL';
		field 'Netizen Open Source License'    => 'NOSL';
		field 'Netscape Public License v1.0'   => 'NPL-1.0';
		field 'Netscape Public License v1.1'   => 'NPL-1.1';

# TODO		field 'Newsletr License'                     => 'Newsletr';
# TODO		field 'No Limit Public License'              => 'NLPL';
		field 'Nokia Open Source License'            => 'Nokia';
		field 'Non-Profit Open Software License 3.0' => 'NPOSL-3.0';

# TODO		field 'Noweb License'                        => 'Noweb';
# TODO		field 'NRL License'                          => 'NRL';
		field 'NTP License' => 'NTP';

# quirk		field 'Nunit License'                              => 'Nunit';
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
		field 'Open LDAP Public License v2.0.1' => 'OLDAP-2.0.1';
		field 'Open LDAP Public License v2.1'   => 'OLDAP-2.1';
		field 'Open LDAP Public License v2.2'   => 'OLDAP-2.2';
		field 'Open LDAP Public License v2.2.1' => 'OLDAP-2.2.1';
		field 'Open LDAP Public License v2.3'   => 'OLDAP-2.3';
		field 'Open LDAP Public License v2.4'   => 'OLDAP-2.4';
		field 'Open LDAP Public License v2.5'   => 'OLDAP-2.5';
		field 'Open LDAP Public License v2.6'   => 'OLDAP-2.6';
		field 'Open LDAP Public License v2.7'   => 'OLDAP-2.7';
		field 'Open LDAP Public License v2.8'   => 'OLDAP-2.8';

# TODO		field 'Open Market License'                     => 'OML';
		field 'Open Public License v1.0'  => 'OPL-1.0';
		field 'Open Software License 1.0' => 'OSL-1.0';
		field 'Open Software License 1.1' => 'OSL-1.1';
		field 'Open Software License 2.0' => 'OSL-2.0';
		field 'Open Software License 2.1' => 'OSL-2.1';
		field 'Open Software License 3.0' => 'OSL-3.0';
		field 'OpenSSL License'           => 'OpenSSL';
		field 'PHP License v3.0'          => 'PHP-3.0';
		field 'PHP License v3.01'         => 'PHP-3.01';

# TODO		field 'Plexus Classworlds License'              => 'Plexus';
		field 'PostgreSQL License' => 'PostgreSQL';

# TODO		field 'psfrag License'                          => 'psfrag';
# TODO		field 'psutils License'                         => 'psutils';
		field 'Python License 2.0'   => 'Python-2.0';
		field 'Q Public License 1.0' => 'QPL-1.0';

# TODO		field 'Qhull License'                           => 'Qhull';
# TODO		field 'Rdisc License'                           => 'Rdisc';
		field 'RealNetworks Public Source License v1.0' => 'RPSL-1.0';
		field 'Reciprocal Public License 1.1'           => 'RPL-1.1';
		field 'Reciprocal Public License 1.5'           => 'RPL-1.5';
		field 'Red Hat eCos Public License v1.1'        => 'RHeCos-1.1';
		field 'Ricoh Source Code Public License'        => 'RSCPL';

# TODO		field 'RSA Message-Digest License'              => 'RSA-MD';
		field 'Ruby License'             => 'Ruby';
		field 'Sax Public Domain Notice' => 'SAX-PD';

# TODO		field 'Saxpath License'                         => 'Saxpath';
# TODO		field 'SCEA Shared Source License'              => 'SCEA';
# TODO		field 'Scheme Widget Library (SWL) Software License Agreement' =>
#			'SWL';
# TODO		field 'Sendmail License'                  => 'Sendmail';
		field 'SGI Free Software License B v1.0' => 'SGI-B-1.0';
		field 'SGI Free Software License B v1.1' => 'SGI-B-1.1';
		field 'SGI Free Software License B v2.0' => 'SGI-B-2.0';
		field 'SIL Open Font License 1.0'        => 'OFL-1.0';
		field 'SIL Open Font License 1.1'        => 'OFL-1.1';
		field 'Simple Public License 2.0'        => 'SimPL-2.0';
		field 'Sleepycat License'                => 'Sleepycat';

# TODO		field 'SNIA Public License 1.1'           => 'SNIA';
# TODO		field 'Spencer License 86'                => 'Spencer-86';
# TODO		field 'Spencer License 94'                => 'Spencer-94';
# TODO		field 'Spencer License 99'                => 'Spencer-99';
		field 'Standard ML of New Jersey License' => 'SMLNJ';
		field 'SugarCRM Public License v1.1.3'    => 'SugarCRM-1.1.3';
		field 'Sun Industry Standards Source License v1.1' => 'SISSL';
		field 'Sun Industry Standards Source License v1.2' => 'SISSL-1.2';
		field 'Sun Public License v1.0'                    => 'SPL-1.0';
		field 'Sybase Open Watcom Public License 1.0'      => 'Watcom-1.0';

# TODO		field 'TCL/TK License'                             => 'TCL';
		field 'The Unlicense' => 'Unlicense';

# TODO		field 'TMate Open Source License'                  => 'TMate';
# TODO		field 'TORQUE v2.5+ Software License v1.1'         => 'TORQUE-1.1';
		field 'Trusster Open Source License'      => 'TOSL';
		field 'Unicode Terms of Use'              => 'Unicode-TOU';
		field 'Universal Permissive License v1.0' => 'UPL-1.0';
		field 'University of Illinois/NCSA Open Source License' => 'NCSA';

# TODO		field 'Vim License'                                     => 'Vim';
# TODO		field 'VOSTROM Public License for Open Source'          => 'VOSTROM';
		field 'Vovida Software License v1.0' => 'VSL-1.0';
		field 'W3C Software Notice and License (1998-07-20)' =>
			'W3C-19980720';
		field 'W3C Software Notice and License (2002-12-31)' => 'W3C';

# TODO		field 'Wsuipa License'                               => 'Wsuipa';
		field 'X.Net License' => 'Xnet';
		field 'X11 License'   => 'X11';

# TODO		field 'Xerox License'                                => 'Xerox';
		field 'XFree86 License 1.1' => 'XFree86-1.1';

# TODO		field 'xinetd License'                               => 'xinetd';
# TODO		field 'XPP License'                                  => 'xpp';
# TODO		field 'XSkat License'                                => 'XSkat';
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

		# quirks: duplicate names
		field 'Nunit'         => 'zlib-acknowledgement';
		field 'Nunit License' => 'zlib-acknowledgement';

		# exceptions
		field '389 Directory Server Exception' => '389-exception';
		field 'Autoconf exception 2.0'         => 'Autoconf-exception-2.0';
		field 'Autoconf exception 3.0'         => 'Autoconf-exception-3.0';
		field 'Bison exception 2.2'            => 'Bison-exception-2.2';
		field 'Classpath exception 2.0'        => 'Classpath-exception-2.0';

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

# TODO		field 'LZMA exception' => 'LZMA-exception';
		field 'Macros and Inline Functions Exception' => 'mif-exception';

# TODO		field 'Nokia Qt LGPL exception 1.1' => 'Nokia-Qt-exception-1.1';
# TODO		field 'OpenVPN OpenSSL Exception' => 'openvpn-openssl-exception';
# TODO		field 'Qwt exception 1.0' => 'Qwt-exception-1.0';
# TODO		field 'U-Boot exception 2.0' => 'u-boot-exception-2.0';
		field 'WxWindows Library Exception 3.1' => 'WxWindows-exception-3.1';

		end();
	},
	'coverage of SPDX 2.2, released 2015-09-30'
);

done_testing;
