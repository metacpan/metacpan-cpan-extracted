# ##############################################################################
# # Script     : Modern::PBP::Moose::Role                                      #
# # -------------------------------------------------------------------------- #
# # Copyright  : Free under 'GNU General Public License' or 'Artistic License' #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.200 #
# # Version    : 1.200                                             14.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Implements the role for the change of name of the getter and  #
# #              setter methods.                                               #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                        UNIX-lineendings #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : none                                                          #
# # -------------------------------------------------------------------------- #
# # Module     : Moose                                  ActivePerl-CORE-Module #
# #              Moose::Exporter                                               #
# #              Moose::Util::MetaRole                                         #
# #              ------------------------------------------------------------- #
# #              Modern::PBP::Perl                      ActivePerl-REPO-Module #
# ##############################################################################

package Modern::PBP::Moose::Role 1.200;

# ##############################################################################

use 5.012;

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use Modern::PBP::Moose::Role::Attribute;
use Modern::PBP::Perl;

# ##############################################################################

my %metaroles = (
   class_metaroles => { attribute         => ['Modern::PBP::Moose::Role::Attribute'], },
   role_metaroles  => { applied_attribute => ['Modern::PBP::Moose::Role::Attribute'], },
);

Moose::Exporter->setup_import_methods(%metaroles);

# ##############################################################################

no Moose;

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
1;
__END__
