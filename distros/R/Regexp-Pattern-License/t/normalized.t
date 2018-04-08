#!perl

use utf8;
use strict;
use warnings;

use lib 't/lib';

use MyTest tests => 82;

license_covered(
	'adobe_2006',
	name => 'Adobe 2006 License',
	text => <<EOF,
Adobe Systems Incorporated grants to you a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license, to reproduce, prepare derivative works of, publicly display, publicly perform, and distribute this source code and such derivative works in source or object code form without any attribution requirements.

The name "Adobe Systems Incorporated" must not be used to endorse or promote products derived from the source code without prior written permission.

You agree to indemnify, hold harmless and defend Adobe Systems Incorporated from and against any loss, damage, claims or lawsuits, including attorney's fees that arise or result from your use or distribution of the source code.

THIS SOURCE CODE IS PROVIDED "AS IS" AND "WITH ALL FAULTS", WITHOUT ANY TECHNICAL SUPPORT OR ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
ALSO, THERE IS NO WARRANTY OF NON-INFRINGEMENT, TITLE OR QUIET ENJOYMENT.
IN NO EVENT SHALL MACROMEDIA OR ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOURCE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'adobe_glyph',
	name => 'Adobe Glyph List License',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this documentation file to use, copy, publish, distribute, sublicense, and/or sell copies of the documentation, and to permit others to do the same, provided that:
- No modification, editing or other alteration of this document is allowed; and
- The above copyright notice and this permission notice shall be included in all copies of the documentation.

Permission is hereby granted, free of charge, to any person obtaining a copy of this documentation file, to create their own derivative works from the content of this document to use, copy, publish, distribute, sublicense, and/or sell the derivative works, and to permit others to do the same, provided that the derived work is not represented as being a copy or version of this document.

Adobe shall not be liable to any party for any loss of revenue or profit or for indirect, incidental, special, consequential, or other similar damages, whether based on tort (including without limitation negligence or strict liability), contract or other legal or equitable grounds even if Adobe has been advised or had reason to know of the possibility of such damages.
The Adobe materials are provided on an "AS IS" basis.
Adobe specifically disclaims all express, statutory, or implied warranties relating to the Adobe materials, including but not limited to those concerning merchantability or fitness for a particular purpose or non-infringement of any third party rights regarding the Adobe materials.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'afl',
	name    => 'Academic Free License',
	license => <<EOF,
This Academic Free License (the "License") applies to any original work of authorship (the "Original Work") whose owner (the "Licensor") has placed the following licensing notice adjacent to the copyright notice for the Original Work:
EOF
);

license_covered(
	'aladdin',
	name  => 'Aladdin Free Public License',
	grant => <<EOF,
This program may also be distributed as part of Aladdin Ghostscript, under the terms of the Aladdin Free Public License (the "License").

Every copy of Aladdin Ghostscript must include a copy of the License, normally in a plain ASCII text file named PUBLIC.
The License grants you the right to copy, modify and redistribute Aladdin Ghostscript, but only under certain conditions described in the License.
Among other things, the License requires that the copyright notice and this notice be preserved on all copies.
EOF
);

license_covered(
	'agpl',
	name  => 'GNU Affero General Public License',
	grant => <<EOF,
This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'apache',
	name  => 'Apache License',
	iri   => 'https://www.apache.org/licenses/LICENSE-2.0',
	grant => <<EOF,
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
EOF
	TODO => [
		qw(
			subject_license
			not_grant_iri)
	]
);

license_covered(
	'apafml',
	name => 'Adobe Postscript AFM License',
	text => <<EOF,
This file and the 14 PostScript(R) AFM files it accompanies may be used, copied, and distributed for any purpose and without charge, with or without modification, provided that all copyright notices are retained; that the AFM files are not distributed without this file; that all modifications to this file or any of the AFM files are prominently noted in the modified file(s); and that this paragraph is not modified.
Adobe Systems has no responsibility or obligation to support the use of the AFM files.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'artistic_2',
	name => 'Artistic License 2.0',
	iri  => 'http://www.perlfoundation.org/artistic_license_2_0',
	text => <<EOF,
Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'bdwgc',
	name => 'bdwgc',
	iri  => 'http://www.hboehm.info/gc/license.txt',
	text => <<EOF,
Permission is hereby granted to use or copy this program for any purpose, provided the above notices are retained on all copies.
Permission to modify the code and to distribute modified code is granted, provided the above notices are retained, and a notice that the code was modified is included with the above copyright notice.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'bdwgc_matlab',
	text => <<EOF,
Permission is hereby granted to use or copy this program for any purpose, provided the above notices are retained on all copies.
User documentation of any code that uses this code must cite the Authors, the Copyright, and "Used by permission."
If this code is accessible from within Matlab, then typing "help colamd" or "colamd" (with no arguments) must cite the Authors.
Permission to modify the code and to distribute modified code is granted, provided the above notices are retained, and a notice that the code was modified is included with the above copyright notice.
You must also retain the Availability information below, of the original version.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'bsd_2_clause',
	name => 'BSD 2-Clause',
	text => <<EOF,
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'bsd_3_clause',
	name => 'BSD 3-Clause',
	text => <<EOF,
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'bsd_4_clause',
	name => 'BSD 4-Clause',
	text => <<EOF,
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software must display the following acknowledgement:
This product includes software developed by the <organization>.
4. Neither the name of the <organization> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'bsl',
	name => 'Boost Software License',
	iri  => 'http://www.boost.org/LICENSE_1_0.txt',
	TODO => [
		qw(
			subject_license subject_name
			)
	],
);

license_covered(
	'bsl_1',
	name => 'Boost Software License 1.0',
	iri  => 'http://www.boost.org/LICENSE_1_0.txt',
	TODO => [
		qw(
			subject_license subject_name
			)
	],
);

license_covered(
	'cc_by',
	name => 'Creative Commons Attribution 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_by_nc',
	name =>
		'Creative Commons Attribution-NonCommercial 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_by_nc_nd',
	name =>
		'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_by_nc_sa',
	name =>
		'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_by_nd',
	name =>
		'Creative Commons Attribution-NoDerivatives 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_by_sa',
	name =>
		'Creative Commons Attribution-ShareAlike 4.0 International Public License',
	TODO => [
		qw(
			subject_license subject_iri
			)
	],
);

license_covered(
	'cc_cc0',
	name => 'Creative Commons Zero 1.0 Universal',
	iri =>
		'https://en.wikipedia.org/wiki/Creative_Commons_license#Zero_/_public_domain',
	grant =>
		'To the extent possible under law, the person who associated CC0 with this work has waived all copyright and related or neighboring rights to this work',
	TODO => [
		qw(
			subject_license
			)
	],
);

license_covered(
	'cc_sp',
	name => 'Creative Commons Sampling Plus 1.0',
	TODO => [
		qw(
			subject_iri subject_license
			)
	],
);

license_covered(
	'cddl',
	name => 'Common Development and Distribution License',
	text => <<EOF,
COMMON DEVELOPMENT AND DISTRIBUTION LICENSE (CDDL)
Version 1.0
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'cecill',
	name => 'CeCILL Free Software License Agreement',
	text => <<EOF,
CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL

Version 2.1 du 2013-06-21
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'cecill_1',
	name => 'CeCILL Free Software License Agreement v1.0',
	iri  => 'https://cecill.info/licences/Licence_CeCILL_V1-fr.html',
	text => <<EOF,
Version 1 du 21/06/2004
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'cecill_1_1',
	name => 'CeCILL Free Software License Agreement v1.1',
	iri  => 'https://cecill.info/licences/Licence_CeCILL_V1.1-US.html',
	text => <<EOF,
Version 1.1 of 10/26/2004
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'cecill_2',
	name => 'CeCILL Free Software License Agreement v2.0',
	iri  => 'https://cecill.info/licences/Licence_CeCILL_V2-fr.html',
	text => <<EOF,
Version 2.0 du 2006-09-05.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'cecill_2_1',
	name  => 'CeCILL Free Software License Agreement v2.1',
	iri   => 'https://cecill.info/licences/Licence_CeCILL_V2.1-fr.html',
	grant => <<EOF,
This software is governed by the CeCILL  license under French law and abiding by the rules of distribution of free software.
You can  use, modify and/ or redistribute the software under the terms of the CeCILL license as circulated by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".
EOF
	text => <<EOF,
Version 2.1 du 2013-06-21
EOF
	TODO => [
		qw(grant_grant
			subject_name
			)
	]
);

license_covered(
	'cecill_b',
	name  => 'CeCILL-B Free Software License Agreement',
	iri   => 'https://cecill.info/licences/Licence_CeCILL-B_V1-en.html',
	grant => <<EOF,
This software is governed by the CeCILL-B license under French law and abiding by the rules of distribution of free software.
You can  use, modify and/ or redistribute the software under the terms of the CeCILL-B license as circulated by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".
EOF
	text => <<EOF,
Ce contrat est une licence de logiciel libre dont l'objectif est de conférer aux utilisateurs une très large liberté de modification et de redistribution du logiciel régi par cette licence.
EOF
	TODO => [qw(not_iri_name)]
);

license_covered(
	'cecill_c',
	name  => 'CeCILL-C Free Software License Agreement',
	iri   => 'https://cecill.info/licences/Licence_CeCILL-C_V1-fr.html',
	grant => <<EOF,
This software is governed by the CeCILL-C license under French law and abiding by the rules of distribution of free software.
You can  use, modify and/ or redistribute the software under the terms of the CeCILL-C license as circulated by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".
EOF
	text => <<EOF,
6.4 MENTIONS DES DROITS

Le Licencié s'engage expressément:

1. à ne pas supprimer ou modifier de quelque manière que ce soit les mentions de propriété intellectuelle apposées sur le Logiciel;

2. à reproduire à l'identique lesdites mentions de propriété intellectuelle sur les copies du Logiciel modifié ou non;

3. à faire en sorte que l'utilisation du Logiciel, ses mentions de propriété intellectuelle et le fait qu'il est régi par le Contrat soient indiqués dans un texte facilement accessible notamment depuis l'interface de tout Logiciel Dérivé.

Le Licencié s'engage à ne pas porter atteinte, directement ou indirectement, aux droits de propriété intellectuelle du Titulaire et/ou des Contributeurs sur le Logiciel et à prendre, le cas échéant, à l'égard de son personnel toutes les mesures nécessaires pour assurer le respect des dits droits de propriété intellectuelle du Titulaire et/ou des Contributeurs.
EOF
	TODO => [
		qw(name_name
			subject_license
			)
	],
);

license_covered(
	'cube',
	name => 'Cube License',
	text => <<EOF,
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
additional clause specific to Cube:
4. Source versions may not be "relicensed" under a different license without my explicitly written permission.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'curl',
	name => 'curl License',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'dsdp',
	name => 'DSDP License',
	text => <<EOF,
This program discloses material protectable under copyright laws of the United States.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'epl',
	name => 'Eclipse Public License',
	text => <<EOF,
Eclipse Public License - v 1.0
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'eurosym',
	name => 'Eurosym License',
	text => <<EOF,
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
If you use this software in a product, an acknowledgment in the product documentation would be appreciated.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. You must not use any of the names of the authors or copyright holders of the original software for advertising or publicity pertaining to distribution without specific, written prior permission.
4. If you change this software and redistribute parts or all of it in any form, you must make the source code of the altered version of this software available.
5. This notice may not be removed or altered from any source distribution.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'fsfap',
	name => 'FSF All Permissive License',
	iri =>
		'https://www.gnu.org/prep/maintain/html_node/License-Notices-for-Other-Files.html',
	text => <<EOF,
Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved.
This file is offered as-is, without any warranty.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'fsful',
	name => 'FSF Unlimited License',
	text => <<EOF,
This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'fsfullr',
	name => 'FSF Unlimited License (with License Retention)',
	text => <<EOF,
This file is free software; the Free Software Foundation gives unlimited permission to copy and/or distribute it, with or without modifications, as long as this notice is preserved.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'ftl',
	name => 'FreeType Project License',
	text => <<EOF,
This license applies to all files found in such packages, and which do not fall under their own explicit license.
EOF
);

license_covered(
	'gfdl',
	name => 'GNU Free Documentation License',
	text => <<EOF,
GNU Free Documentation License
Version 1.1, March 2000
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'isc',
	name => 'ISC License',
	text => <<EOF,
Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'icu',
	name => 'ICU License',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, provided that the above copyright notice(s) and this permission notice appear in all copies of the Software and that both the above copyright notice(s) and this permission notice appear in supporting documentation.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization of the copyright holder.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'json',
	text => <<EOF,
The Software shall be used for Good, not Evil.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'jython',
	name => 'Jython License',
	text =>
		'4. PSF is making Jython available to Licensee on an "AS IS" basis.',
	TODO => [
		qw(name name_name
			subject_name
			)
	],
);

license_covered(
	'kevlin_henney',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose is hereby granted without fee, provided that this copyright and permissions notice appear in all copies and derivatives.
This software is supplied "as is" without express or implied warranty.
But that said, if there are any problems please get in touch.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'lgpl',
	name => 'GNU Library General Public License',
	text => <<EOF,
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'lgpl_bdwgc',
	text => <<EOF,
Permission is hereby granted to use or copy this program under the terms of the GNU LGPL, provided that the Copyright, this License, and the Availability of the original version is retained on all copies.
User documentation of any code that uses this code or any modified version of this code must cite the Copyright, this License, the Availability note, and "Used by permission."
Permission to modify the code and to distribute modified code is granted, provided the Copyright, this License, and the Availability note are retained, and a notice that the code was modified is included.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'llgpl',
	name => 'Lisp Lesser General Public License',
	iri  => 'http://opensource.franz.com/preamble.html',
	text => <<EOF,
as governed by the terms of the Lisp Lesser General Public License
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'libpng',
	name => 'libpng License',
	text => <<EOF,
1. The origin of this source code must not be misrepresented.
2. Altered versions must be plainly marked as such and must not be misrepresented as being the original source.
3. This Copyright notice may not be removed or altered from any source or altered source distribution.
The Contributing Authors and Group 42, Inc. specifically permit, without fee, and encourage the use of this source code as a component to supporting the PNG file format in commercial products.
If you use this source code in a product, acknowledgment is not required but would be appreciated.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_advertising',
	text => <<EOF,
The above copyright notice and this permission notice shall be included in all copies of the Software, its documentation and marketing & publicity materials, and acknowledgment shall be given in the documentation, materials and software packages that this Software was used.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_cmu',
	name => 'CMU License',
	text => <<EOF,
Permission to use, copy, modify and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appears in all copies and that both that copyright notice and this permission notice appear in supporting documentation, and that the name of CMU and The Regents of the University of California not be used in advertising or publicity pertaining to distribution of the software without specific written permission.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'mit_cmu_warranty',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appear in all copies and that both the copyright notice and this permission notice and warranty disclaimer appear in supporting documentation, and that the name of Lucent Technologies, Bell Labs or any Lucent entity not be used in advertising or publicity pertaining to distribution of the software without specific, written prior permission.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_enna',
	name => 'enna License',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies of the Software and its Copyright notices.
In addition publicly documented acknowledgment must be given that this software has been used if no source code of this software is made available publicly.
This includes acknowledgments in either Copyright notices, Manuals, Publicity and Marketing documents or any documentation provided with any product containing this software.
This License does not apply to any software that links to the libraries provided by this software (statically or dynamically), but only to the software provided.
EOF
	TODO => [
		qw(
			subject_name
			)
	]
);

license_covered(
	'mit_feh',
	name => 'feh License',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies of the Software and its documentation and acknowledgment shall be given in the documentation and software packages that this Software was used.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_new',
	name => 'MIT License',
	iri  => 'http://www.jclark.com/xml/copying.txt',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_new_materials',
	text => <<EOF,
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and/or associated documentation files (the "Materials"), to deal in the Materials without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Materials, and to permit persons to whom the Materials are furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Materials.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'mit_old',
	text => <<EOF,
Permission is hereby granted, without written agreement and without license or royalty fees, to use, copy, modify, and distribute this software and its documentation for any purpose, provided that the above copyright notice and the following two paragraphs appear in all copies of this software.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'mit_oldstyle',
	text => <<EOF,
Permission to use, copy, modify, distribute, and sell this software and its documentation for any purpose is hereby granted without fee, provided that the above copyright notice appear in all copies and that both that copyright notice and this permission notice appear in supporting documentation.
No representations are made about the suitability of this software for any purpose.
It is provided "as is" without express or implied warranty.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_oldstyle_disclaimer',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and this permission notice appear in supporting documentation.
THE AUTHOR PROVIDES THIS SOFTWARE ''AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit_oldstyle_permission',
	text => <<EOF,
License to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and this permission notice appear in supporting documentation, and that the name of IBM or Lexmark not be used in advertising or publicity pertaining to distribution of the software without specific, written prior permission.
IBM AND LEXMARK PROVIDE THIS SOFTWARE "AS IS", WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT OF THIRD PARTY RIGHTS.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE, INCLUDING ANY DUTY TO SUPPORT OR MAINTAIN, BELONGS TO THE LICENSEE.
SHOULD ANY PORTION OF THE SOFTWARE PROVE DEFECTIVE, THE LICENSEE (NOT IBM OR LEXMARK) ASSUMES THE ENTIRE COST OF ALL SERVICING, REPAIR AND CORRECTION.
IN NO EVENT SHALL IBM OR LEXMARK BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mpl',
	name => 'Mozilla Public License',
	iri  => 'https://www.mozilla.org/MPL',
	text => <<EOF,
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/MPL/
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'ms_pl',
	name => 'Microsoft Public License',
	iri =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Public_License_(Ms-PL)',
);

license_covered(
	'ms_rl',
	name => 'Microsoft Reciprocal License',
	iri =>
		'https://en.wikipedia.org/wiki/Shared_source#Microsoft_Reciprocal_License_(Ms-RL)',
);

license_covered(
	'ntp',
	name => 'NTP License',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose with or without fee is hereby granted, provided that the above copyright notice appears in all copies and that both the copyright notice and this permission notice appear in supporting documentation, and that the name <<var;name=TMname;original=(TrademarkedName);match=.+>> not be used in advertising or publicity pertaining to distribution of the software without specific, written prior permission.
<<var;name=TMname;original=(TrademarkedName);match=.+>> makes no representations about the suitability this software for any purpose.
It is provided "as is" without express or implied warranty.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'ntp_disclaimer',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and this permission notice appear in supporting documentation, and that the name of M.I.T. not be used in advertising or publicity pertaining to distribution of the software without specific, written prior permission.
M.I.T. makes no representations about the suitability of this software for any purpose.
It is provided "as is" without express or implied warranty.

M.I.T. DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL M.I.T. BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	],
);

license_covered(
	'ofl',
	name => 'SIL Open Font License',
	iri  => 'http://scripts.sil.org/OFL',
	text => <<EOF,
SIL OPEN FONT LICENSE

Version 1.0 - 22 November 2005
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'openssl',
	name => 'OpenSSL License',
	text => <<'EOF',
6. Redistributions of any form whatsoever must retain the following acknowledgment: "This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)"

THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE OpenSSL PROJECT OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This product includes cryptographic software written by Eric Young (eay@cryptsoft.com). This product includes software written by Tim Hudson (tjh@cryptsoft.com).

Original SSLeay License

Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com) All rights reserved.

This package is an SSL implementation written by Eric Young (eay@cryptsoft.com). The implementation was written so as to conform with Netscapes SSL.

This library is free for commercial and non-commercial use as long as the following conditions are aheared to.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'postgresql',
	name => 'PostgreSQL License',
	text => <<EOF,
Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without a written agreement is hereby granted, provided that the above copyright notice and this paragraph and the following two paragraphs appear in all copies.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'public_domain',
	iri   => 'http://www.linfo.org/publicdomain.html',
	grant => <<EOF,
This file is put in the public domain
EOF
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'python',
	name => 'Python License',
	TODO => [
		qw(name name_name
			subject_license
			)
	],
);

license_covered(
	'python_2',
	name => 'Python Software Foundation License version 2',
	text =>
		'4. PSF is making Python available to Licensee on an "AS IS" basis.',
	TODO => [
		qw(name name_name
			subject_name
			)
	],
);

license_covered(
	'qpl',
	name => 'Q Public License',
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'rpsl',
	name => 'RealNetworks Public Source License',
	TODO => [
		qw(
			subject_license
			)
	]
);

license_covered(
	'sgi_b',
	name => 'SGI Free Software License B',
	iri  => 'https://www.sgi.com/projects/FreeB/',
	TODO => [
		qw(
			subject_license
			not_iri_name)
	]
);

license_covered(
	'unicode_strict',
	text => <<EOF,
This file is provided as-is by Unicode, Inc. (The Unicode Consortium).
No claims are made as to fitness for any particular purpose.
No warranties of any kind are expressed or implied.
The recipient agrees to determine applicability of information provided.  If this file has been provided on optical media by Unicode, Inc., the sole remedy for any claim will be exchange of defective media within 90 days of receipt.
Unicode, Inc. hereby grants the right to freely use the information supplied in this file in the creation of products supporting the Unicode Standard, and to make copies of this file in any form for internal or external distribution as long as this notice remains attached.
EOF
	TODO => [
		qw(
			subject_iri subject_name
			)
	]
);

license_covered(
	'unicode_tou',
	name => 'Unicode Terms of Use',
	text => <<EOF,
3. Any person is hereby authorized, without fee, to view, use, reproduce, and distribute all documents and files solely for informational purposes in the creation of products supporting the Unicode Standard, subject to the Terms and Conditions herein.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'wtfpl',
	name  => 'Do What The F*ck You Want To Public License',
	grant => 'This input method table is licensed under the WTFPL.',
	TODO  => [
		qw(name_name
			subject_license
			)
	],
);

license_covered(
	'zlib',
	name => 'zlib License',
	iri  => 'http://zlib.net/zlib_license.html',
	text => <<EOF,
This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'zlib_acknowledgement',
	name => 'zlib/libpng License with Acknowledgement',
	text => <<EOF,
This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
If you use this software in a product, an acknowledgment (see the following) in the product documentation is required.
Portions Copyright (c) 2002-2007 Charlie Poole or Copyright (c) 2002-2004 James W. Newkirk, Michael C. Two, Alexei A. Vorontsov or Copyright (c) 2000-2002 Philip A. Craig
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'bsd',
	name => 'BSD 4-Clause',
	iri  => 'https://en.wikipedia.org/wiki/BSD_licenses',
	text => <<EOF,
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software must display the following acknowledgement:
This product includes software developed by the <organization>.
4. Neither the name of the <organization> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
	TODO => [
		qw(
			subject_name
			)
	],
);

license_covered(
	'mit',
	name  => 'MIT License',
	iri   => 'https://en.wikipedia.org/wiki/MIT_License',
	grant => 'Released under the MIT license',
	TODO  => [
		qw(name_name
			subject_license
			)
	],
);

done_testing;
