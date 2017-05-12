# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }

use blib      '../Object'   ; # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;

# use        Devel::Peek;

use        Notes::Session;    # note: inherits from Notes::Object
use        Notes::Database;   # note: inherits from Notes::Object
use        Notes::Acl;

   # Test 1 - checks wether (dyna)loading the (XS) module works
print "ok 1\n";
$loaded = 1;
END { print "not ok 1\n" unless $loaded; }

######################### End of black magic.


{  my $s    = new Notes::Session;

   {  my $db   = $s-> database(     'perlcapi/test/acl/names.nsf'    );
      my $db_1 = $s-> get_database( 'perlcapi/test/acl/api461re.nsf' );



      {  my $a = $db->acl;
         print "\nAcl Inheritance Test:\n",
         $a->set_status( 1060 ); # status code for
                                  # "The name is not in the list"
         print "\nAcl Inheritance Test:\n",
               $a->status_text, "\n", $a->status, "\n";

         print "\n";
         print "ACL of ${\( $db  ->expanded_path )} contains:\n",
               join( "\n",
                     "\tentries:",
                     $db  ->get_acl->all_entrynames    ,""),
               join( "\n",
                     "\troles:",
                     $db  ->get_acl->all_roles     ,""),
               join( "\n",
                     "\tprivs:",
                     $db  ->get_acl->all_privs,"");

         print "\n";
         print "ACL of ${\( $db_1->path )} contains:\n",
               join( "\n",
                     "\tentries:",
                     $db_1->get_acl->all_entrynames    ,""),
               join( "\n",
                     "\troles:",
                     $db_1->get_acl->all_roles     ,""),
               join( "\n",
                     "\tprivs:",
                     $db_1->get_acl->all_privs,"");

         print "\n";
         print "ACL Entry Names for ", $db->expanded_path, "\n";
         {  my $a       = $db->get_acl;
            my @names   = $a->all_entrynames;

            print "no. of names:   ", scalar @names,   "\n";
            foreach my $n ( @names ) {
               print $n, "\n";
            }
         }  # end my $a
      }  # and my $a

      print "\n";
      print "ACL Entry Names for ", $db_1->expanded_path, "\n";
      {  my $a2      = $db_1->get_acl;
         my @names   = $a2->all_entrynames;

         print "no. of names:   ", scalar @names,   "\n";
         foreach my $n ( @names ) {
            print $n, "\n";
         }
      }  # end my $a2

      print "\n";
      {  my $a1      = $db->get_acl;
         print "Entry existence tests for ", $db->expanded_path, "\n";
         print "we         have entry <LocalDomainServers>\n"
            if     $a1->has_entryname( q(LocalDomainServers) );
         print "we _don't_ have entry <xx_strange>\n"
            unless $a1->has_entryname( q(xx_strange) );
         print "we         have entry <LNAdmin Brech/ERL/KWU>\n"
         if        $a1->has_entryname( q(LNAdmin Brech/ERL/KWU) );

      }  # end my $a1               


      print "\n";
      {  my $a2      = $db_1->get_acl;
         print "Entry existence tests for ", $db_1->expanded_path, "\n";
         print "we         have entry <-Default->\n"
            if     $a2->has_entryname( q(-Default-) );
         print "we _don't_ have entry <OtherDomainServers>\n"
            unless $a2->has_entryname( q(OtherDomainServers) );
       
      }  # end my $a2
   }  # end my $db, my $db_1
}  # end my $s
