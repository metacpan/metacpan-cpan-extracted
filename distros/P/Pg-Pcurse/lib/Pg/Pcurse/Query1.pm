# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .
package Pg::Pcurse::Query1;
use v5.8;
use DBIx::Abstract;
use Carp::Assert;
use base 'Exporter';
use Data::Dumper;
use strict;
use warnings;
our $VERSION = '0.14';
use Pg::Pcurse::Misc;
use Pg::Pcurse::Query0;

our @EXPORT = qw( 
        get_proc_desc  get_proc        
        table_buffers   over_dbs       over_dbs3
        analyze_tbl    analyze_db      vacuum_per_table
	vacuum_tbl     vacuum_db       fsm_settings
	reindex_tbl    reindex_db      table_stat
	bucardo_conf_desc 	 bucardo_conf
        pgbuffercache            buffercache_summary  pgbuffercache_desc
	get_nspacl               all_databases_age    bufstat

	all_databases_desc       all_databases        get_schemas2 
	get_views_all_desc       get_views_all
	index3_desc              index3                  index3b
	get_index_desc           get_index 
	table_stats_desc         table_stats 
	table_stats2_desc        table_stats2 
        rules_desc               rules
	schema_trg_desc          schema_trg
	get_users_desc           get_users
);



sub get_schemas2 {
	my ($o, $database)   = @_;
	$database or $database = $o->{dbname} ;
	my $dsn =  form_dsn ($o, $database);
	my $dh = dbconnect ( $o, $dsn ) or return;
        my $st = $dh->select({
                fields=> [qw(nspname rolname)],
                table=>'pg_namespace,pg_roles',
                join=>'pg_namespace.nspowner=pg_roles.oid',
                });

	[  sort schema_sorter 
           map { sprintf '%-20s%-10s', @{$_}[0..1] }  
               @{ $st->fetchall_arrayref}
        ];
}


sub get_proc_desc {
	sprintf '%-25s%-9s%10s%8s%6s%6s%9s','NAME','LANG', 'strict', 'setof',
                                 'volit', 'nargs','type'
}
sub get_proc {
	my ( $o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
	my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$schema = $dh->quote($schema);
        my $h = $dh->{dbh}->selectall_arrayref(<<"" );
	SELECT proname,           lanname,
	       proisstrict AS s,  proretset AS set,  provolatile AS v,
	       pronargs AS nargs, prorettype::regtype, 
               P.oid
	FROM pg_proc  P
             join pg_namespace N on (pronamespace=N.oid)
	     join pg_language  L on (prolang=L.oid)
	WHERE nspname=$schema
	ORDER BY 1

	[  map { sprintf '%-25s%-9s%7s%7s%9s%7s%9s%40s', @{$_}[0..7]} 
           @$h ];
}


sub table_buffers { 
	my ($o)= @_;
	my $dh = dbconnect ( $o, form_dsn($o, '')  ) or return;
        my $h  = $dh->{dbh}->selectall_arrayref(<<"");
	select 'checkpoints_timed',(select checkpoints_timed 
                                                from pg_stat_bgwriter)
	union
	select 'checkpoints_req',(select checkpoints_req  from pg_stat_bgwriter)
	union
	select 'checkpoints Total',(select checkpoints_timed+checkpoints_req  
                                                from pg_stat_bgwriter)
	union
	select 'Pages/ck',
	(select buffers_checkpoint/(checkpoints_timed+checkpoints_req)  
                                                from pg_stat_bgwriter)
	union
	select 'buffers_alloc',   (select buffers_alloc   from pg_stat_bgwriter)
	union
	select 'buffers_backend', (select buffers_backend from pg_stat_bgwriter)
	union
	select 'buffers_backend', (select buffers_backend from pg_stat_bgwriter)
	union
	select 'buffers_clean',   (select buffers_clean from pg_stat_bgwriter)
	union
	select 'buffers_checkpoint', (select buffers_checkpoint from pg_stat_bgwriter)
	union
	select 'maxwritten_clean', (select maxwritten_clean from pg_stat_bgwriter)
	union
	select name, setting::int
	from pg_settings
	where name ~ 'buffer'
	order by 1

	[ map { sprintf '%-25s%10s', @{$_}[0..1]}
		       @{$h} ];
}
sub bufstat { 
	my ($o)= @_;
	my $dh = dbconnect ( $o, form_dsn($o, '')  ) or return;
        my $h  = $dh->select_one_to_hashref( [qw( buffers_checkpoint 
	                                     checkpoints_req checkpoints_timed
	                                     buffers_alloc   buffers_backend
                                             )], 
                                             'pg_stat_bgwriter');
	my $total_chk     = $h->{checkpoints_req}+ $h->{checkpoints_timed};
	my $forced_ratio  = calc_read_ratio( $h->{buffers_backend},
                                             $h->{buffers_alloc} );
	my $pages_per_chk = $h->{buffers_checkpoint} / $total_chk;
	[ '',
          sprintf('%-20s:%10d'   , 'Checkpoints'        ,  $total_chk        ),
	  sprintf('%-20s:%13.2f' , 'Pages / Checkpoint'  ,  $pages_per_chk   ),
	  sprintf('%-20s:%13.2f KB ', 'Bytes / Checkpoint', $pages_per_chk*8 ),
	  '',
	  sprintf( '%-20s:%13.2f %' , 'Forced from Buffer', $forced_ratio    ),
        ]
}
sub table_stats_desc {
     sprintf '%-23s%15s%15s%13s%11s','NAME','seq-scan','idx_scan', '  seq/idx', 'ndead_tup', 
}

sub format_rat {
	my ($seq, $idx) = @_ ;
	return 'inf' unless $idx;
	sprintf '%5.1f', $seq/$idx ;
}
sub table_stats {
	my ($o, $database , $schema) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $st = $dh->select( [qw(  relname     seq_scan  
                                    idx_scan    n_dead_tup
                               )],
                              'pg_stat_user_tables',
                              ['schemaname', '=', $dh->quote($schema) ]);
	my $h = $st->fetchall_arrayref;
        for my $i (@$h) { 
              $_ || ($_= 0 )   for @$i; 
        }
        [ sort map { sprintf '%-23s%15s%15s%13s%9s', @{$_}[0..2],
                              format_rat( @{$_}[1..2]), ${$_}[3] }
	      @{ $h } ];

}
sub table_stats2_desc {
     sprintf '%-25s%8s%9s%9s%9s%8s%8s','NAME',  'inserts','updates',
                        'deletes','hot-upd', 'live','dead'
}
sub table_stats2 {
	my ($o, $database , $schema) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $st = $dh->select( [qw(  relname     
                                    n_tup_ins      n_tup_upd   n_tup_del    
                                    n_tup_hot_upd  n_live_tup  n_dead_tup
                               )],
                              'pg_stat_user_tables',
                              ['schemaname', '=', $dh->quote($schema) ]);
	my $h = $st->fetchall_arrayref;
        for my $i (@$h) { 
              $_ || ($_= 0 )   for @$i; 
        }
        [ sort map { sprintf '%-25s%8s%9s%9s%9s%8s%8s', @{$_}[0..6] }
	      @{ $h } ];

}


sub get_nspacl {
	my ($o, $database, $schema) = @_;
        my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        $schema = $dh->quote( $schema );
	my $h   = $dh->select_one_to_hashref({
                   fields => 'nspacl', 
                   table  =>  'pg_namespace',
		   where  => [ 'nspname','=', $schema ] 
        });
   

	[ sprintf "%s", $h->{nspacl} ? "@{ $h->{nspacl} }": '' ];
}
sub get_views_all_desc {
	sprintf '%-35s %10s','NAME', 'OWNER' ;
} 
sub get_views_all {
	my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$schema = $dh->quote($schema);
        my $st  = $dh->select(  [qw( viewname viewowner )],
	                       'pg_views',
                               ['schemaname', '=', $schema ] );
	[ sort map { sprintf '%-35s %10s', @{$_}[0..1]}
	       @{$st->fetchall_arrayref} ];
}
sub rules_desc {
	sprintf '%-35s','NAME';
} 
sub rules {
	my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$schema = $dh->quote($schema);
        my $st  = $dh->select(  [qw( rulename )],
	                       'pg_rules',
                               ['schemaname', '=', $schema ] );
	[ sort map { sprintf '%-35s', ${$_}[0]}
	       @{$st->fetchall_arrayref} ];
}
sub max_length_keys {
	my $max=0;
	for (@_) {
		if (length$_ > $max) { $max = length$_};
	}
	$max;
}
sub  analyze_tbl  {
	my ($o, $database , $schema, $table) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( "analyze $schema.$table" ); 1 };
}

sub analyze_db   {
	my ($o, $database ) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( 'analyze' )  ; 1 }           
}
sub  vacuum_tbl  {
	my ($o, $database , $schema, $table) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( "vacuum ${schema}.${table}" )  ; 1};
}

sub vacuum_db   {
	my ($o, $database ) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( 'vacuum' )    ; 1};
}
sub  reindex_tbl  {
	my ($o, $database , $schema, $table) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( "reindex $schema.$table" ); 1};
}

sub reindex_db   {
	my ($o, $database ) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	eval { $dh->{dbh}->do( 'reindex' )    ; 1 };
}
sub bucardo_conf_desc {
	sprintf '%-25s  %s', 'setting', 'value ' ;
}
sub bucardo_conf {
        my ($o)= @_;
        my $dh = dbconnect ( $o, form_dsn($o, 'bucardo')  ) or return;
        my $h  = $dh->{dbh}->selectall_arrayref(<<"");
		SELECT  setting, value, about, cdate 
		FROM    bucardo.bucardo_config
		order by 1

        [ map { sprintf '%-25s  %-31s', @{$_}[0..1] }
	      @$h ]
}

sub schema_trg_desc {
         sprintf '%-25s  %-10s', 'table', 'trigger'
}
sub schema_trg {
        my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
        my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        $schema = $dh->quote($schema);
        my $h   = $dh->{dbh}->selectall_arrayref(<<"") ;
		SELECT T.oid, C.relname,  tgname,
		       tgenabled AS enabled
		FROM          pg_trigger   T
			 join pg_class     C  on (C.oid=tgrelid)
			 join pg_namespace S  on (C.relnamespace=S.oid )
		WHERE nspname = $schema
		ORDER BY 2 , 3

        [ map { sprintf '%-25s  %-44s %1s %30s', @{$_}[1..3,0] }
	      @$h 
       ]

}

sub get_users_desc {
        sprintf '%-6s', 'users';
}

sub get_users {
        my ($o, $database) = @_;
        $database or $database = $o->{dbname} ;
        my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        my $h   = $dh->{dbh}->selectall_arrayref(<<"") ;
	select usename,
		case when(usesuper)  then 'super' else ''  end AS superuser,
		case when(usecatupd) then 'catupd' else '' end AS catupd,
		case when(usecreatedb) then 'createdb' else '' end AS createdb
	from pg_user
	order by 2 desc,1

        [ map { sprintf '%-20s  %-7s %-7s %-s', @{$_}[0..3] }
	      @$h 
       ]

}

sub vacuum_per_table { 
	my ($o, $database , $schema, $table) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref(
                      [ 'vacrelid::regclass::text AS name' , qw(
                        enabled  vac_base_thresh  vac_scale_factor 
			anl_base_thresh   anl_scale_factor   vac_cost_delay  
			vac_cost_limit   freeze_min_age   freeze_max_age
                      )], 'pg_autovacuum, pg_namespace',
                      ['vacrelid::regclass::text', '=', $dh->quote($table) ,
                        'and', 'nspname', '=', $dh->quote($schema)
                      ]);
        my $r =
        [ sprintf( '%-18s : %s', 'relname'          , $table                 ),
          '',                                                   
          sprintf( '%-18s : %s', 'enabled'          , $h->{enabled}          ),
          sprintf( '%-18s : %s', 'vac_base_thresh'  , $h->{vac_base_thresh}  ),
          sprintf( '%-18s : %s', 'vac_scale_factor' , $h->{vac_scale_factor} ),
          sprintf( '%-18s : %s', 'anl_base_thresh'  , $h->{anl_base_thresh}  ),
          sprintf( '%-18s : %s', 'anl_scale_factor' , $h->{anl_scale_factor} ),
          sprintf( '%-18s : %s', 'vac_cost_delay'   , $h->{vac_cost_delay}   ),
          sprintf( '%-18s : %s', 'vac_cost_limit'   , $h->{vac_cost_limit}   ),
          sprintf( '%-18s : %s', 'freeze_min_age'   , $h->{freeze_min_age}   ),
          sprintf( '%-18s : %s', 'freeze_max_age'   , $h->{freeze_max_age}   ),
	];
        $h  = $dh->select_one_to_hashref( 
                      [qw( n_dead_tup 
                           last_vacuum     last_autovacuum  
			   last_analyze    last_autoanalyze
                      )], 'pg_stat_all_tables, pg_namespace',
                      ['relid::regclass::text', '=', $dh->quote($table) ,
                              'and', 'nspname', '=', $dh->quote($schema)
                      ]);

        my $r2 =
        [ #sprintf( '%-18s : %s', 'relname'          , $table                 ),
          '',                                            
          sprintf( '%-18s : %s', 'n_dead_tup'       , $h->{n_dead_tup}       ),
          sprintf( '%-18s : %s', 'last_vacuum'      , $h->{last_vacuum}      ),
          sprintf( '%-18s : %s', 'last_autovacuum'  , $h->{last_autovacuum}  ),
          sprintf( '%-18s : %s', 'last_analyze'     , $h->{last_analyze}     ),
          sprintf( '%-18s : %s', 'last_autoanalyse' , $h->{last_autoanalyze} ),
	];
	[@$r, @$r2];
}
sub over_dbs {
	my ($o, $database )= @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref( {
                      fields=> ['pg_database.datname',
			        'pg_get_userbyid(datdba) AS dba',
				'pg_encoding_to_char(encoding) AS encoding',
			         qw( datistemplate  datallowconn  datconnlimit 
			             datlastsysoid  datfrozenxid  dattablespace
                                     datconfig      datacl        oid
                                 ), 'age(datfrozenxid)',
	      'pg_database_size(pg_database.datname) AS bytes',
	      'pg_size_pretty( pg_database_size(pg_database.datname)) AS size',
                                ],
                      table => 'pg_database,pg_stat_database',
		      join  => 'pg_database.datname=pg_stat_database.datname',
		      where => ['pg_database.datname', 
                                '=', $dh->quote($database)] 
                       });

        [ sprintf( '%-18s : %s', 'database'      , $h->{datname}        ),
          sprintf( '%-18s : %s', 'oid'           , $h->{oid}            ),
          sprintf( '%-18s : %s', 'dba'           , $h->{dba}            ),
          sprintf( '%-18s : %s', 'encoding'      , $h->{encoding}  ),
          sprintf( '%-18s : %s', 'istemplate'    , $h->{datistemplate}  ),
          sprintf( '%-18s : %s', 'allowconn'     , $h->{datallowconn}   ),
          sprintf( '%-18s : %s', 'connlimit'     , $h->{datconnlimit}   ),
          sprintf( '%-18s : %s', 'lastsysoid'    , $h->{datlastsysoid}  ),
          sprintf( '%-18s : %s', 'frozenxid'     , $h->{datfrozenxid}   ),
          sprintf( '%-18s : %s', 'age'           , $h->{age}            ),
          sprintf( '%-18s : %s', 'config'        , $h->{datconfig}
                                                   &&"@{$h->{datconfig}}" ),
          sprintf( '%-18s : %s', 'acl', $h->{datacl} && "@{$h->{datacl}}" ),
          sprintf( '%-18s : %s', 'xact_commit'   , $h->{xact_commit}    ),
          sprintf( '%-18s : %s', 'xact_rollback' , $h->{xact_rollback}  ),
          sprintf( '%-18s : %d', 'db_pages'      , $h->{bytes}/1024/8   ),
          sprintf( '%-18s : %s', 'db_size'       , $h->{size}           ),
          sprintf( '%-18s : %s', 'tablespace'    , $h->{dattablespace}  ),
        ]
}

sub table_stat {
	my ($o, $database , $schema, $table) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $h = $dh->select_one_to_hashref({
	   fields => [qw(     relname         relfrozenxid
                relnamespace  reltype         relam           reltablespace
                reltuples     reltoastrelid   reltoastidxid   relhasindex  
                relisshared   relkind         relnatts        relchecks    
                reltriggers   relukeys        relfkeys        relrefs       
                relhasoids    relhaspkey      relhasrules     relhassubclass
                relname       relfilenode     relpages        relacl  reloptions
                     ), 'pg_get_userbyid(relowner) AS owner',
			'pg_class.oid              AS coid',
			'age(relfrozenxid)',
	                'pg_size_pretty(pg_relation_size(pg_class.oid)) AS rsi',
	     'pg_size_pretty( pg_total_relation_size(pg_class.oid)) AS trsize',
                      ],
	   table  => 'pg_class,pg_namespace',
	   join   => 'pg_class.relnamespace=pg_namespace.oid',
           where  => [        'relname',  '=' ,  $dh->quote($table),
                       'and', 'nspname',  '=' ,  $dh->quote($schema),
                          ]}); 

	my $r1 =
	[ sprintf( '%-14s : %s', 'name' ,        $h->{relname}       ),
	  sprintf( '%-14s : %s', 'oid',          $h->{coid}        ),
	  sprintf( '%-14s : %s', 'owner',        $h->{owner}         ),
	  sprintf( '%-14s : %s', 'natts'      ,  $h->{relnatts}      ),
	  sprintf( '%-14s : %s', 'pages',        $h->{relpages}      ),
	  sprintf( '%-14s : %s', 'size',         $h->{rsi}           ),
	  sprintf( '%-14s : %s', 'total relsize',$h->{trsize}        ),
	  sprintf( '%-14s : %s', 'acl',      
                               $h->{relacl} ? "@{ $h->{relacl} }": ''),
	  sprintf( '%-14s : %s', 'est. tuples',  $h->{reltuples}     ),
	  sprintf( '%-14s : %s', 'haspkey'    ,  $h->{relhaspkey}    ),
	  sprintf( '%-14s : %s', 'fkeys'      ,  $h->{relfkeys}      ),
	  sprintf( '%-14s : %s', 'hasindex'   ,  $h->{relhasindex}   ),
	  sprintf( '%-14s : %s', 'hasrules'   ,  $h->{relhasrules}   ),
	  sprintf( '%-14s : %s', 'triggers'   ,  $h->{reltriggers}   ),
	  sprintf( '%-14s : %s', 'ukeys'      ,  $h->{relukeys}      ),
	  sprintf( '%-14s : %s', 'refs'       ,  $h->{relrefs}       ),
	  sprintf( '%-14s : %s', 'hassubclass',  $h->{relhassubclass}),
	  sprintf( '%-14s : %s', 'checks'     ,  $h->{relchecks}     ),
	  sprintf( '%-14s : %s', 'options',      $h->{reloptions}),
	  sprintf( '%-14s : %s', 'isshared'   ,  $h->{relisshared}   ),
	  sprintf( '%-14s : %s', 'filenode',     $h->{relfilenode} ),
	  sprintf( '%-14s : %s', 'toastrelid' ,  $h->{reltoastrelid} ),
	  sprintf( '%-14s : %s', 'hasoids',      $h->{relhasoids}  ),
	  sprintf( '%-14s : %s', 'frozenxid',    $h->{relfrozenxid}  ),
	  sprintf( '%-14s : %s', 'age',          $h->{age}           ),
	];
        #relnamespace reltype relam reltablespace reltoastidxid relkind        
        $h = $dh->select_one_to_hashref(
                       [qw(  n_dead_tup      last_vacuum     last_autovacuum 
                             last_analyze    last_autoanalyze
	                )],
	                'pg_stat_user_tables',
			[         'relname',    '=', $dh->quote($table),
			   'and', 'schemaname', '=', $dh->quote($schema),
                        ]
             );
    
	my $r2 =
        [
	  sprintf( '%-14s : %s', 'n_dead_tup'      ,  $h->{n_dead_tup}      ),
	  sprintf( '%-14s : %s', 'last_analyze'    ,  $h->{last_analyze}    ),
	  sprintf( '%-14s: %s', 'last_autoanalyze',  $h->{last_autoanalyze} ),
	  sprintf( '%-14s : %s', 'last_vacuum'     ,  $h->{last_vacuum}     ),
	  sprintf( '%-14s: %s', 'last_autovacuum' ,  $h->{last_autovacuum}  ),
        ];

	[@$r1,@$r2]
}


sub all_databases_desc {
          sprintf '%-15s %8s %8s %8s %18s', 'NAME', 'BENDS','COMMIT',
                              '% READ',
}
sub all_databases {
	my ($o) = @_;
	my $dsn =  form_dsn ($o, '');
	my $dh  = dbconnect( $o, $dsn  ) or return;
        my $st  = $dh->select({
                fields=> [qw( pg_database.datname numbackends 
                              xact_commit         xact_rollback
                              blks_read           blks_hit 
                              age(datfrozenxid)
                              pg_catalog.pg_encoding_to_char(encoding) 
                          ),
	               'pg_size_pretty( pg_database_size(pg_database.datname))',
	                 ],
                table=>'pg_stat_database,pg_database',
                join=>'pg_stat_database.datname=pg_database.datname',
                });

       [ sort map { sprintf '%-15s %8s%10s%7.2f %9s %-12s %12s', 
			#TODO sometimes we get an undef that warns
	             @{$_}[0..2],  calc_read_ratio(@{$_}[4..5]), ${$_}[-1]
                   }

		       @{ $st->fetchall_arrayref} ];
}
sub buffercache_summary {
        my ($o, $database )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;

        my $h = $dh->select_one_to_hashref(<<"");
           user in (select rolname from pg_roles where rolsuper) AS super

        return [ q(Must be in a "super" role to view buffer data.) ]
                     unless $h->{super};
        my $db_of_func = search4func( $o, 'pg_buffercache_pages',
                                        $database, databases2 $o ) ;
        return [q(public.pg_buffercache found in any database.)]
                   unless $db_of_func;
        $dh = dbconnect ( $o, form_dsn($o, $db_of_func ) ) or return;

	$h = $dh->select_one_to_hashref(
	[ '(select count(*) from pg_buffercache) AS total',
'(select count(*) from pg_buffercache where relfilenode is not null) AS taken',
'(select count(*) from pg_buffercache where relfilenode is null) AS empty',
'(select count(*) from pg_buffercache where relfilenode is not null
and usagecount>1) AS "usage>1"',
] ); 

	[ sprintf( '%-10s : %8d', 'total'  , $h->{total}),
	  sprintf( '%-10s : %8d', 'empty'  , $h->{empty}),
	  sprintf( '%-10s : %8d', 'taken'  , $h->{taken}),
	  sprintf( '%-10s : %8d', 'usage>1', $h->{'usage>1'}),
	]

}
sub index3_desc {
     sprintf '%-30s %11s %8s %10s %13s','NAME', 'tuples',
                    'pages', 'idx_scan', 'idx_tup_fetch',
}
sub index3 {
	my ($o, $database , $schema) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	$schema = $dh->quote( $schema );
	my $h = $dh->{dbh}->selectall_arrayref( <<"");
		SELECT indexrelname, reltuples, relpages,  idx_scan,
		       idx_tup_fetch,   indexrelid
		 FROM        pg_stat_user_indexes S
			join pg_class C on ( C.relname = S.indexrelname )
		 WHERE schemaname = $schema
		 ORDER by 1

        [ map { sprintf '%-30s  %10s  %5s %8s %8s %90s', @{$_}[0..5] }
	      @$h ]
}

sub get_index_desc {
        sprintf('%-14s%-10s',  'NAME',  'u  p c v r xmin');
}
sub get_index {
        my ($o, $database ,  $indexrelid) = @_;
        my $dh   =  dbconnect ( $o, 'dbi:Pg:dbname='. $database  ) or return;
        my $qin  =  $dh->quote( $indexrelid );

        my $h  = $dh->select_one_to_hashref({
              fields=>
                 [ qw( indexrelid::regclass     indrelid::regclass 
                       indnatts        indisunique indisprimary 
                       indisclustered  indisvalid  indcheckxmin  indisready 
                       indkey indclass indoption   indexprs      indpred
		       relpages        reltuples ),
		     'pg_get_userbyid(relowner) AS owner',
		     'pg_get_indexdef(indexrelid) AS def',
		     'pg_size_pretty(pg_relation_size(indexrelid)) AS siz',
	         ],
		table=> 'pg_index, pg_class',
		join => 'pg_index.indexrelid=pg_class.oid',
                where=> [ 'indexrelid','=', $qin] }) ;

        [ sprintf( '%-14s : %s', 'name'       , $h->{indexrelid}    ),
          sprintf( '%-14s : %s', 'exrelid'    , $indexrelid         ),
          sprintf( '%-14s : %s', 'relid'      , $h->{indrelid}      ),
          sprintf( '%-14s : %s', 'relpages'   , $h->{relpages}      ),
          sprintf( '%-14s : %s', 'reltuples'  , $h->{reltuples}     ),
          sprintf( '%-14s : %s', 'owner'      , $h->{owner}         ),
          sprintf( '%-14s : %s', 'size'       , $h->{siz}           ),
          sprintf( '%-14s : %s', 'natts'      , $h->{indnatts}      ),
          sprintf( '%-14s : %s', 'isunique'   , $h->{indisunique}   ),
          sprintf( '%-14s : %s', 'isprimary'  , $h->{indisprimary}  ),
          sprintf( '%-14s : %s', 'isclustered', $h->{indisclustered}),
          sprintf( '%-14s : %s', 'isvalid'    , $h->{indisvalid}    ),
          sprintf( '%-14s : %s', 'checkxmin'  , $h->{indcheckxmin}  ),
          sprintf( '%-14s : %s', 'isready'    , $h->{indisready}    ),
          sprintf( '%-14s : %s', 'key'        , $h->{indkey}        ),
          sprintf( '%-14s : %s', 'class'      , $h->{indclass}      ),
          sprintf( '%-14s : %s', 'option'     , $h->{indoption}     ),
          sprintf( '%-14s : %s', 'exprs'      , $h->{indexprs}      ),
          sprintf( '%-14s : %s', 'pred'       , $h->{indpred}       ),
           Curses::Widgets::textwrap( $h->{def} , 60)  ,       
        ]

}
sub all_databases_age {
	my ($o) = @_;
	my $dsn =  form_dsn ($o, '');
	my $dh  = dbconnect( $o, $dsn  ) or return;
        my $st  = $dh->select(  [qw( datname age(datfrozenxid))],
                                'pg_database' );
       [ sort map { sprintf '%-22s    %5.3f', ${$_}[0], ${$_}[1]/1_000_000  }
		       @{ $st->fetchall_arrayref} ];
}
      
sub over_dbs3 {
	my ($o, $database )= @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref( {
                      fields=> ['pg_database.datname',
			        'pg_get_userbyid(datdba) AS dba',
				'pg_encoding_to_char(encoding) AS encoding',
			         qw( datistemplate  datallowconn  datconnlimit 
			             datlastsysoid  datfrozenxid  dattablespace
                                     datconfig      datacl        blks_read
                                     blks_hit       xact_commit   xact_rollback
				     tup_returned   tup_fetched   tup_inserted
				     tup_updated    tup_deleted   oid
                                 ), 'age(datfrozenxid)',
	      'pg_size_pretty( pg_database_size(pg_database.datname)) AS size',
                                ],
                      table => 'pg_database,pg_stat_database',
		      join  => 'pg_database.datname=pg_stat_database.datname',
		      where => ['pg_database.datname', 
                                '=', $dh->quote($database)] 
                       });

        [ sprintf( '%-18s : %s', 'database'      , $h->{datname}        ),
          sprintf( '%-18s : %s', 'oid'           , $h->{oid}            ),

          sprintf( '%-18s : %s', 'blks_read'     , $h->{blks_read}        ),
          sprintf( '%-18s : %s', 'blks_hit'      , $h->{blks_hit}         ),
          sprintf( '%-18s : %s', '% read/hit'      , 
                   calc_read_ratio( @{$h}{'blks_read','blks_hit'} )),
          sprintf( '%-18s : %s', 'xact_commit'   , $h->{xact_commit}    ),
          sprintf( '%-18s : %s', 'xact_rollback' , $h->{xact_rollback}  ),
          sprintf( '%-18s : %s', 'pg_size'       , $h->{size}           ),
          sprintf( '%-18s : %s', 'tablespace'    , $h->{dattablespace}  ),
          sprintf( '%-18s : %s', 'tup_returned'  , $h->{tup_returned}   ),
          sprintf( '%-18s : %s', 'tup_fetched'   , $h->{tup_fetched}    ),
          sprintf( '%-18s : %s', 'tup_inserted'  , $h->{tup_inserted}   ),
          sprintf( '%-18s : %s', 'tup_updated'   , $h->{tup_updated}    ),
          sprintf( '%-18s : %s', 'tup_deleted'   , $h->{tup_deleted}    ),
        ]
}
sub index3b {
	my ($o, $database , $oid) = @_;
	my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $h = $dh->select_one_to_hashref( 
		       [qw( relid         indexrelid    
			    relname       indexrelname   idx_scan    
			    idx_tup_read  idx_tup_fetch),
	                "pg_stat_get_blocks_fetched($oid) AS bfetched",
	                "pg_stat_get_blocks_hit($oid)     AS bhit",
	                "pg_stat_get_numscans($oid)       AS nscans",
                       ],
			'pg_stat_user_indexes',
	                [ 'indexrelid', '=', $oid ] );

        [ 
          sprintf( '%-18s : %s', 'indexrelid'    , $h->{indexrelid}    ),
	  sprintf( '%-18s : %s', 'relid'         , $h->{relid}         ),
          sprintf( '%-18s : %s', 'relname'       , $h->{relname}       ),
          sprintf( '%-18s : %s', 'idx_tup_read'  , $h->{idx_tup_read}  ),
          sprintf( '%-18s : %s', 'idx_tup_fetch' , $h->{idx_tup_fetch} ),
          sprintf( '%-18s : %s', 'index scans'   , $h->{nscans}        ),
          sprintf( '%-18s : %s', 'blocks read'   , $h->{bfetched}      ),
          sprintf( '%-18s : %s', 'blocks hit'    , $h->{bhit}          ),
          sprintf( '%-18s : %s', '% read/hit'    , 
			   calc_read_ratio( $h->{bfetched}, $h->{bhit}) ),
	]
}

sub fsm_settings {
        my ($o, $database )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;

	my $h = $dh->{dbh}->selectall_arrayref(<<"");
	   select 
	   (select setting from pg_settings where name='max_fsm_relations') ,
	   (select setting from pg_settings where name='max_fsm_pages') 

        my ($max_fsm_rel, $max_fsm_pages) = map { @{$_}[0..1]}  @$h ;
        my $ret1 = [ sprintf( '%-15s: %10s', 'max_fsm_rel'  , $max_fsm_rel  ), 
                     sprintf( '%-15s: %10s', 'max_fsm_pages', $max_fsm_pages),
                   ];

        # more results if we can fsm functions are installed, and we are super
        $h = $dh->select_one_to_hashref(<<"");
           user in (select rolname from pg_roles where rolsuper) AS super

        return $ret1  unless $h;
	my $db_of_func = search4func( $o, 'pg_freespacemap_pages',
                                        $database, databases2 $o ) ;

	return $ret1  unless $db_of_func;
        $dh = dbconnect ( $o, form_dsn($o, $db_of_func ) ) ;
        my $stored_rel = $dh->select_one_to_hashref( 'count(1)',
				  'pg_freespacemap_relations');
        my $stored_pages = $dh->select_one_to_hashref( 'sum(storedpages)',
                                  'pg_freespacemap_relations');
        my $ret2 = [ 
		sprintf( '%-15s: %10s', 'fsm_rel'  , $stored_rel->{count}), 
		sprintf( '%-15s: %10s', 'fsm_pages', $stored_pages->{sum}),
                   ];
        my $st = $dh->select( {
                 fields=>[qw(  datname      relfilenode
			       avgrequest   interestingpages  storedpages     
                         )], 
		 table =>'pg_freespacemap_relations, pg_database',
		 join  =>'pg_database.oid=pg_freespacemap_relations.reldatabase'
                 });

	my (%o2n,$total_pages, $total_rel);
	$o2n{$database} = oid2name_per_db($o, $database);
	my $r3 = [
                   '', sprintf( '%-10s %-31s %9s %9s %8s', '', '', 'avg.req',
                                             'intrest', ' stored'),
		    map {  my ($db, $oid, $num) =@{$_}[0..1,4];
		       $total_pages += $num; $total_rel++ ;
	               exists $o2n{$db} or $o2n{$db}=oid2name_per_db($o,$db);
	               $oid  = $o2n{$db}->{$oid} || $oid  ;
	               sprintf '%-10s %-33s %8d %8d %8d', $db,$oid,@{$_}[2..4]
                    } @{ $st->fetchall_arrayref}
                 ];
        [ @$ret1, @$ret2, @$r3 ,'', 
          sprintf 'Relations = %4d, %45s = %5d',$total_rel,'Pages',$total_pages 
        ];
}
sub pgbuffercache_desc {
	sprintf '%-36s  %9s %10s %20s',  
		'name', 'count', 'relpages', '% count/relpages'
}
sub pgbuffercache {
        my ($o, $database, $mode )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;

        my $h = $dh->select_one_to_hashref(<<"");
	   user in (select rolname from pg_roles where rolsuper) AS super

        return [ q(Must be in a "super" role to view buffer data.) ]
                     unless $h->{super}; 
	my $db_of_func = search4func( $o, 'pg_buffercache_pages',
                                        $database, databases2 $o ) ;
        return [q(public.pg_buffercache found in any database.)] 
                   unless $db_of_func;

	if ($db_of_func eq $database) {
		goto &not_cached  if $mode =~ /^not_cached$/io;
		(my $st = $dh->{dbh}->prepare(<<""))->execute;
		select B.relfilenode::regclass AS name, count(1), relpages
		from   pg_buffercache B join pg_class C on (B.relfilenode=C.oid)
		where  B.relfilenode is not null
		group  by 1, relpages
		order  by 2 desc

		my @ret;
		while (my $h = $st->fetchrow_hashref) {
		     my ($name,$count,$size)=@{$h}{'name','count','relpages'};
		     next if ($mode =~ /^user$/io)&&( $name =~ /^pg_/o);
		     push @ret, sprintf '%-35s : %9s %10s %10.0f%%', 
                                        @{$h}{'name','count','relpages'},
                                        calc_read_ratio($count, $size);
		} 
		return \@ret;
	}else{
		return [ "public.pg_buffercache is at $db_of_func" ];
	}
}   
sub not_cached {
        my ($o, $database, $mode )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $h  = $dh->{dbh}->selectall_arrayref(<<"");
		select relname, relkind, relpages
		from pg_class
		where relkind in ('r','i')
		and relname !~ '^[0-9]+$$'
		and relname !~ '^pg_'
		and relname !~ '^sql_'
		and  relfilenode in
			(select relfilenode
			from   pg_class C
			where  relkind in ('r','i')
			EXCEPT
			select relfilenode
			from   pg_buffercache B
			where  B.relfilenode is not null)
		order by 2

	my $total;
	[ do {map { $total+= ${$_}[2] ; sprintf '%-35s  %-9s %8s', @{$_}[0..2] }
			      @$h
	  } , 
         '', 
	  sprintf( '%45s  %8d', 'Total', $total)
       ];
}

1;
__END__
=head1 NAME

Pg::Pcurse::Query1  - Support SQL queries for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Query1;

=head1 DESCRIPTION

Support SQL queries for Pg::Pcurse


=head1 SEE ALSO

Pg::Pcurse, pcurse(1)

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut
