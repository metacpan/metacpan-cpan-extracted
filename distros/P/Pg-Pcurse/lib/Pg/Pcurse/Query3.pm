# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .
package Pg::Pcurse::Query3;
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
use Pg::Pcurse::Defaults;

#*pg_default = *Pg::Pcurse::Defaults::pg_default;

our @EXPORT = qw( 
	bucardo_conf_of  user_of           indexdef
        proc_of		 view_of           rewriteof
        rule_of		 tbl_data_of       table2_of	table3_of
	trg_of           tables_of_db      tables_of_db_desc
        statsoftable     statsoftable_desc vac_settings        
	all_settings     get_setting       most_common
	dict_desc        dict              statisticsof
        pgbuff_all	 pgbuff_all_desc   pgbufpages 
        tables_vacuum    tables_vacuum_desc 
);

sub statsoftable_desc {
     sprintf '%-25s%8s%9s%9s%9s%8s%8s','NAME',  'inserts','updates',
                        'deletes','hot-upd', 'live','dead'
}
sub statsoftable {
        my ($o, $database, $schema, $table )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;

	my $h  = $dh->select_one_to_hashref([qw(  relname    seq_scan
                                 seq_tup_read   idx_scan      idx_tup_fetch
				 n_tup_ins      n_tup_upd     n_tup_del
                                 n_tup_hot_upd  n_live_tup    n_dead_tup
                                 last_vacuum    last_autovacuum 
                                 last_analyze   last_autoanalyze
                               )],
                              'pg_stat_user_tables',
                              [     'schemaname', '=', $dh->quote($schema),
                                'and', 'relname', '=', $dh->quote($table)]);

	[ sprintf( '%-18s : %s', 'relname' ,       $h->{relname}      ),
	  sprintf( '%-18s : %s', 'seq_scan',       $h->{seq_scan}     ),
	  sprintf( '%-18s : %s', 'idx_scan',       $h->{idx_scan}     ),
	  sprintf( '%-18s : %s', '% read/idx', 
	            calc_read_ratio( $h->{seq_scan},$h->{idx_scan})    ),
	  sprintf( '%-18s : %s', 'n_live_tup',      $h->{n_live_tup}   ),
	  sprintf( '%-18s : %s', 'n_dead_tup',      $h->{n_dead_tup}   ),
	  sprintf( '%-18s : %s', 'seq_tup_read',   $h->{seq_tup_read} ),
	  sprintf( '%-18s : %s', 'idx_tup_fetch',  $h->{idx_tup_fetch}),
	  sprintf( '%-18s : %s', 'n_tup_ins',       $h->{n_tup_ins}    ),
	  sprintf( '%-18s : %s', 'n_tup_upd',       $h->{n_tup_upd}    ),
	  sprintf( '%-18s : %s', 'n_tup_del',       $h->{n_tup_del}    ),
	  sprintf( '%-18s : %s', 'n_tup_hot_upd',   $h->{n_tup_hot_upd}),
	  sprintf( '%-18s : %s', 'last_vacuum',     $h->{last_vacuum}  ),
	  sprintf( '%-18s : %s', 'last_autovacuum' ,$h->{last_autovacuum}),
	  sprintf( '%-18s : %s', 'last_analyze',    $h->{last_analyze}  ),
	  sprintf( '%-18s : %s', 'last_autoanalyze',$h->{last_autoanalyze}),
        ];
}

sub beautify_src {
	my $src = shift||return'';
($src) =~ /\S.*\S/gs;
$src =~ s/^\s*//mg;
#$src =~ s/\n/ /smg;
 Curses::Widgets::textwrap($src, 40);
}
sub proc_of {
        my ($o, $database, $oid )= @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;

        (my $st = $dh->{dbh}->prepare( <<""))->execute( $oid, 'pg_proc', $oid);
	         SELECT proname  , nspname , pg_get_userbyid(proowner) as owner,
                        lanname  , procost , prorows       , proisagg ,
                        prosecdef, proisstrict , proretset , provolatile , 
                        pronargs , prorettype::regtype     , proallargtypes, 
                        proargtypes ,
                        prosrc   , proargmodes , proargnames, probin ,
                        proacl   , proconfig   ,
		        pg_catalog.obj_description( ?, ? )  AS desc
		FROM pg_proc P 
                     join pg_namespace N on (pronamespace= N.oid)
		     join pg_language  L on (prolang = L.oid)
                WHERE p.oid = ?

        my $h = $st->fetchrow_hashref  ;
	$h->{proargtypes} = types2text( $o, $h->{proargtypes} );
	[ sprintf( '%-12s : %s', 'name',     $h->{proname}     ),
          sprintf( '%-12s : %s', 'oid',         $oid              ),
	  sprintf( '%-12s : %s', 'namespace',$h->{nspname}     ),
	  sprintf( '%-12s : %s', 'owner',    $h->{owner}       ),
	  sprintf( '%-12s : %s', 'lang',     $h->{lanname}     ),
	  sprintf( '%-12s : %s', 'desc',     $h->{desc}        ),
	  sprintf( '%-12s : %s', 'rows',     $h->{prorows}     ),
	  sprintf( '%-12s : %s', 'isagg',    $h->{proisagg}    ),
	  sprintf( '%-12s : %s', 'secdef',   $h->{prosecdef}   ),
	  sprintf( '%-12s : %s', 'isstrict', $h->{proisstrict} ),
	  sprintf( '%-12s : %s', 'retset',   $h->{proretset}   ),
	  sprintf( '%-12s : %s', 'nargs',    $h->{pronargs}    ),
	  sprintf( '%-12s : %s', 'rettype',  $h->{prorettype}  ),
	  sprintf( '%-12s : %s', 'argtypes', $h->{proargtypes} ),
	  sprintf( '%-12s : %s', 'argmodes', $h->{proargmodes} ),
	  sprintf( '%-12s : %s', 'acl',      $h->{proacl}      ),
	  #printf( '%-12s : %s', 'argnames', ($h->{proargnames})
                             #?  $h->{proargnames}[0] : ''),
          #sprintf( '%-12s : %s', 'bin',     $h->{probin}      ),
	  sprintf( '%-12s : %s', 'volatile', $h->{provolatile} ),
	  sprintf( '%-12s : %s', 'config',   $h->{proconfig}   ),
	  sprintf( '%-12s : %s', 'cost',     $h->{procost}     ),
	  '',
          beautify_src( $h->{prosrc} ),
	];
}
      
sub view_of {
	my ($o, $database , $schema, $view) = @_;

        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$view   = $dh->quote($view)  ;
	$schema = $dh->quote($schema);
        my $h   = $dh->select_one_to_hashref( 'definition',
	                                      'pg_views',
                                             ['schemaname' , '=', $schema, 
                                              'and viewname','=', $view ]);
	$h->{definition} ;
}
sub max_length_keys {
	my $max=0;
	for (@_) {
		if (length$_ > $max) { $max = length$_};
	}
	$max;
}
sub bucardo_conf_of {
        my ($o, $setting) = (@_);
        my $dh   = dbconnect ( $o, form_dsn($o, 'bucardo')  ) or return;
	my $h    = $dh->select_one_to_hashref(
                        [qw( setting value about cdate )], 
		        'bucardo.bucardo_config',
		        ['setting','=', $dh->quote( $setting) ] );


        [  sprintf( '%-25s : %-s', 'setting', $h->{setting}  ),
           sprintf( '%-25s : %-s', 'value'  , $h->{value}    ),
           sprintf( '%-25s : %-s', 'default', $bucardo_defaults->{$setting} ), 
           sprintf( '%-25s : %-s', 'cdate'  , $h->{cdate}    ),
	   '',
#%TODO
          Curses::Widgets::textwrap($h->{about},30),
        ]
}

sub trg_of {
	my ($o, $database , $schema, $tgoid ) = @_;
	return [ 'invalid oid '] unless $tgoid =~ /^\d+$/;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$schema = $dh->quote($schema);
        #my $h   = $dh->select_one_to_hashref (
        my $h   = $dh->select_one_to_hashref ( 
                                [qw( tgname  tgrelid::regclass 
	                             tgfoid  tgenabled tgtype
                                     tgisconstraint tgconstrname
                                     tgconstrrelid::regclass   
                                     tgconstraint
                                     tgdeferrable    tginitdeferred 
                                     tgnargs  tgattr tgargs
                                    ),
				     "pg_get_triggerdef($tgoid) as def",
                                 ],   
                                'pg_trigger',
                                 [ 'oid', '=', $tgoid] );

	[ sprintf( '%-15s : %-s',  'name'         ,  $h->{tgname}         ),
	  sprintf( '%-15s : %-s',  'relid'        ,  $h->{tgrelid}        ),
	  sprintf( '%-15s : %-s',  'foid'         ,  $h->{tgfoid}         ),
	  sprintf( '%-15s : %-s',  'type'         ,  $h->{tgtype}         ),
	  sprintf( '%-15s : %-s',  'enabled'      ,  $h->{tgenabled}      ),
	  sprintf( '%-15s : %-s',  'isconstraint' ,  $h->{tgisconstraint} ),
	  sprintf( '%-15s : %-s',  'constrname'   ,  $h->{tgconstrname}   ),
	  sprintf( '%-15s : %-s',  'constrrelid'  ,  $h->{tgconstrrelid}  ),
	  sprintf( '%-15s : %-s',  'constraint'   ,  $h->{tgconstraint}   ),
	  sprintf( '%-15s : %-s',  'deferrable'   ,  $h->{tgdeferrable}   ),
	  sprintf( '%-15s : %-s',  'initdeferred' ,  $h->{tginitdeferred} ),
	  sprintf( '%-15s : %-s',  'nargs'        ,  $h->{tgnargs}        ),
	  sprintf( '%-15s : %-s',  'attr'         ,  $h->{tgattr}         ),
	  sprintf( '%-15s : %-s',  'args'         ,  $h->{tgargs}         ),
	  '',
	  Curses::Widgets::textwrap($h->{def},70),
        ]
}


sub user_of {
	my ($o, $user ) = @_;
	return [ 'invalid user '] unless $user;
	my $dh  = dbconnect ( $o, form_dsn($o,'')  ) or return;

	$user   = $dh->quote('postgres');
        my $h   = $dh->select_one_to_hashref( "user = $user as who" );
        return [ q(Must be user "postgres" to view authid data.) ]
                     unless $h->{who}; 

        $h      = $dh->select_one_to_hashref ( 
                    [qw( rolname      rolsuper      rolinherit   rolcreaterole 
                         rolcreatedb  rolcatupdate  rolcanlogin  rolconnlimit
                         rolpassword  rolvaliduntil rolconfig
                    )],
                    'pg_authid',
	            ['rolname','=', $user] );

        [  sprintf( '%-14s : %-s', 'name'      , $h->{rolname}        ),
           sprintf( '%-14s : %-s', 'super'     , $h->{value}          ),
           sprintf( '%-14s : %-s', 'inherit'   , $h->{rolinherit}     ),
           sprintf( '%-14s : %-s', 'createrole', $h->{rolcreaterole}  ),
           sprintf( '%-14s : %-s', 'createdb'  , $h->{rolcreatedb}    ),
           sprintf( '%-14s : %-s', 'catupdate' , $h->{rolcatupdate}   ),
           sprintf( '%-14s : %-s', 'canlogin'  , $h->{rolcanlogin}    ),
           sprintf( '%-14s : %-s', 'connlimit' , $h->{rolconnlimit}   ),
           sprintf( '%-14s : %-s', 'password'  , $h->{rolpassword}    ),
           sprintf( '%-14s : %-s', 'validuntil', $h->{rolvaliduntil}  ),
#TODO
        #  sprintf( '%-14s : %-s', 'config'    , $h->{rolconfig}      ),
	]
}
sub tbl_data_of {
	my ($o, $database , $schema, $table) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	(my $st  = $dh->{dbh}->prepare(<<""))->execute;
			select age(xmin), * from  $schema.$table
			order by age(xmin) desc
			limit 20

	my ($i,@ret) = 0;
	while ( my $h= $st->fetchrow_hashref ) {	
		push @ret,
		sprintf( '-[ RECORD  %3s ]-------------------------', $i++),
		sprintf '%-20s : %s', 'age(xmin)', $h->{age} ; 
		while( my ($k,$v) = each %$h) {
			next if $k eq 'age';
			push @ret,
		        sprintf '%-20s : %s', $k, $v ; 
		}
		last if $i>20;
	}
	return [ @ret ];
}

sub formatrule {
	my $all = shift;
	my ($l1, $rest)  = $all =~ m/^(.*AS\s*)(\bON\b.*)/sxgi;
	my ($l2, $more)  = $rest =~ m/^(.*)(\bDO\b.*)/xgsi;
        [ $l1, $l2, Curses::Widgets::textwrap($more,60)];
}

sub rule_of {
	my ($o, $database , $schema, $rule) = @_;
        $database or $database = $o->{dbname} ;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
	$schema = $dh->quote($schema);
	$rule   = $dh->quote($rule);
        my $h   = $dh->select_one_to_hashref (  
                                'definition', 'pg_rules',
                               ['schemaname', '=', $schema , 
                                'and', 'rulename', '=', $rule ]) ;
	['', @{ formatrule( $h->{definition} ) }]  ;
}
sub tables_of_db_desc {
         sprintf '%-32s  %-17s', 'Table', 'Age (Million)';
}
sub tables_of_db {
	my ($o, $database ) = @_;
	my $dh  = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        my $h   = $dh->{dbh}->selectall_arrayref( <<"");
		SELECT  nspname||'.'||relname, age( relfrozenxid )
		FROM pg_class c
			 join pg_namespace N on ( N.oid= C.relnamespace)
		WHERE relkind = 'r'
			and nspname not like 'pg_%'
			and nspname not like 'information_schema'
		ORDER BY 1

        [ map { sprintf '%-40s  %5.3f', ${$_}[0], ${$_}[1]/1_000_000 } @$h ]
}

sub are_equal {
	my ($actual, $default) = @_;
	return 1  if ($actual eq'60s'      and   $default eq '1min' );
	return 1  if ($actual eq'1024kB'   and   $default eq '1MB'  );
	return 1  if ($actual eq'2048kB'   and   $default eq '2MB'  );
	return 1  if ($actual eq'16384kB'  and   $default eq '16MB' );
	return 1  if ($actual eq'10240kB'  and   $default eq '10MB' );
	return 1  if ($actual eq'300s'     and   $default eq '5min' );
	return 1  if ($actual eq'1000ms'   and   $default eq '1s'   );
	return 1  if ($actual eq'1440min'  and   $default eq '1d'   );
	return 1  if ($actual eq'88kB'     and   $default eq '64kB' );
	return 1  if ($actual eq'-1kB'     and   $default eq '-1'   );
	return 1  if ($actual eq'-1ms'     and   $default eq '-1'   );
	return 1  if ($actual eq'10248kB'  and   $default eq '8MB'  );
	return 1  if ($actual eq'163848kB' and   $default eq '128MB');
	return;
}

sub all_settings {
	my ($o,undef,undef, $context)= @_;
	my $dh = dbconnect ( $o, form_dsn($o,'') ) or return;
	my $st;
	if ($context =~ /^all/xoi ) {
		$st = $dh->select([qw(name setting unit)], 'pg_settings');
	}elsif ($context =~ /^changed/xoi) {
		$st = $dh->select([qw(name setting unit)], 'pg_settings');
        }else{
		$st = $dh->select([qw(name setting unit)], 
                             'pg_settings', ['context', 'ilike', 
                                    $dh->quote($context)])  or return;
	}
	if ($context !~ /^changed/xoi ) {
	   [ map { sprintf '%-34s%19s%10s',$_->[0], $_->[1]||'',$_->[2]||''}
             @{$st->fetchall_arrayref} ];
	}else{
		my @res ;
		for ( @{$st->fetchall_arrayref}) {
			my ( $name,$val,$unit) = ($_->[0], 
                                                 $_->[1]||'', $_->[2]||'') ;
	                my $default=$Pg::Pcurse::Defaults::pg_default->{$name};
			next  unless $default;
			next  if  ($val.$unit) eq $default;
			next  if  are_equal($val.$unit, $default);
		       push @res, 
		       sprintf '%-34s%19s%10s',$name, $val,$unit,
		
		}
		return  [ @res ] ;
	}
} 
sub get_setting {
	my ($o,$name) = @_;
	return unless $name;
	my $dh = dbconnect ( $o, form_dsn($o,'') ) or return;
	my $h  = $dh->select_one_to_hashref(
                        [qw( name category context min_val max_val
			     short_desc extra_desc vartype unit setting 
                        )], 'pg_settings', 
                        ['name', '=', $dh->quote($name) ])  or return;
        [ sprintf( '%-s', $h->{name}), '',
          sprintf( '%-9s : %s', 'setting' , $h->{setting} || ''),
          sprintf( '%-9s : %s', 'default' , 
                   $Pg::Pcurse::Defaults::pg_default->{ $h->{name}} ),
          sprintf( '%-9s : %s', 'vartype' , $h->{vartype} || ''),
          sprintf( '%-9s : %s', 'min_val' , $h->{min_val} || ''),
          sprintf( '%-9s : %s', 'max_val' , $h->{max_val} || ''),
          sprintf( '%-9s : %s', 'units'   , $h->{units}   || ''),
          sprintf( '%-9s : %s', 'context' , $h->{context} || ''),
          sprintf( '%-9s : %s', 'sourse'  , $h->{sourse}  || ''),
	  sprintf( '%-9s : %s', 'category', $h->{category}|| ''), 
	  '',
	  Curses::Widgets::textwrap($h->{short_desc},75),
	  '',
	  Curses::Widgets::textwrap($h->{extra_desc},75),
	  ($h->{name} eq 'log_line_prefix') && 
		sprintf 'REMEMBER: pgfouine expects   %s', '%t [%p]: [%l-1]'
        ] 
} 
sub dict_desc {
	 sprintf'%-20s %-10s         %-10s', 'Dict', 'Owner', 'template';
}
sub dict {
        my ($o, $database, $schema, $table )= @_;
        my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        $schema = $dh->quote( $schema );
        my $h   = $dh->{dbh}->selectall_arrayref( <<"" );
	 	SELECT dictname,  pg_get_userbyid( dictowner), tmplname
		FROM      pg_ts_dict     D
	             join pg_namespace   D  on (dictnamespace=D.oid)
	             join pg_ts_template D  on (D.dicttemplate=D.oid)
	        WHERE nspname = $schema

	[ map { sprintf('%-20s %-10s         %-10s', @{$_}[0..2] )} 
	     @$h
        ]

}
sub indexdef {
        my ($o, $database, $oid )= @_;
        my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $h   = $dh->select_one_to_hashref( "pg_get_indexdef($oid) AS def");
        [ '','', Curses::Widgets::textwrap( $h->{def} , 50) ]
}
sub statisticsof {
        my ($o, $database, $schema, $table )= @_;
        my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        $schema = $dh->quote( $schema );
        my $st  = $dh->select( [qw( attname  avg_width  null_frac
		               n_distinct most_common_vals most_common_freqs
				histogram_bounds correlation
                             )],
	                     'pg_stats',
	                     ['schemaname', '=', $schema,
                              'and', 'tablename', '=', $dh->quote($table)]);

	my @ret = ( sprintf('%s',$table ), '',
                    sprintf('%-20s %9s %9s %9s %9s', 'column', 'avg_width', 
                            'null_frac', 'n_distinct', 
                            'correlation', 'most_freq') );
	while ( my $h = $st->fetchrow_hashref ) {
		push @ret, 
                sprintf( '%-20s %9s %9.2f %10.2f %10.2f', 
                         $h->{attname}   , $h->{avg_width} ,
		 	 $h->{null_frac} , $h->{n_distinct} ,
		 	 $h->{correlation} , # $h->{most_common_freqs} ,
                  ); 
	}
	\@ret;
}
sub freq2str {
	my ($ref, $mult, $len) = @_;
	my ($out, $val);
	$len=$len-4;
	for (@$ref) {
	        $val = sprintf '%4.2f', $_*$mult;	
		$val =~ s/^(.*)\.00$/' 'x(4-length$1).$1/xeo ;
		$out .= sprintf( "%s%s ", (' 'x$len), $val);  
	}
	$out;
}
sub occur2str {
	my ($ref, $mult, $len) = @_;
	my $out;
	$out .= sprintf( "%${len}d ",  $_*$mult+.5)  for @$ref;
	$out;
}
sub array2str {
	my ($res, $len) = @_;
	my $out;
	$out .= sprintf "%${len}s ", $_  for @$res;
	$out;
}
sub str2array {
	my $res = shift||return;
	$res =~ s/^\{//;
	$res =~ s/,/, /g;
	chop$res;
	[ split /\s*,\s*/, $res ]
}
sub sum_freq {
	my $aref = shift||return;
	my $sum;
	$sum += $_  for @$aref;
	$sum;
}
sub largest_len {
	my $aref = shift||return;
	my $max;
	((length)> $max) && ($max=length) for @$aref;
	$max;
}
sub most_common {
        my ($o, $database, $schema, $table )= @_;
        my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $count = $dh->select_one_to_hashref( 'reltuples','pg_class',
                                    ['relname','=', $dh->quote($table)
                                    ]);
	$count = $count->{reltuples};
        (my $st   = $dh->{dbh}->prepare( <<""))->execute($schema,$table);
		            select   attname,  most_common_freqs,
				     most_common_vals 
	                    from  pg_stats 
	                    where schemaname = ?
                               and   tablename= ?

	my @ret = sprintf '%-s %-20s  (rows=%s)', 'TABLE  ', $table , $count ;
	while ( my $h= $st->fetchrow_hashref) {
		 my $aref = $h->{most_common_freqs};
		 my $cval = str2array $h->{most_common_vals};
	         push @ret, '-' x 73,
	                     sprintf( 'COLUMN: %s', $h->{attname});
		 next unless @{$h}{most_common_freqs};
		 my $sum_of_common_freqs = sum_freq( $aref);
		 my $num_of_common_vals  = @$cval;
		 my $largest_len         = largest_len $cval;
		 $largest_len <4 and $largest_len = 5;
		 push @ret, sprintf('%-12s = %s', 'common vals',
				array2str( $cval, $largest_len )),
	                    sprintf( '%-12s = %s', 'common freqs',
					freq2str $aref, 1, $largest_len),
			    sprintf('%-12s = %s', 'occurrences',
                                        occur2str $aref,$count, $largest_len),
	         #sprintf('%-15s = %3.4f','prob of other values', 
		  #(1-$sum_of_common_freqs)/($count-$num_of_common_vals)),
	         #sprintf('%-15s = %3.4f','occurence of other values', 
		  #$count*(1-$sum_of_common_freqs)/($count-$num_of_common_vals))
	}
	\@ret;
}
sub table2_of {
        my ($o, $database , $schema, $table) = @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref( [qw(  relname     seq_scan
                                    n_tup_ins      n_tup_upd   n_tup_del
                                    n_tup_hot_upd  n_live_tup  n_dead_tup
                                    seq_tup_read   idx_scan    idx_tup_fetch
                                    last_vacuum    last_autovacuum 
                                    last_analyze   last_autoanalyze
                               )],
                              'pg_stat_user_tables',
                              ['relname', '=', $dh->quote($table),
                               'and','schemaname', '=', $dh->quote($schema)] );


        my $r1=
	[ sprintf('%-20s : %s', 'relname'  ,     $h->{relname}          ),
	  sprintf('%-20s : %s', 'seq_scan',      $h->{seq_scan}         ),
	  sprintf('%-20s : %s', 'idx_scan',      $h->{idx_scan}         ),
	  sprintf('%-20s : %s', 'Ratio', 
                calc_read_ratio  $h->{seq_scan}, $h->{idx_scan}         ),
	  sprintf('%-20s : %s', 'seq_tup_read',  $h->{seq_tup_read}     ),
	  sprintf('%-20s : %s', 'idx_tup_fetch', $h->{idx_tup_fetch}    ),
	  sprintf('%-20s : %s', 'n_tup_ins',     $h->{n_tup_ins}        ),
	  sprintf('%-20s : %s', 'n_tup_upd',     $h->{n_tup_upd}        ),
	  sprintf('%-20s : %s', 'n_tup_del',     $h->{n_tup_del}        ),
	  sprintf('%-20s : %s', 'n_tup_hot_upd', $h->{n_tup_hot_upd}    ),
	  sprintf('%-20s : %s', 'n_live_tup',    $h->{n_live_tup}       ),
	  sprintf('%-20s : %s', 'n_dead_tup',    $h->{n_dead_tup}       ),
	];

          $h  = $dh->select_one_to_hashref( [qw( 
				relid           heap_blks_read   heap_blks_hit  
				idx_blks_read   idx_blks_hit     toast_blks_read
				toast_blks_hit  tidx_blks_read   tidx_blks_hit
                               )],
                              'pg_statio_user_tables',
                              ['relname', '=', $dh->quote($table),
                               'and','schemaname', '=', $dh->quote($schema)] );

        my $r2=
	[ sprintf('%-20s : %s', 'heap_blks_read' ,  $h->{heap_blks_read  }),
	  sprintf('%-20s : %s', 'heap_blks_hit'  ,  $h->{heap_blks_hit   }),
	  sprintf('%-20s : %s', 'idx_blks_read'  ,  $h->{idx_blks_read   }),
	  sprintf('%-20s : %s', 'idx_blks_hit'   ,  $h->{idx_blks_hit    }),
	  sprintf('%-20s : %s', 'toast_blks_read',  $h->{toast_blks_read }),
	  sprintf('%-20s : %s', 'toast_blks_hit' ,  $h->{toast_blks_hit  }),
	  sprintf('%-20s : %s', 'tidx_blks_read' ,  $h->{tidx_blks_read  }),
	  sprintf('%-20s : %s', 'tidx_blks_hit'  ,  $h->{tidx_blks_hit   }),
	];
	[ @$r1, @$r2 ]
}
sub ev_type {
	return {  1 => 'SELECT' ,
	          2 => 'UPDATE' ,
	          3 => 'INSERT' ,
	          4 => 'DELETE' ,
                 }->{shift||return};
}

sub rewriteof {
        my ($o, $database , $schema, $rule) = @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref( [qw( rulename     ev_qual     
                                                  ev_attr      ev_type 
					          ev_enabled   is_instead  
                                                  ev_class::regclass 
                               )],
                              'pg_rewrite',
                              ['rulename', '=', $dh->quote($rule) ]);

	[ sprintf('%-20s : %s', 'rulename'  ,     $h->{rulename}         ),
	  sprintf('%-20s : %s', 'ev_class'  ,     $h->{ev_class}         ),
	  sprintf('%-20s : %s', 'ev_qual'   ,     $h->{ev_qual}          ),
	  sprintf('%-20s : %s', 'ev_attr'   ,     $h->{ev_attr}          ),
	  sprintf('%-20s : %s', 'ev_enabled',     $h->{ev_enabled}       ),
	  sprintf('%-20s : %s', 'ev_instead'  ,   $h->{is_instead}       ),
	  sprintf('%-20s : %s %10s', 'ev_type',   $h->{ev_type},
                                                  ev_type($h->{ev_type}) ),
        ]
}

sub pgbuff_all_desc {
	sprintf '%-16s  %-35s %8s',  'dbname', 'name', 'count'
}
sub pgbuff_all {
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
                return ['Not Implemented']  if $mode =~ /^not_cached$/io;
		(my $st = $dh->{dbh}->prepare(<<""))->execute;
			SELECT D.datname, B.relfilenode AS oid, count(1)
			FROM   pg_buffercache B
			       join pg_database D  on ( D.oid=B.reldatabase)
			--where  B.relfilenode::regclass::text !~ '^pg_'
			GROUP  BY datname, B.relfilenode --, relpages
			ORDER  BY 1 , count DESC

		my (%o2n, $tcount);
		$o2n{$database} = oid2name_per_db($o, $database);
		my @ret;
		while (my $h = $st->fetchrow_hashref) {
		     my ($db,$oid,$count)=@{$h}{'datname', 'oid','count'};
                     exists $o2n{$db} or $o2n{$db}=oid2name_per_db($o,$db);
                     my $name  = $o2n{$db}->{$oid} || $oid  ;
		     next if ($mode =~ /^user$/io)&&( $name =~ /^pg_/o);
		     $tcount += $count;
		     push @ret, sprintf '%-15s : %-35s %8d', $db, $name, $count
		} 
		return [ pgbuff_all_desc, '' , 
	                 sprintf( '%53s = %6d', 'Total', $tcount),
                         '', @ret
                       ] ;
	}else{
		return [ "public.pg_buffercache is at $db_of_func" ];
	}
}   
sub pgbufpages_desc {
	sprintf '%-16s  %-35s %5s %8s', 'dbname', 'relation', 
				'block', 'bytes', 
}
sub pgbufpages {
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
                return ['Not Applicable']  if $mode =~ /^not_cached$/io;
		(my $st = $dh->{dbh}->prepare(<<""))->execute;
		SELECT  datname , relfilenode AS oid , 
                        relblocknumber AS bn, bytes
		FROM pg_freespacemap_pages F
			join pg_database D on (D.oid = F.reldatabase)
		WHERE bytes is not NULL

		my (%o2n, $tcount);
		$o2n{$database} = oid2name_per_db($o, $database);
		my @ret;
		while (my $h = $st->fetchrow_hashref) {
		     my ($db,$oid,$count)=@{$h}{'datname', 'oid'} ;
                     exists $o2n{$db} or $o2n{$db}=oid2name_per_db($o,$db);
                     my $name  = $o2n{$db}->{$oid} || $oid  ;
		     next if ($mode =~ /^user$/io)&&( $name =~ /^pg_/o);
		     push @ret, sprintf '%-15s : %-35s %5d %8d', $db, $name, 
                                            @{$h}{ 'bn','bytes'}
		} 
		return [ pgbufpages_desc,'',
                         @ret
                       ] ;
	}else{
		return [ "public.pg_buffercache is at $db_of_func" ];
	}
}   
sub vac_settings {
        my ($o)= @_;
        my $dh = dbconnect ( $o, form_dsn($o,'') ) or return;
        my $st = $dh->select([qw( name setting unit category)],
                           'pg_settings');

        [ map { my ($name,$val,$unit) = @{$_}[0..2];
		my $default=$Pg::Pcurse::Defaults::pg_default->{$name};
		undef $default if $default eq $val.$unit;
		sprintf '%-29s%15s %s%20s',$name, $val,$unit, $default

	      }
	  grep {$_->[0] =~ /vacuum|track_counts/}
          @{$st->fetchall_arrayref} ];
}
sub table3_of {
        my ($o, $database , $schema, $table) = @_;
        my $dh = dbconnect ( $o, form_dsn($o, $database ) ) or return;
        my $h  = $dh->select_one_to_hashref( [qw(  relname     seq_scan
                                    n_tup_ins      n_tup_upd   n_tup_del
                                    n_tup_hot_upd  n_live_tup  n_dead_tup
                                    seq_tup_read   idx_scan    idx_tup_fetch
                                    last_vacuum    last_autovacuum 
                                    last_analyze   last_autoanalyze
                               )],
                              'pg_stat_user_tables',
                              ['relname', '=', $dh->quote($table),
                               'and','schemaname', '=', $dh->quote($schema)] );

	my $res1 =
	[ sprintf('%-20s : %10s', 'relname'  ,     $h->{relname}          ),
	  sprintf('%-20s : %10d', 'n_tup_ins',     $h->{n_tup_ins}        ),
	  sprintf('%-20s : %10d', 'n_tup_upd',     $h->{n_tup_upd}        ),
	  sprintf('%-20s : %10d', 'n_tup_del',     $h->{n_tup_del}        ),
	  sprintf('%-20s : %10d', 'n_tup_hot_upd', $h->{n_tup_hot_upd}    ),
	  sprintf('%-20s : %10d', 'n_live_tup',    $h->{n_live_tup}       ),
	  sprintf('%-20s : %10d', 'n_dead_tup',    $h->{n_dead_tup}       ),
	  '','',
	  sprintf('%-20s = %10d', 'up + del', $h->{n_tup_upd}+$h->{n_tup_del} ),
	  sprintf('%-20s = %10d', 'up + del + ins',  
                       $h->{n_tup_upd} + $h->{n_tup_del} + $h->{n_tup_ins} ),
	];

	## Find number or tuples
	my $reltuples = reltuples( $dh , $table, $schema);

	## Find params from pg_autovacuum or from pg_settings, in this order.
	my ($vac_thresh, $vac_scale, $ana_thresh, $ana_scale)=
                         (pg_autovacuum($dh, $table, $schema)) 
                         ?  pg_autovacuum($dh, $table, $schema)
                         :  pg_settings($dh) ;

	my $vac_expected = $vac_thresh + ($vac_scale* $reltuples);
	my $ana_expected = $ana_thresh + ($ana_scale* $reltuples);
	my $res2 =
	[ sprintf('%-20s %12d', 'autovacuum  kicks at' , $vac_expected), 
	  sprintf('%-20s %12d', 'autoanalyze kicks at' , $ana_expected), 
	];
	[ @$res1, '', '', @$res2 ]
}

sub reltuples {
	## Find number or tuples
	my ($dh, $table, $schema) = @_;
        my $h  = $dh->select_all_to_hashref(  [qw( relname reltuples )],
                                              'pg_class',
                                              ['relname=', $dh->quote($table)]);
	$h->{person} || 0;
}
sub pg_settings {
	## Find params from pg_settings
	my $dh = shift;
        my $h  = $dh->select_all_to_hashref( [qw( name  setting )],
                                          'pg_settings',
                                          ['name ~',$dh->quote('autovacuum')]);
       @{$h}{'autovacuum_vacuum_threshold' ,'autovacuum_vacuum_scale_factor' ,
	     'autovacuum_analyze_threshold','autovacuum_analyze_scale_factor',};
}
sub pg_autovacuum {
	## Find params from pg_settings
	my ($dh, $table, $schema) = @_;
        my $st  = $dh->select( '*',
                  'pg_autovacuum',
                  ['vacrelid::regclass::text=',$dh->quote($table)]) or return;
	my %h= $st->fetchrow_hash();
        @h{'vac_base_thresh'  ,  'vac_scale_factor' ,
	   'anl_base_thresh'  ,  'anl_scale_factor'  , } ;
}

sub tables_vacuum_desc {
         sprintf '%-22s%22s%22s', 'NAME', 'vacuum', 'analyze'
}
sub tables_vacuum {
        my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
        my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        $schema = $dh->quote($schema);
        my $h  = $dh->{dbh}->selectall_arrayref(<<"");
        select relname,
                greatest( last_vacuum,  last_autovacuum ) AS vacuum,
                greatest( last_analyze, last_autoanalyze) AS analyze
        from pg_stat_all_tables
        where schemaname=$schema
        order by 2, 3, 1

        for my $i (@$h) { $_=to_d($_)   for @$i; }
        [ map { sprintf '%-22s%22s%22s', @{$_}[0..2]}
               @{$h} ];
}


1;
=head1 NAME

Pg::Pcurse::Query3  - Support SQL queries for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Query3;

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
