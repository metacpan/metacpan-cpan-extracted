use Test;
use strict;
BEGIN { plan tests => 7 };
use Sys::Utmp qw(:fields);
ok(1); 

# test 

{
   my $utmp = Sys::Utmp->new(Filename => '/var/run/utmp');

   ok(2);

   eval 
   {
      while( my $utent = $utmp->getutent() )
      {
         my $t = $utent->ut_line();
         $t    = $utent->user_process();
       }
       ok(3);
   };
   if ( $@ )
   {
     print $@;
     ok(0);
   }
 
   eval
   {
     $utmp->setutent();
     ok(4);
   };
   if ($@)
   {
     ok(0);
   }

}


{
   my $utmp = Sys::Utmp->new(Filename => '/var/run/utmp');

   ok(5);

   eval 
   {
      while( my @utent = $utmp->getutent() )
      {
         my $t = $utent[UT_USER];
         $t    = $utent[UT_ID];
       }
       ok(6);
   };
   if ( $@ )
   {
     print $@;
     ok(0);
   }
 
   eval
   {
     $utmp->setutent();
     ok(7);
   };
   if ($@)
   {
     ok(0);
   }

}
