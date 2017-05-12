package MySQL::Log::ParseFilter;

use 5.008004;
use strict;
use warnings;

require Exporter;

our $VERSION = '1.00';

our @ISA = qw(Exporter);

our %EXPORT_TAGS =
(
   'options' => [ qw(set_save_meta_values
                    set_save_all_values
                    set_IN_abstraction
                    set_VALUES_abstraction
                    set_atomic_statements
                    set_db_inheritance)
                ],
   'hacks'   => [ qw(get_meta_filter
                     get_statement_filter
                     passes_meta_filter
                     passes_statement_filter)
                ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'options'} }, @{ $EXPORT_TAGS{'hacks'} } );

our @EXPORT = qw(
   set_grep
   set_meta_filter
   set_statement_filter
   set_udl_format
   parse_binary_logs
   parse_general_logs
   parse_slow_logs
   parse_udl_logs
   calc_final_values
   apply_final_meta_filters
);


# Module options and their defaults
my $save_meta_values   = 1;
my $save_all_values    = 0;
my $abstract_in        = 0;
my $abstract_values    = 0;
my $atomic_statements  = 0;
my $db_inheritance     = 0;
my $grep               = '';

# Internal vars for hackers
my %uf                 = ();  # udl format
my %mf                 = ();  # meta filters
my %sf                 = ();  # statement-filter
my $statement_id       = 1;   # I don't know if this is helpful yet; don't use it
my $debug              = 0;
my $debug_filehandles  = ();  # Not tested; don't use it either


#
# Subs to get refs to internal vars exported as :hacks
#
sub get_meta_filter      { return \%mf; }
sub get_statement_filter { return \%sf; }

#
# Subs to set module options exported as :options
# 
sub set_save_meta_values    { $save_meta_values = shift;  }
sub set_save_all_values     { $save_all_values  = shift;  }
sub set_IN_abstraction      { $abstract_in = shift;       }
sub set_VALUES_abstraction  { $abstract_values  = shift;  }
sub set_atomic_statements   { $atomic_statements = shift; }
sub set_db_inheritance      { $db_inheritance = shift;    }

#
# All subs exported by default
#
sub set_grep { $grep = shift; }

sub set_meta_filter
{
   # Meta filter format: [condition],[condtion],etc.
   # [condition] = [meta][op][val]
   # [meta]      = a meta-property name (cid, t, db, etc.)
   # [op]        = > < or = (only = for string [val]s)
   # [val]       = number or string depending on [meta]

   my $filter_string = shift;

   my @filters;
   my $c;  # condition

   _d("set_meta_filter: filter_string '$filter_string'\n") if $debug;

   @filters = split ',', $filter_string;

   foreach $c (@filters)
   {
      if($c =~ /(\w+)([<=>])([\w\.\@]+)/)
      {
         push @{$mf{lc($1)}}, [$2, $3];
      }
      else
      {
         _d("set_meta_filter: bad mf: $c\n") if $debug;
      }
   }
}

sub set_statement_filter
{
   # SQL statement filter format: [+-][TYPE],[TYPE],etc.
   # [+-]   =  positive filter: only SQL statements which *are* TYPE 
   #           or negative filter: only: SQL statements which are *not* TYPE
   # [TYPE] =  any SQL statement type (SELECT, UPDATE, DO, etc.)
   # No space between [+-] and first [TYPE]; defeault is negative filter

   my $filter_string = shift;

   my $pos_neg;
   my $types;

   _d("set_statement_filter: filter_string '$filter_string'\n") if $debug;

   ($pos_neg, $types) = $filter_string =~ /^([+-]?)(.+)/;

   %sf = map { lc($_) => 0; } split ',', $types;

   $sf{pos_neg} = ($pos_neg && $pos_neg eq '+' ? 1 : 0);
}

sub set_udl_format
{
   _d("set_udl_format\n") if $debug;

   my $udl_format_file = shift;

   my $header;
   my @metas;
   my $meta_name;
   my $meta_type;
   my $x;
   my $line;

   if(! open UDLF, "< $udl_format_file")
   {
      _d("Cannot open user-defined log format file '$udl_format_file': $!\n") if $debug;
      return;
   }

   $uf{rs} = <UDLF>;  # First line of uf should be the record seperator
   chomp $uf{rs};
   _d("set_udl_format: record separator literal: '$uf{rs}'\n") if $debug;
   $uf{rs} =~ s/\\n/\n/g;  # change literal \n to actual newline
   $uf{rs} =~ s/\\t/\t/g;  # change literal \t to actual tab
   _d("set_udl_format: record separator escaped: '$uf{rs}'\n") if $debug;

   $header = 1;

   while($line = <UDLF>)
   {
      chomp $line;

      if($header)
      {
         _d("set_udl_format: header: $line\n") if $debug;
         push @{$uf{headers}}, $line;
      }
      else
      {
         _d("set_udl_format: metas: $line\n") if $debug;
         @metas = split ' ', $line;
         
         foreach $x (@metas)
         {
            ($meta_name, $meta_type) = ($x =~ /(\w+):(\w{1,2})/);
            
            if($meta_type eq 's' || $meta_type eq 'n')
            {
               # how to save meta in %q_h after log processing in parse_udl_logs()
               $uf{meta_saves}->{$meta_name} = 'i';  # i means "initial" value only (save once)
            }
            elsif($meta_type eq 'u')
            {
               $uf{meta_saves}->{$meta_name} = 'u';  # special case for user meta
            }
            elsif($meta_type eq 'na' || $meta_type eq 'nf')
            {
               $uf{meta_saves}->{$meta_name} = $meta_type;

               $meta_type = 'n';  # needs to be just n for passes_meta_filter() when set in
                                  # $uf{meta_types}->{$meta_name} = $meta_type below
            }
            else
            {
               _d("set_udl_format: bad meta type: $x\n") if $debug;
               next;
            }

            $uf{meta_types}->{$meta_name} = $meta_type;
            push @{$uf{meta_names}}, $meta_name;
         }
      }

      $header = !$header;  # flip-flop between header/format
   }

   close UDLF;
}

sub parse_binary_logs
{
   my %params = @_;  # hash of params

   my $logs;         # ref to array with log file names
   my $q_h;          # ref to queries hash
   my $q_a;          # ref to array in which to save all statments (optional)
   my $stmt;         # statements from log (1 or more)--filtered by check_stmt()
   my $valid_stmt;   # if stmt is valid (passes all filters)
   my $q;            # becomes abstracted form of $stmt
   my $x;            # becomes ref to $q_h{$q}
   my $use_db;       # db from USE db; statment
   my $line;         # buffer for processing lines from logs
   my $log;          # current log file name
   my $sid;          # meta-property: server_id
   my $cid;          # meta-property: thread_id (a.k.a. connection id)
   my $ext;          # meta-property: exec_time
   my $err;          # meta-property: error_code

   # Set local vars to params for brevity ($$q_h is nicer than $$params{queries})
   $logs = $params{logs};
   $q_h  = $params{queries};
   $q_a  = (exists $params{all_queries} ? $params{all_queries} : 0);

   _d("parse_binary_logs: q_a $q_a\n") if $debug;

   local $/ = "\n# at ";

   foreach $log (@{$logs})
   {
      if(! open LOG, "< $log")
      {
         _d("parse_binary_logs: cannot open binary log file '$log': $!\n") if $debug;
         next;
      }

      _d("parse_binary_logs: parsing '$log'\n");

      $use_db = '';

      while($stmt = <LOG>)
      {
         chomp $stmt;
         $stmt =~ s/^.*\n//;              # remove first line which will be the log pos after '# at'
         next if $stmt !~ /\s+Query\s+/;  # skip the plethora of non-query related info
   
         _d("parse_binary_logs: READ: $stmt\n") if $debug;

         $use_db = '' unless $db_inheritance;  # $use_db can still be overwritten later by an
                                               # explicit USE statement or a header val if bin
                                               # logs ever start logging the db in the header

         # SQL statements are preceded with a header line like:
         # #YYMMDD HH:MM:SS server id N end_log_pos N Query thread_id=N exec_time=N error_code=0
         # Everything after should be SQL statements.
   
         $stmt =~
         s/^.*?server id (\d+)\s+end_log_pos \d+\s+Query\s+thread_id=(\d+)\s+exec_time=([\d\.]+)\s+error_code=(\d+)\n//;
         ($sid, $cid, $ext, $err) = ($1, $2, $3, $4);
   
         next if (exists $mf{sid} && !passes_meta_filter('sid', $sid, 'n'));
         next if (exists $mf{cid} && !passes_meta_filter('cid', $cid, 'n'));
         next if (exists $mf{ext} && !passes_meta_filter('ext', $ext, 'n'));
         next if (exists $mf{err} && !passes_meta_filter('err', $err, 'n'));
   
         $stmt =~ s/^\/\*!(?!\*).*(?:\n|\z)//mg; # remove special SQL comments like /*!\C utf8 *//*!*/;
         $stmt =~ s/^#.*(?:\n|\z)//mg;           # remove regular log comments

         $valid_stmt = check_stmt(\$stmt, \$use_db);

         if($valid_stmt)
         {
            push @{$q_a}, "USE $use_db" if ($q_a && $use_db);
            push @{$q_a}, $stmt if $q_a;
   
            $q = abstract_stmt($stmt);

            if(!exists ${$q_h}{$q})  # if first occurrence of $q (abstracted $stmt)
            {
               ${$q_h}{$q} = { id => $statement_id++, sample => $stmt, db => $use_db };

               if($save_meta_values)
               {
                  ${$q_h}{$q}->{sid}     = $sid;
                  ${$q_h}{$q}->{cid}     = $cid;
                  ${$q_h}{$q}->{err}     = $err;
                  ${$q_h}{$q}->{ext_min} = $ext;
                  ${$q_h}{$q}->{ext_max} = $ext;
               }
            }

            $x = ${$q_h}{$q};
   
            $x->{c_sum} += 1;

            # this handles cases where the db for a query is discovered after
            # the query's first occurrence
            $x->{db} = $use_db if (!$x->{db} && $use_db);

            if($save_meta_values)
            {
               $x->{ext_sum} += $ext;
               $x->{ext_min}  = $ext if $ext < $x->{ext_min};
               $x->{ext_max}  = $ext if $ext > $x->{ext_max};

               push @{$x->{ext_all}}, $ext if $save_all_values;
            }

            _d("parse_binary_logs: c_sum $x->{c_sum}, db $x->{db}, SAVED stmt: $stmt\n") if $debug;

         } # if($valid_stmt)
         else
         {
            _d("parse_biary_logs: INVALID stmt (fails filter)\n") if $debug;
         }
      } # while($stmt = <LOG>)

      close LOG;

   } # foreach $log (@{$logs})
}

sub parse_general_logs
{
   my %params = @_;  # hash of params

   my $logs;         # ref to array with log file names
   my $q_h;          # ref to queries hash
   my $u_h;          # ref to users hash (optional)
   my $q_a;          # ref to array in which to save all statments (optional)
   my $stmt;         # statements from log (1 or more)
   my $have_stmt;    # 0 = reading command; 1 = reading SQL stmt
   my $valid_stmt;   # 0 = stmt ignored due to failing a filter; 1 = stmt saved
   my $q;            # becomes abstracted form of $stmt
   my $x;            # becomes ref to $q_h{$q}
   my $cmd;          # current MySQL command (Connect, Init DB, Query, Quit, etc.)
   my $cid;          # current MySQL connection ID
   my %use_db;       # tracks db for each cid (cid => db)
   my %users;        # tracks user for each cid (cid => user)
   my %hosts;        # tracks host for each cid ($cid => host)
   my $match;        # first part of stmt after cmd
   my $log;          # current log file name
   my $line;         # current line read from log

   # Set local vars to params for brevity ($$q_h is nicer than $$params{queries})
   $logs = $params{logs};
   $q_h  = $params{queries};
   $u_h  = (exists $params{users}       ? $params{users}       : 0);
   $q_a  = (exists $params{all_queries} ? $params{all_queries} : 0);

    _d("parse_general_logs: u_h $u_h q_a $q_a\n") if $debug;

   # Init some vars for safety (do I sill need to do this? other subs don't)
   $stmt       = '';
   $have_stmt  = 0;
   $valid_stmt = 0;
   $match      = '';
   $cmd        = '';
   $cid        = 0; 
   $use_db{0}  = '';
   $users{0}   = '';
   $hosts{0}   = '';

   foreach $log (@$logs)
   {
      if(! open LOG, "< $log")
      {
         _d("parse_general_logs: cannot open general log file '$log': $!\n") if $debug;
         next;
      }

      _d("parse_general_logs: parsing '$log'\n");

      while($line = <LOG>)
      {
         next if $line =~ /^\s*$/;  # skip blank lines
   
         if(!$have_stmt)
         {
            # Fast-forward to a recognizable command
            next unless $line =~ /^[\s\d:]+(?:Query|Execute|Connect|Init|Change)/;
   
            # The general log has two line formats like:
            #                       1 Prepare     [3]
            # 060904  9:39:11       1 Query       SET autocommit=0
            # Each if(m//) below matches one or the other line format.
   
            # without date and time
            if($line =~ /^\s+(\d+) (Query|Execute|Connect|Init|Change)/) {}
            # with date and time
            elsif($line =~ /^\d{6}\s+[\d:]+\s+(\d+) (Query|Execute|Connect|Init|Change)/) {}
            else 
            {
               # This shouldn't happen often. There are known cases, like 'Field List'.
               _d("parse_general_logs: FALSE-POSITIVE match: $line") if $debug;
               next;
            }
   
            $cid = $1;
            $cmd = $2;
   
            next if (exists $mf{cid} && !passes_meta_filter('cid', $cid, 'n'));
   
            # Init a key-val for the cid in the hashes if not already done so
            $users{$cid}  = '' if !exists $users{$cid};
            $hosts{$cid}  = '' if !exists $hosts{$cid};
            $use_db{$cid} = '' if !exists $use_db{$cid};
   
            _d("parse_general_logs: cid $cid, cmd $cmd\n") if $debug;
   
            if($cmd eq "Connect")
            {
               # The Connect command sometimes is and sometimes is not followed by 'on'.
               # When it is, sometimes 'on' is and somtimes 'on' is not followed by a database.
               # Hence, the need for multiple if(m//) again.
               if($line =~ /Connect\s+(.+) on (\w*)/) {}
               elsif($line =~ /Connect\s+(.+)/) {}
               else
               {
                  # This shouldn't happen often
                  _d("parse_general_logs: FALSE-POSITIVE connect match: $line") if $debug;
                  next;
               }
   
               if($1 ne "")
               {
                  if($1 =~ /^Access/)  # Ignore "Access denied for user ..."
                  {
                     _d("parse_general_logs: ignoring: $line") if $debug;
                     next;
                  }
   
                  my @x = split '@', $1;
   
                  $users{$cid} = $x[0];
                  $hosts{$cid} = $x[1];
               }
               
               if($2 && $2 ne "")
               {
                  $use_db{$cid} = $2;
   
                  if($q_a && exists $mf{db} && passes_meta_filter('db', $2, 's'))
                  {
                     push @{$q_a}, "USE $use_db{$cid};";
                  }
               }
   
               _d("parse_general_logs: connect $users{$cid}\@$hosts{$cid}, db $use_db{$cid}\n") if $debug;
   
               next;
            }
            elsif($cmd eq "Init")
            {
               $line =~ /Init DB\s+(\w+)/;
               $use_db{$cid} = $1;
   
               if($q_a && exists $mf{db} && passes_meta_filter('db', $1, 's'))
               {
                  push @{$q_a}, "USE $use_db{$cid};";
               }
   
               _d("parse_general_logs: cid $cid, Init DB $use_db{$cid}\n") if $debug;
   
               next;
            }
            elsif($cmd eq "Change")
            {
               $line =~ /Change user\s+(.+) on (\w*)/;
   
               my $old_cid_info = "$users{$cid}\@$hosts{$cid} db $use_db{$cid}";
   
               if($1 ne "")
               {
                  my @x = split '@', $1;
                  $users{$cid} = $x[0];
                  $hosts{$cid} = $x[1];
               }
   
               if($2 ne "")
               {
                  $use_db{$cid} = $2;
   
                  if($q_a && exists $mf{db} && passes_meta_filter('db', $2, 's'))
                  {
                     push @{$q_a}, "USE $use_db{$cid};";
                  }
               }
   
               _d("parse_general_logs: cid $cid, CHANGE old:$old_cid_info > new:$users{$cid}\@$hosts{$cid} db $use_db{$cid}\n") if $debug;
   
               next;
            }
            elsif($cmd eq "Query")
            {
               $line =~ /Query\s+(.+)/;
               $match = $1;
            }
            elsif($cmd eq "Execute")
            {
               $line =~ /Execute\s+\[\d+\]\s+(.+)/;
               $match = $1;
            }
            else
            {
               # This should never happen
               _d("parse_general_logs: FALSE-POSTIVE command match: $cmd\n") if $debug;
               next;
            }
   
            # At this point, Command was either Query or Execute (directly above).
            # Therefore, we are now dealing with a new SQL statement.
            _d("parse_general_logs: cid $cid, db $use_db{$cid}, START new stmt: $match\n") if $debug;
            $have_stmt = 1;

            # Apply meta and SQL statement filters
            $valid_stmt = 0;

            if($match !~ /^\s*\(?(\w+)\s+/)  # extract SQL statement type
            {
               _d("parse_general_logs: FAIL NON-SQL statement: $match\n") if $debug;
               next;
            }

            next if (%sf && !passes_statement_filter($1));

            next if (exists $mf{user} && !passes_meta_filter('user', $users{$cid},  's'));
            next if (exists $mf{host} && !passes_meta_filter('host', $hosts{$cid},  's'));
            next if (exists $mf{db}   && !passes_meta_filter('db',   $use_db{$cid}, 's'));
   
            # All meta and statement filters passed so begin saving the SQL statement
            $valid_stmt = 1;
            $stmt = $match . "\n";
   
            # At this point, we return to while($line = <LOG>) to begin reading the subsequent lines
            # of the new SQL statement. If it's not valid, then the lines will be ignored
            # until the next recognizable command.
   
         } # if(!$have_stmt)
         else # have_stmt
         {
            if($line =~ /^[\s\d:]+\d [A-Z]/)  # New command so the SQL statement we've been reading until now is done
            {
               _d("parse_general_logs: NEW command (end of previous stmt)\n") if $debug;
   
               $have_stmt = 0;
   
               if($valid_stmt)
               {
                  if($grep && ($stmt !~ /$grep/io))
                  {
                     $valid_stmt = 0;
                     _d("parse_general_logs: previous stmt FAILS grep") if $debug;
                  }
   
                  if($valid_stmt)
                  {
                     push @$q_a, $stmt if $q_a;
   
                     $q = abstract_stmt($stmt);

                     if(!exists ${$q_h}{$q})  # if first occurrence of $q (abstracted $stmt)
                     {
                        ${$q_h}{$q} = {id     => $statement_id++,
                                       sample => $stmt,
                                       db     => $use_db{$cid},
                                       cid    => $cid
                                      };
                     }

                     $x = ${$q_h}{$q};

                     $x->{c_sum} += 1;

                     if($save_meta_values)
                     {
                        $q = "$users{$cid}\@$hosts{$cid}";  # re-using $q
                        $x->{users}->{$q} += 1;  # users of this stmt

                        $$u_h{$q}->{c} += 1 if $u_h;  # all users
                     }
   
                     _d("parse_general_logs: cid $cid, c_cum $x->{c_sum}, db $x->{db}: SAVED previous stmt: $stmt") if $debug;

                  } # if($valid_stmt) after grep
               } # if($valid_stmt)
               else
               {
                  _d("parse_general_logs: previous stmt INVALID\n") if $debug;
               }

               redo;  # Re-read the new command to begin processing it

            } # if(/^[\s\d:]+\d [A-Z]/)  # New command
            else
            {
               $stmt .= $line unless !$valid_stmt;
            }
         } # have_stmt
      } # while($line = <LOG>)

      close LOG;

   } # foreach $log (@$logs)
}

sub parse_slow_logs
{
   my %params = @_;  # hash of params

   my $logs;         # ref to array with log file names
   my $q_h;          # ref to queries hash
   my $u_h;          # ref to users hash (optional)
   my $q_a;          # ref to array in which to save all statments (optional)
   my $msl;          # 0 = baisc slow log; 1 = microslow patched slow log
   my $stmt;         # statements from log (1 or more)--filtered by check_stmt()
   my $valid_stmt;   # if stmt is valid (passes all filters)
   my $q;            # becomes abstracted form of $stmt
   my $x;            # becomes ref to $q_h{$q}
   my $use_db;       # db from USE db; statment
   my $log;          # current log file name
   my $line;         # current line read from log
   # basic slow log meta-propteries
   my ($user, $host, $IP);
   my ($time, $lock, $rows_sent, $rows_examined);
   # basic with microslow patch (msl)
   my $cid;
   my ($qchit, $fullscan, $fulljoin, $tmptable, $disktmptable);
   my ($filesort, $diskfilesort, $merge);
   # basic with microslow patch (msl) with InnoDB vals
   my $have_innodb;
   my ($iorops, $iorbytes, $iorwait);
   my ($reclwait, $qwait);
   my $pages;

   # Set local vars to params for brevity ($$q_h is nicer than $$params{queries})
   $logs = $params{logs};
   $q_h  = $params{queries};
   $u_h  = (exists $params{users}       ? $params{users}       : 0);
   $q_a  = (exists $params{all_queries} ? $params{all_queries} : 0);
   $msl  = (exists $params{microslow}   ? $params{microslow}   : 0);

   _d("parse_slow_logs: u_h $u_h q_a $q_a msl $msl\n") if $debug;

   foreach $log (@$logs)
   {
      if(!open LOG, "< $log")
      {
         _d("parse_slow_logs: cannot open slow log file '$log': $!\n") if $debug;
         next;
      }

      _d("parse_slow_logs: parsing '$log'\n");

      $use_db = '';

      while($line = <LOG>)
      {
         last if !defined $line;
         next until $line =~ /^# User/;  # Fast-forward to a recognizable header

         $use_db = '' unless $db_inheritance;  # $use_db can still be overwritten later by
                                               # Schema in the header or an explicit USE statement

         ($user, $host, $IP) = $line =~
            /^# User\@Host: (.+?) \@ (.*?) \[(.*?)\]/ ? ($1,$2,$3) : ('','','');

         $user =~ s/(\w+)\[\w+\]/$1/;

         next if (exists $mf{user} && !passes_meta_filter('user', $user, 's'));
         next if (exists $mf{host} && !passes_meta_filter('host', $host, 's'));
         next if (exists $mf{ip}   && !passes_meta_filter('ip',   $IP,   's'));

         if($msl)
         {
            $line = <LOG>;
            ($cid) = $line =~ /^# Thread_id: (\d+)\s+Schema: (.*)/;
   
            next if (exists $mf{cid} && !passes_meta_filter('cid', $cid, 'n'));

            if($2)  # database given
            {
               next if (exists $mf{db} && !passes_meta_filter('db', $2, 's'));

               $use_db = $2;
            }
         }

         $line = <LOG>;
         ($time, $lock, $rows_sent, $rows_examined) = $line =~
            /^# Query_time: ([\d\.]+)\s+Lock_time: ([\d\.]+)\s+Rows_sent: (\d+)\s+Rows_examined: (\d+)/;
   
         next if (exists $mf{t}  && !passes_meta_filter('t',  $time,          'n'));
         next if (exists $mf{l}  && !passes_meta_filter('l',  $lock,          'n'));
         next if (exists $mf{rs} && !passes_meta_filter('rs', $rows_sent,     'n'));
         next if (exists $mf{re} && !passes_meta_filter('re', $rows_examined, 'n'));
   
         if($msl)
         {
            $line = <LOG>;
            ($qchit, $fullscan, $fulljoin, $tmptable, $disktmptable) = $line =~
               /^# QC_Hit: (\w+)\s+Full_scan: (\w+)\s+Full_join: (\w+)\s+Tmp_table: (\w+)\s+Tmp_table_on_disk: (\w+)/;
   
            $line = <LOG>;
            ($filesort, $diskfilesort, $merge) = $line =~
               /^# Filesort: (\w+)\s+Filesort_on_disk: (\w+)\s+Merge_passes: (\d+)/;
   
            next if (exists $mf{qchit}        && !passes_meta_filter('qchit',        $qchit,        's'));
            next if (exists $mf{fullscan}     && !passes_meta_filter('fullscan',     $fullscan,     's'));
            next if (exists $mf{fulljoin}     && !passes_meta_filter('fulljoin',     $fulljoin,     's'));
            next if (exists $mf{tmptable}     && !passes_meta_filter('tmptable',     $tmptable,     's'));
            next if (exists $mf{disktmptable} && !passes_meta_filter('disktmptable', $disktmptable, 's'));
            next if (exists $mf{filesort}     && !passes_meta_filter('filesort',     $filesort,     's'));
            next if (exists $mf{diskfilesort} && !passes_meta_filter('diskfilesort', $diskfilesort, 's'));
            next if (exists $mf{merge}        && !passes_meta_filter('merge',        $merge,        'n'));
   
            $line = <LOG>;
   
            if($line =~ /^#\s+InnoDB_IO_r_ops/) # InnoDB values
            {
               $have_innodb = 1;
   
               ($iorops, $iorbytes, $iorwait) = $line =~
                  /^#\s+InnoDB_IO_r_ops: (\d+)\s+InnoDB_IO_r_bytes: (\d+)\s+InnoDB_IO_r_wait: ([\d\.]+)/;
   
               $line = <LOG>;
               ($reclwait, $qwait) = $line =~
                  /^#\s+InnoDB_rec_lock_wait: ([\d\.]+)\s+InnoDB_queue_wait: ([\d\.]+)/;
   
               $line = <LOG>;
               ($pages) = $line =~
                  /^#\s+InnoDB_pages_distinct: (\d+)/;
   
               next if (exists $mf{iorops}   && !passes_meta_filter('iorops',   $iorops,   'n'));
               next if (exists $mf{iorbytes} && !passes_meta_filter('iorbytes', $iorbytes, 'n'));
               next if (exists $mf{iorwait}  && !passes_meta_filter('iorwait',  $iorwait,  'n'));
               next if (exists $mf{reclwait} && !passes_meta_filter('reclwait', $reclwait, 'n'));
               next if (exists $mf{qwait}    && !passes_meta_filter('qwait',    $qwait,    'n'));
               next if (exists $mf{pages}    && !passes_meta_filter('pages',    $pages,    'n'));
            }
            else
            {
               $have_innodb = 0;
            }
         } # if($msl)
   
         $stmt = '';
   
         while($line = <LOG>)
         {
            last if $line =~ /^#(?! administrator )/; # stop at next stmt but not administrator commands
            last if $line =~ /^\/(?![\*\/]+)/;        # stop at log header lines but not SQL comment lines
            next if $line =~ /^\s*$/;
   
            $stmt .= $line;
         }
   
         chomp $stmt;

         $valid_stmt = check_stmt(\$stmt, \$use_db);
   
         if($valid_stmt)
         {
            push @{$q_a}, "USE $use_db" if ($q_a && $use_db);
            push @{$q_a}, $stmt if $q_a;

            $q = abstract_stmt($stmt);

            if(!exists $$q_h{$q})  # if first occurrence of $q (abstracted $stmt)
            {
               $$q_h{$q} = { id => $statement_id++, sample => $stmt, db => $use_db };

               $x = $$q_h{$q};  # just for brevity

               if($save_meta_values)
               {
                  $x->{t_min}  = $time;
                  $x->{t_max}  = $time;
                  $x->{l_min}  = $lock;
                  $x->{l_max}  = $lock;
                  $x->{rs_min} = $rows_sent;
                  $x->{rs_max} = $rows_sent;
                  $x->{re_min} = $rows_examined;
                  $x->{re_max} = $rows_examined;

                  if($msl)
                  {
                     $x->{have_innodb} = $have_innodb;
                     $x->{cid}         = $cid;
                     $x->{merge_min}   = $merge;
                     $x->{merge_max}   = $merge;

                     $x->{diskfilesort_t} = 0;
                     $x->{disktmptable_t} = 0;
                     $x->{filesort_t}     = 0;
                     $x->{fulljoin_t}     = 0;
                     $x->{fullscan_t}     = 0;
                     $x->{tmptable_t}     = 0;
                     $x->{qchit_t}        = 0;

                     if($have_innodb)
                     {
                        $x->{iorops_min}   = $iorops;
                        $x->{iorops_max}   = $iorops;
                        $x->{iorbytes_min} = $iorbytes;
                        $x->{iorbytes_max} = $iorbytes;
                        $x->{iorwait_min}  = $iorwait;
                        $x->{iorwait_max}  = $iorwait;
                        $x->{reclwait_min} = $reclwait;
                        $x->{reclwait_max} = $reclwait;
                        $x->{qwait_min}    = $qwait;
                        $x->{qwait_max}    = $qwait;
                        $x->{pages_min}    = $pages;
                        $x->{pages_max}    = $pages;
                     }
                  } # if($msl
               } # if($save_meta_values)
            } # if(!exists $$q_h{$q})

            $x = $$q_h{$q};

            $x->{c_sum} += 1;

            # this handles cases where the db for a query is discovered after
            # the query's first occurrence
            $x->{db} = $use_db if (!$x->{db} && $use_db);

            if($save_meta_values)
            {
               $x->{t_sum}  += $time;
               $x->{l_sum}  += $lock;
               $x->{rs_sum} += $rows_sent;
               $x->{re_sum} += $rows_examined;

               $x->{t_min}  = $time if $time < $x->{t_min};
               $x->{t_max}  = $time if $time > $x->{t_max};
               $x->{l_min}  = $lock if $lock < $x->{l_min};
               $x->{l_max}  = $lock if $lock > $x->{l_max};
               $x->{rs_min} = $rows_sent if $rows_sent < $x->{rs_min};
               $x->{rs_max} = $rows_sent if $rows_sent > $x->{rs_max};
               $x->{re_min} = $rows_examined if $rows_examined < $x->{re_min};
               $x->{re_max} = $rows_examined if $rows_examined > $x->{re_max};

               push @{$x->{t_all}}, $time;
               push @{$x->{l_all}}, $lock;

               if($msl)
               {
                  $x->{qchit_t}        += 1 if $qchit        eq 'Yes';
                  $x->{fullscan_t}     += 1 if $fullscan     eq 'Yes';
                  $x->{fulljoin_t}     += 1 if $fulljoin     eq 'Yes';
                  $x->{tmptable_t}     += 1 if $tmptable     eq 'Yes';
                  $x->{disktmptable_t} += 1 if $disktmptable eq 'Yes';
                  $x->{filesort_t}     += 1 if $filesort     eq 'Yes';
                  $x->{diskfilesort_t} += 1 if $diskfilesort eq 'Yes';
                  $x->{merge_sum}      += $merge;

                  $x->{merge_min} = $merge if $merge < $x->{merge_min};
                  $x->{merge_max} = $merge if $merge > $x->{merge_max};

                  if($x->{have_innodb})
                  {
                     $x->{iorops_sum}   += $iorops;
                     $x->{iorbytes_sum} += $iorbytes;
                     $x->{iorwait_sum}  += $iorwait;
                     $x->{reclwait_sum} += $reclwait;
                     $x->{qwait_sum}    += $qwait;
                     $x->{pages_sum}    += $pages;

                     $x->{iorops_min}   = $iorops   if $iorops   < $x->{iorops_min};
                     $x->{iorops_max}   = $iorops   if $iorops   > $x->{iorops_max};
                     $x->{iorbytes_min} = $iorbytes if $iorbytes < $x->{iorbytes_min};
                     $x->{iorbytes_max} = $iorbytes if $iorbytes > $x->{iorbytes_max};
                     $x->{iorwait_min}  = $iorwait  if $iorwait  < $x->{iorwait_min};
                     $x->{iorwait_max}  = $iorwait  if $iorwait  > $x->{iorwait_max};
                     $x->{reclwait_min} = $reclwait if $reclwait < $x->{reclwait_min};
                     $x->{reclwait_max} = $reclwait if $reclwait > $x->{reclwait_max};
                     $x->{qwait_min}    = $qwait    if $qwait    < $x->{qwait_min};
                     $x->{qwait_max}    = $qwait    if $qwait    > $x->{qwait_max};
                     $x->{pages_min}    = $pages    if $pages    < $x->{pages_min};
                     $x->{pages_max}    = $pages    if $pages    > $x->{pages_max};

                     if($save_all_values)
                     {
                        push @{$x->{iorops_all}},   $iorops;
                        push @{$x->{iorbytes_all}}, $iorbytes;
                        push @{$x->{iorwait_all}},  $iorwait;
                        push @{$x->{reclwait_all}}, $reclwait;
                        push @{$x->{qwait_all}},    $qwait;
                        push @{$x->{pages_all}},    $pages;
                     }
                  } # if($x->{have_innodb})
               } # if($msl)

               $q = "$user\@$host $IP";  # re-using $q
               $x->{users}->{$q} += 1;   # users of this stmt

               $$u_h{$q}->{c} += 1 if $u_h;  # all users

            } # if($save_meta_values)

            _d("parse_slow_logs: c_sum $x->{c_sum}, db $x->{db}, SAVED stmt\n") if $debug;
   
         } # if($valid_stmt)
         else
         {
            _d("parse_slow_logs: INVALID stmt (fails filter or grep)\n") if $debug;
         }
   
         redo;
   
      } # while($line = <LOG>)

      close LOG;

   } # foreach $log (@$logs)
}

sub parse_udl_logs
{
   my %params = @_;  # hash of params

   my $logs;         # ref to array with log file names
   my $q_h;          # ref to queries hash
   my $u_h;          # ref to users hash (optional)
   my $q_a;          # ref to array in which to save all statments (optional)
   my $stmt;         # statements from log (1 or more)--filtered by check_stmt()
   my $valid_stmt;   # if stmt is valid (passes all filters)
   my $q;            # becomes abstracted form of $stmt
   my $x;            # becomes ref to $q_h{$q}
   my $use_db;       # db from USE db; statment
   my @meta_vals;    # meta vals read from log
   my $headers;      # reference to @{$uf{headers}}
   my $meta_names;   # reference to @{$uf{meta_names}}
   my $meta_types;   # reference to %{$uf{meta_types}}
   my $meta_saves;   # reference to %{$uf{meta_saves}}
   my $t;            # used in for() loops to travers @meta_vals and $meta_names in sync
   my $z;            # becomes shorthand for $$meta_saves{$$meta_names[$t]}
   my $log;          # current log file name
   my $line;         # current line read from log

   # Set local vars to params for brevity ($$q_h is nicer than $$params{queries})
   $logs = $params{logs};
   $q_h  = $params{queries};
   $u_h  = (exists $params{users}       ? $params{users}       : 0);
   $q_a  = (exists $params{all_queries} ? $params{all_queries} : 0);

   _d("parse_udl_logs: u_h $u_h q_a $q_a\n") if $debug;

   # Set input record separator
   local $/ = (exists $uf{rs} ? $uf{rs} : ";\n");

   $headers = (exists $uf{headers} ? \@{$uf{headers}} : 0);

   if($headers)
   {
      $meta_names = \@{$uf{meta_names}};
      $meta_types = \%{$uf{meta_types}};
      $meta_saves = \%{$uf{meta_saves}};
   }

   foreach $log (@$logs)
   {
      if(! open LOG, "< $log")
      {
         _d("parse_slow_logs: cannot open slow log file '$log': $!\n") if $debug;
         next;
      }

      _d("parse_udl_logs: parsing '$log'\n");

      $use_db = '';

      while($stmt = <LOG>)
      {
         chomp $stmt;
         $stmt =~ s/^[\s\n]+//;  # remove leading spaces and newlines
         next if !$stmt;

         _d("parse_udl_logs: READ stmt: '$stmt'\n") if $debug;

         $use_db = '' unless $db_inheritance;  # $use_db can still be overwritten later by
                                               # a header val or an explicit USE  statement

         $valid_stmt = 1;

         if($headers)
         {
            @meta_vals = ();

            foreach $x (@$headers)
            {
               $stmt =~ s/(.+)\n//;  # grab and remove header line
               $line = $1;           # save line

               _d("parse_udl_logs: matching '$line' =~ /$x/\n") if $debug;

               push @meta_vals, ($line =~ /$x/);  # match line to header; save meta vals
            }

            _d("parse_udl_logs: meta values matched: @meta_vals\n") if $debug;

            if(%mf)  # apply meta filters
            {
               for($t = 0; $t < scalar @meta_vals; $t++)
               {
                  if(exists $mf{$$meta_names[$t]} &&
                     !passes_meta_filter($$meta_names[$t], $meta_vals[$t], $$meta_types{$$meta_names[$t]}))
                  {
                     $valid_stmt = 0;
                     last;
                  }
               }
            } # if(%mf)

            next if !$valid_stmt;  # read next stmt if this one is not valid

         } # if($headers)

         $valid_stmt = check_stmt(\$stmt, \$use_db);

         if($valid_stmt)
         {
            push @{$q_a}, "USE $use_db" if ($q_a && $use_db);
            push @{$q_a}, $stmt if $q_a;

            $q = abstract_stmt($stmt);

            if(!exists $$q_h{$q})  # if first occurrence of $q (abstracted $stmt)
            {
               $$q_h{$q} = { id => $statement_id++, sample => $stmt, db => $use_db };

               $x = $$q_h{$q};  # just for brevity

               if($save_meta_values)
               {
                  for($t = 0; $t < scalar @meta_vals; $t++)
                  {
                     $z = $$meta_saves{$$meta_names[$t]};  # i, na, nf
   
                     if($z eq 'i')  # save initial meta value once
                     {
                        $x->{$$meta_names[$t]} = $meta_vals[$t];
                     }
                     elsif($z eq 'na' || $z eq 'nf')  # save meta value plus aggregates
                     {
                        $x->{"$$meta_names[$t]\_min"} = $meta_vals[$t];
                        $x->{"$$meta_names[$t]\_max"} = $meta_vals[$t];
                     }
                  }
               } # if($save_meta_values)
            } # if(!exists $q_h{$q})

            $x = $$q_h{$q};

            $x->{c_sum} += 1;

            # this handles cases where the db for a query is discovered after
            # the query's first occurrence
            $x->{db} = $use_db if (!$x->{db} && $use_db);

            if($save_meta_values)
            {
               # loop through metas again, adding up sums, calcing min/max, and saving all vals where needed
               for($t = 0; $t < scalar @meta_vals; $t++)
               {
                  $z = $$meta_saves{$$meta_names[$t]};  # i, na, nf
   
                  if($z eq 'na' || $z eq 'nf')  # save meta value plus aggregates
                  {
                     $x->{"$$meta_names[$t]\_sum"} += $meta_vals[$t];
   
                     $x->{"$$meta_names[$t]\_min"} = $meta_vals[$t]
                        if $meta_vals[$t] < $x->{"$$meta_names[$t]\_min"};
                     $x->{"$$meta_names[$t]\_max"} = $meta_vals[$t]
                        if $meta_vals[$t] > $x->{"$$meta_names[$t]\_max"};
   
                     if($z eq 'nf')  # numeric plus full aggregate (all values)
                     {
                        push @{$x->{"$$meta_names[$t]\_a"}}, $meta_vals[$t];
                     }
                  }
                  elsif($z eq 'u')  # special case for user
                  {
                     $x->{users}->{$meta_vals[$t]} += 1;  # users of this stmt

                     $$u_h{$meta_vals[$t]}->{c} += 1 if $u_h;  # all users
                  }
               }
            } # if($save_meta_values)

            _d("parse_udl_logs: c_sum $x->{c_sum}, db $x->{db}, SAVED stmt: $stmt\n") if $debug;

         } # if($valid_stmt)
         else
         {
            _d("parse_udl_logs: INVALID stmt (fails filter)\n") if $debug;
         }
      } # while($stmt = <LOG>)

      close LOG;

   } # foreach $log (@$logs)
}

# Check $stmt against SQL statement filter and grep. $stmt can contain
# one or more SQL statments. If more than one (multi-stmts), each statment
# is checked individually. Returns 1 if one or more statement was valid after
# filtering, or 0 if all the statements were invalid; OR if $atomic_statments = 1:
# returns 1 only if all statments are valid, otherwise 0.
sub check_stmt
{
   _d("check_stmt\n") if $debug;

   my $stmt   = shift;  # ref to scalar having statement to check
   my $use_db = shift;  # ref to scalar in which to save db

   my @lines;  # lines of stmt
   my $line;   # current line

   @lines = split(/;\n/, $$stmt);  # split statements

   foreach $line (@lines)  # check each statment
   {
      $line .= ";\n" if $line !~ /;\s*$/;  # put ;\n back that split removed

      _d("check_stmt: checking: $line" . ($line =~ /\n$/ ? '' : "\n")) if $debug;

      if($line !~ /^\s*\(?(\w+)\s+/)  # extract SQL statement type
      {
         _d("check_stmt: FAIL NON-SQL statement line: $line\n") if $debug;
         $line = '';
         next;
      }
      else
      {
         if(lc($1) eq "use")
         {
            $line =~ /use (\w+)/i;  # grab db

            # check db
            return 0 if (exists $mf{db} && !passes_meta_filter('db', $1, 's'));

            $$use_db = $1;  # save db
            $line = '';     # remove USE statment
         }
         else
         {
            # check SQL statement filter
            if(%sf && !passes_statement_filter($1))
            {
               _d("check_stmt: part of compound stmt FAILS stmt filter ($1)\n") if $debug;

               return 0 if $atomic_statements;

               $line = '';
               next;
            }

            # check grep
            if($grep && ($line !~ /$grep/io))
            {
               _d("check_stmt: part of compound stmt FAILS grep\n") if $debug;

               return 0 if $atomic_statements;

               $line = '';
               next;
            }
         }
      }
   }  # foreach $line (@lines)

   $$stmt = join '', @lines;  # rejoin statmennts

   if($$stmt ne '')
   {
      $$stmt =~ s/\n$//;  # remove very last newline
      return 1;           # stmt valid
   }

   return 0;  # stmt invalid
}

sub abstract_stmt
{
   my $q = lc shift;  # scalar having statement to abstract

   my $t;  # position in q while compacting IN and VALUES

   # --- Regex copied from mysqldumpslow
   $q =~ s/\b\d+\b/N/g;
   $q =~ s/\b0x[0-9A-Fa-f]+\b/N/g;
   $q =~ s/''/'S'/g;
   $q =~ s/""/"S"/g;
   $q =~ s/(\\')//g;
   $q =~ s/(\\")//g;
   $q =~ s/'[^']+'/'S'/g;
   $q =~ s/"[^"]+"/"S"/g;
   # ---

   $q =~ s/^\s+//g;      # remove leading blank space
   $q =~ s/\s{2,}/ /g;   # compact 2 or more blank spaces to 1
   $q =~ s/\n/ /g;       # remove newlines
   $q =~ s/`//g;         # remove graves/backticks

   # compact IN clauses: (N, N, N) --> (N3)
   while ($q =~ m/( in\s?)/g)
   {
      $t = pos($q);
      $q =~ s/\G\((?=(?:N|'S'))(.+?)\)/compact_IN($1)/e;
      pos($q) = $t;
   }

   # compact VALUES clauses: (NULL, 'S'), (NULL, 'S') --> (NULL, 'S')2
   while ($q =~ m/( values\s?)/g)
   {
      $t = pos($q);
      $q =~ s/\G(.+?)(\s?)(;|on|\z)/compact_VALUES($1)."$2$3"/e;
      pos($q) = $t;
   }

   return $q;  # abstracted form of stmt
}

sub compact_IN
{
   my $in = shift;

   my $t;  # type of vals: N or 'S'
   my $n;  # number of N or 'S' vals

   $t = ($in =~ /N/ ? 'N' : 'S');  # determine type of vals
   $n = ($in =~ tr/,//) + 1;       # count number of vals

   if($abstract_in)
   {
      use integer;
      my $z = $abstract_in;  # just for brevity
      $n = (($n / $z) * $z) . '-' . (((($n / $z) + 1) * $z) - 1);
   }

   return "($t$n)";
}

sub compact_VALUES
{
   my $vals = shift;

   my $n;  # number of (vals)
   my $v;

   $n = 1;
   $n++ while ($vals =~ /\)\s?\,\s?\(/g);  # count number of (vals)

   # take first (vals) if there are > 1
   if($n > 1) { ($v) = ($vals =~ /^(\(.+?\))\s?\,\s?\(/); }
   else       { $v = $vals; }

   return "$v" if $abstract_values;

   return "$v$n";
}

sub passes_statement_filter
{
   my $s = lc shift;
   _d("passes_statement_filter: FAIL $s\n") if ($debug && ($sf{pos_neg} ^ exists $sf{$s}));
   return !($sf{pos_neg} ^ (exists $sf{$s}));
}

sub passes_meta_filter
{
   my $meta = shift;
   my $val  = shift;
   my $type = shift;

   my $c;  # condition

   # _d("passes_meta_filter: meta $meta val $val type $type\n") if $debug;

   if(exists $mf{$meta})
   {
      foreach $c (@{$mf{$meta}})
      {
         if($type eq 'n') # numeric
         {
            goto FAIL if ($c->[0] eq '<' && !($val <  $c->[1]));
            goto FAIL if ($c->[0] eq '>' && !($val >  $c->[1]));
            goto FAIL if ($c->[0] eq '=' && !($val == $c->[1]));
         }
         elsif($type eq 's') # string
         {
            goto FAIL if (lc($val) ne lc($c->[1]));
         }
      }

      PASS:
      return 1;
   }

   FAIL:
   # _d("passes_meta_filter: FAIL $meta $val\n") if $debug;
   return 0;
}

sub calc_final_values
{
   my $g_t    = pop;  # ref to scalar in which to save grand totals
   my %params = @_;   # hash of params


   my $q_h;  # ref to queries hash
   my $u_h;  # ref to users hash (optional)
   my $q;
   my $x;
   my $y;
   my $z;
   my $total_queries;

   $q_h  = $params{queries};
   $u_h  = (exists $params{users} ? $params{users} : 0);

   $g_t ||= 0;

   _d("calc_final_values: u_h $u_h g_t $g_t\n") if $debug;

   $total_queries = 0;
   foreach $q (keys %$q_h) { $total_queries += $$q_h{$q}->{c_sum}; }
   _d("calc_final_values: total queries: $total_queries\n") if $debug;

   foreach $q (keys %$q_h)
   {
      $x = $$q_h{$q};

      $x->{c_sum_p} = _p($x->{c_sum}, $total_queries);

      # Calculate averages: scan through every query's keys (its meta-property names)
      # looking for any one ending with _max. If one is found, then we know this
      # meta-property is being aggregate and needs an _avg value. For example:
      # if this were a slow log, we'd find "l_max" and then know we need an "l_avg".
      # We could look for _min too, but not _sum because that would match c_sum
      # and result in a useless c_sum_avg (c_sum / c_sum). Furthermore, during this
      # process, we add log-wide grand totals for aggregateble meta-properties
      # ($$g_t{"gt_$1"} += $x->{"$1\_sum"} if $g_t;) and for any _t type meta-
      # props (if($z =~ /(\w+_t)$/)) we calc their percent TRUE--these are purely
      # bivalent values like the msl meta-props diskfilesort_t, tmptable_t, etc.
      foreach $z (keys %$x)
      {
         if($z =~ /([a-z]+)_(?:max)$/)  # aggrevate values
         {
            $x->{"$1\_avg"} = $x->{"$1\_sum"} / $x->{c_sum};
            $$g_t{"gt_$1"} += $x->{"$1\_sum"} if $g_t;
            next;
         }

         if($z =~ /(\w+_t)$/)  # bivalent _t values
         {
            $x->{"$1\_p"} = _p($x->{$1}, $x->{c_sum});
            next;
         }
      }
   }

   # Now that we've added all available grand totals, we loop through %$g_t
   # and calc for every query in %$q_h things like t_sum_p: percentage that
   # t_sum constitutes of grand total t for all SQL statements in log.
   if($g_t)
   {
      foreach $z (keys %$g_t)
      {
         $z =~ /^gt_(\w+)/;
         $y = $1;

         foreach $q (keys %$q_h)
         {
            $x = $$q_h{$q};
            next if !exists $x->{"$y\_sum"};
            $x->{"$y\_sum_p"} = _p($x->{"$y\_sum"}, $$g_t{$z});
         }
      }
   }

   # And finally, calc the percentage that each unique user constitutes of all users
   if($u_h)
   {
      foreach $z (keys %$u_h)
      {
         $$u_h{$z}->{p} = _p($$u_h{$z}->{c}, $total_queries);
      }
      
      $$u_h{total} = scalar keys %$u_h;  # total number of unique users
   }

   return $total_queries;
}

sub apply_final_meta_filters
{
   my $total_queries = pop;  # ref to scalar having total number of queries
                             # to be adjusted for removed queries
   my %params        = @_;   # hash of params

   my $q_h;  # ref to queries hash
   my $q;
   my $x;
   my $meta;
   my $val;
   my $c;
   my $removed;

   $q_h = $params{queries};

   $total_queries ||= 0;
   $removed         = 0;

   _d("apply_final_meta_filters: total queries before: $$total_queries\n") if $debug;

   foreach $meta (keys %mf)  # e.g. t_max
   {
      next unless $meta =~ /_(?:min|max|avg|sum|p)$/;
                     
      foreach $q (keys %$q_h)
      {
         $x = $$q_h{$q};

         if(!exists $x->{$meta})  # next meta if stmts don't have this meta
         {
            _d("apply_final_meta_filters: stmt does not have $meta: $q\n") if $debug;
            next;
         }

         $val = $x->{$meta};  # stmt's val for meta

         foreach $c (@{$mf{$meta}})  # for each filter condition
         {
            goto FAIL if ($c->[0] eq '<' && !($val <  $c->[1]));
            goto FAIL if ($c->[0] eq '>' && !($val >  $c->[1]));
            goto FAIL if ($c->[0] eq '=' && !($val == $c->[1]));
         }

         next;

         FAIL:
         _d("apply_final_meta_filters: FAIL $meta $val: $q\n") if $debug;
         $removed += $$q_h{$q}->{c_sum};
         delete($$q_h{$q});
      }
   }

   _d("apply_final_meta_filters: total queries after: $$total_queries ($removed removed)\n") if $debug;

   $$total_queries -= $removed if $total_queries;

   return $removed;
}


#
# Internal subs not exported; for call directly by hackers
#
sub set_debug 
{
   $debug             = shift;
   $debug_filehandles = shift;
}

# Print debug messages to STDOUT and filehandles given in @debug_filehandles
sub _d
{
   return if !$debug;

   my $msg = shift;

   my $fh;

   print "--- $msg";
   foreach $fh (@$debug_filehandles) { print $fh, "--- $msg";  }
}

# What percentage is x of y
sub _p
{
   my ($x, $y) = @_;
   return sprintf "%.2f", ($x * 100) / ($y ||= 1);
}


1;

__END__

=head1 NAME

MySQL::Log::ParseFilter - Parse and filter MySQL slow, general and binary logs

=head1 SYNOPSIS

    use MySQL::Log::ParseFilter;

    # Parse all unique queries from logs given on command line

    %params = (logs    => \@ARGV,
               queries => \%queries);

    parse_slow_logs(%params);
    parse_general_logs(%params);
    parse_binary_logs(%params);

    calc_final_values(%params);

=head1 DESCRIPTION

MySQL::Log::ParseFilter is a Perl module for parsing and filtering MySQL
slow, general and binary logs. MySQL::Log::ParseFilter also parses and filters
user-defined logs: logs with variable headers and SQL statement meta-properties.

Each MySQL log is formatted differently and poses many problems to accurate
parsing. From the range of MySQL server versions to the vast extent of
SQL syntax, parsing a MySQL log file is rarely a trivial task if done well.

MySQL::Log::ParseFilter handles all the heavy log chopping, hacking and filtering,
allowing a script to simply extract the data that it wants.

=head2 Functions

The following functions are exported by default:

=over 4

=item C<set_meta_filter($filter)>

Set meta-property filter to C<$filter>. C<$filter> is a scalar containing a single
string of meta-property filter conditions. See L</"Meta-Property">.

Returns nothing.

=item C<set_statement_filter($filter)>

Set SQL statement filter to C<$filter>. C<$filter> is a scalar containing a single
string of allowed or disallowed SQL statement types. See L</"SQL Statement">.

Returns nothing.

=item C<set_grep($pattern)>

Set the grep pattern against which SQL statements must match. (This could
be called the "grep filter.") C<$pattern> is a scalar containing a single
Perl regex pattern without m// or similar. For example: C<"^SELECT foo FROM (?:this|that)">.

Returns nothing.

=item C<parse_binary_logs(%params)>

Parse output of mysqlbinlog.

C<%params> may contain the following key/values:

C<logs>        => ref to array having log file names to parse (REQUIRED)

C<queries>     => ref to hash in which to save unique queries (REQUIRED)

C<all_queries> => ref to array in which to save all queries   (optional)

B<NOTE>: MySQL binary logs are, as the name suggests, binary--they are not
text files. It is necessary to first "decode" a binary log with the
MySQL-provided program mysqlbinlog. The log files given to
C<parse_binary_logs()> I<must> be the text output from mysqlbinlog ran first
on the binary log files (without the --short-form option).

Returns nothing.

=item C<parse_general_logs(%params)>

Parse MySQL general logs.

C<%params> may contain the following key/values:

C<logs>        => ref to array having log file names to parse (REQUIRED)

C<queries>     => ref to hash in which to save unique queries (REQUIRED)

C<all_queries> => ref to array in which to save all queries   (optional)

C<users>       => ref to hash in which to save unique users   (optional)

Returns nothing.

=item C<parse_slow_logs(%params)>

Parse MySQL slow and microslow logs.

C<%params> may contain the following key/values:

C<logs>        => ref to array having log file names to parse (REQUIRED)

C<queries>     => ref to hash in which to save unique queries (REQUIRED)

C<all_queries> => ref to array in which to save all queries   (optional)

C<users>       => ref to hash in which to save unique users   (optional)

C<microslow>   => 0 = regular slow log, 1 = microslow log     (optional)

0 is default for C<microslow>.

Returns nothing.

=item C<set_udl_format($format_file)>

Set the user-defined log format defined in C<$format_file>. C<$format_file> is a
scalar containing a single file name. See L</"USER-DEFINED LOGS">.

This function should be called before calling C<parse_udl_logs()>.

Returns nothing.

=item C<parse_udl_logs(%params)>

Parse user-defined logs.

C<%params> may contain the following key/values:

C<logs>        => ref to array having log file names to parse (REQUIRED)

C<queries>     => ref to hash in which to save unique queries (REQUIRED)

C<all_queries> => ref to array in which to save all queries   (optional)

C<users>       => ref to hash in which to save unique users   (optional)

Returns nothing.

See L</"USER-DEFINED LOGS">.

=item C<calc_final_values(%params, $grand_totals)>

Calculate final meta-property and grand total values after parsing logs.
This function should only be called after calling one of the parse_ functions.

This function calculates: number of unique queries, c_sum_p, averages,
grand total sums, percent true for true/false (or yes/no) meta-properties,
per-meta-property percentages of grand total sums, per-user percentages of
all users, and number of unique users.

C<%params> is the same hashed passed earlier to one of the parse_ functions.

C<$grand_totals> is a reference to a hash in which to save the grand total sums.
Pass 0 or C<undef> if you do not want grand total sums.

Returns total number of queries.

=item C<apply_final_meta_filters(%params, $total_queries)>

Apply final meta-propertry filters for min, max, average, percent and sum
meta-property values. This function should be called after calling
C<calc_final_values()>.

C<%params> is the same hashed passed earlier to C<calc_final_values()>
or to one of the parse_ functions if you did not calculate final
values for some reason.

C<$total_queries> is a reference to a scalar having the total number of queries.
Usually, this is obtained from the return value of C<calc_final_values()>.
C<$total_queries> will be adjusted to account for queries which were removed
by a filter. Pass 0 or C<undef> if you do not want an adjusted total queries.

Returns total number of queries removed.

=back

=head1 META-PROPERTIES

Every SQL statement has many meta-properties. These are values about
the SQL statement such as its execution time, how many rows it examines, the
MySQL connection ID it is associated with, etc. It is by these values that a
MySQL log is filtered (and usually sorted).

Every type of MySQL log provides different meta-properties. The list of all
meta-properties is very long so only the basics are given here. For the full
list visit http://hackmysql.com/mysqlsla_filtersZ<>.

But first, it is important to understand the naming scheme that 
MySQL::Log::ParseFilter uses for meta-properties.

=head2 Naming Scheme

Meta-properties are either numeric or string. For strings, the naming scheme
does not change: C<db> is always just C<db>. For numeric values, however,
several additional meta-properties are created and identified by consistent
extensions to the base meta-property name.

Take for example C<t> from slow logs. In addition to this base
meta-property, MySQL::Log::ParseFilter also creates: C<t_min>,
C<t_max>, C<t_avg>, C<t_sum> and C<t_sum_p> (unless C<set_save_meta_values()>
was disabled; see L</"OPTIONS">).

These additional meta-properties are identified by their extensions: C<_min>,
C<_max>, C<_avg>, C<_sum>, C<_sum_p>. These extensions are consistent and
form the naming scheme for I<most> numeric meta-properties. (C<cid> is a
notable exception.) They tell you as well as MySQL::Log::ParseFilter what
the additional meta-property value represents: the minimum, maximum, average
and sum value of their base meta-property.

C<_sum_p> means percentage that the base meta-property constitutes of the
grand total sum for all those base meta-properties (if grand total sum were
calculated when calling C<calc_final_values()>).

There is another extension for true/false (yes/no) meta-properties: C<_t>
and C<_t_p>. Currently, this type of meta-property is only found in microslow logs.

This naming scheme is very important when working with user-defined logs because
it allows you to know in advance the names the of additional meta-properties that
MySQL::Log::ParseFilter will create from the given bases meta-properties.

=head2 Slow Logs

C<c_sum> : Total number of times SQL statement appears in log

C<host> : Host name of MySQL connection

C<ip> : IP address of MySQL connection

C<l> : Time spent acquiring lock

C<l_sum> : Total time spent acquiring lock

C<re> : Number of rows examined

C<rs> : Number of rows sent

C<t> : Execution time

C<t_sum> : Total execution time

C<user> : User of MySQL connection

=head2 General Logs

C<c_sum> : Total number of times SQL statement appears in log

C<cid> : Connection ID of MySQL connection

C<host> : Host name of MySQL connection

C<user> : User of MySQL connection

=head2 Binary Logs

C<c_sum> : Total number of times SQL statement appears in log

C<cid> : Connection ID of MySQL connection

C<ext> : Execution time

C<err> : Error code (if any) caused by SQL statement

C<sid> : Server ID of MySQL server

=head1 SETTING FILTERS

All filters are inclusive: every condition for every filter must pass for the
statement to be saved.

=head2 Meta-Property

The format of C<$filter> when calling C<set_meta_filter($filter)> is
C<[CONDITION],[CONDITION]...> where each C<[CONDITION]> is C<[meta][op][val]>.

C<[meta]> is a meta-property name (listed above or from the full list
at http://hackmysql.com/mysqlsla_filtersZ<>). C<[op]> is either >, <, or =.
And C<[val]> is the value against which C<[meta]> from the log must
pass according to C<[op]>. C<[val]> is numeric or string according to
C<[meta]>. For string values, only = is valid for C<[op]>.

=head2 SQL Statement

The format of C<$filter> when calling C<set_statement_filter($filter)> is
C<[+-][TYPE],[TYPE]...>.

[+-] is give only once at the first start of the filter string. + means that
the filter is positive: allow only the given C<[TYPE]>s. - means that the filter
is negative: remove the given C<[TYPE]>s. C<[TYPE]> is a SQL statement type:
SELECT, UPDATE, INSERT, DO, SET, CREATE, DROP, ALTER, etc.

=head1 EXAMPLES

=head2 Parsing General Logs

    # Parse general logs given on command line extracting only SELECT queries
    # using database foo and calculate grand total sums

    my %queries;
    my %grand_totals;

    my %params = (
        logs    => \@ARGV,
        queries => \%queries,
    );

    set_meta_filter("db=foo");
    set_statement_filter("+SELECT");

    parse_general_logs(%params);

    calc_final_values(%params, \%grand_totals);

=head2 Parsing Slow Logs

    # Parse slow logs given on command line removing SET statements and
    # extracting only queries which took longer than 5 seconds to execute

    my %queries;

    my %params = (
        logs    => \@ARGV,
        queries => \%queries,
    );

    set_meta_filter("t>5");
    set_statement_filter("-SET");

    parse_slow_logs(%params);

    calc_final_values(%params, 0);

=head2 Parsing Binary Logs

    # Parse output files from mysqlbinlog given on command line extracting
    # only INSERT and UPDATE queries which account for more than 75% of all
    # INSERT and UPDATE queries extracted

    my %queries;
    my %grand_totals;

    my %params = (
        logs    => \@ARGV,
        queries => \%queries,
    );

    set_meta_filter("c_sum_p>75");
    set_statement_filter("+INSERT,UPDATE");

    parse_binary_logs(%params);

    calc_final_values(%params, \%grand_totals);

    apply_final_meta_filters(%params, 0);

=head2 Complete Mini-Script (dump_type)

    #!/usr/bin/perl -w

    use strict;
    use MySQL::Log::ParseFilter;

    my %queries;

    if(@ARGV != 2) {
       print "dump_type dumps a unique sample of all statements of TYPE from general LOG.\n";
       print "Usage: dump_type TYPE LOG\n";
       exit;
    }

    set_statement_filter("+$ARGV[0]");

    parse_general_logs( (logs => [ $ARGV[1] ], queries => \%queries) );

    foreach(keys %queries) { print "$queries{$_}->{sample}\n"; }

    exit;

=head1 OPTIONS

MySQL::Log::ParseFilter has six functions to set special options which can be
imported with the C<:options> tag (C<use MySQL::Log::ParseFilter qw(:DEFAULT :options)>).

=over 4

=item C<set_save_meta_values($val)>

Save extra meta-property values. Default 1 (enabled). Can be set to 0 (disabled)
which will result in only the following meta-properties being saved: C<sample>,
C<db>, C<cid>.

Any meta-property value not check in C<apply_final_meta_filters()>
can still be used (C<t>, C<l>, C<host>, C<cid>, etc.)

=item C<set_save_all_values($val)>

Save "all values": arrays of every single value for certain meta-properties
(C<meta_all>). Default 0 (disabled). Can be set to 1 (enabled). This does not
affect user-defined logs which has a seperate mechanism for saving all values
(type nf).

At present, enabling this option causes the following all values to be saved:
for microslow (msl) patched slow log with InnoDB values: C<iorops_all>,
C<iorbytes_all>, C<iorwait_all>, C<reclwait_all>, C<qwait_all>, C<pages_all>;
for binary logs: C<ext_all>.

=item C<set_IN_abstraction($val)>

Abstract IN () clauses further by grouping in groups of $val. Default 0 (disabled).

This is an experimental option. Normally, all IN clauses are condensed from
C<IN (N, N, N)> to C<IN (N3)>. This option furthers this abstraction by grouping
the condensed IN clauses in groups of $val where $val is the "dividing line."

Example: with $val=10  C<IN (N3)> becomes C<IN (N0-9)>. Therefore, any IN clause
with 0 to 9 values will be condensed and then further abstracted to C<IN (N0-9)>.
Likewise, any IN clauses with 10 to 19 values will be condensed and further
abstracted to C<IN (10-19)>.

=item C<set_VALUES_abstraction($val)>

Abstract VALUES () clauses further by removing the number of condensed value sets.
Default 0 (disabled). Can be set to 1 (enabled).

This is an experimental option. Normally, all VALUES clauses are condensed from
C<VALUES (NULL, 'foo'), (NULL, 'bar')> to C<VALUES (NULL, 'S')2>. This option
furthers this abstractiong by removing that number of condensed value sets: 2.

Example: two queries C<INSERT INTO table VALUES ('S')> and
C<INSERT INTO table VALUES ('S'), ('S'), ('S')> are first condensed to
C<INSERT ... VALUES ('S')1> and C<INSERT ... VALUES ('S')3> then further abstracted
to one single query: C<INSERT INTO table VALUES ('S')>.

=item C<set_atomic_statements($val)>

Treat multi-statement groups atomically when filtering. Default 0 (disabled).
Can be set to 1 (enabled).

This is an experimental option. Normally, each statement in a multi-statement
group is filtered individually: only those which fail a filter are removed
and those which pass are kept. With this option enabled, if any one statement
in a group fails, the entire group of statements is removed.

This option does not apply to general logs because general logs never group statements.

=item C<set_db_inheritance($val)>

Allow queries to inherit the last database specified in the log. Default 0 (disabled).
Can be set to 1 (enabled).

Normally, the log must explicitly specify the database for each statement. Or, in the
case of general logs, the current database is tracked by other means. Sometimes, however,
logs only specify the database explicitly once. If this option is enabled, all statements
following an explicit database specification inherit that database.

=back

=head1 USER-DEFINED LOGS

MySQL::Log::ParseFilter can parse user-defined logs which have variable
headers and meta-property values. Accomplishing this is not a trivial task.
Therefore the subject is not covered here but at http://hackmysql.com/udlZ<>.

=head1 HACKS

The following four functions can be imported with the C<:hacks> tag.

=over 4

=item C<get_meta_filter()>

Returns hash ref to internal meta filter hash which is structured:
C<meta =E<gt> [ op, value ]>.

=item C<get_statement_filter()>

Returns hash ref to internal statement filter hash which is structured:
C<type =E<gt> 0>. Also has C<pos_neg =E<gt> 1 (positive) or 0 (negative)>.

=item C<passes_meta_filter($meta, $val, $type)>

C<$meta> is a meta-property name. C<$val> is the log value. C<$type> is
'n' (numeric) or 's' (string). Returns 1 on pass, 0 on fail.

=item C<passes_statement_filter($type)>

C<$type> is a SQL statement type (SELECT, CREATE, DROP, etc.), case
insensitive. Returns  1 on pass, 0 on fail.

=back

=head1 DEBUGGING

Calling C<MySQL::Log::ParseFilter::set_debug(1)> will enable debugging and cause
MySQL::Log::ParseFilter to print a I<flood> of debugging information to STDOUT.
This may be necessary if you feel a function is not working correctly because,
although they do not return errors, they print debugging messages.

=head1 BUGS

There are no known bugs. Please contact me if you find one. Expect that I will
ask for at least a portion of your log because that makes finding and fixing
the bug easier.

=head1 AUTHOR

Daniel Nichter <perl@hackmysql.com>

http://hackmysql.com/

=head1 SEE ALSO

=over 4

=item http://hackmysql.com/mlp

MySQL::Log::ParseFilter home page

=item http://hackmysql.com/udl

Document describing how to make user-defined logs

=item http://hackmysql.com/mysqlsla

mysqlsla uses every part of MySQL::Log::ParseFilter to analyze, sort and report
data from MySQL logs. To study MySQL::Log::ParseFilter in all its glory, study
mysqlsla. In fact, MySQL::Log::ParseFilter was born from mysqlsla.

=item http://hackmysql.com/microsecond_slow_logs

Document summarizing microsecond resolution support for MySQL slow logs

=item http://dev.mysql.com/doc/refman/5.0/en/slow-query-log.html

Official MySQL slow query log documentation.

=item http://dev.mysql.com/doc/refman/5.0/en/query-log.html

Official MySQL general query log documentation.

=item http://dev.mysql.com/doc/refman/5.0/en/binary-log.html

Official MySQL binary query log documentation.

=item http://dev.mysql.com/doc/refman/5.0/en/mysqlbinlog.html

Official MySQL documentation for mysqlbinlog

=back

=head1 VERSION

v1.00

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Daniel Nichter

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
