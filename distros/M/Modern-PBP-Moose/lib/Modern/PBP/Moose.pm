# ##############################################################################
# # Script     : Modern::PBP::Moose                                            #
# # -------------------------------------------------------------------------- #
# # Copyright  : Free under 'GNU General Public License' or 'Artistic License' #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.200 #
# # Version    : 1.200                                             14.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Loading essential Perl Moose modules in the namespace of the  #
# #              caller.                                                       #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                        UNIX-lineendings #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : namespace::autoclean                                          #
# # -------------------------------------------------------------------------- #
# # Module     : Moose                                  ActivePerl-CORE-Module #
# #              Moose::Exporter                                               #
# #              Moose::Util::TypeConstraints                                  #
# #              ------------------------------------------------------------- #
# #              Hook::AfterRuntime                     ActivePerl-REPO-Module #
# #              Modern::PBP::Perl                                             #
# #              MooseX::AttributeShortcuts                                    #
# #              MooseX::DeclareX                                              #
# #              MooseX::DeclareX::Keyword::interface                          #
# #              MooseX::DeclareX::Plugin::abstract                            #
# #              MooseX::DeclareX::Plugin::singleton                           #
# #              MooseX::DeclareX::Privacy                                     #
# #              MooseX::HasDefault::RO                                        #
# ##############################################################################

package Modern::PBP::Moose 1.200;

# ##############################################################################

use 5.012;

use namespace::autoclean;

use Hook::AfterRuntime;
use Moose;
use Moose::Exporter;
use Moose::Util::TypeConstraints;
use MooseX::AttributeShortcuts;
use MooseX::DeclareX;
use MooseX::HasDefaults::RO;
use Modern::PBP::Moose::Role;
use Modern::PBP::Perl;

# ##############################################################################

our ( $IMPORT, $PBP );

# ##############################################################################

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
   install => ['unimport'],
);
$IMPORT = $import;

Moose::Exporter->setup_import_methods( also => ['Moose'] );

# ##############################################################################
# # Function  | Replaces the 'import' method of 'Moose::Exporter'              #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | Object     | Class-Name                                        #
# #           | Str        | Parameters passed class                           #
# # ----------+------------+-------------------------------------------------- #
# # Result    | none                                                           #
# ##############################################################################

sub import {

   my ( $class, $parameter ) = @ARG;

   my $caller_class = scalar caller;

   $PBP = q{no_pbp};
   if ( defined $parameter ) {
      if ( $parameter =~ /(?:no_pbp|pbp)/smx ) {
         if ( $parameter eq q{pbp} ) {
            no strict qw{refs};
            no warnings;    ## no critic qw{ProhibitNoWarnings}
            ${ $caller_class . '::pbp' } = q{pbp};
            use warnings;
            use strict;
         }
         $PBP = splice @ARG, 1, 1;
      }
   }

   return $class->$IMPORT( { into => $caller_class } );

} ## end of sub import

# ##############################################################################
# # Function  | Loading essential Perl Moose modules in the namespace          #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | Object     | Class-Name                                        #
# #           | Hash       | Parameters passed class                           #
# # ----------+------------+-------------------------------------------------- #
# # Result    | none                                                           #
# ##############################################################################

sub init_meta {

   my $class  = shift;
   my %params = @ARG;

   my $for_class = $params{for_class};
   my $caller    = scalar caller;

   # --- All keywords for 'MooseX::DeclareX' -----------------------------------
   my @keywords = (
      qw{class clean extends role with}, 'is dirty', 'is mutable',
      qw{after around augment before method override},
      qw{try catch},
      qw{exception},
      qw{interface namespace},
   );

   # --- All plugins for 'MooseX::DeclareX' ------------------------------------
   my @plugins = (
      qw{private protected public std_constants},
      qw{build guard having imports postprocess preprocess test_case types},
      qw{abstract singleton},
   );

   # --- Parameter for 'MooseX::DeclareX' --------------------------------------
   my %declarex = (
      keyword => [@keywords],
      plugins => [@plugins],
      types   => [ -Moose ],
   );

   # --- Import of all packages for 'Moose'-classes ----------------------------
   Moose->init_meta(@ARG);
   Moose::Util::TypeConstraints->import( { into => $for_class } );
   MooseX::AttributeShortcuts->init_meta(@ARG);
   MooseX::HasDefaults::RO->import( { into => $for_class } );
   $_->setup_for( $for_class, %declarex, provided_by => $caller )
      for MooseX::DeclareX->_keywords( \%declarex );
   if ( $PBP eq q{pbp} ) {
      Modern::PBP::Moose::Role->import( { into => $for_class } );
   }

   # --- Cleanup of the namespace at the end of calling class ------------------
   namespace::autoclean->import( -cleanee => $for_class );
   after_runtime { $for_class->meta->make_immutable };

   return;

} ## end of sub init_meta

# ##############################################################################

no Moose;
no Moose::Util::TypeConstraints;

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
1;
__END__

=head1 NAME

Modern::PBP::Moose - Loading essential Perl Moose modules in the namespace of
the caller


=head1 VERSION

This document describes Perl::Modern::Moose version 1.200.


=head1 SYNOPSIS

   use Modern::PBP:Moose;
   or
   use Modern::PBP::Moose qw{no_pbp}; (equivalent to 'use Modern::PBP::Moose)
   or
   use Modern::PBP::Moose qw{pbp};


=head1 DESCRIPTION

The PERL Moose modules listed below are included in the namespace of the
including module:

   - namespace::autoclean;
   - Moose
   - Moose::Util::TypeConstraints
   - MooseX::AttributeShortcuts
   - MooseX::DeclareX
   - MooseX::HasDefaults::RO
   - namespace::autoclean

When you exit the namespace an auto-mix 'meta> make_immutable' add
'namespace::autoclean' is executed.

The parameter 'qw{pbp}' are separate getters and setters methods for the
attributes (get_... and set_... or _get_... and _set_...) generated. The
parameter 'qw{no_pbp}' (default), this behavior is suppressed.


=head1 INTERFACE

Contains no routines that are invoked explicitly.


=head2 init_meta

Called automatically when integrating.


=head1 DIAGNOSTICS

none


=head1 CONFIGURATION AND ENVIRONMENT

Perl::Modern::Moose requires no configuration files or environment variables.


=head1 DEPENDENCIES

The following pragmas and modules are required:

=head2 CORE

   - Moose
   - Moose::Exporter
   - Moose::Util::TypeConstrains


=head2 CPAN or ActiveState Repository

   - namespace::autoclean
   - Hook::AfterRuntime
   - MooseX::AttributeShortcuts
   - MooseX::DeclareX
   - MooseX::DeclareX::Keyword::interface
   - MooseX::DeclareX::Plugin::abstract
   - MooseX::DeclareX::Plugin::singleton
   - MooseX::DeclareX::Privacy
   - MooseX::HasDefaults::RO
   - PBP::Perl


=head1 INCOMPATIBILITIES

The module works with PERL 5.12 or higher.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-modern-moose@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Juergen von Brietzke  C<< <juergen.von.brietzke@t-online.de> >>


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
