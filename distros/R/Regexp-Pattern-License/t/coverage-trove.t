use Test2::V0;

use lib 't/lib';
use Test2::Tools::LicenseRegistry;

plan 1;

# Key is last segment of trove identifier, or multiword shortname
# Key is singleword shortname, or default name

# Data source (last checked 2021-08-10):
# <https://pypi.org/classifiers/>

# dirty dumps (needs further work):
# curl -s 'https://pypi.org/classifiers/' | perl -nE '/href.*License :: (?:[^:]+:: )*([^<()]+(?:\((?:([^<() ]+)|([^<()]+(?: [^<()]+)+))\))?)/ and do { say '"\"\\t\\tfield '\$1' => '\$2';\"; say \"\\t\\tfield '\$3' => '';\" if \$3 }" | sort

like(
	license_org_metadata('trove'),
	hash {
		field 'Academic Free License (AFL)'          => 'AFL';
		field 'Aladdin Free Public License (AFPL)'   => 'AFPL';
		field 'Apache Software License'              => 'Apache';
		field 'Apple Public Source License'          => 'APSL';
		field 'Artistic License'                     => 'Artistic';
		field 'Attribution Assurance License'        => 'AAL';
		field 'BSD License'                          => 'BSD';
		field 'Boost Software License 1.0 (BSL-1.0)' => 'BSL-1.0';
		field 'CC0 1.0 Universal (CC0 1.0)'          => 'CC0-1.0';
		field 'CC0 1.0'                              => 'CC0-1.0';
		field
			'CEA CNRS Inria Logiciel Libre License, version 2.1 (CeCILL-2.1)'
			=> 'CeCILL-2.1';
		field 'CeCILL-B Free Software License Agreement (CECILL-B)' =>
			'CECILL-B';
		field 'CeCILL-C Free Software License Agreement (CECILL-C)' =>
			'CECILL-C';
		field 'Common Development and Distribution License 1.0 (CDDL-1.0)' =>
			'CDDL-1.0';
		field 'Common Public License' => 'CPL';

#		field 'DFSG approved' => '';
		field 'Eclipse Public License 1.0 (EPL-1.0)'         => 'EPL-1.0';
		field 'Eclipse Public License 2.0 (EPL-2.0)'         => 'EPL-2.0';
		field 'Eiffel Forum License (EFL)'                   => 'EFL';
		field 'Eiffel Forum License'                         => 'EFL';
		field 'European Union Public Licence 1.0 (EUPL 1.0)' => 'EUPL-1.0';
		field 'EUPL 1.0'                                     => 'EUPL-1.0';
		field 'European Union Public Licence 1.1 (EUPL 1.1)' => 'EUPL-1.1';
		field 'EUPL 1.1'                                     => 'EUPL-1.1';
		field 'European Union Public Licence 1.2 (EUPL 1.2)' => 'EUPL-1.2';
		field 'EUPL 1.2'                                     => 'EUPL-1.2';

#		field 'Free For Educational Use' => '';
#		field 'Free For Home Use' => '';
#		field 'Free To Use But Restricted' => '';
#		field 'Free for non-commercial use' => '';
#		field 'Freely Distributable' => '';
#		field 'Freeware' => '';
		field 'GNU Affero General Public License v3' => 'AGPLv3';
		field 'GNU Affero General Public License v3 or later (AGPLv3+)' =>
			'AGPLv3+';
		field 'GNU Free Documentation License (FDL)'            => 'FDL';
		field 'GNU General Public License (GPL)'                => 'GPL';
		field 'GNU General Public License v2 (GPLv2)'           => 'GPLv2';
		field 'GNU General Public License v2 or later (GPLv2+)' => 'GPLv2+';
		field 'GNU General Public License v3 (GPLv3)'           => 'GPLv3';
		field 'GNU General Public License v3 or later (GPLv3+)' => 'GPLv3+';
		field 'GNU Lesser General Public License v2 (LGPLv2)'   => 'LGPLv2';
		field 'GNU Lesser General Public License v2 or later (LGPLv2+)' =>
			'LGPLv2+';
		field 'GNU Lesser General Public License v3 (LGPLv3)' => 'LGPLv3';
		field 'GNU Lesser General Public License v3 or later (LGPLv3+)' =>
			'LGPLv3+';
		field 'GNU Library or Lesser General Public License (LGPL)' => 'LGPL';

#		field 'GUST Font License 1.0' => '';
#		field 'GUST Font License 2006-09-30' => '';
		field 'Historical Permission Notice and Disclaimer (HPND)' => 'HPND';
		field 'IBM Public License'                                 => 'IPL';
		field 'ISC License (ISCL)'                                 => 'ISCL';
		field 'Intel Open Source License'                          => 'Intel';
		field 'Jabber Open Source License'         => 'jabberpl';
		field 'MIT License'                        => 'MIT';
		field 'MIT No Attribution License (MIT-0)' => 'MIT-0';
		field 'MITRE Collaborative Virtual Workspace License (CVW)' => 'CVW';
		field 'MirOS License (MirOS)'                => 'MirOS';
		field 'Motosoto License'                     => 'Motosoto';
		field 'Mozilla Public License 1.0 (MPL)'     => 'MPL-1.0';
		field 'Mozilla Public License 1.1 (MPL 1.1)' => 'MPL-1.1';
		field 'MPL 1.1'                              => 'MPL-1.1';
		field 'Mozilla Public License 2.0 (MPL 2.0)' => 'MPL-2.0';
		field 'MPL 2.0'                              => 'MPL-2.0';
		field 'Nethack General Public License'       => 'NGPL';
		field 'Netscape Public License (NPL)'        => 'NPL';
		field 'Nokia Open Source License (NOKOS)'    => 'NOKOS';
		field 'Nokia Open Source License'            => 'NOKOS';
		field 'Open Group Test Suite License'        => 'OGTSL';
		field 'Open Software License 3.0 (OSL-3.0)'  => 'OSL-3.0';

#		field 'OSI Approved' => '';
#		field 'Other/Proprietary License' => '';
		field 'PostgreSQL License'                   => 'PostgreSQL';
		field 'Public Domain'                        => 'public-domain';
		field 'Python License (CNRI Python License)' => 'Python-2.0';
		field 'CNRI Python License'                  => 'Python-2.0';
		field 'Python Software Foundation License'   => 'PSF-2.0';
		field 'Qt Public License (QPL)'              => 'QPL';

#		field 'Repoze Public License' => '';
		field 'Ricoh Source Code Public License'              => 'RSCPL';
		field 'SIL Open Font License 1.1 (OFL-1.1)'           => 'OFL-1.1';
		field 'Sleepycat License'                             => 'Sleepycat';
		field 'Sun Industry Standards Source License (SISSL)' => 'SISSL';
		field 'Sun Public License'                            => 'SPL';
		field 'The Unlicense (Unlicense)'                     => 'Unlicense';
		field 'Universal Permissive License (UPL)'            => 'UPL';
		field 'University of Illinois/NCSA Open Source License' => 'NCSA';
		field 'Vovida Software License 1.0'                     => 'VSL-1.0';
		field 'W3C License'                                     => 'W3C';
		field 'X.Net License'                                   => 'Xnet';
		field 'Zope Public License'                             => 'ZPL';
		field 'zlib/libpng License'                             => 'Zlib';

		# default summaries
		field 'a BSD-style license'  => 'BSD';
		field 'an MIT-style license' => 'MIT';

		end();
	},
	'coverage of PyPA/PyPI trove classifiers'
);

done_testing;
