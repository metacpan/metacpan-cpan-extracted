use Test2::V0;

plan 1;

use Regexp::Pattern::License;

my %RE = %Regexp::Pattern::License::RE;

# Key is either page title,
# with shortname stripped.
# or item names on list pages alphabetical, category, or do-not-use,
# with shortname stripped.
# Value is page name.
my %names = map {
	my $key = $_;
	my $id  = $RE{$key}{'name.alt.org.osi.synth.nogrant'}
		// $RE{$key}{'name.alt.org.osi'};
	my $maincaption = $RE{$key}{'caption.alt.org.osi.synth.nogrant'}
		// $RE{$key}{'caption.alt.org.osi'} // $RE{$key}{caption};
	my @altcaptions = map { $RE{$key}{$_} } (
		sort grep {
			/^(?:(?:name|caption)\.alt\.org\.osi\.misc\.|summary\.alt\.org\.osi)/
				and !/\.version\./
		} keys %{ $RE{$key} }
	);
	map { $_ => $id } $maincaption, @altcaptions;
	}
	grep {
	grep {/^name\.alt\.org\.osi(?:\.synth\.nogrant)?$/}
		keys %{ $RE{$_} }
	}
	keys %RE;

like(
	\%names,
	hash {
		field '0-clause BSD License' => '0BSD';          # list
		field '0-clause BSD license' => '0BSD';          # list in BSD sublist
		field '1-clause BSD License' => 'BSD-1-Clause';
		field 'The 2-Clause BSD License' => 'BSD-2-Clause';
		field '2-clause BSD License'     => 'BSD-2-Clause';    # list
		field '2-clause BSD license'     => 'BSD-2-Clause';    # category list
		field 'The 3-Clause BSD License' => 'BSD-3-Clause';
		field '3-clause BSD License'     => 'BSD-3-Clause';    # list
		field '3-clause BSD license'     => 'BSD-3-Clause';    # category list
		field 'Academic Free License ("AFL") v. 3.0' => 'AFL-3.0';
		field 'Academic Free License 3.0'            => 'AFL-3.0';      # list
		field 'Adaptive Public License 1.0'          => 'APL-1.0';
		field 'Adaptive Public License'              => 'APL-1.0';      # list
		field 'Apache Software License, version 1.1' => 'Apache-1.1';
		field 'Apache Software License 1.1'          => 'Apache-1.1';   # list
		field 'Apache License, Version 2.0'          => 'Apache-2.0';
		field 'Apache License 2.0'                   => 'Apache-2.0';   # list
		field 'Apple Public Source License 2.0'      => 'APSL-2.0';
		field 'Apple Public Source License' => 'APSL-2.0';     # category list
		field 'Artistic License 1.0'        => 'Artistic-1.0';
		field 'Artistic license 1.0'        => 'Artistic-1.0'; # list
		field 'Artistic license, version 1.0' =>
			'Artistic-1.0';    # do-not-use list
		field 'Artistic License 2.0'        => 'Artistic-2.0';
		field 'Artistic license 2.0'        => 'Artistic-2.0'; # category list
		field 'Artistic License 1.0 (Perl)' => 'Artistic-1.0-Perl'; # unlisted
		field 'Attribution Assurance License' => 'AAL';
		field 'Boost Software License 1.0'    => 'BSL-1.0';
		field 'Boost Software License'        => 'BSL-1.0';         # list
		field 'BSD-2-Clause-Patent'           => 'BSDplusPatent';
		field 'BSD-3-Clause-LBNL'             =>
			'BSD-3-Clause-LBNL';    # list in BSD sublist
		field 'BSD+Patent' => 'BSDplusPatent';

#		field 'CERN Open Hardware License Version 2 - Permissive' => 'CERN-OHL-P';
#		field 'CERN Open Hardware License Version 2 - Weakly Reciprocal' =>
#		'CERN-OHL-W';
#		field 'CERN Open Hardware License Version 2 - Strongly Reciprocl' =>
#		'CERN-OHL-S';
		field 'Cea Cnrs Inria Logiciel Libre License, version 2.1' =>
			'CECILL-2.1';
		field 'CeCILL License 2.1' => 'CECILL-2.1';    # list
		field 'Common Development and Distribution License 1.0' => 'CDDL-1.0';
		field 'Common Public Attribution License Version 1.0'   => 'CPAL-1.0';
		field 'Common Public Attribution License 1.0' => 'CPAL-1.0';    # list
		field 'Common Public License 1.0'             => 'CPL-1.0';
		field 'Common Public License, version 1.0'    => 'CPL-1.0';
		field 'Computer Associates Trusted Open Source License 1.1' =>
			'CATOSL-1.1';
		field 'Cryptographic Autonomy License version 1.0' => 'CAL-1.0';
		field 'Cryptographic Autonomy License v.1.0'  => 'CAL-1.0';     # list
		field 'CUA Office Public License'             => 'CUA-OPL-1.0';
		field 'CUA Office Public License Version 1.0' => 'CUA-OPL-1.0'; # list
		field 'Eclipse Public License 1.0'            => 'EPL-1.0';
		field 'Eclipse Public License version 2.0'    => 'EPL-2.0';
		field 'Eclipse Public License 2.0'            => 'EPL-2.0';     # list
		field 'eCos License version 2.0'              => 'eCos-2.0';
		field 'Educational Community License, Version 1.0' => 'ECL-1.0';
		field 'Educational Community License, Version 2.0' => 'ECL-2.0';
		field 'The Eiffel Forum License, version 1'        => 'EFL-1.0';
		field 'Eiffel Forum License V1.0'         => 'EFL-1.0';         # list
		field 'Eiffel Forum License, version 1.0' =>
			'EFL-1.0';    # do-not-use list
		field 'Eiffel Forum License, Version 2'     => 'EFL-2.0';
		field 'Eiffel Forum License V2.0'           => 'EFL-2.0';      # list
		field 'Entessa Public License'              => 'Entessa';
		field 'Entessa Public License Version. 1.0' => 'Entessa';
		field 'EU DataGrid Software License'        => 'EUDatagrid';
		field 'European Union Public License, version 1.2' => 'EUPL-1.2';
		field 'European Union Public License 1.2' => 'EUPL-1.2';       # list
		field 'European Union Public License' => 'EUPL-1.2';   # category list
		field 'Fair License'                  => 'Fair';
		field 'Frameworx License 1.0'         => 'Frameworx-1.0';
		field 'Frameworx License'             => 'Frameworx-1.0';  # list
		field 'Free Public License 1.0.0'     => '0BSD';           # list
		field 'FPL-1.0.0'                     => '0BSD';           # shortname
		field 'GNU Affero General Public License version 3' => 'AGPL-3.0';
		field 'GNU General Public License' => 'gpl-license';   # category list
		field 'GPL'                        => 'gpl-license';   # shortname
		field 'GNU General Public License version 2'  => 'GPL-2.0';
		field 'GNU General Public License, version 2' =>
			'GPL-2.0';                                         # category list
		field 'GNU General Public License version 3'  => 'GPL-3.0';
		field 'GNU General Public License, version 3' =>
			'GPL-3.0';                                         # category list
		field 'GNU LGPL' => 'lgpl-license';
		field 'LGPL'     => 'lgpl-license';                    # shortname
		field 'GNU Lesser General Public License' =>
			'lgpl-license';                                    # category list
		field 'GNU Library General Public License version 2' =>
			'LGPL-2.0';    # lgpl-license list
		field 'GNU Lesser General Public License version 2.1' => 'LGPL-2.1';
		field 'GNU Lesser General Public License version 3'   => 'LGPL-3.0';
		field 'Historical Permission Notice and Disclaimer'   => 'HPND';
		field 'IBM Public License Version 1.0'                => 'IPL-1.0';
		field 'IBM Public License 1.0'        => 'IPL-1.0';          # list
		field 'The Intel Open Source License' => 'Intel';
		field 'Intel Open Source License'     => 'Intel';            # list
		field 'IPA Font License'              => 'IPA';
		field 'ISC License'                   => 'ISC';
		field 'Jabber Open Source License'    => 'jabberpl';
		field 'LaTeX Project Public License, Version 1.3c' => 'LPPL-1.3c';
		field 'LaTeX Project Public License 1.3c' => 'LPPL-1.3c';    # list
		field 'Lawrence Berkeley National Labs BSD Variant License' =>
			'BSD-3-Clause-LBNL';
		field 'Licence Libre du Québec – Permissive (LiLiQ-P) version 1.1'
			=> 'LiLiQ-P-1.1';
		field
			'Licence Libre du Québec – Réciprocité (LiLiQ-R) version 1.1'
			=> 'LiLiQ-R-1.1';
		field
			'Licence Libre du Québec – Réciprocité forte (LiLiQ-R+) version 1.1'
			=> 'LiLiQ-Rplus-1.1';
		field 'Lucent Public License, Plan 9, version 1.0'   => 'LPL-1.0';
		field 'Lucent Public License ("Plan9"), version 1.0' =>
			'LPL-1.0';    # list
		field 'Lucent Public License Version 1.02' => 'LPL-1.02';
		field 'Microsoft Public License'           => 'MS-PL';
		field 'Microsoft Reciprocal License'       => 'MS-RL';
		field 'MirOS Licence'                      => 'MirOS';
		field 'The MIT License'                    => 'MIT';
		field 'MIT License'                        => 'MIT';         # list
		field 'MIT license'                        => 'MIT';   # category list
		field 'MIT No Attribution License'         => 'MIT-0';
		field 'The MITRE Collaborative Virtual Workspace License' => 'CVW';
		field 'MITRE Collaborative Virtual Workspace License' => 'CVW'; # list
		field 'Motosoto Open Source License - Version 0.9.1'  => 'Motosoto';
		field 'Motosoto License' => 'Motosoto';                         # list
		field 'The Mozilla Public License (MPL), version 1.0' => 'MPL-1.0';
		field 'Mozilla Public License 1.0'          => 'MPL-1.0';       # list
		field 'Mozilla Public License, version 1.0' =>
			'MPL-1.0';    # do-not-use list
		field 'Mozilla Public License 1.1'          => 'MPL-1.1';
		field 'Mozilla Public License, version 1.1' =>
			'MPL-1.1';    # do-not-use list
		field 'Mozilla Public License 2.0'           => 'MPL-2.0';
		field 'Mulan Permissive Software License v2' => 'MulanPSL-2.0';
		field 'MulanPSL - 2.0'  => 'MulanPSL-2.0';    # page shortname
		field 'Multics License' => 'Multics';
		field 'NASA Open Source Agreement v1.3'        => 'NASA-1.3';
		field 'NASA Open Source Agreement 1.3'         => 'NASA-1.3';   # list
		field 'NAUMEN Public License'                  => 'Naumen';
		field 'Naumen Public License'                  => 'Naumen';     # list
		field 'The Nethack General Public License'     => 'NGPL';
		field 'Nethack General Public License'         => 'NGPL';       # list
		field 'Nokia Open Source License Version 1.0a' => 'Nokia';
		field 'Nokia Open Source License'              => 'Nokia';      # list
		field 'NOKIA' => 'Nokia';    # page shortname
		field 'The Non-Profit Open Software License version 3.0' =>
			'NPOSL-3.0';
		field 'Non-Profit Open Software License 3.0' => 'NPOSL-3.0';    # list
		field 'NTP License'                          => 'NTP';
		field 'The OCLC Research Public License 2.0 License' => 'OCLC-2.0';
		field 'OCLC Research Public License 2.0'   => 'OCLC-2.0';       # list
		field 'The Open Group Test Suite License'  => 'OGTSL';
		field 'Open Group Test Suite License'      => 'OGTSL';          # list
		field 'Open Software License, version 1.0' => 'OSL-1.0';
		field 'Open Software License 1.0'          => 'OSL-1.0';        # list
		field 'The Open Software License 2.1'      => 'OSL-2.1';
		field 'Open Software License 2.1'          => 'OSL-2.1';        # list
		field 'The Open Software License 3.0'      => 'OSL-3.0';
		field 'Open Software License 3.0'          => 'OSL-3.0';        # list
		field 'Open Software License' => 'OSL-3.0';    # category list
		field 'OpenLDAP Public License Version 2.8' => 'OLDAP-2.8';
		field 'OSET Public License version 2.1'     => 'OPL-2.1';
		field 'OSET-PL-2.1'            => 'OPL-2.1'; # category list shortname
		field 'The PHP License 3.0'    => 'PHP-3.0';
		field 'PHP License 3.0'        => 'PHP-3.0'; # list
		field 'PHP License 3.01'       => 'PHP-3.01';
		field 'The PostgreSQL Licence' => 'PostgreSQL';
		field 'The PostgreSQL License' => 'PostgreSQL';    # list
		field 'Python License'         => 'Python-2.0';
		field 'overall Python license' => 'Python-2.0';
		field 'The CNRI portion of the multi-part Python License' =>
			'CNRI-Python';
		field 'CNRI portion of Python License' => 'CNRI-Python';   # shortname
		field 'CNRI Python license'            => 'CNRI-Python';   # list
		field 'The Q Public License Version'   => 'QPL-1.0';
		field 'Q Public License'               => 'QPL-1.0';       # list
		field 'RealNetworks Public Source License Version 1.0' => 'RPSL-1.0';
		field 'RealNetworks Public Source License V1.0' => 'RPSL-1.0';  # list
		field 'Reciprocal Public License, version 1.1'  => 'RPL-1.1';
		field 'Reciprocal Public License 1.5'           => 'RPL-1.5';
		field 'The Ricoh Source Code Public License'    => 'RSCPL';
		field 'Ricoh Source Code Public License'        => 'RSCPL';     # list
		field 'SIL OPEN FONT LICENSE'                   => 'OFL-1.1';
		field 'SIL Open Font License 1.1'               => 'OFL-1.1';   # list
		field 'Simple Public License'                   => 'SimPL-2.0';
		field 'Simple Public License 2.0'               => 'SimPL-2.0'; # list
		field 'Simple-2.0'            => 'SimPL-2.0';    # category list link
		field 'The Sleepycat License' => 'Sleepycat';
		field 'Sleepycat License'     => 'Sleepycat';    # list
		field 'Sun Industry Standards Source License' => 'SISSL';
		field 'Sun Public License, Version 1.0'       => 'SPL-1.0';
		field 'Sun Public License 1.0'                => 'SPL-1.0';     # list
		field 'The Sybase Open Source Licence'        => 'Watcom-1.0';
		field 'Sybase Open Watcom Public License 1.0' => 'Watcom-1.0';  # list
		field 'The Universal Permissive License (UPL), Version 1.0' => 'UPL';
		field 'Universal Permissive License' => 'UPL';                  # list
		field 'The University of Illinois/NCSA Open Source License' => 'NCSA';
		field 'University of Illinois/NCSA Open Source License'     =>
			'NCSA';                                                     # list
		field 'Upstream Compatibility License v1.0' => 'UCL-1.0';
		field 'Unicode, Inc. License Agreement - Data Files and Software' =>
			'Unicode-DFS-2016';
		field 'Unicode Data Files and Software License' =>
			'Unicode-DFS-2016';                                         # list
		field 'Unicode License Agreement - Data Files and Software' =>
			'Unicode-DFS-2016';    # category list
		field 'The Unlicense'                         => 'Unlicense';
		field 'The Vovida Software License v. 1.0'    => 'VSL-1.0';
		field 'Vovida Software License v. 1.0'        => 'VSL-1.0';     # list
		field 'The W3C® SOFTWARE NOTICE AND LICENSE' => 'W3C';
		field 'W3C License'                           => 'W3C';         # list
		field 'The wxWindows Library Licence'         => 'WXwindows';
		field 'wxWindows Library License'             => 'WXwindows';   # list
		field 'The X.Net, Inc. License'               => 'Xnet';
		field 'X.Net License'                         => 'Xnet';        # list
		field 'Zero-Clause BSD'                       => '0BSD';
		field 'Zero-Clause BSD / Free Public License 1.0.0' => '0BSD'
			; # old name: https://web.archive.org/web/20210128111142/https://opensource.org/licenses/0BSD
		field 'The Zope Public License Ver.2.0' => 'ZPL-2.0';
		field 'Zope Public License 2.0'         => 'ZPL-2.0';  # list
		field 'Zope Public License 2.o'         => 'ZPL-2.0';  # category list
		field 'The zlib/libpng License'         => 'Zlib';
		field 'zlib/libpng license'             => 'Zlib';     # list

		end();
	},
	'coverage of <https://opensource.org/licenses/alphabetical> (plus unlisted entries gpl-license lgpl-license LGPL-2.0)'
);

done_testing;
