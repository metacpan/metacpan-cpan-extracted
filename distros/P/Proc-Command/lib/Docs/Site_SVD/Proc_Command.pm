#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Proc_Command;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.04';
$DATE = '2003/07/27';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Proc_Command.pm' => [qw(0.04 2003/07/27), 'revised 0.03'],
    'MANIFEST' => [qw(0.04 2003/07/27), 'generated, replaces 0.03'],
    'Makefile.PL' => [qw(0.04 2003/07/27), 'generated, replaces 0.03'],
    'README' => [qw(0.04 2003/07/27), 'generated, replaces 0.03'],
    'lib/Proc/Command.pm' => [qw(1.05 2003/07/27), 'revised 1.04'],
    't/Proc/Command.d' => [qw(0.02 2003/07/27), 'revised 0.01'],
    't/Proc/Command.pm' => [qw(0.01 2003/07/14), 'unchanged'],
    't/Proc/Command.t' => [qw(0.02 2003/07/27), 'revised 0.01'],
    'tlib/File/Package.pm' => [qw(1.11 2003/07/27), 'new'],
    'tlib/Test/Tech.pm' => [qw(1.11 2003/07/27), 'new'],

);

########
# The ExtUtils::SVDmaker module uses the data after the __DATA__ 
# token to automatically generate this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time ExtUtils::SVDmaker generates this file.
#
#



=head1 Title Page

 Software Version Description

 for

 Proc::Command - backtick that does not use the shell for Perl under Windows

 Revision: C

 Version: 0.04

 Date: 2003/07/27

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright © 2003 Software Diamonds

 Classification: NONE

=head1 1.0 SCOPE

This paragraph identifies and provides an overview
of the released files.

=head2 1.1 Identification

This release,
identified in L<3.2|/3.2 Inventory of software contents>,
is a collection of Perl modules that
extend the capabilities of the Perl language.

=head2 1.2 System overview

The "L<Proc::Command|Proc::Command>" module extends the Perl language (the system).

Some Perls under Microsoft windows suffers disabilities over Unix Perls.
One particular disability is a backtick without the console.
Altough the Microsoft console, may be started without a window
(start command with /b option or spawn program call), the Perl
system command on windows usually create a window.
Creating a window causes immense user interface problem since 
it will randomly pop-up and take focus over the current window,
erasing current entries into that window.
Solutions such as "Proc::SafePipe" do not run on Perls for Window.

This module provides an answer by using the "open" command with
a pipe to provide a backtick without a console that will run
under Perls on Microsoft Windows.

=head2 1.3 Document overview.

This document releases Proc::Command version 0.04
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file found
at the following repository(s):

   http://www.softwarediamonds/packages/Proc-Command-0.04
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Proc-Command-0.04


Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=item License.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=back

=head2 3.2 Inventory of software contents

The content of the released, compressed, archieve file,
consists of the following files:

 file                                                         version date       comment
 ------------------------------------------------------------ ------- ---------- ------------------------
 lib/Docs/Site_SVD/Proc_Command.pm                            0.04    2003/07/27 revised 0.03
 MANIFEST                                                     0.04    2003/07/27 generated, replaces 0.03
 Makefile.PL                                                  0.04    2003/07/27 generated, replaces 0.03
 README                                                       0.04    2003/07/27 generated, replaces 0.03
 lib/Proc/Command.pm                                          1.05    2003/07/27 revised 1.04
 t/Proc/Command.d                                             0.02    2003/07/27 revised 0.01
 t/Proc/Command.pm                                            0.01    2003/07/14 unchanged
 t/Proc/Command.t                                             0.02    2003/07/27 revised 0.01
 tlib/File/Package.pm                                         1.11    2003/07/27 new
 tlib/Test/Tech.pm                                            1.11    2003/07/27 new


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Proc-Command-0.01

Originated

=item Proc-Command-0.02

Added a statement to support the VSM platform

$command = "MCR $command" if $^O eq 'VMS';

=item Proc-Command-0.03

Added a 1 at the end of the code section. Unix Perls very strict on this one.

=item Proc-Command-0.04

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=back

=head2 3.4 Adaptation data.

This installation requires that the installation site
has the Perl programming language installed.
There are no other additional requirements or tailoring needed of 
configurations files, adaptation data or other software needed for this
installation particular to any installation site.

=head2 3.5 Related documents.

There are no related documents needed for the installation and
test of this release.

=head2 3.6 Installation instructions.

Instructions for installation, installation tests
and installation support are as follows:

=over 4

=item Installation Instructions.

To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

   http://www.softwarediamonds/packages/Proc-Command-0.04
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Proc-Command-0.04


=item Prerequistes.

 None.


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Proc/Command.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There is still much work needed to ensure the quality 
of this module as follows:

=over 4

=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

=item *

All the tests are GO path tests. Should add
NOGO tests.

=item *

Add the requirements addressed as I<# R: >
comment to the tests

=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

=back

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=back

=head1 2.0 SEE ALSO

=over 4

=item L<Proc::Command|Proc::Command> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html
<hr>
<p><br>
<!-- BLK ID="PROJECT_MANAGEMENT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

1;

__DATA__

DISTNAME: Proc-Command^
REPOSITORY_DIR: packages^

VERSION : 0.04^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.03^
REVISION: C^


AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: backtick that does not use the shell for Perl under Windows^
TITLE   : Proc::Command - backtick that does not use the shell for Perl under Windows^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Proc/Command.pm
t/Proc/Command.*
lib/File/Package.pm => tlib/File/Package.pm
lib/Test/Tech.pm => tlib/Test/Tech.pm
^

PREREQ_PM:  ^
TESTS: t/Proc/Command.t^
EXE_FILES:  ^

CHANGES: 
Changes are as follows:

\=over 4

\=item Proc-Command-0.01

Originated

\=item Proc-Command-0.02

Added a statement to support the VSM platform

$command = "MCR $command" if $^^O eq 'VMS';

\=item Proc-Command-0.03

Added a 1 at the end of the code section. Unix Perls very strict on this one.

\=item Proc-Command-0.04

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The "L<Proc::Command|Proc::Command>" module extends the Perl language (the system).

Some Perls under Microsoft windows suffers disabilities over Unix Perls.
One particular disability is a backtick without the console.
Altough the Microsoft console, may be started without a window
(start command with /b option or spawn program call), the Perl
system command on windows usually create a window.
Creating a window causes immense user interface problem since 
it will randomly pop-up and take focus over the current window,
erasing current entries into that window.
Solutions such as "Proc::SafePipe" do not run on Perls for Window.

This module provides an answer by using the "open" command with
a pipe to provide a backtick without a console that will run
under Perls on Microsoft Windows.
^

PROBLEMS:
There is still much work needed to ensure the quality 
of this module as follows:

\=over 4

\=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

\=item *

All the tests are GO path tests. Should add
NOGO tests.

\=item *

Add the requirements addressed as I<# R: >
comment to the tests

\=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

\=back

^

LICENSE:
Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
^


INSTALLATION:
To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

${REPOSITORY}
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

NOTES:
The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=back
^

SEE_ALSO: 
\=over 4

\=item L<Proc::Command|Proc::Command> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back
^

HTML:
<hr>
<p><br>
<!-- BLK ID="PROJECT_MANAGEMENT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^
~-~


