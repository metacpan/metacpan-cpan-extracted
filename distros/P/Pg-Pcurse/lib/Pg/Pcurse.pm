# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Pcurse;

use v5.8;
use strict;
use warnings;
require Exporter;

use Curses;
use Curses::Widgets;
use Carp::Assert;
use strict;
use Pg::Pcurse::Query0;
use Pg::Pcurse::Query1;
use Pg::Pcurse::Query2;
use Pg::Pcurse::Query3;

our $VERSION = '0.25';

our $opt;

use base 'Exporter';

our @EXPORT = qw( 
	execute_mode       retrieve_context   capital_context
	$opt               retrieve_permit    update_big_display
	analyze            reindex            vacuum   save2file
	stat_of            over3              bufcalc  idx3b
	table2of           table3of           rewrite_of
);

*secondary_listbox = *main::secondary_listbox;
*big_listbox       = *main::big_listbox;
*create_button     = *main::create_button;
*display_strings   = *main::display_strings;


#########################################################################
## Main Dispatcher
sub execute_mode {
        my $mode = shift;
        ({  
	    tables     =>  \& show_tables      ,
	    views      =>  \& show_views       ,
            databases  =>  \& show_databases   ,
            vacuum     =>  \& show_vacuum      ,
            stats      =>  \& show_stats       ,
            buffers    =>  \& show_buffers     ,
            indexes    =>  \& show_indexes     ,
            procedures =>  \& show_procedu     ,
            rules      =>  \& show_rules       ,
            settings   =>  \& show_settings    ,
            bucardo    =>  \& show_bucardo     ,
            dict       =>  \& show_dict        ,
            triggers   =>  \& show_triggers    ,
            users      =>  \& show_users       ,
         } -> {$mode})->();
}

#########################################################################

sub update_schema_display {
        #  Schema Table
        $::she     = get_schemas2( $opt, $::dbname) or return;
	my $val;
        eval { $val=0; $val = $::schemas->getField('VALUE')  };
        $::schemas = secondary_listbox('Schemas', $::she, 2,37, $val);
        $::schemas->execute($::mwh,0);
        ($::sname) = first_word( $::she->[ $::schemas->getField('VALUE')] );
}

sub update_big_display {
        # Result Table ( like relevant tables, indexes, objects, etc,. )
       ($::desc, $::actual) = @_ ;
        $::desc    = $::desc->();
        $::tab     = $::actual->( $opt, $::dbname, $::sname, $::secname);
	my $val;
        eval { $val=0; $val = $::big->getField('VALUE')  };
        $::big     = big_listbox( $::desc, $::tab, 11, 0, $val);
        $::big->execute($::mwh,0);
}
sub disable_schema_display {
	return unless $::schemas;
	my $misc = misc_system_wide($opt);
	$::schemas->setField( LISTITEMS =>$misc, CAPTION=>'' );
	$::schemas->draw($::mwh);
}
sub big_display_only { 
	disable_schema_display ; 
        goto &update_big_display;
}
sub whole_movie {
        ($::desc, $::actual) = @_ ;
	update_schema_display( $::desc, $::actual );
	update_big_display( $::desc, $::actual) ;
}
sub update_section_display {
	my ($title, $choices) = @_ ;
	$::she = $choices;
	my $val;
        eval { $val=0; $val = $::schemas->getField('VALUE')  };
        $::schemas  = secondary_listbox( $title, $::she, 2,37,$val);
        $::schemas->execute($::mwh,0);
        ($::secname) = first_word( $::she->[ $::schemas->getField('VALUE')]);
}

sub show_settings { 
        my $choi = [qw( All backend internal postmaster 
                        sighup superuser user changed)];
	update_section_display ('Context', $choi);
        update_big_display( sub{''}, \& all_settings);
}
sub show_buffers { 
        my $choi = [ 'user', 'system & user', 'not_cached'];
	update_section_display ('', $choi);
        update_big_display( \& pgbuffercache_desc, \& bufferca_);
}
sub bufferca_{ 
	pgbuffercache $opt, $::dbname, $::secname;
}
sub show_databases{ big_display_only( \& all_databases_desc,\& all_databases) } 
sub show_bucardo  { big_display_only( \& bucardo_conf_desc, \& bucardo_conf)} 
sub show_users    { big_display_only( \&get_users_desc, \&get_users     )  }

sub show_stats   { whole_movie( \&table_stats_desc, \&table_stats       )  }
sub show_dict    { whole_movie( \&dict_desc, \&dict                     )  }
sub show_tables  { whole_movie( \&tables_brief_desc, \&tables_brief     )  }
sub show_views   { whole_movie( \&get_views_all_desc, \&get_views_all   )  }
sub show_procedu { whole_movie( \&get_proc_desc, \&get_proc             )  }
sub show_indexes { whole_movie( \&index3_desc, \&index3                 )  }
sub show_rules   { whole_movie( \&rules_desc, \&rules                   )  }
sub show_triggers{ whole_movie( \&schema_trg_desc, \&schema_trg         )  }
sub show_vacuum  { whole_movie( \&tables_vacuum_desc, \&tables_vacuum   )  }


## Another dispatcher
sub retrieve_permit {
        my ($sna) = first_word( $::she->[ $::schemas->getField('VALUE')] );
	get_nspacl($opt, $::dbname, $sna) ;
}

## Another dispatcher
sub retrieve_context {
	#return if $::mode eq 'rules' ;
        ({  
	    tables     => \& tstat    ,
            views      => \& viewof   ,
            vacuum     => \& vacuumof ,
            databases  => \& over2    ,
            stats      => \& statsof  ,
            settings   => \& settingof,
            procedures => \& procof   ,
	    buffers    => \& bufferca ,
	    rules      => \& ruleof   ,
            indexes    => \& indexof  ,
            bucardo    => \& bucardoof,
            triggers   => \& trgof    ,
            users      => \& userof   ,

         }->{$::mode||return})->(@_) ;
}

### The following functions are colled from the above dispatcher
sub stats2 { [table_stats2_desc,  @{table_stats2($opt, $::dbname, $::sname )}]}
sub bufferca{ 
	[ @{buffercache_summary( $opt, $::dbname)} ,
	  '','',
	  #@{ pgbuffercache( $opt, $::dbname)} ,
	  @{ pgbufpages( $opt, $::dbname, $::secname)} ,
        ]
}

sub vacuumof {
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        vacuum_per_table( $opt, $::dbname, $::sname, $f ) or return [];
        #vacuum_per_table( $opt, $::dbname, split(/\./, $f,2) ) or return [];
}
sub userof {
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        user_of( $opt, $f ) or return [];
}
sub trgof {
        my $index = $::big->getField('VALUE');
        my ($l)   = last_word( $::tab->[$index] );
        trg_of( $opt, $::dbname, $::sname, $l ) or return [];
}

sub ruleof {
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        my $text  = rule_of( $opt, $::dbname, $::sname, $f ) or return [];
}

sub over2  { 
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        over_dbs( $opt, $f) ;
} 
sub bucardoof  { 
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        bucardo_conf_of( $opt, $f) ;
} 


sub statsof  { 
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        statsoftable( $opt, $::dbname, $::sname,  $f) ;
} 
sub sql_formater {
	local $_ = shift or return '';
	return $_  if /^(select|from)/i ;
	return "    $_";
}
sub viewof  { 
        my $index =  $::big->getField('VALUE');
        my ($f)   =  first_word( $::tab->[$index] );
        my $text  =  view_of( $opt, $::dbname, $::sname,  $f) ;
	[  '', 
	   map { sql_formater( $_ ) }
	   map { my @parts  = split  /\bFROM\b/i, $_ ,2  ;
		 (@parts>1) ?  ($parts[0], 'FROM '. $parts[1])  : $parts[0] 
                }
		Curses::Widgets::textwrap($text, 50) 
        ];
} 

sub settingof {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        get_setting( $opt, $f ) or return [];
}

sub last_word { local $_ = shift; my ($last) =  / \w+$/xg; $last; }
sub over3  { 
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        over_dbs3( $opt, $f) ;
} 

sub procof {
        my $index = $::big->getField('VALUE')   ; 
        my $last  = last_word( $::tab->[$index] )   or return ['selection?'] ;
        proc_of( $opt, $::dbname, $last );
}

sub indexof {
        my $index = $::big->getField('VALUE')   ; 
        my $last  = last_word( $::tab->[$index] )   or return ['selection?'] ;
        get_index( $opt, $::dbname, $last ) or return [];
}
sub tstat {
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        table_stat( $opt, $::dbname, $::sname, $f ) or return [];
}

##########################################################################
## Another dispatcher
sub capital_context {
        eval{
        ({  tables     => \& tdataof  ,
            stats      => \& tdataof  ,
            indexes    => \& idxdef   ,
            rules      => \& ruleof   ,
            views      => \& viewof   ,
            stats      => \& mostof   ,
            settings   => \& fsmvals  ,
            databases  => \& dbof     ,
            buffers    => \& pgbufall ,
            vacuum     => \& v_settings ,
         }->{$::mode||return})->(@_) ;
	 };
}

sub v_settings{ vac_settings $opt }
sub pgbufall{ pgbuff_all $opt, $::dbname, $::secname }
sub bufcalc { 
	     [ '',
               @{buffercache_summary( $opt, $::dbname)} ,
	       '',
               @{bufstat( $opt, $::dbname, $::sname)},
	     ]
}

sub idxdef {
        my $index = $::big->getField('VALUE');
        my ($l) = last_word( $::tab->[$index] );
        indexdef( $opt, $::dbname, $l ) or return [];
}
sub idx3b {
        my $index = $::big->getField('VALUE');
        my ($l) = last_word( $::tab->[$index] );
        index3b( $opt, $::dbname, $l ) or return [];
}
sub stat_of {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        statisticsof( $opt, $::dbname, $::sname, $f ) or return [];
}
sub rewrite_of {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        rewriteof( $opt, $::dbname, $::sname, $f ) or return [];
}
sub mostof {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        most_common( $opt, $::dbname, $::sname, $f ) or return [];
}
sub tdataof {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        tbl_data_of( $opt, $::dbname, $::sname, $f ) or return [];
}
sub dbof {
        my $index  = $::big->getField('VALUE');
        my ($f)    = first_word( $::tab->[$index] );
        my $title  = object_totals_desc;
        my @desc   = object_totals_desc_long;
        my $r1     = object_totals( $opt, $f, 'all'     );
        my $r2     = object_totals( $opt, $f, 'shared'  );
        my $r3     = object_totals( $opt, $f, 'noshared');
        my $r4     = object_totals( $opt, $f, 'noshared-nosystem');
	[ $f, '', $title, '' , 
          "@$r1" . "\t\t totals", 
          "@$r2" . "\t\t shared", 
          "@$r3" . "\t\t not shared", 
          "@$r4" . "\t\t not shared, non-system", 
          @desc,
        ];
}
sub fsmvals {
        fsm_settings( $opt, $::dbname ) or return [];
}

##########################################################################
## Other dispatchers

sub display_keyword {
        my $keyword = shift||return;
        my ($y,$x)  = (9,1) ;
        $::mwh->addstr( $y,$x, $keyword);
        $::mwh->refresh;
        sleep 1;
        $::mwh->addstr( $y,$x, ' ' x length$keyword);
        $::mwh->refresh;
}
sub update_big_d {
        $::tab     = tables_brief( $opt, $::dbname, $::sname);
	$::big->setField( LISTITEMS => $::tab );
}

sub update_bigbox_inc {
        $::tab = ({ tables    => \& tables_brief,
                    stats     => \& table_stats,
                    #vacuum    => \& tables_of_db,
                    vacuum    => \& tables_vacuum,
                    databases => \& all_databases,
                 } -> {$::mode})->($opt, $::dbname, $::sname);
	$::big->setField( LISTITEMS => $::tab );
}
sub analyze  {
        return unless $::mode =~ qr/^ (tables|stats|databases|vacuum) $/xo;
        ({ tables    => \& do_analyze_tbl,
           stats     => \& do_analyze_tbl,
           vacuum    => \& do_analyze_tbl,
           databases => \& do_analyze_db,
        } -> {$::mode})->() ? display_keyword 'ANALYZE'
                            : display_keyword 'failed';
	update_bigbox_inc ;
}

sub vacuum  {
        return unless $::mode =~ qr/^ (tables|stats|databases|vacuum) $/xo;
        ({ tables    => \& do_vacuum_tbl,
           stats     => \& do_vacuum_tbl,
           vacuum    => \& do_vacuum_tbl,
           databases => \& do_vacuum_db,
        } -> {$::mode})->() ? display_keyword 'VACUUM' 
                            : display_keyword 'failed' ;
	update_bigbox_inc ;
}

sub reindex  {
	return unless $::mode eq 'indexes';
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
	my $ret = ($::mode eq 'tables') 
		?  reindex_tbl( $opt, $::dbname, $::sname, $f )
		:  reindex_db( $opt, $::dbname ) ;
        ($ret)  ? display_keyword 'REINDEX' 
                : display_keyword 'failed' ;
}

sub do_analyze_tbl {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        analyze_tbl( $opt, $::dbname, $::sname, $f ) or return ;
}
sub do_analyze_db {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        #analyze_db( $opt, $::dbname ) or return ;
        analyze_db( $opt, $f ) or return ;
}
sub do_vacuum_tbl {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        vacuum_tbl( $opt, $::dbname, $::sname, $f ) or return ;
}
sub table2of {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
        table2_of( $opt, $::dbname, $::sname, $f ) or return ;
}
sub table3of {
        my $index = $::big->getField('VALUE');
        my ($f) = first_word( $::tab->[$index] );
	my $nsp = $::sname;
	($f=~/\w\.\w/ )  and ($nsp,$f) = split /\./, $f ;
        table3_of( $opt, $::dbname, $nsp, $f ) or return ;
}
sub do_vacuum_db {
        my $index = $::big->getField('VALUE');
        my ($f)   = first_word( $::tab->[$index] );
        #vacuum_db( $opt, $::dbname ) or return ;
        vacuum_db( $opt, $f ) or return ;
}
sub save2file {
	eval { open my ($i) , '>>/tmp/pcurse.out';
	       print {$i} $::desc                ;
	       print {$i} $_  for @{$::tab}      ; 1;
	} or return;
        display_keyword 'SAVED ' ;
}

sub  display_button {
	my ($choices) = @_ ;
        $::butt       = create_button( $choices, 4, 58, 8);
        $::butt->execute($::mwh,0);
}
1;
__END__
=head1 NAME

Pg::Pcurse - Monitors a Postgres cluster


=head1 SYNOPSIS

  use Pg::Pcurse;

=head1 DESCRIPTION

Library functions for pcurse(1) which monitors Postgres databases



=head1 SEE ALSO

pcurse(1)


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut
