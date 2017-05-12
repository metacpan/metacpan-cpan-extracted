# ##############################################################################
# # Script     : Modern::PBP::Moose::Role::Attribute                           #
# # -------------------------------------------------------------------------- #
# # Copyright  : Free under 'GNU General Public License' or 'Artistic License' #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.200 #
# # Version    : 1.200                                             14.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Defines the attributes of getter and setter methods.          #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                        UNIX-lineendings #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : none                                                          #
# # -------------------------------------------------------------------------- #
# # Module     : Moose::Role                            ActivePerl-CORE-Module #
# #              ------------------------------------------------------------- #
# #              Modern::PBP::Perl                      ActivePerl-REPO-Module #
# ##############################################################################

package Modern::PBP::Moose::Role::Attribute 1.200;

# ##############################################################################

use 5.012;

use Modern::PBP::Perl;
use Moose::Role;

# ##############################################################################
# # Function  | replaces getter / setter Method by 'get _... / set _...'.      #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | Object     | Class-Name                                        #
# #           | Str        | Name der getter/setter                            #
# #           | Any        | Options                                           #
# # ----------+------------+-------------------------------------------------- #
# # Result    | none                                                           #
# ##############################################################################

before _process_options => sub {

   my ( $class, $name, $options ) = @ARG;

   # --- identify caller -------------------------------------------------------
   my $caller = scalar caller 12;

   no strict qw{refs};
   if ( defined ${ $caller . '::pbp' } ) {
      use strict;

      # --- PBP callers required -----------------------------------------------
      if ( exists $options->{is} and $options->{is} ne q{bare} ) {

         # --- 'is' parameter set and not equal to'bare' -----------------------
         if ( not( exists $options->{reader} or exists $options->{writer} ) ) {

            # --- No specified getter/setter method ----------------------------
            my ( $get, $set );
            if ( $name =~ /^[_]/ismx ) {
               ( $get, $set ) = ( q{_get}, q{_set} );
            }
            else {
               ( $get, $set ) = ( q{get_}, q{set_} );
            }
            $options->{reader} = $get . $name;
            if ( $options->{is} eq 'rw' ) {
               $options->{writer} = $set . $name;
            }
            delete $options->{is};
         }
      }
   }

};

# ##############################################################################

no Moose::Role;

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
1;
__END__
