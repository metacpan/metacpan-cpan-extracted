#
#extract name, type, len from a sybase database given a list of tables
#
# $Id: ObjectInfo.pm,v 1.6 2001/02/26 04:06:55 spragues Exp $
#
# (c) 1999, 2000 Morgan Stanley Dean Witter and Co.
# See ..../src/LICENSE for terms of distribution.
#
#
#pod documentation at the end
#
package Sybase::ObjectInfo;

   require 5.004;

#set-up package
   use strict;
   no strict 'refs';
   use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION/;
   use Exporter;
   use Carp;
   use Sybase::DBlib;
   $VERSION = 0.2;
   @ISA = qw/Exporter/;
   @EXPORT = qw/grab/;



#----------------------------------------------------------
#Load Sybase table information into our data structure  
#----------------------------------------------------------
   sub grab {    


      my $class = shift;
      
     
#get args - db handle, database, and pointer to array of tables
      my ($dbh, $db_name, $pt) = @_;
      my %info;

      croak "param #1 must be a blessed Sybase::DBlib reference" if ref($dbh) ne "Sybase::DBlib";


#if table is not a ref the it must be a single table
     $pt = [ $pt ] unless( ref $pt);
    
#check if db_name is specified, if not then it *must* be in the table
    
     my @odata = ();
     unless($db_name) {
        for my $t (@$pt) {
            my ($db, $own, $tab) = split(/\./,$t);
            push @odata, "$db\t$tab";
        }
     } else {
        for my $t (@$pt) { push @odata, "$db_name\t$t"; }
     }



#for each line in the table file
      foreach my $tb (@odata) {
         my ($db_name, $tab_name) = split(/\t/, $tb);
         $db_name  =~ s/\s+//g;
         $tab_name =~ s/\s+//g;
 
#create the sql
         my $sql_string=<<EOF;
         select
            col_name    = c.name, 
            type_name   = t.name, 
            col_len     = c.length,
            col_order   = c.colid,
            ctype       = c.type, 
            utype       = t.usertype,
            allownulls  = t.allownulls,
            prec        = c.prec
         from
            $db_name.dbo.syscolumns c, 
            $db_name.dbo.systypes t
         where
            c.id = object_id('$db_name..$tab_name')
            and c.usertype *= t.usertype
          
         order 
            by c.colid
EOF

  
#run the sql
         my @h_pointers =  $dbh->nsql($sql_string, "HASH") ;
         if($DB_ERROR) {carp "$DB_ERROR"}

#re-organize
         for my $col (@h_pointers) {
            my $col_name= $col->{col_name};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_type}       = $col->{type_name};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_len}        = $col->{col_len};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_id}         = $col->{col_order};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_allownulls} = $col->{allownulls};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_prec}       = $col->{prec};

#if user-defined type, get underlying
            if($col->{utype} > 100 ) {

#i pulled this sql from sp_help
               my $sql = <<EOF;
               select 
                   name 
               from 
                   $db_name..systypes
               where 
                   usertype < 100
                   and type=$col->{ctype} 
                   and name not in ("sysname", "nchar", "nvarchar")
EOF
               my @name = $dbh->nsql($sql,"HASH");
               if($DB_ERROR) {carp "$DB_ERROR" }

               $info{$db_name}->{$tab_name}->{$col_name}->{col_type}     = $name[0]->{name};
               $info{$db_name}->{$tab_name}->{$col_name}->{col_usertype} = $col->{type_name};

#not user-defined type
            } else {
               $info{$db_name}->{$tab_name}->{$col_name}->{col_usertype} = undef;

            }

#            $info{$db_name}->{$tab_name}->{$col_name}->{col_ctype} = $col->{ctype};
#            $info{$db_name}->{$tab_name}->{$col_name}->{col_utype} = $col->{utype};

         }

#add the list column names in the right order
         @{ $info{$db_name}->{$tab_name}->{__COLNAMES__} } =
         sort { $info{$db_name}->{$tab_name}->{$a}->{col_id} <=>
                $info{$db_name}->{$tab_name}->{$b}->{col_id} 
              } keys %{ $info{$db_name}->{$tab_name} };

      }


#      bless \%info;
      return %info;
   }
__END__

=head1 NAME

Sybase::ObjectInfo - Return Sybase Object information

=head1 SYNOPSIS

 %info = grab Sybase::ObjectInfo($dbh, $database, \@table_list) 

 where:
    $dbh is a Sybase::DBlib handle
    $database is the name of the database
    @table_list is an array containing the tables


 returns a hash for the form:
    $r = $info{$db_name}->{$table_name}->{$field_name}

    $r->{col_id}          # column order
      ->{col_type}        # column fundamental datatype
      ->{col_len}         # column datatype length
      ->{col_allownulls}  # does the column allow nulls
      ->{col_usertype}    # column usertype - if applicable
      ->{col_prec}        # column precision
      ->{col_order}       # an array of the columns names in order

   and per table:
     $info{$db_name}->{$table_name}->{__COLNAMES__} #an array of the column names in order
 

=head1 DEPENDENCIES

 perl version 5.004

 Sybase::DBlib

=head1 DESCRIPTION

Grabs column information from Sybase system tables for a given list 
of tables. Information includes column number, type, length, allow
null attribute, usertype, and precision.

 It performs the following SQL:
    select
       col_name    = c.name,
       type_name   = t.name,
       col_len     = c.length,
       col_order   = c.colid,
       ctype       = c.type,
       utype       = t.usertype,
       allownulls  = t.allownulls
    from
       $db_name..syscolumns c,
       $db_name..systypes t
    where
       c.id = object_id('$db_name..$tab_name')
       and c.usertype *= t.usertype
    order
       by c.colid


followed by this for each field where utype > 100  to get the 
underlying datatype for usertypes

    select
       name
    from
       $db_name..systypes
    where
       usertype < 100
       and type=$col->{ctype}
       and name not in ("sysname", "nchar", "nvarchar")


=head1 MISC

When supplying the parameters to grab, $database can  be  null.  If  so,
then tables must be of the form  "database.owner.table"  (owner  can  be
null)

If only  one  table  is  specified  then  table_list  can  be  a  scalar
containing the name of the table.

=head1 WISH LIST

I should convert this to use DBI/DBD at  some  point.  And  if  I'm  not
mistaken these kind of attributes are already  built  into  that  system
(thereby rendering this module close to obsolete if DBI is installed)

=head1 CONTACTS

stephen.sprague@msdw.com


=head1 VERSION

Version 0.21  24-FEB-2001
      Added return key '{__COLNAMES__}'

Version 0.20  10-FEB-2001
      Documentation/pod changes only

version 0.1, 01-OCT-2000
      Created
=cut

1;
