# ##############################################################################
# # Script     : MooseX::Types::Tkx                                            #
# # -------------------------------------------------------------------------- #
# # Copyright  : Free under 'GNU General Public License' or 'Artistic License' #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.010 #
# # Version    : 1.010                                             18.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : MooseX::Types for Tkx-GUI-Objects.                            #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                        UNIX-lineendings #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : none                                                          #
# # -------------------------------------------------------------------------- #
# # Module     : Scalar::Util                           ActivePerl-CORE-Module #
# #              ------------------------------------------------------------- #
# #              Modern::PBP::Perl                      ActivePerl-REPO-Module #
# #              MooseX::Types                                                 #
# #              MooseX::Types::Moose                                          #
# ##############################################################################

package MooseX::Types::Tkx 1.010;

# ##############################################################################

use Modern::PBP::Perl;
use Scalar::Util qw{blessed};
use MooseX::Types -declare => [qw{TkxObject}];
use MooseX::Types::Moose qw{Object};

# ##############################################################################
# # Data types        |                                                        #
# # ------------------+------------------------------------------------------- #
# # TkxObject         | A Tkx GUI object (e.g .: widget, frame, etc.)          #
# ##############################################################################

                                                                      ## no tidy
subtype TkxObject,
   as Object,
   where { ( my $package = blessed($ARG) ) =~ m{^Tkx(?:[:]{2}[\w]+)*$}smx },
   message {"'$ARG' is not a Tkx-GUI-object"};
                                                                     ## use tidy

# ##############################################################################
# #                                    E N D                                   #
# ##############################################################################
1;
__END__

=head1 NAME

MooseX::Types::Tkx - MooseX::Types for Tkx-GUI-Objects.


=head1 VERSION

This document describes MooseX::Types::Tkx version 1.010.


=head1 SYNOPSIS

   use Moose;
   use MooseX::Types::Tkx qw{TkxObject};
   use Tkx;
   ...
   has 'mainwindow' => (
      is  => 'rw',
      isa => TkxObject,
   );
   has 'button' => (
      is  => 'ro',
      isa => TkxObject,
   );
   ...


=head1 DESCRIPTION

Created a data type for Tkx objects. For example, Main Window, buttons, frames
etc.


=head1 INTERFACE

Contains no routines that are invoked explicitly.



=head1 DIAGNOSTICS

none


=head1 CONFIGURATION AND ENVIRONMENT

MooseX::Types::Tkx requires no configuration files or environment variables.


=head1 DEPENDENCIES

The following pragmas and modules are required:

=head2 CORE

   - Scalar::Utils


=head2 CPAN or ActiveState Repository

   - Modern::PBP::Perl
   - MooseX::Types
   - MooseX::Types::Moose


=head1 INCOMPATIBILITIES

none


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-moosex-types-tkx@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Juergen von Brietzke - JVBSOFT  C<< <juergen.von.brietzke@t-online.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, 2016
Juergen von Brietzke C<< <juergen.von.brietzke@t-online.de> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/artistic.html>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
