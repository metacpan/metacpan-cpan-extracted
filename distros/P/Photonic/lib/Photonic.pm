package Photonic;

use 5.006;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Photonic - A perl package for calculations on photonics and metamaterials.

=head1 VERSION

Version 0.024

=cut


$Photonic::VERSION = '0.024';

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 SYNOPSIS

  use Photonic::LE::NR2::EpsTensor;
  use Photonic::Geometry::FromB;
  my $g=Photonic::Geometry::FromB->new(B=>$B);
  my $eps=Photonic::LE::NR2::EpsTensor->new(geometry=>$g, epsA=>$epsA, epsB=>$epsB, nh=>$N);
  my $epsilonTensor=$eps->epsTensor;

Calculates the dielectric tensor of a metamaterial made up of two
materials with dielectric functions $epsA and $epsB with a geometry $g
corresponding to a characteristic funcion $b and using $N Haydock
coefficients.

=head1 DESCRIPTION

Set of packages for the calculation of optical properties of
metamaterials. The included modules are:

=over 4

=item L<Photonic>

This file. This package.

=over 4

=item L<Photonic::CharacteristicFunctions>

Couple of examples of characteristic functions, helpful for fast
tests.

=item L<Photonic::Geometry>

Group of modules for geometrical characterization.

=over 4

=item L<Photonic::Geometry::FromB>

Geometrical attributes of binary metamaterials, obtained from a
characteristic function.

=item L<Photonic::Geometry::FromEpsilon>

Geometrical attributes, obtained from the microscopic dielectric function.

=item L<Photonic::Geometry::FromImage2D>

Geometrical attributes, obtained from a 2D image.

=back

=item L<Photonic::LE>

Group of modules for non retarded calculations based on the
longitudinal dielectric function.

=over 4

=item L<Photonic::LE::NP>

Group of modules for non retarded calculations based on the
longitudinal dielectric function for metamaterials made of an
arbitrary number of phases NP. Constrained to a macroscopic external
field of one Fourier component.

=over 4

=item L<Photonic::LE::NP::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::LE::NP::EpsL>

Calculate the longitudinal dielectric response.

=item L<Photonic::LE::NP::EpsTensor>

Calculate the dielectric tensor.

=back

=item L<Photonic::LE::NR2>

Group of modules for non retarded calculations based on the
longitudinal dielectric function of binary metamaterials, based on the
characteristic function.

=over 4

=item L<Photonic::LE::NR2::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::LE::NR2::EpsL>

Calculate the longitudinal dielectric response.

=item L<Photonic::LE::NR2::EpsTensor>

Calculate the dielectric tensor.

=item L<Photonic::LE::NR2::Field>

Calculate the microscopic field.

=item L<Photonic::LE::NR2::SH>

Calculate the SH polarization.

=item L<Photonic::LE::NR2::SHChiTensor>

Calculate the second harmonic quadratic susceptibility.

=item L<Photonic::LE::NR2::SHP>

Prepares data for the calculation of the nonretarded second harmonic
polarization.

=back

=item L<Photonic::LE::S>

Group of modules for non retarded calculations based on the
longitudinal dielectric function for metamaterials made of an
arbitrary number of phases, using the spinor representation.

=over 4

=item L<Photonic::LE::S::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::LE::S::EpsL>

Calculate the longitudinal dielectric response.

=item L<Photonic::LE::S::EpsTensor>

Calculate the dielectric tensor.

=item L<Photonic::LE::S::Field>

Calculate the microscopic field.

=back

=back

=item L<Photonic::Roles>

Group of roles to factor out related behavior.

=over 4

=item L<Photonic::Roles::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::Roles::EpsL>

Calculate the longitudinal dielectric response.

=item L<Photonic::Roles::EpsParams>

Some fields that have been factored our from the calculations of the response.

=item L<Photonic::Roles::Field>

Role consumed by all Field objects.

=item L<Photonic::Roles::Geometry>

Role consumed by all Geometry objects.

=item L<Photonic::Roles::KeepStates>

Flag to keepstates.

=item L<Photonic::Roles::Metric>

Role factored out of the metric calculators.

=item L<Photonic::Roles::Reorthogonalize>

Role to keep Haydock states orthogonalized.

=item L<Photonic::Roles::UseMask>

Role to manage masks in reciprocal space.

=back

=item L<Photonic::Types>

Defines types that are useful in constraining values for Photonic
calculations.

=item L<Photonic::Utils>

Useful assortment of utility functions.

=item L<Photonic::WE>

Group of modules for Photonic calculations starting from the wave
equation.

=over 4

=item L<Photonic::WE::R2>

Group of modules for binary metamaterials characterized by a
characteristic function.

=over 4

=item L<Photonic::WE::R2::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::WE::R2::Field>

Calculate the microscopic field.

=item L<Photonic::WE::R2::Green>

Calculate the macroscopic Green tensor, macroscopic wave tensor,
or dielectric tensor.

=item L<Photonic::WE::R2::GreenP>

Calculate projected onto some direction the macroscopic Green tensor,
or macroscopic wave operator, or dielectric function.

=item L<Photonic::WE::R2::Metric>

Retarded metric tensor of binary metamaterial with a non-dissipative
host.

=back

=item L<Photonic::WE::S>

Group of modules for calculations within metamaterials with an
arbitrary number of phases characterized by a complex microscopic
dielectric function, using the spinor representation.

=over 4

=item L<Photonic::WE::S::Haydock>

Obtain one, or all, Haydock coefficients.

=item L<Photonic::WE::S::Field>

Calculate the microscopic field.

=item L<Photonic::WE::S::Green>

Calculate the macroscopic Green tensor, macroscopic wave tensor, or
dielectric tensor.

=item L<Photonic::WE::S::GreenP>

Calculate projected onto some direction the macroscopic Green tensor,
macroscopic wave operator, or dielectric function.

=item L<Photonic::WE::S::Metric>

Retarded metric tensor of binary metamaterial with a non-dissipative
host.

=back

=back

=back

=back

=cut

=head1 AUTHORS

=over 4

=item * W. Luis Mochán, Instituto de Ciencias Físicas, UNAM, México
C<mochan@fis.unam.mx>

=item * Guillermo Ortiz, Departamento de Física - FCENA, Universidad
Nacional del Nordeste, Argentina C<gortiz@exa.unne.edu.ar>

=item * Bernardo S. Mendoza, Department of Photonics, Centro de
Investigaciones en Óptica, México C<bms@cio.mx>

=item * Lucila Juárez-Reyes, Centro de Investigaciones en Óptica ,
México, C<lucilajr@icf.unam.mx>

=item * José Samuel Pérez-Huerta, Unidad Académica de Física,
Universidad Autónoma de Zacatecas, México  C<jsperez@fisica.uaz.edu.mx>

=item * Merlyn Jaqueline Juárez-Gutiérrez, Instituto de Ciencias
Físicas, Universidad Nacional Autónoma de México and Centro de
Investigación en Ciencias, Universidad Autónoma del Estado de
Morelos, México C<merlynj@icf.unam.mx>

=back

=head1 ACKNOWLEDGMENTS

This work was partially supported by DGAPA-UNAM under grants IN108413,
IN113016, and IN111119.

=head1 LICENSE

This software is copyright (c) 2016 by W. Luis Mochán.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

=head2 *--- The GNU General Public License, Version 1, February 1989 ---*

This software is Copyright (c) 2016 by W. Luis Mochan.

This is free software, licensed under:

  The GNU General Public License, Version 1, February 1989

                    GNU GENERAL PUBLIC LICENSE
                     Version 1, February 1989

 Copyright (C) 1989 Free Software Foundation, Inc.
 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The license agreements of most software companies try to keep users
at the mercy of those companies.  By contrast, our General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  The
General Public License applies to the Free Software Foundation's
software and to any other program whose authors commit to using it.
You can use it for your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Specifically, the General Public License is designed to make
sure that you have the freedom to give away or sell copies of free
software, that you receive source code or can get it if you want it,
that you can change the software or use pieces of it in new free
programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of a such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must tell them their rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License Agreement applies to any program or other work which
contains a notice placed by the copyright holder saying it may be
distributed under the terms of this General Public License.  The
"Program", below, refers to any such program or work, and a "work based
on the Program" means either the Program or any work containing the
Program or a portion of it, either verbatim or with modifications.  Each
licensee is addressed as "you".

  1. You may copy and distribute verbatim copies of the Program's source
code as you receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice and
disclaimer of warranty; keep intact all the notices that refer to this
General Public License and to the absence of any warranty; and give any
other recipients of the Program a copy of this General Public License
along with the Program.  You may charge a fee for the physical act of
transferring a copy.

  2. You may modify your copy or copies of the Program or any portion of
it, and copy and distribute such modifications under the terms of Paragraph
1 above, provided that you also do the following:

    a) cause the modified files to carry prominent notices stating that
    you changed the files and the date of any change; and

    b) cause the whole of any work that you distribute or publish, that
    in whole or in part contains the Program or any part thereof, either
    with or without modifications, to be licensed at no charge to all
    third parties under the terms of this General Public License (except
    that you may choose to grant warranty protection to some or all
    third parties, at your option).

    c) If the modified program normally reads commands interactively when
    run, you must cause it, when started running for such interactive use
    in the simplest and most usual way, to print or display an
    announcement including an appropriate copyright notice and a notice
    that there is no warranty (or else, saying that you provide a
    warranty) and that users may redistribute the program under these
    conditions, and telling the user how to view a copy of this General
    Public License.

    d) You may charge a fee for the physical act of transferring a
    copy, and you may at your option offer warranty protection in
    exchange for a fee.

Mere aggregation of another independent work with the Program (or its
derivative) on a volume of a storage or distribution medium does not bring
the other work under the scope of these terms.

  3. You may copy and distribute the Program (or a portion or derivative of
it, under Paragraph 2) in object code or executable form under the terms of
Paragraphs 1 and 2 above provided that you also do one of the following:

    a) accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of
    Paragraphs 1 and 2 above; or,

    b) accompany it with a written offer, valid for at least three
    years, to give any third party free (except for a nominal charge
    for the cost of distribution) a complete machine-readable copy of the
    corresponding source code, to be distributed under the terms of
    Paragraphs 1 and 2 above; or,

    c) accompany it with the information you received as to where the
    corresponding source code may be obtained.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form alone.)

Source code for a work means the preferred form of the work for making
modifications to it.  For an executable file, complete source code means
all the source code for all modules it contains; but, as a special
exception, it need not include source code for modules which are standard
libraries that accompany the operating system on which the executable
file runs, or for standard header files or definitions files that
accompany that operating system.

  4. You may not copy, modify, sublicense, distribute or transfer the
Program except as expressly provided under this General Public License.
Any attempt otherwise to copy, modify, sublicense, distribute or transfer
the Program is void, and will automatically terminate your rights to use
the Program under this License.  However, parties who have received
copies, or rights to use copies, from you under this General Public
License will not have their licenses terminated so long as such parties
remain in full compliance.

  5. By copying, distributing or modifying the Program (or any work based
on the Program) you indicate your acceptance of this license to do so,
and all its terms and conditions.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the original
licensor to copy, distribute or modify the Program subject to these
terms and conditions.  You may not impose any further restrictions on the
recipients' exercise of the rights granted herein.

  7. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of the license which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
the license, you may choose any version ever published by the Free Software
Foundation.

  8. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  9. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  10. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.


=head2 *--- The Artistic License 1.0 ---*

This software is Copyright (c) 2016 by W. Luis Mochan.

This is free software, licensed under:

  The Artistic License 1.0

The Artistic License

Preamble

The intent of this document is to state the conditions under which a Package
may be copied, such that the Copyright Holder maintains some semblance of
artistic control over the development of the package, while giving the users of
the package the right to use and distribute the Package in a more-or-less
customary fashion, plus the right to make reasonable modifications.

Definitions:

  - "Package" refers to the collection of files distributed by the Copyright
    Holder, and derivatives of that collection of files created through
    textual modification.
  - "Standard Version" refers to such a Package if it has not been modified,
    or has been modified in accordance with the wishes of the Copyright
    Holder.
  - "Copyright Holder" is whoever is named in the copyright or copyrights for
    the package.
  - "You" is you, if you're thinking about copying or distributing this Package.
  - "Reasonable copying fee" is whatever you can justify on the basis of media
    cost, duplication charges, time of people involved, and so on. (You will
    not be required to justify it to the Copyright Holder, but only to the
    computing community at large as a market that must bear the fee.)
  - "Freely Available" means that no fee is charged for the item itself, though
    there may be fees involved in handling the item. It also means that
    recipients of the item may redistribute it under the same conditions they
    received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications derived
from the Public Domain or from the Copyright Holder. A Package modified in such
a way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided that
you insert a prominent notice in each changed file stating how and when you
changed that file, and provided that you do at least ONE of the following:

  a) place your modifications in the Public Domain or otherwise make them
     Freely Available, such as by posting said modifications to Usenet or an
     equivalent medium, or placing the modifications on a major archive site
     such as ftp.uu.net, or by allowing the Copyright Holder to include your
     modifications in the Standard Version of the Package.

  b) use the modified Package only within your corporation or organization.

  c) rename any non-standard executables so the names do not conflict with
     standard executables, which must also be provided, and provide a separate
     manual page for each non-standard executable that clearly documents how it
     differs from the Standard Version.

  d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or executable
form, provided that you do at least ONE of the following:

  a) distribute a Standard Version of the executables and library files,
     together with instructions (in the manual page or equivalent) on where to
     get the Standard Version.

  b) accompany the distribution with the machine-readable source of the Package
     with your modifications.

  c) accompany any non-standard executables with their corresponding Standard
     Version executables, giving the non-standard executables non-standard
     names, and clearly documenting the differences in manual pages (or
     equivalent), together with instructions on where to get the Standard
     Version.

  d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this
Package.  You may charge any fee you choose for support of this Package. You
may not charge a fee for this Package itself. However, you may distribute this
Package in aggregate with other (possibly commercial) programs as part of a
larger (possibly commercial) software distribution provided that you do not
advertise this Package as a product of your own.

6. The scripts and library files supplied as input to or produced as output
from the programs of this Package do not automatically fall under the copyright
of this Package, but belong to whomever generated them, and may be sold
commercially, and may be aggregated with this Package.

7. C or perl subroutines supplied by you and linked into this Package shall not
be considered part of this Package.

8. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

9. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

The End

=cut

1;
