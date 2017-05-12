# $Id: Xfer.pm,v 1.19 2000/11/18 13:56:12 spragues Exp $
#
# (c) 1999, 2000 Morgan Stanley Dean Witter and Co.
# See ..../src/LICENSE for terms of distribution.
#
#Transfer data between two Sybase servers in memory
#
#See pod documentation at the end of this file
#
#
#
#public:
#   sub new
#   sub xfer
#   sub done 
#
#private:
#   sub sx_grab_from_sybase {
#   sub sx_grab_from_perl {
#   sub sx_cleanup {
#
#sendrow stuff
#   sub sx_sendrow_bcp {
#   sub sx_sendrow_failure {
#   sub sx_sendrow_batch {
#   sub sx_sendrow_return {
#   sub sx_sendrow_temp {
#
#auto delete stuff
#   sub sx_remove_target_rows {
#   sub sx_auto_delete_setup {
#
#option stuff
#   sub sx_checkargs {
#   sub sx_prep_xfer {
#   sub sx_verify_options { 
#
#util stuff
#   sub sx_complain {
#   sub sx_usage {
#   sub sx_message_handler {
#   sub sx_error_handler {
#   sub sx_print {
#   sub sx_oversize_error {
#   sub sx_open_bcp {
#   sub sx_debug {
#   sub sx_delete_sql {
#
#

package Sybase::Xfer;
 
   require 5.005;

#set-up package
   use strict;
   use Exporter;
   use Carp;
   use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION/;
   $VERSION = 0.1;
   @ISA = qw/Exporter/;

 
#RCS/CVS Version
   my($RCSVERSION) = do {
     my @r = (q$Revision: 1.19 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r
   };

 
   
#modules
   use File::Basename;
   use Sybase::DBlib;
   use Sybase::ObjectInfo;
   use Getopt::Long;
   use Tie::IxHash;


#globals
  use vars qw/$DB_ERROR %opt/;



#-----------------------------------------------------------------------
#constructor
#-----------------------------------------------------------------------
   sub new {

     my $self  = shift;
     my $class = ref($self) || $self;

#basic option checking
     my %opt = sx_checkargs(@_); 

     $self = { %opt };
     bless $self;


#install new err/msg handlers. will restore when done.
     my $cb = sub { return sx_message_handler($self, @_) };
     $self->{current_msg_handler} = dbmsghandle($cb);   

     $cb = sub { return sx_error_handler($self, @_) };
     $self->{current_err_handler} = dberrhandle($cb);

#another option
     $Sybase::DBlib::nsql_strip_whitespace++ if $self->{trim_whitespace};

#set the stage. delete/truncate; define source. 
     sx_prep_xfer($self); 

#squirrel away a few counts
     $self->{sx_send_count} = 0;
     $self->{sx_succeed_count} = 0;
     $self->{sx_err_count} = 0;
     $self->{sx_resend_count} = 0;
     $self->{sx_send_count_batch} = 0;
     $self->{sx_succeed_count_batch} = 0;
     $self->{sx_err_count_batch} = 0;
     $self->{sx_resend_count_batch} = 0;
      

#send it back
     return $self;
   }
     

#-----------------------------------------------------------------------
#destroy the object
#-----------------------------------------------------------------------
   sub done {
      my $self = shift;
      my $class = ref($self) || $self;

#return current handlers
      dbmsghandle( $self->{current_msg_handler} );
      dberrhandle( $self->{current_err_handler} );

      my $num_success = $self->{sx_succeed_count};
      my $num_err =   $self->{sx_err_count};
      my $num_resend = $self->{sx_resend_count};
      my $num_fails = $num_err - $num_resend;

      $self = undef;

      return wantarray ? ($num_success, $num_err, $num_resend, $num_fails) : $num_success;
   }



#-----------------------------------------------------------------------
#xfer the data
#-----------------------------------------------------------------------
   sub xfer {

     my $self = shift;
     my $class = ref($self) || $self;

     my %opt = %$self;

#no buffering on stdout
     $|++;

#pick the source
     if(ref($self->{sx_sql_source}) eq "CODE") {
        sx_grab_from_perl($self);
     } else {
        sx_grab_from_sybase($self);
     }

#summarize, restore env & exit
     return sx_cleanup($self);
   }




#-----------------------------------------------------------------------
#cleanup & exit
#-----------------------------------------------------------------------
  sub sx_cleanup {

     my $opt = shift;

     my ($abort_error) = ();

#if number of rows sent is zero and it's an error condition, then problem with sql
     if($DB_ERROR) {

#error can come up down the line. particularly convert errors.
#        if($opt->{sx_send_count} == 0) { sx_print($opt, $DB_ERROR) }      

        sx_print($opt, $DB_ERROR);
        sx_print($opt, "$opt->{sx_send_count} rows read before abort\n");
        $abort_error++;
     }


#close connections
     $opt->{sx_dbh_from}->dbclose() if $opt->{sx_dbh_from};
     $opt->{sx_dbh_to_bcp}->dbclose() if $opt->{sx_dbh_to_bcp};
     $opt->{sx_dbh_to_non_bcp}->dbclose() if $opt->{sx_dbh_to_non_bcp};

#return current handlers
     dbmsghandle( $opt->{current_msg_handler} );
     dberrhandle( $opt->{current_err_handler} );

#notification
     my $num_fails = $opt->{sx_err_count} - $opt->{sx_resend_count};
     unless( $opt->{silent} ) {
     
       sx_print($opt, "Xfer summary:\n");
       sx_print($opt, "   $opt->{sx_succeed_count} total rows transferred\n");
       sx_print($opt, "   $opt->{sx_err_count} total rows had errors\n") if $opt->{sx_err_count} > 0;
       sx_print($opt, "   $opt->{sx_resend_count} total successful retries\n") if $opt->{sx_resend_count} > 0;
       sx_print($opt, "   $num_fails total unsuccessful retries\n") if $num_fails > 0;
     }

#return.
     ($abort_error || $num_fails) ? return 1 : return 0;
   
  }

#-----------------------------------------------------------------------
#print opts
#-----------------------------------------------------------------------
  sub sx_debug {

#db handles
#   $opt{sx_dbh_from}
#   $opt{sx_dbh_to_bcp}
#   $opt{sx_dbh_to_bcp_temp}
#   $opt{sx_dbh_to_non_bcp}
#   
#   $opt{sx_sql_source}
#
#auto delete stuff
#   $opt{sx_ad_temp_table}
#   $opt{sx_ad_create_table}
#   $opt{sx_ad_delete_cmd}
#   $opt{sx_ad_delete_join}
#   $opt{sx_ad_temp_tab_count}
#   $opt{sx_ad_col_num}
#   $opt{sx_ad_rows_deleted}
#   $opt{scratch_db}
#   $opt{auto_delete}
#   $opt{auto_delete_batchsize}
#
#   $opt{current_msg_handler}
#   $opt{current_err_handler}
#   
#   $opt{sx_to_database}
#   $opt{sx_to_table}
#
#sendrow stuff
#   $opt{sx_send_count}
#   $opt{sx_send_count_batch}
#
#   $opt{sx_succeed_count}
#   $opt{sx_succeed_count_batch}
#
#   $opt{sx_err_count}
#   $opt{sx_err_count_batch}
#
#   $opt{sx_resend_count}
#   $opt{sx_resend_count_batch}


  }



#-----------------------------------------------------------------------
#auto delete
#-----------------------------------------------------------------------
  sub sx_remove_target_rows {

    my $opt = shift;

    return unless($opt->{auto_delete});

#create temp table
    $opt->{sx_dbh_to_non_bcp}->nsql($opt->{sx_ad_create_table},{});
    $DB_ERROR && sx_complain("unable to create temp table\n$DB_ERROR\n");

#create a bcp connection to it
    my $nc = scalar @{ $opt->{sx_ad_col_num} };
    $opt->{sx_dbh_to_bcp_temp} = sx_open_bcp($opt->{sx_ad_temp_table}, $opt, $nc);

#bcp rows to temp table
    sx_print($opt, "bcping keys to $opt->{to_server} : $opt->{sx_ad_temp_table}\n") if $opt->{echo};
    my $cb = sub { return sx_sendrow_temp(\@_, $opt) };

#do it. callback counts rows
    $opt->{sx_dbh_from}->nsql($opt->{sx_sql_source}, [], $cb);

#final batch
    $opt->{sx_dbh_to_bcp_temp}->bcp_done();
    $DB_ERROR && sx_complain("error in bcp'ing to temp table\n$DB_ERROR\n");

#log message
    sx_print($opt, "   $opt->{sx_ad_temp_tab_count} keys transferred\n") if $opt->{echo};

#run the delete
    sx_print($opt, "auto_deleting rows on $opt->{to_server} : $opt->{to_table}\n") if $opt->{echo};
    sx_print($opt, "   $opt->{sx_ad_delete_join}\n") if $opt->{echo};
    my @res = $opt->{sx_dbh_to_non_bcp}->nsql($opt->{sx_ad_delete_cmd}, {});
    $DB_ERROR && sx_complain("error in deleting rows\n$DB_ERROR\n");
    $opt->{sx_ad_rows_deleted} = $res[0]->{tot_rows};
    my $loop = $res[0]->{loop};
    sx_print($opt, "   $opt->{sx_ad_rows_deleted} rows deleted\n") if($opt->{echo} && $loop>1);

#destroy the temp table
    @res = $opt->{sx_dbh_to_non_bcp}->nsql("drop table $opt->{sx_ad_temp_table}", []);
    $DB_ERROR && sx_complain("error in dropping temp table\n$DB_ERROR\n");

    return ;

  }


#-----------------------------------------------------------------------
#grab data from sybase to push to 'to' server
#-----------------------------------------------------------------------
  sub sx_grab_from_sybase {

    my $opt = shift;

#remove the rows from target table
    sx_remove_target_rows($opt) if $opt->{auto_delete};

#get bcp connection
    my $nc = scalar keys %{ $opt->{sx_to_info}->{ $opt->{sx_to_database} }->{ $opt->{sx_to_table} } };
    $opt->{sx_dbh_to_bcp} = sx_open_bcp($opt->{to_table}, $opt, $nc);

#define cb for use with nsql
    my $cb = sub { return sx_sendrow_bcp(\@_, $opt) }; 

#run nsql on 'from' server
    sx_print($opt, "transferring rows to $opt->{to_server} : $opt->{to_table}\n") if($opt->{echo});
    my $sql = $opt->{sx_sql_source};

#$sql will be an arrayref when there are multiple batches in the from_sql/from_script
    if( ref($sql) eq "ARRAY" ) {
       for my $each_sql ( @{ $sql } ) {
          $opt->{sx_dbh_from}->nsql($each_sql, [], $cb);
          $DB_ERROR && return;
       }
    } else {
       $opt->{sx_dbh_from}->nsql($sql, [], $cb);
       $DB_ERROR && return;
    }

#commit last set of rows
    my $final_batch = sx_sendrow_batch($opt);

    return; 
  }


#-----------------------------------------------------------------------
#grab data from perl source
#-----------------------------------------------------------------------
  sub sx_grab_from_perl {

     my $opt = shift;

#remove the rows from target table, if called for.
     sx_remove_target_rows($opt) if $opt->{auto_delete};

#bcp init
     my $nc = scalar keys %{ $opt->{sx_to_info}->{ $opt->{sx_to_database} }->{ $opt->{sx_to_table} } };
     $opt->{sx_dbh_to_bcp} = sx_open_bcp($opt->{to_table}, $opt, $nc);

#transfer the data by calling perl code ref
     my ($status_getrow, $r_data) =  $opt->{sx_sql_source}->(); 
     while( $status_getrow ) {
        my $status = sx_sendrow_bcp($r_data, $opt);
        last unless( $status );
        ($status_getrow, $r_data) = $opt->{sx_sql_source}->(); 
     }

#commit last set of rows
    my $final_batch = sx_sendrow_batch($opt);

     return;
  }




#-----------------------------------------------------------------------
#auto_delete callback
#-----------------------------------------------------------------------
    sub sx_sendrow_temp {

#args
      my $r_row = $_[0];
      my $opt = $_[1];
      

#pull out the key columns only
      my @bcp_row = @{$r_row} [ @{ $opt->{sx_ad_col_num} } ];

#row count
      $opt->{sx_ad_temp_tab_count}++;

#send the row
      my $status_send = $opt->{sx_dbh_to_bcp_temp}->bcp_sendrow(@bcp_row); 
      $DB_ERROR && sx_complain("$DB_ERROR\n");

#commit the row
      if($opt->{sx_ad_temp_tab_count} % $opt->{batchsize} == 0) {
         sx_print($opt, '   '.$opt->{sx_ad_temp_tab_count} . " keys transferred\n") if $opt->{echo};
         $opt->{sx_dbh_to_bcp_temp}->bcp_batch();
         $DB_ERROR && sx_complain("$DB_ERROR\n");
      }

      return 1;
    }




#-----------------------------------------------------------------------
#the actual callback - bcp version
#-----------------------------------------------------------------------
   sub sx_sendrow_bcp {

#args
     my ($r_row, $opt) = @_;

     my $dbh = $opt->{sx_dbh_to_bcp};
     my ($status_cb_pre, $status_cb_err_send, $status_cb_err_batch) = ();
     my ($status_send, $status_batch) = ();

#the actual data
     my @row = @$r_row; 
		 

#---
#user-defined callback pre send
#---
     $status_cb_pre = 1;
     if( ref( $opt->{callback_pre_send} ) eq 'CODE') {
       my $r_user_row = ();
       ($status_cb_pre, $r_user_row) = $opt->{callback_pre_send}->($r_row) ;
       if($status_cb_pre) {
          @row = @$r_user_row;
       } else {
          sx_complain("User-defined '-callback_pre_send' failed ($opt->{callback_pre_send}).\n");
       }
     }
             
#debug
     if($opt->{debug}) { 
        my $i=0; for my $y (@row) { $i++; sx_print($opt,"$i:\t<$y>\n"); } 
     }


#---
#send row - will snag client errors
#---
#status_send will == 0 on errors as well as DB_ERROR being set.
     $DB_ERROR = ();
     $opt->{sx_send_count}++; 
     $opt->{sx_send_count_batch}++;
     $status_send = 1;
     if ($dbh->bcp_sendrow(\@row) == FAIL )  {
        $status_send = 0; 
     }

#check for failure on send
     if( !$status_send ) {
        $opt->{sx_err_count}++; 
        $opt->{sx_err_count_batch}++;
        $status_send = sx_sendrow_failure($opt, \@row);
     } else {
        $opt->{sx_succeed_count}++; 
        $opt->{sx_succeed_count_batch}++;
     } 


#commit
      $status_batch = 1;
      if($opt->{sx_succeed_count} % $opt->{batchsize} == 0) {
         $status_batch = sx_sendrow_batch($opt);
         $opt->{sx_send_count_batch} = 0; 
         $opt->{sx_resend_count_batch} = 0;
         $opt->{sx_succeed_count_batch} = 0; 
         $opt->{sx_err_count_batch} = 0;
      }

#set return code
     return sx_sendrow_return($opt, $status_send, $status_batch, $status_cb_pre);

   }
   


#-----------------------------------------------------------------------
#sendrow failure processing
#-----------------------------------------------------------------------
   sub sx_sendrow_failure {

     my $opt = shift;
     my $r_row = shift;

     my $status_send = ();

#a) err send is a cb
     if( ref( $opt->{callback_err_send} ) eq 'CODE' && $opt->{error_handling} !~ /^abort$/i) { 
         my ($status_cb_err_send, $u_row) = 
               $opt->{callback_err_send}->(DB_ERROR => $DB_ERROR, 
                                           row_num  => $opt->{sx_send_count},
                                           row_ptr  => $r_row);

#if user indicated retry status- then send the (fixed-up) row again!
         if($status_cb_err_send) { 
            $opt->{sx_resend_count}++; $opt->{sx_resend_count_batch}++;
            my $rs = sx_sendrow_bcp($u_row, $opt);
            $DB_ERROR = ();   #clean-up error
            $status_send = 1; #force success
         } else {
            $status_send = 0;
         }

#b) err send is a HASH
     } elsif( ref( $opt->{callback_err_send} ) eq 'HASH' && $opt->{error_handling} !~ /^abort$/i) { 
         ${ $opt->{callback_err_send} }{ $opt->{sx_send_count} }->{msg} = $DB_ERROR;
         ${ $opt->{callback_err_send} }{ $opt->{sx_send_count} }->{row} = $r_row;                 
         $DB_ERROR = ();
         $status_send = 1;

#c) no err cb - print offending row
     } else {
         $opt->{override_silent}++;
         sx_print($opt, "$DB_ERROR\n");
         my $n = $opt->{sx_send_count};
         sx_print($opt, "row #$n\n");
           
#print out the row smartly
         sx_oversize_error($opt, @$r_row); 
         $status_send = 0;
     }

     return $status_send;

  }



#-----------------------------------------------------------------------
#commit the rows
#-----------------------------------------------------------------------
  sub sx_sendrow_batch {

      my $opt = shift;
      my $dbh = $opt->{sx_dbh_to_bcp};

      my $status_batch = 1;

#returns number of rows when it works, -1 on failure, or zero
      $status_batch = $dbh->bcp_batch;
      $status_batch = 0 if($status_batch < 0);

         
#---
#FAILURE on batch
#---
      if( !$status_batch ) {
             
#a) call back exists
          if( ref($opt->{callback_err_batch}) eq 'CODE'  && $opt->{error_handling} !~ /^abort$/i) {
             my ($status_cb_err_batch) = $opt->{callback_err_batch}->(DB_ERROR => $DB_ERROR, 
                                                                      row_num  => $opt->{sx_send_count});
#change status_batch to success if err cb says so.
             if($status_cb_err_batch) { 
                $status_batch = 1; 
                $DB_ERROR = ();
             }
#b) no callback
          } else {
             $DB_ERROR && sx_print($opt, "$DB_ERROR\n");
          }
#---
#SUCCESS on batch
#---
      } else {
          if($opt->{progress_log}) {
             my $suc = $opt->{sx_succeed_count};
             my $res = $opt->{sx_resend_count};
             my $fal = $opt->{sx_err_count} - $res;
             my $bsuc= $opt->{sx_succeed_count_batch};
             my $bres= $opt->{sx_resend_count_batch};
             my $bfal= $opt->{sx_err_count_batch} - $bres;

#if errors encountered then give a different log message. otherwise keep it simple
             $opt->{override_silent}=1;
             if($res) {
               sx_print($opt, "$status_batch rows committed [$suc] (retries=$bres, fails=$bfal)\n");
             } else {
               sx_print($opt, "$status_batch rows committed [$suc]\n");
             }
             $opt->{override_silent}=0;
          }
      }


      return $status_batch;
   }


#-----------------------------------------------------------------------
#set the return code from bcp_sendow
#-----------------------------------------------------------------------
  sub sx_sendrow_return {

     my $opt = shift;
     my ($status_send, $status_batch, $status_cb_pre) = @_;

     my $error = !($status_send && $status_batch && $status_cb_pre);
     if($error) {

#abort
        if($opt->{error_handling} =~ /^abort$/i) { 
           sx_print($opt, "Aborting on error.\n");
           sx_print($opt, "   error_handling = $opt->{error_handling}\n");
           sx_print($opt, "   callback_err_send  = $opt->{callback_err_send}\n") if defined $opt->{callback_err_send};
           sx_print($opt, "   callback_err_batch = $opt->{callback_err_batch}\n") if defined $opt->{callback_err_batch};
           return 0;

#plow thru errrors if so set
        } else {
           $DB_ERROR = ();
           return 1;

        }

#clean return
     } else {
        return 1;

     }
  }



#-----------------------------------------------------------------------
#where to put messages
#-----------------------------------------------------------------------
   sub sx_print {

     my ($opt, $line) = @_;

#we don't want to suppress print statements from SQL
     my ($pack2) = caller(2);

#some conditions must be overrieded like errors
     my $force = $opt->{override_silent} ;

     if($pack2 eq "Sybase::DBlib" || !$opt->{silent} || $force) {
        ref($opt->{callback_print}) eq 'CODE' ?  $opt->{callback_print}->($line) : print "$line";
     }
   }


#-----------------------------------------------------------------------
#prep for xfer
#-----------------------------------------------------------------------
   sub sx_prep_xfer {

#args
      my $opt = shift;


#FROM connection
     my $dbh_from = ();
     unless( $opt->{from_perl} ) {
        $dbh_from = new Sybase::DBlib($opt->{from_user}, $opt->{from_password}, 
                    $opt->{from_server}, $opt->{app_name}.'_F');
        $DB_ERROR && sx_complain("FROM login error:\n$DB_ERROR\n");

#use the right database
        my $rs = $dbh_from->nsql("use $opt->{from_database}",'ARRAY') if($opt->{from_database});
        $DB_ERROR && sx_complain("$DB_ERROR\n");
     }
#squirrel it away
     $opt->{sx_dbh_from} = $dbh_from;

#select from 'from' source
     my $sql_source = ();
     if( $opt->{from_sql} ) {
        $sql_source = $opt->{from_sql};
#allow mulitiple batches. This is particularly useful (and even necessary if using cursors)
        my $re = qr/^\s*GO\s*\n/mi;
        my @s = split($re,$sql_source);
        $sql_source = \@s if (@s > 1);


     } elsif($opt->{from_script}) {
        open(FH1,"<$opt->{from_script}") or sx_complain("unable to open script: <$opt->{from_script}>\n");
        my @lines = <FH1>;
        close(FH1);
        $sql_source = join "", @lines;

     } elsif($opt->{from_table}) {
        my $wc = "where $opt->{where_clause}" if $opt->{where_clause};
        $sql_source = "select * from $opt->{from_table} $opt->{holdlock} $wc";

     } elsif( ref( $opt->{from_perl} ) eq "CODE" ) {
        $sql_source = $opt->{from_perl};

     }
#squirrel it away
     $opt->{sx_sql_source} = $sql_source;


#log into 'to' server (NON-BCP)
     my %to_info = ();
     my $dbh_to_non_bcp = new Sybase::DBlib($opt->{to_user}, $opt->{to_password}, 
                          $opt->{to_server}, $opt->{app_name}.'_X');
     $DB_ERROR && sx_complain("TO login error:\n$DB_ERROR\n");

    
#check that -to_table exists
     my @path = split(/\./, $opt->{to_table});
     my $chk = "select count(*) from $path[0]..sysobjects where name = '$path[2]'";
     my $chkn = ($dbh_to_non_bcp->nsql($chk, []) )[0];
     ($DB_ERROR || !$chkn) && sx_complain("Can't find to_table <$opt->{to_table}>\n$DB_ERROR\n");
     

#get to_table object info
     %to_info = grab Sybase::ObjectInfo($dbh_to_non_bcp, undef, $opt->{to_table} );
     $opt->{sx_to_info} = \%to_info;
     ($opt->{sx_to_database}) = keys %to_info;
     ($opt->{sx_to_table}) = keys %{ $to_info{ $opt->{sx_to_database} } };

#use right db
     my $rs = $dbh_to_non_bcp->nsql("use $opt->{sx_to_database}",'ARRAY') if $opt->{sx_to_database};
     $DB_ERROR && sx_complain("$DB_ERROR\n");

#squirrel away
     $opt->{sx_dbh_to_non_bcp} = $dbh_to_non_bcp;
 
#check if delete flag specified
     if($opt->{delete_flag} && $opt->{where_clause} ) {
        my $del_line = "delete $opt->{to_table} where $opt->{where_clause}";
        my $sql_string = sx_delete_sql($del_line, $opt->{batchsize});
        sx_print($opt, "delete table $opt->{to_server} : $opt->{to_table}\n") if($opt->{echo});
        sx_print($opt, "   $del_line (in a loop)\n") if($opt->{echo});
        my @status = $dbh_to_non_bcp->nsql($sql_string,[]);
        $DB_ERROR && sx_complain("$DB_ERROR\n");
     }
   
#check if truncate flag specified
     if($opt->{truncate_flag}) {
        my $sql_string = "truncate table $opt->{to_table}";
        sx_print($opt, "truncating table $opt->{to_server} : $opt->{to_table}\n") if($opt->{echo});
        my @status = $dbh_to_non_bcp->nsql($sql_string,[]);
        $DB_ERROR && sx_complain("$DB_ERROR\n");
     }


#create auto_delete commands
     sx_auto_delete_setup($opt) if $opt->{auto_delete};


#debug. calc num rows to be xferred
     if($opt->{debug} && $opt->{from_table}) {
        sx_print($opt, "calculating number for rows to transfer.\n");
        my $wc = "where $opt->{where_clause}" if $opt->{where_clause};
        my $sql_string = "select count(*) from $opt->{from_table} $wc"; 
        sx_print($opt, "$sql_string\n") if $opt->{echo} ;
        my @status = $dbh_from->nsql($sql_string, []);
        $DB_ERROR && sx_complain("$DB_ERROR\n");
        sx_print($opt, "num rows: $status[0]\n");
     }

     return; 
  }



#-----------------------------------------------------------------------
#make bcp connection
#-----------------------------------------------------------------------
  sub sx_open_bcp {
     
     my ($tab, $opt, $num_cols) = @_;

     my $dbh = ();
     &BCP_SETL(TRUE);

     $dbh = new Sybase::DBlib($opt->{to_user}, $opt->{to_password}, $opt->{to_server}, 
            $opt->{app_name}.'_T');
     $DB_ERROR && sx_complain("$DB_ERROR\n"); 

     $dbh->bcp_init($tab, '', '', &DB_IN);
     $DB_ERROR && sx_complain("$DB_ERROR\n"); 

     $dbh->bcp_meminit($num_cols); 
     $DB_ERROR && sx_complain("$DB_ERROR\n");

     return $dbh;

   }




#-----------------------------------------------------------------------
#create the auto_delete string
#-----------------------------------------------------------------------
   sub sx_auto_delete_setup {

#args
      my $opt = shift;
      return unless $opt->{auto_delete};
     
#pull the necessary info off the options hash
      my %to_info = %{ $opt->{sx_to_info} };
      my($db) = keys %to_info;
      my($table) = keys %{ $to_info{$db} };


      my $temp_db = $opt->{scratch_db};
      my $del_batchsize = $opt->{auto_delete_batchsize};
      my $tmp_tab = $opt->{sx_ad_temp_table} = "$temp_db..sybxfer$$";

      my $del_one_line = "delete $db..$table where";
      my $del_join = "delete $db..$table from $db..$table a, $tmp_tab b where";
#create sql prefix
      my $crt_sql = "create table $tmp_tab(";

#get the columns specified by the user
      my @cols = split( /[\ ,]+/, $opt->{auto_delete} );

      my $columns = ();

#loop thru the columns
      for my $c (@cols) {
         my ($val, $ctype) = ();

#if $c is all digits then its a column position
         my $cname = ();
         if($c =~ /^\d+$/) {
           ($cname) = grep {$to_info{$db}->{$table}->{$_}->{col_id} == $c} keys %{$to_info{$db}->{$table}};
           unless (defined $cname) { sx_complain("couldn't find column #$c in $table\n"); }
         } else {
           $cname = $c;
         }

#get datatype
         my $type = $to_info{$db}->{$table}->{$cname}->{col_type}   || sx_complain("unknown column: <$cname>\n");
         my $col_num = $to_info{$db}->{$table}->{$cname}->{col_id}  || sx_complain("unknown column: <$cname>\n");
         my $col_len = $to_info{$db}->{$table}->{$cname}->{col_len} || sx_complain("unknown column: <$cname>\n");

#list of columns
         $columns .= "$cname,";

#perl is zero indexed
         $col_num--;
         push @{ $opt->{sx_ad_col_num} }, $col_num;

#add delimeters
         if($type =~ /date|time/i) {  
            $val = qq/$cname = '\${row[$col_num]}'/;
            $ctype = $type;
         } elsif($type =~ /char/i) {
            $val = qq/$cname = '\${row[$col_num]}'/; 
            $ctype = "$type($col_len)";
         } elsif($type =~ /binary/i) { 
            $val = qq/$cname = 0x\${row[$col_num]}/;
            $ctype = "$type($col_len)";
         } else { 
            $val = qq/$cname = \${row[$col_num]}/;
            $ctype = $type;
         }
      

#make cmds
         $crt_sql .= " $cname $ctype null,";
         $del_join .= " a.$cname = b.$cname and";
         $del_one_line .= " $val and";
      }


#remove trailing syntax
      $columns = substr($columns,0,-1);
      $crt_sql = substr($crt_sql,0,-1) . ")\n";
      $crt_sql .= "create index ix_$$ on $tmp_tab ( $columns )\nupdate statistics $tmp_tab\n";
      $del_join = substr($del_join,0,-4);
      $del_one_line = substr($del_one_line,0,-4);

#create the sql to delete the rows
      my $del_sql = sx_delete_sql($del_join, $opt->{batchsize});

      $opt->{sx_ad_create_table} = $crt_sql;
      $opt->{sx_ad_delete_cmd} = $del_sql;
      $opt->{sx_ad_delete_join} = $del_join;   
      return;
   }



#-----------------------------------------------------------------------
#sql to delete rows
#-----------------------------------------------------------------------
   sub sx_delete_sql {

      my ($del_line, $batchsize) = @_;

      return <<EOF;
      set rowcount $batchsize 
      declare \@loop int, \@tot_rows int, \@n int
      select \@loop=0, \@tot_rows=0, \@n=0
      while (\@loop = 0 or \@n > 0)
      begin
         select \@loop=\@loop+1
         $del_line
         select \@n=\@\@rowcount
         select \@tot_rows=\@tot_rows+\@n
         if ( \@n > 0) print "   \%1! deleted", \@n
      end
      select loop=\@loop-1, tot_rows=\@tot_rows
      set rowcount 0
EOF
   }



#-----------------------------------------------------------------------
#oversize row info trace
#-----------------------------------------------------------------------
   sub sx_oversize_error {

       my $opt     = shift;
       my @row     = @_;

#ObjectInfo structure
       my %to_info = %{ $opt->{sx_to_info} };

       my ($db, $tab) = ($opt->{sx_to_database}, $opt->{sx_to_table} );

#sort the fields by column order
       my @sorted_fields = sort { $to_info{$db}->{$tab}->{$a}->{col_id} <=> 
                                  $to_info{$db}->{$tab}->{$b}->{col_id} } 
                                  keys %{$to_info{$db}->{$tab}
                                };
       my @sorted_len = map { $to_info{$db}->{$tab}->{$_}->{col_len}  } @sorted_fields;
       my @sorted_type= map { $to_info{$db}->{$tab}->{$_}->{col_type} } @sorted_fields;
       my @sorted_prec= map { $to_info{$db}->{$tab}->{$_}->{col_prec} } @sorted_fields;


#loop thru all the fields
       for (my $i=0; $i<@row; $i++) { 
           my $val      = $row[$i];
           my $fld_name = $sorted_fields[$i];
           my $act_len  = length $row[$i];
           my $dec_type = $sorted_type[$i];
           my $dec_len  = ($dec_type =~ /numeric/ ? $sorted_prec[$i] : $sorted_len[$i]);

           my $msg = ();
           if($dec_type =~ /char/i && $act_len > $dec_len ) { 
              $msg = "Column #" . ($i+1) . " actual length [$act_len] > declared length [$dec_len]\n"; 
              sx_print($opt, "$msg");
           }
           sx_print($opt, sprintf("   %2i: %-20s\t%-10s\t<%s>\n", $i+1, $fld_name, $dec_type . '('.$dec_len.')', $val) );
       }
       return 0; 
    }

   
#-----------------------------------------------------------------------
#check arguments
#-----------------------------------------------------------------------
   sub sx_checkargs {
      
      my @user_options = @_;

#verify the options
      my %opt = sx_verify_options(@user_options);

#if help, then give usage and bail
      sx_usage(), exit 1 if defined $opt{help};
      

#if "U" specified, then make from and to equal to "user"
      if($opt{user}) {
         $opt{from_user}     = $opt{user}     unless $opt{from_user};
         $opt{from_password} = $opt{password} unless $opt{from_password};
         $opt{to_user}       = $opt{user}     unless $opt{to_user};
         $opt{to_password}   = $opt{password} unless $opt{to_password};
      }
      
      
#if "S" specified, then make from and to server equal to "server"
      if($opt{server}) {
         $opt{from_server} = $opt{server} unless $opt{from_server};
         $opt{to_server}   = $opt{server} unless $opt{to_server};
      }
      
#if "T" specified, then set from and to tables 
      $opt{from_table} = $opt{table} if $opt{table};
      $opt{to_table}   = $opt{table} if $opt{table};


#if "D" specified, then set from database only
      $opt{from_database} = $opt{database}  if $opt{database};


#if batchsize not specified then force it to 1000
      $opt{batchsize} = 1000 unless $opt{batchsize};

#make sure -to_table is of the from db.[owner].table
      if($opt{to_table}) {
         my @tt = split(/\./, $opt{to_table});
         if( @tt != 3) {
            sx_complain("-to_table MUST be of the form db.[owner].table\n");
         }
      } else {
        sx_complain("-to_table MUST be specified\n");
      }

#error handling
      if(defined $opt{error_handling} && ! $opt{error_handling} =~ m/^(continue|abort)$/i) {
         sx_complain("if -error_handling is specified it must be either 'continue' or 'abort'\n");
      }
      $opt{error_handling} = 'abort' unless defined $opt{error_handling};
    

#check for omissions
      sx_complain("Must specify <from server>\n") unless($opt{from_server} || $opt{from_perl} );
      sx_complain("Must specify <to server>\n") unless $opt{to_server};
      sx_complain("Must specify <to table>, use db..table syntax for safety.\n") unless $opt{to_table};
      unless ($opt{from_table} || $opt{from_script} || $opt{from_sql} || $opt{from_perl} ) {
        sx_complain("Must specify <-from table>, <-from_script>, <-from_sql>, or <-from_perl>\n");
      }

#default scratch db
      $opt{scratch_db} = 'tempdb' unless $opt{scratch_db};
      $opt{auto_delete_batchsize} = 3000 unless defined $opt{auto_delete_batchsize};

#check delete options
      my $c = (defined $opt{auto_delete}) + (defined $opt{delete_flag}) + (defined $opt{truncate_flag});
      if($c > 1) {
        sx_complain("-auto_delete, -delete_flag and -truncate_flag are mutually exclusive\n");
      }

      return %opt;

   }



#-----------------------------------------------------------------------
#confirm options and load massaged options
#-----------------------------------------------------------------------
     sub sx_verify_options { 

      my @user_settings = @_;

#need to preserve order for options processing
      my %user_settings = ();
      tie %user_settings, "Tie::IxHash";
#      for (my $i=0; $i<@user_settings; $i+=2) {
#          my ($k,$v) = ($user_settings[$i], $user_settings[$i+1]);
#          $user_settings{"$k"} = $v;
#      }

      my $i=0;
      while($i<@user_settings) {
          my ($k,$v) = ($user_settings[$i], $user_settings[$i+1]);

#this means flag style option if the next option starts with a '-'
          if($v =~ /^\-\w/ || $i == $#user_settings && $k =~ /^\-\w/) { 
             $v = 1;
             $i++;
          } else {
             $i += 2;
          }
          $user_settings{"$k"} = $v;

      }           
    
#the list of options
      my @valid_options = 
                     qw/help|h:s
                        from_server|fs=s
                        from_user|fu=s
                        from_password|fp=s
                        from_database|fd=s

                        from_table|ft=s
                        from_script=s
                        from_sql=s
                        from_perl=s

                        to_server|ts=s
                        to_user|tu=s
                        to_password|tp=s
                        to_table|tt=s
                        to_database|td=s

                        user|U=s
                        password|P=s
                        server|S=s
                        table|T=s
                        database|D=s

                        delete_flag|df:s
                        truncate_flag|tf:s
                        where_clause|wc=s
                        batchsize|bs=i
                        error_handling|eh=s
                        holdlock|hl!
                        trim_whitespace|tw!
                       
                        scratch_db=s
                        auto_delete=s
                        auto_delete_batchsize|adb=i
           
                        debug=s
                        echo:s
                        silent:s
                        progress_log:s
                        app_name|an=s
                        
                        callback_pre_send=s
                        callback_err_send=s
                        callback_err_batch=s
                        callback_print=s
                     /;


#sub to pull code ref's
      my $sub = sub {
                my $key = shift; my $cb = ();
                if(exists $user_settings{$key}) {
                  if(ref($user_settings{$key}) eq 'CODE') {
                     $cb = $user_settings{$key};
                     delete $user_settings{$key};
                  } else { sx_complain("$key must be a CODE reference\n") if $user_settings{$key}; } #can be undef
                }
                return $cb;
      };


#code references aren't handled all that great by GetOptions. so. pull these out and put 'em back in 
#why do I say this? GetOptions was actually calling the code ref.
      my $cb_pl = $sub->('-from_perl');
      my $cb_ps = $sub->('-callback_pre_send');
      my $cb_es = $sub->('-callback_err_send');
      my $cb_eb = $sub->('-callback_err_batch');
      my $cb_pr = $sub->('-callback_print');


#save ARGV
      my @SAVE_ARGV = @ARGV;

      use vars qw/%real_options/;
      $SIG{__WARN__} = sub { sx_complain("$_[0]") };


#load up ARGV for GetOptions
      %real_options = ();
      @ARGV = %user_settings;
      Getopt::Long::Configure(qw/no_ignore_case/);
      my $rs = GetOptions(\%real_options, @valid_options);

#restore ARGV
      @ARGV = @SAVE_ARGV;

#put the code ref's back in
      $real_options{from_perl} = $cb_pl if $cb_pl;
      $real_options{callback_pre_send} = $cb_ps if $cb_ps;
      $real_options{callback_err_send} = $cb_es if $cb_es;
      $real_options{callback_err_batch} = $cb_eb if $cb_eb;
      $real_options{callback_print} = $cb_pr if $cb_pr;

#set some defaults
      $real_options{app_name} = basename($0) unless defined $real_options{app_name};

#program_name in master..sysprocesses only 16 bytes long. need last two for sybxfer.
      $real_options{app_name} = substr($real_options{app_name},0,14);

      $real_options{progress_log} = 1 unless defined $real_options{progress_log};
      $real_options{holdlock} = 'HOLDLOCK' if $real_options{holdlock};
      $real_options{trim_whitespace} = 0 unless defined $real_options{trim_whitespace};

      return %real_options;
   }


#-----------------------------------------------------------------------
#complain
#-----------------------------------------------------------------------
   sub sx_complain {
#      print STDERR "$_[0]"; #can't use die
      carp "$_[0]";
      exit 2;
   }


#-----------------------------------------------------------------------
#usage statement
#-----------------------------------------------------------------------
   sub sx_usage {

     print "Type 'perldoc Sybase::Xfer' for usage.\n";
     return 0
   }


#-----------------------------------------------------------------------
#this is copied from nsql_error_handler. I might change it later.
#-----------------------------------------------------------------------
    sub sx_error_handler {
       my ($self, $db, $severity, $error, $os_error, $error_msg, $os_error_msg) = @_;

#check the error code to see if we should report this.
       if ( $error != SYBESMSG ) {
         $DB_ERROR = "Sybase error: $error_msg\n";
         $DB_ERROR .= "OS Error: $os_error_msg\n" if defined $os_error_msg;
       }

       INT_CANCEL;
   }


#-----------------------------------------------------------------------
#prints sql 'print' code via sx_print
#-----------------------------------------------------------------------
   sub sx_message_handler {
      my ($opt, $db, $message, $state, $severity, $text, $server, $procedure, $line) = @_;
 
      if ( $severity > 0 ) {
         $DB_ERROR = "Message: $message\n";
         $DB_ERROR .= "Severity: $severity\n";
         $DB_ERROR .= "State: $state\n";
         $DB_ERROR .= "Server: $server\n"        if defined $server;
         $DB_ERROR .= "Procedure: $procedure\n"  if defined $procedure;
         $DB_ERROR .= "Line: $line\n"            if defined $line;
         $DB_ERROR .= "Text: $text\n";
 
         return unless ref $db;
 
         my $lineno = 1;
         foreach my $row ( split(/\n/,$db->dbstrcpy) ) {
             $DB_ERROR .= sprintf ("%5d", $lineno ++) . "> $row\n";
         }

#force nosilent on errors.
         $opt->{override_silent}++;
 
 
#grab messages of severity = 0 (print messages)
    } else {
 
      unless($message =~ m/^(5701|5703)$/) {
          sx_print($opt, "$text\n");
      }
 
    }
 
    return 0;
  }

__END__

=head1 NAME

 Sybase::Xfer - transfer data between Sybase servers via bcp.

=head1 SYNOPSIS

 #!/usr/bin/perl5.005
 #the perl version
    use Sybase::Xfer;
    $h = new Sybase::Xfer( %switches );
    $h->xfer();
    $h->done();

 #!/bin/ksh
 #the bin version
    sybxfer <switches>
 


=head1 DEPENDENCIES

 requires at least perl version 5.005

 Sybase::DBlib 
 Sybase::ObjectInfo (this comes packaged with Sybase::Xfer)
 Getopt::Long 
 Tie::IxHash

=head1 DESCRIPTION

If you're in an environment with multiple servers and you don't want to use 
cross-server joins then this module may be worth a gander. It transfers data from
one server to another server row-by-row in memory w/o using an intermediate file.

To juice things up it can take data from any set of sql commands as long as the 
output of the sql matches the definition of the target table. And it can take data
from a perl subroutine if you're into that. 

It also has some smarts to delete rows in the target table before the data is 
transferred by several methods. See the -truncate_flag, -delete_flag and -auto_delete
switches.

Everything is controlled by switch settings sent as a hash to the module.  In essence
 one describes the I<from source> and the I<to source> and the module takes it from there.

Error handling:

An attempt was made to build in hooks for robust error reporting via perl callbacks. By
default, it will print to stderr the data, the column names, and their datatypes upon error. 
This is especially useful when sybase reports I<attempt to load an oversized row> warning 
message.

Auto delete:

More recently the code has been tweaked to handle the condition 
where data is bcp'ed into a table but the row already exists and 
the desired result to replace the row. Originally, the
-delete_flag option was meant for this condition. ie. clean out 
the table via the -where_clause before the bcp in was to occur. If 
this is action is too drastic, however, by using the -auto_delete
option one can be more precise and force only those rows about to 
be inserted to be deleted before the bcp in begins. It will bcp the 
'key' information to a temp table, run a delete (in a loop so as not 
to blow any log space) via a join between the temp table and target
table and then begin the bcp in. It's weird but in the right situation
it may be exactly what you want.  Typically used to manually replicate
a table.


=head1 OPTIONS SUMMARY

=head2 HELP

=over 5

=item -help | -h

this help

=back

=head2 FROM INFO

=over 5

=item -from_server | -fs        (string)

from server name

=item  -from_database | -fd     (string)

from database name

=item  -from_user | -fu         (string)

from username

=item  -from_password | -fp    (string)

from username password

=back

=head2 FROM SOURCES

=over 5

=item -from_table | -ft      (string)

from table name

=item -from_sql (string)

string is the sql to run against the I<from> server

=item -from_script (string)

string is the filename containing sql to run

=item -from_perl (coderef)

coderef is perl sub to call to get data

=back

=head2 TO INFO

=over 5

=item -to_server | -ts (string)

to server name

=item -to_table | -tt (string)

to table name

=item -to_user | -tu (string)

to username

=item -to_password | -tp (string)

to username password

=back

=head2 FROM & TO INFO

=over 5

=item -server | -S (string)

set from_server and to_server

=item -database | -D (string)

set from_database

=item -table | -T (string)

set from_table and to_table

=item -user | -U (string)

set from_user and to_user

=item -password | -P (string)

set from_password and to_password

=back

=head2 MISC

=over 5

=item -batchsize | -bs (int)

bcp batch size. Default=1000

=item -where_clause | -wc (string)

append I<string> when using -from_table to sql select statement

=item -truncate_flag | -tf

truncate to_table

=item -delete_flag | -df

delete I<to_table> [where I<where_clause>]

=item -app_name | -an (string)

application name

=item -holdlock | -hl

adds I<holdlock> after the I<from_table> 

=item -trim_whitespace | -tw

strips trailing whitespace

=back

=head2 AUTO DELETE

=over 5

=item -auto_delete [I<c1,c2...>]

I<c1,c2...> are I<to_table> column keys 

=item -auto_delete_batchsize  (int)

auto_delete batchsize

=item -scratch_db  (string)

scratch database used by auto_delete

=back

=head2 CALLBACKS

=over 5

=item -callback_pre_send (coderef)

before row is sent callback

=item -callback_err_send (coderef)

error on bcp_sendrow callback

=item -callback_err_batch (coderef)

error on bcp_batch callback

=item -callback_print (coderef)

any output that normally goes to stdout callback

=back

=head2 ERROR HANDLING

=over 5

=item -error_handling| -eh (string)

I<string> is B<abort> or B<continue>. Default is B<abort>.

=back

=head2 FLAGS

=over 5

=item -echo

echo sql commands

=item -silent

don't print begin & end/summary messages

=item -progress_log

print progess message on every bcp_batch

=item -debug

programmer debug mode

=back

=head1 OPTION DETAILS

=head2 from sources

 -from_table | -ft  <table_name>

from table name. Use a fully qualified path to be safe. For example,  pubs..titles. This removes the dependency on the default
database for the -from_user value.

 -from_sql  <string>

send sql in <string> to -from_server and xfer results to -to_table.  For example, 'select author_id, lname from pubs..authors'
This implies the -to_table has two columns of compatible type to store author_id and lname in it.

 -from_script <file> 

send sql in <file> to from_server and xfer results to to_table.  Essentially the same as -from_sql except that it opens
a file and gets the sql from there.

 -from_perl <code-ref> 

call code reference repetitively for data. Call the code-ref for data to send to -to_table.  
user routine must return the following array: ($status, $array_ref)  where $status is true to call it again or false to 
end the transfer. $arrary_ref is an array refernce to the row to send. This switch is only available from the API for
obvious reasons.


=head2 from information

 -from_server | -fs  <server_name>   
   
The name of the server get the data from. Also see switch -server.

 -from_database | -fd  <database_name>   

The name of the from database. Optional. Will execute a dbuse on the from server. Also
see switch -database.

 -from_user | -fu  <user_name> 

username to use on the from server. Also see switch -user.

 -from_password | -fp  <password> 

password to use on the from user. Also see switch -password.



=head2 to information

 -to_server | -ts <server_name> 

name of the to server. Also see switch -server.

 -to_table | -tt  <table_name>

name of the to table. USE A FULLY QUALIFIED PATH. Eg. pubs..titles. This removes the dependency on
the the login default database. Also see switch -table.

 -to_user | -tu <user_name>

to user name. Also see switch -user.

 -to_password | -tp <password>

to user password. Also see switch -password.
 

=head2 I<from> and I<to> short cuts

many times the I<from> and I<to> user/pw pair are the same. Or the table names are 
the same on the two servers. These options are just a way to set both the 
I<from> and I<to> options above with one switch.

 -server | -S <server>

set from_server & to_server to this value. Also see switches -from_server and -to_server.

 -database | -D  <database>

set from_database only. The to_database name is set using a fully 
qualified table name. This this the way bcp works. I'd change it if I could. Also see
switches -from_database and -to_database.

 -table | -T  <table>    

set the from_table & to_table to this value. Also see switches -from_table and -to_table.

 -user | -U  <user_name>

set from_user & to_user to this value. Also see switches -from_user and -to_user.

 -password | -P  <password>

set from_password & to_password to this value. Also see switches -from_password and
-to_password
 


=head2 other qualifiers

 -batchsize | -bs  <number>    

bcp batch size into the to_table. Default=1000.

 -where_clause | -wc <where_clause>

send 'select * from I<from_table> where I<where_clause>' to the I<from_server>. The 
default is to use no where clause thereby just sending 'select * from I<from_table>'.
This is only used when the I<from_source> is a table.  Also see -delete_flag.

 -truncate_flag | -tf  

send 'truncate table I<to_table>' to the I<to_server> before the transfer begins.
This requires dbo privilege, remember. If you don't have dbo privilege and you
want to remove all the rows from the target table you have two options. Use the
-delete_flag with no -where_clause or truncate the table via an alternate method (eg.
under a different user name) before you run the transfer. Default is false.

 -delete_flag | -df     

send 'delete I<to_table> [where I<where_clause>]' to the I<to_server> before the transfer 
begins. Also see -where_clause. Default is false.


 -app_name | -an <val>    

name of program. Will append '_F' and '_T' to differentiate between the I<from> and I<to>
connections. This string appears in the field program_name in the table master..sysprocesses.
Will truncate to 14 characters if longer.  Default is basename($0). 

 -holdlock | hl

if using I<from_table> then this switch will add an additional B<holdlock> after
the table. This is especially useful if the I<from_table> has the potential to be 
updated at the same time the transfer is taking place. The default is noholdlock.

 -trim_whitespace | tw

Will set B<nsql>'s $Sybase::DBlib::nsql_strip_whitespace to true which trims trailing
whitespace before bcp'ing the data into target table. If a field is all whitepace on
the I<from> table then the result of trimming whitespace will be null. Therefore,
the corresponding column on the I<to> table needs to permit nulls. Default is false.


=head2 auto delete

The -auto_delete switch indicates that it should be ensured that any rows selected from 
the I<from_table> first be removed from the I<to_table>. This differs from the 
-delete_flag and -where_clause combination that makes sweeping deletes. -auto_delete was
added for the sole purpose of keeping the -to_table up-to-date by transferring 
only 'changed' records from the -from_table and not knowing just which records 
changed apriori. 

 -auto_delete [c1,c2...]

c1, c2, ... are the B<unique key column names> into I<to_table>. When this switch is in 
effect the module will create a table in -scratch_db named sybxfer$$, $$ being the current 
process number, with the columns c1, c2, ...  Then it will bcp only those columns to
this temp table. After that bcp is complete it will perform a delete (in a loop of the 
-auto_delete_batchsize) via a join by these columns in the temp table to the 
I<to_table> so as to remove the rows, if any. After the delete is complete the temp
table is dropped and all the columns specified will be bcp'ed to the I<to_table>.

In essence, a simplisitic view is that the following is effectively done. 
'delete I<to_table> where c1='cval1' and c2='cval2' ...' for every row in 
the I<from_table> for values c1, c2, ... I mention this only in this way because 
the explanation above seems either too convoluted (or I can't explain it clearly enough.)


 -auto_delete_batchsize | adb [i]

batchsize to use when auto-deleting rows. 3000 is the default. See -auto_delete.

 -scratch_db  [db]       

scratch database used by auto_delete. tempdb is the default. See -auto_delete.

=head2 callbacks (also see error handling)

callback switches are only valid from the API. ie. not from the script I<sybxfer>

 -callback_pre_send <code_ref>

sub to call before sending row to I<to_server>. first and only arg
is ref to the array of the data. cb routine returns ($status, \@row).
$status true means continue, $status false means abort.

It's called like this: 
       ($status_cb_pre, $r_user_row) = $opt->{callback_pre_send}->(\@row);

It must return this:  return ($status, \@row) 



 -callback_print <code_ref> 

sub to call if the catching of log messages desired. No return status necessary. 

It's called like this: $opt->{callback_print}->($message)

 

=head2 error handling

What to do upon encountering an error?

 -error_handling | -eh  <value>

Value can be B<abort> or B<continue> only. I should probably have a threshold number but
I'll leave that until a later time.  When set to B<continue> the transfer will proceed 
and call any error callbacks that are defined (see below) and examine the return status of those
to decide what to do next. If no error callbacks are defined and -error_handling set
to B<continue> the module will print the offending record by describing the row by
record number, column-types and data values and continue to the next record. If -error_handling
is set to B<abort>, the same is printed and the xfer sub exits with a non-zero return
code.
The default is B<abort>.

Here's a deliberate example of a syntax type error and an example of the output 
from the error_handler:

 Sybase error: Attempt to convert data stopped by syntax error in source field.
 
 row #1
     1: ID                       char(10)        <bababooey >
     2: TICKER                   char(8)         <>
     3: CPN                      float(8)        <>
     4: MATURITY                 datetime(8)     <>
     5: SERIES                   char(6)         <JUNK>
     6: NAME                     varchar(30)     <>
     7: SHORT_NAME               varchar(20)     <>
     8: ISSUER_INDUSTRY          varchar(16)     <>
     9: MARKET_SECTOR_DES        char(6)         <>
    10: CPN_FREQ                 tinyint(1)      <>
    11: CPN_TYP                  varchar(24)     <>
    12: MTY_TYP                  varchar(18)     <>
    13: CALC_TYP_DES             varchar(18)     <>
    14: DAY_CNT                  int(4)          <>
    15: MARKET_ISSUE             varchar(25)     <bo_fixed_euro_agency_px>
 Column #16 actual length [26] > declared length [4]
    16: COUNTRY                  char(4)         <Sep 29 2000 12:00:00:000AM>
 Column #17 actual length [6] > declared length [4]
    17: CRNCY                    char(4)         <EMISCH>
    18: COLLAT_TYP               varchar(18)     <EBS (SWISS)>
    19: AMT_ISSUED               float(8)        <Govt>
    20: AMT_OUTSTANDING          float(8)        <CH>
    21: MIN_PIECE                float(8)        <>
    22: MIN_INCREMENT            float(8)        <CLEAN>
 Sybase error: Attempt to convert data stopped by syntax error in source field.
 
 Aborting on error.
   error_handling = abort
 1 rows read before abort



 -callback_err_send <code_ref | hash_ref>

sub to call if error detected on bcp sendrow. The module pases a hash as you
see below. It expects and 2 element array in return  ie. ($status, \@row).
$status true means continue, $status false means abort.
Can also be a hash_ref meaning to store the error rows keyed by row number.

 

It's called like this if I<code_ref>.  @row is the array of data:

     $opt->{callback_err_send}->(DB_ERROR => $DB_ERROR,
                                 row_num  => $row_rum,
                                 row_ptr  => \@row );

It must return this:  return ($status, \@row);

It stores the error like this if I<hash_ref>:

     ${ $opt->{callback_err_send} }{ $row_num }->{msg} = $DB_ERROR;
     ${ $opt->{callback_err_send} }{ $row_num }->{row} = \@row;




 -callback_err_batch <ref>

sub to call if error detected on bcp batch. Not implemented.



=head2 miscellaneous boolean flags

 -echo                   

echo sql commands running under the covers. Default is false.

 -silent                 

don't print begin & end/summary messages. Default is false.

 -progress_log           

print progess message on every bcp_sendbatch. Default is true.

 -debug                  

programmer debug mode. Default is false.
 




=head1 EXAMPLES

=head2   EXAMPLE #1  - simple table transfer

   my %opts = ( 
                -from_server   => 'EARTH',
                -to_server     => 'MARS',
                -U             => 'steve',          #user 'steve' is valid on both servers/dbs
                -P             => 'BobDobbs',       #same pw for both
                -T             => 'lamr..cities',   #same db and table on both servers

                -truncate_flag => 1,                #issue a 'truncate table lamr..cities' on to server
                -batchsize     => 2000,
              );

   my $h = new Sybase::Xfer(%opts);
   my $rs = $h->xfer();
   $rs && die 'xfer aborted';




=head2   EXAMPLE #2  - using 'from_sql'

   my %opts = (
                -from_server    => 'NYP_FID_RATINGS',
                -from_user      => 'rateuser',
                -from_password  => 'grack',
                -from_database  => 'fid_ratings',
                -from_sql       => 'select id, name, rating from rating where name like "A%"',

                -to_server      => 'NYP_FID_DATAMART',
                -to_user        => 'fiduser',
                -to_password    => 'glorp',
                -to_table       => 'fid_datamart..ratings_sap',  #NOTE FULLY QUALIFIED NAME

                -batchsize      => 500,
                -error_handling => 'abort',
               );

   my $h = new Sybase::Xfer(%opts);
   my $rs = $h->xfer();
   $rs && die 'xfer aborted';



=head2   EXAMPLE #3  - using all three callbacks

   my %opts = (
                -from_server        => 'MOTO',
                -from_user          => 'guest',
                -from_password      => 'guest',
                -from_database      => 'parts',
                -from_sql           => "select partno, desc, price from elec\n" .
                                       "UNION\n" .
                                       "select partno, name, px from m777\n",

                -to_server          => 'MASTERMOTO',
                -to_user            => 'kingfish',
                -to_password        => 'shirley',
                -to_table           => 'summary..elec_contents',

                -callback_pre_send  => \&pre_send,
                -callback_err_send  => \&err_on_send,
                -callback_err_batch => \&err_batch,

                -batchsize          => 100,
               );

 #-----
 #pre send callback. Adds 10000 to partno effectively between the time it 
 #was pulled from the source and the time it gets pushed into the target table.
 #-----
    sub pre_send {
      my @row = @{ +shift };    #array reference to the row about to be sent to the 'to' server
      $row[0] += 10000;         #manipulate @row all you want
      my $status = 1;           #status true means continue, false means abort
      return ($status, \@row);  #mandatory return args
    }


 #----
 #error on 'send row' callback - fix a syntax error by nulling out offending value.
 #----
    sub err_on_send {

        my %err_data = @_;
   
 #just to be explicit about it
        my $err_message = $err_data{DB_ERROR};  #key #1 = 'DB_ERROR'
        my $err_row_num = $err_data{row_num};   #key #2 = 'row_num' : last row sent to server
        my @row =  @{ $err_data{row_ptr} };     #key #3 = 'row_ptr' : reference to the array of



 #nb.
 #for example purposes I'm hardwiring this. I real life you'd create closure and send
 #it via that to this routine has a parameter.
 #
 #list of datatypes of the columns
        my $p_datatypes->{part_no}->{col_id} = 1;
        my $p_datatypes->{part_no}->{col_type} = 'int';
        my $p_datatypes->{descr}->{col_id} = 2;
        my $p_datatypes->{descr}->{col_type} = 'varchar(30)';
        my $p_datatypes->{price}->{col_id} = 3;
        my $p_datatypes->{price}->{col_type} = 'float';
 
        my (@col_names, @col_types, $retry_status) = ();
 
 #get column names in column order
        my @col_names =  sort { $p_datatypes->{$a}->{col_id} 
                         <=> $p_datatypes->{$b}->{col_id} }
                         keys %{ $p_datatypes };
 
 #get column types
        for my $col (@col_names) { push @col_types, $p_datatypes->{$col}->{col_type} }
 
 #for syntax errors compare data to data type
        my @row = ();
        if ($err_data{DB_ERROR} =~ /syntax/i ) {
           @row = @{ $err_data{row_ptr} };
 
 #check for character data in 'int' field
           for( my $i=0; $i<@row; $i++) {
              if($col_types[$i] =~ /int/ && $row[$i] =~ /\D/ ) {
                 $row[$i] = undef;
                 $retry_status = 1;
              }
           }
        }
 
 
 #if not a retry candidate then bail out
        unless ($retry_status) {
           cmp_print("row failed ($err_data{DB_ERROR})\n");
           for( my $i=0; $i<@row; $i++) { cmp_print("\t$i : $row[$i]\n") }
           cmp_error("xfer aborted");
        }
 
        return ($retry_status,\@row);
   }
 


 #----
 #error on 'send batch' callback
 #----
    sub err_batch {
      my %info = @_;                      #arg is a two keyed hash
      my $err_message = $info{DB_ERRROR}; #key #1 = 'DB_ERROR' 
      my $err_row_num = $info{row_num};   #key #2 = 'row_num', last row sent to server 
      my $status = 1;                     #status true means continue, false means abort
      return $status;                     #mandatory return arg
    }                

=head2 EXAMPLE #4 - Using auto_delete


   my %opts = (
                -user           => 'smoggy',
                -password       => 'smoggy',
                -table          => 'fx_rates..asia_geo_region',

                -from_server    => 'TEST',
                -to_server      => 'PROD',
 
                -auto_delete    => 'country_iso, id',   #unique key in table
                -auto_delete_batchsize => 10000,        #change the default
                -scratch_db     => 'tempdb',            #just to be explicit about it

                -batchsize      => 50000,
                -error_handling => 'abort',
               );

 
my $h = new Sybase::Xfer(%opts);
my $rs = $h->xfer();
   $rs && die 'xfer aborted';>


=head1 WISH LIST

=over 5

=item *

Would like to convert from Sybase:: to DBI:: and ultimately be able to transfer
data between different server makes and models. 

=item *

Create the -to_table on the fly if it doesn't exist.

=item *

Incorporate more of Michael Peppler's features of Sybase::BCP like pushing all the
rows except the bad ones of a batch into the target table. I got my eye on his 
code but it'll have to wait to the next release. :)

=item *

When the -delete_flag is specified perform the delete in loop of bathsize rows 
(instead of just running a naked delete command)

=item *

Incorporate logic to do the right thing when transferring data between Unicode and
ISO versions of the Sybase server.

=back


=head1 BUGS

=over 5

=item * 

Error handling and reporting could be better. 

=back

=head1 CONTACTS


=over 5

=item Author's e-mail

stephen.sprague@msdw.com

=item Michael Peppler's homepage

http://www.mbay.net/~mpeppler/
for all things perl and Sybase including Sybase::DBLib, Sybase::BCP and a 
ton other goodies. Definitely a must see. 

=item Sybperl mail-list

This a good place to ask questions specifically about Sybase and Perl.
I pulled these instructions from Michael's page:

Send a message to listproc@list.cren.net with
subscribe Sybperl-L I<your-name>
in the body to subscribe. The mailing list is archived
and searchable at http://www.cren.net:8080/ 

=item Original idea

Sybase::Xfer idea inspired by Mikhail Kopchenov.

=back


=head1 VERSION

Version 0.1, 01-OCT-2000

=cut

1;
