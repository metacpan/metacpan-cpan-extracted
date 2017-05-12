=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * '*.lib'

=back

=cut

use strict ;
use warnings ;
use Data::Dumper ;

use PBS::Output ;

#-------------------------------------------------------------------------------

PbsUse('Rules/C') ; 

PbsUse('Configs/gcc') ;

#-------------------------------------------------------------------------------

#~ LockConfigMerge() ;

#~ AddConfig (Nadim => 'me') ;

AddRule 'lib', ['*/*.lib' => '*.lib_dep'], \&BuildLib ;

AddRule 'lib_dep', ['*/*.lib_dep' => '*.c'] ;

#cyclic test
#~ AddRule 'lib_dep_test', ['*/*.lib_dep' => '*.lib'] ;

AddRule 'ch', ['*/*.c' => '*.h'] ;
AddRule 'subsub_pbsfile', {NODE_REGEX =>'*/x.h', PBSFILE => 'P3.pl', PACKAGE => 'LIB3', BUILD_DIRECTORY => '/bd_P3', SOURCE_DIRECTORIES => ['/sd_P3']} ;

AddRule 'c2', ['*/*.c' => '*.z'] ;

#~PBS::Config::RemoveConfig('a', 'b', 'c') ;
#~PBS::Config::RemoveConfig('PBS::LIBS', 'BuiltIn') ;

#~sub Build
#~{
#~}

sub BuildLib
{
PrintInfo("BuildLib called\n") ;
return(1, "BuildLib OK") ;
}


