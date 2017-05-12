# ##############################################################################
# # Script     : Modern::PBP::Perl                                             #
# # -------------------------------------------------------------------------- #
# # Copyright  : Free under 'GNU General Public License' or 'Artistic License' #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.240 #
# # Version    : 1.240                                             23.Mai.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Loading pragmas and Modules for 'Perl Best Practices'.        #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.24.xx #
# # Coding     : ISO 8859-15 / Latin-9                        UNIX-lineendings #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : feature, mro, strict, version, warnings                       #
# # -------------------------------------------------------------------------- #
# # Module     : Carp                                   ActivePerl-CORE-Module #
# #              English                                                       #
# #              Exporter                                                      #
# #              IO::File                                                      #
# #              IO::Handle                                                    #
# #              ------------------------------------------------------------- #
# #              Perl::Version                          ActivePerl-REPO-Module #
# ##############################################################################

package Modern::PBP::Perl 1.240;

# ##############################################################################

use 5.012;

use feature ();
use mro     ();
use strict;
use version;
use warnings;

use Carp;
use English qw{-no_match_vars};
use Exporter;
use IO::File;
use IO::Handle;
use Perl::Version;

# ##############################################################################
# # Feature/Warnings-Table : Contains all the features available to Perl 5.24  #
# # -------------------------------------------------------------------------- #
# # 5.xx  <->  Feature is included in the feature tag ( ':5.xx' )              #
# # ++++  <->  Feature can be switched on in Perl version                      #
# # ----  <->  Feature is not implemented in the Perl version                  #
# ##############################################################################

                                                                      ## no tidy
# ------ Perl-Version ---- 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.24 -------------
our %FEATURES = (
   array_base      => [qw( 5.10 5.12 5.14 ++++ ++++ ++++ ++++ ++++ )],
   bitwise         => [qw( ---- ---- ---- ---- ---- ---- ++++ ++++ )],
   current_sub     => [qw( ---- ---- ---- 5.16 5.18 5.20 5.22 5.24 )],
   evalbytes       => [qw( ---- ---- ---- 5.16 5.18 5.20 5.22 5.24 )],
   fc              => [qw( ---- ---- ---- 5.16 5.18 5.20 5.22 5.24 )],
   lexical_subs    => [qw( ---- ---- ---- ---- ++++ ++++ ++++ ++++ )],
   postderef       => [qw( ---- ---- ---- ---- ---- ++++ ++++ ++++ )],
   postderef_qq    => [qw( ---- ---- ---- ---- ---- ++++ ++++ 5.24 )],
   refaliasing     => [qw( ---- ---- ---- ---- ---- ---- ++++ ++++ )],
   say             => [qw( 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.24 )],
   signatures      => [qw( ---- ---- ---- ---- ---- ++++ ++++ ++++ )],
   state           => [qw( 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.24 )],
   switch          => [qw( 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.24 )],
   unicode_eval    => [qw( ---- ---- ---- 5.16 5.18 5.20 5.22 5.24 )],
   unicode_strings => [qw( ---- 5.12 5.14 5.16 5.18 5.20 5.22 5.24 )],
);

our %WARNINGS = (
   autoderef       => [qw( ---- ---- ---- ---- ---- 5.20 5.22 ---- )],
   bitwise         => [qw( ---- ---- ---- ---- ---- ---- 5.22 5.24 )],
   const_attr      => [qw( ---- ---- ---- ---- ---- ---- 5.22 5.24 )],
   lexical_subs    => [qw( ---- ---- ---- ---- 5.18 5.20 5.22 5.24 )],
   lexical_topic   => [qw( ---- ---- ---- ---- 5.18 5.20 5.22 ---- )],
   postderef       => [qw( ---- ---- ---- ---- ---- 5.20 5.22 5.24 )],
   re_strict       => [qw( ---- ---- ---- ---- ---- ---- 5.22 5.24 )],
   refaliasing     => [qw( ---- ---- ---- ---- ---- ---- 5.22 5.24 )],
   regex_sets      => [qw( ---- ---- ---- ---- 5.18 5.20 5.22 5.24 )],
   signatures      => [qw( ---- ---- ---- ---- ---- 5.20 5.22 5.24 )],
   smartmatch      => [qw( ---- ---- ---- ---- 5.18 5.20 5.22 5.24 )],
);                                                                   ## use tidy

# ##############################################################################
# # Function  | Imports all features of a given of the current version of Perl #
# #           | and the pragma 'strict' and 'warnings' and the modules English #
# #           | IO::File and IO::Handle.                                       #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | Str        | Perl version and/or to remove features (optional) #
# # ----------+------------+-------------------------------------------------- #
# # Result    | none                                                           #
# ##############################################################################

sub import {

                                         ## no critic qw{RequireUseOfExceptions}
   my ( $class, @extra_parameters ) = @ARG;

   my ( $actual_perl_version, $use_perl_version, $version_tag, $version_idx );

   # --- Remove control for Perl version of parameters - if any ----------------
   my @version = grep {/^\d[.]\d\d/smx} @extra_parameters;
   @extra_parameters = grep { not /^\d[.]\d\d/smx } @extra_parameters;

   # --- Remove Control for 'English' of parameters - if any -------------------
   my $english_parameter = grep {/^(?:[+]?)match_vars$/smx} @extra_parameters;
   @extra_parameters = grep { not /^(?:[+]?)match_vars$/smx } @extra_parameters;

   # --- Determine current version of Perl -------------------------------------
   if ( $PERL_VERSION =~ /^v5[.](\d\d).+$/smx ) {
      $actual_perl_version = "5.$1";
      $use_perl_version    = "5.0$1";
   }
   else {
      confess "Version '$PERL_VERSION' not detected\n";
   }

   # --- Check the version string and form feature tag -------------------------
   my $version = $version[0] // $actual_perl_version;
   if ( $version =~ /^5[.](1[02468]|2[024])$/ismx ) {
      $use_perl_version = "5.0$1";
      $version_idx      = $1 / 2 - 5;
      $version_tag      = ":$version";
   }
   else {
      confess "Version ($version) not supports\n";
   }

   # --- Test - current version of Perl greater than or equal Feature version --
   my $perl_version    = Perl::Version->new($actual_perl_version);
   my $feature_version = Perl::Version->new($version);
   if ( $perl_version < $feature_version ) {
      confess "Features '$version' in '$actual_perl_version' not available\n";
   }

   # --- Activate Perl version and import features -----------------------------
   my $use = "use qw{$use_perl_version}";
   eval {$use} or confess "Can't execute '$use'\n";
   warnings->import;
   strict->import;
   version->import;
   feature->import($version_tag);
   mro::set_mro( scalar caller(), 'c3' );

   # --- Import additional features --------------------------------------------
   foreach my $feature ( keys %FEATURES ) {
      if ( $FEATURES{$feature}->[$version_idx] eq '++++' ) {
         feature->import($feature);
      }
   }

   # --- Off alerts for imported features --------------------------------------
   foreach my $warning ( keys %WARNINGS ) {
      if ( $WARNINGS{$warning}->[$version_idx] ne '----' ) {
         warnings->unimport("experimental::$warning");
      }
   }

   # --- Remove Individual Features / Turn certain warnings --------------------
   my $flag;
   foreach my $delete (@extra_parameters) {
      $flag = 0;
      $delete =~ s/^(?:[-+]?)(.+)/$1/smx;
      if ( exists $FEATURES{$delete} ) {
         $flag = 1;
         if ( $FEATURES{$delete}->[$version_idx] ne '----' ) {
            feature->unimport($delete);
         }
         else {
            confess "Feature '$delete' in version '$version' not available\n";
         }
      }
      if ( exists $WARNINGS{$delete} ) {
         $flag = 1;
         if ( $WARNINGS{$delete}->[$version_idx] ne '----' ) {
            warnings->import("experimental::$delete");
         }
      }
      if ( not $flag ) {
         confess "Unknown feature/warning for delete '$delete'\n";
      }
   }

   # --- Import 'English' variables --------------------------------------------
   local $Exporter::ExportLevel = 1;        ## no critic qw(ProhibitPackageVars)
   if ($english_parameter) {                                          ## no tidy
      *English::EXPORT = \@English::COMPLETE_EXPORT;
      my $match_vars = q{*English::MATCH     = *&;}
                     . q{*English::PREMATCH  = *`;}
                     . q{*English::POSTMATCH = *';}
                     . q{1;};                                        ## use tidy
      eval {$match_vars} or confess("Can't create English match variablen\n");
   }
   else {
      *English::EXPORT = \@English::MINIMAL_EXPORT;
   }
   Exporter::import('English');

   return;

} ## end of sub import
                                        ## use critic qw{RequireUseOfExceptions}

# ##############################################################################
# # Function  | Removes all experimental features a version of Perl.           #
# # ----------+--------------------------------------------------------------- #
# # Parameter | none                                                           #
# # ----------+--------------------------------------------------------------- #
# # Result    | none                                                           #
# ##############################################################################

sub unimport {                          ## no critic qw(ProhibitBuiltinHomonyms)

   warnings->unimport;
   strict->unimport;
   feature->unimport;

   return;

} ## end of sub unimport

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
1;
__END__

=head1 NAME

Modern::PBP::Perl - Loading pragmas and Modules for 'Perl Best Practices'


=head1 VERSION

This document describes Modern::PBP::Perl version 1.240.


=head1 SYNOPSIS

   use Modern::PBP::Perl;
   or
   use Modern::PBP::Perl qw{5.20};
   or
   use Modern::PBP::Perl qw{-switch lexical_subs}
   or
   use Modern::PBP::Perl qw{5.22 -switch +match_vars}
   or
   use Modern::PBP::Perl qw{-switch 5.14 +match_vars}


=head1 DESCRIPTION

Loading all the features of the current Perl version installed, or the specified
version of Perl. The corresponding warnings are deactivated. If a version of
Perl is specified, this must be less than or equal to that is installed.

Should one or more features not be activated or a warning will remain active,
this may be given on the version (the minus or plus sign is optional).

In addition, the pragma 'strict' and 'version' will be imported as well as the
alternatives for the special variables (use English) transferred in the calling
package. By default, the variables 'MATCH', 'PREMATCH' and 'POST MATCH' not
accepted. However, these can be aktivieret by specifying '+match_vars'.

The modules

   IO :: File
   IO :: Handle

are precisely the case with imports.


=head1 INTERFACE

Contains no routines that are invoked explicitly.


=head2 import

Called automatically when integrating.


=head2 unimport

Called automatically when you leave the name space.


=head1 DIAGNOSTICS

=head2 Version '5.xx' not detected

The version of the installed PERL could not be determined.

=head2 Version (5.xx) not supports

The transferred PERL version is not supported.

=head2 Features '5.xx' in '5.xx' not available

he requested PERL version is higher than the installed.

=head2 Can't execute 'use qw{5.xx}'

The requested PERL version can not be activated.

=head2 Feature 'xxxxx' in version '5.xx' not available.

he feature to be removed is not included in the selected version of Perl.

=head2 Unknown feature/warning for delete 'xxxxx'

The feature to be removed is unknown.

=head2 Can't create English match variablen

The import of the match variables failed


=head1 CONFIGURATION AND ENVIRONMENT

PBP::Perl requires no configuration files or environment variables.


=head1 DEPENDENCIES

The following pragmas and modules are required:

=head2 CORE

   - feature
   - mro
   - strict
   - version
   - warnings

   - Carp
   - English
   - Exporter
   - IO::File
   - IO::Handle


=head2 CPAN or ActiveState Repository

   - Perl::Version


=head1 INCOMPATIBILITIES

The module works with Perl version 5.12, 5.14, 5.16, 5.18, 5.20, 5.22 and 5.24.
Developers Perl versions are not supported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-modern-moose@rt.cpan.org>, or through the web interface at
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
