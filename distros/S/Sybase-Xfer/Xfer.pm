# $Id: Xfer.pm,v 1.42 2001/05/10 13:09:40 spragues Exp spragues $
#
# (c) 1999, 2000 Morgan Stanley Dean Witter and Co.
# See ..../src/LICENSE for terms of distribution.
#
#
#See pod documentation at the end of this file
# 
#
#reminder. when updating documentation:
#   1) usage
#   2) short usage
#   3) pod summary
#   4) pod detailed
#
#
#public:
#   sub new
#   sub xfer
#   sub done 
#
#if -error_handling set to 'retry' and -callback_err_batch undefined
#then this routine becomes the bcp_batch error_handler
#
#   sub bcp_batch_error_handler {
#
#private:
#   sub _grab_from_sybase {
#   sub _grab_from_file {
#   sub _grab_from_perl {
#   sub sx_cleanup {
#
#sendrow stuff
#   sub sx_sendrow_bcp {
#   sub sx_sendrow_batch {
#   sub sx_sendrow_batch_of_size {
#   sub sx_sendrow_batch_success {
#   sub sx_sendrow_return {
#   sub sx_sendrow_temp {
#   sub sx_sendrow_final_batch {
#
#auto delete stuff
#   sub sx_remove_target_rows {
#   sub sx_auto_delete_setup {
#
#option stuff
#   sub _checkargs {
#   sub _prep_xfer {
#   sub sx_verify_options { 
#   sub sx_from_file_map {
#
#error handling routinues
#   sub sx_sendrow_failure {
#   sub sx_sendrow_batch_failure {
#   sub _print_error_detection {
#   sub sx_error_tidy_msg {
#   sub sx_oversize_error {
#
#util stuff
#   sub _open_bcp {
#
#   sub sx_complain {
#   sub sx_usage {
#   sub sx_message_handler {
#   sub sx_error_handler {
#   sub sx_error_handler_dbi {
#   sub _print {
#   sub sx_debug {
#   sub sx_delete_sql {
#   sub sx_truncate_table {
#   sub sx_delete_rows {
#   sub _drop_indices {
#   sub _drop_indices_setup {
#   sub _create_indices {
#   sub sx_run_shell_cmd {
#   sub sx_parse_user_hash {
#   sub _parse_path {
#
#

    package Sybase::Xfer;

    use 5.6.1;

#set-up package
    use strict;

#    use Exporter;
#    use Carp;
#    use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION/;
#    @ISA = qw/Exporter/;

    use vars qw/$VERSION/;
    $VERSION = '0.63';

#RCS version
    my ($RCSVERSION) = do {
        my @r = ( q$Revision: 1.42 $ =~ /\d+/g );
        sprintf "%d." . "%02d" x $#r, @r;
    };

#modules 
#    use lib '/ms/dist/perl5/PROJ/DBI/1.30-5.6/lib/perl5/';
#    use DBI;

#Sybase DBD
#     use lib '/ms/dist/perl5/PROJ/DBD-Sybase/0.94-5.6/lib/perl5/';
#    use lib '/ms/dev/perl5/DBD-Sybase/0.95-5.6/install/.exec/sun4u.sunos64.5.8/lib/perl5';
#     use lib '/ms/dist/perl5/PROJ/DBD-Sybase/0.95-5.6/lib/perl5/';

#DB2
#    use lib '/ms/dist/perl5/PROJ/DBD-DB2/0.76-5.6/lib/perl5/';
#    use DBD::DB2;
#    use DBD::DB2::Constants;

#BLK routines for Sybase
    use lib '/ms/dist/perl5/PROJ/syb/2.15-5.6/lib/perl5';

#    use lib '/ms/dist/perl5/PROJ/syb/2.14-5.6/lib/perl5';
    use Sybase::CTlib;

#other stuff
    use FileHandle;
    use File::Basename;

#    use Sybase::ObjectInfo;
    use Getopt::Long;
    use Tie::IxHash;

    use Sys::Hostname;

#to validate numbers
    use POSIX qw/strtod/;

#constants
    use constant RS_UNRECOV_ERROR => -1;
    use constant RS_INTERRUPT     => -2;
    use constant RS_TIMEOUT       => -3;

#globals
    use vars qw/$DB_ERROR %opt $DB_ERROR_ONELINE $DB_DEADLOCK $DB_IN_ERR_HANDLER/;

#-----------------------------------------------------------------------
#constructor
#-----------------------------------------------------------------------
    sub new {

        my $self  = shift;
        my $class = ref($self) || $self;


#basic option checking, bail out of error
        my %opt = $self->_checkargs(@_);
        return undef if exists $opt{1};

        $self = {%opt};
        bless $self, $class;

#use CTlib instead of DBI
        $self->{CTLib} = 1;

#other initializations
        $DB_ERROR = ();
        $Sybase::CTlib::nsql_strip_whitespace++ if $self->{trim_whitespace};

#set the stage. delete/truncate; define source. if error return. 
        $self->_prep_xfer() && return undef;

#squirrel away a few counts
        $self->{sx_send_count}          = 0;
        $self->{sx_succeed_count}       = 0;
        $self->{sx_err_count}           = 0;
        $self->{sx_resend_count}        = 0;
        $self->{sx_send_count_batch}    = 0;
        $self->{sx_succeed_count_batch} = 0;
        $self->{sx_err_count_batch}     = 0;
        $self->{sx_resend_count_batch}  = 0;

#install interrupt signal handler
        $SIG{INT} = sub { return sx_interrupt_handler($self) };


#send it back
        return $self;
    }

#---------
#interrupt handler
#----------
    sub sx_interrupt_handler {
        my $self = shift;

#dummy up error message for sx_cleanup
        $DB_ERROR = "Interrupt detected. Terminating transfer!";

#print
        $self->_print("\n");
        $self->_print("------\n");
        $self->_print("$DB_ERROR\n");
        $self->_print("------\n");

        $self->{GOT_INTERRUPT} = RS_INTERRUPT;
        die 'interrupt';

    }

#----------
#timeout handler
#----------
    sub sx_timeout_handler {
        my $self = shift;

#dummy up error message for sx_cleanup
        $DB_ERROR = "Timeout detected ($self->{timeout} seconds). Terminating transfer!";

#print
        $self->_print("------\n");
        $self->_print("$DB_ERROR\n");
        $self->_print("------\n");

        $self->{GOT_TIMEOUT} = RS_TIMEOUT;
        die 'timeout';

    }

#-----------------------------------------------------------------------
#destroy the object
#-----------------------------------------------------------------------
    sub done {
        my $self  = shift;
        my $class = ref($self) || $self;

#return current handlers
        ct_callback( CS_SERVERMSG_CB, $self->{current_err_handler} );
        ct_callback( CS_CLIENTMSG_CB, $self->{current_msg_handler} );

        my $num_success = $self->{sx_succeed_count};
        my $num_err     = $self->{sx_err_count};
        my $num_resend  = $self->{sx_resend_count};
        my $num_fails   = $num_err - $num_resend;

        $self = undef;

        return wantarray ? ( $num_success, $num_err, $num_resend, $num_fails ) : $num_success;
    }

#-----------------------------------------------------------------------
#xfer the data
#-----------------------------------------------------------------------
    sub xfer {

        my $self  = shift;
        my $class = ref($self) || $self;

#set return type
        my $return = $_[0];
        my %rstyle;
        if ( ref $return ) {
            %rstyle = %$return;
        }
        elsif ($return) {
            %rstyle = @_;
        }
        else {
            %rstyle = ( -return => 'ARRAY' );
        }
        my $val = $rstyle{"-return"} || $rstyle{return};
        sx_complain("unknown return key passed to xfer: <$return>\n"), return 1 unless $val;
        unless ( ref $val eq "HASH" || uc $val eq "HASH" || ref $val eq "ARRAY" || uc $val eq "ARRAY" ) {
            sx_complain("-return must be HASH, ARRAY, {} or []\n") && return 1;
        }
        $self->{return} ||= $val;




#no buffering on stdout
        $|++;

#timeout signal
        if ( $self->{timeout} ) {
            alarm $self->{timeout};
            $SIG{ALRM} = sub { return sx_timeout_handler($self) };
        }



#grab data from one of three possible genre of sources
        my $rs = 0;
        eval {
            SWITCH: {

#perl code source
                if ( ref( $self->{sx_xfer_source} ) =~ /^(CODE|ARRAY)/ ) {
                    $rs = $self->_grab_from_perl();
                    last;
                }

#file-like source
                if ( UNIVERSAL::isa( $self->{sx_xfer_source}, 'IO::File' ) ) {
                    $rs = $self->_grab_from_file();
                    last;
                }

#db source
                $rs = $self->_grab_from_db();
                last;
            }

        };

#check return
        if ($@) {
            $self->_print("main eval error: $@\n");
            $rs = $self->{GOT_INTERRUPT} || $self->{GOT_TIMEOUT};
        }

#summarize, restore env 
        my @rc = sx_cleanup( $self, $rs );

#return with proper context
        my $rstyle = $self->{return};

#hash return
        my %rs = ( rows_read => $rc[1],
            rows_transferred => $rc[2],
            last_error_msg   => $rc[3],
            scalar_return    => $rc[0],
            ok               => $rc[0] >= 0 ? 1 : 0,    #1=>all rows transferred, 0=>problems
        );

#array return
        my @rs = @rc[ 1 .. 3, 0 ];
        $rs[4] = $rc[0] >= 0 ? 1 : 0;

#scalar return
        $rs = $rc[0];

#send it back
        if ( $rstyle eq "HASH" || ref $rstyle eq "HASH" ) {
            return wantarray ? %rs : $rs;

        }
        elsif ( $rstyle eq "ARRAY" || ref $rstyle eq "ARRAY" ) {
            return wantarray ? @rs : $rs;

#backward compatibility requires array if not specified
        }
        else {
            return wantarray ? @rs : $rs;

        }
    }


#-----------------------------------------------------------------------
#cleanup & exit
#-----------------------------------------------------------------------
    sub sx_cleanup {

        my ( $self, $grab_rs ) = @_;

#resave db error if not saved already
        $self->{sx_save_db_error} = $DB_ERROR if $DB_ERROR && !$self->{sx_save_db_error};
        $self->{sx_save_db_error_oneline} = $DB_ERROR_ONELINE if $DB_ERROR_ONELINE && !$self->{sx_save_db_error_oneline};

#close 'from' and 'to' connections
        $self->{sx_dbh_from} = undef if ref $self->{sx_dbh_from};

#        $self->{sx_dbh_to_bcp}->blk_drop() if ref $self->{sx_dbh_to_bcp};
        $self->{sx_dbh_to_bcp} = undef if ref $self->{sx_dbh_to_bcp};

#if indices were dropped on 'to' table then recreate them now.
        $self->{drop_and_recreate_indices} && $self->_create_indices() && return 1;

#close the non-bcp 'to' connection
        $self->{sx_dbh_to_non_bcp} = undef if $self->{sx_dbh_to_non_bcp};

#if number of rows sent is zero and an error condition, then sx_sendrow_bcp NEVER
#called to field an error. So we have to do it here.
        if ($grab_rs) {
            if ( $self->{sx_send_count} == 0 || $self->{GOT_INTERRUPT} || $self->{GOT_TIMEOUT} ) {
                $self->_print("--------------\n");
                $self->_print("Error detected. (non-recoverable)\n");
                sx_error_tidy_msg($self);
                $self->_print("--------------\n");
            }
            $self->{GOT_UNRECOV_ERROR} = 1;
        }

#return current handlers
        ct_callback( CS_SERVERMSG_CB, $self->{current_err_handler} );
        ct_callback( CS_CLIENTMSG_CB, $self->{current_msg_handler} );

#restore nsql deadlock retry logic
        $Sybase::CTlib::nsql_deadlock_retrycount = $self->{save_deadlock_retry};
        $Sybase::CTlib::nsql_deadlock_retrysleep = $self->{save_deadlock_sleep};
        $Sybase::CTlib::nsql_deadlock_verbose    = $self->{save_deadlock_verbose};

#restore alarm settings
        alarm(0) if $opt{timeout};

#last error saved if retry or continue
        my $err_oneline = $self->{sx_save_db_error_oneline} || $DB_ERROR_ONELINE;
        my $err = $self->{sx_save_db_error} || $DB_ERROR;

#notification
#     my $num_fails = $self->{sx_err_count} - $self->{sx_resend_count};
        my $num_fails = $self->{sx_send_count} - $self->{sx_succeed_count};
        unless ( $self->{silent} ) {

            $self->_print("\n");
            $self->_print("Xfer summary:\n");
            $self->_print("   $self->{sx_send_count} rows read from source\n");
            $self->_print("   $self->{sx_succeed_count} rows transferred to target\n");

#8/29/01. too misleading when retry is on.
##            $self->_print(  "   $self->{sx_err_count} rows had errors\n" ) if $self->{sx_err_count} > 0;
##            $self->_print(  "   $self->{sx_resend_count} total rows resent\n" ) if $self->{sx_resend_count} > 0;

#only if retry on
            if ( $num_fails > 0 && $self->{error_handling} =~ /^retry/ ) {
                $self->_print("   $num_fails total unsuccessful retries\n");
            }

            $self->_print("   last known error message encountered: $err_oneline\n") if $err_oneline;
        }

#get rid of empty error file
        my $elf = $self->{sx_error_data_file_fh};
        my $fn  = $self->{error_data_file};
        if ($elf) {
            $elf->close();
            unlink $fn unless $fn && -s $fn;
        }

#set return values

#scalar return value
#    0  = success w/o any hitches
#   >0  = success with n number of recoverable failures
#   -1 = unrecovable errors (eg. bad sql, xfer aborted)
#   -2 = got interrupt
#   -3 = got timeout
#
        my $scalar_return = 0;
        $scalar_return ||= $self->{GOT_INTERRUPT} || $self->{GOT_TIMEOUT} || -1 * defined( $self->{GOT_UNRECOV_ERROR} );
        if ( $num_fails >= 1 ) {
            $scalar_return = -1.0 * abs($num_fails);
        }

        my $num_rows_read    = $self->{sx_send_count};
        my $num_rows_xferred = $self->{sx_succeed_count};

#        print "scalar return=$scalar_return, num_fails=$num_fails\n";    #DEBUG
        return ( $scalar_return, $num_rows_read, $num_rows_xferred, $err );

    }

#-----------------------------------------------------------------------
#routine to manage fetching one record at time from the 'from' source
#-----------------------------------------------------------------------
    sub sx_get_row_at_a_time {

        my ( $self, $sql, $cb ) = @_;

        if ( $self->{from_source} =~ /^dbd/i ) {

            my $dbh = $self->{sx_dbh_from};

#            my $sth = $dbh->do($sql);

#send sql
            my $sth;
            unless ( $sth = $dbh->prepare($sql) ) {
                $DB_ERROR = $dbh->errstr;
                $self->_print( "error in dbi.prepare: " . $DB_ERROR . "\n" );
                return 1;
            }

#run sql
            my $re;
            unless ( $re = $sth->execute ) {
                $DB_ERROR = $sth->errstr;
                $self->_print( "error in dbi.execute: <" . $DB_ERROR . ">\n" );
                return 1;
            }

#field 'rows' one at a time
            {
                my ( @results, $set );
                local $SIG{__WARN__} = sub { warn "SJS: $_[0]" if $_[0] !~ /no statement executing/; };
                do {
                    $cb->( $sth->fetchall_array( [] ) );
                } while ( $sth->{syb_more_results} );
            }
            return 0;
        }
    }

#-----------------------------------------------------------------------
#grab data from dbi source to push to 'to' server
#-----------------------------------------------------------------------
    sub _grab_from_db {

        my $self = shift;

#remove the rows from target table
        $self->{auto_delete} && $self->sx_remove_target_rows() && return 1;

#get bcp connection
        my ( $db, $tab ) = @{$self}{qw/sx_to_database sx_to_table/};
        my $nc = scalar @{ $self->{sx_to_info}->{$db}->{$tab}->{__COLNAMES__} };
        $self->{sx_dbh_to_bcp} = $self->_open_bcp( $self->{to_table}, $nc );
        return 1 if $self->{sx_dbh_to_bcp} == 1;

#see if -from_file_map is specified. This could result in the re-ordering of fields
        $self->sx_from_file_map() && return 1;

#define cb for use with nsql
        my $cb = sub { return sx_sendrow_bcp( \@_, $self ) };

#run nsql on 'from' server
        $self->_print("transferring rows to $self->{to_server} : $self->{to_table}\n") if ( $self->{echo} );
        my $sql = $self->{sx_xfer_source};

#progress log
        if ( $self->{progress_log} ) {
            $self->_print("\n");
            $self->_print("Progress log\n");
        }

#hack. peppler needs to fix...
        local $SIG{__WARN__} = sub { warn "$_[0]" if $_[0] !~ /no statement executing/; };

#$sql will be an arrayref when there are multiple batches in the from_sql/from_script
        if ( ref($sql) eq "ARRAY" ) {
            for my $each_sql ( @{$sql} ) {
                $self->_print("SQL:\n$each_sql\n") if $self->{echo};
                $self->_runsql( $self->{sx_dbh_from}, $each_sql, [], $cb );

#!                $self->{sx_dbh_from}->func( $each_sql, [], $cb, 'nsql' );
                last if $DB_ERROR;
            }
        }
        else {
            $self->_print("SQL:\n$sql\n") if $self->{echo};
            $self->_runsql( $self->{sx_dbh_from}, $sql, [], $cb );

#!            $self->{sx_dbh_from}->func( $sql, [], $cb, 'nsql' );
        }

#commit last set of rows
        return !$DB_ERROR ? $self->sx_sendrow_final_batch() : 1;
    }

#-----------------------------------------------------------------------
#grab data from file and push to 'to' server
#-----------------------------------------------------------------------
    sub _grab_from_file {

        my $self = shift;

#remove the rows from target table, if called for.
        $self->{auto_delete} && sx_remove_target_rows($self) && return 1;

#bcp init
        my ( $db, $tab ) = @{$self}{qw/sx_to_database sx_to_table/};
        my $nc = scalar @{ $self->{sx_to_info}->{$db}->{$tab}->{__COLNAMES__} };
        $self->{sx_dbh_to_bcp} = $self->_open_bcp( $self->{to_table}, $nc );
        return 1 if $self->{sx_dbh_to_bcp} == 1;

#see if -from_file_map is specified. This could result in the re-ordering of fields
        sx_from_file_map($self) && return 1;
        my ( $map, %map ) = ();
        if ( $self->{sx_from_file_map} ) {
            %map = %{ $self->{sx_from_file_map} };
            $map++;
        }

#log
        if ( $self->{progress_log} ) {
            $self->_print("\n");
            $self->_print("Progress log\n");
        }

#transfer the data by reading the file
        my $delim    = $self->{from_file_delimiter};
        my $fixed    = $self->{from_file_pack_format};
        my $fh       = $self->{sx_xfer_source};
        my @colnames = @{ $self->{sx_to_colnames} };
        my ( $status, $line ) = ( 1, 0 );
        while ( defined( $line = <$fh> ) && $status ) {
            chomp $line;
            my $r_data = ();

            if ( $delim && $map ) {
                $r_data = [ ( split /$delim/, $line, -1 ) ];    #[ @map{@colnames} ] ];
            }
            elsif ( $delim && !$map ) {
                $r_data = [ split /$delim/, $line, -1 ];
            }
            elsif ( $fixed && $map ) {
                $r_data = [ ( unpack( $self->{from_file_pack_format}, $line ) ) ];
            }
            elsif ( $fixed && !$map ) {
                $r_data = [ unpack( $self->{from_file_pack_format}, $line ) ];
            }

            $status = sx_sendrow_bcp( $r_data, $self )    #returns 1==good, 0==bad;
        }

#return
        return $status ? sx_sendrow_final_batch($self) : 1;

    }

#-----------------------------------------------------------------------
#grab data from perl source
#-----------------------------------------------------------------------
    sub _grab_from_perl {

        my $opt = shift;

#remove the rows from target table, if called for.
        $opt->{auto_delete} && sx_remove_target_rows($opt) && return 1;

#bcp init
        my ( $db, $tab ) = @{$opt}{qw/sx_to_database sx_to_table/};
        my $nc = scalar @{ $opt->{sx_to_info}->{$db}->{$tab}->{__COLNAMES__} };
        $opt->{sx_dbh_to_bcp} = $opt->_open_bcp( $opt->{to_table}, $nc );
        return 1 if $opt->{sx_dbh_to_bcp} == 1;

#progress log
        if ( $opt->{progress_log} ) {
            $opt->_print("\n");
            $opt->_print("Progress log\n");
        }

        my $bcp_status = 1;

#PERL - CODEREF
        if ( ref $opt->{from_perl} eq 'CODE' ) {

#transfer the data by calling perl code ref
#return status of user function:
#   < 0 => skip
#  == 0 => quit
#   > 0 => keep going
            my ( $status_getrow, $r_data ) = $opt->{sx_xfer_source}->();
            while ($status_getrow) {
                if ( $status_getrow >= 1 ) {
                    $bcp_status = sx_sendrow_bcp( $r_data, $opt );
                }
                else {
                    $bcp_status = 1;
                }
                last unless $bcp_status;
                ( $status_getrow, $r_data ) = $opt->{sx_xfer_source}->();
            }

#PERL - ARRAYREF
        }
        elsif ( ref $opt->{from_perl} eq 'ARRAY' ) {
            for my $row ( @{ $opt->{from_perl} } ) {
                $bcp_status = sx_sendrow_bcp( $row, $opt );
                last unless $bcp_status;
            }

        }

#set return
        return $bcp_status ? sx_sendrow_final_batch($opt) : 1;

    }

#----
#
#----
    sub _runsql {

        my ( $self, $dbh, $sql, $type, $cb ) = @_;

#ctlib connection
        if ( $self->{CTLib} ) {
            my @res = ();
            eval { @res = $dbh->nsql( $sql, $type, $cb ) };
            print "** eval: [$@] **\n" if $@;
            return \@res;

#dbi connection
        }
        else {
            if ($type) {
                my @res = ();
                eval { @res = $dbh->func( $sql, $type, $cb, 'nsql' ); };
                print "** eval: [$@] **\n" if $@;
                return \@res;
            }
            else {
                my $sth = $dbh->prepare($sql);
                $sth->execute;
                while ( $sth->{syb_more_results} ) { $sth->fetch() }
            }
        }

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
#   $opt{sx_xfer_source}
#
#auto delete stuff
#   $opt{sx_ad_create_table}
#   $opt{sx_ad_create_index}
#   $opt{sx_ad_delete_cmd}
#   $opt{sx_ad_delete_join}
#   $opt{sx_ad_upd_stat}
#   $opt{sx_ad_temp_table}
#   $opt{sx_ad_temp_tab_count}
#   $opt{sx_ad_col_num}
#   $opt{sx_ad_rows_deleted}
#   $opt{sx_ad_upd_stat}
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
#
#drop/recreate indices
#   $opt{sx_drop_indices_sql}
#   $opt{sx_create_indices_sql}
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

        return 0 unless ( $opt->{auto_delete} );

        if ( $opt->{progress_log} ) {
            $opt->_print("Auto delete log\n");
        }

# check target table to see if there's any rows in there
        sx_check_target( $opt, "auto_delete" ) || return 0;

#create temp table
        my ( $dbh_to, $dbh_from, $sql ) = @{$opt}{qw/sx_dbh_to_non_bcp sx_dbh_from sx_ad_create_table/};
        $opt->_runsql( $dbh_to, $sql, {}, undef );

#!        $opt->{sx_dbh_to_non_bcp}->func( $opt->{sx_ad_create_table}, {}, undef, 'nsql' );
        $DB_ERROR && sx_complain("unable to create temp table\n$DB_ERROR\n") && return 1;

#create a bcp connection to it
        my $nc = scalar @{ $opt->{sx_ad_col_num} };
        $opt->{sx_dbh_to_bcp_temp} = $opt->_open_bcp( $opt->{sx_ad_temp_table}, $nc );
        return 1 if $opt->{sx_dbh_to_bcp_temp} == 1;

#callback for bcp
        my %ad_seen = ();
        my $cb      = sub { return sx_sendrow_temp( \@_, $opt, \%ad_seen ) };

#do it. callback counts rows
        $sql = $opt->{sx_xfer_source};
        $opt->_print("   bcping keys to $opt->{to_server} : $opt->{sx_ad_temp_table}\n") if $opt->{progress_log};
        $opt->_runsql( $dbh_from, $sql, [], $cb );

#!        $opt->{sx_dbh_from}->func( $opt->{sx_xfer_source}, [], $cb, 'nsql' );
        $DB_ERROR && sx_complain("error in bcp'ing to temp table (a)\n$DB_ERROR\n") && return 1;

#final batch
        my $numRowsAffected;
        $opt->{sx_dbh_to_bcp_temp}->blk_done( CS_BLK_ALL, $numRowsAffected );
        $DB_ERROR && sx_complain("error in bcp'ing to temp table (b)\n$DB_ERROR\n") && return 1;

#log message
        if ( $opt->{progress_log} ) {
            $opt->_print("   $opt->{sx_ad_temp_tab_count} keys transferred\n");
            $opt->_print("   creating index on temp table\n");
        }

#create index temp table
        $sql = $opt->{sx_ad_create_index};
        $opt->_runsql( $dbh_to, $sql, {}, undef );

#!        $opt->{sx_dbh_to_non_bcp}->func( $opt->{sx_ad_create_index}, {}, undef, 'nsql' );
        $DB_ERROR && sx_complain("unable to create temp table index\n$DB_ERROR\n") && return 1;

#run the delete
        if ( $opt->{progress_log} ) {
            $opt->_print("   auto_deleting rows in $opt->{to_server} : $opt->{to_table}\n");
            $opt->_print("   $opt->{sx_ad_delete_join}\n") if $opt->{echo};
        }
        $sql = $opt->{sx_ad_delete_cmd};
        my @res = @{ $opt->_runsql( $dbh_to, $sql, {}, undef ) };

#!        my @res = $opt->{sx_dbh_to_non_bcp}->func( $opt->{sx_ad_delete_cmd}, {}, undef, 'nsql' );
        $DB_ERROR && sx_complain("error in deleting rows\n$DB_ERROR\n") && return 1;

        $opt->{sx_ad_rows_deleted} = $res[0]->{tot_rows};
        my $loop = $res[0]->{loop};
        if ( $opt->{progress_log} ) {
            $opt->_print("   $opt->{sx_ad_rows_deleted} rows deleted\n");    # if $opt->{echo} && $loop>1;
        }

#destroy the temp table
        $sql = "drop table $opt->{sx_ad_temp_table}";
        @res = @{ $opt->_runsql( $dbh_to, $sql, [], undef ) };

#!        @res = $opt->{sx_dbh_to_non_bcp}->func("drop table $opt->{sx_ad_temp_table}", [], undef, 'nsql' );
        $DB_ERROR && sx_complain("error in dropping temp table\n$DB_ERROR\n") && return 1;

        if ( $opt->{progress_log} ) {
            $opt->_print("   auto_delete successful\n\n");    # if $opt->{echo} && $loop>1;
        }

#        my $db  = $opt->{sx_to_database};
#        my $tab = $opt->{sx_to_table};
#        my $xxx = scalar @{ $opt->{sx_to_info}->{$db}->{$tab}->{__COLNAMES__} };
#        print "3. db=$db, tab=$tab, xxx=$xxx\n";

#success
        return 0;
    }

#----
#parse a user hash
#-----
    sub sx_parse_user_hash {

#this is a string like the following:
#
#  '(key=>val, key=>val)'
#  '{key=>val, key=>val}'
#  real perl hashref
#  'filename' that contains hash
#
        my ( $uh, $option ) = ( shift, shift );
        my %uhash = ();
        my $err   = '';

#real perl hash reference
        if ( ref $uh eq 'HASH' ) {
            %uhash = %$uh;

#char list
        }
        elsif ( $uh =~ /^\s*\(/ ) {
            {
                no strict;
                local $SIG{__WARN__} = sub { warn "$_[0]\n" };
                %uhash = eval "$uh";
            }
            $err = $@;

#maybe char ref
        }
        elsif ( $uh =~ /^\s*\{/ ) {
            my $s = ();
            {
                no strict;
                local $SIG{__WARN__} = sub { };
                $s = eval "$uh";
            }
            $err = $@;
            unless ($err) {
                %uhash = %$s;
            }

#see if it's a file
        }
        elsif ( $uh =~ /[^\,\=]/ ) {
            open( F, "<$uh" ) or $err = "couldn't open <$uh>: $!";
            if ( !$err ) {
                my @lines = <F>;
                my $lines = join '', @lines;
                $lines = '(' . $lines if $lines !~ /^\s*\(/;
                $lines .= ')' if $lines !~ /\)\s*$/;
                {
                    local $SIG{__WARN__} = sub { };
                    %uhash = eval "$lines";
                }
                $err = $@;
                close(F);
            }

#something's wrong
        }
        else {
            $err = "can't parse $option";

        }

        return ( \%uhash, $err );
    }

#---
#
#---
    sub sx_from_file_map {

        my $self = shift;
        my $p    = $self->{from_file_map};

        my $db   = $self->{sx_to_database};
        my $tab  = $self->{sx_to_table};
        my @cols = @{ $self->{sx_to_colnames} };

        my %map = ();

#check if user specified a map. can be hashref, char string of list, for file
        if ($p) {

#parse the value. verify options has already verified no parsing error
            my ( $m, $err ) = sx_parse_user_hash( $p, '-from_file_map' );
            %map = %$m;

#check for accuracy
            my @nf = grep { !exists $map{$_} } @cols;
            if (@nf) {
                sx_complain("the following fields are in -to_table but are not mapped: @nf\n");
                return 1;
            }

#make sure all the columns in -to_table are mapped
            my %cols = ();
            @cols{@cols} = ();
            @nf = grep { !exists $cols{$_} } keys %map;
            if (@nf) {
                sx_complain("the following fields are in the map but not in -to_table: @nf\n");
                return 1;
            }

#it's quite ok not to map certain fields in the -from_source
#         @cols{values %map} = ();
#         @nf = grep { !exists $cols{$_} } 0 .. $#cols;
#         if (@nf) {
#            sx_complain("the following column numbers were not mapped (first column is 0): @nf\n");
#            return 1;
#         }

            $self->{sx_from_file_map}         = \%map;
            $self->{sx_from_file_map_indices} = [ @map{@cols} ];

        }
        else {
            $self->{sx_from_file_map}         = 0;
            $self->{sx_from_file_map_indices} = 0;
        }

        return 0;
    }

#-------
#
#-------
    sub sx_sendrow_final_batch {

        my $self = shift;

#commit last set of rows
        my $rc = 0;
        if ( $self->{sx_send_count_batch} > 0 ) {
            $rc = sx_sendrow_batch($self);    #<0 == bad, >=0 == good
            $rc = $rc == &CS_FAIL ? 1 : 0;
        }

#1 == error, 0 == success
        return $rc;
    }

#-----------------------------------------------------------------------
#auto_delete callback
#must return 1 on success (nsql requirement) 
#-----------------------------------------------------------------------
    sub sx_sendrow_temp {

#args
        my ( $r_row, $opt, $ad_seen ) = @_;

#pull out the key columns only
        my @bcp_row = @{$r_row}[ @{ $opt->{sx_ad_col_num} } ];

#only do unique rows
        my $distinct = join '', @bcp_row;
        return 1 if $ad_seen->{$distinct};
        $ad_seen->{$distinct} = 1;

#row count
        $opt->{sx_ad_temp_tab_count}++;

#send the row
        my $status_send = $opt->{sx_dbh_to_bcp_temp}->blk_rowxfer( \@bcp_row );
        $DB_ERROR && sx_complain("$DB_ERROR\n") && return 0;

#commit the row
        if ( $opt->{sx_ad_temp_tab_count} % $opt->{batchsize} == 0 ) {
            my $numRowsAffected;
            $opt->_print( '   ' . $opt->{sx_ad_temp_tab_count} . " keys transferred\n" ) if $opt->{echo};
            $opt->{sx_dbh_to_bcp_temp}->blk_done( CS_BLK_BATCH, $numRowsAffected );
            $DB_ERROR && sx_complain("$DB_ERROR\n") && return 0;
        }

        return 1;
    }

#-----------------------------------------------------------------------
#the actual callback - bcp version
#must return 1 on success (nsql requirement)
#-----------------------------------------------------------------------
    sub sx_sendrow_bcp {

#args
        my ( $r_row, $opt ) = @_;

        my $dbh = $opt->{sx_dbh_to_bcp};
        my ( $status_cb_pre, $status_cb_err_send, $status_cb_err_batch ) = ();
        my ( $status_send, $status_batch ) = ();


#---
#user-defined callback pre send
#---
        $status_cb_pre = 1;
        if ( ref( $opt->{callback_pre_send} ) eq 'CODE' ) {
            my $r_user_row = ();
            ( $status_cb_pre, $r_user_row ) = $opt->{callback_pre_send}->($r_row);

#>0  => use @row returned by user
            if ( $status_cb_pre > 0 ) {

                $r_row = $r_user_row;
            }

#<0  => skip row altogether
            elsif ( $status_cb_pre < 0 ) {
                $opt->{sx_send_count}++;
                $opt->{sx_send_count_batch}++;
                return 1;

#==0 => abort based on user
            }
            else {
                sx_complain("User-defined '-callback_pre_send' failed ($opt->{callback_pre_send}).\n");
                return 0;
            }

        }

#debug
        if ( ( $opt->{debug} & 0x02 ) != 0 ) {
            my $i = 0;
            for my $y (@$r_row) { $i++; $opt->_print("$i:\t<$y>\n"); }
        }

#---
#if -map is speficied, this will call for a possible re-ordering of fields
#---
        if ( $opt->{sx_from_file_map} ) {
            $r_row = [ @{$r_row}[ @{ $opt->{sx_from_file_map_indices} } ] ];
        }

#---
#null out identity columns if server is going to set them
#---
       if (exists $opt->{identity_column}) {
           $r_row->[ $opt->{identity_column} ] = undef;
       }

#---
#image columns are returned as strings in perl. #eg '151c2001ff34ac'  is
#obviously a string in hex - however when it comes back from perl via  a
#select statement it comes back in the form of a *character  string*  of
#hex digits. this code changes to its native chars.
#---
       for my $c ( @{ $opt->{binary_columns} } ) {

#lose the 0x business
         $r_row->[$c] = substr($r_row->[$c],2) if substr($r_row->[$c],0,2) eq '0x';

#convert to char
         $r_row->[$c] = pack("H*", $r_row->[$c]); 
       }

      



#---
#send row - will snag client errors
#---
#status_send will == 0 on errors as well as DB_ERROR being set.
        $DB_ERROR = ();
        $opt->{sx_send_count}++;
        $opt->{sx_send_count_batch}++;
        $status_send = 1;

#confirm number of columns in the source matches the target. ctlib v2.15 is presently core'ing on mismatch
        my ($l1, $l2) =  (scalar @$r_row, $opt->{sx_to_numcols});

#push undef to end of record data record less than target table.
        if($l1 < $l2) {
            push @$r_row, undef for 1 .. ($l2 - $l1);
        }

#signal error if data record greater than target table
        if( $l1 > $l2 ) {
            $DB_ERROR="number of columns in data record does not match number of columns in target table\n";
            $DB_ERROR_ONELINE=$DB_ERROR;
        }

#make the call to send the data
        if(!$DB_ERROR) { 
           if ( $dbh->blk_rowxfer($r_row) == CS_FAIL ) {
               $status_send = 0;
            }
        }
        $status_send = 0 if $DB_ERROR;


#save the row iff error_handling == 'retry'
        if ( $opt->{error_handling} =~ /^retry/i ) {
            push @{ $opt->{data_rows} }, {
                rn  => $opt->{sx_send_count},
                row => $r_row,
            };
        }

#check for failure on send
        if ( !$status_send ) {
            $opt->{sx_err_count}++;
            $opt->{sx_err_count_batch}++;
            $status_send = sx_sendrow_failure( $opt, $r_row );

        }
        else {
            $opt->{sx_succeed_count_batch}++;
        }

#commit
        $status_batch = 1;
        if ( $opt->{sx_send_count} % $opt->{batchsize} == 0 ) {
            $status_batch = sx_sendrow_batch($opt);
            $opt->{sx_send_count_batch}    = 0;
            $opt->{sx_resend_count_batch}  = 0;
            $opt->{sx_succeed_count_batch} = 0;
            $opt->{sx_err_count_batch}     = 0;
        }

#set return code
        return sx_sendrow_return( $opt, $status_send, $status_batch, $status_cb_pre );

    }

#-----------------------------------------------------------------------
#sendrow failure processing
#-----------------------------------------------------------------------
    sub sx_sendrow_failure {

        my $opt   = shift;
        my $r_row = shift;

        my $status_send     = ();
        my $pissant_warning = 0;

#squirrel the errors away
        $opt->{sx_save_db_error}         = $DB_ERROR;
        $opt->{sx_save_db_error_oneline} = $DB_ERROR_ONELINE;

#a) err send is a cb
        if ( ref( $opt->{callback_err_send} ) eq 'CODE' && $opt->{error_handling} !~ /^abort/i ) {
            my ( $status_cb_err_send, $u_row ) = $opt->{callback_err_send}->(
              DB_ERROR => $DB_ERROR,
              row_num  => $opt->{sx_send_count},
              row_ptr  => $r_row
            );

#if user indicated retry status- then send the (fixed-up) row again!
            if ($status_cb_err_send) {
                $opt->{sx_resend_count}++;
                $opt->{sx_resend_count_batch}++;
                my $rs = sx_sendrow_bcp( $u_row, $opt );
                $DB_ERROR    = ();    #clean-up error
                $status_send = 1;     #force success
            }
            else {
                $status_send = 0;
            }

#b) err send is a HASH
        }
        elsif ( ref( $opt->{callback_err_send} ) eq 'HASH' && $opt->{error_handling} !~ /^abort$/i ) {
            ${ $opt->{callback_err_send} }{ $opt->{sx_send_count} }->{msg} = $DB_ERROR;
            ${ $opt->{callback_err_send} }{ $opt->{sx_send_count} }->{row} = $r_row;
            $DB_ERROR    = ();
            $status_send = 1;

#c) no err cb - print offending row
        }
        else {

#regardless of -error_handling write to edf if specified; otherwise stderr
            if ( $opt->{error_data_file} ) {
                my $rn  = $opt->{sx_send_count};
                my $elf = $opt->{sx_error_data_file_fh};
                local ($") = "|";
                print $elf "#recnum=$rn, reason=$DB_ERROR_ONELINE\n@{$r_row}\n";

#print out the row smartly to stderr
            }
            else {
                $opt->{override_silent}++;
                my $n = $opt->{sx_send_count};
                sx_oversize_error( $opt, $r_row, $n, $DB_ERROR );
                $pissant_warning++ if $DB_ERROR_ONELINE =~ /oversized row/;
            }

#set return status
#  continue => plow ahead and skip this row
#  retry    => since callback defined, skip this row
#  abort    => stop now

            if ($pissant_warning) {
                $status_send = 1;
            }
            else {
                if ( $opt->{error_handling} =~ /^abort/i ) {
                    $opt->{GOT_UNRECOV_ERROR} = 1;
                    $status_send = 0;
                }
                else {
                    $status_send = 1;
                }
            }

        }

        return $status_send;

    }

#-----------------------------------------------------------------------
#print sybase error nicely
#-----------------------------------------------------------------------
    sub sx_error_tidy_msg {
        my $self = shift;

#      if (substr($DB_ERROR, 0,-1) !~ /\n/s ) {
        $self->_print("   error_message  : $DB_ERROR_ONELINE\n");

#      } else {
#         $self->_print("   error_message  : $DB_ERROR_ONELINE");
#      }
    }

#-----------------------------------------------------------------------
#print error detection status
#-----------------------------------------------------------------------
    sub _print_error_detection {
        my $self = shift;
        $self->_print("--------------\n");
        $self->_print("Error detected\n");
        $self->_print("   error_handling : $self->{error_handling}\n");
        $self->_print("   error_data_file: $self->{error_data_file}\n") if $self->{error_data_file};
        $self->_print("   rows read      : $self->{sx_send_count}\n");
        $self->sx_error_tidy_msg();
        $self->_print("   callback_err_send  = $self->{callback_err_send}\n")  if defined $self->{callback_err_send};
        $self->_print("   callback_err_batch = $self->{callback_err_batch}\n") if defined $self->{callback_err_batch};
        $self->_print("--------------\n");
    }

#-----------------------------------------------------------------------
#what to do on send batch failure
#-----------------------------------------------------------------------
    sub sx_sendrow_batch_failure {

        my $opt = shift;

        my $status_batch = ();

#squirrel the errors away
        $opt->{sx_save_db_error}         = $DB_ERROR;
        $opt->{sx_save_db_error_oneline} = $DB_ERROR_ONELINE;

#ABORT
        if ( $opt->{error_handling} =~ /^abort$/i ) {
            $opt->_print_error_detection();
            $status_batch = 0;
            $opt->{GOT_UNRECOV_ERROR} = 1;

#CONTINUE OR RETRY
        }
        elsif ( $opt->{error_handling} =~ /^continue/i || $opt->{error_handling} =~ /^retry/i ) {

#a) callback exists. returns status(1=resend batch, 0=abort batch) and a ref to the rows
            my $cb = $opt->{callback_err_batch};
            if ( ref($cb) eq 'CODE' ) {
                my ( $cb_status, $ref_row ) = $cb->(
                  DB_ERROR  => $DB_ERROR,
                  row_num   => $opt->{sx_send_count},
                  rows      => \@{ $opt->{data_rows} },
                  xfer_self => $opt
                );

                if ( $cb_status == 0 ) {
                    $status_batch = 0;
                }
                elsif ( $cb_status > 0 ) {
                    $status_batch = sx_sendrow_batch_of_size( $opt, $ref_row, $cb_status );
                }
                else {
                }
                $DB_ERROR = ();

#b) no callback
            }
            else {
                $status_batch = 0;
                $opt->_print_error_detection();

#@             sx_error_tidy_msg($opt);
#@              $DB_ERROR && $opt->_print( "$DB_ERROR\n");
                $opt->_print(
                    "blk_done error, -error_handling=$opt->{error_handling}, but no " . "-callback_err_batch defined\n" );
            }
        }

        return $status_batch;
    }

#-----------------------------------------------------------------------
#commit the rows
#-----------------------------------------------------------------------
    sub sx_sendrow_batch {

# returns -1 for failure, >=0 for success

        my $opt          = $_[0];
        my $dbh          = $opt->{sx_dbh_to_bcp};
        my $status_batch = -99;

#reset error flags before call to blk_done
        ( $DB_ERROR, $DB_ERROR_ONELINE, $DB_DEADLOCK ) = ();

#returns number of rows when it works, -1 on failure , or zero.
        my $numRowsAffected;
        $status_batch = $dbh->blk_done( CS_BLK_BATCH, $numRowsAffected );

#      print "****strange case status_batch=$status_batch\n" if $DB_ERROR && $status_batch == 0;

        if ( $status_batch != CS_SUCCEED || $DB_ERROR ) {
            $status_batch = sx_sendrow_batch_failure($opt);
        }
        else {
            $status_batch = sx_sendrow_batch_success( $opt, $numRowsAffected );
        }

#give back the storage
        print scalar localtime() . " undefing\n" if $opt->{debug};
        @{ $opt->{data_rows} } = undef                if $status_batch > 0;    #if $opt->{error_handling} =~ /^retry/i;
        print scalar localtime() . " done undefing\n" if $opt->{debug};

        return $numRowsAffected;
    }

#---
#
#---
    sub bcp_batch_error_handler {

#pull the args
        my %h = @_;
        my ( $err, $line_num, $row_ref, $opt ) = @h{qw/DB_ERROR row_num rows xfer_self/};

#return code definitions:
#      rc = 0  : abort
#      rc = 1  : resend and batch a record at a time
#      rc > 1  : resend but in one batch
#
        my $rc = 0;
        my ( $st, $md, $v ) = @{$opt}{qw/retry_deadlock_sleep retry_max retry_verbose/};

#deadlock error.
        my $deadlock = 1 if $err =~ /1205/m;

#        my $deadlock = 1 if $err =~ /2601/m; #testing. simulate deadlock error with dupe key error
        if ($deadlock) {
            my $nd = ++$opt->{sx_num_retry};
            if ( $nd > $md ) {
                $opt->_print("------\n");
                $opt->_print("max retries. aborting only this batch.\n\n");
                $opt->_print("------\n");
                $rc = 0;
            }
            else {

                if ($v) {
                    $opt->_print("------\n");
                    $opt->_print("Error on blk_done. It's a deadlock error! Sleeping for $st seconds\n");
                    $opt->_print("  $DB_ERROR_ONELINE\n");
                    $opt->_print("------\n");
                }
                sleep $st;
                $rc = 2;    #force no one-by-one error reporting
            }

#not a deadlock error. 
        }
        else {
            if ($v) {
                $opt->_print("------\n");
                $opt->_print(
                    "Error on blk_done. It's NOT a deadlock error. Setting batch-size to one and resending batch.\n");
                $opt->_print("  $DB_ERROR_ONELINE\n");
                $opt->_print("------\n");
            }
            $rc = 1;    #one at a time

#            $rc = 2; #testing

        }
        return ( $rc, $row_ref );
    }

#----
#resubmit the row
#-----
    sub sx_sendrow_batch_of_size {

#
#returns number of rows sent, >=1 success, <=0 bad
#
        my $opt           = shift;
        my $r_rows        = shift;
        my $new_batchsize = shift;

        my $x = scalar @$r_rows;

        my $rcount = 0;
        my $elf    = $opt->{sx_error_data_file_fh};
        my $dbh    = $opt->{sx_dbh_to_bcp};
        foreach my $hp ( @{$r_rows} ) {
            my ( $rn, $row ) = ( $hp->{rn}, $hp->{row} );
            next unless $row;    #for some reason an undefined row is being stored
            $rcount++;

            $opt->{sx_resend_count}++;
            $opt->{sx_resend_count_batch}++;

#send row again
            if ( $dbh->blk_rowxfer($row) == CS_FAIL ) {
                local ($") = "|";
                eval { print $elf "#recnum=$rn, reason=$DB_ERROR_ONELINE\n@$row\n"; };
                print "eval error=$@\n" if $@;

                next;
            }

#batch one by one only if batchsize is 1
            if ( $new_batchsize == 1 ) {
                my $numRowsAffected;
                my $status = $dbh->blk_done( CS_BLK_BATCH, $numRowsAffected );
                if ( $numRowsAffected != $new_batchsize ) {
                    $opt->{sx_err_count}++;
                    $opt->{sx_err_count_batch}++;
                    local ($") = "|";
                    print $elf "#recnum=$rn, reason=$DB_ERROR_ONELINE\n@$row\n";
                }
            }
        }

        my $num_good = ();
        if ( $new_batchsize == 1 ) {
            $num_good = $opt->{sx_resend_count_batch} - $opt->{sx_err_count_batch};

#        $DB_IN_ERR_HANDLER = 1;
            sx_sendrow_batch_success( $opt, $num_good );    #log message
                                                            #        $DB_IN_ERR_HANDLER = 0;

        }
        else {
            $num_good = sx_sendrow_batch($opt);

            $num_good = 0 if $num_good < 0;
            $DB_IN_ERR_HANDLER = 1;
            sx_sendrow_batch_success( $opt, $num_good );    #log message
            $DB_IN_ERR_HANDLER = 0;

        }

#log message
        return $num_good;

#       return   sx_sendrow_batch_success($opt, $num_good);
    }

#-----
#
#-----
    sub sx_sendrow_batch_success {

        my $opt          = shift;
        my $status_batch = shift;

        return $status_batch if $DB_IN_ERR_HANDLER;

        my $send_count = $opt->{sx_send_count};
        $opt->{sx_succeed_count} += $status_batch;
        if ( $opt->{progress_log} ) {
            my $suc  = $opt->{sx_succeed_count};
            my $res  = $opt->{sx_resend_count};
            my $fal  = $opt->{sx_err_count} - $res;
            my $bsuc = $opt->{sx_succeed_count_batch};
            my $bres = $opt->{sx_resend_count_batch};
            my $bfal = $opt->{sx_err_count_batch};

#if errors encountered then give a different log message. otherwise keep it simple
            if ($res) {
                $opt->{override_silent} = 1;
                $opt->_print("   $status_batch rows committed [$suc/$send_count] (retries=$bres, fails=$bfal)\n");
                $opt->{override_silent} = 0;
            }
            else {
                $opt->_print("   $status_batch rows committed [$suc]\n");
            }
        }

        return $status_batch;
    }

#-----------------------------------------------------------------------
#set the return code from bcp_sendow
#must return 1 for success (nsql thingy)
#-----------------------------------------------------------------------
    sub sx_sendrow_return {

        my $opt = shift;
        my ( $status_send, $status_batch, $status_cb_pre ) = @_;

        my $error = !( $status_send && $status_batch && $status_cb_pre );
        if ($error) {

#abort
            if ( $opt->{error_handling} =~ /^abort$/i ) {

#batch failure already logged message
                $status_batch && $opt->_print_error_detection();
                return 0;

#plow thru errrors if so set
            }
            else {
                $DB_ERROR = ();
                return 1;
            }

#clean return
        }
        else {
            return 1;

        }
    }

#-----------------------------------------------------------------------
#where to put messages
#-----------------------------------------------------------------------
    sub _print {

        my ( $self, $line ) = @_;

#we don't want to suppress print statements from SQL
        my ($pack2) = caller(2);

#some conditions must be overrieded like errors
        my $force = $self->{override_silent};

        if ( $pack2 eq "Sybase::CTlib" || !$self->{silent} || $force ) {
            ref( $self->{callback_print} ) eq 'CODE' ? $self->{callback_print}->($line) : print "$line";
        }
    }

#-----
#
#-----
    sub _dbiConnect {

        my $self     = shift;
        my $fromOrTo = shift;

        my ( $dbih, $dbiDSN, $dbd, $where );
        my ( $u,    $p,      $s,   $d, $a );

#FROM side
        if ( $fromOrTo =~ /from/i ) {
            $where = 'FROM';

            if ( $self->{from_dsn} =~ /^DBD/i ) {
                ( $u, $p, $s, $d, $a ) = @{$self}{qw/from_user from_password from_server from_database app_name/};
                $dbd = ( split /\./, $self->{from_dsn} )[1];
            }
            else {
                sx_complain("brain-damage. can't make dbi connection on non-DBI FROM source\n");
                return undef;
            }

#TO side
        }
        elsif ( $fromOrTo =~ /to/i ) {
            $where = 'TO';
            ( $u, $p, $s, $d, $a ) = @{$self}{qw/to_user to_password to_server to_database app_name/};
            $dbd = 'Sybase';    #sjs needs to be changed! I know. I know.

#error
        }
        else {
            sx_complain("brain-damage. bad dbiConnect call\n");
            return undef;

        }

        $a .= "_" . substr( $where, 0, 1 );

#set the dbi dsn value
        if ( $dbd =~ /^Sybase$/i ) {
            $dbiDSN = "dbi:$dbd:server=$s;hostname=$ENV{HOSTNAME}";
            $dbiDSN .= ";scriptName=$a";
            $dbiDSN .= ";database=$d" if $d;
        }
        elsif ( $dbd =~ /^DB2$/i ) {
            $dbiDSN = "dbi:$dbd:$s";
        }

#make the connection via DBI - we'll print our own error message
        $dbih = DBI->connect( $dbiDSN, $u, $p, { RaiseError => 0, PrintError => 0 } );
        $dbih || ( sx_complain("$where login error:\n$DB_ERROR(User=[$u], Pwd=[$p], Server=[$s])\n") && return undef );
        if ( $dbd =~ /Sybase/i ) {
            $dbih->{syb_err_handler} = sub { return $self->sx_error_handler_dbi(@_) };
            $dbih->{syb_show_sql}++;
            $dbih->{syb_show_eed}++;
            $dbih->do("set flushmessage on");
            $dbih->func( 'LONG', '_date_fmt' );    #need seconds + microseconds to xfer properly
                                                   #set imagesize if asked to
            my $imagesize = $self->{textsize} || 10_000_000;
            $dbih->do("set textsize $imagesize");

#use the above. this seems a little esoteric
#            $dbih->ct_options(CS_SET, CS_OPT_TEXTSIZE, $imagesize, CS_INT_TYPE);

        }

#turn this back on for paranoia sake
        $dbih->{PrintError} = 0;
        $dbih->{RaiseError} = 1;

        return $dbih;
    }

#---
#
#---
    sub _ctConnect {

        my ( $self, $fromOrTo ) = @_;
        my ( $u, $p, $s, $d, $a );

        if ( $fromOrTo =~ /from/i ) {
            ( $u, $p, $s, $d, $a ) = @{$self}{qw/from_user from_password from_server from_database app_name/};
            $a .= '_F';
        }
        else {
            ( $u, $p, $s, $d, $a ) = @{$self}{qw/to_user to_password to_server to_database app_name/};
            $a .= '_T';
        }

#specific error handlers
        $self->{current_err_handler} = ct_callback( CS_SERVERMSG_CB, sub { $self->sx_error_handler(@_) } );
        $self->{current_msg_handler} = ct_callback( CS_CLIENTMSG_CB, sub { $self->sx_message_handler(@_) } );

#charset. this effects all open connections, alas.
#      ?

#only set the hostname property for now. we may want to set packetsize later.
        my $props = { CON_PROPS => { CS_HOSTNAME => Sys::Hostname::hostname() } };

        my $dbh = Sybase::CTlib->new( $u, $p, $s, $a, $props );
        $DB_ERROR && sx_complain("[$fromOrTo] login error:\n$DB_ERROR(User=$u, Server=$s)\n") && return 1;

#use the right database if specified
        if($d) {
           $dbh->nsql("use $d");
           $DB_ERROR && sx_complain("unable to use database [$d].\n$DB_ERROR\n") && return 1;
        }

#binary/image/text size
        my $imagesize = $self->{textsize} || 32_000;
        my $r1 =$dbh->ct_options( CS_SET, CS_OPT_TEXTSIZE, $imagesize, CS_INT_TYPE );
        if($r1 != CS_SUCCEED) {
          sx_complain("unable to set textsize. text/image data may truncated\n");
        }

#date format - make it long so as milliseconds are present in the xfer
        my $r2 = cs_dt_info(CS_SET, CS_DT_CONVFMT, CS_UNUSED, CS_DATES_LONG);
        if ($r2 != CS_SUCCEED) {
          sx_complain("error setting datetime format to 'LONG'. Datetime precision will be lost\n");
        }

#numerics greater than 2 gig do not translate to int nor float correctly so we keep them in 
#their native format. 
        $dbh->{UseNumeric} = 1;


        return $dbh;

    }

#---
#
#---
    sub _connectNonBcp {
        my $self = shift;

#allows connect via CTlib for now since there seems to be some conflict
#using DBD::Sybase and Sybase::CTlib at the same time

        if ( $self->{CTLib} ) {
            return $self->_ctConnect(@_);

        }
        else {
            return $self->_ctConnect(@_);

#         return $self->_dbiConnect(@_);
        }

    }

#---
#
#---
    sub _tableDef {

        my ( $self, $dbih, $table ) = @_;

#for each line in the table file
        my ( $db_name, $own_name, $tab_name ) = split ( /\./, $table );
        $db_name  =~ s/\s+//g;
        $own_name =~ s/\s+//g;
        $tab_name =~ s/\s+//g;

#create the sql
        my $sql_string = <<EOF;
         select col_name    = c.name,
                type_name   = t.name,
                col_len     = c.length,
                col_order   = c.colid,
                ctype       = c.type,
                utype       = t.usertype,
                allownulls  = convert(bit, (c.status & 8)),
                prec        = c.prec,
                isIdentity  = convert(bit, (c.status & 0x80))
         from   $db_name.dbo.syscolumns c,
                $db_name.dbo.systypes t
         where  c.id = object_id('$db_name.$own_name.$tab_name')
                and c.usertype *= t.usertype
         order  by c.colid
EOF

#run the sql
        my @h_pointers = $self->_runsql( $dbih, $sql_string, {}, undef );
        $DB_ERROR && return undef;

#re-organize
        my %info = ();
        for my $col ( @{ $h_pointers[0] } ) {
            my $col_name = $col->{col_name};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_type}       = $col->{type_name};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_len}        = $col->{col_len};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_id}         = $col->{col_order};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_allownulls} = $col->{allownulls};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_prec}       = $col->{prec};
            $info{$db_name}->{$tab_name}->{$col_name}->{col_identity}   = $col->{isIdentity};

#if user-defined type, get underlying
            if ( $col->{utype} > 100 ) {

#i pulled this sql from sp_help
                my $sql = <<EOF;
               select  name
               from    $db_name.$own_name.systypes
               where   usertype < 100
                       and type=$col->{ctype}
                       and name not in ("sysname", "nchar", "nvarchar")
EOF
                my @name = $self->_runsql( $dbih, $sql, {}, undef );
                $DB_ERROR && return undef;

                $info{$db_name}->{$tab_name}->{$col_name}->{col_type}     = $name[0]->[0]->{name};
                $info{$db_name}->{$tab_name}->{$col_name}->{col_usertype} = $col->{type_name};

#not user-defined type
            }
            else {
                $info{$db_name}->{$tab_name}->{$col_name}->{col_usertype} = undef;

            }

        }

#add the list column names in the right order    
        @{ $info{$db_name}->{$tab_name}->{__COLNAMES__} } =
          sort { $info{$db_name}->{$tab_name}->{$a}->{col_id} <=> $info{$db_name}->{$tab_name}->{$b}->{col_id} }
          keys %{ $info{$db_name}->{$tab_name} };

        return \%info;
    }

#-----------------------------------------------------------------------
#prep for xfer
#-----------------------------------------------------------------------
    sub _prep_xfer {

#args
        my $self = shift;

#little sub to split on keyword GO
        my $split_on_go = sub {
            my $sql = shift;
            my $re  = qr/^\s*GO\s*\n/mi;
            my @s   = split $re, $sql;
            return @s > 1 ? \@s : $sql;
        };

#log into <from> db if appropriate
        my $dbh_from = ();
        if ( $self->{from_dsn} =~ /^DBD/i ) {

#            $dbh_from = $self->_dbiConnect('FROM');
            $dbh_from = $self->_connectNonBcp('FROM');
            $dbh_from || return 1;
        }

#squirrel it away
        $self->{sx_dbh_from} = $dbh_from;

#select from 'from' source
        my ($xfer_source) = ();

#from sql
        if ( $self->{from_sql} ) {
            $xfer_source = $split_on_go->( $self->{from_sql} );    #allow multiple batches

#file containing any sql
        }
        elsif ( $self->{from_script} ) {
            my $fn = $self->{from_script};
            open( FH1, "<$fn" ) or ( sx_complain("unable to open script: <$fn>, $!\n") && return 1 );
            $xfer_source = $split_on_go->( join '', <FH1> );    #allow multiple batches
            close(FH1);

#table
        }
        elsif ( $self->{from_table} ) {
            my $wc = $self->{where_clause} ? "where $self->{where_clause}" : '';
            $xfer_source = "select * from $self->{from_table} $self->{holdlock} $wc";

#perl codeRef or ArrayRef
        }
        elsif ( $self->{from_perl} ) {
            $xfer_source = $self->{from_perl};

#data file
        }
        elsif ( $self->{from_file} ) {
            my $fn = $self->{from_file};
            if ( !ref($fn) ) {
                if ( $fn =~ /\.gz$|\.zip$/i ) {
                    $xfer_source = new FileHandle "zcat $fn |" or sx_complain("unable to open file: <$fn>, $!\n")
                      and return 1;
                }
                else {
                    $xfer_source = new FileHandle "<$fn" or sx_complain("unable to open file: <$fn>, $!\n") and return 1;
                }
            }
            else {
                $xfer_source = $fn;
            }

        }

#squirrel it away
        $self->{sx_xfer_source} = $xfer_source;

#log into 'to' server (NON-BCP)
        my %to_info = ();

#        my $dbh_to  = $self->_dbiConnect('TO');
        my $dbh_to = $self->_connectNonBcp('TO');
        $dbh_to || return 1;

#header report
        if ( $self->{progress_log} ) {
            $self->_print("Xfer info\n");
            $self->_print("   -from => $self->{from_dsn}\n");
            $self->_print( "   -to   => dbd." . "$self->{to_source}.$self->{to_server}.$self->{to_table}\n" );
        }

#check that -to_table exists
        my @path = split ( /\./, $self->{to_table} );
        my $chk = "select count(*) from $path[0]..sysobjects where name = '$path[2]'";
        my @res = @{ $self->_runsql( $dbh_to, $chk, [], undef ) };
        ( $DB_ERROR || !$res[0] ) && sx_complain("Can't find to_table <$self->{to_table}>\n$DB_ERROR\n") && return 1;

#get to_table object info
        my $toInfo = $self->_tableDef( $dbh_to, $self->{to_table} );
        $self->{sx_to_info} = $toInfo;
        ( $self->{sx_to_database} ) = keys %{$toInfo};
        ( $self->{sx_to_table} )    = keys %{ $toInfo->{ $self->{sx_to_database} } };
        my @cols = @{ $self->{sx_to_info}->{ $self->{sx_to_database} }->{ $self->{sx_to_table} }->{__COLNAMES__} };
        sx_complain("brain-damage. No columns found in target table\n"), return 1 unless @cols;
        $self->{sx_to_colnames} = [@cols];
        $self->{sx_to_numcols} = scalar @cols;

#use right db
        if ( $self->{sx_to_database} ) {
            my $sql = "use $self->{sx_to_database}";
            my $rs  = $self->_runsql( $dbh_to, $sql, undef, undef );

#!           my $rs = $dbh_to_non_bcp->func("use $self->{sx_to_database}",  [], undef, 'nsql' );
            $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;
        }

#check to charset for unicode and iso
        $self->{sx_toCharSet} = $self->_checkCharSet( $dbh_to, 'TO');
        $self->{sx_fromCharSet} = $self->_checkCharSet( $dbh_from, 'FROM');


#squirrel away
        $self->{sx_dbh_to_non_bcp} = $dbh_to;

#check if delete flag specified
        $self->{delete_flag} && sx_delete_rows {$self} && return 1;

#check if truncate flag specified
        $self->{truncate_flag} && sx_truncate_table($self) && return 1;

#create auto_delete commands
        $self->{auto_delete} && sx_auto_delete_setup($self) && return 1;

#drop/recreate indices
        $self->{drop_and_recreate_indices} && $self->_drop_indices() && return 1;

#debug. calc num rows to be xferred
        if ( $self->{debug} && $self->{from_table} ) {
            $self->_print("calculating number for rows to transfer.\n");
            my $wc = "where $self->{where_clause}" if $self->{where_clause};
            my $sql_string = "select count(*) from $self->{from_table} $wc";
            $self->_print("$sql_string\n") if $self->{echo};
            my @status = @{ $self->_runsql( $dbh_from, $sql_string, [], undef ) };

#!            my @status = $dbh_from->func( $sql_string, [], undef, 'nsql' );
            $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;
            $self->_print("num rows: $status[0]\n");
        }

        return;
    }

#-----
#
#-----
    sub _checkCharSet {
        my ( $self, $dbh, $where) = @_;

#assume iso_1 if from source is not a database
        return 'iso_1' unless $dbh;

        my $sql  = qq/sp_configure "default character set id"/;
        my @data = $self->_runsql( $dbh, $sql, {}, undef );
        my $val  = $data[0]->[0]->{'Run Value'};
        my $str = 0;
        if ( $val == 190 ) {
            $str = 'utf8';
        }
        elsif ( $val == 1 ) {
            $str = 'iso_1'
        }
        else {
            my $swi = $where eq 'TO' ? '--to_server' : '--from_server';
            $self->_print("unknown charset on $swi: [$val]. Using iso_1\n");
            $str = 'iso_1';
        }
        return $str;
    }

#-----------------------------------------------------------------------
#make bcp connection
#-----------------------------------------------------------------------
    sub _open_bcp {

        my ( $self, $tab, $num_cols ) = @_;

        my $dbh = ();

#specific error handlers
        ct_callback( CS_SERVERMSG_CB, sub { $self->sx_error_handler(@_) } );
        ct_callback( CS_CLIENTMSG_CB, sub { $self->sx_message_handler(@_) } );

        my ( $u, $p, $s, $a, $cs ) = @{$self}{qw/to_user to_password to_server app_name sx_toCharSet/};

#bulk login connection property
        my $props = {};
        $props->{CS_BULK_LOGIN} = CS_TRUE;

#character set property. eg. iso vs. unicode
        $props->{CS_SYB_CHARSET} = $cs;

#used for increasing the peformance of xferring text/image columns
        $props->{CS_PACKETSIZE} = $self->{packetsize} if $self->{packetsize};

#hostname 
        $props->{CS_HOSTNAME} = Sys::Hostname::hostname(); 

#program name. 'T' for 'To' or 'Target'.
        my $programName = $a . '_T';

#make connection
        $dbh = Sybase::CTlib->new( $u, $p, $s, $programName, { CON_PROPS => $props } );
        $DB_ERROR && sx_complain("TO login error:\n$DB_ERROR(User=$u, Server=$s)\n") && return 1;

        my ($val, $rs);
        if($self->{sx_fromCharSet} =~ /iso_1/i && $self->{sx_toCharSet} =~ /utf8/i) {
           my $rs = $dbh->ct_con_props(CS_GET, CS_CHARSETCNV, $val, CS_INT_TYPE);
        }

#special checking for identity and image
        my %to_info = %{ $self->{sx_to_info} };
        my ( $idb, $itab ) = @{$self}{qw/sx_to_database sx_to_table/};
        my @sorted_fields    = @{ $to_info{$idb}->{$itab}->{__COLNAMES__} };


#set imagesize
        my $imagesize = $self->{textsize} || 32_000;
        $dbh->ct_options( CS_SET, CS_OPT_TEXTSIZE, $imagesize, CS_INT_TYPE );
#---
#image columns are returned as a *string* of hex digits in perl when using
#a select statement. we'll have to convert it back to chars on the sendrow.
#this code documents what columns to convert back.
#---
        my @sorted_binary = grep {$to_info{$idb}->{$itab}->{$_}->{col_type} =~ /(image|binary|timestamp)/ } @sorted_fields;
        my @binary_col_num = ();
        for my $c (@sorted_binary) {
          push @binary_col_num, grep { $sorted_fields[$_] eq $c  } 0 .. $#sorted_fields;
        }
        $self->{binary_columns} = [ @binary_col_num ];


#check identity column stuff
        my @sorted_identity  = grep { $to_info{$idb}->{$itab}->{$_}->{col_identity} } @sorted_fields;
        my @identity_col_num = ();
        for my $c (@sorted_identity) {
          push @identity_col_num, grep { $sorted_fields[$_] eq $c } 0 .. $#sorted_fields;
        }


#first one. remember id_column starts at one
        my ( $has_identity, $id_column ) = ( undef, undef );

#we want to carry over identity columns
        if ( scalar(@identity_col_num) > 0 && $self->{set_identity_insert} ) {
            ( $has_identity, $id_column ) = ( 1, $identity_col_num[0] + 1 );

        }

#we want server to set new identity columns
        elsif ( scalar(@identity_col_num) > 0 && !$self->{set_identity_insert} ) {
            ( $has_identity, $id_column ) = ( 0, $identity_col_num[0] + 1 );

#if this is set then we will ensure this column is set to undef on the blk_xfer. column number is base 0.
           $self->{identity_column} = $identity_col_num[0];

        }

#no identity column but the switch is set. that's okay...
        elsif ( !(scalar(@identity_col_num) > 0) && $self->{set_identity_insert} ) {
#            sx_complain("Identity column not found, but switch set_identity_insert specified\n") && return 1;
        }


#no identity and the switch isn't set and that's just fine
        elsif ( !(scalar(@identity_col_num) > 0) && !$self->{set_identity_insert} ) {

#no-op
        }


#initialize
        print "init: <$tab> <$num_cols>, <$has_identity>, <$id_column>\n" if $self->{debug};
        my $rc = $dbh->blk_init( $tab, $num_cols, $has_identity, $id_column );
        if ( $rc == CS_FAIL || $DB_ERROR ) {
            sx_complain("$DB_ERROR\n") && return 1;
        }

        return $dbh;

    }

#-----------------------------------------------------------------------
#create the auto_delete string
#-----------------------------------------------------------------------
    sub sx_auto_delete_setup {

#args
        my $opt = shift;
        return 0 unless $opt->{auto_delete};

#pull the necessary info off the options hash
        my %to_info = %{ $opt->{sx_to_info} };
        my ($db)    = keys %to_info;
        my ($table) = keys %{ $to_info{$db} };

        my $temp_db       = $opt->{scratch_db};
        my $del_batchsize = $opt->{auto_delete_batchsize};
        my $tmp_tab       = $opt->{sx_ad_temp_table} = "$temp_db..sybxfer$$";

        my $del_one_line = "delete $db..$table where";
        my $del_join     = "delete $db..$table from $db..$table a, $tmp_tab b where";

#create sql prefix
        my $crt_sql = "create table $tmp_tab(";

#get the columns specified by the user
        my @cols = split ( /[\ ,]+/, $opt->{auto_delete} );

        my $columns = ();

#loop thru the columns
        for my $c (@cols) {
            my ( $val, $ctype ) = ();

#if $c is all digits then its a column position
            my $cname = ();
            if ( $c =~ /^\d+$/ ) {
                ($cname) =
                  grep { $to_info{$db}->{$table}->{$_}->{col_id} == $c } @{ $to_info{$db}->{$table}->{__COLNAMES__} };
                sx_complain("couldn't find column #$c in $table\n"), return 1 unless defined $cname;
            }
            else {
                $cname = $c;
            }

#get datatype
            my $type    = $to_info{$db}->{$table}->{$cname}->{col_type} || sx_complain("unknown column: <$cname>\n");
            my $col_num = $to_info{$db}->{$table}->{$cname}->{col_id}   || sx_complain("unknown column: <$cname>\n");
            my $col_len = $to_info{$db}->{$table}->{$cname}->{col_len}  || sx_complain("unknown column: <$cname>\n");

#list of columns
            $columns .= "$cname,";

#perl is zero indexed
            $col_num--;
            push @{ $opt->{sx_ad_col_num} }, $col_num;

#add delimiters
            if ( $type =~ /date|time/i ) {
                $val   = qq/$cname = '\${row[$col_num]}'/;
                $ctype = $type;
            }
            elsif ( $type =~ /char/i ) {
                $val   = qq/$cname = '\${row[$col_num]}'/;
                $ctype = "$type($col_len)";
            }
            elsif ( $type =~ /binary/i ) {
                $val   = qq/$cname = 0x\${row[$col_num]}/;
                $ctype = "$type($col_len)";
            }
            else {
                $val   = qq/$cname = \${row[$col_num]}/;
                $ctype = $type;
            }

#make cmds
            $crt_sql .= " $cname $ctype null,";
            $del_join .= " a.$cname = b.$cname and";
            $del_one_line .= " $val and";
        }

#remove trailing syntax
        $columns      = substr( $columns,      0, -1 );
        $crt_sql      = substr( $crt_sql,      0, -1 ) . ") ";
        $del_join     = substr( $del_join,     0, -4 );
        $del_one_line = substr( $del_one_line, 0, -4 );
        my $crt_idx  = "create index ix_$$ on $tmp_tab ( $columns ) ";
        my $upd_stat = "update statistics $tmp_tab ";

#create the sql to delete the rows
        my $del_sql = sx_delete_sql( $del_join, $opt->{batchsize}, $opt->{silent} );

        $opt->{sx_ad_create_table} = $crt_sql;
        $opt->{sx_ad_create_index} = $crt_idx;
        $opt->{sx_ad_delete_cmd}   = $del_sql;
        $opt->{sx_ad_delete_join}  = $del_join;
        $opt->{sx_ad_upd_stat}     = $upd_stat;

        return 0;
    }

#-----------------------------------------------------------------------
#sql to delete rows
#-----------------------------------------------------------------------
    sub sx_delete_sql {

        my ( $del_line, $batchsize, $silent ) = @_;

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
         if ( \@n > 0 and $silent <> 1) print "   \%1! rows deleted.", \@n
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
        my @row     = @{ +shift };
        my $row_num = shift;
        my $error   = shift;

#ObjectInfo structure
        my %to_info = %{ $opt->{sx_to_info} };

        my ( $db, $tab ) = @{$opt}{qw/sx_to_database sx_to_table/};

#sort the fields by column order
        my @sorted_fields = @{ $to_info{$db}->{$tab}->{__COLNAMES__} };
        my @sorted_len    = map { $to_info{$db}->{$tab}->{$_}->{col_len} } @sorted_fields;
        my @sorted_type   = map { $to_info{$db}->{$tab}->{$_}->{col_type} } @sorted_fields;
        my @sorted_prec   = map { $to_info{$db}->{$tab}->{$_}->{col_prec} } @sorted_fields;

#check num columns in each
        my $to_nc   = scalar @sorted_fields;
        my $from_nc = scalar @row;

        $opt->_print("------------------\n");
        $opt->_print("Expanded error log\n");
        $opt->_print("   Error: $error");
        $opt->_print("   note : num columns in source ($from_nc) != num columns in target ($to_nc)\n") if $from_nc != $to_nc;
        $opt->_print("   row  : $row_num\n");
        $opt->_print("   table: $db.$tab definitions with values on right.\n");

#loop thru all the fields
        my $max = $to_nc > $from_nc ? $to_nc : $from_nc;
        for ( my $i = 0 ; $i < $max ; $i++ ) {

#from data
            my ( $val, $act_len, $form ) = ();
            if ( $i < $from_nc ) {
                $val     = $row[$i];
                $act_len = length $row[$i];
                $form    = "      %2i: %-20s\t%-10s\t<%s>\n";
            }
            else {
                $val     = "__not supplied__";
                $act_len = -1;
                $form    = "      %2i: %-20s\t%-10s\t%s\n";
            }

#to data
            my ( $fld_name, $dec_type, $dec_len ) = ();
            if ( $i < $to_nc ) {
                $fld_name = $sorted_fields[$i];
                $dec_type = $sorted_type[$i];
                $dec_len  = $dec_type =~ /numeric/ ? $sorted_prec[$i] : $sorted_len[$i];
            }
            else {
                $fld_name = "__missing__";
                $dec_type = "__missing__ ";
                $dec_len  = " ";
            }

#expanded messages
            my $msg = ();
            if ( $dec_type =~ /char/i && $act_len > $dec_len && $act_len >= 0 ) {
                $msg = "       *Column #" . ( $i + 1 ) . " actual length [$act_len] > declared length [$dec_len]\n";
                $opt->_print("$msg");

            }
            elsif ( $dec_type =~ /(int|float)/ && $act_len >= 0 ) {
                local $! = 0;
                my ( $test, $err ) = POSIX::strtod($val);
                if ($err) {
                    $msg = "       *Column #" . ( $i + 1 ) . " contains non-numeric data\n";
                    $opt->_print("$msg");
                }
            }

            $dec_len = '(' . $dec_len . ')' if $dec_type !~ /missing/i;
            my $line = sprintf $form, $i + 1, $fld_name, $dec_type . $dec_len, $val;
            $opt->_print($line);
        }
        $opt->_print("------------------\n");
        $opt->_print("\n");
        return 0;
    }

#-----------------------------------------------------------------------
#check arguments
#-----------------------------------------------------------------------
    sub _checkargs {

        my $self         = shift;
        my @user_options = @_;

#verify the options
        my %opt = sx_verify_options(@user_options);
        return 1 if exists $opt{1};

#if help or no options then give usage and bail
        if ( defined $opt{help} || ( $opt{sybxfer} && keys %opt == 1 ) ) {
            sx_usage( \%opt ), return 1;
        }

#set some defaults
#program_name in master..sysprocesses only 16 bytes long. need last two for sybxfer.
        $opt{app_name} = basename($0) unless defined $opt{app_name};
        $opt{app_name} = substr( $opt{app_name}, 0, 14 );
        $opt{progress_log} = 1 unless defined $opt{progress_log};
        $opt{holdlock} = $opt{holdlock} ? 'HOLDLOCK' : '';
        $opt{trim_whitespace} ||= 0;
        $opt{silent} ||= 0;

#if "U" specified, then make from and to equal to "user"
        $opt{from_user} ||= $opt{user} || $ENV{USER};
        $opt{to_user} ||= $opt{user}   || $ENV{USER};

#if "P" specified, then make from and to equal to "password"
        $opt{from_password} ||= $opt{password} || $opt{from_user};
        $opt{to_password} ||= $opt{password}   || $opt{to_user};

#if "S" specified, then make from and to server equal to "server"
        $opt{from_server} ||= $opt{server} || $ENV{DSQUERY};
        $opt{to_server} ||= $opt{server}   || $ENV{DSQUERY};

#if "T" specified, then set from and to tables 
        if ( $opt{table} ) {
            $opt{from_table} ||= $opt{table};
            $opt{to_table} ||= $opt{table};
        }

#if "D" specified, then set database
        if ( $opt{database} ) {
            $opt{from_database} ||= $opt{database};
            $opt{to_database} ||= $opt{database};
        }

#parse the --from_source switch
        my $rc;
        ( $rc, $opt{from_dsn} ) = $self->_parse_from_source( \%opt );
        $rc && return 1;

#if batchsize not specified then force it to 1000
        $opt{batchsize} = 1000 unless $opt{batchsize};

#make sure no ambiguity/problems with -to_table 
        if ( $opt{to_table} ) {
            my ( $ok, $source, $server, $db, $own, $tab ) = $self->_parse_path( \%opt, $opt{to_table} );
            if ($ok) {
                if ( !$opt{to_database} && !$db ) {
                    sx_complain("-to_table should be of the form [db.][owner.]table if no -to_database specified\n")
                      && return 1;
                }

                if ( !$opt{to_server} && !$server ) {
                    sx_complain("-to_table should be of the form [server.][db.][owner.]table if no -to_server specified\n")
                      && return 1;
                }

#we'll get to this later
#             if (!$opt{to_source} && !$source) {
#                 sx_complain("-to_table should be of the form [source.][server.][db.][owner.]table if no -to_source specified\n") 
#                 && return 1; 
#             }

                $opt{to_database} = $db     || $opt{to_database};
                $opt{to_server}   = $server || $opt{to_server};
                $opt{to_source}   = $source || $opt{source} || 'Sybase';
                if ($own) {
                    $opt{to_table} = "$opt{to_database}.$own.$tab";
                }
                else {
                    $opt{to_table} = "$opt{to_database}..$tab";
                }
            }
            else {
                sx_complain("couldn't parse -to_table. form should be [db.][owner.]table\n") && return 1;
            }
        }
        else {
            sx_complain("-to_table MUST be specified\n") && return 1;
        }

#make sure no ambiguity/problems with -from_table 
        if ( $opt{from_table} ) {
            my ( $ok, $source, $server, $db, $own, $tab ) = $self->_parse_path( \%opt, $opt{from_table} );
            if ($ok) {
                if ( !$opt{from_database} && !$db ) {
                    sx_complain("-from_table should be of the form [db.][owner.]table if no -from_database specified\n")
                      && return 1;
                }

                if ( !$opt{from_server} && !$server ) {
                    sx_complain(
                        "-from_table should be of the form [server.][db.][owner.]table if no -from_server specified\n")
                      && return 1;
                }

#we'll get to this later
#             if (!$opt{from_source} && !$source) {
#                 sx_complain("-from_table should be of the form source.server.db.[owner].table if no -from_source specified\n") 
#                 && return 1; 
#             }

#@                $opt{from_database} = $db     || $opt{from_database};
#@               $opt{from_server}   = $server || $opt{from_server};
#@                $opt{from_source}   = $source || $opt{from_source} || 'Sybase';
#@                if ($own) {
#@                    $opt{from_table} = "$opt{from_database}.$own.$tab";
#@                }
#@                else {
#@                    $opt{from_table} = "$opt{from_database}..$tab";
#@                }
            }
            else {
                sx_complain("couldn't parse -from_table. form should be [db.][owner.]table\n") && return 1;
            }
        }

#error handling
        if ( defined $opt{error_handling} && !$opt{error_handling} =~ m/^(continue|abort|retry)/i ) {
            sx_complain("if -error_handling is specified it must be either abort/continue/retry\n") && return 1;
        }
        $opt{error_handling} = 'abort' unless defined $opt{error_handling};
        if ( $opt{error_handling} =~ /retry/i ) {

            if ( !$opt{callback_err_batch} ) {
                $opt{callback_err_batch} = \&bcp_batch_error_handler;
                sx_complain("Must specify -error_data_file if -error_handling = 'retry'\n"), return 1
                  unless ( $opt{error_data_file} );
            }
        }
        my $fn = $opt{error_data_file};

        if ($fn) {
            $opt{sx_error_data_file_fh} = new FileHandle ">$fn";
            sx_complain("Can't open <$fn> $!\n"), return 1 unless $opt{sx_error_data_file_fh};
        }

#checks
        if ( $opt{error_handling} =~ /abort/i && ( $opt{retry_max} || $opt{retry_verbose} || $opt{retry_deadlock_sleep} ) ) {
            sx_complain(
                "when -error_handling is 'abort', -retry_max, -retry_verbose, -retry_deadlock_sleep cannot be used\n");
        }

#default scratch db
        $opt{scratch_db}            = 'tempdb' unless $opt{scratch_db};
        $opt{auto_delete_batchsize} = 3000     unless defined $opt{auto_delete_batchsize};

#--
#deadlock retry
#--
        $opt{retry_max}            = 3   unless defined $opt{retry_max};
        $opt{retry_deadlock_sleep} = 120 unless defined $opt{retry_deadlock_sleep};
        $opt{retry_verbose}        = 1   unless defined $opt{retry_verbose};
        $opt{save_deadlock_retry}   = $Sybase::CTlib::nsql_deadlock_retrycount;
        $opt{save_deadlock_sleep}   = $Sybase::CTlib::nsql_deadlock_retrysleep;
        $opt{save_deadlock_verbose} = $Sybase::CTlib::nsql_deadlock_verbose;
        $Sybase::CTlib::nsql_deadlock_retrycount = defined $opt{retry_max}            ? $opt{retry_max}            : 3;
        $Sybase::CTlib::nsql_deadlock_retrysleep = defined $opt{retry_deadlock_sleep} ? $opt{retry_deadlock_sleep} : 120;
        $Sybase::CTlib::nsql_deadlock_verbose    = defined $opt{verbose}              ? $opt{verbose}              : 1;

#checks
        unless ( $opt{to_server} ) {
            sx_complain("Must specify -to server\n") && return 1;
        }

        unless ( $opt{to_table} ) {
            sx_complain("Must specify -to table, use db.[owner].table syntax for safety.\n") && return 1;
        }

        unless ( $opt{from_table} || $opt{from_script} || $opt{from_sql} || $opt{from_perl} || $opt{from_file} ) {
            sx_complain("Must specify -from table, -from_script, -from_sql, -from_perl or -from_file\n");
            return 1;
        }

#        if ( $opt{from_table} || $opt{from_script} || $opt{from_sql} ) { $opt{from_source} ||= 'Sybase' }

        if ( $opt{from_perl} ) {
            $opt{from_source} = 'PERL-CODEREF';
        }

        if ( $opt{from_file} && !ref( $opt{from_file} ) ) { $opt{from_source} = 'FLAT-FILE' }
        if ( $opt{from_file} && ref( $opt{from_file} ) ) { $opt{from_source} = 'FILE-HANDLE' }

        my $c = grep { defined $_ } @opt{qw/from_table from_script from_perl from_file/};
        if ( $c > 1 ) {
            sx_complain("-from_table, -from_script, -from_perl, -from_file are mutually exclusive\n") && return 1;
        }

        if ( ( $opt{from_table} || $opt{from_script} || $opt{from_sql} ) && !$opt{from_server} ) {
            sx_complain("Must specify -from_server if -from_table, -from_script or -from_sql is specified\n");
            return 1;
        }

        if ( $opt{from_file} && !$opt{from_file_delimiter} && !$opt{from_file_pack_format} ) {
            sx_complain("Must specify either -from_file_delimiter or -from_file_pack_format if -from_file is specified\n")
              && return;
        }
        $opt{from_file_delimiter} = quotemeta $opt{from_file_delimiter} if length $opt{from_file_delimiter} == 1;

        if ( $opt{from_file_delimiter} && !$opt{from_file} ) {
            sx_complain("Must specify -from_file if -from_file_delimiter is specified\n") && return 1;
        }

        if ( $opt{from_file_pack_format} && !$opt{from_file} ) {
            sx_complain("Must specify -from_file if -from_file_pack_format is specified\n") && return 1;
        }
        $c = grep { defined $_ } @opt{qw/from_file_delimiter from_file_pack_format/};
        if ( $c > 1 ) {
            sx_complain("-from_file_delimiter, -from_file_pack_format are mutually exclusive\n") && return 1;
        }

        $c = grep { defined $_ } @opt{qw/auto_delete delete_flag truncate_flag/};
        if ( $c > 1 ) {
            sx_complain("-auto_delete, -delete_flag and -truncate_flag are mutually exclusive\n") && return 1;
        }

#----
#check -from_file_map syntax
#----
        my $err = ();
        $opt{from_file_map} and ( undef, $err ) = sx_parse_user_hash( $opt{from_file_map}, '-from_file_map' );
        if ($err) {
            sx_complain(<<EOF);
error parsing -from_file_map, err=$err

syntax is:  -from_file_map [hashref | string | filename | 0]
   * hashref  => is a perl hash ref

   * string   => is of the form '(col=>pos, col=>pos, ...)'
                 where col is column name in -to_table and
                 pos is field number in input stream
                 first position is zero NOT one

   * filename => is name of file containing above string

   * 0        => same as -NOfrom_file_map

   one of the above values must be specified if this switch
   is used
EOF
            return 1;
        }

#---
#check -drop_and_recreate_indices
#---
        my ( %dari, $dari ) = ();
        if ( defined $opt{drop_and_recreate_indices} && $opt{drop_and_recreate_indices} !~ /^[01]$/ ) {
            ( $dari, $err ) = sx_parse_user_hash( $opt{drop_and_recreate_indices}, '-drop_and_recreate_indices' );
        }

        if ( !$err && $dari ) {
            %dari = %$dari;
            !exists $dari{syts}   and $err = "key 'syts' not found";
            $dari{syts} && !exists $dari{source} and $err = "key 'source' not found";

#defaults
            $dari{logfile} = 'stdout' unless defined $dari{logfile};
            $dari{logfile} = '/dev/null' if $dari{logfile} eq '0';
            $dari{sytsUser} = $opt{to_user}   unless defined $dari{sytsUser};
            $dari{sytsPwd}  = $dari{sytsUser} unless defined $dari{sytsPwd};
            $dari{withSortedData} = 0 unless defined $dari{withSortedData};
        }

#print error
        if ($err) {
            sx_complain(<<EOF);
error parsing -drop_and_recreate_indices, err=$err

syntax is:  -drop_and_recreate_indices [hashref | string | filename | 0 | 1]
   * 1         => same as -drop_and_recreate_indices

   * 0         => same as -NOdrop_and_recreate_indices

   * hashref   => is a perl hash ref

   * string    => is of the form: 
                  '(syts=>1/0, source=>"server.database", logfile=>"filename", sytsUser=>user, sytsPwd=>pwd, withSortedData=>0/1)'
                  syts indicates to use syts
                  server.database is where the -to_table exists with indices.
                  filename is the logfile. omit if stdout desired.
                  user is the syts user. default is -to_user.
                  pwd is the syts pwd. default is user.

EOF
            return 1;
        }

#squirrel away
        if (%dari) {
            $opt{sx_drop_and_recreate_indices} = \%dari;
        }
        else {
            $opt{sx_drop_and_recreate_indices} = { syts => 0 };
        }

#auto delete
        if ( $opt{auto_delete} && !$opt{from_table} ) {
            sx_complain("switch -auto_delete can only be used with -from_table\n");
            return 1;
        }

        return %opt;
    }

#-------------------------------------------------------
#parse source path
#-------------------------------------------------------
    sub _parse_path {
        my ( $self, $opt, $path ) = @_;

        my @parts = split /\./, $path;
        my ( $ok, $source, $server, $db, $own, $tab );
        if ( @parts <= 5 ) {
            ( $source, $server, $db, $own, $tab ) = @parts if @parts == 5;
            ( $server, $db, $own, $tab ) = @parts if @parts == 4;
            ( $db, $own, $tab ) = @parts if @parts == 3;
            ( $own, $tab ) = @parts if @parts == 2;
            ($tab) = @parts if @parts == 1;
            $ok = 1;
        }
        else {
            $ok = 0;
        }
        return ( $ok, $source, $server, $db, $own, $tab );

    }

#-----------------------------------------------------------------------
#confirm options and load massaged options
#-----------------------------------------------------------------------
    sub sx_verify_options {

        my @user_settings = @_;

#need to preserve order for options processing
        my %user_settings = ();
        tie %user_settings, "Tie::IxHash";

        my $i = 0;
        while ( $i < @user_settings ) {
            my ( $k, $v ) = ( $user_settings[$i], $user_settings[ $i + 1 ] );

#this means flag style option if the next option starts with a '-'
            if ( $v =~ /^\-\w/ || $i == $#user_settings && $k =~ /^\-\w/ ) {
                $v = 1;
                $i++;
            }
            else {
                $i += 2;
            }
            $user_settings{"$k"} = $v;

        }

#the list of options
        my @valid_options =
          qw/
          help|h|?:s

          from_source|fx=s
          from_server|fs=s
          from_user|fu=s
          from_password|fp=s
          from_database|fd=s

          from_table|ft=s
          from_script=s
          from_sql=s
          from_perl=s
          from_file|ff=s
          from_file_delimiter|ffd=s
          from_file_map|ffm|map:s
          from_file_pack_format|ffpf=s

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
          holdlock|hl:s
          trim_whitespace|tw:s
          timeout|to=i
          drop_and_recreate_indices|dari:s
          copy_source_indices|csi!
          set_identity_insert|sii:s
          textsize|txs:s
          packetsize|ps:s

          scratch_db=s
          auto_delete=s
          auto_delete_batchsize|adb=i

          debug=s
          echo:s
          silent:s
          progress_log|verbose:s
          app_name|an=s

          error_handling|eh=s
          error_data_file|edf=s
          retry_max=s
          retry_deadlock_sleep|rds=s
          retry_verbose|rv=s

          callback_err_send=s
          callback_err_batch=s
          callback_pre_send=s
          callback_print=s

          sybxfer:s
          return:s
          method:s
          /;

        use vars qw/%real_options/;

        do {
            local $SIG{__WARN__} = sub { sx_complain("$_[0]") };

#load up ARGV for GetOptions
            %real_options = ();
            local @ARGV = %user_settings;
            Getopt::Long::Configure(qw/no_ignore_case/);
            my $rs = GetOptions( \%real_options, @valid_options );
            $rs || return 1;
        };

        return %real_options;
    }

#-----------------------------------------------------------------------
#complain
#-----------------------------------------------------------------------
    sub sx_complain {

        my $msg = shift;
        warn "----------------\n";
        warn "$msg";
        warn "----------------\n";
        return 1;

    }

#-----------------------------------------------------------------------
#this is copied from nsql_error_handler. I might change it later.
#-----------------------------------------------------------------------
    sub sx_error_handler {
        my $self = shift;
        shift;    #dbh not needed.
        return $self->sx_error_handler_dbi(@_);
    }

#-----
#
#-----
    sub sx_error_handler_dbi {

        my ( $self, $number, $sev, $state, $line, $server, $proc, $msg ) = @_;

        $DB_DEADLOCK = 1 if $number == 1205 ? 1 : undef;
        $DB_ERROR         = undef;
        $DB_ERROR_ONELINE = undef;

#ignore these
# 5701    #changed db context
# 5703    #changed language
# 5704    #changed character set

        return 1 if grep { $_ == $number } ( 5701, 5703, 5704 );

#print messages are severity 10
        if ( $sev == 10 ) {
            print "$msg\n";

        }
        else {
            chomp($msg);
            $DB_ERROR = <<EOF;
Sybase::Xfer [Error Handler]
  Server   : $server
  Number   : $number
  Severity : $sev
  Line     : $line
  Text     : $msg
EOF
            $DB_ERROR_ONELINE = "SybaseError:server=$server:number=$number:text=$msg";
        }
        return 1;
    }

#-----------------------------------------------------------------------
#prints sql 'print' code via _print
#-----------------------------------------------------------------------
    sub sx_message_handler {

#   my ( $opt, $db, $message, $state, $severity, $text, $server, $procedure, $line ) = @_;

        my ( $self, $layer, $origin, $severity, $number, $msg, $osmsg, $dbh ) = @_;

#ignore these
# 5701    #changed db context
# 5703    #changed language
# 5704    #changed character set

        return CS_SUCCEED if grep { $_ == $number } ( 5701, 5703, 5704 );

#set DB_ERROR
        $DB_ERROR .= "\nOpen Client Message:\n";
        $DB_ERROR .= sprintf( "Message number: LAYER = (%ld) ORIGIN = (%ld) ", $layer,    $origin );
        $DB_ERROR .= sprintf( "SEVERITY = (%ld) NUMBER = (%ld)\n",             $severity, $number );
        $DB_ERROR .= "Message String: $msg\n";
        $DB_ERROR .= sprintf( "Operating System Error: %s\n", $osmsg ) if defined $osmsg;
        $DB_ERROR_ONELINE = "$number $msg";

#force nosilent on errors.
        $self->{override_silent}++;
        $self->_print("$msg\n");

        CS_SUCCEED;
    }

#-----
#
#-----
    sub _drop_indices_setup {

        my $self = shift;
        my ($dbh, $db, $tab) = @_;

        my %dari = %{ $self->{sx_drop_and_recreate_indices} };

        my $sql = <<EOF . "\n";
     declare \@db varchar(40), \@objname varchar(100), \@withSortedData int
     select \@db='$db', \@objname='$tab'
     select \@withSortedData=$dari{withSortedData}
EOF

        $sql = $sql . <<'EOF';
set nocount on
declare @keys varchar(255), @indid int, @nk int
declare @inddesc varchar(255), @idx_name varchar(40), @cluster varchar(20), @options varchar(50)
declare @uniq varchar(12), @dev varchar(40)
select @nk=0

--
--  this select will set @indid to the index id of the first index.
--
select @indid = min(indid)
from sysindexes
where id = object_id(@objname) and indid > 0 and indid < 255

--
--  If no indexes, return.
--
--if @indid is NULL print "17640, Object does not have any indexes."


--
--foreach index
--
while @indid is not NULL
begin
   select @idx_name=null, @uniq=null, @cluster=null, @options=null, @dev=null  
   select @nk=@nk+1

-- first we'll figure out what the keys are.
   declare @i int, @thiskey varchar(30), @sorder char(4), @lastindid int
   select @keys = "", @i = 1

--foreach key
   set nocount on
   while @i <= 31
   begin
       select @thiskey = index_col(@objname, @indid, @i)
       if (@thiskey is NULL) break
       if @i > 1 select @keys = @keys + "," 
       select @keys = @keys + @thiskey

--sort order
       select @sorder = index_colorder(@objname, @indid, @i)
       if (@sorder = "DESC") select @keys = @keys + "-" + @sorder

       select @i = @i + 1
   end
   select @keys=ltrim(@keys) 

--idx: clustered or nonclustered
   if @indid = 1 select @cluster = "clustered"

   if @indid > 1 begin
        if exists (select * from sysindexes i
                   where status2 & 512 = 512 and i.indid = @indid and i.id = object_id(@objname))
               select @cluster = "clustered"
         else
               select @cluster = "nonclustered"
    end

--idx: unique or not
    if exists (select * from master.dbo.spt_values v, sysindexes i
               where i.status & v.number = v.number
               and v.type = "I"
               and v.number = 2
               and i.id = object_id(@objname)
               and i.indid = @indid) begin

           select @uniq = 'unique'

           select @inddesc = @inddesc + ", " + v.name
           from master.dbo.spt_values v, sysindexes i
           where i.status & v.number = v.number
           and v.type = "I"
           and v.number = 2
           and i.id = object_id(@objname)
           and i.indid = @indid
    end

-- if this is a nonunique clustered index on dol tables
    else
-- 
-- allow_dup_rows
--
           if exists (
           select * from sysindexes i
           where status2 & 512 = 512
           and i.indid = @indid
           and i.id = object_id(@objname)) begin

                  select @options='allow_dup_rows'

                  select @inddesc = @inddesc + ", " + v.name
                  from master.dbo.spt_values v, sysindexes i
                  where v.type = "I"
                  and v.number = 64
                  and i.id = object_id(@objname)
                  and i.indid = @indid
           end


--
--  ignore_dupkey (0x01).
--
       if exists (
       select * from master.dbo.spt_values v, sysindexes i
       where i.status & v.number = v.number
       and v.type = "I"
       and v.number = 1
       and i.id = object_id(@objname)
       and i.indid = @indid) begin

                 select @options='ignore_dup_key'

                 select @inddesc = @inddesc + ", " + v.name
                 from master.dbo.spt_values v, sysindexes i
                 where i.status & v.number = v.number
                 and v.type = "I"
                 and v.number = 1
                 and i.id = object_id(@objname)
                 and i.indid = @indid
       end

--
--  See if the index is ignore_dup_row (0x04).
--
       if exists (
       select * from master.dbo.spt_values v, sysindexes i
       where i.status & v.number = v.number
       and v.type = "I"
       and v.number = 4
       and i.id = object_id(@objname)
       and i.indid = @indid) begin

                 select @options='ignore_dup_row'

                 select @inddesc = @inddesc + ", " + v.name
                 from master.dbo.spt_values v, sysindexes i
                 where i.status & v.number = v.number
                 and v.type = "I"
                 and v.number = 4
                 and i.id = object_id(@objname)
                 and i.indid = @indid
        end

--
--  See if the index is allow_dup_row (0x40).
--
        if exists (
        select * from master.dbo.spt_values v, sysindexes i
        where i.status & v.number = v.number
        and v.type = "I"
        and v.number = 64
        and i.id = object_id(@objname)
        and i.indid = @indid) begin

                  select @options='allow_dup_row'

                  select @inddesc = @inddesc + ", " + v.name   
                  from master.dbo.spt_values v, sysindexes i
                  where i.status & v.number = v.number
                  and v.type = "I"
                  and v.number = 64
                  and i.id = object_id(@objname)
                  and i.indid = @indid
        end

--  device
        select @dev = s.name
        from syssegments s, sysindexes i
        where s.segment = i.segment
        and i.id = object_id(@objname)
        and i.indid = @indid


--  index name
        select  @idx_name=name
        from    sysindexes
        where   id = object_id(@objname) and indid = @indid

        if(@withSortedData <> 0 and @cluster = 'clustered') 
        BEGIN
--            print "before = [%1!]", @options
            select @options=case when @options <> null 
                                then @options + ', sorted_data' 
                                else 'sorted_data'
                           end
--            print "after = [%1!]", @options
        END

        if @options <> null select @options='with ' + @options

--debug
--        print "create %1! %2! index %3! on %4!..%5!(%6!) %7! on %8!", 
--        @uniq, @cluster, @idx_name, @db, @objname, @keys, @options, @dev


--
-- return create_index, drop_index and idx_name
--
        select create_index='create '+@uniq+' '+@cluster+' index '+@idx_name+' on '+
                             @db+'..'+@objname+'('+@keys+') '+@options+' on '+"'"+@dev+"'",

               drop_index='drop index '+@objname+'.'+@idx_name, 

               idx_name=@idx_name

--
--  Now move @indid to the next index.
--
      select @lastindid = @indid
      select @indid = NULL
      select @indid = min(indid) from sysindexes
      where  id = object_id(@objname) and indid > @lastindid and indid < 255
end
--select num_indices=@nk
EOF

#run the sql
        my @idx = @{ $self->_runsql( $dbh, $sql, {}, undef ) };
        $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;


#get some info
        my ( $user, $pwd, $db, $server ) = @{$self}{qw/to_user to_password sx_to_database to_server/};
        my ( $from_server, $from_database ) = @{$self}{qw/from_server sx_from_database/};
        my ($tab) = keys %{ $self->{sx_to_info}->{$db} };
        @{ $self->{sx_to_table_indices}->{_names} } = ();

#check option settings
        my $dari = $self->{sx_drop_and_recreate_indices};
        my %dari = %$dari;

#rip thru the results of the sql depending if syts is specified
        if ( $dari{syts} ) {
            my $src              = $dari{source};
            my $syts_drop_base   = "syts -T$server.$db -U$dari{sytsUser} -P$dari{sytsPwd} -a 'drop index' ";
            my $syts_create_base = "syts -S$src -D$server.$db -U$dari{sytsUser} -P$dari{sytsPwd} -a 'create index' ";
            my $li               = ();

            for my $index (@idx) {
                my ( $ci, $di, $in ) = @{$index}{qw/create_index drop_index idx_name/};
                $li .= "$tab.$in,";
                push @{ $self->{sx_to_table_indices}->{_names} }, $in;
            }
            $li = substr( $li, 0, -1 );
            $self->{sx_to_table_indices}->{syts}->{create} = $syts_create_base . "-O'$li'";
            $self->{sx_to_table_indices}->{syts}->{drop}   = $syts_drop_base . "-O'$li'";

        }
        else {
            for my $index (@idx) {
                my ( $ci, $di, $in ) = @{$index}{qw/create_index drop_index idx_name/};
                $self->{sx_to_table_indices}->{$in}->{create_sql} = $ci;
                $self->{sx_to_table_indices}->{$in}->{drop_sql}   = $di;
                push @{ $self->{sx_to_table_indices}->{_names} }, $in;
            }
        }

        return 0;
    }


#----
#
#----
    sub sx_usage {

        my $self = shift;

#if not called from sybxfer don't bother.
        return 0 unless $self->{sybxfer};

        my $short_usage = <<EOF;
$0 usage:
   --help, -h                        for this help
   perldoc Xfer.pm                   for the full doc

from sources
   --from_table, -ft                 tablename in db..table syntax containing data
   --from_script                     file containing sql to run on from_server to get data
   --from_sql                        sql to run on from_server to get data
   --from_perl                       perl coderef to run to get data
   --from_file, -ff                  flat-file containing delimited fields

from login information
   --from_server, -fs                defaults to DSQUERY
   --from_user, -fu                  defaults to USER
   --from_password, -fp              defaults to -from_user
   --from_database, -fd              no default

to login information
   --to_server, -ts                  defaults to DSQUERY
   --to_user, -tu                    defaults to USER 
   --to_password, -tp                defaults to -to_user
   --to_database, -td                no default. 
   --to_table, -tt                   no default. [SERVER.][DATABASE.][OWNER.]TABLE syntax supported

from and to login information
   --server, -S                      sets -from_server and -to_server
   --user, -U                        sets -from_user and -to_user
   --password, -P                    sets -from_password and -to_password
   --database, -D                    sets -from_database and -to_database
   --table, -T                       sets -from_table and to_table. Use 'db..table' syntax

if using from_file
   --from_file_delimiter, -ffd <regex>           eg '\\s+' or '|'
   --from_file_pack_format, -ffpf <pack string>  eg 'a2 x4 a23'

more options
   --timeout,-to                     timeout value in seconds 
   --where_clause, -wc               where_clause to append to query if -from_table
   --delete_flag, -df                delete (with where_clause) from -to_table first
   --batchsize, -bs                  batchsize of deletes and bcp commit size
   --holdlock, -hl                   appends a holdlock to sql if -from_table
   --trim_whitespace, -tw            trims whitepspace before bcp
   --app_name, -an                   set program_name in sysprocesses
   --echo                            echo sql commands that run under the covers
   --silent                          quiet mode
   --progress_log, -verbose          print a log for every -batchsize 
   --debug                           programmer debug mode. use with caution.
   --set_identity_insert, -sii       use the identity values in the -source
   --packetsize, -ps                 packet size value. overrides target server config value.
   --textsize, -txs                  textsize value.  overrides target server config value.
                                    

   --from_file_map, -ffm <string | hash ref | file>  
                                     map table columns to field positions
                                     as string eg. '(cusip=>0, matdate=>2, name=>4)'

   --drop_and_recreate_indices, -dari [ <string | hash ref | file> ]
                                     drop indices pre-transfer; recreate post-transfer
                                     the value indicates to use MorganStanley's syts app. 

   --truncate_flag,-tf [<string | hash ref | file> ]
                                     truncate -to_table first
                                     the value indicates to use MorganStanley's syts app.
                       
autodelete info
   --auto_delete                     delete only records to be inserted
   --scratch_db                      scratch_db to hold temp tables. default=tempdb
   --auto_delete_batchsize, -adb     batchsize of autodelete
           
error handling
   --error_handling, -eh             continue | abort | retry - how to handle errors
   --error_data_file, -edf           file containing data and error msg of rows not xferred
   --retry_max                       how many times to retry the batch 
   --retry_verbose, -rv              whether or not notification desired on server errors when retrying
   --retry_deadlock_sleep, -rds      if deadlock server error (1205) how long to sleep between retries

api only options
   --callback_err_send  coderef      code to call if error on bcp_sendrow
   --callback_err_batch coderef      code to call if error on bcp_batch (commit)
   --callback_pre_send  coderef      code to call before row is sent to bcp_sendrow
   --callback_print     coderef      code to call when printing to stdout
EOF

        warn $short_usage;
        return 1;
    }

#-----
#truncate table
#-----
    sub sx_truncate_table {

        my $self = shift;

#special sql to use 'syts' to truncate table
        my ( $user, $pwd, $db, $server ) = @{$self}{qw/to_user to_password sx_to_database to_server/};
        my ($tab) = keys %{ $self->{sx_to_info}->{$db} };
        $self->_print("   -truncate_flag option set, truncating target table\n") if ( $self->{progress_log} );
        my $tv = $self->{truncate_flag};

        my ( %trunc, $err, $hp ) = ();
        if ( $tv && $tv =~ /^.$/ ) {
            %trunc = ( syts => 0 );
        }
        else {
            ( $hp, $err ) = sx_parse_user_hash($tv);
            %trunc = %$hp if ref($hp) eq "HASH";
        }

#check if necessary.
        sx_check_target( $self, 'truncate' ) || return 0;

#some defaults
        $trunc{logfile} = '/dev/null' if $trunc{logfile} eq '0';
        $trunc{logfile} = 'stdout' unless defined $trunc{logfile};
        $trunc{sytsUser} = $user unless defined $trunc{sytsUser};
        $trunc{sytsPwd} = $trunc{sytsUser} unless defined $trunc{sytsPwd};

#check for errors
        my @s = keys %trunc;
        if ( $err || @s != 4 || !defined $trunc{syts} || !defined $trunc{logfile} ) {
            sx_complain( "couldn't understand -truncate_flag.\n"
                . "Use syntax: -truncate_flag [ '(syts=>1, logfile=>filename), sytsUser=>User, sytsPwd=>Pwd' ] \n" );
            return 1;
        }

#truncate via syts
        if ( $trunc{syts} ) {
            my $out = $trunc{logfile} eq 'stdout' ? '' : ">$trunc{logfile}";
            my $syts_cmd   = qq/syts -T$server.$db -U$trunc{sytsUser} -P$trunc{sytsPwd}/;
            my $ksh_string = "$syts_cmd -a 'truncate table' -O '$tab' $out";
            return sx_run_shell_cmd($ksh_string);

#standard sql to truncate table
        }
        else {
            my $dbh_to     = $self->{sx_dbh_to_non_bcp};
            my $sql_string = "truncate table $tab";
            my @status     = @{ $self->_runsql( $dbh_to, $sql_string, [], undef ) };

#!            my @status = $dbh_to_non_bcp->func($sql_string,  [], undef, 'nsql' );
            $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;
            return 0;

        }
    }

#----
#
#----
    sub sx_check_target {

        my $self  = shift;
        my $which = shift;

        my $dbh_to  = $self->{sx_dbh_to_non_bcp};
        my $zerosql = "select cnt=count(*) from $self->{to_table}";
        my @res     = @{ $self->_runsql( $dbh_to, $zerosql, {}, undef ) };

#!        my @res = $self->{sx_dbh_to_non_bcp}->func($zerosql,  {}, undef, 'nsql' );
        $DB_ERROR && sx_complain("unable to get count on target table\n$DB_ERROR\n") && return 1;
        my $numrows = $res[0]->{cnt};
        if ( $numrows > 0 ) {
            return 1;
        }
        else {
            $self->_print("   target table empty. skipping $which.\n") if $self->{progress_log};
            return 0;
        }
    }

#-----------------------------------------------------------------------
#parse the --from_source value
#-----------------------------------------------------------------------
    sub _parse_from_source {

        my ( $self, $opt ) = @_;

#examples
#
#--from_source  \
#
#    {source => dbd:Sybase:<server>:<user>:<pwd>,  from => table=<tablename>, whereClause => wc, holdlock => 0/1 }
#    {source => dbd:Sybase:<server>:<user>:<pwd>,  from => sql=<sql> }
#    {source => dbd:Sybase:<server>:<user>:<pwd>,  from => file=<filename> }
#
#    {source => dbd:DB2:<server>:<user>:<pwd>,  from => table=<tablename>, whereClause => wc, holdlock => 0/1 }
#    {source => dbd:DB2:<server>:<user>:<pwd>,  from => sql=<sql> }
#    {source => dbd:DB2:<server>:<user>:<pwd>,  from => file=<filename> }
# 
#    {source => Perl, from => \&code  }
#    {source => Perl, from => \*fh }
#    {source => Perl, from => \@array }
# 
#    {source => File, from => xxx.bcp }
#
#
#
#returns a dsn like string
#
#     dbd.Sybase.<server>.<table>
#     dbd.Sybase.<server>.SQL.inline
#     dbd.Sybase.<server>.SQL.inFile.$fn
#     dbd.DB2.<server>.<table>
#     dbd.DB2.<server>.SQL.inline
#     dbd.DB2.<server>.SQL.inFile.$fn
#     Perl.CodeRef.<ref>
#     Perl.FHRef.<ref>
#     Perl.ArrayRef.<ref>
#     File.Name.<$fn>
#     Sql.Inline.<$sql>
#     Sql.File.Name.<$fn>

#parse the value. verify options has already verified no parsing error
        my $dsn = ();
        if ( $opt->{from_source} ) {
            my ( $fs, $err ) = sx_parse_user_hash( $opt->{from_source}, '-from_source' );

#look for key 'source'
            my $pref = "err: --from_source.";
            sx_complain("unable to parse --from_source. see documentation.") && return 1 if $err;
            sx_complain("$pref 'source' must be specified")                  && return 1 if !$fs->{source};
            sx_complain("$pref 'source' value error. Only dbd,  Perl, and File are supported.") && return 1
              if $fs->{source} !~ /^(dbd|Perl|File)/;

#key source =~ ^dbd
            my @s = ();

#DBD
            if ( $fs->{source} =~ /^dbd/i ) {

                my (@s) = split /[:=]/, $fs->{source};

#key from
                my ( $from, $fromValue ) = $fs->{from} =~ /(t|s|f)(?:\w*)[:=](.*)/i;
                $from = lc $from;
                if ( $fromValue =~ s/^\s*['"]// ) { $fromValue =~ s/['"]\s*$//; }
                my (@f) = split /[:=]/, $fromValue;

#backward compatiblity
                $opt->{from_server}     = $s[2];
                $opt->{from_user}       = $s[3];
                $opt->{from_password}   = $s[4];
                $opt->{from_scriptName} = $s[5];

                if ( $from eq 't' ) {
                    $opt->{from_table} = $fromValue;
                    $dsn = "$s[0].$s[1].$s[2].sql.table=$fromValue";
                }
                elsif ( $from eq 's' ) {
                    $opt->{from_sql} = $fromValue;
                    $dsn = "$s[0].$s[1].$s[2].sql.inline=<not echoed>";
                }
                elsif ( $from eq 'f' ) {
                    $opt->{from_script} = $fromValue;
                    $dsn = "$s[0].$s[1].$s[2].sql.inFile=$fromValue";
                }

#PERL
            }
            elsif ( $fs->{source} =~ /^Perl/i ) {
                $opt->{from_perl} = $fs->{from};    #arrayRef or codeRef
                if ( ref $fs->{from} eq 'CODE' ) {
                    $dsn = "Perl.CodeRef.$fs->{from}";
                }
                elsif ( ref $fs->{from} eq 'ARRAY' ) {
                    $dsn = "Perl.ArrayRef.$fs->{from}";
                }
                elsif ( ref $fs->{from} eq 'GLOB' ) {
                    $dsn = "Perl.FHRef.$fs->{from}";
                    $opt->{from_file} = $opt->{from_perl};
                    delete $opt->{from_perl};
                }
                else {
                    sx_complain(
                        "When -source is 'Perl', -from can only be codeRef, ArrayRef or FHref. bad value=<$fs->{source}>");
                }

#FILE
            }
            elsif ( $fs->{source} =~ /^File/i ) {
                $opt->{from_file} = $fs->{source};
                $dsn = "Perl.File.$opt->{from_file}";
                if ( ref $opt->{from_file} eq 'GLOB' ) {
                    $opt->{from_perl} = $opt->{from_file};
                    delete $opt->{from_file};
                    $dsn = "Perl.CodeRef.$opt->{from_perl}";
                }
            }
            return ( 0, $dsn );

#---
#backward compatibility. these options used with Sybase::Xfer
#---
        }
        elsif ( ref( $opt->{from_perl} ) eq 'CODE' ) {
            $dsn = "Perl.CodeRef.$opt->{from_perl}";
            return ( 0, $dsn );
        }
        elsif ( ref( $opt->{from_perl} ) eq 'ARRAY' ) {
            $dsn = "Perl.ArrayRef.$opt->{from_perl}";
            return ( 0, $dsn );
        }
        elsif ( $opt->{from_table} ) {
            $dsn = "dbd.Sybase.$opt->{from_server}.$opt->{from_table}";
            return ( 0, $dsn );
        }
        elsif ( $opt->{from_file} ) {
            $dsn = "File.Name.$opt->{from_file}";
            return ( 0, $dsn );

        }
        elsif ( $opt->{from_sql} ) {
            $dsn = "dbd.Sybase.$opt->{from_server}.sql.inline=<not echoed>";
            return ( 0, $dsn );

        }
        elsif ( $opt->{from_script} ) {
            $dsn = "dbd.Sybase.$opt->{from_server}.sql.inFile=$opt->{from_script}";
            return ( 0, $dsn );

        }
        return ( 0, undef );

    }

#-----
#
#-----
    sub sx_delete_rows {

        my $self = shift;

        my ( $dbh_to, $tab, $wc, $bs, $silent ) = @{$self}{qw/sx_dbh_to_non_bcp to_table where_clause batchsize silent/};
        my ( $log, $echo ) = @{$self}{qw/progress_log echo/};
        my $del_line = "delete $tab";
        $del_line .= " where $wc" if $wc;

        my $sql_string = sx_delete_sql( $del_line, $bs, $silent );
        $self->_print("   -delete_flag option set, deleting rows from target table\n") if $log;
        $self->_print("   $del_line (in a loop)\n") if $echo;

#check if any rows in target;
        sx_check_target( $self, "delete" ) || return 0;

        my $a = $Sybase::CTlib::nsql_deadlock_retrycount;
        my $b = $Sybase::CTlib::nsql_deadlock_retrysleep;
        my $c = $Sybase::CTlib::nsql_deadlock_verbose;

        $Sybase::CTlib::nsql_deadlock_retrycount = 100;
        $Sybase::CTlib::nsql_deadlock_retrysleep = 60;
        $Sybase::CTlib::nsql_deadlock_verbose    = 1;

        my @status = @{ $self->_runsql( $dbh_to, $sql_string, [], undef ) };

#        my @status = $dbh_to_non_bcp->func($sql_string,  [], undef, 'nsql' );
        $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;

        $Sybase::CTlib::nsql_deadlock_retrycount = $a;
        $Sybase::CTlib::nsql_deadlock_retrysleep = $b;
        $Sybase::CTlib::nsql_deadlock_verbose    = $c;

        return 0;
    }

#-----
#
#-----
    sub _drop_indices {

        my $self = shift;

#find the indices
        my $dbh = $self->{sx_dbh_to_non_bcp};
        my $db = $self->{sx_to_database};
        my $tab = $self->{sx_to_table};
        $self->_drop_indices_setup($dbh, $db, $tab) && return 1;

#log
        my ( $server, $tab, $log, $dbh_to ) = @{$self}{qw/to_server to_table progress_log sx_dbh_to_non_bcp/};
        my @idx_names = @{ $self->{sx_to_table_indices}->{_names} };
        local $" = ',';    #so the array list separates with commas.
        if (@idx_names) {
            $self->_print("   -drop_and_recreate_indices option set, dropping indices (@idx_names) on target table\n")
              if $log;
        }
        else {
            $self->_print("   -drop_and_recreate_indices option set,  no indices to drop on target table\n") if $log;
        }

        my %dari = %{ $self->{sx_drop_and_recreate_indices} };

#check if syts specified
        if ( $dari{syts} ) {
            my $out = $dari{logfile} eq 'stdout' ? '' : ">$dari{logfile}";
            my $ksh_cmd = $self->{sx_to_table_indices}->{syts}->{drop} . " $out";
            return sx_run_shell_cmd($ksh_cmd);

        }
        else {
            my $drop_sql = '';
            for my $in (@idx_names) {
                $drop_sql .= $self->{sx_to_table_indices}->{$in}->{drop_sql} . "\n";
            }

            if ($drop_sql) {
                $self->_runsql( $dbh_to, $drop_sql, undef, undef );
                $DB_ERROR && sx_complain("$DB_ERROR\n") && return 1;
            }
        }
        return 0;
    }

#----
#
#----
    sub _create_indices {

        my $self = shift;

        my @idx_names = @{ $self->{sx_to_table_indices}->{_names} };
        if ( $self->{progress_log} ) {
            $self->_print("\n");
            $self->_print("Post xfer processing\n");
            local $" = ',';    #so the array list separates with commas.
            $self->_print("   -drop_and_recreate_indices option set, creating indices (@idx_names) on target table\n");
        }

#this was setup in drop_indices
        my %dari = %{ $self->{sx_drop_and_recreate_indices} };

#syts
        if ( $dari{syts} ) {
            my $out = $dari{logfile} eq 'stdout' ? '' : ">>$dari{logfile}";
            my $ksh_cmd = $self->{sx_to_table_indices}->{syts}->{create} . " $out";
            return sx_run_shell_cmd($ksh_cmd);

#not syts
        }
        else {
            my $dbh_to = $self->{sx_dbh_to_non_bcp};
            for my $in (@idx_names) {
                my $sql = $self->{sx_to_table_indices}->{$in}->{create_sql};
                $self->_print("   creating index $in : $sql\n") if $self->{progress_log};
                $self->_runsql( $dbh_to, $sql, undef, undef );
                $DB_ERROR && sx_complain("Create Index error:\n$DB_ERROR\n") && return 1;
            }
        }

        return 0;
    }

#------
#run a shell script
#------
    sub sx_run_shell_cmd {
        return system( +shift );
    }

#================================================================
#================================================================
#================================================================
#================================================================

__END__


=head1 NAME

 Sybase::Xfer - Bcp data into a Sybae table from multiple sources

=head1 SYNOPSIS

 #!/usr/bin/perl
    use Sybase::Xfer;
    my %switches = (-from_server=>'CIA', -to_server=>'NSA', -table => 'x-files');
    my $h = Sybase::Xfer->new( %switches );
    my %status = $h->xfer(-return=>"HASH");
    print "xref failed. $status{last_error_msg}\n" unless $status{ok};

 #!/bin/ksh
    sybxfer -from_server 'CIA -to_server 'NSA' -table 'x-files'
    if [[ $? != 0 ]]; then print "transfer problems"; fi
 

=head1 DEPENDENCIES

 requires at least perl version 5.6

 Sybase::CTlib 

=head1 QUICK DESCRIPTION

Bulk copies data into a  Sybase  table.  Data  sources  can  include  a)
another Sybase table, b) the results of any Transact-Sql, c) the  return
values from a perl subroutine called repetitively, or d)  a  flat  file.
Comes with robust error reporting, handling, and intercepting.
 
Also comes with a command line wrapper, sybxfer.


=head1 DESCRIPTION

If you're in an environment with multiple servers and you don't want  to
use cross-server joins (aka using Component Integration  Services)  then
this module may be worth a look. It transfers data from  one  server  to
another server row-by-row in memory w/o using an intermediate file.

The source is not limited to another Sybase table though. Other  sources
are a) any transact-sql, b) a perl subroutine  called  repetitively  for
the rows, or c) a flat file.
 
It also has some smarts to delete rows in the target  table  before  the
data  is  transferred  by  several  methods.  See  the   -truncate_flag,
-delete_flag and -auto_delete switches.

The  transfer  is  controlled  entirely  by  the  switch  settings.  One
typically describes the I<from_source> and I<to_source> and, if  necessary,
how the transfer is proceed through other switches. 


=head1 ERROR HANDLING

This is most obtuse section and fields the most questions. The following
switches determine error handling behaviour and are discussed below. Granted
it's 7 options and the the permutations make it all that more confusing. In
time this too shall be repaired. But for now this is the way it stands.

 -error_handling       =>    abort | continue | retry
 -errror_data_file     =>    filename
 -retry_max            =>    n
 -retry_verbose        =>    1 | 0
 -retry_deadlock_sleep =>    secs
 -callback_err_send    =>    code ref
 -callback_err_batch   =>    code ref

and return values from the I<xfer> method.

First note that there are two two catagories of errors:

=over 5 

=item client errors

Client errors are reported on the bcp_sendrow. They include errors  like
sending a alpha character to a float field, sending  a  char  string  50
bytes long into a 40 byte field, or sending a null to a field that  does
not permit nulls. these errors can be fielded by -callback_err_send if
callback so desired.

=item server errors

Server errors are reported on the bcp_batch. This is  where  the  commit
takes place. These errors, for example,  include  unique  index  errors,
constraint errors, and deadlock errors. these errors can be fielded
by -callback_err_batch callback.

=back

what happens on an error then? that all depends on the switch settings.

=over 5

=item -error_handling 'abort'

on client errors or server errors the transfer stops dead in its tracks.
Any rows committed stay committed in the target table. Any rows sent but
not committed are lost from the target table.  

if -error_data_file is specified, then for client errors, the error message
and the data row in error is written to this file. for server errors,
error data file is ignored (I don't know which rows in the batch caused the error)
and instead the error message is written to stdout.

If no -error_data_file is specified then for client errors, an *expanded*
error message is written to stdout detailing the to_table datatype definitions and
the data being attempted to insert with commentary on datatype mismatches. for server
errors, once again, only an error message is written to stdout.

Setting -retry_max, -retry_verbose,  -retry_deadlock_sleep,  -callback_err_send, and 
-callback_err_batch have no effect.

=item -error_handling 'continue'

on client errors the row in error is skipped and  processing  continues.
on server errors all the rows in the current  batch  are  lost  and  not
transferred to the target table.  Processing  continues  with  the  next
batch. 

-error_data_file behaviour is the same as described above for abort. The
difference is that for client errors it's now possible to have more than
one error in the -error_data_file. This switch is ignored for server errors 
for the same reason as above in 'abort'.

Setting -retry_max, -retry_verbose and -retry_deadlock_sleep have
no effect.

However, if -callback_err_send is defined then it is called on client
errors and its return status determines whether or not to continue or
abort. Likewise, if -callback_err_batch is defined then it is called on
server errors and its return status detemines whether the xfer should
continue or abort. For details about these two switches refer to the
section elsewhere in this document describing each switch in detail.

=item -error_handling 'retry'

first off, -error_data_file must be specified so that client errors and
data rows can be logged.  On client errors, behaviour is exactly the
same as with 'continue'. ie. if -callback_err_send is defined then it
is called and its return status determines how to proceed. if no -callback_err_send
is defined then error message and data rows are written to -error_data_file and
processing continues.  On server errors, too, if -callback_err_batch is specified
then behaviour is the same as 'continue.' ie. it's return status determines
if the xfer continues or aborts. 

However, if  no  -callback_err_batch  is  specified  then  behaviour  is
dramitically different. First it checks -retry_verbose. If set  it  will
print a message to stdout indicating it's retrying. when a server  error
is encountered under this condition the module will test for a  deadlock
error (errno; 1205) specifically. if it's NOT a 1205 it will temporarily
set the batchsize to one and immediately resend  the  data  writing  any
failed rows to the -error_data_file then continuing on. if it IS a  1205
it'll print a further message about deadlock encountered if -retry_verbose
is set. Next, will sleep for -retry_deadlock_sleep seconds and then it
will resend the data again. It'll do this for -retry_max times. If still
after -retry_max times it's in an error state it'll abort.



NB. when 'retry', all the rows in the a batch are  saved  in  memory  so
should an error occur the rows can be 'retrieved' again  and  resent
with a batchsize of one . if the source table is large and  the  the
batchsize is large this can have negative performance impacts on the
transfer. After successful transfer of  all  rows  in  a  batch  the
memory is garbage collected and available for the next batch.


See discussion in next section about return value settings.


=back

=head1 AUTO DELETE

The -auto_delete switch is a way to indicate to *only* delete  the  rows
you're about to insert. Sometimes  the  -delete_flag  and  -where_clause
combination won't work - they cut too  wide  a  swath.  This  option  is
typically used to manually replicate a  table or to append to a table.  
-to_table  must  have  a unique index for this option to work.

=head1 RETURN VALUES

In scalar context, the method xfer returns the following:

  0 = success
 >0 = success w/ n number for rows not transferred
 -1 = abort. unrecoverable error.
 -2 = abort. interrupt.
 -3 = abort. timeout.

In array context, the method xfer returns the following:

 [0] = number of rows read from source
 [1] = number of rows transferred to target
 [2] = last known error message
 [3] = scalar return status (listed above)

if -return => 'HASH', the method xfer returns the following:

 {rows_read}        = number of rows read from target
 {rows_transferred} = number of rows transferred to target
 {last_error_msg}   = last error message encountered
 {scalar_return}    = scalar return listed above
 {ok}               = 1 if all rows were transferred regardless of retries or warnings
                        along the way.
                    = 0 if not

The sybxfer command line app returns to the shell the following:

 0 = success
 1 = abort. unrecoverable error.
 2 = abort. interrupt.
 3 = abort. timeout.
 4 = success w/ some rows not transferred






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

=item -from_perl (coderef | arrayref)

coderef is perl sub to call to get data. arrayref is an array of arrayrefs.

=item -from_file | -ff (filename)

name of file to read data from. can be reference to a fileHandle or if filename
ends in .gz or .zip it'll zcat the file first.

=back

=head2 TO INFO

=over 5

=item -to_server | -ts (string)

to server name

=item -to_database | -td (string)o

to database name

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

=item -truncate_flag | -tf [ 1 | string ]

truncate to_table. If 'string'  then it'll  use  a  Morgan  Stanley
only command to modify the meta data of a production database.

=item -delete_flag | -df

delete I<to_table> [where I<where_clause>]

=item -app_name | -an (string)

application name

=item -holdlock | -hl

adds I<holdlock> after the I<from_table> 

=item -trim_whitespace | -tw

strips trailing whitespace

=item -from_file_delimiter | -ffd "delimiter | regexp"

the delimiter used to separate fields. Used in conjunction with -from_file only.

=item -from_file_pack_format | -ffpf "pack format"

the 'pack' format to send to perl's unpack function to determine the fields 

=item -from_file_map | -ffm (hashref or string or file)

the positional mapping between field names in -to_table and fields in -from_file. 
First position begins at 0 (not one.) Ignored if source is -from_perl.

=item -timeout | -to  (secs)

timeout value in seconds before the transfer is aborted. Default is 0. No timeout.

=item -drop_and_recreate_indices | -dari [ < string | hash ref | filename > ]

drop all the indices on -to_table before the transfer begins and recreate all the
indices after the transfer is complete. DO NOT specify a value unless you wish to
use MorganStanley's I<syts> application.

=item -set_identity_insert | -sii (column)
                                                                                          
this switch should be used if the target table has  an  identity  column
and you want the values xferred from the source. The default is to  have
the server set new values. The first column starts at 1 (not zero.)

=item -packetsize | -ps (value)

I defer to sybase's documentation at 
https://login.sybase.com/detail/1,6904,954,00.html

Increase the packet size for  the  connection  On  most  platforms,  the
packet size defaults to 512 bytes. This default is provided for backward
compatibility. Larger packet sizes  2048  to  4096  bytes,  for  example
almost always yield better  performance.  This  is  generally  true  for
applications that fetch rows with  large  columns,  rows  with  lots  of
columns, or lots of rows with a few small columns. It is especially true
for applications that do bulk copy data transfers or  that  handle  text
and image data.

To increase a connection's packet size, set the CS_PACKETSIZE connection
property, via ct_con_props, prior to opening the  connection.  [this  is
what happens when you use this switch]


Note. You may have to reconfigure SQL Server to accept a larger  maximum
network packet size. See the SQL Server System Administration Guide  for
instructions on reconfiguring the maximum network packet size.

The following  trade-offs  come  into  play  when  the  packet  size  is
increased:

Increasing the packet size will increase the amount of  memory  required
by the client and the server. Any network will impose a  restriction  on
the maximum size of transmitted packets. On most networks, this  is  4K.
If the TDS packet size  is  larger  than  the  maximum  allowed  by  the
underlying network, then each TDS packet will actually be transmitted as
one  or  more  physical  network  packets.  This  can  adversely  affect
performance.



=item -textsize | -txs (value)

From the Sybase's Open Client-Library/C Reference Manual (online version),
chapter 2, Options:

specifies the value of the Adaptive Server global  variable  @@textsize,
which limits the size of text  or  image  values  that  Adaptive  Server
returns.

When setting this option, supply a parameter that specifies  length,  in
bytes, of the longest text or image value that  Adaptive  Server  should
return.

The default server configuration seems to be 32k. So if youre text/images
are larger than this you'll need to set this value.



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

I<string> is B<abort>, B<continue>, or B<retry>. Default is B<abort>.

=item -error_data_file | -edf (filename)

name of file to write the failed records into

=item -retry_max n

number of times to retry an bcp_batch error

=item -retry_deadlock_sleep

sleep time between calls to bcp_batch if deadlock error detected


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

from table name. Use a fully qualified path to  be  safe.  For  example,
pubs..titles. This removes the dependency on the  default  database  for
the -from_user value.

 -from_sql  <string>

send sql in <string> to -from_server and xfer results to -to_table.  For
example, 'select author_id, lname from pubs..authors' This  implies  the
-to_table has two columns of compatible  type  to  store  author_id  and
lname in it.

 -from_script <file> 

send sql  in  <file>  to  from_server  and  xfer  results  to  to_table.
Essentially the same as -from_sql except that it opens a file  and  gets
the sql from there.

 -from_perl <code-ref | array-ref> 

if code-ref then call repetitively for data to  transfer  to  -to_table.
code-ref must return the following array:  ($status,  $array_ref)  where
$status less than 0 to skip, equal 0 to end the  transfer,  and  greater
than 0 to continue. $arrary_ref is an array reference to the row to send.

if array-ref then ref contains array-refs to transfer each sub array-ref
being one row.

This switch is only available from the API. --from_file_map is ignored
when this switch is used.

 -from_file <file>

the file to read the actual data from. It can be a delimited file  or  a
fixed-field  file.  When  using  this  option  it  behaves  simliar   to
Sybase::BCP (in) and Sybase's own bcp. I've attempted to make the  error
handling  richer.  See  switches  -from_file_delimiter  (for   delimited
files),   -from_file_pack_format   (for   fixed   format   files)    and
-from_file_map (for changing the ordering). It can be a compressed  file
(.gz or .zip)  or  a  reference  that  is  sub-classed  from  "IO::File"
(usually a FileHandle but not always.) If you want to to get  fancy,  it
can be anything that is valid in perl's own 'open' statement such  as  a
named pipe. eg. "cut -d: -f1,5 /etc/passwd |"

=head2 from information

 -from_server | -fs  <server_name>   

The name of the server get the data from. Also see switch -server.

 -from_database | -fd  <database_name>   

The name of the I<from> database. Optional. Will execute a dbuse on the from server. Also
see switch -database.

 -from_user | -fu  <user_name> 

username to use on the from server. Also see switch -user.

 -from_password | -fp  <password> 

password to use on the from user. Also see switch -password.



=head2 to information

 -to_server | -ts <server_name> 

name of the to server. Also see switch -server.

 -to_database | -td <database_name>

The name of the I<to> database. Optional. If -to_table is not specified as db.[owner].table this
value will be pre-prepended to -to_table. Also see switch -database.


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

send  'select  *  from  I<from_table>  where  I<where_clause>'  to   the
I<from_server> when -from_table is a specified (otherwise this switch is
only used by the -delete_flag.) The default is to use  no  where  clause
thereby just sending 'select * from I<from_table>'. 
Also see -delete_flag switch.

 -truncate_flag | -tf  < 1 | user_string >

send  'truncate  table  I<to_table>'  to  the  I<to_server>  before  the
transfer begins. This requires dbo privilege,  remember.  If  you  don't
have dbo privilege and you want to remove all the rows from  the  target
table you have two options. Use the -delete_flag with  no  -where_clause
or truncate the table via an alternate method  (eg.  under  a  different
user name) before you run the transfer. Default  is  false.  

If user_string is specified, a hook into MorganStanley syts command can
be used.  user_string is specified as such:
 
   '{syts=>1, logfile=>file, sytsUser=>user, sytsPwd=>pwd}' 

   or a perl hash pointer to the above.

<file> defaults  to  stdout,  <user>  defaults  to  -to_user  and  <pwd>
defaults to <user>. Using 'user_string' cirmcumvents dbo  privilege  but
does require other syts privilege.


 -delete_flag | -df     

send 'delete I<to_table> [where I<where_clause>]'  to  the  I<to_server>
before the transfer begins. Also see -where_clause.  Default  is  false.
The  delete  will  be  performed  in  batches  in  the  size  given   by
-batch_size.


 -app_name | -an <val>    

name of program. Will append '_F' and '_T' to differentiate between  the
I<from>  and  I<to>  connections.  This  string  appears  in  the  field
program_name in the table  master..sysprocesses.  Will  truncate  to  14
characters if longer. Default is basename($0).

 -holdlock | hl

if  using  I<from_table>  then  this  switch  will  add  an   additional
B<holdlock>  after  the  table.  This  is  especially  useful   if   the
I<from_table> has the potential to be  updated  at  the  same  time  the
transfer is taking place. The default is noholdlock.

 -trim_whitespace | tw

Will set B<nsql>'s $Sybase::CTlib::nsql_strip_whitespace to  true  which
trims trailing whitespace before bcp'ing the data into target table.  If
a field is all whitepace  on  the  I<from>  table  then  the  result  of
trimming whitespace will be null. Therefore, the corresponding column on
the I<to> table needs to permit nulls. Default is false.

 -from_file_delimiter | -ffd <regex>

the delimiter to use to split  each  record  in  -from_file.  Can  be  a
regular expression. This switch is only valid with -from_file. Mutually
exclusive with -from_file_pack_format.

 -from_file_pack_format | -ffpf <pack format>

the pack format to apply (using unpack) to each input line. This  switch
is   only   valid   with    -from_file.    Mutually    exclusive    with
-from_file_delimeter.


 -from_file_map | -ffm <string, hashref or file)

the positional mapping between column names in -to_table and  positional
fields in source. First position in the source begins at 0. Examples:

specified as string: '(cusip=>2, matdate=>0, coupon=>5)'

specified as file:  'format.fmt'  #as long as the first non-whitespace char is not a '('
and the file 'format.fmt' contains
 cusip   => 2,
 matdate => 0,
 coupon  => 5

specified as a hashref: only via the api. reference to a perl hash.

Works with -from_sql, -from_table, -from_script, -from_file. Ignore on -from_perl.


 -timeout | -to <secs>

Timout value before the transfer aborts. Default is 0, ie.  no  timeout.
If the timeout is met then a scalar return code of -3  is  returned  (+3
via sybxfer script.)


 -drop_and_recreate_indices [ < string | hash ref | filename> ]

drop all the  indices  on  -to_table  before  the  transfer  begins  and
recreate all the indices after the transfer  is  complete.  Even  if  an
error has occurred an attempt will be made to recreate the  indices  (if
they've been dropped.) Note that unique indices may fail to be recreated
if the transfer resulted in  duplicates.  Also,  enough  space  must  be
available to recreate the indices.

DO NOT specify any value unless you want to use  Morgan  Stanley's  syts
application to drop and recreate the indices then specify the value as
one of the following:

=over 3

=item string

"(syts=>1, source=>'server.database', logfile=>'file', withSortedData=>0/1)"
where server.database is the location of the -to_table with the indices 
to create (typically on a test server.) if no logfile is 
specified then syts output goes to stdout.

=item hash ref

is the same as above only as a perl hashref

=item filename

is the same as above only in a file

=back

=head2 auto delete

The -auto_delete switch indicates that it should  be  ensured  that  any
rows  selected  from  the  I<from_table>  first  be  removed  from   the
I<to_table>.  This  differs  from  the  -delete_flag  and  -where_clause
combination that makes sweeping deletes. -auto_delete was added for  the
sole purpose of keeping the -to_table up-to-date  by  transferring  only
'changed' records from  the  -from_table  and  not  knowing  just  which
records changed apriori.

This switch presently only works with -from_table.

 -auto_delete [c1,c2...]

c1, c2, ... are the B<unique key column names>  into  I<to_table>.  When
this switch is in effect the module will create a table  in  -scratch_db
named sybxfer$$, $$ being the current process number, with  the  columns
c1, c2, ... Then it will bcp only those  columns  to  this  temp  table.
After that bcp is complete it will perform a delete (in a  loop  of  the
-auto_delete_batchsize) via a join by these columns in the temp table to
the I<to_table> so as to remove the rows, if any. After  the  delete  is
complete the temp table is dropped and all the columns specified will be
bcp'ed to the I<to_table>.

In essence, a simplisitic view is  that  the  following  is  effectively
done. 'delete I<to_table> where c1='cval1' and c2='cval2' ...' for every
row in the I<from_table> for values c1, c2, ... I mention this  only  in
this way because the explanation above seems either too convoluted (or I
can't explain it clearly enough.)


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

What to do upon encountering an error on bcp_sendrow or bcp_batch?

 -error_handling | -eh  <value>

Value can be B<abort>, B<continue> or B<retry>. I should probably have a threshold number but
I'll leave that until a later time.  When set to B<continue> the transfer will proceed 
and call any error callbacks that are defined (see below) and examine the return status of those
to decide what to do next. If no error callbacks are defined and -error_handling set
to B<continue> the module will print the offending record by describing the row by
record number, column-types and data values and continue to the next record. If -error_handling
is set to B<abort>, the same is printed and the xfer sub exits with a non-zero return
code. 

When value is B<retry> it attempts to behave like Sybase::BCP on error in bcp_batch. These 
are where server errors are detected, like duplicate key or deadlock error. 

By default, when -error_handling = B<retry>

=over 5

=item * 

if a deadlock error is detected on the bcp_batch the program will sleep for 
-retry_deadlock_sleep seconds and rerun bcp_sendrow for all the rows in the batch
and rerun bcp_batch once and repeat until no deadlock error or max tries.

=item * 

if a non-deadlock error is detected on the bcp_batch the program will attempt to behave
like Sybase::BCP by bcp_sendrow'ing and bcp_batch'ing every record. Those in error are written
to the -error_data_file.

=back

The default is B<abort>.

Here's a deliberate example of a syntax type error and an example of the output 
from the error_handler. Note This is detected on bcp_sendrow. See below for bcp_batch 
error trace.

#------
#SAMPLE BCP_SENDROW ERROR FORMAT
#------

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

#------
#SAMPLE BCP_BATCH ERROR_FILE
#------
if B<-error_handling> = I<retry> and an error occurs on the bcp_batch then the -error_data_file will
have this format.

#recnum=1, reason=2601 Attempt to insert duplicate key row in object 'sjs_junk1' with unique index 'a'
mwd|20010128|10.125
#recnum=2, reason=2601 Attempt to insert duplicate key row in object 'sjs_junk1' with unique index 'a'
lnux|20010128|2.875
#recnum=3, reason=2601 Attempt to insert duplicate key row in object 'sjs_junk1' with unique index 'a'
scmr|20010128|25.500
#recnum=4, reason=2601 Attempt to insert duplicate key row in object 'sjs_junk1' with unique index 'a'
qcom|20010128|84.625


 -retry_max <n>

n is the number of times to retry a bcp_batch when an error is detected. default is 3.

 -retry_deadlock_sleep <n>

n is the number of secords to sleep between re-running a bcp_batch when a deadlock error
is detected.


 -callback_err_send <code_ref | hash_ref>

sub to call if error detected on bcp sendrow. The module passes a hash as
seen below. It expects a 2 element array in return  ie. ($status, \@row).
$status true means continue, $status false means abort.
Can also be a hash_ref meaning to store the error rows keyed by row number.

It's called like this if I<code_ref>.  @row is the array of data:

your_err_sendrow_cb(DB_ERROR => $DB_ERROR,
                 row_num  => $row_rum,
                 row_ptr  => \@row );

It must return this:  

return ($status, \@row);

It stores the error like this if I<hash_ref>:

$your_hash{ $row_num }->{msg} = $DB_ERROR;
$your_hash{ $row_num }->{row} = \@row;




 -callback_err_batch <coderef>

sub to call if an error detected on bcp_batch. The module passes a hash as
seen below. It expects a 2 element array in return. ie. ($status, \@row).

$status == 0 indicates to abort the batch. 

$status == 1 indicates to resend and batch a row at a time and report 
errors to -error_data_file. 

$status > 1 indicates not to do a record by record send and batch but to resend
and batch once.

It's called like this:

     your_err_batch_cb(DB_ERROR  => $DB_ERROR, 
                       row_num   => $row_num,
                       rows      => \@row)

It must return this:  

     return ($status, \@row);

A word about @row above. It's got a tad more info in it.  @row is a array
of hash refs. where:

  $row[$i]->{rn}  == row number in input file,
  $row[$i]->{row} == the actual array of data


=head2 miscellaneous boolean flags

 -echo                   

echo sql commands running under the covers. Default is false.

 -silent                 

don't print begin & end/summary messages. Default is false.

 -progress_log           

print progess message on every bcp_sendbatch. Default is true.

 -debug                  

programmer debug mode. Default is false.
  0x01 = various debug messages 
  0x02 = print data in vertical mode before it's sent (and before map)




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

Incorporate logic to do the right thing when transferring data between Unicode and
ISO versions of the Sybase server.

=item *

Allow CTlib handle to be passed in lieu of from_user/from_pwd/from_server

=item *

add new option -ignore_warnings 'num | regexp'. (a way to deal with the 'oversized row'
message not being fatal in Sybase's bcp)

=item *

add a statistics summary in Xfer Summary report

=item *

print time on Progress Log report

=item * 

-auto_delete option should figure out the unique keys on -to_table thereby not
forcing the user to supply them.

=item *

add new option -direction to allow for bcp out

=item *

=back


=head1 BUGS

=over 5

=item * 

Deadlock retry features need to more thoroughly tested.

=item *

-to_table residing on anything other than Sybase 11.9 or above is
not supported. Morgan Stanley has an inhouse product called MSDB. This
is not supported for the -to_server.

=item *

the examples in the documentation reek badly and need to be rewritten.

=back

=head1 CONTACTS


=over 5

=item Author's e-mail

stephen.sprague@msdw.com

=item Michael Peppler's homepage

http://www.mbay.net/~mpeppler/
for all things perl and Sybase including Sybase::CTLib, Sybase::BCP and a 
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

Version 0.52, 10-SEP-2001
Version 0.51, 15-JUN-2001
Version 0.41, 15-APR-2001
Version 0.40, 01-MAR-2001
Version 0.31, 12-FEB-2001
Version 0.30, 10-FEB-2001
Version 0.20, 12-DEC-2000

=cut




1;
