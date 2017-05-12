# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Pcurse::Defaults;
use v5.8;
our $VERSION = '0.15';
use warnings;
use strict;

our @EXPORT =   qw(
	$bucardo_defaults
	$pg_default 
);

our $pg_default =  {
	listen_addresses          =>  'localhost',
	max_connections           =>  100        ,
	unix_socket_group         =>  ''         ,
	unix_socket_permissions   =>  0777       ,
	bonjour_name              =>  ''         ,
	authentication_timeout    =>  '1min'     ,     
	ssl_ciphers =>  'ALL:!ADH:!LOW:!EXP:!MD5:@STRENGTH'  ,
	password_encryption       =>  'on'       ,
	db_user_namespace         =>  'off'      ,
	krb_server_keyfile        =>  ''         , 
	krb_srvname               =>  'postgres' ,  
	krb_server_hostname       =>  ''         ,
	krb_caseins_users         =>  'off'      ,    
	krb_realm                 =>  ''         ,        
	tcp_keepalives_idle       =>  0          , 
	tcp_keepalives_interval   =>  0          ,
	tcp_keepalives_count      =>  0          ,
	temp_buffers              =>  '8MB'      ,     
	max_prepared_transactions =>  5          ,    
	work_mem                  =>  '1MB'      ,      
	maintenance_work_mem      =>  '16MB'     ,      
	max_stack_depth           =>  '2MB'      ,           
	max_fsm_relations         =>  1000       ,     
	max_files_per_process     =>  1000       ,  
	shared_preload_libraries  =>  ''         , 
	vacuum_cost_delay         =>  0          , 
	vacuum_cost_page_hit      =>  1          , 
	vacuum_cost_page_miss     =>  10         , 
	vacuum_cost_page_dirty    =>  20         , 
	vacuum_cost_limit         =>  200        ,       
	bgwriter_delay            =>  '200ms'    ,      
	bgwriter_lru_maxpages     =>  100        , 
	bgwriter_lru_multiplier   =>  2.0        , 
	fsync                     => 'on'        ,        
	wal_sync_method           =>  'fsync'    , 
	full_page_writes          => 'on'        ,  
	wal_buffers               =>  '64kB'     ,       
	wal_writer_delay          =>  '200ms'    ,  
	commit_delay              =>  0          , 
	commit_siblings           =>  5          , 
	checkpoint_segments       =>  3          , 
	checkpoint_timeout        =>  '5min'     ,        
	checkpoint_completion_target =>  0.5     ,
	checkpoint_warning        =>  '30s'      ,   
	archive_mode              =>  'off'      , 
	archive_command           =>  ''         ,
	archive_timeout           =>  0          ,
	enable_bitmapscan         => 'on'        , 
	enable_hashagg            => 'on'        ,
	enable_hashjoin           => 'on'        ,
	enable_indexscan          => 'on'        ,
	enable_mergejoin          => 'on'        ,
	enable_nestloop           => 'on'        ,
	enable_seqscan            => 'on'        ,
	enable_sort               => 'on'        ,
	enable_tidscan            => 'on'        ,
	seq_page_cost             =>  1.0        ,             
	random_page_cost          =>  4.0        ,        
	cpu_tuple_cost            =>  0.01       ,        
	cpu_index_tuple_cost      =>  0.005      ,
	cpu_operator_cost         =>  0.0025     , 
	effective_cache_size      =>  '128MB'    ,
	geqo                      => 'on'        ,
	geqo_threshold            =>  12         ,
	geqo_effort               =>  5          ,
	geqo_pool_size            =>  0          ,
	geqo_generations          =>  0          ,
	geqo_selection_bias       =>  2.0        ,
	default_statistics_target =>  10         ,
	constraint_exclusion      =>  'off'      ,
	from_collapse_limit       =>  8          ,
	join_collapse_limit       =>  8              ,
	logging_collector               =>  'off'    ,
	log_destination                 => 'stderr'  ,
	log_directory                   => '/var/log/postgres'   ,
	log_filename                    =>  'postgresql-8.3.log' ,
	log_directory                   =>  'pg_log'             ,
	log_filename                    =>  'postgresql-%Y-%m-%d_%H%M%S.log' ,
	log_truncate_on_rotation        =>  'off'      ,
	log_rotation_age                =>  '1d'       ,
	log_rotation_size               =>  '10MB'     ,
	client_min_messages             =>  'notice'   ,
	log_min_messages                =>  'notice'   ,
	log_error_verbosity             =>  'default'  ,
	log_min_error_statement         =>  'error'    ,
	log_min_duration_statement      =>  -1         ,
	silent_mode                     =>  'off'      ,
	debug_print_parse               =>  'off'      ,
	debug_print_rewritten           =>  'off'      ,
	debug_print_plan                =>  'off'      ,
	debug_pretty_print              =>  'off'      ,
	log_checkpoints                 =>  'off'      ,
	log_connections                 =>  'off'      ,
	log_disconnections              =>  'off'      ,
	log_duration                    =>  'off'      ,
	log_hostname                    =>  'off'      ,
	log_line_prefix                 =>  ''         , 
	log_lock_waits                  =>  'off'      ,   
	log_statement                   =>  'none'     , 
	log_temp_files                  =>  -1         ,      
	log_timezone                    =>  'unknown'       ,
	track_activities                => 'on'             ,
	track_counts                    => 'on'             ,
	update_process_title            => 'on'             ,
	log_parser_stats                =>  'off'           ,
	log_planner_stats               =>  'off'           ,
	log_executor_stats              =>  'off'           ,
	log_statement_stats             =>  'off'           ,
	autovacuum                      => 'on'             ,          
	log_autovacuum_min_duration     =>  -1              ,
	autovacuum_max_workers          =>  3               ,   
	autovacuum_naptime              =>  '1min'          ,     
	autovacuum_vacuum_threshold     =>  50              ,
	autovacuum_analyze_threshold    =>  50              ,
	autovacuum_vacuum_scale_factor  =>  0.2             ,
	autovacuum_analyze_scale_factor =>  0.1             ,
	autovacuum_freeze_max_age       =>  200000000       ,
	autovacuum_vacuum_cost_delay    =>  '20ms'          ,
	autovacuum_vacuum_cost_limit    =>  -1              ,
	search_path                     =>  '"$user",public',
	default_tablespace              =>  ''              ,
	temp_tablespaces                =>  ''              , 
	check_function_bodies           => 'on'             ,
	default_transaction_isolation   =>  'read committed',
	default_transaction_read_only   =>  'off'           ,
	statement_timeout               =>  0               ,    
	session_replication_role        =>  'origin'        ,
	vacuum_freeze_min_age           =>  100000000       ,
	xmlbinary                       =>  'base64'        ,
	xmloption                       =>  'content'       ,
	timezone                        =>  'unknown'       ,           
	timezone_abbreviations          =>  'Default'       ,   
	extra_float_digits              =>  0               ,      
	client_encoding                 =>  'sql_ascii'     ,        
	explain_pretty_print            => 'on'             ,
	dynamic_library_path            =>  '$libdir'       ,
	local_preload_libraries         =>  ''              ,
	deadlock_timeout                =>  '1s'            ,
	max_locks_per_transaction       =>  64              ,       
	add_missing_from                =>  'off'           ,
	array_nulls                     => 'on'             ,
	backslash_quote                 =>  'safe_encoding' ,
	default_with_oids               =>  'off'           ,
	escape_string_warning           => 'on'             ,
	standard_conforming_strings     =>  'off'           ,
	port                            =>  5432            , 
	regex_flavor                    =>  'advanced'      ,
	sql_inheritance                 => 'on'             ,
	transform_null_equals           =>  'off'           ,
	custom_variable_classes         =>  ''              ,
	ssl                             =>  'off'           ,
	shared_buffers                  =>  '32MB'          ,
	max_fsm_pages                   =>   204800         ,
	log_destination                 =>  'stderr'        ,
	datestyle                       =>  'iso, mdy'      ,
	lc_messages                     =>  'en_US'         ,
	lc_monetary                     =>  'en_US'         ,
	lc_numeric                      =>  'en_US'         ,    
	lc_time                         =>  'en_US'         ,  
	syslog_facility                 =>  'LOCAL0'        ,
	syslog_ident                    =>  'postgres'      ,
	default_text_search_config      =>  'pg_catalog.english',
};
1;
__END__
=head1 NAME

Pg::Pcurse::Defaults  - Configuration defaults for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Defaults

=head1 DESCRIPTION

Configuration defaultgs for Pg::Pcurse


=head1 SEE ALSO

Pg::Pcurse, pcurse(1)

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut
