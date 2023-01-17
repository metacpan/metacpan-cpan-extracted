use Test2::V0;

use lib 't/lib';
use Test2::Tools::LicenseRegistry;

plan 1;

# Data sources:
# <https://fedoraproject.org/w/index.php?title=Licensing:Main&oldid=585544>
# <https://fedoraproject.org/wiki/Licensing/CDDL>
# <https://fedoraproject.org/w/index.php?title=Licensing:BSD&oldid=433484>
# <https://fedoraproject.org/w/index.php?title=Licensing:MIT&oldid=585545>

# dirty dump (needs further work):
# curl 'https://fedoraproject.org/w/index.php?title=Licensing:Main&action=edit' | perl -nE 'm{^\|([^|]+?)\s+\|\|(?:[^|]+\|\|)*?(http[^\s|]+)} and say '"\"\\t\\tfield '\$1' => '\$2'\";" | sort -t= -k2 > fedora.t

# Key is Full Name, and multi-word Short Name, and IRI page/fragment, and page headline.
# Value is singleword Short Name, or default name.
like(
	license_org_metadata( 'fedora', { date => '20200819', rev => '2_53' } ),
	hash {
		# Good Licenses
		field '3dfx Glide License' => 'Glide';

#		field '4Suite Copyright License'       => '';
#		field 'ASL 1.1'                        => ''; # short

		field 'Abstyles License'      => 'Abstyles';
		field 'Abstyles'              => 'Abstyles';    # iri
		field 'Academic Free License' => 'AFL';

		field 'Academy of Motion Picture Arts and Sciences BSD' => 'AMPAS';
		field 'AMPAS BSD' => 'AMPAS';                   # short
		field 'AMPASBSD'  => 'AMPAS';                   # iri

		field 'Adobe Systems Incorporated Source Code License Agreement' =>
			'Adobe';
		field 'AdobeLicense'  => 'Adobe';    # iri
		field 'Adobe License' => 'Adobe';    # ignore: default caption

		field 'Adobe Postscript AFM License' => 'APAFML';
		field 'AdobePostscriptAFM'           => 'APAFML';    # iri

		field 'Adobe Glyph List License' => 'Adobe-Glyph';
		field 'AdobeGlyph'               => 'Adobe-Glyph';    # iri

		field 'Affero General Public License 1.0'          => 'AGPLv1';
		field 'Affero General Public License 3.0'          => 'AGPLv3';
		field 'Affero General Public License 3.0 or later' => 'AGPLv3+';

#		field
#			'Affero General Public License 3.0 with Zarafa trademark exceptions'
#			=> '';
#		field 'AGPLv3 with exceptions' => '';

		field 'Afmparse License' => 'Afmparse';
		field 'Afmparse'         => 'Afmparse';               # iri

		field 'Amazon Digital Services License' => 'ADSL';
		field 'AmazonDigitalServicesLicense'    => 'ADSL';    # iri

		field 'AMD\'s plpa_map.c License' => 'AMDPLPA';
		field 'AMD plpa map License'      => 'AMDPLPA';       # iri

		field 'ANTLR Software Rights Notice' => 'ANTLR-PD';
		field 'ANTLR-PD'                     => 'ANTLR-PD';    # iri

		field 'Apache Software License 1.0' => 'Apache-1.0';
		field 'ASL 1.0'                     => 'Apache-1.0';    # short
		field 'Apache Software License 1.1' => 'Apache-1.1';
		field 'ASL 1.1'                     => 'Apache-1.1';    # short
		field 'Apache Software License 2.0' => 'Apache-2.0';
		field 'ASL 2.0'                     => 'Apache-2.0';    # short

#		field 'App::s2p License'             => 'App-s2p';

		field 'Apple MIT License' => 'AML';

		field 'Apple Public Source License 2.0' => 'APSL-2.0';
		field 'APSL 2.0'                        => 'APSL-2.0';    # short

#		fiekd 'Array Input Method Public License' => 'Array'

		field 'Artistic (clarified)' => 'Artistic-1.0-clarified';
		field 'Artistic clarified'   => 'Artistic-1.0-clarified';    # short
		field 'ArtisticClarified'    => 'Artistic-1.0-clarified';    # iri
		field 'Artistic 2.0'         => 'Artistic-2.0';

#		field 'Aspell-ru License'    => 'ARL';
#		field 'Aspell-ru License'    => 'ARL'; # iri

		field 'Attribution Assurance License' => 'AAL';

		field 'Bahyph License' => 'Bahyph';
		field 'Bahyph'         => 'Bahyph';                          # iri

		field 'Barr License' => 'Barr';
		field 'Barr'         => 'Barr';                              # iri

		field 'Beerware License' => 'Beerware';
		field 'Beerware'         => 'Beerware';                      # iri

#		field 'BeOpen Open Source License Agreement Version 1' => 'BeOpen';
#		field 'Bibtex License'                                 => 'Bibtex';

		field 'BitTorrent License'             => 'BitTorrent';
		field 'BitTorrent Open Source License' => 'BitTorrent';      # iri

		field 'Boost Software License' => 'Boost';

		field 'Borceux license' => 'Borceux';
		field 'Borceux'         => 'Borceux';                        # iri

		field 'BSD + Patent'        => 'BSD-2-Clause-Patent';
		field 'BSD-2-Clause-Patent' => 'BSD-2-Clause-Patent';        # iri

		# relaxed from more specific BSD-4-Clause-UC
		field 'BSD License (original)' => 'BSD-4-Clause';
		field 'BSDwithAdvertising'     => 'BSD-4-Clause';            # iri

		field 'BSD with attribution' => 'BSD-3-Clause-Attribution';

		field 'BSD License (no advertising)' => 'BSD-3-Clause';
		field '3ClauseBSD'                   => 'BSD-3-Clause';      # iri

		field 'BSD License (two clause)' => 'BSD-2-Clause-FreeBSD';
		field '2ClauseBSD'               => 'BSD-2-Clause-FreeBSD';    # iri

		field 'BSD Protection License' => 'BSD-Protection';
		field 'BSD Protection'         => 'BSD-Protection';            # iri

		field 'Computer Associates Trusted Open Source License 1.1' =>
			'CATOSL';

		field 'CeCILL License v1.1' => 'CeCILL';
		field 'CeCILL License v2'   => 'CeCILL';
		field 'CeCILL-B License'    => 'CeCILL-B';
		field 'CeCILL-C License'    => 'CeCILL-C';

#		field 'Celtx Public License (CePL)'                 => 'Netscape';

		field 'CMU License (BSD like)' => 'MIT-CMU';
		field 'CMU Style'              => 'MIT-CMU';    # iri

		field 'CNRI License (Old Python)' => 'CNRI';

		field 'Common Development Distribution License 1.0' => 'CDDL-1.0';
		field 'CDDL 1.0' => 'CDDL-1.0';                 # page
		field 'Common Development Distribution License 1.1' => 'CDDL-1.1';
		field 'CDDL 1.1' => 'CDDL-1.1';                 # page

		field 'Common Public License' => 'CPL';

		field 'Condor Public License' => 'Condor';

#		field 'Copyright Attribution Only' => 'CopyrightOnly';
#		field 'Copyright only'             => 'CopyrightOnly';

		field 'CPAL License 1.0' => 'CPAL';

#		field 'CP/M License'                          => 'CPM';
#		field 'CRC32 License'                         => 'CRC32';

		field 'Creative Commons BSD' => 'BSD-2-Clause';
		field 'BSD 2-Clause License' => 'BSD-2-Clause';    # default caption

		field 'Creative Commons GNU GPL' => 'GPL-2';
		field 'GNU General Public License, Version 2' =>
			'GPL-2';                                       # default caption

		field 'Creative Commons GNU LGPL' => 'LGPL-2.1';
		field 'GNU Lesser General Public License, Version 2.1' =>
			'LGPL-2.1';                                    # default caption

		field 'Creative Commons Zero 1.0 Universal' => 'CC0';

		field 'Crossword License' => 'Crossword';
		field 'Crossword'         => 'Crossword';          # iri

		field 'Cryptix General License' => 'Cryptix';

#		field 'Crystal Stacker License' => 'CrystalStacker';
#		field 'Crystal Stacker'         => 'CrystalStacker';

		field 'CUA Office Public License Version 1.0' => 'MPLv1.1';

		field 'Cube License' => 'Cube';
		field 'Cube'         => 'Cube';                    # iri

#		field 'diffmark license'                          => 'diffmark';
#		field 'DO WHATEVER PUBLIC LICENSE'            => 'DWPL';

		field 'Do What The F*ck You Want To Public License' => 'WTFPL';
		field 'WTFPL'                                       => 'WTFPL';  # iri

#		field 'DOC License'                           => 'DOC';
#		field 'Docbook MIT License'                   => 'DMIT';
#		field 'Dotseqn License'                       => 'Dotseqn';

		field 'DSDP License' => 'DSDP';
		field 'DSDP'         => 'DSDP';                                  # iri

#		field 'dvipdfm License'                       => 'dvipdfm';

		field 'Eclipse Distribution License 1.0' => 'EDL-1.0';

		field 'Eclipse Public License 1.0' => 'EPL-1.0';
		field 'Eclipse Public License 2.0' => 'EPL-2.0';

		field 'eCos License v2.0' => 'eCos';

		field 'Educational Community License 1.0' => 'ECL-1.0';
		field 'ECL 1.0'                           => 'ECL-1.0';
		field 'Educational Community License 2.0' => 'ECL-2.0';
		field 'ECL 2.0'                           => 'ECL-2.0';

#		field 'eGenix.com Public License 1.1.0' => 'eGenix';

		field 'Eiffel Forum License 2.0' => 'EFL-2';
		field 'EFL 2.0'                  => 'EFL-2';

		field 'enna License' => 'MIT-enna';
		field 'enna'         => 'MIT-enna';

		field 'Enlightenment License (e16)' => 'MIT-advertising';
		field 'MIT With Advertising'        => 'MIT-advertising';

		field 'Entessa Public License' => 'Entessa';

#		field 'EPICS Open License'                => 'EPICS';

		field 'Erlang Public License 1.1' => 'ERPL';
		field 'ErlangPublicLicense'       => 'ERPL';

		field 'EU Datagrid Software License' => 'EUDatagrid';
		field 'EU Datagrid'                  => 'EUDatagrid';

		field 'European Union Public License 1.1' => 'EUPL-1.1';
		field 'EUPL 1.1'                          => 'EUPL-1.1';
		field 'European Union Public License 1.2' => 'EUPL-1.2';
		field 'EUPL 1.2'                          => 'EUPL-1.2';

		field 'Eurosym License' => 'Eurosym';
		field 'Eurosym'         => 'Eurosym';    # iri

		field 'Fedora Directory Server License' => '389-exception';

		field 'Fair License' => 'Fair';

		field 'feh License' => 'MIT-feh';
		field 'feh'         => 'MIT-feh';

#		field 'FLTK License'                      => 'FLTK-exception';
#		field 'Fraunhofer FDK AAC License'        => 'FDK-AAC';
#		field 'FreeImage Public License'          => 'MPLv1.0';

		field 'Freetype License' => 'FTL';

		field 'FSF All Permissive license' => 'FSFAP';
		field 'FSFAP'                      => 'FSFAP';    # iri

		field 'FSF Unlimited License' => 'FSFUL';

		field 'FSF Unlimited License (with License Retention)' => 'FSFULLR';

#		field 'Giftware License' => 'Giftware';
#		field 'GL2PS License'    => 'GL2PS';
#		field 'Glulxe License'   => 'Glulxe';

#		field 'GNU General Public License (no version)' => 'GPL+';
# combo		field 'GNU General Public License (no version), with Classpath exception' => '';
# combo		field 'GNU General Public License (no version), with font embedding exception' => '';

		field 'GNU General Public License v1.0 only'     => 'GPLv1';
		field 'GNU General Public License v1.0 or later' => 'GPL+';
		field 'GNU General Public License v2.0 only'     => 'GPLv2';

# combo		field 'GNU General Public License v2.0 only, with Classpath exception' => '';
# combo		field 'GNU General Public License v2.0 only, with font embedding exception' => '';

		field 'GNU General Public License v2.0 or later' => 'GPLv2+';

# combo		field 'GNU General Public License v2.0 or later, with Classpath exception' => '';
# combo		field 'GNU General Public License v2.0 or later, with font embedding exception' => '';

		field 'GNU General Public License v3.0 only' => 'GPLv3';

# combo		field 'GNU General Public License v3.0 only, with Classpath exception' => '';
# combo		field 'GNU General Public License v3.0 only, with font embedding exception' => '';

		field 'GNU General Public License v3.0 or later' => 'GPLv3+';

# combo		field 'GNU General Public License v3.0 or later, with Classpath exception' => '';
# combo		field 'GNU General Public License v3.0 or later, with font embedding exception' => '';
		field 'Classpath exception' =>
			'Classpath-exception-2.0';    # exception part
		field 'font embedding exception' =>
			'Font-exception-2.0';         # exception part

#		field 'GNU Lesser General Public License (no version)' => 'LGPLv2+';
# combo		field 'GNU Lesser General Public License v2 (or 2.1) only' => 'LGPLv2';
# combo		field 'GNU Lesser General Public License v2 (or 2.1), with exception' => '';

		field 'GNU Lesser General Public License v2 (or 2.1) or later' =>
			'LGPLv2+';

# combo		field 'GNU Lesser General Public License v2 (or 2.1) or later, with exception' => '';

		field 'GNU Lesser General Public License v3.0 only' => 'LGPLv3';

# combo		field 'GNU Lesser General Public License v3.0 only, with exception' => '';

		field 'GNU Lesser General Public License v3.0 or later' => 'LGPLv3+';

# combo		field 'GNU Lesser General Public License v3.0 or later, with exception' => '';
#		field 'gnuplot License'  => 'gnuplot';
#		field 'Gnuplot'  => 'gnuplot'; # iri
#		field 'Haskell Language Report License' => 'HaskellReport';
#		field 'Henry Spencer Reg-Ex Library License' => 'HSRL';

		field 'Historical Permission Notice and Disclaimer' => 'HPND';

		field 'IBM Public License' => 'IBM';

#		field 'iMatix Standard Function Library Agreement' => 'iMatix';
#		field 'ImageMagick License'                         => 'ImageMagick';

		field 'Imlib2 License' => 'Imlib2';
		field 'Imlib2'         => 'Imlib2';    # iri

		field 'Independent JPEG Group License' => 'IJG';
		field 'IJG'                            => 'IJG';    # iri

#		field 'Inner Net License' => 'Inner-Net';
#		field 'Intel ACPI Software License Agreement' => 'Intel-ACPI';
#		field 'Intel ACPI' => 'Intel-ACPI';
#		field 'Interbase Public License'     => 'Interbase';

		field 'ISC License (Bind, DHCP Server)' => 'ISC';
		field 'ISC License'                     => 'ISC';    # default caption

		field 'Jabber Open Source License' => 'Jabber';

#		field 'JasPer License'               => 'JasPer';

		field 'JPython License (old)' => 'JPython';

#		field 'Julius License'               => 'Julius';
#		field 'Knuth License'                => 'Knuth';

		field 'LaTeX Project Public License' => 'LPPL';

#		field 'Latex2e License'              => 'Latex2e';

		field 'Lawrence Berkeley National Labs BSD variant license' =>
			'BSD-3-Clause-LBNL';
		field 'LBNL BSD' => 'BSD-3-Clause-LBNL';    # short
		field 'LBNLBSD'  => 'BSD-3-Clause-LBNL';    # iri

#		field 'LEGO Open Source License Agreement' => 'LOSLA';

		field 'Leptonica License' => 'Leptonica';
		field 'Leptonica'         => 'Leptonica';    # iri

#		field 'Lhcyr License'                 => 'Lhcyr';

		field 'libtiff License' => 'libtiff';
		field 'libtiff'         => 'libtiff';        # iri

		field 'Lisp Library General Public License' => 'LLGPL';

#		field 'Logica Open Source License'          => 'Logica';

		field 'Lucent Public License (Plan9)' => 'LPL';

#		field 'MakeIndex License'                   => 'MakeIndex';
#		field 'Matrix Template Library License' => 'MTLL';
#		field 'mecab-ipadic license' => 'mecab-ipadic';
#		field 'Metasploit Framework License (post 2006)' => '';
#		field 'Metasploit Framework License' => ''; # page

		field 'Microsoft Public License'     => 'MS-PL';
		field 'Microsoft Reciprocal License' => 'MS-RL';

#		field 'midnight License'                                => 'midnight';

		field 'MirOS License' => 'MirOS';

		field 'MIT license (also X11)' => 'mit_new';
		field 'MIT-style license, Modern Style with sublicense' =>
			'mit_new';    # page

#		field 'MIT +no-false-attribs license'                   => 'MITNFA';
#		field 'mod_macro License'                               => 'mod_macro';

		field 'Motosoto License' => 'Motosoto';

		field 'Mozilla Public License v1.0' => 'MPLv1.0';
		field 'Mozilla Public License v1.1' => 'MPLv1.1';
		field 'Mozilla Public License v2.0' => 'MPLv2.0';

		field 'mpich2 License' => 'mpich2';

#		field 'Mup License'                                     => 'Mup';
#		field 'MX4J License'                                    => 'ASL 1.1';
#		field 'MX4J' => 'ASL 1.1';
#		field 'MySQL License'                                   => '';

		field 'Naumen Public License' => 'Naumen';

		field 'NCSA/University of Illinois Open Source License' => 'NCSA';

#		field 'Neotonic Clearsilver License'                    => 'ASL 1.1';
#		field 'NetCDF license'                                  => 'NetCDF';

		field 'Nethack General Public License' => 'NGPL';

		field 'Netizen Open Source License' => 'NOSL';

		field 'Netscape Public License' => 'Netscape';

#		field 'Newmat License'        => 'Newmat';
#		field 'Newmat_License'        => 'Newmat';
#		field 'Newsletr License'      => 'Newsletr';
#		field 'NIST Software License' => 'NISTSL';
#		field 'Nmap License' => 'Nmap';

		field 'Nokia Open Source License' => 'Nokia';

#		field 'No Limit Public License'                       => 'NLPL';
#		field 'Noweb License'                                 => 'Noweb';
#		field 'NRL License'                                   => '';

		field 'Nunit License' => 'zlib-acknowledgement';
		field 'Nunit'         => 'zlib-acknowledgement';

#		field 'Open Government License'                       => 'OGL';

		field 'OpenLDAP License' => 'OpenLDAP';

#		field 'Open Market License'        => 'OML';
#		field 'OpenPBS License'            => 'OpenPBS';

		field 'Open Software License 1.0' => 'OSL-1.0';
		field 'OSL 1.0'                   => 'OSL-1.0';    # short
		field 'Open Software License 1.1' => 'OSL1.1';
		field 'OSL 1.1'                   => 'OSL1.1';     # short
		field 'Open Software License 2.0' => 'OSL-2.0';
		field 'OSL 2.0'                   => 'OSL-2.0';    # short
		field 'Open Software License 2.1' => 'OSL2.1';
		field 'OSL 2.1'                   => 'OSL2.1';     # short
		field 'Open Software License 3.0' => 'OSL-3.0';
		field 'OSL 3.0'                   => 'OSL-3.0';    # short

		field 'OpenSSL License' => 'OpenSSL';

#		field 'OReilly License'           => 'OReilly';
#		field 'Par License'               => 'Par';

		field 'Perl License' => 'Perl';
		field
			'the same terms as the Perl 5 programming language itself (Artistic or GPL)'
			=> 'Perl';                                     # default summary

#		field 'GPL+ or Artistic'          => 'Perl';
#		field 'Perl License (variant)'              => '';
#		field 'GPLv2 or Artistic'          => 'Perl';
#		field 'Perl License (variant)'              => '';
#		field 'GPLv2+ or Artistic'          => 'Perl';
#		field 'Perl License (variant)'              => '';
#		field 'LGPLv2+ or Artistic'          => 'Perl';
#		field 'Phorum License'            => '';

		field 'PHP License v3.0' => 'PHP';

#		field 'PlainTeX License'          => 'PlainTeX';
#		field 'Plexus Classworlds License' => 'Plexus';

		field 'PostgreSQL License' => 'PostgreSQL';

#		field 'psfrag License'             => 'psfrag';
#		field 'psutils License'            => 'psutils';

		field 'Public Domain' => 'public-domain';

		field 'Python License' => 'Python';

#		field 'Qhull License'              => 'Qhull';

		field 'Q Public License' => 'QPL';

#		field 'Qwt License 1.0'            => 'Qwt-exception-1.0';
#		field 'QuickFix License'           => '';
#		field 'ASL 1.1'           => '';
#		field 'radvd License'              => 'radvd';
#		field 'Rdisc License'              => 'Rdisc';
#		field 'REX License'                => 'REX';
#		field 'Rice BSD'                   => 'RiceBSD';
#		field 'Rice BSD License'           => 'RiceBSD'; # iri
#		field 'Romio License'              => 'Romio';
#		field 'RSA License'                => 'RSA';
#		field 'Rsfs License'               => 'Rsfs';

		field 'Ruby License' => 'Ruby';

#		field 'Saxpath License'            => 'Saxpath';
#		field 'Sequence Library License'   => 'Sequence';
#		field 'SequenceLibraryLicense'     => 'Sequence'; # iri
#		field 'SCEA Shared Source License' => 'SCEA';
#		field 'Scheme Widget Library (SWL) Software License Agreement' => 'SWT';
#		field 'SciTech MGL Public License' => 'STMPL';
#		field 'SCRIP License'              => 'SCRIP';
#		field 'Sendmail License'           => 'Sendmail';

		field 'SGI Free Software License B 2.0' => 'SGI-B-2.0';

		field 'Sleepycat Software Product License' => "Sleepycat";
		field 'Sleepycat'                          => "Sleepycat";    # iri

#		field 'SLIB License'                       => 'SLIB';
#		field 'softSurfer License'                 => 'softSurfer';
#		field 'SNIA Public License 1.1'            => 'SNIA';

		field 'Standard ML of New Jersey License' => 'SMLNJ';

		field 'Sun Industry Standards Source License' => 'SISSL';

		field 'Sun Public License' => 'SPL';

#		field 'TCL/TK License'                     => 'TCL';
#		field 'Teeworlds License'                  => 'Teeworlds';
#		field 'Text-Tabs+Wrap License'             => 'TTWL';
#		field 'Thor Public License'                => 'TPL';
#		field 'ThorPublicLicense'                  => 'TPL'; # iri
#		field 'Threeparttable License'             => 'Threeparttable';
#		field 'Time::ParseDate License'            => 'TPDL';
#		field 'TMate Open Source License'          => ''TMate;
#		field 'Tolua License'                      => 'Tolua';
#		field 'TORQUE v2.5+ Software License v1.1' => 'TORQUEv1.1';
#		field 'Transitive Grace Period Public Licence' => 'TGPPL';

		field 'Trusster Open Source License' => 'TOSL';

#		field 'Tumbolia Public License'                => 'Tumbolia';
#		field 'UCAR License'                           => 'UCAR';
#		field 'Unicode Character Database Terms Of Use'  => 'UCD';

		field 'Unicode License' => 'Unicode';

		field 'Unlicense'     => 'Unlicense';
		field 'The Unlicense' => 'Unlicense';    # default caption

		field 'Universal Permissive License' => 'UPL';
		field 'UPL'                          => 'UPL';    # iri

#		field 'Vim License'                            => '';
#		field 'Vita Nuova Liberal Source License' => 'VNLSL';
#		field 'VOSTROM Public License for Open Source' => 'VOSTROM';

		field 'Vovida Software License v. 1.0' => 'VSL';

		field 'W3C Software Notice and License' => 'W3C';

#		field 'Webmin License'                         => 'Webmin';
#		field 'Wsuipa License'                         => 'Wsuipa';
#		field 'wxWidgets Library License'              => 'wxWidgets';
#		field 'wxWindows Library License v 3.1'        => 'wxWindows';
#		field 'wxWindows.html'                         => 'wxWindows'; # iri
#		field 'xinetd License'                         => 'xinetd';
#		field 'Xerox License'                          => 'Xerox';
#		field 'XPP License'                            => 'xpp';
#		field 'XSkat License'                          => 'XSkat';

		field 'Yahoo Public License v 1.1' => 'YPLv1.1';

		field 'Zed License' => 'Zed';

		field 'Zend License v2.0' => 'Zend';

		field 'Zero-Clause BSD' => '0BSD';
		field 'ZeroClauseBSD'   => '0BSD';    # iri

		field 'Zope Public License v 1.0' => 'ZPLv1.0';
		field 'Zope Public License v 2.0' => 'ZPLv2.0';
		field 'Zope Public License v 2.1' => 'ZPLv2.1';

		field 'zlib/libpng License' => 'zlib';
		field 'zlib/libpng License with Acknowledgement' =>
			'zlib-acknowledgement';
		field 'zlib with acknowledgement' => 'zlib-acknowledgement';   # short

		# Bad Licenses
#		field '9wm License (Original)'  => '';
#		field 'Adaptive Public License' => '';
#		field 'Agere LT Modem Driver License' =>
#			'Agere_LT_Modem_Driver_License';

		field 'Aladdin Free Public License' => 'Aladdin';

#		field 'AMAP License'                => 'AMAP_License';
#		field 'Amazon Software License'     => '';
#		field 'Apple iTunes License'        => '';

		field 'Apple Public Source License 1.0' => 'APSL-1.0';
		field 'Apple Public Source License 1.1' => 'APSL-1.1';
		field 'Apple Public Source License 1.2' => 'APSL-1.2';

#		field 'Apple Quicktime License' => '';
#		field 'Aptana Public License'   => '';

		field 'Artistic 1.0 (original)' => 'Artistic-1.0-Perl';

#		field 'AT&T Public License' => '';
#		field 'C/Migemo License'        => 'CMigemo';
#		field 'CACert Root Distribution License' =>
#			'CACert_Root_Distribution_License';

		field 'CodeProject Open License (CPOL)' => 'CPOL';

#		field 'Commons Clause'                  => 'CommonsClause';

		field 'Eiffel Forum License 1.0' => 'EFL-1';
		field 'Eiffel Forum License V1'  => 'EFL-1';    # iri

#		field 'EMC2 License'                    => '';

		field 'European Union Public License v1.0' => 'EUPL-1.0';

		field 'Frameworx License' => 'Frameworx-1.0';

#		field 'Frontier Artistic License'                        => '';
#		field 'GPL for Computer Programs of the Public Administration' => '';

		field 'gSOAP Public License' => 'gSOAP-1.3b';

#		field 'Hacktivismo Enhanced-Source Software License Agreement' => '';
#		field 'Helix DNA Technology Binary Research Use License' => '';
#		field 'HP Software License Terms'                        => '';
#		field 'IBM Sample Code License' => '';
#		field 'Intel IPW3945 Daemon License' => '';

		field 'Intel Open Source License' => 'Intel';

#		field 'Jahia Community Source License' => '';
		field 'JSON License' => 'JSON';

#		field 'lha license'                    => '';
#		field
#			'License Agreement for Application Response Measurement (ARM) SDK'
#			=> 'ApplicationResponseMeasurementSDKLicense';
#		field 'Maia Mailguard License'            => '';
#		field 'MAME License'                      => '';
#		field 'McRae General Public License'      => '';
#		field 'MeepZor Consulting Public Licence' => '';
#		field 'Metasploit Framework License (pre 2006)' =>
#			'Metasploit_Framework_License';
#		field 'Microsoft\'s Shared Source CLI/C#/Jscript License' => '';
#		field 'Microsoft_Shared_Source_License' => ''; # iri
		field 'MITRE Collaborative Virtual Workspace License (CVW)' => 'CVW';

#		field 'MSNTP License'         => 'MSNTP';
#		field 'mrouted license (old)' => 'mrouted';
#		field 'NASA CDF License'      => 'NasaCDF';

		field 'NASA Open Source Agreement v1.3' => 'NASA-1.3';
		field 'NASA Open Source Agreement'      => 'NASA-1.3';    # iri

# since 20210108		field 'Nmap Public Source License Version 0.92 (NPSL)' => '';

		field 'OCLC Public Research License 2.0' => 'OCLC-2.0';

#		field 'Open CASCADE Technology Public License' => '';

		field 'Open Group Test Suite License' => 'OGTSL';

#		field 'Open Map License'                     => '';
#		field 'Open Motif Public End User License'   => '';

		field 'Open Public License'      => 'OPL-1.0';
		field 'Open Public License v1.0' => 'OPL-1.0';    # default caption

#		field 'OSGi Specification License'           => '';
#		field 'Paul Hsieh Derivative License'        => '';
#		field 'Paul Hsieh Exposition License'        => '';
#		field 'Pine License'                         => '';
#		field 'qmail License'                        => '';

		field 'Reciprocal Public License' => 'RPL';

		field 'Ricoh Source Code Public License' => 'RSCPL';

#		field 'Scilab License (OLD)'                 => 'Scilab_License_Old';
#		field 'Server Side Public License v1 (SSPL)' => 'SSPL';
# too broad		field 'SGI Free Software License B 1.1 or older' => '';
#		field 'SGI GLX Public License 1.0'  => 'GLX_Public_License';
#		field 'Siren14 License Agreement'   => 'Siren14_Licensing_Agreement';
#		field 'Spin Commercial License'     => '';
#		field 'Squeak License'              => '';
#		field 'SystemC Open Source License' => '';
#		field 'Sun Binary Code License Agreement' => '';
#		field 'Sun Community Source License'               => '';
#		field 'Sun RPC License'                            => 'SunRPC';

		field 'Sybase Open Watcom Public License 1.0' => 'Watcom-1.0';

#		field 'Terracotta Public License 1.0'              => '';

		field 'TrueCrypt License' => 'TrueCrypt';

#		field 'TORQUE v2.5+ Software License v1.0'         => '';
#		field 'University of Utah Public License'          => '';
#		field 'University of Washington Free Fork License' => 'UofWFreeFork';
#		field 'unrar license'                              => 'Unrar';

		field 'X.Net License' => 'Xnet';

		field 'Yahoo Public License 1.0' => 'YPL-1.0';

		field 'Zimbra Public License 1.3' => 'Zimbra-1.3';

		# Good Documentation Licenses
#		field 'Apple\'s Common Documentation License, Version 1.0' => 'CDL';
#		field 'Common_Documentation_License' => 'CDL'; # iri

		field 'Creative Commons Attribution license'    => 'CC-BY';
		field 'Creative Commons Attribution-ShareAlike' => 'CC-BY-SA';

#		field 'FreeBSD Documentation License'              => 'FBSDDL';

		field 'GNU Free Documentation License' => 'GFDL';
		field 'GNU General Public License'     => 'GPL';

#		field 'IEEE and Open Group Documentation License' => 'IEEE';
#		field 'Linux Documentation Project License'        => 'LDPL';
#		field 'Old FSF Documentation License'  => 'OFSFDL';
#		field 'OldFSFDocLicense' => 'OFSFDL';
#		field 'Open Publication License, v1.0' => '';
#		field 'Open Publication' => ''; # short
#		field 'Public Use License, v1.0'       => 'PublicUseLicense';
#		field 'Public Use'                     => 'PublicUseLicense'; # short

		# Bad Documentation Licenses
#		field 'Open Content License'           => '';
#		field 'Open Directory License'         => '';
#		field 'W3C Documentation License'      => '';

		# Good Content Licenses
# duplicate		field 'Creative Commons Attribution license' => 'CC-BY';
# duplicate		field 'Creative Commons Attribution-ShareAlike' => 'CC-BY-SA';
		field 'Creative Commons Attribution-NoDerivs' => 'CC-BY-ND';

# duplicate		field 'Creative Commons Zero 1.0 Universal' => 'CC0';
#		field 'Data license Germany - attribution 2.0' => 'DL-DE-BY';
#		field 'Design Science License'                    => 'DSL';
#		field 'Distributed Management Task Force License' => 'DMTF';
#		field 'EFF Open Audio License v1' => 'OAL';
#		field 'OpenAudioLicense'          => 'OAL';
#		field 'Ethymonics Free Music License' => 'EFML';

		field 'Free Art License' => 'FAL';
		field 'Free Art'         => 'FAL';    # short

#		field 'GeoGratis Licence Agreement' => 'GeoGratis';

# duplicate		field 'GNU General Public License' => 'GPL';

		field 'Open Data Commons Public Domain Dedication and Licence' =>
			'PDDL-1.0';
		field 'PDDL' => 'PDDL-1.0';           # iri

#		field 'Open Data License (GeoLite Country and GeoLite City databases)' => '';

		# Bad Content Licenses
#		field 'CAcert Non-Related Persons Disclaimer and License' => '';
		field 'Creative Commons Attribution-NonCommercial-NoDerivs' =>
			'CC-BY-NC-ND';
		field 'Creative Commons Attribution-NonCommercial' => 'CC-BY-NC';
		field 'Creative Commons Attribution-NonCommercial-ShareAlike' =>
			'CC-BY-NC-SA';
		field 'Creative Commons Sampling Plus 1.0' => 'CC-SP-1.0';

#		field 'LinuxTag Yellow OpenMusic License' => '';

		# Good Font Licenses
		field 'SIL Open Font License 1.1' => 'OFL';

#		field 'Adobe/TUG Utopia license agreement' => 'Utopia';
#		field 'AMS Bluesky Font License' => 'AMS';
#		field 'Arphic Public License' => 'Arphic';
#		field 'Atkinson Hyperlegible Font License' => 'AHFL';
#		field 'Baekmuk License' => 'Baekmuk';
#		field 'Bitstream Vera Font License' => '';
#		field 'Bitstream Vera' => ''; # short
#		field 'Charter License' => 'Charter';
# duplicate		field 'Creative Commons Attribution license' => 'CC-BY';
#		field 'DoubleStroke Font License' => 'DoubleStroke';
#		field 'ec Font License' => 'ec';
#		field 'Elvish Font License' => 'Elvish';
#		field 'GUST Font License' => 'LPPL';
#		field 'Hack Open Font License' => 'HOFL';
#		field 'Hershey Font License' => 'Hershey';

		field 'IPA Font License' => 'IPA';

#		field 'Liberation Font License' => 'Liberation';
# duplicate		field 'LaTeX Project Public License' => 'LPPL';
#		field 'Lucida Legal Notice' => 'Lucida';
#		field 'MgOpen Font License' => 'MgOpen';
#		field 'mplus Font License' => 'mplus';
#		field 'ParaType Font License' => 'PTFL';
#		field 'Punknova Font License' => 'Punknova';
#		field 'STIX Fonts User License' => 'STIX';
#		field 'Wadalab Font License' => 'Wadalab';
#		field 'XANO Mincho Font License' => 'XANO';

		# Bad Font Licenses
#		field 'DIP SIPA Font License' => '';
#		field 'Larabie Fonts License' => '';
#		field 'Literat Font License' => '';
#		field 'Ubuntu Font License' => '';

		# BSD
		field 'a BSD-style license' => 'BSD';    # group page
		field 'BSD'                 => 'BSD';    # iri
		field 'BSD license'         => 'BSD';    # default caption

		# Fedora use BSD-4-Clause-UC as proof but names are more general
		field 'Original BSD License' => 'BSD-4-Clause';
		field 'Original BSD License (BSD with advertising)' =>
			'BSD-4-Clause';                      # page

		field 'New BSD'                            => 'BSD-3-Clause';
		field 'New BSD (no advertising, 3 clause)' => 'BSD-3-Clause';

		field 'FreeBSD BSD Variant (2 clause BSD)' => 'BSD-2-Clause-FreeBSD';

		field 'Academy of Motion Picture Arts and Sciences BSD Variant' =>
			'AMPAS';

#		field 'Hybrid BSD' => '';
#		field 'HybridBSD' => ''; # anchor
#		field 'BSD Without Notice Requirement' => '';
#		field 'BSDWithoutNoticeRequirement' => '';
# variant		field 'BSDThreeClauseVariant' => '';
# variant		field 'BSD Three Clause Variant' => '';
#		field 'VTK BSD' => '';
# variant		field 'VTKBSDVariant' => '';
# variant		field 'BSD-style license, Compilation Variant' => '';
# variant		field 'BSD-style license, AES Variant' => '';
# variant		field 'BSD-style license, jCharts Variant' => '';
# variant		field 'BSD-style license, Modification Variant' => '';
# variant		field 'BSD-style license, Advertising Variant' => '';
# variant		field 'BSD-style license, OpenData Variant' => '';
# variant		field 'BSD-style license, xvt variant' => '';
# variant		field 'BSD-style license, tcp_wrappers variant' => '';

		# CDDL
		field 'CDDL' => 'CDDL';    # group page
		field 'Common Development and Distribution License' =>
			'CDDL';                # default caption

		# MIT
		field 'an MIT-style license' => 'MIT';
		field 'MIT'                  => 'MIT';    # group page
		field 'MIT license'          => 'MIT';    # default caption

		field 'MIT-style license, Old Style' => 'mit_oldstyle';
		field 'MIT (Old Style)' => 'mit_oldstyle';    # default caption

		field
			'MIT-style license, Old Style (no advertising without permission)'
			=> 'mit_oldstyle_permission';

		field 'MIT-style license, Old Style with legal disclaimer' =>
			'mit_oldstyle_disclaimer';
		field 'MIT (Old Style, legal disclaimer)' =>
			'mit_oldstyle_disclaimer';                # default caption

#		field 'MIT-style license, Old Style with legal disclaimer 2' => '';
#		field 'MIT-style license, Old Style with legal disclaimer 3' => '';
# variant		field 'MIT-style license, Old Style (Bellcore variant)' => '';

		field 'MIT-style license, PostgreSQL License (MIT Variant)' =>
			'PostgreSQL';

#		field 'MIT-style license, CMU Style' => '';

		field 'MIT-style license, MLton variant' => 'SMLNJ';
		field 'MIT-style license, Standard ML of New Jersey Variant' =>
			'SMLNJ';

		field 'MIT-style license, WordNet Variant' => 'WordNet';
		field 'WordNet License' => 'WordNet';    # default caption

#		field 'MIT-style license, Modern Style with sublicense' => '';
#		field 'MIT-style license, Modern Style without sublicense (Unicode)' => '';
# variant		field 'MIT-style license, Modern Variants' => '';

		field 'MIT-style license, Modern style (ICU Variant)' => 'ICU';
		field 'ICU License' => 'ICU';            # default caption

		field 'MIT-style license, feh variant' => 'MIT-feh';

		field 'MIT-style license, enna variant' => 'MIT-enna';

# variant		field 'MIT-style license, Thrift variant' => '';
#		field 'Thrift' => '';

		field 'MIT-style license, mpich2 variant' => 'mpich2';

		field 'MIT-style license, Festival variant' => 'Festival';
		field 'Festival'                            => 'Festival';

# variant		field 'MIT-style license, Minimal variant' => '';

		field
			'MIT-style license, Another Minimal variant (found in libatomic_ops)'
			=> 'bdwgc';
		field 'Boehm GC License' => 'bdwgc';    # default caption

		field 'MIT-style license, Adobe Glyph List Variant' => 'Adobe-Glyph';

		field 'MIT-style license, Xfig Variant' => 'mit_xfig';
		field 'Xfig'                            => 'mit_xfig';    # short

		field 'MIT-style license, Hylafax Variant' => 'libtiff';
		field 'Hylafax'                            => 'libtiff';

# variant		field 'MIT-style license, DANSE Variant' => '';

		field 'MIT-style license, Nuclear Variant' => 'mit_widget';

		field 'MIT-style license, Epinions Variant' => 'mit_epinions';

		field 'MIT-style license, OpenVision Variant' => 'mit_openvision';

		field 'MIT-style license, PetSC Variant' => 'DSDP';

		field 'MIT-style license, Whatever Variant' => 'mit_whatever';

		field 'MIT-style license, UnixCrypt Variant' => 'mit_unixcrypt';

# variant		field 'MIT-style license, UnixCrypt Variant, Variant Text' => '';

		field 'MIT-style license, HP Variant' => 'mit_osf';

		field 'MIT-style license, Cheusov variant' => 'STLport';    # page
		field 'STLport License Agreement' => 'STLport';    # default caption

		field 'MIT-style license, NTP variant' => 'NTP';
		field 'NTP License'                    => 'NTP';    # default caption

		end();
	},
	'coverage of Fedora snapshot from 2021-07-31'
);

done_testing;
