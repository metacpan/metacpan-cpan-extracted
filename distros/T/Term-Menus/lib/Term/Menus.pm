package Term::Menus;

#    Menus.pm
#
#    Copyright (C) 2000-2018
#
#    by Brian M. Kelly. <Brian.Kelly@fullautosoftware.net>
#
#    You may distribute under the terms of the GNU Affero General
#    Public License, as specified in the LICENSE file.
#    <http://www.gnu.org/licenses/agpl.html>.
#
#    http://www.fullautosoftware.net/

## See user documentation at the end of this file.  Search for =head


our $VERSION = '3.024';


use 5.006;

my $menu_return_debug=0;

use strict;
use warnings;
## Module export.
require Exporter;
our @ISA = qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %term_input %test %Dump %tosspass %b
            %blanklines %parent_menu %Hosts %fa_code %canload %setsid
            %VERSION %SetTerminalSize %SetControlChars %find_Selected
            %clearpath %noclear %ReadKey %local_hostname %BEGIN %ISA
            %editor %__ANON__ %data_dump_streamer %ReadMode %filechk
            %fa_conf %transform_pmsi %termwidth %a %tm_menu %fa_code
            %DumpVars %DumpLex %fullauto %delete_Selected %timeout
            %pick %termheight %EXPORT_OK %ReadLine %fa_login %Menu
            %fa_host %fa_menu %abs_path $fa_code %log %FH %AUTOLOAD
            %get_all_hosts %hostname %GetSpeed %get_subs_from_menu
            %passwd_file_loc %run_sub %GetTerminalSize %escape_quotes
            %GetControlChars %numerically %rawInput %transform_sicm
            %return_result $MenuMap %get_Menu_map_count %MenuMap %facall
            %get_Menu_map %check_for_dupe_menus %EXPORT_FAIL %EXPORT
            %import $new_user_flag %new_user_flag %DB_ENV_DSYNC_LOG
            %DB_LOCK_PUT %DB_ST_IS_RECNO &DB_JOINENV %DB_LOCK_INHERIT
            %DB_VERB_REP_SYSTEM %DB_VERSION_MISMATCH %DB_ENV_STANDALONE
            %DB_LOG_VERIFY_ERR %DB_EVENT_REG_ALIVE %DB_XA_CREATE
            %DB_VERB_REP_ELECT %DB_REP_JOIN_FAILURE %DB_DELIMITER
            %DB_ENV_TXN %DB_ENV_RPCCLIENT %DB_MPOOL_CLEAN %DB_BTREEOLDVER
            %DB_TEMPORARY %DB_REPMGR_ACKS_ONE %DB_OLD_VERSION %padwalker
            %DB_TEST_POSTLOGMETA %DB_SET_RECNO %DB_SA_UNKNOWNKEY
            %DB_MAX_RECORDS %DB_LOCK_CONFLICT %DB_REP_NEWMASTER %banner
            %DB_LOCK_FREE_LOCKER %DB_POSITIONI %DB_VERB_FILEOPS
            %DB_LOCK_DEFAULT %DB_REP_ANYWHERE %DB_REPMGR_CONF_2SITE_STRICT
            %DB_AUTO_COMMIT %DB_TXN_NOWAIT %DB_STAT_LOCK_PARAMS %pw
            %DB_REP_CONF_NOWAIT %DB_OK_RECNO %DB_SEQ_WRAPPED %test_hashref
            %DB_MUTEX_LOCKED %DB_BEFORE %DB_EVENT_REP_MASTER_FAILURE
            %DB_QUEUE %DB_TXN_LOCK_OPTIMISTIC %DB_REP_UNAVAIL %eval_error
            %DB_FOREIGN_CASCADE %DB_NOOVERWRITE %DB_REP_CONF_AUTOINIT
            %LOGREC_OP %DB_RUNRECOVERY %DB_UNREF %DB_REPMGR_ISPEER
            %DB_VERIFY_BAD %DB_STAT_NOERROR %DB_ENV_LOG_AUTOREMOVE
            %DB_REP_PAGELOCKED %DB_ST_RECNUM %DB_ORDERCHKONLY %DB_JOINENV
            %DB_PRIORITY_VERY_LOW %DB_BTREEMAGIC %DB_LOCK_NOTHELD
            %DB_QAMOLDVER %DB_TEST_POSTSYNC %DB_LOG_AUTO_REMOVE
            %DB_BTREEVERSION %DB_GET_BOTHC %DB_ENV_RPCCLIENT_GIVEN
            %DB_CREATE %DB_ARCH_DATA %DB_VERB_WAITSFOR %DB_INIT_REP
            %DB_ENV_RECOVER_FATAL %DB_LOCK_GET_TIMEOUT %DB_STAT_CLEAR
            %DB_REP_FULL_ELECTION %DB_VERB_REP_LEASE %DB_REGISTERED
            %DB_APPLY_LOGREG %DB_REP_HANDLE_DEAD %DB_NOORDERCHK
            %DB_HEAP_RID_SZ %DB_VERIFY_PARTITION %DB_THREADID_STRLEN
            %DB_FIRST %DB_REPMGR_CONF_ELECTIONS %DB_SEQ_DEC
            %DB_REP_CONF_INMEM %DB_MUTEX_ALLOCATED %DB_JOIN_ITEM
            %DB_REP_CONF_NOAUTOINIT %DB_REPMGR_DISCONNECTED
            %DB_DUPSORT %DB_TXN_POPENFILES %DB_LOCK_RW_N
            %DB_TXN_NOT_DURABLE %DB_LOCK_NORUN %DB_REP_CONF_BULK
            %DB_STAT_SUBSYSTEM %DB_USERCOPY_GETDATA %DB_LOCK_TRADE
            %DB_COMMIT %DB_LOG_AUTOREMOVE %DB_MPOOL_TRY %DB_WRITEOPEN
            %DB_STAT_LOCK_CONF %DB_CLIENT %DB_ENV_TIME_NOTGRANTED
            %DB_REPFLAGS_MASK %DB_ENV_NOPANIC %DB_DUPCURSOR
            %DB_ENV_APPINIT %DB_LOGFILEID_INVALID %DB_LOCKMAGIC
            %DB_STAT_MEMP_HASH %DB_REP_FULL_ELECTION_TIMEOUT
            %DB_TXN_CKP %DB_QAMVERSION %DB_EVENT_REP_CLIENT
            %DB_NOCOPY %DB_TXNVERSION %LOGREC_PGLIST %DB_RENAMEMAGIC
            %DB_REP_DUPMASTER %DB_OPEN_CALLED %DB_PAGE_NOTFOUND
            %DB_VERB_DEADLOCK %DB_TXN_FORWARD_ROLL %DB_MULTIVERSION
            %DB_LOCK_TIMEOUT %DB_JOIN_NOSORT %DB_NEEDSPLIT
            %DB_SET_TXN_NOW %DB_TXN_OPENFILES %DB_TEST_POSTOPEN
            %DB_RECORD_LOCK %DB_TEST_PREOPEN %DB_RPC_SERVERVERS
            %DB_PRINTABLE %DB_VERB_REPLICATION %DB_MULTIPLE
            %DB_COMPACT_FLAGS %DB_KEYEXIST %DB_PRIORITY_VERY_HIGH
            %DB_NOERROR %DB_VERSION_RELEASE %DB_USE_ENVIRON
            %DB_LOG_VERIFY_DBFILE %DB_TEST_ELECTSEND %DB_TXN_REDO
            %DB_DURABLE_UNKNOWN %DB_ARCH_LOG %DB_QAMMAGIC
            %DB_TIMEOUT %DB_VERB_REPMGR_MISC %DB_REP_PAGEDONE
            %DB_LOCK_PUT_OBJ %DB_VERSION_FAMILY %DB_OK_BTREE
            %DB_MAX_PAGES %DB_RDONLY %DB_CACHED_COUNTS
            %DB_CKP_INTERNAL %DB_LOG_IN_MEMORY %DB_LOCK_GET
            %DB_AGGRESSIVE %DB_STAT_LOCK_LOCKERS %DB_LOCKVERSION
            %DB_PRIORITY_DEFAULT %DB_ENV_REP_MASTER %DB_FAILCHK
            %DB_ENV_LOG_INMEMORY %DB_LOG_VERIFY_FORWARD
            %DB_LOG_VERIFY_WARNING %DB_IGNORE_LEASE %DB_BACKUP_CLEAN
            %DB_ENV_DBLOCAL %DB_GET_BOTH_RANGE %DB_FOREIGN_ABORT
            %DB_REP_PERMANENT %DB_MPOOL_NOFILE %DB_LOG_BUFFER_FULL
            %DB_ENV_MULTIVERSION %DB_RPC_SERVERPROG %DB_MPOOL_DIRTY
            %DB_REP_NOBUFFER %DB_USE_ENVIRON_ROOT %DB_LOCK_CHECK
            %DB_PREV_NODUP %DB_ST_TOPLEVEL %DB_PAGEYIELD %DB_EXCL
            %DB_UPGRADE %DB_INORDER %DB_YIELDCPU %DB_ENV_DSYNC_DB
            %DB_REP_ELECTION %DB_LOCK_RIW_N %DB_PAGE_LOCK
            %DB_TXN_SYNC %DB_ST_DUPSORT %DB_LOG_SILENT_ERR
            %DB_MPOOL_UNLINK %LOGREC_PGDBT %DB_DIRECT %DB_CHKSUM
            %DB_ENV_OVERWRITE %DB_TXN_LOG_UNDO %DB_INIT_TXN
            %DB_REP_CHECKPOINT_DELAY %DB_TEST_ELECTVOTE2
            %DB_TEST_ELECTINIT %DB_EID_BROADCAST %DB_DELETED
            %DB_REPMGR_ACKS_QUORUM %DB_ENV_LOCKDOWN
            %DB_MUTEXDEBUG %DB_FREE_SPACE %DB_VERB_REGISTER
            %DB_MPOOL_EDIT %DB_NORECURSE %DB_TEST_ELECTVOTE1
            %DB_PRIORITY_LOW %DB_EVENT_REP_PERM_FAILED
            %DB_SET_RANGE %DB_FORCE %LOGREC_LOCKS %DB_RENUMBER
            %DB_REP_CONNECTION_RETRY %DB_MPOOL_PRIVATE
            %DB_SEQUENCE_OLDVER %DB_LOG_CHKPNT %DB_FREELIST_ONLY
            %DB_VERB_REP_MISC %DB_ENV_REGION_INIT %DB_RENUMBER
            %DB_TXN_BACKWARD_ROLL %DB_LOCK_ABORT %DB_LOG_RESEND
            %DB_ENV_REF_COUNTED %DB_DONOTINDEX %DB_NOMMAP
            %DB_LOCK_UPGRADE %DB_REP_STARTUPDONE %DB_NEXT_DUP
            %DB_ENV_OPEN_CALLED %DB_LOGVERSION_LATCHING
            %DB_REP_ELECTION_RETRY %DB_VERB_REP_TEST
            %DB_VERB_REP_MSGS %DB_debug_FLAG %DB_LOG_DSYNC
            %DB_DSYNC_LOG %DB_GET_BOTH_LTE %DB_TXN_LOG_VERIFY
            %DB_LOCK_RANDOM %DB_KEYEMPTY %DB_DIRECT_LOG
            %DB_LOG_ZERO %DB_ENV_REP_LOGSONLY %DB_NOSYNC
            %DB_LOG_VERIFY_INTERR %DB_SHALLOW_DUP %DB_SET
            %DB_LOCK_SET_TIMEOUT %DB_UPDATE_SECONDARY
            %DB_THREAD %DB_USERCOPY_SETDATA %DB_ASSOC_CREATE
            %DB_MUTEXLOCKS %DB_LOGOLDVER %DB_TXN_LOCK_MASK
            %DB_REGION_NAME %DB_NOLOCKING %DB_MPOOL_CREATE
            %DB_INIT_MPOOL %DB_CURLSN %DB_LOG_PERM %DB_WRITELOCK
            %DB_ENV_FAILCHK %DB_EVENT_REP_NEWMASTER
            %DB_JAVA_CALLBACK %DB_OVERWRITE_DUP %DB_RPCCLIENT
            %DB_ENV_CREATE %DB_ENV_THREAD %DB_PR_HEADERS
            %DB_TXN_APPLY %DB_WRITELOCK %DB_VRFY_FLAGMASK
            %DB_REP_LOCKOUT %DB_EVENT_NOT_HANDLED %DB_NEXT
            %DB_TIME_NOTGRANTED %DB_LOG_INMEMORY %LOGREC_Done
            %DB_LOG_DIRECT %DB_ALREADY_ABORTED %DB_INCOMPLETE
            %DB_MUTEX_LOGICAL_LOCK %DB_TXN_LOG_MASK %DB_PREV
            %DB_STAT_MEMP_NOERROR %DB_CL_WRITER %DB_DSYNC_DB
            %DB_ENV_TXN_NOWAIT %DB_REGISTER %DB_ODDFILESIZE
            %DB_FAST_STAT %DB_LOG_NOT_DURABLE %DB_CDB_ALLDB
            %DB_LOG_NOCOPY %DB_INIT_CDB %DB_RECORDCOUNT
            %LOGREC_DATA %DB_NEXT_DUP %DB_SET_LOCK_TIMEOUT
            %DB_PERMANENT %DB_TXN_LOG_REDO %DB_CHECKPOINT
            %DB_ENV_CDB_ALLDB %DB_EVENT_REP_JOIN_FAILURE
            %DB_LOG_VERIFY_VERBOSE %DB_LOGCHKSUM %DB_BTREE
            %DB_LOG_VERIFY_PARTIAL %DB_KEYFIRST %DB_EXTENT
            %DB_TXN_SNAPSHOT %DB_REP_ISPERM %DB_NOPANIC
            %DB_LOCK_UPGRADE_WRITE %DB_FOREIGN_CONFLICT
            %DB_MPOOL_NEW %DB_TXN_UNDO %DB_REGION_MAGIC
            %DB_PRIORITY_HIGH %DB_ENV_DIRECT_DB %LOGREC_HDR 
            %DB_RECOVER_FATAL %DB_LOCK_REMOVE %DB_LOGVERSION
            %DB_GID_SIZE %DB_PRIORITY_UNCHANGED %LOGREC_HDR
            %DB_LOGC_BUF_SIZE %DB_REVSPLITOFF %DB_LOCK_NOWAIT
            %DB_SEQUENTIAL %DB_REGION_ANON %DB_ENV_NOMMAP
            %DB_SEQUENCE_VERSION %DB_SYSTEM_MEM %DB_AFTER
            %DB_REP_ELECTION_TIMEOUT %DB_STAT_ALL %DB_APPEND
            %DB_HASHVERSION %DB_LOCK_OLDEST %DB_XIDDATASIZE
            %DB_VERIFY_FATAL %DB_ASSOC_IMMUTABLE_KEY
            %DB_SEQ_RANGE_SET %DB_REGION_INIT %DB_RECOVER
            %DB_LOCK_MAXLOCKS %DB_REP_CONF_DELAYCLIENT
            %DB_EVENT_REP_ELECTION_FAILED %DB_ENV_YIELDCPU
            %DB_OK_QUEUE %DB_MULTIPLE_KEY %DB_DIRECT_DB
            %DB_LOCK_DUMP %DB_TEST_PREDESTROY %DB_ENCRYPT 
            %DB_EID_INVALID %DB_LOCK_MINLOCKS %LOGREC_TIME
            %LOGREC_DBOP %DB_ENV_REP_CLIENT %DB_SPARE_FLAG
            %DB_TXNMAGIC %DB_LOCK_NOTEXIST %DB_REP_REREQUEST
            %DB_VERB_REP_SYNC %DB_NO_AUTO_COMMIT %DB_PR_PAGE
            %DB_EVENT_REP_DUPMASTER %DB_GET_BOTH %DB_HASH 
            %DB_TXN_BULK %DB_TEST_POSTLOG %DB_REP_LOGSONLY
            %DB_ENV_TXN_NOT_DURABLE %DB_POSITION %DB_RECNUM
            %DB_LOCKDOWN %DB_LOG_NO_DATA %DB_ST_DUPSET
            %DB_REP_HEARTBEAT_SEND %DB_SET_TXN_TIMEOUT
            %DB_REPMGR_ACKS_ALL_PEERS %DB_TEST_ELECTWAIT2
            %DB_ENV_DATABASE_LOCKING %DB_GET_RECNO
            %DB_ARCH_REMOVE %DB_LOCK_RECORD %DB_EVENT_PANIC
            %DB_LOG_LOCKED %DB_LOCK_NOTGRANTED %DB_RMW
            %DB_ENV_AUTO_COMMIT %DB_NEXT_NODUP %DB_SEQ_WRAP
            %DB_LOCK_PUT_READ %DB_REP_ACK_TIMEOUT
            %DB_VERB_CHKPOINT %DB_LOG_DISK %DB_HASHMAGIC
            %DB_HASHOLDVER %DB_OK_HASH %DB_REP_NEWSITE
            %DB_TEST_POSTRENAME %DB_ST_RELEN %DB_TXN_LOCK
            %DB_NOSERVER_ID %DB_UNKNOWN %DB_ENV_LOGGING
            %DB_EVENT_NO_SUCH_EVENT %DB_NODUPDATA
            %DB_BUFFER_SMALL %DB_APP_INIT %DB_TXN_FAMILY
            %DB_ENV_SYSTEM_MEM %DB_READ_UNCOMMITTED
            %DB_MPOOL_DISCARD %DB_SNAPSHOT %DB_NOSERVER
            %DB_REPMGR_CONNECTED %DB_VERSION_FULL_STRING
            %DB_SWAPBYTES %DB_REP_MASTER %DB_SECONDARY_BAD
            %DB_TXN_LOCK_2PL %DB_TXN_LOG_UNDOREDO
            %DB_LOG_WRNOSYNC %DB_ENV_FATAL %DB_TRUNCATE
            %DB_LOCK_PUT_ALL %DB_MUTEX_SELF_BLOCK
            %DB_CURSOR_BULK %DB_VERSION_PATCH %DB_ENV_CDB
            %DB_DATABASE_LOCK %DB_HANDLE_LOCK %DB_SET_LTE
            %DB_LOG_VERIFY_BAD %DB_OPFLAGS_MASK %DB_PAD
            %DB_SET_REG_TIMEOUT %DB_REP_BULKOVF
            %DB_REP_CONF_LEASE %DB_INIT_LOCK %DB_NOTFOUND
            %DB_TXN_PRINT %DB_INIT_LOG %DB_TEST_SUBDB_LOCKS
            %DB_ARCH_ABS %DB_ST_DUPOK %DB_REP_IGNORE
            %DB_REPMGR_PEER %DB_REPMGR_ACKS_NONE %LOGREC_DBT
            %DB_WRNOSYNC %DB_VERSION_STRING %DB_ST_OVFL_LEAF
            %DB_ENV_TXN_NOSYNC %DB_SA_SKIPFIRSTKEY %DB_FLUSH
            %DB_REP_EGENCHG %DB_MPOOL_NEW_GROUP %DB_LOGMAGIC
            %LOGREC_PGDDBT %DB_MPOOL_FREE %DB_READ_COMMITTED
            %DB_ENV_NOLOCKING %DB_EVENT_REG_PANIC
            %DB_TXN_NOSYNC %DB_CONSUME_WAIT %DB_CURRENT
            %DB_REPMGR_ACKS_ALL %DB_REP_NOTPERM %DB_DEGREE_2
            %LOGREC_POINTER %DB_REP_OUTDATED %DB_RDWRMASTER
            %DB_ENV_USER_ALLOC %DB_CURSOR_TRANSIENT
            %DB_FOREIGN_NULLIFY %DB_LOCK_SWITCH %DB_VERIFY
            %DB_EVENT_REP_MASTER %DB_DIRTY_READ %LOGREC_DB
            %DB_MPOOL_LAST %DB_CONSUME %DB_KEYLAST
            %DB_LOCK_MINWRITE %DB_REP_HEARTBEAT_MONITOR
            %DB_LOG_COMMIT %DB_VERB_RECOVERY %DB_TXN_WAIT
            %DB_EVENT_REP_ELECTED %DB_FILE_ID_LEN
            %DB_TEST_ELECTWAIT1 %DB_LOCK_EXPIRE %DB_LAST
            %DB_DATABASE_LOCKING %DB_FCNTL_LOCKING
            %DB_TXN_WRITE_NOSYNC %DB_ENV_NO_OUTPUT_SET
            %DB_user_BEGIN %DB_EVENT_WRITE_FAILED
            %DB_MPOOL_NOLOCK %DB_VERSION_MINOR %transform_mbii
            %DB_REP_CREATE %DB_REP_DEFAULT_PRIORITY
            %DB_REP_LEASE_TIMEOUT %DB_REP_CLIENT
            %DB_TXN_LOCK_OPTIMIST %DB_LOCK_DEADLOCK
            %DB_ENCRYPT_AES %DB_LOCK_MAXWRITE %DB_GETREC
            %DB_MUTEX_THREAD %DB_ENV_PRIVATE %DB_PREV_DUP
            %DB_TEST_PRERENAME %DB_PR_RECOVERYTEST
            %DB_MPOOL_EXTENT %DB_FILEOPEN %DB_SALVAGE
            %DB_CXX_NO_EXCEPTIONS %DB_LOCK_YOUNGEST
            %DB_VERB_REPMGR_CONNFAIL %DB_REP_LOGREADY
            %DB_ENV_TXN_WRITE_NOSYNC %DB_ENV_LOCKING
            %DB_IMMUTABLE_KEY %DB_MUTEX_SHARED %DB_HEAP
            %DB_CHKSUM_SHA1 %DB_ENV_TXN_SNAPSHOT
            %DB_VERSION_MAJOR %DB_ENV_HOTBACKUP %transform_mbio
            %DB_TEST_POSTDESTROY %DB_FORCESYNC %DB_DUP
            %DB_NOSERVER_HOME %DB_SEQ_INC %DB_FIXEDLEN
            %DB_LOG_VERIFY_CAF %DB_TXN_TOKEN_SIZE
            %DB_VERB_FILEOPS_ALL %LOGREC_ARG %DB_RECNO
            %DB_REP_LEASE_EXPIRED %DB_HOTBACKUP_IN_PROGRESS
            %DB_ENV_DIRECT_LOG %DB_REPMGR_ACKS_ALL_AVAILABLE
            %DB_WRITECURSOR %DB_STAT_LOCK_OBJECTS
            %DB_TEST_RECYCLE %DB_TXN_ABORT %DB_PRIVATE
            %DB_PANIC_ENVIRONMENT %DB_OVERWRITE
            %DB_EVENT_REP_STARTUPDONE %DB_SURPRISE_KID
            %DB_REPMGR_ACKS_ONE_PEER %DB_REP_HOLDELECTION
            %DB_EVENT_REP_SITE_ADDED %DB_EVENT_REP_INIT_DONE
            %DB_MEM_THREAD %DB_EVENT_REP_CONNECT_ESTD
            %DB_ENV_NOFLUSH %DB_EVENT_REP_LOCAL_SITE_REMOVED
            %DB_LEGACY %DB_GROUP_CREATOR %DB_EID_MASTER
            %DB_HEAPVERSION %DB_OK_HEAP %DB_MEM_TRANSACTION
            %DB_EVENT_REP_CONNECT_TRY_FAILED %DB_NOFLUSH
            %DB_STAT_SUMMARY %DB_MEM_TRANSACTION %CARP_NOT
            %DB_HEAPMAGIC %DB_REPMGR_NEED_RESPONSE
            %DB_MEM_LOCKOBJECT %DB_MEM_LOGID %DB_MEM_LOCKER
            %DB_INTERNAL_DB %DB_MEM_LOCK %DB_HEAPOLDVER
            %DB_FAILCHK_ISALIVE %DB_BOOTSTRAP_HELPER
            %DB_HEAP_FULL %DB_STAT_ALLOC %DB_LOCAL_SITE
            %DB_NO_CHECKPOINT %DB_EVENT_REP_SITE_REMOVED
            %DB_EVENT_REP_CONNECT_BROKEN %DB_INIT_MUTEX
            %DB_VERB_BACKUP %DB_INTERNAL_PERSISTENT_DB
            %DB_REP_CONF_AUTOROLLBACK %DB2_AM_INTEXCL
            %DB2_AM_EXCL %DB_INTERNAL_TEMPORARY_DB
            %DB_BACKUP_UPDATE %DB2_AM_NOWAIT %DB_BACKUP_SIZE
            %DB_BACKUP_FILES %DB_BACKUP_WRITE_DIRECT
            %DB_EVENT_REP_WOULD_ROLLBACK &DB_BACKUP_CLEAN
            %DB_BACKUP_READ_COUNT %DB_BACKUP_SINGLE_DIR
            %DB_LOCK_IGNORE_REC %DB_BACKUP_READ_SLEEP
            %DB_BACKUP_NO_LOGS %DB_REP_WOULDROLLBACK
            %DB_STREAM_WRITE %DB_REP_CONF_ELECT_LOGLENGTH
            %list_module %DB_STREAM_READ %DB_LOG_BLOB
            %DB_STREAM_SYNC_WRITE %DB_CHKSUM_FAIL
            %DB_EVENT_REP_AUTOTAKEOVER_FAILED %DB_VERB_MVCC
            %DB_REPMGR_ISVIEW %DB_MUTEX_PROCESS_ONLY
            %transform_mbir %DB_EVENT_REP_INQUEUE_FULL
            %DB_MUTEX_DESCRIBE_STRLEN %DB_FAILURE_SYMPTOM_SIZE
            %DB_LOG_NOSYNC %DB_REPMGR_CONF_PREFMAS_CLIENT
            %DB_SET_MUTEX_FAILCHK_TIMEOUT %DB_INTERNAL_BLOB_DB
            %DB_EVENT_FAILCHK_PANIC %DB_EXIT_FAILCHK
            %LOGREC_LONGARG %DB_EVENT_MUTEX_DIED
            %DB_MUTEX_OWNER_DEAD %DB_STREAM_WRITE
            %DB_REPMGR_CONF_PREFMAS_MASTER %DB_EXIT_FILE_EXISTS
            %DB_MEM_EXTFILE_DATABASE %DB_EVENT_REP_AUTOTAKEOVER
            %DB_FORCESYNCENV %SELECT %DB_REPMGR_CONF_FORWARD_WRITES
            %DB_REPMGR_CONF_ENABLE_EPOLL %DB2_AM_MPOOL_OPENED
            %DB_REP_WRITE_FORWARD_TIMEOUT %DB_META_CHKSUM_FAIL
            %DB_MEM_REP_SITE %DB_LOG_EXT_FILE %DB_OFF_T_MAX
            %DB_REPMGR_ISELECTABLE %DB_SLICE_CORRUPT
            %DB_VERB_SLICE %DB_REPMGR_CONF_DISABLE_POLL
            %DB_TXN_DISPATCH %DB_CONVERT %EPOLL %POLL
            %DB_SYSTEM_MEM_MISSING %DB_REP_INELECT %DB_SLICED
            %DB_REGION_MAGIC_RECOVER %DB_NOINTMP %HAVE_EPOLL
            %DB_MEM_DATABASE %DB_MEM_DATABASE_LENGTH);
 
@EXPORT = qw(pick Menu get_Menu_map);

#####################################################################
####                                                              ###
#### DEFAULT MODULE OF  Term::Menus  $tm_menu IS:                 ###
####                                                              ###
#### ==> *NONE* <==  If you want a different                      ###
####                                                              ###
#### module to be the default, change $tm_menu variable below or  ###
#### set the $tm_menu variable in the BEGIN { } block             ###
#### of the top level script invoking &Menu(). (Advised)          ###
####                                                              ###
#####################################################################

our $tm_menu='';

    #  Example:  our $tm_menu='my_menus.pm';                      ###
                                                                  ###
    #  See documentation for more info                            ###
                                                                  ###
    #################################################################

use Config ();
use Cwd 'abs_path';
use Capture::Tiny;
BEGIN {
   our $filechk = sub {
      package filechk;
      eval { die };
      my $path=$@;
      $path=~s/Died at (.*)Term\/Menus.pm.*$/$1/s;
      chomp($path);
      return 0 unless -e "$path$_[0]";
      return 1;
   };
   our $canload = sub {
      package canloadone;
      eval { die };
      my $path=$@;
      $path=~s/Died at (.*)Term\/Menus.pm.*$/$1/s;
      chomp($path);
      return 0 unless -e "$path$_[0]";
      eval { require $_[0] };
      unless ($@) {
         return 1;
      } else {
         return 0;
      }
   };
}

unless (defined caller(2) && -1<index caller(2),'FullAuto') {

   ### NOTE:  $tm_menu will *NOT* be used when Term::Menus
   ###        is used with Net::FullAuto. Set $fa_menu (below)
   ###        or $main::fa_menu when using Net::FullAuto.

   if ($tm_menu) {
      unless ($Term::Menus::canload->($tm_menu)) {
         my $die="\n       FATAL ERROR: The variable \$tm_menu is defined,\n".
                 "              in the module file:\n\n".
                 "              $INC{'Term/Menus.pm'}\n\n".
                 "              but the value: $tm_menu  does not\n".
                 "              reference a module that can be loaded";
         die $die;
      }
   } elsif (defined $main::tm_menu) {
      if ($Term::Menus::canload->($main::tm_menu)) {
         $tm_menu=$main::tm_menu;
      } else {
         my $die="\n       FATAL ERROR: The variable \$tm_menu is defined,\n".
             "              but the value: $tm_menu  does not\n".
             "              reference a module that can be loaded";
         die $die;
      }
   }
   if ($tm_menu) {
      require $tm_menu;
      my $tm=substr($tm_menu,
             (rindex $tm_menu,'/')+1,-3);
      import $tm;
   }

}

##############################################################
##############################################################
#
#  THIS BLOCK MARKED BY TWO LINES OF POUND SYMBOLS IS FOR
#  SETTINGS NEEDED BY THE MODULE   Net::FullAuto.  IF YOU ARE
#  USING   Term::Menus   OUTSIDE OF   Net::FullAuto,  YOU CAN
#  SAFELY IGNORE THIS SECTION. (That's 'ignore' - not 'remove')
#

our $data_dump_streamer=0;
eval { require Data::Dump::Streamer };
unless ($@) {
   $data_dump_streamer=1;
   import Data::Dump::Streamer;
}

#our $io_interactive=0;
#eval { require IO::Interactive };
#unless ($@) {
#   $io_interactive=1;
#   import IO::Interactive;
#}

BEGIN { ##  Begin  Net::FullAuto  Settings

   eval { require Data::Dump::Streamer };
   unless ($@) {
      $data_dump_streamer=1;
      import Data::Dump::Streamer;
   }
   unless (exists $INC{'Term/Menus.pm'}) {
      foreach my $fpath (@INC) {
         my $f=$fpath;
         if (-e $f.'/Term/Menus.pm') {
            $INC{'Term/Menus.pm'}=$f.'/Term/Menus.pm';
            last;
         }
      }
   }
   my $vlin=__LINE__;
   #####################################################################
   ####                                                              ###
   #### DEFAULT MODULE OF  Net::FullAuto  $fa_code IS:               ###
   ####                                                              ###
   #### ==> Distro/fa_code_demo.pm <==  If you want a different      ###
   ####                                                              ###
   #### module to be the default, change $fa_code variable below or  ###
   #### set the $fa_code variable in the BEGIN { } block             ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $fa_code=['Distro/fa_code_demo.pm', #<== Change Location Here ###
                 "From $INC{'Term/Menus.pm'}, Line: ".($vlin+13)];   ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT MODULE OF  Net::FullAuto  $fa_conf IS:               ###
   ####                                                              ###
   #### ==> Distro/fa_conf.pm <==  If you want a differnet           ###
   ####                                                              ###
   #### module to be the default, change $fa_conf variable below or  ###
   #### set the $fa_conf variable in the BEGIN { } block             ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $fa_conf=['Distro/fa_conf.pm', #<== Change Location Here      ###
                 "From $INC{'Term/Menus.pm'}, Line: ".($vlin+30)];   ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT MODULE OF  Net::FullAuto  $fa_host IS:               ###
   ####                                                              ###
   #### ==> Distro/fa_host.pm <==  If you want a different           ###
   ####                                                              ###
   #### module to be the default, change $fa_host variable below or  ###
   #### set the $fa_hosts_config variable in the BEGIN { } block     ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $fa_host=['Distro/fa_host.pm', #<== Change Location Here      ###
                 "From $INC{'Term/Menus.pm'}, Line: ".($vlin+47)];   ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT MODULE OF  Net::FullAuto  $fa_menu IS:               ###
   ####                                                              ###
   #### ==> Distro/fa_menu_demo.pm <==  If you want a different      ###
   ####                                                              ###
   #### module to be the default, change $fa_menu variable below or  ###
   #### set the $fa_menu variable in the BEGIN { } block             ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ### 
   our $fa_menu=['Distro/fa_menu_demo.pm', #<== Change Location Here ###
                 "From $INC{'Term/Menus.pm'}, Line ".($vlin+81)];    ###
                                                                     ###
   #####################################################################

   our $fullauto=0;$new_user_flag=1;
   if (defined caller(2) && -1<index caller(2),'FullAuto') {
      $fullauto=1;
      my $default_modules='';
      unless ($main::fa_code && $main::fa_conf && $main::fa_host
              && $main::fa_menu) {
         unless (exists $INC{'Net/FullAuto.pm'}) {
            foreach my $fpath (@INC) {
               my $f=$fpath;
               if (-e $f.'/Net/FullAuto.pm') {
                  $INC{'Net/FullAuto.pm'}=$f.'/Net/FullAuto.pm';
                  last;
               }
            }
         }
         my $fa_path=$INC{'Net/FullAuto.pm'};
         my $progname=substr($0,(rindex $0,'/')+1,-3);
         substr($fa_path,-3)='';
         my $username=getlogin || getpwuid($<);
         if (-f $fa_path.'/fa_global.pm') {
            if (-r $fa_path.'/fa_global.pm') {
               {
                  no strict 'subs';
                  require $fa_path.'/fa_global.pm';
                  $fa_global::berkeley_db_path||='';
                  $fa_global::FA_Sudo||={};
                  if (exists $fa_global::FA_Sudo->{$username}) {
                     $username=$fa_global::FA_Sudo->{$username};
                  }
                  if ($fa_global::berkeley_db_path &&
                        -d $fa_global::berkeley_db_path.'Defaults') {
                     BEGIN { $Term::Menus::facall=caller(2);
                             $Term::Menus::facall||='' };
                     use if (-1<index $Term::Menus::facall,'FullAuto'),
                         "BerkeleyDB";
                     my $dbenv = BerkeleyDB::Env->new(
                        -Home  => $fa_global::berkeley_db_path.'Defaults',
                        -Flags => DB_CREATE|DB_INIT_CDB|DB_INIT_MPOOL
                     ) or die(
                        "cannot open environment for DB: ".
                        $BerkeleyDB::Error."\n",'','');
                     my $kind=(grep { /^--test$/ } @ARGV)?'test':'prod';
                     my $bdb = BerkeleyDB::Btree->new(
                           -Filename => "${progname}_${kind}_defaults.db",
                           -Flags    => DB_CREATE,
                           -Env      => $dbenv
                        );
                     unless ($BerkeleyDB::Error=~/Successful/) {
                        $bdb = BerkeleyDB::Btree->new(
                           -Filename => "${progname}_${kind}_defaults.db",
                           -Flags    => DB_CREATE|DB_RECOVER_FATAL,
                           -Env      => $dbenv
                        );
                        unless ($BerkeleyDB::Error=~/Successful/) {
                           die "Cannot Open DB ${progname}_${kind}_defaults.db:".
                               " $BerkeleyDB::Error\n";
                        }
                     }
                     if (exists $ENV{'SSH_CONNECTION'} &&
                           exists $ENV{'USER'} && ($ENV{'USER'}
                           ne $username)) {
                        $username=$ENV{'USER'};
                     } elsif ($username eq 'SYSTEM' &&
                           exists $ENV{'IWUSER'} && ($ENV{'IWUSER'}
                           ne $username)) {
                        my $login_flag=0;
                        foreach (@ARGV) {
                           my $argv=$_;
                           if ($login_flag) {
                              $username=$argv;
                              last;
                           } elsif (lc($argv) eq '--login') {
                              $login_flag=1;
                           }
                        }
                        $username=$ENV{'IWUSER'} unless $login_flag;
                     } elsif (grep { /--login/ } @ARGV) {
                        my $login_flag=0;
                        foreach (@ARGV) {
                           my $argv=$_;
                           if ($login_flag) {
                              $username=$argv;
                              last;
                           } elsif (lc($argv) eq '--login') {
                              $login_flag=1;
                           }
                        }
                     }
                     my $status=$bdb->db_get(
                           $username,$default_modules) if $bdb;
                     $default_modules||='';
                     $default_modules=~s/\$HASH\d*\s*=\s*//s
                        if -1<index $default_modules,'$HASH';
                     $default_modules=eval $default_modules;
                     $default_modules||={};
                     my $save_defaults_for_user_flag=0;
                     if ($data_dump_streamer) {
                        foreach my $mod (keys %{$default_modules}) {
                           if ($mod eq 'set') {
                              if ($default_modules->{set} ne 'none') {
                                 $save_defaults_for_user_flag=1;
                                 next;
                              } else { next }
                           }
                           unless ($Term::Menus::filechk->(
                                 $default_modules->{$mod})) {
                              delete $default_modules->{$mod};
                              next;
                           }
                           $save_defaults_for_user_flag=1;
                        }
                        if ($save_defaults_for_user_flag) {
                           my $def_modules=Data::Dump::Streamer::Dump(
                              $default_modules)->Out();
                           my $status=$bdb->db_put(
                                 $username,$def_modules) if $bdb;
                        } else {
                           my $status=$bdb->db_del(
                                 $username) if $bdb;
                        }
                     }
                     undef $bdb;
                     $dbenv->close();
                     undef $dbenv;
                     unless (keys %{$default_modules}) {
                        $default_modules->{'set'}='none';
                        $default_modules->{'fa_code'}=
                           'Net/FullAuto/Distro/fa_code_demo.pm';
                        $default_modules->{'fa_conf'}=
                           'Net/FullAuto/Distro/fa_conf.pm';
                        $default_modules->{'fa_host'}=
                           'Net/FullAuto/Distro/fa_host.pm';
                        $default_modules->{'fa_menu'}=
                           'Net/FullAuto/Distro/fa_menu_demo.pm';
                     } elsif (exists $default_modules->{'set'} &&
                           $default_modules->{'set'} ne 'none') {
                        $new_user_flag=0;
                        my $setname=$default_modules->{'set'};
                        my $stenv = BerkeleyDB::Env->new(
                           -Home  => $fa_global::berkeley_db_path.'Sets',
                           -Flags => DB_CREATE|DB_INIT_CDB|DB_INIT_MPOOL
                        ) or die(
                           "cannot open environment for DB: ".
                           $BerkeleyDB::Error."\n",'','');
                        my $std = BerkeleyDB::Btree->new(
                              -Filename => "${progname}_sets.db",
                              -Flags    => DB_CREATE,
                              -Env      => $stenv
                           );
                        unless ($BerkeleyDB::Error=~/Successful/) {
                           $std = BerkeleyDB::Btree->new(
                              -Filename => "${progname}_sets.db",
                              -Flags    => DB_CREATE|DB_RECOVER_FATAL,
                              -Env      => $stenv
                           );
                           unless ($BerkeleyDB::Error=~/Successful/) {
                              die "Cannot Open DB ${progname}_sets.db:".
                                  " $BerkeleyDB::Error\n";
                           }
                        }
                        #my $username=getlogin || getpwuid($<);
                        my $set='';
                        my $status=$std->db_get(
                              $username,$set);
                        $set||='';
                        $set=~s/\$HASH\d*\s*=\s*//s
                           if -1<index $set,'$HASH';
                        $set=eval $set;
                        $set||={};
                        undef $std;
                        $stenv->close();
                        undef $stenv;
                        $fa_code=[$set->{$setname}->{'fa_code'},
                                  "From Default Set $setname ".
                                  "(Change with fa --set)"];
                        $fa_conf=[$set->{$setname}->{'fa_conf'},
                                  "From Default Set $setname ".
                                  "(Change with fa --set)"];
                        $fa_host=[$set->{$setname}->{'fa_host'},
                                  "From Default Set $setname ".
                                  "(Change with fa --set)"];
                        $fa_menu=[$set->{$setname}->{'fa_menu'},
                                  "From Default Set $setname ".
                                  "(Change with fa --set)"];
                     } else {
                        $new_user_flag=0; 
                        if (exists $default_modules->{'fa_code'}) {
                           $fa_code=[$default_modules->{'fa_code'},
                                     "From Default Setting ".
                                     "(Change with fa --defaults)"];
                        }
                        if (exists $default_modules->{'fa_conf'}) {
                           $fa_conf=[$default_modules->{'fa_conf'},
                                     "From Default Setting ".
                                     "(Change with fa --defaults)"];
                        }
                        if (exists $default_modules->{'fa_host'}) {
                           $fa_host=[$default_modules->{'fa_host'},
                                     "From Default Setting ".
                                     "(Change with fa --defaults)"];
                        }
                        if (exists $default_modules->{'fa_menu'}) {
                           $fa_menu=[$default_modules->{'fa_menu'},
                                     "From Default Setting ".
                                     "(Change with fa --defaults)"];
                        }
                     }
                  }
               }
            } else {
               warn("WARNING: Cannot read defaults file $fa_path/fa_global.pm".
                    " - permission denied (Hint: Perhaps you need to 'Run as ".
                    "administrator'?)");
            }
         }
         my @A=();my %A=();
         push @A,@ARGV;
         my $acnt=0;
         foreach my $a (@A) {
            $acnt++;
            my $aa=$a;
            if (-1<index $aa,'--fa_') {
               my $k=unpack('x5a*',$aa);
               my $v=$A[$acnt]||'';
               unless (-1<index $v, '--fa_') {
                  $A{$k}=$v;
               } else {
                  @A=();
                  last;
               }
            } elsif (-1<index $aa,'--set') {
               my $v=$A[$acnt]||'';
               unless (-1<index $v, '--') {
                  $A{set}=$v;
               } else {
                  @A=();
                  last;
               }
            }
         }
         foreach my $e (('set','code','conf','host','maps','menu')) {
            if (exists $A{$e}) {
               $new_user_flag=0;
               if ($e eq 'set') {
                  no strict 'subs';
                  my $setname=$A{$e};
                  my $fa_path=$INC{'Net/FullAuto.pm'};
                  my $progname=substr($0,(rindex $0,'/')+1,-3);
                  substr($fa_path,-3)='';
                  if (-f $fa_path.'/fa_global.pm') {
                     my $stenv = BerkeleyDB::Env->new(
                        -Home  => $fa_global::berkeley_db_path.'Sets',
                        -Flags => DB_CREATE|DB_INIT_CDB|DB_INIT_MPOOL
                     ) or die(
                        "cannot open environment for DB: ".
                        $BerkeleyDB::Error."\n",'','');
                     my $std = BerkeleyDB::Btree->new(
                           -Filename => "${progname}_sets.db",
                           -Flags    => DB_CREATE,
                           -Env      => $stenv
                        );
                     unless ($BerkeleyDB::Error=~/Successful/) {
                        $std = BerkeleyDB::Btree->new(
                           -Filename => "${progname}_sets.db",
                           -Flags    => DB_CREATE|DB_RECOVER_FATAL,
                           -Env      => $stenv
                        );
                        unless ($BerkeleyDB::Error=~/Successful/) {
                           die "Cannot Open DB ${progname}_sets.db:".
                               " $BerkeleyDB::Error\n";
                        }
                     }
                     #my $username=getlogin || getpwuid($<);
                     my $set='';
                     my $status=$std->db_get(
                           $username,$set);
                     $set||='';
                     $set=~s/\$HASH\d*\s*=\s*//s
                        if -1<index $set,'$HASH';
                     $set=eval $set;
                     $set||={};
                     undef $std;
                     $stenv->close();
                     undef $stenv;
                     $fa_code=[$set->{$setname}->{'fa_code'},
                               "From CMD arg fa --set $setname line ".__LINE__];
                     $fa_conf=[$set->{$setname}->{'fa_conf'},
                               "From CMD arg fa --set $setname line ".__LINE__];
                     $fa_host=[$set->{$setname}->{'fa_host'},
                               "From CMD arg fa --set $setname line ".__LINE__];
                     $fa_menu=[$set->{$setname}->{'fa_menu'},
                               "From CMD arg fa --set $setname line ".__LINE__];
                  } else {
                     my $die="\n       FATAL ERROR: The Set indicated from".
                             " the CMD arg:\n\n".
                             "              ==> fa --set $A{$e}n\n".
                             "              does not exist. To create this\n".
                             "              set, run fa --set without any\n".
                             "              other arguments";
                     die $die;
                  }
               } elsif ($e eq 'code') {
                  $fa_code=$A{$e};
                  $fa_code=[$fa_code,
                            "From CMD arg: fa --fa_code $A{$e}"];
               } elsif ($e eq 'menu') {
                  $fa_menu=$A{$e};
                  $fa_menu=[$fa_menu,
                            "From CMD arg: fa --fa_menu $A{$e}"];
               } elsif ($e eq 'host') {
                  $fa_host=$A{$e};
                  $fa_host=[$fa_host,
                            "From CMD arg: fa --fa_host $A{$e}"];
               } elsif ($e eq 'conf') {
                  $fa_conf=$A{$e};
                  $fa_conf=[$fa_conf,
                            "From CMD arg: fa --fa_conf $A{$e}"];
               }
            }
            my $abspath=abs_path($0);
            $abspath=~s/\.exe$//;
            $abspath.='.pl';
            if (defined $main::fa_code && $main::fa_code) {
               $new_user_flag=0;
               $fa_code=$main::fa_code;
               my $p=abs_path($0);
               $fa_code=[$fa_code,
                         "From \$fa_code variable in $abspath"];
            }
            if (defined $main::fa_conf && $main::fa_conf) {
               $new_user_flag=0;
               $fa_conf=$main::fa_conf;
               $fa_conf=[$fa_conf,
                         "From \$fa_conf variable in $abspath"];
            }
            if (defined $main::fa_host && $main::fa_host) {
               $new_user_flag=0;
               $fa_host=$main::fa_host;
               $fa_host=[$fa_host,
                         "From \$fa_host variable in $abspath"];
            }
            if (defined $main::fa_menu && $main::fa_menu) {
               $new_user_flag=0;
               $fa_menu=$main::fa_menu;
               $fa_menu=[$fa_menu,
                         "From \$fa_menu variable in $abspath"];
            }
         }
      } else {
         $new_user_flag=0;
         my $abspath=abs_path($0);
         $abspath=~s/\.exe$//;
         $abspath.='.pl';
         $fa_code=[$fa_code,
                   "From \$fa_code variable in $abspath"];
         $fa_conf=[$fa_conf,
                   "From \$fa_conf variable in $abspath"];
         $fa_host=[$fa_host,
                   "From \$fa_host variable in $abspath"];
         $fa_menu=[$fa_menu,
                   "From \$fa_menu variable in $abspath"];
      }
      $fa_code->[0]='Net/FullAuto/'.$fa_code->[0]
         if $fa_code->[0] && -1==index $fa_code->[0],'Net/FullAuto';
      $fa_code->[0]||='';
      my $argv=join " ",@ARGV;
      my $rx='^--edi*t* *|^-e[a-z]|^--admin|^-V|^-v|^--VE*R*S*I*O*N*|'.
             '^--users|^--ve*r*s*i*o*n*|^--cat|^--tutorial|^--figlet';
      if (!map { /$rx/ } @ARGV) {
         if ($fa_code->[0]) {
            if ($Term::Menus::canload->($fa_code->[0])) {
               require $fa_code->[0];
               my $mod=substr($fa_code->[0],(rindex $fa_code->[0],'/')+1,-3);
               import $mod;
               $fa_code=$mod.'.pm';
            } else {
               my $ln=__LINE__;
               $ln-=5;
               die "Cannot load module $fa_code->[0]".
                   "\n   $fa_code->[1]\n".
                   "\"require $fa_code->[0];\"".
                   "--failed at ".$INC{'Term/Menus.pm'}." line $ln\.\n$@\n";
            }
         } else {
            require 'Net/FullAuto/Distro/fa_code.pm';
            import fa_code;
            $fa_code='fa_code.pm';
         } 
      }
      $fa_conf->[0]='Net/FullAuto/'.$fa_conf->[0]
         if $fa_conf->[0] && -1==index $fa_conf->[0],'Net/FullAuto';
      $fa_conf->[0]||='';
      if ($argv!~/--edit |^-e[a-z]|--cat /) {
         if ($fa_conf->[0]) {
            if ($Term::Menus::canload->($fa_conf->[0])) {
               require $fa_conf->[0];
               my $mod=substr($fa_conf->[0],(rindex $fa_conf->[0],'/')+1,-3);
               import $mod;
               $fa_conf=$mod.'.pm';
            } else {
               my $ln=__LINE__;
               $ln-=5;
               die "Cannot load module $fa_conf->[0]".
                   "\n   $fa_conf->[1]\n".
                   "\"require $fa_conf->[0];\"".
                   "--failed at ".$INC{'Term/Menus.pm'}." line $ln\.\n$@\n";
            }
         } else {
            require 'Net/FullAuto/Distro/fa_conf.pm';
            import fa_conf;
            $fa_conf='fa_conf.pm';
         }
      }
      $fa_host->[0]='Net/FullAuto/'.$fa_host->[0]
         if $fa_host->[0] && -1==index $fa_host->[0],'Net/FullAuto';
      $fa_host->[0]||='';
      if ($argv!~/--edit |^-e[a-z]/) {
         if ($fa_host->[0]) {
            if ($Term::Menus::canload->($fa_host->[0])) {
               require $fa_host->[0];
               my $mod=substr($fa_host->[0],(rindex $fa_host->[0],'/')+1,-3);
               import $mod;
               $fa_host=$mod.'.pm';
            } else {
               my $ln=__LINE__;
               $ln-=5;
               die "Cannot load module $fa_host->[0]".
                   "\n   $fa_host->[1]\n".
                   "\"require $fa_host->[0];\"".
                   "--failed at ".$INC{'Term/Menus.pm'}." line $ln\.\n$@\n";
            }
         } else {
            require 'Net/FullAuto/Distro/fa_host.pm';
            import fa_host;
            $fa_host='fa_host.pm';
         }
      }
      $fa_menu->[0]='Net/FullAuto/'.$fa_menu->[0]
         if $fa_menu->[0] && -1==index $fa_menu->[0],'Net/FullAuto';
      $fa_menu->[0]||='';
      if ($argv!~/--edit |^-e[a-z]/) {
         if ($fa_menu->[0]) {
            if ($Term::Menus::canload->($fa_menu->[0])) {
               require $fa_menu->[0];
               my $mod=substr($fa_menu->[0],(rindex $fa_menu->[0],'/')+1,-3);
               import $mod;
               $fa_menu=$mod.'.pm';
            } else {
               my $ln=__LINE__;
               $ln-=5;
               die "Cannot load module $fa_menu->[0]".
                   "\n   $fa_menu->[1]\n".
                   "\"require $fa_menu->[0];\"".
                   "--failed at ".$INC{'Term/Menus.pm'}." line $ln\.\n$@\n";
            }
         } else {
            require 'Net/FullAuto/Distro/fa_menu_demo.pm';
            import fa_menu_demo;
            $fa_menu='fa_menu_demo.pm';
         }
      }
        
   }

}

our %email_defaults=();
if (%fa_code::email_defaults) {
   %email_defaults=%fa_code::email_defaults;
}
our %email_addresses=();
if (%fa_code::email_addresses) {
   %email_addresses=%fa_code::email_addresses;
}
our $passwd_file_loc='';
if (defined $fa_code::passwd_file_loc && $fa_code::passwd_file_loc) {
   $passwd_file_loc=$fa_code::passwd_file_loc;
}
our $test=0;
if (defined $fa_code::test && $fa_code::test) {
   $test=$fa_code::test;
}
our $timeout=30;
if (defined $fa_code::timeout && $fa_code::timeout) {
   $timeout=$fa_code::timeout;
}
our $log=0;
if (defined $fa_code::log && $fa_code::log) {
   $log=$fa_code::log;
}
our $tosspass=0;
if (defined $fa_code::tosspass && $fa_code::tosspass) {
   $tosspass=$fa_code::tosspass;
}

##  End  Net::FullAuto  Settings

##############################################################
##############################################################

##  Begin  Term::Menus

our $termwidth=0;
our $termheight=0;
our $padwalker=0;
our $term_input=0;
eval { require Term::ReadKey };
unless ($@) {
   import Term::ReadKey;
   ($termwidth,$termheight)=eval {
      no strict 'subs';
      my ($termwidth,$termheight)=('','');
      ($termwidth, $termheight) =
         Term::ReadKey::GetTerminalSize();
      $termwidth||='';$termheight||='';
      return $termwidth,$termheight;
   };
   if ($@) {
      $termwidth='';$termheight='';
   }
} else {
   $termwidth='';$termheight='';
}
if ($termwidth) {
   eval { require Term::RawInput };
   unless ($@) {
      $term_input=1;
      import Term::RawInput;
   }
}
eval { require PadWalker };
unless ($@) {
   $padwalker=1;
   import PadWalker;
}
eval { require Devel::Symdump };
unless ($@) {
   #$devel_symdump=1;
   import Devel::Symdump;
}
our $clearpath='';
if ($^O ne 'MSWin32' && $^O ne 'MSWin64') {
   if (-e '/usr/bin/clear') {
      $clearpath='/usr/bin/';
   } elsif (-e '/bin/clear') {
      $clearpath='/bin/';
   } elsif (-e '/usr/local/bin/clear') {
      $clearpath='/usr/local/bin/';
   }
}

our %LookUpMenuName=();
our $MenuMap=[];

our $noclear=1; # set to one to turn off clear for debugging

sub check_for_dupe_menus {

   my $m_flag=0;
   my $s_flag=0;
   foreach my $dir (@INC) {
      if (!$m_flag && -f "$dir/$Term::Menus::fa_menu") {
         $m_flag=1;
         open(FH,"<$dir/$Term::Menus::fa_menu");
         my $line='';my %menudups=();
         while ($line=<FH>) {
            if ($line=~/^[ \t]*\%(.*)\s*=/) {
               if (!exists $menudups{$1}) {
                  $menudups{$1}='';
               } else {
                  my $mcmf=$Term::Menus::fa_menu;my $die='';
                  $die="\n       FATAL ERROR! - Duplicate Hash Blocks:"
                      ."\n              ->  \"%$1\" is defined more than once\n"
                      ."              in the $dir/$mcmf file.\n\n"
                      ."       Hint:  delete or comment-out all duplicates\n\n";
                  if ($Term::Menus::fullauto) {
                     print $die if !$Net::FullAuto::FA_Core::cron;
                     &Net::FullAuto::FA_Core::handle_error($die,'__cleanup__');
                  } else { die $die }
               }
            }
         }
      }
      if (!$s_flag && -f "$dir/$Term::Menus::fa_code") {
         $s_flag=1;
         open(FH,"<$dir/$Term::Menus::fa_code");
         my $line='';my %dups=();
         while ($line=<FH>) {
            if ($line=~/^[ \t]*\%(.*)\s*=/) {
               if (!exists $dups{$1}) {
                  $dups{$1}='';
               } else {
                  my $die="\n       FATAL ERROR! - Duplicate Hash Blocks:"
                         ."\n              ->  \"%$1\" is defined more "
                         ."than once\n              in the $dir/"
                         .$Term::Menus::fa_code
                         ." file.\n\n       Hint:  delete "
                         ."or comment-out all duplicates\n\n";
                  if ($Term::Menus::fullauto) {
                     print $die if !$Net::FullAuto::FA_Core::cron;
                     &Net::FullAuto::FA_Core::handle_error($die,'__cleanup__');
                  } else { die $die }
               }
            }
         }
      }
   }

   if ($Term::Menus::fullauto) {
      foreach my $symname (keys %Term::Menus::) {
         if (eval "\\%$symname") {
            my $hashref=eval "\\%$symname";
            HF: foreach my $key (keys %{$hashref}) {
               if (ref $hashref->{$key} eq 'HASH') {
                  foreach my $ky (keys %{$hashref->{$key}}) {
                     if (lc($ky) eq 'text') {
                        $LookUpMenuName{$hashref}=$symname;
                        last HF;
                     }
                  }
               }
            }
         }
      }
   }

}

&check_for_dupe_menus() if defined $main::fa_menu
                                && $main::fa_menu;

{
   use Sys::Hostname;
   our $local_hostname=&Sys::Hostname::hostname();
}

my $count=0;
our $blanklines='';
if ($Term::Menus::termheight) {
   $count=$Term::Menus::termheight;
} else { $count=30 }
while ($count--) { $blanklines.="\n" }
our $parent_menu='';

sub fa_login
{
   my $code='';my $menu_args='';my $to='';my $die='';
   my $start_menu_ref='';my $cache='';
   my $returned='';
   eval {
      ($code,$menu_args,$to,$cache)=
         &Net::FullAuto::FA_Core::fa_login(@_);
      $main::cache=$cache if $cache;
      undef $main::cache unless $cache;
      my $mc=substr($Term::Menus::fa_menu,
             (rindex $Term::Menus::fa_menu,'/')+1,-3);
      $start_menu_ref=eval '$'.$mc.'::start_menu_ref';
      $to||=0;
      $timeout=$to if $to;
      if ($code) {
         &run_sub($code,$menu_args);
      } elsif (ref $start_menu_ref eq 'HASH') {
         unless (keys %LookUpMenuName) {
            &check_for_dupe_menus();
         }
         if ($Net::FullAuto::FA_Core::plan) {
            my $plann=shift @{$Net::FullAuto::FA_Core::plan};
            my $return=eval $plann->{Item};
            &Net::FullAuto::FA_Core::handle_error($@,'-1') if $@;
            return $return;
         }
         $returned=&Menu($start_menu_ref);
      } elsif ($start_menu_ref) {
         my $mcmf=$Term::Menus::fa_menu;
         my $die="\n       FATAL ERROR! - The top level menu "
                ."block indicated\n              by the "
                ."\$start_menu_ref variable in the\n       "
                ."       $mcmf file, does not exist as"
                ."\n              a properly constructed and"
                ."\\or named hash\n              block in the"
                ." ".__PACKAGE__.".pm file\n\n       Hint:  "
                ."our \$start_menu_ref=\\%Menu_1\;\n\n       "
                ."\[ Menu_1 is example - name you choose is"
                ." optional \]\n\n       %Menu_1=\(\n"
                ."          Item_1 => { ... },\n        "
                ."...\n       \)\;\n";
         &Net::FullAuto::FA_Core::handle_error($die);
      } else {
         my $mcmf=$Term::Menus::fa_menu;
         my $die="\n       FATAL ERROR! - The \$start_menu_ref\n"
                ."              variable in the $mcmf\n"
                ."              file, is not defined or properly"
                ."\n              initialized with the name of "
                ."the\n              menu hash block designated"
                ." for the\n              top level menu.\n\n"
                ."              Hint:  our \$start_menu_ref"
                ."=\\%Menu_1\;\n\n       \[ Menu_1 is example - "
                ."name you choose is optional \]\n\n       "
                ."%Menu_1=\(\n          Item_1 => { ... },\n"
                ."          ...\n       \)\;\n";
         &Net::FullAuto::FA_Core::handle_error($die);
      }
   };
   if ($@) {
      my $cmdlin=52;
      $cmdlin=47 if $code;
      my $errr=$@;
      $errr=~s/^\s*/\n       /s;
      print $errr;
   }
   &Net::FullAuto::FA_Core::cleanup(0,$returned);

}

sub run_sub
{
   use if $Term::Menus::fullauto, "IO::Handle";
   use if $Term::Menus::fullauto, POSIX => qw(setsid);

   if ($Term::Menus::fullauto && defined $Net::FullAuto::FA_Core::service
         && $Net::FullAuto::FA_Core::service) {
      print "\n\n   ##### TRANSITIONING TO SERVICE ######".
            "\n\n   FullAuto will now continue running as".
            "\n   as a Service/Daemon. Now exiting".
            "\n   interactive mode ...\n\n";
      chdir '/'                 or die "Can't chdir to /: $!";
      umask 0;
      open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
      open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
      open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
      defined(my $pid = fork)   or die "Can't fork: $!";
      exit if $pid;
      $pid = &setsid          or die "Can't start a new session: $!";
   }

   my $code=$_[0];
   $code=~s/^[&]//;
   my $menu_args= (defined $_[1]) ? $_[1] : '';
   my $subfile=substr($Term::Menus::fa_code,0,-3).'::'
         if $Term::Menus::fa_code;
   $subfile||='';
   my $return=
      eval "\&$subfile$code\(\@{\$menu_args}\)";
   &Net::FullAuto::FA_Core::handle_error($@,'-1') if $@;
   return $return;
}

sub get_all_hosts
{
   return Net::FullAuto::FA_Core::get_all_hosts(@_);
}

sub get_Menu_map_count
{
   my $map_count=0;$count=0;
   foreach my $map (@{$_[0]}) {
      $count=$map->[0];
      $map_count=$count if $map_count<$count;
   }
   return $map_count;
}

sub get_Menu_map
{
   my %tmphash=();my @menu_picks=();
   foreach my $map (@{$MenuMap}) {
      $tmphash{$map->[0]}=$map->[1]; 
   }
   foreach my $number (sort numerically keys %tmphash) {
      push @menu_picks, $tmphash{$number};
   }
   return @menu_picks;
}

sub eval_error
{

   my $log_handle=$_[1]||'';
   if (10<length $_[0] && unpack('a11',$_[0]) eq 'FATAL ERROR') {
      if (defined $log_handle &&
            -1<index $log_handle,'*') {
         print $log_handle $@;
         close($log_handle);
      }
      die $_[0];
   } else {
      my $die="\n       FATAL ERROR! - The Local "
             ."System $Term::Menus::local_hostname "
             ."Conveyed\n"
             ."              the Following "
             ."Unrecoverable Error Condition :\n\n"
             ."       $_[0]\n       line ".__LINE__;
      if (defined $log_handle &&
            -1<index $log_handle,'*') {
         print $log_handle $die;
         close($log_handle);
      }
      if ($Term::Menus::fullauto) {
         &Net::FullAuto::FA_Core::handle_error($die);
      } else { die $die }
   }
}

sub banner
{

   my $banner=$_[0]||'';
   return '' unless $banner;
   my $Conveyed=$_[1]||{};
   my $SaveMMap=$_[2]||'';
   my $picks_from_parent=$_[3]||'';
   my $numbor=(defined $_[4])?$_[4]:'';
   my $ikey=$_[5]||'';
   my $input=$_[6]||{};
   my $MenuUnit_hash_ref=$_[7]||{};
   my $log_handle=$_[8]||'';
   $banner||='';
   if (ref $banner eq 'CODE') {
      my $banner_code=$banner;
      if ($Term::Menus::data_dump_streamer) {
         $banner_code=
            &Data::Dump::Streamer::Dump($banner_code)->Out();
         $banner_code=&transform_pmsi($banner_code,
            $Conveyed,$SaveMMap,$picks_from_parent);
      }
#print "WHAT IS CDNOW2=$banner_code<==\n";<STDIN>;
      $banner_code=~s/\$CODE\d*\s*=\s*//s;
#print "WHAT IS CDREALLYNOW=$banner_code<==\n";<STDIN>;
      my $eval_banner_code=eval $banner_code;
      $eval_banner_code||=sub {};
      my $die="\n"
             ."       FATAL ERROR! - Error in Banner => sub{ *CONTENT* },\n"
             ."                      code block. To find error, copy the\n"
             ."                      *CONTENT* to a separate script, and\n"
             ."                      test for the error there. Use the\n"
             ."                      'use strict;' pragma.\n\n";
      eval {
         $banner=$eval_banner_code->();
      };
      if ($@) {
         if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
            if (wantarray) {
               return '',$@
            }
            if (defined $log_handle &&
                  -1<index $log_handle,'*') {
               print $log_handle $@;
               close($log_handle);
            }
            if ($Term::Menus::fullauto) {
               &Net::FullAuto::FA_Core::handle_error($@);
            } else { die $@ }
         } else {
            if (wantarray) {
               return '',$die.'       '.$@
            }
            if (defined $log_handle &&
                  -1<index $log_handle,'*') {
               print $log_handle $die.'       '.$@;
               close($log_handle);
            }
            if ($Term::Menus::fullauto) {
               &Net::FullAuto::FA_Core::handle_error(
                  $die.'       '.$@);
            } else { die $die.'       '.$@ }
         }
      }
   } elsif (keys %{$Conveyed} || $picks_from_parent) {
      $banner=&transform_pmsi($banner,
         $Conveyed,$SaveMMap,$picks_from_parent);
   } else {
      chomp($banner);
   }
   if ($banner && ($banner=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/
         && grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) &&
         defined $picks_from_parent &&
         !ref $picks_from_parent) {
      my @banner=();
      if ($banner!~/::/) {
         $banner=~s/^[&]//;
         eval "\@banner=main::$banner";
      } else {
         eval "\@banner=$banner";
      }
      $banner=join '',@banner;
   }
   return transform_mbio(transform_mbii(transform_mbir(
             $banner,$Conveyed,$MenuUnit_hash_ref,
             $log_handle),$numbor,$ikey,$input,
             $MenuUnit_hash_ref,$Conveyed,$log_handle),$MenuUnit_hash_ref,
             $Conveyed,$SaveMMap,$picks_from_parent,$log_handle);

}

sub Menu
{
#print "MENUCALLER=",(caller)[0]," and ",__PACKAGE__,"\n";<STDIN>;
#print "MENUCALLER=",caller,"\n";
   my $MenuUnit_hash_ref=$_[0];
#print "WHAT IS THIS=",&Data::Dump::Streamer::Dump($MenuUnit_hash_ref)->Out(),"\n";
   $MenuUnit_hash_ref->{Name}=&pw($MenuUnit_hash_ref);
   my $select_many=0;
   if (exists $MenuUnit_hash_ref->{Select}) {
      if (exists $MenuUnit_hash_ref->{Select} &&
            $MenuUnit_hash_ref->{Select} &&
            $MenuUnit_hash_ref->{Select}=~/many/i) {
         $select_many='Many';
         $MenuUnit_hash_ref->{Select}={};
      } elsif (exists $MenuUnit_hash_ref->{Select} &&
            $MenuUnit_hash_ref->{Select} &&
            $MenuUnit_hash_ref->{Select}=~/one/i) {
         $MenuUnit_hash_ref->{Select}={};
      } 
   } else {
      $MenuUnit_hash_ref->{Select}={};
   }
   my $picks_from_parent=$_[1]||'';
   my $log_handle='';
   if ($picks_from_parent && -1<index $picks_from_parent,'*') {
      $log_handle=$picks_from_parent;
      $picks_from_parent='';
   }
   my $unattended=0;
   if ($picks_from_parent=~/\](Cron|Batch|Unattended|FullAuto)\[/i) {
      $unattended=1;
      undef $picks_from_parent;
   }
   my $recurse = (defined $_[2]) ? $_[2] : 0;
   my $FullMenu= (defined $_[3]) ? $_[3] : {};
   my $Selected= (defined $_[4]) ? $_[4] : {};
   my $Conveyed= (defined $_[5]) ? $_[5] : {};
   my $SavePick= (defined $_[6]) ? $_[6] : {};
   my $SaveMMap= (defined $_[7]) ? $_[7] : {};
   my $SaveNext= (defined $_[8]) ? $_[8] : {};
   my $Persists= (defined $_[9]) ? $_[9] : {};
   my $parent_menu= (defined $_[10]) ? $_[10] : '';
   my $no_wantarray=0;

   if ((defined $_[11] && $_[11]) ||
         ((caller)[0] ne __PACKAGE__ && !wantarray)) {
      $no_wantarray=1;
   }
   if (defined $_[12] && $_[12]) {
      return '','','','','','','','','','','',$_[12];
   }
   if (defined $_[13] && $_[13]) {
      $log_handle=$_[13];
   }
   my %Items=();my %negate=();my %result=();my %convey=();
   my %chosen=();my %default=();my %select=();my %mark=();
   my $pick='';my $picks=[];my %num__=();
   my $display_this_many_items=10;my $die_err='';
   my $master_substituted='';my $convey='';$mark{BLANK}=1;
   my $show_banner_only=0;
   my $num=0;my @convey=();my $filtered=0;my $sorted='';
   foreach my $key (keys %{$MenuUnit_hash_ref}) {
      if (4<length $key && substr($key,0,4) eq 'Item') {
         $Items{substr($key,5)}=$MenuUnit_hash_ref->{$key};
      }
   }
   $Persists->{unattended}=$unattended if $unattended;
   my $start=($FullMenu->{$MenuUnit_hash_ref}[11])?
             $FullMenu->{$MenuUnit_hash_ref}[11]:0;

   ############################################
   # Breakdown the MenuUnit into its Components
   ############################################

      # Breakdown Each Item into its Components
      #########################################

   my $got_item_flag=0;
   while (++$num) {
      $start=$FullMenu->{$MenuUnit_hash_ref}[11]||0;
      @convey=();
      unless (exists $Items{$num}) {
         if (exists $MenuUnit_hash_ref->{Banner} && !$got_item_flag) {
            $show_banner_only=1;
         } else { last }
      } else {
         $got_item_flag=1;
      }
      if (exists $Items{$num}->{Negate} &&
            !(keys %{$MenuUnit_hash_ref->{Select}})) {
         my $die="Can Only Use \"Negate =>\""
                ."\n\t\tElement in ".__PACKAGE__.".pm when the"
                ."\n\t\t\"Select =>\" Element is set to \'Many\'\n\n";
         &Net::FullAuto::FA_Core::handle_error($die)
            if $Term::Menus::fullauto;
         die $die;
      }
      my $con_regex=qr/\]c(o+nvey)*\[/i;
      if (exists $Items{$num}->{Convey}) {
         my $convey_test=$Items{$num}->{Convey};
         if (ref $Items{$num}->{Convey} eq 'ARRAY') {
            foreach my $line (@{$Items{$num}->{Convey}}) {
               push @convey, $line;
            }
         } elsif (ref $Items{$num}->{Convey} eq 'CODE') {
            my $convey_code=$Items{$num}->{Convey};
            if ($Term::Menus::data_dump_streamer) {
               $convey_code=
                  &Data::Dump::Streamer::Dump($convey_code)->Out();
#print "PICKSFROMPARENTXX=$picks_from_parent AND CONVEY_CODE=$convey_code\n";
               $convey_code=&transform_pmsi($convey_code,
                  $Conveyed,$SaveMMap,$picks_from_parent);
            }
#print "WHAT IS CDNOW1=$convey_code<==\n";
            $convey_code=~s/\$CODE\d*\s*=\s*//s;
#print "WHAT IS CDREALLYNOW=$convey_code<==\n";<STDIN>;
            my $eval_convey_code=eval $convey_code;
            $eval_convey_code||=sub {};
            @convey=$eval_convey_code->();
            @convey=@{$convey[0]} if ref $convey[0] eq 'ARRAY';
            if ($@) {
               if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                  if ($parent_menu && wantarray && !$no_wantarray) {
                     return '',$FullMenu,$Selected,$Conveyed,
                            $SavePick,$SaveMMap,$SaveNext,
                            $Persists,$parent_menu,$@;
                  }
                  if (defined $log_handle &&
                        -1<index $log_handle,'*') {
                     print $log_handle $@;
                     close($log_handle);
                  }
                  if ($Term::Menus::fullauto) {
                     &Net::FullAuto::FA_Core::handle_error($@);
                  } else { die $@ }
               } else {
                  my $die="\n       FATAL ERROR! - The Local "
                         ."System $Term::Menus::local_hostname "
                         ."Conveyed\n"
                         ."              the Following "
                         ."Unrecoverable Error Condition :\n\n"
                         ."       $@\n       line ".__LINE__;
                  if ($parent_menu && wantarray && !$no_wantarray) {
                     return '',$FullMenu,$Selected,$Conveyed,
                            $SavePick,$SaveMMap,$SaveNext,
                            $Persists,$parent_menu,$die;
                  }
                  if (defined $log_handle &&
                        -1<index $log_handle,'*') {
                     print $log_handle $die;
                     close($log_handle);
                  }
                  if ($Term::Menus::fullauto) {
                     &Net::FullAuto::FA_Core::handle_error($die);
                  } else { die $die }
               }
            }
            if (0==$#convey && $convey[0]=~/^(?:[{](.*)[}])?[<]$/) {
               return \@convey;
            }
         } elsif ($convey_test=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
               grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
            if (defined $picks_from_parent &&
                          !ref $picks_from_parent) {
               my $transformed_convey=
                     &transform_pmsi($Items{$num}->{Convey},
                                     $Conveyed,$SaveMMap,
                                     $picks_from_parent);
               if ($transformed_convey!~/::/) {
                  $transformed_convey=~s/^[&]//;
                  eval "\@convey=main::$transformed_convey";
               } else {
                  eval "\@convey=$transformed_convey";
               }
            }
         } else {
            push @convey, $Items{$num}->{Convey};
         }
         foreach my $item (@convey) {
            next if $item=~/^\s*$/s;
            my $text=$Items{$num}->{Text};
            $text=~s/$con_regex/$item/g;
            $text=&transform_pmsi($text,
                  $Conveyed,$SaveMMap,
                  $picks_from_parent);
            if (-1<index $text,"__Master_${$}__") {
               $text=~
                  s/__Master_${$}__/Local-Host: $Term::Menus::local_hostname/sg;
               $master_substituted="Local-Host: $Term::Menus::local_hostname";
            }
            if (exists $Items{$num}->{Include}) {
               if ($text=~/$Items{$num}->{Include}/s) {
                  next if exists $Items{$num}->{Exclude} &&
                        $text=~/$Items{$num}->{Exclude}/;
                  push @{$picks}, $text;
               } else {
                  next;
               }
            } elsif (exists $Items{$num}->{Exclude} &&
               $text=~/$Items{$num}->{Exclude}/) {
               next;
            } else {
               push @{$picks}, $text;
            }
            if (exists $Items{$num}->{Convey} &&
                  $Items{$num}->{Convey} ne '') {
               $convey{$text}=[$item,$Items{$num}->{Convey}];
            } elsif (!exists $Items{$num}->{Convey}) {
               $convey{$text}=[$item,''];
            }
            $default{$text}=$Items{$num}->{Default}
               if exists $Items{$num}->{Default};
#print "WHAT IS THIS=$text and NEGATE=",$Items{$num}->{Negate}," and KEYS=",keys %{$Items{$num}},"\n";
            $negate{$text}=$Items{$num}->{Negate}
               if exists $Items{$num}->{Negate};
            if (exists $FullMenu->{$MenuUnit_hash_ref}[2]{$text}) {
               $result{$text}=
                  $FullMenu->{$MenuUnit_hash_ref}[2]{$text};
            } elsif (exists $Items{$num}->{Result}) {
               $result{$text}=$Items{$num}->{Result}
            }
            my $tsttt=$Items{$num}->{Select};
            $select{$text}=$Items{$num}->{Select}
               if exists $Items{$num}->{Select}
               && $tsttt=~/many/i;
            if (exists $Items{$num}->{Mark}) {
               $mark{$text}=$Items{$num}->{Mark};
               my $lmt=length $mark{$text};
               $mark{BLANK}=$lmt if $mark{BLANK}<$lmt;
            }
            $filtered=1 if exists $Items{$num}->{Filter};
            $sorted=$Items{$num}->{Sort}
               if exists $Items{$num}->{Sort};
            $chosen{$text}="Item_$num";
         }
      } elsif ($show_banner_only) {
         if (exists $MenuUnit_hash_ref->{Result}) {
            $result{'__FA_Banner__'}=$MenuUnit_hash_ref->{Result};
         } last;
      } else {
         my $text=&transform_pmsi($Items{$num}->{Text},
                  $Conveyed,$SaveMMap,
                  $picks_from_parent);
         if (-1<index $Items{$num}->{Text},"__Master_${$}__") {
            $text=~
               s/__Master_${$}__/Local-Host: $Term::Menus::local_hostname/sg;
            $master_substituted=
                             "Local-Host: $Term::Menus::local_hostname";
         }
         if (exists $Items{$num}->{Include}) {
            if ($Items{$num}->{Text}=~/$Items{$num}->{Include}/) {
               next if exists $Items{$num}->{Exclude} &&
                     $Items{$num}->{Text}=~/$Items{$num}->{Exclude}/;
               push @{$picks}, $text;
            } else { next }
         } elsif (exists $Items{$num}->{Exclude} &&
            $Items{$num}->{Text}=~/$Items{$num}->{Exclude}/) {
            next;
         } else { push @{$picks}, $text }
         $convey{$Items{$num}->{Text}}=['',$Items{$num}->{Convey}]
            if exists $Items{$num}->{Convey};
         $default{$text}=$Items{$num}->{Default}
            if exists $Items{$num}->{Default};
         $negate{$text}=$Items{$num}->{Negate}
            if exists $Items{$num}->{Negate};
         if (exists $FullMenu->{$MenuUnit_hash_ref}[2]{$text}) {
            $result{$text}=
               $FullMenu->{$MenuUnit_hash_ref}[2]{$text};
         } elsif (exists $Items{$num}->{Result}) {
            $result{$text}=$Items{$num}->{Result}
         }
         my $tsttt=$Items{$num}->{Select}||'';
         $select{$text}=$Items{$num}->{Select}
            if exists $Items{$num}->{Select}
            && $tsttt=~/many/i;
         if (exists $Items{$num}->{Mark}) {
            $mark{$text}=$Items{$num}->{Mark};
            my $lmt=length $mark{$text};
            $mark{BLANK}=$lmt if $mark{BLANK}<$lmt;
         }
         $filtered=1 if exists $Items{$num}->{Filter};
         $sorted=$Items{$num}->{Sort}
            if exists $Items{$num}->{Sort};
         $chosen{$text}="Item_$num";
         $num__{$text}=$Items{$num}->{__NUM__}
            if exists $Items{$num}->{__NUM__};
      }
   }


      #########################################
      # End Items Breakdown

   $display_this_many_items=$_[0]->{Display}
      if exists $_[0]->{Display};

   if (exists $MenuUnit_hash_ref->{Scroll} &&
         ref $MenuUnit_hash_ref->{Scroll} ne 'ARRAY') {
      $MenuUnit_hash_ref->{Scroll}=
         [ $MenuUnit_hash_ref->{Scroll},1 ];
   }

   ############################################
   # End MenuUnit Breakdown
   ############################################

   %default=() if defined $FullMenu->{$MenuUnit_hash_ref}[5];
   my $nm_=(keys %num__)?\%num__:{};
#print "MENU=",$MenuUnit_hash_ref->{Name}," and CONVEY=",keys %convey,"\n";<STDIN>;
   $FullMenu->{$MenuUnit_hash_ref}=[ $MenuUnit_hash_ref,
      \%negate,\%result,\%convey,\%chosen,\%default,
      \%select,\%mark,$nm_,$filtered,$picks,$start ];
   if ($select_many || keys %{$MenuUnit_hash_ref->{Select}}) {
      my @filtered_menu_return=();
      my $error='';
      ($pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveMMap,$SaveNext,$Persists,$parent_menu,
              @filtered_menu_return,$error)=&pick(
                        $picks,$MenuUnit_hash_ref->{Banner}||'',
                        $display_this_many_items,'','',
                        $MenuUnit_hash_ref,++$recurse,
                        $picks_from_parent,$parent_menu,
                        $FullMenu,$Selected,$Conveyed,$SavePick,
                        $SaveMMap,$SaveNext,$Persists,
                        $no_wantarray,$sorted,
                        $select_many);
      if (-1<$#filtered_menu_return) {
         return $pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveMMap,$SaveNext,$Persists,$parent_menu,
              $filtered_menu_return[0],$filtered_menu_return[1],
              $filtered_menu_return[2];
      }
      if ($Term::Menus::fullauto && $master_substituted) {
         $pick=~s/$master_substituted/__Master_${$}__/sg;
      }
      if ($pick eq ']quit[') {
         return ']quit['
      } elsif ($pick eq '-' || $pick eq '+') {
         return $pick,$FullMenu,$Selected,$Conveyed,
                    $SavePick,$SaveMMap,$SaveNext,$Persists;
      } elsif ($pick=~/DONE/) {
         return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
      } elsif (ref $pick eq 'ARRAY' && wantarray
            && !$no_wantarray && 1==$recurse) {
         if (ref $pick->[$#{$pick}] eq 'HASH') {
            my @choyce=@{$pick};undef @{$pick};undef $pick;
            pop @choyce;
            pop @choyce;
            return @choyce
         }
         my @choyce=@{$pick};undef @{$pick};undef $pick;
         return @choyce
      } elsif ($pick) { return $pick }
   } else {
      my @filtered_menu_return=();
      my $error='';
      ($pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveMMap,$SaveNext,$Persists,$parent_menu,
              @filtered_menu_return,$error)
              =&pick($picks,$MenuUnit_hash_ref->{Banner}||'',
                       $display_this_many_items,
                       '','',$MenuUnit_hash_ref,++$recurse,
                       $picks_from_parent,$parent_menu,
                       $FullMenu,$Selected,$Conveyed,$SavePick,
                       $SaveMMap,$SaveNext,$Persists,
                       $no_wantarray,$sorted,
                       $select_many);
      if (-1<$#filtered_menu_return) {
         return $pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveMMap,$SaveNext,$Persists,$parent_menu,
              $filtered_menu_return[0],$filtered_menu_return[1],
              $filtered_menu_return[2];
      }
#print "WAHT IS ALL=",keys %{$pick->[0]}," and FULL=$FullMenu and SEL=$Selected and CON=$Conveyed and SAVE=$SavePick and LAST=$SaveMMap and NEXT=$SaveNext and PERSISTS=$Persists  and PARENT=$parent_menu<==\n";
      if ($Term::Menus::fullauto && $master_substituted) {
         $pick=~s/$master_substituted/__Master_${$}__/sg;
      }
      if ($pick eq ']quit[') {
         return ']quit['
      } elsif ($pick eq '-' || $pick eq '+') {
         unless (keys %{$SavePick->{$MenuUnit_hash_ref}}) {
            return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
         } elsif ($select_many || keys %{$Selected->{$MenuUnit_hash_ref}}) {
            return '+',$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
         } else {
            return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
         }
      } elsif ($pick=~/DONE/) {
         return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
      } elsif (ref $pick eq 'ARRAY') {
         my $topmenu='';
         my $savpick='';
         if (1==$recurse && ref $pick->[$#{$pick}] eq 'HASH') {
            $topmenu=pop @{$pick};
            $savpick=pop @{$pick};
         }
         if (wantarray && 1==$recurse) {
            my @choyce=@{$pick};undef @{$pick};undef $pick;
            return @choyce
         } elsif (ref $pick eq 'ARRAY' && -1<$#{$pick} &&
               $pick->[0]=~/^[{](.*)[}][<]$/) {
            return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
         } elsif (!$picks_from_parent &&
               !(keys %{$MenuUnit_hash_ref->{Select}})) {
            if (ref $topmenu eq 'HASH' && (keys %{$topmenu->{Select}} &&
                  $topmenu->{Select} eq 'Many') || (ref $savpick eq 'HASH' &&
                  exists $topmenu->{Select}->{(keys %{$savpick})[0]})) {
               if (wantarray) {
                  return @{$pick}
               } else {
                  return $pick; 
               }
            } elsif (-1==$#{$pick} &&
                  (ref $topmenu eq 'HASH') &&
                  (grep { /Item_/ } keys %{$topmenu})) {
               return [ $topmenu ];
            } else {
               return $pick->[0];
            }
         } else {
            if ($picks_from_parent) {
               $pick->[0]=&transform_pmsi($pick->[0],
                  $Conveyed,$SaveMMap,$picks_from_parent);
            }
            return $pick
         }
      } elsif ($pick) { return $pick }
   }

}

sub pw {

   ## pw [p]ad [w]alker
   #print "PWCALLER=",caller,"\n";
   return $_[0]->{Name} if ref $_[0] eq 'HASH'
      && exists $_[0]->{Name};
   my @packages=();
   @packages=@{$_[1]} if defined $_[1] && $_[1];
   my $name='';
   unless (ref $_[0] eq 'HASH') {
      return '';
   } else {
      my $flag=1;
      my $n=0;
      WH: while (1) {
         {
            local $SIG{__DIE__}; # No sigdie handler
            eval {
               $name=PadWalker::var_name($n++,$_[0]);
            };
            if ($@) {
               undef $@;
               my $o=0;
               while (1) {
                  eval {
                     my $vars=PadWalker::peek_our($o++);
                     foreach my $key (keys %{$vars}) {
                        if (ref $vars->{$key} eq 'HASH' &&
                              %{$_[0]} eq %{$vars->{$key}}) {
                           $name=$key;
                           last;
                        } 
                     }
                  };
                  if ($@) {
                     undef $@;
                     my $s=0;
                     unshift @packages, 'main';
                     PK: foreach my $package (@packages) {
                        my $obj=Devel::Symdump->rnew($package);
                        foreach my $hash ($obj->hashes) {
                           next if $hash=~/^_</;
                           next if $hash=~/^Term::Menus::/;
                           next if $hash=~/^Config::/;
                           next if $hash=~/^DynaLoader::/;
                           next if $hash=~/^warnings::/;
                           next if $hash=~/^utf8::/;
                           next if $hash=~/^Carp::/;
                           next if $hash=~/^fields::attr/;
                           next if $hash=~/^Text::Balanced::/;
                           next if $hash=~/^Data::Dump::Streamer/;
                           next if $hash=~/^re::EXPORT_OK/;
                           next if $hash=~/^fa_code::email_addresses/;
                           next if $hash=~/^fa_code::email_defaults/;
                           next if $hash=~/^PadWalker::/;
                           next if $hash=~/^Fcntl::/;
                           next if $hash=~/^B::Utils::/;
                           next if $hash=~/^ExtUtils::/;
                           next if $hash=~/^Exporter::/;
                           next if $hash=~/^Moo::/;
                           next if $hash=~/^overload::/;
                           next if $hash=~/^Term::ReadKey::/;
                           next if $hash=~/^main::INC/;
                           next if $hash=~/^main::SIG/;
                           next if $hash=~/^main::ENV/;
                           next if $hash=~/^main[:][^\w]*$/;
                           next if $hash=~/^main::[@]$/;
                           next if $hash=~/^Net::FullAuto::FA_Core::makeplan/;
                           next if $hash=~
                              /^Net::FullAuto::FA_Core::admin_menus/;
                           my %test=eval "%$hash";
                           $name=$hash if %test eq %{$_[0]};
                           last PK if $name;
                        }
                     }
                     $name||='';
                     $name=~s/^.*::(.*)$/$1/;
                     last WH;
                  }
                  last WH if $name;
               }
            }
            last if $name;
         };
      }
      $name||='';
      $name=~s/^%//;
      return $name if $name;
   }
}

sub list_module {
   my @modules = @_;
   my @result=();
   no strict 'refs';
   foreach my $module (@modules) {
      $module=~s/\.pm$//;
      push @result,grep { defined &{"$module\::$_"} } keys %{"$module\::"};
   }
   return @result;
}

sub test_hashref {

   my $hashref_to_test=$_[0];
   if (ref $hashref_to_test eq 'HASH') {
      if (grep { /Item_/ } keys %{$hashref_to_test}) {
         return 1;
      } elsif (exists $hashref_to_test->{Input} &&
            $hashref_to_test->{Input}) {
         return 1; 
      } elsif (!grep { /Item_/ } keys %{$hashref_to_test} 
            && grep { /Banner/ } keys %{$hashref_to_test}) {
         return 1;
      } else {
         my $die="\n      FATAL ERROR! - Unable to verify Menu\n"
             ."\n      This Error is usually the result of a Menu"
             ."\n           block that does not contain properly"
             ."\n           coded Item blocks or was not coded"
             ."\n           ABOVE the parent Menu hash block"
             ."\n           (Example: 1), or not coded with"
             ."\n           GLOBAL scope (Example: 2).\n"
             ."\n      Example 1:"
             ."\n                   my %Example_Menu=( \# ABOVE parent"
             ."\n                                      \# Best Practice"
             ."\n                      Item_1 => {"
             ."\n                         Text   => 'Item Text',"
             ."\n                      },"
             ."\n                   );"
             ."\n                   my %Parent_Menu=(\n"
             ."\n                      Item_1 => {"
             ."\n                         Text   => 'Item Text',"
             ."\n                         Result => \%Example_Menu,"
             ."\n                      },"
             ."\n                   );\n"
             ."\n"
             ."\n      Example 2:"
             ."\n                   my %Parent_Menu=(\n"
             ."\n                      Item_1 => {"
             ."\n                         Text   => 'Item Text',"
             ."\n                         Result => \%Example_Menu,"                             
             ."\n                      },"
             ."\n                   );"
             ."\n                   our %Example_Menu=( \# GLOBAL scope"
             ."\n                                       \# Note: 'our' pragma"
             ."\n                      Item_1 => {"
             ."\n                         Text   => 'Item Text',"
             ."\n                      },"
             ."\n                   );\n"
             ."\n";
         die $die;
      }
   } else { return 0 }

}

sub transform_sicm
{

#print "TRANSFORM_SICM_CALLER=",caller,"\n";
   ## sicm - [s]elected [i]tems [c]urrent [m]enu
   my $text=$_[0]||'';
   my $numbor=$_[1]||-1;
   my $all_menu_items_array=$_[2]||'';
   my $picks=$_[3]||'';
   my $pn=$_[4]||'';
   my $return_from_child_menu=$_[5]||'';
   my $log_handle=$_[6]||'';
   my $current_menu_name=$_[7]||'';
   my $selected=[];my $replace='';
   my $expand_array_flag=0;
   my $sicm_regex=
      qr/\](!)?s(?:e+lected[-_]*)*i*(?:t+ems[-_]*)
         *c*(?:u+rrent[-_]*)*m*(?:e+nu[-_]*)*\[/xi;
   my $tsmi_regex=qr/\](!)?t(?:e+st[-_]*)*s*(?:e+lected[-_]*)
         *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   if ((-1<index $text,'][[') && (-1<index $text,']][')) {
      unless ($text=~/^\s*\]\[\[\s*/s && $text=~/\s*\]\]\[\s*$/s) {
         my $die="\n       FATAL ERROR! - The --RETURN-ARRAY-- Macro"
                ."\n            Boundary indicators: '][[' and ']]['"
                ."\n            are only supported at the beginning"
                ."\n            and end of the return instructions."
                ."\n            Nothing but white space should precede"
                ."\n            the left indicator, nor extend beyond"
                ."\n            the right indicator.\n"
                ."\n       Your String:\n"
                ."\n            $text\n"
                ."\n       Remedy: Recreate your return instructions"
                ."\n            to conform to this convention. Also"
                ."\n            be sure to use the Macro delimiter"
                ."\n            indicator ']|[' to denote return array"
                ."\n            element separation boundaries."
                ."\n       Example:\n"
                ."\n            '][[ ]S[ ]|[ ]P[{Menu_One} ]|[ SomeString ]]['"
                ."\n";
         if (defined $log_handle &&
               -1<index $log_handle,'*') {
            print $log_handle $die;
            close($log_handle);
         }
      }
      $expand_array_flag=1;
   }
   my @pks=keys %{$picks};
   if (0<$#pks && !$return_from_child_menu) {
      foreach my $key (sort numerically keys %{$picks}) {
         push @{$selected},$all_menu_items_array->[$key-1];
      }
      $replace=&Data::Dump::Streamer::Dump($selected)->Out();
      $replace=~s/\$ARRAY\d*\s*=\s*//s;
      $replace=~s/\;\s*$//s;
      if ($expand_array_flag) {
         $replace='eval '.$replace;
      }
      $replace=~s/\'/\\\'/sg;
   } else {
      if (ref $pn eq 'HASH') {
         $pn->{$numbor}->[1]||=1; #COMEHERE
         $replace=$all_menu_items_array->[$pn->{$numbor}->[1]-1];
      } elsif ($pn) {
         $replace=$all_menu_items_array->[$pn];
      } else {
         $replace=$all_menu_items_array->[$numbor-1]||'';
      }
      $replace=~s/\'/\\\'/g;
      $replace=~s/\"/\\\"/g;
      $replace='"'.$replace.'"' unless
         $text=~/^&?(\w+)\s*[(]["'].*["'][)]\s*$/;
   }
   my $test_regx_flag=0;
   FE: foreach my $regx ($tsmi_regex,$sicm_regex) {
      last if $test_regx_flag;
      while ($text=~m/($regx(?:\\\{([^}]+)\})*)/sg) {
         $test_regx_flag=1 if -1<index $regx,'(!)?t(?:';
         my $esc_one=$1;
         my $bang=$2;
         my $menu=$3;
         $menu||='';
         $esc_one=~s/\[/\\\[/;$esc_one=~s/\]/\\\]/;
         $replace=~s/\s*//s if $text=~/[)]\s*$/s;
         if ($menu) {
            if (-1<index $menu, $current_menu_name) {
               $text=~s/$esc_one/$replace/sg;
            } else {
               $test_regx_flag=0;
            }
            next;
         }
         $text=~s/$esc_one(?![{])/$replace/g;
      }
   }
   return $text;

}

sub transform_mbio
{

   my $text=$_[0]||'';
   my $input=$_[1]||{};
   my $MenuUnit_hash_ref=$_[2]||{};
   my $Conveyed=$_[3]||'';
   my $SaveMMap=$_[4]||'';
   my $picks_from_parent=$_[5]||'';
   my $log_handle=$_[6]||'';
   my $tobi_regex=qr/\](!)?o(?:u+tput[-_]*)*b*(?:a+nner[-_]*)
         *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my $test_regx_flag=0;
   FE: foreach my $regx ($tobi_regex) {
      last if $test_regx_flag;
      while ($text=~m/($regx(?:\{[^}]+\})*)/sg) {
         $test_regx_flag=1 if -1<index $regx,'(!)?t(?:';
         my $esc_one=$1;my $bang=$2;
         my $length_of_macro=length $esc_one;
         $esc_one=~s/["]\s*[.]\s*["]//s;
         my $esc_two=$esc_one;
         $esc_two=~s/\]/\\\]/;$esc_two=~s/\[/\\\[/;
         $esc_one=~s/^\]/\[\]\]/;$esc_one=~s/^(.*?)\[\{/$1\[\[\]{/;
         $esc_one=~s/^(.*?[]])[{](.*)[}]$/$1\[\{\]$2\[\}\]/;
         my $instructions=$esc_two;
         $instructions=~s/^\\[]][^[]+\\[[]\s*[{](.*?)[}]$/$1/;
         $instructions=~/^(.*?),(.*?)$/;
         my $input_macro=$1;my $code=$2;
         $code=~s/["']//g;
         $code="\$main::$code";
         my $input_text=$input->{$input_macro};
         $code=eval $code;
         my $cd=&Data::Dump::Streamer::Dump($code)->Out();
         $cd=&transform_pmsi($cd,
              $Conveyed,$SaveMMap,
              $picks_from_parent);
         $cd=~s/\$CODE\d*\s*=\s*//s;
         $code=eval $cd;
         my $output='';
         $output=$code->($input_text) if $input_text!~/^\s*$/;
         my $out_height=$output=~tr/\n//;
         my @output=split /\n/,$output;
         my @newtext=();
         foreach my $line (split "\n",$text) {
            if ($line=~/^(.*)$esc_one(.*)$/) {
               my $front_of_line=$1;my $back_of_line=$2;
               my $frlen=length $front_of_line;
               my $bottomline=pop @output||'';
               $bottomline=$front_of_line.$bottomline.$back_of_line;
               foreach my $ln (@output) {
                  my $pad=sprintf "%-${frlen}s",'';
                  push @newtext,$pad.$ln;
               }
               push @newtext,$bottomline;
            } else {
               push @newtext,$line;
            } 
         } $text=join "\n",@newtext;
      }
   }
   return $text,$input;

}

sub transform_mbir
{

   ## mbir - [m]enu [b]anner [i]nput [r]esults
   my $text=$_[0]||'';
   my $Conveyed=$_[1]||{};
   my $MenuUnit_hash_ref=$_[2]||'';
   my $log_handle=$_[3]||'';
   my $tbii_regex=qr/\](!)?i(?:n+put[-_]*)*b*(?:a+nner[-_]*)
         *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my $test_regx_flag=0;
   FE: foreach my $regx ($tbii_regex) {
      last if $test_regx_flag;
      while ($text=~m/($regx(?:\{[^}]+\})*)/sg) {
         $test_regx_flag=1 if -1<index $regx,'(!)?t(?:';
         my $esc_one=$1;my $bang=$2;
         my $length_of_macro=length $esc_one;
         $esc_one=~s/["]\s*[.]\s*["]//s;
         $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
         my $instructions=$esc_one;
         $instructions=~s/^\\[]][^[]+\\[[]\s*[{](.*?)[}]$/$1/;
         $instructions='('.$instructions.')';
         my @instructions=eval $instructions;
         next if $#instructions==2;
         if ($#instructions==1) {
            if (exists $Conveyed->{$instructions[0].'_mbir'}) {
               my $item=$instructions[0].'_mbir';
               my $replace=$Conveyed->{$item}->{$instructions[1]};
               $esc_one=~s/[{]/\\{/g;
               $text=~s/$esc_one/$replace/s;
            }
         }
      }
   } return $text;
}

sub transform_mbii
{

   ## mbii - [m]enu [b]anner [i]nput [i]tems
   my $text=$_[0]||'';
   my $numbor=(defined $_[1])?$_[1]:'';
   my $ikey=$_[2]||'';
   my $input=$_[3]||{};
   my $MenuUnit_hash_ref=$_[4]||{};
   my $Conveyed=$_[5]||'';
   my $log_handle=$_[6]||'';
   my $tbii_regex=qr/\](!)?i(?:n+put[-_]*)*b*(?:a+nner[-_]*)
         *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my $test_regx_flag=0;
   if ($ikey eq 'TAB' && exists $input->{focus}) {
      $input->{focus}->[0]=$input->{focus}->[2]->{$input->{focus}->[0]};
      $ikey='';$numbor='';
   }
   
   FE: foreach my $regx ($tbii_regex) {
      last if $test_regx_flag;
      my $fill_focus=0;
      $fill_focus=1 unless exists $input->{focus};
      while ($text=~m/($regx(?:\{[^}]+\})*)/sg) {
         $test_regx_flag=1 if -1<index $regx,'(!)?t(?:';
         my $esc_one=$1;my $bang=$2;
         my $length_of_macro=length $esc_one;
         $esc_one=~s/["]\s*[.]\s*["]//s;
         my $esc_two=$esc_one;
         $esc_two=~s/\]/\\\]/;$esc_two=~s/\[/\\\[/;
         $esc_one=~s/^\]/\[\]\]/;$esc_one=~s/^(.*?)\[\{/$1\[\[\]{/;
         $esc_one=~s/^(.*?[]])[{](.*)[}]$/$1\[\{\]$2\[\}\]/;
         my $instructions=$esc_two;
         $instructions=~s/^\\[]][^[]+\\[[]\s*[{](.*?)[}]$/$1/;
         $instructions='('.$instructions.')';
         my @instructions=eval $instructions;
         unless (exists $input->{$instructions[0]}) {
            $input->{$instructions[0]}=$instructions[1];
            $numbor='';
         }
         $input->{$instructions[0]}='' unless defined
            $input->{$instructions[0]};
         if ($fill_focus) {
            unless (exists $input->{focus}) {
               my $default_focus=$instructions[0];
               if (exists $MenuUnit_hash_ref->{Focus} &&
                     $MenuUnit_hash_ref->{Focus}) {
                  $default_focus=$MenuUnit_hash_ref->{Focus};
               }  
               $input->{focus}=[$default_focus,[$instructions[0]],{}];
            } else {
               $input->{focus}->[2]->{
                  $input->{focus}->[1][$#{$input->{focus}->[1]}]}
                  =$instructions[0];
               push @{$input->{focus}->[1]},$instructions[0];
               $input->{focus}->[2]->{$instructions[0]}=
                  $input->{focus}->[1]->[0];
            }
         }
         my @newtext=();
         foreach my $line (split "\n",$text) {
            if ($line=~/^(.*)$esc_one(.*)$/) {
               my $front_of_line=$1;my $back_of_line=$2;
               my $box_top_bottom='';my @sides=('| ',' |');
               if ($#instructions==2 and $instructions[2]>0) {
                  if ($input->{focus}->[0] eq $instructions[0]) {
                     for (1..$instructions[2]) {
                        $box_top_bottom.='=';
                     }
                     @sides=('[ ',' ]');
                  } else {
                     for (1..$instructions[2]) {
                        $box_top_bottom.='-';
                     }
                  }
               }
               if ($input->{focus}->[0] eq $instructions[0]) {
                  if ($ikey eq 'BACKSPACE') {
                     chop $input->{$instructions[0]};
                  } elsif ($ikey eq 'DELETE') {
                     $input->{$instructions[0]}='';
                  } elsif ($ikey ne 'TAB' && defined $numbor) {
                     my $length_input=length $input->{$instructions[0]};
                     my $length_box=$instructions[2];
                     if ($length_input>$length_box) {
                        print "\n\n   WARNING! - input exceeds box size!";
                        print "\n\n   You may have forgotten to [TAB] to the".
                              "\n   next box, or the input for the next box".
                              "\n   box has a TAB in it - usually at the".
                              "\n   front of the string. Use a text editor".
                              "\n   to see and remove it before pasting".
                              "\n   input.";
                        print "\n\n   Press to continue ...\n\n";
                        sleep 1;
                        <STDIN>;
                     }
                     $input->{$instructions[0]}.=$numbor;
                  }
               }
               my $insert=$sides[0];
               $insert.=$input->{$instructions[0]};
               $Conveyed->{&pw($MenuUnit_hash_ref).'_mbir'}->
                  {$instructions[0]}=$input->{$instructions[0]};
               my $insert_num_of_spaces=$instructions[2]-2;
               $insert=sprintf "%-${insert_num_of_spaces}s",$insert;
               $insert.=$sides[1];
               my $frlen=length $front_of_line;
               my $box_top_line='';
               my $box_mid_line='';
               my $box_bot_line='';
               my $length_of_front_and_macro=$frlen+$length_of_macro;
               if ($#newtext==-1 || $#newtext==0) {
                  $box_top_line=sprintf "%-${frlen}s",'';
                  $box_top_line.=$box_top_bottom;
               } else {
                  my $front_of_box_top=unpack("a$frlen",$newtext[$#newtext-1]);
                  $front_of_box_top=sprintf "%-${frlen}s",$front_of_box_top
                     if length $front_of_box_top<$frlen;
                  my $back_of_box_top='';
                  if ($length_of_front_and_macro<=length
                        $newtext[$#newtext-1]) {
                     $back_of_box_top=unpack("x$length_of_front_and_macro a*",
                        $newtext[$#newtext-1]);
                  }
                  $box_top_line=$front_of_box_top.
                     $box_top_bottom.$back_of_box_top;
               }
               if ($#newtext==-1) {
                  $box_mid_line=sprintf "%-${frlen}s",'';
                  $box_mid_line.=$insert;
               } else {
                  my $elem=($#newtext==0)?0:$#newtext;
                  my $front_of_box_mid=sprintf "%-${frlen}s",'';
                  if ($newtext[$elem]!~/^\s*$/) {
                     $front_of_box_mid=unpack("a$frlen",$newtext[$elem]);
                     $front_of_box_mid=sprintf "%-${frlen}s",$front_of_box_mid
                        if length $front_of_box_mid<$frlen;
                  }
                  my $back_of_box_mid='';
                  if ($length_of_front_and_macro<=length $newtext[$elem]) {
                     $back_of_box_mid=unpack("x$length_of_front_and_macro a*",
                        $newtext[$elem]);
                  }
                  $box_mid_line=$front_of_box_mid.
                     $insert.$back_of_box_mid;
               }
               $box_bot_line=$front_of_line.$box_top_bottom.$back_of_line;
               if ($#newtext==-1) {
                  push @newtext,$box_top_line;
                  push @newtext,$box_mid_line;
               } elsif ($#newtext==0) {
                  unshift @newtext,$box_top_line;
                  $newtext[1]=$box_mid_line;
               } else {
                  $newtext[$#newtext-1]=$box_top_line;
                  $newtext[$#newtext]=$box_mid_line;
               } push @newtext, $box_bot_line;
            } else {
               push @newtext,$line;
            }
         } $text=join "\n",@newtext;
      }
   } return $text, $input;
}

sub transform_pmsi
{

#print "TRANSFORM_PMSI CALLER=",caller,"\n";
   ## pmsi - [p]revious [m]enu [s]elected [i]tems 
   my $text=$_[0]||'';
   my $Conveyed=$_[1]||'';
   my $SaveMMap=$_[2]||'';
   my $picks_from_parent=$_[3]||'';
   my $log_handle=$_[4]||'';
   my $expand_array_flag=0;
   my $tpmi_regex=qr/\](!)?t(?:e+st[-_]*)*p*(?:r+vious[-_]*)
         *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my $pmsi_regex=qr/\](!)?p(?:r+evious[-_]*)*m*(?:e+nu[-_]*)
         *s*(?:e+lected[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my $amlm_regex=qr/\]a(n+cestor[-_]*)*m*(e+nu[-_]*)
         *l*(a+bel[-_]*)*m*(a+p[-_]*)*\[/xi;
   $text=~s/\s?$//s;
   if ((-1<index $text,'][[') && (-1<index $text,']][')) {
      unless ($text=~/^\s*\]\[\[\s*/s && $text=~/\s*\]\]\[\s*$/s) {
         my $die=<<DIE;

       FATAL ERROR! - The --RETURN-ARRAY-- Macro
            Boundary indicators: '][[' and ']]['
            are only supported at the beginning
            and end of the return instructions.
            Nothing but white space should precede
            the left indicator, nor extend beyond
            the right indicator.
       Your String:
            $text
       Remedy: Recreate your return instructions
            to conform to this convention. Also
            be sure to use the Macro delimiter
            indicator ']|[' to denote return array
            element separation boundaries.
       Example:
            '][[ ]S[ ]|[ ]P[{Menu_One} ]|[ SomeString ]]['
DIE
         if (defined $log_handle &&
               -1<index $log_handle,'*') {
            print $log_handle $die;
            close($log_handle);
         }
      }
      $expand_array_flag=1;
   }
   my $test_regx_flag=0;
   FE: foreach my $regx ($tpmi_regex,$pmsi_regex) {
      last if $test_regx_flag;
      while ($text=~m/($regx(?:\{[^}]+\})*)/sg) {
         $test_regx_flag=1 if -1<index $regx,'(!)?t(?:';
         my $esc_one=$1;my $bang=$2;
         $esc_one=~s/["]\s*[.]\s*["]//s;
         $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
         $esc_one=~s/[{]/\\\{\(/;$esc_one=~s/\}/\)\}/;
         while ($esc_one=~/[{]/ && $text=~m/$esc_one/) {
            unless (exists $Conveyed->{$1} || $bang || $test_regx_flag) {
               my $die="\n\n       FATAL ERROR! - The Menu Name:  \"$1\""
                      ."\n            describes a Menu that is *NOT* in the"
                      ."\n            invocation history of this process.\n"
                      ."\n       This Error is *usually* the result of a missing,"
                      ."\n            Menu, a Menu block that was not global or"
                      ."\n            was not coded ABOVE the parent Menu hash"
                      ."\n            block. (See Example)\n"
                      ."\n       Also be sure to use a UNIQUE name for every"
                      ."\n            Menu.\n"
                      ."\n       Example:   my %Example_Menu=(\n"
                      ."\n                     Item_1 => {"
                      ."\n                            ...   # ]P[ is a Macro 'Previous'"
                      ."\n                        Result => sub { return ']P[{Parent_Menu}' },"
                      ."\n                  );"
                      ."\n                  my %Parent_Menu=(\n"
                      ."\n                     Item_1 => {"
                      ."\n                            ..."
                      ."\n                        Result => \\%Example_Menu,"
                      ."\n                            ..."
                      ."\n                  );\n"
                      ."\n       *HOWEVER*: Read the Documentation on \"stepchild\""
                      ."\n                  and other deeply nested menus. There are"
                      ."\n                  scenarios with dynamically generated menus"
                      ."\n                  where Term::Menus simply cannot test for"
                      ."\n                  menu stack integrity when it encounters"
                      ."\n                  unexpanded macros in defined but ungenerated"
                      ."\n                  menus. In these situations this error"
                      ."\n                  message should be turned off by using the"
                      ."\n                  \"test\" macro ( ]T[ ) or using an"
                      ."\n                  exclamation point character with either"
                      ."\n                  or both the ]S[ (becomes ]!S[) and ]P["
                      ."\n                  (becomes ]!P[) macros.\n\n";
               if (defined $log_handle &&
                     -1<index $log_handle,'*') {
                  print $log_handle $die;
                  close($log_handle);
               }
               if ($Term::Menus::fullauto) {
                  &Net::FullAuto::FA_Core::handle_error($die);
               } else { die $die }
            }
            unless ($Conveyed->{$1}) {
               $test_regx_flag=0;
               next FE
            }
            my $replace=$Conveyed->{$1};
            if (ref $replace) {
               $replace=&Data::Dump::Streamer::Dump($Conveyed->{$1})->Out();
               my $type=ref $Conveyed->{$1};
               $replace=~s/\$$type\d*\s*=\s*//s;
               $replace=~s/\'/\\\'/sg;
               if ($expand_array_flag) {
                  $replace='eval '.$replace;
               }
            }
            if ($text=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
                  grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
               $replace=~s/\'/\\\'/g;
               $replace=~s/\"/\\\"/g;
               $replace='"'.$replace.'"' unless
                  $text=~/^&?(\w+)\s*[(]["'].*["'][)]\s*$/;
            }
            if ($replace=~/^.(?<!["']).*(?!["']).?$/s && $replace=~/\s/s) {
               $replace='"'.$replace.'"' if
                  $text!~/^&?(\w+)\s*[(]["'].*["'][)]\s*$/ &&
                  $replace!~/^eval /;
            }
            $text=~s/$esc_one/$replace/se;
         }
         my $replace='';
         if (ref $picks_from_parent eq 'ARRAY') {
            $replace=&Data::Dump::Streamer::Dump($picks_from_parent)->Out();
            my $type=ref $picks_from_parent;
            $replace=~s/\$$type\d*\s*=\s*//s;
            $replace=~s/\'/\\\'/sg;
            if ($expand_array_flag) {
               $replace='eval '.$replace;
            } elsif ($replace=~/^.(?<!["']).*(?!["']).?$/s && $replace=~/\s/s) {
               $replace='"'.$replace.'"' unless
                  $text=~/^&?(\w+)\s*[(]["'].*["'][)]\s*$/;
            }
         } else {
            $replace=$picks_from_parent;
            if ($replace=~/^.(?<!["']).*(?!["']).?$/s && $replace=~/\s/s) {
               $replace='"'.$replace.'"' unless
                  $text=~/^&?(\w+)\s*[(]["'].*["'][)]\s*$/;
            }

         }
         if ($text=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
               grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
            $replace=~s/\'/\\\'/g;
            $replace=~s/\"/\\\"/g;
            $replace='"'.$replace.'"' if
               $text!~/^&?(?:.*::)*(\w+)\s*[(]["'].*["'][)]\s*$/ &&
               $replace!~/^eval /;
         }
         $text=~s/$esc_one/$replace/s;
      }
   }
   while ($text=~m/($amlm_regex(?:\{[^}]+\})*)/sg) {
      my $esc_one=$1;
      last unless $esc_one;
      $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
      $esc_one=~s/\{/\{\(/;$esc_one=~s/\}/\)\}/;
      my $replace=$Conveyed->{$1};
      if (ref $replace) {
         $replace=&Data::Dump::Streamer::Dump($Conveyed->{$1})->Out();
         my $type=ref $Conveyed->{$1};
         $replace=~s/\$$type\d*\s*=\s*//s;
         $replace=~s/\'/\\\'/sg;
         if ($expand_array_flag) {
            $replace='eval '.$replace;
         }
      }
      $text=~s/$esc_one/$replace/se;
   } return $text;

}

sub pick # USAGE: &pick( ref_to_choices_array,
             #  (Optional)       banner_string,
             #  (Optional)       display_this_many_items,
             #  (Optional)       return_index_only_flag,
             #  (Optional)       log_file_handle,
             #  ----------
             #  For Use With Sub-Menus
             #  ----------
             #  (Optional)       MenuUnit_hash_ref,
             #  (Optional)       recurse_level,
             #  (Optional)       picks_from_parent,
             #  (Optional)       parent_menu,
             #  (Optional)       menus_cfg_file,
             #  (Optional)       Full_Menu_data_structure,
             #  (Optional)       Selected_data_structure,
             #  (Optional)       Conveyed_data_structure,
             #  (Optional)       SavePick_data_structure,
             #  (Optional)       SaveMMap_data_structure,
             #  (Optional)       SaveNext_data_structure,
             #  (Optional)       Persists_data_structure,
             #  (Optional)       no_wantarray_flag,
             #  (Optional)       sorted
             #  (Optional)       select_many )
{

#print "PICKCALLER=",caller," and Argument 7 =>$_[6]<=\n";<STDIN>;

   #  "pick" --> This function presents the user with
   #  with a list of items from which to choose.

   my @all_menu_items_array=@{$_[0]};
   my $banner=defined $_[1] ? $_[1] : "\n   Please Pick an Item :";
   my $display_this_many_items=defined $_[2] ? $_[2] : 10;
   my $return_index_only_flag=(defined $_[3]) ? 1 : 0;
   my $log_handle= (defined $_[4]) ? $_[4] : '';

   # Used Only With Cascasding Menus (Optional)
   my $MenuUnit_hash_ref= (defined $_[5]) ? $_[5] : {};
   my $show_banner_only=0;
   unless (grep { /Item_/ } keys %{$MenuUnit_hash_ref}) {
      if (grep { /Banner/ } keys %{$MenuUnit_hash_ref}) {
         $show_banner_only=1;
      }
   }
   $MenuUnit_hash_ref->{Select}||={};
   my $recurse_level= (defined $_[6]) ? $_[6] : 1;
   my $picks_from_parent= (defined $_[7]) ? $_[7] : '';
   my $parent_menu= (defined $_[8]) ? $_[8] : '';
   my $FullMenu= (defined $_[9]) ? $_[9] : {};
   my $Selected= (defined $_[10]) ? $_[10] : {};
   my $Conveyed= (defined $_[11]) ? $_[11] : {};
   my $SavePick= (defined $_[12]) ? $_[12] : {};
   my $SaveMMap= (defined $_[13]) ? $_[13] : {};
   my $SaveNext= (defined $_[14]) ? $_[14] : {};
   my $Persists= (defined $_[15]) ? $_[15] : {};
   my $no_wantarray= (defined $_[16]) ? $_[16] : 0;
   my $sorted= (defined $_[17]) ? $_[17] : 0;
   my $select_many= (defined $_[18]) ? $_[18] : 0;

   my %items=();my %picks=();my %negate=();
   my %exclude=();my %include=();my %default=();
   my %labels=();
   foreach my $menuhash (keys %{$FullMenu}) {
      my $name=&pw($FullMenu->{$menuhash}[0]);
      if ($name) {
         $FullMenu->{$menuhash}[0]->{Name}=$name;
      } else { next }
      $labels{$name}=$FullMenu->{$menuhash}[0];
   }
   if ($SavePick && exists $SavePick->{$MenuUnit_hash_ref}) {
      %picks=%{$SavePick->{$MenuUnit_hash_ref}};
   }
   my $num_pick=$#all_menu_items_array+1;
   my $caller=(caller(1))[3]||'';
   my $numbor=0;                    # Number of Item Selected
   my $ikey='';                     # rawInput Key - key used
                                    #    to end menu. Can be
                                    #    any non-alphanumeric
                                    #    key like Enter or
                                    #    Right Arrow.
   my $return_from_child_menu=0;

   my $choose_num='';
   my $convey='';
   my $menu_output='';
   my $hidedefaults=0;
   my $start=($FullMenu->{$MenuUnit_hash_ref}[11])?
             $FullMenu->{$MenuUnit_hash_ref}[11]:0;
   my $got_default=0;

   sub delete_Selected
   {

      my $Selected=$_[2];
      my $SavePick=$_[3];
      my $SaveNext=$_[4];
      my $Persists=$_[5];
      if ($_[1]) {
         my $result=$Selected->{$_[0]}{$_[1]};
         delete $Selected->{$_[0]}{$_[1]};
         delete $SavePick->{$_[0]}{$_[1]};
         if ($result) {
            &delete_Selected($result,'',
                $Selected,$SavePick,$SaveNext);
         } delete $SaveNext->{$_[0]};
      } else {
         if (keys %{$Selected->{$_[0]}}) {
            foreach my $key (keys %{$Selected->{$_[0]}}) {
               delete $Selected->{$_[0]}{$key};
               delete $SavePick->{$_[0]}{$key};
               delete $SaveNext->{$_[0]};
            }
         } else {
            foreach my $key (keys %{$SavePick->{$_[0]}}) {
               delete $SavePick->{$_[0]}{$key};
               delete $SaveNext->{$_[0]};
            }
         }
      } delete $SaveNext->{$_[0]};
      return $SaveNext;

   }

   sub find_Selected
   {
      my $Selected=$_[2];
      if ($_[1]) {
         my $result=$Selected->{$_[0]}{$_[1]};
         if ($result=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
                  grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
            return 0;
         } else {
            return &find_Selected($result,'',$Selected);
         }
      } else {
         if (keys %{$Selected->{$_[0]}}) {
            foreach my $key (keys %{$Selected->{$_[0]}}) {
               my $result=$Selected->{$_[0]}{$key};
               #return '+' if substr($result,0,1) eq '&';
               if ($result=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
                  grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
                  return '+';
               }
               my $output=&find_Selected($result,'',$Selected);
               return '+' if $output eq '+';
            }
         }
      }
   }

   sub get_subs_from_menu
   {
      my $Selected=$_[0];
      my @subs=();
      foreach my $key (keys %{$Selected}) {
         foreach my $item (keys %{$Selected->{$key}}) {
            my $seltext=$Selected->{$key}{$item};
            if ($seltext=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ &&
                  grep { $1 eq $_ } list_module('main',$Term::Menus::fa_code)) {
               push @subs, escape_quotes($seltext);
            } elsif (ref $seltext eq 'CODE') {
               push @subs, $seltext;
            } 
         }
      }
      return @subs;
   }

   my $get_result = sub {

      # $_[0] => $MenuUnit_hash_ref
      # $_[1] => \@all_menu_items_array
      # $_[2] => $picks
      # $_[3] => $picks_from_parent

      my $convey=[];
      my $FullMenu=$_[4];
      my $Conveyed=$_[5];
      my $Selected=$_[6];
      my $SaveNext=$_[7];
      my $Persists=$_[8];
      my $parent_menu=$_[9];
      my $pick=(keys %{$_[2]})[0] || 1;
      $_[1]->[$pick-1]||='';
      my $gotmany=(exists $MenuUnit_hash_ref->{Select} &&
            $MenuUnit_hash_ref->{Select}) ? 1 : 0;
      $FullMenu->{$_[0]}[3]={} unless $gotmany;
      if ($pick && exists $FullMenu->{$_[0]}[3]{$_[1]->[$pick-1]}) {
         if ($pick && exists $_[0]->{$FullMenu->{$_[0]}
                            [4]{$_[1]->[$pick-1]}}{Convey}) {
            my $contmp='';
            if (0<$#{[keys %{$_[2]}]}) {
               foreach my $numb (sort numerically keys %{$_[2]}) {
                  $contmp=${${$FullMenu}{$_[0]}[3]}
                                   {${$_[1]}[$numb-1]}[0];
                  $contmp=~s/\s?$//s;
                  push @{$convey}, $contmp;
               }
            } else {
               $convey=${${${$FullMenu}{$_[0]}[3]}{${$_[1]}[$pick-1]}}[0];
               #$convey=$FullMenu->{$_[0]}[3]->{$_[1]->[$pick-1]}->[0];
               $convey=~s/\s?$//s;
            }
            $convey='SKIP' if $convey eq '';
            if (ref $convey eq 'ARRAY' && $#{$convey}==0) {
               $convey=$convey->[0];
            }
         }
         $Conveyed->{&pw($_[0])}=$convey;
      } elsif ($pick) {
         $convey=${$_[1]}[$pick-1];
         $Conveyed->{&pw($_[0])}=$convey;
      } elsif ($_[3]) {
         $convey=$_[3];
         $Conveyed->{&pw($_[0])}=$convey;
      }
      $convey='' if !$convey ||
            (ref $convey eq 'ARRAY' && $#{$convey}==-1);
      my $test_item='';my $show_banner_only=0;
      if (exists $FullMenu->{$_[0]}[2]{'__FA_Banner__'}) {
         $test_item=$FullMenu->{$_[0]}[2]{'__FA_Banner__'};
         $show_banner_only=1;$pick=0;
      } elsif ($pick) {
         $test_item=$FullMenu->{$_[0]}[2]{$_[1]->[$pick-1]};
      }
      $test_item||='';
      if (($pick &&
            exists $FullMenu->{$_[0]}[2]{$_[1]->[$pick-1]} &&
            (ref $test_item eq 'HASH' &&
            (values %{$test_item})[0] ne 'recurse')) ||
            ref $test_item eq 'CODE') {
         if ((ref $test_item eq 'HASH' &&
                   ((grep { /Item_/ } keys %{$test_item}) ||
                   ($show_banner_only && (grep { /Banner/ }
                   keys %{$test_item}))))
                   || ($test_item=~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/
                   && grep { $1 eq $_ } list_module(
                   'main',$Term::Menus::fa_code))
                   || ref $test_item eq 'CODE' ||
                   &test_hashref($test_item)) {
            my $con_regex=qr/\]c(o+nvey)*\[/i;
            my $tpmi_regex=qr/\](!)?t(?:e+st[-_]*)*p*(?:r+vious[-_]*)
                  *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
            my $sicm_regex=
               qr/\]s(e+lected[-_]*)*i*(t+ems[-_]*)
                  *c*(u+rrent[-_]*)*m*(e+nu[-_]*)*\[/xi;
            my $pmsi_regex=qr/\](!)?p(?:r+evious[-_]*)*m*(?:e+nu[-_]*)
                  *s*(?:e+lected[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
            my $amlm_regex=qr/\]a(n+cestor[-_]*)*m*(e+nu[-_]*)
                  *l*(a+bel[-_]*)*m*(a+p[-_]*)*\[/xi;
            my $tbii_regex=qr/\](!)?i(?:n+put[-_]*)*b*(?:a+nner[-_]*)
                  *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
            if ($test_item=~/$con_regex|$pmsi_regex|
                  $amlm_regex|$sicm_regex|$tpmi_regex|$tbii_regex/x) {
               $test_item=&transform_mbii($test_item,
                       $Conveyed,$SaveMMap,
                       $picks_from_parent,$log_handle);
               $test_item=&transform_sicm($test_item,$numbor,
                             \@all_menu_items_array,$_[2],'',
                             $return_from_child_menu,$log_handle,
                             $_[0]->{Name});
               $test_item=&transform_pmsi($test_item,
                       $Conveyed,$SaveMMap,
                       $picks_from_parent,$log_handle);
               $test_item=&transform_mbir($test_item,
                       $Conveyed,$MenuUnit_hash_ref,$log_handle);
            } elsif (ref $test_item eq 'CODE') {
               my $cd='';
               #if ($Term::Menus::data_dump_streamer && (!$show_banner_only
               #      || (exists $MenuUnit_hash_ref->{Input} 
               #      && $MenuUnit_hash_ref->{Input}==1))) {
                  $cd=&Data::Dump::Streamer::Dump($test_item)->Out();
                  $cd=&transform_sicm($cd,$numbor,
                         \@all_menu_items_array,$_[2],'',
                         $return_from_child_menu,$log_handle,
                         $_[0]->{Name});
                  $cd=&transform_pmsi($cd,
                         $Conveyed,$SaveMMap,
                         $picks_from_parent);
                  $cd=&transform_mbir($cd,$Conveyed,$MenuUnit_hash_ref,
                         $log_handle);
               #}
               $cd=~s/\$CODE\d*\s*=\s*//s;
#print "CD2=$cd<==\n";<STDIN>;
               eval { $test_item=eval $cd };
               if ($@) {
                  if (unpack('a11',$@) eq 'FATAL ERROR') {
                     if (defined $log_handle &&
                           -1<index $log_handle,'*') {
                        print $log_handle $@;
                        close($log_handle);
                     }
                     die $@;
                  } else {
                     my $die="\n       FATAL ERROR! - The Local "
                            ."System $Term::Menus::local_hostname Conveyed\n"
                            ."              the Following "
                            ."Unrecoverable Error Condition :\n\n"
                            ."       $@\n       line ".__LINE__;
                     if (defined $log_handle &&
                           -1<index $log_handle,'*') {
                        print $log_handle $die;
                        close($log_handle);
                     }
                     if ($parent_menu && wantarray && !$no_wantarray) {
                        return $FullMenu,$Conveyed,
                           $SaveNext,$Persists,$Selected,
                           $convey,$parent_menu;
                     } elsif ($Term::Menus::fullauto) {
                        &Net::FullAuto::FA_Core::handle_error($die);
                     } else { die $die }
                  }
               }
               my $item=($show_banner_only)?'__FA_Banner__':$pick;
               $Selected->{$_[0]}->{$item}=$test_item;
               return $FullMenu,$Conveyed,$SaveNext,
                      $Persists,$Selected,$convey,$parent_menu;
            }
            if ($test_item=~/Convey\s*=\>/) {
               if ($convey ne 'SKIP') {
                  $test_item=~s/Convey\s*=\>/$convey/g;
               } else {
                  $test_item=~s/Convey\s*=\>/${$_[1]}[$pick-1]/g;
               }
            }
            if ($test_item=~/Text\s*=\>/) {
               $test_item=~s/Text\s*=\>/${$_[1]}[$pick-1]/g;
            }
         } else {
            my $die="The \"Result3 =>\" Setting\n              -> "
                   .$FullMenu->{$_[0]}[2]{$_[1]->[$_[2]-1]}
                   ."\n              Found in the Menu Unit -> "
                   .$MenuUnit_hash_ref
                   ."\n              is not a Menu Unit\,"
                   ." and Because it Does Not Have"
                   ."\n              an \"&\" as"
                   ." the Lead Character, $0"
                   ."\n              Cannot Determine "
                   ."if it is a Valid SubRoutine.\n\n";
            die $die;
         }
      }
      if ($show_banner_only) {
         $Selected->{$_[0]}{'__FA_Banner__'}=$test_item;
         $SaveNext->{$_[0]}=$FullMenu->{$_[0]}[2]{'__FA_Banner__'};
      } else { 
         chomp($pick) if $pick;
         $Selected->{$_[0]}{$pick}=$test_item if $pick;
         if ($pick && ref $_[0]->{$FullMenu->{$_[0]}
               [4]{$_[1]->[$pick-1]}}{'Result'} eq 'HASH') {
            $SaveNext->{$_[0]}=$FullMenu->{$_[0]}[2]
               {$_[1]->[$pick-1]};
         }
      }
      return $FullMenu,$Conveyed,$SaveNext,
             $Persists,$Selected,$convey,$parent_menu;
   };

   my $filtered_menu=0;my $defaults_exist=0;my $input='';
   while (1) {
      if ($num_pick-$start<=$display_this_many_items) {
         $choose_num=$num_pick-$start;
      } else { $choose_num=$display_this_many_items }
      $numbor=$start+$choose_num+1;my $done=0;my $savechk=0;my %pn=();
      my $sorted_flag=0;
      $Persists->{$MenuUnit_hash_ref}={} unless exists
         $Persists->{$MenuUnit_hash_ref};
      if (!exists $Persists->{$MenuUnit_hash_ref}{defaults} &&
               defined ${[keys %{$FullMenu->{$MenuUnit_hash_ref}[5]}]}[0]) {
         my $it=${[keys %{$FullMenu->{$MenuUnit_hash_ref}[5]}]}[0];
         my $def=$FullMenu->{$MenuUnit_hash_ref}[5]{$it};
         if ($def) {
            $def='.*' if $def eq '*';
            foreach my $item (
                  @{[keys %{$FullMenu->{$MenuUnit_hash_ref}[5]}]}) {
               if ($item=~/$def/) {
                  $Persists->{$MenuUnit_hash_ref}{defaults}=1;
               } 
            }
         }
      }
      $Persists->{$MenuUnit_hash_ref}{defaults}=0 unless exists
         $Persists->{$MenuUnit_hash_ref}{defaults};
      my $plann='';my $plannn='';
      if (ref $Net::FullAuto::FA_Core::plan eq 'HASH') {
         my $plann=shift @{$Net::FullAuto::FA_Core::plan};
         $plannn=$plann->{Item}; 
         my $plan_='';
         if (substr($plannn,2,5) eq 'ARRAY') {
            my $eval_plan=substr($plannn,1,-1);
            $plan_=eval $eval_plan;
            &eval_error($@,$log_handle) if $@;
         } else {
            $plan_=$plannn;
         }
         return $plan_;
      }
      while ($numbor=~/\d+/ &&
            ($numbor<=$start || $start+$choose_num < $numbor ||
            $numbor eq 'admin') || $input) {
         my $menu_text='';my $picknum_for_display='';
         my $bout='';
         ($bout,$input)=&banner($MenuUnit_hash_ref->{Banner}||$banner,
            $Conveyed,$SaveMMap,$picks_from_parent,
            $numbor,$ikey,$input,$MenuUnit_hash_ref,$log_handle);
         $menu_text.=$bout."\n";
         my $picknum=$start+1;
         my $numlist=$choose_num;
         my $mark='';
         my $mark_len=$FullMenu->{$MenuUnit_hash_ref}[7]{BLANK};
         while ($mark_len--) {
            $mark.=' ';
         }
         my $mark_blank=$mark;
         my $mark_flg=0;my $prev_menu=0;
         $numlist=1 if $numbor eq 'admin';
         while (0 < $numlist) {
            if (exists $picks{$picknum}) {
               $mark_flg=1;
               if ($return_from_child_menu) {
                  $mark=$mark_blank;
                  substr($mark,-1)=$picks{$picknum}=$return_from_child_menu;
                  %{$SavePick->{$MenuUnit_hash_ref}}=%picks;
                  $prev_menu=$picknum;
#print "DO WE GET HERE3 and SEL=$MenuUnit_hash_ref->{Select}! and $return_from_child_menu\n";
               } else {
                  $mark=$mark_blank;
                  substr($mark,-1)=$picks{$picknum};
               }
#print "DO WE GET HERE4 and SEL=$MenuUnit_hash_ref->{Select}!\n";
               my $gotmany=($select_many ||
                     (keys %{$MenuUnit_hash_ref->{Select}})) ? 1 : 0;
               if (($gotmany
                     && $numbor=~/^[Ff]$/) || ($picks{$picknum} ne
                     '+' && $picks{$picknum} ne '-' &&
                     !$gotmany)) {
#print "DO WE GET HERE5! and $MenuUnit_hash_ref->{Select}\n";
                  $mark_flg=1;
                  $mark=$mark_blank;
                  substr($mark,-1)='*';
                  if ((exists $FullMenu->{$MenuUnit_hash_ref}[2]
                        {$all_menu_items_array[$picknum-1]}) && ref
                        $FullMenu->{$MenuUnit_hash_ref}[2]
                        {$all_menu_items_array[$picknum-1]} eq 'HASH' &&
                        (grep { /Item_/ } keys %{$FullMenu->
                        {$MenuUnit_hash_ref}[3]})) {
                     if (exists $FullMenu->{$MenuUnit_hash_ref}[3]
                                      {$all_menu_items_array[$picknum-1]}) {
                        $convey=$FullMenu->{$MenuUnit_hash_ref}[3]
                                      {$all_menu_items_array[$picknum-1]}->[0];
                     } else { $convey=$all_menu_items_array[$picknum-1] }
                     eval {
                        ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                           $SaveMMap,$SaveNext,$Persists)=&Menu($FullMenu->
                           {$MenuUnit_hash_ref}[2]
                           {$all_menu_items_array[$picknum-1]},$convey,
                           $recurse_level,$FullMenu,
                           $Selected,$Conveyed,$SavePick,
                           $SaveMMap,$SaveNext,$Persists,
                           $MenuUnit_hash_ref,$no_wantarray);
                     }; # MENU RETURN MENURETURN 1
                     print "MENU RETURN 1\n" if $menu_return_debug;
                     die $@ if $@;
                     chomp($menu_output) if !(ref $menu_output);
                     if ($menu_output eq '-') {
                        $picks{$picknum}='-';
                        $mark=$mark_blank;
                        substr($mark,-1)='-';
                        $start=${$FullMenu}{$MenuUnit_hash_ref}[11];
                     } elsif ($menu_output eq '+') {
                        $picks{$picknum}='+';
                        $mark=$mark_blank;
                        substr($mark,-1)='+';
                        $start=$FullMenu->{$MenuUnit_hash_ref}[11];
                     } elsif ($menu_output eq 'DONE_SUB') {
                        return 'DONE_SUB';
                     } elsif ($menu_output eq 'DONE') {
                        if (1==$recurse_level) {
                           my $subfile=substr($Term::Menus::fa_code,0,-3).'::'
                                 if $Term::Menus::fa_code;
                           $subfile||='';
                           foreach my $sub (&get_subs_from_menu($Selected)) {
                              my @resu=();
                              if (ref $sub eq 'CODE') {
                                 if ($Term::Menus::fullauto && (!exists
                                       $MenuUnit_hash_ref->{'NoPlan'} ||
                                       !$MenuUnit_hash_ref->{'NoPlan'})
                                       && defined
                                       $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN1\n";
                                    if (-1==
                                          $#{$Net::FullAuto::FA_Core::makeplan{
                                          'Plan'}} && !exists
                                          $Net::FullAuto::FA_Core::makeplan->{
                                          'Title'}) {
                                       $Net::FullAuto::FA_Core::makeplan->{
                                          'Title'}=$pn{$numbor}[0];
                                    }
                                    my $n='Number';
                                    my $planid=
                                          $Net::FullAuto::FA_Core::makeplan->{
                                          $n}; 
                                    my $s=$sub;
                                    my $item=
                                          &Data::Dump::Streamer::Dump(
                                          $s)->Out();
                                    push @{$Net::FullAuto::FA_Core::makeplan->{
                                            'Plan'}},
                                         { Menu   => &pw($MenuUnit_hash_ref),
                                           Number => $numbor,
                                           PlanID => $planid,
                                           Item   => $item
                                         }
                                 }
                                 eval { @resu=$sub->() };
                                 if ($@) {
                                    if (10<length $@ && unpack('a11',$@)
                                          eq 'FATAL ERROR') {
                                       if ($parent_menu && wantarray
                                             && !$no_wantarray) {
                                          return '',$FullMenu,$Selected,
                                                 $Conveyed,$SavePick,$SaveMMap,
                                                 $SaveNext,$Persists,
                                                 $parent_menu,$@;
                                       }
                                       if (defined $log_handle &&
                                             -1<index $log_handle,'*') {
                                          print $log_handle $@;
                                          close($log_handle);
                                       }
                                       if ($Term::Menus::fullauto) {
                                         &Net::FullAuto::FA_Core::handle_error(
                                            $@);
                                       } else { die $@ }
                                    } else {
                                       my $die=''
                                          ."\n       FATAL ERROR! - The Local "
                                          ."System $Term::Menus::local_hostname"
                                          ." Conveyed\n"
                                          ."              the Following "
                                          ."Unrecoverable Error Condition :\n\n"
                                          ."       $@\n       line ".__LINE__;
                                       if ($parent_menu && wantarray
                                             && !$no_wantarray) {
                                          return '',$FullMenu,$Selected,
                                                 $Conveyed,$SavePick,$SaveMMap,
                                                 $SaveNext,$Persists,
                                                 $parent_menu,$die;
                                       }
                                       if (defined $log_handle &&
                                             -1<index $log_handle,'*') {
                                          print $log_handle $die;
                                          close($log_handle);
                                       }
                                       if ($Term::Menus::fullauto) {
                                          &Net::FullAuto::FA_Core::handle_error(
                                             $die);
                                       } else { die $die }
                                    }
                                 }
                                 if (-1<$#resu) {
                                    if ($resu[0] eq '<') { %picks=();next }
                                    if (0<$#resu && wantarray &&
                                          !$no_wantarray) {
                                       return @resu;
                                    } else {
                                       return return_result($resu[0],
                                          $MenuUnit_hash_ref,$Conveyed);
                                    } return 'DONE_SUB';
                                 }
                              }
                              eval {
                                 if ($subfile) {
                                    $sub=~s/^[&]//;
                                    if ($Term::Menus::fullauto && (!exists
                                          $MenuUnit_hash_ref->{'NoPlan'} ||
                                          !$MenuUnit_hash_ref->{'NoPlan'})
                                          && defined
                                          $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN2\n";
                                       if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                             'Plan'}} && !exists
                                             $Net::FullAuto::FA_Core::makeplan->{
                                             'Title'}) {
                                          $Net::FullAuto::FA_Core::makeplan->{
                                             'Title'}=$pn{$numbor}[0];
                                       }
                                       push @{$Net::FullAuto::FA_Core::makeplan->{
                                               'Plan'}},
                                            { Menu   => &pw($MenuUnit_hash_ref),
                                              Number => $numbor,
                                              PlanID =>
                                                 $Net::FullAuto::FA_Core::makeplan->{Number},
                                              Item   => "&$subfile$sub" }
                                    }
                                    eval "\@resu=\&$subfile$sub";
                                    my $firsterr=$@||'';

                                    if ((-1<index $firsterr,
                                          'Undefined subroutine') &&
                                          (-1<index $firsterr,$sub)) {
                                       if ($sub!~/::/) {
                                          eval "\@resu=main::$sub";
                                       } else {
                                          eval "\@resu=$sub";
                                       }
                                       my $seconderr=$@||'';my $die='';
                                       my $c=$Term::Menus::fa_code;
                                       if ($seconderr=~/Undefined subroutine/) {
                                          if ($FullMenu->{$MenuUnit_hash_ref}
                                                [2]{$all_menu_items_array[
                                                $numbor-1]}) {
                                             $die="The \"Result15 =>\" Setting"
                                                 ."\n\t\t-> " . $FullMenu->
                                                 {$MenuUnit_hash_ref}[2]
                                                 {$all_menu_items_array[
                                                 $numbor-1]}
                                                 ."\n\t\tFound in the Menu "
                                                 ."Unit -> "
                                                 .$MenuUnit_hash_ref->{Name}
                                                 ."\n\t\t"
                                                 ."Specifies a Subroutine"
                                                 ." that Does NOT Exist"
                                                 ."\n\t\tin the User Code File "
                                                 .$c.",\n\t\tnor was a routine "
                                                 ."with that name\n\t\tlocated"
                                                 ." in the main:: script.\n";
                                          } else {
                                             $die=
                                                "$firsterr\n       $seconderr"
                                          }
                                       } else { $die=$seconderr }
                                       &Net::FullAuto::FA_Core::handle_error(
                                          $die);
                                    } elsif ($firsterr) {
                                       &Net::FullAuto::FA_Core::handle_error(
                                          $firsterr);
                                    }
                                 } else {
                                    if ($sub!~/::/) {
                                       $sub=~s/^[&]//;
                                       eval "\@resu=main::$sub";
                                    } else {
                                       eval "\@resu=$sub";
                                    }
                                    die $@ if $@;
                                 }
                              };
                              if ($@) {
                                 if (10<length $@ && unpack('a11',$@)
                                       eq 'FATAL ERROR') {
                                    if ($parent_menu && wantarray
                                          && !$no_wantarray) {
                                       return '',$FullMenu,$Selected,$Conveyed,
                                              $SavePick,$SaveMMap,$SaveNext,
                                              $Persists,$parent_menu,$@;
                                    }
                                    if (defined $log_handle &&
                                          -1<index $log_handle,'*') {
                                       print $log_handle $@;
                                       close($log_handle);
                                    }
                                    if ($Term::Menus::fullauto) {
                                      &Net::FullAuto::FA_Core::handle_error($@);
                                    } else { die $@ }
                                 } else {
                                    my $die=''
                                       ."\n       FATAL ERROR! - The Local "
                                       ."System $Term::Menus::local_hostname "
                                       ."Conveyed\n"
                                       ."              the Following "
                                       ."Unrecoverable Error Condition :\n\n"
                                       ."       $@\n       line ".__LINE__;
                                    if ($parent_menu && wantarray
                                          && !$no_wantarray) {
                                       return '',$FullMenu,$Selected,$Conveyed,
                                              $SavePick,$SaveMMap,$SaveNext,
                                              $Persists,$parent_menu,$die;
                                    }
                                    if (defined $log_handle &&
                                          -1<index $log_handle,'*') {
                                       print $log_handle $die;
                                       close($log_handle);
                                    }
                                    if ($Term::Menus::fullauto) {
                                       &Net::FullAuto::FA_Core::handle_error(
                                          $die);
                                    } else { die $die }
                                 }
                              }
                              if (-1<$#resu) {
                                 if ($resu[0] eq '<') { %picks=();next }
                                 if (0<$#resu && wantarray && !$no_wantarray) {
                                    return @resu;
                                 } else {
                                    return return_result($resu[0],
                                       $MenuUnit_hash_ref,$Conveyed);
                                 }
                              }
                           }
                           return 'DONE_SUB';
                        } else { return 'DONE' }
                     } elsif ($menu_output) {
                        return $menu_output;
                     } else {
                        $picks{$picknum}='+';
                        $mark=$mark_blank;
                        substr($mark,-1)='+';
                        $start=$FullMenu->{$MenuUnit_hash_ref}[11];
                     }
                  }
               }
            } else {
               $mark='';
               my $mark_len=$FullMenu->{$MenuUnit_hash_ref}[7]{BLANK};
               while ($mark_len--) {
                  $mark.=' ';
               }
            }
            $mark=$FullMenu->{$MenuUnit_hash_ref}[7]
                  {$all_menu_items_array[$picknum-1]}
               if exists $FullMenu->{$MenuUnit_hash_ref}[7]
                  {$all_menu_items_array[$picknum-1]};
            if (!$hidedefaults &&
                  ref $FullMenu->{$MenuUnit_hash_ref}[5] eq 'HASH' 
                  && $FullMenu->{$MenuUnit_hash_ref}[5]
                  {$all_menu_items_array[$picknum-1]} && ($FullMenu->
                  {$MenuUnit_hash_ref}[5]{$all_menu_items_array[$picknum-1]}
                  eq '*' || $all_menu_items_array[$picknum-1]=~
                  /$FullMenu->{$MenuUnit_hash_ref}[5]{
                  $all_menu_items_array[$picknum-1]}/)) {
               $mark=$mark_blank;
               substr($mark,-1)='*';$mark_flg=1;
               $SavePick->{$MenuUnit_hash_ref}{$picknum}='*';
            }
            $picknum_for_display=$picknum;
            if (ref $FullMenu->{$MenuUnit_hash_ref}[8] eq 'HASH'
                  && keys %{$FullMenu->{$MenuUnit_hash_ref}[8]} &&
                  exists $FullMenu->{$MenuUnit_hash_ref}[8]
                  {$all_menu_items_array[$picknum-1]}
                  && $FullMenu->{$MenuUnit_hash_ref}[8]
                  {$all_menu_items_array[$picknum-1]}) {
               $picknum_for_display=
                  $FullMenu->{$MenuUnit_hash_ref}[8]
                  {$all_menu_items_array[$picknum-1]};
               $mark=$mark_blank;
               if (exists $SavePick->{$MenuUnit_hash_ref}
                          {$picknum_for_display} &&
                          $SavePick->{$MenuUnit_hash_ref}
                          {$picknum_for_display}) {
                  substr($mark,-1)=$SavePick->{$MenuUnit_hash_ref}
                     {$picknum_for_display}
               } else { $mark=' ' }
               $mark_flg=1 unless $mark=~/^ +$/;
               $Persists->{$MenuUnit_hash_ref}{defaults}=1
                 if $Persists->{$parent_menu}{defaults};
               if ($FullMenu->{$MenuUnit_hash_ref}[9]) {
                  $filtered_menu=1;
               } 
            }
            $pn{$picknum_for_display}=
               [ $all_menu_items_array[$picknum-1],$picknum ];
            my $scroll=' ';
            if (exists $MenuUnit_hash_ref->{Scroll}
                  && ($MenuUnit_hash_ref->{Scroll}->[1] eq $picknum
                  || $MenuUnit_hash_ref->{Scroll}->[0] eq $picknum)) {
               if ($MenuUnit_hash_ref->{Scroll}->[0]) {
                  if ($MenuUnit_hash_ref->{Scroll}->[0] eq $picknum) {
                     $MenuUnit_hash_ref->{Scroll}->[1]=$picknum;
                     $MenuUnit_hash_ref->{Scroll}->[0]=0;
                     $scroll='>';
                  }
               } else {
                  $scroll='>';
               }
            }
            my $picknum_display=sprintf "%-7s",$picknum_for_display;
            $menu_text.="   $scroll$mark  $picknum_display"
                       ."$all_menu_items_array[$picknum-1]\n";
            if (exists $FullMenu->{$MenuUnit_hash_ref}[6]
                  {$all_menu_items_array[$picknum-1]}) {
               my $tstt=$FullMenu->{$MenuUnit_hash_ref}[6]
                        {$all_menu_items_array[$picknum-1]};
               if ($tstt=~/many/i) {
                  $MenuUnit_hash_ref->{Select}{$picknum_for_display}='many';  
               }
            }
            if ($mark=~/^ +$/ || (exists $picks{$picknum} ||
                  exists $picks{$picknum_for_display})) {
               ${$_[0]}[$picknum_for_display-1]=
                  $all_menu_items_array[$picknum-1];
            }
            $picknum++;
            $numlist--;
         } $hidedefaults=1;$picknum--;
         if ($Term::Menus::fullauto && (!exists
               $MenuUnit_hash_ref->{'NoPlan'} ||
               !$MenuUnit_hash_ref->{'NoPlan'}) &&
               $Net::FullAuto::FA_Core::makeplan &&
               $Persists->{$MenuUnit_hash_ref}{defaults} &&
               !$filtered_menu) {
            my %askmenu=(

                  Item_1 => {

                     Text => "Use the result saved with the \"Plan\""

                            },
                  Item_2 => {

                     Text => "Use the \"Default\" setting to determine result"

                            },
                  NoPlan => 1,
                  Banner => "   FullAuto has determined that the ".
                            &pw($MenuUnit_hash_ref) .
                            " Menu has been\n".
                            "   configured with a \"Default\" setting."

            );
            my $answ=Menu(\%askmenu);
            if ($answ eq ']quit[') {
               return ']quit['
            }
            if (-1==index $answ,'result saved') {
#print "IN MAKEPLAN3\n";
               if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}} &&
                     !exists $Net::FullAuto::FA_Core::makeplan->{'Title'}) {
                  $Net::FullAuto::FA_Core::makeplan->{'Title'}=$pn{$numbor}[0];
               }
               push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
                    { Menu   => &pw($MenuUnit_hash_ref),
                      Number => 'Default',
                      PlanID =>
                         $Net::FullAuto::FA_Core::makeplan->{Number},
                      Item   => '' };
               $got_default=1;
            }
         }
         unless ($Persists->{unattended}) {
            if ($^O ne 'cygwin') {
               unless ($noclear) {
                  if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
                     system("cmd /c cls");
                     print "\n";
                  } else {
                     print `${Term::Menus::clearpath}clear`."\n";
                     print $blanklines
                  }
               } else { print $blanklines }
            } else { print $blanklines }
            print $menu_text;my $ch=0;
            if ($select_many || (keys %{${$MenuUnit_hash_ref}{Select}})) {
               print "\n";
               unless (keys %{$FullMenu->{$MenuUnit_hash_ref}[1]}) {
                  print "   a.  Select All";$ch=1;
               }
               if ($mark_flg==1 || $Persists->{$MenuUnit_hash_ref}{defaults}) {
                  print "   c.  Clear All";#print "\n" if $ch;
               }
               print "   f.  FINISH\n";
               if ($filtered_menu) {
                  print "\n   (Type '<' to return to previous Menu)\n";
               }
               if ($Persists->{$MenuUnit_hash_ref}{defaults} &&
                     !$filtered_menu) {
                  print "\n   == Default Selections Exist! == ",
                        "(Type '*' to view them)\n";
               }
            } else {
               if ($Persists->{$MenuUnit_hash_ref}{defaults}) {
                  print "\n",
                        "   c.  Clear Default Selection.",
                        "   f.  FINISH with Default Selection.\n";
                  if ($filtered_menu) {
                     print "\n   (Type '<' to return to previous Menu)\n";
                  } else {
                     print "\n   == Default Selection Exists! == ",
                           "(Type '*' to view it)\n";
                  }
               } elsif ($filtered_menu) {
                  print "\n   (Type '<' to return to previous Menu)\n";
               }
            }
            if ($display_this_many_items<$num_pick) {
               my $len=length $num_pick;my $pad='';
               foreach my $n (1..$len) {
                  $pad.=' '; 
               }
               print $pad,
                     "\n   $num_pick Total Choices   ",
                     "[v][^] Scroll with ARROW keys ".
                     "  [F1] for HELP\n";
            } else { print "\n   \(Press [F1] for HELP\)\n" }
            if ($Term::Menus::term_input) {
               print "\n";
               if (exists $MenuUnit_hash_ref->{Input} &&
                     $MenuUnit_hash_ref->{Input}) {
                  ($numbor,$ikey)=rawInput("   \([ESC] to Quit\)".
                     "   Press ENTER when finished ",1);
                  next unless ($ikey eq 'ENTER' || $ikey eq 'ESC' ||
                     $ikey eq 'UPARROW' || $ikey eq 'DOWNARROW' ||
                     $ikey eq 'LEFTARROW' || $ikey eq 'RIGHTARROW' ||
                     $ikey eq 'F1');
               } elsif ($show_banner_only) {
                  ($numbor,$ikey)=rawInput("   \([ESC] to Quit\)".
                     "   Press ENTER to continue ... ");
                   
               } else {
                  ($numbor,$ikey)=rawInput("   \([ESC] to Quit\)".
                     "   PLEASE ENTER A CHOICE: ");
               }
               print "\n";
            } else {
               if ($show_banner_only) {
                  print "\n   \([ESC] to Quit\)",
                        "   Press ENTER to continue ... ";
               } else {
                  print "\n   \([ESC] to Quit\)",
                        "   PLEASE ENTER A CHOICE: ";
               }
               $numbor=<STDIN>;
            } $picknum_for_display=$numbor;chomp $picknum_for_display;
         } elsif ($Persists->{$MenuUnit_hash_ref}{defaults}) {
            $numbor='f';
         } elsif (wantarray && !$no_wantarray) {
            my $die="\n       FATAL ERROR! - 'Unattended' mode cannot be\n"
                   ."                         used without a Plan or Default\n"
                   ."                         Selections being available.";
            return '',$die;
         } else {
            my $die="\n       FATAL ERROR! - 'Unattended' mode cannot be\n"
                   ."                         used without a Plan or Default\n"
                   ."                         Selections being available.";
            die($die);
         }
         if ($numbor=~/^[Ff]$/ &&
               ($Persists->{$MenuUnit_hash_ref}{defaults} ||
               $filtered_menu)) {
            # FINISH
            delete $main::maintain_scroll_flag->{$MenuUnit_hash_ref}
               if defined $main::maintain_scroll_flag;
            my $choice='';my @keys=();
            my $chosen='';
            if ($filtered_menu) {
               $chosen=$parent_menu;
               return '-',
                  $FullMenu,$Selected,$Conveyed,
                  $SavePick,$SaveMMap,$SaveNext,
                  $Persists,$parent_menu;
            } else { $chosen=$MenuUnit_hash_ref }
            @keys=keys %picks;
            if (-1==$#keys) {
               if ($Persists->{$MenuUnit_hash_ref}{defaults}) {
                  if ($filtered_menu) {
                     $chosen=$parent_menu;
                  }
                  my $it=${[keys %{${$FullMenu}{$chosen}[5]}]}[0];
                  my $def=${$FullMenu}{$chosen}[5]{$it};
                  $def='.*' if $def eq '*';
                  if ($def) {
                     my $cnt=1;
                     foreach my $item (@all_menu_items_array) {
                           #sort @{[keys %{${$FullMenu}{$chosen}[5]}]}) {
                        if ($item=~/$def/) {
                           $picks{$cnt}='*';
                           push @keys, $item;
                        } $cnt++
                     }
                  }
               } else {
                  @keys=keys %{$SavePick->{$parent_menu}};
                  if (-1==$#keys) {
                     if ($^O ne 'cygwin') {
                        unless ($noclear) {
                           if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
                              system("cmd /c cls");
                              print "\n";
                           } else {
                              print `${Term::Menus::clearpath}clear`."\n";
                           }
                        } else { print $blanklines }
                     } else { print $blanklines }
                     print "\n\n       Attention USER! :\n\n       ",
                           "You have selected \"f\" to finish your\n",
                           "       selections, BUT -> You have not actually\n",
                           "       selected anything!\n\n       Do you wish ",
                           "to quit or re-attempt selecting?\n\n       ",
                           "Press [ESC] to quit or ENTER to continue ... ";
                     if ($Term::Menus::term_input) {
                        print "\n";
                        ($choice,$ikey)=rawInput("   \([ESC] to Quit\)".
                           "   PLEASE ENTER A CHOICE: ");
                        print "\n";
                     } else {
                        print "   \([ESC] to Quit\)",
                              "\n   PLEASE ENTER A CHOICE: ";
                        $choice=<STDIN>;
                     } 
                     chomp($choice);
                     next if lc($choice) ne 'quit';
                     return ']quit['
                  } 
               }
            }
            my $return_values=0;
            sub numerically { $a <=> $b }
            my %dupseen=();my @pickd=();
            foreach my $pk (sort numerically keys %picks) {
               $return_values=1 if !exists
                  ${$FullMenu}{$chosen}[2]{${$_[0]}[$pk-1]}
                  || !keys
                  %{${$FullMenu}{$chosen}[2]{${$_[0]}[$pk-1]}};
               if (${${$FullMenu}{$parent_menu}[10]}[$pk-1] &&
                     !${$_[0]}[$pk-1]) {
                  my $txt=${${$FullMenu}{$parent_menu}[10]}[$pk-1];
                  if (-1<index $txt,"__Master_${$}__") {
                     my $lhn=$Term::Menus::local_hostname;
                     $txt=~s/__Master_${$}__/Local-Host: $lhn/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               } elsif (${$_[0]}[$pk-1]) {
                  my $txt=${$_[0]}[$pk-1];
                  if (-1<index $txt,"__Master_${$}__") {
                     my $lhn=$Term::Menus::local_hostname;
                     $txt=~s/__Master_${$}__/Local-Host: $lhn/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               } elsif ($pn{$picknum}) {
                  my $txt=$pn{$picknum}[0];
                  if (-1<index $txt,"__Master_${$}__") {
                     my $lhn=$Term::Menus::local_hostname;
                     $txt=~s/__Master_${$}__/Local-Host: $lhn/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               }
            }
            if ($return_values && $Term::Menus::fullauto &&
                   (!exists ${$MenuUnit_hash_ref}{'NoPlan'} ||
                   !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                   defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN4\n";
               if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}} &&
                     !exists $Net::FullAuto::FA_Core::makeplan->{'Title'}) {
                  $Net::FullAuto::FA_Core::makeplan->{'Title'}=
                     "Multiple Selections";
               }
               unless ($got_default) {
                  push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
                       { Menu   => &pw($MenuUnit_hash_ref),
                         Number => 'Multiple',
                         PlanID =>
                            $Net::FullAuto::FA_Core::makeplan->{Number},
                         Item   => "'".
                                   &Data::Dump::Streamer::Dump(\@pickd)->Out().
                                   "'" }
               }
            }
            return \@pickd if $return_values;
            return 'DONE';
         } elsif ($numbor=~/^\s*%(.*)/s) {
            # PERCENT SYMBOL SORT ORDER
            my $one=$1||'';
            chomp $one;
            $one=qr/$one/ if $one;
            my @spl=();
            chomp $numbor;
            my $cnt=0;my $ct=0;my @splice=();
            my $sort_ed='';
            if ($one) {

            } elsif ($sorted && $sorted eq 'forward') {
               @spl=reverse @all_menu_items_array;$sort_ed='reverse';
            } else { @spl=sort @all_menu_items_array;$sort_ed='forward' }
            next if $#spl==-1;
            my %sort=();
            foreach my $line (@all_menu_items_array) {
               $cnt++;
               if (exists $pn{$picknum} &&
                     exists $FullMenu->{$MenuUnit_hash_ref}[8]
                     {$pn{$picknum}[0]} && $FullMenu->
                     {$MenuUnit_hash_ref}[8]{$pn{$picknum}[0]} &&
                     ref $FullMenu->{$MenuUnit_hash_ref}[8]
                     {$pn{$picknum}[0]} eq 'HASH' &&
                     keys %{$FullMenu->{$MenuUnit_hash_ref}[8]
                     {$pn{$picknum}[0]}} && $FullMenu->
                     {$MenuUnit_hash_ref}[8]{$pn{$picknum}[0]}) {
                  $sort{$line}=$FullMenu->{$MenuUnit_hash_ref}[8]{$line};
               } else { $sort{$line}=$cnt }
            } $cnt=0;
            my $chosen='';
            if (!$sorted) {
               my $send_select='Many' if $select_many;
               $chosen={
                  Select => $send_select,
                  Banner => ${$MenuUnit_hash_ref}{Banner},
               };
               my $cnt=0;
               foreach my $text (@spl) {
                  my $num=$sort{$text};
                  $cnt++;
                  if (exists $picks{$num}) {
                     $chosen->{'Item_'.$cnt}=
                        { Text => $text,Default => '*',__NUM__=>$num };
                  } else {
                     $chosen->{'Item_'.$cnt}=
                        { Text => $text,__NUM__=>$num };
                  }
                  $chosen->{'Item_'.$cnt}{Result}=
                     ${${$MenuUnit_hash_ref}{${${$FullMenu}
                     {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                     if exists ${${$MenuUnit_hash_ref}{${${$FullMenu}
                     {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
                  $chosen->{'Item_'.$cnt}{Sort}=$sort_ed;
                  $chosen->{'Item_'.$cnt}{Filter}=1;
               } $sorted=$sort_ed;
            } else {
               @all_menu_items_array=reverse @all_menu_items_array;
               next;
            }
            %{$SavePick->{$chosen}}=%picks;
            my @return_from_filtered_menu=();
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  @return_from_filtered_menu)=&Menu(
                  $chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            }; # MENU RETURN MENURETURN 2
            print "MENU RETURN 2\n" if $menu_return_debug;
            die $@ if $@;
            if (-1<$#return_from_filtered_menu) {
               if ((values %{$menu_output})[0] eq 'recurse') {
                  my %k=%{$menu_output};
                  delete $k{Menu};
                  my $lab=(keys %k)[0];
                  $menu_output=$labels{$lab};
               }
               $MenuMap=$Persists->{$MenuUnit_hash_ref};
               eval {
                  ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                     $SaveMMap,$SaveNext,$Persists)=&Menu(
                     $menu_output,$FullMenu,
                     $Selected,$Conveyed,$SavePick,
                     $SaveMMap,$SaveNext,$Persists,
                     $return_from_filtered_menu[0],
                     $MenuUnit_hash_ref,
                     $return_from_filtered_menu[2]);
               };
               die $@ if $@;
            }
            chomp($menu_output) if !(ref $menu_output);
            if ($menu_output eq '-') {
               %picks=%{$SavePick->{$chosen}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq '+') {
               %picks=%{$SavePick->{$chosen}};
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq 'DONE_SUB') {
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($Term::Menus::fa_code,0,-3)
                        .'::' if $Term::Menus::fa_code;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     if (ref $sub eq 'CODE') {
                        if ($Term::Menus::fullauto && (!exists
                              ${$MenuUnit_hash_ref}{'NoPlan'} ||
                              !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN5\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                  'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                     $Net::FullAuto::FA_Core::makeplan->{
                                     'Number'},
                                  Item   => 
                                     &Data::Dump::Streamer::Dump($sub)->Out() }
                        }
                        eval { @resu=$sub->() };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@)
                                 eq 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') { %picks=();next }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                        $done=1;last
                     }
                     eval {
                        if ($subfile) {
                           $sub=~s/^[&]//;
                           if ($Term::Menus::fullauto && (!exists
                                 ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                 !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN6\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$pn{$numbor}[0];
                              }
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                      'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{
                                        'Number'},
                                     Item   => "&$subfile$sub" }
                           }
                           eval "\@resu=\&$subfile$sub";
                           my $firsterr=$@||'';
                           if ((-1<index $firsterr,'Undefined subroutine') &&
                                 (-1<index $firsterr,$sub)) {
                              if ($sub!~/::/) {
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              my $seconderr=$@||'';my $die='';
                              if ($seconderr=~/Undefined subroutine/) {
                                 if ($FullMenu->{$MenuUnit_hash_ref}
                                       [2]{$all_menu_items_array[$numbor-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}
                                        {$MenuUnit_hash_ref}[2]
                                        {$all_menu_items_array[$numbor-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code File "
                                        .$Term::Menus::fa_code
                                        .",\n\t\tnor was a routine with "
                                        ."that name\n\t\tlocated in the"
                                        ." main:: script.\n";
                                 } else { $die="$firsterr\n       $seconderr" }
                              } else { $die=$seconderr }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } elsif ($firsterr) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr);
                           }
                        } else {
                           if ($sub!~/::/) {
                              $sub=~s/^[&]//;
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           die $@ if $@;
                        }
                     };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                  }
                  return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output) {
               return $menu_output;
            } else {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            }
         } elsif ($numbor=~/^\*\s*$/s) {
            # SHOW DEFAULT SELECTIONS using STAR symbol
            if ($filtered_menu) {
               print "\n   WARNING!: Only -ONE- Level of Filtering",
                     " is Supported!\n";
               sleep 2;
               last;
            }
            my @splice=();
            my @spl=();
            foreach my $key (keys %{$SavePick->{$parent_menu}}) {
               $picks{$key}='*';
            }
            $SavePick->{$MenuUnit_hash_ref}||={};
            foreach my $key (keys %picks) {
               if ($parent_menu) {
                  $SavePick->{$parent_menu}->{$key}='*';
               } else {
                  $SavePick->{$MenuUnit_hash_ref}->{$key}='*';
               }
            }
            if ($Persists->{$MenuUnit_hash_ref}{defaults}) {
               my $it=${[keys %{$FullMenu->{$MenuUnit_hash_ref}[5]}]}[0];
               my $def=$FullMenu->{$MenuUnit_hash_ref}[5]{$it};
               $def='.*' if $def eq '*';
               if ($def) {
                  my $cnt=1;
                  foreach my $item (@all_menu_items_array) {
                     if ($item=~/$def/) {
                        $picks{$cnt}='*';
                     } $cnt++
                  }
               }
            }
            foreach my $pick (sort numerically keys %picks) {
               push @splice,($pick-1)
            }
            foreach my $spl (@splice) {
               push @spl, $FullMenu->{$MenuUnit_hash_ref}[10]->[$spl];
            }
            my $send_select='Many' if $select_many;
            my $chosen={
               Select => $send_select,
               Banner => $MenuUnit_hash_ref->{Banner},
            }; my $cnt=0;
            my $hash_ref=$parent_menu||$MenuUnit_hash_ref;
            foreach my $text (@spl) {
               my $num=shift @splice;
               $cnt++;
               $chosen->{'Item_'.$cnt}=
                  { Text => $text,Default => '*',__NUM__=>$num+1 };
               $chosen->{'Item_'.$cnt}{Result}=
                  ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                  if exists ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
               $chosen->{'Item_'.$cnt}{Filter}=1;
            }
            %{$SavePick->{$chosen}}=%picks;
            $hidedefaults=1;
            eval {
               my ($ignore1,$ignore2,$ignore3)=('','','');
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,$ignore1,$ignore2,
                  $ignore3)
                  =&Menu($chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            }; # MENU RETURN MENURETURN 3
            print "MENU RETURN 3\n" if $menu_return_debug;
            die $@ if $@;
            chomp($menu_output) if !(ref $menu_output);
            if ($menu_output eq '-') {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq '+') {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=${$FullMenu}{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq 'DONE_SUB') {
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($Term::Menus::fa_code,0,-3)
                             .'::' if $Term::Menus::fa_code;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     if (ref $sub eq 'CODE') {
                        if ($Term::Menus::fullauto && (!exists
                              ${$MenuUnit_hash_ref}{'NoPlan'} ||
                              !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN7\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           my $n='Number';
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                   'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                     $Net::FullAuto::FA_Core::makeplan->{$n},
                                  Item   => 
                                     &Data::Dump::Streamer::Dump($sub)->Out() }
                        }
                        eval { @resu=$sub->() };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@)
                                 eq 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') { %picks=();next }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                        $done=1;last
                     }
                     eval {
                        if ($subfile) {
                           $sub=~s/^[&]//;
                           if ($Term::Menus::fullauto && (!exists
                                 ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                 !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN8\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$pn{$numbor}[0];
                              }
                              my $n='Number';
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                      'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   => "&$subfile$sub" }
                           }
                           eval "\@resu=\&$subfile$sub";
                           my $firsterr=$@||'';
                           if ((-1<index $firsterr,'Undefined subroutine') &&
                                 (-1<index $firsterr,$sub)) {
                              if ($sub!~/::/) {
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              my $seconderr=$@||'';my $die='';
                              if ($seconderr=~/Undefined subroutine/) {
                                 if (${$FullMenu}{$MenuUnit_hash_ref}
                                       [2]{$all_menu_items_array[$numbor-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}
                                        {$MenuUnit_hash_ref}[2]
                                        {$all_menu_items_array[$numbor-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code File "
                                        .$Term::Menus::fa_code
                                        .",\n\t\tnor was a routine with "
                                        ."that name\n\t\tlocated in the"
                                        ." main:: script.\n";
                                 } else { $die="$firsterr\n       $seconderr" }
                              } else { $die=$seconderr }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } elsif ($firsterr) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr);
                           }
                        } else {
                           if ($sub!~/::/) {
                              $sub=~s/^[&]//; 
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           die $@ if $@;
                        }
                     };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                  }
                  return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output) {
               return $menu_output;
            } else {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            }
         } elsif ($numbor=~/^\s*\/(.+)$/s) {
            ## SLASH SEARCH
            if ($filtered_menu) {
               print "\n   WARNING!: ",
                     "Only -ONE- Level of Search is Supported!\n";
               sleep 2;
               last;
            }
            my $one=$1||'';
            chomp $one;
            $one=~s/\*/[\*]/g;
            $one=~s/\+/[\+]/g;
            $one=qr/$one/ if $one;
            my @spl=();
            chomp $numbor;
            my $def='';
            unless (exists $Persists->{$MenuUnit_hash_ref}{defaults}) {
               my $it=${[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}[0];
               $def=${$FullMenu}{$MenuUnit_hash_ref}[5]{$it};
               $def='.*' if $def eq '*';
               if ($def) {
                  my $cnt=1;
                  foreach my $item (sort
                        @{[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}) {
                     if ($item=~/$def/) {
                        $picks{$cnt}='*';
                     } $cnt++
                  }
               }
            }

            my $cnt=0;my $ct=0;my @splice=();
            foreach my $pik (@all_menu_items_array) {
               $cnt++;
               if ($pik=~/$one/s) {
                  push @spl, $pik;
                  $splice[$ct++]=$cnt;
               }
            }
            next if $#spl==-1;
            my $send_select='Many' if $select_many;
            my $chosen={
               Select => $send_select,
               Banner => ${$MenuUnit_hash_ref}{Banner},
            }; $cnt=0;
            foreach my $text (@spl) {
               my $num=$splice[$cnt];
               $cnt++;
               if (exists $picks{$num}) {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,Default => '*',__NUM__=>$num };
               } elsif ($def && $text=~/$def/) {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,Default => '*',__NUM__=>$num };
                  $picks{$num}='*';
               } else {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,__NUM__=>$num };
               }
               $chosen->{'Item_'.$cnt}{Result}=
                  ${${$MenuUnit_hash_ref}{${$FullMenu->
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                  if exists ${${$MenuUnit_hash_ref}{${$FullMenu->
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
               $chosen->{'Item_'.$cnt}{Filter}=1;
            }
            %{$SavePick->{$chosen}}=%picks;
            my @return_from_filtered_menu=();
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  @return_from_filtered_menu)=&Menu(
                  $chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            }; # MENU RETURN MENURETURN 4
            print "MENU RETURN 4\n" if $menu_return_debug;
            die $@ if $@;
            if (-1<$#return_from_filtered_menu) {
               if ((values %{$menu_output})[0] eq 'recurse') {
                  my %k=%{$menu_output};
                  delete $k{Menu};
                  my $lab=(keys %k)[0];
                  $menu_output=$labels{$lab};
               }
               $MenuMap=$Persists->{$MenuUnit_hash_ref};
               eval {
                  ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                     $SaveMMap,$SaveNext,$Persists)=&Menu(
                     $menu_output,$FullMenu,
                     $Selected,$Conveyed,$SavePick,
                     $SaveMMap,$SaveNext,$Persists,
                     $return_from_filtered_menu[0],
                     $MenuUnit_hash_ref,
                     $return_from_filtered_menu[2]);
               }; # MENU RETURN MENURETURN 5
               print "MENU RETURN 5\n" if $menu_return_debug;
               die $@ if $@;
            }
            chomp($menu_output) if !(ref $menu_output);
            if (($menu_output eq '-') && exists
                  $SavePick->{$MenuUnit_hash_ref}) {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq '+' && exists
                  $SavePick->{$MenuUnit_hash_ref}) {
               %picks=%{$SavePick->{$MenuUnit_hash_ref}};
               $start=$FullMenu->{$MenuUnit_hash_ref}[11];
            } elsif ($menu_output eq 'DONE_SUB') {
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($Term::Menus::fa_code,0,-3)
                             .'::' if $Term::Menus::fa_code;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     if (ref $sub eq 'CODE') {
                        if ($Term::Menus::fullauto && (!exists
                              $MenuUnit_hash_ref->{'NoPlan'} ||
                              !$MenuUnit_hash_ref->{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN9\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           my $n='Number';
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                   'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                     $Net::FullAuto::FA_Core::makeplan->{$n},
                                  Item   => 
                                     &Data::Dump::Streamer::Dump($sub)->Out() }
                        }
                        eval { @resu=$sub->() };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@) eq
                                 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') { %picks=();next }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                        $done=1;last
                     }
                     eval {
                        if ($subfile) {
                           $sub=~s/^[&]//;
                           if ($Term::Menus::fullauto && (!exists
                                 $MenuUnit_hash_ref->{'NoPlan'} ||
                                 !$MenuUnit_hash_ref->{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN10\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$pn{$numbor}[0];
                              }
                              my $n='Number';
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                      'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   => "&$subfile$sub" }
                           }
                           eval "\@resu=\&$subfile$sub";
                           my $firsterr=$@||'';
                           if ((-1<index $firsterr,'Undefined subroutine') &&
                                 (-1<index $firsterr,$sub)) {
                              if ($sub!~/::/) {
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              my $seconderr=$@||'';my $die='';
                              if ($seconderr=~/Undefined subroutine/) {
                                 if (${$FullMenu}{$MenuUnit_hash_ref}
                                       [2]{$all_menu_items_array[$numbor-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}
                                        {$MenuUnit_hash_ref}[2]
                                        {$all_menu_items_array[$numbor-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code File "
                                        .$Term::Menus::fa_code
                                        .",\n\t\tnor was a routine with "
                                        ."that name\n\t\tlocated in the"
                                        ." main:: script.\n";
                                 } else { $die="$firsterr\n       $seconderr" }
                              } else { $die=$seconderr }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } elsif ($firsterr) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr);
                           }
                        } else {
                           if ($sub!~/::/) {
                              $sub=~s/^[&]//;
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           die $@ if $@;
                        }
                     };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                  }
                  return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output eq '-') {
               $return_from_child_menu='-';
            } elsif ($menu_output eq '+') {
               $return_from_child_menu='+';
            } elsif ($menu_output) {
               return $menu_output;
            }
         } elsif (($numbor=~/^\</ || $ikey eq 'LEFTARROW') && $FullMenu) {
            if ($recurse_level==1) {
               print "\n   WARNING! - You are at the First Menu!\n";
               sleep 2;
            } elsif (grep { /\+|\*/ } values %picks) {
               return '+',
                  $FullMenu,$Selected,$Conveyed,
                  $SavePick,$SaveMMap,$SaveNext,
                  $Persists;
            } else {
               my %sp_copy=%{$SavePick->{$parent_menu}}
                     if exists $SavePick->{$parent_menu};
               foreach my $key (keys %sp_copy) {
                  $SavePick->{$parent_menu}->{$key}='-' if
                     $sp_copy{$key} eq '+';
               }
               $parent_menu->{Scroll}->[1]||=0;
               $main::maintain_scroll_flag||={};
               if ($parent_menu->{Scroll}->[1]>1 &&
                     !exists $main::maintain_scroll_flag->{$parent_menu}) {
                  --$parent_menu->{Scroll}->[1];
                  $main::maintain_scroll_flag->{$parent_menu}='';
               }
               return '-',
                  $FullMenu,$Selected,$Conveyed,
                  $SavePick,$SaveMMap,$SaveNext,
                  $Persists;
            } last;
         } elsif (($numbor=~/^\>/ || $ikey eq 'RIGHTARROW') && exists
                  $SaveNext->{$MenuUnit_hash_ref} &&
                  ((grep { /-|\+/ } values %picks) || $show_banner_only)) {
            $MenuMap=$SaveMMap->{$MenuUnit_hash_ref};
            my $returned_FullMenu='';
            my $returned_Selected='';
            my $returned_Conveyed='';
            my $returned_SavePick='';
            my $returned_SaveMMap='';
            my $returned_SaveNext='';
            my $returned_Persists='';
            my $menu_result='';
            if (exists $Selected->{$MenuUnit_hash_ref}
                  {'__FA_Banner__'}) {
               $menu_result=$Selected->{$MenuUnit_hash_ref}
                            {'__FA_Banner__'};
               $menu_result=$menu_result->() if ref
                  $menu_result eq 'CODE';
            } else {
               $menu_result=$FullMenu->{$MenuUnit_hash_ref}[2]
                            {$all_menu_items_array[(keys %{$SavePick->
                            {$MenuUnit_hash_ref}})[0]-1]};
            }
            eval {
               ($menu_output,$returned_FullMenu,
                  $returned_Selected,$returned_Conveyed,
                  $returned_SavePick,$returned_SaveMMap,
                  $returned_SaveNext,$returned_Persists)
                  =&Menu($menu_result,$convey,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveMMap,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            }; # MENU RETURN MENURETURN 6
            print "MENU RETURN 6\n" if $menu_return_debug;
            die $@ if $@;
            chomp($menu_output) if !(ref $menu_output);
            if (ref $menu_output eq 'ARRAY' &&
                  $menu_output->[0]=~/^[{](.*)[}][<]$/) {
               delete $Selected->{$MenuUnit_hash_ref};
               delete $Conveyed->{$MenuUnit_hash_ref};
               delete $SavePick->{$MenuUnit_hash_ref};
               delete $SaveMMap->{$MenuUnit_hash_ref};
               delete $SaveNext->{$MenuUnit_hash_ref};
               delete $Persists->{$MenuUnit_hash_ref};
               if ($1 eq $MenuUnit_hash_ref->{Name}) {
                  delete $FullMenu->{$MenuUnit_hash_ref}[2]
                         {'__FA_Banner__'};
                  %picks=();
                  next;
               } else {
                  delete $FullMenu->{$MenuUnit_hash_ref};
                  return $menu_output,
                     $FullMenu,$Selected,$Conveyed,
                     $SavePick,$SaveMMap,$SaveNext,
                     $Persists;
               }
            } else {
               $FullMenu=$returned_FullMenu;
               $Selected=$returned_Selected;
               $Conveyed=$returned_Conveyed;
               $SavePick=$returned_SavePick;
               $SaveMMap=$returned_SaveMMap;
               $SaveNext=$returned_SaveNext;
               $Persists=$returned_Persists;
            }
            if ($menu_output eq 'DONE_SUB') {
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  if ($Term::Menus::fullauto && (!exists
                        $MenuUnit_hash_ref->{'NoPlan'} ||
                        !$MenuUnit_hash_ref->{'NoPlan'}) &&
                        defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN11\n";
                     if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}} &&
                           !exists $Net::FullAuto::FA_Core::makeplan->{
                           'Title'}) {
                        $Net::FullAuto::FA_Core::makeplan->{'Title'}
                           =$pn{$numbor}[0];
                     }
                     unless ($got_default) {
                        push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
                             { Menu   => &pw($MenuUnit_hash_ref),
                               Number => $numbor,
                               PlanID =>
                                  $Net::FullAuto::FA_Core::makeplan->{Number},
                               Item   => $pn{$numbor}[0] }
                     }
                  }
                  my $subfile=substr($Term::Menus::fa_code,0,-3)
                             .'::' if $Term::Menus::fa_code;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     if (ref $sub eq 'CODE') {
                        if ($Term::Menus::fullauto && (!exists
                              ${$MenuUnit_hash_ref}{'NoPlan'} ||
                              !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN12\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           my $n='Number';
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                  'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                     $Net::FullAuto::FA_Core::makeplan->{$n},
                                  Item   => 
                                     &Data::Dump::Streamer::Dump($sub)->Out() }
                        }
                        eval { @resu=$sub->() };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@)
                                 eq 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') { %picks=();next }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                        $done=1;last
                     }
                     eval {
                        if ($subfile) {
                           $sub=~s/^[&]//;
                           if ($Term::Menus::fullauto && (!exists
                                 ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                 !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN13\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$pn{$numbor}[0];
                              }
                              my $n='Number';
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                      'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   => "&$subfile$sub" }
                           }
                           eval "\@resu=\&$subfile$sub";
                           my $firsterr=$@||'';
                           if ((-1<index $firsterr,'Undefined subroutine') &&
                                 (-1<index $firsterr,$sub)) {
                              if ($sub!~/::/) {
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              my $seconderr=$@||'';my $die='';
                              if ($seconderr=~/Undefined subroutine/) {
                                 if (${$FullMenu}{$MenuUnit_hash_ref}
                                       [2]{$all_menu_items_array[$numbor-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}
                                        {$MenuUnit_hash_ref}[2]
                                        {$all_menu_items_array[$numbor-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code File "
                                        .$Term::Menus::fa_code
                                        .",\n\t\tnor was a routine with "
                                        ."that name\n\t\tlocated in the"
                                        ." main:: script.\n";
                                 } else { $die="$firsterr\n       $seconderr" }
                              } else { $die=$seconderr }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } elsif ($firsterr) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr);
                           }
                        } else {
                           if ($sub!~/::/) {
                              $sub=~s/^[&]//;
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           die $@ if $@;
                        }
                     };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                  } 
                  return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output eq '-') {
               $return_from_child_menu='-';
            } elsif ($menu_output eq '+') {
               $return_from_child_menu='+';
            } elsif ($menu_output) {
               return $menu_output;
            }
         } elsif ($ikey eq 'ESC' || $numbor=~/^quit|exit|bye$/i) {
            print "\n" if $^O ne 'cygwin';
            return ']quit['
         } elsif ($Term::Menus::fullauto and $ikey eq 'F1' ||
               $numbor=~/^help$/i) {
            system('man Net::FullAuto');
         } elsif ($ikey eq 'F1' || $numbor=~/^help$/i) {
            system('man Term::Menus');
         } elsif ($Term::Menus::fullauto and $numbor=~/^admin$/i) {
            if (!exists $Net::FullAuto::FA_Core::admin_menus{
                  &pw($MenuUnit_hash_ref)}) {
               while (1) {
                  my @menu_output=Menu($Net::FullAuto::FA_Core::admin_menu->())
                     if $Net::FullAuto::FA_Core::admin_menu;
                  last if $menu_output[0] ne '-' && $menu_output[0] ne '+';
               }
            } else {
               return ['{admin}<'],$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveMMap,$SaveNext,$Persists;
            }
         } elsif (!keys %{$FullMenu->{$MenuUnit_hash_ref}[1]}
                                             && $numbor=~/^[Aa]$/) {
            if (!$select_many && !(keys %{$MenuUnit_hash_ref->{Select}})) {
               print "\n   ERROR: Cannot Select All Items\n".
                     "          When 'Select' is NOT set to 'Many'\n";
               sleep 2;next;
            }
            if ($filtered_menu) {
               foreach my $num (0..$#all_menu_items_array) {
                  $picks{$num+1}='*';
               }
               foreach my $key (keys %{$FullMenu->{$MenuUnit_hash_ref}[8]}) {
                  $SavePick->{$parent_menu}{$FullMenu->
                     {$MenuUnit_hash_ref}[8]{$key}}='*';
               }
            } else {
               my $nmp=$num_pick-1;
               foreach my $pck (0..$nmp) {
                  if ($select_many ||
                         exists $FullMenu->{$MenuUnit_hash_ref}[6]->{
                         $all_menu_items_array[$pck]}) {
                     $picks{$pck+1}='*'
                  }
               }
            }
         } elsif ($numbor=~/^[Cc]$/) {
            ## CLEAR ALL CLEARALL
            foreach my $key (keys %{${$FullMenu}{$MenuUnit_hash_ref}[8]}) {
               delete ${$SavePick}{$parent_menu}{${$FullMenu}
                  {$MenuUnit_hash_ref}[8]{$key}};
            }
            foreach my $pick (keys %picks) {
               if (exists $picks{$pick}) {
                  delete $picks{$pick};
                  delete $items{$pick};
                  delete $Selected->{$MenuUnit_hash_ref}{$pick};
                  delete $Selected->{$parent_menu}{$pick};  
                  delete $SavePick->{$MenuUnit_hash_ref}{$pick};
                  delete $SavePick->{$parent_menu}{$pick};
                  delete $SaveNext->{$MenuUnit_hash_ref};
               }
            } $FullMenu->{$parent_menu}[5]='';
            $return_from_child_menu=0;
            $Persists->{$MenuUnit_hash_ref}{defaults}=0;
            $Persists->{$parent_menu}{defaults}=0 if defined $parent_menu; 
         }
         if ($numbor=~/^u$/i || $ikey eq 'UPARROW' || $ikey eq 'PAGEUP') {
            if ($ikey ne 'PAGEUP' && exists $MenuUnit_hash_ref->{Scroll}
                  && $MenuUnit_hash_ref->{Scroll}) {
               $MenuUnit_hash_ref->{Scroll}->[1]-- if
                  $MenuUnit_hash_ref->{Scroll}->[1]!=1;
               my $remainder=0;my $curscreennum=0;
               $remainder=$num_pick % $display_this_many_items if $num_pick;
               $curscreennum=($start+$remainder==$num_pick)?
                     $start+$remainder:$start+$choose_num;
               if ($curscreennum-$remainder==
                     $MenuUnit_hash_ref->{Scroll}->[1] &&
                     $curscreennum==$num_pick) {
                  $start=$start-$display_this_many_items;
                  $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
               } elsif ($start==$MenuUnit_hash_ref->{Scroll}->[1]) {
                  if ($display_this_many_items<$num_pick-$start
                        || $remainder || (!$remainder &&
                        (($num_pick==$start+1) ||
                        ($num_pick==$start+$display_this_many_items)))) {
                     $start=$start-$display_this_many_items;
                     $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
                  }
               } else { next }
               $numbor=$start+$choose_num+1;
               $hidedefaults=0;
               last;
            } elsif (0<=$start-$display_this_many_items) {
               $start=$start-$display_this_many_items;
               $MenuUnit_hash_ref->{Scroll}->[1]=
                  $start+$display_this_many_items
                  if $ikey eq 'PAGEUP' &&
                  exists $MenuUnit_hash_ref->{Scroll}
                  && $MenuUnit_hash_ref->{Scroll};
               $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
            } else {
               $start=$FullMenu->{$MenuUnit_hash_ref}[11]=0;
            }
            $numbor=$start+$choose_num+1;
            $hidedefaults=0;
            last;
         } elsif ($ikey eq 'END') {
            $FullMenu->{$MenuUnit_hash_ref}[11]=$num_pick;
            $MenuUnit_hash_ref->{Scroll}->[1]=$num_pick if
               $MenuUnit_hash_ref->{Scroll} &&
               $MenuUnit_hash_ref->{Scroll};
            $hidedefaults=0;
            if ($num_pick==$start+$choose_num) {
               next;
            }
            my $remainder=$num_pick % $choose_num;
            if ($remainder) {
               $start=$num_pick-$remainder;
            } else {
               $start=$num_pick-$display_this_many_items;
            }
            last;
         } elsif ($ikey eq 'HOME') {
            $FullMenu->{$MenuUnit_hash_ref}[11]=0;
            $MenuUnit_hash_ref->{Scroll}->[1]=1 if
               $MenuUnit_hash_ref->{Scroll} &&
               $MenuUnit_hash_ref->{Scroll}; 
            $hidedefaults=0;
            $start=0;
            last;
         } elsif ($numbor && unpack('a1',$numbor) eq '!') {
            # SHELLOUT shellout
            my $username=getlogin || getpwuid($<);
            my $cmd=unpack('x1 a*',$numbor);
            print "\n";
            unless ($^O eq 'cygwin') {
               system("su -l -c$cmd $username");
            } else {
               system($cmd);
            }
            print "\nPress ENTER to continue";<STDIN>;
            next;
         } elsif (((!$ikey || $ikey eq 'ENTER') &&
               ($numbor=~/^()$/ || $numbor=~/^\n/)) || $numbor=~/^d$/i
               || $ikey eq 'DOWNARROW' || $ikey eq 'PAGEDOWN') {
            $ikey||='ENTER';
            delete $main::maintain_scroll_flag->{$MenuUnit_hash_ref}
               if defined $main::maintain_scroll_flag;
            if (($ikey eq 'DOWNARROW' || $numbor=~/^d$/i) &&
                  exists $MenuUnit_hash_ref->{Scroll}
                  && $MenuUnit_hash_ref->{Scroll}) {
               my $remainder=0;my $curscreennum=0;
               $remainder=$num_pick % $choose_num if $num_pick;
               $curscreennum=($start+$remainder==$num_pick)?
                     $start+$remainder:$start+$choose_num;
               $MenuUnit_hash_ref->{Scroll}->[1]++
                  if $MenuUnit_hash_ref->{Scroll}->[1]!=$num_pick;
               if ($curscreennum<$MenuUnit_hash_ref->{Scroll}->[1]) {
                  if ($display_this_many_items<$num_pick-$start) {
                     $start=$start+$display_this_many_items;
                     $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
                  } else {
                     $start=$start+$remainder;
                     $FullMenu->{$MenuUnit_hash_ref}[11]=$num_pick;
                  }
               } else { next }
               $hidedefaults=0;
               $numbor=$start+$choose_num+1;
               last;
            } elsif ($ikey eq 'ENTER' && exists $MenuUnit_hash_ref->{Scroll}
                  && $MenuUnit_hash_ref->{Scroll} && !$show_banner_only) {
               $numbor=$MenuUnit_hash_ref->{Scroll}->[1];
               $MenuUnit_hash_ref->{Scroll}->[1]++
                  if $MenuUnit_hash_ref->{Scroll}->[1]!=$num_pick;
            } else {
               if ($show_banner_only) {
                  if (exists $MenuUnit_hash_ref->{Result}) {
                     $numbor='f';
                     $picks{'__FA_Banner__'}='';
                     my $remainder=0;
                     $remainder=$choose_num % $num_pick if $num_pick;
                     my $curscreennum=($start+$remainder==$num_pick)?
                     $start+$remainder:$start+$choose_num;
                     my $numpick=0;
                     if ($parent_menu and exists $parent_menu->{Scroll}) {
                        if (ref $parent_menu->{Scroll} eq 'ARRAY') {
                           $numpick=$#{[keys %{$FullMenu->{$parent_menu}[2]}]};
                           if ($curscreennum+$display_this_many_items
                                 <$parent_menu->{Scroll}->[1] &&
                                 $parent_menu->{Scroll}->[1]<$numpick) {
                              $FullMenu->{$parent_menu}[11]=
                                 $parent_menu->{Scroll}->[1];
                           }
                        }
                        $parent_menu->{Scroll}->[1]||=0;
                     }
                  } else {
                     return 'DONE_SUB';
                  }
               } elsif ($display_this_many_items<$num_pick-$start) {
                  $start=$start+$display_this_many_items;
                  $MenuUnit_hash_ref->{Scroll}->[1]=$start+1 if
                     exists $MenuUnit_hash_ref->{Scroll}
                     && $MenuUnit_hash_ref->{Scroll};
                  $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
               } elsif ($ikey ne 'PAGEDOWN') {
                  $start=$FullMenu->{$MenuUnit_hash_ref}[11]=0;
               }
               unless ($show_banner_only || $numbor!~/^\d+/) {
                  $hidedefaults=0;
                  $numbor=$start+$choose_num+1;
                  last;
               }
            }
         } chomp $numbor;
         if (!((keys %picks) && $numbor=~/^[Ff]$/) &&
               $numbor!~/^\d+|admin$/ && !$return_from_child_menu) {
            delete $main::maintain_scroll_flag->{$MenuUnit_hash_ref}
               if defined $main::maintain_scroll_flag;
            $numbor=$start+$choose_num+1;
            last;
         } elsif (exists $pn{$numbor} || ((keys %picks) && $numbor=~/^[Ff]$/)) {
            # NUMBOR CHOSEN
            delete $main::maintain_scroll_flag->{$MenuUnit_hash_ref}
               if defined $main::maintain_scroll_flag;
            delete $picks{'__FA_Banner__'} if exists $picks{'__FA_Banner__'};
            %pn=() unless %pn;
            my $callertest=__PACKAGE__."::Menu";
            if ($Persists->{$MenuUnit_hash_ref}{defaults} && !$filtered_menu) {
               $Persists->{$MenuUnit_hash_ref}{defaults}=0;
               $Persists->{$parent_menu}{defaults}=0 if $parent_menu;
               foreach my $pick (keys %picks) {
                  if (exists $picks{$pick} && !$picks{$numbor}) {
                     if ($picks{$pick} eq '*') {
                        delete $picks{$pick};
                        delete $items{$pick};
                        delete $Selected->{$MenuUnit_hash_ref}{$pick};
                     } elsif ($picks{$pick} eq '+') {
                        &delete_Selected($MenuUnit_hash_ref,$pick,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        delete $picks{$pick};
                        delete $items{$pick};
                     }
                  }
               } $FullMenu->{$MenuUnit_hash_ref}[5]='';
            }
            $pn{$numbor}[1]||=1;
            my $digital_numbor=($numbor=~/^\d+$/) ? $numbor : 1;
            $all_menu_items_array[0]||=''; 
            if (exists $MenuUnit_hash_ref->{Result} &&
                  !defined $MenuUnit_hash_ref->{Result}) {
               my $name=$MenuUnit_hash_ref->{Name};
               print "\n\n";
               my $fatal_error=<<END;

  FATAL ERROR!:   The Menu Block \"$name\" :

END
               $fatal_error.=<<'END';
          has a  Result => undef  element defined, but not instantiated.
          There may be a couple reasons for this, having to do with scope
          and where code blocks are located in relation to each other in
          the script. It could also be that you didn't provide a value
          for the element. If blocks are locally scoped with "my" than
          the result block must exist ABOVE the calling block:

             my $block_being_called  = { ... };
             my $block_doing_calling = { Result => $block_being_called, };

          However, with more complex menu implementations, this
          convenience is not always possible or workable. In this
          situation, the approach is different. It will be necessary to
          globally scope code blocks, and use full package naming
          conventions when calling code blocks:

             our $block_doing_calling = {

                    Result => $Full::Package::Name::Of::block_being_called,

                 };
             our $block_being_called  = { ... };
 
          ---------------------------------------------------------------

          Result =>   elements MUST have a value. A NULL value will work:

             my|our $block_being_called = { Result => '', }

END
               die $fatal_error;
            }
            if (($select_many ||
                  (exists ${$MenuUnit_hash_ref}{Select}{$numbor}))
                  && $numbor!~/^[Ff]$/) {
               if ($filtered_menu && (exists
                     $SavePick->{$parent_menu}{$numbor})) {
                  if ($Persists->{$parent_menu}{defaults}) {
                     $Persists->{$parent_menu}{defaults}=0;
                     $Persists->{$MenuUnit_hash_ref}{defaults}=0;
                     foreach my $pick (keys %picks) {
                        if (exists $picks{$pick} && !$picks{$numbor}) {
                           if ($picks{$pick} eq '*') {
                              delete $picks{$pick};
                              delete $items{$pick};
                              delete $Selected->{$parent_menu}{$pick};
                              delete $SavePick->{$MenuUnit_hash_ref}{$numbor};
                           } elsif ($picks{$pick} eq '+') {
                              &delete_Selected($parent_menu,$pick,
                                 $Selected,$SavePick,$SaveNext,$Persists);
                              $SaveNext={%{$SavePick}};
                              delete $picks{$pick};
                              delete $items{$pick};
                           }
                        }
                     } $FullMenu->{$MenuUnit_hash_ref}[5]='';
                  }
                  delete $Selected->{$MenuUnit_hash_ref}{$numbor};
                  delete $picks{$numbor};
                  delete $items{$numbor};
                  delete $SaveNext->{$MenuUnit_hash_ref};
                  delete $SavePick->{$MenuUnit_hash_ref}{$numbor};
                  delete $SavePick->{$parent_menu}{$numbor};
               } elsif (exists $picks{$numbor}) {
                  if ($picks{$numbor} eq '*') {
                     delete $picks{$numbor};
                     delete $items{$numbor};
                     delete $Selected->{$MenuUnit_hash_ref}{$numbor};
                     delete $SavePick->{$MenuUnit_hash_ref}{$numbor};
                     delete $SavePick->{$parent_menu}{$numbor}
                        if $filtered_menu;
                  } else {
                     &delete_Selected($MenuUnit_hash_ref,$numbor,
                         $Selected,$SavePick,$SaveNext,$Persists);
                     delete $picks{$numbor};
                     delete $items{$numbor};
                  }
               } else {
                  $items{$numbor}=$FullMenu->{$MenuUnit_hash_ref}
                                   [4]{$all_menu_items_array[$numbor-1]};
                  $SavePick->{$parent_menu}{$numbor}='*'
                     if $filtered_menu;
                  my $skip=0;
                  foreach my $key (keys %picks) {
                     if (defined $all_menu_items_array[$key-1] &&
                           exists ${$FullMenu}{$MenuUnit_hash_ref}[1]->{
                           $all_menu_items_array[$key-1]}
                           && (grep { $items{$numbor} eq $_ }
                           @{${$FullMenu}{$MenuUnit_hash_ref}[1]->{
                           $all_menu_items_array[$key-1]}})) {
                        my $warn="\n   WARNING! You Cannot Select ";
                        $warn.="Line $numbor while Line $key is Selected!\n";
                        print "$warn";sleep 2;
                        $skip=1;
                     } elsif ($picks{$key} eq '-') {
                        delete ${$Selected}{$MenuUnit_hash_ref}{$key};
                        delete $picks{$key};
                        delete $SaveNext->{$MenuUnit_hash_ref};
                     }
                  }
                  if ($skip==0) {
                     $picks{$numbor}='*';
                     $negate{$numbor}=
                        ${${$FullMenu}{$MenuUnit_hash_ref}[1]}
                        {$all_menu_items_array[$numbor-1]};
                     %{$SavePick->{$MenuUnit_hash_ref}}=%picks;
                  }
               }
               if ($prev_menu && $prev_menu!=$numbor) {
                  &delete_Selected($MenuUnit_hash_ref,$prev_menu,
                     $Selected,$SavePick,$SaveNext,$Persists);
                  delete $picks{$prev_menu};
                  delete $items{$prev_menu};
               }
            } elsif (($show_banner_only && exists $MenuUnit_hash_ref->
                         {Result} and ref $MenuUnit_hash_ref->
                         {Result} eq 'HASH') || ($numbor=~/^\d+$/ &&
                         (ref $FullMenu->{$MenuUnit_hash_ref}[2]
                         {$all_menu_items_array[$digital_numbor-1]||
                         $all_menu_items_array[$pn{$digital_numbor}[1]-1]}
                         eq 'HASH')) || ($numbor=~/^[Ff]$/ &&
                         ref $FullMenu->{$MenuUnit_hash_ref}[2]
                         {$all_menu_items_array[((keys %picks)[0]||1)-1]}
                         eq 'HASH')) {
               my $numbor_is_eff=0;
               if ($numbor=~/^[Ff]$/) {
                  $numbor=(keys %picks)[0];
                  $numbor_is_eff=1;
               }
               if (grep { /Item_/ } keys %{$MenuUnit_hash_ref}) {
                  my @items=();
                  foreach my $key (keys %{$MenuUnit_hash_ref}) {
                     next unless $key=~/Item_/;
                     push @items, $MenuUnit_hash_ref->{$key};
                  }
                  if ($#items==0 && ref $items[0] eq 'HASH' &&
                        (!grep { /Item_/ } keys %{$items[0]}) &&
                        grep { /Banner/ } keys %{$items[0]}) {
                     $show_banner_only=1;
                  }
               }
               if ($show_banner_only ||
                         (grep { /Item_/ } keys %{$FullMenu->{
                         $MenuUnit_hash_ref}[2]{$all_menu_items_array[
                         $numbor-1]||$all_menu_items_array[
                         $pn{$numbor}[1]-1]}})|| exists $labels{
                         (keys %{$FullMenu->{$MenuUnit_hash_ref}[2]
                         {$all_menu_items_array[$digital_numbor-1]
                         ||''}})[0]or[]}||
                         &test_hashref($FullMenu->{$MenuUnit_hash_ref}[2]
                         {$all_menu_items_array[$numbor-1]||
                         $all_menu_items_array[$pn{$numbor}[1]-1]})) {
                  my $menyou='';
                  my $cur_menu=($filtered_menu)?$parent_menu:$MenuUnit_hash_ref;
                  if ($filtered_menu) {
                     my @all_copy=@all_menu_items_array;
                     @all_menu_items_array=();
                     my $pstart=0;
                     my $pstop=0;
                     foreach my $pik (sort numerically keys %pn) {
                        $pstop=$pik-2;
                        foreach my $item ($pstart..$pstop) {
                           push @all_menu_items_array,'';
                        }
                        push @all_menu_items_array, shift @all_copy;
                        $pstart=$pstop+2;
                        $pstop=0;
                     }
                     while (my $pst=$pstart--) {
                        if ($pst=~/0$/) {
                           $FullMenu->{$cur_menu}[11]=$pst;
                           last;
                        }
                     }
                     delete $SavePick->{$MenuUnit_hash_ref};
                     delete $SaveNext->{$MenuUnit_hash_ref};
                  }
                  if (!$filtered_menu) {
                     if (exists $MenuUnit_hash_ref->{Result}) {
                        $FullMenu->{$MenuUnit_hash_ref}[2]
                           {'__FA_Banner__'}
                           =$MenuUnit_hash_ref->{Result};
                     } elsif (exists $labels{(keys %{$FullMenu->
                           {$MenuUnit_hash_ref}[2]
                           {$all_menu_items_array[$digital_numbor-1]}})[0]}) {
                        my %men_result=%{$FullMenu->
                           {$MenuUnit_hash_ref}[2]
                           {$all_menu_items_array[$digital_numbor-1]}};
                        $menyou=&Data::Dump::Streamer::Dump($labels{
                           (keys %men_result)[0]})->Out();
#print "MENYOU=$menyou<==\n";<STDIN>;
                        $menyou=~s/\$HASH\d*\s*=\s*//s;
                        my $mnyou=eval $menyou;
#print "WHAT IS THE CONVEY=$mnyou->{Item_1}->{Convey}<==\n";
                        $FullMenu->
                           {$MenuUnit_hash_ref}[2]
                           {$all_menu_items_array[$numbor-1]}=$mnyou;
                        my $itemnum=$FullMenu->{$MenuUnit_hash_ref}[4]
                                    {$all_menu_items_array[$numbor-1]};
                     }
                  }
                  chomp($numbor) if $numbor;
                  unless ($numbor_is_eff) {
                     if (exists $picks{$numbor}) {
                        #$FullMenu->{$cur_menu}[5]='ERASE';
                        $hidedefaults=0;
                        foreach my $key (keys %{$SaveNext}) {
                           delete $SaveNext->{$key};
                        }
                        if ($picks{$numbor} eq '*') {
                           delete $picks{$numbor};
                           delete $items{$numbor};
                           delete $Selected->{$cur_menu}{$numbor};
                        } elsif ($picks{$numbor} ne ' ') {
                           &delete_Selected($cur_menu,$numbor,
                              $Selected,$SavePick,$SaveNext,$Persists);
                           delete $picks{$numbor};
                           delete $items{$numbor};
                        }
                     }
                     if ($prev_menu && $prev_menu!=$numbor) {
                        #$FullMenu->{$cur_menu}[5]='ERASE';
                        $hidedefaults=0;
                        &delete_Selected($cur_menu,$prev_menu,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        delete $picks{$prev_menu};
                        delete $items{$prev_menu};
                     }
                  } elsif (!$show_banner_only) {
                     foreach my $key (keys %picks) {
                        if (($start<=$key) || ($key<=$start+$choose_num)) {
                           $numbor=$key;
                           last;
                        }
                     }
                  }
                  my $next_menu_ref='';
                  unless ($show_banner_only) {
                     $next_menu_ref=$FullMenu->
                        {$cur_menu}[2]
                        {$all_menu_items_array[$numbor-1]}
                        unless $filtered_menu;
                     $next_menu_ref||='';
                     delete $SavePick->{$next_menu_ref}
                        unless $filtered_menu;
                     $FullMenu->{$next_menu_ref}[11]=0
                        unless $filtered_menu;
                     %picks=() if (!$select_many &&
                        !exists ${$MenuUnit_hash_ref}{Select}{$numbor});
                     $picks{$numbor}='-' if !(keys %picks) || $numbor!~/^[Ff]$/;
                  }
                  ($FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,
                     $convey,$parent_menu)
                     =$get_result->($cur_menu,
                     \@all_menu_items_array,\%picks,
                     $picks_from_parent,$FullMenu,$Conveyed,$Selected,
                     $SaveNext,$Persists,$parent_menu);
                  %{$SavePick->{$cur_menu}}=%picks;
                  $Conveyed->{&pw($cur_menu)}=[];
                  if (0<$#{[keys %picks]}) {
                     foreach my $key (sort numerically keys %picks) {
                        push @{$Conveyed->{&pw($cur_menu)}},
                               $all_menu_items_array[$key-1];
                     }
                  } elsif ($numbor) {
                     $Conveyed->{&pw($cur_menu)}=
                        $all_menu_items_array[$numbor-1];
                  }
                  my $mcount=0;
                  unless (exists $SaveMMap->{$cur_menu}) {
                     if ($filtered_menu) {
                        my $pmap=[];
                        foreach my $kee (keys %{$SaveMMap}) {
                           my $map=&Data::Dump::Streamer::Dump(
                              $SaveMMap->{$kee})->Out();
                           $map=~s/\$ARRAY\d*\s*=\s*//s;
                           my $m=eval $map;
                           $pmap=$m if $#{$pmap}<$#{$m};
                        }
                        $SaveMMap->{$cur_menu}=$pmap;
                        $mcount=&get_Menu_map_count(
                           $SaveMMap->{$cur_menu});
                     } elsif ($parent_menu) {
                        my $parent_map=&Data::Dump::Streamer::Dump(
                              $SaveMMap->{$parent_menu})->Out();
                        $parent_map=~s/\$ARRAY\d*\s*=\s*//s;
                        $SaveMMap->{$cur_menu}=eval $parent_map;
                        $mcount=&get_Menu_map_count(
                           $SaveMMap->{$cur_menu});
                     } else {
                        $SaveMMap->{$cur_menu}=[];
                     }
                  }
                  if (ref $convey eq 'ARRAY') {
                     push @{$SaveMMap->{$cur_menu}},
                        [ ++$mcount, $convey->[0] ];
                  } else {
                     push @{$SaveMMap->{$cur_menu}},
                        [ ++$mcount, $convey ];
                  }
                  if ($filtered_menu) {
                     return $FullMenu->
                        {$cur_menu}[2]
                        {$all_menu_items_array[$numbor-1]},$convey,
                        $recurse_level,$FullMenu,
                        $Selected,$Conveyed,$SavePick,
                        $SaveMMap,$SaveNext,$Persists,
                        $cur_menu,$no_wantarray;
                  }
                  $MenuMap=$SaveMMap->{$cur_menu};
                  my $returned_FullMenu='';
                  my $returned_Selected='';
                  my $returned_Conveyed='';
                  my $returned_SavePick='';
                  my $returned_SaveMMap='';
                  my $returned_SaveNext='';
                  my $returned_Persists='';
                  my $menu_result='';
                  if (exists $Selected->{$cur_menu}
                        {'__FA_Banner__'}) {
                     $menu_result=$Selected->{$cur_menu}
                                  {'__FA_Banner__'};
                     $menu_result=$menu_result->() if ref
                        $menu_result eq 'CODE';
                  } else {
                     $menu_result=$FullMenu->{$cur_menu}[2]
                                  {$all_menu_items_array[$numbor-1]};
                  }
                  eval {
                     ($menu_output,$returned_FullMenu,
                        $returned_Selected,$returned_Conveyed,
                        $returned_SavePick,$returned_SaveMMap,
                        $returned_SaveNext,$returned_Persists)
                        =&Menu($menu_result,$convey,
                        $recurse_level,$FullMenu,
                        $Selected,$Conveyed,$SavePick,
                        $SaveMMap,$SaveNext,$Persists,
                        $cur_menu,$no_wantarray);
                  }; # MENU RETURN MENURETURN 7
                  print "MENU RETURN 7\n" if $menu_return_debug;
                  die $@ if $@;
                  if (ref $menu_output eq 'ARRAY' &&
                        $menu_output->[0]=~/^[{](.*)[}][<]$/) {
                     delete $Selected->{$MenuUnit_hash_ref};
                     delete $Conveyed->{$MenuUnit_hash_ref};
                     delete $SavePick->{$MenuUnit_hash_ref};
                     delete $SaveMMap->{$MenuUnit_hash_ref};
                     delete $SaveNext->{$MenuUnit_hash_ref};
                     delete $Persists->{$MenuUnit_hash_ref};
                     if ($1 eq $MenuUnit_hash_ref->{Name}) {
                        %picks=();
                        my $remainder=0;my $curscreennum=0;
                        $remainder=$num_pick % $choose_num if $num_pick;
                        $curscreennum=($start+$remainder==$num_pick)?
                           $start+$remainder:$start+$choose_num;
                        if ($curscreennum<$MenuUnit_hash_ref->{Scroll}->[1]
                               && $display_this_many_items<$num_pick-$start) {
                           $start=$start+$display_this_many_items;
                           $FullMenu->{$MenuUnit_hash_ref}[11]=$start;
                           if ($start+$remainder==$num_pick) {
                              $choose_num=$num_pick-$start;
                           } else { 
                              $choose_num=$display_this_many_items;
                           }
                        }
                        $show_banner_only=0;
                        next;
                     } else {
                        delete $FullMenu->{$MenuUnit_hash_ref};
                        return $menu_output,
                           $FullMenu,$Selected,$Conveyed,
                           $SavePick,$SaveMMap,$SaveNext,
                           $Persists;
                     }
                  } else {
                     $FullMenu=$returned_FullMenu;
                     $Selected=$returned_Selected;
                     $Conveyed=$returned_Conveyed;
                     $SavePick=$returned_SavePick;
                     $SaveMMap=$returned_SaveMMap;
                     $SaveNext=$returned_SaveNext;
                     $Persists=$returned_Persists;
                  }
                  chomp($menu_output) if !(ref $menu_output);
                  if ($filtered_menu) {
                     if (grep { /\+|\*/ } values %picks) {
                        return '+',
                           $FullMenu,$Selected,$Conveyed,
                           $SavePick,$SaveMMap,$SaveNext,
                           $Persists;
                     } else {
                        my %sp_copy=%{$SavePick->{$parent_menu}}
                              if exists $SavePick->{$parent_menu};
                        foreach my $key (keys %sp_copy) {
                           $SavePick->{$parent_menu}->{$key}='-' if
                              $sp_copy{$key} eq '+';
                        }
                        return '-',
                           $FullMenu,$Selected,$Conveyed,
                           $SavePick,$SaveMMap,$SaveNext,
                           $Persists;
                     }
                  } elsif ($menu_output eq '-') {
                     $return_from_child_menu='-';
                  } elsif ($menu_output eq '+') {
                     $return_from_child_menu='+';
                  } elsif ($menu_output eq 'DONE_SUB') {
                     return 'DONE_SUB';
                  } elsif ($menu_output eq 'DONE' and 1<$recurse_level) {
                     return 'DONE';
                  } elsif ($menu_output) {
                     return $menu_output;
                  } else {
                     if ($Term::Menus::fullauto && (!exists
                           ${$MenuUnit_hash_ref}{'NoPlan'} ||
                           !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                           defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN14\n";
                        if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}}
                              && !exists
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}) {
                           $Net::FullAuto::FA_Core::makeplan->{'Title'}
                              =$all_menu_items_array[$numbor-1];
                        }
                        unless ($got_default) {
                           push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
                             { Menu   => &pw($MenuUnit_hash_ref),
                               Number => $numbor,
                               PlanID =>
                                  $Net::FullAuto::FA_Core::makeplan->{Number},
                               Item   => $all_menu_items_array[$numbor-1] }
                        }
                     }
                     my $subfile=substr(
                           $Term::Menus::fa_code,0,-3).'::'
                           if $Term::Menus::fa_code;
                     $subfile||='';
                     foreach my $sub (&get_subs_from_menu($Selected)) {
                        my @resu=();
                        if (ref $sub eq 'CODE') {
                           if ($Term::Menus::fullauto && (!exists
                                 ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                 !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN15\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$all_menu_items_array[$numbor-1];
                              }
                              my $n='Numbor';
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                     'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   =>
                                        &Data::Dump::Streamer::Dump($sub)->Out()
                                   }
                           }
                           eval { @resu=$sub->() };
                           if ($@) {
                              if (10<length $@ && unpack('a11',$@) eq
                                    'FATAL ERROR') {
                                 if ($parent_menu && wantarray &&
                                       !$no_wantarray) {
                                    return '',$FullMenu,$Selected,$Conveyed,
                                           $SavePick,$SaveMMap,$SaveNext,
                                           $Persists,$parent_menu,$@;
                                 }
                                 if (defined $log_handle &&
                                       -1<index $log_handle,'*') {
                                    print $log_handle $@;
                                    close($log_handle);
                                 }
                                 if ($Term::Menus::fullauto) {
                                    &Net::FullAuto::FA_Core::handle_error($@);
                                 } else { die $@ }
                              } else {
                                 my $die="\n       FATAL ERROR! - The Local "
                                        ."System $Term::Menus::local_hostname "
                                        ."Conveyed\n"
                                        ."              the Following "
                                        ."Unrecoverable Error Condition :\n\n"
                                        ."       $@\n       line ".__LINE__;
                                 if ($parent_menu && wantarray &&
                                       !$no_wantarray) {
                                    return '',$FullMenu,$Selected,$Conveyed,
                                           $SavePick,$SaveMMap,$SaveNext,
                                           $Persists,$parent_menu,$die;
                                 }
                                 if (defined $log_handle &&
                                       -1<index $log_handle,'*') {
                                    print $log_handle $die;
                                    close($log_handle);
                                 }
                                 if ($Term::Menus::fullauto) {
                                    &Net::FullAuto::FA_Core::handle_error($die);
                                 } else { die $die }
                              }
                           }
                           if (-1<$#resu) {
                              if ($resu[0] eq '<') {
                                 %picks=();
                                 $show_banner_only=0;
                                 next
                              } 
                              if (0<$#resu && wantarray && !$no_wantarray) {
                                 return @resu;
                              } else {
                                 return return_result($resu[0],
                                    $MenuUnit_hash_ref,$Conveyed);
                              }
                           }
                           $done=1;last
                        }
                        eval {
                           if ($subfile) {
                              $sub=~s/^[&]//;
                              if ($Term::Menus::fullauto && (!exists
                                    ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                    !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                    defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN16\n";
                                 if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                       'Plan'}} && !exists
                                       $Net::FullAuto::FA_Core::makeplan->{
                                       'Title'}) {
                                    $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                       =$all_menu_items_array[$numbor-1];
                                 }
                                 my $n='Number';
                                 push @{$Net::FullAuto::FA_Core::makeplan->{
                                         'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   => "&$subfile$sub" }
                              }
                              eval "\@resu=\&$subfile$sub";
                              my $firsterr=$@||'';
                              if ((-1<index $firsterr,'Undefined subroutine') &&
                                    (-1<index $firsterr,$sub)) {
                                 if ($sub!~/::/) {
                                    eval "\@resu=main::$sub";
                                 } else {
                                    eval "\@resu=$sub";
                                 }
                                 my $seconderr=$@||'';my $die='';
                                 my $c=$Term::Menus::fa_code;
                                 if ($seconderr=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$MenuUnit_hash_ref}[2]
                                          {$all_menu_items_array[$numbor-1]}) {
                                       $die="The \"Result15 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}
                                           {$MenuUnit_hash_ref}[2]
                                           {$all_menu_items_array[$numbor-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code File "
                                           .$c.",\n\t\tnor was a routine with "
                                           ."that name\n\t\tlocated in the"
                                           ." main:: script.\n";
                                    } else {
                                       $die="$firsterr\n       $seconderr"
                                    }
                                 } else { $die=$seconderr }
                                 if ($Term::Menus::fullauto) {
                                    &Net::FullAuto::FA_Core::handle_error($die);
                                 } else {
                                    die $die;
                                 }
                              } elsif ($firsterr) {
                                 if ($Term::Menus::fullauto) {
                                    &Net::FullAuto::FA_Core::handle_error(
                                       $firsterr);
                                 } else {
                                    die $firsterr;
                                 }
                              }
                           } else {
                              if ($sub!~/::/) {
                                 $sub=~s/^[&]//;
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              die $@ if $@;
                           }
                        };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@) eq
                                 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') {
                              %picks=();
                              $show_banner_only=0;
                              next
                           }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                     }
                     return 'DONE_SUB';
                  }
               }
            } elsif ($FullMenu && $caller eq $callertest &&
                  ($select_many || (keys %{$MenuUnit_hash_ref->{Select}}))) {
               if ($numbor!~/^[Ff]$/ && exists $picks{$numbor}) {
                  if ($picks{$numbor} eq '*') {
                     delete $picks{$numbor};
                     delete $items{$numbor};
                     delete ${$Selected}{$MenuUnit_hash_ref}{$numbor};
                  } else {
                     &delete_Selected($MenuUnit_hash_ref,$numbor,
                        $Selected,$SavePick,$SaveNext,$Persists);
                     $SaveNext={%{$SavePick}};
                     delete $picks{$numbor};
                     delete $items{$numbor};
                  } last;
               }
               if (keys %{$FullMenu->{$MenuUnit_hash_ref}[2]}) {
                  $numbor=(keys %picks)[0] if $numbor=~/^[Ff]$/;
                  my $test_result=
                        $FullMenu->{$MenuUnit_hash_ref}[2]
                        {$all_menu_items_array[$numbor-1]};
                  if (ref $test_result eq 'CODE') {
                     my $cd='';
                     my $sub=$FullMenu->{$MenuUnit_hash_ref}[2]
                              {$all_menu_items_array[$picknum-1]};
                     my $select_ed=[];
                     if (0<$#{[keys %picks]}) {
                        foreach my $key (keys %picks) {
                           push @{$select_ed}, $pn{$key}[0];
                        }
                     } else {
                        $select_ed=$pn{$numbor}[0];
                     }
                     if ($Term::Menus::data_dump_streamer) {
                        $cd=&Data::Dump::Streamer::Dump($sub)->Out();
                        $cd=&transform_sicm($cd,$numbor,
                               \@all_menu_items_array,\%picks,'',
                               $return_from_child_menu,$log_handle,
                               $MenuUnit_hash_ref->{Name});
#print "CD3=$cd\n<=CD\n";<STDIN>;
                        $cd=&transform_pmsi($cd,
                               $Conveyed,$SaveMMap,
                               $picks_from_parent);
#print "CD4=$cd\n<=CD2\n";<STDIN>;
                     }
                     $cd=~s/\$CODE\d*\s*=\s*//s;
                     $sub=eval $cd;
                     my @resu=();
                     eval { @resu=$sub->() };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                  } elsif ($test_result &&
                        ($test_result!~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ ||
                        (!grep { $1 eq $_ } list_module('main',
                        $Term::Menus::fa_code) && $picks{$numbor} ne '*'))) {
                     my $die="The \"Result12 =>\" Setting\n              -> "
                            ."$test_result\n              Found in the Menu "
                            ."Unit -> ".$MenuUnit_hash_ref
                            ."\n              is NOT a Menu Unit\,"
                            ."\ and it is NOT a Valid Subroutine.\n\n"
                            ."\n              Cannot Determine "
                            ."if it is a Valid SubRoutine.\n\n";
                     die $die;
                  } elsif (!defined $pn{$numbor}[0] ||
                        !exists ${$FullMenu}{$MenuUnit_hash_ref}[2]{
                        $pn{$numbor}[0]}) {
                     my @resu=map { $all_menu_items_array[$_-1] }
                           sort numerically keys %picks;
                     push @resu,\%picks,$MenuUnit_hash_ref;
                     if (wantarray && !$no_wantarray) {
                        return @resu;
                     } elsif ($#resu==0) {
                        return @resu;
                     } else {
                        return \@resu;
                     }
                  }
                  if (${$FullMenu}{$MenuUnit_hash_ref}[2]
                                   {$pn{$numbor}[0]}) { }
                  ($FullMenu,$Conveyed,$SaveNext,
                     $Persists,$Selected,$convey,$parent_menu)
                     =$get_result->($MenuUnit_hash_ref,
                     \@all_menu_items_array,\%picks,$picks_from_parent,
                     $FullMenu,$Conveyed,$Selected,$SaveNext,
                     $Persists,$parent_menu);
                  my %pick=();
                  $pick{$numbor}='*';
                  %{$SavePick->{$MenuUnit_hash_ref}}=%pick;
                  if ($Term::Menus::fullauto && (!exists
                        $MenuUnit_hash_ref->{'NoPlan'} ||
                        !$MenuUnit_hash_ref->{'NoPlan'}) &&
                        defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN17\n";
                     if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}} &&
                           !exists
                           $Net::FullAuto::FA_Core::makeplan->{'Title'}) {
                        $Net::FullAuto::FA_Core::makeplan->{'Title'}
                           =$pn{$numbor}[0];
                     }
                     unless ($got_default) {
                        push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
                             { Menu   => &pw($MenuUnit_hash_ref),
                               Number => $numbor,
                               PlanID =>
                                  $Net::FullAuto::FA_Core::makeplan->{Number},
                               Item   => $pn{$numbor}[0] }
                     }
                  }
                  my $subfile=substr($Term::Menus::fa_code,0,-3)
                             .'::' if $Term::Menus::fa_code;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     if (ref $sub eq 'CODE') {
                        if ($Term::Menus::fullauto && (!exists
                              ${$MenuUnit_hash_ref}{'NoPlan'} ||
                              !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN18\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           my $n='Number';
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                  'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                     $Net::FullAuto::FA_Core::makeplan->{$n},
                                  Item   => 
                                     &Data::Dump::Streamer::Dump($sub)->Out()
                                }
                        }
                        eval { @resu=$sub->() };
                        if ($@) {
                           if (10<length $@ && unpack('a11',$@)
                                 eq 'FATAL ERROR') {
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$@;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $@;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($@);
                              } else { die $@ }
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                     ."System $Term::Menus::local_hostname "
                                     ."Conveyed\n"
                                     ."              the Following "
                                     ."Unrecoverable Error Condition :\n\n"
                                     ."       $@\n       line ".__LINE__;
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',$FullMenu,$Selected,$Conveyed,
                                        $SavePick,$SaveMMap,$SaveNext,
                                        $Persists,$parent_menu,$die;
                              }
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($Term::Menus::fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        }
                        if (-1<$#resu) {
                           if ($resu[0] eq '<') { %picks=();next }
                           if (0<$#resu && wantarray && !$no_wantarray) {
                              return @resu;
                           } else {
                              return return_result($resu[0],
                                 $MenuUnit_hash_ref,$Conveyed);
                           }
                        }
                        $done=1;last
                     }
                     eval {
                        if ($subfile) {
                           $sub=~s/^[&]//;
                           if ($Term::Menus::fullauto && (!exists
                                 ${$MenuUnit_hash_ref}{'NoPlan'} ||
                                 !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                                 defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN19\n";
                              if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                    'Plan'}} && !exists
                                    $Net::FullAuto::FA_Core::makeplan->{
                                    'Title'}) {
                                 $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                    =$pn{$numbor}[0];
                              }
                              my $n='Number';
                              push @{$Net::FullAuto::FA_Core::makeplan->{
                                      'Plan'}},
                                   { Menu   => &pw($MenuUnit_hash_ref),
                                     Number => $numbor,
                                     PlanID =>
                                        $Net::FullAuto::FA_Core::makeplan->{$n},
                                     Item   => "&$subfile$sub" }
                           }
                           eval "\@resu=\&$subfile$sub";
                           my $firsterr=$@||'';
                           if ((-1<index $firsterr,'Undefined subroutine') &&
                                 (-1<index $firsterr,$sub)) {
                              if ($sub!~/::/) {
                                 eval "\@resu=main::$sub";
                              } else {
                                 eval "\@resu=$sub";
                              }
                              my $seconderr=$@||'';my $die='';
                              if ($seconderr=~/Undefined subroutine/) {
                                 if (${$FullMenu}{$MenuUnit_hash_ref}
                                       [2]{$all_menu_items_array[$numbor-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}
                                        {$MenuUnit_hash_ref}[2]
                                        {$all_menu_items_array[$numbor-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code File "
                                        .$Term::Menus::fa_code
                                        .",\n\t\tnor was a routine with "
                                        ."that name\n\t\tlocated in the"
                                        ." main:: script.\n";
                                 } else { $die="$firsterr\n       $seconderr" }
                              } else { $die=$seconderr }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } elsif ($firsterr) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr);
                           }
                        } else {
                           if ($sub!~/::/) {
                              $sub=~s/^[&]//;
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           die $@ if $@;
                        }
                     };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                     $done=1;last
                  }
               } else { $done=1;last }
               return 'DONE_SUB';
            } elsif (($show_banner_only && exists $MenuUnit_hash_ref->
                  {Result} && ref $MenuUnit_hash_ref->{Result}
                  eq 'CODE')||(keys %{$FullMenu->{$MenuUnit_hash_ref}[2]} 
                  && exists $FullMenu->{$MenuUnit_hash_ref}[2]
                  {$pn{$numbor}[0]})) {
               my $test_result='';
               if ($show_banner_only) {
                  $test_result=$MenuUnit_hash_ref->{Result};
                  $numbor=1;
               } else {
                  $test_result=
                     $FullMenu->{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]};
               }
               if (ref $test_result eq 'CODE') {
                  my @resu=();
                  my $test_result_loop=$test_result;
                  while (1) {
                     my $look_at_test_result=
                           &Data::Dump::Streamer::Dump(
                           $test_result_loop)->Out();
                     my $tspmi_regex=qr/\](!)?t(?:e+st[-_]*)*[p|s]*
                           (?:r+vious[-_]*|e+lected[-_]*)
                           *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
                     my $sicm_regex=
                           qr/\](!)?s(?:e+lected[-_]*)*i*(?:t+ems[-_]*)
                           *c*(?:u+rrent[-_]*)*m*(?:e+nu[-_]*)*\[/xi;
                     my $tbii_regex=qr/\](!)?i(?:n+put[-_]*)*b*(?:a+nner[-_]*)
                           *m*(?:e+nu[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
                     my $trim_look=$look_at_test_result;
                     $trim_look=~s/^.*(\$CODE\d+\s*=\s*.*$)/$1/s;
                     if ((($trim_look!~/Item_/s &&
                           $trim_look!~/[']Result['][,]/s) ||
                           $trim_look=~/=\s*[']Item_/s) ||
                           $look_at_test_result=~/$tspmi_regex/ ||
                           $trim_look=~/$sicm_regex/ ||
                           $trim_look=~/$tbii_regex/) {
                        %picks=() unless $select_many;
                        $picks{$numbor}='';
                        ($FullMenu,$Conveyed,$SaveNext,$Persists,
                           $Selected,$convey,$parent_menu)
                           =$get_result->($MenuUnit_hash_ref,
                           \@all_menu_items_array,\%picks,$picks_from_parent,
                           $FullMenu,$Conveyed,$Selected,$SaveNext,
                           $Persists,$parent_menu);
                        my $item=($show_banner_only)?'__FA_Banner__':$numbor;
                        $test_result_loop=
                           $Selected->{$MenuUnit_hash_ref}->{$item}
                           if $Selected->{$MenuUnit_hash_ref}->{$item};
                        my $cd=&Data::Dump::Streamer::Dump(
                           $test_result_loop)->Out();
                        $cd=&transform_sicm($cd,$numbor,
                           \@all_menu_items_array,\%picks,\%pn,
                           $return_from_child_menu,$log_handle,
                           $MenuUnit_hash_ref->{Name});
                        $cd=&transform_pmsi($cd,
                           $Conveyed,$SaveMMap,
                           $picks_from_parent);
                        $cd=&transform_mbir($cd,$Conveyed,$MenuUnit_hash_ref,
                           $log_handle);
                        $cd=~s/\$CODE\d*\s*=\s*//s;
                        eval { $test_result_loop=eval $cd };
                     }
                     eval { @resu=$test_result_loop->() };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (0==$#resu && ref $resu[0] eq 'CODE') {
                        $test_result_loop=$resu[0];
                        $SaveNext->{$MenuUnit_hash_ref}=$resu[0];
                        next;
                     } else {
                        last;
                     }
                  }
                  if (-1<$#resu) {
                     if ($resu[0] eq '<') { %picks=();next }
                     if (0<$#resu && wantarray && !$no_wantarray) {
                        if (1==$recurse_level) {
                           return \@resu;
                        } else {
                           return @resu;
                        }
                     } elsif (ref $resu[0] eq 'HASH') {
                        if (grep { /Item_/ } keys %{$resu[0]} && $parent_menu) {
                           if (exists $FullMenu->{$parent_menu}[2]
                                 {'__FA_Banner__'}) {
                              $FullMenu->{$MenuUnit_hash_ref}[2]
                                 {'__FA_Banner__'}=$resu[0];
                           } else {
                              $FullMenu->{$MenuUnit_hash_ref}[2]
                                 {$pn{$numbor}[0]}=$resu[0];
                           }
                        } else {
                           $FullMenu->{$MenuUnit_hash_ref}[2]{'__FA_Banner__'}=
                              $resu[0];
                        }
                     } else {
                        return return_result($resu[0],
                           $MenuUnit_hash_ref,$Conveyed);
                     }
                  }
               } elsif ($test_result!~/^&?(?:.*::)*(\w+)\s*[(]?.*[)]?\s*$/ ||
                     !grep { $1 eq $_ } list_module(
                     'main',$Term::Menus::fa_code)) {
                  my $die="The \"Result14 =>\" Setting\n              -> "
                         .$test_result
                         ."\n              Found in the Menu Unit -> "
                         .$MenuUnit_hash_ref
                         ."\n              is not a Menu Unit\,"
                         ." and not a Valid SubRoutine.\n\n";
                  die $die;
               }
               %picks=() unless $select_many; 
               $picks{$numbor}='';
               ($FullMenu,$Conveyed,$SaveNext,$Persists,
                  $Selected,$convey,$parent_menu)
                  =$get_result->($MenuUnit_hash_ref,
                  \@all_menu_items_array,\%picks,$picks_from_parent,
                  $FullMenu,$Conveyed,$Selected,$SaveNext,
                  $Persists,$parent_menu);
               my $show_banner_only=0;
               my $test_item='';
               if (exists $Selected->{$MenuUnit_hash_ref}{'__FA_Banner__'}) {
                  $test_item=$Selected->{$MenuUnit_hash_ref}{'__FA_Banner__'};
                  $show_banner_only=1;
               } else {
                  $test_item=$FullMenu->{$MenuUnit_hash_ref}[2]
                     {$pn{$numbor}[0]};
               }
               $test_item||='';
               if ((ref $test_item eq 'HASH' &&
                     grep { /Item_/ } keys %{$test_item}) ||
                     $show_banner_only) {
                  $Conveyed->{&pw($MenuUnit_hash_ref)}=[];
                  if (0<$#{[keys %picks]}) {
                     foreach my $key (sort numerically keys %picks) {
                        push @{$Conveyed->{&pw($MenuUnit_hash_ref)}},
                               $all_menu_items_array[$key-1];
                     }
                  } else {
                     $Conveyed->{&pw($MenuUnit_hash_ref)}=
                        $all_menu_items_array[$numbor-1];
                  }
                  my $mcount=0;
                  unless (exists $SaveMMap->{$MenuUnit_hash_ref}) {
                     if ($filtered_menu) {
                        my $pmap=[];
                        foreach my $kee (keys %{$SaveMMap}) {
                           my $map=&Data::Dump::Streamer::Dump(
                              $SaveMMap->{$kee})->Out();
                           $map=~s/\$ARRAY\d*\s*=\s*//s;
                           my $m=eval $map;
                           $pmap=$m if $#{$pmap}<$#{$m};
                        }
                        $SaveMMap->{$MenuUnit_hash_ref}=$pmap;
                        $mcount=&get_Menu_map_count(
                           $SaveMMap->{$MenuUnit_hash_ref});
                     } elsif ($parent_menu) {
                        my $parent_map=&Data::Dump::Streamer::Dump(
                              $SaveMMap->{$parent_menu})->Out();
                        $parent_map=~s/\$ARRAY\d*\s*=\s*//s;
                        $SaveMMap->{$MenuUnit_hash_ref}=eval $parent_map;
                        $mcount=&get_Menu_map_count(
                           $SaveMMap->{$MenuUnit_hash_ref});
                     } else {
                        $SaveMMap->{$MenuUnit_hash_ref}=[];
                     }
                  }
                  if (ref $convey eq 'ARRAY') {
                     push @{$SaveMMap->{$MenuUnit_hash_ref}},
                        [ ++$mcount, $convey->[0] ];
                  } else {
                     push @{$SaveMMap->{$MenuUnit_hash_ref}},
                        [ ++$mcount, $convey ];
                  }
                  $MenuMap=$SaveMMap->{$MenuUnit_hash_ref};
                  my $returned_FullMenu='';
                  my $returned_Selected='';
                  my $returned_Conveyed='';
                  my $returned_SavePick='';
                  my $returned_SaveMMap='';
                  my $returned_SaveNext='';
                  my $returned_Persists='';
                  my $menu_result='';
                  if ($show_banner_only) {
                     $menu_result=$test_item;
                  } else {
                     $menu_result=$FullMenu->{$MenuUnit_hash_ref}[2]
                                  {$all_menu_items_array[$numbor-1]};
                  }
                  $SaveNext->{$MenuUnit_hash_ref}=$menu_result
                     unless exists $SaveNext->{$MenuUnit_hash_ref};
                  eval {
                     ($menu_output,$returned_FullMenu,
                        $returned_Selected,$returned_Conveyed,
                        $returned_SavePick,$returned_SaveMMap,
                        $returned_SaveNext,$returned_Persists)
                        =&Menu($menu_result,$convey,
                        $recurse_level,$FullMenu,
                        $Selected,$Conveyed,$SavePick,
                        $SaveMMap,$SaveNext,$Persists,
                        $MenuUnit_hash_ref,$no_wantarray);
                  }; # MENU RETURN MENURETURN 8
                  print "MENU RETURN 8\n" if $menu_return_debug;
                  die $@ if $@;
                  chomp($menu_output) if !(ref $menu_output);
                  my $test_for_menu_name=$MenuUnit_hash_ref->{Name};
                  if ($menu_output eq '-') {
                     $return_from_child_menu='-';
                     next;
                  } elsif ($menu_output eq '+') {
                     $return_from_child_menu='+';
                     next;
                  } elsif ($menu_output eq 'DONE_SUB') {
                     return 'DONE_SUB';
                  } elsif ($menu_output eq 'DONE' and 1<$recurse_level) {
                     return 'DONE';
                  } elsif (ref $menu_output eq 'ARRAY' &&
                        $menu_output->[0]=~
                        /^[{]$test_for_menu_name[}][<]$/) {
                     delete $Selected->{$MenuUnit_hash_ref};
                     delete $Conveyed->{$MenuUnit_hash_ref};
                     delete $SavePick->{$MenuUnit_hash_ref};
                     delete $SaveMMap->{$MenuUnit_hash_ref};
                     delete $SaveNext->{$MenuUnit_hash_ref};
                     delete $Persists->{$MenuUnit_hash_ref};
                     delete $FullMenu->{$MenuUnit_hash_ref}[2]
                            {'__FA_Banner__'};
                     %picks=();
                     $start=$FullMenu->{$MenuUnit_hash_ref}[11]-1 if
                        $start+$choose_num<$FullMenu->{$MenuUnit_hash_ref}[11];
                     $choose_num=$num_pick-$start if
                        $display_this_many_items>=$num_pick-$start;
                     next;
                  } elsif ($menu_output) {
                     return $menu_output;
                  } else {
                     $FullMenu=$returned_FullMenu;
                     $Selected=$returned_Selected;
                     $Conveyed=$returned_Conveyed;
                     $SavePick=$returned_SavePick;
                     $SaveMMap=$returned_SaveMMap;
                     $SaveNext=$returned_SaveNext;
                     $Persists=$returned_Persists;
                  }
               }
               my %pick=();
               $pick{$numbor}='*';
               %{$SavePick->{$MenuUnit_hash_ref}}=%pick;
               my $subfile=($Term::Menus::fullauto)
                          ?substr($Term::Menus::fa_code,0,-3).'::'
                          :'';
               foreach my $sub (&get_subs_from_menu($Selected)) {
                  my @resu=();
                  if (ref $sub eq 'CODE') {
                     if ($Term::Menus::fullauto && (!exists
                           $MenuUnit_hash_ref->{'NoPlan'} ||
                           !$MenuUnit_hash_ref->{'NoPlan'}) &&
                           defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN20\n";
                        if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                              'Plan'}} && !exists
                              $Net::FullAuto::FA_Core::makeplan->{
                              'Title'}) {
                           $Net::FullAuto::FA_Core::makeplan->{'Title'}
                              =$pn{$numbor}[0];
                        }
                        push @{$Net::FullAuto::FA_Core::makeplan->{
                               'Plan'}},
                             { Menu   => &pw($MenuUnit_hash_ref),
                               Number => $numbor,
                               PlanID =>
                                  $Net::FullAuto::FA_Core::makeplan->{Number},
                               Item   =>
                                  &Data::Dump::Streamer::Dump($sub)->Out() }
                     }
                     eval { @resu=$sub->() };
                     if ($@) {
                        if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$@;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $@;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($@);
                           } else { die $@ }
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $Term::Menus::local_hostname "
                                  ."Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@\n       line ".__LINE__;
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',$FullMenu,$Selected,$Conveyed,
                                     $SavePick,$SaveMMap,$SaveNext,
                                     $Persists,$parent_menu,$die;
                           }
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     }
                     if (-1<$#resu) {
                        if ($resu[0] eq '<') { %picks=();next }
                        if ($resu[0]=~/^[{](.*)[}][<]$/) {
                           if ($1 eq $MenuUnit_hash_ref->{Name}) {
                              %picks=();next;
                           } else {
                              return $resu[0];
                           }
                        }
                        if (0<$#resu && wantarray && !$no_wantarray) {
                           return @resu;
                        } else {
                           return return_result($resu[0],
                              $MenuUnit_hash_ref,$Conveyed);
                        }
                     }
                     $done=1;last
                  }
                  eval {
                     if ($subfile) {
                        $sub=~s/^[&]//; 
                        if ($Term::Menus::fullauto && (!exists
                              ${$MenuUnit_hash_ref}{'NoPlan'} ||
                              !${$MenuUnit_hash_ref}{'NoPlan'}) &&
                              defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN21\n";
                           if (-1==$#{$Net::FullAuto::FA_Core::makeplan{
                                 'Plan'}} && !exists
                                 $Net::FullAuto::FA_Core::makeplan->{
                                 'Title'}) {
                              $Net::FullAuto::FA_Core::makeplan->{'Title'}
                                 =$pn{$numbor}[0];
                           }
                           my $n='Number';
                           push @{$Net::FullAuto::FA_Core::makeplan->{
                                   'Plan'}},
                                { Menu   => &pw($MenuUnit_hash_ref),
                                  Number => $numbor,
                                  PlanID =>
                                    $Net::FullAuto::FA_Core::makeplan->{$n},
                                  Item   => "&$subfile$sub" }
                        }
                        $sub=&transform_sicm($sub,$numbor,
                           \@all_menu_items_array,\%picks,\%pn,
                           $return_from_child_menu,$log_handle,
                           $MenuUnit_hash_ref->{Name});
                        $sub=&transform_pmsi($sub,
                           $Conveyed,$SaveMMap,
                           $picks_from_parent);
                        eval "\@resu=\&$subfile$sub";
                        my $firsterr=$@||'';
                        if ((-1<index $firsterr,'Undefined subroutine') &&
                              (-1<index $firsterr,$sub)) {
                           if ($sub!~/::/) {
                              eval "\@resu=main::$sub";
                           } else {
                              eval "\@resu=$sub";
                           }
                           my $seconderr=$@||'';my $die='';
                           if ($seconderr=~/Undefined subroutine/) {
                              if (${$FullMenu}{$MenuUnit_hash_ref}
                                    [2]{$all_menu_items_array[$numbor-1]}) {
                                 $die="The \"Result15 =>\" Setting"
                                     ."\n\t\t-> " . ${$FullMenu}
                                     {$MenuUnit_hash_ref}[2]
                                     {$all_menu_items_array[$numbor-1]}
                                     ."\n\t\tFound in the Menu Unit -> "
                                     .$MenuUnit_hash_ref->{Name}."\n\t\t"
                                     ."Specifies a Subroutine"
                                     ." that Does NOT Exist"
                                     ."\n\t\tin the User Code File "
                                     .$Term::Menus::fa_code
                                     .",\n\t\tnor was a routine with "
                                     ."that name\n\t\tlocated in the"
                                     ." main:: script.\n";
                              } else { $die="$firsterr\n       $seconderr" }
                           } else { $die=$seconderr }
                           &Net::FullAuto::FA_Core::handle_error($die.
                                          "\n\n       line ".__LINE__);
                        } elsif ($firsterr) {
                           if ($Term::Menus::fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($firsterr.
                                             "\n\n       line ".__LINE__);
                           } else {
                              die "$firsterr\n\n       line ".__LINE__;
                           }
                        }
                     } else {
                        $sub=&transform_sicm($sub,$numbor,
                            \@all_menu_items_array,\%picks,\%pn,
                            $return_from_child_menu,$log_handle,
                            $MenuUnit_hash_ref->{Name});
                        $sub=&transform_pmsi($sub,
                            $Conveyed,$SaveMMap,
                            $picks_from_parent);
                        if ($sub!~/::/) {
                           $sub=~s/^[&]//;
                           eval "\@resu=main::$sub";
                        } else {
                           eval "\@resu=$sub";
                        }
                        if ($@) {
                           my $er=$@."\n       line ";
                           die $er.__LINE__;
                        }
                     }
                  };
                  if ($@) {
                     if (10<length $@ && unpack('a11',$@) eq 'FATAL ERROR') {
                        if ($parent_menu && wantarray && !$no_wantarray) {
                           return '',$FullMenu,$Selected,$Conveyed,
                                  $SavePick,$SaveMMap,$SaveNext,
                                  $Persists,$parent_menu,$@;
                        }
                        if (defined $log_handle &&
                              -1<index $log_handle,'*') {
                           print $log_handle $@;
                           close($log_handle);
                        }
                        if ($Term::Menus::fullauto) {
                           &Net::FullAuto::FA_Core::handle_error($@);
                        } else { die $@ }
                     } else {
                        my $die="\n       FATAL ERROR! - The Local "
                               ."System $Term::Menus::local_hostname "
                               ."Conveyed\n"
                               ."              the Following "
                               ."Unrecoverable Error Condition :\n\n"
                               ."       $@\n       line ".__LINE__;
                        if ($parent_menu && wantarray && !$no_wantarray) {
                           return '',$FullMenu,$Selected,$Conveyed,
                                  $SavePick,$SaveMMap,$SaveNext,
                                  $Persists,$parent_menu,$die;
                        }
                        if (defined $log_handle &&
                              -1<index $log_handle,'*') {
                           print $log_handle $die;
                           close($log_handle);
                        }
                        if ($Term::Menus::fullauto) {
                           &Net::FullAuto::FA_Core::handle_error($die);
                        } else { die $die }
                     }
                  }
                  if (-1<$#resu) {
                     if ($resu[0] eq '<') { %picks=();next }
                     if ($resu[0]=~/^[{](.*)[}][<]$/) {
                        if ($1 eq $MenuUnit_hash_ref->{Name}) {
                           %picks=();next;
                        } else {
                           return $resu[0];
                        }
                     }
                     if (0<$#resu && wantarray && !$no_wantarray) {
                        return @resu;
                     } else {
                        return return_result($resu[0],
                           $MenuUnit_hash_ref,$Conveyed);
                     }
                  }
                  $done=1;last
               }
               return 'DONE_SUB';
            } elsif ($return_from_child_menu &&
                  !exists $SavePick->{$MenuUnit_hash_ref}->{$pn{$numbor}}) {
               delete_Selected($MenuUnit_hash_ref);
               $done=1;last;
            } else { $done=1 }
            last if !$return_from_child_menu;
         }
      } last if $done;
   }
   if ($select_many ||
         (exists ${$MenuUnit_hash_ref}{Select}{(keys %picks)[0]||''})) {
      my @picks=();
      foreach (sort numerically keys %picks) {
         my $pik=$all_menu_items_array[$_-1];
         push @picks, $pik;
      } undef @all_menu_items_array;
      if ($MenuUnit_hash_ref) {
         push @picks,\%picks;
         push @picks,$MenuUnit_hash_ref;
         return \@picks,
                $FullMenu,$Selected,$Conveyed,
                $SavePick,$SaveMMap,$SaveNext,
                $Persists,$parent_menu;
      } else {
         return @picks;
      }
   }
   my $pick='';
   if ($filtered_menu) {
      $pick=${$FullMenu}{$MenuUnit_hash_ref}[10]->[$numbor-1];
   } elsif ($numbor=~/^\d+$/) {
      $pick=$all_menu_items_array[$numbor-1];
   }
   undef @all_menu_items_array;
   if ($Term::Menus::fullauto && (!exists ${$MenuUnit_hash_ref}{'NoPlan'} ||
         !${$MenuUnit_hash_ref}{'NoPlan'}) &&
         defined $Net::FullAuto::FA_Core::makeplan) {
#print "IN MAKEPLAN23\n";
      if (-1==$#{$Net::FullAuto::FA_Core::makeplan{'Plan'}} &&
            !exists $Net::FullAuto::FA_Core::makeplan->{'Title'}) {
         $Net::FullAuto::FA_Core::makeplan->{'Title'}=$pick;
      }
      unless ($got_default) {
         push @{$Net::FullAuto::FA_Core::makeplan->{'Plan'}},
              { Menu   => &pw($MenuUnit_hash_ref),
                Number => $numbor,
                PlanID =>
                   $Net::FullAuto::FA_Core::makeplan->{Number},
                Item   => $pick }
      }
   }
   if (wantarray) {
      return $pick,
          $FullMenu,$Selected,$Conveyed,
          $SavePick,$SaveMMap,$SaveNext,
          $Persists,$parent_menu;
   } else {
      return $pick;
   }

}

sub return_result {

   my $result_string=$_[0];
   my $MenuUnit_hash_ref=$_[1];
   my $Conveyed=$_[2];
   $Conveyed->{&pw($MenuUnit_hash_ref)}=$result_string;
   my $result_array=[];
   if ((-1<index $result_string,'][[') &&
         (-1<index $result_string,']][')) {
      $result_string=~s/^\s*\]\[\[\s*//s;
      $result_string=~s/\s*\]\]\[\s*$//s;
      my @elems=split /\s*\]\|\[\s*/,$result_string;
      foreach my $elem (@elems) {
         if (unpack('a5',$elem) eq 'eval ') {
            $elem=unpack('x5 a*',$elem);
            push @{$result_array}, eval $elem;
         } else {
            push @{$result_array}, $elem;
         }
      }
   } return [ $result_string ];

}

sub escape_quotes {

   my $sub=$_[0];
   return $sub if -1==index $sub,'"';
   my $routine=substr($sub,0,(index $sub,'(')+1);
   my $args=substr($sub,(index $sub,'(')+1,-1);
   $args=~s/[']/!%!'%!%/g;
   $args=~s/^\s*(["]|!%!)//;$args=~s/(["]|%!%)\s*$//;
   my @args=split /(?:["]|%!%)\s*,\s*(?:["]|!%!)/, $args;
   my @newargs=();
   foreach my $arg (@args) {
      $arg=~s/(!%!|%!%)//g;
      if ($arg=~/^[']/) {
         push @newargs, $arg;
      } else {
         $arg=~s/["]/\\"/g;
         push @newargs, '"'.$arg.'"';
      }
   }
   $sub=$routine;
   foreach my $arg (@newargs) {
      $sub.=$arg.",";
   }
   chop $sub;
   $sub.=')';
   return $sub;

}

1;

package TMMemHandle;

use strict;
sub TIEHANDLE {
   my $class = shift;
   bless [], $class;
}

sub PRINT {
   my $self = shift;
   push @$self, join '', @_;
}

sub PRINTF {
   my $self = shift;
   my $fmt = shift;
   push @$self, sprintf $fmt, @_;
}

sub READLINE {
   my $self = shift;
   shift @$self;
}

1;

__END__;

######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man Term/Menus.pm | groff -man -Tps > Term::Menus.ps

=head1 NAME

Term::Menus - Create Powerful Terminal, Console and CMD Enviroment Menus

=head1 SYNOPSIS

C<use Term::Menus;>

see METHODS section below

=head1 DESCRIPTION

Term::Menus allows you to create powerful Terminal, Console and CMD environment
menus. Any perl script used in a Terminal, Console or CMD environment can
now include a menu facility that includes sub-menus, forward and backward
navigation, single or multiple selection capabilities, dynamic item creation
and customized banners. All this power is simple to implement with a straight
forward and very intuitive configuration hash structure that mirrors the actual
menu architechture needed by the application. A separate configuration file is
optional. Term::Menus is cross platform compatible.

Term::Menus was initially conceived and designed to work seemlessly
with the perl based Network Process Automation Utility Module called
Net::FullAuto (Available in CPAN :-) - however, it is not itself dependant
on other Net::FullAuto components, and will work with *any* perl
script/application.


Reasons to use this module are:

=over 2

=item *

You have a list (or array) of items, and wish to present the user a simple
CMD enviroment menu to pick a single item and return that item as a scalar
(or simple string). Example:

   use Term::Menus;

   my @list=('First Item','Second Item','Third Item');
   my $banner="  Please Pick an Item:";
   my $selection=&pick(\@list,$banner);
   print "SELECTION = $selection\n";

The user sees ==>


   Please Pick an Item:

       1      First Item
       2      Second Item
       3      Third Item

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< 2 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = Second Item

=item *

You have a large list of items and need scrolling capability:

   use Term::Menus;

   my @list=`ls -1 /bin`;
   my $banner="   Please Pick an Item:";
   my $selection=&pick(\@list,$banner);
   print "SELECTION = $selection\n";

The user sees ==>

   Please Pick an Item:

       1      arch
       2      ash
       3      awk
       4      basename
       5      bash
       6      cat
       7      chgrp
       8      chmod
       9      chown
       10     cp

   a.  Select All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--<ENTER>--------------------------------------

   Please Pick an Item:

       11      cpio
       12      csh
       13      cut
       14      date
       15      dd
       16      df
       17      echo
       18      ed
       19      egrep
       20      env

   a.  Select All   f.  FINISH
                        ___
   93  Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 14 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = date

=item *

You need to select multiple items and return the selected list:

   use Term::Menus;

   my %Menu_1=(

      Item_1 => {

         Text    => "/bin Utility - ]Convey[",
         Convey  => [ `ls -1 /bin` ],

      },

      Select => 'Many',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS = @selections\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< 3 >-<ENTER>----------------------------------

--< 7 >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
    *  3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
    *  7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< f >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = /bin Utility - awk /bin Utility - chgrp


=item *

You need sub-menus:

   use Term::Menus;

   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]

      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my $selection=&Menu(\%Menu_1);
   print "\n   SELECTION=$selection\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All   c.  Clear All   f.   FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< 5 >-<ENTER>----------------------------------

   Choose an Answer :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = bash is a Good Utility

=item *

You have a large amount of text, or instructional information, and want
a I<banner only screen> that displays the banner only (no selections) and
that moves to the next screen/menu with just a press of the ENTER key.
Yet, you want to preserve selections from earlier menus, and/or return
to more menus after user completes reading the banner only screens.
You can also navigate backwards and forwards through these screens.

   use Term::Menus:

   my %Menu_1=(

      Name   => 'Menu_1',
      Banner => "\n   This is a BANNER ONLY display."

   );

   &Menu(\%Menu_1);

The user sees ==>

   This is a BANNER ONLY display.

   ([ESC] to Quit)   Press ENTER to continue ...

=item *

You want to use perl subroutines to create the text items and/or banner:

   use Term::Menus;

   sub create_items {

      my $previous=shift;
      my @textlines=();
      push @textlines, "$previous is a Good Utility";
      push @textlines, "$previous is a Bad Utility";
      return @textlines;
             ## return value must be an array
             ## NOT an array reference

   }

   sub create_banner {

      my $previous=shift;
      return "\n   Choose an Answer for $previous :"
             ## return value MUST be a string for banner

   }

   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Convey[",
         Convey => "create_items(]Previous[)",

      },

      Select => 'One',
      Banner => "create_banner(]Previous[)",

   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selection=&Menu(\%Menu_1);
   print "\n   SELECTION=@selection\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer for bash :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = bash is a Good Utility

=item *

You want to use anonymous subroutines to create the text items and/or banner
(see the more detailed treatment of anonymous subroutines and Term::Menus
macros in a later section of this documentation):

   use Term::Menus;

   my $create_items = sub {

      my $previous=shift;
      my @textlines=();
      push @textlines, "$previous is a Good Utility";
      push @textlines, "$previous is a Bad Utility";
      return \@textlines;
             ## return value must an array reference

   };

   my $create_banner = sub {

      my $previous=shift;
      return "\n   Choose an Answer for ]Previous[ :"
             ## return value MUST be a string for banner

   };

   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Convey[",
         Convey => $create_items->(']Previous['), # Subroutine executed
                                                  # at runtime by Perl
                                                  # and result is passed
                                                  # to Term::Menus.

                                                  # Do not use this argument
                                                  # construct with Result =>
                                                  # elements because only Menu
                                                  # blocks or subroutines can
                                                  # be passed. (Unless the
                                                  # return item is itself
                                                  # a Menu configuration
                                                  # block [HASH] or an
                                                  # anonymous subroutine
                                                  # [CODE])

      },

      Select => 'One',
      Banner => $create_banner, # Perl passes sub itself at runtime and
                                # execution is carried out by Term::Menus.

   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selection=&Menu(\%Menu_1);
   print "\n   SELECTION=@selection\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer for bash :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = bash is a Good Utility

=back

Usage questions should be directed to the Usenet newsgroup
comp.lang.perl.modules.

Contact me, Brian Kelly <Brian.Kelly@fullautosoftware.net>,
if you find any bugs or have suggestions for improvements.

=head2 What To Know Before Using

=over 2

=item *

There are two methods available with Term::Menus - &pick() and &Menu().
C<&Menu()> uses C<&pick()> - you can get the same results using
only
C<&Menu()>. However, if you need to simply pick one item from a single
list - use C<&pick()>. The syntax is simpler, and you'll write less code.
;-)

=item *

You'll need to be running at least Perl version 5.002 to use this
module.

=back

=head1 METHODS

=over 4

=item B<pick> - create a simple menu

    $pick = &pick ($list|\@list|['list',...],[$Banner]);

Where I<$list> is a variable containing an array or list reference.
This argument can also be a escaped array (sending a reference) or
an anonymous array (which also sends a reference).

I<$Banner> is an optional argument sending a customized Banner to
top the simple menu - giving instructions, descriptions, etc.
The default is "Please Pick an Item:"

=item B<Menu> - create a complex Menu

    $pick  = &Menu ($list|\@list|['list',...],[$Banner]);

Where I<$pick> is a variable containing an array or list reference
of the pick or picks.

    @picks = &Menu ($Menu_1|\%Menu_1|{ Name => 'Menu_1' });

Where I<$Menu_1> is a hash reference to the top level Menu
Configuration Hash Structure.

=back

=head2  Menu Configuration Hash Structures

=over 4

These are the building blocks of the overall Menu architecture. Each
hash structure represents a I<menu screen>. A single menu layer, has
only one hash structure defining it. A menu with a single sub-menu
will have two hash structures. The menus connect via the C<Result>
element of an I<Item> - C<Item_1> - hash structure in parent menu
C<%Menu_1>:


   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]
      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

=back

=head3  Menu Component Elements

Each Menu Configuration Hash Structure consists of elements that define
and control it's behavior, appearance, constitution and purpose. An
element's syntax is as you would expect it to be in perl - a key string
pointing to an assocaited value: C<key =E<gt> value>. The following
items
list supported key names and ther associated value types:

=over 4

=item

B<Display> => 'Integer'

=over 2


The I<Display> key is an I<optional> key that determines the number
of Menu
Items that will be displayed on each screen. This is useful when the items
are multi-lined, or the screen size is bigger or smaller than the default
number utilizes in the most practical fashion. The default number is 10.

   Display => 15,

=back

=item

B<Name> => 'Char String consisting of ASCII Characters'

=over 2


The I<Name> key provides a unique identifier to each Menu Structure.
This element is not "strictly" required for most Menu construts to
function properly. Term::Menus goes to great lengths to discover and
utilize the Menu's name provided on the left side of the equals
character of a Menu block using the following construct:

   my %MenuName=(

      [ Menu Contents Here ]

   );

In the above example, the Menu name is "MenuName". Most of the time 
Term::Menus will discover this name successfully, affording the user 
or Menu developer one less requirement to worry about. Allowing 
Term::Menus to discover this name will cut down on opportunities for
coding errors (and we all have enough of those already). HOWEVER,
there are "edge cases" and more complex Menu constructs that will 
prevent Term::Menus from accurately discovering this name. Therefore,
it is recommended and is considered a "best practice" to always 
explicitly "Name" Menu blocks as follows:

   my %MenuName=(

      Name => 'MenuName',

      [ Menu Contents Here ]

   );

Be careful to always use the SAME NAME for the Name element as for
the Menu block itself. This can be a source of error, especially
when one is using Macros that reference Menu Names explicitly (So
be CAREFUL!) One case where the Name element must ALWAYS be used
(if one wishes to reference that Menu with an explicit Named Macro)
is when creating anonymous Menu blocks to feed directly to Result
elements:

   my %ContainingMenu=(

      Name   => 'ContainingMenu',
      Item_1 => {

          Text => "Some Text",
          Result => {

             Name => "Anonymous_Menu", # MUST use "Name" element
                                       # if planning to use
                                       # explicit Macros

             [ Menu Contents Here ]

          },
      },

   );


=back

=item

B<Item_E<lt>intE<gt>> => { Item Configuration Hash
Structure }

=over 2


The I<Item_E<lt>intE<gt>> elements define customized menu items.
There are
essentially two methods for creating menu items: The I<Item_E<lt>intE<gt>>
elements, and the C<]Convey[> macro (described later). The difference being
that the C<]Convey[> macro turns an Item Configuration Hash into an Item
I<Template> -> a B<powerful> way to I<Item>-ize large lists
or quantities
of data that would otherwise be difficult - even impossible - to anticipate
and cope with manually.

   Item_1 => { Text => 'Item 1' },
   Item_2 => { Text => 'Item 2' },

Items created via C<]Convey[> macros have two drawbacks:

=over 2

=item *

They all have the same format.

=item *

They all share the same C<Result> element.

=back

The syntax and usage of I<Item_E<lt>intE<gt>> elements is important
and
extensive enough to warrant it's own section. See B<I<Item Configuration 
Hash Structures>> below.

=back

=item

B<Select> => 'One' --or-- 'Many'

=over 2


The MENU LEVEL I<Select> element determines whether this particular menu
layer allows the selection of multiple items - or a single item. The 
default is 'One'.

   Select => 'Many',

=back

=item

B<Banner> => 'Char String consisting of ASCII Characters' or  
anonymous subroutine or subroutine reference for generating 
dynamic banners.

=over 2


The I<Banner> element provides a customized descriptive header to the menu.
I<$Banner> is an optional element - giving instructions, descriptions, etc.
The default is "Please Pick an Item:"

   Banner => "The following items are for selection,\n".
             "\tEnjoy the Experience!",

--or--

   Banner => sub { <generate dynamic banner content here> },

--or--

   my $create_banner = sub { <generate dynamic banner content here> },

   Banner => $create_banner,

Creating a reference to a Banner subroutine enables the sharing of
Banner generation code between multiple Menus.


B<NOTE:>   Macros (like  C<]Previous[> )  I<can> be used in Banners!   :-)   ( See Item Configuration Macros below )

=back

=back

=head3 Item Configuration Hash Structures

Each Menu Item can have an independant configurtion. Each Menu Configuration
Hash Structure consists of elements that define and control it's behavior,
appearance, constitution and purpose. An element's syntax is as you would
expect it to be in perl - a key string pointing to an assocaited value: key
=> value. The following items list supported key names and ther associated
value types:

=over 4

=item

B<Text> => 'Char String consisting of ASCII Characters'

=over 2


The I<Text> element provides a customized descriptive string for the Item.
It is the text the user will see displayed, describing the selection.

   Text => 'This is Item_1',

=back

=item

B<Convey> => [ List ] --or-- @List --or-- $Scalar --or-- 'ASCII String' --or-- Anonymous Subroutine --or-- Subroutine Reference --or-- Ordinary Subroutine (*Ordinary* subroutine calls need to be surrounded by quotes. DO NOT use quotes with anonymous subroutine calls or ones called with a reference!)

=over 2


The I<Convey> element has a twofold purpose; it provides for the contents
of the C<]Convey[> macro, and defines or contains the string or result that
is passed on to child menus - if any. Use of this configuration element is
I<optional>. If C<Convey> is not a list, then it's value is passed onto child
menus. If C<Convey> I<is> a list, then the Item selected is passed onto the
children - if any. It is important to note, I<when used>, that only the
resulting I<Convey> string - B<I<NOT>> the the Item C<Text> value or string,
is conveyed to child menus. When the C<Convey> element is not used, the
full Item C<Text> value B<is> conveyed to the children - if any. However, the
full contents of the C<Text> element is I<returned> as the I<Result> of the
operation when the user completes all menu activity. See the I<Macro> section
below for more information.

   Convey => [ `ls -1` ],

B<NOTE:>     When using anonymous subroutines or subroutine references, there may be situations where code populating the Convey item encounters an error or gets data that is empty or unsatisfactory for some reason, and there is a need to print a message or write to a log or send an alert, and then return from this routine to an earlier menu. To force a return to a parent menu (assuming there is one) from a subroutine assigned to a Convey element, just return '<' from the subroutine. To return to any ancestor Menu in the stack, return this macro from the subroutine: C<{Menu_Name}<> :-)

=back

=item

B<Default> => 'Char String' --or-- Perl regular expression - qr/.../

=over 2


The I<Default> element provides a means to pre-select certain elements,
as if the items were selected by the user. This can be done with two
constructs - simple string or pre-compiled regular expression.
Note: The C<Default> element is available only when the C<Select> element
is set to C<'Many'> - C<Select => 'Many',>

   Default => 'base|chown',

   Default => qr/base|chown/i,

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
    *  4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
    *  9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

=back

=item

B<Select> => 'One' --or-- 'Many'

=over 2


The ITEM LEVEL I<Select> element provides a means to inform Term::Menus
that the specific items of a single ITEM BLOCK (as opposed to full menu)
are subject to multiple selecting - or just single selection. This is
useful in particular for Directory Tree navigation - where files can
be multi-selected (or tagged), yet when a directory is selectedi, it
forces an immediate navigation and new menu - showing the contents of
the just selected directory.

B<NOTE:> See the B<RECURSIVELY CALLED MENUS> section for more information.

   Select => 'More',

The user sees ==>

    d  1      bin
    d  2      blib
    d  3      dist
    d  4      inc
    d  5      lib
    d  6      Module
    d  7      t
       8      briangreat2.txt
    *  9      ChangeLog
       10     close.perl

   a.  Select All   f.  FINISH
                       ___
   49 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

=back

=item

B<Exclude> => 'Char String' --or-- Perl regular expression - qr/.../

=over 2


The I<Exclude> element provides a means to remove matching elements
from the Menu seen by the user. This element is useful only when the
C<]Convey[> macro is used to populate items. This can be done with two
constructs - simple string or pre-compiled regular expression.

   Exclude => 'base|chown',

   Exclude => qr/base|chown/i,

=back

=item

B<Include> => 'Char String' --or-- Perl regular expression - qr/.../

=over 2


The I<Include> element provides a means to create items filtered from a larger
list of potential items available via the C<]Convey[> macro. This element is
useful only when the C<]Convey[> macro is used to populate items. The
C<Exclude> element can be used in conjunction with C<Include> to further
refine the final list of items used to construct the menu. The C<Include>
element - when used - always takes presidence, and the C<Exclude> will be used
only on the C<Include> filtered results. This element can be used with
two value constructs - simple string or pre-compiled regular expression.

   Include => 'base|chown',

   Include => qr/base|chown/i,

=back

=item

B<Result> => \%Menu_2  --or --  "&any_method()",

=over 2

=item

I<Result> is an I<optional> element that also has two important uses:

=item 

For selecting the child menu next in the chain of operation and conveyance,

   Result => \%Menu_2,

--or--

=item

For building customized method arguements using C<&Menu()>'s built-in
macros.

=item

   Result => "&any_method($arg1,\"]Selected[\",\"]Previous[\")",

B<NOTE:> I<ALWAYS> be sure to surround the subroutine or method calling
syntax with DOUBLE QUOTES. (You can use single quotes if you don't want
interpolation). Quotes are necessary because you're telling C<&Menu()> -
I<not> Perl - what method you want invoked. C<&Menu()> won't invoke the method
until after all other processing - where Perl will try to invoke it the first
time it encounters the line during runtime - lo----ng before a user gets a
chance to see or do I<anything>. B<BUT> - be sure I<B<NOT>> to use quotes
when assigning a child menu reference to the C<Result> value.

Again, I<Result> is an I<optional> element. The default behavior when
C<Result> is omitted from the Item Configuration element, is for the selection
to be returned to the C<&Menu()>'s calling script/module/app. If the C<Select>
element was set to C<'One'>, then that item is returned regardless of whether
the Perl structure receiving the output is an array or scalar. If there were
multiple selections - i.e., C<Select> is set to C<'Many'> - then, depending
on what structure is set for receiving the output, will determine whether
C<&Menu()> returns a list (i.e. - array), or I<reference> to an array.

=back

=item

B<Input> => 1  --or --  0,

=over 2

=item

I<Input> is an I<optional> element that that is used with Term::Menus L<FORMS|/FORMS>:

=item

For indicating to Term::Menus that the configuration hash is for a FORMS page.

   Input => 1,

=back

=back

=head3 Item Configuration Macros

Each Menu Item can utilize a very powerful set of configuration I<Macros>.
These constructs principally act as purveyors of information - from one
menu to another, from one element to another. There are currently three
available Macros:

=over 4

=item

B<]Convey[>


=over 2


C<]Convey[> is used in conjunction with the I<Convey> element (described)
earlier. It's purpose to "convey" or transport or carry a list item associated
with the C<Convey> element - and replace the C<]Convey[> Macro in the C<Text>
element value with that list item. The I<Convey> mechanism utilizing the
C<Convey> Macro is essentially an I<Item multiplier>. The entire contents of
the list associated with the I<Convey> element will be turned into it's own
C<Item> when the menu is displayed. Both ordinary and anonymous subroutines can be use to dynamically generate I<Convey> lists. (With I<]Convey[>, macros can be used only as subroutine arguments or in the body of anonymous subroutines - see other examples.)

   use Term::Menus;

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

B<NOTE:>     C<]C[>  can be used as a shorthand for  C<]Convey[>.

=back

=item

B<]Previous[>


=over 2


C<]Previous[> can be used in child menus. The C<]Previous[> Macro contains
the I<Selection> of the parent menu. Unlike the C<]Convey[> Macro, the
C<]Previous[> Macro can be used in both the C<Text> element value, and the
C<Result> element values (when constructing method calls):

The C<]Previous[> Macro can also be used in the Banner.

   use Term::Menus;

   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]
      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH

   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = bash is a Good Utility

B<NOTE:>     C<]P[>  can be used as a shorthand for  C<]Previous[>.

=back

=item

B<]Previous[{> <I<Menu_Name>> B<}>  i.e. Explicit Named Macro


=over 2


C<]Previous[{Menu_Name}> (i.e. Explicit Named Macros) can be used in child menus. 
The C<]Previous[{Menu_Name}> Macro contains the I<Selection> of any preceding menu 
specified with the C<Menu_Name> string. The C<]Previous[{Menu_Name}> follows the 
same conventions as the C<]Previous[> Macro - but enables access to the selection 
of i<any> preceding menu. This is very useful for Menu trees more than two levels 
deep.

The C<]Previous[{Menu_Name}> Macro can also be used in the Banner.

   use Term::Menus;

   my %Menu_3=(

      Name   => 'Menu_3',
      Item_1 => {

         Text   => "]Convey[ said ]P[{Menu_1} is a ]Previous[ Utility!",
         Convey => [ 'Bob','Mary' ]
      },

      Select => 'One',
      Banner => "\n   Who commented on ]Previous[{Menu_1}? :"
   );

   my %Menu_2=(

      Name   => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]C[ Utility",
         Convey => [ 'Good','Bad' ],
         Result => \%Menu_3,
      },

      Select => 'One',
      Banner => "\n   Is ]P[ Good or Bad? :"
   );

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
       5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Is bash Good or Bad? :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

   Who commented on bash? :

       1      Bob said bash is a Good Utility!
       2      Mary said bash is a Good Utility!

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 2 >-<ENTER>----------------------------------


The user sees ==>

   SELECTIONS = Mary said bash is a Good Utility!

B<NOTE:>     C<]P[>  can be used as a shorthand for  C<]Previous[>.

C<]P[{Menu_Name}>  can be used as a shorthand for C<]Previous[{Menu_Name}>.

C<]C[> can be used as a shorthand for C<]Convey[>.


=back

=item

B<]Selected[>


=over 2

C<]Selected[> can only be used in a I<terminal> menu. B<(> I<A terminal menu is
the last menu in the chain, or the last menu the user sees. It is the menu that
defines the> C<Result> I<element with a method> C<Result =E<gt> &any_method()>,
I<or does not have a> C<Result> I<element included or defined.> B<)>
C<]Selected[> is used to pass the selection of the I<current> menu to the
C<Result> element method of the current menu:

   use Term::Menus;

   sub selected { print "\n   SELECTED ITEM = $_[0]\n" }

   my %Menu_1=(

      Name   => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => "&selected(]Selected[)", # ]Selected[ macro passed to
                                            # ordinary perl subroutine.
                                            # The '&' characater is optional
                                            # but the quotes are NOT. Ordinary
                                            # subroutine calls MUST be
                                            # surrounded by either double or
                                            # single quotes. (DO NOT use
                                            # quotes around anonymous
                                            # subroutine calls, however!) 

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my $selection=&Menu(\%Menu_1);
   print "\n   SELECTION=$selection\n";

B<NOTE:>     C<]S[>  can be used as a shorthand for  C<]Selected[>.

B<NOTE:>     It is possible to use the same Result subroutine in
             different B<Item_E<lt>intE<gt>> blocks, and even in
             other Menu blocks within the same script. Furthermore,
             when complex Menu structures are created using lots
             of anonymous subroutines with generous subroutine
             reuse, it can be difficult to prevent early substitution
             of this Macro by a parent Menu. To prevent this, use
             the Explicit Named Macro construct with this Macro as
             well - C<]Selected[{Menu_Name}> 

             Also, if the same Result subroutine is to be used by
             multiple nested menus, all the Menu_Names of those Menu
             blocks should be included in the Named section
             separated by the vertical bar symbol - C<]S[{Menu1_Name|Menu2_Name}>

B<NOTE:>     B<Stepchild and Grandchild Menus> - While on the topic
             of multiple nested menus, one of the more challenging
             aspects is preventing child menus from having their
             macros expanded or populated too "early" during runtime.
             Using the "Explict Name" convention (C<]Selected[{Menu_Name}>)
             helps, but there is another issue to be aware of. It is
             extremely useful (and powerful!) to use previous menu
             selections to dynamically build and return child menus
             for some results, but not for others. Code to reflect
             this goal would ordinarly look like this:

             $result_code = sub {

                my $selection=']S[{current_menu_name}';
                if ($selection eq 'Return to Main Menu')  {

                   return '{main}<';

                } else {

                   my %next_menu=(

                      Name => 'next_menu',
                      Item_1 => {

                         Text => ']C[',
                         Convey => [ ... ],

                      },
                      Item_2 => { ... },

                   );

                }

             };

             But this may not work correctly. The reason is that
             Term::Menus identifies menus in result blocks by
             explicitly looking for the 'Item_' (Item underscore)
             string in the block. If it finds one it will treat
             the result as a child menu to be I<immediately>
             created - not a routine to be evaluated first! So,
             in this scenario, the routine is acting as a kind
             of surrogate or "step" parent, since it is not a
             "real" parent menu. Hence, the "stepchild" menu. In
             this situation it may be necessary to "trick"
             Term::Menus into not recognizing the embedded menu
             (yet) that is part of a conditional structure that
             will be returned, only if the conditional is true.
             To do that, you can code this scenario like this:

             $result_code = sub {

                my $selection=']S[{current_menu_name}';
                if ($selection eq 'Return to Main Menu')  {

                   return '{main}<';

                } else {

                   my %next_menu=(  # This is a "stepchild" menu

                      Name => 'next_menu',

                   );
                   my $key = 'Item'.'_1';
                   $next_menu{$key}={

                       Text => ']C[',
                       Convey => [ ... ],

                   };
                   $key = 'Item'.'_2'; 
                   $next_menu{$key}={

                       Text => '. . .',

                   };
                   return \%next_menu;

                }

             };

             While that works, it is not very elegant (and not
             Best Practice!). It is better in these situations
             to substitute the Select (C<]Select[>) or Previous
             (C<]Previous[>) Macros with a TEST Macro (C<]Test[>
             or C<]T[> is shorthand):

             $result_code = sub {

                my $selection=']T[{current_menu_name}'; # <-- Note the ]T[
                if ($selection eq 'Return to Main Menu')  {

                   return '{main}<';

                } else {

                   my %next_menu=(  # "stepchild" menu

                      Name => 'next_menu',
                      Item_1 => {

                         Text => ']C[',
                         Convey => [ ... ],

                      },
                      Item_2 => { ... },

                   );

                }

             };

             The presence of the C<]Test[> macro tells
             Term::Menus that it's dealing with stepchild menus,
             and not to evaluate them early.

             However, there are scenario's where you want to
             evaluate on a condition that does not involve a
             child or even a step child menu - but a grandchild
             or great grandchild menu, etc. (This can certainly
             happen when there is menu re-use or recursion). In
             these situations Term::Menus will invariably
             determine there is an error condition (due to the
             explicitly named menu missing in the history stack)
             when there isn't - because there is no "obvious"
             way for Term::Menus to know that an explicitly named
             menu is not yet "supposed" to exist. In these
             scenarios the only option will be to suppress the
             error message and allow macro expansion to otherwise
             continue unabated. To do that, and allow processing
             to continue, use a "bang" (or exclamation point)
             character in the macro syntax after the starting
             bracket:

             C<my $selection=']!S[{menu_name}';>

             --OR--

             C<my $selection=']!T[{menu_name}';> 

             Hopefully, one or more of these approaches or
             "tricks" will deliver the results you're after.
             Whatever works!

B<NOTE:>     if you want to return output from the Result subroutine,
             you must include a 'return' statement. So the sub above:

                sub selected { print "\n   SELECTED ITEM = $_[0]\n" }

             Becomes:

                sub selected { print "\n   SELECTED ITEM = $_[0]\n";return $_[0] }

=back

=back

=head1 ANONYMOUS SUBROUTINES AND MACROS

Term::Menus macros can be used I<directly> in the body of B<anonymous> subroutines! Ordinary subroutines can be used as illustrated above of course, but the macro values can only be passed as arguments to ordinary subroutines. This is much more complicated and less intuitive than using macros directly in the code itself. Below is an example of their usage. The author received a request a while back from a user, asking if it was possible to return the item number rather than it's text value. The answer of course is YES! The code below illustrates this:

=over 4 

   use Term::Menus;

   my @list=('One','Two','Three');

   my %Menu_1=(

      Item_1 => {

         Text    => "NUMBER - ]Convey[",
         Convey  => \@list,
         Result  => sub {
                           my $cnt=-1;my $selection=']Selected[';
                           foreach my $item (@list) {
                              $cnt++;
                              chomp($item);
                              last if -1<index $selection, $item;
                           } return "$cnt";
                        }
                        # Note use of ]Selected[ macro in
                        # anonymous subroutine body

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my $selection=Menu(\%Menu_1);
   print "   \nSELECTION = $selection\n";

=back

Anonymous subroutines can be assigned directly to "Item_1" (or Item_2, etc.) elements 'Convey' and 'Result' as well as to the Menu "Banner" element. Use of the these constructs over more traditional subroutines is encouraged because it means writing less code, while enabling the code that is written to be less complex, more intuitive and readable, and certainly easier to maintain. The same anonymous routine can be use in multipe Menus or Items of a single Menu by assigning that routine to a variable, and then assigning the variable instead.

B<NOTE:>   To force a return to a parent menu (assuming there is one) from a subroutine assigned to a Result element, just return '<' from the subroutine. This is extremely useful when there is a desire to process a selection, and then return to the parent menu when processing is complete. To return to any ancestor Menu in the stack, return this macro from the subroutine: C<{Menu_Name}<> :-)

=over 4

   use Term::Menus;

   my @list=('One','Two','Three');

   my $result = sub {
                       my $cnt=-1;my $selection=']Selected[';
                       foreach my $item (@list) {
                          $cnt++;
                          chomp($item);
                          last if -1<index $selection, $item;
                       } return "$cnt";
                    };
                    # Anonymous subroutine assigned to "$result" variable

   my %Menu_1=(

      Item_1 => {

         Text    => "NUMBER - ]Convey[",
         Convey  => \@list,
         Result  => $result, # Anonymous subroutine assisned via
                             # "$result" variable

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my $selection=Menu(\%Menu_1);
   print "   \nSELECTION = $selection\n";

=back

=head1 RECURSIVELY CALLED MENUS

There are occasions where it is desirable to re-use the same Menu template/hash configuration with dynamically discovered data. One obvious example of this is navigating directory trees. Each subsequent directory selection could potentially contain deeper levels of directories. Essentially, any data structured in any kind of relational tree layout is subject to this kind of navigation approach. Be warned however, unlike most other functionality that is handled almost entirely by the Term::Menus module, the code for doing recursive templating is mostly contained in the template/hash configuration itself. There is a "helper routine" (&get_Menu_map) that Term::Menus provides to assist with the creation of recursively-friendly configurations, but given the highly data-centric characteristics of such functionality, most of the working code must be left to the authoring and management of the user.


=head2 &get_Menu_map()

This is a helper routine that returns a list of ancestor menu results. This is needed when wanting to navigate a directory tree for instance. Imagine a directory path that looks like this: /one/two/three. A call to &get_Menu_map() when processing directory three with return this list: ('one','two').

=over 4

The following code is an example of how to use recursion for navigating a directory tree.

   use Term::Menus;

   my %dir_menu=(

      Name   => 'dir_menu',
      Item_1 => {

         Text => "]C[",
         Mark => "d",
         Convey => sub {

            if ("]P[") {

               my $dir="]P[";
               if ($^O eq 'cygwin') {
                  $dir='/cygdrive/c/';
               } else {
                  $dir='/';
               }
               my @xfiles=();
               my @return=();
               my @map=get_Menu_map;
               my $path=join "/", @map;
               opendir(DIR,"$dir$path") || die $!;
               @xfiles = readdir(DIR);
               closedir(DIR);
               foreach my $entry (sort @xfiles) {
                  next if $entry eq '.';
                  next if $entry eq '..';
                  if (-1<$#map) {
                     next unless -d "$dir$path/$entry";
                  } else {
                     next unless -d "$dir/$entry";
                  }
                  push @return, "$entry";
               }
               return @return;

            }
            my @xfiles=();
            my @return=();
            if ($^O eq 'cygwin') {
               opendir(DIR,'/cygdrive/c/') || die $!;
            } else {
               opendir(DIR,'/') || die $!;
            }
            @xfiles = readdir(DIR);
            closedir(DIR);
            foreach my $entry (@xfiles) {
               next if $entry eq '.';
               next if $entry eq '..';
               next unless -d "$entry";
               push @return, "$entry";
            }
            return @return;

         },
         Result => { 'dir_menu'=>'recurse' },

      },
      Item_2 => {

         Text => "]C[",
         Select => 'Many',
         Convey => sub {

            if ("]P[") {

               my $dir="]P[";
               if ($^O eq 'cygwin') {
                  $dir='/cygdrive/c/';
               } else {
                  $dir='/';
               }

               my @xfiles=();
               my @return=();
               my @map=get_Menu_map;
               my $path=join "/", @map;
               opendir(DIR,"$dir/$path") || die $!;
               @xfiles = readdir(DIR);
               closedir(DIR);
               foreach my $entry (sort @xfiles) {
                  next if $entry eq '.';
                  next if $entry eq '..';
                  if (-1<$#map) {
                     next if -d "$dir/$path/$entry";
                  } else {
                     next if -d "$dir/$entry";
                  }
                  push @return, "$entry";
               }
               return @return;

            }
            my @xfiles=();
            my @return=();
            if ($^O eq 'cygwin') {
               opendir(DIR,'/cygdrive/c/') || die $!;
            } else {
               opendir(DIR,'/') || die $!;
            }
            @xfiles = readdir(DIR);
            closedir(DIR);
            foreach my $entry (@xfiles) {
               next if $entry eq '.';
               next if $entry eq '..';
               next if -d "$entry";
               push @return, "$entry";
            }
            return @return;

         },
      },
      Banner => "   Current Directory: ]P[\n",

   );

   my $selection=Menu(\%dir_menu);

   if (ref $selection eq 'ARRAY') {
      print "\nSELECTION=",(join " ",@{$selection}),"\n";
   } else {
      print "\nSELECTION=$selection\n";
   }

=back

=head1 FORMS

With Term::Menus, you can now create CMD and Terminal environment input forms.
Below is an example of a form that works with the program "figlet":


   '########:'##::::'##::::'###::::'##::::'##:'########::'##:::::::'########:
    ##.....::. ##::'##::::'## ##::: ###::'###: ##.... ##: ##::::::: ##.....::
    ##::::::::. ##'##::::'##:. ##:: ####'####: ##:::: ##: ##::::::: ##:::::::
    ######:::::. ###::::'##:::. ##: ## ### ##: ########:: ##::::::: ######:::
    ##...:::::: ## ##::: #########: ##. #: ##: ##.....::: ##::::::: ##...::::
    ##:::::::: ##:. ##:: ##.... ##: ##:.:: ##: ##:::::::: ##::::::: ##:::::::
    ########: ##:::. ##: ##:::: ##: ##:::: ##: ##:::::::: ########: ########:
   ........::..:::::..::..:::::..::..:::::..::..:::::::::........::........::

   ========================================
   [ EXAMPLE                              ]  banner3-D  font
   ========================================

   The box above is an input box. The [DEL] key will clear the contents.
   Type anything you like, and it will appear in the banner3-D FIGlet font!

   (Press [F1] for HELP)

   ([ESC] to Quit)   Press ENTER when finished


In this example, input typed in the input field, immediately appears in the
output field in the figlet font "banner3-D". Here is the code for this example:

      use Term::Menus;
      my $path='/usr/share/figlet';
      opendir(my $dh, $path) || die "can't opendir $path: $!";
      while (my $file=readdir($dh)) {
         chomp($file);
         next unless $file=~s/.flf$//;
         push @figletfonts,$file;
      }
      my $figlet='/usr/bin/';
      my $figban=`${figlet}figlet -f small "FIGlet   Fonts"`;
      $figban=~s/^/   /mg;
      $figban="\n\n$figban   ".
         "Choose a FIGlet Font (by number) to preview with text \"Example\"".
         "\n   -OR- continuously scroll and view by repeatedly pressing ENTER".
         "\n\n   HINT: Typing  !figlet -f<fontname> YOUR TEXT\n\n".
         "         is another way to preview the font of your choice.\n\n";

      $main::figletoutput=sub {

         return `figlet -f ]P[{figmenu} $_[0]`;

      };

      my $figlet_banner=<<END;

      ]O[{1,'figletoutput'}


                           ]P[{figmenu}  font
      ]I[{1,'Example',40}

      The box above is an input box. The [DEL] key will clear the contents.
      Type anything you like, and it will appear in the ]P[{figmenu} FIGlet font!

   END
   # ^ Be sure the END is at the margin (no spaces from edge)

      my %figletoutput=(

         Name   => 'figletoutput',
         Result => sub { return '{figmenu}<' },
         Input  => 1,
         Banner => $figlet_banner,

      );

      my %figmenu=(

         Name => 'figmenu',
         Item_1 => {

            Text    => ']C[',
            Convey  => \@figletfonts,
            Result  => \%figletoutput,

         },
         Display => 8,
         Scroll => 1,
         Banner => $figban,

      );
      my $selection=Menu(\%figmenu);


Any number of input fields can be added to a form page, and navigation among
 fields is accomplished using the TAB key (as you would use in most GUI applications).


   Term::Menus FORM - 3 input fields:

                      ========================================
   Name               [                                      ]
                      ========================================
                      ----------------------------------------
   Street Address     |                                      |
                      ----------------------------------------
                      --------------------------------- ------
   City, State        |                               | |    |
                      --------------------------------- ------
                      ---------------- -----------------------
   Zip Code, Phone    |              | |                     |
                      ---------------- -----------------------

   (Press [F1] for HELP)

   ([ESC] to Quit)   Press ENTER when finished


Note how the first field has a thicker border than the other two. This means this
field is "highlighted" and is the one chosen for entry. The following keys have
special behavior:

   [DEL]        ==>  Clears the selected input field entirely

   [BACKSPACE]  ==>  Deletes one character at time going backwards

   [TAB]        ==>  Navigates among input fields

   [ENTER]      ==>  Submits entire form 

=head2 Form Assembly

Form syntax is used in the C<Banner> that is fed to C<&Menu()> via the Menu
Configuration Hash Structure. This is the code for the input fields above:

   use Term::Menus;

   my $input_fields_banner.=<<END;

   my @default_input=('','','','','','');

   Term::Menus FORM - 6 input fields:


   Name
                      ]I[{1,$default_input[0],40}

   Street Address
                      ]I[{2,$default_input[1],40}

   City, State
                      ]I[{3,$default_input[2],33} ]I[{4,$default_input[3],6}

   Zip Code, Phone
                      ]I[{5,$default_input[4],16} ]I[{6,$default_input[5],23}

END
   my $input_example={

      Name => 'input_example',
      Input => 1,
      Banner => $input_fields_banner,
      Result => sub { return "]I[{'input_example',1}",
                             "]I[{'input_example',2}",
                             "]I[{'input_example',3}",
                             "]I[{'input_example',4}",
                             "]I[{'input_example',5}",
                             "]I[{'input_example',6}"  },

   };

   my @output=Menu($input_example);
   print "\n   OUTPUT=@output\n";

=head3 Input Macro -> Banner

The Input Macro syntax for Banner is as follows:

   ]I[{<identity_number>,'<default_input>',<length_of_input_box>}

*NOTE* => Be sure you have a RESULT C<]I[> macro for every BANNER C<]I[> macro you use!

=head3 Input Macro -> Result

The Input Macro syntax for Result is as follows:

   ]I[{'<menu_name>','<identity_number>'}

=head3 Output Macro -> Banner

The Output Macro syntax for Banner is as follows:

   ]O[{<identity_number>,'<name_of_method_to_operate_on_character_input>'}

=head1 USAGE and NAVIGATION

Usage of C<&pick()> and/or C<&Menu()> during the runtime of a script in which
one or both are included, is simple and intuitive. Nearly everything the end
user needs in terms of instruction is included on-screen. The
script-writer/developer/programmer can also include whatever instructions s/he
deems necessary and/or helpful in the customizable C<Banner> (as described
above). There is however, one important feature about using C<&Menu()> with
sub-menus that's important to know about.

=head2 Forward  ' B<E<gt>> ' and  Backward  ' B<E<lt>> ' Navigation

When working with more than one C<&Menu()> screen, it's valuable to know how
to navigate back and forth between the different C<&Menu()> levels/layers.  For
example, above was illustrated the output for two layers of menus - a parent
and a child:

=over 4

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

The user sees ==>

   Choose an Answer :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:


In the above example, suppose that the user "fat-fingered" his/her
choice, and really didn't want to "bash" bash, but wanted to bash
awk instead. Is restarting the whole script/application now necessary?
Suppose it was a process that had run overnight, and the user is seeing
this menu through fogged glasses from the steam rising out of their
morning coffee? Having to run the whole job again would not be welcome news
for the BOSS. THANKFULLY, navigation makes this situation avoidable.
All the user would have to do is type ' B<E<lt>> ' to go backward to the
previous menu, and ' B<E<gt>> ' to go forward to the next menu (assuming there
is one in each case):


The user sees ==>

   Choose an Answer :

       1      bash is a Good Utility
       2      bash is a Bad Utility

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

 --<  >  >-<ENTER>-----------------------------

The user sees ==>

   Choose a /bin Utility :

       1      /bin Utility - arch
       2      /bin Utility - ash
       3      /bin Utility - awk
       4      /bin Utility - basename
    -  5      /bin Utility - bash
       6      /bin Utility - cat
       7      /bin Utility - chgrp
       8      /bin Utility - chmod
       9      /bin Utility - chown
       10     /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

Note in the above example the Dash ' B<-> ' in front of item B<5.> This informs
the user that s/he had previously selected this item. To clear the selection,
the user would simply choose item B<5> again. This effectively deletes the
previous choice and restores the menu for a new selection. If the user was
satisfied with the choice, and was simply double checking thier selection, they
simply repeat the navigation process by typing ' B<E<gt>> ' - then <ENTER>
-
and returning to the child menu they left.

If the child menu was a I<multiple-selection> menu, and the user had made some
selections before navigating back to the parent menu, the user would see a
' B<+> ' rather than a ' B<-> '. This informs the user that selections were
made in the child menu.

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
   +  5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All   c.  Clear All   f.  FINISH
                       ___
   93 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

=back

=head2 View Sorted Items ' B<%> '

When working with numerous items in a single menu, it may be desirable to see
the set of choices organized in either descending or reverse acscii order.
Term::Menus provides this feature with the I<Percent> ' B<%> ' key.  Simply
type ' B<%> ' and the items will be sorted in descending ascii order. Type
' B<%> ' again, and you will see the items reverse sorted. Assume that we have
the following menus.

=over 4

The user sees ==>

   Choose a /bin Utility :

    *  1      [.exe
    *  2      2to3
       3      2to3-3.2
    *  4      411toppm.exe
       5      a2p.exe
       6      aaflip.exe
       7      aclocal
    *  8      aclocal-1.10
       9      aclocal-1.11
    *  10     aclocal-1.12

   a.  Select All   c.  Clear All   f.  FINISH
                         ___
   1925 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< % >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

   *  2.        2to3
      3.        2to3-3.2
   *  4.        411toppm.exe
      759.      FvwmCommand.exe
      1650.     Ted.exe
      1782.     WPrefs.exe
      1785.     X
      1889.     XWin.exe
      1808.     Xdmx.exe
      1815.     Xephyr.exe

   a.  Select All   c.  Clear All   f.  FINISH

   (Type '<' to return to previous Menu)
                          ___
   1925  Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

And if we choose to enter ' B<%> ' I<again>

--< % >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

       1925     znew
       1924     zmore
       1923     zless
       1922     zipsplit.exe
       1921     zipnote.exe
       1920     zipinfo.exe
       1919     zipgrep
       1918     zipcloak.exe
       1917     zip.exe
       1916     zgrep

   a.  Select All   c.  Clear All   f.  FINISH

   (Type '<' to return to previous Menu)
                         ___
   1925 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP 

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

This submenu of sorted selections works just like any other menu. The user can
deselect an item, clear all items, re-choose all items, etc. The choices made
here are preserved when the user navigates back to the original (parent)
menu. In other words, if Item 1. is deselected in the sorted menu, Item 1.
will also be deselected in the parent menu. Navigating back to the
parent is necessary - the menu will not generate results from a sort menu.
Use either the B<LEFTARROW> ' B<E<lt>> ' key or FINISH key ' B<F> or B<f> ' to
return to the parent menu, and then continue your menu activities there. 

=back

=head2 View Summary of Selected Items ' B<*> '

When working with numerous items in a single menu, it is desirable to see the
set of choices made before leaving the menu and committing to a non-returnable
forward (perhaps even critical) process. Term::Menus provides this feature
with the I<Star> ' B<*> ' key. Assume we have the following menu with 93 Total
Choices. Assume further that we have selected items 1,3,9 & 11. Note that we
cannot see Item 11 on the first screen since this menu is configured to show
only 10 Items at a time.

=over 4

The user sees ==>

   Choose a /bin Utility :

    *  1      [.exe
       2      2to3
    *  3      2to3-3.2
       4      411toppm.exe
       5      a2p.exe
       6      aaflip.exe
       7      aclocal
       8      aclocal-1.10
    *  9      aclocal-1.11
       10     aclocal-1.12

   a.  Select All   c.  Clear All   f.  FINISH
                         ___
   1925 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< * >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

    *  1      [.exe
    *  3      2to3-3.2
    *  9      aclocal-1.11
    *  11     aclocal-1.13

   a.  Select All   c.  Clear All   f.  FINISH

   (Type '<' to return to previous Menu)

   ([F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

This submenu of summary selections works just like any other menu. The user 
can deselect an item, clear all items, re-choose all items, etc. The choices
made here are preserved when the user navigates back to the original (parent)
menu. In other words, if Item 1. is deselected in the summary menu, Item 1.
will also be deselected in the parent menu. Navigating back to the
parent is necessary - the menu will not generate results from a summary menu.
Use either the B<LEFTARROW> ' B<E<lt>> ' key or FINISH key ' B<F> or B<f> ' to
return to the parent menu, and then continue your menu activities there.

=back

=head2 Shell Out to Command Environment ' B<!>I<command> '

Borrowed from the editor vi, users can run any command environment command
(typically a shell command) without leaving their Term::Menus session or even
context. At anytime, a user can type an exclamation point ' B<!> ' followed
by the command they wish to run, and that command will be run and the results
returned for viewing.

=over 4

The user sees ==>

   Choose a /bin Utility :

    *  1      [.exe
       2      2to3
    *  3      2to3-3.2
       4      411toppm.exe
       5      a2p.exe
       6      aaflip.exe
       7      aclocal
       8      aclocal-1.10
    *  9      aclocal-1.11
       10     aclocal-1.12

   a.  Select All   c.  Clear All   f.  FINISH
                         ___
   1925 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE: 

--< !hostname >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

    *  1      [.exe
       2      2to3
    *  3      2to3-3.2
       4      411toppm.exe
       5      a2p.exe
       6      aaflip.exe
       7      aclocal
       8      aclocal-1.10
    *  9      aclocal-1.11
       10     aclocal-1.12

   a.  Select All   c.  Clear All   f.  FINISH
                         ___
   1925 Total Choices   |_v_| Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

central_server

Press ENTER to continue

=back

=head1 AUTHOR

Brian M. Kelly <Brian.Kelly@fullautosoftware.net>

=head1 COPYRIGHT

Copyright (C) 2000-2016
by Brian M. Kelly.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License.
(http://www.gnu.org/licenses/agpl.html).
